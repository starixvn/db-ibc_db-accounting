CREATE PROCEDURE [NAP_Admin_Settlement_RefundFT_Push]
	@MatchId int,
	@AdminId int,
	@IsExcludeBetdaq bit = 0,
	@IsSettleAbandonedMatch bit = 0,
	@IsExcludeBetfair bit = 0,
	@IsSettleAbandonedMatchBetFair bit = 0,
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
	

	Param's Explanation:
	• @matchid: matchid of match to Refund HT
	• @IsSettleAbandonedMatch: Is Settlement for Abandoned/postponed match or not
	• @IsSettleAbandonedMatchBetFair: Is Settlement for Betfair ticket of Abandoned/postponed match or not

*/
BEGIN
	SET NOCOUNT ON 
	DECLARE @matchcode nvarchar(50),@sporttype int, @leagueid int, @sqlCommand NVARCHAR(500)

	SELECT @matchcode = m.matchcode, @sporttype = m.sporttype, @leagueid = m.leagueid
	FROM match m with(NOLOCK)
	where m.matchid = @MatchId

	IF @@ROWCOUNT = 0 
	BEGIN
		SELECT	 @ErrCode	= 1000001
				,@ErrMsg	= 'Match does not exist!'	
		RETURN
	END 

	SELECT @sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_RefundFT] @matchid = ' + CONVERT(NVARCHAR(10),@MatchId) +
								 ', @adminid = ' + CONVERT(NVARCHAR(10),@AdminId) + 
								 ', @IsExcludeBetdaq = ' + CONVERT(NVARCHAR(1),@IsExcludeBetdaq) + 
								 ', @IsSettleAbandonedMatch = ' + CONVERT(NVARCHAR(1),@IsSettleAbandonedMatch) +
								 ', @IsExcludeBetfair = ' + CONVERT(NVARCHAR(1),@IsExcludeBetfair) + 
								 ', @IsSettleAbandonedMatchBetFair = ' + CONVERT(NVARCHAR(1),@IsSettleAbandonedMatchBetFair) + 
								 ', @fth = ' + ISNULL(CONVERT(NVARCHAR(10),@FullTimeHome),'NULL') +
								 ', @fta = ' + ISNULL(CONVERT(NVARCHAR(10),@FullTimeAway),'NULL') +
								 ', @betstatus = ' + CASE when @BetStatus IS NULL THEN 'NULL' ELSE 'N''' + CONVERT(nvarchar(20),@BetStatus)+ '''' END +
								 ', @IP = ''' + CONVERT(NVARCHAR(10),@IP) + '''' +
								 ', @ErrCode = @ErrCode OUTPUT' +
								 ', @ErrMsg = @ErrMsg OUTPUT' 
	INSERT INTO Single_Calculate_Queue(matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
	SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, 'Refund-FT', @sqlCommand

END 




GO

GRANT EXECUTE ON [NAP_Admin_Settlement_RefundFT_Push] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_RefundFT_Push] TO [vnteam] AS [dbo]
GO


