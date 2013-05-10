----------------------------------------------
---2
-- create folder G:\IBC_DB\bodb_Archive\BETM
-------------------------------
--CREATE FILEGROUPS and FILES
USE bodb_Archive
GO

ALTER DATABASE bodb_Archive ADD filegroup [BETM_10M01]
ALTER DATABASE bodb_Archive ADD filegroup [BETM_10M02]
ALTER DATABASE bodb_Archive ADD filegroup [BETM_10M03]
ALTER DATABASE bodb_Archive ADD filegroup [BETM_10M04]
ALTER DATABASE bodb_Archive ADD filegroup [BETM_10M05]
ALTER DATABASE bodb_Archive ADD filegroup [BETM_10M06]
ALTER DATABASE bodb_Archive ADD filegroup [BETM_10M07]
ALTER DATABASE bodb_Archive ADD filegroup [BETM_10M08]
ALTER DATABASE bodb_Archive ADD filegroup [BETM_10M09]
ALTER DATABASE bodb_Archive ADD filegroup [BETM_10M10]
ALTER DATABASE bodb_Archive ADD filegroup [BETM_10M11]
ALTER DATABASE bodb_Archive ADD filegroup [BETM_10M12]

ALTER DATABASE bodb_Archive ADD filegroup [BETM_MAX]

GO

--------------

ALTER DATABASE bodb_Archive ADD FILE (name = 'BETM_10M01', filename ='M:\IBC_DB\bodb_Archive\BETM\BETM_10M01.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETM_10M01]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETM_10M02', filename ='M:\IBC_DB\bodb_Archive\BETM\BETM_10M02.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETM_10M02]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETM_10M03', filename ='M:\IBC_DB\bodb_Archive\BETM\BETM_10M03.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETM_10M03]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETM_10M04', filename ='M:\IBC_DB\bodb_Archive\BETM\BETM_10M04.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETM_10M04]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETM_10M05', filename ='M:\IBC_DB\bodb_Archive\BETM\BETM_10M05.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETM_10M05]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETM_10M06', filename ='M:\IBC_DB\bodb_Archive\BETM\BETM_10M06.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETM_10M06]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETM_10M07', filename ='M:\IBC_DB\bodb_Archive\BETM\BETM_10M07.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETM_10M07]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETM_10M08', filename ='M:\IBC_DB\bodb_Archive\BETM\BETM_10M08.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETM_10M08]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETM_10M09', filename ='M:\IBC_DB\bodb_Archive\BETM\BETM_10M09.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETM_10M09]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETM_10M10', filename ='M:\IBC_DB\bodb_Archive\BETM\BETM_10M10.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETM_10M10]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETM_10M11', filename ='M:\IBC_DB\bodb_Archive\BETM\BETM_10M11.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETM_10M11]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETM_10M12', filename ='M:\IBC_DB\bodb_Archive\BETM\BETM_10M12.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETM_10M12]

ALTER DATABASE bodb_Archive ADD FILE (name = 'BETM_MAX', filename ='M:\IBC_DB\bodb_Archive\BETM\BETM_MAX.ndf', SIZE = 512KB ,FILEGROWTH = 16MB ) TO filegroup [BETM_MAX]

GO
----

--2
--Create partition function
CREATE PARTITION FUNCTION pf_BETM_monthly (SMALLDATETIME) AS
RANGE LEFT FOR VALUES
(    
    '2010/01/31 23:59:00',
    '2010/02/28 23:59:00',
    '2010/03/31 23:59:00',
    '2010/04/30 23:59:00',
    '2010/05/31 23:59:00',
    '2010/06/30 23:59:00',
    '2010/07/31 23:59:00',
    '2010/08/31 23:59:00',
    '2010/09/30 23:59:00',
    '2010/10/31 23:59:00',
    '2010/11/30 23:59:00',
    '2010/12/31 23:59:00'
)

--Create partition schema
CREATE PARTITION SCHEME ps_BETM_monthly
AS PARTITION pf_BETM_monthly
TO
    (	
	[BETM_10M01], 
	[BETM_10M02], 
	[BETM_10M03], 
	[BETM_10M04], 
	[BETM_10M05], 
	[BETM_10M06], 
	[BETM_10M07], 
	[BETM_10M08], 
	[BETM_10M09], 
	[BETM_10M10], 
	[BETM_10M11], 
	[BETM_10M12],
	
	[BETM_MAX]
	
 )                
GO
---


USE [bodb_Archive]
GO
/****** Object:  Table [dbo].[bettransm2]    Script Date: 04/01/2013 01:48:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[bettransm2](
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
	[statusID] [tinyint] NULL,
	[bettype] [smallint] NULL,
	[recommdate] [datetime] NULL
)

GO
SET ANSI_PADDING OFF
GO
USE [bodb_Archive]
GO
/****** Object:  Index [IX_transid]    Script Date: 04/01/2013 01:51:52 ******/
CREATE NONCLUSTERED INDEX [IX_transid] ON [dbo].[bettransm2] 
(
	[transid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON ps_BETM_monthly(winlostdate)
GO

/****** Object:  Index [IX_bettransm2]    Script Date: 04/01/2013 01:48:29 ******/
CREATE CLUSTERED INDEX [IX_bettransm2] ON [dbo].[bettransm2] 
(
	[refno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON ps_BETM_monthly(winlostdate)
GO

/****** Object:  Index [IX_winlostdate]    Script Date: 04/01/2013 01:48:29 ******/
CREATE NONCLUSTERED INDEX [IX_winlostdate] ON [dbo].[bettransm2] 
(
	[winlostdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON ps_BETM_monthly(winlostdate)
GO
GRANT SELECT ON [dbo].[bettransm2] TO [bodbAdminNet]
GO
GRANT SELECT ON [dbo].[bettransm2] TO [bodbDownlineNet]
GO
GRANT SELECT ON [dbo].[bettransm2] TO [bodbDownlineNetView]
GO
GRANT SELECT ON [dbo].[bettransm2] TO [bodbExtAccNet]
GO
GRANT SELECT ON [dbo].[bettransm2] TO [bodbLicenseeNet]