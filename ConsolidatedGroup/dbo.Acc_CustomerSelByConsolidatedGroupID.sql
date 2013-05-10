 SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Acc_CustomerSelByConsolidatedGroupID]
	@GroupID int
AS

/*	Created by: Sophia
	Date: 2011-07-12
	Task: Select Customer by Consolidated Group 
	DB: DBAGE/bodb_AGE

	Revisions:	
		- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE
	Param's Explanation:

*/

SET NOCOUNT ON

SELECT		a.Groupid, c.Username, c.currency, c.Custid, a.isHeader
FROM		Age_CustGroup a WITH (NOLOCK)
INNER JOIN	bodb02.dbo.customer c WITH (NOLOCK)
		ON	a.Custid = c.Custid
WHERE		a.Groupid = @GroupID
ORDER BY	a.isHeader DESC


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelByConsolidatedGroupID] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelByConsolidatedGroupID] TO [vnteam]
go