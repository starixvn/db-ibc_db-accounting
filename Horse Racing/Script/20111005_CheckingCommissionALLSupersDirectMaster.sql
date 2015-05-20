--
--CREATE TABLE #tmpDummy (CustID INT)
--
--CREATE TABLE #tmpSuperNonComm (CustID INT, UserName VARCHAR(30), Currency INT, Total MONEY)
----
--CREATE TABLE #tmpDirectMaster (
--	SRecommend INT,
--	MRecommend INT,
--	Recommend INT,
--	CustID	INT,
--	Username VARCHAR(50),
--	sdiscount MONEY,
--	adiscount MONEY,
--	discount MONEY,
--	Total MONEY,
--	SType BIT
--)



INSERT INTO #tmpDummy(CustID)
SELECT	CustID 
FROM	f_DepSuper_1('ALL')
UNION ALL
SELECT custid 
FROM custInfo WITH (NOLOCK)
WHERE (username LIKE '3rdSuper%'
		OR  username LIKE '%ACCSuper%'
		OR  username LIKE 'STEST%'
		)
	AND roleid = 4


--Super with sdiscount  <> 0.1 at SUPER LEVEL
INSERT INTO #tmpSuperNonComm(CustID, Username, Currency,Total)

SELECT  DISTINCT ci.custid, ci.username,ci.currency, (sdiscount+adiscount+discount+playerdiscount) total
FROM	CustSetting3rd cs WITH (NOLOCK)
		INNER JOIN custInfo ci WITH (NOLOCK) ON cs.custid = ci.custid
WHERE	ci.srecommend NOT IN (
			SELECT custid FROM #tmpDummy WITH (NOLOCK)  
		)
		AND ci.currency <> 20
		AND ci.srecommend > 100
		AND cs.sdiscount <> 0.01
		AND ci.roleid = 4
		AND cs.sporttype = 151
		AND cs.bettype BETWEEN 31 AND 52
ORDER BY ci.custid


select *
from #tmpSuperNonComm WITH (NOLOCK)
where TOTAL = 0


--SELECT  DISTINCT ci.srecommend, ci.mrecommend, ci.recommend, ci.custid, ci.username, (sdiscount+adiscount+discount+playerdiscount)
--FROM	CustSetting3rd cs WITH (NOLOCK)
--		INNER JOIN custInfo ci WITH (NOLOCK) ON cs.custid = ci.custid
--WHERE	ci.currency <> 20
--		AND ci.srecommend > 100
--		AND ci.srecommend NOT IN (
--				SELECT custid FROM #tmpDummy WITH (NOLOCK)
--				UNION ALL
--				SELECT custid FROM #tmpSuperNonComm WITH (NOLOCK)
--		)
--		AND cs.sdiscount <> 0.01
--		AND ci.roleid = 1
--		AND cs.sporttype = 151
--		AND cs.bettype BETWEEN 31 AND 52
--ORDER BY ci.custid



---
--Supers of Direct Master  sdiscount = 0 
INSERT INTO #tmpDirectMaster(
	Srecommend,
	Mrecommend,
	Recommend,
	CustID,
	Username,
	Sdiscount,
	adiscount,
	discount,
	total,
	SType 
)

SELECT  DISTINCT ci.srecommend, ci.mrecommend, ci.recommend, 
	ci.custid, ci.username, sdiscount, adiscount, discount, 
	(sdiscount+adiscount+discount+playerdiscount) Total,
	1 
FROM	CustSetting3rd cs WITH (NOLOCK)
		INNER JOIN custInfo ci WITH (NOLOCK) ON cs.custid = ci.custid
WHERE	ci.currency <> 20
		AND ci.srecommend < 100
		AND cs.sdiscount <> 0.01
		--AND (adiscount <> 0.01 OR sdiscount <> 0.01 OR (sdiscount + adiscount) <> 0.02)
		AND ci.roleid = 4
		AND cs.sporttype = 151
		AND cs.bettype BETWEEN 31 AND 52



--Direct Master adiscount = 0 ngoai super o tren 
INSERT INTO #tmpDirectMaster(
	Srecommend,
	Mrecommend,
	Recommend,
	CustID,
	Username,
	Sdiscount,
	adiscount,
	discount,
	total,
	SType 
)

SELECT  DISTINCT ci.srecommend, ci.mrecommend, ci.recommend, 
	ci.custid, ci.username, sdiscount, adiscount, discount, 
	(sdiscount+adiscount+discount+playerdiscount) Total,
	0 
FROM	CustSetting3rd cs WITH (NOLOCK)
		INNER JOIN custInfo ci WITH (NOLOCK) ON cs.custid = ci.custid
WHERE	ci.currency <> 20
		AND ci.srecommend < 100
		AND ci.srecommend NOT IN (SELECT distinct srecommend FROM #tmpDirectMaster with (nolock))
		AND (  cs.adiscount <> 0.01)
		AND ci.roleid = 3
		AND cs.sporttype = 151
		AND cs.bettype BETWEEN 31 AND 52




SELECT  DISTINCT ci.srecommend, ci.mrecommend, ci.recommend, 
	ci.custid, ci.username, sdiscount, adiscount, discount, 
	(sdiscount+adiscount+discount+playerdiscount) Total,
	0 
FROM	CustSetting3rd cs WITH (NOLOCK)
		INNER JOIN custInfo ci WITH (NOLOCK) ON cs.custid = ci.custid
WHERE	ci.currency <> 20
		AND ci.srecommend < 100
		AND ci.srecommend NOT IN (SELECT distinct srecommend FROM #tmpDirectMaster with (nolock))
		AND (  cs.adiscount <> 0.01)
		AND ci.roleid = 1
		AND cs.sporttype = 151
		AND cs.bettype BETWEEN 31 AND 52





--ORDER BY ci.srecommend, ci.mrecommend,ci.custid


DROP TABLE #tmpDummy


DROP TABLE #tmpSuperNonComm

DROP TABLE  #tmpDirectMaster