 /*
	Created by: 
	Date: 
	DB: DB06.bodb02
	Task: 
	Job Name: bodb02 : Log Digger
	Schedule: Occurs every 2 minutes
	
*/  

 USE [msdb]
GO
/****** Object:  Job [bodb02 : Log Digger]    Script Date: 05/06/2011 08:11:03 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/06/2011 08:11:03 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'bodb02 : Log Digger', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBAAdmin', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Dig data for 1 match]    Script Date: 05/06/2011 08:11:03 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Dig data for 1 match', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=2, 
		@on_fail_action=1, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @matchid int
SELECT @matchid = matchid
FROM dbo.LogQueue (nolock)
WHERE IsDone = 0

IF @@ROWCOUNT = 0
BEGIN
	DELETE FROM dbo.LogData
	WHERE matchid IN (
		SELECT matchid FROM dbo.LogQueue
		WHERE FinishTime < DATEADD(hour, -2, CURRENT_TIMESTAMP)
	)
	DELETE FROM dbo.LogQueue
	WHERE FinishTime < DATEADD(hour, -2, CURRENT_TIMESTAMP)

	RAISERROR (''No more Match to Dig.'', 16, 1)
	RETURN
END

UPDATE dbo.LogQueue
SET IsRunning = 1, StartTime = CURRENT_TIMESTAMP
WHERE matchid = @matchid

EXEC dbo.Admin_Tools_MatchLog
	@matchid, 1

UPDATE dbo.LogQueue
SET IsRunning = 0, IsDone = 1, FinishTime = CURRENT_TIMESTAMP
WHERE matchid = @matchid
', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Loop until Error]    Script Date: 05/06/2011 08:11:03 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Loop until Error', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=1, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'WAITFOR DELAY ''000:00:05''', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'1 minute check', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=2, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20071023, 
		@active_end_date=99991231, 
		@active_start_time=45, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
