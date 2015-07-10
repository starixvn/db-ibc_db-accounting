
/*
	1. Insert default PT setting on IBC database
*/

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)	
AS
/*	
	 1 - Insert PT Setting 
*/
BEGIN	
	SET NOCOUNT ON 
	DECLARE @res AS TABLE (custid INT)
	DECLARE @splitter CHAR(1), @string VARCHAR(MAX)
	SELECT @splitter = ',', @string = @ids
	
	IF SUBSTRING (@string, LEN (@string), 1) <> @splitter
		  SET @string= @string+@splitter
		
	DECLARE @START INT, @word NVARCHAR(4000), @CHARINDEX INT, @i INT
		  
	
	IF (SELECT COUNT(1) FROM sys.objects WHERE NAME IN ('Dep_CustSetting3rd') AND TYPE = 'u') <> 1
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
		
	INSERT INTO Dep_CustSetting3rd
		([custid]
       ,[bettype]
       ,[sporttype]
       ,[islive]
       ,[apositiontaking]
       ,[mpositiontaking]
       ,[spositiontaking]
       ,[playerdiscount]
       ,[discount]
       ,[adiscount]
       ,[sdiscount]
       ,[minbet]
       ,[maxbet])
	SELECT 				
		[custid]
       ,1220 as [bettype]
       ,186 as [sporttype]
       ,[islive]
       ,[apositiontaking]
       ,[mpositiontaking]
       ,[spositiontaking]
       ,0 as [playerdiscount]
       ,0 as [discount]
       ,0 as [adiscount]
       ,0 as [sdiscount]
       ,[minbet]
       ,[maxbet]		
	FROM dbo.Dep_CustSetting3rd cs WITH(NOLOCK)			
	WHERE cs.custid IN (SELECT * FROM @res)
		AND cs.bettype = 1201 AND cs.sporttype = 180	AND cs.islive=0
	
	INSERT INTO Dep_CustSetting3rd
		([custid]
       ,[bettype]
       ,[sporttype]
       ,[islive]
       ,[apositiontaking]
       ,[mpositiontaking]
       ,[spositiontaking]
       ,[playerdiscount]
       ,[discount]
       ,[adiscount]
       ,[sdiscount]
       ,[minbet]
       ,[maxbet])
	SELECT 				
		[custid]
       ,1231 as [bettype]
       ,181 as [sporttype]
       ,[islive]
       ,[apositiontaking]
       ,[mpositiontaking]
       ,[spositiontaking]
       ,0 as [playerdiscount]
       ,0 as [discount]
       ,0 as [adiscount]
       ,0 as [sdiscount]
       ,[minbet]
       ,[maxbet]		
	FROM dbo.Dep_CustSetting3rd cs WITH(NOLOCK)			
	WHERE cs.custid IN (SELECT * FROM @res)
		AND cs.bettype = 1201 AND cs.sporttype = 180	AND cs.islive=0
END
 
/*
DECLARE @mincustid INT,@maxcustid INT
SELECT @mincustid= 0
select @maxcustid = max(custid) from custinfo with(nolocK)

-- 1. Insert PT Setting (Dep_CustSetting3rd)
	 
CREATE TABLE #temp (custid INT PRIMARY KEY, isfinished BIT)

INSERT INTO #temp (custid, isfinished)
SELECT custid, 0
FROM dbo.Customer c WITH (NOLOCK)
WHERE custid >= @mincustid and custid <= @maxcustid
	and srecommend IN (SELECT custid FROM dbo.f_DepSuper_1('all'))

GO

declare @ids varchar(max), @rowcnt int        

WHILE (1=1)
BEGIN
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
END
*/

 