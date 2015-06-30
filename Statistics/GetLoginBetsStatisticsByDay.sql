--Create table
/*
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TempLoginByDay](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[LoginDate] [smalldatetime] NOT NULL,
	[Site] [varchar](20) NULL,
	[IsWap] [bit] NULL,
	[NoOfLogin] [int] NULL,
 CONSTRAINT [PK_LoginByDay] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
SET ANSI_PADDING OFF
GO



USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TempBetsReport_Wap](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Date] [smalldatetime] NULL,
	[NoOfBets] [int] NULL,
	[Amt] [money] NULL,
	[Site] [varchar](10) NULL,
	[BetFrom] [nvarchar](1) NULL,
 CONSTRAINT [PK_TempBetsReport_Wap] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
SET ANSI_PADDING OFF
*/

--Create job
USE [msdb]
GO
/****** Object:  Job [bodb02 : GetLoginBetsStatisticsByDay]    Script Date: 11/06/2008 05:30:59 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 11/06/2008 05:30:59 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'bodb02 : GetLoginBetsStatisticsByDay', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [GetLoginBetsByDay-Wap]    Script Date: 11/06/2008 05:31:00 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'GetLoginBetsByDay-Wap', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @fromdate varchar(10),@todate varchar(10),@balancedate smalldatetime
select @fromdate = convert(varchar(10),dateadd(day,-2,getdate()), 120),
	@todate = convert(varchar(10),dateadd(day,1,@fromdate),120)

---------------------------------------------------------------------------------------------------------
-- Login
--If had data already 

if not exists (select 1 from TempLoginByDay with(nolock) where convert(varchar(10),logindate,120) = @fromdate)
Begin

	--Get Data
	Truncate table tempLogins

	INSERT INTO tempLogins (CustID, LoginDate, IsWap)
	select  userID custid, convert(varchar(10),logdate, 120) LoginDate,
	case when doing like ''%WAP:%'' then 1 else 0 end IsWap
	 from userlog (nolock) where
		(doing like ''%Success SID:%'' 
		or doing like ''%Result:Success ServerID:%'')
		and logdate >= @fromdate and logdate < @todate


	Update tempLogins set Site = ag.Site
	from tempLogins T
		inner join custinfo c (nolock) on T.Custid = c.custid
		inner join customer ag (nolock) on Ag.custid = c.recommend
	where c.RoleID = 1

	----------------
	insert into TempLoginByDay(LoginDate,Site,IsWap,NoOfLogin)
	select  LoginDate, 
	case when site NOT in (''12Bet'', ''asiabet88'') then ''IBC'' else site end as Site, IsWap 
	, count(*) as NoOfLogin
	from tempLogins (nolock)
	group by LoginDate, case when site NOT in (''12Bet'', ''asiabet88'') then ''IBC'' else site end, IsWap
	--order by logindate, 
	--2, isWap
END

---------------------------------------------------------------------------------------------------------
-- Bets
if not exists (select 1 from TempBetsReport_Wap with(nolock) where convert(varchar(10),date,120) = @fromdate)
Begin
	select @balancedate = max(winlostdate) from bettrans14 with(nolock) 
	if @fromdate > @balancedate
	begin
		--bettrans
		insert into TempBetsReport_Wap(date,site,noofbets,amt,betfrom)	
		select convert(varchar(10),b.transdate,120) as date, ag.site,
		count(b.transid) as noofbets,sum(b.stake*b.actualrate) as amt,b.betfrom
		from bettrans b (nolock) inner join bodb02.dbo.custinfo c (nolock) on b.custid=c.custid
		inner join bodb02.dbo.customer ag (nolock) on c.recommend=ag.custid
		where b.betfrom in (''m'',''w'') and b.bettype < 99 and b.transdate >= @fromdate and b.transdate < @todate
		group by ag.site,convert(varchar(10),b.transdate,120),b.betfrom
		order by ag.site
	end
	else
	begin
		--bettrans14
		insert into TempBetsReport_Wap(date,site,noofbets,amt,betfrom)	
		select convert(varchar(10),b.transdate,120) as date, ag.site,
		count(b.transid) as noofbets,sum(b.stake*b.actualrate) as amt,b.betfrom
		from bettrans14 b (nolock) inner join bodb02.dbo.custinfo c (nolock) on b.custid=c.custid
		inner join bodb02.dbo.customer ag (nolock) on c.recommend=ag.custid
		where b.betfrom in (''m'',''w'') and b.bettype < 99 and b.transdate >= @fromdate and b.transdate < @todate
		group by ag.site,convert(varchar(10),b.transdate,120),b.betfrom
		order by ag.site
	end
End


', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'GetLoginBetsByDay', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20081101, 
		@active_end_date=99991231, 
		@active_start_time=170000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
