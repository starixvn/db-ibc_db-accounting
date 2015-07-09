/*
select eventdate from match_bk m with (nolock) where matchid = 
(select min(matchid) from Dot_Admin_LiveLog t with (nolock) where matchid >0)

Dot_Admin_LiveLog: 2011-09-24 00:00:00.000

Dot_Admin_Assignment_Operator_bk: 2010

bingoBall_bk: 2010-10-28 00:00:00.000

SS_GameState_bk: no data yet

*/

USE [master]
GO
ALTER DATABASE [bodb_Archive11] ADD FILEGROUP [EVENT_2011]
GO
ALTER DATABASE [bodb_Archive11] ADD FILE
( NAME = N'bodb_Archive11_event01', FILENAME = N'Q:\Archive\2011\bodb_Archive11_event01.ndf'
    , SIZE = 512KB , FILEGROWTH = 16384KB ) TO FILEGROUP [EVENT_2011]
GO
ALTER DATABASE [bodb_Archive11] ADD FILE
( NAME = N'bodb_Archive11_event02', FILENAME = N'Q:\Archive\2011\bodb_Archive11_event02.ndf'
    , SIZE = 512KB , FILEGROWTH = 16384KB ) TO FILEGROUP [EVENT_2011]
GO
ALTER DATABASE [bodb_Archive11] ADD FILE
( NAME = N'bodb_Archive11_event03', FILENAME = N'Q:\Archive\2011\bodb_Archive11_event03.ndf'
    , SIZE = 512KB , FILEGROWTH = 16384KB ) TO FILEGROUP [EVENT_2011]
GO

USE [master]
GO
ALTER DATABASE [bodb_Archive11] ADD FILEGROUP [LiveLog]
GO
ALTER DATABASE [bodb_Archive11] ADD FILE
( NAME = N'bodb_Archive11_LiveLog01', FILENAME = N'Q:\Archive\2011\bodb_Archive11_LiveLog01.ndf'
    , SIZE = 2048KB , FILEGROWTH = 16384KB ) TO FILEGROUP [LiveLog]
GO
ALTER DATABASE [bodb_Archive11] ADD FILE
( NAME = N'bodb_Archive11_LiveLog02', FILENAME = N'Q:\Archive\2011\bodb_Archive11_LiveLog02.ndf'
    , SIZE = 2048KB , FILEGROWTH = 16384KB ) TO FILEGROUP [LiveLog]
GO
ALTER DATABASE [bodb_Archive11] ADD FILE
( NAME = N'bodb_Archive11_LiveLog03', FILENAME = N'Q:\Archive\2011\bodb_Archive11_LiveLog03.ndf'
    , SIZE = 2048KB , FILEGROWTH = 16384KB ) TO FILEGROUP [LiveLog]
GO

