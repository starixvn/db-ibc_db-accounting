
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS

/*
	correct discount on member: copy from upline
*/
BEGIN
	SET NOCOUNT ON 
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('custsetting','custinfo') AND type = 'U') <> 2
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
	
	UPDATE cp WITH(ROWLOCK,UPDLOCK)
	SET cp.sdiscount = cs.sdiscount,
		cp.adiscount = cm.adiscount,
		cp.discount  = ca.discount,
		cp.playerdiscount = CASE WHEN cp.playerdiscount > ca.discount THEN ca.discount ELSE cp.playerdiscount END
	FROM custinfo c WITH(NOLOCK)
		INNER JOIN custsetting cp ON c.custid = cp.custid
		INNER JOIN custsetting cs WITH(NOLOCK) ON c.srecommend = cs.custid
		INNER JOIN custsetting cm WITH(NOLOCK) ON c.mrecommend = cm.custid
		INNER JOIN custsetting ca WITH(NOLOCK) ON c.recommend  = ca.custid
	WHERE   cp.sporttype = 99 AND cp.bettype = 9
		AND cs.sporttype = 99 AND cs.bettype = 9
		AND cm.sporttype = 99 AND cm.bettype = 9
		AND ca.sporttype = 99 AND ca.bettype = 9
		AND c.custid IN (select * from @res)
END
GO



DECLARE @maxCustID INT,
		@minCustID INT
		
SELECT	@maxCustID = 8232278,
		--@minCustID = 3208991	---- 3564330 customers 
		@minCustID = 0			---- 3996858 customers 
create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
SELECT c.custid, 0
FROM custinfo c WITH(NOLOCK)
		INNER JOIN custsetting cp ON c.custid = cp.custid
		INNER JOIN custsetting cs WITH(NOLOCK) ON c.srecommend = cs.custid
		INNER JOIN custsetting cm WITH(NOLOCK) ON c.mrecommend = cm.custid
		INNER JOIN custsetting ca WITH(NOLOCK) ON c.recommend  = ca.custid
		INNER JOIN custsuper csp WITH(NOLOCK) ON c.srecommend = csp.custid
	WHERE   cp.sporttype = 99 AND cp.bettype = 9
		AND cs.sporttype = 99 AND cs.bettype = 9
		AND cm.sporttype = 99 AND cm.bettype = 9
		AND ca.sporttype = 99 AND ca.bettype = 9
		AND c.roleid = 1 AND cs.isInternal = 0
		AND c.custid BETWEEN @minCustID AND @maxCustID
		AND srecommend NOT IN (SELECT custid FROM f_depsuper_1('all'))
		AND ( 
				   cp.sdiscount <> cs.sdiscount
				OR cp.adiscount <> cm.adiscount
				OR cp.discount  <> ca.discount
				OR cp.playerdiscount > ca.discount
			)

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
 
