ALTER PROCEDURE [dbo].[Dot_Admin_SettleOutright_Trans] 
	@matchid INT
	,@status NVARCHAR(10)
	,@deadheat FLOAT = 1
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
	,@eventdate SMALLDATETIME = NULL
AS
/*
Created:
Task : sp for outright settlement

DB: DBTXN/BODB02
Original:

Revisions:
	- 20120202@Thien: receive @winlostdate param from outside SP, to resolve late replication in DBDW/2
	- 20120430@AllenWu: Apply new credit balance procedure
	- 20120808@Sophia: . Add table TempVariableNumber to check if this match is being calculated then not allow to settle until the on-going process is completed
					   . Add @ErrCode, @ErrMsg to raise error
	- 20130103@Elodie:  Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table
	- 20130121@Elodie:  Write more log on DBTXN server in case of DBLOG server failure
	- 20130624@Martin: Hotfix(There is already an object named 'pk_C2' in the database.Could not create constraint. See previous errors)
	- 20130624@Jamie: Add BalanceNegative 
	- 20130719@Ava::Add @eventdate when user re-settle
	- 20140219@Elodie: Write settlement log for outright
Param's Explanation:
	- @deadheat = fraction of deadheat to divide (1,2,3  etc)
*/
BEGIN	
	SET NOCOUNT ON

	-- check and not allow attempt to settlement same game while it's still not finish
	IF EXISTS (
			SELECT 1
			FROM dbo.TempVariableNumber
			WHERE KeyID = 2
				AND KeyValue = @matchid
			)
	BEGIN
		SELECT @ErrCode = 101
			,@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END

	DECLARE @Remark VARCHAR(500), @ActionID INT

	SELECT @ActionID = CASE @status 
		WHEN 'Refund' THEN 139 
		WHEN 'Won' THEN 137
		WHEN 'Lose' THEN 137
	END

	INSERT INTO dbo.TempVariableNumber (
		KeyID
		,KeyValue
		)
	VALUES (
		2
		,@matchid
		)

	IF (@@Error = 0)
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = 5838421,--dbaAdmin
				@Matchid = @matchid,
				@KeyID = 2,
				@ActionID = @ActionID,
				@Remark = 'ADD SUCCESS SPName = Dot_Admin_SettleOutright_Trans'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'ADD SUCCESS SPName = Dot_Admin_SettleOutright_Trans ErrMsg=' + left(error_message(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = 5838421,--dbaAdmin
				@Matchid = @matchid,
				@KeyID = 2,
				@ActionID = @ActionID,
				@Remark = @Remark
		END CATCH
	END
	ELSE
	BEGIN
		SELECT @ErrCode = 102
			,@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

		RETURN
	END

	---------
	DECLARE @winlostdate SMALLDATETIME

	IF (@eventdate IS NULL)
		SET @winlostdate = convert(CHAR(10), getdate(), 111)
	ELSE
		SET @winlostdate = convert(CHAR(10), @eventdate, 111)

	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceBefore (
		custid INT PRIMARY KEY
		,balance MONEY
		)

	INSERT INTO #BalanceBefore
	SELECT custid
		,sum(winlost - actual_stake + playercomm)
	FROM dbo.bettrans WITH (ROWLOCK)
	WHERE matchid = @matchid
		AND bettype = 10
		AND statusID NOT IN (101, 102)
	GROUP BY custid

	EXEC Admin_Calculate_10 @matchid
		,@status
		,@deadheat
		,@winlostdate

	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (
		custid INT PRIMARY KEY
		,balance MONEY
		)

	INSERT INTO #BalanceAfter
	SELECT custid
		,sum(winlost - actual_stake + playercomm)
	FROM dbo.bettrans WITH (ROWLOCK)
	WHERE matchid = @matchid
		AND bettype = 10
		AND statusID = CASE @status
			WHEN 'won' THEN 112
			WHEN 'lose' THEN 113
			WHEN 'Refund' THEN 103
			ELSE 999
			END
	GROUP BY custid

	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	CREATE TABLE #Balance (
		custid INT NOT NULL
		,balance MONEY
		,Increased BIT NOT NULL
		,PRIMARY KEY CLUSTERED (custid, Increased)
		)

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

	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

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
		,3 ---- Outright Settlement 
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

	---------------------------------------------------
	--add log to outright_log to notify for Apollo
	EXEC bodb02.dbo.[Acc_Set_ConfirmedActionOutright] @matchid = @matchid
		,@actionid = 31
		,@status = @status
		,@deadheat = @deadheat

	----------------------------------------------------
	DELETE
	FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
	WHERE KeyID = 2
		AND KeyValue = @matchid

	IF (@@Error = 0)
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = 5838421,--dbaAdmin
				@Matchid = @matchid,
				@KeyID = 2,
				@ActionID = @ActionID,
				@Remark = 'DEL SUCCESS SPName = Dot_Admin_SettleOutright_Trans'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName = Dot_Admin_SettleOutright_Trans ErrMsg=' + left(error_message(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = 5838421,--dbaAdmin
				@Matchid = @matchid,
				@KeyID = 2,
				@ActionID = @ActionID,
				@Remark = @Remark
		END CATCH
	END
	ELSE
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = 5838421,--dbaAdmin
				@Matchid = @matchid,
				@KeyID = 2,
				@ActionID = @ActionID,
				@Remark = 'DEL FAILED SPName = Dot_Admin_SettleOutright_Trans'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED SPName = Dot_Admin_SettleOutright_Trans ErrMsg=' + left(error_message(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = 5838421,--dbaAdmin
				@Matchid = @matchid,
				@KeyID = 2,
				@ActionID = @ActionID,
				@Remark = @Remark
		END CATCH
	END

	-- WRITE LOG
	SELECT @Remark = 'Status=' + @status + 'IsDeadheat=' + CAST(@deadheat AS VARCHAR(5))

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_SettleOutright 
			@UserID = 5838421
			,@MatchID = @matchid
			,@ActionID = @ActionID
			,@LeagueID = 0
			,@EventDate = @winlostdate
			,@Remark = @Remark
	END TRY

	BEGIN CATCH
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_SettleOutright 
			@UserID = 5838421
			,@MatchID = @matchid
			,@ActionID = @ActionID
			,@LeagueID = 0
			,@EventDate = @winlostdate
			,@Remark = @Remark
	END CATCH
END

GO
GRANT EXECUTE ON [dbo].[Dot_Admin_SettleOutright_Trans] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Dot_Admin_SettleOutright_Trans] TO [Dot_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Admin_SettleOutright_Trans] TO [vnteam] AS [dbo]
