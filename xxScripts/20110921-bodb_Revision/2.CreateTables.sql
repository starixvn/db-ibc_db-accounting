USE [bodb_Review]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[bettrans](
	[transid] [bigint] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL CONSTRAINT [DF_bettrans_transdate]  DEFAULT (getdate()),
	[oddsid] [int] NOT NULL CONSTRAINT [DF_bettrans_oddsid]  DEFAULT ((0)),
	[hdp1] [smallmoney] NULL CONSTRAINT [DF_bettrans_hdp1]  DEFAULT ((0)),
	[hdp2] [smallmoney] NULL CONSTRAINT [DF_bettrans_hdp2]  DEFAULT ((0)),
	[odds] [smallmoney] NULL CONSTRAINT [DF_bettrans_odds]  DEFAULT ((0)),
	[stake] [money] NOT NULL CONSTRAINT [DF_bettrans_stake]  DEFAULT ((0)),
	[status] [nvarchar](10) NULL,
	[winlost] [money] NULL CONSTRAINT [DF_bettrans_winlost]  DEFAULT ((0)),
	[awinlost] [money] NULL CONSTRAINT [DF_bettrans_awinlost]  DEFAULT ((0)),
	[mwinlost] [money] NULL CONSTRAINT [DF_bettrans_mwinlost]  DEFAULT ((0)),
	[playercomm] [money] NULL CONSTRAINT [DF_bettrans_playercomm]  DEFAULT ((0)),
	[comm] [money] NULL CONSTRAINT [DF_bettrans_comm]  DEFAULT ((0)),
	[acomm] [money] NULL CONSTRAINT [DF_bettrans_acomm]  DEFAULT ((0)),
	[apositiontaking] [smallmoney] NULL CONSTRAINT [DF_bettrans_apositiontaking]  DEFAULT ((0)),
	[mpositiontaking] [smallmoney] NULL CONSTRAINT [DF_bettrans_mpositiontaking]  DEFAULT ((0)),
	[tpositiontaking] [smallmoney] NULL CONSTRAINT [DF_bettrans_tpositiontaking]  DEFAULT ((0)),
	[playerdiscount] [decimal](9, 8) NULL CONSTRAINT [DF_bettrans_playerdiscount]  DEFAULT ((0)),
	[discount] [decimal](9, 8) NULL CONSTRAINT [DF_bettrans_discount]  DEFAULT ((0)),
	[adiscount] [decimal](9, 8) NULL CONSTRAINT [DF_bettrans_adiscount]  DEFAULT ((0)),
	[livehomescore] [smallint] NULL CONSTRAINT [DF_bettrans_livehomescore]  DEFAULT ((0)),
	[liveawayscore] [smallint] NULL CONSTRAINT [DF_bettrans_liveawayscore]  DEFAULT ((0)),
	[liveindicator] [bit] NULL CONSTRAINT [DF_bettrans_liveindicator]  DEFAULT ((0)),
	[betteam] [nvarchar](10) NULL,
	[creator] [int] NOT NULL CONSTRAINT [DF_bettrans_creator]  DEFAULT ((0)),
	[refno] [bigint] NOT NULL,
	[comstatus] [nvarchar](20) NULL CONSTRAINT [DF_bettrans_comstatus]  DEFAULT ('s'),
	[winlostdate] [smalldatetime] NULL CONSTRAINT [DF_bettrans_winlostdate]  DEFAULT (getdate()),
	[betfrom] [nvarchar](1) NULL CONSTRAINT [DF_bettrans_betfrom]  DEFAULT ('i'),
	[betcheck] [nvarchar](50) NULL CONSTRAINT [DF_bettrans_betcheck]  DEFAULT ((0)),
	[checktime] [datetime] NULL,
	[oddsspread] [smallmoney] NULL,
	[actualrate] [float] NULL,
	[matchid] [int] NULL,
	[recommend] [int] NOT NULL,
	[mrecommend] [int] NOT NULL,
	[ruben] [tinyint] NULL CONSTRAINT [DF_bettrans_ruben]  DEFAULT ((0)),
	[betid] [bigint] NULL,
	[statuswinlost] [tinyint] NULL,
	[modds] [smallmoney] NULL CONSTRAINT [DF_bettrans_modds]  DEFAULT ((1)),
	[bettype] [smallint] NULL,
	[betdaqid] [bigint] NULL,
	[tstamp] [timestamp] NULL,
	[actual_stake] [money] NULL CONSTRAINT [DF_bettrans_actual_stake]  DEFAULT ((0)),
	[currency] [tinyint] NULL,
	[ip] [nvarchar](15) NULL,
	[transdesc] [nvarchar](300) NULL,
	[sdiscount] [decimal](9, 8) NULL,
	[scomm] [money] NULL CONSTRAINT [DF_bettrans_scomm]  DEFAULT ((0)),
	[spositiontaking] [smallmoney] NULL CONSTRAINT [DF_bettrans_spositiontaking]  DEFAULT ((0)),
	[swinlost] [money] NULL CONSTRAINT [DF_bettrans_swinlost]  DEFAULT ((0)),
	[srecommend] [int] NOT NULL,
	[Username] [nvarchar](50) NULL,
	[CurrencyName] [nvarchar](50) NULL,
	[virtualrate] [float] NOT NULL CONSTRAINT [DF_bettrans_virtualrate]  DEFAULT ((0)),
	[oddstype] [tinyint] NULL,
	[statusID] [tinyint] NULL,
	[currency2] [tinyint] NULL,
	[balance] [money] NULL,
 CONSTRAINT [PK_bettrans] PRIMARY KEY NONCLUSTERED 
(
	[transid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [CIX_matchid_bettype]    Script Date: 09/21/2011 04:29:02 ******/
CREATE CLUSTERED INDEX [CIX_matchid_bettype] ON [dbo].[bettrans] 
(
	[matchid] ASC,
	[custid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_custid]    Script Date: 09/21/2011 04:29:02 ******/
CREATE NONCLUSTERED INDEX [IX_custid] ON [dbo].[bettrans] 
(
	[custid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_recommend]    Script Date: 09/21/2011 04:29:02 ******/
CREATE NONCLUSTERED INDEX [IX_srecommend] ON [dbo].[bettrans] 
(
	[srecommend] ASC
)
INCLUDE ( [winlostdate],
[bettype]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]