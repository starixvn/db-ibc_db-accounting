USE [master]
GO
ALTER DATABASE [bodb_Archive04-05] ADD FILEGROUP [SUM_2005]
GO
ALTER DATABASE [bodb_Archive04-05] ADD FILE ( NAME = N'Sum_winloss_2005', FILENAME = N'P:\Archive\2004-2005\Sum_winloss_2005.ndf' , SIZE = 2048KB , FILEGROWTH = 1024KB ) TO FILEGROUP [SUM_2005]
GO
----------------

USE [bodb_Archive04-05]
GO
/****** Object:  Table [dbo].[sum_winloss_2005]    Script Date: 11/21/2009 09:18:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[sum_winloss_2005](
	[keyid] [int] NOT NULL,
	[winlostdate] [datetime] NULL,
	[username] [nvarchar](50) NULL,
	[custid] [int] NULL,
	[roleid] [int] NULL,
	[recommend] [int] NULL,
	[mrecommend] [int] NULL,
	[srecommend] [int] NULL,
	[turnover] [money] NULL,
	[winlost] [money] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,
	[BetCount] [int] NULL,
	[grosscomm] [money] NULL,
	[sporttype] [tinyint] NOT NULL,
	[bettype] [tinyint] NOT NULL
) ON [SUM_2005]

GO

/****** Object:  Index [CIX_sum_winloss_2005]    Script Date: 11/21/2009 09:18:17 ******/
CREATE CLUSTERED INDEX [CIX_sum_winloss_2005] ON [dbo].[sum_winloss_2005] 
(
	[winlostdate] ASC,
	[srecommend] ASC,
	[mrecommend] ASC,
	[recommend] ASC,
	[roleid] ASC,
	[sporttype] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [SUM_2005]
GO
GRANT SELECT ON [dbo].[sum_winloss_2005] TO [vnteam]
-----------------
--IMPORT DATA