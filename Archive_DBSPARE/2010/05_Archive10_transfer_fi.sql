--select min(winlostdate) from transfer_fi : 2010-01-01 00:00:00
 
 USE [master]

ALTER DATABASE [bodb_Archive10] ADD FILEGROUP [TRANSFI]
GO
ALTER DATABASE [bodb_Archive10] ADD FILE ( NAME = N'bodb_Archive10_TRANSFI-1', FILENAME = N'Q:\Archive\2010\bodb_Archive10_TRANSFI-1.ndf' , SIZE = 2048KB , FILEGROWTH = 16384KB ) TO FILEGROUP [TRANSFI]
GO

USE [bodb_Archive10]
GO

/****** Object:  Table [dbo].[transfer_fi]    Script Date: 03/31/2013 22:56:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[transfer_fi](
	[transid] [bigint] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[bettype] [smallint] NULL,
	[actual_stake] [money] NOT NULL,
	[winlost] [money] NOT NULL,
	[TransDesc] [nvarchar](300) NULL,
	[winlostdate] [smalldatetime] NOT NULL,
	[recommend] [int] NOT NULL,
	[mrecommend] [int] NOT NULL,
	[srecommend] [int] NOT NULL,
	[currency] [tinyint] NULL,
	[refno] [bigint] NOT NULL,
	[creator] [int] NULL,
	[CheckerID] [int] NULL,
	[CheckerName] [varchar](50) NULL,
	[checkTime] [datetime] NULL,
	[ActualRate] [float] NULL,
	[isReversal] [bit] NULL
) ON [TRANSFI]

GO

SET ANSI_PADDING OFF
GO


USE [bodb_Archive10]
/****** Object:  Index [CIX_winlostdate]    Script Date: 03/31/2013 22:56:44 ******/
CREATE CLUSTERED INDEX [CIX_winlostdate] ON [dbo].[transfer_fi] 
(
	[winlostdate] ASC,
	[custid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TRANSFI]
GO


USE [bodb_Archive10]
/****** Object:  Index [IX_refno]    Script Date: 03/31/2013 22:56:44 ******/
CREATE NONCLUSTERED INDEX [IX_refno] ON [dbo].[transfer_fi] 
(
	[refno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TRANSFI]
GO
---
--IMPORT DATA
SELECT     transid, custid, transdate, bettype, actual_stake, winlost, TransDesc, winlostdate, recommend, mrecommend, srecommend, currency, refno, 
                      creator, CheckerID, CheckerName, checkTime, ActualRate, isReversal
FROM         transfer_fi with (nolock) 
where winlostdate BETWEEN
'2010/01/01' AND 	'2010/12/31 23:59:00'