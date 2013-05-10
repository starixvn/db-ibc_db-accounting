ALTER PROCEDURE [dbo].[Admin_Settlement_SS]
	@oddsid		int,
	@action varchar(10) = 'CAL', -- CAL  / Refund / RefundBO  (Refund By Oddsid)
	@IP varchar(50) = NULL ,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created by:[Victor]
	Date:[20120920]
	Task: Settlement 
	DB: DBTXN/BODB02
	Revisions:
		- 20121018@Elodie: Add @bettype value into content of log
		- 20121022@Elodie: Remove @betteam value from @Remark string
						   Update @ActionID value
		- 20130103@Elodie: Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table																 
		- 20130121@Elodie: Change link server DB02 to DBPRO
						   Write more log on DBTXN server in case of DBLOG server failure
*/
BEGIN
SET NOCOUNT ON
Declare @start datetime, @stop datetime , @LogData nvarchar(200), @ActionID int, @Remark varchar(500) , @betteam Varchar(10) ,@matchid int , @bettype int
SELECT @ActionID = CASE @Action 
		WHEN 'CAL' THEN 127
		WHEN 'Refund' THEN 128
		WHEN 'RefundBO' THEN 129 		
	END
-- check and not allow attempt to settlement same game while it's still not finish
IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 3 AND KeyValue = @oddsid)
BEGIN
	SELECT  @ErrCode = 101,
			@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END

INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (3, @oddsid)
IF (@@Error = 0)
BEGIN
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = 111, 
			@Matchid = @oddsid, 
			@KeyID = 3,
			@ActionID = @ActionID, 
			@Remark = 'ADD SUCCESS'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(error_message(), 400)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = 111, 
			@Matchid = @oddsid, 
			@KeyID = 3,
			@ActionID = @ActionID, 
			@Remark = @Remark
	END CATCH
END
ELSE 
BEGIN
	SELECT @ErrCode = 100, @ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END
---------
	
	SELECT @start = CURRENT_TIMESTAMP	
	
	select @Matchid = matchid , @bettype = bettype From Odds (nolock) WHERE oddsid = @oddsid
	
	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)
	Declare @TotalAccount int, @TotalAccount_BalanceUpdate int
		
	INSERT INTO #BalanceBefore
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE Matchid = @Matchid 
	GROUP BY custid

	SET @TotalAccount = @@ROWCOUNT

	IF @action = 'CAL'
	BEGIN
	
		EXEC DBPRO.BODB02.dbo.Dot_Member_SS_GetBetteam @oddsid = @oddsid , @betteam = @betteam output
		 
		--settle
		EXEC Admin_Calculate_SS @matchid = @matchid , @bettype = @bettype , @oddsid = @oddsid , @betteam = @betteam
		
		If @bettype = 1301
		Begin	 
			EXEC DBPRO.BODB02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_SS-CAL', @Matchid = @matchid
		End
		
		SELECT @LogData = 'Calculate for matchid:' + CAST(@matchid as nvarchar(10)) + 'Oddsid:' + CAST(@Oddsid as nvarchar(10)), @ActionID = @ActionID
	END
	ELSE IF @action in ('Refund','RefundBO')
	BEGIN

		--EXEC DBPRO.BODB02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_SS-Refund', @Matchid = @matchid
		
		EXEC Admin_Calculate_SS_Refund @matchid =@matchid , @oddsid = @oddsid , @action = @action
						
		SELECT @LogData = 'Refund for matchid:' + CAST(@matchid as nvarchar(10)) + 'Action:' + @action , @ActionID = @ActionID	
	END
	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)
	
	INSERT INTO #BalanceAfter
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE Matchid = @Matchid 
	GROUP BY custid
	

	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	CREATE TABLE #Balance (custid int PRIMARY KEY, balance money, Increased bit)
	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

	INSERT INTO #Balance
	SELECT b.custid, a.balance - b.balance, CASE WHEN a.balance > b.balance THEN 1 ELSE 0 END
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

	DROP TABLE #Balance
	DROP TABLE #BalanceBefore
	DROP TABLE #BalanceAfter


	SELECT @stop = CURRENT_TIMESTAMP


	SELECT @LogData = @LogData + '(' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms)'
	EXEC dbo.WriteLog_UserLog 111, @LogData
	
	SELECT @Remark = 'Oddsid:' + CAST(@Oddsid as nvarchar(10)) + ' Bettype:' + CONVERT(VARCHAR(20),@Bettype) + ';' 
					+ ' Duration:' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms; '
					+ '/' + CAST(IsNull(@TotalAccount,0) as varchar(20))
	BEGIN TRY					
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
			@UserID = 111,
			@Matchid = @matchid,
			@ActionID = @ActionID,
			@finalhomescore = NULL,
			@finalawayscore = NULL,  
			@hthomescore = NULL,
			@htawayscore = NULL,
			@GoalRecord = NULL,
			@betstatus = @betteam,
			@Remark = @Remark,
			@IP = @IP
	END TRY
	BEGIN CATCH
		SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 250)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
			@UserID = 111,
			@Matchid = @matchid,
			@ActionID = @ActionID,
			@finalhomescore = NULL,
			@finalawayscore = NULL,  
			@hthomescore = NULL,
			@htawayscore = NULL,
			@GoalRecord = NULL,
			@betstatus = @betteam,
			@Remark = @Remark,
			@IP = @IP
	END CATCH
		
----
DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
WHERE KeyID = 3 AND KeyValue = @oddsid
IF (@@Error = 0)
BEGIN	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = 111, 
			@Matchid = @oddsid, 
			@KeyID = 3,
			@ActionID = @ActionID, 
			@Remark = 'DEL SUCCESS'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = 111, 
			@Matchid = @oddsid, 
			@KeyID = 3,
			@ActionID = @ActionID, 
			@Remark = @Remark
	END CATCH
END
ELSE
BEGIN
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = 111, 
			@Matchid = @oddsid, 
			@KeyID = 3,
			@ActionID = @ActionID, 
			@Remark = 'DEL FAILED'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = 111, 
			@Matchid = @oddsid, 
			@KeyID = 3,
			@ActionID = @ActionID, 
			@Remark = @Remark
	END CATCH
END
END
GO


 