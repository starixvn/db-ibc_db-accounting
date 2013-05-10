ALTER PROCEDURE [dbo].[Acc_Con_GroupInfoDel]
	@GroupID int,
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT ,
	@UserID int,
	@System nvarchar(50) = 'ACCOUNTING'
AS

--Check permission for account site: @phuc20080213
EXEC dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output, @System = @System
If @ErrCode <> 0
	RETURN
--end
if @system ='ACCOUNTING'
BEGIN
	IF exists (select 1 from AccCustomer_1 with (NOLOCK) where GroupID = @GroupID) 
	BEGIN
		Select @ErrMsg = 	case @Language 
						when 'E' then N' This group has customer belong to, so you cannot delete!'
						when 'CS' then N' This group has customer belong to, so you cannot delete!'
						else N' This group has customer belong to, so you can not delete!'
				end, @ErrCode = 102
		return
	END
	
END
ELSE IF @System='AFFILIATE'
BEGIN
	IF exists (select 1 from affiliate_user with (NOLOCK) where GroupID = @GroupID) 
	BEGIN
		Select @ErrMsg = 	case @Language 
						when 'E' then N' This group has customer belong to, so you cannot delete!'
						when 'CS' then N' This group has customer belong to, so you cannot delete!'
						else N' This group has customer belong to, so you can not delete!'
				end, @ErrCode = 102
		return
	END	
END	
DELETE FROM Acc_GroupPolicy_1 where GroupID=@GroupID
DELETE FROM Acc_GroupInfo_1 where GroupID=@GroupID
declare @LogData nvarchar(300)
Select @LogData ='[' + @System + '] Delete GroupID:' + convert(varchar(20),@groupid)
EXEC Log.bodb02.dbo.WriteLog_UserLog @UserID = @UserID, @Doing = @LogData



GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_GroupInfoDel] TO [vnteam]
go

GRANT EXECUTE ON [dbo].[Acc_Con_GroupInfoDel] TO [bodbAdminNet]