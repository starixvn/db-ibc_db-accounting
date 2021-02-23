

/* BEGIN create data files & filegroups */
ALTER DATABASE bodb_CustomerLog_Archive ADD FILEGROUP DATA
GO
ALTER DATABASE bodb_CustomerLog_Archive ADD FILE  (NAME = N'bodb_DATA-1'
	,FILENAME = N'D:\IBC_DB\bodb_CustomerLog_Archive\bodb_DATA-1.ndf'
	,SIZE = 30, FILEGROWTH = 10, MAXSIZE = 50)  TO FILEGROUP DATA

GO

ALTER DATABASE bodb_CustomerLog_Archive ADD FILEGROUP [INDEX]
GO
ALTER DATABASE bodb_CustomerLog_Archive ADD FILE  (NAME = N'bodb_INDEX-1'
	,FILENAME = N'D:\IBC_DB\bodb_CustomerLog_Archive\bodb_INDEX-1.ndf'
	,SIZE = 30, FILEGROWTH = 10, MAXSIZE = 50)  TO FILEGROUP [INDEX]
--- do we need to create many files for this filegroup([INDEX]) as in bodb_customerLog11


GO
ALTER DATABASE bodb_CustomerLog_Archive ADD FILEGROUP [MATCH]
GO
ALTER DATABASE bodb_CustomerLog_Archive ADD FILE  (NAME = N'bodb_MatchLog'
	,FILENAME = N'D:\IBC_DB\bodb_CustomerLog_Archive\bodb_MatchLog.ndf'
	,SIZE = 30, FILEGROWTH = 10, MAXSIZE = 50)  TO FILEGROUP [MATCH]
	
GO

ALTER DATABASE bodb_CustomerLog_Archive ADD FILEGROUP [Transaction]
GO
ALTER DATABASE bodb_CustomerLog_Archive ADD FILE  (NAME = N'bodb_Transaction'
	,FILENAME = N'D:\IBC_DB\bodb_CustomerLog_Archive\bodb_Transaction.ndf'
	,SIZE = 30, FILEGROWTH = 10, MAXSIZE = 50)  TO FILEGROUP [Transaction]
	
GO
/* END create data files & filegroups */

/* BEGIN create tables & related indexes */
CREATE TABLE [dbo].[AgentFunctionUsage](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ServerId] [int] NOT NULL,
	[Function] [varchar](50) NULL,
	[SubFunction] [varchar](50) NULL,
	[Lang] [varchar](2) NULL,
	[Count] [bigint] NULL,
	[LogDate] [smalldatetime] NOT NULL
) ON [DATA]

GO

SET ANSI_PADDING OFF
GO


