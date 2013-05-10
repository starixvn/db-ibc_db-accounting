ALTER PROCEDURE [dbo].Acc_Rpt_LiveCasino_GameStatistics_GameTypeSel
AS
SET NOCOUNT ON
/*
Created by: Daniel
Date: 2012-02-17
Task : Retrieve Live Casino Bettypes 
DB: DB06.bodb02
Original:

Revisions:

*/
SET NOCOUNT ON
SELECT	b.typeID, b.typenamee 
FROM	bettype b WITH (NOLOCK) 
WHERE	typeid BETWEEN 1101 AND 1199
ORDER BY b.typeID ASC

GO
GRANT EXECUTE ON [dbo].Acc_Rpt_LiveCasino_GameStatistics_GameTypeSel TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].Acc_Rpt_LiveCasino_GameStatistics_GameTypeSel TO [vnteam]