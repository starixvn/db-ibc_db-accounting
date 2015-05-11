 
 
/*
	5. update disableVS for 789y customers

*/
 

SELECT custid 
INTO #789Customer
FROM customer 
WITH(NOLOCK) WHERE site = '789y' AND roleid = 4

DECLARE @maxCustID INT
SET @maxCustID = xxx
 
-- disable virtual sport for all downlines
--- 8008
UPDATE custInfo WITH(ROWLOCK,UPDLOCK)
SET DisableVirtualSports = 1
WHERE srecommend IN (SELECT * FROM #789Customer)
AND roleid < 4
AND DisableVirtualSports = 0
AND custid <= @maxCustID


GO


DECLARE @maxCustID INT
SET @maxCustID = xxx
-- enable virtual sport for supers only
-- 355
UPDATE custInfo WITH(ROWLOCK,UPDLOCK)
SET DisableVirtualSports = 0
WHERE srecommend IN (SELECT * FROM #789Customer)
AND roleid = 4
AND DisableVirtualSports = 1
