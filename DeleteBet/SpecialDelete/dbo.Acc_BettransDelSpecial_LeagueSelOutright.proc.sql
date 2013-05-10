ALTER PROCEDURE [dbo].[Acc_BettransDelSpecial_LeagueSelOutright]
AS
/*
Created: 20090121@[Phuc]
Task : Select outright leagues for Special Del
DB: DB05.bodb02
Original:

Revisions:    
    - 200903024@Daniel: Exclude Horse leagues (sporttype = 151)
	- 20091230@Khoa: remove leaguename
	- 20120704@Elodie: check case of orid = matchid

Param's Explanation:

*/

SET NOCOUNT ON

select DISTINCT league.leagueid--, leaguename
from outright with (nolock)
	inner join league with (nolock) on outright.leagueid = league.leagueid
where	orid IN(select matchid from bettrans with (nolock) where bettype in (10,31,32,33)) and sporttype <> 151
--order by leaguename

GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecial_LeagueSelOutright] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecial_LeagueSelOutright] TO [VNTeam]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransDelSpecial_LeagueSelOutright] TO [VNTeam]
