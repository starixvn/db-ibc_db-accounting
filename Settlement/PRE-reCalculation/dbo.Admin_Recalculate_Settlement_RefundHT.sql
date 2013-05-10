



ALTER PROCEDURE [dbo].[Admin_Recalculate_Settlement_RefundHT]
	@matchid int,
	@adminid int,
	@IP varchar(15) = ''
AS

/*
	Created: 20111116@Lukas
	Task : Refund Half-time in case there are HT tickets bet on special matches that have 3 sets
	DB: DB052.BODB_REVIEW
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
	Param's Explanation:
	• @matchid: matchid of match to Refund HT

*/
BEGIN

	SET NOCOUNT ON 
	--Check if match already Refund FT => refund whole match
	if exists(select 1 from DB02.BODB02.dbo.Match with (nolock) where matchid = @matchid AND betstatus like '%Refund FT%')
	BEGIN
			EXEC dbo.Admin_Recalculate_Settlement_Refund_All @matchid, @adminid
		return
	END

	DECLARE @RowCount INT

--	EXEC DB02.bodb02.dbo.Admin_Match_Update @Command	= 'Admin_Settlement_RefundHT', 
--											@Matchid	= @matchid,
--											@RowCount	= @Rowcount OUTPUT,
--											@creator	= @adminid 

	IF EXISTS (SELECT 1 FROM bodb02.dbo.match WITH(NOLOCK) WHERE matchid = @matchid)
	BEGIN
--		EXEC DB02.bodb02.dbo.updateMatch_remark @matchid, 'F'

		EXEC dbo.Admin_Recalculate_RefundHT @matchid = @matchid

--		Declare @LogData nvarchar(300)
--		SELECT @LogData = 'Calculate (Refund HT) for matchid:' + CAST(@matchid as nvarchar(10))
--		EXEC dbo.WriteLog_UserLog @UserID = @AdminID, @Doing = @LogData		
		
		--Write Log Settle
--		DECLARE 
--				@finalhomescore INT, @finalawayscore INT,
--				@betstatus nvarchar(50), @goalrecord varchar(50)
--
--		SELECT 
--				@finalhomescore = finalhomescore, 
--				@finalawayscore = finalawayscore,
--				@goalrecord = goalrecord,
--				@betstatus = betstatus
--		 FROM	DB02.BODB02.dbo.Match WITH(NOLOCK) WHERE matchid = @matchid


--		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
--			@UserID = @adminid,
--			@Matchid = @matchid,
--			@ActionID = 110,
--			@finalhomescore = @finalhomescore,
--			@finalawayscore = @finalawayscore,  
--			@hthomescore = 0,
--			@htawayscore = 0,
--			@GoalRecord = @goalrecord,
--			@betstatus = @betstatus,
--			@IP = @IP
			
	END

END




