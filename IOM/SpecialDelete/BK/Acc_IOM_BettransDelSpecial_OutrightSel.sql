ALTER PROCEDURE [dbo].[Acc_IOM_BettransDelSpecial_OutrightSel]
	@LeagueID int = 0
AS
SET NOCOUNT ON
/*
Created: 20120704@Elodie
Task : Select outright for special delete
DB: DB053.bodb02
Original: Acc_BettransDelSpecial_OutrightSel

Revisions:    

Param's Explanation:

*/	

select	orid, 
		leagueid,
		teamid
from	outright with (nolock) 
where	orid IN(select matchid from bettrans with (nolock) where bettype in (10,31,32,33))
	and  leagueid = case when @LeagueID = 0 then leagueid else @leagueid end

GO
GRANT EXECUTE ON [dbo].[Acc_IOM_BettransDelSpecial_OutrightSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_IOM_BettransDelSpecial_OutrightSel] TO [VNTeam] 