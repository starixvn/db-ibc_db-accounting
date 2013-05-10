ALTER PROCEDURE [dbo].[Acc_NewsSelAll]
	@PageIndex int = 1,
	@AppID smallint,
	@PageSize int = 20,
	@TotalRows int = 0 output
AS
/*
Created: 20110215@Bobby
Task : Get All News item on Accounting site
DB: DB06.bodb_Maintenance
Original:
	
Param's Explanation:	
*/
SET NOCOUNT ON;

-- Rows count 
SELECT @TotalRows = COUNT(NewsID) FROM dbo.Acc_News WITH(NOLOCK) WHERE AppID=@AppID AND Feature<>-1;
WITH News AS
(
	SELECT TOP(@PageIndex*@PageSize) ROW_NUMBER() OVER (ORDER BY [Date] DESC) AS Row,
			[NewsID],
			[Date],
			[Title],
			[AppID],
			[Func],
			[Feature],
			[Thumbnail]
		   FROM dbo.Acc_News WITH(NOLOCK)
		   WHERE AppID = @AppID AND Feature<>-1
)

SELECT  [NewsID],
		[Date],
		[Title],
		[AppID],
		[Func],
		[Feature],
		[Thumbnail]
FROM News
WHERE (Row BETWEEN (@PageIndex-1)*@PageSize + 1 AND @PageIndex*@PageSize)

GO
GRANT EXECUTE ON [dbo].[Acc_NewsSelAll] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_NewsSelAll] TO [VNTeam]
GO
