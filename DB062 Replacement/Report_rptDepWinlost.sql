ALTER DATABASE bodb_Report ADD filegroup [DepWL]
ALTER DATABASE bodb_Report ADD FILE (name = 'DepWL', filename ='G:\IBC_DB\bodb_Report\bodb_Report_DepWL.ndf', SIZE = 1 GB ,FILEGROWTH = 100 MB ) TO filegroup [DepWL]

ALTER DATABASE bodb_Report ADD filegroup [DepWL_Index]
ALTER DATABASE bodb_Report ADD FILE (name = 'DepWL_Index', filename ='G:\IBC_DB\bodb_Report\bodb_Report_DepWL_Index.ndf', SIZE = 150 MB ,FILEGROWTH = 32 MB ) TO filegroup [DepWL_Index]

ALTER DATABASE bodb_Report ADD filegroup [DepWL_bk]
ALTER DATABASE bodb_Report ADD FILE (name = 'DepWL_bk', filename ='G:\IBC_DB\bodb_Report\bodb_Report_DepWL_bk.ndf', SIZE = 1500 MB ,FILEGROWTH = 100 MB ) TO filegroup [DepWL_bk]

ALTER DATABASE bodb_Report ADD filegroup [DepWL_bk_Index]
ALTER DATABASE bodb_Report ADD FILE (name = 'DepWL_bk_Index', filename ='G:\IBC_DB\bodb_Report\bodb_Report_DepWL_bk_Index.ndf', SIZE = 400 MB ,FILEGROWTH = 32 MB ) TO filegroup [DepWL_bk_Index]

-----------
USE [bodb_Report]
GO
/****** Object:  Table [dbo].[rptDepWinlost]    Script Date: 01/23/2010 05:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[rptDepWinlost](
	[winlostdate] [smalldatetime] NOT NULL,
	[custid] [int] NOT NULL,
	[currency] [int] NOT NULL,
	[OpeningBalance] [money] NULL,
	[Deposit] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_Deposit]  DEFAULT ((0)),
	[Withdrawal] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_Withdrawal]  DEFAULT ((0)),
	[Aff2MemTransfer] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_Aff2MemTransfer]  DEFAULT ((0)),
	[Bonus] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_Bonus]  DEFAULT ((0)),
	[Adjustment] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_Adjustment]  DEFAULT ((0)),
	[Turnover] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_Turnover]  DEFAULT ((0)),
	[Outstanding] [money] NULL,
	[Winloss] [money] NOT NULL,
	[ClosingBalance] [money] NULL,
	[recommend] [int] NOT NULL,
	[mrecommend] [int] NOT NULL,
	[srecommend] [int] NOT NULL,
	[actualrate] [float] NULL,
	[Transfer3rd] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_Transfer3rd]  DEFAULT ((0)),
	[DrawGame] [money] NOT NULL CONSTRAINT [DF_rptDepwinlost_DrawGame]  DEFAULT ((0))
) ON [DepWL]

GO

/****** Object:  Index [IX_rptDepWinlost]    Script Date: 01/23/2010 05:07:47 ******/
CREATE UNIQUE CLUSTERED INDEX [IX_rptDepWinlost] ON [dbo].[rptDepWinlost] 
(
	[winlostdate] ASC,
	[custid] ASC,
	[currency] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DepWL]
GO

/****** Object:  Index [IX_recommend]    Script Date: 01/23/2010 05:07:47 ******/
CREATE NONCLUSTERED INDEX [IX_recommend] ON [dbo].[rptDepWinlost] 
(
	[recommend] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DepWL_Index]
GO

/****** Object:  Index [IX_srecommend]    Script Date: 01/23/2010 05:07:47 ******/
CREATE NONCLUSTERED INDEX [IX_srecommend] ON [dbo].[rptDepWinlost] 
(
	[srecommend] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DepWL_Index]
GO

/****** Object:  Index [IX_Winlostdate]    Script Date: 01/23/2010 05:07:47 ******/
CREATE NONCLUSTERED INDEX [IX_Winlostdate] ON [dbo].[rptDepWinlost] 
(
	[winlostdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DepWL_Index]
GO
GRANT SELECT ON [dbo].[rptDepWinlost] TO [bodbAdminNet]
GO
GRANT UPDATE ON [dbo].[rptDepWinlost] TO [bodbAdminNet]
GO
GRANT SELECT ON [dbo].[rptDepWinlost] TO [bodbDownlineNet]
GO
GRANT SELECT ON [dbo].[rptDepWinlost] TO [bodbDownlineNetView]

-------------
USE [bodb_Report]
GO
/****** Object:  Table [dbo].[rptDepWinlost_bk]    Script Date: 01/23/2010 05:13:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[rptDepWinlost_bk](
	[winlostdate] [smalldatetime] NOT NULL,
	[custid] [int] NOT NULL,
	[currency] [int] NOT NULL,
	[OpeningBalance] [money] NULL,
	[Deposit] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk_Deposit]  DEFAULT ((0)),
	[Withdrawal] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk_Withdrawal]  DEFAULT ((0)),
	[Aff2MemTransfer] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk_Aff2MemTransfer]  DEFAULT ((0)),
	[Bonus] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk_Bonus]  DEFAULT ((0)),
	[Adjustment] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk_Adjustment]  DEFAULT ((0)),
	[Turnover] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk_Turnover]  DEFAULT ((0)),
	[Outstanding] [money] NULL,
	[Winloss] [money] NOT NULL,
	[ClosingBalance] [money] NULL,
	[recommend] [int] NOT NULL,
	[mrecommend] [int] NOT NULL,
	[srecommend] [int] NOT NULL,
	[actualrate] [float] NULL,
	[Transfer3rd] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk_Transfer3rd]  DEFAULT ((0)),
	[DrawGame] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk_DrawGame]  DEFAULT ((0))
) ON [DepWL_bk]

GO

/****** Object:  Index [CIX_rptDepWinlost_bk]    Script Date: 01/23/2010 05:13:31 ******/
CREATE UNIQUE CLUSTERED INDEX [CIX_rptDepWinlost_bk] ON [dbo].[rptDepWinlost_bk] 
(
	[winlostdate] ASC,
	[custid] ASC,
	[currency] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DepWL_bk]
GO

/****** Object:  Index [IX_srecommend]    Script Date: 01/23/2010 05:13:31 ******/
CREATE NONCLUSTERED INDEX [IX_srecommend] ON [dbo].[rptDepWinlost_bk] 
(
	[srecommend] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DepWL_bk_Index]
GO

/****** Object:  Index [IX_Winlostdate]    Script Date: 01/23/2010 05:13:31 ******/
CREATE NONCLUSTERED INDEX [IX_Winlostdate] ON [dbo].[rptDepWinlost_bk] 
(
	[winlostdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DepWL_bk_Index]