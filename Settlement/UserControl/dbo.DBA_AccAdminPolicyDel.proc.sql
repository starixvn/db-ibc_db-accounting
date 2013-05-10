ALTER PROCEDURE dbo.DBA_AccAdminPolicyDel
	@CustID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

BEGIN TRANSACTION
DELETE FROM Acc_MemberPolicy WHERE Custid=@Custid
DELETE FROM AccCustomer WHERE Custid = @Custid
IF  @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	select @ErrMsg = N'Error occurs.Delete unsuccessfully.',@ErrCode = 101
	RETURN
END
COMMIT TRANSACTION
