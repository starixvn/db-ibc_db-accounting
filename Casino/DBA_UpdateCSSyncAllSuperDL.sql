ALTER Procedure [dbo].[ExecRep_07]	
	@UserName varchar(30),
	@MaxCustid int,
	@SyncCasino bit =0,
	@DisableCasino bit = 1
AS

if NOT exists (select * from dbo.sysobjects where name = 'custinfo')
BEGIN
	RETURN
END

Declare @RoleID int, @CustID int

SELECT @RoleID=roleid, @CustID=custid
FROM CustInfo with (nolock)
WHERE username=@UserName
    and Enabled = 1
    and closed=0

IF (@roleid not in (4,3,2,1)) 
    RETURN
    
IF @RoleID=4
	UPDATE CustInfo with (ROWLOCK, UPDLOCK) set SyncCasino=@SyncCasino, DisableCasino=@DisableCasino
	WHERE srecommend=@CustID 
	    and SyncCasino = 0
	    and Enabled = 1
	    and closed=0
	    and custid <= @MaxCustid	    
	
ELSE IF @RoleID=3
	UPDATE CustInfo with (ROWLOCK, UPDLOCK) set SyncCasino=@SyncCasino, DisableCasino=@DisableCasino
	WHERE mrecommend=@CustID 
	    and SyncCasino = 0
	    and Enabled = 1	  
	    and closed=0 
	    and custid <= @MaxCustid 
	
ELSE IF @RoleID=2
	UPDATE CustInfo with (ROWLOCK, UPDLOCK) set SyncCasino=@SyncCasino, DisableCasino=@DisableCasino
	WHERE recommend=@CustID 
	    and SyncCasino = 0
	    and Enabled = 1	 
	    and closed=0
	    and custid <= @MaxCustid   
	
ELSE
	UPDATE CustInfo with (ROWLOCK, UPDLOCK) set SyncCasino=@SyncCasino, DisableCasino=@DisableCasino
	WHERE custid=@CustID 
	    and SyncCasino = 0
	    and Enabled = 1
	    and closed=0
	    and custid <= @MaxCustid