



--drop table #Agency
--drop table #actAgency
--
CREATE TABLE #Agency (	srecommend INT, 
						mrecommend INT,
						recommend INT,
						roleid INT,
						username VARCHAR(50),
						currency INT
					 )
--GO
CREATE TABLE #actAgency (srecommend INT, mrecommend INT, recommend INT)
GO




------ check direct supers
INSERT INTO #Agency(srecommend, mrecommend, recommend, roleid, username, currency)
		SELECT srecommend, mrecommend, recommend, 4, username, currency
		FROM custinfo WITH(NOLOCK)
		WHERE roleid = 4 AND enabled = 1
			AND custid NOT IN (	SELECT custid     ------- exclude dummy supers
								FROM custinfo WITH(NOLOCK)
								WHERE ((username LIKE '3rdSuper%' OR username LIKE '%AccSuper%' OR username LIKE 'STEST%')
										OR currency = 20
									  )
									  AND roleid = 4
							  )
			AND disable152_UK = 1			
			AND disable152_AU = 1


----- check direct masters
INSERT INTO #Agency(srecommend, mrecommend, recommend, roleid, username, currency)
		SELECT srecommend, mrecommend, recommend, 3, username, currency
		FROM custinfo WITH(NOLOCK)
		WHERE roleid = 3 AND enabled = 1
			AND srecommend IN (SELECT custid FROM custinfo WITH(NOLOCK) WHERE roleid = 4 and custid <= 100)
			AND disable152_UK = 1			
			AND disable152_AU = 1

--- check for direct agents
INSERT INTO #Agency(srecommend, mrecommend, recommend, roleid, username, currency)
		SELECT srecommend, mrecommend, recommend, 2, username, currency
		FROM custinfo WITH(NOLOCK)
		WHERE roleid = 2 AND enabled = 1
			AND mrecommend IN (SELECT custid FROM Acc_CustDirect WITH(NOLOCK) WHERE roleid = 3)
			AND disable152_UK = 1			
			AND disable152_AU = 1

--- agency have bet tickets
---DECLARE @actAgency TABLE (srecommend INT, mrecommend INT, recommend INT)



-----------------------------------------------
--- exclude some agents have racing tickets on these days
DECLARE @GreyhoundLeague TABLE (leagueid INT)

INSERT INTO @GreyhoundLeague 
SELECT l.leagueid
FROM league l WITH(NOLOCK)
WHERE sporttype = 152




--- check from bettrans
INSERT INTO #actAgency(srecommend, mrecommend, recommend)
		SELECT srecommend, mrecommend, recommend
		FROM #Agency a
		WHERE EXISTS (	SELECT 1 FROM bettrans b WITH(NOLOCK)
							INNER JOIN outright o WITH(NOLOCK) ON b.matchid = o.orid
						WHERE b.bettype BETWEEN 31 AND 33 AND o.leagueid IN (SELECT leagueid FROM @GreyhoundLeague)
							AND b.srecommend = a.srecommend
							AND b.mrecommend = a.mrecommend
							AND b.recommend = a.recommend
					)

--- check from bettrans14
INSERT INTO #actAgency(srecommend, mrecommend, recommend)
		SELECT srecommend, mrecommend, recommend
		FROM #Agency a
		WHERE EXISTS (	SELECT 1 FROM bettrans14 b WITH(NOLOCK)
							INNER JOIN outright14 o WITH(NOLOCK) ON b.matchid = o.orid
						WHERE b.bettype BETWEEN 31 AND 33 AND o.leagueid IN (SELECT leagueid FROM @GreyhoundLeague)
							AND b.srecommend = a.srecommend
							AND b.mrecommend = a.mrecommend
							AND b.recommend = a.recommend
					)



GO
/*
check data from bettrans_bk take long time
need to separate this checking
*/
DECLARE @GreyhoundLeague TABLE (leagueid INT)

INSERT INTO @GreyhoundLeague 
SELECT l.leagueid
FROM league l WITH(NOLOCK)
WHERE sporttype = 152

