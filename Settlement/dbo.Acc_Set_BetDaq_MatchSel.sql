ALTER PROCEDURE [dbo].[Acc_Set_BetDaq_MatchSel]
	@MatchID		INT,
	@ErrCode		INT = 0 OUTPUT ,
	@ErrMsg			VARCHAR(200)='' OUTPUT	
AS
/*
	Created: Shifu
	Date: 2010-06-01
	Task: Find available matches for moving BetDaq ticket
	DB: DB02.BODB02 

	Revisions: 
				

	Param's Explanation: 
		@MatchID: current match 

*/
SET NOCOUNT ON
DECLARE	@awayID			INT,
		@homeID			INT,
		@leagueID		INT,
		@eventdate		DATETIME,
		@rc				INT
		

SELECT	@awayID		= awayID,
		@homeID		= homeID,
		@leagueID	= leagueID,
		@eventdate	= eventdate
FROM	Match WITH (NOLOCK)
WHERE	matchid = @MatchID 

SELECT	matchcode, matchid,  convert(varchar, eventdate, 110) eventdate   
FROM	match WITH (NOLOCK) 
WHERE	homeid = @HomeID
		AND awayid = @AwayID
		AND	leagueid = @LeagueID 
		AND eventdate >= @Eventdate 
		AND matchid <> @MatchID 
		AND matchcode NOT LIKE '%hedge%'
ORDER BY eventdate

SELECT @rc = @@ROWCOUNT
IF @rc = 0 
BEGIN
	SELECT	@ErrCode = 101,
			@ErrMsg  = 'A new match has not been created yet!'
	RETURN
END


GO
GRANT EXECUTE ON [dbo].[Acc_Set_BetDaq_MatchSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Set_BetDaq_MatchSel] TO [vnteam] 
