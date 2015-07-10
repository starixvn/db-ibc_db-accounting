USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[DBA_MNLBackupSPs_ALL]    Script Date: 12/13/2012 03:26:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_MNLBackupSPs_ALL] 
AS
/*
	DB: DB02.bodb02
	Creator : Viet
	Date : 6 Feb 2010
	Task : Generate script for all SPs belong to accounting, agent and affiliate site.
	History:
		- 20121213@Dan: Change linked server from DB052-->DBEXT, DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET	 
		
*/

SET NOCOUNT ON

EXEC dbo.DBA_MNLBackupSPs
EXEC DB03.bodb02.dbo.DBA_MNLBackupSPs
EXEC DB03.on_user.dbo.DBA_MNLBackupSPs
EXEC DBEXT.bodb02.dbo.DBA_MNLBackupSPs
EXEC DBLOG.bodb_CustomerLog.dbo.DBA_MNLBackupSPs
EXEC DBEXT.bodb_Maintenance.dbo.DBA_MNLBackupSPs
EXEC DBAFF12BET.Affiliate_12bet.dbo.DBA_MNLBackupSPs
EXEC DB06.bodb02.dbo.DBA_MNLBackupSPs


