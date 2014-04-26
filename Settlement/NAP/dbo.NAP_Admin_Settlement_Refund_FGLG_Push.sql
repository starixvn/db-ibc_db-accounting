ALTER PROCEDURE [NAP_Admin_Settlement_Refund_FGLG_Push]
	@MatchId int,
	@action VARCHAR(10) = 'CAL', -- CAL, CAL-HT, CAL-FT
	@AdminId int,
	@LastGoalOnly bit,
	@IP varchar(15) = '',
	@IsLoopTempTable BIT = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
Created: 20140213@Kathy
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
	DECLARE @matchcode nvarchar(50),@sporttype int, @leagueid int, @sqlCommand NVARCHAR(500) ,@mode VARCHAR(20)

	SELECT @matchcode = m.matchcode, @sporttype = m.sporttype, @leagueid = m.leagueid
	FROM match m with(NOLOCK)
	where m.matchid = @MatchId

	SELECT @mode = CASE when @action = 'CAL' THEN CASE WHEN @LastGoalOnly = 1 THEN 'Refund-LG' ELSE 'Refund-FGLG' END
					     WHEN @action = 'CAL-FT' THEN CASE when @LastGoalOnly = 1 then 'Refund-FTLG' ELSE 'Refund-FTFGLG' END
						 when @action = 'CAL-HT' THEN CASE WHEN @LastGoalOnly = 1 then 'Refund-HTLG' ELSE 'Refund-HTFGLG' END
					END 

	IF @@ROWCOUNT = 0 
	BEGIN
		SELECT	 @ErrCode	= 1000001
				,@ErrMsg	= 'Match does not exist!'	
		RETURN
	END 

	SELECT @sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_Refund_FGLG] @matchid = ' + CONVERT(NVARCHAR(50),@MatchId) +
								 ', @action = ' + CASE WHEN @action IS NULL THEN 'CAL-FT' ELSE '''' + CONVERT(NVARCHAR(50), @action) + '''' END +
								 ', @adminid = ' + CONVERT(NVARCHAR(50),@AdminId) + 
								 ', @LGOnly= ' + CONVERT(NVARCHAR(1),@LastGoalOnly) + 
								 ', @IsLoopTempTable = ' + CONVERT(NVARCHAR(1),@IsLoopTempTable) +		
								 ', @IP = ''' + CONVERT(NVARCHAR(50),@IP) + '''' +
								 ', @ErrCode = @ErrCode OUTPUT' +
								 ', @ErrMsg = @ErrMsg OUTPUT' 
	INSERT INTO Single_Calculate_Queue(matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
	SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, @mode, @sqlCommand
END 

GO

GRANT EXECUTE ON [NAP_Admin_Settlement_Refund_FGLG_Push] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_Refund_FGLG_Push] TO [vnteam] AS [dbo]
GO


