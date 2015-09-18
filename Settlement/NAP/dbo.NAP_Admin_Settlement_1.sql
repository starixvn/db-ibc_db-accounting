USE [bodb02]
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_1] 
	@creator			INT
	,@matchid			INT
	,@fth				SMALLINT		= NULL
	,@fta				SMALLINT		= NULL
	,@hth				SMALLINT
	,@hta				SMALLINT
	,@goalrecord		VARCHAR(50)		= NULL
	,@betstatus			NVARCHAR(50)	= NULL 
	,@SetResult			VARCHAR(50)		= NULL 
	,@GameResult1		VARCHAR(MAX)	= NULL
	,@GameResult2		VARCHAR(MAX)	= NULL
	,@GameResult3		VARCHAR(MAX)	= NULL
	,@GameResult4		VARCHAR(MAX)	= NULL
	,@GameResult5		VARCHAR(MAX)	= NULL
	,@SelectedSet		VARCHAR(50)		= NULL 
	,@SelectedSet1Game	VARCHAR(MAX)	= NULL 
	,@SelectedSet2Game	VARCHAR(MAX)	= NULL 
	,@SelectedSet3Game	VARCHAR(MAX)	= NULL 
	,@SelectedSet4Game	VARCHAR(MAX)	= NULL 
	,@SelectedSet5Game	VARCHAR(MAX)	= NULL 
	,@fthCorners		SMALLINT		= NULL
	,@ftaCorners		SMALLINT		= NULL
	,@hthCorners		SMALLINT		= NULL
	,@htaCorners		SMALLINT		= NULL  
	,@ftFCorner			VARCHAR(1)		= NULL
	,@ftLCorner			VARCHAR(1)		= NULL
	,@htFCorner			VARCHAR(1)		= NULL
	,@htLCorner			VARCHAR(1)		= NULL 	
	,@isExcludeCorner	BIT				= 0 
	,@action			VARCHAR(10)		= 'CAL'
	,@IP				VARCHAR(50)		= ''
	,@ErrCode			INT				= 0		OUTPUT
	,@ErrMsg			NVARCHAR(200)	= ''	OUTPUT
