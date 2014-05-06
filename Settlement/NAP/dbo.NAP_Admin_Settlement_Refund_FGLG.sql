ALTER PROCEDURE [NAP_Admin_Settlement_Refund_FGLG] @matchid INT
	,@action VARCHAR(10) = 'CAL' -- CAL, CAL-HT, CAL-FT
	,@adminid INT
	,@LGOnly BIT
	,@IP VARCHAR(15) = ''
	,@IsLoopTempTable BIT = 0
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: Kathy
	Date: 20140213
	Task : Refund Half-time in case there are HT tickets bet on special matches that have 3 sets
	DB: DBTXN/BODB02
	Original: Admin_Settlement_Refund_FGLG

	Revisions:
		- 20140426@Kathy: Add 1H FGLG (127) [Redmine:#14449]
		
	Param's Explanation:
			+ @matchid: matchid of match to Refund HT
			+ @IsLoopTempTable: 1 : is nested
								0 : Normal

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Remark VARCHAR(500)
		,@ActionID INT
		,@bettype INT

	SELECT @ActionID = 112
		,@bettype = CASE 
			WHEN @action = 'CAL-HT' THEN 127
			WHEN @action = 'CAL-FT' THEN 14
			ELSE 0
			END

	IF @IsLoopTempTable = 0
	BEGIN
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

		CREATE TABLE #BalanceBefore (
			custid INT PRIMARY KEY
			,balance MONEY
			)

		DECLARE @TotalAccount INT
			,@TotalAccount_BalanceUpdate INT

		BEGIN
			INSERT INTO #BalanceBefore
			SELECT custid
				,SUM(winlost - actual_stake + playercomm)
			FROM dbo.bettrans WITH (ROWLOCK)
			WHERE matchid = @matchid AND ((@bettype = 0 AND bettype IN (14, 127)) OR (bettype = @bettype))
			GROUP BY custid

			SET @TotalAccount = @@ROWCOUNT
		END
	END

	------
	DECLARE @finalhomescore INT
		,@finalawayscore INT
		,@hthomescore INT
		,@htawayscore INT
		,@goalrecord VARCHAR(50)
		,@betstatus NVARCHAR(50)
		,@matchdate DATETIME

	SELECT @matchdate = eventdate
		,@betstatus = betstatus
	FROM DBPRO.bodb02.dbo.match WITH (NOLOCK)
	WHERE matchid = @matchid

	IF @LGOnly = 1 ---refund last goal
	BEGIN
		IF @action IN ('CAL', 'CAL-FT')
			SET @betStatus = CASE 
					WHEN CHARINDEX('FL:', @betstatus) > 0 THEN STUFF(@betStatus, LEN(@betStatus), 1, '0')
					ELSE @betStatus
					END

		IF @action IN ('CAL', 'CAL-HT')
			SET @betStatus = CASE 
					WHEN CHARINDEX('1FL:', @betstatus) > 0 THEN STUFF(@betstatus, CHARINDEX('1FL:', @betstatus) + 6, 1, '0')
					ELSE @betStatus
					END
	END
	ELSE --- refund all FGLG
	BEGIN
		IF @betStatus = 'Refund'
			SET @betStatus = 'Refund;'

		IF @action IN ('CAL', 'CAL-HT')
		BEGIN
			SET @betStatus = CASE 
					WHEN CHARINDEX('1FL:', @betstatus) > 0 THEN STUFF(@betstatus, CHARINDEX('1FL:', @betstatus), 7, '1FL:0-0')
					ELSE ISNULL(@betstatus, '') + '1FL:0-0'
					END
		END

		IF @action IN ('CAL', 'CAL-FT')
		BEGIN
			SELECT @betstatus

			SET @betStatus = CASE 
					WHEN CHARINDEX(';FL:', @betstatus) > 0 THEN SUBSTRING(@betStatus, 1, CHARINDEX(';FL:', @betStatus)) + 'FL:0-0'
					ELSE ISNULL(@betstatus, '') + ';FL:0-0'
					END
		END
	END

	EXEC DBPRO.BODB02.dbo.NAP_Admin_Match_Update @Command = 'NAP_Admin_Settlement_Refund_FGLG'
		,@MatchID = @matchid
		,@BetStatus = @betstatus

	--EXEC dbo.NAP_Admin_Calculate_RefundFGLG @matchid = @matchid, @LGOnly=@LGOnly, @matchdate=@matchdate
	EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
		,@action = 'REFUND-FGLG'
		,@mode = @action
		,@LGOnly = @LGOnly
		,@matchdate = @matchdate

	IF @IsLoopTempTable = 0
	BEGIN
		-------------------------------------------------------------
		---         CAPTURE value BALANCE after settlement        ---
		---------------------------VVVV------------------------------
		CREATE TABLE #BalanceAfter (
			custid INT PRIMARY KEY
			,balance MONEY
			)

		BEGIN
			INSERT INTO #BalanceAfter
			SELECT custid
				,SUM(winlost - actual_stake + playercomm)
			FROM dbo.bettrans WITH (ROWLOCK)
			WHERE matchid = @matchid AND ((@bettype = 0 AND bettype IN (14, 127)) OR (bettype = @bettype))
			GROUP BY custid
		END --IF @SkipBalanceUpdate = 0

		-------------------------------------------------------------
		---                   compare BALANCE                     ---
		---------------------------VVVV------------------------------
		CREATE TABLE #Balance (
			custid INT PRIMARY KEY
			,balance MONEY
			,Increased BIT
			)

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

		---------------------------------------------------
		DROP TABLE #Balance

		DROP TABLE #BalanceBefore

		DROP TABLE #BalanceAfter
	END

	DECLARE @LogData NVARCHAR(200)

	SELECT @LogData = 'Calculate (Refund FGLG) for matchid:' + CAST(@matchid AS NVARCHAR(10)) + 'action: ' + @action + 'LG Only:' + CASE 
			WHEN @LGOnly = 1 THEN ' (LG only)'
			ELSE ' (All)'
			END

	EXEC dbo.WriteLog_UserLog @AdminID
		,@LogData

	--Write Log Settle
	SELECT @finalhomescore = finalhomescore
		,@finalawayscore = finalawayscore
		,@hthomescore = hthomescore
		,@htawayscore = htawayscore
		,@goalrecord = goalrecord
		,@betstatus = betstatus
	FROM DBPRO.bodb02.dbo.match WITH (NOLOCK)
	WHERE matchid = @matchid

	SELECT @Remark = 'Action=' + @action + ' RefundLGOnly=' + convert(CHAR(1), @LGOnly)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @adminid
			,@Matchid = @matchid
			,@ActionID = @ActionID
			,@finalhomescore = @finalhomescore
			,@finalawayscore = @finalawayscore
			,@hthomescore = @hthomescore
			,@htawayscore = @htawayscore
			,@GoalRecord = @goalrecord
			,@betstatus = @betstatus
			,@Remark = @Remark
			,@IP = @IP
	END TRY

	BEGIN CATCH
		SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 350)

		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @adminid
			,@Matchid = @matchid
			,@ActionID = @ActionID
			,@finalhomescore = @finalhomescore
			,@finalawayscore = @finalawayscore
			,@hthomescore = @hthomescore
			,@htawayscore = @htawayscore
			,@GoalRecord = @goalrecord
			,@betstatus = @betstatus
			,@Remark = @Remark
			,@IP = @IP
	END CATCH

	-----
	IF @IsLoopTempTable = 0
	BEGIN
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
END

GO

GRANT EXECUTE ON [NAP_Admin_Settlement_Refund_FGLG] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_Refund_FGLG] TO [vnteam] AS [dbo]
GO


