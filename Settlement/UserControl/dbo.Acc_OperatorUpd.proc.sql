ALTER PROCEDURE dbo.Acc_OperatorUpd
	@custid int,
	@firstname nvarchar(50),
	@lastname nvarchar(50),
	@address nvarchar(80),
	@state nvarchar(50),
	@country nvarchar(50),
	@phone nvarchar(50),
	@mobilephone nvarchar(50),
	@fax nvarchar(50),
	@email nvarchar(50),
	@roleid int,
	@postal nvarchar(50),
	@city nvarchar(50),
	@UserID int = 0,
	@ReturnErrCode bit = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
BEGIN
	IF @ReturnErrCode = 0
		RAISERROR (@ErrMsg, 16, 1)
	RETURN
END
--end
UPDATE Customer with (ROWLOCK, UPDLOCK) SET 
		firstname=@firstname, 
		lastname=@lastname, 
		address=@address, 
		state=@state, 
		country=@country, 
		phone=@phone, 
		mobilephone=@mobilephone, 
		fax=@fax, 
		email=@email, 
		roleid=@roleid,
		postal = @postal,
		city = @city
WHERE custid=@custid

declare @LogData nvarchar(200)

Select @LogData = 
	'Update operator:' + convert(varchar(10), @custID)
EXEC WriteLog_UserLog @UserID = @userID, @Doing = @LogData


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

GRANT  EXECUTE  ON [dbo].[Acc_OperatorUpd]  TO [bodbAdminNet]
GO

