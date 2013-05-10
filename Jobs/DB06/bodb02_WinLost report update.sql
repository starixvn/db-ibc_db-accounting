/*
	Created by: 
	Date: 
	DB: DB06.bodb02
	Task: insert data into rptWinlost & rptDepWinlost table
	Job Name: bodb02 : bodb02 : WinLost report update
	Schedule: Occurs every 2 hours
	
*/  

USE [msdb]
GO
/****** Object:  Job [bodb02 : WinLost report update]    Script Date: 05/06/2011 08:16:26 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/06/2011 08:16:26 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'bodb02 : WinLost report update', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Viet', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Cal Job]    Script Date: 05/06/2011 08:16:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Cal Job', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @Hour int
Declare @Today smalldatetime
Declare @Yesterday smalldatetime
Declare @Earlyday smalldatetime

SELECT
	@Hour = DATEPART(hour, CURRENT_TIMESTAMP),
	@Today = CONVERT(nvarchar(10), CURRENT_TIMESTAMP, 120),
	@Yesterday = DATEADD(day, -1, @Today),
	@Earlyday = DATEADD(day, -2, @Today)


select @hour , @today, @yesterday

IF @Hour < 12
BEGIN
	EXEC dbo.Task_rptWinLost_UpdateTable @Today
	EXEC dbo.Task_rptWinLost_UpdateTable @Yesterday
	EXEC dbo.Task_rptWinLost_UpdateTable @Earlyday


	EXEC dbo.Task_DOT_Dep_DailySummary @Today
	EXEC dbo.Task_DOT_Dep_DailySummary @Yesterday
	EXEC dbo.Task_DOT_Dep_DailySummary @Earlyday
END
ELSE
BEGIN
	EXEC dbo.Task_rptWinLost_UpdateTable @Today
	EXEC dbo.Task_DOT_Dep_DailySummary @Today
END
', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 2 Hours', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=2, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20070130, 
		@active_end_date=99991231, 
		@active_start_time=430, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
