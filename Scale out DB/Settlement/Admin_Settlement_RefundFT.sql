

ALTER PROCEDURE [dbo].[Admin_Settlement_RefundFT_xtest]
	@matchid int,
	@adminid int,
	@IsExcludeBetdaq bit = 0,
	@IsSettleAbandonedMatch bit = 0,
	@fth int = NULL,
	@fta int = NULL,
	@betstatus nvarchar(50) = NULL,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
as

/*
	Created: 
	Task : Refund Full-time tickets
	DB: DBTRANS.bodb02
	Original: 
		
	Revisions:
		- 20090729@Daniel: Add check match already refund HT -> Call refund all
		- 20091012@Kiwi: Remove custBetCredit
		- 20091031@Jamie: Change the name of SP - "Refund" into "Admin_Settlement_Refund_All"
		- 20091225@Daniel: Add writelog to table Userlog_settle
		- 20100224@Khoa: Add more condition exclude betdaq when refund fulltime
		- 20100305@Daniel: Add back writelog to table Userlog
		-- 20100424@Henry: Update column StatusID of Bettrans
		-- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100610@Jamie: Call nested SP "Admin_Calculate_RefundFT"
		- 20100720@Henry: Change SP Logfile to WriteLog_UserLog
		- 20100825@Lukas: Update last time modify (changetime column) for match table
		- 20100827@Jamie: 1st Money Line 
		- 20100916@Jamie: Update settleTime for FT Settlement
		- 20110606@Lukas: replace update match statement by store procedure	
		- 20110620@Jamie: Refer to Match in DB02 instead of DBTRANS	
		- 20110912@Tom: Add new bettypes 30
					apply new bet type 1st correct score on Sport Books	
		- 20111202@Sophia: Add new bettype 124, 125 for 1x2 HDP	
		- 20120215@Jamie: Settle Abandoned Match
		- 20120314@Jamie: Allow entering Scores for Settlement O/U BETDAQ 
		- 20120808@Sophia: Add table TempVariableNumber to check if this match is being calculated then not allow to settle until the on-going process is completed
		- 20120930@Lukas: Put servername to control SP execution
		
	Param's Explanation:
	• @matchid: matchid of match to Refund HT
	• @IsSettleAbandonedMatch: Is Settlement for Abandoned/postponed match or not

	30 OCT 2008 : Joe 
	Check if match MUST already settled 1st Half
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
	SELECT	custid, SUM(winlost-actual_stake+playercomm)
	FROM	dbo.bettrans with (rowlock)
	WHERE	matchid = @matchid 
			AND bettype <> 14
	GROUP BY custid
END

Declare @status TABLE (FTBet bit, BetCount int, InRunning int)
INSERT INTO @status
SELECT
	CASE WHEN bettype IN (7,8,12,15,21,30,125) THEN 0 ELSE 1 END,
	SUM(CASE WHEN statusID IN (101,102) THEN 0 ELSE 1 END),
	SUM(CASE WHEN statusID = 0 THEN 1 ELSE 0 END)
	
FROM dbo.bettrans with (nolock)
WHERE matchid = @matchid
GROUP BY CASE WHEN bettype IN (7,8,12,15,21,30,125) THEN 0 ELSE 1 END

IF NOT EXISTS(SELECT * FROM @status WHERE FTBet = 0) INSERT INTO @status VALUES (0,0,0)
IF NOT EXISTS(SELECT * FROM @status WHERE FTBet = 1) INSERT INTO @status VALUES (1,0,0)

Declare @HTDone bit, @FTDone bit
SELECT @HTDone = CASE InRunning WHEN 0 THEN 1 ELSE 0 END FROM @status WHERE FTBet = 0
SELECT @FTDone = CASE InRunning WHEN 0 THEN 1 ELSE 0 END FROM @status WHERE FTBet = 1

IF @IsSettleAbandonedMatch = 1 SELECT @IsExcludeBetdaq = 1 

---===============================================
--Check if match already Refund HT => refund whole match
if exists(select 1 from DB02.BODB02.dbo.Match with (nolock) where matchid = @matchid AND betstatus like '%Refund HT%')
	AND @HTDone = 1
BEGIN
	-----
	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')	
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid
	
	EXEC dbo.Admin_Settlement_Refund_All 
		@matchid=@matchid , 
		@IsExcludeBetdaq = @IsExcludeBetdaq, 
		@creator=@adminid,
		@IsSettleAbandonedMatch = @IsSettleAbandonedMatch,
		@hth = NULL,
		@hta = NULL,
		@fth = @fth,
		@fta = @fta, 
		@betstatus = @betstatus,
		@Action='CAL-FT',
		@IP=@IP,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
	RETURN
END

/*
	Settle Abandoned Match for Over/Under 
*/

