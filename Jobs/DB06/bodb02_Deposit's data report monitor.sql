
/*
	Created by: 
	Date: 
	DB: DB06.bodb02
	Task: check member balance in bodb_report.dbo.rptdepwinlost
	Job Name: bodb02 : Deposit's data report monitor
	Schedule: Occurs every day at 4:00:00 AM.
	
*/  

USE [msdb]
GO
/****** Object:  Job [bodb02 : Deposit's data report monitor]    Script Date: 05/06/2011 08:07:17 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/06/2011 08:07:17 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'bodb02 : Deposit''s data report monitor', 
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
/****** Object:  Step [xxx]    Script Date: 05/06/2011 08:07:17 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'xxx', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @Today SMALLDATETIME, @d SMALLDATETIME
DECLARE @ErrMsg varchar(1000), @ErrCode int

SELECT @ErrCode = 0, @ErrMsg = ''''

SELECT @d = dateadd(dd, -7, DATEDIFF(dd,0,CURRENT_TIMESTAMP))
SELECT @Today = CONVERT(nvarchar(10), CURRENT_TIMESTAMP, 120)
WHILE (@d < @today)
BEGIN	
	IF NOT EXISTS(select top 1 1 from bodb_report.dbo.rptdepwinlost with(nolock) where winlostdate = @d)
	BEGIN
		SELECT @ErrMsg = @ErrMsg + case when @ErrCode=0 then ''Balance not tally at: '' else ''; '' end + convert(varchar(11), @d, 106)
		SELECT @ErrCode = 101
	END
	ELSE IF EXISTS (
		select 1    
		FROM    
		(     
		select custid, isnull(closingbalance,0) closingbalance, currency    
		from bodb_report.dbo.rptdepwinlost with(nolock)    
		where winlostdate = @d    
		) r1    
		INNER JOIN    
		(    
		select custid, isnull(openingbalance,0) openingbalance    
		from bodb_report.dbo.rptdepwinlost with(nolock)    
		where winlostdate = dateadd(dd,1,@d)    
		) r2 on r1.custid = r2.custid     
		where r1.closingbalance <> r2.openingbalance
	)   
	BEGIN
		SELECT @ErrMsg = @ErrMsg + case when @ErrCode=0 then ''Balance not tally at: '' else ''; '' end + convert(varchar(11), @d, 106)
		SELECT @ErrCode = 101
	END
	
	--select @d, @ErrCode, @ErrMsg
	SELECT @d = dateadd(dd, 1, @d)

END
select @ErrCode, @ErrMsg
IF @ErrCode <> 0
RAISERROR(@ErrMsg,16,1)', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Occurs every day at 4:00:00 AM', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20091222, 
		@active_end_date=99991231, 
		@active_start_time=40000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
