ALTER PROCEDURE [NAP_Admin_Settlement_Refund_FGLG]
	@MatchId int,
	@AdminId int,
	@LastGoalOnly bit,
	@IP varchar(15) = '',
	@IsLoopTempTable BIT = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
Created: 20140109@Kathy
Task : Refund Half-time in case there are HT tickets bet on special matches that have 3 sets
DB: DBTXN/BODB02
Original: Admin_Settlement_Refund_FGLG

Revisions:
	
		
Param's Explanation:
		+ @matchid: matchid of match to Refund HT
		+ @IsLoopTempTable: 1 : is nested
							0 : Normal

*/
BEGIN
	SET NOCOUNT ON
	DECLARE @matchcode nvarchar(50),@sporttype int, @leagueid int, @sqlCommand NVARCHAR(500), @action varchar(20)

	SET @action = 'Refund-FGLG'

	SELECT @matchcode = m.matchcode, @sporttype = m.sporttype, @leagueid = m.leagueid
	FROM match m with(NOLOCK)
	where m.matchid = @MatchId

	IF @@ROWCOUNT = 0 
	BEGIN
		SELECT	 @ErrCode	= 1000001
				,@ErrMsg	= 'Match does not exist!'	
		RETURN
	END 

	SELECT @sqlCommand = 'EXEC [dbo].[Admin_Settlement_Refund_FGLG] @matchid = ' + CONVERT(NVARCHAR(10),@MatchId) +
								 ', @adminid = ' + CONVERT(NVARCHAR(10),@AdminId) + 
								 ', @LGOnly= ' + CONVERT(NVARCHAR(1),@LastGoalOnly) + 
								 ', @IsLoopTempTable = ' + CONVERT(NVARCHAR(1),@IsLoopTempTable) +		
								 ', @IP = ''' + CONVERT(NVARCHAR(10),@IP) + '''' +
								 ', @ErrCode = @ErrCode OUTPUT' +
								 ', @ErrMsg = @ErrMsg OUTPUT' 
	INSERT INTO Single_WaitingList(matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
	SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, @Action, @sqlCommand
END



GO

GRANT EXECUTE ON [NAP_Admin_Settlement_Refund_FGLG] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_Refund_FGLG] TO [vnteam] AS [dbo]
GO


