


/*Acc_ExternalSettlement_Log: delete data with logdate  >= '2012-01-01'*/
-- rows affected 1696141
WHILE 1 = 1  
BEGIN 
	DELETE TOP(10000) Acc_ExternalSettlement_Log WITH(ROWLOCK,UPDLOCK)
	WHERE LogDate >= '2012-01-01'
	
	IF @@ROWCOUNT <> 10000
		BREAK
	WAITFOR DELAY '00:00:01'		
END


/* AgentFunctionUsage */
--rows affected: 71930
DELETE FROM AgentFunctionUsage  WITH(ROWLOCK,UPDLOCK)
WHERE LogDate < '2011-01-01'

--rows affected: 82511
DELETE FROM AgentFunctionUsage  WITH(ROWLOCK,UPDLOCK)
WHERE LogDate >= '2012-01-01'


/*CompanyBalance_History*/
-- rows affected: 648
DELETE FROM CompanyBalance_History  WITH(ROWLOCK,UPDLOCK)
WHERE BalanceUpDay < '2011-01-01'
-- rows affected: 32
DELETE FROM CompanyBalance_History  WITH(ROWLOCK,UPDLOCK)
WHERE BalanceUpDay >= '2012-01-01'

/* */
-- All data with datelog > '2012-01-01'
TRUNCATE TABLE IS_FunctionUsage
TRUNCATE TABLE rmUserLog_Login
TRUNCATE TABLE rmUserLog_RunSP
TRUNCATE TABLE rmUserLog_UserControl
TRUNCATE TABLE UserLog_UserControl

/* UserLog_Credit */

-- logdate < '2011-01-01' rows affected: 9083608
WHILE 1 = 1  
BEGIN 
	DELETE TOP(10000) UserLog_Credit WITH(ROWLOCK,UPDLOCK)
	WHERE LogDate < '2011-01-01'
	
	IF @@ROWCOUNT <> 10000
		BREAK
	WAITFOR DELAY '00:00:01'		
END

-- logdate >= '2012-01-01' rows affected: 10824475
WHILE 1 = 1  
BEGIN 
	DELETE TOP(10000) UserLog_Credit WITH(ROWLOCK,UPDLOCK)
	WHERE LogDate >= '2012-01-01'
	
	IF @@ROWCOUNT <> 10000
		BREAK
	WAITFOR DELAY '00:00:01'		
END

/* UserLog_Exchange */
-- rows affected: 1451
DELETE FROM UserLog_Exchange  WITH(ROWLOCK,UPDLOCK)
WHERE LogDate < '2011-01-01'
-- rows affected: 2146
DELETE FROM UserLog_Exchange  WITH(ROWLOCK,UPDLOCK)
WHERE LogDate >= '2012-01-01'

/* UserLog_Login_Lrf */
-- rows affected: 76734
DELETE FROM UserLog_Login_Lrf  WITH(ROWLOCK,UPDLOCK)
WHERE LogDate >= '2012-01-01'


/* UserLog_Settle */
-- logdate < '2011-01-01' rows affected: 408498
WHILE 1 = 1  
BEGIN 
	DELETE TOP(10000) UserLog_Settle WITH(ROWLOCK,UPDLOCK)
	WHERE LogDate < '2011-01-01'
	
	IF @@ROWCOUNT <> 10000
		BREAK
	WAITFOR DELAY '00:00:01'		
END

-- logdate >= '2012-01-01' rows affected: 2054402
WHILE 1 = 1  
BEGIN 
	DELETE TOP(10000) UserLog_Settle WITH(ROWLOCK,UPDLOCK)
	WHERE LogDate >= '2012-01-01'
	
	IF @@ROWCOUNT <> 10000
		BREAK
	WAITFOR DELAY '00:00:01'		
END


/* UserLog_Transaction */
-- rows affected: 75
DELETE FROM UserLog_Transaction  WITH(ROWLOCK,UPDLOCK)
WHERE LogDate < '2011-01-01'
-- rows affected: 3259
DELETE FROM UserLog_Transaction  WITH(ROWLOCK,UPDLOCK)
WHERE LogDate >= '2012-01-01'

/* UserLog_Transfer */
-- logdate >= '2012-01-01' rows affected: 25589848
WHILE 1 = 1  
BEGIN 
	DELETE TOP(10000) UserLog_Transfer WITH(ROWLOCK,UPDLOCK)
	WHERE LogDate >= '2012-01-01'
	
	IF @@ROWCOUNT <> 10000
		BREAK
	WAITFOR DELAY '00:00:01'		
END


/* UserLog_UserControl_BK */
-- rows affected: 6316
DELETE FROM UserLog_UserControl_BK  WITH(ROWLOCK,UPDLOCK)
WHERE LogDate >= '2012-01-01'



/*============================
Partitioned tables
============================*/


-- partition 12M01
CREATE TABLE [UserLog_LOGIN_12M01]
(
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
	[Duration] [int] NULL,
	[username2] [varchar](50) NULL
) ON LOGIN_12M01
GO
CREATE CLUSTERED INDEX IX_LOGIN_12M01 ON [UserLog_LOGIN_12M01]
(
	[UserID] ASC,
	[LogDate] ASC,
	[SubAccID] ASC,
	[ActionID] ASC
) ON LOGIN_12M01


-- partition 12M02
CREATE TABLE [UserLog_LOGIN_12M02]
(
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
	[Duration] [int] NULL,
	[username2] [varchar](50) NULL
) ON LOGIN_12M02
GO
CREATE CLUSTERED INDEX IX_LOGIN_12M02 ON [UserLog_LOGIN_12M02]
(
	[UserID] ASC,
	[LogDate] ASC,
	[SubAccID] ASC,
	[ActionID] ASC
) ON LOGIN_12M02

