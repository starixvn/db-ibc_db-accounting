CREATE PROCEDURE [NAP_Admin_Settlement_Refund_BetDaq_Push]
	@MatchId int,
	@AdminId int, 	
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
Created: 20140218@Kathy 
Task : Refund Running BetDaq 
Original: 
DB: DBTXN/BODB02

Revisions: 
	

Param's Explanation:
• @matchid: matchid need to refund
• @IsExcludeBetdaq: Is Exclude betdaq tickets or not
• @IsSettleAbandonedMatch: Is Settlement for Abandoned/postponed match or not
BetDaq account: 
			custid	--- username	-	roleid
			50057	---	BQUS888		-	1
			879241	---	BQUSMLB		-	1
			103873	---	BQUSNBA		-	1
			78761	---	ITibc101	-	1
			1688156	---	MTEST0101	-	2
			851668  --- BDUS01      -   1
			878902  --- BDUS016     -   1
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @matchcode nvarchar(50),@sporttype int, @leagueid int, @sqlCommand NVARCHAR(500)	

	SELECT @matchcode = m.matchcode, @sporttype = m.sporttype, @leagueid = m.leagueid
	FROM match m with(NOLOCK)
	where m.matchid = @MatchId

	IF @@ROWCOUNT = 0 
	BEGIN
		SELECT	 @ErrCode	= 100
				,@ErrMsg	= 'Match does not exist!'	
		RETURN
	END 

	SELECT @sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_Refund_BetDaq] @matchid = ' + CONVERT(NVARCHAR(10),@MatchId) +
								 ', @creator = ' + CONVERT(NVARCHAR(10),@AdminId) + 
								 ', @IP = ''' + CONVERT(NVARCHAR(10),@IP) + '''' +
								 ', @ErrCode = @ErrCode OUTPUT' +
								 ', @ErrMsg = @ErrMsg OUTPUT' 

	INSERT INTO Single_Calculate_Queue(matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
	SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, 'Refund-Betdaq', @sqlCommand
END





GO

GRANT EXECUTE ON [NAP_Admin_Settlement_Refund_BetDaq_Push] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_Refund_BetDaq_Push] TO [vnteam] AS [dbo]
GO


