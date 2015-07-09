--1. Step 1: Create a temp transaction table 

CREATE TABLE #tmpbettrans (
			transid bigint primary key
			,refno bigint
			,custid int
			,username nvarchar(30)
			,statusid tinyint
			,combo tinyint
		)

--2. Step 2: Add parlay tickets into #tmpbettrans 		
	
 DECLARE @fromdate DATETIME,
		@todate DATETIME

SELECT @fromdate = '2012-11-01', @todate = '2012-11-01'

INSERT INTO #tmpbettrans (transid,refno,custid,statusid,combo)
SELECT transid,refno,custid,statusID,RIGHT(betcheck,len(betcheck)-1)
FROM bodb_archive.dbo.bettrans_bk WITH(NOLOCK,INDEX = CIX_winlostdate)
WHERE winlostdate BETWEEN @fromdate and @todate
	AND matchid = 9


--3. Add into rmTransaction 

INSERT INTO DB054.bodb_RMS.dbo.rmTransaction (transid,refno,custid,combo)

SELECT transid,refno,custid,combo
FROM #tmpbettrans WITH (NOLOCK)

--4. Update username of #tmpbettrans

update b
set b.username = c.username
from #tmpbettrans b
	INNER JOIN custInfo c WITH(NOLOCK) ON b.custid = c.custid

--5. Add rmSumWinloss 
INSERT INTO DB054.bodb_RMS.dbo.rmSumWinloss (winlostdate
				,custid
				,sporttype
				,statusid
				,username
				,currency
				,stake
				,winlost
				,company_stake
				,company_winlost
				,actualrate
				,odds
				,betcount)

SELECT b.winlostdate
		,mt.custid
		,liveawayscore
		,mt.statusid
		,isnull(mt.username,'')
		,currency
		,SUM(stake)
		,SUM(winlost)
		,SUM(stake*(1-tpositiontaking))
		,SUM(-(winlost-stake)*(1-tpositiontaking))
		,actualrate
		,SUM(modds)
		,count(1)
FROM #tmpbettrans mt 
	INNER JOIN bodb_archive.dbo.bettrans_bk b WITH(NOLOCK,INDEX = IX_transid) ON b.transid = mt.transid
WHERE mt.statusid IN (111,112,113)
GROUP BY winlostdate, mt.custid, liveawayscore, mt.statusid, mt.username, currency, actualrate



