ALTER PROCEDURE [dbo].[Acc_Con_FuncInfoSelParent]
@System varchar(50)='ACCOUNTING'
AS
/*
Task: Select function Info BY System 
DB: DB03.BODB02 

Revision
	20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
*/
	SET NOCOUNT ON 

	Select FuncId, FuncName
	from acc_functioninfo
	where System = @System

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_FuncInfoSelParent] TO [vnteam]
go
GRANT EXECUTE ON [dbo].[Acc_Con_FuncInfoSelParent] TO [bodbAdminNet]