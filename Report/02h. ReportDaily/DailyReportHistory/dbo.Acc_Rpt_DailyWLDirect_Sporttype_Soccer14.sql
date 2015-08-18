ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Sporttype_Soccer14]
	@winlostdate	datetime,
	@SoccerType		TINYINT = 0,
	@LineTotal		money OUTPUT,
	@IncludeBettype VARCHAR(MAX) = ''
AS
/*	Creator: Elodie
	Date: 2012-07-11
	Task: Daily Winloss Report History for Soccer
	DB: DBACC/bodb02	
	Origional: Acc_Rpt_DailyWLDirect_Sporttype14
	 	
	History:
		- 20130408@Elodie: Add RealLineTotal field for all products that enable virtual currency
		- 20130522@Elodie: Get more fields RealTurnover, VirtualTurnover
		- 20130802@Johnson: Separate win loss by credit/deposit site(1: credit, 2: deposit)	
		- 20140711@Johnson: Separate major and minor bettypes of soccer		
		- 20140930@Johnson: Add new report for soccer minor bettype
		- 20141111@Johnson: include additional bettypes into report
		- 20150204@Johnson: move 1H Double Chance bet type to major bettype [RedmineID: #27216]
		- 20150525@Sophia: Apply Metric Gaming - SuperLive and Sport Betype Matrix [#35359]
	Explanation's Param:
		- @SoccerType =	 0: All bettype(major and minor bettype)
					= 1: report soccer for major bettype
					= 2: report soccer for minor bettype
		- @IncludeBettype: include more bettypes in some specific cases(minor bettypes soccer get some major bettypes)
*/
SET NOCOUNT ON

--Declare @temp table to contain all matches based on @winlostdate
DECLARE @Match TABLE (matchid INT, sporttype smallint, type varchar(10), primary key(matchid, type))
CREATE TABLE #DepAgent (custid int primary key)
DECLARE @Bettype TABLE(bettype int, soccerType INT)
	
INSERT INTO #DepAgent 
SELECT custid
FROM custInfo with(NOLOCK)
WHERE srecommend IN (SELECT custid FROM f_DepSuper_1('All'))
	AND roleid = 2
UNION
SELECT 5707545--BARM

----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT,SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode = 5, @SportType  = 1

	
INSERT INTO @Bettype(bettype,soccerType)
SELECT typeid, CASE WHEN typeid IN (1,2,3,5,6,7,8,12,15,24,25,28,121,122,123,126,151) THEN 1 ELSE 2 END as SoccerType
FROM bettype b WITH(NOLOCK)
INNER JOIN @SportBettype s 
		ON s.bettype = b.typeid
WHERE ---(typeid < 31 OR typeid BETWEEN 121 AND 999)
	s.EventType IN (1,2)
	AND s.SubProduct NOT IN ('MG-SuperLive')
	AND 1 = CASE WHEN @SoccerType = 0 THEN 1 
				WHEN @SoccerType = 1 AND typeid IN (1,2,3,5,6,7,8,12,15,24,25,28,121,122,123,126,151) THEN 1 
				WHEN @SoccerType = 2 AND typeid NOT IN (1,2,3,5,6,7,8,12,15,24,25,28,121,122,123,126,151) THEN 1 
				ELSE 0 END							

IF ISNULL(@IncludeBettype,'')<>'' AND @soccerType <> 0
BEGIN
	INSERT INTO @Bettype(bettype,soccerType)
		SELECT val, @soccerType
		FROM strSPlit(@IncludeBettype,',')
END
			
INSERT INTO @Match 
SELECT	m.matchid, 
		s.sporttype,
		m.type
FROM (
		SELECT matchid, leagueid, exrisk, matchcode, 'match' as type FROM match14 WITH (NOLOCK) WHERE eventdate = @winlostdate
		UNION ALL
		SELECT orid, leagueid, 0, matchcode, 'outright' as type FROM outright14 WITH (NOLOCK) WHERE eventdate = @winlostdate
		)m	
INNER JOIN league l WITH (NOLOCK) ON m.leagueid = l.leagueid	
INNER JOIN Sports s WITH (NOLOCK) ON l.sporttype = s.sporttype
WHERE s.SportType = 1 --Get matchs of Soccer

