CREATE PROCEDURE [dbo].[NAP_Set_WaitingSel] @MatchCode NVARCHAR(50) = ''
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

	Param's explanation:  
		
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @matchid INT, @StartTime DATETIME, @EndTime	DATETIME, @SqlCommand VARCHAR(MAX)
	SELECT @MatchCode = ISNULL(@MatchCode, ''), @LeagueId = ISNULL(@LeagueID, 0), @SportType = ISNULL(@SportType, 0)

	IF ISNUMERIC(@MatchCode) = 1
		SET @matchid = CAST(@MatchCode AS INT)
	
	DECLARE @TempMatch TABLE (MatchId INT, SingleStatus INT, ParlayStatus INT, IsSingle BIT, IsMixParlay BIT, IsExistFGLG BIT, IsExistHTFGLG BIT, AutoSettleResultStatus VARCHAR(50))

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
	
	INSERT INTO @TempMatch(MatchId, SingleStatus, ParlayStatus, IsSingle, IsMixParlay, IsExistFGLG, IsExistHTFGLG, AutoSettleResultStatus)
	SELECT ISNULL(sg.matchid, pl.matchid) AS MatchId
		, sg.IsCalculating AS SingleStatus
		, pl.IsCalculating AS ParlayStatus
		, CAST(ISNULL(sg.IsCalculating, 0) AS BIT) AS IsSingle
		, CAST(ISNULL(pl.IsCalculating, 0) AS BIT) AS IsMixParlay
		, CONVERT(BIT, 0) AS IsExistFGLG
		, CONVERT(BIT, 0) AS IsExistHTFGLG
		, CONVERT(VARCHAR(50), 'N/A') AS AutoSettleResultStatus
	FROM SingleTicket sg
		FULL OUTER JOIN ParlayTicket pl ON sg.matchid = pl.matchid
	
	DECLARE @TmpAutoSettle1s TABLE (MatchId INT, ResultStatusID INT)
	INSERT INTO @TmpAutoSettle1s(MatchId, ResultStatusID)
	SELECT MatchId, MIN(ResultStatusID) AS ResultStatusID
	FROM DBPRO.bodb02.dbo.ResultDetail WITH (NOLOCK)
	WHERE @Sporttype IN (0, 1)
		AND MatchID IN (SELECT MatchID FROM @TempMatch)
		AND (ResourceID IN ('135','168','173','174','175','176','192','193','210','211','212','213','214','215','216','217')
				OR ResourceID LIKE '160__'
				OR ResourceID LIKE '164__'
				OR ResourceID LIKE '169__'
				OR ResourceID LIKE '180__'
				OR ResourceID LIKE '216__')
	GROUP BY MatchId

	UPDATE t
	SET AutoSettleResultStatus = CASE WHEN ResultStatusID IN (0, 1, 3) THEN 'Running'
										WHEN ResultStatusID IN (2, 5) THEN 'Completed'
									ELSE '' END
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

