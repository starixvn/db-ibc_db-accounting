DECLARE @maxcustid INT, @superid INT

SELECT @superid = xxxx

SELECT @maxcustid= MAX(custid) FROM Customer WITH(NOLOCK) 
		
CREATE TABLE #temp (custid INT PRIMARY KEY, isfinished BIT)	

INSERT INTO #temp (custid, isfinished)
SELECT custid, 0
FROM customer WITH(NOLOCK)
WHERE custid <= @maxcustid
	AND roleid <> 1
	AND srecommend = @superid

GO

DECLARE @rowcnt INT


IF (SELECT COUNT(1) FROM sys.objects WHERE NAME IN ('custLoginInfo') AND TYPE = 'u') <> 1
		RETURN
		
WHILE (1=1)
BEGIN   
    UPDATE TOP (20000) #temp
    SET isfinished = 1
    FROM #temp
    WHERE isfinished = 0
 
	SELECT @rowcnt = @@ROWCOUNT    

    UPDATE custLoginInfo WITH(UPDLOCK,ROWLOCK)
    SET isForcedChangeSecurityCode = 1
    WHERE custid IN (SELECT custid FROM #temp WHERE isfinished = 1)
		AND SecurityCode IS NULL
    
    IF @rowcnt < 20000 RETURN
	
	DELETE #temp WHERE isfinished = 1
	
    WAITFOR DELAY '00:00:02'
    
END