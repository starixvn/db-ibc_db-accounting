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
		- 20160509@Kathy: Fast Market integration [Remine:#56367]
	
	Param's explanation:  
		
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @matchid INT, @StartTime DATETIME, @EndTime	DATETIME, @SqlCommand VARCHAR(MAX)
	SELECT @MatchCode = ISNULL(@MatchCode, ''), @LeagueId = ISNULL(@LeagueID, 0), @SportType = ISNULL(@SportType, 0)

	IF ISNUMERIC(@MatchCode) = 1
		SET @matchid = CAST(@MatchCode AS INT)
	
	DECLARE @TempMatch TABLE (MatchId INT, SingleStatus INT, ParlayStatus INT, IsSingle BIT, IsMixParlay BIT, IsExistFGLG BIT, IsExistHTFGLG BIT, AutoSettleResultStatus VARCHAR(50), AutoSettleFastMarket VARCHAR(50))

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
	
	INSERT INTO @TempMatch(MatchId, SingleStatus, ParlayStatus, IsSingle, IsMixParlay, IsExistFGLG, IsExistHTFGLG, AutoSettleResultStatus, AutoSettleFastMarket)
	SELECT ISNULL(sg.matchid, pl.matchid) AS MatchId
		, sg.IsCalculating AS SingleStatus
		, pl.IsCalculating AS ParlayStatus
		, CAST(ISNULL(sg.IsCalculating, 0) AS BIT) AS IsSingle
		, CAST(ISNULL(pl.IsCalculating, 0) AS BIT) AS IsMixParlay
		, CONVERT(BIT, 0) AS IsExistFGLG
		, CONVERT(BIT, 0) AS IsExistHTFGLG
		, CONVERT(VARCHAR(50), 'N/A') AS AutoSettleResultStatus
		, CONVERT(VARCHAR(50), 'N/A') AS AutoSettleFastMarket
	FROM SingleTicket sg
		FULL OUTER JOIN ParlayTicket pl ON sg.matchid = pl.matchid
	
	DECLARE @TmpAutoSettle1s TABLE (MatchId INT, SettlementStatusID INT, FM_SettlementStatusID INT)
	INSERT INTO @TmpAutoSettle1s(MatchId, SettlementStatusID, FM_SettlementStatusID)
	SELECT	MatchId
			, MIN(CASE WHEN ResourceId NOT IN ('22100', '22200', '22300', '22400', '22500', '22101', '22201', '22301', '22401', '22501') 
						THEN SettlementStatusID ELSE NULL END)
			, CASE WHEN MIN(CASE WHEN ResourceId IN ('22100', '22200', '22300', '22400', '22500') THEN SettlementStatusID END) IS NULL 
						THEN MIN(CASE WHEN ResourceId IN ('22101', '22201', '22301', '22401', '22501') THEN 0 END ) 
				ELSE MIN(CASE WHEN ResourceId IN ('22100', '22200', '22300', '22400', '22500') THEN SettlementStatusID END) 
			END
	FROM DBPRO.bodb02.dbo.ResultDetail WITH (NOLOCK)
	WHERE @Sporttype IN (0, 1)
		AND MatchID IN (SELECT MatchID FROM @TempMatch)
		AND (ResourceId IN (SELECT CAST(BetType AS VARCHAR(20)) FROM dbo.f_Set_GetGroupBettypes() WHERE IsAuto = 1 )
				OR ResourceID LIKE '160__'
				OR ResourceID LIKE '164__'
				OR ResourceID LIKE '169__'
				OR ResourceID LIKE '180__'
				OR ResourceID LIKE '216__')
				OR ResourceId IN ('22100', '22200', '22300', '22400', '22500', '22101', '22201', '22301', '22401','22501')
	GROUP BY MatchId
	
	UPDATE t
	SET AutoSettleResultStatus = CASE	
									WHEN a.SettlementStatusID IS NULL THEN 'N/A'
									WHEN a.SettlementStatusID = 0 THEN 'Running'
									WHEN a.SettlementStatusID > 0 THEN 'Completed'
									ELSE '' 
								END
		,AutoSettleFastMarket = CASE 
									WHEN a.FM_SettlementStatusID IS NULL THEN 'N/A'
									WHEN a.FM_SettlementStatusID = 0 THEN 'Running'
									WHEN a.FM_SettlementStatusID > 0 THEN 'Completed'
									ELSE ''
								END
	FROM @TempMatch t
	INNER JOIN @TmpAutoSettle1s tt ON t.MatchId = tt.MatchId
		
	DECLARE @TmpBetCount TABLE (MatchId INT, IsExistFGLG INT, IsExistHTFGLG INT)
	INSERT INTO @TmpBetCount(MatchId, IsExistFGLG, IsExistHTFGLG)
	SELECT b.matchid
		, SUM(CASE WHEN b.bettype = 14 THEN 1 ELSE 0 END) AS IsExistFGLG
		, SUM(CASE WHEN b.bettype = 127 THEN 1 ELSE 0 END) AS IsExistHTFGLG
	FROM dbo.bettrans b WITH(NOLOCK)
	WHERE b.matchid IN (SELECT MatchId FROM @TempMatch)
		AND b.bettype IN (14 , 127)
	GROUP BY b.matchid

	UPDATE t
	SET IsExistFGLG = CASE WHEN t.IsExistFGLG > 0 THEN 1 ELSE 0 END
		, IsExistHTFGLG = CASE WHEN t.IsExistHTFGLG > 0 THEN 1 ELSE 0 END
	FROM @TempMatch t
	INNER JOIN @TmpBetCount tt ON t.MatchId = tt.MatchId
	
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
		, AutoSettleResultStatus
		, tm.AutoSettleFastMarket
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

