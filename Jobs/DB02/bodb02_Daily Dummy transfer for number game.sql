/*
	Created by: 
	Date: 
	DB: DB02.bodb02
	Task: insert dummy transactions for number game by currency
	Job Name: bodb02: Daily Dummy transfer for number game
	Schedule: Occurs every day at 12:00:01 AM.
	
*/

USE [msdb]
GO
/****** Object:  Job [bodb02: Daily Dummy transfer for number game]    Script Date: 05/08/2011 22:46:19 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/08/2011 22:46:19 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'bodb02: Daily Dummy transfer for number game', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'thien', 
		@notify_email_operator_name=N'vnTeam', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [zzz]    Script Date: 05/08/2011 22:46:19 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'zzz', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @Today SMALLDATETIME, @Yesterday SMALLDATETIME, @Earlyday smalldatetime
DECLARE @ErrMsg varchar(1000), @ErrCode int

SELECT @Today = CONVERT(nvarchar(10), CURRENT_TIMESTAMP, 120)
SELECT @Yesterday = DATEADD(day, -1, @Today), @Earlyday = DATEADD(day, -2, @Today)
SELECT @ErrCode = 0, @ErrMsg = ''''

--- transfer for yesterday''s data
EXEC Task_DailyDummyTransfer_s161 @Yesterday

--- check data for the day before yesterday
SELECT currency,actualrate, currencyname,
	isnull(sum(winlost-actual_stake+scomm+awinlost+mwinlost+swinlost),0) winlost
FROM bettrans b with (nolock)
	inner join match m with(nolock) on b.matchid = m.matchid	
WHERE m.sporttype=161
	AND b.[statusID] NOT IN (101,102,103)
	and b.winlostdate = @Earlyday
GROUP BY b.currency,actualrate, currencyname
HAVING isnull(sum(winlost-actual_stake+scomm+awinlost+mwinlost+swinlost),0) <> 0

IF @@rowcount > 0
BEGIN
	SELECT @ErrMsg = ''NUMBER GAME - Balance didn''''t become 0 on '' + convert(varchar(11), @Earlyday, 106)
	SELECT @ErrCode = 101
END

select @ErrCode, @ErrMsg
IF @ErrCode <> 0 RAISERROR(@ErrMsg,16,1)', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Occurs every day at 12:00:01 AM', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20101217, 
		@active_end_date=99991231, 
		@active_start_time=1, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
