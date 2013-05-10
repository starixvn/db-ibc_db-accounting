


ALTER PROCEDURE [dbo].[Admin_Recalculate_Settlement_1]
	@creator	INT = 0,
	@matchid	INT,
	@fth		SMALLINT = NULL,
	@fta		SMALLINT = NULL,
	@hth		SMALLINT,
	@hta		SMALLINT,
	@goalrecord VARCHAR(50)= NULL,
	@betstatus	NVARCHAR(50),
	@action		VARCHAR(10) = 'CAL',
	@IP			VARCHAR(15) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = '' OUTPUT,
	@DelayTime	INT = 0 OUTPUT
AS


/*	Creator: 20111113@Lukas
	Task: main SP for settlement
	DB: DB052.BODB_REVIEW
	
	History:
		- 20090626@Daniel: Include FGLG when calc FT /calc All
		- 20091125@Daniel: Add writelog for GoalRecord
		- 20091212@Daniel: Fix writelog NULL when calc-HT
		- 20091225@Daniel: Add writelog to table Userlog_settle
		- 20100305@Daniel: Add back writelog to table Userlog
		- 20100531@Henry: Change to use statusID instead of status
		- 20100720@Henry: Change SP Logfile to WriteLog_UserLog
		- 20100724@Jamie: If Refund HT then the betstatus not changed when CAL-FT 
		- 20100825@Lukas: Update last time modify (changetime column) for match table
		- 20100827@Jamie: 1st Money Line
		- 20100916@Jamie: Update settleTime for FT Settlement 
		- 20101019@Thien:	Put delay on settlement of big matches on weekend
							Record the @TicketCount in the log
							Add @ErrCode, @ErrMsg param
		- 20110517@Lukas: re-arrange bettype	
		- 20110606@Lukas: replace update match statement by store procedure
		- 20110620@Jamie: Refer to Match in DB02 instead of DBTRANS			
		- 20110620@Thien: replace "RESET 'SaveBet' of DB06" by calling SP, instead of direct update					
		- 20110912@Tom: Add new bettypes 30
				apply new bet type 1st correct score on Sport Books			
			
	Param's Explanation:
		+ @betstatus: Used for score table, FGLG status, refund status
		
*/
BEGIN

	SET NOCOUNT ON

	--Declare @start datetime, @stop datetime, @goalrecord_old varchar(50)
	--
	--Declare @LogData nvarchar(200)
	--Declare @eventstatus nvarchar(50)
	--SELECT @goalrecord_old = ISNULL(goalrecord,'') FROM dbo.match WITH(NOLOCK) WHERE matchid = @matchid


	-- 20090412 : Joe : case for unsettle the game.
	IF @action = 'UNDO'
	BEGIN

		EXEC dbo.Admin_Recalculate_Undo @matchid
		EXEC dbo.Admin_Recalculate_Settlement_Parlay 
					@matchid		= @matchid, 
					@finalhomescore = @fth,
					@finalawayscore = @fta,
					@hthomescore	= @hth,
					@htawayscore	= @hta,
					--@goalrecord		= @goalrecord,
					@betstatus		= @betstatus,				
					@action			= 'UNDO'
					

		--EXEC DB02.bodb02.dbo.UpdateMAtch_Remark @matchid, 'U'
		
		--EXEC DB02.bodb02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_1-UNDO', @MatchID = @matchid, @creator = @creator 
		--EXEC DB06.bodb02.dbo.Admin_Match_UpdateSaveBet @action = 'UNDO', @matchid = @matchid

	END
	ELSE
	BEGIN
		IF LEFT(@action, 3) = 'CAL' EXEC dbo.Admin_Recalculate_Settlement_3 
												@creator	= @creator, 
												@matchid	= @matchid, 
												@mode		= @action,
												@fth		= @fth,
												@fta		= @fta,		
												@hth		= @hth,		
												@hta		= @hta,		
												@goalrecord = @goalrecord,
												@betstatus	= @betstatus
		
		--Check and calc FGLG
		IF @action IN('CAL', 'CAL-FT') 	
		BEGIN
			IF EXISTS (SELECT 1 FROM bettrans WITH(NOLOCK) WHERE bettype = 14 AND matchid = @matchid)
				OR EXISTS (SELECT 1 FROM bettransm WITH(NOLOCK) WHERE bettype = 14 AND matchid = @matchid)	
							EXEC dbo.Admin_Recalculate_Settlement_FGLG
											@creator	= @creator,
											@matchid	= @matchid,	
											@betstatus	= @betstatus,
											@IncludeLG	= 1,
											@goalrecord = @goalrecord,
											@IP			= @IP		
		

		END

	--	IF @eventstatus = 'completed'
	--		EXEC DB02.bodb02.dbo.updateMatch_remark @matchid, 'C'
	--	ELSE IF @action = 'CAL-HT'
	--		EXEC DB02.bodb02.dbo.updateMatch_remark @matchid, 'H'

	END -- IF @action = 'UNDO'

END






