/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_RefundFT_Push]    Script Date: 08/15/2014 13:56:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.NAP_Admin_Settlement_RefundFT_Push    Script Date: 31/07/2014 12:58:50 PM ******/
/****** Object:  Stored Procedure dbo.NAP_Admin_Settlement_RefundFT_Push    Script Date: 7/30/2014 5:52:29 PM ******/
/****** Object:  Stored Procedure dbo.NAP_Admin_Settlement_RefundFT_Push    Script Date: 3/20/2014 4:22:32 PM ******/
ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_RefundFT_Push]
	@MatchId int,
	@AdminId int,
	@IsExcludeBetdaq bit = 0,
	@IsSettleAbandonedMatch bit = 0,
	@IsExcludeBetfair bit = 0,
	@IsSettleAbandonedMatchBetFair bit = 0,
	@IsSettleAbandonedMatchIBC bit = 0,
	@FullTimeHome int = NULL,
	@FullTimeAway int = NULL,
	@BetStatus nvarchar(50) = NULL,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
as

/*
	Created: 20140213@Kathy
	Task : Refund Full-time tickets
	DB: DBTXN/BODB02
	Original: 
	
	Revisions:
		- 20140304@Kathy: Execute settlement for abandoned/postponed matches- Clean Sheet, Both/One/Neither team to score, To Win To Nil 
		- 20140506@Kathy: Don't allow to calculate exists matches in queue

	Param's Explanation:
	• @matchid: matchid of match to Refund HT
	• @IsSettleAbandonedMatch: Is Settlement for Abandoned/postponed match or not
	• @IsSettleAbandonedMatchBetFair: Is Settlement for Betfair ticket of Abandoned/postponed match or not

*/
BEGIN
	SET NOCOUNT ON 
	DECLARE  @matchcode nvarchar(50)
			,@sporttype int
			,@leagueid int
			,@sqlCommand NVARCHAR(500)
			,@procName nvarchar(50)	

	SELECT   @matchcode = m.matchcode
			,@sporttype = m.sporttype
			,@leagueid = m.leagueid
	FROM match m with(NOLOCK)
	WHERE m.matchid = @MatchId

	IF @@ROWCOUNT = 0 
	BEGIN
		SELECT	 @ErrCode	= 1000001
				,@ErrMsg	= 'Match does not exist!'	
		RETURN
	END 
	
	IF EXISTS (SELECT 1 from Single_Calculate_Queue with(NOLOCK) WHERE matchid = @matchid AND IsCalculating IN (0,1) )
		OR EXISTS (SELECT 1 from Parlay_Calculate_Queue with(NOLOCK) WHERE matchid = @matchid AND IsCalculating IN (0,1))
	BEGIN 
		SELECT	 @ErrCode	= 1000003
				,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'	
		RETURN
	END 

	SELECT   @ErrCode = 0
			,@ErrMsg = ''
			,@procName = OBJECT_NAME(@@procid)
			,@sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_RefundFT] @matchid = ' + CONVERT(NVARCHAR(50),@MatchId) +
								 ', @adminid = ' + CONVERT(NVARCHAR(50),@AdminId) + 
								 ', @IsExcludeBetdaq = ' + CONVERT(NVARCHAR(1),@IsExcludeBetdaq) + 
								 ', @IsSettleAbandonedMatch = ' + CONVERT(NVARCHAR(1),@IsSettleAbandonedMatch) +
								 ', @IsExcludeBetfair = ' + CONVERT(NVARCHAR(1),@IsExcludeBetfair) + 
								 ', @IsSettleAbandonedMatchBetFair = ' + CONVERT(NVARCHAR(1),@IsSettleAbandonedMatchBetFair) + 
								 ', @IsSettleAbandonedMatchIBC = ' + CONVERT(NVARCHAR(1),@IsSettleAbandonedMatchIBC) + 
								 ', @fth = ' + ISNULL(CONVERT(NVARCHAR(50),@FullTimeHome),'NULL') +
								 ', @fta = ' + ISNULL(CONVERT(NVARCHAR(50),@FullTimeAway),'NULL') +
								 ', @betstatus = ' + CASE when @BetStatus IS NULL THEN 'NULL' ELSE 'N''' + CONVERT(nvarchar(20),@BetStatus)+ '''' END +
								 ', @IP = ''' + CONVERT(NVARCHAR(50),@IP) + '''' +
								 ', @ErrCode = @ErrCode OUTPUT' +
								 ', @ErrMsg = @ErrMsg OUTPUT' 

	IF @procName LIKE '%_xtest' or @procName LIKE '%_xpre'
	BEGIN
		DECLARE  @fth SMALLINT
				,@fta SMALLINT
				,@hth SMALLINT
				,@hta SMALLINT
				,@GoalRecord VARCHAR(50)
		BEGIN TRY
			EXEC sys.sp_executesql @sqlCommand
				,N'@ErrMsg VARCHAR(400) OUTPUT, @ErrCode int OUTPUT'
				,@ErrMsg = @ErrMsg OUTPUT
				,@ErrCode = @ErrCode OUTPUT
		END TRY

		BEGIN CATCH
			SELECT  @ErrMsg = @ErrMsg + ERROR_MESSAGE()
				   ,@ErrCode = @@error
			RETURN
		END CATCH

		SELECT	 @fth = m.finalhomescore
				,@fta = m.finalawayscore
				,@hth = m.hthomescore
				,@hta = m.htawayscore
				,@GoalRecord = m.GoalRecord
				,@BetStatus = m.betstatus
				,@sporttype = sporttype
		FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
		WHERE m.matchid = @MatchId

		IF @sporttype = 1
		BEGIN
			SELECT @GoalRecord = CASE when CHARINDEX(';',@GoalRecord) > 0 THEN REPLACE(@GoalRecord,';','')
									  ELSE @GoalRecord
								 END ,
					@BetStatus = CASE when CHARINDEX('1FL:',@BetStatus) > 0 THEN REPLACE(@BetStatus,SUBSTRING(@BetStatus,CHARINDEX('1FL:',@BetStatus),8),'')
									  ELSE @BetStatus
								 END 
		END

		EXEC Acc_Set_ConfirmedAction @matchid = @MatchId
				,@action = 12
				,@fth = @fth
				,@fta = @fta
				,@hth = @hth
				,@hta = @hta
				,@goalrecord = @GoalRecord
				,@betstatus = @BetStatus
	END 
	ELSE
	BEGIN
		INSERT INTO Single_Calculate_Queue(matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
		SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, 'Refund-FT', @sqlCommand
	END

END

GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_RefundFT_Push] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_RefundFT_Push] TO [vnteam] AS [dbo]