USE [master]
GO
ALTER DATABASE [bodb_Archive04-05] ADD FILEGROUP [EVENT_2004]
GO
ALTER DATABASE [bodb_Archive04-05] ADD FILE ( NAME = N'bodb_Archive04-0505_event_2004', FILENAME = N'P:\Archive\2004-2005\bodb_Archive04-0505_event_2004.ndf' , SIZE = 2048KB , FILEGROWTH = 16384KB ) TO FILEGROUP [EVENT_2004]
GO

USE [bodb_Archive04-05]
GO
/****** Object:  Table [dbo].[odds_2004]    Script Date: 12/02/2009 03:42:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[odds_2004](
	[oddsid] [int] NOT NULL,
	[matchid] [int] NOT NULL,
	[bettype] [tinyint] NULL,
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
 CONSTRAINT [PK_odds_2004] PRIMARY KEY CLUSTERED 
(
	[oddsid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_2004]
) ON [EVENT_2004]

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [IX_matchid]    Script Date: 12/02/2009 03:42:55 ******/
CREATE NONCLUSTERED INDEX [IX_matchid] ON [dbo].[odds_2004] 
(
	[matchid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_2004]
GO
GO
CREATE TABLE [dbo].[match_2004](
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
	[multiple] [bit] NULL,
	[yenbet] [bit] NULL,
	[exrisk] [float] NULL,
	[sporttype] [tinyint]  NULL ,
	[tstamp] [binary](8) NULL,
	[homeid2] [int]  NULL ,
	[awayid2] [int]  NULL ,
	[DisplayMode] [tinyint] NULL ,
	[LeaguePatternID] [smallint] NULL ,
	[HomeDisplayPatternID] [smallint] NULL ,
	[AwayDisplayPatternID] [smallint] NULL ,
	[IsNeutral] [bit] NULL ,
	[GoalRecord] [varchar](50) NULL,
 CONSTRAINT [PK_match_2004] PRIMARY KEY CLUSTERED 
(
	[matchid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_2004]
) ON [EVENT_2004]

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [IX_eventdate]    Script Date: 12/02/2009 05:16:39 ******/
CREATE NONCLUSTERED INDEX [IX_eventdate] ON [dbo].[match_2004] 
(
	[eventdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_2004]
GO
------------
--IMPORT DATA
SELECT  o.oddsid, o.matchid, o.bettype, o.switch, o.hdp1, o.hdp2, o.odds1a, o.odds2a, o.odds1b, o.odds2b, o.odds1c, o.odds2c, o.odds1e, o.odds2e, 
                      o.odds1f, o.odds2f, o.odds1d, o.odds2d, o.odds1hka, o.odds2hka, o.odds1hkb, o.odds2hkb, o.odds1hkc, o.odds2hkc, o.odds1hke, o.odds2hke, 
                      o.odds1hkf, o.odds2hkf, o.odds1hkd, o.odds2hkd, o.oddsspreada, o.oddsspreadb, o.oddsspreadd, o.oddsspreade, o.oddsspreadf, o.oddsspreadc, 
                      o.autobookie, o.gapodds1, o.gapodds2, o.maxstake1, o.maxstake2, o.minstake1, o.minstake2, o.diffbalance, o.maxodds, o.minodds, o.oddsstatus, 
                      o.liveindicator, o.changetime, o.risk, o.stakerange, o.newoffersetup, o.livehomescore, o.liveawayscore, o.creator, o.com1, o.comx, o.com2, o.cs00, 
                      o.cs01, o.cs10, o.cs11, o.cs02, o.cs12, o.cs22, o.cs21, o.cs20, o.cs30, o.cs31, o.cs32, o.cs33, o.cs23, o.cs13, o.cs03, o.cs43, o.cs42, o.cs41, o.cs40, 
                      o.cs44, o.cs14, o.cs24, o.cs04, o.cs34, o.cs50, o.cs05, o.comstatus, o.csstatus, o.commaxbet, o.csmaxbet, o.com1total, o.comxtotal, o.com2total, 
                      o.bal00, o.bal10, o.bal11, o.bal01, o.bal20, o.bal21, o.bal22, o.bal12, o.bal02, o.bal30, o.bal31, o.bal32, o.bal33, o.bal23, o.bal13, o.bal03, o.bal40, 
                      o.bal41, o.bal42, o.bal43, o.bal44, o.bal34, o.bal24, o.bal14, o.bal04, o.bal50, o.bal05, o.maxbet, o.ht, o.autoreject, o.allowance, o.autosuspend, 
                      o.multiple, o.stakerange2, o.risk2, o.allowance2, o.site2, o.site3, o.site4, o.hometotal, o.awaytotal, o.sporttype, o.tstamp
FROM         odds_BK AS o WITH (nolock) INNER JOIN
                      match_06Q3 AS m WITH (nolock) ON o.matchid = m.matchid
WHERE     (m.eventdate BETWEEN '2004/01/01' AND '2004/12/31 23:59:59.997')

SELECT     matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, creator, 
                      matchcode, kickofftime, closedtime, showtime, hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, tstamp
FROM         match_06Q3 AS m WITH (nolock)
WHERE     (m.eventdate BETWEEN '2004/01/01' AND '2004/12/31 23:59:59.997')