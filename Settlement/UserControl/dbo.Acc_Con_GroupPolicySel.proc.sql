ALTER PROCEDURE [dbo].[Acc_Con_GroupPolicySel]
	@Groupid int
AS 

/*
Task: SELECT group info 
DB: DB03.BODB02 

Revision
	20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
*/
SET NOCOUNT ON 

SELECT gp.createdate,gp.modifydate,gp.policy,gp.groupid,fi.funcid,gi.groupname,fi.funcname
	,fi.funcdesc,fi.parentid ,count(fip.funcID) as SubFuncCount,fi.DisplayOrder
FROM Acc_GroupPolicy_1 gp with(nolock) 
INNER JOIN Acc_groupInfo_1 gi with(nolock) on gp.groupid=gi.groupid  
INNER JOIN acc_functioninfo fi with(nolock) on gp.funcid=fi.funcid 
left join acc_functioninfo fip with (nolock) on fi.funcID = fip.ParentID and fip.parentid <> fip.funcid
WHERE gp.groupid=@Groupid
group by gp.createdate,gp.modifydate,gp.policy,gp.groupid,fi.funcid,gi.groupname,fi.funcname
	,fi.funcdesc,fi.parentid, fi.DisplayOrder
ORDER BY fi.parentid,count(fip.funcID) DESC, fi.DisplayOrder


GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_GroupPolicySel] TO [vnteam]
go
GRANT EXECUTE ON [dbo].Acc_Con_GroupPolicySel TO [bodbAdminNet]