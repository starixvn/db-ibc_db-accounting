/*<info serverAlias="DBCUST-CustDB"></info>*/
/*
	Created: 20210301@Percy
	DB: DBCUST-msdb
	Task: Add job to clean up data
*/

USE [msdb]
GO

EXEC dbo.sp_add_job
		@job_name=N'NAP_UserControl: Daily Auto Clean Up Headline Group Mapping',
		@enabled=1,
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N'No description available.',
		@category_name=N'[Uncategorized (Local)]',
		@owner_login_name=N'sa'

EXEC dbo.sp_add_jobstep
		@job_name=N'NAP_UserControl: Daily Auto Clean Up Headline Group Mapping',
		@step_name=N'Clean Up Data',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0,
		@subsystem=N'TSQL',
		@command=N'EXEC dbo.Task_Acc_CustGroup_Queue_Del',
		@database_name=N'NAP_UserControl',
		@flags=0
EXEC dbo.sp_update_job
		@job_name=N'NAP_UserControl: Daily Auto Clean Up Headline Group Mapping',
		@start_step_id = 1
EXEC dbo.sp_add_jobschedule
		@job_name=N'NAP_UserControl: Daily Auto Clean Up Headline Group Mapping',
		@name=N'Schedule Auto Migrate Data ProblemAccount',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=1,
		@freq_subday_interval=0,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20210611,
		@active_end_date=99991231,
		@active_start_time=500,
		@active_end_time=235959
EXEC dbo.sp_add_jobserver
		@job_name=N'NAP_UserControl: Daily Auto Clean Up Headline Group Mapping',
		@server_name = N'(local)'