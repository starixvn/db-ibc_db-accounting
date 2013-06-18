 CREATE PROCEDURE [dbo].[Acc_CustomerSelConsolidatedGroup]

/*	Created by: Sophia
	Date: 2011-07-12
	Task: Select Consolidated Group 
	DB: DBAGE/bodb_AGE

	Revisions:	
		- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE
	Param's Explanation:

*/
AS
SET NOCOUNT ON


SELECT		a.GroupID, a.CustID, c.username, c.currency , b.TotalMember
FROM		Age_CustGroup a WITH (NOLOCK)
INNER JOIN	bodb02.dbo.customer c WITH (NOLOCK) ON  a.custid = c.custid	
INNER JOIN  (SELECT GroupID, Count (CustID) as TotalMember FROM Age_CustGroup GROUP BY GroupID) b ON b.GroupID = a.GroupID
WHERE		a.isHeader = 1 
ORDER BY	c.username



GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelConsolidatedGroup] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelConsolidatedGroup] TO [vnteam]
go

