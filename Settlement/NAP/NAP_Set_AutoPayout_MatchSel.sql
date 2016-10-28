USE bodb02
GO
ALTER PROCEDURE dbo.NAP_Set_AutoPayout_MatchSel
	@FromDate 				DATETIME
	, @ToDate 				DATETIME
	, @SportType 			SMALLINT = 0
	, @LeagueID 			INT = 0 -- 0 for ALL Leagues
	, @MatchCode 			NVARCHAR(50) = ''
	, @StatusId 			TINYINT = 0
	, @FilterBy 			TINYINT = 0
	, @AutoSettlementOnly 	BIT = 0 
	, @IsReLoad 			BIT = 0
	, @IsHTOverOnly 		BIT = 0
	, @IsOverOnly 			BIT = 0
	, @AutoSetting 			TINYINT = 0
AS
/*  
 Created by: 20160311@Patrick
 Task: Auto Payout - Match results for calculating settlement 
 DB: DBTXN/BODB02
 Original: Acc_Set_MatchSel
		 - NAP_Acc_Set_MatchSel
 Revisions:  
	- 20160801@Patrick: Auto Payout - User can cal MP before calculating FT FGLG [Redmine: #61767]
	- 20160713@Patrick: PH-AIO phase 2 (67 bettypes ) [Redmine:#53154]
	- 20160808@Kathy: BetTrade - changes for new commercial terms - add bettype 904 [Redmine:#61905]
	- 20160930@Bobby: #65002 - Implement Auto CAL page info: update Instant match status & enable link FGLG when existing parlay tickets
	- 20161026@Bobby: #65002 - Do refactor code and move to DBTXN
      
 Param explanation:  
	@MatchCode: match code
	@LeagueID: = 0: show info of all leagues     
	@StatusId: 0: all, 1: running; 2: closed; 3: completed; 4: refund; 5: Completed (Running Corner)
	@FilterBy: 0: none, 1: un-calculated game; 2: Un-calculated multiple only; 3: all
	@PenaltyShootoutOnly: 0: none; 1: running penalty shootout only
	@IsReLoad: 1: reload partial matches of a league, 0: not reload
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @UncalOnly BIT, @UncalMultiOnly BIT, @EventStatus NVARCHAR(50), @IsRefund BIT
		, @MatchId INT, @Today DATETIME

	SELECT @matchcode 	= ISNULL(@matchcode, '')
		, @LeagueID 	= ISNULL(@LeagueID, 0)
		, @filterBy 	= ISNULL(@filterBy, 0)
		, @Today 		= GETDATE()
		, @MatchId 		= 0
		--, @AutoSetting 	= CAST(ISNULL(@AutoPayoutOnly,0) AS TINYINT) + POWER(2*ISNULL(@InstantCalOnly, 0),1)

	-- if entering matcode, ignore other params (excep FromDate, ToDate, sport type)
	IF @matchcode <> ''
	BEGIN
		SELECT @eventstatus = '', @isRefund = NULL, @UncalOnly = NULL, @UncalMultiOnly = NULL
			, @LeagueID = CASE WHEN @isReLoad = 1 THEN @LeagueID 
							ELSE 0 END -- reload partial; search on LeagueID, not reload: get all leagues
		IF ISNUMERIC(@matchcode) = 1
		BEGIN
			SET @MatchId = CAST(@matchcode AS INT)
		END
		ELSE
		BEGIN
			SELECT @MatchId = matchid
			FROM dbo.match m WITH(NOLOCK) WHERE matchcode = @matchcode
		END
	END
	ELSE
	BEGIN
		SELECT @eventstatus = CASE @statusid WHEN 1 THEN 'running'
								WHEN 2 THEN 'closed'
								WHEN 3 THEN 'completed'
								WHEN 5 THEN 'running'
								ELSE ''	END
			, @isRefund = CASE @statusid WHEN 4 THEN 1
							WHEN 0 THEN NULL
							ELSE 0 END
			, @UncalOnly = CASE WHEN @filterBy IN (3, 1) THEN 1
							ELSE 0 END
			, @UncalMultiOnly = CASE WHEN @filterBy IN (3, 2) THEN 1
								ELSE 0 END

		--ignore event status if selecting filterby
		IF (@UncalMultiOnly = 1 OR @UncalOnly = 1 OR @AutoSettlementOnly = 1)
			SELECT @eventstatus = '', @isRefund = NULL
	END

	CREATE TABLE #matchList (HalfTimeHomeScore INT
		, HalfTimeAwayScore INT
		, IsCalculated BIT
		, IsMultiCaled BIT
		, IsRefund BIT
		, IsCalRefund BIT
		, matchid INT PRIMARY KEY
		, leagueid INT
		, homeid INT
		, awayid INT
		, matchcode NVARCHAR(50)
		, kickofftime DATETIME
		, finalhomescore INT
		, finalawayscore INT
		, betstatus NVARCHAR(50)
		, eventstatus NVARCHAR(50)
		, SettlementStatus135 tinyint
		, Foddsstatus VARCHAR(10)
		, sporttype SMALLINT
		, IsNeutral BIT
		, eventdate DATETIME
		, goalrecord VARCHAR(50)
		, suspenderHalfTime NVARCHAR(50)
		, suspenderFullTime NVARCHAR(50)
		, IsHalfTimeCal BIT
		, calculate BIT
		, isPending BIT
		, isUndecided BIT
		, IsKeyscore BIT
		, IsExistFGLG BIT
		, IsExistHTFGLG BIT
		, IsExistRunningFGLG BIT
		, IsExistRunningHTFGLG BIT
		, WinOdds MONEY
		, PlaceOdds MONEY
		, AutoSetting TINYINT
		, IsExistRunningCorner BIT
		, IsExistRunningHTCorner BIT
		, IsNeedToCalculateFGLG BIT
		, IsNeedToCalculateCorner BIT
		, AutoSettingForLeague TINYINT
		--, IsExistRunningResultandFirstTeamScore BIT
		, BetCount INT
		, IsEnabledGoalRecordHT BIT
		, IsEnabledGoalRecordFT BIT
		, LivePeriod	TINYINT
		, IsHT			BIT
		, livehomescore	INT
		, liveawayscore	INT
	)
	--for instant match info
	CREATE TABLE #InstMatchInfo (
		MatchId 					INT
		, InstantHomeScore 			VARCHAR(50)
		, InstantAwayScore 			VARCHAR(50)
		, InstantStatusId 			TINYINT
		, InstantCalculationType 	TINYINT DEFAULT(0)
		, InstantPriority 			TINYINT
		, isPending					BIT
		, isUndecided				BIT
	)
	
	CREATE TABLE #tempBettrans (matchid INT, bettype SMALLINT, runningBet INT, betCount INT, IsParlay BIT DEFAULT(0))
	CREATE CLUSTERED INDEX IX_tempBettrans_bettype ON #tempBettrans (bettype)
	
	CREATE TABLE #tmpAutoSettle1s(MatchID INT, SettlementStatusID TINYINT)

	INSERT INTO #matchList
	SELECT m.hthomescore
		, m.htawayscore
		, ISNULL(mr.calculate, 0) IsCalculated
		, ISNULL(mr.multiple, 0) IsMultiCaled
		, ISNULL(mr.refund, 0) IsRefund
		, ISNULL(mr.calrefund, 0) IsCalRefund
		, m.matchid
		, m.leagueid
		, m.homeid
		, m.awayid
		, m.matchcode
		, m.kickofftime
		, m.finalhomescore
		, m.finalawayscore
		, m.betstatus
		, CASE WHEN m.betstatus LIKE 'Refund FT%' THEN 'Refund FT'
					WHEN m.betstatus LIKE 'Refund HT%' THEN 'Refund HT'
					WHEN m.betstatus LIKE 'Refund%' THEN 'Refund'
					ELSE m.eventstatus END AS eventstatus
		, ISNULL(mr.SettlementStatus135,0) as SettlementStatus135
		, '' AS Foddsstatus
		, m.sporttype
		, ISNULL(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
		, m.eventdate
		, m.goalrecord
		, ISNULL(ci.username, '') AS suspenderHT
		, ISNULL(cci.username, '') AS suspenderFT
		--, CASE WHEN mr.ConfirmHT = 0 THEN ''
		--	ELSE (SELECT username
		--			FROM dbo.custinfo WITH (NOLOCK)
		--			WHERE custid = mr.ConfirmHT) END suspenderHT
		--, CASE WHEN mr.ConfirmFT = 0 THEN ''
		--	ELSE (SELECT username
		--			FROM dbo.custinfo WITH (NOLOCK)
		--			WHERE custid = mr.ConfirmFT) END suspenderFT
		, ISNULL(mr.IsHTCal, 0) AS IsHTCal
		, ISNULL(mr.calculate, 0) AS calculate
		, ISNULL(mr.isPending, 0) AS isPending
		, ISNULL(mr.isUndecided, 0) AS isUndecided
		, CASE WHEN hthomescore IS NOT NULL 
						AND htawayscore IS NOT NULL 
						AND finalhomescore IS NOT NULL 
						AND finalawayscore IS NOT NULL THEN 1
			ELSE 0 END IsKeyscore
		, 0 AS IsExistFGLG
		, 0 AS IsExistHTFGLG
		, 0 AS IsExistRunningFGLG
		, 0 AS IsExistRunningHTFGLG
		, 0 AS WinOdds
		, 0 AS PlaceOdds
		, ISNULL(m.AutoSetting, ISNULL(l.AutoSetting, 0)) AS AutoSetting
		, 0 AS IsExistRunningCorner
		, 0 AS IsExistRunningHTCorner
		, 0 AS IsNeedToCalculateFGLG
		, 0 AS IsNeedToCalculateCorner
		, ISNULL(l.AutoSetting, 0) AS AutoSettingForLeague
		--, 0 AS IsExistRunningResultandFirstTeamScore
		, 0 AS BetCount
		, 0 AS IsEnabledGoalRecordHT
		, 0 AS IsEnabledGoalRecordFT
		, mr.LivePeriod
		, mr.IsHT
		, m.livehomescore
		, m.liveawayscore
	FROM dbo.match m WITH (NOLOCK)
		INNER JOIN dbo.match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
		INNER JOIN dbo.League l WITH(NOLOCK) ON m.leagueid = l.leagueid
		LEFT JOIN CustDB.dbo.CustInfo ci WITH(NOLOCK) ON mr.ConfirmHT > 0 AND mr.ConfirmHT = ci.custid
		LEFT JOIN CustDB.dbo.CustInfo cci WITH(NOLOCK) ON mr.ConfirmFT > 0 AND mr.ConfirmFT = cci.custid
		--LEFT JOIN dbo.ResultDetail r WITH (NOLOCK) ON m.matchID = r.MatchId AND r.ResourceId = '00'
	WHERE m.eventdate BETWEEN @FromDate AND @ToDate
		AND m.sporttype = 1 --soccer only
		AND m.leagueID = CASE WHEN @LeagueID <> 0 THEN @LeagueID ELSE m.leagueID END 			
		AND CASE WHEN @UncalMultiOnly = 0 THEN 1 
					WHEN @UncalMultiOnly = 1 THEN hthomescore * htawayscore * finalhomescore * finalawayscore
					WHEN @UncalMultiOnly IS NULL OR @UncalOnly IS NULL THEN 1
			END IS NOT NULL AND m.sporttype = CASE WHEN @sporttype = 0 THEN m.sporttype ELSE @sporttype END 
		AND (@MatchId = 0 OR (@MatchId <> 0 AND m.matchid = @matchid))
		AND (@eventstatus = '' OR eventstatus IN (@eventstatus, 'internal')) 
		AND (@isRefund IS NULL
				OR (@isRefund = 1 AND betstatus LIKE 'Refund%') 
				OR (@isRefund = 0 AND ISNULL(betstatus, '') NOT LIKE 'Refund%')
			)
		AND 1 = CASE WHEN @IsHTOverOnly = 0 THEN 1
					WHEN @IsHTOverOnly = 1 
						AND m.eventstatus IN ('Closed', 'running', 'internal')
						AND mr.ishtcal = 0
						AND (mr.confirmHT <> 0 OR (DATEDIFF(MINUTE, m.kickofftime, @Today) > 40 
													AND DATEDIFF(MINUTE, m.kickofftime, @Today) < 100)) THEN 1
				ELSE 0 END
		AND 1 = CASE WHEN @IsOverOnly = 0 THEN 1
					WHEN @IsOverOnly = 1
						AND m.eventstatus <> N'Completed'
						AND (mr.ConfirmFT > 0 OR m.kickofftime < DATEADD(SS, - 6000, @Today)) THEN 1
				ELSE 0 END
		AND (@UncalOnly = 0 OR ISNULL(mr.calculate, 0) = 0 OR @UncalOnly IS NULL) 
		AND (@UncalMultiOnly = 0 OR ISNULL(mr.multiple, 0) = 0 OR @UncalMultiOnly IS NULL)
		
	--check auto setting
	IF (@AutoSetting > 0)
	BEGIN
		DELETE m
		FROM #matchList m
		WHERE @AutoSetting & m.AutoSetting <> @AutoSetting
	END
	
	BEGIN --update status
		DECLARE @n INT = 2147483647
		
		
		--checking bettrans
		INSERT INTO #tempBettrans (matchid, bettype, runningBet, betCount)
		SELECT m.matchid
			,b.bettype
			,b.runningBet
			,b.betCount
		FROM (SELECT TOP (@n) MatchId FROM #matchList) AS m
			CROSS APPLY 
			(
				SELECT	b.bettype
						,SUM(CASE 
								WHEN b.statusID = 0 AND GETDATE() > '20160801' THEN 1 -- using hint to force Compute Scalar included in Aggregate Operator 
								ELSE 0 
							END) AS runningBet
						,COUNT(1) AS betCount
				FROM dbo.bettrans b WITH(NOLOCK)
				WHERE b.matchid = m.MatchId
				GROUP BY b.bettype
			) AS b
		OPTION (OPTIMIZE FOR (@n = 1))	-- using hint to force Optimize execute temp table first
	
		;WITH BetStatus AS (
			SELECT b.matchid
				, SUM(ISNULL(b.betCount, 0)) AS BetCount
				, SUM(CASE WHEN f.GroupId = 4 THEN 1 ELSE 0 END) AS IsExistFGLG
				, SUM(CASE WHEN f.GroupId = 3 THEN 1 ELSE 0 END) AS IsExistHTFGLG
				, SUM(CASE WHEN f.GroupId = 4 AND (b.runningBet > 0) THEN 1 ELSE 0 END) AS IsExistRunningFGLG
				, SUM(CASE WHEN f.GroupId = 3 AND (b.runningBet > 0) THEN 1 ELSE 0 END) AS IsExistRunningHTFGLG
				, SUM(CASE WHEN f.GroupId = 6 AND b.runningBet > 0 THEN 1 ELSE 0 END) AS IsExistRunningCorner
				, SUM(CASE WHEN f.GroupId = 5 AND b.runningBet > 0 THEN 1 ELSE 0 END) AS IsExistRunningHTCorner
				, SUM(CASE WHEN f.GroupId = 1 AND f.IsUsedGoalRecordValue = 1 AND b.betCount > 0 THEN 1 ELSE 0 END) AS IsEnabledGoalRecordHT
				, SUM(CASE WHEN f.GroupId = 2 AND f.IsUsedGoalRecordValue = 1 AND b.betCount > 0 THEN 1 ELSE 0 END) AS IsEnabledGoalRecordFT
				, SUM(CASE WHEN f.GroupId = 1 AND f.IsUsedGoalRecordValue = 1 AND b.runningBet > 0 THEN 1 ELSE 0 END) AS IsExistRunningUseGoalRecordHT
				, SUM(CASE WHEN f.GroupId = 2 AND f.IsUsedGoalRecordValue = 1 AND b.runningBet > 0 THEN 1 ELSE 0 END) AS IsExistRunningUseGoalRecordFT
			from #tempBettrans b
				INNER JOIN dbo.f_Set_GetGroupBettypes() f 
				ON b.bettype = f.BetType
			
			GROUP BY b.matchid
		)
		UPDATE t
		SET IsExistFGLG = CASE WHEN tt.IsExistFGLG > 0 THEN 1 ELSE 0 END
			, IsExistHTFGLG = CASE WHEN tt.IsExistHTFGLG > 0 THEN 1 ELSE 0 END
			, IsExistRunningFGLG = CASE WHEN tt.IsExistRunningFGLG > 0 OR tt.IsExistRunningUseGoalRecordFT > 0 THEN 1 ELSE 0 END
			, IsExistRunningHTFGLG = CASE WHEN tt.IsExistRunningHTFGLG > 0 OR tt.IsExistRunningUseGoalRecordHT > 0 THEN 1 ELSE 0 END
			, IsExistRunningCorner = CASE WHEN tt.IsExistRunningCorner > 0 THEN 1 ELSE 0 END
			, IsExistRunningHTCorner = CASE WHEN tt.IsExistRunningHTCorner > 0 THEN 1 ELSE 0 END
			, IsEnabledGoalRecordHT = CASE WHEN tt.IsEnabledGoalRecordHT > 0 THEN 1 ELSE 0 END
			, IsEnabledGoalRecordFT = CASE WHEN tt.IsEnabledGoalRecordFT > 0 THEN 1 ELSE 0 END
			, BetCount = tt.BetCount
		FROM #matchList t
			INNER JOIN BetStatus tt ON t.matchid = tt.matchid
	
		
	
		--checking bettransm
		IF(EXISTS(SELECT TOP 1 1 FROM #matchList WHERE IsExistFGLG = 0 OR IsExistHTFGLG = 0 OR IsExistRunningFGLG = 0 OR IsExistRunningHTFGLG = 0))
		BEGIN
			INSERT INTO #tempBettrans (matchid, bettype, runningBet, betCount, IsParlay)
			SELECT	m.matchid
				,b.bettype
				,b.runningBetFGLG
				,b.betCountFGLG
				,1 AS IsParlay
			FROM (
					SELECT TOP (@n) MatchId 
					FROM #matchList
					WHERE IsExistFGLG = 0 
						OR IsExistHTFGLG = 0 
						OR IsExistRunningFGLG = 0 
						OR IsExistRunningHTFGLG = 0
				) AS m
				CROSS APPLY 
				(
					SELECT	b.bettype
							,SUM(CASE 
									WHEN b.statusID = 0 AND GETDATE() > '20160801' THEN 1 -- using hint to force Compute Scalar included in Aggregate Operator 
									ELSE 0 
								END) AS runningBetFGLG
							,COUNT(1) AS betCountFGLG
					FROM	dbo.bettransm b WITH(NOLOCK)
					WHERE	b.matchid = m.MatchId AND bettype IN (14,127)
							AND b.statusID NOT BETWEEN 101 AND 103
					GROUP BY b.bettype
				) AS b
			OPTION (OPTIMIZE FOR (@n = 1))	-- using hint to force Optimize execute temp table first
	
			;WITH BetStatusM AS (
				SELECT b.matchid
					, SUM(CASE WHEN f.GroupId = 4 AND (b.betCount > 0) THEN 1 ELSE 0 END) AS IsExistFGLG
					, SUM(CASE WHEN f.GroupId = 3 AND (b.betCount > 0) THEN 1 ELSE 0 END) AS IsExistHTFGLG
					, SUM(CASE WHEN f.GroupId = 4 AND (b.runningBet > 0) THEN 1 ELSE 0 END) AS IsExistRunningFGLG
					, SUM(CASE WHEN f.GroupId = 3 AND (b.runningBet > 0) THEN 1 ELSE 0 END) AS IsExistRunningHTFGLG
				FROM #tempBettrans b WITH(NOLOCK)
					INNER JOIN dbo.f_Set_GetGroupBettypes() f 
					ON b.bettype = f.BetType AND b.IsParlay = 1
					
				GROUP BY b.matchid
			)

			UPDATE t
			SET IsExistFGLG = CASE WHEN t.IsExistFGLG = 1 OR tt.IsExistFGLG > 0 THEN 1 ELSE 0 END
				, IsExistHTFGLG = CASE WHEN t.IsExistHTFGLG = 1 OR tt.IsExistHTFGLG > 0 THEN 1 ELSE 0 END
				, IsExistRunningFGLG = CASE WHEN t.IsExistRunningFGLG = 1 OR tt.IsExistRunningFGLG > 0 THEN 1 ELSE 0 END
				, IsExistRunningHTFGLG = CASE WHEN t.IsExistRunningHTFGLG = 1 OR tt.IsExistRunningHTFGLG > 0 THEN 1 ELSE 0 END
			FROM #matchList t
				INNER JOIN BetStatusM tt 
				ON t.matchid = tt.matchid
		END
	END
	
	SET @Today = DATEADD(HH, -1, GETDATE())

	;WITH SingleTicket AS (
		SELECT matchid, MAX(IsCalculating) AS IsCalculating
		FROM dbo.Single_Calculate_Queue s WITH(NOLOCK)
		WHERE Starttime > @Today AND s.IsCalculating IN (0,1)
		GROUP BY matchid
	), ParlayTicket AS (
		SELECT p.matchid, min(IsCalculating)  IsCalculating
		FROM dbo.Parlay_Calculate_Queue p WITH(NOLOCK)
			INNER JOIN dbo.match m WITH (NOLOCK)
			ON p.matchid = m.matchid
		WHERE p.Starttime > @Today
			AND p.IsCalculating IN (0,1)
			AND m.sporttype = 1
			AND m.leagueid = CASE WHEN @LeagueId = 0 THEN m.leagueid ELSE @LeagueId END
		GROUP BY p.matchid
	)	

	SELECT ISNULL(sg.matchid, pl.matchid) AS matchid
		, sg.IsCalculating AS IsCalculatingSingle
		, pl.IsCalculating AS IsCalculatingMP
	INTO #tempmatch
	FROM SingleTicket sg
		FULL OUTER JOIN ParlayTicket pl ON sg.matchid = pl.matchid 
	
	BEGIN --Auto Betradar
		DECLARE @tblAutoBetradar TABLE (matchid INT, ResourceID VARCHAR(20) )
		INSERT INTO @tblAutoBetradar (matchid, ResourceID)
		SELECT t.matchid 
			, t.bettype AS ResourceID
		FROM #tempBettrans t 
			INNER JOIN dbo.f_Set_GetGroupBettypes() bt 
			ON t.bettype = bt.bettype		
		WHERE bt.GroupId = 8

		INSERT INTO #tmpAutoSettle1s(MatchID, SettlementStatusID)
		SELECT m.MatchID
			, MIN(rs.SettlementStatusID)
		FROM @tblAutoBetradar AS m
			INNER JOIN DBPRO.bodb02.dbo.ResultDetail rs WITH (NOLOCK) 
			ON m.matchid = rs.MatchId AND (m.ResourceID = rs.ResourceId OR rs.ResourceID LIKE m.ResourceID + '__')
		GROUP BY m.matchid 

		IF @AutoSettlementOnly = 1 --Running Auto bettypes ONLY ( BETRADAR USED)
		BEGIN
			DELETE FROM #matchList
			WHERE MatchID NOT IN (SELECT MatchID FROM #tmpAutoSettle1s WHERE SettlementStatusID = 0)
		END
	END
	
	IF @StatusID = 5 --match-conner
	BEGIN
		
		;WITH CTE_MatchConner  AS (
			SELECT t.MatchID
			FROM #tempBettrans t 
				INNER JOIN dbo.f_Set_GetGroupBettypes() bt 
				ON t.bettype = bt.bettype
				
			WHERE bt.GroupId IN (5,6)
			GROUP BY t.matchid 
		),tmpCornerBets AS (
			SELECT m.matchId
				, rs.SettlementStatusID
			FROM CTE_MatchConner m
				CROSS APPLY (
					SELECT MIN(rs.SettlementStatusID) AS SettlementStatusID
					FROM DBPRO.bodb02.dbo.ResultDetail rs WITH (NOLOCK)
					WHERE rs.matchId = m.matchId 
					AND rs.ResourceID IN ('04','05','206','207','208','209')
				) AS rs
		)
		DELETE FROM #matchList
		WHERE MatchID NOT IN (SELECT MatchID FROM tmpCornerBets WHERE SettlementStatusID = 0)
	END

	;WITH PayoutResult AS (
		SELECT t.MatchId
			, MAX(CASE WHEN rs.CalculationType = 1 THEN 1 ELSE 0 END) AS HTStatus
			, MAX(CASE WHEN rs.CalculationType = 2 THEN 1 ELSE 0 END) AS FTStatus
		FROM #matchList t 
			INNER JOIN DBPRO.bodb02.dbo.AutoPayoutResult rs WITH(NOLOCK) 
			ON t.matchId = rs.matchId
		WHERE t.eventstatus IN ('running', 'Completed')
			AND 1 & t.AutoSetting = 1
			AND rs.StatusId IN (1, 2)
			AND rs.CalculationType IN (1, 2)
		GROUP BY t.MatchId
		
	)
	--update status of match in order to can be calc FGLG & Corner bettype manually
	UPDATE t
	SET IsNeedToCalculateFGLG = CASE WHEN rs.HTStatus = 1 
										AND t.IsHalfTimeCal = 1 
										AND rs.FTStatus IN (0, 1) 
										AND t.IsExistRunningHTFGLG = 1 THEN 1 --can calc HT FGLG
									WHEN rs.FTStatus = 1
										AND t.IsHalfTimeCal = 1
										AND t.IsExistRunningFGLG = 1 THEN 1 --can calc FT FGLG
								ELSE 0 END
		, IsNeedToCalculateCorner = CASE WHEN rs.HTStatus = 1
										AND t.IsHalfTimeCal = 1
										AND rs.FTStatus IN (0, 1) 
										AND t.IsExistRunningHTCorner = 1 THEN 1 --can calc HT Corner
									WHEN rs.FTStatus = 1
										AND t.IsHalfTimeCal = 1
										AND t.IsExistRunningCorner = 1 THEN 1 --can calc FT Corner
								ELSE 0 END
									
	FROM #matchList t
		INNER JOIN PayoutResult rs ON t.matchid = rs.MatchId
	
	--Checking for Inst match info
	IF (@AutoSetting = 0 OR 2 & @AutoSetting = 2)
	BEGIN 
		INSERT INTO #InstMatchInfo (MatchId, InstantHomeScore, InstantAwayScore, InstantStatusId,InstantCalculationType,InstantPriority, isPending, isUndecided)
		SELECT t.MatchId
			, 0 AS HomeValue
			, 0 AS AwayValue
			, 0 AS StatusId
			, 0 AS CalculationType
			, 4 AS Priority
			, t.isPending
			, t.isUndecided
		FROM #matchList t 
		WHERE 2 & t.AutoSetting = 2
			AND t.eventstatus IN ('running')
		
		;WITH InstMatchConfirm AS (
			SELECT temp.MatchId
				,temp.HomeValue
				,temp.AwayValue
				, 1 AS StatusId --to Confirm
				,temp.CalculationType
			FROM (
				SELECT prd.MatchId
					, prd.HomeValue
					, prd.AwayValue
					, prd.TypeId AS CalculationType
					, prd.IsConfirmed
					, ROW_NUMBER() OVER(
						PARTITION BY prd.matchID
						ORDER BY ProviderResultDetailId DESC
					) AS RowIdx
				FROM #InstMatchInfo m
					INNER JOIN DBPRO.bodb02.dbo.ProviderResultDetail prd WITH(NOLOCK)
					ON m.matchid = prd.matchID
				WHERE prd.TypeId IN (101, 102)
					AND m.isPending = 0
					AND m.isUndecided = 0
			
			) AS temp
				LEFT JOIN DBPRO.bodb02.dbo.AutoPayoutResult aps WITH(NOLOCK)
					ON temp.matchid = aps.matchID
					AND temp.CalculationType = aps.CalculationType
					AND temp.HomeValue 	= aps.HomeValue
					AND temp.AwayValue 	= aps.AwayValue
					
			WHERE temp.RowIdx = 1
				AND (
					aps.StatusId IS NULL --not confirm yet
					OR aps.StatusId = 3 --FAILED to re-confirm
					OR (
						aps.StatusId = 2 --abnormal case -> re-calculate
						AND temp.IsConfirmed = 0
					)
				)
		)
		UPDATE d
		SET InstantHomeScore			= u.HomeValue
			, InstantAwayScore			= u.AwayValue
			, InstantStatusId			= u.StatusId
			, InstantCalculationType	= u.CalculationType
			, InstantPriority			= 3
		FROM #InstMatchInfo d
			INNER JOIN InstMatchConfirm u 
			ON d.matchID = u.matchID
			
		;WITH InstMatchInProgress AS (
			SELECT m.MatchId
				, aps.HomeValue
				, aps.AwayValue
				, 2 AS StatusId -- has confirmed
				, aps.CalculationType
			FROM #InstMatchInfo m
				INNER JOIN DBPRO.bodb02.dbo.AutoPayoutResult aps WITH(NOLOCK)
				ON m.matchid = aps.matchID
				
			WHERE aps.StatusId IN (1) --waiting & calculating
				AND aps.CalculationType IN (101, 102)	
		)
		UPDATE d
		SET InstantHomeScore			= u.HomeValue
			, InstantAwayScore			= u.AwayValue
			, InstantStatusId			= u.StatusId
			, InstantCalculationType	= u.CalculationType
			, InstantPriority			= 1
		FROM #InstMatchInfo d
			INNER JOIN InstMatchInProgress u 
			ON d.matchID = u.matchID
	END
	
	SELECT m.HalfTimeHomeScore
		, m.HalfTimeAwayScore
		, m.IsCalculated
		, m.IsMultiCaled
		, m.IsRefund
		, m.IsCalRefund
		, m.matchid
		, m.leagueid
		, m.homeid
		, m.awayid
		, m.matchcode
		, m.kickofftime
		, m.finalhomescore
		, m.finalawayscore
		, m.betstatus
		, m.eventstatus
		, m.Foddsstatus
		, m.sporttype
		, m.IsNeutral
		, m.eventdate
		, m.goalrecord
		, m.suspenderHalfTime
		, m.suspenderFullTime
		, m.IsHalfTimeCal
		, m.calculate
		, m.isPending
		, m.isUndecided
		, m.IsKeyscore
		, m.IsExistFGLG
		, m.IsExistHTFGLG
		, m.WinOdds
		, m.PlaceOdds
		, t.IsCalculatingSingle
		, t.IsCalculatingMP
		, CASE WHEN a.SettlementStatusID IS NULL THEN 'N/A'
				WHEN a.SettlementStatusID = 0 THEN 'Running'
				WHEN a.SettlementStatusID > 0 THEN 'Completed'
			ELSE '' END AS AutoSettleResultStatus
		, AutoSetting
		, IsNeedToCalculateFGLG
		, IsNeedToCalculateCorner
		, AutoSettingForLeague
		, IsEnabledGoalRecordHT
		, IsEnabledGoalRecordFT
		
		/*Instant match info*/
		, m.livehomescore
		, m.liveawayscore
		, m.IsHT
		, m.LivePeriod
		, ISNULL(im.InstantHomeScore, '') AS InstantHomeScore
		, ISNULL(im.InstantAwayScore,'') AS InstantAwayScore
		, ISNULL(im.InstantStatusId, 0) AS InstantStatusId
		, ISNULL(im.InstantCalculationType, 0) AS InstantCalculationType
		
	FROM #matchList m
		LEFT JOIN #tempmatch t ON t.matchid = m.matchid
		LEFT JOIN #tmpAutoSettle1s a WITH (NOLOCK) ON m.matchID = a.MatchID
		LEFT JOIN #InstMatchInfo im ON m.matchid = im.matchid
		
	WHERE 1 = CASE WHEN @IsHTOverOnly = 1 OR @IsOverOnly = 1 THEN CASE WHEN m.BetCount > 0 THEN 1 ELSE 0 END
				ELSE 1 END
	ORDER BY CASE m.eventstatus WHEN 'Completed' THEN 1 WHEN 'Refund' THEN 1 ELSE 0 END
		, m.eventdate
		, m.kickofftime
		, m.sporttype
		, m.leagueid
		, m.matchid
		, m.betstatus
		, m.matchcode
	
	
	DROP TABLE #tempmatch
	DROP TABLE #tmpAutoSettle1s
	DROP TABLE #matchList
	DROP TABLE #InstMatchInfo
	DROP TABLE #tempBettrans
END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_AutoPayout_MatchSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_AutoPayout_MatchSel] TO [vnteam] AS [dbo]
GO
