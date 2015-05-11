--2
--Create partition function
CREATE PARTITION FUNCTION pf_RUNSP_monthly (DATETIME) AS
RANGE LEFT FOR VALUES
(  
    
    '2008/01/31 23:59:59.997'
    
)

--Create partition schema
CREATE PARTITION SCHEME ps_RUNSP_monthly
AS PARTITION pf_RUNSP_monthly
TO
    ( 
	[RUNSP_08M01],	
	[RUNSP_MAX]
	
 )                
GO
------------------
USE [master]
GO
ALTER DATABASE [bodb_CustomerLog] ADD FILEGROUP [RUNSP_INDEX2]
GO
ALTER DATABASE [bodb_CustomerLog] ADD FILE ( NAME = N'RUNSP_INDEX_01', FILENAME = N'G:\IBC_DB\bodb_CustomerLog\RUNSP\RUNSP_INDEX_01.ndf' , SIZE = 2048KB , FILEGROWTH = 32768KB ) TO FILEGROUP [RUNSP_INDEX2]
GO
ALTER DATABASE [bodb_CustomerLog] ADD FILE 
( NAME = N'RUNSP_INDEX_05', 
FILENAME = N'G:\IBC_DB\bodb_CustomerLog\RUNSP\RUNSP_INDEX_05.ndf' , 
SIZE = 2048KB , FILEGROWTH = 32768KB ) TO FILEGROUP [RUNSP_INDEX2]
GO
------------------
USE [bodb_CustomerLog]
GO
/****** Object:  Table [dbo].[UserLog_RunSP2]    Script Date: 12/13/2010 02:28:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UserLog_RunSP2](
	[logid] [bigint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[userid] [int] NULL,
	[spname] [varchar](50) NULL,
	[doing] [varchar](4000) NULL,
	[logdate] [datetime] NULL CONSTRAINT [DF_UserLog_RunSP_logdate]  DEFAULT (getdate()),
	[custid] [int] NULL,
	[ActionID] [int] NULL,
	[TrackingValue] [nvarchar](max) NULL,
	[Duration] [int] NULL
)

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [IX_UserLog_RunSP]    Script Date: 12/13/2010 02:28:56 ******/
CREATE CLUSTERED INDEX [IX_UserLog_RunSP] ON [dbo].[UserLog_RunSP2] 
(
	[custid] ASC,
	[logdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ps_RUNSP_monthly]([logdate])
GO

/****** Object:  Index [IX_ActionID_Custid]    Script Date: 12/13/2010 02:28:56 ******/
CREATE NONCLUSTERED INDEX [IX_ActionID_Custid] ON [dbo].[UserLog_RunSP2] 
(
	[ActionID] ASC,
	[custid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [RUNSP_INDEX2]
GO

/****** Object:  Index [IX_SPname_Custid]    Script Date: 12/13/2010 02:28:56 ******/
CREATE NONCLUSTERED INDEX [IX_SPname_Custid] ON [dbo].[UserLog_RunSP2] 
(
	[spname] ASC,
	[custid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [RUNSP_INDEX2]
GO
GRANT INSERT ON [dbo].[UserLog_RunSP2] TO [bodbAdminNet]
GO
GRANT SELECT ON [dbo].[UserLog_RunSP2] TO [bodbAdminNet]
GO
GRANT INSERT ON [dbo].[UserLog_RunSP2] TO [bodbDownlineNet]
GO
GRANT SELECT ON [dbo].[UserLog_RunSP2] TO [bodbDownlineNet]
GO
GRANT INSERT ON [dbo].[UserLog_RunSP2] TO [bodbDownlineNetView]
GO
GRANT SELECT ON [dbo].[UserLog_RunSP2] TO [bodbDownlineNetView]
GO
GRANT INSERT ON [dbo].[UserLog_RunSP2] TO [Dot_Admin]
GO
GRANT SELECT ON [dbo].[UserLog_RunSP2] TO [Dot_Admin]
GO
GRANT INSERT ON [dbo].[UserLog_RunSP2] TO [Dot_Member]
GO
GRANT SELECT ON [dbo].[UserLog_RunSP2] TO [Dot_Member]
-----------
SELECT     max(logid)
FROM         UserLog_RunSP2 with (nolock)
WHERE     (logdate BETWEEN '2010/12/01' AND 	'2010/12/31 23:59:59.997')
--MaxLogID = 62206348
----

EXEC SP_RENAME 'UserLog_RunSP', 'UserLog_RunSP_del'
GO
EXEC SP_RENAME 'UserLog_RunSP2', 'UserLog_RunSP'
-----
SELECT     logid, userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration
FROM         UserLog_RunSP_DEL with (nolock)
WHERE     (logdate BETWEEN '2010/12/13' AND 	'2010/12/13 23:59:59.997')
and logid > 62206348
-------------
INSERT INTO UserLog_RunSP
(userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration)
SELECT     userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration
FROM         UserLog_RunSP_DEL with (nolock)
WHERE     (logdate BETWEEN '2010/12/13' AND 	'2010/12/13 23:59:59.997')
and logid > 62206348
---------------
drop table UserLog_RunSP_del
--------------
--Remove partition scheme and function
-------------
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_Index-1]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_Index]
GO
-------
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f9]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG9]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f8]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG8]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f7]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG7]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f6]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG6]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f5]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG5]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f4]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG4]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f38]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG38]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f37]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG37]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f36]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG36]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f35]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG35]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f34]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG34]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f33]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG33]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f32]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG32]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f31]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG31]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f30]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG30]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f3]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG3]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f29]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG29]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f28]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG28]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f27]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG27]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f26]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG26]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f25]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG25]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f24]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG24]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f23]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG23]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f22]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG22]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f21]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG21]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f20]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG20]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f2]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG2]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f19]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG19]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f18]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG18]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f17]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG17]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f16]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG16]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f15]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG15]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f14]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG14]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f13]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG13]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f12]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG12]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f11]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG11]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f10]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG10]
GO
USE [bodb_CustomerLog]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f1_a]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f1_b]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f1_c]
GO
ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_RunSP_f1_d]
GO
ALTER DATABASE [bodb_CustomerLog] REMOVE FILEGROUP [RunSP_FG1]
GO

