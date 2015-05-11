ALTER Procedure [dbo].[ExecRep_07]	
	@UserName varchar(30)
AS

Declare @RoleID int, @CustID int

SELECT @RoleID=roleid, @CustID=custid FROM CustInfo with (nolock) WHERE username=@UserName

IF @RoleID=4
	UPDATE CustInfo with (ROWLOCK, UPDLOCK) set SyncCasino=1, DisableCasino=0 WHERE SyncCasino=0 and srecommend=@CustID
	
ELSE IF @RoleID=3
	UPDATE CustInfo with (ROWLOCK, UPDLOCK) set SyncCasino=1, DisableCasino=0 WHERE SyncCasino=0 and mrecommend=@CustID
	
ELSE IF @RoleID=2
	UPDATE CustInfo with (ROWLOCK, UPDLOCK) set SyncCasino=1, DisableCasino=0 WHERE SyncCasino=0 and recommend=@CustID
	
ELSE
	UPDATE CustInfo with (ROWLOCK, UPDLOCK) set SyncCasino=1, DisableCasino=0 WHERE SyncCasino=0 and custid=@CustID

GO
GRANT VIEW DEFINITION ON [dbo].[ExecRep_07] TO [ITTim]
GO
GRANT VIEW DEFINITION ON [dbo].[ExecRep_07] TO [ITVivi]