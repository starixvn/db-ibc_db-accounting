ALTER PROCEDURE [NAP_Admin_Settlement_FGLG_Push]
	@AdminId int,
	@action VARCHAR(10) = 'CAL-FT', -- CAL-FT, CAL-HT
	@MatchId int,	
	@BetStatus nvarchar(50),
	@IncludeLastGoal bit = 0,
	@IP varchar(15) = '',
	@goalrecord varchar(50) = '',
	@IsLoopTempTable BIT = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
	
AS
/*	Creator: Kathy
	Date: 20140213
	Task: SP for settle FGLG
	DB: DBTXN/BODB02
	
	Revisions:
		- 20140506@Kathy: Don't allow to calculate exists matches in queue
		- 20140426@Kathy: Add 1H FGLG (127) [Redmine:#14449]
		
	Param's Explanation:
		+ @betstatus: FGLG status
		+ @IsLoopTempTable: 1 : is nested
							0 : Normal
		
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @matchcode nvarchar(50),@sporttype int, @leagueid int, @sqlCommand NVARCHAR(500), @mode varchar(20)

	SELECT @matchcode = m.matchcode, @sporttype = m.sporttype, @leagueid = m.leagueid
	FROM match m with(NOLOCK)
	where m.matchid = @MatchId

	IF @@ROWCOUNT = 0 
	BEGIN
		SELECT	 @ErrCode	= 1000001
				,@ErrMsg	= 'Match does not exist!'	
		RETURN
	END 

	IF EXISTS (SELECT 1 from Single_Calculate_Queue with(NOLOCK) WHERE matchid = @matchid AND IsCalculating IN (0,1) )
		OR EXISTS (SELECT 1 from Parlay_Calculate_Queue with(NOLOCK) WHERE matchid = @matchid AND IsCalculating IN (0,1))
	BEGIN 
		SELECT	 @ErrCode	= 1000000
				,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'	
		RETURN
	END 

	SELECT @ErrCode = 0, @ErrMsg = ''
			,@mode = CASE when @action = 'CAL-FT' THEN CASE WHEN @IncludeLastGoal = 0 then  'CAL-FTFGLG' 
														 ELSE 'CAL-FTLG' 
													END
					   ELSE CASE WHEN @IncludeLastGoal = 0 THEN 'CAL-HTFGLG'
								 ELSE 'CAL-HTLG'
							END
				 END 

	SELECT @sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_FGLG] @matchid = ' + CONVERT(NVARCHAR(50),@MatchId) +
								 ', @action = ' + CASE WHEN @action IS NULL THEN 'CAL-FT' ELSE '''' + CONVERT(NVARCHAR(50), @action) + '''' END +
								 ', @creator = ' + CONVERT(NVARCHAR(50),@AdminId) + 
								 ', @goalrecord = '+ CASE when @GoalRecord IS NULL THEN 'NULL' ELSE '''' + CONVERT(nvarchar(50),@GoalRecord)+ '''' END +
								 ', @betstatus = ' + CASE when @BetStatus IS NULL THEN 'NULL' ELSE 'N''' + CONVERT(nvarchar(50),@BetStatus)+ '''' END +
								 ', @IncludeLG = ' + CONVERT(NVARCHAR(1),@IncludeLastGoal) + 
								 ', @IsLoopTempTable = ' + CONVERT(NVARCHAR(1),@IsLoopTempTable) + 
								 ', @IP = ''' + CONVERT(NVARCHAR(50),@IP) + '''' +
								 ', @ErrCode = @ErrCode OUTPUT' +
								 ', @ErrMsg = @ErrMsg OUTPUT' 

	INSERT INTO Single_Calculate_Queue(matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
	SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, @mode, @sqlCommand
END

GO

GRANT EXECUTE ON [NAP_Admin_Settlement_FGLG_Push] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_FGLG_Push] TO [vnteam] AS [dbo]
GO


