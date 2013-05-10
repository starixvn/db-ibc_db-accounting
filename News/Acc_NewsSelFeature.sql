ALTER PROCEDURE [dbo].[Acc_NewsSelFeature]
	@AppID int
AS
SET NOCOUNT ON
/*
Created: 20110215@Bobby
Task : Get News feature item on Accounting site
DB: DB06.bodb_Maintenance
Original:
	
Param's Explanation:	
*/
SELECT TOP(1)
	[NewsID],
	[Date],
	[NewsContent],
	[Title],
	[Func],
	[Thumbnail],
	[AppID],
	[Feature]
FROM dbo.Acc_News WITH(NOLOCK)
WHERE Feature = 1 AND AppID = @AppID
ORDER BY [Date] DESC

GO
GRANT EXECUTE ON [dbo].[Acc_NewsSelFeature] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_NewsSelFeature] TO [VNTeam]
GO
