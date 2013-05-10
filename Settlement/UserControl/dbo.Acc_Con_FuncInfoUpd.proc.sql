ALTER PROCEDURE [dbo].[Acc_Con_FuncInfoUpd]
	@FuncId int,
	@FuncName nvarchar(50),
	@FuncNote nvarchar(2000) = null,
	@FuncDesc nvarchar(50) = '',
	@FileNames nvarchar(2000),
	@System nvarchar(50) = 'ACCOUNTING',	
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@UserId int,
	@ParentId int
AS
/*
Task: Update function info 
DB: DB03.BODB02 

Revision
	20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
*/
	SET NOCOUNT ON 
	--Check permission
	EXEC dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output, @System = 'ACCOUNTING'
	If @ErrCode <> 0
		RETURN
	IF exists (select 1 from acc_functioninfo with (NOLOCK) where system = @System and FuncName = @FuncName and FuncId <> @FuncId)
	BEGIN
		Select @ErrMsg = 	case @Language 
							when 'E' then N'This function name is already used.'
							when 'CS' then N'This function name is already used.'
							else N'This function name is already used.'
					end, @ErrCode = 101	
		return
	END 
		
	update acc_functioninfo with (rowlock)
	set FuncName = @FuncName, FuncNote = @FuncNote, FuncDesc = @FuncDesc, ModifyDate = getdate(), FileNames = @FileNames, ParentId = @ParentId
	where FuncID = @FuncId
	--Write log
	declare @LogData nvarchar(200)
	Select @LogData = '[' + @System + '] Update functioninfo:' + convert(varchar(20),@FuncId)
	EXEC Log.bodb02.dbo.WriteLog_UserLog @UserID = @UserID, @Doing = @LogData



GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_FuncInfoUpd] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_FuncInfoUpd] TO [bodbAdminNet]
GO