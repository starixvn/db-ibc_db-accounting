ALTER PROCEDURE [dbo].[Acc_NewsSel]
	@NewsID	int,
	@AppID smallint
AS
/*
Created: 20110215@Bobby
Task : Get News item detail on Accounting site
DB: DB06.bodb_Maintenance
Original:
	
Param's Explanation:	
*/
SET NOCOUNT ON

SELECT [NewsID],
	   [Date],
	   [NewsContent],
	   [Title],
	   [Func],
	   [AppID],
	   [Feature],
	   [Thumbnail],
	   [OwnerID]	
FROM   dbo.Acc_News WITH(NOLOCK)
WHERE NewsID = @NewsID AND AppID = @AppID AND Feature<>-1

GO
GRANT EXECUTE ON [dbo].[Acc_NewsSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_NewsSel] TO [VNTeam]
GO