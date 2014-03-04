CREATE PROCEDURE [NAP_Admin_Settlement_FGLG_Push]
	@AdminId int,
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
		
		
	Param's Explanation:
		+ @betstatus: FGLG status
		+ @IsLoopTempTable: 1 : is nested
							0 : Normal
		
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @matchcode nvarchar(50),@sporttype int, @leagueid int, @sqlCommand NVARCHAR(500), @action varchar(20)

	SELECT @matchcode = m.matchcode, @sporttype = m.sporttype, @leagueid = m.leagueid
	FROM match m with(NOLOCK)
	where m.matchid = @MatchId

	SELECT @ErrCode = 0, @ErrMsg = '', @action = CASE WHEN @IncludeLastGoal = 0 THEN 'CAL-FGLG'
											else 'CAL-LG' END 

	SELECT @sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_FGLG] @matchid = ' + CONVERT(NVARCHAR(10),@MatchId) +
								 ', @creator = ' + CONVERT(NVARCHAR(10),@AdminId) + 
								 ', @goalrecord = '+ CASE when @GoalRecord IS NULL THEN 'NULL' ELSE '''' + CONVERT(nvarchar(20),@GoalRecord)+ '''' END +
								 ', @betstatus = ' + CASE when @BetStatus IS NULL THEN 'NULL' ELSE 'N''' + CONVERT(nvarchar(20),@BetStatus)+ '''' END +
								 ', @IncludeLG = ' + CONVERT(NVARCHAR(1),@IncludeLastGoal) + 
								 ', @IsLoopTempTable = ' + CONVERT(NVARCHAR(1),@IsLoopTempTable) + 
								 ', @IP = ''' + CONVERT(NVARCHAR(10),@IP) + '''' +
								 ', @ErrCode = @ErrCode OUTPUT' +
								 ', @ErrMsg = @ErrMsg OUTPUT' 

	INSERT INTO Single_Calculate_Queue(matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
	SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, @action, @sqlCommand
END





GO

GRANT EXECUTE ON [NAP_Admin_Settlement_FGLG_Push] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_FGLG_Push] TO [vnteam] AS [dbo]
GO


