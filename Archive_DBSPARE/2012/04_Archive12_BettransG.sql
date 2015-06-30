---MIN WINLOSTDATE: 2012-03-14 00:00:00

  USE [master]
GO
ALTER DATABASE [bodb_Archive12] ADD FILEGROUP [BettransG]
GO
ALTER DATABASE [bodb_Archive12] ADD FILE ( NAME = N'bodb_Archive12_BettransG-1', FILENAME = N'Q:\Archive\2012\bodb_Archive12_BettransG-1.ndf' , SIZE = 2048KB , FILEGROWTH = 16MB ) TO FILEGROUP [BettransG]
GO
ALTER DATABASE [bodb_Archive12] ADD FILE ( NAME = N'bodb_Archive12_BettransG-2', FILENAME = N'Q:\Archive\2012\bodb_Archive12_BettransG-2.ndf' , SIZE = 2048KB , FILEGROWTH = 16MB ) TO FILEGROUP [BettransG]
GO
ALTER DATABASE [bodb_Archive12] ADD FILE ( NAME = N'bodb_Archive12_BettransG-3', FILENAME = N'Q:\Archive\2012\bodb_Archive12_BettransG-3.ndf' , SIZE = 2048KB , FILEGROWTH = 16MB ) TO FILEGROUP [BettransG]
GO

USE [bodb_Archive12]
GO
/****** Object:  Table [dbo].[bettransG]    Script Date: 03/30/2013 06:36:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[bettransG](
	[transid] [int] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[oddsid] [int] NOT NULL,
	[odds] [smallmoney] NULL,
	[stake] [money] NOT NULL,
	[status] [nvarchar](10) NULL,
	[winlost] [money] NULL,
	[betteam] [nvarchar](10) NULL,
	[creator] [int] NOT NULL,
	[refno] [bigint] NOT NULL,
	[winlostdate] [smalldatetime] NULL,
	[betfrom] [nvarchar](1) NULL,
	[checktime] [smalldatetime] NULL,
	[apositiontaking] [smallmoney] NULL,
	[mpositiontaking] [smallmoney] NULL,
	[tpositiontaking] [smallmoney] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[playerdiscount] [decimal](9, 8) NULL,
	[discount] [decimal](9, 8) NULL,
	[adiscount] [decimal](9, 8) NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[actualrate] [float] NULL,
	[matchid] [int] NULL,
	[matchdate] [smalldatetime] NULL,
	[statuswinlost] [tinyint] NULL,
	[ruben] [tinyint] NULL,
	[bettype] [smallint] NULL,
	[spositiontaking] [smallmoney] NULL,
	[swinlost] [money] NULL,
	[sdiscount] [decimal](9, 8) NULL,
	[scomm] [money] NULL,
	[statusID] [tinyint] NULL,
	[virtualrate] [float] NULL,
	[SiteID] [varchar](7) NULL,
 CONSTRAINT [PK_bettransG] PRIMARY KEY NONCLUSTERED 
(
	[transid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [bettransG]
) ON [bettransG]

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [IX_bettransG]    Script Date: 03/30/2013 06:36:37 ******/
CREATE CLUSTERED INDEX [IX_bettransG] ON [dbo].[bettransG] 
(
	[refno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [bettransG]
GO

/****** Object:  Index [IX_winlostdate]    Script Date: 03/30/2013 06:36:37 ******/
CREATE NONCLUSTERED INDEX [IX_winlostdate] ON [dbo].[bettransG] 
(
	[winlostdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [BettransG]
GO


---
--IMPORT DATA

SELECT      transid, custid, transdate, oddsid, odds, stake, status, winlost, betteam, creator, refno, winlostdate, betfrom, checktime, apositiontaking, 
                      mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, 
                      statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, statusID, virtualrate, SiteID
FROM         bettransG  with (nolock) 
where winlostdate BETWEEN
'2012/01/01' AND 	'2012/12/31 23:59:00'