USE [bodb_Archive11]
GO
/****** Object:  Table [dbo].[bingoBall_bk]    Script Date: 03/30/2013 06:29:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[bingoBall_bk](
	[Matchid] [int] NOT NULL,
	[Seq] [tinyint] NOT NULL,
	[Number] [tinyint] NULL,
	[UpdateTime] [datetime] NULL,
 CONSTRAINT [PK_bingoBall_bk] PRIMARY KEY CLUSTERED 
(
	[Matchid] ASC,
	[Seq] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_2011]
) ON [EVENT_2011]

GO
/****** Object:  Table [dbo].[Dot_Admin_Assignment_Operator_bk]    Script Date: 03/30/2013 06:29:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dot_Admin_Assignment_Operator_bk](
	[ID] [int] NOT NULL,
	[matchid] [int] NULL,
	[OperatorType] [int] NULL,
	[OperatorID] [int] NULL,
	[bettype] [smallint] NULL,
 CONSTRAINT [PK_Dot_admin_Assignment_Operator_bk] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_2011]
) ON [EVENT_2011]

GO

/****** Object:  Index [IX_matchid]    Script Date: 03/30/2013 06:29:13 ******/
CREATE NONCLUSTERED INDEX [IX_matchid] ON [dbo].[Dot_Admin_Assignment_Operator_bk] 
(
	[matchid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_2011]
GO
/****** Object:  Table [dbo].[Dot_Admin_LiveLog]    Script Date: 03/30/2013 06:29:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Dot_Admin_LiveLog](
	[ID] [bigint] NOT NULL,
	[matchid] [int] NULL,
	[action_memo] [varchar](600) NULL,
	[OperatorID] [int] NULL,
	[transtime] [datetime] NOT NULL,
 CONSTRAINT [PK_Dot_Admin_LiveLog] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [LiveLog]
) ON [LiveLog]

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [CIX_MatchID]    Script Date: 03/30/2013 06:29:13 ******/
CREATE CLUSTERED INDEX [CIX_MatchID] ON [dbo].[Dot_Admin_LiveLog] 
(
	[matchid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [LiveLog]
GO
/****** Object:  Table [dbo].[match_bk]    Script Date: 03/30/2013 06:29:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[match_bk](
	[matchid] [int] NOT NULL,
	[leagueid] [int] NOT NULL,
	[homeid] [int] NOT NULL,
	[awayid] [int] NOT NULL,
	[eventdate] [datetime] NULL,
	[eventstatus] [varchar](50) NULL,
	[betstatus] [varchar](50) NULL,
	[livehomescore] [int] NULL,
	[liveawayscore] [int] NULL,
	[finalhomescore] [int] NULL,
	[finalawayscore] [int] NULL,
	[creator] [int] NOT NULL,
	[matchcode] [varchar](50) NULL,
	[kickofftime] [datetime] NULL,
	[closedtime] [datetime] NULL,
	[showtime] [varchar](50) NULL,
	[hthomescore] [int] NULL,
	[htawayscore] [int] NULL,
	[ruben] [tinyint] NULL,
	[multiple] [tinyint] NULL,
	[yenbet] [bit] NULL,
	[exrisk] [float] NULL,
	[sporttype] [tinyint] NULL,
	[tstamp] [binary](8) NULL,
	[homeid2] [int] NULL,
	[awayid2] [int] NULL,
	[DisplayMode] [tinyint] NULL,
	[LeaguePatternID] [smallint] NULL,
	[HomeDisplayPatternID] [smallint] NULL,
	[AwayDisplayPatternID] [smallint] NULL,
	[IsNeutral] [bit] NULL,
	[GoalRecord] [varchar](50) NULL,
 CONSTRAINT [PK_match_bk] PRIMARY KEY CLUSTERED 
(
	[matchid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_2011]
) ON [EVENT_2011]

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [IX_eventdate]    Script Date: 03/30/2013 06:29:13 ******/
CREATE NONCLUSTERED INDEX [IX_eventdate] ON [dbo].[match_bk] 
(
	[eventdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_2011]
GO
/****** Object:  Table [dbo].[odds_bk]    Script Date: 03/30/2013 06:29:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[odds_bk](
	[oddsid] [int] NOT NULL,
	[matchid] [int] NOT NULL,
	[bettype] [smallint] NULL,
	[switch] [bit] NULL,
	[hdp1] [float] NULL,
	[hdp2] [float] NULL,
	[odds1a] [float] NULL,
	[odds2a] [float] NULL,
	[odds1b] [float] NULL,
	[odds2b] [float] NULL,
	[odds1c] [float] NULL,
	[odds2c] [float] NULL,
	[odds1e] [float] NULL,
	[odds2e] [float] NULL,
	[odds1f] [float] NULL,
	[odds2f] [float] NULL,
	[odds1d] [float] NULL,
	[odds2d] [float] NULL,
	[odds1hka] [float] NULL,
	[odds2hka] [float] NULL,
	[odds1hkb] [float] NULL,
	[odds2hkb] [float] NULL,
	[odds1hkc] [float] NULL,
	[odds2hkc] [float] NULL,
	[odds1hke] [float] NULL,
	[odds2hke] [float] NULL,
	[odds1hkf] [float] NULL,
	[odds2hkf] [float] NULL,
	[odds1hkd] [float] NULL,
	[odds2hkd] [float] NULL,
	[oddsspreada] [float] NULL,
	[oddsspreadb] [float] NULL,
	[oddsspreadd] [float] NULL,
	[oddsspreade] [float] NULL,
	[oddsspreadf] [float] NULL,
	[oddsspreadc] [float] NULL,
	[autobookie] [bit] NULL,
	[gapodds1] [float] NULL,
	[gapodds2] [float] NULL,
	[maxstake1] [float] NULL,
	[maxstake2] [float] NULL,
	[minstake1] [float] NULL,
	[minstake2] [float] NULL,
	[diffbalance] [float] NULL,
	[maxodds] [float] NULL,
	[minodds] [float] NULL,
	[oddsstatus] [varchar](50) NULL,
	[liveindicator] [bit] NULL,
	[changetime] [datetime] NULL,
	[risk] [float] NULL,
	[stakerange] [float] NULL,
	[newoffersetup] [bit] NULL,
	[livehomescore] [int] NULL,
	[liveawayscore] [int] NULL,
	[creator] [int] NULL,
	[com1] [float] NULL,
	[comx] [float] NULL,
	[com2] [float] NULL,
	[cs00] [float] NULL,
	[cs01] [float] NULL,
	[cs10] [float] NULL,
	[cs11] [float] NULL,
	[cs02] [float] NULL,
	[cs12] [float] NULL,
	[cs22] [float] NULL,
	[cs21] [float] NULL,
	[cs20] [float] NULL,
	[cs30] [float] NULL,
	[cs31] [float] NULL,
	[cs32] [float] NULL,
	[cs33] [float] NULL,
	[cs23] [float] NULL,
	[cs13] [float] NULL,
	[cs03] [float] NULL,
	[cs43] [float] NULL,
	[cs42] [float] NULL,
	[cs41] [float] NULL,
	[cs40] [float] NULL,
	[cs44] [float] NULL,
	[cs14] [float] NULL,
	[cs24] [float] NULL,
	[cs04] [float] NULL,
	[cs34] [float] NULL,
	[cs50] [float] NULL,
	[cs05] [float] NULL,
	[comstatus] [bit] NULL,
	[csstatus] [varchar](50) NULL,
	[commaxbet] [float] NULL,
	[csmaxbet] [float] NULL,
	[com1total] [float] NULL,
	[comxtotal] [float] NULL,
	[com2total] [float] NULL,
	[bal00] [float] NULL,
	[bal10] [float] NULL,
	[bal11] [float] NULL,
	[bal01] [float] NULL,
	[bal20] [float] NULL,
	[bal21] [float] NULL,
	[bal22] [float] NULL,
	[bal12] [float] NULL,
	[bal02] [float] NULL,
	[bal30] [float] NULL,
	[bal31] [float] NULL,
	[bal32] [float] NULL,
	[bal33] [float] NULL,
	[bal23] [float] NULL,
	[bal13] [float] NULL,
	[bal03] [float] NULL,
	[bal40] [float] NULL,
	[bal41] [float] NULL,
	[bal42] [float] NULL,
	[bal43] [float] NULL,
	[bal44] [float] NULL,
	[bal34] [float] NULL,
	[bal24] [float] NULL,
	[bal14] [float] NULL,
	[bal04] [float] NULL,
	[bal50] [float] NULL,
	[bal05] [float] NULL,
	[maxbet] [float] NULL,
	[ht] [bit] NULL,
	[autoreject] [bit] NULL,
	[allowance] [int] NULL,
	[autosuspend] [bit] NULL,
	[multiple] [bit] NULL,
	[stakerange2] [float] NULL,
	[risk2] [float] NULL,
	[allowance2] [float] NULL,
	[site2] [float] NULL,
	[site3] [float] NULL,
	[site4] [float] NULL,
	[hometotal] [float] NULL,
	[awaytotal] [float] NULL,
	[sporttype] [tinyint] NOT NULL,
	[tstamp] [binary](8) NULL,
	[Resourceid] [varchar](20) NULL,
	[ResultKey] [varchar](50) NULL,
 CONSTRAINT [PK_odds_bk] PRIMARY KEY CLUSTERED 
(
	[oddsid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_2011]
) ON [EVENT_2011]

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [IX_matchid]    Script Date: 03/30/2013 06:29:13 ******/
CREATE NONCLUSTERED INDEX [IX_matchid] ON [dbo].[odds_bk] 
(
	[matchid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_Index]
GO
/****** Object:  Table [dbo].[outright_bk]    Script Date: 03/30/2013 06:29:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[outright_bk](
	[orid] [int] NOT NULL,
	[leagueid] [int] NOT NULL,
	[teamid] [int] NOT NULL,
	[eventdate] [smalldatetime] NOT NULL,
	[kickofftime] [datetime] NOT NULL,
	[oddsstatus] [varchar](10) NULL,
	[odds] [smallmoney] NULL,
	[maxbet] [int] NULL,
	[gapodds] [smallmoney] NULL,
	[matchcode] [varchar](10) NULL,
	[groupmatch] [varchar](20) NULL,
	[status] [varchar](10) NULL,
	[creator] [int] NOT NULL,
	[bal] [money] NULL,
	[risk] [money] NULL,
	[DisplayMode] [tinyint] NULL,
	[PlaceOdds] [smallmoney] NULL,
	[Placing] [tinyint] NULL,
	[IsFavor] [bit] NULL,
	[IsSCR] [bit] NULL,
	[ProgramID] [varchar](10) NULL,
	[FOddsStatus] [varchar](10) NULL,
	[SCRTime] [datetime] NULL,
	[LeaguePatternID] [smallint] NULL,
	[TeamPatternID] [smallint] NULL,
	[ProgramDate] [smalldatetime] NULL,
	[IsDeadheat] [bit] NULL,
 CONSTRAINT [PK_outright_bk] PRIMARY KEY CLUSTERED 
(
	[orid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_2011]
) ON [EVENT_2011]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SS_GameState_bk]    Script Date: 03/30/2013 06:29:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SS_GameState_bk](
	[matchid] [int] NOT NULL,
	[ResultKey] [varchar](50) NOT NULL,
	[ResultValue] [varchar](120) NULL,
 CONSTRAINT [PK_SS_GameState_bk] PRIMARY KEY CLUSTERED 
(
	[matchid] ASC,
	[ResultKey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_2011]
) ON [EVENT_2011]

--

--IMPORT DATA

[Task_Archive_Event_DBSPARE]