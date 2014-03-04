CREATE PROCEDURE [NAP_Admin_Settlement_Refund_BetFair_Push]
	@MatchId int,
	@AdminId int, 	
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
Created: 20140218@Kathy 
Task : Refund Running BetFair
Original: Admin_Settlement_Refund_BetFair
DB: DBTXN/BODB02

Revisions: 
	

Param's Explanation:
• @matchid: matchid need to refund
• @IsExcludeBetfair: Is Exclude betdaq tickets or not
• @IsSettleAbandonedMatchBetFair: Is Settlement for Abandoned/postponed match or not
BetFair account: 
			custid	--- username	-	roleid
			2331	---	BF		    -	1
			1077687	---	BFOS		-	1
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @matchcode nvarchar(50),@sporttype int, @leagueid int, @sqlCommand NVARCHAR(500)

	SELECT @matchcode = m.matchcode, @sporttype = m.sporttype, @leagueid = m.leagueid
	FROM match m with(NOLOCK)
	where m.matchid = @MatchId

	IF @@ROWCOUNT = 0 
	BEGIN
		SELECT	 @ErrCode	= 1000000
				,@ErrMsg	= 'Match does not exist!'	
		RETURN
	END 

	SELECT @sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_Refund_BetFair] @matchid = ' + CONVERT(NVARCHAR(10),@MatchId) +
								 ', @creator = ' + CONVERT(NVARCHAR(10),@AdminId) + 
								 ', @IP = ''' + CONVERT(NVARCHAR(10),@IP) + '''' +
								 ', @ErrCode = @ErrCode OUTPUT' +
								 ', @ErrMsg = @ErrMsg OUTPUT' 
	INSERT INTO Single_Calculate_Queue(matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
	SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, 'Refund-BetFair', @sqlCommand
END



GO

GRANT EXECUTE ON [NAP_Admin_Settlement_Refund_BetFair_Push] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_Refund_BetFair_Push] TO [vnteam] AS [dbo]
GO


