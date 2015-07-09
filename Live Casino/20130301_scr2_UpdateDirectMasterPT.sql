

CREATE TABLE #directMaster (custid INT, srecommend INT)

-- direct master
-- get master of 70%, 85% PT (except THB & IDD currency)
INSERT INTO #directMaster
SELECT c.custid, c.srecommend
FROM customer c WITH(NOLOCK)
	INNER JOIN custsettinggame g WITH(NOLOCK) ON c.custid = g.custid
WHERE roleid = 3 AND currency NOT IN (33,43) AND c.srecommend <= 100
AND site <> '789y'
AND g.mpositiontaking IN (0.7,0.85)

-- 598 rows affected
UPDATE custsettinggame WITH(ROWLOCK,UPDLOCK)
SET mpositiontaking = CASE	WHEN mpositiontaking = 0.70 THEN 0.83							
							WHEN mpositiontaking = 0.85 THEN 0.93
							ELSE mpositiontaking
					  END
WHERE custid IN (SELECT custid FROM #directMaster)


-- 20 rows affected
;WITH rs AS
(
	SELECT t.srecommend, MAX(mpositiontaking) mpositiontaking
	FROM custsettinggame g WITH(NOLOCK)	
		INNER JOIN #directMaster t ON g.custid = t.custid 
	WHERE g.custid IN (SELECT custid FROM #directMaster)
	GROUP BY t.srecommend 
)
UPDATE g WITH(ROWLOCK,UPDLOCK)
SET g.spositiontaking = r.mpositiontaking
FROM custsettinggame g 
	INNER JOIN rs r ON g.custid = r.srecommend


GO
GO


CREATE TABLE #directMasterCurrency (custid INT, srecommend INT)

-- direct master THB & IDD
INSERT INTO #directMasterCurrency
SELECT c.custid, c.srecommend
FROM customer c WITH(NOLOCK)
WHERE roleid = 3 AND currency IN (33,43) and c.srecommend <= 100
AND site <> '789y'

-- 1 row affected
UPDATE custsettinggame WITH(ROWLOCK,UPDLOCK)
SET mpositiontaking = 0.93					
WHERE custid IN (SELECT custid FROM #directMasterCurrency)

-- 1 row affected
UPDATE custsettinggame WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = 0.93					
WHERE custid IN (SELECT DISTINCT srecommend FROM #directMasterCurrency)
