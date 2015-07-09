

/*
	1. Insert default PT setting for missing 789y customers

*/

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)	
AS
BEGIN	
	SET NOCOUNT ON 
	DECLARE @res AS TABLE (custid INT)
	DECLARE @splitter CHAR(1), @string VARCHAR(MAX)
	SELECT @splitter = ',', @string = @ids
	
	IF SUBSTRING (@string, LEN (@string), 1) <> @splitter
		  SET @string= @string+@splitter
		
	DECLARE @START INT, @word NVARCHAR(4000), @CHARINDEX INT, @i INT
		  
	IF (SELECT COUNT(1) FROM sys.objects WHERE NAME IN ('CustSetting3rd') AND TYPE = 'u') <> 1
		RETURN
				
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
		
	INSERT INTO CustSetting3rd([custId], [bettype], [sporttype], [apositiontaking], [mpositiontaking], [spositiontaking],  [playerdiscount], [discount], [adiscount], [sdiscount], [Minbet], [Maxbet], autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking)
	SELECT cs.custid, 1201, 180, [apositiontaking], [mpositiontaking], [spositiontaking],  0 as [playerdiscount], 0 as [discount], 0 as [adiscount], 0 as [sdiscount], [Minbet], [Maxbet], autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, 0 as alivepositiontaking,0 as mlivepositiontaking,0 as  slivepositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking, 0 as autolivempositiontaking, 0 as isautolivempositiontaking
	FROM CustSetting3rd cs WITH(NOLOCK)			
	WHERE cs.custid IN (SELECT * FROM @res)
		AND cs.bettype = 81 AND cs.sporttype = 161			

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

INSERT INTO #temp (custid, isfinished)  -- 944538 rows affected
SELECT c.custid, 0
FROM custInfo c WITH(NOLOCK)
	LEFT OUTER JOIN custsetting3rd cs3 WITH(NOLOCK) ON c.custid = cs3.custid AND cs3.sporttype = 180
WHERE srecommend IN (SELECT * FROM #789Customer)
AND cs3.custid IS NULL 
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
