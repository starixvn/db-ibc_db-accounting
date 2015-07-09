 
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	Correct com setting for other comm & 1x2
*/
BEGIN
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('customer','custsetting') AND type = 'U') <> 2
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
		cp.discount  =  ca.discount,
		cp.playerdiscount = CASE WHEN cp.playerdiscount > ca.discount THEN ca.discount ELSE cp.playerdiscount END
	FROM customer c WITH(NOLOCK)
		INNER JOIN custsetting cp ON c.custid = cp.custid
		INNER JOIN custsetting cs WITH(NOLOCK) ON c.srecommend = cs.custid AND cp.sporttype = cs.sporttype and cp.bettype = cs.bettype
		INNER JOIN custsetting cm WITH(NOLOCK) ON c.mrecommend = cm.custid AND cp.sporttype = cm.sporttype and cp.bettype = cm.bettype
		INNER JOIN custsetting ca WITH(NOLOCK) ON c.recommend  = ca.custid AND cp.sporttype = ca.sporttype and cp.bettype = ca.bettype
	WHERE c.custid IN (SELECT * FROM @res)
		AND cp.bettype IN (4,5,6,9,10,20,21,22)	
		AND cs.bettype IN (4,5,6,9,10,20,21,22)	
		AND cm.bettype IN (4,5,6,9,10,20,21,22)	
		AND ca.bettype IN (4,5,6,9,10,20,21,22)	
		AND (
			cp.sdiscount <> cs.sdiscount
			OR cp.adiscount <> cm.adiscount
			OR cp.discount <> ca.discount
			OR cp.playerdiscount > ca.discount
		)
END


CREATE TABLE #temp (custid int primary key, isfinished bit)
DECLARE @maxCustID INT
SET @maxCustID = 1200000000

INSERT INTO #temp (custid, isfinished)
SELECT distinct c.custid, 0
FROM customer c WITH(NOLOCK)	
	INNER JOIN custsetting cp WITH(NOLOCK) ON c.custid = cp.custid
	INNER JOIN custsetting cs WITH(NOLOCK) ON c.srecommend = cs.custid and cp.sporttype = cs.sporttype and cp.bettype = cs.bettype
	INNER JOIN custsetting cm WITH(NOLOCK) ON c.mrecommend = cm.custid and cp.sporttype = cm.sporttype and cp.bettype = cm.bettype
	INNER JOIN custsetting ca WITH(NOLOCK) ON c.recommend  = ca.custid and cp.sporttype = ca.sporttype and cp.bettype = ca.bettype
	INNER JOIN custsuper csp WITH(NOLOCK) ON c.srecommend = csp.custid
WHERE c.roleid = 1 AND csp.isInternal = 0 	
	AND (
			cp.sdiscount <> cs.sdiscount
		OR cp.adiscount <> cm.adiscount
		OR cp.discount <> ca.discount
		OR cp.playerdiscount > ca.discount
		)
	AND cp.bettype IN (4,5,6,9,10,20,21,22)	
	AND c.recommend not in (5707545,52466)
	AND c.srecommend <= 100
	AND c.custid <= @maxCustID

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


