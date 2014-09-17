ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Sporttype_OtherSports14]
	@winlostdate	datetime,
	@LineTotal		money OUTPUT
AS
/*	Creator: Elodie
	Date: 2012-07-11
	Task: Daily Winloss Report History for Other sports
	DB: DBACC/bodb02
	Origional: Acc_Rpt_DailyWLDirect_Sporttype14
	 	
	History:
		- 20121009@Elodie: Add 34 new bettypes of Tennis (1301 -> 1334)
		- 20130408@Elodie: Add RealLineTotal field for all products that enable virtual currency
		- 20130522@Elodie: Get more fields RealTurnover, VirtualTurnover
		- 20130802@Johnson: Separate win loss by credit/deposit site(1: credit, 2: deposit)	
		- 20140917@Johnson: hardcode sporttype for others is 3
	Explanation's Param:
		
*/
SET NOCOUNT ON

--Declare @temp table to contain all matches based on @winlostdate
DECLARE @Match TABLE (matchid INT, sporttype smallint, type varchar(10), primary key(matchid, type))
CREATE TABLE #DepAgent (custid int primary key)
	
INSERT INTO #DepAgent 
SELECT custid
FROM custInfo with(NOLOCK)
WHERE srecommend IN (SELECT custid FROM f_DepSuper_1('All'))
	AND roleid = 2
UNION
SELECT 5707545--BARM
	
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
WHERE s.SportType > 1 --Get matchs of Other sports

SELECT
		'Other Sports' as SportName,
		3 as SportType,		
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
WHERE	b.winlostdate = @winlostdate
		AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR b.bettype BETWEEN 1301 and 1334) -- bettype of sportbook
		AND b.matchid > 0		
		AND b.statusID NOT IN (101, 102,103) --('VOID', 'REJECT','REFUND')
		AND b.ruben = 1	
		AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
GROUP BY	
		case when m.sporttype> 1 then 3 else 1 end,
		case when dep.custid is null then 1 else 2 end

-- Get win lost of agent '8RM'
UNION ALL
SELECT
		'Other Sports' as SportName,
		3 as SportType,		
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
WHERE	b.winlostdate = @winlostdate
		AND b.matchid > 0 
		AND b.bettype < 19001
		AND b.statusID NOT IN (101, 102,103) 
		AND b.ruben = 1	
		AND b.recommend = 52466
		AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
GROUP BY	
		case when m.sporttype> 1 then 3 else 1 end
		
-- Get win lost of agent 'BARM'
UNION ALL
SELECT
		'Other Sports' as SportName,
		3 as SportType,			
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
WHERE	b.winlostdate = @winlostdate
		AND b.matchid > 0 
		AND b.bettype < 19001
		AND b.statusID NOT IN (101, 102,103) 
		AND b.ruben = 1	
		AND b.recommend = 5707545
		AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
GROUP BY	
		case when m.sporttype> 1 then 3 else 1 end
		
SELECT	@LineTotal = isnull(sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate), 0) 
FROM	bettrans14 b WITH (NOLOCK)
		INNER JOIN @Match m on b.matchid = m.matchid
WHERE
		winlostdate = @winlostdate
		AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR b.bettype BETWEEN 1301 and 1334) -- bettype of sportbook
		AND b.matchid >=0 
		AND b.statusID NOT IN (101, 102,103,121) --('VOID', 'REJECT','DONE','REFUND') 
		AND b.ruben = 1	
		AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid

DROP TABLE #DepAgent

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Sporttype_OtherSports14] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_Sporttype_OtherSports14] TO [vnteam]		
 