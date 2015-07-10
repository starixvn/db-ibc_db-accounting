/*
	Created by: 
	Date: 
	DB: DB052.on_user
	Task: 
	Job Name: on_user : FIND UNUSED SP
	Schedule: Occurs every day every 20 minute(s) 
	
*/  

USE [msdb]
GO
/****** Object:  Job [on_user : FIND UNUSED SP]    Script Date: 05/09/2011 05:27:50 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/09/2011 05:27:50 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'on_user : FIND UNUSED SP', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [xxx]    Script Date: 05/09/2011 05:27:50 ******/
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
		@command=N'declare @dbnm varchar(50), @seq_id int

set @dbnm = db_name()
select @seq_id = max(seq_id) from dbo.MONIT_ObjectRecompilation

set @seq_id = ISNULL(@seq_id,0) + 1

Declare @XXX TABLE (obj_nm varchar(200), obj_id int, obj_type varchar(2))
insert into @XXX
select so.name, so.id, so.type
from dbo.sysobjects so
where so.id NOT IN (
	SELECT so.id
	FROM dbo.sysobjects so
	inner join (
		select DISTINCT sc.objid [objid] from master.dbo.SYSCACHEOBJECTS sc
			   --on sc.objid = so.id
		   left join master.dbo.sysdatabases sd
			  on sd.dbid = sc.dbid and sd.name = ''ON_USER''
		) X ON so.id = X.objid
	WHERE so.type  in (''P'', ''FN'', ''TR'', ''TF'')
	)

insert into dbo.MONIT_ObjectRecompilation (SEQ_ID, DB_NM, Object_NM, objectID, Object_Type, Status)
SELECT @seq_id, @dbnm, *, ''S'' FROM @XXX WHERE obj_type in (''P'', ''FN'', ''TR'', ''TF'')

/* select @seq_id, @dbnm, so.name, so.id, so.type, ''S''  
 from dbo.sysobjects so
   left join master.dbo.SYSCACHEOBJECTS sc 
	   on sc.objid = so.id
   left join master.dbo.sysdatabases sd
      on sd.dbid = sc.dbid and sd.name = @dbnm
 where so.type  in (''P'', ''FN'', ''TR'', ''TF'')
 and sc.objid is null
*/

/*
declare @seq_id int
 
select @seq_id = max(seq_id)  from #MONIT_ObjectRecompilation

select  DB_NM, Object_NM, objectID, Object_Type, Status, count(*)   
 from #MONIT_ObjectRecompilation mor
 where mor.status = ''S'' 
 group by DB_NM, Object_NM, objectID, Object_Type, Status    
 having count(*) =  (@seq_id - 1)
*/', 
		@database_name=N'ON_USER', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'xxx', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=20, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20080911, 
		@active_end_date=99991231, 
		@active_start_time=2100, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
