/*<info serverAlias="DBPOL-NAP_UserControl"></info>*/
/*
	Created: 20210811@Percy
	DB: DBPOL-NAP_UserControl
	Task: Migrate user for BC Group
*/
use NAP_UserControl
go

-- select * from dbo.eaGroup with (nolock) where GroupName = 'BC'

-- 2 rows
update dbo.eaUserInfo with (rowlock, updlock)
set GroupId = 107 -- BC
where GroupId in (27, 28, 29) -- ACCTHAI2, ACTHAI56, ACCTHAI99