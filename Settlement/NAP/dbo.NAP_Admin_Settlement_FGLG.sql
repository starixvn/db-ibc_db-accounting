ALTER PROCEDURE [NAP_Admin_Settlement_FGLG]
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
	Date: 20140108
	Task: SP for settle FGLG
	DB: DBTXN/BODB02
	
	History:
		
		
	Param's Explanation:
		+ @betstatus: FGLG status
		+ @IsLoopTempTable: 1 : is nested
							0 : Normal
		
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @matchcode nvarchar(50),@sporttype int, @leagueid int, @sqlCommand NVARCHAR(500), @action varchar(20)

	SELECT @ErrCode = 0, @ErrMsg = '', @action = CASE WHEN @IncludeLastGoal = 0 THEN 'CAL-FGLG'
											else 'CAL-LG' END 

	-- check and not allow attempt to settlement same game while it's still not finish
	IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END

	IF exists(SELECT 1 FROM Single_WaitingList w WITH(NOLOCK) WHERE w.matchid = @MatchId AND w.IsCalculating IN (0,1))
	BEGIN
		SELECT @ErrCode = 101,
				@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.' 
		RETURN
	END

	SELECT @sqlCommand = 'EXEC [dbo].[Admin_Settlement_FGLG] @matchid = ' + CONVERT(NVARCHAR(10),@MatchId) +
								 ', @creator = ' + CONVERT(NVARCHAR(10),@AdminId) + 
								 ', @goalrecord = '+ CASE when @GoalRecord IS NULL THEN 'NULL' ELSE '''' + CONVERT(nvarchar(20),@GoalRecord)+ '''' END +
								 ', @betstatus = ' + CASE when @BetStatus IS NULL THEN 'NULL' ELSE 'N''' + CONVERT(nvarchar(20),@BetStatus)+ '''' END +
								 ', @IncludeLG = ' + CONVERT(NVARCHAR(1),@IncludeLastGoal) + 
								 ', @IsLoopTempTable = ' + CONVERT(NVARCHAR(1),@IsLoopTempTable) + 
								 ', @IP = ''' + CONVERT(NVARCHAR(10),@IP) + '''' +
								 ', @ErrCode = @ErrCode OUTPUT' +
								 ', @ErrMsg = @ErrMsg OUTPUT' 

	INSERT INTO Single_WaitingList(matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
	SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, @action, @sqlCommand
END




GO

GRANT EXECUTE ON [NAP_Admin_Settlement_FGLG] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_FGLG] TO [vnteam] AS [dbo]
GO


