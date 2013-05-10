ALTER PROCEDURE [dbo].[Acc_Con_FuncInfoDel]
	@FuncID int,
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT ,
	@UserID int,
	@System nvarchar(50) = 'ACCOUNTING'
AS

/*
	Created by: []
	Task: Delete function
	DB: DB03.bodb02 
	
	Revisions:
		- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1

*/ 
SET NOCOUNT ON 
--Check permission for account site: @phuc20080213
EXEC dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UserControl]',@System='ACCOUNTING',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

if exists (select 1 from acc_functioninfo with (nolock) where ParentId = @FuncId and ParentId <> FuncId)
BEGIN
	Select @ErrMsg = 	case @Language 
					when 'E' then N'Error occurs. This function has sub function belong to, so you can not delete!'
					when 'CS' then N'Error occurs. This function has sub function belong to, so you can not delete!'
					else N'Error occurs. This function has sub function belong to, so you can not delete!'
			end, @ErrCode = 102
	return
END
BEGIN TRANSACTION
	DELETE FROM Acc_GroupPolicy_1 where FuncId=@FuncId
	DELETE FROM Acc_MemberPolicy_1 where FuncId=@FuncId
	DELETE FROM acc_functioninfo where FuncId=@FuncId
	IF @@ERROR <> 0
		BEGIN
			ROLLBACK TRANSACTION
			select @ErrMsg = case @Language 
						when 'E' then 'Delete function failed.'
						when 'CS' then N'Delete function failed.'
						when 'J' then N'Delete function failed.'
						else N'Delete function failed.'
					end, @ErrCode = 103
			return
		END
COMMIT TRANSACTION
	
declare @LogData nvarchar(300)
Select @LogData = '[' + @System + '] Delete FunctionID:' + convert(varchar(20),@FuncId)
EXEC Log.bodb02.dbo.WriteLog_UserLog @UserID = @UserID, @Doing = @LogData



GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_FuncInfoDel] TO [vnteam]
go
GRANT EXECUTE ON [dbo].[Acc_Con_FuncInfoDel] TO [bodbAdminNet]