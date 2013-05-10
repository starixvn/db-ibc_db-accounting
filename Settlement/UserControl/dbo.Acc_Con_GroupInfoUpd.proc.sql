ALTER PROCEDURE [dbo].[Acc_Con_GroupInfoUpd]
	@GroupID int,
	@GroupName nvarchar(50)=null,
	@GroupDesc nvarchar(50)=null,
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@UserID int,
	@System nvarchar(50) = 'ACCOUNTING'
AS

--Check permission for account site: @phuc20080213
EXEC dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UserControl]',@System=@System,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

IF exists (select 1 from Acc_GroupInfo_1 with (NOLOCK) where system = @System and Groupname = @GroupName and GroupID <> @GroupID)
BEGIN
	Select @ErrMsg = 	case @Language 
						when 'E' then N'This group name is already used.'
						when 'CS' then N'This group name is already used.'
						else N'This group name is already used.'
				end, @ErrCode = 101	
	return
END 
ELSE
BEGIN
	Update Acc_GroupInfo_1 set GroupName=isnull(@GroupName,GroupName),GroupDesc=isnull(@GroupDesc,GroupDesc),Modifydate=getdate(),Creator=@Userid where GroupID=@GroupID	
	declare @LogData nvarchar(200)
	Select @LogData = '[' + @System + '] Update groupinfo:' + convert(varchar(20),@GroupID)	
	EXEC Log.bodb02.dbo.WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
END



GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_GroupInfoUpd] TO [vnteam]
go

GRANT EXECUTE ON [dbo].[Acc_Con_GroupInfoUpd] TO [bodbAdminNet]