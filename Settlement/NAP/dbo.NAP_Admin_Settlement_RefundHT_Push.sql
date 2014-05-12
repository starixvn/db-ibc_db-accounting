ALTER PROCEDURE [NAP_Admin_Settlement_RefundHT_Push]
	@MatchId int,
	@AdminId int,
	@IsExcludeBetdaq bit = 0,
	@IsSettleAbandonedMatch bit = 0,
	@IsExcludeBetfair bit = 0,
	@IsSettleAbandonedMatchBetFair bit = 0,
	@HalfTimeHome int = NULL,
	@HalfTimeAway int = NULL,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
as

/*
	Created: 20130213@Kathy
	Task : Refund Half-time in case there are HT tickets bet on special matches that have 3 sets
	DB: DBTXN/BODB02

	Revisions:
		- 20140506@Kathy: Don't allow to calculate exists matches in queue
	
	Param's Explanation:
	• @matchid: matchid of match to Refund HT
	• @IsExcludeBetdaq: Is Exclude betdaq tickets or not
	• @IsSettleAbandonedMatch: Is Settlement for Betdaq ticket of Abandoned/postponed match or not
	• @IsExcludeBetfair: Is Exclude betfair tickets or not
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

	IF EXISTS (SELECT 1 from Single_Calculate_Queue with(NOLOCK) WHERE matchid = @matchid AND IsCalculating IN (0,1) )
		OR EXISTS (SELECT 1 from Parlay_Calculate_Queue with(NOLOCK) WHERE matchid = @matchid AND IsCalculating IN (0,1))
	BEGIN 
		SELECT	 @ErrCode	= 1000000
				,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'	
		RETURN
	END 

	SELECT @sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_RefundHT] @matchid = ' + CONVERT(NVARCHAR(50),@MatchId) +
								 ', @adminid = ' + CONVERT(NVARCHAR(50),@AdminId) + 
								 ', @IsExcludeBetdaq = ' + CONVERT(NVARCHAR(1),@IsExcludeBetdaq) + 
								 ', @IsSettleAbandonedMatch = ' + CONVERT(NVARCHAR(1),@IsSettleAbandonedMatch) +
								 ', @IsExcludeBetfair = ' + CONVERT(NVARCHAR(1),@IsExcludeBetfair) + 
								 ', @IsSettleAbandonedMatchBetFair = ' + CONVERT(NVARCHAR(1),@IsSettleAbandonedMatchBetFair) + 
								 ', @hth = ' + ISNULL(CONVERT(NVARCHAR(50),@HalfTimeHome),'NULL' )+
								 ', @hta = ' + ISNULL(CONVERT(NVARCHAR(50),@HalfTimeAway),'NULL') +
								 ', @IP = ''' + CONVERT(NVARCHAR(50),@IP) + '''' +
								 ', @ErrCode = @ErrCode OUTPUT' +
								 ', @ErrMsg = @ErrMsg OUTPUT' 

	INSERT INTO Single_Calculate_Queue(matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
	SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, 'Refund-HT', @sqlCommand
END

GO

GRANT EXECUTE ON [NAP_Admin_Settlement_RefundHT_Push] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_RefundHT_Push] TO [vnteam] AS [dbo]
GO