DECLARE @winlostdate DATETIME
SET @winlostdate = '2012-01-01'
--- check from bettrans_bk
INSERT INTO #actAgency(srecommend, mrecommend, recommend)
		SELECT srecommend, mrecommend, recommend
		FROM #Agency a
		WHERE EXISTS (	SELECT 1 FROM bodb_archive.dbo.bettrans_bk b WITH(NOLOCK)
								INNER JOIN bodb_archive.dbo.outright_bk o WITH(NOLOCK) ON b.matchid = o.orid
						WHERE b.bettype BETWEEN 31 AND 33 AND o.leagueid IN (SELECT leagueid FROM @GreyhoundLeague)
							AND b.srecommend = a.srecommend
							AND b.mrecommend = a.mrecommend
							AND b.recommend = a.recommend
						AND winlostdate >= @winlostdate 
					)
			

-- delete active agents from #Agency
DELETE #Agency
FROM #actAgency a
WHERE #Agency.srecommend = a.srecommend AND
	#Agency.mrecommend = a.mrecommend AND
	#Agency.recommend = a.recommend 

/*

*/

---- super list
SELECT c.username, e.currency, CASE WHEN cs3.bettype = 41 THEN 'UK'									
									WHEN cs3.bettype = 51 THEN 'Aust' ELSE '' END AS Partner,
		cs3.minbet, cs3.maxbet, 
		 CASE WHEN cs3.bettype = 41 THEN maxpermatch152_UK				
				WHEN cs3.bettype = 51 THEN maxpermatch152_AU ELSE -1 END AS maxpermatch
FROM #Agency a 
	INNER JOIN custsetting3rd cs3 WITH(NOLOCK) ON a.srecommend = cs3.custid
	INNER JOIN exchange e WITH(NOLOCK) ON a.currency = e.exchangeid
	INNER JOIN custinfo c WITH(NOLOCK) ON c.custid = a.srecommend 
WHERE a.roleid = 4 AND cs3.sporttype = 152 AND cs3.bettype IN (41,51)

----- master list
SELECT c.username, e.currency, CASE WHEN cs3.bettype = 41 THEN 'UK'									
									WHEN cs3.bettype = 51 THEN 'Aust' ELSE '' END AS Partner,
		cs3.minbet, cs3.maxbet, 
		 CASE WHEN cs3.bettype = 41 THEN maxpermatch152_UK				
				WHEN cs3.bettype = 51 THEN maxpermatch152_AU ELSE -1 END AS maxpermatch
FROM #Agency a 
	INNER JOIN custsetting3rd cs3 WITH(NOLOCK) ON a.mrecommend = cs3.custid
	INNER JOIN exchange e WITH(NOLOCK) ON a.currency = e.exchangeid
	INNER JOIN custinfo c WITH(NOLOCK) ON c.custid = a.mrecommend 
WHERE a.roleid = 3 AND cs3.sporttype = 152 AND cs3.bettype IN (41,51)
AND a.srecommend NOT IN (SELECT srecommend FROM #Agency where ROLEID = 4)
-- agent list
SELECT c.username, e.currency, CASE WHEN cs3.bettype = 41 THEN 'UK'									
									WHEN cs3.bettype = 51 THEN 'Aust' ELSE '' END AS Partner,
		cs3.minbet, cs3.maxbet, 
		 CASE WHEN cs3.bettype = 41 THEN maxpermatch152_UK				
				WHEN cs3.bettype = 51 THEN maxpermatch152_AU ELSE -1 END AS maxpermatch
FROM #Agency a 
	INNER JOIN custsetting3rd cs3 WITH(NOLOCK) ON a.recommend = cs3.custid
	INNER JOIN exchange e WITH(NOLOCK) ON a.currency = e.exchangeid
	INNER JOIN custinfo c WITH(NOLOCK) ON c.custid = a.recommend 	
WHERE a.roleid = 2 AND cs3.sporttype = 152 AND cs3.bettype IN (41,51)
AND a.Mrecommend NOT IN (SELECT Mrecommend FROM #Agency where ROLEID = 3)

