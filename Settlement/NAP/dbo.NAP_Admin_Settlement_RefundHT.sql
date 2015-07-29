USE [bodb02]
GO

ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_RefundHT] @matchid INT
	,@adminid INT
	,@IsExcludeBetdaq BIT = 0
	,@IsSettleAbandonedMatch BIT = 0
	,@IsExcludeBetfair BIT = 0
	,@IsSettleAbandonedMatchBetFair BIT = 0
	,@hth INT = NULL
	,@hta INT = NULL
	,@isExistTotalCorner			BIT	= 0 
	,@isExistHTFCorner				BIT	= 0 
	,@isExistHTLCorner				BIT	= 0 
	,@isExistFTFCorner				BIT	= 0 
	,@isExistFTLCorner				BIT	= 0  
	,@IP VARCHAR(15) = ''
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: Kathy
	Date: 20140213
	Task : Refund Half-time in case there are HT tickets bet on special matches that have 3 sets
	DB: DBTXN/BODB02
	Original: Admin_Settlement_RefundHT

	Revisions:
		- 20140421@Kathy: Add new bettype 126 [Redmine:#14449]
		- 20140729@Kathy: Add one more account(BF3) into BetFair's group [Redmine:#19665]
		- 20140617@Kathy: Apply BetRadar [Redmine:#17142]
		- 20140710@Kathy: Apply BetRadar - PenaltyShootout(135) [Redmine:#17142]	
		- 20140811@Kathy: Support new 11 bettypes [Redmine:#19667]
		- 20150422@Jamie: Manual Settlement Betradar phase 2 [Redmine: #27212]
		- 20150611@Johnson: Add bettrade [Redmine: #35921]
	
	Param's Explanation:
	• @matchid: matchid of match to Refund HT
	• @IsExcludeBetdaq: Is Exclude betdaq tickets or not
	• @IsSettleAbandonedMatch: Is Settlement for Betdaq ticket of Abandoned/postponed match or not
	• @IsExcludeBetfair: Is Exclude betfair tickets or not
	• @IsSettleAbandonedMatchBetFair: Is Settlement for Betfair ticket of Abandoned/postponed match or not

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

	SELECT @ActionID = 110

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
			
	CREATE TABLE #tmpTrans (transid BIGINT)

	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)
	
	INSERT INTO #tmpTrans
	SELECT transid
	FROM dbo.bettrans WITH (ROWLOCK)
	WHERE matchid = @matchid 
		AND bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209)
		AND betdaqid = 0--bettrade tickets
		
	INSERT INTO #BalanceBefore
	SELECT custid
		,SUM(winlost - actual_stake + playercomm)
	FROM dbo.bettrans WITH (ROWLOCK)
	WHERE matchid = @matchid 
		AND bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209,901,902,903)
		AND 1 = CASE WHEN bettype IN (901,902,903) 
						AND refno IN (SELECT transid FROM #tmpTrans)	
						THEN 1 
					WHEN bettype NOT IN (901,902,903) THEN 1
				ELSE 0 END
	GROUP BY custid

	IF @IsSettleAbandonedMatch = 1
		SELECT @IsExcludeBetdaq = 1

	IF @IsSettleAbandonedMatchBetFair = 1
		SELECT @IsExcludeBetfair = 1

	--Check if match already Refund FT => refund whole match
	IF EXISTS (
			SELECT 1
			FROM DBPRO.BODB02.dbo.Match WITH (NOLOCK)
			WHERE matchid = @matchid AND betstatus LIKE '%Refund FT%'
			)
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
			,@hth = @hth
			,@hta = @hta
			,@fth = NULL
			,@fta = NULL
			,@betstatus = NULL
			,@hthCorners = NULL
			,@htaCorners = NULL
			,@HTFCorner	 = NULL
			,@isExistTotalCorner= @isExistTotalCorner
			,@isExistHTFCorner	= @isExistHTFCorner
			,@isExistHTLCorner	= @isExistHTLCorner
			,@isExistFTFCorner	= @isExistFTFCorner
			,@isExistFTLCorner	= @isExistFTLCorner
			,@Action = 'CAL-HT'
			,@IP = @IP
			,@ErrCode = @ErrCode OUTPUT
			,@ErrMsg = @ErrMsg OUTPUT

		RETURN
	END

	IF @IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1
	BEGIN
		DECLARE @ScoreLog VARCHAR(100)

		SELECT @ScoreLog = ' HTHScore=' + CAST(@hth AS VARCHAR(10)) + ' HTAScore=' + CAST(@hta AS VARCHAR(10))

		DECLARE @totalht SMALLMONEY

		SELECT @totalht = (@hth + @hta)

		IF @totalht IS NULL
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

		DECLARE @betcount_8 INT

		SELECT @betcount_8 = ISNULL(SUM(CASE bettype WHEN 8 THEN 1 ELSE 0 END), 0)
		FROM bettrans WITH (NOLOCK)
		WHERE matchid = @matchid 
		AND bettype = 8 
		AND 1 = CASE 
					WHEN @IsSettleAbandonedMatch = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) THEN 1
					WHEN @IsSettleAbandonedMatchBetFair = 1 AND custid IN (2331, 1077687, 115770, 15523642) THEN 1
					ELSE 0
				END 
		AND statusID NOT IN (101, 102)

								EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
			,@action = 'REFUND'
			,@mode = 'HT'
			,@betcount_8 = @betcount_8 -- bettype
			,@totalht = @totalht
			,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
			,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
	END

	/* --- END Settle Abandoned Match ---*/
	DECLARE @RowCount INT

	EXEC DBPRO.BODB02.dbo.NAP_Admin_Match_Update @Command = 'NAP_Admin_Settlement_RefundHT'
		,@Matchid = @matchid
		,@RowCount = @Rowcount OUTPUT
		,@creator = @adminid

	EXEC DBPRO.BODB02.dbo.[NAP_Admin_Result_Update_1s] 
		@Command			= 'NAP_Admin_Settlement_RefundHT'
		,@MatchID			= @matchid
		,@isExistTotalCorner= @isExistTotalCorner
		,@isExistHTFCorner	= @isExistHTFCorner
		,@isExistHTLCorner	= @isExistHTLCorner
		,@creator			= @adminid

	IF @Rowcount > 0
	BEGIN
		EXEC DBPRO.BODB02.dbo.NAP_updateMatch_remark @matchid
			,'F'

								EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
			,@action = 'REFUND'
			,@mode = 'HT'
			,@IsExcludeBetdaq = @IsExcludeBetdaq
			,@IsExcludeBetfair = @IsExcludeBetfair
			,@row_count = @RowCount
	END

	INSERT INTO #BalanceAfter
	SELECT custid
		,SUM(winlost - actual_stake + playercomm)
	FROM dbo.bettrans WITH (ROWLOCK)
	WHERE matchid = @matchid 
		AND bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209,901,902,903)
		AND 1 = CASE WHEN bettype IN (901,902,903) 
						AND refno IN (SELECT transid FROM #tmpTrans)	
						THEN 1 
					WHEN bettype NOT IN (901,902,903) THEN 1
				ELSE 0 END--bettrade
	GROUP BY custid

	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
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
	DECLARE @movebet VARCHAR(20)
		,@matchcode NVARCHAR(50)

	SELECT @movebet = convert(VARCHAR(20), DATEADD(d, 1, kickofftime), 100)
		,@matchcode = matchcode
	FROM match WITH (NOLOCK)
	WHERE matchid = @matchid

	IF @matchcode NOT LIKE '%Hedge%'
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
	
	DROP TABLE #tmpTrans

	-------------------------------------------------------------
	---                      WRITE LOG                        ---
	---------------------------VVVV------------------------------
	SELECT @stop = CURRENT_TIMESTAMP

	IF @IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1 OR @Rowcount > 0
	BEGIN
		DECLARE @LogData NVARCHAR(300)

		SELECT @LogData = 'NAP: Calculate (Refund HT) for matchid:' + CAST(@matchid AS NVARCHAR(10))

		EXEC dbo.WriteLog_UserLog @UserID = @AdminID
			,@Doing = @LogData

		--Write Log Settle
		DECLARE @finalhomescore INT
			,@finalawayscore INT
			,@betstatus NVARCHAR(50)
			,@goalrecord VARCHAR(50)

		SELECT @finalhomescore = finalhomescore
			,@finalawayscore = finalawayscore
			,@goalrecord = goalrecord
			,@betstatus = betstatus
		FROM DBPRO.BODB02.dbo.Match WITH (NOLOCK)
		WHERE matchid = @matchid

		SELECT @Remark = 'NAP: ExcludeBetdaqTickets=' + convert(CHAR(1), @IsExcludeBetdaq) + ' SettleDeterminedBetdaqTickets=' + convert(CHAR(1), @IsSettleAbandonedMatch) + ' ExcludeBetfairTickets=' + convert(CHAR(1), @IsExcludeBetfair) + ' SettleDeterminedBetfairTickets=' + convert(CHAR(1), @IsSettleAbandonedMatchBetFair) + CASE 
				WHEN @IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1 THEN @ScoreLog
				ELSE ''
				END + ' Duration=' + CAST(DATEDIFF(millisecond, @start, @stop) AS NVARCHAR(50)) + ' ms;'

		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @adminid
				,@Matchid = @matchid
				,@ActionID = @ActionID
				,@finalhomescore = @finalhomescore
				,@finalawayscore = @finalawayscore
				,@hthomescore = 0
				,@htawayscore = 0
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
				,@finalhomescore = @finalhomescore
				,@finalawayscore = @finalawayscore
				,@hthomescore = 0
				,@htawayscore = 0
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
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_RefundHT] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_RefundHT] TO [vnteam] AS [dbo]