ALTER PROCEDURE [NAP_Admin_Settlement_1_Push]
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
	DECLARE @matchcode nvarchar(50),@sporttype int, @leagueid int, @sqlCommand NVARCHAR(500), @NextAllowSettleTime datetime	

	SELECT @ErrCode = 0, @ErrMsg = ''
	
	SELECT @matchcode = m.matchcode, @sporttype = m.sporttype, @leagueid = m.leagueid
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

	SELECT @sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_1] @matchid = ' + CONVERT(NVARCHAR(50),@MatchId) +
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
	
	INSERT INTO Single_Calculate_Queue(matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
	SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, @Action, @sqlCommand
END

GO

GRANT EXECUTE ON [NAP_Admin_Settlement_1_Push] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_1_Push] TO [vnteam] AS [dbo]
GO


