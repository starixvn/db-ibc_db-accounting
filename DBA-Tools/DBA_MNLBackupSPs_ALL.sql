ALTER PROCEDURE [dbo].[DBA_MNLBackupSPs_ALL] 
AS
/*
	DB: DB02.bodb02
	Creator : Viet
	Date : 6 Feb 2010
	Task : Generate script for all SPs belong to accounting, agent and affiliate site.
	History:
		
*/

SET NOCOUNT ON

EXEC dbo.DBA_MNLBackupSPs
EXEC DB03.bodb02.dbo.DBA_MNLBackupSPs
EXEC DB03.on_user.dbo.DBA_MNLBackupSPs
EXEC DB052.bodb02.dbo.DBA_MNLBackupSPs
EXEC DB052.bodb_CustomerLog.dbo.DBA_MNLBackupSPs
EXEC DB052.bodb_Maintenance.dbo.DBA_MNLBackupSPs
EXEC DB052.Affiliate_12bet.dbo.DBA_MNLBackupSPs
EXEC DB06.bodb02.dbo.DBA_MNLBackupSPs


GO
GRANT VIEW DEFINITION ON [dbo].[DBA_MNLBackupSPs_ALL] TO [vnteam]