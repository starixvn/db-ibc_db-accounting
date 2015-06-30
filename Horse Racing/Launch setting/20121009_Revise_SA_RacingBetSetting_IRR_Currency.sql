
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	update SA horse racing BET SETTING for IRR currency
	minbet: 5
	maxbet: 15000
	maxpermatch: 30000	
*/
BEGIN
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('custsetting3rd') AND type = 'U') <> 1
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

	UPDATE cs3 WITH(ROWLOCK,UPDLOCK)
	SET minbet = 5,
		maxbet = 15000
	FROM custsetting3rd cs3		
	WHERE cs3.sporttype = 151 AND cs3.bettype IN (31,32)
		AND cs3.custid in (select * from @res)	
	
END


CREATE TABLE #temp (custid int primary key, isfinished bit)
DECLARE @maxCustID INT
SET @maxCustID = XXX

INSERT INTO #temp (custid, isfinished)
SELECT c.custid, 0
FROM custinfo c WITH(NOLOCK)
	INNER JOIN custsetting3rd cs3 WITH(NOLOCK) ON c.custid = cs3.custid 
WHERE c.currency = 40
	--srecommend NOT IN (SELECT custid FROM dbo.f_depsuper_1('ALL'))
	AND (cs3.minbet <> 5 OR cs3.maxbet <> 15000)
	AND cs3.sporttype = 151 AND cs3.bettype BETWEEN 31 AND 32
AND custid <= @maxCustID

--

declare @ids varchar(max), @rowcnt int

while (1=1)
begin
	select @ids = ''
	
	update TOP (10000) #temp
	set @ids = @ids + case @ids when '' then '' else ',' end + cast(custid as varchar(12))
		,isfinished = 1
	from #temp
	where isfinished = 0
	
	select @rowcnt = @@rowcount
	
	EXEC [Acc_ExecRep_09] @ids = @ids

	
	if @rowcnt < 10000 RETURN
	WAITFOR DELAY '00:00:01'
end

