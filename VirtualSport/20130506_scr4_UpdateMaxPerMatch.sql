



/*
	4. correct maxpermatch for 789y customers

*/

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)	
AS
BEGIN	
	IF (SELECT COUNT(1) FROM sys.objects WHERE NAME IN ('custinfo') AND TYPE = 'u') <> 1
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
			
	UPDATE custinfo WITH(ROWLOCK,UPDLOCK)
	SET maxpermatch180 = maxpermatch161
	WHERE custid IN (SELECT * FROM @res)		
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
WHERE srecommend IN (SELECT * FROM #789Customer)
and maxpermatch161 <> maxpermatch180
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
