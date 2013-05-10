ALTER PROCEDURE  [dbo].[Acc_CustGroupSelGroup]
	
AS
/*
	Created by: [Henry]
	Date: 2011-04-01
	Task: Select the list Group Name of Acc_CustGroup for drop down list box
	DB: DBAGE/bodb_AGE
	
	Revisions:
		- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE

*/
	SET NOCOUNT ON 
	
	select distinct GroupName from Acc_CustGroup (nolock)
	order by GroupName
	

GO
GRANT EXECUTE ON [dbo].[Acc_CustGroupSelGroup] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustGroupSelGroup] TO [vnteam]