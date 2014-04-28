ALTER PROCEDURE [NAP_Admin_Settlement_Refund_All] @matchid INT
	,@creator INT
	,@IsExcludeBetdaq BIT = 0
	,@IsSettleAbandonedMatch BIT = 0
	,@IsExcludeBetfair BIT = 0
	,@IsSettleAbandonedMatchBetFair BIT = 0
	,@IsSettleAbandonedMatchIBC BIT = 0
	,@hth INT = NULL
	,@hta INT = NULL
	,@fth INT = NULL
	,@fta INT = NULL
	,@betstatus NVARCHAR(50) = NULL
	,@Action VARCHAR(10) = 'CAL'
	,@IsNested BIT = 1
	,@IP VARCHAR(15) = ''
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: Kathy
	Date: 20140213
	Task : refund tickets 
	Original: refund
	DB: DBTXN/BODB02

	Revisions: 
		-20140304@Kathy: Execute settlement for abandoned/postponed matches- Clean Sheet, Both/One/Neither team to score, To Win To Nil 
		- 20140426@Kathy: Add 1H FGLG (127) [Redmine:#14449]
	
	Param's Explanation:
	• @matchid: matchid need to refund
	• @IsExcludeBetdaq: Is Exclude betdaq tickets or not
	• @IsSettleAbandonedMatch: Is Settlement for Abandoned/postponed match or not
	• @IsExcludeBetfair: Is Exclude betfair tickets or not
	• @IsSettleAbandonedMatchBetFair: Is Settlement for Betfair ticket of Abandoned/postponed match or not
	  @IsSettleAbandonedMatchIBC: Is Settlement for IBC ticket of Abandoned/postponed match or not
	* List of BetDaq Customers 
				custid	--- username	-	roleid
				50057	---	BQUS888		-	1
				879241	---	BQUSMLB		-	1
				103873	---	BQUSNBA		-	1
				78761	---	ITibc101	-	1
				1688156	---	MTEST0101	-	2
				851668  --- BDUS01      -   1
				878902  --- BDUS016     -   1
	* List of Betfair Customers 
				custid	--- username	-	roleid
				2331	---	BF		    -	1
				1077687	---	BFOS		-	1

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

	SELECT @ActionID = 109

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
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
				,@Matchid = @matchid
				,@KeyID = 1
				,@ActionID = @ActionID
				,@Remark = 'ADD SUCCESS'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(error_message(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
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
	WHERE matchid = @matchid AND bettype not IN (14, 127)
	GROUP BY custid

	IF @IsSettleAbandonedMatch = 1
		SELECT @IsExcludeBetdaq = 1

	IF @IsSettleAbandonedMatchBetFair = 1
		SELECT @IsExcludeBetfair = 1

	DECLARE @ScoreLog VARCHAR(100)
		,@sporttype TINYINT

	SELECT @sporttype = SportType
	FROM DBPRO.BODB02.dbo.Match WITH (NOLOCK)
	WHERE matchid = @matchid

	IF @IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1 OR @IsSettleAbandonedMatchIBC = 1
	BEGIN
		SELECT @ScoreLog = ' HTHScore=' + ISNULL(CAST(@hth AS VARCHAR(10)), '') + ' HTAScore=' + ISNULL(CAST(@hta AS VARCHAR(10)), '') + ' FTHScore=' + ISNULL(CAST(@fth AS VARCHAR(10)), '') + ' FTAScore=' + ISNULL(CAST(@fta AS VARCHAR(10)), '') + CASE 
				WHEN @SportType IN (5, 6, 9, 30) THEN ' Betstatus=Refund;'
				ELSE ' Betstatus='
				END + @betstatus

		DECLARE @TennisTotal SMALLINT
			,@T_Home SMALLINT
			,@T_Away SMALLINT

		IF @SportType IN (5, 6, 9, 30) -- Tennis/VolleyBall/Badminton/Squash : get TotalGamesPlayed
			EXEC dbo.Admin_Settlement_2 @betstatus = @betstatus
				,@Total = @TennisTotal OUTPUT
				,@TotalHome = @T_Home OUTPUT
				,@TotalAway = @T_Away OUTPUT

		DECLARE @totalgoal SMALLMONEY
			,@totalht SMALLMONEY

		SELECT @totalgoal = CASE 
				WHEN @sporttype IN (5, 6, 9, 30) AND @TennisTotal > 0 THEN @TennisTotal
				ELSE (@fth + @fta)
				END
			,@totalht = (@hth + @hta)

		IF @Action IN ('CAL', 'CAL-FT') AND @totalgoal IS NULL
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
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
						,@Matchid = @matchid
						,@KeyID = 1
						,@ActionID = @ActionID
						,@Remark = 'DEL SUCCESS'
				END TRY

				BEGIN CATCH
					SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)

					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
						,@Matchid = @matchid
						,@KeyID = 1
						,@ActionID = @ActionID
						,@Remark = @Remark
				END CATCH
			END
			ELSE
			BEGIN
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
						,@Matchid = @matchid
						,@KeyID = 1
						,@ActionID = @ActionID
						,@Remark = 'DEL FAILED'
				END TRY

				BEGIN CATCH
					SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)

					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
						,@Matchid = @matchid
						,@KeyID = 1
						,@ActionID = @ActionID
						,@Remark = @Remark
				END CATCH
			END

			RETURN
		END

		IF @Action IN ('CAL', 'CAL-HT') AND @totalht IS NULL
		BEGIN
			SELECT @ErrCode = 1000005
				,@ErrMsg = 'Cannot settle determined ticket(s) without HT Score!'

			-----
			DELETE
			FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
			WHERE KeyID = 1 AND KeyValue = @matchid

			IF (@@Error = 0)
			BEGIN
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
						,@Matchid = @matchid
						,@KeyID = 1
						,@ActionID = @ActionID
						,@Remark = 'DEL SUCCESS'
				END TRY

				BEGIN CATCH
					SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)

					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
						,@Matchid = @matchid
						,@KeyID = 1
						,@ActionID = @ActionID
						,@Remark = @Remark
				END CATCH
			END
			ELSE
			BEGIN
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
						,@Matchid = @matchid
						,@KeyID = 1
						,@ActionID = @ActionID
						,@Remark = 'DEL FAILED'
				END TRY

				BEGIN CATCH
					SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)

					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
						,@Matchid = @matchid
						,@KeyID = 1
						,@ActionID = @ActionID
						,@Remark = @Remark
				END CATCH
			END

			RETURN
		END
	END

	/*
		Settle Betdaq, Betfair tickets Abandoned Match for Over/Under 
*/
	IF @IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1
	BEGIN
		DECLARE @betcount_3 INT
			,@betcount_8 INT

		SELECT @betcount_3 = ISNULL(SUM(CASE bettype
						WHEN 3 THEN 1
						ELSE 0
						END), 0)
			,@betcount_8 = ISNULL(SUM(CASE bettype
						WHEN 8 THEN 1
						ELSE 0
						END), 0)
		FROM bettrans WITH (NOLOCK)
		WHERE matchid = @matchid AND bettype IN (3, 8) AND 1 = CASE 
				WHEN @IsSettleAbandonedMatch = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) THEN 1
				WHEN @IsSettleAbandonedMatchBetFair = 1 AND custid IN (2331, 1077687, 115770) THEN 1
				ELSE 0
				END AND statusID NOT IN (101, 102)

		IF @Action IN ('CAL', 'CAL-FT')
		BEGIN
			EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
				,@action = 'REFUND'
				,@mode = 'ALL'
				,@betcount_3 = 3 -- bettype
				,@totalgoal = @totalgoal
				,@ticket_count = @betcount_3 -- sum ticket of bettype
				,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
				,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
		END

		IF @Action IN ('CAL', 'CAL-HT')
		BEGIN
			EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
				,@action = 'REFUND'
				,@mode = 'ALL'
				,@betcount_8 = 8 -- bettype
				,@totalht = @totalht
				,@ticket_count = @betcount_8 -- sum ticket of bettype
				,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
				,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
		END
	END

	/* --- END Settle Betdaq, Betfair tickets Abandoned Match for Over/Under  ---*/
	--	Settle tickets Abandoned Match of Soccer for Clean Sheet, Both/One/Neither team to score, To Win To Nil  	
	IF (@IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1 OR @IsSettleAbandonedMatchIBC = 1) AND @action IN ('CAL', 'CAL-FT') AND @sporttype = 1
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
				WHEN @IsSettleAbandonedMatchIBC = 1 AND (custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770) AND recommend <> 1688156) THEN 1
				WHEN @IsSettleAbandonedMatch = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) THEN 1
				WHEN @IsSettleAbandonedMatchBetFair = 1 AND custid IN (2331, 1077687, 115770) THEN 1
				ELSE 0
				END

		EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
			,@action = 'REFUND'
			,@mode = 'ALL'
			,@betcount_13 = 13
			,@fth = @fth
			,@fta = @fta
			,@ticket_count = @betcount_13
			,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
			,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
			,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

		EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
			,@action = 'REFUND'
			,@mode = 'ALL'
			,@betcount_26 = 26
			,@fth = @fth
			,@fta = @fta
			,@ticket_count = @betcount_26
			,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
			,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
			,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

		EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
			,@action = 'REFUND'
			,@mode = 'ALL'
			,@betcount_27 = 27
			,@fth = @fth
			,@fta = @fta
			,@ticket_count = @betcount_27
			,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
			,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
			,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
	END

	EXEC DBPRO.BODB02.dbo.NAP_Admin_Match_Update @Command = 'NAP_Admin_Settlement_Refund_All'
		,@MatchID = @matchid
		,@creator = @creator

	EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
		,@action = 'REFUND'
		,@mode = 'ALL'
		,@IsExcludeBetdaq = @IsExcludeBetdaq
		,@IsExcludeBetfair = @IsExcludeBetfair
		,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
		,@fth = @fth
		,@fta = @fta
		,@row_count = 1

	INSERT INTO #BalanceAfter
	SELECT custid
		,SUM(winlost - actual_stake + playercomm)
	FROM dbo.bettrans WITH (ROWLOCK)
	WHERE matchid = @matchid AND bettype NOT in (14,127)
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

	--  Betfair & Betdaq - Warning message:
	DECLARE @movebet VARCHAR(20), @matchcode nvarchar(50)

	SELECT @movebet = convert(VARCHAR(20), DATEADD(d, 1, kickofftime), 100),
		@matchcode = matchcode
	FROM match WITH (NOLOCK)
	WHERE matchid = @matchid

	IF @matchcode not like '%Hedge%'
	BEGIN 
		IF (@IsExcludeBetdaq = 1 OR @IsSettleAbandonedMatch = 1) AND (@IsExcludeBetfair = 1 OR @IsSettleAbandonedMatchBetFair = 1)
		BEGIN
			SELECT @ErrCode = 1000006
				,@ErrMsg = 'Please move Betdaq and Betfair tickets to a new match before ' + @movebet + ' GMT-4. Otherwise they will bring harm to the system'
		END
		ELSE IF (@IsExcludeBetdaq = 1 OR @IsSettleAbandonedMatch = 1)
		BEGIN
			SELECT @ErrCode = 1000006
				,@ErrMsg = 'Please move Betdaq tickets to a new match before ' + @movebet + ' GMT-4. Otherwise they will bring harm to the system'
		END
		ELSE IF (@IsExcludeBetfair = 1 OR @IsSettleAbandonedMatchBetFair = 1)
		BEGIN
			SELECT @ErrCode = 1000006
				,@ErrMsg = 'Please move Betfair tickets to a new match before ' + @movebet + ' GMT-4. Otherwise they will bring harm to the system'
		END
	END 
	---------------------------------------------------
	DROP TABLE #Balance

	DROP TABLE #BalanceBefore

	DROP TABLE #BalanceAfter

	----------------------------------------------
	SELECT @stop = CURRENT_TIMESTAMP

	DECLARE @LogData NVARCHAR(200)

	SELECT @LogData = 'Calculate (Refund All) for matchid:' + CAST(@matchid AS NVARCHAR(10)) + CASE 
			WHEN @IsExcludeBetdaq = 1 THEN ', Exclude Betdaq tickets' ELSE '' END 
			+ CASE WHEN @IsSettleAbandonedMatch = 1 THEN ', Settle determined betdaq tickets' ELSE '' END 
			+ CASE WHEN @IsExcludeBetfair = 1 THEN ', Exclude Betfair tickets' ELSE '' END 
			+ CASE WHEN @IsSettleAbandonedMatchBetFair = 1 THEN ', Settle determined betfair tickets' ELSE '' END
			+ CASE WHEN @IsSettleAbandonedMatchIBC = 1 THEN ', Settle determined IBC tickets' ELSE '' END

	EXEC dbo.WriteLog_UserLog @creator
		,@LogData

	--Write Log Settle
	SELECT @Remark = 'ExcludeBetdaqTickets=' + convert(char(1),@IsExcludeBetdaq) 
					+ ' SettleDeterminedBetdaqTickets=' + convert(char(1),@IsSettleAbandonedMatch)
					+ ' ExcludeBetfairTickets=' + convert(char(1),@IsExcludeBetfair) 
					+ ' SettleDeterminedBetfairTickets=' + convert(char(1),@IsSettleAbandonedMatchBetFair)
					+ ' SettleDeterminedIBCTickets=' + convert(char(1),@IsSettleAbandonedMatchIBC)
					+ CASE WHEN (@IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair =1 OR @IsSettleAbandonedMatchIBC = 1) THEN @ScoreLog ELSE '' END 
					+ ' Action=' + @Action
					+ ' Duration=' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms;'

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @creator
			,@Matchid = @matchid
			,@ActionID = @ActionID
			,@finalhomescore = 0
			,@finalawayscore = 0
			,@hthomescore = 0
			,@htawayscore = 0
			,@GoalRecord = ''
			,@betstatus = 'Refund'
			,@Remark = @Remark
			,@IP = @IP
	END TRY

	BEGIN CATCH
		SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 250)

		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @creator
			,@Matchid = @matchid
			,@ActionID = @ActionID
			,@finalhomescore = 0
			,@finalawayscore = 0
			,@hthomescore = 0
			,@htawayscore = 0
			,@GoalRecord = ''
			,@betstatus = 'Refund'
			,@Remark = @Remark
			,@IP = @IP
	END CATCH

	-----
	DELETE
	FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid

	IF (@@Error = 0)
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
				,@Matchid = @matchid
				,@KeyID = 1
				,@ActionID = @ActionID
				,@Remark = 'DEL SUCCESS'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 350)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
				,@Matchid = @matchid
				,@KeyID = 1
				,@ActionID = @ActionID
				,@Remark = @Remark
		END CATCH
	END
	ELSE
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
				,@Matchid = @matchid
				,@KeyID = 1
				,@ActionID = @ActionID
				,@Remark = 'DEL FAILED'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 350)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
				,@Matchid = @matchid
				,@KeyID = 1
				,@ActionID = @ActionID
				,@Remark = @Remark
		END CATCH
	END

	IF @IsNested = 0
	BEGIN
		-- Update match_remark
		EXEC DBPRO.BODB02.dbo.NAP_updateMatch_remark @matchid
			,'F'

		-- Write log
		DECLARE @log VARCHAR(200)

		SET @log = 'Refund for matchid: ' + CONVERT(VARCHAR(10), @matchid)

		EXEC dbo.WriteLog_UserLog @creator
			,@Log
	END
END



GO

GRANT EXECUTE ON [NAP_Admin_Settlement_Refund_All] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_Refund_All] TO [vnteam] AS [dbo]
GO


