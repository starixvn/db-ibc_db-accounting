
ALTER PROCEDURE [dbo].[Admin_Settlement_FGLG_xtest]
	@creator int,
	@matchid int,	
	@betstatus nvarchar(50),
	@IncludeLG bit = 1,
	@IP varchar(15) = '',
	@goalrecord varchar(50) = '',
	@IsLoopTempTable BIT = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
	
AS
/*	Creator: Daniel
	Date: 
	Task: SP for settle FGLG
	DB: DBTRANS.bodb02
	
	History:
		- 20091225@Daniel: Add writelog to table Userlog_settle
		- 20100305@Daniel: Add writelog to table Userlog
		- 20100720@Henry: Change SP Logfile to WriteLog_UserLog
		- 20100825@Lukas: Update last time modify (changetime column) for match table
		- 20110606@Lukas: replace update match statement by store procedure	
		- 20110620@Jamie: Refer to Match in DB02 instead of DBTRANS	
		- 20120404@Joe: add balance table
		- 20120808@Sophia: . Add table TempVariableNumber to check if this match is being calculated then not allow to settle until the on-going process is completed
						   . Add new parametter @IsLoopTempTable to indicate this SP is nested or normal called
						   . Add @ErrCode, @ErrMsg to raise error
		- 20120930@Lukas: Put servername to control SP execution
	Param's Explanation:
		+ @betstatus: FGLG status
		+ @IsLoopTempTable: 1 : is nested
							0 : Normal
		
*/
SET NOCOUNT ON

IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
BEGIN
	IF @IsLoopTempTable = 0
	BEGIN
		-- check and not allow attempt to settlement same game while it's still not finish
		IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
		BEGIN
			SELECT  @ErrCode = 101,
					@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
			RETURN
		END

		INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)
	END
END

---

IF @@SERVERNAME IN ('DBTRANS','DB206')
BEGIN
	EXEC DB02.bodb02.dbo.Admin_Match_Update @Command	= 'Admin_Settlement_FGLG', 
											@MatchID	= @matchid, 
											@BetStatus	= @betstatus,
											@GoalRecord	= @goalrecord,
											@creator	= @creator
		-------------------------
END

--First Goal, Last Goal  
Declare @FGLG1 varchar(10), @FGLG2 varchar(10), @FLString varchar(10)

select @FGLG1 = '', @FGLG2 = ''

if charindex('FL:', @betstatus) > 0
BEGIN
	select 	@FLString = substring(@betstatus, charindex('FL:', @betstatus) + 3, 3)

	select @FGLG1 = case @FLString
						when '0-0' then '0:0'
						else left(@FLString,1) + ':1'
						end,			
			@FGLG2 = case @FLString
						when '0-0' then ''
						else right(@FLString,1) + ':2'
						end
END
-------------------------


-------------------------------------------------------------
---        CAPTURE value BALANCE before settlement        ---
---------------------------VVVV------------------------------
IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
BEGIN
	CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)
	Declare @TotalAccount int, @TotalAccount_BalanceUpdate int
	BEGIN
	--===
		INSERT INTO #BalanceBefore
		SELECT custid, SUM(winlost-actual_stake+playercomm)
		FROM dbo.bettrans with (rowlock)
		WHERE matchid = @matchid AND bettype = 14
		GROUP BY custid

		SET @TotalAccount = @@ROWCOUNT
	--===
	END
END

-- bettype 14 : First Goal Last Goal - re-use the SP of Correct Score, so we have to call it twice		

if @FGLG2 <> ''
BEGIN	
	EXEC dbo.Admin_Calculate_4 @matchid, 14, @FGLG1, 0, @FGLG2, 1
END
ELSE
BEGIN
	EXEC dbo.Admin_Calculate_4 @matchid, 14, @FGLG1, 0, NULL, 1
END


--refund all LG tickets if not include LG
IF @IncludeLG = 0
BEGIN
	EXEC dbo.Admin_Settlement_Refund_FGLG_xtest--refund LG
		@matchid = @matchid,
		@adminid = @creator,
		@LGOnly = 1,
		@IP = @IP,
		@IsLoopTempTable = 1 ---Not check concurrency by TempVariableNumber table	
END



-------------------------------------------------------------
---         CAPTURE value BALANCE after settlement        ---
---------------------------VVVV------------------------------
IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
BEGIN
	CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)
	BEGIN
	--===
		INSERT INTO #BalanceAfter
		SELECT custid, SUM(winlost-actual_stake+playercomm)
		FROM dbo.bettrans with (rowlock)
		WHERE matchid = @matchid AND bettype = 14
		GROUP BY custid
	--===
	END

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

-------------------------------------------------------------
---                      WRITE LOG                        ---
---------------------------VVVV------------------------------
IF @@SERVERNAME IN ('DBTRANS','DB206')
BEGIN
	--Write Log Settle
	DECLARE 
			@finalhomescore INT, @finalawayscore INT,
			@hthomescore INT, @htawayscore INT,
			@Remark varchar(50)
	SELECT 
			@finalhomescore = finalhomescore,
			@finalawayscore = finalawayscore,
			@hthomescore = hthomescore, 
			@htawayscore = htawayscore
	 FROM	DB02.BODB02.dbo.match WITH(NOLOCK) WHERE matchid = @matchid
	 
	DECLARE	@LogData VARCHAR(200)
	SELECT @LogData = 'Calculate FGLG for matchid:' + CAST(@matchid as nvarchar(10)) 
		+ ' score:' + CAST(ISNULL(@finalhomescore,0) as nvarchar(10)) + '-' + CAST(ISNULL(@finalawayscore,0) as nvarchar(10)) + ' HT:' + CAST(@hthomescore as nvarchar(10)) + '-' + CAST(@htawayscore as nvarchar(10)) 
		+ ' GoalRecord:' + ISNULL(@goalrecord, '') + ') Remark(BetStatus=' + @betstatus + ', IncludeLG=' + convert(char(1),@IncludeLG) + ')'
	EXEC dbo.WriteLog_UserLog @creator, @LogData

	SELECT @Remark = 'IncludeLG=' + convert(char(1),@IncludeLG)

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
		@UserID = @creator,
		@Matchid = @matchid,
		@ActionID = 108,
		@finalhomescore = @finalhomescore,
		@finalawayscore = @finalawayscore,  
		@hthomescore = @hthomescore,
		@htawayscore = @htawayscore,
		@GoalRecord = @goalrecord,
		@betstatus = @betstatus,
		@Remark = @Remark,
		@IP = @IP
END

-----
IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
BEGIN
	IF @IsLoopTempTable = 0
	BEGIN
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid
	END
END


GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_FGLG] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Settlement_FGLG] TO [vnteam]