IF @IsSettleAbandonedMatch = 1 AND @HTDone = 1 
BEGIN 
	DECLARE	@sporttype tinyint

	DECLARE	@ScoreLog VARCHAR(100)

	SELECT	@sporttype = SportType
	FROM	DB02.BODB02.dbo.Match with (nolock) 
	WHERE	matchid = @matchid
	
	SELECT	@ScoreLog = ' FTHScore=' + CAST(@fth AS VARCHAR(10))
						+ ' FTAScore=' + CAST(@fta AS VARCHAR(10))
						+ ' BetStatus=' + @betstatus 

	DECLARE @TennisTotal smallint, @T_Home smallint, @T_Away smallint
	IF @SportType IN (5, 6, 9, 30) -- Tennis/VolleyBall/Badminton/Squash : get TotalGamesPlayed
		EXEC dbo.Admin_Settlement_2
			@betstatus = @betstatus,
			@Total =  @TennisTotal OUTPUT,
			@TotalHome = @T_Home OUTPUT,
			@TotalAway = @T_Away OUTPUT

	DECLARE @totalgoal smallmoney

	SELECT	@totalgoal	= CASE WHEN @sporttype IN (5, 6, 9, 30) and @TennisTotal > 0 THEN @TennisTotal ELSE (@fth + @fta) END			
	
	
	IF	@totalgoal IS NULL 
	BEGIN 
		SELECT	@ErrCode = 105
				,@ErrMsg = 'Cannot settle determined ticket(s) without FT Score!'
				
		-----
		IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
			DELETE FROM dbo.TempVariableNumber WITH(ROWLOCK,UPDLOCK)
			WHERE KeyID = 1 AND KeyValue = @matchid
		
		RETURN
	END

	DECLARE @betcount_3 int
	SELECT	@betcount_3 = ISNULL(SUM(case bettype when 3 then 1 else 0 end), 0)
	FROM	bettrans WITH(NOLOCK) 
	WHERE	matchid = @matchid
			AND bettype =3
			AND( custid IN (50057, 879241, 103873, 78761, 1077687) 
					OR recommend = 1688156	)
			AND statusID NOT IN (101, 102)
	
	EXEC dbo.Admin_Calculate_3 @matchid = @matchid, @bettype = 3, @totalgoal = @totalgoal, @betcount = @betcount_3, @IsSettleAbandonedMatch = 1

END 
/* --- END Settle Abandoned Match ---*/


DECLARE @RowCount INT
IF @@SERVERNAME IN ('DBTRANS','DB206')
BEGIN
	EXEC DB02.bodb02.dbo.Admin_Match_Update @Command	= 'Admin_Settlement_RefundFT', 
											@MatchID	= @matchid, 
											@HTDone		= @HTDone,
											@RowCount	= @RowCount OUTPUT,
											@creator	= @adminid 

	IF @RowCount > 0
	BEGIN
		EXEC DB02.bodb02.dbo.updateMatch_remark @matchid, 'F'		
			--EXEC dbo.Admin_Calculate_RefundFT @matchid = @matchid, @IsExcludeBetdaq = @IsExcludeBetdaq
			---- original location
	END
END

EXEC dbo.Admin_Calculate_RefundFT @matchid = @matchid, @IsExcludeBetdaq = @IsExcludeBetdaq

IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
BEGIN
	INSERT INTO #BalanceAfter	
	SELECT	custid, SUM(winlost-actual_stake+playercomm)
	FROM	dbo.bettrans with (rowlock)
	WHERE	matchid = @matchid 
			AND bettype <> 14
	GROUP BY custid


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

SELECT	@stop = CURRENT_TIMESTAMP

IF @@SERVERNAME IN ('DBTRANS','DB206')
BEGIN
	IF @RowCount > 0 OR (@IsSettleAbandonedMatch = 1 AND @HTDone = 1 )
	BEGIN
		Declare @LogData nvarchar(300)
		SELECT @LogData = 'Calculate (Refund FT) for matchid:' + CAST(@matchid as nvarchar(10))
		+ CASE WHEN @IsExcludeBetdaq = 1 THEN  ', Exclude Betdaq tickets' ELSE '' END
		EXEC dbo.WriteLog_UserLog @AdminID, @LogData

		--Write Log Settle
		DECLARE 
			@hthomescore INT, @htawayscore INT,
			@goalrecord varchar(50), @Remark varchar(500)
			
		SELECT @Remark = 'ExcludeBetdaqTickets=' + convert(char(1),@IsExcludeBetdaq)
							+ ' SettleDeterminedTickets=' + convert(char(1),@IsSettleAbandonedMatch)
							+ CASE WHEN @IsSettleAbandonedMatch = 1 AND @HTDone = 1 THEN @ScoreLog ELSE '' END 
							+ ' Duration=' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms;'

		SELECT 
				@hthomescore = hthomescore, 
				@htawayscore = htawayscore,
				@goalrecord = goalrecord,
				@betstatus = betstatus
		 FROM	DB02.BODB02.dbo.match WITH(NOLOCK) WHERE matchid = @matchid


		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
			@UserID = @adminid,
			@Matchid = @matchid,
			@ActionID = 111,
			@finalhomescore = 0,
			@finalawayscore = 0,  
			@hthomescore = @hthomescore,
			@htawayscore = @htawayscore,
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
GRANT EXECUTE ON [dbo].[Admin_Settlement_RefundFT] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Settlement_RefundFT] TO [vnteam]