ALTER PROCEDURE [dbo].[Acc_IOM_BettransDelSpecial_LeagueSelOutright]
AS
/*
Created: 20120704@Elodie
Task : Select outright leagues for Special Del
DB: DB053.bodb02
Original: Acc_BettransDelSpecial_LeagueSelOutright

Revisions:    
   
Param's Explanation:

*/

SET NOCOUNT ON

select DISTINCT league.leagueid
from outright with (nolock)
	inner join league with (nolock) on outright.leagueid = league.leagueid
where orid IN (select matchid from bettrans with (nolock) where bettype in (10,31,32,33)) and sporttype <> 151

GO
GRANT EXECUTE ON [dbo].[Acc_IOM_BettransDelSpecial_LeagueSelOutright] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_IOM_BettransDelSpecial_LeagueSelOutright] TO [VNTeam]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_IOM_BettransDelSpecial_LeagueSelOutright] TO [VNTeam]
  