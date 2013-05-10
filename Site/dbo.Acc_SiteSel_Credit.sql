CREATE PROC [Acc_SiteSel_Credit]
AS

/*
Created by: Scott
Date: 2012-11-20
Task : GET active CREDIT sites
DB: DB053.BODB02
Original SP: [Acc_SiteSel] 
Revisions:
*/

SET NOCOUNT ON  

select [siteid], [site] 
from [site]  with(nolock)
where islicensee = 0  AND isactive=1

GO


GRANT EXECUTE ON [dbo].[Acc_SiteSel_Credit] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_SiteSel_Credit] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SiteSel_Credit] TO [vnteam]

