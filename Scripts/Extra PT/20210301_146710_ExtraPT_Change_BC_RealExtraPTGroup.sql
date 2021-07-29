/*<info serverAlias="DBCUST-CUSTDB"></info>*/
/*
	Created: 20210301@Percy
	DB: DBCUST-CustDB
	Task: Change BC Group to real Extra PT Group
*/
use CustDB
go

declare @EndDate datetime = convert(date, getdate())

-- Extra PT Group
delete dbo.Acc_DWLList_ExtraPT with (rowlock, updlock)
where GroupName in ('ACCTHAI2', 'ACCTHAI56', 'ACCTHAI99')

-- Extra PT Setting
update dbo.Acc_GroupExtraPT_Product with (rowlock)
set ToDate = @EndDate
where GroupName in ('ACCTHAI2', 'ACCTHAI56', 'ACCTHAI99')
	and ToDate > @EndDate

update dbo.Acc_GroupExtraPTSetting with (rowlock)
set ToDate = @EndDate
where GroupName in ('ACCTHAI2', 'ACCTHAI56', 'ACCTHAI99')
	and ToDate > @EndDate

insert into NAP_UserControl.dbo.eaGroup (GroupName, Description, CreatedDate, Creator, Currency, CurrencyCode, Site, ParentID)
values ('BC', '', GETDATE(), 15512891, 'THB', 'THB', '755555', 0)

delete NAP_UserControl.dbo.eaGroup with (rowlock, updlock)
where GroupName in ('ACCTHAI2', 'ACCTHAI56', 'ACCTHAI99')

insert into dbo.Acc_CustGroup (CustID, RoleID, GroupName, IsPayout)
select distinct CustId, 4 as RoleId, 'BC', 1 as IsPayout
from dbo.Acc_CustGroup with (nolock)
where GroupName in ('ACCTHAI2', 'ACCTHAI56', 'ACCTHAI99')

delete dbo.Acc_CustGroup with (rowlock, updlock)
where GroupName in ('ACCTHAI2', 'ACCTHAI56', 'ACCTHAI99')