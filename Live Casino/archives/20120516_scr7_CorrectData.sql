
CREATE TABLE #LiveCSSetting(custid INT, roleid INT)

INSERT INTO #LiveCSSetting
SELECT c.custid, c.roleid   ---- 8096 rows affected
FROM customer c WITH(NOLOCK)
	LEFT JOIN custsettinggame cg WITH(NOLOCK) ON c.custid = cg.custid
WHERE  c.roleid < 5 --and c.site = '789y'
	AND cg.custid IS NULL

---- Lukas 20120625 correct default discount 
INSERT INTO custsettinggame (CustID,Bettype,Sporttype,apositiontaking,mpositiontaking,spositiontaking,playerdiscount,discount,adiscount,sdiscount,autopositiontaking,isautopositiontaking,autompositiontaking,isautompositiontaking)
SELECT CustID,1101,162,alivepositiontaking,mlivepositiontaking,slivepositiontaking,0,0,0,0,autolivepositiontaking,isautolivepositiontaking,autolivempositiontaking,isautolivempositiontaking
FROM custsetting WITH(NOLOCK)
WHERE custid IN (SELECT custid FROM #LiveCSSetting)			
AND sporttype = 1 AND bettype = 1

WAITFOR DELAY '00:00:05'
GO

INSERT INTO custoverridegame (CustID,Bettype,Sporttype,minpositiontaking)
SELECT CustID,1101,162,minlivepositiontaking
FROM custoverride WITH(NOLOCK)
WHERE custid IN (   --- 520 rows affected
					SELECT c.custid, c.username, c.roleid
					FROM customer c WITH(NOLOCK)
						LEFT JOIN custoverridegame cg WITH(NOLOCK) ON c.custid = cg.custid
					WHERE c.roleid BETWEEN 2 AND 4 --and c.site = '789y'
					AND cg.custid IS NULL
				)			
AND sporttype = 1 AND bettype = 1

WAITFOR DELAY '00:00:05'
GO


UPDATE custsettingGame WITH(ROWLOCK,UPDLOCK)
SET sdiscount = 0.007
WHERE custid IN (SELECT custid FROM #LiveCSSetting WHERE roleid = 1)
---
--- M69EB1924	6247769
UPDATE custsettingGame WITH(ROWLOCK,UPDLOCK) 
SET sdiscount = 0.007,
	adiscount = 0.007
WHERE custid = 6247769