


/*
	2. correct PT setting & min/max bet for 789y customers

*/

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)	
AS
BEGIN	
	IF (SELECT COUNT(1) FROM sys.objects WHERE NAME IN ('CustSetting3rd') AND TYPE = 'u') <> 1
		RETURN
		
	SET NOCOUNT ON 
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
			
	UPDATE vs WITH(ROWLOCK,UPDLOCK)
	SET vs.spositiontaking = ng.spositiontaking,
		vs.mpositiontaking = ng.mpositiontaking,
		vs.apositiontaking = ng.apositiontaking,
		vs.autopositiontaking = ng.autopositiontaking,
		vs.isautopositiontaking = ng.isautopositiontaking,
		vs.autompositiontaking = ng.autompositiontaking,
		vs.isautompositiontaking = ng.isautompositiontaking,
		vs.minbet = ng.minbet,
		vs.maxbet = ng.maxbet
	FROM custsetting3rd vs
		INNER JOIN custsetting3rd ng WITH(NOLOCK) ON vs.custid = ng.custid
	WHERE vs.custid IN (SELECT * FROM @res)
		AND vs.sporttype = 180 AND vs.bettype = 1201
		AND ng.sporttype = 161 AND ng.bettype = 81
END
 
GO

-- select max(custid) from custinfo with(nolocK)
DECLARE @maxcustid INT
SELECT @maxcustid = XXXX 
	
--- get 789 super customers
SELECT custid 
INTO #789Customer
FROM customer 
WITH(NOLOCK) WHERE site = '789y' AND roleid = 4

-- get affected customers
CREATE TABLE #temp (custid INT PRIMARY KEY, isfinished BIT)

INSERT INTO #temp (custid, isfinished)   
SELECT c.custid, 0
FROM custInfo c WITH(NOLOCK)
	INNER JOIN custsetting3rd vs WITH(NOLOCK) ON c.custid = vs.custid AND vs.sporttype = 180
	INNER JOIN custsetting3rd ng WITH(NOLOCK) ON c.custid = ng.custid AND ng.sporttype = 161 AND ng.bettype = 81
WHERE srecommend IN (SELECT * FROM #789Customer)
and (vs.spositiontaking <> ng.spositiontaking
	OR vs.mpositiontaking <> ng.mpositiontaking
	OR vs.apositiontaking <> ng.apositiontaking
	OR vs.autopositiontaking <> ng.autopositiontaking
	OR vs.isautopositiontaking <> ng.isautopositiontaking
	OR vs.autompositiontaking <> ng.autompositiontaking
	OR vs.isautompositiontaking <> ng.isautompositiontaking
	OR vs.minbet <> ng.minbet
	OR vs.maxbet <> ng.maxbet)
AND c.custid <= @maxcustid

GO

declare @ids varchar(max), @rowcnt int        

WHILE (1=1)
BEGIN
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
END
