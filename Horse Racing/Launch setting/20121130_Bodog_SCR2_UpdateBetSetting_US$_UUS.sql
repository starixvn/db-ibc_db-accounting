
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	update racing min/max bet for bodog customers
*/
	
BEGIN
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('custinfo','dep_custsetting3rd') AND type = 'U') <> 2
		RETURN

	DECLARE @res AS TABLE (custid INT)
	DECLARE @splitter CHAR(1), @string VARCHAR(MAX)

	SELECT @splitter = ',', @string = @ids

	IF SUBSTRING (@string, LEN (@string), 1) <> @splitter
		  SET @string= @string+@splitter

	DECLARE @START INT, @word NVARCHAR(4000), @CHARINDEX INT, @i INT
	SET @i=1
	SET @START=1
	SET @CHARINDEX= CHARINDEX( @splitter, @string, @START)
	WHILE (@CHARINDEX <> 0)BEGIN
		SET @word= SUBSTRING( @string, @START, @CHARINDEX - @START)
		SET @START= @CHARINDEX +1
		SET @CHARINDEX= CHARINDEX( @splitter, @string, @START)
		INSERT INTO @res  VALUES(CAST(@word AS INT))
		SET @i=@i+1
	END

	DECLARE @betsetting TABLE(currency INT, currencyName VARCHAR(20), minbet MONEY, maxbet MONEY, maxpermatch MONEY)

	INSERT INTO @betsetting (currencyname,currency,minbet, maxbet, maxpermatch)
			  SELECT 	'US$'	,	3	,	10.00	,	2500.00		,	7500.00
	UNION ALL SELECT 	'UUS'	,	20	,	10.00	,	2500.00		,	7500.00  -- FOR TESTING , the same as US$



	UPDATE cs3 WITH(ROWLOCK,UPDLOCK)	
	SET cs3.minbet = b.minbet,
		cs3.maxbet = b.maxbet
	FROM custinfo c WITH(NOLOCK)
		INNER JOIN @betsetting b ON c.currency = b.currency
		INNER JOIN dep_custsetting3rd cs3 ON c.custid = cs3.custid
	WHERE c.custid IN (SELECT * FROM @res)
		AND sporttype IN (151,152,153)
		
	UPDATE	c WITH (UPDLOCK,ROWLOCK) 
	SET		c.maxpermatch151 = b.maxpermatch,
			c.maxpermatch151_OT = b.maxpermatch,
			c.MaxPerMatch151_AU = b.maxpermatch,
			c.MaxPerMatch152_UK = b.maxpermatch,
			c.MaxPerMatch152_AU = b.maxpermatch,
			c.MaxPerMatch153_AU = b.maxpermatch
	FROM	custInfo c
			INNER JOIN @betsetting b ON c.currency = b.currency
	WHERE	c.custid IN (SELECT * FROM @res)
END

go 


DECLARE @betsetting TABLE(currency INT, currencyName VARCHAR(20), minbet MONEY, maxbet MONEY, maxpermatch MONEY)

INSERT INTO @betsetting (currencyname,currency,minbet, maxbet, maxpermatch)
		  SELECT 	'US$'	,	3	,	10.00	,	2500.00		,	7500.00
UNION ALL SELECT 	'UUS'	,	20	,	10.00	,	2500.00		,	7500.00  -- FOR TESTING , the same as US$

declare @maxCustid int 
set @maxCustid = XXX  -- SELECT MAX(CustID) FROM Custinfo WITH (NOLOCK) 


create table #temp (custid int primary key, isfinished bit)

INSERT INTO #temp (custid, isfinished)
SELECT DISTINCT c.custid, 0
FROM custinfo c WITH(NOLOCK)
	INNER JOIN @betsetting b ON c.currency = b.currency
	INNER JOIN dep_custsetting3rd cs3 WITH(NOLOCK) ON c.custid = cs3.custid
WHERE sporttype IN (151,152,153)
	AND ( cs3.minbet <> b.minbet
		OR cs3.maxbet <> b.maxbet
		)
	AND c.srecommend IN (SELECT custid FROM f_depsuper_1('bodog'))
	AND c.mrecommend NOT IN (4603309,	-- BODOGACCUUS
							4687035	,	-- BODOGACCUS$
							4688841	,	-- BODOGACCRMB
							4689362	,	-- BODOGACCTB
							4689753	,	-- BODOGACCSD$
							4690118	,	-- BODOGACCNT
							4714306	,	-- BODOGACCRM
							4715123	,	-- BODOGACCGBP
							4715305	,	-- BODOGACCEURO
							4715598	,	-- BODOGACCWON
							7651931	,	-- BODOGACCAUD
							7652101	,	-- BODOGACCNZD
							8198588		-- BODOGACCINH
							)
	AND c.custid <= @maxCustid
go


declare @ids varchar(max), @rowcnt int

while (1=1)
begin
	select @ids = ''
	
	update TOP (5000) #temp
	set @ids = @ids + case @ids when '' then '' else ',' end + cast(custid as varchar(12))
		,isfinished = 1
	from #temp
	where isfinished = 0
	
	select @rowcnt = @@rowcount	

	EXEC [Acc_ExecRep_09] @ids = @ids
	
	if @rowcnt < 5000 RETURN

	WAITFOR DELAY '00:00:01'
end

