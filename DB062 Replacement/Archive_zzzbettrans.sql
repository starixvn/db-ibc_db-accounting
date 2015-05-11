USE [bodb_Archive]
GO
/****** Object:  Table [dbo].[zzzbettrans]    Script Date: 01/21/2010 09:28:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[zzzbettrans](
	[transid] [int] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[oddsid] [int] NOT NULL,
	
	[hdp1] [smallmoney] NULL,
	[hdp2] [smallmoney] NULL,
	[odds] [smallmoney] NULL,
	
	[stake] [money] NOT NULL,	
	[winlost] [money] NULL,
	
	[status] [varchar](20) NULL,

	[livehomescore] [smallint] NULL,
	[liveawayscore] [smallint] NULL,
	[liveindicator] [bit] NULL,

	[betteam] [varchar](10) NULL,
	[creator] [int] NOT NULL,
	[refno] [bigint] NULL,
	
	[winlostdate] [smalldatetime] NULL,
	[betfrom] [varchar](1) NULL,
	[betcheck] [varchar](50) NULL,
	[checktime] [datetime] NULL,
	[matchid] [int] NULL,
	[bettype] [tinyint] NULL,
	[keyid] [int] NOT NULL
) ON [DATA]

GO

/****** Object:  Index [IX_zzzbettrans_transid]    Script Date: 01/21/2010 09:28:05 ******/
CREATE CLUSTERED INDEX [IX_zzzbettrans_transid] ON [dbo].[zzzbettrans] 
(
	[transid] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF) ON [DATA]