USE [master]
GO
ALTER DATABASE [bodb_Archive] ADD FILEGROUP [Bettransm]
GO
ALTER DATABASE [bodb_Archive] ADD FILE ( NAME = N'bettransm_01', FILENAME = N'G:\IBC_DB\bodb_Archive\bodb_Archive_bettransm_01.ndf' , SIZE = 2048KB , FILEGROWTH = 32MB ) TO FILEGROUP [Bettransm]
GO
ALTER DATABASE [bodb_Archive] ADD FILE ( NAME = N'bettransm_02', FILENAME = N'G:\IBC_DB\bodb_Archive\bodb_Archive_bettransm_02.ndf' , SIZE = 2048KB , FILEGROWTH = 32MB ) TO FILEGROUP [Bettransm]
GO

ALTER DATABASE [bodb_Archive] ADD FILEGROUP [Bettransm_Index]
GO
ALTER DATABASE [bodb_Archive] ADD FILE ( NAME = N'bettransm_Index', FILENAME = N'G:\IBC_DB\bodb_Archive\bodb_Archive_bettransm_Index.ndf' , SIZE = 2048KB , FILEGROWTH = 32MB ) TO FILEGROUP [Bettransm_Index]
GO
------------------
USE [bodb_Archive]
GO
CREATE TABLE [dbo].[bettransm](
	[transid] [int] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[oddsid] [int] NOT NULL,
	[hdp1] [smallmoney] NULL,
	[hdp2] [smallmoney] NULL,
	[odds] [smallmoney] NULL,
	[stake] [money] NOT NULL,
	[status] [varchar](10) NULL,
	[winlost] [money] NULL,
	[livehomescore] [smallint] NULL,
	[liveawayscore] [smallint] NULL,
	[liveindicator] [bit] NULL,
	[betteam] [varchar](10) NULL,
	[creator] [int] NOT NULL,
	[refno] [bigint] NOT NULL,
	[comstatus] [varchar](20) NULL,
	[winlostdate] [smalldatetime] NULL,
	[betfrom] [varchar](1) NULL,
	[betcheck] [varchar](50) NULL,
	[checktime] [smalldatetime] NULL,
	[oddsspread] [smallmoney] NULL,
	
	[apositiontaking] [smallmoney] NULL,
	[mpositiontaking] [smallmoney] NULL,
	[spositiontaking] [smallmoney] NULL,
	[tpositiontaking] [smallmoney] NULL,
	
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,

	[playerdiscount] [decimal](9, 8) NULL,
	[discount] [decimal](9, 8) NULL,
	[adiscount] [decimal](9, 8) NULL,
	[sdiscount] [decimal](9, 8) NULL,

	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,

	[actualrate] [float] NULL,
	[matchid] [int] NULL,
	[matchdate] [smalldatetime] NULL,
	[finalodds] [smallmoney] NULL,
	[isfinish] [char](1) NULL,
	[statuswinlost] [tinyint] NULL,
	[ruben] [tinyint] NULL,
	[bettype] [tinyint] NULL,
	
 CONSTRAINT [PK_bettransm] PRIMARY KEY NONCLUSTERED 
(
	[transid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Bettransm]
) ON [Bettransm]

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [IX_bettransm]    Script Date: 11/22/2009 15:36:48 ******/
CREATE CLUSTERED INDEX [IX_bettransm] ON [dbo].[bettransm] 
(
	[refno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
ON [Bettransm]

GO
CREATE NONCLUSTERED INDEX [IX_winlostdate] ON [dbo].[bettransm] 
(
	[winlostdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
ON [Bettransm_Index]