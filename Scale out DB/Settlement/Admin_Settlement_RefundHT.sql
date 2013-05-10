ALTER PROCEDURE [dbo].[Admin_Settlement_RefundHT_xtest]
	@matchid int,
	@adminid int,
	@IsExcludeBetdaq bit = 0,
	@IsSettleAbandonedMatch bit = 0,
	@hth int = NULL,
	@hta int = NULL,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
as

/*
	Created: 20090722@VinhTruong
	Task : Refund Half-time in case there are HT tickets bet on special matches that have 3 sets
	DB: DBTRANS.bodb02
	Original: Admin_Settlement_RefundHT

	Revisions:
		- 20091012@Kiwi: Remove custBetCredit
		- 20091031@Jamie: Change the name of SP - "Refund" into "Admin_Settlement_Refund_All"
		- 20091225@Daniel: Add writelog to table Userlog_settle
		- 20100305@Daniel: Add back writelog to table Userlog
		-- 20100424@Henry: Update column StatusID of Bettrans
		-- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100610@Jamie: Call nested SP "Admin_Calculate_RefundHT"
		- 20100706@Shifu: Allow to refund HT when match is 'Running'
		- 20100720@Henry: Fix Refund HT when betstatus is NULL
		- 20100727@Jamie: Fix bugs in getting the finalawayscore wrongly 
		- 20100825@Lukas: Update last time modify (changetime column) for match table 
		- 20110606@Lukas: replace update match statement by store procedure	
		- 20110620@Jamie: Refer to Match in DB02 instead of DBTrans 
		- 20120215@Jamie: Settle Abandoned Match
		- 20120314@Jamie: Allow entering score for Settlement O/U BETDAQ
		- 20120808@Sophia: Add table TempVariableNumber to check if this match is being calculated then not allow to settle until the on-going process is completed
		- 20120930@Lukas: Put servername to control SP execution
		
	Param's Explanation:
	• @matchid: matchid of match to Refund HT
	• @IsExcludeBetdaq: Is Exclude betdaq tickets or not
	• @IsSettleAbandonedMatch: Is Settlement for Abandoned/postponed match or not

*/
SET NOCOUNT ON 

DECLARE	@start DATETIME, @stop DATETIME
SELECT	@start = CURRENT_TIMESTAMP

IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
BEGIN
	-- check and not allow attempt to settlement same game while it's still not finish
	IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END

	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)

	---
	CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)

	CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)

	CREATE TABLE #Balance (custid int PRIMARY KEY, balance money, Increased bit)
	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

	INSERT INTO #BalanceBefore
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid AND bettype IN (7,8,12,15,21,30,125)
	GROUP BY custid
END

IF @IsSettleAbandonedMatch = 1 SELECT @IsExcludeBetdaq = 1 

--Check if match already Refund FT => refund whole match

if exists(select 1 from DB02.BODB02.dbo.Match with (nolock) where matchid = @matchid AND betstatus like '%Refund FT%')
BEGIN
	-----
	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid
		
	EXEC dbo.Admin_Settlement_Refund_All 
			@matchid = @matchid, 
			@creator = @adminid,
			@IsExcludeBetdaq = @IsExcludeBetdaq,
			@IsSettleAbandonedMatch = @IsSettleAbandonedMatch,
			@hth = @hth,
			@hta = @hta, 
			@fth = NULL,
			@fta = NULL,
			@betstatus = NULL,
			@Action='CAL-HT',
			@IP = @IP,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT 
		
	RETURN
END

