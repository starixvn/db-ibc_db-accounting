CREATE PROCEDURE [NAP_Set_BetDaq_MatchSel]
	@MatchID		INT
AS
/*
	Created: Kathy
	Date: 20140113
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
		@eventdate		DATETIME
		

SELECT	@awayID		= awayID,
		@homeID		= homeID,
		@leagueID	= leagueID,
		@eventdate	= eventdate
FROM	Match WITH (NOLOCK)
WHERE	matchid = @MatchID 

SELECT	matchcode, matchid, eventdate   
FROM	match WITH (NOLOCK) 
WHERE	homeid = @HomeID
		AND awayid = @AwayID
		AND	leagueid = @LeagueID 
		AND eventdate >= @Eventdate 
		AND matchid <> @MatchID 
		AND matchcode NOT LIKE '%hedge%'
ORDER BY eventdate


GO

GRANT EXECUTE ON [NAP_Set_BetDaq_MatchSel] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_BetDaq_MatchSel] TO [vnteam] AS [dbo]
GO


