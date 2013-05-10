ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_MixParlay]
	@winlostdate	datetime,
	@bettype		int
AS


/*	Creator: Phuong Dao
	Date: 2009-03-03
	Task: Winloss Summary History
	DB: DB06.bodb02

	Revisions:
		- 20090731@Jamie: 
			+ Break out Mix-Parlay into Soccer and Others 
			+ Not to view data in range of date, but only one date at once 
		- 20100330@Jamie: Add one more row for Parlay - Multiple Sports
		-- 20100525@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100611@Henry: Change mix-parlay match from 0 to 9
		- 16Dec2010@Viet: Correct Turnover's value, will revert back when old data's gone
		- 20110801@Johnson:  add new bettype mix-parlay combination
		- 20110824@Johnson: remove check winlostdate with '16 Dec 2010' for sumary turnover, get from stake instead actual_stake
		- 20110824@Elly: - Correct Turnover of sports book since Sep 01, 2011
		- 20120210@Henry: Fix system parlay turnover bug
		
	
	- Parameter's Explanation:
		- @bettype - 9 : mix-parlay
					- 29: combination mix-parlay	
*/
SET NOCOUNT ON 


CREATE TABLE #tmpMixSports( refno BIGINT )
DECLARE @tmpOtherSports TABLE( refno BIGINT)
DECLARE @_matchid INT

IF @bettype = 9 
	SELECT @_matchid = 9
ELSE IF @bettype = 29 
	SELECT @_matchid = 29
	

INSERT INTO #tmpMixSports(refno)
SELECT	refno 
FROM(
		SELECT DISTINCT m.sporttype, bm.refno 
		FROM	bettransm bm WITH (NOLOCK)
				INNER JOIN match m WITH (NOLOCK) ON bm.matchid = m.matchid 
		WHERE	refno IN( 
			SELECT	refno
			FROM	bettrans WITH (NOLOCK)
			WHERE	
					bettype = @bettype
					AND matchid = @_matchid
					--AND matchid = 0 					
					AND ruben = 1 
					--AND status NOT IN ('VOID','REJECT','REFUND')
					AND statusID NOT IN (101,102,103)
					AND winlostdate = @winlostdate
		)
		UNION 
		SELECT DISTINCT m14.sporttype, bm14.refno
		FROM	bettransm14 bm14 WITH (NOLOCK)
				INNER JOIN match14 m14 WITH (NOLOCK) ON bm14.matchid = m14.matchid 
		WHERE	refno IN (
			SELECT	refno
			FROM	bettrans WITH (NOLOCK)
			WHERE	bettype = @bettype
					AND matchid = @_matchid
					AND ruben = 1 
					--AND status NOT IN ('VOID','REJECT','REFUND')
					AND statusID NOT IN (101,102,103)
					AND winlostdate = @winlostdate
		)	
) s
GROUP BY refno 
HAVING COUNT(refno) > 1 	

INSERT INTO @tmpOtherSports( refno)
SELECT	refno 
FROM(
		SELECT DISTINCT m.sporttype, bm.refno 
		FROM	bettransm bm WITH (NOLOCK)
				INNER JOIN match m WITH (NOLOCK) ON bm.matchid = m.matchid 
		WHERE	refno IN( 
			SELECT	refno
			FROM	bettrans WITH (NOLOCK)
			WHERE	bettype = @bettype
					AND matchid = @_matchid
					AND ruben = 1 
					--AND status NOT IN ('VOID','REJECT','REFUND')
					AND statusID NOT IN (101,102,103)
					AND winlostdate = @winlostdate
		)
		UNION 
		SELECT DISTINCT m14.sporttype, bm14.refno
		FROM	bettransm14 bm14 WITH (NOLOCK)
				INNER JOIN match14 m14 WITH (NOLOCK) ON bm14.matchid = m14.matchid 
		WHERE	refno IN (
			SELECT	refno
			FROM	bettrans WITH (NOLOCK)
			WHERE	bettype = @bettype
					AND matchid = @_matchid
					AND ruben = 1 
					--AND status NOT IN ('VOID','REJECT','REFUND')
					AND statusID NOT IN (101,102,103)
					AND winlostdate = @winlostdate
		)	
) o
WHERE sporttype <> 1 
AND refno NOT IN (SELECT refno FROM #tmpMixSports with (NOLOCK))


SELECT  @bettype bettype, status, 98 sporttype,
		sum((winlost-actual_stake)*virtualrate) WinLost,
		sum((awinlost+mwinlost+swinlost)*virtualrate) Position,
		sum(scomm*virtualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*virtualrate) LineTotal,
		sum((1-tpositiontaking)*ABS(case when bettype=29 and betid>0 then  actual_stake else stake end)*virtualrate) Turnover
		
FROM	bettrans WITH (NOLOCK)
		INNER JOIN #tmpMixSports m WITH (NOLOCK) ON bettrans.refno = m.refno 
WHERE
		bettrans.ruben=1 and
		bettype = @bettype AND
		matchid = @_matchid AND 
		bettrans.winlostdate = @winlostdate AND
		--bettrans.matchid=0	
		--and bettrans.status NOT IN ('VOID','REJECT','REFUND')
		bettrans.statusID NOT IN (101,102,103)
GROUP BY status 
UNION ALL
SELECT 
		@bettype bettype, status, 1 sporttype,
		sum((winlost-actual_stake)*virtualrate) WinLost,
		sum((awinlost+mwinlost+swinlost)*virtualrate) Position,
		sum(scomm*virtualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*virtualrate) LineTotal,
		sum((1-tpositiontaking)*ABS(case when bettype=29 and betid>0 then  actual_stake else stake end)*virtualrate) Turnover
FROM	bettrans WITH (NOLOCK)
WHERE
		bettrans.ruben=1 AND
		bettype = @bettype AND
		matchid = @_matchid AND 
		bettrans.winlostdate = @winlostdate AND
		--bettrans.matchid=0	
		--and bettrans.status NOT IN ('VOID','REJECT','REFUND')
		bettrans.statusID NOT IN (101,102,103)
		and refno NOT IN (
			SELECT refno FROM #tmpMixSports WITH (NOLOCK) 
			UNION 
			SELECT refno FROM @tmpOtherSports 
		)
GROUP BY status 
UNION ALL 
SELECT 
		@bettype bettype, status, 99 sporttype,
		sum((winlost-actual_stake)*virtualrate) WinLost,
		sum((awinlost+mwinlost+swinlost)*virtualrate) Position,
		sum(scomm*virtualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*virtualrate) LineTotal,
		sum((1-tpositiontaking)*ABS(case when bettype=29 and betid>0 then  actual_stake else stake end)*virtualrate) Turnover
FROM	bettrans WITH (NOLOCK)
WHERE	bettrans.ruben=1 AND
		bettype = @bettype AND
		matchid = @_matchid AND 
		bettrans.winlostdate = @winlostdate AND
		--bettrans.matchid=0
		--and bettrans.status NOT IN ('VOID','REJECT','REFUND')
		bettrans.statusID NOT IN (101,102,103)
		and bettrans.refno IN (SELECT refno FROM @tmpOtherSports)
GROUP BY status 

DROP TABLE #tmpMixSports
	-------------------
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_MixParlay] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_MixParlay] TO [vnteam]