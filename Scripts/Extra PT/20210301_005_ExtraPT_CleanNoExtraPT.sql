/*<info serverAlias="DBCUST-CustDB"></info>*/
/*
	Created: 20210301@Percy
	DB: DBCUST-CustDB
	Task: Clean No Extra PT Setting data
	https://nexdev.net/issues/146710 (Step 2.5)
*/
use CustDB
go

-- 24 rows
delete dbo.Acc_GroupExtraPTSetting with (rowlock, updlock)
where GroupId = 0 -- No Extra PT

-- 4 rows
delete dbo.Acc_GroupExtraPT2Setting with (rowlock, updlock)
where GroupId = 0 -- No Extra PT