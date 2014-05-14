--DB054

USE [msdb]
GO

/****** Object:  Job [CheckLicenseeDB: Get licensee config data from DBLIC]    Script Date: 05/06/2014 00:17:38 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/06/2014 00:17:38 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'CheckLicenseeDB: Get licensee config data from DBLIC', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Use to store licensee configuration data used for checking data consistency with custDB', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'vnDBA', 
		@notify_email_operator_name=N'Jamie', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Go]    Script Date: 05/06/2014 00:17:39 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Go', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE CheckLicenseeDB
GO
SET NOCOUNT ON

TRUNCATE TABLE dbo.[Licensees]
--TRUNCATE TABLE dbo.LicenseeBAConfig
--TRUNCATE TABLE dbo.LicenseeBAHistory
--TRUNCATE TABLE dbo.LicenseeSpecialCust	
--TRUNCATE TABLE dbo.LicenseeGroupComm
--TRUNCATE TABLE dbo.LicenseeCustComm


DECLARE @InsertDate SmallDateTime

SELECT @InsertDate=CONVERT(Varchar(10),GETDATE(),101)

INSERT INTO [dbo].[Licensees]
           ([LicenseeID]
           ,[LicenseeName]
           ,[Description]
           ,[IsDeposit]
           ,[AffectedDate]
           ,[BrandName]
           ,[CompanyName]
           ,[IsAllowedMemberComm]
		   )
SELECT [LicenseeID]
        ,[LicenseeName]
        ,[Description]
        ,[IsDeposit]
        ,[AffectedDate]
        ,[BrandName]
        ,[CompanyName]
        ,[IsAllowedMemberComm]
FROM DBLIC.bodb_licensee.dbo.[Licensees] lb WITH(NOLOCK)

INSERT INTO [dbo].LicenseeBAConfig 
	([LicenseeID]
      ,[1x2Comm]
      ,[OtherComm]
      ,[EnableBA]
      ,[ModifyBy]
      ,[ModifyDate]
      ,[groupa]
      ,[groupb]
      ,[groupc]
      ,[groupd]
	  ,[InsertDate])

SELECT [LicenseeID]
      ,[1x2Comm]
      ,[OtherComm]
      ,[EnableBA]
      ,[ModifyBy]
      ,[ModifyDate]
      ,[groupa]
      ,[groupb]
      ,[groupc]
      ,[groupd]
	  ,@InsertDate
FROM DBLIC.bodb_licensee.dbo.LicenseeBAConfig lb WITH(NOLOCK)

INSERT INTO [dbo].[LicenseeBAHistory]
           ([ID]
           ,[LicenseeID]
           ,[CustID]
           ,[OnDate]
           ,[OffDate]
           ,[OnBy]
           ,[OffBy]
           ,[GroupComm]
           ,[1x2Comm]
           ,[OtherComm]
           ,[Status]
           ,[Ugroup]
		   ,[InsertDate])
SELECT [ID]
           ,[LicenseeID]
           ,[CustID]
           ,[OnDate]
           ,[OffDate]
           ,[OnBy]
           ,[OffBy]
           ,[GroupComm]
           ,[1x2Comm]
           ,[OtherComm]
           ,[Status]
           ,[Ugroup]
		   ,@InsertDate
FROM DBLIC.bodb_licensee.dbo.[LicenseeBAHistory] lb WITH(NOLOCK)
WHERE [Status] = ''running''

INSERT INTO [dbo].[LicenseeCustComm]
           ([LicenseeID]
           ,[CustID]
           ,[SBComm]
           ,[RacingComm]
           ,[NGComm]
           ,[GroupCommID]
           ,[LCComm]
           ,[RNGComm]
		   ,[InsertDate])
SELECT [LicenseeID]
        ,[CustID]
        ,[SBComm]
        ,[RacingComm]
        ,[NGComm]
        ,[GroupCommID]
        ,[LCComm]
        ,[RNGComm]
		,@InsertDate
FROM DBLIC.bodb_licensee.dbo.[LicenseeCustComm] lb WITH(NOLOCK) 

INSERT INTO [dbo].[LicenseeGroupComm]
           ([id]
           ,[Licenseeid]
           ,[GroupName]
           ,[IsActive]
           ,[SBComm]
           ,[RacingComm]
           ,[NGComm]
           ,[color]
           ,[IsDefault]
           ,[LCComm]
           ,[RNGComm]
		   ,[InsertDate])
SELECT [id]
        ,[Licenseeid]
        ,[GroupName]
        ,[IsActive]
        ,[SBComm]
        ,[RacingComm]
        ,[NGComm]
        ,[color]
        ,[IsDefault]
        ,[LCComm]
        ,[RNGComm]
		,@InsertDate
FROM DBLIC.bodb_licensee.dbo.[LicenseeGroupComm] lb WITH(NOLOCK)

INSERT INTO [dbo].[LicenseeSpecialCust]
           ([Licenseeid]
           ,[Custid]
           ,[ugroup]
           ,[ugroup_old]
           ,[modifyby]
           ,[modifydate]
		   ,[InsertDate])
SELECT [Licenseeid]
        ,[Custid]
        ,[ugroup]
        ,[ugroup_old]
        ,[modifyby]
        ,[modifydate]
		,@InsertDate
FROM DBLIC.bodb_licensee.dbo.[LicenseeSpecialCust] lb WITH(NOLOCK)

', 
		@database_name=N'CheckLicenseeDB', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'After backup full CustDB done in DBTRANS estimately', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=127, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20140428, 
		@active_end_date=99991231, 
		@active_start_time=20500, 
		@active_end_time=235959, 
		@schedule_uid=N'ff1f3371-1687-4e1c-bcdb-61c57a5533c4'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


