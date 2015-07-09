CREATE PROCEDURE [dbo].[DBA_UpdSyncCSIBC]
	@UserName varchar(30)
AS
/*
Created: 20090704@Hanh
Task : Select customer's status
DB: DBTRANS.bodb02

Param's Explanation:
• @UserName customer id.   
*/
SET NOCOUNT ON

	Update CustInfo with (ROWLOCK, UPDLOCK) set SyncCasino=1 where username=@UserName
	
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_UpdSyncCSIBC] TO [vnteam]
GRANT EXECUTE ON [dbo].[DBA_UpdSyncCSIBC] TO [vnteam]