/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_1_Push]    Script Date: 08/15/2014 13:55:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.NAP_Admin_Settlement_1_Push    Script Date: 7/30/2014 5:52:28 PM ******/
/****** Object:  Stored Procedure dbo.NAP_Admin_Settlement_1_Push    Script Date: 3/17/2014 4:21:08 PM ******/
ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_1_Push]
	@AdminId int,
	@Matchid int,
	@FullTimeHome smallint = NULL,
	@FullTimeAway smallint = NULL,
	@HalfTimeHome smallint,
	@HalfTimeAway smallint,
	@GoalRecord varchar(50)= NULL,
	@BetStatus nvarchar(50),
	@Action varchar(10) = 'CAL',
	@IP varchar(15) = '',

	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*	Creator: Kathy
	Date: 20140213
	Task: SP for settlement
	DB: DBTXN/BODB02

	Revisions:		
		- 20140506@Kathy: Don't allow to calculate exists matches in queue
		
	Param's Explanation:

		
*/
BEGIN
	SET NOCOUNT ON
	DECLARE  @matchcode nvarchar(50)
			,@sporttype int
			,@leagueid int
			,@sqlCommand NVARCHAR(500)
			,@NextAllowSettleTime datetime
			,@procName nvarchar(50)
	
	SELECT   @matchcode = m.matchcode
			,@sporttype = m.sporttype
			,@leagueid = m.leagueid
	FROM match m with(NOLOCK)
	where m.matchid = @MatchId

	IF @@ROWCOUNT = 0 
	BEGIN
		SELECT	 @ErrCode	= 1000001
				,@ErrMsg	= 'Match does not exist!'	
		RETURN
	END 

	IF @action = 'CAL' AND @sporttype = 154 AND (@FullTimeHome = 0 OR @FullTimeHome IS NULL OR @FullTimeAway = 0 OR @FullTimeAway IS NULL)
	BEGIN
		SELECT	 @ErrCode	= 1000002
				,@ErrMsg	= 'Score is not valid.'	
		RETURN
	END

	IF EXISTS (SELECT 1 from Single_Calculate_Queue with(NOLOCK) WHERE matchid = @matchid AND IsCalculating IN (0,1) )
		OR EXISTS (SELECT 1 from Parlay_Calculate_Queue with(NOLOCK) WHERE matchid = @matchid AND IsCalculating IN (0,1))
	BEGIN 
		SELECT	 @ErrCode	= 1000000
				,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'	
		RETURN
	END 

	SELECT   @ErrCode = 0
			,@ErrMsg = ''
			,@procName = OBJECT_NAME(@@procid)
			,@sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_1] @matchid = ' + CONVERT(NVARCHAR(50),@MatchId) +
								 ', @creator = ' + CONVERT(NVARCHAR(50),@AdminId) + 
								 ', @fth = ' + ISNULL(CONVERT(NVARCHAR(50),@FullTimeHome),'NULL') +
								 ', @fta = ' + ISNULL(CONVERT(NVARCHAR(50),@FullTimeAway),'NULL') +
								 ', @hth = ' + ISNULL(CONVERT(NVARCHAR(50),@HalfTimeHome),'NULL') +
								 ', @hta = ' + ISNULL(CONVERT(NVARCHAR(50),@HalfTimeAway),'NULL') +
								 ', @goalrecord = '+ CASE when @GoalRecord IS NULL THEN 'NULL' ELSE '''' + CONVERT(nvarchar(50),@GoalRecord)+ '''' END +
								 ', @betstatus = ' + CASE when @BetStatus IS NULL THEN 'NULL' ELSE 'N''' + CONVERT(nvarchar(50),@BetStatus)+ '''' END +
								 ', @action = ''' + CONVERT(NVARCHAR(50),@Action) + '''' +
								 ', @IP = ''' + CONVERT(NVARCHAR(50),@IP) + '''' +
								 ', @ErrCode = @ErrCode OUTPUT' +
								 ', @ErrMsg = @ErrMsg OUTPUT' 
	
	IF @procName LIKE '%_xtest' or @procName LIKE '%_xpre'
	BEGIN
		DECLARE @ActionId INT

		BEGIN TRY
			EXEC sys.sp_executesql @sqlCommand
				,N'@ErrMsg VARCHAR(400) OUTPUT, @ErrCode int OUTPUT'
				,@ErrMsg = @ErrMsg OUTPUT
				,@ErrCode = @ErrCode OUTPUT
		END TRY

		BEGIN CATCH
			SELECT  @ErrMsg = @ErrMsg + ISNULL(ERROR_MESSAGE(),'')
				   ,@ErrCode = @@error
			RETURN
		END CATCH

		SELECT  @ActionId = CASE 
				WHEN @Action = 'CAL-HT' THEN 2
				WHEN @Action = 'CAL-FT' THEN 3
				WHEN @Action = 'CAL' THEN 4
				WHEN @Action = 'UNDO' THEN 0
				ELSE - 1
				END
			,@FullTimeHome = m.finalhomescore
			,@FullTimeAway = m.finalawayscore
			,@HalfTimeHome = m.hthomescore
			,@HalfTimeAway = m.htawayscore
			,@GoalRecord = m.GoalRecord
			,@BetStatus = m.betstatus
			,@sporttype = sporttype
		FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
		WHERE m.matchid = @MatchId

		IF @ActionId <> -1
		BEGIN
			SELECT @GoalRecord = CASE when CHARINDEX(';',@GoalRecord) > 0 THEN REPLACE(@GoalRecord,';','')
										ELSE @GoalRecord
									END ,
					@BetStatus = CASE when CHARINDEX('1FL:',@BetStatus) > 0 THEN REPLACE(@BetStatus,SUBSTRING(@BetStatus,CHARINDEX('1FL:',@BetStatus),8),'') -- 1FL:1:1;
										ELSE @BetStatus
									END 

			EXEC Acc_Set_ConfirmedAction @matchid = @MatchId
					,@action = @ActionId
					,@fth = @FullTimeHome
					,@fta = @FullTimeAway
					,@hth = @HalfTimeHome
					,@hta = @HalfTimeAway
					,@goalrecord = @GoalRecord
					,@betstatus = @BetStatus
		END
	END 
	ELSE
	BEGIN
		INSERT INTO Single_Calculate_Queue(matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
		SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, @Action, @sqlCommand
	END 	
END

GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_1_Push] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_1_Push] TO [vnteam] AS [dbo]