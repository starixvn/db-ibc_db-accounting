ALTER PROCEDURE [dbo].[DBA_SettleOutright_Undo_Trans] 
	@matchid INT
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
Created: Elodie
Task : sp for undo outright

DB: DBTXN/BODB02
Original:

Revisions:
	
Param's Explanation:
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

	SELECT @ActionID = 141

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
				@Remark = 'ADD SUCCESS SPName = DBA_SettleOutright_Undo_Trans'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'ADD SUCCESS SPName = DBA_SettleOutright_Undo_Trans ErrMsg=' + left(error_message(), 400)
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

	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
 
	CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)
 
	INSERT INTO #BalanceBefore
	SELECT custid, sum(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid
		and bettype = 10
	Group by custid
 
 
	--Unsettle tickets
	UPDATE bettrans WITH (ROWLOCK, UPDLOCK)
	SET
		ruben = 0, status = 'running', statusID = 0,
		winlost = 0, awinlost = 0, mwinlost = 0, swinlost = 0,
		playercomm = 0, comm = 0, acomm = 0, scomm = 0
	WHERE matchid = @matchid
 
	-------------------------------------------------------------
	---         CAPTURE value BALANCE after unsettlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (custid int PRIMARY KEY , balance money)
 
	INSERT INTO #BalanceAfter
	SELECT custid,sum( winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid and bettype = 10
	Group by custid
         
	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	CREATE TABLE #Balance (custid int not null , balance money, Increased bit not null , PRIMARY KEY CLUSTERED(custid, Increased))
 
	INSERT INTO #Balance
	SELECT b.custid, a.balance - b.balance, CASE WHEN a.balance > b.balance THEN 1 ELSE 0 END
	FROM #BalanceBefore b
			INNER JOIN #BalanceAfter a ON b.custid = a.custid
	WHERE b.balance <> a.balance
 
	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)
 
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
	INSERT INTO [bodb02].[dbo].[BalanceNegative]
			   ([ExecDate]
			   ,[MatchID]
			   ,[ActionID]
			   ,[GroupID]
			   ,[CustID]
			   ,[Balance]
			   ,[StatusID]
			   ,[Remark])
	SELECT   GETDATE()
			,@MatchID
			,@ActionID --Undo settle
			,3  --outright settlement
			,CustID
			,Balance
			,0
			,NULL
	FROM    #Balance WITH (NOLOCK)
	WHERE   Increased = 0
                 
	---------------------------------------------------
	DROP TABLE #Balance
	DROP TABLE #BalanceBefore
	DROP TABLE #BalanceAfter 
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
				@Remark = 'DEL SUCCESS SPName = DBA_SettleOutright_Undo_Trans'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName = DBA_SettleOutright_Undo_Trans ErrMsg=' + left(error_message(), 400)
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
				@Remark = 'DEL FAILED SPName = DBA_SettleOutright_Undo_Trans'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED SPName = DBA_SettleOutright_Undo_Trans ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = 5838421,--dbaAdmin
				@Matchid = @matchid,
				@KeyID = 2,
				@ActionID = @ActionID,
				@Remark = @Remark
		END CATCH
	END

	-- WRITE LOG	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_SettleOutright 
			@UserID = 5838421
			,@MatchID = @matchid
			,@ActionID = @ActionID
			,@LeagueID = 0
			,@EventDate = NULL
			,@Remark = 'UNDO'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'UNDO ErrMsg=' + left(error_message(), 400)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_SettleOutright 
			@UserID = 5838421
			,@MatchID = @matchid
			,@ActionID = @ActionID
			,@LeagueID = 0
			,@EventDate = NULL
			,@Remark = @Remark
	END CATCH
END

GO
GRANT EXECUTE ON [dbo].[DBA_SettleOutright_Undo_Trans] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_SettleOutright_Undo_Trans] TO [vnteam] AS [dbo]
 