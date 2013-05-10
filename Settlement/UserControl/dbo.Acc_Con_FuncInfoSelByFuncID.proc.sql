ALTER PROCEDURE [dbo].[Acc_Con_FuncInfoSelByFuncID]
	@FuncId int
AS
/*
Task: Select function Info BY FuncID 
DB: DB03.BODB02 

Revision
	20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
*/

SET NOCOUNT ON 

select FuncId, FuncName, FuncDesc, FileNames, (select count(funcid) from acc_functioninfo acc1 with (nolock) where acc1.parentid = acc.funcid and acc1.parentid <> acc1.funcid) as SubFuncCount
from acc_functioninfo acc with (nolock)
where FuncId = @FuncId


GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_FuncInfoSelByFuncID] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_FuncInfoSelByFuncID] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_FuncInfoSelByFuncID] TO [bodbExtAccNet]
GO