ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
/*	
Insert Min PT Setting (CustOverride3rd)	 
*/
BEGIN	
	SET NOCOUNT ON 
	DECLARE @res AS TABLE (custid INT)
	DECLARE @splitter CHAR(1), @string VARCHAR(MAX)
	SELECT @splitter = ',', @string = @ids
	
	IF SUBSTRING (@string, LEN (@string), 1) <> @splitter
		  SET @string= @string+@splitter
		
	DECLARE @START INT, @word NVARCHAR(4000), @CHARINDEX INT, @i INT		  	
	
	IF (SELECT COUNT(1) FROM sys.objects WHERE NAME IN ('custinfo' ,'CustOverride3rd') AND TYPE = 'u') <> 2
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
	
	INSERT INTO CustOverride3rd([custId], [bettype], [sporttype], minpositiontaking, maxpositiontaking,minlivepositiontaking,maxlivepositiontaking)		
	SELECT co.CustID, 1201, 180, minpositiontaking, 
		case when roleid = 4 then maxpositiontaking
			else 0.9 end as maxpositiontaking, 
		0 as minlivepositiontaking,0 as maxlivepositiontaking
	FROM custinfo ci WITH (NOLOCK) JOIN 
		custOverride3rd co WITH(NOLOCK)	ON ci.custid=co.custid 		
	WHERE co.custid IN (SELECT * FROM @res)		
		AND co.bettype = 81 AND co.sporttype = 161							
END
 
/*

-- select max(custid) from custinfo with(nolocK)
DECLARE @mincustid INT,@maxcustid INT
SELECT @mincustid= 0,
	@maxcustid= XXXX --8414563
	
--1. Insert Min PT Setting (CustOverride3rd)

CREATE TABLE #temp (custid INT PRIMARY KEY, isfinished BIT)

INSERT INTO #temp (custid, isfinished)
SELECT custid, 0
FROM dbo.Customer c WITH (NOLOCK)
WHERE custid >= @mincustid and custid <= @maxcustid
	and roleid in (2,3,4)

-- SELECT * FROM #temp

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

 