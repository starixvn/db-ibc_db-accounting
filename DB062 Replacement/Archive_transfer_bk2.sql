 --CREATE FILEGROUPS and FILES
USE bodb_Archive
GO

ALTER DATABASE bodb_Archive ADD filegroup [TRANSBK_10M01]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSBK_10M02]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSBK_10M03]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSBK_10M04]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSBK_10M05]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSBK_10M06]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSBK_10M07]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSBK_10M08]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSBK_10M09]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSBK_10M10]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSBK_10M11]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSBK_10M12]

ALTER DATABASE bodb_Archive ADD filegroup [TRANSBK_MAX]

--------------

ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSBK_10M01', filename ='M:\IBC_DB\bodb_Archive\TRANSBK\TRANSBK_10M01.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSBK_10M01]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSBK_10M02', filename ='M:\IBC_DB\bodb_Archive\TRANSBK\TRANSBK_10M02.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSBK_10M02]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSBK_10M03', filename ='M:\IBC_DB\bodb_Archive\TRANSBK\TRANSBK_10M03.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSBK_10M03]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSBK_10M04', filename ='M:\IBC_DB\bodb_Archive\TRANSBK\TRANSBK_10M04.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSBK_10M04]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSBK_10M05', filename ='M:\IBC_DB\bodb_Archive\TRANSBK\TRANSBK_10M05.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSBK_10M05]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSBK_10M06', filename ='M:\IBC_DB\bodb_Archive\TRANSBK\TRANSBK_10M06.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSBK_10M06]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSBK_10M07', filename ='M:\IBC_DB\bodb_Archive\TRANSBK\TRANSBK_10M07.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSBK_10M07]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSBK_10M08', filename ='M:\IBC_DB\bodb_Archive\TRANSBK\TRANSBK_10M08.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSBK_10M08]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSBK_10M09', filename ='M:\IBC_DB\bodb_Archive\TRANSBK\TRANSBK_10M09.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSBK_10M09]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSBK_10M10', filename ='M:\IBC_DB\bodb_Archive\TRANSBK\TRANSBK_10M10.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSBK_10M10]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSBK_10M11', filename ='M:\IBC_DB\bodb_Archive\TRANSBK\TRANSBK_10M11.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSBK_10M11]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSBK_10M12', filename ='M:\IBC_DB\bodb_Archive\TRANSBK\TRANSBK_10M12.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSBK_10M12]

ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSBK_MAX', filename ='M:\IBC_DB\bodb_Archive\TRANSBK\TRANSBK_MAX.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSBK_MAX]

----

--2
--Create partition function
CREATE PARTITION FUNCTION pf_TRANSBK_monthly (SMALLDATETIME) AS
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
CREATE PARTITION SCHEME ps_TRANSBK_monthly
AS PARTITION pf_TRANSBK_monthly
TO
    (	
	[TRANSBK_10M01], 
	[TRANSBK_10M02], 
	[TRANSBK_10M03], 
	[TRANSBK_10M04], 
	[TRANSBK_10M05], 
	[TRANSBK_10M06], 
	[TRANSBK_10M07], 
	[TRANSBK_10M08], 
	[TRANSBK_10M09], 
	[TRANSBK_10M10], 
	[TRANSBK_10M11], 
	[TRANSBK_10M12],
	
	[TRANSBK_MAX]
	
 )                
GO
---
--CREATE TABLE AND INDEX
---
--CREATE TABLE
USE [bodb_Archive]
GO
/****** Object:  Table [dbo].[transfer_bk]    Script Date: 08/17/2011 22:32:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[transfer_bk2](
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[Debit] [money] NOT NULL,
	[Credit] [money] NOT NULL,
	[TransDesc] [nvarchar](300) NULL,
	[winlostdate] [smalldatetime] NOT NULL,
	[recommend] [int] NOT NULL,
	[mrecommend] [int] NOT NULL,
	[srecommend] [int] NOT NULL,
	[currency] [tinyint] NULL,
	[refno] [bigint] NOT NULL,
	[creator] [int] NULL,
	[transid] [bigint] NOT NULL,
	[bettype] [smallint] NULL
)

GO

/****** Object:  Index [IX_Transfer_Data]    Script Date: 08/17/2011 22:32:14 ******/
CREATE CLUSTERED INDEX [CIX_winlostdate] ON [dbo].[transfer_bk2] 
(
	[winlostdate] ASC,
	[custid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ps_TRANSBK_monthly]([winlostdate])
--------------
--IMPORT DATA
--SHRINK ALL THE FILES
