USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Set_WaitingSel] @MatchCode NVARCHAR(50) = ''
	, @SportType SMALLINT = 0
	, @LeagueId INT = 0 -- 0 for ALL Leagues
AS
/*
	Created: 20140103@Kathy
	Task: get status for a match
	DB: DBTXN/BODB02
	
	Revision:
		- 20140419@Lukas: reduce data return by excluding old matches
		- 20140421@Kathy: Directly get IsExistFGLG value from bettrans (not use NAP_Set_MatchBetStatusSel)
		- 20140506@Kathy: get HT FGLG status 
		- 20140711@Kathy: get Penalty Shootout status
		- 20141007@Jamie: Get Tennis in new table [Redmine: #23034]
		- 20150420@Jamie: Betradar phase II [Readmine:#27212]
		- 20151210@Patrick: Database - Change datatype [Redmine: #48660]
		- 20160805@Kathy: Write log duration
		- 20160811@Patrick: Rearrange code & remove link server to DBPRO
		- 20160830@Kathy: PH-AIO phase 2b [Redmine:#62861]
		- 20161118@Kathy: Changes on Auto Settlement [Redmine:#67328]
		- 20160509@Kathy: Fast Market integration [Remine:#56367]
	
	Param's explanation:  
		
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @matchid INT, @StartTime DATETIME, @EndTime	DATETIME, @SqlCommand VARCHAR(MAX)
	SELECT @MatchCode = ISNULL(@MatchCode, ''), @LeagueId = ISNULL(@LeagueID, 0), @SportType = ISNULL(@SportType, 0)

	IF ISNUMERIC(@MatchCode) = 1
		SET @matchid = CAST(@MatchCode AS INT)
	
	DECLARE @TempMatch TABLE (MatchId INT
		,SingleStatus 					INT
		,ParlayStatus 					INT
		,IsSingle 						BIT
		,IsMixParlay 					BIT
		,IsExistFGLG 					BIT
		,IsExistHTFGLG 					BIT
		,SettlementStatusID 			TINYINT
		,IsExistAutoBettypes 			BIT
		,IsExistAutoBettypesParlay 		BIT
		,IsRunningAutoBettypes			BIT
		,IsRunningAutoBettypesParlay	BIT
		,IsMissingAutoResult			BIT
		,IsExistFastMarket				BIT
		,IsRunningFastMarket			BIT
		,IsExistFastMarletResult		BIT
	)

	;WITH SingleTicket AS (
		SELECT matchid, MIN(IsCalculating) AS IsCalculating
		FROM dbo.Single_Calculate_Queue s WITH(NOLOCK)
		WHERE Starttime > DATEADD(HH, -1, GETDATE())
		GROUP BY matchid 
	), ParlayTicket AS (
		SELECT p.matchid, MIN(IsCalculating) AS IsCalculating
		FROM dbo.Parlay_Calculate_Queue p WITH(NOLOCK)
		WHERE Starttime > DATEADD(HH, -1, GETDATE())
		GROUP BY matchid 
	)
	
	INSERT INTO @TempMatch(MatchId, SingleStatus, ParlayStatus, IsSingle, IsMixParlay, IsExistFGLG, IsExistHTFGLG
		, IsExistAutoBettypes, IsExistAutoBettypesParlay, IsRunningAutoBettypes, IsRunningAutoBettypesParlay, IsMissingAutoResult
		, IsExistFastMarket, IsRunningFastMarket, IsExistFastMarletResult
	)
	SELECT ISNULL(sg.matchid, pl.matchid) AS MatchId
		, sg.IsCalculating AS SingleStatus
		, pl.IsCalculating AS ParlayStatus
		, CAST(ISNULL(sg.IsCalculating, 0) AS BIT) AS IsSingle
		, CAST(ISNULL(pl.IsCalculating, 0) AS BIT) AS IsMixParlay
		, CONVERT(BIT, 0) AS IsExistFGLG
		, CONVERT(BIT, 0) AS IsExistHTFGLG
		, 0 AS IsExistAutoBettypes
		, 0 AS IsExistAutoBettypesParlay
		, 0 AS IsRunningAutoBettypes
		, 0 AS IsRunningAutoBettypesParlay
		, 0 AS IsMissingAutoResult
		, 0 AS IsExistFastMarket
		, 0 AS IsRunningFastMarket
		, 0 AS IsExistFastMarletResult
	FROM SingleTicket sg
		FULL OUTER JOIN ParlayTicket pl ON sg.matchid = pl.matchid
	
	;WITH cteAutoResultDetail
	AS(
		SELECT	CASE 
					WHEN BetType IN (160,164,169,180,216) OR GroupId = 9 THEN CAST(BetType AS VARCHAR(20)) + '__'
					ELSE CAST(BetType AS VARCHAR(20))
				END AS ResourceId
				,GroupId
		FROM	dbo.f_Set_GetGroupBettypes()
		WHERE	IsAuto = 1
	)
	UPDATE	m
		SET SettlementStatusID = rs.SettlementStatusID
			,IsExistFastMarletResult = rs.IsExistFastMarletResult
	FROM	@TempMatch m
		CROSS APPLY (
			SELECT	TOP 1 r.MatchID
					,MIN(CASE WHEN c.groupId = 8 THEN ISNULL(r.SettlementStatusID,0) ELSE NULL END) AS SettlementStatusID
					,MAX(CASE WHEN c.groupId = 9 THEN 1 ELSE 0 END) AS IsExistFastMarletResult
			FROM	DBPRO.bodb02.dbo.ResultDetail r WITH (NOLOCK)
				INNER JOIN cteAutoResultDetail c
					ON	r.MatchId = m.MatchId
						AND r.ResourceId LIKE c.ResourceId
			GROUP BY r.MatchID
		) rs
	
	CREATE TABLE #tblBetStatus (matchid INT, bettype SMALLINT, isRunning INT, groupId TINYINT ,IsParlay	 BIT)
	
	INSERT INTO #tblBetStatus (matchid, bettype, isRunning, groupId, IsParlay)
	SELECT b.matchid, b.bettype, b.IsRunning, f.GroupId, 0
	FROM dbo.f_Set_GetGroupBettypes() f
		INNER JOIN (
			SELECT  b.matchid, b.bettype, SUM (CASE WHEN b.statusID = 0 THEN 1 ELSE 0 END) AS IsRunning
			FROM	dbo.bettrans b WITH (NOLOCK)
			WHERE matchid IN (SELECT matchid FROM @TempMatch)
				AND 1 = CASE 
							WHEN bettype IN (14,127) THEN 1
							WHEN bettype NOT IN (14,127) AND statusid = 0 THEN 1
							ELSE 0 
						END
				AND b.statusID NOT IN (101, 102)
			GROUP BY b.matchid, b.bettype
		) b
			ON	f.BetType = b.bettype
	WHERE f.GroupId IN (3,4,8,9)

	INSERT INTO #tblBetStatus (matchid, bettype, isRunning, groupId, IsParlay)
	SELECT bm.matchid, bm.bettype, bm.IsRunning, f.GroupId, 1
	FROM dbo.f_Set_GetGroupBettypes() f
		INNER JOIN (
			SELECT  bm.matchid, bm.bettype, SUM (CASE WHEN bm.statusID = 0 THEN 1 ELSE 0 END) AS IsRunning
			FROM	dbo.bettransm bm WITH (NOLOCK)
			WHERE matchid IN (SELECT matchid FROM @TempMatch)
				AND bm.statusID NOT IN (101, 102)
			GROUP BY bm.matchid, bm.bettype
		) bm
			ON	f.BetType = bm.bettype
	WHERE f.GroupId = 8

	;WITH cteBetStatus
	AS(
		SELECT matchid
			,MAX(CASE WHEN groupId = 3 THEN 1 ELSE 0 END) AS IsExistHTFGLG
			,MAX(CASE WHEN groupId = 4 THEN 1 ELSE 0 END) AS IsExistFGLG
			,MAX(CASE WHEN groupId = 8 AND IsParlay = 0 THEN 1 ELSE 0 END) AS IsExistAutoBettypes
			,MAX(CASE WHEN groupId = 8 AND IsParlay = 1 THEN 1 ELSE 0 END) AS IsExistAutoBettypesParlay
			,MAX(CASE WHEN groupId = 8 AND IsParlay = 0 AND isRunning > 0 THEN 1 ELSE 0 END) AS IsRunningAutoBettypes
			,MAX(CASE WHEN groupId = 8 AND IsParlay = 1 AND isRunning > 0 THEN 1 ELSE 0 END) AS IsRunningAutoBettypesParlay
			,MAX(CASE WHEN groupId = 9 AND IsParlay = 0 THEN 1 ELSE 0 END) AS IsExistFastMarket
			,MAX(CASE WHEN groupId = 9 AND IsParlay = 0 AND isRunning > 0 THEN 1 ELSE 0 END) AS IsRunningFastMarket
		FROM #tblBetStatus
		GROUP BY matchid
	)
	UPDATE t
	SET IsExistFGLG = CASE WHEN tt.IsExistFGLG > 0 THEN 1 ELSE 0 END
		,IsExistHTFGLG = CASE WHEN tt.IsExistHTFGLG > 0 THEN 1 ELSE 0 END
		,IsExistAutoBettypes = CASE WHEN tt.IsExistAutoBettypes > 0 THEN 1 ELSE 0 END
		,IsExistAutoBettypesParlay = CASE WHEN tt.IsExistAutoBettypesParlay > 0 THEN 1 ELSE 0 END
		,IsRunningAutoBettypes = CASE WHEN tt.IsRunningAutoBettypes > 0 THEN 1 ELSE 0 END
		,IsRunningAutoBettypesParlay = CASE WHEN tt.IsRunningAutoBettypesParlay > 0 THEN 1 ELSE 0 END
		,IsExistFastMarket = CASE WHEN tt.IsExistFastMarket > 0 THEN 1 ELSE 0 END
		,IsRunningFastMarket = CASE WHEN tt.IsRunningFastMarket > 0 THEN 1 ELSE 0 END
	FROM @TempMatch t
	INNER JOIN cteBetStatus tt ON t.MatchId = tt.MatchId	
	
	;WITH cteAutoBettypes
	AS(
		SELECT	CASE 
					WHEN BetType IN (160,164,169,180,216) THEN CAST(BetType AS VARCHAR(20)) + '__'
					ELSE CAST(BetType AS VARCHAR(20))
				END AS ResourceId
				,BetType
		FROM	dbo.f_Set_GetGroupBettypes()
		WHERE	GroupId = 8
	)	
	UPDATE m
		SET IsMissingAutoResult = CASE WHEN t.MissingAutoResult > 0 THEN 1 ELSE 0 END
	FROM @TempMatch m
		INNER JOIN (
			SELECT  b.matchid, COUNT(1) MissingAutoResult
			FROM	#tblBetStatus b
				INNER JOIN cteAutoBettypes c
					ON b.bettype = c.bettype
			WHERE	IsParLay = 1		
					AND NOT EXISTS (SELECT TOP 1 1 FROM DBPRO.bodb02.dbo.ResultDetail WITH(NOLOCK) WHERE b.matchid = MatchId AND ResourceId LIKE c.ResourceId)
			GROUP BY b.matchid
	) t
		ON m.matchid = t.matchid
	
	SELECT m.matchid, m.leagueid, m.homeid, m.awayid, m.matchcode, m.finalhomescore, m.finalawayscore
		, m.betstatus, m.sporttype, m.goalrecord
		, hthomescore AS HalfTimeHomeScore
		, htawayscore AS HalfTimeAwayScore
		, ISNULL(mr.calculate, 0) AS IsCalculated
		, ISNULL(mr.multiple, 0) AS IsMultiCaled
		, ISNULL(mr.refund, 0) AS IsRefund
		, ISNULL(mr.calrefund, 0) AS IsCalRefund
		, CASE WHEN m.betstatus LIKE 'Refund FT%' THEN 'Refund FT'  
				WHEN m.betstatus LIKE 'Refund HT%' THEN 'Refund HT'  
				WHEN m.betstatus LIKE 'Refund%' THEN 'Refund'  
			ELSE m.eventstatus END AS eventstatus
		, ISNULL(mr.SettlementStatus135, 0) AS SettlementStatus135
		, ISNULL(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
		, ISNULL(mr.IsHTCal, 0) AS IsHalfTimeCal
		, ISNULL(mr.isPending, 0) AS IsPending
		, ISNULL(mr.isUndecided, 0) AS IsUndecided
		, CAST(CASE WHEN hthomescore IS NOT NULL 
				AND htawayscore IS NOT NULL 
				AND finalhomescore IS NOT NULL 
				AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore
		, IsExistFGLG
		, IsExistHTFGLG
		, tm.SingleStatus AS IsCalculatingSingle
		, tm.ParlayStatus AS IsCalculatingMP
		, CASE WHEN tm.SettlementStatusID IS NULL AND tm.IsExistAutoBettypes = 0 AND tm.IsExistAutoBettypesParlay = 0 THEN 'N/A'
				WHEN tm.SettlementStatusID = 0 OR tm.IsRunningAutoBettypes > 0 THEN 'Running'
				WHEN ISNULL(tm.IsMissingAutoResult,0) > 0 AND tm.IsRunningAutoBettypesParlay > 0 THEN 'Parlay Running'
				WHEN tm.SettlementStatusID > 0 
					OR (tm.IsExistAutoBettypes > 0 AND tm.IsRunningAutoBettypes = 0)
					OR (tm.IsExistAutoBettypes = 0 AND tm.IsExistAutoBettypesParlay > 0 AND tm.IsRunningAutoBettypesParlay = 0) THEN 'Completed'
			ELSE '' END AS AutoSettleResultStatus
		, CASE
			WHEN tm.IsExistFastMarletResult = 0 AND tm.IsExistFastMarket = 0 THEN 'N/A'
			WHEN tm.IsRunningFastMarket > 0 THEN 'Running'
			WHEN tm.IsExistFastMarket > 0 AND tm.IsRunningFastMarket = 0 THEN 'Completed'
			ELSE ''
		END AS AutoSettleFastMarket
	FROM dbo.match m WITH(NOLOCK)
		INNER JOIN @TempMatch tm ON m.matchid = tm.matchid
		LEFT JOIN dbo.match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
	WHERE m.sporttype = @sporttype
		AND (@LeagueId = 0 OR m.leagueid = @LeagueId)
		AND (@matchcode = '' OR (m.matchid = @matchid OR m.matchcode = @matchcode))
	
	-- GET TENNIS RESULT DETAIL 
	SELECT MatchId
		, ResourceId
		, HomeValue
		, AwayValue
		, ResultStatusID
		, SettlementStatusID
	FROM DBPRO.bodb02.dbo.ResultDetail rs WITH (NOLOCK)
	WHERE rs.MatchId IN (SELECT t.MatchId FROM @TempMatch t)
		AND ResourceId LIKE '0[0-5]'

	SET @EndTime = GETDATE()
	IF DATEDIFF(MILLISECOND, @StartTime, @EndTime) > 1000
	BEGIN
		SET @SqlCommand = 'EXEC NAP_Set_WaitingSel @MatchCode =''' + ISNULL(@MatchCode,'') + ''', @SportType = ' + CONVERT(VARCHAR(10),@SportType) + ', @LeagueId =' + CONVERT(VARCHAR(10),@LeagueId)
		INSERT INTO dbo.SettlementRunSPLog(LogDate, SqlCommand, StartTime, EndTime)
		SELECT GETDATE(), @SqlCommand, @StartTime, @EndTime
	END

END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_WaitingSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_WaitingSel] TO [vnteam] AS [dbo]