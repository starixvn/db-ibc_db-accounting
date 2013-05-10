Alter Procedure dbo.Acc_Con_AdminSelByListGroupNameUserName
	(
		@ListGroupName varchar(1000),
		@Username varchar(30)='',
		@CustID int=0
	)
AS

/*
Created: HuyNguyen
Task : Check exist UserName in a list of GroupNames
DB: DB03.bodb02
Original:Accounting site
Params:
	@ListGroupName: list group name will be denied ex:'THB,CSD'
Revisions:
*/		
SET NOCOUNT ON
if (@CustID=0)
	SELECT ac.custid
			FROM customer c with (nolock)
				INNER JOIN acccustomer_1 ac with (nolock) on c.custid = ac.custid
				INNER JOIN acc_groupinfo_1 gi with(nolock) on ac.groupid=gi.groupid
	Where gi.GroupName in (select val from dbo.strSplit(@ListGroupName, ',')) and c.username=@Username
else
	SELECT ac.custid
			FROM customer c with (nolock)
				INNER JOIN acccustomer_1 ac with (nolock) on c.custid = ac.custid
				INNER JOIN acc_groupinfo_1 gi with(nolock) on ac.groupid=gi.groupid
	Where gi.GroupName in (select val from dbo.strSplit(@ListGroupName, ',')) and c.custid=@CustID

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminSelByListGroupNameUserName] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminSelByListGroupNameUserName] TO [bodbAdminNet]
