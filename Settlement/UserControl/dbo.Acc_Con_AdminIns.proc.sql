ALTER PROCEDURE [dbo].[Acc_Con_AdminIns] 
	@FirstName nvarchar(50),
	@LastName nvarchar(50),	
	@UserName nvarchar(50),
	@UserPwd nvarchar(50) = '',
	@CustID int OUTPUT,
	@UserID int,
	@GroupID int,
	@System varchar(50) = 'ACCOUNTING',
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
--Used to create AccAdmin
--In db02
SET NOCOUNT ON

/*
Created: 
Task : Add account in User control 
DB: DB02.bodb02
Original:

Revisions:
    - 20080213@Phuc: Check permission for account site
	- 20090218@PhuongDao: Check username2 
	- 20101112@Henry: add Maxperball161
	
Param's Explanation:
• @ErrCode:
    = 0: super create master successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[UserControl]',@System = @System, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end


Declare @pwdexpiry datetime, @roleid int, @closed bit

Select @RoleID = 6,
	@pwdexpiry =  DATEADD(month,1,CURRENT_TIMESTAMP),
	@closed = 0
	
if exists(select 1 from customer with (NOLOCK) where username=@username) 
BEGIN
	SELECT @ErrMsg =  case @Language
						when 'E' then 'This username is not available. '
						when 'CS' then N'This username is not available. '
						when 'J' then N'This username is not available. '
						else N'This username is not available. '
					end, @ErrCode = 102
	return
END

BEGIN TRANSACTION

	INSERT INTO customer (username, userpwd, roleid, firstname, lastname, creator, pwdexpiry) 
	VALUES (@username, @userpwd, @roleid, @firstname, @lastname, @UserID, @pwdexpiry) 

	Select @CustID = @@IDENTITY

		
	INSERT INTO [dbo].[custinfo](username, [custid], [currency], [MaxPerMatch], [MaxPerMatch2],[MaxPerMatch3],[MaxPerMatch5],[MaxPerMatch8],[MaxPerMatch10],[MaxPerMatch11],[MaxPerMatch12],[MaxPerMatch99],[Maxpermatch151],[maxpermatch201],[MaxPerMatch161],[MaxPerMatch99MP],[MaxPerBall161],[MaxPerMatch151_OT],    [roleid], [mrecommend], [recommend], [dangercust], [autosuspend], [reject], [credit], [MatchLimit],[VirtualMultiplier],[DisableHorseRacing],[DisableFinancial],[DisableCasino],[DisableOutright],[DisableOpenTote],[DisableBingo],[DisableNumber],[SyncCasino],[danger],[danger2],[danger3],[Enabled],[closed])
	VALUES(@username, @custid, NULL, 0, 0, 0, 0, 0, 0, 0,  0, 0,0,0,0,0,0,0,
	@roleid, 0, 0, 0, 0, 0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,@closed)
	
	if @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		select @ErrMsg = case @Language 
							when 'E' then 'Add customer failed.'
							when 'CS' then N'Add customer failed.'
							when 'J' then N'Add customer failed.'
							else N'Add customer failed.'
						end, @ErrCode = 103	
		return
	END

COMMIT TRANSACTION 	

EXEC db03.bodb02.dbo.Acc_Con_AdminPolicyIns_1 @CustID=@Custid,@Userid=@UserID,@GroupID=@GroupID, @System = @System


DECLARE @LogData nvarchar(200)
SELECT @LogData = 'NEW ' + @System + ' Admin custid:' + convert(varchar(20), @custid) + ' username:' + @UserName + ' GroupID:' + convert(varchar(20),@GroupID)
EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminIns] TO [vnteam]