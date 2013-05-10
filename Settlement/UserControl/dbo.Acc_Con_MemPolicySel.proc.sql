create PROCEDURE dbo.Acc_Con_MemPolicySel
	@system varchar(50) = 'Accounting',
	@custid int
AS
	select Acc_FunctionInfo.FuncID, Acc_FunctionInfo.FuncName, Acc_FunctionInfo.FuncDesc,Acc_MemberPolicy.Policy ,Acc_FunctionInfo.ParentID
	FROM  Acc_FunctionInfo with(nolock),Acc_MemberPolicy with(nolock)
	where Acc_FunctionInfo.FuncID != Acc_MemberPolicy.FuncID and Acc_MemberPolicy.Custid=@custid
	and Acc_FunctionInfo.system=@system
	group by Acc_FunctionInfo.FuncID, Acc_FunctionInfo.FuncName, Acc_FunctionInfo.FuncDesc,Acc_MemberPolicy.Policy,Acc_FunctionInfo.ParentID
	order by Acc_FunctionInfo.ParentID

GO
GRANT EXECUTE ON [dbo].[Acc_Con_MemPolicySel] TO [bodbAdminNet]
GO
 