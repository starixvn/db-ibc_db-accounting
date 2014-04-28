ALTER PROCEDURE [NAP_Admin_Settlement_FGLG_Push] @AdminId INT
	,@MatchId INT
	,@action VARCHAR(10) = 'CAL-FT'
	,@BetStatus NVARCHAR(50)
	,@IncludeLastGoal BIT = 0
	,@IP VARCHAR(15) = ''
	,@goalrecord VARCHAR(50) = ''
	,@IsLoopTempTable BIT = 0
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*	Creator: Kathy
	Date: 20140213
	Task: SP for settle FGLG
	DB: DBTXN/BODB02
	
	Revisions:
		- 20140426@Kathy: Add 1H FGLG (127) [Redmine:#14449]
		
	Param's Explanation:
		+ @betstatus: FGLG status
		+ @IsLoopTempTable: 1 : is nested
							0 : Normal
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @matchcode NVARCHAR(50)
		,@sporttype INT
		,@leagueid INT
		,@sqlCommand NVARCHAR(500)
		,@mode VARCHAR(20)

	SELECT @matchcode = m.matchcode
		,@sporttype = m.sporttype
		,@leagueid = m.leagueid
	FROM match m WITH (NOLOCK)
	WHERE m.matchid = @MatchId

	SELECT @ErrCode = 0
		,@ErrMsg = ''
		,@mode = CASE when @action = 'CAL-FT' THEN CASE WHEN @IncludeLastGoal = 0 then  'CAL-FTFGLG' 
														 ELSE 'CAL-FTLG' 
													END
					   ELSE CASE WHEN @IncludeLastGoal = 0 THEN 'CAL-HTFGLG'
								 ELSE 'CAL-HTLG'
							END
				 END

	SELECT @sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_FGLG] @matchid = ' + CONVERT(NVARCHAR(50), @MatchId) 
					+ ', @action = ' + CASE WHEN @action IS NULL THEN 'CAL-FT' ELSE '''' + CONVERT(NVARCHAR(50), @action) + '''' END 
					+ ', @creator = ' + CONVERT(NVARCHAR(50), @AdminId) 
					+ ', @goalrecord = ' + CASE WHEN @GoalRecord IS NULL THEN 'NULL'ELSE '''' + CONVERT(NVARCHAR(50), @GoalRecord) + '''' END 
					+ ', @betstatus = ' + CASE WHEN @BetStatus IS NULL THEN 'NULL' ELSE 'N''' + CONVERT(NVARCHAR(50), @BetStatus) + '''' END 
					+ ', @IncludeLG = ' + CONVERT(NVARCHAR(1), @IncludeLastGoal) 
					+ ', @IsLoopTempTable = ' + CONVERT(NVARCHAR(1), @IsLoopTempTable) 
					+ ', @IP = ''' + CONVERT(NVARCHAR(50), @IP) + '''' 
					+ ', @ErrCode = @ErrCode OUTPUT' 
					+ ', @ErrMsg = @ErrMsg OUTPUT'

	INSERT INTO Single_Calculate_Queue (
		matchid
		,matchcode
		,IsCalculating
		,LeagueID
		,SportType
		,AdminId
		,IP
		,Action
		,sqlCommand
		)
	SELECT @MatchId
		,@matchcode
		,0
		,@leagueid
		,@sporttype
		,@AdminId
		,@IP
		,@action
		,@sqlCommand
END



GO

GRANT EXECUTE ON [NAP_Admin_Settlement_FGLG_Push] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_FGLG_Push] TO [vnteam] AS [dbo]
GO