SELECT
		CASE WHEN t.soccerType = 1 THEN 'Soccer-Major Bet Types' ELSE 'Soccer-Minor Bet Types' END as SportName,
		t.soccerType as SportType,						
		0 ibc,
		case when dep.custid is null then 1 else 2 end as site,
		sum((winlost-actual_stake)*virtualrate) WinLost,
		sum((awinlost+mwinlost+swinlost)*virtualrate) Position,
		sum(scomm*virtualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) RealLineTotal,
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*virtualrate) VirtualLineTotal,
		sum((1-tpositiontaking)*ABS(stake)*actualrate) RealTurnover,
		sum((1-tpositiontaking)*ABS(stake)*virtualrate) VirtualTurnover
FROM	bettrans14 b WITH (NOLOCK)
		INNER JOIN @Match m on b.matchid = m.matchid
		LEFT JOIN (select custid from #DepAgent) dep ON b.recommend = dep.custid		
		INNER JOIN @Bettype t ON b.bettype = t.bettype
WHERE	b.winlostdate = @winlostdate
		--AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999)		
		AND b.matchid > 0		
		AND b.statusID NOT IN (101, 102,103) 
		AND b.ruben = 1	
		AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
GROUP BY CASE WHEN t.soccerType = 1 THEN 'Soccer-Major Bet Types' ELSE 'Soccer-Minor Bet Types' END,
		t.soccerType,		
		case when dep.custid is null then 1 else 2 end

-- Get win lost of agent '8RM'
UNION ALL
SELECT
		'Soccer' as SportName,
		1 as SportType,	
		1 ibc,
		0 as site,
		-sum(winlost-actual_stake) WinLost,
		-sum(awinlost+mwinlost+swinlost) Position,
		sum(scomm) Commission,	
		-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) RealLineTotal,
		-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) VirtualLineTotal,
		-sum((1-tpositiontaking)*ABS(stake)) RealTurnover,
		-sum((1-tpositiontaking)*ABS(stake)) VirtualTurnover
FROM	bettrans14 b WITH (NOLOCK)
		INNER JOIN @Match m on b.matchid = m.matchid
		INNER JOIN @Bettype t ON b.bettype = t.bettype
WHERE	b.winlostdate = @winlostdate
		AND b.matchid > 0 
		AND b.bettype < 19001
		AND b.statusID NOT IN (101, 102,103) 
		AND b.ruben = 1	
		AND b.recommend = 52466
		AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
GROUP BY m.sporttype

-- Get win lost of agent 'BARM'
UNION ALL
SELECT
	'Soccer' as SportName,
	1 as SportType,	
	2 ibc,
	0 as site,
	-sum(winlost-actual_stake) WinLost,
	-sum(awinlost+mwinlost+swinlost) Position,
	sum(scomm) Commission,	
	-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) RealLineTotal,
	-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) VirtualLineTotal,
	-sum((1-tpositiontaking)*ABS(stake)) RealTurnover,
	-sum((1-tpositiontaking)*ABS(stake)) VirtualTurnover
FROM	bettrans14 b WITH (NOLOCK)
		INNER JOIN @Match m on b.matchid = m.matchid
		INNER JOIN @Bettype t ON b.bettype = t.bettype
WHERE	b.winlostdate = @winlostdate
	AND b.matchid > 0 
	AND b.bettype < 19001
	AND b.statusID NOT IN (101, 102,103) 
	AND b.ruben = 1	
	AND b.recommend = 5707545
	AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
GROUP BY m.sporttype
ORDER BY SportType

SELECT	@LineTotal = isnull(sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate), 0) 
FROM	bettrans14 b WITH (NOLOCK)
		INNER JOIN @Match m on b.matchid = m.matchid
		INNER JOIN @Bettype t ON b.bettype = t.bettype
WHERE
		winlostdate = @winlostdate
		AND b.bettype < 19001 
		AND b.matchid >=0 
		AND b.statusID NOT IN (101, 102,103,121) --('VOID', 'REJECT','DONE','REFUND') 
		AND b.ruben = 1	
		AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid

DROP TABLE #DepAgent



	
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Sporttype_Soccer14] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_Sporttype_Soccer14] TO [vnteam]
 