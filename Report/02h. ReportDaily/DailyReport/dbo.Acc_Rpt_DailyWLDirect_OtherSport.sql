ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_OtherSport]
	@winlostdate	datetime
AS
SET NOCOUNT ON

/*	Creator: Phuong Dao
	Date: 2009-02-26
	Task: Winloss Summary History
	DB: DBACC/bodb02
	
	Revisions: 
		- 20090731@Jamie: Not to view data in range of date, but only one date at once 	
		- 20091109@Kiwi: Declare @temp table to contain all matches based on @winlostdate
		-- 20100525@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100917@Henry: Include Number Game
		- 20101204@Johnson: Exclude Number Game
		- 16Dec2010@Viet: Correct Turnover's value, will revert back when old data's gone		
		- 20110824@Elly: Correct Turnover of sports book since Sep 01, 2011
		- 20111202@Sophia: . Add new range for sportbook from 121 to 999
						   . Remove @NegativeBetEffectiveDate
		- 20120412@Hurri: Get win lost of agent 'BARM'
		- 20120530@Elodie: Change formula of 8RM/BARM winloss
		- 20120626@Elodie: check case of matchid = orid
		- 20121009@Elodie: Add 34 new bettypes of Tennis (1301 -> 1334)
		- 20130408@Elodie: Add RealLineTotal field for all products that enable virtual currency
		
*/
	DECLARE @Match TABLE (matchid int, sporttype tinyint, type varchar(10), primary key(matchid, type))
	
	INSERT INTO @Match
	SELECT	m.matchid,
			sp.sporttype SportType,
			m.type
	FROM 
		(	select matchid, leagueid, exrisk, 'match' as type from match with (nolock) where eventdate = @winlostdate
			union all
			select orid, leagueid, 0, 'outright' as type from outright with (nolock) where eventdate = @winlostdate
		) m
	INNER JOIN league l with (nolock) ON m.leagueid = l.leagueid
	INNER JOIN sports sp with (nolock) ON l.sporttype = sp.sporttype
	WHERE sp.sporttype >1
	
	SELECT
			b.liveindicator, 
			m.sporttype SportType,
			sum((winlost-actual_stake)*virtualrate) WinLost,
			sum((awinlost+mwinlost+swinlost)*virtualrate) Position,
			sum(scomm*virtualrate) Commission,	
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) RealLineTotal,
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*virtualrate) VirtualLineTotal,
			sum((1-tpositiontaking)*ABS(stake)*virtualrate) Turnover
	FROM	bettrans b WITH (NOLOCK)
			INNER JOIN @Match m on b.matchid = m.matchid
	WHERE
			b.winlostdate = @winlostdate
			AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR bettype BETWEEN 1301 and 1334)
			AND b.matchid > 0 
			--AND b.status NOT IN ('VOID', 'REJECT','REFUND') 
			AND b.statusID NOT IN (101, 102,103) 
			AND b.ruben = 1		
			AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120626@Elodie: check case of matchid = orid
	GROUP BY
			b.liveindicator, 
			m.sporttype
	ORDER BY
			b.liveindicator, 
			m.sporttype

	select	b.liveindicator, 
			-sum((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm)*virtualrate) Winlost8RM
	FROM	bettrans b WITH (NOLOCK)
			INNER JOIN @Match m on b.matchid = m.matchid
	WHERE
			b.winlostdate = @winlostdate
			AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR bettype BETWEEN 1301 and 1334)
			AND b.matchid > 0
			--AND b.status NOT IN ('VOID', 'REJECT','REFUND') 
			AND b.statusID NOT IN (101, 102,103) 
			AND b.ruben = 1			
			AND b.recommend = 52466
			AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120626@Elodie: check case of matchid = orid
	GROUP BY
			b.liveindicator			

	-- 20120412@Hurri: Get win lost of agent 'BARM'
	select	b.liveindicator, 
			-sum((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm)*virtualrate) WinlostBARM
	FROM	bettrans b WITH (NOLOCK)
			INNER JOIN @Match m on b.matchid = m.matchid
	WHERE
			b.winlostdate = @winlostdate
			AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR bettype BETWEEN 1301 and 1334)
			AND b.matchid > 0
			--AND b.status NOT IN ('VOID', 'REJECT','REFUND') 
			AND b.statusID NOT IN (101, 102,103) 
			AND b.ruben = 1			
			AND b.recommend = 5707545
			AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120626@Elodie: check case of matchid = orid
	GROUP BY
			b.liveindicator		
		
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_OtherSport] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_OtherSport] TO [vnteam]

