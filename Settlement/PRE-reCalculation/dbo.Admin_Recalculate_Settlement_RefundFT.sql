



ALTER PROCEDURE [dbo].[Admin_Recalculate_Settlement_RefundFT]
	@matchid int,
	@adminid int,
	@IsExcludeBetdaq bit = 0,
	@IP varchar(15) = ''
AS

/*
	Created: 20111116@Lukas
	Task : Refund Full-time tickets
	DB: DB052.BODB_REVIEW
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
	Param's Explanation:
	• @matchid: matchid of match to Refund HT

	30 OCT 2008 : Joe 
	Check if match MUST already settled 1st Half
*/
BEGIN

	SET NOCOUNT ON 

	Declare @status TABLE (FTBet bit, BetCount int, InRunning int)
	INSERT INTO @status
	SELECT
		CASE WHEN bettype IN (7,8,12,15,21,30) THEN 0 ELSE 1 END,
		SUM(CASE WHEN statusID IN (101,102) THEN 0 ELSE 1 END),
		SUM(CASE WHEN statusID = 0 THEN 1 ELSE 0 END)
		
	FROM dbo.bettrans with (nolock)
	WHERE matchid = @matchid
	GROUP BY CASE WHEN bettype IN (7,8,12,15,21,30) THEN 0 ELSE 1 END

	IF NOT EXISTS(SELECT * FROM @status WHERE FTBet = 0) INSERT INTO @status VALUES (0,0,0)
	IF NOT EXISTS(SELECT * FROM @status WHERE FTBet = 1) INSERT INTO @status VALUES (1,0,0)

	Declare @HTDone bit, @FTDone bit
	SELECT @HTDone = CASE InRunning WHEN 0 THEN 1 ELSE 0 END FROM @status WHERE FTBet = 0
	SELECT @FTDone = CASE InRunning WHEN 0 THEN 1 ELSE 0 END FROM @status WHERE FTBet = 1

	---===============================================
	--Check if match already Refund HT => refund whole match
	if exists(select 1 from DB02.BODB02.dbo.Match with (nolock) where matchid = @matchid AND betstatus like '%Refund HT%')
		AND @HTDone = 1
	BEGIN
			EXEC dbo.Admin_Recalculate_Settlement_Refund_All @matchid=@matchid , @IsExcludeBetdaq = @IsExcludeBetdaq, @creator=@adminid,@IP=@IP
		return
	END

	DECLARE @RowCount INT

--	EXEC DB02.bodb02.dbo.Admin_Match_Update @Command	= 'Admin_Settlement_RefundFT', 
--											@MatchID	= @matchid, 
--											@HTDone		= @HTDone,
--											@RowCount	= @RowCount OUTPUT,
--											@creator	= @adminid 


	IF EXISTS (SELECT 1 FROM bodb02.dbo.match WITH(NOLOCK) WHERE matchid = @MatchID AND @HTDone = 1)
	BEGIN
--		EXEC DB02.bodb02.dbo.updateMatch_remark @matchid, 'F'

		EXEC dbo.Admin_Recalculate_RefundFT @matchid = @matchid, @IsExcludeBetdaq = @IsExcludeBetdaq
		
--		Declare @LogData nvarchar(300)
--		SELECT @LogData = 'Calculate (Refund FT) for matchid:' + CAST(@matchid as nvarchar(10))
--		+ CASE WHEN @IsExcludeBetdaq = 1 THEN  ', Exclude Betdaq tickets' ELSE '' END
--		EXEC dbo.WriteLog_UserLog @AdminID, @LogData
--
--		--Write Log Settle
--		DECLARE 
--			@hthomescore INT, @htawayscore INT,
--			@betstatus nvarchar(50), @goalrecord varchar(50), @Remark varchar(50)
--			
--		SELECT @Remark = 'ExcludeBetdaqTickets=' + convert(char(1),@IsExcludeBetdaq)
--
--		SELECT 
--				@hthomescore = hthomescore, 
--				@htawayscore = htawayscore,
--				@goalrecord = goalrecord,
--				@betstatus = betstatus
--		 FROM	DB02.BODB02.dbo.match WITH(NOLOCK) WHERE matchid = @matchid


--		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
--			@UserID = @adminid,
--			@Matchid = @matchid,
--			@ActionID = 111,
--			@finalhomescore = 0,
--			@finalawayscore = 0,  
--			@hthomescore = @hthomescore,
--			@htawayscore = @htawayscore,
--			@GoalRecord = @goalrecord,
--			@betstatus = @betstatus,
--			@Remark = @Remark,
--			@IP = @IP
	END

END