AS
/*	Creator: Kathy
	Date: 20140213
	Task: main SP for settlement
	DB: DBTXN/BODB02
	Original: Admin_Settlement_1
	
	Revisions:
		- 20140423@Kathy: Remove check weekend peak-hour
		- 20140426@Kathy: Add 1H Total Goal and 1H FGLG bettypes (126, 127) [Redmine:#14449]
		- 20140617@Kathy: Apply BetRadar [Redmine:#17142]
		- 20140710@Kathy: Apply BetRadar - PenaltyShootout(135) [Redmine:#17142]
		- 20140808@Kathy: Support new 11 bettypes [Redmine:#19667]
		- 20140909@Kathy: Exclude virtual racing (bettype 1231,1232,1233, 1237, 1238), outright (bettype 10, 31, 32, 33),
						 sportting solution (from 1301 -> 1334), keno (1501 -> 1599)
		- 20140910@Kathy: Update SettlementStatus135 = 4 if the match hasn't any PS ticket [Redmine:#21560]
		- 20141009@Jamie: Sporting Solution for Tennis [Redmine:#23034]
		- 20150406@Jamie: Manual Settlement Betradar phase 2 [Redmine: #27212]
		- 20150618@Jamie: Offer the option Exclude Corner tickets [Feature #38099]
		- 20150918@Johnson: Check status of corner tickets when settle FT [Redmine: #43806]
	Param's Explanation:
		+ @betstatus: Used for score table, FGLG status, refund status
		+ @GameResult: Game result for Set(s) of Tennis Sport 
				+ In case, the score clear, N-N 
				'A-40,30-40,15-40;N-N;N-N;N-N;N-N' : Only Set 1 key score 
		+ @SelectedSet: The list of selected SET(s) for Settlement - Tennis 
			Sample: '1,2,3,4,5,6' : 6: Match option checked 

		+ @SelectedGame: The list of Games with changed score 
				+ '2,5,6'   
 
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @SkipBalanceUpdate				BIT
		,@start								DATETIME
		,@stop								DATETIME
		,@goalrecord_old					VARCHAR(50)
		,@LogData							NVARCHAR(300)
		,@eventstatus						NVARCHAR(50)
		,@sporttype							TINYINT
		,@TicketCount						INT
		--,@betcount_135						INT
		--,@SettlementStatus135				INT
		,@betCount_1324						INT		-- Set x Game y Winner - 1324
		,@MaxGameSet1						INT
		,@MaxGameSet2						INT
		,@MaxGameSet3						INT
		,@MaxGameSet4						INT
		,@MaxGameSet5						INT
		,@Remark							VARCHAR(500)
		,@ActionID							INT
		,@HomeValue							VARCHAR(20)
		,@AwayValue							VARCHAR(20)
		

	SELECT @start				= CURRENT_TIMESTAMP
		,@SkipBalanceUpdate 	= 0
		,@TicketCount			= 0
		--,@betcount_135			= 0
		,@MaxGameSet1			= 0
		,@MaxGameSet2			= 0 
		,@MaxGameSet3			= 0
		,@MaxGameSet4			= 0
		,@MaxGameSet5			= 0 
		,@ActionID				= CASE @Action
									WHEN 'CAL'		THEN 100
									WHEN 'CAL-FT'	THEN 101
									WHEN 'CAL-HT'	THEN 102
									WHEN 'UNDO'		THEN 103
								  END

	SELECT @sporttype		= m.sporttype
		,@goalrecord_old	= ISNULL(m.goalrecord, '')
	FROM DBPRO.BODB02.dbo.match m WITH(NOLOCK)
	WHERE m.matchid = @matchid

	SELECT	 @HomeValue	= CAST(@fth AS VARCHAR(20))
			,@AwayValue	= CAST(@fta AS VARCHAR(20)) 

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 1001001
			,@ErrMsg	= 'Match does not exist!'

		RETURN
	END

	-- check result of horse racing fixodds
	IF @action = 'CAL' AND @sporttype = 154 AND (@fth = 0 OR @fth IS NULL OR @fta = 0 OR @fta IS NULL)
	BEGIN
		SELECT @ErrCode = 1001002
			,@ErrMsg	= 'Score is not valid.'

		RETURN
	END
	
	-- check and not allow attempt to settlement same game while it's still not finish
	IF EXISTS (
			SELECT 1 
			FROM dbo.TempVariableNumber t WITH(NOLOCK)
			WHERE t.KeyID = 1 
			AND t.KeyValue = @matchid
			)
	BEGIN
		SELECT @ErrCode = 1000000
			,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

		RETURN
	END

	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue)
	VALUES (1, @matchid)

	IF (@@ERROR = 0)
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @creator
				,@Matchid	= @matchid
				,@KeyID		= 1
				,@ActionID	= @ActionID
				,@Remark	= 'ADD SUCCESS'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(ERROR_MESSAGE(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @creator
				,@Matchid	= @matchid
				,@KeyID		= 1
				,@ActionID	= @ActionID
				,@Remark	= @Remark
		END CATCH
	END
	ELSE
	BEGIN
		SELECT @ErrCode = 1000000
			,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

		RETURN
	END

	SELECT	@TicketCount = COUNT(1)
			--,@betcount_135	= ISNULL(SUM(CASE WHEN b.bettype = 135 and b.statusID NOT IN (101, 102) THEN 1 ELSE 0 END),0)
			,@MaxGameSet1 =   ISNULL(MAX(CASE WHEN b.bettype = 1324 AND LEFT(CAST(b.betID AS VARCHAR(20)),3) LIKE '801%' THEN (b.betID - 80100) ELSE 0 END),0)  --  Tennis - Set x Game y Winner
			,@MaxGameSet2 =   ISNULL(MAX(CASE WHEN b.bettype = 1324 AND LEFT(CAST(b.betID AS VARCHAR(20)),3) LIKE '802%' THEN (b.betID - 80200) ELSE 0 END),0)
			,@MaxGameSet3 =   ISNULL(MAX(CASE WHEN b.bettype = 1324 AND LEFT(CAST(b.betID AS VARCHAR(20)),3) LIKE '803%' THEN (b.betID - 80300) ELSE 0 END),0)
			,@MaxGameSet4 =   ISNULL(MAX(CASE WHEN b.bettype = 1324 AND LEFT(CAST(b.betID AS VARCHAR(20)),3) LIKE '804%' THEN (b.betID - 80400) ELSE 0 END),0)
			,@MaxGameSet5 =   ISNULL(MAX(CASE WHEN b.bettype = 1324 AND LEFT(CAST(b.betID AS VARCHAR(20)),3) LIKE '805%' THEN (b.betID - 80500) ELSE 0 END),0)
	FROM dbo.bettrans b WITH(NOLOCK)
	WHERE b.bettype <= 19000 
		AND b.matchid = @matchid
		AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
		AND b.bettype NOT BETWEEN 1501 AND 1599 -- Keno

	IF @Sporttype = 5 
	BEGIN
		DECLARE	 @MaxGameSet1Parlay		INT	= 0
				,@MaxGameSet2Parlay		INT	= 0 
				,@MaxGameSet3Parlay		INT	= 0 
				,@MaxGameSet4Parlay		INT	= 0 
				,@MaxGameSet5Parlay		INT	= 0 
		SELECT	 @MaxGameSet1Parlay	=   ISNULL(MAX(CASE WHEN bm.betcheck LIKE '801%' THEN (CAST(bm.betcheck AS INT) - 80100) ELSE 0 END),0)  --  Tennis - Set x Game y Winner
				,@MaxGameSet2Parlay	=   ISNULL(MAX(CASE WHEN bm.betcheck LIKE '802%' THEN (CAST(bm.betcheck AS INT) - 80200) ELSE 0 END),0)
				,@MaxGameSet3Parlay	=   ISNULL(MAX(CASE WHEN bm.betcheck LIKE '803%' THEN (CAST(bm.betcheck AS INT) - 80300) ELSE 0 END),0)
				,@MaxGameSet4Parlay	=   ISNULL(MAX(CASE WHEN bm.betcheck LIKE '804%' THEN (CAST(bm.betcheck AS INT) - 80400) ELSE 0 END),0)
				,@MaxGameSet5Parlay	=   ISNULL(MAX(CASE WHEN bm.betcheck LIKE '805%' THEN (CAST(bm.betcheck AS INT) - 80500) ELSE 0 END),0)
		FROM	dbo.bettransm bm WITH(NOLOCK)
		WHERE	bettype = 1324		--Set x Game y - Tennis 
				AND matchID = @MatchID 

		SELECT	 @MaxGameSet1 = CASE WHEN @MaxGameSet1 < @MaxGameSet1Parlay THEN @MaxGameSet1Parlay ELSE @MaxGameSet1 END 
				,@MaxGameSet2 = CASE WHEN @MaxGameSet2 < @MaxGameSet2Parlay THEN @MaxGameSet2Parlay ELSE @MaxGameSet2 END
				,@MaxGameSet3 = CASE WHEN @MaxGameSet3 < @MaxGameSet3Parlay THEN @MaxGameSet3Parlay ELSE @MaxGameSet3 END
				,@MaxGameSet4 = CASE WHEN @MaxGameSet4 < @MaxGameSet4Parlay THEN @MaxGameSet4Parlay ELSE @MaxGameSet4 END
				,@MaxGameSet5 = CASE WHEN @MaxGameSet5 < @MaxGameSet5Parlay THEN @MaxGameSet5Parlay ELSE @MaxGameSet5 END
	END

	--SELECT @SettlementStatus135 = mr.SettlementStatus135
	--FROM DBPRO.BODB02.dbo.match_remark mr WITH(NOLOCK)
	--WHERE mr.matchid = @matchid
	
	--IF @betcount_135 = 0 AND 
	--	NOT EXISTS (SELECT TOP 1 1 
	--				FROM dbo.bettransm bm WITH(NOLOCK) 
	--				WHERE bm.matchid = @matchid AND bm.statusid NOT IN (101, 102) AND bm.bettype = 135)
	--BEGIN
	--		SELECT @SettlementStatus135 = CASE WHEN @SettlementStatus135 = 0 THEN 0
	--										   ELSE 4
	--									  END
	--END
	--ELSE
	--BEGIN
	--	SELECT @SettlementStatus135 = CASE	WHEN @action = 'UNDO' THEN 1 -- Running
	--										ELSE 3 -- Calculated (Manual)
	--								  END
	--END
	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceBefore (
		custid INT PRIMARY KEY
		,balance MONEY
		)

	DECLARE @TotalAccount INT
		,@TotalAccount_BalanceUpdate INT

	IF @SkipBalanceUpdate = 0
	BEGIN
		--===
		IF @Action IN ('CAL', 'CAL-FT')
		BEGIN
			INSERT INTO #BalanceBefore
			SELECT b.custid
				,SUM(b.winlost - b.actual_stake + b.playercomm)
			FROM dbo.bettrans b WITH (ROWLOCK)
			WHERE b.matchid = @matchid 
				AND b.bettype NOT IN (14, 127)
				AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
				AND b.bettype NOT BETWEEN 1501 and 1599 -- Keno
				AND b.bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) -- Auto settle Betradar
			GROUP BY b.custid

			SET @TotalAccount = @@ROWCOUNT
		END
		ELSE IF @Action = 'CAL-HT'
		BEGIN
			INSERT INTO #BalanceBefore
			SELECT b.custid
				,SUM(b.winlost - b.actual_stake + b.playercomm)
			FROM dbo.bettrans b WITH (ROWLOCK)
			WHERE	b.matchid = @matchid 
					AND b.bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209)
					AND b.bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217)
			GROUP BY b.custid

			SET @TotalAccount = @@ROWCOUNT
		END
		ELSE IF @Action = 'UNDO'
		BEGIN
			INSERT INTO #BalanceBefore
			SELECT b.custid
				,SUM(b.winlost - b.actual_stake + b.playercomm)
			FROM dbo.bettrans b WITH (ROWLOCK)
			WHERE	b.matchid = @matchid
					AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
					AND b.bettype NOT BETWEEN 1501 and 1599 -- Keno
					AND b.bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217)
			GROUP BY b.custid
		END
				--===
	END --IF @SkipBalanceUpdate = 0
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	-- 20090412 : Joe : case for unsettle the game.
	IF @action = 'UNDO'
	BEGIN
								EXEC dbo.NAP_Admin_Calculate_Main 
			@matchid		= @matchid
			,@SelectedSet	= @SelectedSet
			,@action		= 'CAL'		-- Default Action for UNDO Settlement 
			,@mode			= 'UNDO' 

								EXEC dbo.NAP_Admin_Settlement_Parlay
			@matchids		= @matchid
			,@creator		= @creator
			,@action		= 'UNDO'
			,@SelectedSet	= @SelectedSet
			,@IP			= @IP

								EXEC DBPRO.BODB02.dbo.NAP_UpdateMatch_Remark 
			@matchid		= @matchid
			,@command		= 'U'
			--,@ivalue		= @SettlementStatus135 -- update SettlementStatus135 value
			,@SelectedSet	= @SelectedSet	--Tennis 

		EXEC DBPRO.BODB02.dbo.NAP_Admin_Match_Update 
			@Command		= 'NAP_Admin_Settlement_1-UNDO'
			,@MatchID		= @matchid
			,@betstatus		= @betstatus
			,@SelectedSet	= @SelectedSet
			,@creator		= @creator

		IF @Sporttype = 5 -- Tennis 
		BEGIN
			EXEC DBPRO.BODB02.dbo.NAP_Admin_Result_Update 
					@Command			= 'NAP_Admin_Settlement_1-UNDO',
					@MatchID			= @MatchID,
					@SelectedSet		= @SelectedSet
		END

		IF @Sporttype = 1 -- Soccer
		BEGIN
												EXEC DBPRO.BODB02.dbo.NAP_Admin_Result_Update_1s 
				@Command			= 'NAP_Admin_Settlement_1-UNDO',
				@MatchID			= @MatchID,
				@creator			= @creator 
		END
		/* --20110620@Thien: replace by calling SP instead
	-- RESET 'SaveBet' of DB06
	DELETE FROM DB06.bodb02.dbo.Save_Jobs WHERE matchid = @matchid
	UPDATE DB06.bodb02.dbo.Save_ListMatch SET IsGameFinish = 1 WHERE matchid = @matchid

	INSERT INTO DB06.bodb02.dbo.SAve_Jobs (matchid, liveindicator, savetype, bettype, typename)
	SELECT @matchid, 1, 'DEL', 0, 0
	*/
		EXEC DBACC.bodb02.dbo.NAP_Admin_Match_UpdateSaveBet 
			@action			= 'UNDO'
			,@matchid		= @matchid
			,@SelectedSet	= @SelectedSet --Tennis 
	END
	ELSE
	BEGIN
		/* 06 OCT 2008 : Joe
As of Today.  Match Remark can't tell game just settled for HT yet
need below code to determine for mark match as calculated (all bets settled)
*/
		DECLARE @status TABLE (FTBet BIT, BetCount INT, InRunning INT)

		INSERT INTO @status
		SELECT CASE 
					WHEN b.bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209) THEN 0
					--WHEN b.bettype = 135 THEN 2
					ELSE 1
			   END
			,SUM(CASE 
					WHEN b.statusID IN (101, 102) THEN 0
					ELSE 1
				 END)
			,SUM(CASE 
					WHEN b.statusID = 0 THEN 1
					ELSE 0
				 END)
		FROM dbo.bettrans b WITH(NOLOCK)
		WHERE b.matchid = @matchid
				AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
				AND b.bettype NOT BETWEEN 1501 and 1599 -- Keno
				AND b.bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) --Auto settle Betradar
		GROUP BY CASE 
					WHEN b.bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209) THEN 0
					--WHEN b.bettype = 135 THEN 2
					ELSE 1
				 END

		IF NOT EXISTS (SELECT * FROM @status WHERE FTBet = 0)
			INSERT INTO @status VALUES (0, 0,0)

		IF NOT EXISTS (SELECT * FROM @status WHERE FTBet = 1)
			INSERT INTO @status VALUES (1, 0, 0)

		DECLARE @HTDone BIT, @FTDone BIT

		SELECT @HTDone = CASE InRunning
							WHEN 0 THEN 1
							ELSE 0
						 END
		FROM @status
		WHERE FTBet = 0

		SELECT @FTDone = CASE InRunning
							WHEN 0 THEN 1
							ELSE 0
						 END
		FROM @status
		WHERE FTBet = 1

		DECLARE @isExistRunningCornerBet BIT
		SELECT	@isExistRunningCornerBet = 0 
		IF @Sporttype = 1 
		BEGIN
			IF EXISTS(	SELECT TOP 1 1 FROM Bettrans WITH (NOLOCK) 
						WHERE	bettype IN (194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209)
								AND matchID = @MatchID 
								AND statusID = 0 	
								AND @isExcludeCorner = 1 
			)
			SELECT	@isExistRunningCornerBet = 1 
		END

		/* Mode
	CAL : (default) Settle ALL BetTypes
	CAL-FT : Full Time Only
	CAL-HT : Half Time Only
	SCORE : Only Save Score -- not use
	UNDO : Unsettle the match  -- not use
	*/
		SELECT @eventstatus = CASE 
								WHEN @action = 'CAL' AND @Sporttype NOT IN (1,5)		THEN N'completed'
								WHEN @action = 'CAL' AND @Sporttype = 1 AND @isExcludeCorner = 0 THEN N'completed'
								WHEN @action = 'CAL' AND @Sporttype = 1 AND @isExcludeCorner = 1 AND @isExistRunningCornerBet = 0 THEN N'completed'
								WHEN @action = 'CAL' AND @Sporttype = 5 AND @SelectedSet LIKE '%6%' THEN N'completed'	-- Match Option checked 
								WHEN @action = 'CAL-HT' AND m.matchcode LIKE '%hedge%'	THEN eventstatus -- Jamie@20120330: Not change eventstatus='completed' for Hedge Match although 
								WHEN @action = 'CAL-HT' AND @FTDone = 1					THEN N'completed'
								WHEN @action = 'CAL-FT' AND @HTDone = 1 AND @isExcludeCorner = 0 THEN N'completed'
								WHEN @action = 'CAL-FT' AND @HTDone = 1 AND @isExcludeCorner = 1 AND @isExistRunningCornerBet = 0 THEN N'completed'
								ELSE m.eventstatus
							  END
			,@FTDone		= CASE 
								WHEN @action = 'CAL-HT' AND m.matchcode LIKE '%hedge%' THEN 0
								ELSE @FTDone
							  END
		FROM DBPRO.BODB02.dbo.Match m WITH(NOLOCK)
		WHERE m.matchid = @matchid

		EXEC DBPRO.BODB02.dbo.NAP_Admin_Match_Update 
			@Command		= 'NAP_Admin_Settlement_1-CAL'
			,@MatchID		= @matchid
			,@FTHome		= @fth
			,@FTAway		= @fta
			,@HTHome		= @hth
			,@HTAway		= @hta
			,@BetStatus 	= @betstatus
			,@GoalRecord	= @goalrecord
			,@SelectedSet	= @SelectedSet		-- Tennis selected 
			,@Action		= @action
			,@FTDone		= @FTDone
			,@HTDone		= @HTDone
			,@isExcludeCorner = @isExcludeCorner
			,@isExistRunningCornerBet = @isExistRunningCornerBet
			,@creator		= @creator

		IF @Sporttype = 5 AND @Action='CAL'
		BEGIN
			EXEC DBPRO.BODB02.dbo.NAP_Admin_Result_Update 
				@Command			= 'NAP_Admin_Settlement_1-CAL',
				@MatchID			= @MatchID,
				@HomeValue			= @HomeValue,
				@AwayValue			= @AwayValue,
				@SetResult			= @SetResult, 
				@GameResult1		= @GameResult1,
				@GameResult2		= @GameResult2,
				@GameResult3		= @GameResult3,
				@GameResult4		= @GameResult4,
				@GameResult5		= @GameResult5,
				@SelectedSet		= @SelectedSet,
				@SelectedSet1Game	= @SelectedSet1Game,
				@SelectedSet2Game	= @SelectedSet2Game,
				@SelectedSet3Game	= @SelectedSet3Game,
				@SelectedSet4Game	= @SelectedSet4Game,
				@SelectedSet5Game	= @SelectedSet5Game,
			    @MaxGameSet1		= @MaxGameSet1,
				@MaxGameSet2		= @MaxGameSet2,
				@MaxGameSet3		= @MaxGameSet3,
				@MaxGameSet4		= @MaxGameSet4,
				@MaxGameSet5		= @MaxGameSet5,
				@action				= @Action,
				@creator			= @creator 			
		END

		IF @Sporttype = 1 AND LEFT(@Action, 3) = 'CAL'
		BEGIN
			EXEC DBPRO.BODB02.dbo.NAP_Admin_Result_Update_1s
				@Command = 'NAP_Admin_Settlement_1-CAL',
				@MatchID = @MatchID,
				@ResourceIDs = NULL,
				@Results = NULL,
				@fth = @fth,
				@fta = @fta,
				@hth = @hth,
				@hta = @hta,
				@fthCorners = @fthCorners,
				@ftaCorners = @ftaCorners,
				@hthCorners = @hthCorners,
				@htaCorners = @htaCorners,
				@ftFCorner = @ftFCorner,
				@ftLCorner = @ftLCorner,
				@htFCorner = @htFCorner,
				@htLCorner = @htLCorner,
				@isExcludeCorner = @isExcludeCorner,
				@Action = @Action,
				@IsAuto = 0,
				@creator = @creator
		END

		IF LEFT(@action, 3) = 'CAL'
		BEGIN
			IF @sporttype IN (180, 181, 182, 183, 184, 185, 186) --virtual sports 	
			BEGIN
				EXEC dbo.NAP_Admin_Settlement_3_VS 
					@creator	= @creator
					,@matchid	= @matchid
					,@mode		= @action
			END
			ELSE IF @Sporttype = 5 -- Tennis settlement 
			BEGIN 
				EXEC dbo.NAP_Admin_Settlement_5 
					@MatchID = @MatchID,
					@Action = 'CAL',
					@Mode = 'CAL',
					@SelectedSet = @SelectedSet
			END
			ELSE 
			BEGIN
				EXEC dbo.NAP_Admin_Settlement_3 
					@matchid	= @matchid
					,@mode		= @action	
					,@isExcludeCorner = @isExcludeCorner					
			END
		END

		--Check and calc 1H FGLG
		IF @action IN ('CAL', 'CAL-HT')
		BEGIN
			IF EXISTS (
					SELECT 1
					FROM dbo.bettrans b WITH(NOLOCK)
					WHERE b.bettype = 127 AND b.matchid = @matchid
					) OR EXISTS (
					SELECT 1
					FROM dbo.bettransm bm WITH(NOLOCK)
					WHERE bm.bettype = 127 AND bm.matchid = @matchid
					)
				IF CHARINDEX('1FL:', @betstatus) > 0
				BEGIN
																				EXEC dbo.NAP_Admin_Settlement_FGLG 
						@creator			= @creator
						,@matchid			= @matchid
						,@action			= 'CAL-HT'
						,@betstatus			= @betstatus
						,@IncludeLG			= 1
						,@goalrecord		= @goalrecord
						,@IP				= @IP
						,@IsLoopTempTable	= 1 ---Not check concurrency by TempVariableNumber table		
				END

	 
		END

		--Check and calc FGLG
		IF @action IN ('CAL', 'CAL-FT')
		BEGIN
			IF EXISTS (
					SELECT 1
					FROM dbo.bettrans b WITH(NOLOCK)
					WHERE b.bettype = 14 AND b.matchid = @matchid
					) OR EXISTS (
					SELECT 1
					FROM dbo.bettransm bm WITH(NOLOCK)
					WHERE bm.bettype = 14 AND bm.matchid = @matchid
					)
																EXEC dbo.NAP_Admin_Settlement_FGLG 
					@creator			= @creator
					,@matchid			= @matchid
					,@action			= 'CAL-FT'
					,@betstatus			= @betstatus
					,@IncludeLG			= 1
					,@goalrecord		= @goalrecord
					,@IP				= @IP
					,@IsLoopTempTable	= 1 ---Not check concurrency by TempVariableNumber table	
		END

		IF @eventstatus = 'completed'
		BEGIN
												EXEC DBPRO.BODB02.dbo.NAP_updateMatch_remark 
				@matchid	= @matchid
				,@command	= 'C'

			--IF @SettlementStatus135 = 4
			--BEGIN
			--				EXEC DBPRO.BODB02.dbo.NAP_updateMatch_remark 
			--		@matchid	= @matchid 
			--		,@command	= 'PS'
			--		,@ivalue	= @SettlementStatus135
			--END
		END
		ELSE IF @action = 'CAL-HT'
		BEGIN
												EXEC DBPRO.BODB02.dbo.NAP_updateMatch_remark 
				@matchid	= @matchid
				,@command	= 'H'
		END
	END 

	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (custid INT PRIMARY KEY, balance MONEY)

	IF @SkipBalanceUpdate = 0
	BEGIN
		IF @Action IN ('CAL', 'CAL-FT')
		BEGIN
			INSERT INTO #BalanceAfter
			SELECT b.custid
				,SUM(b.winlost - b.actual_stake + b.playercomm)
			FROM dbo.bettrans b WITH (ROWLOCK)
			WHERE	b.matchid = @matchid 
					AND b.bettype NOT IN (14, 127)
					AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
					AND b.bettype NOT BETWEEN 1501 and 1599 -- Keno
					AND b.bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) --Auto betradar
			GROUP BY b.custid
		END
		ELSE IF @Action = 'CAL-HT'
		BEGIN
			INSERT INTO #BalanceAfter
			SELECT	b.custid
					,SUM(b.winlost - b.actual_stake + b.playercomm)
			FROM	dbo.bettrans b WITH (ROWLOCK)
			WHERE	b.matchid = @matchid 
					AND b.bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209)
			GROUP BY b.custid
		END
		ELSE IF @Action = 'UNDO'
		BEGIN
			INSERT INTO #BalanceAfter
			SELECT b.custid
				,SUM(b.winlost - b.actual_stake + b.playercomm)
			FROM dbo.bettrans b WITH (ROWLOCK)
			WHERE	b.matchid = @matchid
					AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
					AND b.bettype NOT BETWEEN 1501 and 1599 -- Keno
					AND b.bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) --Auto betradar
			GROUP BY b.custid
		END
	END --IF @SkipBalanceUpdate = 0

	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	CREATE TABLE #Balance (custid INT PRIMARY KEY, balance MONEY, Increased BIT)

	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

	INSERT INTO #Balance
	SELECT b.custid
		,a.balance - b.balance
		,CASE 
			WHEN a.balance > b.balance THEN 1
			ELSE 0
			END
	FROM #BalanceBefore b
		INNER JOIN #BalanceAfter a ON b.custid = a.custid
	WHERE b.balance <> a.balance

	SET @TotalAccount_BalanceUpdate = @@ROWCOUNT

	INSERT INTO dbo.BalancePendingDebit (custid, balance)
	SELECT custid, ABS(balance)
	FROM #Balance
	WHERE Increased = 0

	INSERT INTO dbo.BalancePendingCredit (custid, balance)
	SELECT custid, balance
	FROM #Balance
	WHERE Increased = 1

	----
	-- Add Negative Balance into BalanceNegative table 
	----
	INSERT INTO [bodb02].[dbo].[BalanceNegative] (
		[ExecDate]
		,[MatchID]
		,[ActionID]
		,[GroupID]
		,[CustID]
		,[Balance]
		,[StatusID]
		,[Remark]
		)
	SELECT GETDATE()
		,@MatchID
		,@ActionID
		,1 -- Sportsbook Single bet Settlement 
		,CustID
		,Balance
		,0
		,NULL
	FROM #Balance WITH(NOLOCK)
	WHERE Increased = 0

	---------------------------------------------------
	DROP TABLE #Balance

	DROP TABLE #BalanceBefore

	DROP TABLE #BalanceAfter

	-------------------------------------------------------------
	---                      WRITE LOG                        ---
	---------------------------VVVV------------------------------
	SELECT @stop = CURRENT_TIMESTAMP

	SELECT @LogData = 'NAP: Calculate (' + @action + ') for matchid:' + CAST(@matchid AS NVARCHAR(10)) 
														+ ' score:' + CAST(ISNULL(@fth, 0) AS NVARCHAR(10)) 
														+ '-' + CAST(ISNULL(@fta, 0) AS NVARCHAR(10)) 
														+ ' HT:' + CAST(@hth AS NVARCHAR(10)) 
														+ '-' + CAST(@hta AS NVARCHAR(10)) 
														+ ' GoalRecord:' + ISNULL(@goalrecord, '') 
														+ '(Old:' + @goalrecord_old + ') Remark(' + @betstatus + ')' 

														+ CASE	WHEN @SelectedSet IS NULL THEN ''
																ELSE ' (Set:' + @SelectedSet + ')' 
																END  
														+ CASE	WHEN @SetResult IS NULL THEN ''
																ELSE ' (SR:' + @SetResult + ')' 
																END
														+ CASE	WHEN @SelectedSet1Game IS NULL THEN ''
																ELSE ' (S1Game:' + @SelectedSet1Game + ') ' 
																END   
														+ CASE	WHEN @GameResult1 IS NULL THEN ''
																ELSE '(S1GR:' + @GameResult1 + ') ' 
																END  
														+ CASE	WHEN @SelectedSet2Game IS NULL THEN ''
																ELSE ' (S2Game:' + @SelectedSet2Game + ') ' 
																END   
														+ CASE	WHEN @GameResult2 IS NULL THEN ''
																ELSE '(S2GR:' + @GameResult2 + ') ' 
																END
														+ CASE	WHEN @SelectedSet3Game IS NULL THEN ''
																ELSE ' (S3Game:' + @SelectedSet3Game + ') ' 
																END   
														+ CASE	WHEN @GameResult3 IS NULL THEN ''
																ELSE '(S3GR:' + @GameResult3 + ') ' 
																END
														+ CASE	WHEN @SelectedSet4Game IS NULL THEN ''
																ELSE ' (S4Game:' + @SelectedSet4Game + ') ' 
																END   
														+ CASE	WHEN @GameResult4 IS NULL THEN ''
																ELSE '(S4GR:' + @GameResult1 + ') ' 
																END
														+ CASE	WHEN @SelectedSet5Game IS NULL THEN ''
																ELSE ' (S5Game:' + @SelectedSet5Game + ') ' 
																END   
														+ CASE	WHEN @GameResult5 IS NULL THEN ''
																ELSE '(S5GR:' + @GameResult5 + ') ' 
																END
														+ CASE WHEN @fthCorners IS NULL THEN '' ELSE '(fthCorners:' + CAST(@fthCorners AS VARCHAR(50))  + ') ' END 
														+ CASE WHEN @ftaCorners IS NULL THEN '' ELSE '(ftaCorners:' + CAST(@ftaCorners AS VARCHAR(50))  + ') ' END
														+ CASE WHEN @hthCorners IS NULL THEN '' ELSE '(hthCorners:' + CAST(@hthCorners AS VARCHAR(50))  + ') ' END
														+ CASE WHEN @htaCorners IS NULL THEN '' ELSE '(htaCorners:' + CAST(@htaCorners AS VARCHAR(50))  + ') ' END
														+ CASE WHEN @ftFCorner IS NULL THEN '' ELSE '(ftFCorner:' + @ftFCorner + ') ' END
														+ CASE WHEN @ftLCorner IS NULL THEN '' ELSE '(ftLCorner:' + @ftLCorner + ') ' END
														+ CASE WHEN @htFCorner IS NULL THEN '' ELSE '(htFCorner:' + @htFCorner + ') ' END
														+ CASE WHEN @htLCorner IS NULL THEN '' ELSE '(htLCorner:' + @htLCorner + ') ' END
														+ CASE WHEN @isExcludeCorner IS NULL THEN '' ELSE '(isExcludeCorner:' + CAST(@isExcludeCorner AS VARCHAR(50)) + ') ' END

														+' (' + CAST(DATEDIFF(millisecond, @start, @stop) AS NVARCHAR(50)) + ' ms)'

	EXEC dbo.WriteLog_UserLog 
		@UserID = @creator
		,@Doing = @LogData

		
	SELECT @Remark ='NAP: ' + CASE	WHEN ISNULL(@goalrecord_old,'')='' THEN ''
									ELSE 'Old GoalRecord:' + @goalrecord_old + '<br/> '
									END
							+ CASE	WHEN @SelectedSet IS NULL THEN ''
									ELSE 'Set:' + @SelectedSet + '<br/> ' 
									END  
							+ CASE	WHEN @SetResult IS NULL THEN ''
									ELSE 'SR:' + @SetResult + '<br/> ' 
									END 
							+ CASE	WHEN @SelectedSet1Game IS NULL THEN ''
									ELSE 'S1Game:' + @SelectedSet1Game + '<br/> ' 
									END  
							+ CASE	WHEN @GameResult1 IS NULL THEN ''
									ELSE 'S1GR:' + @GameResult1 + '<br/> ' 
									END  
							+ CASE	WHEN @SelectedSet2Game IS NULL THEN ''
									ELSE 'S2Game:' + @SelectedSet2Game + '<br/> ' 
									END  
							+ CASE	WHEN @GameResult2 IS NULL THEN ''
									ELSE 'S2GR:' + @GameResult2 + '<br/> ' 
									END  
							+ CASE	WHEN @SelectedSet3Game IS NULL THEN ''
									ELSE 'S3Game:' + @SelectedSet3Game + '<br/> ' 
									END  
							+ CASE	WHEN @GameResult3 IS NULL THEN ''
									ELSE 'S3GR:' + @GameResult3 + '<br/> ' 
									END  
							+ CASE	WHEN @SelectedSet4Game IS NULL THEN ''
									ELSE 'S4Game:' + @SelectedSet4Game + '<br/> ' 
									END  
							+ CASE	WHEN @GameResult4 IS NULL THEN ''
									ELSE 'S4GR:' + @GameResult4 + '<br/> ' 
									END  
							+ CASE	WHEN @SelectedSet5Game IS NULL THEN ''
									ELSE 'S5Game:' + @SelectedSet5Game + '<br/> ' 
									END  
							+ CASE	WHEN @GameResult5 IS NULL THEN ''
									ELSE 'S5GR:' + @GameResult5 + '<br/> ' 
									END  

							+ CASE WHEN @fthCorners IS NULL THEN '' ELSE 'fthCorners:' + CAST(@fthCorners AS VARCHAR(50))  + ' ' END 
							+ CASE WHEN @ftaCorners IS NULL THEN '' ELSE 'ftaCorners:' + CAST(@ftaCorners AS VARCHAR(50))  + '<br/> ' END
							+ CASE WHEN @hthCorners IS NULL THEN '' ELSE 'hthCorners:' + CAST(@hthCorners AS VARCHAR(50))  + ' ' END
							+ CASE WHEN @htaCorners IS NULL THEN '' ELSE 'htaCorners:' + CAST(@htaCorners AS VARCHAR(50))  + '<br/> ' END
							+ CASE WHEN @ftFCorner IS NULL THEN '' ELSE 'ftFCorner:' + @ftFCorner + '<br/> ' END
							+ CASE WHEN @ftLCorner IS NULL THEN '' ELSE 'ftLCorner:' + @ftLCorner + '<br/> ' END
							+ CASE WHEN @htFCorner IS NULL THEN '' ELSE 'htFCorner:' + @htFCorner + '<br/> ' END
							+ CASE WHEN @htLCorner IS NULL THEN '' ELSE 'htLCorner:' + @htLCorner + '<br/> ' END
							+ CASE WHEN @isExcludeCorner IS NULL THEN '' ELSE 'isExcludeCorner:' + CAST( @isExcludeCorner AS VARCHAR(50)) + '<br/> ' END 


							+ 'Duration:' + CAST(DATEDIFF(MILLISECOND, @start, @stop) AS NVARCHAR(50)) + ' ms;' 
							+ ' TC:' + CAST(ISNULL(@ticketCount, 0) AS VARCHAR(20)) 
							+ ' Bal:' + CAST(ISNULL(@TotalAccount_BalanceUpdate, 0) AS VARCHAR(20)) + '/' + CAST(IsNull(@TotalAccount, 0) AS VARCHAR(20))

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle 
			@UserID				= @creator
			,@Matchid			= @matchid
			,@ActionID			= @ActionID
			,@finalhomescore	= @fth
			,@finalawayscore	= @fta
			,@hthomescore		= @hth
			,@htawayscore		= @hta
			,@GoalRecord		= @goalrecord
			,@betstatus			= @betstatus
			,@Remark			= @Remark
			,@IP				= @IP
	END TRY

	BEGIN CATCH
		SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 250)

		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle 
			@UserID				= @creator
			,@Matchid			= @matchid
			,@ActionID			= @ActionID
			,@finalhomescore	= @fth
			,@finalawayscore	= @fta
			,@hthomescore		= @hth
			,@htawayscore		= @hta
			,@GoalRecord		= @goalrecord
			,@betstatus			= @betstatus
			,@Remark			= @Remark
			,@IP				= @IP
	END CATCH
	
	DELETE
	FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid

	IF (@@Error = 0)
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @creator
				,@Matchid	= @matchid
				,@KeyID		= 1
				,@ActionID	= @ActionID
				,@Remark	= 'DEL SUCCESS'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS  ErrMsg=' + left(error_message(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @creator
				,@Matchid	= @matchid
				,@KeyID		= 1
				,@ActionID	= @ActionID
				,@Remark	= @Remark
		END CATCH
	END
	ELSE
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @creator
				,@Matchid	= @matchid
				,@KeyID		= 1
				,@ActionID	= @ActionID
				,@Remark	= 'DEL FAILED'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED  ErrMsg=' + left(error_message(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @creator
				,@Matchid	= @matchid
				,@KeyID		= 1
				,@ActionID	= @ActionID
				,@Remark	= @Remark
		END CATCH
	END
END
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_1] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_1] TO [Dot_Member] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_1] TO [vnteam] AS [dbo]