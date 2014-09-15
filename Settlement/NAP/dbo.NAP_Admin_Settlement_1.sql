/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_1]    Script Date: 09/11/2014 11:07:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_1] 
	@creator		INT
	,@matchid		INT
	,@fth			SMALLINT		= NULL
	,@fta			SMALLINT		= NULL
	,@hth			SMALLINT
	,@hta			SMALLINT
	,@goalrecord	VARCHAR(50)		= NULL
	,@betstatus		NVARCHAR(50)
	,@action		VARCHAR(10)		= 'CAL'
	,@IP			VARCHAR(50)		= ''
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		NVARCHAR(200)	= ''	OUTPUT
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


	Param's Explanation:
		+ @betstatus: Used for score table, FGLG status, refund status
		
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @SkipBalanceUpdate				BIT
		,@start								DATETIME
		,@stop								DATETIME
		,@goalrecord_old					VARCHAR(50)
		,@LogData							NVARCHAR(200)
		,@eventstatus						NVARCHAR(50)
		,@sporttype							TINYINT
		,@TicketCount						INT
		,@betcount_135						INT
		,@SettlementStatus135				INT
		,@Remark							VARCHAR(500)
		,@ActionID							INT

	SELECT @start				= CURRENT_TIMESTAMP
		,@SkipBalanceUpdate 	= 0
		,@TicketCount			= 0
		,@betcount_135			= 0
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

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 1000001
			,@ErrMsg	= 'Match does not exist!'

		RETURN
	END

	-- check result of horse racing fixodds
	IF @action = 'CAL' AND @sporttype = 154 AND (@fth = 0 OR @fth IS NULL OR @fta = 0 OR @fta IS NULL)
	BEGIN
		SELECT @ErrCode = 1000002
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

	SELECT @TicketCount = COUNT(1)
		,@betcount_135	= ISNULL(SUM(CASE WHEN b.bettype = 135 and b.statusID NOT IN (101, 102) THEN 1 ELSE 0 END),0)
	FROM dbo.bettrans b WITH(NOLOCK)
	WHERE b.bettype <= 19000 
	AND b.matchid = @matchid
	AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
	AND b.bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
	AND b.bettype NOT BETWEEN 1501 AND 1599 -- Keno
	
	SELECT @SettlementStatus135 = mr.SettlementStatus135
	FROM DBPRO.BODB02.dbo.match_remark mr WITH(NOLOCK)
	WHERE mr.matchid = @matchid
	
	IF @betcount_135 = 0 AND 
		NOT EXISTS (SELECT TOP 1 1 
					FROM dbo.bettransm bm WITH(NOLOCK) 
					WHERE bm.matchid = @matchid AND bm.statusid NOT IN (101, 102) AND bm.bettype = 135)
	BEGIN
			SELECT @SettlementStatus135 = CASE WHEN @SettlementStatus135 = 0 THEN 0
											   ELSE 4
										  END
	END
	ELSE
	BEGIN
		SELECT @SettlementStatus135 = CASE	WHEN @action = 'UNDO' THEN 1 -- Running
											ELSE 3 -- Calculated (Manual)
									  END
	END
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
			AND b.bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
			AND b.bettype NOT BETWEEN 1501 and 1599 -- Keno
			GROUP BY b.custid

			SET @TotalAccount = @@ROWCOUNT
		END
		ELSE IF @Action = 'CAL-HT'
		BEGIN
			INSERT INTO #BalanceBefore
			SELECT b.custid
				,SUM(b.winlost - b.actual_stake + b.playercomm)
			FROM dbo.bettrans b WITH (ROWLOCK)
			WHERE b.matchid = @matchid AND b.bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151)
			GROUP BY b.custid

			SET @TotalAccount = @@ROWCOUNT
		END
		ELSE IF @Action = 'UNDO'
		BEGIN
			INSERT INTO #BalanceBefore
			SELECT b.custid
				,SUM(b.winlost - b.actual_stake + b.playercomm)
			FROM dbo.bettrans b WITH (ROWLOCK)
			WHERE b.matchid = @matchid
			AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
			AND b.bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
			AND b.bettype NOT BETWEEN 1501 and 1599 -- Keno
			GROUP BY b.custid
		END
				--===
	END --IF @SkipBalanceUpdate = 0
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	-- 20090412 : Joe : case for unsettle the game.
	IF @action = 'UNDO'
	BEGIN
		EXEC dbo.NAP_Admin_Calculate_Main 
			@matchid	= @matchid
			,@mode		= 'UNDO' 

		EXEC dbo.NAP_Admin_Settlement_Parlay 
			@matchids	= @matchid
			,@creator	= @creator
			,@action	= 'UNDO'
			,@IP		= @IP

		EXEC DBPRO.BODB02.dbo.NAP_UpdateMatch_Remark 
			@matchid	= @matchid
			,@command	= 'U'
			,@ivalue	= @SettlementStatus135 -- update SettlementStatus135 value

		EXEC DBPRO.BODB02.dbo.NAP_Admin_Match_Update 
			@Command	= 'NAP_Admin_Settlement_1-UNDO'
			,@MatchID	= @matchid
			,@creator	= @creator

		/* --20110620@Thien: replace by calling SP instead
	-- RESET 'SaveBet' of DB06
	DELETE FROM DB06.bodb02.dbo.Save_Jobs WHERE matchid = @matchid
	UPDATE DB06.bodb02.dbo.Save_ListMatch SET IsGameFinish = 1 WHERE matchid = @matchid

	INSERT INTO DB06.bodb02.dbo.SAve_Jobs (matchid, liveindicator, savetype, bettype, typename)
	SELECT @matchid, 1, 'DEL', 0, 0
	*/
		EXEC DBACC.bodb02.dbo.NAP_Admin_Match_UpdateSaveBet 
			@action		= 'UNDO'
			,@matchid	= @matchid
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
					WHEN b.bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151) THEN 0
					WHEN b.bettype = 135 THEN 2
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
		AND b.bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
		AND b.bettype NOT BETWEEN 1501 and 1599 -- Keno
		GROUP BY CASE 
					WHEN b.bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151) THEN 0
					WHEN b.bettype = 135 THEN 2
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

		/* Mode
	CAL : (default) Settle ALL BetTypes
	CAL-FT : Full Time Only
	CAL-HT : Half Time Only
	SCORE : Only Save Score -- not use
	UNDO : Unsettle the match  -- not use
	*/
		SELECT @eventstatus = CASE 
								WHEN @action = 'CAL'									THEN N'completed'
								WHEN @action = 'CAL-HT' AND m.matchcode LIKE '%hedge%'	THEN eventstatus -- Jamie@20120330: Not change eventstatus='completed' for Hedge Match although 
								WHEN @action = 'CAL-HT' AND @FTDone = 1					THEN N'completed'
								WHEN @action = 'CAL-FT' AND @HTDone = 1					THEN N'completed'
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
			,@Action		= @action
			,@FTDone		= @FTDone
			,@HTDone		= @HTDone
			,@creator		= @creator

		IF LEFT(@action, 3) = 'CAL'
		BEGIN
			IF @sporttype IN (180, 181, 182, 183, 184, 185, 186) --virtual sports 	
			BEGIN
				EXEC dbo.NAP_Admin_Settlement_3_VS 
					@creator	= @creator
					,@matchid	= @matchid
					,@mode		= @action
			END
			ELSE
			BEGIN
				EXEC dbo.NAP_Admin_Settlement_3 
					@matchid	= @matchid
					,@mode		= @action						
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

			IF @SettlementStatus135 = 4
			BEGIN
				EXEC DBPRO.BODB02.dbo.NAP_updateMatch_remark 
					@matchid	= @matchid 
					,@command	= 'PS'
					,@ivalue	= @SettlementStatus135
			END
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
			WHERE b.matchid = @matchid 
			AND b.bettype NOT IN (14, 127)
			AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
			AND b.bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
			AND b.bettype NOT BETWEEN 1501 and 1599 -- Keno
			GROUP BY b.custid
		END
		ELSE IF @Action = 'CAL-HT'
		BEGIN
			INSERT INTO #BalanceAfter
			SELECT b.custid
				,SUM(b.winlost - b.actual_stake + b.playercomm)
			FROM dbo.bettrans b WITH (ROWLOCK)
			WHERE b.matchid = @matchid 
			AND b.bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151)
			GROUP BY b.custid
		END
		ELSE IF @Action = 'UNDO'
		BEGIN
			INSERT INTO #BalanceAfter
			SELECT b.custid
				,SUM(b.winlost - b.actual_stake + b.playercomm)
			FROM dbo.bettrans b WITH (ROWLOCK)
			WHERE b.matchid = @matchid
			AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
			AND b.bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
			AND b.bettype NOT BETWEEN 1501 and 1599 -- Keno
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
														+ '(Old:' + @goalrecord_old + ') Remark(' + @betstatus + ') (' + CAST(DATEDIFF(millisecond, @start, @stop) AS NVARCHAR(50)) + ' ms)'

	EXEC dbo.WriteLog_UserLog 
		@UserID = @creator
		,@Doing = @LogData
		
	SELECT @Remark ='NAP: ' + CASE 
									WHEN LEN(@goalrecord_old) = 0 THEN ''
									ELSE 'Old GoalRecord:' + @goalrecord_old + '<br/> '
							   END 
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
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_1] TO [vnteam] AS [dbo]