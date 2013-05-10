 ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Sporttype_Soccer]
	@winlostdate	datetime,
	@LineTotal		money OUTPUT
AS
/*	Creator: Elodie
	Date: 2012-07-11
	Task: Daily Winloss Report for Soccer
	DB: DBACC/bodb02	
	Origional: Acc_Rpt_DailyWLDirect_Sporttype
	 	
	History:
		- 20130408@Elodie: Add RealLineTotal field for all products that enable virtual currency
		
	Explanation's Param:
		
*/
SET NOCOUNT ON

--Declare @temp table to contain all matches based on @winlostdate
DECLARE @Match TABLE (matchid INT, sporttype smallint, type varchar(10), primary key(matchid, type))

INSERT INTO @Match 
SELECT	m.matchid, 
		s.sporttype,
		m.type
FROM (
		SELECT matchid, leagueid, exrisk, matchcode, 'match' as type FROM match WITH (NOLOCK) WHERE eventdate = @winlostdate
		UNION ALL
		SELECT orid, leagueid, 0, matchcode, 'outright' as type FROM outright WITH (NOLOCK) WHERE eventdate = @winlostdate
		)m	
		INNER JOIN league l WITH (NOLOCK) ON m.leagueid = l.leagueid	
		INNER JOIN Sports s WITH (NOLOCK) ON l.sporttype = s.sporttype 
WHERE s.SportType = 1 --Get matchs of Soccer

SELECT
		'Soccer' as SportName,
		1 as SportType,		
		0 ibc,
		sum((winlost-actual_stake)*virtualrate) WinLost,
		sum((awinlost+mwinlost+swinlost)*virtualrate) Position,
		sum(scomm*virtualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) RealLineTotal,
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*virtualrate) VirtualLineTotal,
		sum((1-tpositiontaking)*ABS(stake)*virtualrate) Turnover
FROM	bettrans b WITH (NOLOCK)
		INNER JOIN @Match m on b.matchid = m.matchid
WHERE	b.winlostdate = @winlostdate
		AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999)
		AND b.matchid > 0		
		AND b.statusID NOT IN (101, 102,103) 
		AND b.ruben = 1	
		AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
GROUP BY m.sporttype

-- Get win lost of agent '8RM'
UNION ALL
SELECT
		'Soccer' as SportName,
		1 as SportType,	
		1 ibc,
		-sum(winlost-actual_stake) WinLost,
		-sum(awinlost+mwinlost+swinlost) Position,
		sum(scomm) Commission,	
		-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) RealLineTotal,
		-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) VirtualLineTotal,
		-sum((1-tpositiontaking)*ABS(stake)) Turnover
FROM	bettrans b WITH (NOLOCK)
		INNER JOIN @Match m on b.matchid = m.matchid
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
	-sum(winlost-actual_stake) WinLost,
	-sum(awinlost+mwinlost+swinlost) Position,
	sum(scomm) Commission,	
	-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) RealLineTotal,
	-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) VirtualLineTotal,
	-sum((1-tpositiontaking)*ABS(stake)) Turnover
FROM	bettrans b WITH (NOLOCK)
		INNER JOIN @Match m on b.matchid = m.matchid
WHERE	b.winlostdate = @winlostdate
	AND b.matchid > 0 
	AND b.bettype < 19001
	AND b.statusID NOT IN (101, 102,103) 
	AND b.ruben = 1	
	AND b.recommend = 5707545
	AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
GROUP BY m.sporttype
	
SELECT	@LineTotal = isnull(sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate), 0) 
FROM	bettrans b WITH (NOLOCK)
		INNER JOIN @Match m on b.matchid = m.matchid
WHERE
		winlostdate = @winlostdate
		AND bettype < 19001 
		AND b.matchid >=0 
		AND b.statusID NOT IN (101, 102,103,121) --('VOID', 'REJECT','DONE','REFUND') 
		AND b.ruben = 1	
		AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
	
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Sporttype_Soccer] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_Sporttype_Soccer] TO [vnteam]		
