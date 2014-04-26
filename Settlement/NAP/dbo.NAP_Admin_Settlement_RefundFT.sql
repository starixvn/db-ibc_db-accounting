ALTER PROCEDURE [NAP_Admin_Settlement_RefundFT] @matchid INT
	,@adminid INT
	,@IsExcludeBetdaq BIT = 0
	,@IsSettleAbandonedMatch BIT = 0
	,@IsExcludeBetfair BIT = 0
	,@IsSettleAbandonedMatchBetFair BIT = 0
	,@IsSettleAbandonedMatchIBC BIT = 0
	,@fth INT = NULL
	,@fta INT = NULL
	,@betstatus NVARCHAR(50) = NULL
	,@IP VARCHAR(15) = ''
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: Kathy
	Date: 20140213
	Task : Refund Full-time tickets
	DB: DBTXN/BODB02
	Original: 
	
	Revisions:
		- 20140304@Kathy: Execute settlement for abandoned/postponed matches- Clean Sheet, Both/One/Neither team to score, To Win To Nil 
		- 20140426@Kathy: Add 1H Total Goal and 1H FGLG bettypes (126, 127) [Redmine:#14449]


	Param's Explanation:
	• @matchid: matchid of match to Refund HT
	• @IsSettleAbandonedMatch: Is Settlement for Abandoned/postponed match or not
	• @IsSettleAbandonedMatchBetFair: Is Settlement for Betfair ticket of Abandoned/postponed match or not
	• @IsSettleAbandonedMatchIBC: Is Settlement for IBC ticket of Abandoned/postponed match or not

*/
BEGIN
	SET NOCOUNT ON

	-- check and not allow attempt to settlement same game while it's still not finish
	IF EXISTS (
			SELECT 1
			FROM dbo.TempVariableNumber
			WHERE KeyID = 1 AND KeyValue = @matchid
			)
	BEGIN
		SELECT @ErrCode = 1000000
			,@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

		RETURN
	END

	DECLARE @Remark VARCHAR(500)
		,@ActionID INT

	SELECT @ActionID = 111

	INSERT INTO dbo.TempVariableNumber (
		KeyID
		,KeyValue
		)
	VALUES (
		1
		,@matchid
		)

	IF (@@Error = 0)
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @adminID
				,@Matchid = @matchid
				,@KeyID = 1
				,@ActionID = @ActionID
				,@Remark = 'ADD SUCCESS'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(error_message(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @adminID
				,@Matchid = @matchid
				,@KeyID = 1
				,@ActionID = @ActionID
				,@Remark = @Remark
		END CATCH
	END
	ELSE
	BEGIN
		SELECT @ErrCode = 1000000
			,@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

		RETURN
	END

	---
	DECLARE @start DATETIME
		,@stop DATETIME

	SELECT @start = CURRENT_TIMESTAMP

	CREATE TABLE #BalanceBefore (
		custid INT PRIMARY KEY
		,balance MONEY
		)

	CREATE TABLE #BalanceAfter (
		custid INT PRIMARY KEY
		,balance MONEY
		)

	CREATE TABLE #Balance (
		custid INT PRIMARY KEY
		,balance MONEY
		,Increased BIT
		)

	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

	INSERT INTO #BalanceBefore
	SELECT custid
		,SUM(winlost - actual_stake + playercomm)
	FROM dbo.bettrans WITH (ROWLOCK)
	WHERE matchid = @matchid AND bettype NOT IN (14, 127)
	GROUP BY custid

	DECLARE @status TABLE (
		FTBet BIT
		,BetCount INT
		,InRunning INT
		)

	INSERT INTO @status
	SELECT CASE 
			WHEN bettype IN (7, 8, 12, 15, 21, 30, 125, 126) THEN 0
			ELSE 1
			END
		,SUM(CASE 
				WHEN statusID IN (101, 102) THEN 0
				ELSE 1
				END)
		,SUM(CASE 
				WHEN statusID = 0 THEN 1
				ELSE 0
				END)
	FROM dbo.bettrans WITH (NOLOCK)
	WHERE matchid = @matchid
	GROUP BY CASE 
			WHEN bettype IN (7, 8, 12, 15, 21, 30, 125, 126) THEN 0
			ELSE 1
			END

	IF NOT EXISTS (
			SELECT *
			FROM @status
			WHERE FTBet = 0
			)
		INSERT INTO @status
		VALUES (
			0
			,0
			,0
			)

	IF NOT EXISTS (
			SELECT *
			FROM @status
			WHERE FTBet = 1
			)
		INSERT INTO @status
		VALUES (
			1
			,0
			,0
			)

	DECLARE @HTDone BIT
		,@FTDone BIT

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

	IF @IsSettleAbandonedMatch = 1
		SELECT @IsExcludeBetdaq = 1

	IF @IsSettleAbandonedMatchBetFair = 1
		SELECT @IsExcludeBetfair = 1

	---===============================================
	--Check if match already Refund HT => refund whole match
	IF EXISTS (
			SELECT 1
			FROM DBPRO.BODB02.dbo.Match WITH (NOLOCK)
			WHERE matchid = @matchid AND betstatus LIKE '%Refund HT%'
			) AND @HTDone = 1
	BEGIN
		-----
		DELETE
		FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid

		IF (@@Error = 0)
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @adminID
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = 'DEL SUCCESS'
			END TRY

			BEGIN CATCH
				SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)

				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @adminID
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = @Remark
			END CATCH
		END
		ELSE
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @adminID
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = 'DEL FAILED'
			END TRY

			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)

				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @adminID
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = @Remark
			END CATCH
		END

		EXEC dbo.NAP_Admin_Settlement_Refund_All @matchid = @matchid
			,@creator = @adminid
			,@IsExcludeBetdaq = @IsExcludeBetdaq
			,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
			,@IsExcludeBetfair = @IsExcludeBetfair
			,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
			,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
			,@hth = NULL
			,@hta = NULL
			,@fth = @fth
			,@fta = @fta
			,@betstatus = @betstatus
			,@Action = 'CAL-FT'
			,@IP = @IP
			,@ErrCode = @ErrCode OUTPUT
			,@ErrMsg = @ErrMsg OUTPUT

		RETURN
	END

	/*
	Settle Abandoned Match for Over/Under 
*/
	DECLARE @ScoreLog VARCHAR(100)
		,@sporttype TINYINT

	SELECT @sporttype = SportType
	FROM DBPRO.BODB02.dbo.Match WITH (NOLOCK)
	WHERE matchid = @matchid

	IF (@IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1 OR @IsSettleAbandonedMatchIBC = 1) AND @HTDone = 1
	BEGIN
		SELECT @ScoreLog = ' FTHScore=' + CAST(@fth AS VARCHAR(10)) + ' FTAScore=' + CAST(@fta AS VARCHAR(10)) + ' BetStatus=' + @betstatus

		DECLARE @TennisTotal SMALLINT
			,@T_Home SMALLINT
			,@T_Away SMALLINT

		IF @SportType IN (5, 6, 9, 30) -- Tennis/VolleyBall/Badminton/Squash : get TotalGamesPlayed
			EXEC dbo.Admin_Settlement_2 @betstatus = @betstatus
				,@Total = @TennisTotal OUTPUT
				,@TotalHome = @T_Home OUTPUT
				,@TotalAway = @T_Away OUTPUT

		DECLARE @totalgoal SMALLMONEY

		SELECT @totalgoal = CASE 
				WHEN @sporttype IN (5, 6, 9, 30) AND @TennisTotal > 0 THEN @TennisTotal
				ELSE (@fth + @fta)
				END

		IF @totalgoal IS NULL
		BEGIN
			SELECT @ErrCode = 1000004
				,@ErrMsg = 'Cannot settle determined ticket(s) without FT Score!'

			-----
			DELETE
			FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
			WHERE KeyID = 1 AND KeyValue = @matchid

			IF (@@Error = 0)
			BEGIN
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @adminID
						,@Matchid = @matchid
						,@KeyID = 1
						,@ActionID = @ActionID
						,@Remark = 'DEL SUCCESS'
				END TRY

				BEGIN CATCH
					SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)

					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @adminID
						,@Matchid = @matchid
						,@KeyID = 1
						,@ActionID = @ActionID
						,@Remark = @Remark
				END CATCH
			END
			ELSE
			BEGIN
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @adminID
						,@Matchid = @matchid
						,@KeyID = 1
						,@ActionID = @ActionID
						,@Remark = 'DEL FAILED'
				END TRY

				BEGIN CATCH
					SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)

					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @adminID
						,@Matchid = @matchid
						,@KeyID = 1
						,@ActionID = @ActionID
						,@Remark = @Remark
				END CATCH
			END

			RETURN
		END
	END

	IF (@IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1) AND @HTDone = 1
	BEGIN
		DECLARE @betcount_3 INT

		SELECT @betcount_3 = ISNULL(SUM(CASE bettype
						WHEN 3 THEN 1
						ELSE 0
						END), 0)
		FROM bettrans WITH (NOLOCK)
		WHERE matchid = @matchid AND bettype = 3 AND 1 = CASE 
				WHEN @IsSettleAbandonedMatch = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) THEN 1
				WHEN @IsSettleAbandonedMatchBetFair = 1 AND custid IN (2331, 1077687, 115770) THEN 1
				ELSE 0
				END AND statusID NOT IN (101, 102)

		--EXEC dbo.NAP_Admin_Calculate_3 @matchid = @matchid, @bettype = 3, @totalgoal = @totalgoal, @betcount = @betcount_3, @IsSettleAbandonedMatch = @IsSettleAbandonedMatch, @IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
		EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
			,@action = 'REFUND'
			,@mode = 'FT'
			,@betcount_3 = 3
			,@totalgoal = @totalgoal
			,@ticket_count = @betcount_3
			,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
			,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
	END

	/* --- END Settle Abandoned Match ---*/
	IF (@IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1 OR @IsSettleAbandonedMatchIBC = 1) AND @HTDone = 1 AND @sporttype = 1
	BEGIN
		DECLARE @betcount_13 INT
			,@betcount_26 INT
			,@betcount_27 INT

		SELECT @betcount_13 = ISNULL(SUM(CASE b.bettype
						WHEN 13 THEN 1
						ELSE 0
						END), 0)
			,@betcount_26 = ISNULL(SUM(CASE b.bettype
						WHEN 26 THEN 1
						ELSE 0
						END), 0)
			,@betcount_27 = ISNULL(SUM(CASE b.bettype
						WHEN 27 THEN 1
						ELSE 0
						END), 0)
		FROM bettrans b WITH (NOLOCK)
		WHERE b.matchid = @matchid AND b.bettype IN (13, 26, 27) AND b.statusID NOT IN (101, 102) AND 1 = CASE 
				WHEN @IsSettleAbandonedMatch = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) THEN 1
				WHEN @IsSettleAbandonedMatchBetFair = 1 AND custid IN (2331, 1077687, 115770) THEN 1
				WHEN @IsSettleAbandonedMatchIBC = 1 AND (b.custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770) AND recommend <> 1688156) THEN 1
				ELSE 0
				END

		EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
			,@action = 'REFUND'
			,@mode = 'FT'
			,@betcount_13 = 13
			,@fth = @fth
			,@fta = @fta
			,@ticket_count = @betcount_13
			,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
			,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
			,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

		EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
			,@action = 'REFUND'
			,@mode = 'FT'
			,@betcount_26 = 26
			,@fth = @fth
			,@fta = @fta
			,@ticket_count = @betcount_26
			,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
			,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
			,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

		EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
			,@action = 'REFUND'
			,@mode = 'FT'
			,@betcount_27 = 27
			,@fth = @fth
			,@fta = @fta
			,@ticket_count = @betcount_27
			,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
			,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
			,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
	END

	DECLARE @RowCount INT

	EXEC DBPRO.BODB02.dbo.NAP_Admin_Match_Update @Command = 'NAP_Admin_Settlement_RefundFT'
		,@MatchID = @matchid
		,@HTDone = @HTDone
		,@RowCount = @RowCount OUTPUT
		,@creator = @adminid

	IF @RowCount > 0
	BEGIN
		EXEC DBPRO.BODB02.dbo.NAP_updateMatch_remark @matchid
			,'F'

		-- Calculate Refund FT
		EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
			,@action = 'REFUND'
			,@mode = 'FT'
			,@row_count = @RowCount
			,@IsExcludeBetdaq = @IsExcludeBetdaq
			,@IsExcludeBetfair = @IsExcludeBetfair
			,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
			,@fth = @fth
			,@fta = @fta
	END

	INSERT INTO #BalanceAfter
	SELECT custid
		,SUM(winlost - actual_stake + playercomm)
	FROM dbo.bettrans WITH (ROWLOCK)
	WHERE matchid = @matchid AND bettype NOT IN (14, 127)
	GROUP BY custid

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

	INSERT INTO dbo.BalancePendingDebit (
		custid
		,balance
		)
	SELECT custid
		,ABS(balance)
	FROM #Balance
	WHERE Increased = 0

	INSERT INTO dbo.BalancePendingCredit (
		custid
		,balance
		)
	SELECT custid
		,balance
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
	FROM #Balance WITH (NOLOCK)
	WHERE Increased = 0

	---------------------------------------
	--  Betfair & Betdaq - Warning message:
	DECLARE @movebet VARCHAR(20),@matchcode nvarchar(50)

	SELECT @movebet = convert(VARCHAR(20), DATEADD(d, 1, kickofftime), 100),
		@matchcode = matchcode
	FROM match WITH (NOLOCK)
	WHERE matchid = @matchid
	IF @matchcode not like '%Hedge%'
	BEGIN 
		IF (@IsExcludeBetdaq = 1 OR @IsSettleAbandonedMatch = 1) AND (@IsExcludeBetfair = 1 OR @IsSettleAbandonedMatchBetFair = 1) AND @HTDone = 1
		BEGIN
			SELECT @ErrCode = 1000006
				,@ErrMsg = 'Please move Betdaq and Betfair tickets to a new match before ' + @movebet + ' GMT-4. Otherwise they will bring harm to the system'
		END
		ELSE IF (@IsExcludeBetdaq = 1 OR @IsSettleAbandonedMatch = 1) AND @HTDone = 1
		BEGIN
			SELECT @ErrCode = 1000006
				,@ErrMsg = 'Please move Betdaq tickets to a new match before ' + @movebet + ' GMT-4. Otherwise they will bring harm to the system'
		END
		ELSE IF (@IsExcludeBetfair = 1 OR @IsSettleAbandonedMatchBetFair = 1) AND @HTDone = 1
		BEGIN
			SELECT @ErrCode = 1000006
				,@ErrMsg = 'Please move Betfair tickets to a new match before ' + @movebet + ' GMT-4. Otherwise they will bring harm to the system'
		END
	END
	---------------------------------------------------
	DROP TABLE #Balance

	DROP TABLE #BalanceBefore

	DROP TABLE #BalanceAfter

	---------------------------------------------------
	SELECT @stop = CURRENT_TIMESTAMP

	IF @RowCount > 0 OR ((@IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1) AND @HTDone = 1)
	BEGIN
		DECLARE @LogData NVARCHAR(300)

		SELECT @LogData = 'Calculate (Refund FT) for matchid:' + CAST(@matchid AS NVARCHAR(10)) + CASE 
				WHEN @IsExcludeBetdaq = 1 THEN ', Exclude Betdaq tickets'
				ELSE ''
				END + CASE 
				WHEN @IsSettleAbandonedMatch = 1 THEN ', Settle determined betdaq tickets'
				ELSE ''
				END + CASE 
				WHEN @IsExcludeBetfair = 1 THEN ', Exclude Betfair tickets'
				ELSE ''
				END + CASE 
				WHEN @IsSettleAbandonedMatchBetFair = 1 THEN ', Settle determined betfair tickets'
				ELSE ''
				END + CASE 
				WHEN @IsSettleAbandonedMatchIBC = 1 THEN ', Settle determined IBC tickets'
				ELSE ''
				END

		EXEC dbo.WriteLog_UserLog @AdminID
			,@LogData

		--Write Log Settle
		DECLARE @hthomescore INT
			,@htawayscore INT
			,@goalrecord VARCHAR(50)

		SELECT @Remark = 'ExcludeBetdaqTickets=' + convert(CHAR(1), @IsExcludeBetdaq) + ' SettleDeterminedBetdaqTickets=' + convert(CHAR(1), @IsSettleAbandonedMatch) + ' ExcludeBetfairTickets=' + convert(CHAR(1), @IsExcludeBetfair) + ' SettleDeterminedBetfairTickets=' + convert(CHAR(1), @IsSettleAbandonedMatchBetFair) + ' SettleDeterminedIBCTickets=' + convert(CHAR(1), @IsSettleAbandonedMatchIBC) + CASE 
				WHEN (@IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1 OR @IsSettleAbandonedMatchIBC = 1) AND @HTDone = 1 THEN @ScoreLog
				ELSE ''
				END + ' Duration=' + CAST(DATEDIFF(millisecond, @start, @stop) AS NVARCHAR(50)) + ' ms;'

		SELECT @hthomescore = hthomescore
			,@htawayscore = htawayscore
			,@goalrecord = goalrecord
			,@betstatus = betstatus
		FROM DBPRO.BODB02.dbo.match WITH (NOLOCK)
		WHERE matchid = @matchid

		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @adminid
				,@Matchid = @matchid
				,@ActionID = @ActionID
				,@finalhomescore = 0
				,@finalawayscore = 0
				,@hthomescore = @hthomescore
				,@htawayscore = @htawayscore
				,@GoalRecord = @goalrecord
				,@betstatus = @betstatus
				,@Remark = @Remark
				,@IP = @IP
		END TRY

		BEGIN CATCH
			SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @adminid
				,@Matchid = @matchid
				,@ActionID = @ActionID
				,@finalhomescore = 0
				,@finalawayscore = 0
				,@hthomescore = @hthomescore
				,@htawayscore = @htawayscore
				,@GoalRecord = @goalrecord
				,@betstatus = @betstatus
				,@Remark = @Remark
				,@IP = @IP
		END CATCH
	END

	-----
	DELETE
	FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid

	IF (@@Error = 0)
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @adminID
				,@Matchid = @matchid
				,@KeyID = 1
				,@ActionID = @ActionID
				,@Remark = 'DEL SUCCESS'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @adminID
				,@Matchid = @matchid
				,@KeyID = 1
				,@ActionID = @ActionID
				,@Remark = @Remark
		END CATCH
	END
	ELSE
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @adminID
				,@Matchid = @matchid
				,@KeyID = 1
				,@ActionID = @ActionID
				,@Remark = 'DEL FAILED'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @adminID
				,@Matchid = @matchid
				,@KeyID = 1
				,@ActionID = @ActionID
				,@Remark = @Remark
		END CATCH
	END
END



GO

GRANT EXECUTE ON [NAP_Admin_Settlement_RefundFT] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_RefundFT] TO [vnteam] AS [dbo]
GO