-- partition 12M03
CREATE TABLE [UserLog_LOGIN_12M03]
(
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
	[Duration] [int] NULL,
	[username2] [varchar](50) NULL
) ON LOGIN_12M03
GO
CREATE CLUSTERED INDEX IX_LOGIN_12M03 ON [UserLog_LOGIN_12M03]
(
	[UserID] ASC,
	[LogDate] ASC,
	[SubAccID] ASC,
	[ActionID] ASC
) ON LOGIN_12M03


-- partition 12M04
CREATE TABLE [UserLog_LOGIN_12M04]
(
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
	[Duration] [int] NULL,
	[username2] [varchar](50) NULL
) ON LOGIN_12M04
GO
CREATE CLUSTERED INDEX IX_LOGIN_12M04 ON [UserLog_LOGIN_12M04]
(
	[UserID] ASC,
	[LogDate] ASC,
	[SubAccID] ASC,
	[ActionID] ASC
) ON LOGIN_12M04

-- partition 12M05
CREATE TABLE [UserLog_LOGIN_12M05]
(
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
	[Duration] [int] NULL,
	[username2] [varchar](50) NULL
) ON LOGIN_12M05
GO
CREATE CLUSTERED INDEX IX_LOGIN_12M05 ON [UserLog_LOGIN_12M05]
(
	[UserID] ASC,
	[LogDate] ASC,
	[SubAccID] ASC,
	[ActionID] ASC
) ON LOGIN_12M05


-- partition 12M06
CREATE TABLE [UserLog_LOGIN_12M06]
(
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
	[Duration] [int] NULL,
	[username2] [varchar](50) NULL
) ON LOGIN_12M06
GO
CREATE CLUSTERED INDEX IX_LOGIN_12M06 ON [UserLog_LOGIN_12M06]
(
	[UserID] ASC,
	[LogDate] ASC,
	[SubAccID] ASC,
	[ActionID] ASC
) ON LOGIN_12M06



-- partition 12M07
CREATE TABLE [UserLog_LOGIN_12M07]
(
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
	[Duration] [int] NULL,
	[username2] [varchar](50) NULL
) ON LOGIN_12M07
GO
CREATE CLUSTERED INDEX IX_LOGIN_12M07 ON [UserLog_LOGIN_12M07]
(
	[UserID] ASC,
	[LogDate] ASC,
	[SubAccID] ASC,
	[ActionID] ASC
) ON LOGIN_12M07


-- partition 12M08
CREATE TABLE [UserLog_LOGIN_12M08]
(
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
	[Duration] [int] NULL,
	[username2] [varchar](50) NULL
) ON LOGIN_12M08
GO
CREATE CLUSTERED INDEX IX_LOGIN_12M08 ON [UserLog_LOGIN_12M08]
(
	[UserID] ASC,
	[LogDate] ASC,
	[SubAccID] ASC,
	[ActionID] ASC
) ON LOGIN_12M08


-- partition 12M09
CREATE TABLE [UserLog_LOGIN_12M09]
(
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
	[Duration] [int] NULL,
	[username2] [varchar](50) NULL
) ON LOGIN_12M09
GO
CREATE CLUSTERED INDEX IX_LOGIN_12M09 ON [UserLog_LOGIN_12M09]
(
	[UserID] ASC,
	[LogDate] ASC,
	[SubAccID] ASC,
	[ActionID] ASC
) ON LOGIN_12M09


-- partition 12M10
CREATE TABLE [UserLog_LOGIN_12M10]
(
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
	[Duration] [int] NULL,
	[username2] [varchar](50) NULL
) ON LOGIN_12M10
GO
CREATE CLUSTERED INDEX IX_LOGIN_12M10 ON [UserLog_LOGIN_12M10]
(
	[UserID] ASC,
	[LogDate] ASC,
	[SubAccID] ASC,
	[ActionID] ASC
) ON LOGIN_12M10


-- partition 12M11
CREATE TABLE [UserLog_LOGIN_12M11]
(
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
	[Duration] [int] NULL,
	[username2] [varchar](50) NULL
) ON LOGIN_12M11
GO
CREATE CLUSTERED INDEX IX_LOGIN_12M11 ON [UserLog_LOGIN_12M11]
(
	[UserID] ASC,
	[LogDate] ASC,
	[SubAccID] ASC,
	[ActionID] ASC
) ON LOGIN_12M11


ALTER TABLE userlog_Login SWITCH PARTITION 13 TO UserLog_LOGIN_12M01
ALTER TABLE userlog_Login SWITCH PARTITION 14 TO UserLog_LOGIN_12M02
ALTER TABLE userlog_Login SWITCH PARTITION 15 TO UserLog_LOGIN_12M03
ALTER TABLE userlog_Login SWITCH PARTITION 16 TO UserLog_LOGIN_12M04
ALTER TABLE userlog_Login SWITCH PARTITION 17 TO UserLog_LOGIN_12M05
ALTER TABLE userlog_Login SWITCH PARTITION 18 TO UserLog_LOGIN_12M06
ALTER TABLE userlog_Login SWITCH PARTITION 19 TO UserLog_LOGIN_12M07
ALTER TABLE userlog_Login SWITCH PARTITION 20 TO UserLog_LOGIN_12M08
ALTER TABLE userlog_Login SWITCH PARTITION 21 TO UserLog_LOGIN_12M09
ALTER TABLE userlog_Login SWITCH PARTITION 22 TO UserLog_LOGIN_12M10
ALTER TABLE userlog_Login SWITCH PARTITION 23 TO UserLog_LOGIN_12M11



/* merge range */