---------------------------
SELECT  logid, userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration, TrackingValue2
FROM    UserLog_RunSP with (nolock)
where
    logdate between '2007/09/01' AND 	'2007/09/30 23:59:59.997'
    logdate between '2007/10/01' AND 	'2007/10/31 23:59:59.997'
    logdate between '2007/11/01' AND 	'2007/11/30 23:59:59.997'
    logdate between '2007/12/01' AND 	'2007/12/31 23:59:59.997'
    logdate between '2008/01/01' AND 	'2008/01/31 23:59:59.997'
    logdate between '2008/02/01' AND 	'2008/02/29 23:59:59.997'
    logdate between '2008/03/01' AND 	'2008/03/31 23:59:59.997'
    logdate between '2008/04/01' AND 	'2008/04/30 23:59:59.997'
    logdate between '2008/05/01' AND 	'2008/05/31 23:59:59.997'
    logdate between '2008/06/01' AND 	'2008/06/30 23:59:59.997'
    logdate between '2008/07/01' AND 	'2008/07/31 23:59:59.997'
    logdate between '2008/08/01' AND 	'2008/08/31 23:59:59.997'
    logdate between '2008/09/01' AND 	'2008/09/30 23:59:59.997'
    logdate between '2008/10/01' AND 	'2008/10/31 23:59:59.997'
    logdate between '2008/11/01' AND 	'2008/11/30 23:59:59.997'
    logdate between '2008/12/01' AND 	'2008/12/31 23:59:59.997'
    logdate between '2009/01/01' AND 	'2009/01/31 23:59:59.997'
    logdate between '2009/02/01' AND 	'2009/02/28 23:59:59.997'
    logdate between '2009/03/01' AND 	'2009/03/31 23:59:59.997'
    logdate between '2009/04/01' AND 	'2009/04/30 23:59:59.997'
    logdate between '2009/05/01' AND 	'2009/05/31 23:59:59.997'
    logdate between '2009/06/01' AND 	'2009/06/30 23:59:59.997'
    logdate between '2009/07/01' AND 	'2009/07/31 23:59:59.997'
    logdate between '2009/08/01' AND 	'2009/08/31 23:59:59.997'
    logdate between '2009/09/01' AND 	'2009/09/30 23:59:59.997'
    logdate between '2009/10/01' AND 	'2009/10/31 23:59:59.997'
    logdate between '2009/11/01' AND 	'2009/11/30 23:59:59.997'
    logdate between '2009/12/01' AND 	'2009/12/31 23:59:59.997'
    logdate between '2010/01/01' AND 	'2010/01/31 23:59:59.997'
    logdate between '2010/02/01' AND 	'2010/02/28 23:59:59.997'
    logdate between '2010/03/01' AND 	'2010/03/31 23:59:59.997'
    logdate between '2010/04/01' AND 	'2010/04/30 23:59:59.997'
    logdate between '2010/05/01' AND 	'2010/05/31 23:59:59.997'
    logdate between '2010/06/01' AND 	'2010/06/30 23:59:59.997'
    logdate between '2010/07/01' AND 	'2010/07/31 23:59:59.997'
    logdate between '2010/08/01' AND 	'2010/08/31 23:59:59.997'
    logdate between '2010/09/01' AND 	'2010/09/30 23:59:59.997'
    logdate between '2010/10/01' AND 	'2010/10/31 23:59:59.997'
    logdate between '2010/11/01' AND 	'2010/11/30 23:59:59.997'
    logdate between '2010/12/01' AND 	'2010/12/31 23:59:59.997'
--------------

ALTER PROCEDURE [dbo].[DBA_DelRunSP]
    @logDate datetime
AS

if @logDate >= '2011-01-01' --to prevent mistake
    RETURN
    
Declare @RowsEffected int
Declare @RowsCnt int

SELECT @RowsEffected = 0

SET NOCOUNT ON
WHILE 1=1
BEGIN
    DELETE TOP(3000) FROM UserLog_RunSP where
        logDate >= @logDate 
		and logdate < dateadd(dd, 1, @logDate)
    
	SELECT @RowsCnt = @@ROWCOUNT
	SELECT @RowsEffected = @RowsEffected + @RowsCnt   

	IF @RowsCnt < 3000
        BREAK

END

SET NOCOUNT OFF

print convert(varchar(20), @logDate,0) + '-' + convert(varchar(20), dateadd(mi, 1439, @logDate),0) + ' - '+ convert(varchar,@RowsEffected) 
---------

SELECT  logid, userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration, TrackingValue2
FROM    UserLog_RunSP with (nolock)
where		
		logdate between '2012/04/01' AND 	'2012/04/30 23:59:59.997'
--------
logdate between '2012/05/01' AND 	'2012/05/31 23:59:59.997'

------------


SELECT  userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration, TrackingValue2
FROM    UserLog_RunSP2 with (nolock)
where		
		logdate between '2012/05/17' AND 	'2012/05/17 23:59:59.997'
