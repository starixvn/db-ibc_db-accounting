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
	DECLARE @Today DATETIME, @RowId INT, @Count INT
	SELECT @LeagueID = ISNULL(@LeagueID, 0), @SportType = ISNULL(@SportType, 0), @Today = GETDATE(), @RowId = 0

	SET @Today = DATEADD(HH, -1, @Today)

	CREATE TABLE #MatchInQueue (RowId INT IDENTITY(1,1), MatchId INT, SingleStatus INT, ParlayStatus INT, IsSingle BIT, IsMixParlay BIT)

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
	INSERT INTO #MatchInQueue(MatchId, SingleStatus, ParlayStatus, IsSingle, IsMixParlay)
	SELECT ISNULL(sg.matchid, pl.matchid) AS MatchId
		, sg.IsCalculating AS SingleStatus
		, pl.IsCalculating AS ParlayStatus
		, CAST(ISNULL(sg.IsCalculating, 0) AS BIT) AS IsSingle
		, CAST(ISNULL(pl.IsCalculating, 0) AS BIT) AS IsMixParlay
	FROM SingleTicket sg
		FULL OUTER JOIN ParlayTicket pl on sg.matchid = pl.matchid

	SET @Count = @@ROWCOUNT

	CREATE TABLE #tmpAutoSettle1s(MatchID INT, ResultStatusID TINYINT)
	INSERT INTO #tmpAutoSettle1s(MatchID, ResultStatusID)
	SELECT MatchID, MIN(ResultStatusID)
	FROM DBPRO.bodb02.dbo.ResultDetail rs WITH (NOLOCK)
	WHERE @Sporttype IN(0, 1)
		AND EXISTS (SELECT TOP 1 1 FROM #MatchInQueue t WHERE rs.MatchId = t.MatchId)
		AND (ResourceID IN ('135','168','173','174','175','176','192','193','210','211','212','213','214','215','216','217')
				OR ResourceID LIKE '160__'
				OR ResourceID LIKE '164__'
				OR ResourceID LIKE '169__'
				OR ResourceID LIKE '180__'
				OR ResourceID LIKE '216__')
	GROUP BY MatchID
	CREATE TABLE #MatchData (matchid INT, leagueid INT, hthomescore INT, htawayscore INT, calculate BIT, multiple BIT
			, refund BIT, calrefund BIT, homeid INT, awayid INT, matchcode VARCHAR(50), finalhomescore INT, finalawayscore INT
			, betstatus NVARCHAR(50), eventstatus VARCHAR(50), SettlementStatus135 TINYINT, sporttype SMALLINT, isNeutral BIT
			, goalrecord VARCHAR(50), IsHTCal BIT, isPending BIT, isUndecided BIT, IsAutoPayout BIT, IsAutoPayout_League BIT, ConfirmHT INT, ConfirmFT INT)

	DECLARE @SqlQuery VARCHAR(MAX), @MatchIds VARCHAR(MAX)
	
	WHILE @Count > @RowId
	BEGIN
		SELECT @MatchIds = NULL

		SELECT @MatchIds = COALESCE(@MatchIds + ',' + CAST(MatchId AS VARCHAR), CAST(MatchId AS VARCHAR))
		FROM #MatchInQueue
		WHERE RowId BETWEEN @RowId AND @RowId + 512 --maximum data via remote server < 8000 chars

		SET @RowId = @RowId + 512

		IF ISNULL(@MatchIds, '') = '' OR @@ROWCOUNT = 0
		SET @SqlQuery = '
			INSERT INTO #MatchData(matchid, leagueid, hthomescore, htawayscore, calculate, multiple
				, refund, calrefund, homeid, awayid, matchcode, finalhomescore, finalawayscore
				, betstatus, eventstatus, SettlementStatus135, sporttype, isNeutral
				, goalrecord, IsHTCal, isPending, isUndecided, IsAutoPayout, IsAutoPayout_League, ConfirmHT, ConfirmFT)
			SELECT *
			FROM OPENQUERY(DBPRO, ''SELECT m.matchid, m.leagueid, hthomescore, htawayscore, calculate, mr.multiple
					, refund, calrefund, homeid, awayid, matchcode, finalhomescore, finalawayscore
					, betstatus, eventstatus, SettlementStatus135, m.sporttype, mr.isNeutral
					, goalrecord, IsHTCal, isPending, isUndecided, m.IsAutoPayout, l.IsAutoPayout AS IsAutoPayout_League, ConfirmHT, ConfirmFT
			FROM bodb02.dbo.match m WITH(NOLOCK)
				INNER JOIN bodb02.dbo.match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
				INNER JOIN bodb02.dbo.league l WITH(NOLOCK) ON m.leagueid = l.leagueid
			WHERE m.matchid IN (' + @MatchIds + ') 
				AND m.leagueID = CASE WHEN ''''' + CAST(@LeagueID AS VARCHAR) + ''''' <> 0 THEN ''''' + CAST(@LeagueID AS VARCHAR) + ''''' ELSE m.leagueID END
				AND m.sporttype = CASE WHEN ''''' + CAST(@sporttype AS VARCHAR) + ''''' = 0 THEN m.sporttype ELSE ''''' + CAST(@sporttype AS VARCHAR) + ''''' END'')
		'
		--PRINT (@SqlQuery)
		EXEC (@SqlQuery)
	END

	;WITH BetStatus AS (
		SELECT b.matchid
			, SUM(CASE WHEN b.bettype = 14 THEN 1 ELSE 0 END) AS IsExistFGLG
			, SUM(CASE WHEN b.bettype = 127 THEN 1 ELSE 0 END) AS IsExistHTFGLG
			, SUM(CASE WHEN b.bettype = 14 AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningFGLG
			, SUM(CASE WHEN b.bettype = 127 AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningHTFGLG
			, SUM(CASE WHEN b.bettype = 172 THEN 1 ELSE 0 END) AS IsExistResultandFirstTeamScore
			, SUM(CASE WHEN b.bettype = 172 AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningResultandFirstTeamScore
			, SUM(CASE WHEN b.bettype IN (194, 195, 196, 197, 198, 199, 206, 208) AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningCorner
			, SUM(CASE WHEN b.bettype IN (200, 201, 202, 203, 204, 205, 207, 209) AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningHTCorner
		FROM dbo.bettrans b WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM #MatchInQueue t WHERE b.matchid = t.matchid)
			AND bettype IN (14, 127, 172, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209)
			AND StatusId NOT IN (101, 102, 103)
		GROUP BY b.matchid
	), BetStatusM AS (
		SELECT b.matchid
			, SUM(CASE WHEN b.bettype = 14 THEN 1 ELSE 0 END) AS IsExistFGLG
			, SUM(CASE WHEN b.bettype = 127 THEN 1 ELSE 0 END) AS IsExistHTFGLG
			, SUM(CASE WHEN b.bettype = 14 AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningFGLG
			, SUM(CASE WHEN b.bettype = 127 AND StatusId = 0 THEN 1 ELSE 0 END) AS IsExistRunningHTFGLG
		FROM dbo.bettransm b WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM #MatchInQueue t WHERE b.matchid = t.matchid)
			AND bettype IN (14, 127)--FGLG
			AND StatusId NOT IN (101, 102, 103)
		GROUP BY b.matchid
	), PayoutResult AS (
		SELECT rs.MatchId
			, MAX(CASE WHEN rs.CalculationType = 1 THEN 1 ELSE 0 END) AS HTStatus
			, MAX(CASE WHEN rs.CalculationType = 2 THEN 1 ELSE 0 END) AS FTStatus
		FROM dbo.AutoPayoutResult rs WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM #MatchInQueue t WHERE rs.MatchId = t.matchid)
			AND StatusId IN (1, 2)
		GROUP BY rs.MatchId
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
		, CASE WHEN ISNULL(b.IsExistFGLG, 0) > 0 OR ISNULL(b.IsExistResultandFirstTeamScore, 0) > 0 OR ISNULL(bm.IsExistFGLG, 0) > 0 THEN 1 ELSE 0 END AS IsExistFGLG
		, CASE WHEN ISNULL(b.IsExistHTFGLG, 0) > 0 OR ISNULL(bm.IsExistHTFGLG, 0) > 0 THEN 1 ELSE 0 END AS IsExistHTFGLG
		, CASE WHEN ISNULL(b.IsExistRunningCorner, 0) > 0 THEN 1 ELSE 0 END AS IsExistCorner
		, CASE WHEN ISNULL(b.IsExistRunningHTCorner, 0) > 0 THEN 1 ELSE 0 END AS IsExistHTCorner
		, tm.SingleStatus AS IsCalculatingSingle
		, tm.ParlayStatus AS IsCalculatingMP
		, CASE WHEN a.ResultStatusID IS NULL THEN 'N/A'
				WHEN a.ResultStatusID IN(0,1,3) THEN 'Running'
				WHEN a.ResultStatusID IN (2,5) THEN 'Completed'
			ELSE '' END AS AutoSettleResultStatus
		, CASE WHEN rs.MatchId IS NOT NULL
					AND rs.HTStatus = 1 
					AND t.IsHTCal = 1 
					AND rs.FTStatus IN (0,1)
					AND (ISNULL(b.IsExistRunningHTFGLG, 0) > 0 OR ISNULL(bm.IsExistRunningHTFGLG, 0) > 0) THEN 1 --can calc HT FGLG
				WHEN rs.MatchId IS NOT NULL
					AND rs.FTStatus = 1
					AND t.IsHTCal = 1 
					AND (ISNULL(b.IsExistRunningFGLG, 0) > 0  OR ISNULL(bm.IsExistRunningFGLG, 0) > 0 
							OR ISNULL(IsExistRunningResultandFirstTeamScore, 0) > 0) THEN 1 --can calc FT FGLG
			ELSE 0 END AS IsNeedToCalculateFGLG
		, CASE WHEN rs.MatchId IS NOT NULL
					AND rs.HTStatus IN (0,1) 
					AND t.IsHTCal = 1
					AND rs.FTStatus = 0
					AND ISNULL(b.IsExistRunningHTCorner, 0) > 0 THEN 1 --can calc HT Corner
				WHEN rs.MatchId IS NOT NULL
					AND rs.FTStatus = 1
					AND t.IsHTCal = 1
					AND ISNULL(b.IsExistRunningCorner, 0) > 0 THEN 1 --can calc FT Corner
			ELSE 0 END AS IsNeedToCalculateCorner
		, CASE t.ConfirmHT WHEN 0 THEN '' ELSE (SELECT username FROM CustDB.dbo.custInfo ci (NOLOCK) WHERE ci.custid = t.ConfirmHT ) END suspenderHalfTime 
		, CASE t.ConfirmFT WHEN 0 THEN '' ELSE (SELECT username FROM CustDB.dbo.custInfo ci (NOLOCK) WHERE ci.custid = t.ConfirmFT ) END suspenderFullTime
		, CASE WHEN t.IsAutoPayout IS NULL THEN ISNULL(t.IsAutoPayout_League, 0)
					 WHEN t.IsAutoPayout = 1 THEN 1
				ELSE 0 END AS IsAutoPayout
	FROM #MatchInQueue tm
		INNER JOIN #MatchData t ON tm.MatchId = t.matchid
		LEFT JOIN #tmpAutoSettle1s a WITH (NOLOCK) ON tm.matchID = a.MatchID
		LEFT JOIN BetStatus b ON tm.matchid = b.matchid
		LEFT JOIN BetStatusM bm ON tm.matchid = bm.matchid
		LEFT JOIN PayoutResult rs ON tm.matchid = rs.matchid

	DROP TABLE #MatchInQueue
	DROP TABLE #MatchData
	DROP TABLE #tmpAutoSettle1s
END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_AutoPayout_WaitingSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_AutoPayout_WaitingSel] TO [vnteam] AS [dbo]