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
		- 20160713@Patrick: PH-AIO phase 2 (67 bettypes ) [Redmine:#53154]

	Param's explanation: 
		
*/
BEGIN

	SET NOCOUNT ON 
	DECLARE @Today DATETIME, @RowId INT, @Count INT
	SELECT @LeagueID = ISNULL(@LeagueID, 0), @SportType = ISNULL(@SportType, 0), @Today = GETDATE(), @RowId = 0

	SET @Today = DATEADD(HH, -1, @Today)

	CREATE TABLE #MatchInQueue (RowId INT IDENTITY(1,1), MatchId INT, SingleStatus INT, ParlayStatus INT, IsSingle BIT, IsMixParlay BIT, IsInQueue BIT)

	;WITH SingleTicket AS (
		SELECT matchid, MIN(IsCalculating) AS IsCalculating
		FROM dbo.Single_Calculate_Queue s WITH(NOLOCK)
		WHERE Starttime > @Today AND SportType = 1
		GROUP BY matchid
	), ParlayTicket AS (
		SELECT p.matchid, MIN(IsCalculating) AS IsCalculating
		FROM dbo.Parlay_Calculate_Queue p WITH(NOLOCK)
		WHERE Starttime > @Today
		GROUP BY matchid 
	)
	INSERT INTO #MatchInQueue(MatchId, SingleStatus, ParlayStatus, IsSingle, IsMixParlay, IsInQueue)
	SELECT ISNULL(sg.matchid, pl.matchid) AS MatchId
		, sg.IsCalculating AS SingleStatus
		, pl.IsCalculating AS ParlayStatus
		, CAST(ISNULL(sg.IsCalculating, 0) AS BIT) AS IsSingle
		, CAST(ISNULL(pl.IsCalculating, 0) AS BIT) AS IsMixParlay
		, 1 AS IsInQueue
	FROM SingleTicket sg
		FULL OUTER JOIN ParlayTicket pl on sg.matchid = pl.matchid
	
	SET @Count = @@ROWCOUNT

	--get more error from AutoPayoutResult to refresh on main page
	INSERT INTO #MatchInQueue(MatchId, SingleStatus, ParlayStatus, IsSingle, IsMixParlay, IsInQueue)
	SELECT MatchId, 3 AS SingleStatus_FailedAuto, NULL AS ParlayStatus, 1 AS IsSingle, 0 AS IsMixParlay, 0 AS IsInQueue
	FROM DBPRO.bodb02.dbo.AutoPayoutResult a WITH(NOLOCK)
	WHERE NOT EXISTS (SELECT TOP 1 1 FROM #MatchInQueue q WHERE q.MatchId = a.MatchId)
		AND a.ModifiedDate > DATEADD(MINUTE, -1, GETDATE())
		AND StatusId = 3
	GROUP BY MatchId

	SET @Count = @Count + @@ROWCOUNT

	CREATE TABLE #tmpAutoSettle1s(MatchID INT, ResultStatusID TINYINT)
	INSERT INTO #tmpAutoSettle1s(MatchID, ResultStatusID)
	SELECT MatchID, MIN(ResultStatusID)
	FROM DBPRO.bodb02.dbo.ResultDetail rs WITH (NOLOCK)
	WHERE @Sporttype IN (0, 1)
		AND EXISTS (SELECT TOP 1 1 FROM #MatchInQueue t WHERE rs.MatchId = t.MatchId)
		AND (ResourceID IN (SELECT CAST(BetType AS VARCHAR(50)) FROM dbo.f_Set_GetGroupBettypes() WHERE GroupId = 8)
			--('135','168','173','174','175','176','192','193','210','211','212','213','214','215','216','217') --auto betradar
				OR ResourceID LIKE '160__'
				OR ResourceID LIKE '164__'
				OR ResourceID LIKE '169__'
				OR ResourceID LIKE '180__'
				OR ResourceID LIKE '216__')
	GROUP BY MatchID

	CREATE TABLE #MatchData (matchid INT, leagueid INT, hthomescore INT, htawayscore INT, calculate BIT, multiple BIT
			, refund BIT, calrefund BIT, homeid INT, awayid INT, matchcode VARCHAR(50), finalhomescore INT, finalawayscore INT
			, betstatus NVARCHAR(50), eventstatus VARCHAR(50), SettlementStatus135 TINYINT, sporttype SMALLINT, isNeutral BIT
			, goalrecord VARCHAR(50), IsHTCal BIT, isPending BIT, isUndecided BIT, IsAutoPayout BIT, IsAutoPayout_League BIT
			, ConfirmHT INT, ConfirmFT INT, HTStatus BIT, FTStatus BIT)

	DECLARE @SqlQuery VARCHAR(8000), @MatchIds VARCHAR(8000)
	
	WHILE @Count > @RowId
	BEGIN
		SELECT @MatchIds = NULL

		SELECT @MatchIds = COALESCE(@MatchIds + ',' + CAST(MatchId AS VARCHAR), CAST(MatchId AS VARCHAR))
		FROM #MatchInQueue
		WHERE RowId BETWEEN @RowId AND @RowId + 512 --maximum data via remote server < 8000 chars

		IF ISNULL(@MatchIds, '') = '' OR @@ROWCOUNT = 0
			BREAK

		SET @SqlQuery = '
			INSERT INTO #MatchData(matchid, leagueid, hthomescore, htawayscore, calculate, multiple
				, refund, calrefund, homeid, awayid, matchcode, finalhomescore, finalawayscore
				, betstatus, eventstatus, SettlementStatus135, sporttype, isNeutral
				, goalrecord, IsHTCal, isPending, isUndecided, IsAutoPayout, IsAutoPayout_League
				, ConfirmHT, ConfirmFT, HTStatus, FTStatus)
			SELECT *
			FROM OPENQUERY(DBPRO, ''SELECT m.matchid, m.leagueid, hthomescore, htawayscore, calculate, mr.multiple
					, refund, calrefund, homeid, awayid, matchcode, finalhomescore, finalawayscore
					, betstatus, eventstatus, SettlementStatus135, m.sporttype, mr.isNeutral
					, goalrecord, IsHTCal, isPending, isUndecided, m.IsAutoPayout, l.IsAutoPayout AS IsAutoPayout_League
					, ConfirmHT, ConfirmFT
					, MAX(CASE WHEN rs.CalculationType = 1 THEN 1 ELSE 0 END) AS HTStatus
					, MAX(CASE WHEN rs.CalculationType = 2 THEN 1 ELSE 0 END) AS FTStatus
			FROM bodb02.dbo.match m WITH(NOLOCK)
				INNER JOIN bodb02.dbo.match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
				INNER JOIN bodb02.dbo.league l WITH(NOLOCK) ON m.leagueid = l.leagueid
				LEFT JOIN bodb02.dbo.AutoPayoutResult rs WITH(NOLOCK) ON m.matchid = rs.matchid AND StatusId IN (1, 2)
			WHERE m.matchid IN (' + @MatchIds + ') 
				AND m.leagueID = CASE WHEN ''''' + CAST(@LeagueID AS VARCHAR) + ''''' <> 0 THEN ''''' + CAST(@LeagueID AS VARCHAR) + ''''' ELSE m.leagueID END
				AND m.sporttype = CASE WHEN ''''' + CAST(@sporttype AS VARCHAR) + ''''' = 0 THEN m.sporttype ELSE ''''' + CAST(@sporttype AS VARCHAR) + ''''' END
			GROUP BY m.matchid, m.leagueid, hthomescore, htawayscore, calculate, mr.multiple
					, refund, calrefund, homeid, awayid, matchcode, finalhomescore, finalawayscore
					, betstatus, eventstatus, SettlementStatus135, m.sporttype, mr.isNeutral
					, goalrecord, IsHTCal, isPending, isUndecided, m.IsAutoPayout, l.IsAutoPayout
					, ConfirmHT, ConfirmFT
		'')'
		--PRINT (@SqlQuery)
		EXEC (@SqlQuery)
		SET @RowId = @RowId + 512

	END

	;WITH BetStatus AS (
		SELECT b.matchid
			--, SUM(CASE WHEN b.bettype = 14 THEN 1 ELSE 0 END) AS IsExistFGLG
			--, SUM(CASE WHEN b.bettype = 127 THEN 1 ELSE 0 END) AS IsExistHTFGLG
			--, SUM(CASE WHEN b.bettype = 14 AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningFGLG
			--, SUM(CASE WHEN b.bettype = 127 AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningHTFGLG
			--, SUM(CASE WHEN b.bettype = 172 THEN 1 ELSE 0 END) AS IsExistResultandFirstTeamScore
			--, SUM(CASE WHEN b.bettype = 172 AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningResultandFirstTeamScore
			--, SUM(CASE WHEN b.bettype IN (194, 195, 196, 197, 198, 199, 206, 208) AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningCorner
			--, SUM(CASE WHEN b.bettype IN (200, 201, 202, 203, 204, 205, 207, 209) AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningHTCorner
			, SUM(CASE WHEN f.GroupId = 4 THEN 1 ELSE 0 END) AS IsExistFGLG
			, SUM(CASE WHEN f.GroupId = 3 THEN 1 ELSE 0 END) AS IsExistHTFGLG
			, SUM(CASE WHEN f.GroupId = 4 AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningFGLG
			, SUM(CASE WHEN f.GroupId = 3 AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningHTFGLG
			, SUM(CASE WHEN f.GroupId = 6 AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningCorner
			, SUM(CASE WHEN f.GroupId = 5 AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningHTCorner
			, SUM(CASE WHEN f.GroupId = 1 AND f.IsUsedGoalRecordValue = 1 THEN 1 ELSE 0 END) AS IsEnabledGoalRecordHT
			, SUM(CASE WHEN f.GroupId = 2 AND f.IsUsedGoalRecordValue = 1 THEN 1 ELSE 0 END) AS IsEnabledGoalRecordFT
		FROM dbo.bettrans b WITH(NOLOCK)
			INNER JOIN (
				SELECT GroupId, IsUsedGoalRecordValue, BetType
				FROM dbo.f_Set_GetGroupBettypes() f WHERE GroupId IN (1, 2, 3, 4, 5, 6)
			)f ON b.bettype = f.BetType
		WHERE EXISTS (SELECT TOP 1 1 FROM #MatchInQueue t WHERE b.matchid = t.matchid AND t.IsInQueue = 1)
			--AND bettype IN (14, 127, 172, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209)
			AND StatusId NOT IN (101, 102, 103)
		GROUP BY b.matchid
	), BetStatusM AS (
		SELECT b.matchid
			, SUM(CASE WHEN f.GroupId = 4 THEN 1 ELSE 0 END) AS IsExistFGLG
			, SUM(CASE WHEN f.GroupId = 3 THEN 1 ELSE 0 END) AS IsExistHTFGLG
			, SUM(CASE WHEN f.GroupId = 4 AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningFGLG
			, SUM(CASE WHEN f.GroupId = 3 AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningHTFGLG
			, SUM(CASE WHEN f.GroupId = 1 AND f.IsUsedGoalRecordValue = 1 THEN 1 ELSE 0 END) AS IsEnabledGoalRecordHT
			, SUM(CASE WHEN f.GroupId = 2 AND f.IsUsedGoalRecordValue = 1 THEN 1 ELSE 0 END) AS IsEnabledGoalRecordFT
		FROM dbo.bettransm b WITH(NOLOCK)
			INNER JOIN (
				SELECT GroupId, IsUsedGoalRecordValue, BetType
				FROM dbo.f_Set_GetGroupBettypes() f WHERE GroupId IN (1, 2, 3, 4)
			)f ON b.bettype = f.BetType
		WHERE EXISTS (SELECT TOP 1 1 FROM #MatchInQueue t WHERE b.matchid = t.matchid AND t.IsInQueue = 1)
			--AND bettype IN (14, 127)--FGLG
			AND StatusId NOT IN (101, 102, 103)
		GROUP BY b.matchid
	)

	SELECT tm.matchid
		, leagueid
		, hthomescore AS HalfTimeHomeScore
		, htawayscore AS HalfTimeAwayScore
		, ISNULL(t.calculate, 0) AS IsCalculated
		, ISNULL(t.multiple, 0) AS IsMultiCaled
		, ISNULL(t.refund, 0) AS IsRefund
		, ISNULL(t.calrefund, 0) AS IsCalRefund
		, homeid
		, awayid
		, matchcode
		, finalhomescore
		, finalawayscore
		, betstatus
		, CASE WHEN t.betstatus LIKE 'Refund FT%' THEN 'Refund FT'  
				WHEN t.betstatus LIKE 'Refund HT%' THEN 'Refund HT'  
				WHEN t.betstatus LIKE 'Refund%' THEN 'Refund'  
			ELSE t.eventstatus END AS eventstatus
		, ISNULL(t.SettlementStatus135, 0) AS SettlementStatus135
		, sporttype
		, ISNULL(t.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
		, goalrecord
		, ISNULL(t.IsHTCal, 0) AS IsHalfTimeCal
		, isPending
		, isUndecided
		, CAST(CASE WHEN hthomescore IS NOT NULL 
						AND htawayscore IS NOT NULL 
						AND finalhomescore IS NOT NULL 
						AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore
		, CASE WHEN ISNULL(b.IsExistFGLG, 0) > 0 OR ISNULL(bm.IsExistFGLG, 0) > 0 THEN 1 ELSE 0 END AS IsExistFGLG
		, CASE WHEN ISNULL(b.IsExistHTFGLG, 0) > 0 OR ISNULL(bm.IsExistHTFGLG, 0) > 0 THEN 1 ELSE 0 END AS IsExistHTFGLG
		, CASE WHEN ISNULL(b.IsExistRunningCorner, 0) > 0 THEN 1 ELSE 0 END AS IsExistCorner
		, CASE WHEN ISNULL(b.IsExistRunningHTCorner, 0) > 0 THEN 1 ELSE 0 END AS IsExistHTCorner
		, tm.SingleStatus AS IsCalculatingSingle
		, tm.ParlayStatus AS IsCalculatingMP
		, CASE WHEN a.ResultStatusID IS NULL THEN 'N/A'
				WHEN a.ResultStatusID IN(0,1,3) THEN 'Running'
				WHEN a.ResultStatusID IN (2,5) THEN 'Completed'
			ELSE '' END AS AutoSettleResultStatus
		, CASE WHEN t.HTStatus IS NOT NULL AND t.HTStatus = 1 
					AND t.FTStatus IS NOT NULL AND t.FTStatus IN (0, 1)
					AND t.IsHTCal = 1 
					AND (ISNULL(b.IsExistRunningHTFGLG, 0) > 0 OR ISNULL(bm.IsExistRunningHTFGLG, 0) > 0
						OR ISNULL(b.IsEnabledGoalRecordHT, 0) > 1 OR ISNULL(bm.IsEnabledGoalRecordHT, 0) > 1) THEN 1 --can calc HT FGLG
				WHEN t.FTStatus IS NOT NULL AND t.FTStatus = 1
					AND t.IsHTCal = 1
					AND (ISNULL(b.IsExistRunningFGLG, 0) > 0  OR ISNULL(bm.IsExistRunningFGLG, 0) > 0
						OR ISNULL(b.IsEnabledGoalRecordFT, 0) > 1 OR ISNULL(bm.IsEnabledGoalRecordFT, 0) > 1) THEN 1 --can calc FT FGLG
			ELSE 0 END AS IsNeedToCalculateFGLG
		, CASE WHEN t.HTStatus IS NOT NULL AND t.HTStatus = 1
					AND t.FTStatus IS NOT NULL AND t.FTStatus IN (0, 1)
					AND t.IsHTCal = 1
					AND ISNULL(b.IsExistRunningHTCorner, 0) > 0 THEN 1 --can calc HT Corner
				WHEN t.FTStatus IS NOT NULL AND t.FTStatus = 1
					AND t.IsHTCal = 1
					AND ISNULL(b.IsExistRunningCorner, 0) > 0 THEN 1 --can calc FT Corner
			ELSE 0 END AS IsNeedToCalculateCorner
		, CASE t.ConfirmHT WHEN 0 THEN '' ELSE (SELECT username FROM CustDB.dbo.custInfo ci (NOLOCK) WHERE ci.custid = t.ConfirmHT) END suspenderHalfTime 
		, CASE t.ConfirmFT WHEN 0 THEN '' ELSE (SELECT username FROM CustDB.dbo.custInfo ci (NOLOCK) WHERE ci.custid = t.ConfirmFT) END suspenderFullTime
		, CASE WHEN t.IsAutoPayout IS NULL THEN ISNULL(t.IsAutoPayout_League, 0)
					 WHEN t.IsAutoPayout = 1 THEN 1
				ELSE 0 END AS IsAutoPayout
		, CASE WHEN ISNULL(b.IsEnabledGoalRecordHT, 0) > 1 OR ISNULL(bm.IsEnabledGoalRecordHT, 0) > 1 THEN 1 ELSE 0 END IsEnabledGoalRecordHT
		, CASE WHEN ISNULL(b.IsEnabledGoalRecordFT, 0) > 1 OR ISNULL(bm.IsEnabledGoalRecordFT, 0) > 1 THEN 1 ELSE 0 END IsEnabledGoalRecordFT
	FROM #MatchInQueue tm
		INNER JOIN #MatchData t ON tm.MatchId = t.matchid
		LEFT JOIN #tmpAutoSettle1s a WITH (NOLOCK) ON tm.matchID = a.MatchID
		LEFT JOIN BetStatus b ON tm.matchid = b.matchid
		LEFT JOIN BetStatusM bm ON tm.matchid = bm.matchid

	DROP TABLE #MatchInQueue
	DROP TABLE #MatchData
	DROP TABLE #tmpAutoSettle1s
END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_AutoPayout_WaitingSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_AutoPayout_WaitingSel] TO [vnteam] AS [dbo]