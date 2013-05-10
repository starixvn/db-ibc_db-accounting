ALTER PROCEDURE [dbo].[Acc_Con_Batch_AdminPolicySel]
	@CustIDs nvarchar(4000),
	@GroupID int = NULL OUTPUT,
	@System varchar(50)='ACCOUNTING'
AS

/*
	Created by: []
	Task: Get functionID by CustIDs 
	DB: DB03.BODB02
	
	Revisions:
		- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1 
*/

SET NOCOUNT ON 

If @System='ACCOUNTING'
BEGIN
	Select top 1 @GroupID = GroupID From AccCustomer_1 with(nolock) where Custid in (SELECT val FROM dbo.strSplit_Key(@CustIDs,','))

	SELECT fi.funcid,fi.funcname, fi.funcdesc,f.policy ,gp.policy as gpolicy,fi.parentid ,count(fip.funcID) as SubFuncCount, fi.DisplayOrder
	FROM acc_functioninfo fi with(nolock) 
		INNER JOIN  
			(SELECT funcid,min(policy) as policy,ac.groupid as groupid
			FROM acc_memberpolicy_1 mp with(nolock) inner join AccCustomer_1 ac with(nolock) on ac.custid=mp.custid
			WHERE mp.custid in (SELECT val FROM dbo.strSplit_Key(@CustIDs,','))
			GROUP BY mp.funcid,ac.groupid) f on fi.funcid=f.funcid
		INNER JOIN Acc_GroupPolicy_1 gp with(nolock)	on gp.groupid=f.groupid and gp.funcID=f.funcID
		left join acc_functioninfo fip with (nolock) on fi.funcID = fip.ParentID and fip.parentid <> fip.funcid
	group by fi.funcid,fi.funcname, fi.funcdesc,f.policy ,gp.policy,fi.parentid, fi.DisplayOrder
	ORDER BY fi.parentid, count(fip.funcID) DESC, fi.DisplayOrder
END
if @System='AFFILIATE'
BEGIN
	Select top 1 @GroupID = GroupID From Affiliate_user with(nolock) where Custid in (SELECT val FROM dbo.strSplit_Key(@CustIDs,','))

	SELECT fi.funcid,fi.funcname, fi.funcdesc,f.policy ,gp.policy as gpolicy,fi.parentid ,count(fip.funcID) as SubFuncCount, fi.DisplayOrder
	FROM acc_functioninfo fi with(nolock) 
		INNER JOIN  
			(SELECT funcid,min(policy) as policy,ac.groupid as groupid
			FROM acc_memberpolicy_1 mp with(nolock) inner join Affiliate_user ac with(nolock) on ac.custid=mp.custid
			WHERE mp.custid in (SELECT val FROM dbo.strSplit_Key(@CustIDs,','))
			GROUP BY mp.funcid,ac.groupid) f on fi.funcid=f.funcid
		INNER JOIN Acc_GroupPolicy_1 gp with(nolock)	on gp.groupid=f.groupid and gp.funcID=f.funcID
		left join acc_functioninfo fip with (nolock) on fi.funcID = fip.ParentID and fip.parentid <> fip.funcid
	group by fi.funcid,fi.funcname, fi.funcdesc,f.policy ,gp.policy,fi.parentid, fi.DisplayOrder
	ORDER BY fi.parentid, count(fip.funcID) DESC, fi.DisplayOrder
END


GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_Batch_AdminPolicySel] TO [vnteam]
go
GRANT EXECUTE ON [dbo].Acc_Con_Batch_AdminPolicySel TO [bodbAdminNet]