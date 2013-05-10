ALTER PROCEDURE [dbo].[DBA_LicenseeCustomerDel]
	@custid INT,
	@roleid INT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg varchar(200) = '' OUTPUT
AS
/*
Created: 
Task : Delete Licensee Customer
DB: DB052.bodb_licensee
Original:

Revisions:
	
Param's Explanation:
	@username: pass the username of customer you want to delete.
*/		
IF @roleid = 2
BEGIN
	DELETE LicenseeCust WHERE custid = @custid
	IF @@ERROR <> 0
	BEGIN		
		select @ErrMsg = N'Delete Licensee Customer failed.', @ErrCode = 100
		RETURN
	END
END
IF @roleid = 1
BEGIN
	DELETE LicenseeCustComm WHERE custid = @custid
	DELETE LicenseeCustInfo WHERE custid = @custid
	DELETE LicenseeSpecialCust WHERE custid = @custid
	IF @@ERROR <> 0
	BEGIN
		select @ErrMsg = N'Delete Licensee Customer failed.', @ErrCode = 101
		RETURN
	END
END