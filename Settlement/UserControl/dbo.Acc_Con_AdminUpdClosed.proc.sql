ALTER PROCEDURE [dbo].[Acc_Con_AdminUpdClosed]
	@CustID int,
	@Closed bit,
	@UserID int,
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@System varchar(50)='ACCOUNTING'
AS
/*
Created: 
Task : 
DB: DB02.BODB02
Original:

Revisions:
	- 20100108@Daniel: Add reset logincount when open account
Param's Explanation:

*/

SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UserControl]',@System=@System,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

DECLARE @Old_Closed bit, @LoginCount int
select @Old_Closed = closed from custinfo with (nolock) where custid = @custid
select @LoginCount = logincount from customer with (nolock) where custid = @custid

update custinfo with (ROWLOCK) set Closed = @Closed
where custid = @CustID

IF (@Old_Closed = 1 and @Closed = 0 and @LoginCount > 5)
	update customer with (ROWLOCK, UPDLOCK) set logincount = 0
	where custid = @custid


declare @LogData nvarchar(200)
Select @LogData = 'Update ' + @System + ' closed for CustID: ' + cast(@custid as varchar(20)) + ' closed: ' + case @closed when 0 then 'closed' else 'open' end
EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData






GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminUpdClosed] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminUpdClosed] TO [bodbAdminNet]