

CREATE TABLE #customer(custid INT, roleid INT)

INSERT INTO #customer
SELECT custid, roleid
FROM custinfo WITH(NOLOCK)
WHERE srecommend IN (SELECT custid FROM f_depsuper_1('12bet'))
AND mrecommend NOT IN (
						791048	,--- 12BETACCUS$
						791052	,--- 12BETACCEURO
						832125	,--- 12BETACCTB
						835094	,--- 12BETACCGBP
						835036	,--- 12BETACCRM
						835044	,--- 12BETACCRMB
						1255629	,--- 12BETACCUUS
						1015436	,--- 12BETACCAUD
						1015563	,--- 12BETACCCHF
						1752427	,--- 12BETACCSD$
						1813588	,--- 12BETACCIN
						3167467	,--- 12BETACCINH
						6006581	,--- 12BETACCWON
						6006552	,--- 12BETACCINR
						6006574	,--- 12BETACCJPY
						7526067	,--- 12BETACCHK$
						927780  --- 12BETAFF
					)
AND roleid > 1


-- update dummy super PT
-- 17 rows affected
UPDATE custsettingGame WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = 0.93,
	mpositiontaking = 0,
	apositiontaking = 0
WHERE custid IN (SELECT custid FROM #customer WHERE roleid = 4)


-- update dummy master PT
-- 28 rows affected
UPDATE custsettingGame WITH(ROWLOCK,UPDLOCK)
SET mpositiontaking = 0.93	
WHERE custid IN (SELECT custid FROM #customer WHERE roleid = 3)

-- update agent PT
-- 2094 rows affected
UPDATE custsettingGame WITH(ROWLOCK,UPDLOCK)
SET apositiontaking = 0.93
WHERE custid IN (SELECT custid FROM #customer WHERE roleid = 2)

