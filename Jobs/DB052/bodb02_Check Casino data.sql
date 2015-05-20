/*
	Created by: 
	Date: 
	DB: DB052.bodb02
	Task: Check data synchronization between IBC DB & Casino DB
	Job Name: Check Casino's data
	Schedule: Occurs every day at 12:00 AM
*/  

USE [msdb]
GO
/****** Object:  Job [Check Casino's data]    Script Date: 05/05/2011 00:26:01 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/05/2011 00:26:01 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Check Casino''s data', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'thien', 
		@notify_email_operator_name=N'Viet', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [run job]    Script Date: 05/05/2011 00:26:01 ******/
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
		@command=N'DECLARE @ErrCode int, @ErrMsg nvarchar(3000), @Cnt int
SELECT @ErrCode = 0, @ErrMsg = '''', @Cnt = 0

SELECT @Cnt = count(1)
FROM CustInfo WITH (nolock)
WHERE Custid not in (SELECT isnull(IBCCustid,0) FROM DBCasino.CasinoAdmin.dbo.Customer WITH (nolock))
	and SyncCasino=1
	and currency<>20
	and enabled=1
IF @Cnt > 0
BEGIN
	SELECT @ErrMsg = @ErrMsg + ''+ SyncCasino=1 in IBC DB and does not exist in Casino DB (''+ cast(@Cnt as varchar(5)) +'' rows); ''
	SELECT @ErrCode = 101
END

SELECT @Cnt = count(1) FROM CustInfo ibc WITH (nolock)
	INNER join DBCasino.CasinoAdmin.dbo.Customer cas WITH (nolock)
	ON ibc.custid = cas.IBCCustID
WHERE ibc.enabled=1
	and ibc.currency<>20
	and ibc.DisableCasino=0
	and ibc.SyncCasino=1
	and cas.EnableCasino=0
IF @Cnt>0
BEGIN
	SELECT @ErrMsg = @ErrMsg + ''+ Enable in IBC DB but Disable in Casino DB (''+ cast(@Cnt as varchar(5)) +'' rows); ''
	SELECT @ErrCode = 101
END


SELECT @Cnt = count(1) FROM CustInfo ibc WITH (nolock)
	INNER join DBCasino.CasinoAdmin.dbo.Customer cas WITH (nolock)
	ON ibc.custid = cas.IBCCustID
WHERE ibc.enabled=1
	and ibc.currency<>20
	and ibc.DisableCasino = 1
	and ibc.SyncCasino = 1
	and cas.EnableCasino=1
IF @Cnt > 0
BEGIN
	SELECT @ErrMsg = @ErrMsg + ''+ Disable in IBC DB but Enable in Casino DB (''+ cast(@Cnt as varchar(5)) +'' rows); ''
	SELECT @ErrCode = 101
END

SELECT @Cnt = count(1) FROM custinfo ibc WITH (nolock)
		INNER join DBCASINO.CasinoAdmin.dbo.customer cas WITH (nolock) ON ibc.custid = cas.ibccustid
	WHERE ibc.closed = 0
		and cas.isfrozen=1
		and ibc.synccasino=1
		and ibc.enabled=1
		and ibc.currency <> 20
IF @cnt > 0
BEGIN
	SELECT @ErrMsg = @ErrMsg + ''+ Opened in IBC DB but Closed in Casino DB (''+ cast(@Cnt as varchar(5)) +'' rows); ''
	SELECT @ErrCode = 101
END

--select @ErrCode, @ErrMsg
IF @ErrCode <> 0
RAISERROR(@ErrMsg,16,1)', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'everyday at 12AM', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20100723, 
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
