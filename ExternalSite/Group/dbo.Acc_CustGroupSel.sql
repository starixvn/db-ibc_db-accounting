ALTER PROCEDURE  [dbo].[Acc_CustGroupSel]
	@GroupName varchar(50) = null
AS
/*
	Created by: [Henry]
	Date: 2011-04-01
	Task: Select the list super/master of Acc_CustGroup
	DB: DBAGE/bodb_AGE
	
	Revisions:
		- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE

*/
	SET NOCOUNT ON 
	
	if @GroupName = ''
	set @GroupName = null
	
	select 
		a.CustID, c.username,c.firstname, c.lastname, a.roleid, a.GroupName , c.iplogin
	from 
		Acc_CustGroup a (nolock) inner join bodb02.dbo.customer c (nolock) on a.CustID = c.CustID
	where GroupName = COALESCE(@GroupName,GroupName)
	order by GroupName, username	
	

GO
GRANT EXECUTE ON [dbo].[Acc_CustGroupSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustGroupSel] TO [vnteam]