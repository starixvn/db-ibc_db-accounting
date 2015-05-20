
CREATE TABLE #super (custid INT)


-- get super of 70%, 85% PT (except THB & IDD currency)
INSERT INTO #super
SELECT c.custid
FROM customer c WITH(NOLOCK)
	INNER JOIN custsettinggame g WITH(NOLOCK) ON c.custid = g.custid
WHERE roleid = 4 AND currency NOT IN (33,43) AND c.custid > 100
AND site <> '789y'
AND c.custid NOT IN (SELECT custid FROM f_depsuper_1('All'))
AND g.spositiontaking IN (0.7,0.85)

-- 1238 rows affected
UPDATE custsettinggame WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = CASE	WHEN spositiontaking = 0.70 THEN 0.83
							WHEN spositiontaking = 0.85 THEN 0.93
							ELSE spositiontaking
					  END
WHERE custid IN (SELECT custid FROM #super)

GO
GO
CREATE TABLE #superCurrency (custid INT)


-- get super THB & IDD
INSERT INTO #superCurrency
SELECT c.custid
FROM customer c WITH(NOLOCK)
WHERE roleid = 4 AND currency IN (33,43) AND c.custid > 100
	AND site <> '789y'
	AND c.custid NOT IN (SELECT custid FROM f_depsuper_1('All'))

-- 208 rows affected
UPDATE custsettinggame WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = 0.93					
WHERE custid IN (SELECT custid FROM #superCurrency)

