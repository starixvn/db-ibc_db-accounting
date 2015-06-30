   /*
	Created by: 
	Date: 
	DB: DB06.bodb_Report
	Task: archive rptDepWinlost
	Job Name: Monthly archive rptdepwinlost
	Schedule: Occurs every month on day 1 at 12:00:00 AM.
	
*/
 USE [msdb]
GO
/****** Object:  Job [Monthly archive rptdepwinlost]    Script Date: 05/06/2011 08:52:09 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/06/2011 08:52:09 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monthly archive rptdepwinlost', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'thien', 
		@notify_email_operator_name=N'DBAAdmin', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [run job]    Script Date: 05/06/2011 08:52:10 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run job', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @winlostdate SMALLDATETIME, @todate SMALLDATETIME -- first day of last month
SELECT @todate = CONVERT(VARCHAR(10),DATEADD(mm, DATEDIFF(m,0,CURRENT_TIMESTAMP)-1,0), 120)
SELECT @winlostdate = MIN(winlostdate) FROM rptDepWinlost WITH(nolock)

WHILE (@winlostdate < @todate)
BEGIN
    INSERT INTO [rptDepWinlost_bk] (
        [winlostdate],
        [custid],
        [currency],
        [OpeningBalance],
        [Deposit],
        [Withdrawal],
        [Aff2MemTransfer],
        [Bonus],
        [Adjustment],
        [Turnover],
        [Outstanding],
        [Winloss],
        [ClosingBalance],
        [recommend],
        [mrecommend],
        [srecommend],
        [actualrate],
        [Transfer3rd],
        [DrawGame]
    )
    SELECT [winlostdate],
        [custid],
        [currency],
        [OpeningBalance],
        [Deposit],
        [Withdrawal],
        [Aff2MemTransfer],
        [Bonus],
        [Adjustment],
        [Turnover],
        [Outstanding],
        [Winloss],
        [ClosingBalance],
        [recommend],
        [mrecommend],
        [srecommend],
        [actualrate],
        [Transfer3rd],
        [DrawGame]
    FROM rptDepWinlost WITH(nolock)
    WHERE WINLOSTDATE = @winlostdate

    DELETE FROM rptDepWinlost WITH(rowlock) WHERE Winlostdate = @winlostdate
    --WAITFOR DELAY ''000:00:01''
    SELECT @winlostdate = DATEADD(dd, 1, @winlostdate)
END', 
		@database_name=N'bodb_Report', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'once every month', 
		@enabled=1, 
		@freq_type=16, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20100122, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