IF @IsSettleAbandonedMatch = 1 
BEGIN 
			
	DECLARE	@ScoreLog VARCHAR(100)

	SELECT	@ScoreLog = ' HTHScore=' + CAST(@hth AS VARCHAR(10))
						+ ' HTAScore=' + CAST(@hta AS VARCHAR(10))
						
	DECLARE @totalht smallmoney

	SELECT	@totalht	= (@hth + @hta)
			
	IF	@totalht IS NULL 
	BEGIN 
		SELECT	@ErrCode = 110
				,@ErrMsg = 'Cannot settle determined ticket(s) without HT Score!'
		
		-----
		IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
			DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
			WHERE KeyID = 1 AND KeyValue = @matchid
				
		RETURN
	END

	DECLARE @betcount_8 int
	SELECT	@betcount_8 = ISNULL(SUM(case bettype when 8 then 1 else 0 end), 0)
	FROM	bettrans WITH(NOLOCK) 
	WHERE	matchid = @matchid
			AND bettype =8
			AND( custid IN (50057, 879241, 103873, 78761, 1077687) 
					OR recommend = 1688156	)
			AND statusID NOT IN (101, 102)
	
	EXEC dbo.Admin_Calculate_8 @matchid = @matchid, @bettype = 8, @totalht = @totalht, @betcount = @betcount_8, @IsSettleAbandonedMatch = 1

END 
/* --- END Settle Abandoned Match ---*/

DECLARE @RowCount INT
IF @@SERVERNAME IN ('DBTRANS','DB206')
BEGIN
	EXEC DB02.bodb02.dbo.Admin_Match_Update @Command	= 'Admin_Settlement_RefundHT', 
											@Matchid	= @matchid,
											@RowCount	= @Rowcount OUTPUT,
											@creator	= @adminid 

	IF @Rowcount > 0
	BEGIN
		EXEC DB02.bodb02.dbo.updateMatch_remark @matchid, 'F'

		--EXEC dbo.Admin_Calculate_RefundHT 
		--		@matchid = @matchid,
		--		@IsExcludeBetdaq = @IsExcludeBetdaq		
	END
END

EXEC dbo.Admin_Calculate_RefundHT 
		@matchid		= @matchid,
		@IsExcludeBetdaq= @IsExcludeBetdaq	

IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
BEGIN
	INSERT INTO #BalanceAfter
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid AND bettype IN (7,8,12,15,21,30,125)
	GROUP BY custid


	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	INSERT INTO #Balance
	SELECT b.custid, a.balance - b.balance, CASE WHEN a.balance > b.balance THEN 1 ELSE 0 END
	FROM #BalanceBefore b
		INNER JOIN #BalanceAfter a ON b.custid = a.custid
	WHERE b.balance <> a.balance

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
-------------------------------------------------------------
---                      WRITE LOG                        ---
---------------------------VVVV------------------------------
IF @@SERVERNAME IN ('DBTRANS','DB206')
BEGIN
	IF @IsSettleAbandonedMatch = 1 OR @Rowcount > 0
	BEGIN 
		Declare @LogData nvarchar(300)
		SELECT @LogData = 'Calculate (Refund HT) for matchid:' + CAST(@matchid as nvarchar(10))
		EXEC dbo.WriteLog_UserLog @UserID = @AdminID, @Doing = @LogData		
		
		--Write Log Settle
		DECLARE 
				@finalhomescore INT, @finalawayscore INT,
				@betstatus nvarchar(50), @goalrecord varchar(50)

		SELECT 
				@finalhomescore = finalhomescore, 
				@finalawayscore = finalawayscore,
				@goalrecord = goalrecord,
				@betstatus = betstatus
		 FROM	DB02.BODB02.dbo.Match WITH(NOLOCK) WHERE matchid = @matchid

		DECLARE @Remark VARCHAR(500)
		SELECT	@Remark = 'ExcludeBetdaqTickets=' + convert(char(1),@IsExcludeBetdaq) 
						+ ' SettleDeterminedTickets=' + convert(char(1),@IsSettleAbandonedMatch)
						+ CASE WHEN @IsSettleAbandonedMatch =1 THEN @ScoreLog ELSE '' END 
						+ ' Duration=' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms;'

		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
			@UserID = @adminid,
			@Matchid = @matchid,
			@ActionID = 110,
			@finalhomescore = @finalhomescore,
			@finalawayscore = @finalawayscore,  
			@hthomescore = 0,
			@htawayscore = 0,
			@GoalRecord = @goalrecord,
			@betstatus = @betstatus,
			@Remark = @Remark,
			@IP = @IP

	END
END

-----
IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid


GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_RefundHT] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Settlement_RefundHT] TO [vnteam]