ALTER PROCEDURE dbo.Acc_OperatorDel
	@CustID int, 
	@Language varchar(2) = 'E',
	@UserID int = 0,
	@ReturnErrCode bit = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
SET NOCOUNT ON
--Original: DelOperator.asp

--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
BEGIN
	IF @ReturnErrCode = 0
		RAISERROR (@ErrMsg, 16, 1)
	RETURN
END
--end

-------------------
--Thien@20080223: Not allow to delete operator since it's related to User Control in Admin.NET
select @ErrMsg = 'Not allow to delete operator here! Please contact Thien''s team for information!', @ErrCode = 100
RETURN
-------------------

delete Customer with (ROWLOCK) where CustID = @CustID

delete CustInfo with (ROWLOCK) where CustID = @CustID

declare @LogData nvarchar(200)

Select @LogData = 'Delete Operator Custid:' + convert(varchar(10), @CustID) 
EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

GRANT  EXECUTE  ON [dbo].[Acc_OperatorDel]  TO [bodbAdminNet]
GO

