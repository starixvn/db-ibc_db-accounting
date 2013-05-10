ALTER PROCEDURE [dbo].[Admin_Settlement_VS_181]
	@matchid int, --VS EventID
	@action varchar(10) = 'CAL', -- CAL  / Refund 
	@IP varchar(50) = NULL ,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created by:[Victor]
	Date:[20130111]
	Task: Settlement 
	DB: DBTRANS.bodb02
	
	Revisions:

*/
BEGIN
SET NOCOUNT ON

-- check and not allow attempt to settlement same game while it's still not finish
IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 2 AND KeyValue = @matchid)
BEGIN
	SELECT  @ErrCode = 101,
			@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END

INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (2, @matchid) 

---------

	Declare @start datetime, @stop datetime , @LogData nvarchar(200), @ActionID int, @Remark varchar(500) 
	SELECT @start = CURRENT_TIMESTAMP
	

	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)
	Declare @TotalAccount int, @TotalAccount_BalanceUpdate int
		
	INSERT INTO #BalanceBefore
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid AND bettype in (1231,1232,1233)
	GROUP BY custid

	SET @TotalAccount = @@ROWCOUNT

	IF @action = 'CAL'
	BEGIN

			EXEC DB02.bodb02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_VS_181-CAL', @Matchid = @matchid
				
			EXEC Admin_Calculate_181M @matchid =@matchid  
			EXEC Admin_Calculate_181 @matchid =@matchid 

		SELECT @LogData = 'Calculate for matchid:' + CAST(@matchid as nvarchar(10)), @ActionID = 127	
	END
	ELSE IF @action = 'Refund'
	BEGIN

		EXEC DB02.bodb02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_VS_181-Refund', @Matchid = @matchid
		
		EXEC Admin_Calculate_VS_181_Refund @matchid =@matchid
						
		SELECT @LogData = 'Refund for matchid:' + CAST(@matchid as nvarchar(10)), @ActionID = 128	
	END

	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)
	
	INSERT INTO #BalanceAfter
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)	
	WHERE matchid = @matchid AND bettype in (1231,1232,1233)
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
	EXEC dbo.WriteLog_UserLog 181, @LogData


	SELECT @Remark = ' Duration:' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms; '
			+ ' Bal:' + CAST(IsNull(@TotalAccount_BalanceUpdate,0) as varchar(20)) + '/' + CAST(IsNull(@TotalAccount,0) as varchar(20))
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
		@UserID = 181, --a user is dedicted for bettype 181 to write log
		@Matchid = @matchid,
		@ActionID = @ActionID,
		@finalhomescore = NULL,
		@finalawayscore = NULL,  
		@hthomescore = NULL,
		@htawayscore = NULL,
		@GoalRecord = NULL,
		@betstatus = NULL,
		@Remark = @Remark,
		@IP = @IP



----
DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
WHERE KeyID = 2 AND KeyValue = @matchid

END

GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_VS_181] TO [Dot_Member] AS [dbo]