ALTER PROCEDURE [dbo].[Acc_OperatorIns]
	@custid int OUTPUT,
	@firstname nvarchar (50),
	@lastname nvarchar (50),
	@address nvarchar (80),
	@postal nvarchar (50),
	@city nvarchar (50),
	@state nvarchar (50),
	@country nvarchar (50),
	@phone nvarchar (50),
	@mobilephone nvarchar (50),
	@fax nvarchar (50),
	@email nvarchar (50),
	@creator int,
	@username nvarchar (50),
	@userpwd nvarchar (50),
	@roleid int,
	@ReturnErrCode bit = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2) = 'E'
AS
Declare @pwdexpiry datetime
--Original: saveoperator.asp

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


SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@creator,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
BEGIN
	IF @ReturnErrCode = 0
		RAISERROR (@ErrMsg, 16, 1)
	RETURN
END
--end

if exists(select 1 from customer with (nolock) where username= @username) 
	or exists (select 1 from customer with (nolock) where username2 = @username)
	or exists(select 1 from custsub with (NOLOCK) where username= @username)
BEGIN
	SELECT @ErrMsg =  'This username is not available. ',
			@ErrCode = 101
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

select @pwdexpiry = dateadd(dd, 30, getdate())

BEGIN TRANSACTION

insert into customer (username, firstname, lastname, phone, mobilephone, fax, email, address, city, state, country, postal, userpwd, roleid, pwdexpiry, Creatdate, creator)
values (@username, @firstname, @lastname, @phone, @mobilephone, @fax, @email, @address, @city, @state, @country, @postal, @userpwd, @roleid, @pwdexpiry, getdate(), @creator)

Select @CustID = @@Identity

INSERT INTO [dbo].[custinfo](username, [custid], [currency], [MaxPerMatch], [MaxPerMatch2],[MaxPerMatch3],[MaxPerMatch5],[MaxPerMatch8],[MaxPerMatch10],[MaxPerMatch11],[MaxPerMatch12],[MaxPerMatch99],[Maxpermatch151],[maxpermatch201],[MaxPerMatch161],[MaxPerMatch99MP],[MaxPerBall161],[MaxPerMatch151_OT],    [roleid], [mrecommend], [recommend], [dangercust], [autosuspend], [reject], [credit], [closed],[MatchLimit],[VirtualMultiplier],[DisableHorseRacing],[DisableFinancial],[DisableCasino],[DisableOutright],[DisableOpenTote],[DisableBingo],[DisableNumber],[SyncCasino],[danger],[danger2],[danger3],[Enabled])
VALUES(@username, @custid, NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0,0,0,0,0,
@roleid, 0,0, 0, 0, 0, 0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1)

if @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	select @ErrMsg = case @Language 
						when 'E' then 'Add customer failed.'
						when 'CS' then N'Add customer failed.'
						when 'J' then N'Add customer failed.'
						else N'Add customer failed.'
					end		
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

COMMIT TRANSACTION

declare @LogData nvarchar(200)
Select @LogData = 'add operator:' + @UserName
EXEC WriteLog_UserLog @UserID = @Creator, @Doing = @LogData





GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

GRANT  EXECUTE  ON [dbo].[Acc_OperatorIns]  TO [bodbAdminNet]
GO