CREATE CLUSTERED INDEX [CIX_AgentFunctionUsage] ON [dbo].[AgentFunctionUsage] 
(
	[ServerId] ASC,
	[Function] ASC,
	[SubFunction] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
GO


CREATE UNIQUE NONCLUSTERED INDEX [IX_ID] ON [dbo].[AgentFunctionUsage] 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
GO




CREATE TABLE [dbo].[CompanyBalance_History](
	[BalanceUpDay] [smalldatetime] NOT NULL,
	[Currency] [int] NOT NULL,
	[CompBalBefore] [float] NULL,
	[CompBalAfter] [float] NULL,
 CONSTRAINT [PK_CompanyBalance_History] PRIMARY KEY CLUSTERED 
(
	[BalanceUpDay] ASC,
	[Currency] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO


CREATE TABLE [dbo].[IS_FunctionUsage](
	[PageURL] [varchar](500) NULL,
	[Function] [varchar](50) NOT NULL,
	[SubFunction] [varchar](50) NOT NULL,
	[LogDate] [datetime] NOT NULL,
	[Site] [varchar](20) NOT NULL,
	[ServerID] [int] NULL,
	[Count] [int] NULL
) ON [DATA]

GO

SET ANSI_PADDING OFF
GO



CREATE CLUSTERED INDEX [CIX_IS_FunctionUsage] ON [dbo].[IS_FunctionUsage] 
(
	[PageURL] ASC,
	[Function] ASC,
	[SubFunction] ASC,
	[LogDate] ASC,
	[Site] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
GO


CREATE NONCLUSTERED INDEX [IX_ServerID] ON [dbo].[IS_FunctionUsage] 
(
	[ServerID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
GO

ALTER TABLE [dbo].[IS_FunctionUsage] ADD  CONSTRAINT [DF_IS_FunctionUsage_LogDate]  DEFAULT (getdate()) FOR [LogDate]
GO



CREATE TABLE [dbo].[UserLog_Credit](
	[logid] [bigint] IDENTITY(1,1) NOT NULL,
	[userid] [int] NOT NULL,
	[custid] [int] NOT NULL,
	[logdate] [datetime] NOT NULL,
	[spname] [varchar](50) NULL,
	[OldValue] [money] NULL,
	[NewValue] [money] NULL,
	[ip] [varchar](15) NULL,
	[doing] [varchar](500) NULL,
	[ActionID] [int] NULL
) ON [INDEX]

GO

SET ANSI_PADDING OFF
GO


CREATE CLUSTERED INDEX [IX_UserLog_Credit] ON [dbo].[UserLog_Credit] 
(
	[logdate] ASC,
	[custid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [INDEX]
GO

ALTER TABLE [dbo].[UserLog_Credit] ADD  CONSTRAINT [DF_userlog_Credit_logdate]  DEFAULT (getdate()) FOR [logdate]
GO



CREATE TABLE [dbo].[UserLog_Exchange](
	[LogID] [bigint] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[ExchangeID] [int] NOT NULL,
	[actualrate] [float] NULL,
	[doing] [varchar](500) NULL,
	[IP] [varchar](15) NULL,
	[LogDate] [datetime] NULL
) ON [DATA]

GO

SET ANSI_PADDING OFF
GO


CREATE CLUSTERED INDEX [IX_UserLog_Exchange] ON [dbo].[UserLog_Exchange] 
(
	[LogDate] ASC,
	[UserID] ASC,
	[ExchangeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
GO

ALTER TABLE [dbo].[UserLog_Exchange] ADD  CONSTRAINT [DF_UserLog_Exchange_LogDate]  DEFAULT (getdate()) FOR [LogDate]
GO



CREATE TABLE [dbo].[UserLog_Settle](
	[LogID] [bigint] IDENTITY(1,1) NOT NULL,
	[LogDate] [datetime] NOT NULL,
	[UserID] [int] NULL,
	[MatchID] [int] NULL,
	[ActionID] [int] NULL,
	[finalhomescore] [int] NULL,
	[finalawayscore] [int] NULL,
	[hthomescore] [int] NULL,
	[htawayscore] [int] NULL,
	[GoalRecord] [varchar](50) NULL,
	[betstatus] [nvarchar](50) NULL,
	[Remark] [varchar](500) NULL,
	[IP] [varchar](15) NULL
) ON [MATCH]

GO

SET ANSI_PADDING OFF
GO

CREATE CLUSTERED INDEX [CIX_LogDate_MatchID] ON [dbo].[UserLog_Settle] 
(
	[LogDate] ASC,
	[MatchID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF) ON [MATCH]
GO

CREATE NONCLUSTERED INDEX [IX_MatchID_Action] ON [dbo].[UserLog_Settle] 
(
	[MatchID] ASC,
	[ActionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF) ON [MATCH]
GO

ALTER TABLE [dbo].[UserLog_Settle] ADD  CONSTRAINT [DF_userlog_settle_logdate]  DEFAULT (getdate()) FOR [LogDate]
GO



CREATE TABLE [dbo].[UserLog_Transaction](
	[LogID] [bigint] IDENTITY(1,1) NOT NULL,
	[LogDate] [datetime] NOT NULL,
	[ActionID] [int] NOT NULL,
	[Refno] [bigint] NOT NULL,
	[UserID] [int] NOT NULL,
	[IP] [varchar](15) NULL,
	[Doing] [varchar](1000) NULL
) ON [Transaction]

GO

SET ANSI_PADDING OFF
GO

CREATE CLUSTERED INDEX [CIX_UserLog_Transaction] ON [dbo].[UserLog_Transaction] 
(
	[LogDate] ASC,
	[ActionID] ASC,
	[Refno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Transaction]
GO

ALTER TABLE [dbo].[UserLog_Transaction] ADD  CONSTRAINT [DF_UserLog_Transaction_LogDate]  DEFAULT (getdate()) FOR [LogDate]
GO

/* END create tables & related indexes */

GO
GO
GO

/* BEGIN insert data scripts */
-- table: [AgentFunctionUsage]
SET IDENTITY_INSERT [AgentFunctionUsage] ON
INSERT INTO [AgentFunctionUsage](Id,ServerId,[Function],SubFunction,Lang,[Count],LogDate)
SELECT Id,ServerId,[Function],SubFunction,Lang,[Count],LogDate
FROM bodb_CustomerLog11.dbo.[AgentFunctionUsage] WITH(NOLOCK)
WHERE Id < 71932 --- this ID was begining of '2011-01-01'
SET IDENTITY_INSERT [AgentFunctionUsage] OFF
GO

-- table: CompanyBalance_History
INSERT INTO CompanyBalance_History(BalanceUpDay, Currency, CompBalBefore, CompBalAfter)
SELECT BalanceUpDay, Currency, CompBalBefore, CompBalAfter
FROM bodb_CustomerLog11.dbo.CompanyBalance_History WITH(NOLOCK)
WHERE BalanceUpDay < '2011-01-01'
GO

-- table: IS_FunctionUsage


-- table: UserLog_Credit (9083608 rows)
DECLARE @i DATETIME
SET @i = '01-01-2010'
WHILE @i <= '12-31-2010'  --- 466 loops
BEGIN

	SET IDENTITY_INSERT UserLog_Credit ON
	INSERT INTO UserLog_Credit(logid, userid, custid, logdate, spname, OldValue, NewValue, ip, doing, ActionID)
	SELECT logid, userid, custid, logdate, spname, OldValue, NewValue, ip, doing, ActionID
	FROM bodb_CustomerLog11.dbo.UserLog_Credit WITH(NOLOCK)
	WHERE logdate >= @i AND logdate < DATEADD(DAY,1,@i)
	SET IDENTITY_INSERT UserLog_Credit OFF

	WAITFOR DELAY '00:00:01'
	SET @i = DATEADD(DAY,1,@i)	
	
END


-- table: UserLog_Exchange
SET IDENTITY_INSERT UserLog_Exchange ON
INSERT INTO UserLog_Exchange(LogID, UserID, ExchangeID, actualrate, doing, IP, LogDate)
SELECT LogID, UserID, ExchangeID, actualrate, doing, IP, LogDate
FROM bodb_CustomerLog11.dbo.UserLog_Exchange WITH(NOLOCK)
WHERE logate < '2011-01-01'
SET IDENTITY_INSERT UserLog_Exchange OFF


-- table: UserLog_Settle
SET IDENTITY_INSERT UserLog_Settle ON
INSERT INTO UserLog_Settle(LogID, LogDate, UserID, MatchID, ActionID, finalhomescore, finalawayscore, hthomescore, htawayscore, GoalRecord, betstatus, Remark, IP)
SELECT LogID, LogDate, UserID, MatchID, ActionID, finalhomescore, finalawayscore, hthomescore, htawayscore, GoalRecord, betstatus, Remark, IP
FROM bodb_CustomerLog11.dbo.UserLog_Settle WITH(NOLOCK)
WHERE logdate < '2011-01-01'
SET IDENTITY_INSERT UserLog_Settle OFF

DECLARE @i DATETIME
SET @i = '01-01-2010'
WHILE @i <= '12-31-2010'  --- 466 loops
BEGIN

	SET IDENTITY_INSERT UserLog_Settle ON
	INSERT INTO UserLog_Settle(LogID, LogDate, UserID, MatchID, ActionID, finalhomescore, finalawayscore, hthomescore, htawayscore, GoalRecord, betstatus, Remark, IP)
	SELECT LogID, LogDate, UserID, MatchID, ActionID, finalhomescore, finalawayscore, hthomescore, htawayscore, GoalRecord, betstatus, Remark, IP
	FROM bodb_CustomerLog11.dbo.UserLog_Settle WITH(NOLOCK)
	WHERE logdate >= @i AND logdate < DATEADD(DAY,1,@i)
	SET IDENTITY_INSERT UserLog_Settle OFF

	WAITFOR DELAY '00:00:01'
	SET @i = DATEADD(DAY,1,@i)	
	
END

-- table: UserLog_Transaction
SET IDENTITY_INSERT UserLog_Transaction ON
INSERT INTO UserLog_Transaction(LogID, LogDate, ActionID, Refno, UserID, IP, Doing)
SELECT LogID, LogDate, ActionID, Refno, UserID, IP, Doing
FROM bodb_CustomerLog11.dbo.UserLog_Transaction WITH(NOLOCK)
WHERE logdate < '2011-01-01'
SET IDENTITY_INSERT UserLog_Transaction OFF

/* END insert data scripts */


GO
GO
GO

