ALTER PROCEDURE [dbo].[DBA_AccAdminDel]
	@InputUser varchar(30),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
Declare @Custid int
if isnumeric(@InputUser) = 0
BEGIN
	select @custid = custid from customer with (nolock) where username = @InputUser
END
else
BEGIN
	select @custid = custid from customer with (nolock) where custid = @InputUser
END

IF Exists(Select 1 From customer c with(nolock) inner join 
			db03.bodb02.dbo.AccCustomer ac with(nolock) on c.custid=ac.custid
			where c.custid=@custid and roleid  <>6 )
BEGIN
	select @ErrMsg = N'You can not delete this admin!', @ErrCode = 102
	RETURN
END

EXEC db03.bodb02.dbo.DBA_AccAdminPolicyDel @Custid=@Custid,@Errcode=@Errcode output,@Errmsg=@Errmsg output
IF @Errcode <> 0 
	Return

BEGIN TRANSACTION
	DELETE FROM dbo.CustInfo WHERE Custid = @Custid
	DELETE FROM dbo.Customer WHERE Custid = @Custid
	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		select @ErrMsg = N'Delete Admin failed.', @ErrCode = 102
		RETURN
	END

COMMIT TRANSACTION 	
