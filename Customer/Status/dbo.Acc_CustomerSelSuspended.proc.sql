USE [bodb02]
GO
Alter Procedure [dbo].[Acc_CustomerSelSuspended]
	@CustID int
AS
SET NOCOUNT ON
/*
Created: 
Task : Get status suspended by custid
DB: DB05.bodb02
Original:Accounting site

Revisions:
	- 20090527@Pluto: Get customer suspended status
Param's Explanation:
	@CustID: id of customer
*/		
Select isnull(reject,0) as Suspended
From custinfo with (nolock)
Where CustID = @CustID

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelSuspended] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelSuspended] TO [vnteam]

