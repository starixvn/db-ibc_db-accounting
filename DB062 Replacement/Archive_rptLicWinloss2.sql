 
----------------------------------------------
---2
-- create folder G:\IBC_DB\bodb_Licensee\rptLicWL
-------------------------------
--CREATE FILEGROUPS and FILES
USE bodb_Licensee
GO

ALTER DATABASE bodb_Licensee ADD filegroup [rptLicWL_10M01]
ALTER DATABASE bodb_Licensee ADD filegroup [rptLicWL_10M02]
ALTER DATABASE bodb_Licensee ADD filegroup [rptLicWL_10M03]
ALTER DATABASE bodb_Licensee ADD filegroup [rptLicWL_10M04]
ALTER DATABASE bodb_Licensee ADD filegroup [rptLicWL_10M05]
ALTER DATABASE bodb_Licensee ADD filegroup [rptLicWL_10M06]
ALTER DATABASE bodb_Licensee ADD filegroup [rptLicWL_10M07]
ALTER DATABASE bodb_Licensee ADD filegroup [rptLicWL_10M08]
ALTER DATABASE bodb_Licensee ADD filegroup [rptLicWL_10M09]
ALTER DATABASE bodb_Licensee ADD filegroup [rptLicWL_10M10]
ALTER DATABASE bodb_Licensee ADD filegroup [rptLicWL_10M11]
ALTER DATABASE bodb_Licensee ADD filegroup [rptLicWL_10M12]

ALTER DATABASE bodb_Licensee ADD filegroup [rptLicWL_MAX]


--------------

ALTER DATABASE bodb_Licensee ADD FILE (name = 'rptLicWL_10M01', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M01.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [rptLicWL_10M01]
ALTER DATABASE bodb_Licensee ADD FILE (name = 'rptLicWL_10M02', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M02.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [rptLicWL_10M02]
ALTER DATABASE bodb_Licensee ADD FILE (name = 'rptLicWL_10M03', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M03.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [rptLicWL_10M03]
ALTER DATABASE bodb_Licensee ADD FILE (name = 'rptLicWL_10M04', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M04.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [rptLicWL_10M04]
ALTER DATABASE bodb_Licensee ADD FILE (name = 'rptLicWL_10M05', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M05.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [rptLicWL_10M05]
ALTER DATABASE bodb_Licensee ADD FILE (name = 'rptLicWL_10M06', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M06.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [rptLicWL_10M06]
ALTER DATABASE bodb_Licensee ADD FILE (name = 'rptLicWL_10M07', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M07.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [rptLicWL_10M07]
ALTER DATABASE bodb_Licensee ADD FILE (name = 'rptLicWL_10M08', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M08.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [rptLicWL_10M08]
ALTER DATABASE bodb_Licensee ADD FILE (name = 'rptLicWL_10M09', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M09.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [rptLicWL_10M09]
ALTER DATABASE bodb_Licensee ADD FILE (name = 'rptLicWL_10M10', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M10.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [rptLicWL_10M10]
ALTER DATABASE bodb_Licensee ADD FILE (name = 'rptLicWL_10M11', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M11.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [rptLicWL_10M11]
ALTER DATABASE bodb_Licensee ADD FILE (name = 'rptLicWL_10M12', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M12.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [rptLicWL_10M12]

ALTER DATABASE bodb_Licensee ADD FILE (name = 'rptLicWL_MAX', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_MAX.ndf', SIZE = 1MB ,FILEGROWTH = 32MB ) TO filegroup [rptLicWL_MAX]


----

--2
--Create partition function
CREATE PARTITION FUNCTION pf_rptLicWL_monthly (SMALLDATETIME) AS
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
CREATE PARTITION SCHEME ps_rptLicWL_monthly
AS PARTITION pf_rptLicWL_monthly
TO
    (	
	[rptLicWL_10M01], 
	[rptLicWL_10M02], 
	[rptLicWL_10M03], 
	[rptLicWL_10M04], 
	[rptLicWL_10M05], 
	[rptLicWL_10M06], 
	[rptLicWL_10M07], 
	[rptLicWL_10M08], 
	[rptLicWL_10M09], 
	[rptLicWL_10M10], 
	[rptLicWL_10M11], 
	[rptLicWL_10M12],
	
	[rptLicWL_MAX]
	
 )                
GO
---
--CREATE TABLE AND INDEX

/****** Object:  Table [dbo].[bettrans_bk2]    Script Date: 11/15/2010 08:50:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[rptLicWinloss2](
	[keyid] [bigint] IDENTITY(1,1) NOT NULL,
	[winlostdate] [smalldatetime] NULL,
	[username] [nvarchar](50) NULL,
	[username2] [nvarchar](50) NULL,
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
	[Currency] [smallint] NULL,
	[sporttype] [smallint] NOT NULL,
	[bettype] [smallint] NOT NULL,
	[statusID] [smallint] NOT NULL,
	[isBA] [bit] NULL CONSTRAINT [DF_rptLicWinloss2_IsBA]  DEFAULT ((0))
)


USE [bodb_Licensee]
GO
CREATE CLUSTERED INDEX [CIX_rptLicWinloss] ON [dbo].[rptLicWinloss2] 
(
	[winlostdate] ASC,
	[recommend] ASC,
	[roleid] ASC,
	[sporttype] ASC,
	[bettype] ASC,
	[statusID] ASC,
	[isBA] ASC
)WITH (STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ps_rptLicWL_monthly]([winlostdate])
GO

