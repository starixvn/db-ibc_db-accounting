ALTER PROCEDURE [dbo].[Acc_Con_AdminUpd]
	@CustID int,
	@FirstName nvarchar(50),
	@LastName nvarchar(50),
	@UserID int,
	@GroupID int,
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@System varchar(50) = 'ACCOUNTING'
AS

SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UserControl]',@System=@System,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end
EXEC db03.bodb02.dbo.Acc_Con_AdminGroupUpd_1 @CustID=@CustID,@UserID=@UserID,@GroupID=@GroupID,@Language=@Language,@System=@System,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
IF @ErrCode<> 0
	RETURN 
	
BEGIN TRANSACTION
UPDATE customer with (ROWLOCK, UPDLOCK) SET firstname = @FirstName, LastName = @LastName WHERE custid = @custid
IF  @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	select @ErrMsg = case @Language 
						when 'E' then 'Error occurs.Update unsuccessfully.'
						when 'CS' then N'Error occurs.Update unsuccessfully.'
						when 'J' then N'Error occurs.Update unsuccessfully.'
						else N'Error occurs.Update unsuccessfully.'
					end, @ErrCode = 102
	RETURN
END
COMMIT TRANSACTION



declare @LogData nvarchar(300)
Select @LogData =@System + ' UPDATE AccAdmin custid:' + convert(varchar(20), @custid) + ' Name:' + @firstname + ' '  + @lastname + ' GroupID:' + convert(varchar(20),@groupid)

EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData



GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminUpd] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminUpd] TO [bodbAdminNet]