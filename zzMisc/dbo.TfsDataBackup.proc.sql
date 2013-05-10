CREATE PROCEDURE [dbo].[TfsDataBackup]
-- Backup script for Team Foundation Server
-- viet.hoang@20081002
-- Always exist 7 files (T1: sunday, T2: Monday,... T7: saturday) in backup folder
AS
Declare @Date nvarchar(50)
Set @Date = 
CAST(DATEPART(year, CURRENT_TIMESTAMP) as nvarchar) + 
CASE WHEN DATEPART(month, CURRENT_TIMESTAMP) < 10 THEN '0' + CAST(DATEPART(month, CURRENT_TIMESTAMP) as nvarchar) ELSE CAST(DATEPART(month, CURRENT_TIMESTAMP) as nvarchar) END + 
CASE WHEN DATEPART(day, CURRENT_TIMESTAMP)   < 10 THEN '0' + CAST(DATEPART(day, CURRENT_TIMESTAMP) as nvarchar)   ELSE CAST(DATEPART(day, CURRENT_TIMESTAMP) as nvarchar) END

Declare @DBName_BK nvarchar(200)
Declare @FileName nvarchar(200)  
Set @FileName = N'E:\_backup\TfsDataBackup-T' + CAST(DATEPART(weekday, CURRENT_TIMESTAMP) as nvarchar) + '.bak'  

SELECT @DBName_BK =N'ReportServer_backup_' + @Date
BACKUP DATABASE [ReportServer] TO  DISK = @FileName WITH NOFORMAT, INIT,  NAME = @DBName_BK, SKIP, REWIND, NOUNLOAD,  STATS = 10

SELECT @DBName_BK =N'ReportServerTempDB_backup_' + @Date
BACKUP DATABASE [ReportServerTempDB] TO  DISK = @FileName WITH NOFORMAT, NOINIT,  NAME = @DBName_BK, SKIP, REWIND, NOUNLOAD,  STATS = 10

SELECT @DBName_BK =N'STS_Config_TFS_backup_' + @Date
BACKUP DATABASE [STS_Config_TFS] TO  DISK = @FileName WITH NOFORMAT, NOINIT,  NAME = @DBName_BK, SKIP, REWIND, NOUNLOAD,  STATS = 10

SELECT @DBName_BK =N'STS_Content_TFS_backup_' + @Date
BACKUP DATABASE [STS_Content_TFS] TO  DISK = @FileName WITH NOFORMAT, NOINIT,  NAME = @DBName_BK, SKIP, REWIND, NOUNLOAD,  STATS = 10

SELECT @DBName_BK =N'TfsActivityLogging_backup_' + @Date
BACKUP DATABASE [TfsActivityLogging] TO  DISK = @FileName WITH NOFORMAT, NOINIT,  NAME = @DBName_BK, SKIP, REWIND, NOUNLOAD,  STATS = 10

SELECT @DBName_BK =N'TfsBuild_backup_' + @Date
BACKUP DATABASE [TfsBuild] TO  DISK = @FileName WITH NOFORMAT, NOINIT,  NAME = @DBName_BK, SKIP, REWIND, NOUNLOAD,  STATS = 10

SELECT @DBName_BK =N'TfsIntegration_backup_' + @Date
BACKUP DATABASE [TfsIntegration] TO  DISK = @FileName WITH NOFORMAT, NOINIT,  NAME = @DBName_BK, SKIP, REWIND, NOUNLOAD,  STATS = 10

SELECT @DBName_BK =N'TfsVersionControl_backup_' + @Date
BACKUP DATABASE [TfsVersionControl] TO  DISK = @FileName WITH NOFORMAT, NOINIT,  NAME = @DBName_BK, SKIP, REWIND, NOUNLOAD,  STATS = 10

SELECT @DBName_BK =N'TFSWarehouse_backup_' + @Date
BACKUP DATABASE [TFSWarehouse] TO  DISK = @FileName WITH NOFORMAT, NOINIT,  NAME = @DBName_BK, SKIP, REWIND, NOUNLOAD,  STATS = 10

SELECT @DBName_BK =N'TfsWorkItemTracking_backup_' + @Date
BACKUP DATABASE [TfsWorkItemTracking] TO  DISK = @FileName WITH NOFORMAT, NOINIT,  NAME = @DBName_BK, SKIP, REWIND, NOUNLOAD,  STATS = 10

SELECT @DBName_BK =N'TfsWorkItemTrackingAttachments_backup_' + @Date
BACKUP DATABASE [TfsWorkItemTrackingAttachments] TO  DISK = @FileName WITH NOFORMAT, NOINIT,  NAME = @DBName_BK, SKIP, REWIND, NOUNLOAD,  STATS = 10
GO