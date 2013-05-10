


ALTER PROCEDURE [dbo].[Admin_Recalculate_Settlement_Refund_All]
	@matchid int,
	@creator int, 	
	@IsExcludeBetdaq bit = 0,
	@IP varchar(15) = ''
AS

/*
	Created: 20111116@Lukas
	Task : refund tickets 
	Original: Admin_Settlement_Refund_All
	DB: DB052.BODB_REVIEW

	Revisions: 
		- 20090915@KhoaTran: Exclude betdaq tickets or not
		- 20091025@PhucPham: agent MTEST0101: 1688156 (requested by Erica)
		- 20091031@Jamie: Change the name of SP - "Refund" into "Admin_Settlement_Refund_All"
		- 20091225@Daniel: Add writelog to table Userlog_settle
		- 20100305@Daniel: Add back writelog to table Userlog
		-- 20100424@Henry: Update column StatusID of Bettrans 
		-- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100610@Jamie: Call nested SP "Admin_Calculate_Refund" 
		- 20100720@Henry: Stop using SP Logfile to write log
		- 20100825@Lukas: Update last time modify (changetime column) for match table
		- 20100916@Jamie: Update settleTime for FT Settlement 
		- 20110606@Lukas: replace update match statement by store procedure	

	Param's Explanation:
	• @matchid: matchid need to refund
	• @IsExcludeBetdaq: Is Exclude betdaq tickets or not
	BetDaq account: 
				BQUS888:50057
				BQUSMLB:879241
				BQUSNBA:103873 
*/
BEGIN

	SET NOCOUNT ON


	--EXEC DB02.bodb02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_Refund_All', @MatchID = @matchid, @creator = @creator 

	EXEC dbo.Admin_Recalculate_RefundAll @matchid = @matchid, @IsExcludeBetdaq = @IsExcludeBetdaq
	--
	--Declare @LogData nvarchar(200)
	--SELECT @LogData = 'Calculate (Refund All) for matchid:' + CAST(@matchid as nvarchar(10))
	--+ CASE WHEN @IsExcludeBetdaq = 1 THEN  ', Exclude Betdaq tickets' ELSE '' END
	--
	--EXEC dbo.WriteLog_UserLog @creator, @LogData
	--
	----Write Log Settle
	--DECLARE @Remark varchar(50)
	--SELECT @Remark = 'ExcludeBetdaqTickets=' + convert(char(1),@IsExcludeBetdaq)
	--EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
	--	@UserID = @creator,
	--	@Matchid = @matchid,
	--	@ActionID = 109,
	--	@finalhomescore = 0,
	--    @finalawayscore = 0,  
	--    @hthomescore = 0,
	--    @htawayscore = 0,
	--    @GoalRecord = '',
	--    @betstatus = 'Refund',
	--    @Remark = @Remark,
	--    @IP = @IP
	    
END

