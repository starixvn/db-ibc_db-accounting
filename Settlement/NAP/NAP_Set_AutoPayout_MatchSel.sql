USE bodb02
GO
ALTER PROCEDURE dbo.NAP_Set_AutoPayout_MatchSel @FromDate DATETIME
	, @ToDate DATETIME
	, @SportType SMALLINT = 0
	, @LeagueID INT = 0 -- 0 for ALL Leagues
	, @MatchCode NVARCHAR(50) = ''
	, @StatusId TINYINT = 0
	, @FilterBy TINYINT = 0
	, @AutoSettlementOnly BIT = 0 
	, @IsReLoad BIT = 0
	, @AutoPayoutOnly BIT = 0
	, @IsHTOverOnly BIT = 0
	, @IsOverOnly BIT = 0
AS
/*  
 Created by: 20160311@Patrick
 Task: Auto Payout - Match results for calculating settlement 
 DB: DBPRO/BODB02
 Original: Acc_Set_MatchSel
		 - NAP_Acc_Set_MatchSel
 Revisions:  
      
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

	SELECT @matchcode = ISNULL(@matchcode, ''), @LeagueID = ISNULL(@LeagueID, 0)
		, @filterBy = ISNULL(@filterBy, 0), @Today = GETDATE()

	-- if entering matcode, ignore other params (excep FromDate, ToDate, sport type)
	IF (@matchcode <> '')
	BEGIN
		SELECT @eventstatus = ''
			, @isRefund = NULL
			, @LeagueID = CASE WHEN @isReLoad = 1 THEN @LeagueID 
							ELSE 0 END -- reload partial; search on LeagueID, not reload: get all leagues
			, @UncalOnly = NULL
			, @UncalMultiOnly = NULL

		BEGIN TRY
			SET @matchid = CASE WHEN ISNUMERIC(@matchcode) = 1 THEN CAST(@matchcode AS INT)
							ELSE NULL END
		END TRY

		BEGIN CATCH
			SET @matchid = NULL
		END CATCH
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
		, matchid INT
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
		, WinOdds MONEY
		, PlaceOdds MONEY
		, IsAutoPayout BIT
		, IsExistCorner BIT
		, IsExistHTCorner BIT
		, IsNeedToCalculateFGLG BIT
		, IsNeedToCalculateCorner BIT
		, IsAutoPayoutForLeague BIT
		, IsExistResultandFirstTeamScore BIT)
	
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
		, 0 AS WinOdds
		, 0 AS PlaceOdds
		, CASE WHEN m.IsAutoPayout IS NULL THEN ISNULL(l.IsAutoPayout, 0)
					 WHEN m.IsAutoPayout = 1 THEN 1
				ELSE 0 END AS IsAutoPayout
		, 0 AS IsExistCorner
		, 0 AS IsExistHTCorner
		, 0 AS IsNeedToCalculateFGLG
		, 0 AS IsNeedToCalculateCorner
		, ISNULL(l.IsAutoPayout, 0) AS IsAutoPayoutForLeague
	FROM dbo.match m WITH (NOLOCK)
		INNER JOIN dbo.League l WITH(NOLOCK) ON m.leagueid = l.leagueid
		INNER JOIN dbo.match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
		LEFT JOIN dbo.CustInfo ci WITH(NOLOCK) ON mr.ConfirmHT > 0 AND mr.ConfirmHT = ci.custid
		LEFT JOIN dbo.CustInfo cci WITH(NOLOCK) ON mr.ConfirmFT > 0 AND mr.ConfirmFT = cci.custid
		LEFT JOIN dbo.ResultDetail r WITH (NOLOCK) ON m.matchID = r.MatchId AND r.ResourceId = '00'
	WHERE m.eventdate BETWEEN @FromDate AND @ToDate
		AND m.sporttype = 1 --soccer only
		AND m.leagueID = CASE WHEN @LeagueID <> 0 THEN @LeagueID ELSE m.leagueID END 			
		AND CASE WHEN @UncalMultiOnly = 0 THEN 1 
					WHEN @UncalMultiOnly = 1 THEN hthomescore * htawayscore * finalhomescore * finalawayscore
					WHEN @UncalMultiOnly IS NULL OR @UncalOnly IS NULL THEN 1
			END IS NOT NULL AND m.sporttype = CASE WHEN @sporttype = 0 THEN m.sporttype ELSE @sporttype END 
		AND (@matchcode = '' OR (m.matchid = @matchid OR m.matchcode = @matchcode))
		AND (@eventstatus = '' OR eventstatus IN (@eventstatus, 'internal')) 
		AND (@isRefund IS NULL
				OR (@isRefund = 1 AND betstatus LIKE 'Refund%') 
				OR (@isRefund = 0 AND ISNULL(betstatus, '') NOT LIKE 'Refund%')
			)
		AND 1 = CASE WHEN @AutoPayoutOnly = 0 THEN 1
						WHEN @AutoPayoutOnly = 1 AND m.IsAutoPayout IS NULL AND ISNULL(l.IsAutoPayout, 0) = 1 THEN 1
						WHEN @AutoPayoutOnly = 1 AND ISNULL(m.IsAutoPayout, 0) = 1 THEN 1
				ELSE 0 END
		AND 1 = CASE WHEN @IsHTOverOnly = 0 THEN 1
					WHEN @IsHTOverOnly = 1 
						AND m.eventstatus IN ('Closed', 'running', 'internal')
						AND mr.ishtcal = 0
						AND (mr.confirmHT <> 0 OR (DATEDIFF(MM, m.kickofftime, @Today) > 40 
													AND DATEDIFF(MM, m.kickofftime, @Today) < 100)) THEN 1
				ELSE 0 END
		AND 1 = CASE WHEN @IsOverOnly = 0 THEN 1
					WHEN @IsOverOnly = 1
						AND m.eventstatus <> N'Completed'
						AND (mr.ConfirmFT > 0 OR m.kickofftime < DATEADD(SS, - 6000, @Today)) THEN 1
				ELSE 0 END
		AND (@UncalOnly = 0 OR ISNULL(mr.calculate, 0) = 0 OR @UncalOnly IS NULL) 
		AND (@UncalMultiOnly = 0 OR ISNULL(mr.multiple, 0) = 0 OR @UncalMultiOnly IS NULL)
	
	;WITH BetStatus AS (
		SELECT b.matchid
			--, CASE WHEN b.bettype IN (14,127) THEN 1 ELSE 0 END IsFGLG
			, SUM(CASE WHEN b.bettype = 14 THEN 1 ELSE 0 END) AS IsExistFGLG
			, SUM(CASE WHEN b.bettype = 127 THEN 1 ELSE 0 END) AS IsExistHTFGLG
			, SUM(CASE WHEN b.bettype = 172 THEN 1 ELSE 0 END) AS IsExistResultandFirstTeamScore
			, SUM(CASE WHEN b.bettype IN (194, 195, 196, 197, 198, 199, 206, 208) THEN 1 ELSE 0 END) AS IsExistCorner
			, SUM(CASE WHEN b.bettype IN (200, 201, 202, 203, 204, 205, 207, 209) THEN 1 ELSE 0 END) AS IsExistHTCorner
		FROM DBTXN.bodb02.dbo.bettrans b 
		WHERE EXISTS (SELECT TOP 1 1 FROM #matchList m WHERE b.matchid = m.matchid)
			AND bettype IN (14, 127)--FGLG & ResultandFirstTeamScore
			AND bettype IN (194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209) --corner
			AND bettype IN (172)
		GROUP BY b.matchid--, CASE WHEN b.bettype IN (14,127) THEN 1 ELSE 0 END
	)

	UPDATE t
	SET IsExistFGLG = CASE WHEN tt.IsExistFGLG > 0 THEN 1 ELSE 0 END
		, IsExistHTFGLG = CASE WHEN tt.IsExistHTFGLG > 0 THEN 1 ELSE 0 END
		, IsExistResultandFirstTeamScore = CASE WHEN tt.IsExistResultandFirstTeamScore > 0 THEN 1 ELSE 0 END
		, IsExistCorner = CASE WHEN tt.IsExistCorner > 0 THEN 1 ELSE 0 END
		, IsExistHTCorner = CASE WHEN tt.IsExistHTCorner > 0 THEN 1 ELSE 0 END
	FROM #matchList t
		INNER JOIN BetStatus tt ON t.matchid = tt.matchid

	SET @Today = DATEADD(HH, -1, GETDATE())

	;WITH SingleTicket AS (
		SELECT matchid, MAX(IsCalculating) AS IsCalculating
		FROM DBTXN.bodb02.dbo.Single_Calculate_Queue s WITH(NOLOCK)
		WHERE Starttime > @Today AND s.IsCalculating IN (0,1)
		GROUP BY matchid
	), ParlayTicket AS (
		SELECT p.matchid, min(IsCalculating)  IsCalculating
		FROM DBTXN.bodb02.dbo.Parlay_Calculate_Queue p WITH(NOLOCK)
		WHERE Starttime > @Today AND p.IsCalculating IN (0,1)
		GROUP BY matchid
	)	

	SELECT ISNULL(sg.matchid, pl.matchid) AS matchid
		, sg.IsCalculating AS IsCalculatingSingle
		, pl.IsCalculating AS IsCalculatingMP
	INTO #tempmatch
	FROM SingleTicket sg
		FULL OUTER JOIN ParlayTicket pl ON sg.matchid = pl.matchid 

	CREATE TABLE #tmpAutoSettle1s(MatchID INT, SettlementStatusID TINYINT)

	INSERT INTO #tmpAutoSettle1s(MatchID, SettlementStatusID)
	SELECT MatchID, MIN(SettlementStatusID)
	FROM dbo.ResultDetail WITH (NOLOCK)
	WHERE @Sporttype IN (0, 1)
		AND MatchID IN (SELECT MatchID FROM #matchList)
		AND (ResourceID IN ('135','168','173','174','175','176','192','193','210','211','212','213','214','215','216','217')
				OR ResourceID LIKE '160__'
				OR ResourceID LIKE '164__'
				OR ResourceID LIKE '169__'
				OR ResourceID LIKE '180__'
				OR ResourceID LIKE '216__')
	GROUP BY MatchID

	CREATE TABLE #tmpCornerBets(MatchID	INT, SettlementStatusID	TINYINT)

	INSERT INTO #tmpCornerBets(MatchID, SettlementStatusID)
	SELECT MatchID, MIN(SettlementStatusID)
	FROM dbo.ResultDetail WITH (NOLOCK)
	WHERE @Sporttype IN(0, 1)
		AND MatchID IN (SELECT MatchID FROM #matchList)
		AND ResourceID IN ('04','05','206','207','208','209')			
	GROUP BY MatchID 

	IF @AutoSettlementOnly = 1 --Running Auto bettypes ONLY ( BETRADAR USED)
	BEGIN
		DELETE FROM #matchList
		WHERE MatchID NOT IN (SELECT MatchID FROM #tmpAutoSettle1s WHERE SettlementStatusID = 0)
	END

	IF @StatusID = 5 
	BEGIN
		DELETE FROM #matchList
		WHERE MatchID NOT IN (SELECT MatchID FROM #tmpCornerBets WHERE SettlementStatusID = 0)
	END

	--;WITH PayoutResult AS (
	--	SELECT rs.MatchId
	--		, MAX(CASE WHEN rs.CalculationType = 1 THEN 1 ELSE 0 END) AS HTStatus
	--		, MAX(CASE WHEN rs.CalculationType = 2 THEN 1 ELSE 0 END) AS FTStatus
	--	FROM dbo.AutoPayoutResult rs WITH(NOLOCK)
	--	WHERE EXISTS (SELECT TOP 1 1 FROM #matchList t WHERE rs.MatchId = t.matchid AND t.eventstatus = 'running')
	--		AND StatusId IN (1, 2)
	--	GROUP BY rs.MatchId
	--)

	----update status of match in order to can be calc FGLG & Corner bettype manually
	--UPDATE t
	--SET IsNeedToCalculateFGLG = CASE WHEN rs.HTStatus = 1 
	--									AND t.IsHalfTimeCal = 1 
	--									AND rs.FTStatus IN (0,1) 
	--									AND t.IsExistHTFGLG = 1 THEN 1 --can calc HT FGLG
	--								WHEN rs.HTStatus = 1 
	--									AND t.IsHalfTimeCal = 1 
	--									AND rs.FTStatus = 1
	--									AND t.IsExistFGLG = 1 THEN 1 --can calc FT FGLG
	--							ELSE 0 END
	--	, IsNeedToCalculateCorner = CASE WHEN rs.HTStatus = 1 
	--									AND t.IsHalfTimeCal = 1 
	--									AND rs.FTStatus IN (0,1) 
	--									AND t.IsExistHTCorner = 1 THEN 1 --can calc HT Corner
	--								WHEN rs.HTStatus = 1 
	--									AND t.IsHalfTimeCal = 1 
	--									AND rs.FTStatus = 1
	--									AND t.IsExistCorner = 1 THEN 1 --can calc FT Corner
	--							ELSE 0 END
									
	--FROM #matchList t
	--	INNER JOIN PayoutResult rs ON t.matchid = rs.MatchId

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
		, IsAutoPayout
		, CASE WHEN (m.IsHalfTimeCal = 1 OR ISNULL(IsCalculatingSingle, -1) IN (0,1) OR ISNULL(IsCalculatingMP, -1) IN (0,1))
					AND m.IsExistHTFGLG = 1 AND m.IsCalculated = 0 THEN 1 --can calc HT FGLG
				WHEN (m.IsCalculated = 1 OR ISNULL(IsCalculatingSingle, 0) IN (0,1) OR ISNULL(IsCalculatingMP, -1) IN (0,1))
					AND m.IsHalfTimeCal = 1	AND (m.IsExistFGLG = 1 OR m.IsExistResultandFirstTeamScore = 1) THEN 1 --can calc FT FGLG
				ELSE 0 END AS IsNeedToCalculateFGLG
		, CASE WHEN (m.IsHalfTimeCal = 1 OR ISNULL(IsCalculatingSingle, -1) IN (0,1) OR ISNULL(IsCalculatingMP, -1) IN (0,1))
					AND m.IsExistHTCorner = 1 AND m.IsCalculated = 0 THEN 1 --can calc HT Corner
				WHEN (m.IsCalculated = 1 OR ISNULL(IsCalculatingSingle, -1) IN (0,1) OR ISNULL(IsCalculatingMP, -1) IN (0,1))
					AND m.IsHalfTimeCal = 1	AND m.IsExistCorner = 1 THEN 1 --can calc FT Corner
				ELSE 0 END AS IsNeedToCalculateCorner
		--, IsNeedToCalculateFGLG
		--, IsNeedToCalculateCorner
		, IsAutoPayoutForLeague
	FROM #matchList m
		LEFT JOIN #tempmatch t ON t.matchid = m.matchid
		LEFT JOIN #tmpAutoSettle1s a WITH (NOLOCK) ON m.matchID = a.MatchID
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
	DROP TABLE #tmpCornerBets
END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_AutoPayout_MatchSel] TO [bodbAdminNet] AS [dbo]
GO
