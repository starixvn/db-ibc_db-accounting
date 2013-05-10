ALTER PROCEDURE [dbo].[Acc_Con_GroupInfoIns]
	@GroupID int output,
	@GroupName nvarchar(50)='',
	@GroupDesc nvarchar(50)='',
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@UserID int,
	@System nvarchar(50) = 'ACCOUNTING'
As

/*
Task: Insert group info 
DB: DB03.BODB02 

Revision
	20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
*/

SET NOCOUNT ON 
--Check permission for account site: @phuc20080213
EXEC dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output, @System = @System
If @ErrCode <> 0
	RETURN
--end
IF exists (select 1 from Acc_GroupInfo_1 with (NOLOCK) where system = @System and GroupName = @GroupName)
BEGIN
	Select @ErrMsg = 	case @Language 
					when 'E' then N'This group name is already used.'
					when 'CS' then N'This group name is already used.'
					else N'This group name is already used.'
			end, @ErrCode = 102
	return
END
BEGIN TRANSACTION
	INSERT INTO Acc_GroupInfo_1(Groupname, GroupDesc, System, CreateDate,ModifyDate,Creator)
		VALUES (@GroupName, @GroupDesc, @System, getdate(),getdate(),@UserID)
	
	SELECT @GroupID=@@IDENTITY
	Insert into Acc_GroupPolicy_1(GroupID,FuncID,Policy,Createdate,ModifyDate,Creator)
		Select @GroupID as GroupID,FuncID,0 as policy,getdate() as createdate,
			getdate() as modifydate, @UserID as creator
		from acc_functioninfo with (nolock) where system = @System
	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		select @ErrMsg = case @Language 
							when 'E' then 'Add group failed.'
							when 'CS' then N'Add group failed.'
							when 'J' then N'Add group failed.'
							else N'Add group failed.'
						end, @ErrCode = 103
		return
	END
COMMIT TRANSACTION
declare @LogData nvarchar(200)
Select @LogData = '[' + @System + '] add groupinfo:' + convert(varchar(20),@GroupID)
EXEC Log.bodb02.dbo.WriteLog_UserLog @UserID = @UserID, @Doing = @LogData



GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_GroupInfoIns] TO [vnteam]
go

GRANT EXECUTE ON [dbo].Acc_Con_GroupInfoIns TO [bodbAdminNet]