-------
--RUN SCRIPT on Excel file
-------
ALTER DATABASE [bodb_CustomerLog] ADD FILEGROUP [LOGIN_MAX] 
 GO 
	ALTER DATABASE [bodb_CustomerLog] ADD FILE ( NAME = N'LOGIN_MAX', FILENAME = N'G:\IBC_DB\bodb_CustomerLog\LOGIN\LOGIN_MAX.ndf' , SIZE = 1MB , FILEGROWTH = 32MB ) TO FILEGROUP [LOGIN_MAX] 
 GO 

-------
CREATE PARTITION FUNCTION pf_LOGIN_monthly (DATETIME) AS
RANGE LEFT FOR VALUES
(  
    
    '2010/04/30 23:59:59.997'
    
)

--Create partition schema
CREATE PARTITION SCHEME ps_LOGIN_monthly
AS PARTITION pf_LOGIN_monthly
TO
    ( 
	[LOGIN_10M04],	
	[LOGIN_MAX]
	
 )                
GO
-------
--RUN SCRIPT on Excel file
-------
USE [bodb_CustomerLog]
GO
/****** Object:  Table [dbo].[UserLog_Login2]    Script Date: 12/13/2010 05:28:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UserLog_Login2](
	[LogID] [bigint] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[RoleID] [tinyint] NOT NULL,
	[SubAccID] [int] NOT NULL,
	[ServerID] [int] NOT NULL,
	[IP] [varchar](15) NOT NULL,
	[LogDate] [datetime] NULL,
	[ActionID] [int] NULL,
	[Doing] [varchar](300) NULL,
	[DomainName] [nvarchar](253) NULL,
	[BrowserName] [nvarchar](255) NULL,
	[Platform] [nvarchar](255) NULL,
	[CountryCode] [varchar](64) NULL,
	[Duration] [int] NULL
) ON [Login]

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [CIX_LogDate_User]    Script Date: 12/13/2010 05:28:18 ******/
CREATE CLUSTERED INDEX [CIX_LogDate_User] ON [dbo].[UserLog_Login2] 
(
	[UserID] ASC,
	[LogDate] ASC,	
	[SubAccID] ASC,
	[ActionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ps_LOGIN_monthly]([logdate])
GO
GRANT INSERT ON [dbo].[UserLog_Login2] TO [bodbAdminNet]
GO
GRANT SELECT ON [dbo].[UserLog_Login2] TO [bodbAdminNet]
GO
GRANT INSERT ON [dbo].[UserLog_Login2] TO [bodbDownlineNet]
GO
GRANT SELECT ON [dbo].[UserLog_Login2] TO [bodbDownlineNet]
GO
GRANT INSERT ON [dbo].[UserLog_Login2] TO [bodbDownlineNetView]
GO
GRANT SELECT ON [dbo].[UserLog_Login2] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[UserLog_Login2] TO [vnteam]
----------
SELECT     LogID, UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration
FROM         UserLog_Login WITH (nolock)
WHERE logdate between '2010/12/01' AND 	'2010/12/31 23:59:59.997'
--------
select max(logID) from UserLog_Login2 with (nolock)
WHERE logdate between '2010/12/01' AND 	'2010/12/31 23:59:59.997'
--MaxLogID = 199791996
-----
INSERT INTO UserLog_Login
(UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration)
SELECT     UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration
FROM         UserLog_Login_DEL with (nolock)
WHERE     (logdate BETWEEN '2010/12/13' AND 	'2010/12/13 23:59:59.997')
and logid > 199791996