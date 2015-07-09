ALTER Procedure [dbo].[DBA_CustomerSelNoneSyncCS]
	@UserName varchar(30)
AS
/*
Created: 20090919
Task : Select all customers does not sync Casino
DB: DB052.bodb02

Param's Explanation:
• @UserName customer id.   
*/

Declare @RoleID int, @CustID int

SELECT @RoleID=	roleid, @CustID=custid FROM CustInfo with (nolock) WHERE username=@UserName

IF @RoleID=4
	SELECT Custid,Username FROM CustInfo with (nolock) WHERE SyncCasino=0 and srecommend=@CustID and Enabled = 1
	
ELSE IF @RoleID=3
	SELECT Custid,Username FROM CustInfo with (nolock) WHERE SyncCasino=0 and mrecommend=@CustID and Enabled = 1
	
ELSE IF @RoleID=2
	SELECT Custid,Username FROM CustInfo with (nolock) WHERE SyncCasino=0 and recommend=@CustID and Enabled = 1
	
ELSE
	SELECT Custid,Username FROM CustInfo with (nolock) WHERE SyncCasino=0 and CustID=@CustID and Enabled = 1
	
GO
GRANT EXECUTE ON [dbo].[DBA_CustomerSelNoneSyncCS] TO [CasinoTeam]
GRANT VIEW DEFINITION ON [dbo].[DBA_CustomerSelNoneSyncCS] TO [vnTeam]

