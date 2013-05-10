 
ALTER PROCEDURE [dbo].[Admin_Settlement_s162_xtest]
	@matchid int,
	@action varchar(10) = 'CAL', -- CAL  / Refund 
	@AdminID int = 5067934, -- Livecasino
	@betstatus varchar(50) ='',
	@CardsResult VARCHAR(50) = '',
	@IP varchar(50) = NULL ,
	@CommRate money = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created by:[Victor]
	Date:[20120109]
	Task: Settlement 
	DB: DBTRANS.bodb02
	
	Revisions:
		- 20120109@Viet: revise SP		
		- 20120207@Victor Su: add more parameter @CommRate to calc for WIN tickets of Banker bettype
		- 20120210@Lukas: apply credit/debit balance table
		- 20120808@Sophia: . Add table TempVariableNumber to check if this match is being calculated then not allow to settle until the on-going process is completed
						   . Add @ErrCode, @ErrMsg to raise error
		- 20120830@Victor: Add Live Roulette
		- 20120907@Victor: add @bettype put in homeid2 remove @bettype put in ParentID
		- 20120930@Lukas: Put servername to control SP execution
		
	Param explanation:
		@CardsResult: 
				1101: the sequence of cards result 'C2,H2,D2,S2,D3,S3'
				1102: not input this parameter
		@betstatus: 
				1101: '2,4,7'
				1102: input result ball number
		@CommRate:
				1101: 0.05 ~ 0.3
				1102: not input this parameter
*/
BEGIN
	SET NOCOUNT ON

	-- check and not allow attempt to settlement same game while it's still not finish
	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
		BEGIN
			SELECT  @ErrCode = 101,
					@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
			RETURN
		END
		
		INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid) 
	END

---------

	Declare @start datetime, @stop datetime , @LogData nvarchar(200), @ActionID int, @Remark varchar(500) ,@Bettype smallint ,@Newbetstatus varchar(100)
	SELECT @start = CURRENT_TIMESTAMP
	
	-- match.homeid2 will keep this match is which bettype
	select @Bettype = homeid2 FROM DB02.bodb02.dbo.Match with (rowlock)
	WHERE matchid = @matchid and sporttype = 162
	
	-- for old data not maintain match.homeid2
	if @bettype is null set @bettype = 1101
	
	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
	BEGIN
		CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)
		Declare @TotalAccount int, @TotalAccount_BalanceUpdate int
			
		INSERT INTO #BalanceBefore
		SELECT custid, SUM(winlost-actual_stake+playercomm)
		FROM dbo.bettrans with (rowlock)
		WHERE matchid = @matchid AND bettype = @Bettype
		GROUP BY custid
	END
	
	SET @TotalAccount = @@ROWCOUNT

	IF @action = 'CAL'
	BEGIN
		--bettye 1101,1102 all use Admin_Calculate_1101G for settle
		IF (@bettype = 1101)
		BEGIN
			IF @@SERVERNAME IN ('DBTRANS','DB206')
				EXEC DB02.bodb02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_s162-CAL', @Matchid = @matchid, @creator = @AdminID
				
			EXEC Admin_Calculate_1101G @matchid =@matchid  ,@betteam = @betstatus ,@CommRate =@CommRate ,@Bettype = @Bettype
			EXEC Admin_Calculate_1101 @matchid =@matchid 

		END
		ELSE 
		BEGIN
			IF @@SERVERNAME IN ('DBTRANS','DB206')
				EXEC DB02.bodb02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_s162-1102-CAL', @Matchid = @matchid, @creator = @AdminID
								
			select @Newbetstatus = StrValue from MappingTable  with (rowlock) where Ballno = @betstatus
					
			EXEC Admin_Calculate_1101G @matchid =@matchid  ,@betteam = @Newbetstatus ,@CommRate =@CommRate ,@Bettype = @Bettype
			EXEC Admin_Calculate_1101 @matchid =@matchid 

		END	
		SELECT @LogData = 'Calculate for matchid:' + CAST(@matchid as nvarchar(10)) + 'CommRate:' + CAST(@CommRate as nvarchar(10)), @ActionID = 121	
	END
	ELSE IF @action = 'Refund'
	BEGIN
		IF @@SERVERNAME IN ('DBTRANS','DB206')
			EXEC DB02.bodb02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_s162-Refund', @Matchid = @matchid, @creator = @AdminID
		
		EXEC Admin_Calculate_s162_Refund @matchid =@matchid
						
		SELECT @LogData = 'Refund for matchid:' + CAST(@matchid as nvarchar(10)) + 'CommRate:' + CAST(@CommRate as nvarchar(10)), @ActionID = 122	
	END

	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
	BEGIN
		CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)
		
		INSERT INTO #BalanceAfter
		SELECT custid, SUM(winlost-actual_stake+playercomm)
		FROM dbo.bettrans with (rowlock)
		WHERE matchid = @matchid AND bettype = @Bettype
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
	END

	SELECT @stop = CURRENT_TIMESTAMP

	IF @@SERVERNAME IN ('DBTRANS','DB206')
	BEGIN
		SELECT @LogData = @LogData + '(' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms)'
		EXEC dbo.WriteLog_UserLog @AdminID, @LogData

		SELECT @Remark = 'Cards result: ' + @CardsResult + '; '
						+ ' Duration:' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms; '
						+ ' Bal:' + CAST(IsNull(@TotalAccount_BalanceUpdate,0) as varchar(20)) + '/' + CAST(IsNull(@TotalAccount,0) as varchar(20))
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
			@UserID = @AdminID,
			@Matchid = @matchid,
			@ActionID = @ActionID,
			@finalhomescore = NULL,
			@finalawayscore = NULL,  
			@hthomescore = NULL,
			@htawayscore = NULL,
			@GoalRecord = NULL,
			@betstatus = @betstatus,
			@Remark = @Remark,
			@IP = @IP
	END
----
	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid

END

GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_s162_XTEST] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_s162_XTEST] TO [Dot_Casino]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Settlement_s162_XTEST] TO [vnteam]