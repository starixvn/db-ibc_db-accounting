USE bodb02
GO
ALTER PROCEDURE dbo.NAP_Set_AutoPayout_WaitingSel @SportType SMALLINT = 0
	, @LeagueId INT = 0 -- 0 for ALL Leagues
AS
/*
	Created: 20160314@Patrick
	Task: Autop payout - Get status for a match
	DB: DBTXN/BODB02
	Original:
		NAP_Set_WaitingSel
	
	Revision:
	Param's explanation:  
		
*/
BEGIN

	SET NOCOUNT ON 
	DECLARE @Today DATETIME
	SELECT @LeagueID = ISNULL(@LeagueID, 0), @SportType = ISNULL(@SportType, 0), @Today = GETDATE() 

	SET @Today = DATEADD(HH, -1, @Today)

	;WITH SingleTicket AS (
		SELECT matchid, MIN(IsCalculating) AS IsCalculating
		FROM dbo.Single_Calculate_Queue s WITH(NOLOCK)
		WHERE Starttime > @Today
		GROUP BY matchid 
	), ParlayTicket AS (
		SELECT p.matchid, MIN(IsCalculating) AS IsCalculating
		FROM dbo.Parlay_Calculate_Queue p WITH(NOLOCK)
		WHERE Starttime > @Today
		GROUP BY matchid 
	)	
	SELECT ISNULL(sg.matchid, pl.matchid) AS MatchId
		, sg.IsCalculating AS SingleStatus
		, pl.IsCalculating AS ParlayStatus
		, CAST(ISNULL(sg.IsCalculating, 0) AS BIT) AS IsSingle
		, CAST(ISNULL(pl.IsCalculating, 0) AS BIT) AS IsMixParlay
	INTO #tempmatch
	FROM SingleTicket sg
		FULL OUTER JOIN ParlayTicket pl on sg.matchid = pl.matchid

	CREATE TABLE #tmpAutoSettle1s(MatchID INT, ResultStatusID TINYINT)
	INSERT INTO #tmpAutoSettle1s(MatchID, ResultStatusID)
	SELECT MatchID, MIN(ResultStatusID)
	FROM DBPRO.bodb02.dbo.ResultDetail rs WITH (NOLOCK)
	WHERE @Sporttype IN(0, 1)
		AND EXISTS (SELECT TOP 1 1 FROM #tempmatch t WHERE rs.MatchId = t.MatchId)
		AND (ResourceID IN ('135','168','173','174','175','176','192','193','210','211','212','213','214','215','216','217')
				OR ResourceID LIKE '160__'
				OR ResourceID LIKE '164__'
				OR ResourceID LIKE '169__'
				OR ResourceID LIKE '180__'
				OR ResourceID LIKE '216__')
	GROUP BY MatchID

	;WITH BetStatus AS (
		SELECT b.matchid
			, SUM(CASE WHEN b.bettype = 14 THEN 1 ELSE 0 END) AS IsExistFGLG
			, SUM(CASE WHEN b.bettype = 127 THEN 1 ELSE 0 END) AS IsExistHTFGLG
			, SUM(CASE WHEN b.bettype = 172 THEN 1 ELSE 0 END) AS IsExistResultandFirstTeamScore
			, SUM(CASE WHEN b.bettype IN (194, 195, 196, 197, 198, 199, 206, 208) THEN 1 ELSE 0 END) AS IsExistCorner
			, SUM(CASE WHEN b.bettype IN (200, 201, 202, 203, 204, 205, 207, 209) THEN 1 ELSE 0 END) AS IsExistHTCorner
		FROM dbo.bettrans b 
		WHERE EXISTS (SELECT TOP 1 1 FROM #tempmatch t WHERE b.matchid = t.matchid)
			AND bettype IN (14, 127)--FGLG
			AND bettype IN (194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209) --Corner
			AND bettype IN (172) --ExistResultandFirstTeamScore
			AND StatusId NOT IN (101, 102, 103)
		GROUP BY b.matchid
	), BetStatusM AS (
		SELECT b.matchid
			, SUM(CASE WHEN b.bettype = 14 THEN 1 ELSE 0 END) AS IsExistFGLG
			, SUM(CASE WHEN b.bettype = 127 THEN 1 ELSE 0 END) AS IsExistHTFGLG
		FROM dbo.bettrans b 
		WHERE EXISTS (SELECT TOP 1 1 FROM #tempmatch t WHERE b.matchid = t.matchid)
			AND bettype IN (14, 127)--FGLG
			AND StatusId NOT IN (101, 102, 103)
		GROUP BY b.matchid
	), PayoutResult AS (
		SELECT rs.MatchId
			, MAX(CASE WHEN rs.CalculationType = 1 THEN 1 ELSE 0 END) AS HTStatus
			, MAX(CASE WHEN rs.CalculationType = 2 THEN 1 ELSE 0 END) AS FTStatus
		FROM dbo.AutoPayoutResult rs WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM #tempmatch t WHERE rs.MatchId = t.matchid)
			AND StatusId IN (1, 2)
		GROUP BY rs.MatchId
	)

	SELECT tm.matchid
		, leagueid
		, hthomescore AS HalfTimeHomeScore
		, htawayscore AS HalfTimeAwayScore
		, ISNULL(mr.calculate, 0) AS IsCalculated
		, ISNULL(mr.multiple, 0) AS IsMultiCaled
		, ISNULL(mr.refund, 0) AS IsRefund
		, ISNULL(mr.calrefund, 0) AS IsCalRefund
		, homeid
		, awayid
		, matchcode
		, finalhomescore
		, finalawayscore
		, betstatus
		, CASE WHEN m.betstatus LIKE 'Refund FT%' THEN 'Refund FT'  
				WHEN m.betstatus LIKE 'Refund HT%' THEN 'Refund HT'  
				WHEN m.betstatus LIKE 'Refund%' THEN 'Refund'  
			ELSE m.eventstatus END AS eventstatus
		, ISNULL(mr.SettlementStatus135, 0) AS SettlementStatus135
		, sporttype
		, ISNULL(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
		, goalrecord
		, ISNULL(mr.IsHTCal, 0) AS IsHalfTimeCal
		, isPending
		, isUndecided
		, CAST(CASE WHEN hthomescore IS NOT NULL 
						AND htawayscore IS NOT NULL 
						AND finalhomescore IS NOT NULL 
						AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore
		, CASE WHEN ISNULL(b.IsExistFGLG, 0) > 0 OR ISNULL(bm.IsExistFGLG, 0) > 0 THEN 1 ELSE 0 END AS IsExistFGLG
		, CASE WHEN ISNULL(b.IsExistHTFGLG, 0) > 0 OR ISNULL(bm.IsExistHTFGLG, 0) > 0 THEN 1 ELSE 0 END AS IsExistHTFGLG
		, CASE WHEN ISNULL(b.IsExistCorner, 0) > 0 THEN 1 ELSE 0 END AS IsExistCorner
		, CASE WHEN ISNULL(b.IsExistHTCorner, 0) > 0 THEN 1 ELSE 0 END AS IsExistHTCorner
		, tm.SingleStatus AS IsCalculatingSingle
		, tm.ParlayStatus AS IsCalculatingMP
		, CASE WHEN a.ResultStatusID IS NULL THEN 'N/A'
				WHEN a.ResultStatusID IN(0,1,3) THEN 'Running'
				WHEN a.ResultStatusID IN (2,5) THEN 'Completed'
			ELSE '' END AS AutoSettleResultStatus
		--, CASE WHEN (ISNULL(mr.IsHTCal, 0) = 1 OR ISNULL(tm.SingleStatus, -1) IN (0,1) OR ISNULL(tm.ParlayStatus, -1) IN (0,1))
		--			AND (b.IsExistHTFGLG = 1 OR bm.IsExistHTFGLG = 1)
		--			AND ISNULL(mr.calculate, 0) = 0 THEN 1 --can calc HT FGLG
		--		WHEN (ISNULL(mr.calculate, 0) = 1 OR ISNULL(tm.SingleStatus, 0) IN (0,1) OR ISNULL(tm.ParlayStatus, -1) IN (0,1))
		--			AND (b.IsExistFGLG = 1 OR bm.IsExistFGLG = 1 OR b.IsExistResultandFirstTeamScore = 1)
		--			AND ISNULL(mr.IsHTCal, 0) = 1 THEN 1 --can calc FT FGLG
		--	ELSE 0 END AS IsNeedToCalculateFGLG
		--, CASE WHEN (ISNULL(mr.IsHTCal, 0) = 1 OR ISNULL(tm.SingleStatus, -1) IN (0,1) OR ISNULL(tm.ParlayStatus, -1) IN (0,1))
		--			AND b.IsExistHTCorner = 1 AND ISNULL(mr.calculate, 0) = 0 THEN 1 --can calc HT Corner
		--		WHEN (ISNULL(mr.calculate, 0) = 1 OR ISNULL(tm.SingleStatus, -1) IN (0,1) OR ISNULL(tm.ParlayStatus, -1) IN (0,1))
		--			AND ISNULL(mr.IsHTCal, 0) = 1 AND b.IsExistCorner = 1 THEN 1 --can calc FT Corner
		--	ELSE 0 END AS IsNeedToCalculateCorner

		, CASE WHEN rs.MatchId IS NOT NULL
					AND rs.HTStatus = 1 
					AND mr.IsHTCal = 1 
					AND rs.FTStatus IN (0,1)
					AND (ISNULL(b.IsExistHTFGLG, 0) > 0 OR ISNULL(bm.IsExistHTFGLG, 0) > 0) THEN 1 --can calc HT FGLG
				WHEN rs.MatchId IS NOT NULL
					AND rs.FTStatus = 1
					AND (ISNULL(b.IsExistFGLG, 0) > 0  OR ISNULL(bm.IsExistFGLG, 0) > 0 
							OR ISNULL(IsExistResultandFirstTeamScore, 0) > 0) THEN 1 --can calc FT FGLG
			ELSE 0 END AS IsNeedToCalculateFGLG
		, CASE WHEN rs.MatchId IS NOT NULL
					AND rs.HTStatus IN (0,1) 
					AND mr.IsHTCal = 1
					AND rs.FTStatus = 0
					AND ISNULL(b.IsExistHTCorner, 0) > 0 THEN 1 --can calc HT Corner
				WHEN rs.MatchId IS NOT NULL
					AND rs.FTStatus = 1
					AND ISNULL(b.IsExistCorner, 0) > 0 THEN 1 --can calc FT Corner
			ELSE 0 END AS IsNeedToCalculateCorner
	FROM #tempmatch tm
		INNER JOIN DBPRO.bodb02.dbo.match m with(NOLOCK) ON tm.matchid = m.matchid
		INNER JOIN DBPRO.bodb02.dbo.match_remark mr WITH(NOLOCK) ON tm.matchid = mr.matchid
		LEFT JOIN #tmpAutoSettle1s a WITH (NOLOCK) ON tm.matchID = a.MatchID
		LEFT JOIN BetStatus b ON tm.matchid = b.matchid
		LEFT JOIN BetStatusM bm ON tm.matchid = bm.matchid
		LEFT JOIN PayoutResult rs ON tm.matchid = rs.matchid
	WHERE m.leagueID = CASE WHEN @LeagueID <> 0 THEN @LeagueID ELSE m.leagueID END
		AND m.sporttype = CASE WHEN @sporttype = 0 THEN m.sporttype ELSE @sporttype END
END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_AutoPayout_WaitingSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_AutoPayout_WaitingSel] TO [vnteam] AS [dbo]