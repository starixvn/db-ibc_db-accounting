 ----------------------------------------------
---2
-- create folder G:\IBC_DB\bodb_Archive\BETG
-------------------------------
--CREATE FILEGROUPS and FILES
USE bodb_Archive
GO

ALTER DATABASE bodb_Archive ADD filegroup [BETG_12M01]
ALTER DATABASE bodb_Archive ADD filegroup [BETG_12M02]
ALTER DATABASE bodb_Archive ADD filegroup [BETG_12M03]
ALTER DATABASE bodb_Archive ADD filegroup [BETG_12M04]
ALTER DATABASE bodb_Archive ADD filegroup [BETG_12M05]
ALTER DATABASE bodb_Archive ADD filegroup [BETG_12M06]
ALTER DATABASE bodb_Archive ADD filegroup [BETG_12M07]
ALTER DATABASE bodb_Archive ADD filegroup [BETG_12M08]
ALTER DATABASE bodb_Archive ADD filegroup [BETG_12M09]
ALTER DATABASE bodb_Archive ADD filegroup [BETG_12M10]
ALTER DATABASE bodb_Archive ADD filegroup [BETG_12M11]
ALTER DATABASE bodb_Archive ADD filegroup [BETG_12M12]

ALTER DATABASE bodb_Archive ADD filegroup [BETG_MAX]

GO

--------------

ALTER DATABASE bodb_Archive ADD FILE (name = 'BETG_12M01', filename ='E:\IBC_DB\bodb_Archive\BETG\BETG_12M01.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETG_12M01]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETG_12M02', filename ='E:\IBC_DB\bodb_Archive\BETG\BETG_12M02.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETG_12M02]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETG_12M03', filename ='E:\IBC_DB\bodb_Archive\BETG\BETG_12M03.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETG_12M03]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETG_12M04', filename ='E:\IBC_DB\bodb_Archive\BETG\BETG_12M04.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETG_12M04]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETG_12M05', filename ='E:\IBC_DB\bodb_Archive\BETG\BETG_12M05.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETG_12M05]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETG_12M06', filename ='E:\IBC_DB\bodb_Archive\BETG\BETG_12M06.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETG_12M06]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETG_12M07', filename ='E:\IBC_DB\bodb_Archive\BETG\BETG_12M07.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETG_12M07]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETG_12M08', filename ='E:\IBC_DB\bodb_Archive\BETG\BETG_12M08.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETG_12M08]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETG_12M09', filename ='E:\IBC_DB\bodb_Archive\BETG\BETG_12M09.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETG_12M09]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETG_12M10', filename ='E:\IBC_DB\bodb_Archive\BETG\BETG_12M10.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETG_12M10]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETG_12M11', filename ='E:\IBC_DB\bodb_Archive\BETG\BETG_12M11.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETG_12M11]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETG_12M12', filename ='E:\IBC_DB\bodb_Archive\BETG\BETG_12M12.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETG_12M12]

ALTER DATABASE bodb_Archive ADD FILE (name = 'BETG_MAX', filename ='E:\IBC_DB\bodb_Archive\BETG\BETG_MAX.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETG_MAX]

GO
----

--2
--Create partition function
CREATE PARTITION FUNCTION pf_BETG_monthly (SMALLDATETIME) AS
RANGE LEFT FOR VALUES
(    
    '2012/01/31 23:59:00',
    '2012/02/29 23:59:00',
    '2012/03/31 23:59:00',
    '2012/04/30 23:59:00',
    '2012/05/31 23:59:00',
    '2012/06/30 23:59:00',
    '2012/07/31 23:59:00',
    '2012/08/31 23:59:00',
    '2012/09/30 23:59:00',
    '2012/10/31 23:59:00',
    '2012/11/30 23:59:00',
    '2012/12/31 23:59:00'
)

--Create partition schema
CREATE PARTITION SCHEME ps_BETG_monthly
AS PARTITION pf_BETG_monthly
TO
    (	
	[BETG_12M01], 
	[BETG_12M02], 
	[BETG_12M03], 
	[BETG_12M04], 
	[BETG_12M05], 
	[BETG_12M06], 
	[BETG_12M07], 
	[BETG_12M08], 
	[BETG_12M09], 
	[BETG_12M10], 
	[BETG_12M11], 
	[BETG_12M12],
	
	[BETG_MAX]
	
 )                
GO
---
USE [bodb_Archive]
GO

/****** Object:  Table [dbo].[bettransG2]    Script Date: 04/01/2013 12:08:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[bettransG2](
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
	[SiteID] [varchar](7) NULL
)

GO

SET ANSI_PADDING OFF
GO
USE [bodb_Archive]
GO

/****** Object:  Index [IX_transid]    Script Date: 04/01/2013 12:14:44 ******/
CREATE NONCLUSTERED INDEX [IX_transid] ON [dbo].[bettransG2] 
(
	[transid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON ps_BETG_monthly(winlostdate)
GO






USE [bodb_Archive]
/****** Object:  Index [IX_bettransG2]    Script Date: 04/01/2013 12:08:51 ******/
CREATE CLUSTERED INDEX [IX_bettransG2] ON [dbo].[bettransG2] 
(
	[refno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON ps_BETG_monthly(winlostdate)
GO


USE [bodb_Archive]
/****** Object:  Index [IX_winlostdate]    Script Date: 04/01/2013 12:08:51 ******/
CREATE NONCLUSTERED INDEX [IX_winlostdate] ON [dbo].[bettransG2] 
(
	[winlostdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON ps_BETG_monthly(winlostdate)
GO

GRANT SELECT ON [dbo].[bettransG2] TO [bodbAdminNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[bettransG2] TO [bodbDownlineNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[bettransG2] TO [bodbDownlineNetView] AS [dbo]
GO

GRANT SELECT ON [dbo].[bettransG2] TO [bodbExtAccNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[bettransG2] TO [bodbLicenseeNet] AS [dbo]
GO


