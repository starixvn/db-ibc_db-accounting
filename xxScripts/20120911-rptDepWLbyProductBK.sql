USE [master]
GO
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_12M09]
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_12M10]
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_12M11]
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_12M12]
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_13M01]
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_13M02]
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_13M03]
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_13M04]
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_13M05]
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_13M06]
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_13M07]
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_13M08]
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_13M09]
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_13M10]
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_13M11]
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLbyProductBK_13M12]

ALTER DATABASE [bodb_Report] ADD filegroup [DepWLbyProductBK_MAX]

GO
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_12M09', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_12M09.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_12M09]
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_12M10', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_12M10.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_12M10]
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_12M11', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_12M11.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_12M11]
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_12M12', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_12M12.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_12M12]
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_13M01', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_13M01.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_13M01]
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_13M02', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_13M02.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_13M02]
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_13M03', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_13M03.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_13M03]
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_13M04', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_13M04.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_13M04]
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_13M05', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_13M05.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_13M05]
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_13M06', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_13M06.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_13M06]
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_13M07', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_13M07.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_13M07]
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_13M08', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_13M08.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_13M08]
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_13M09', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_13M09.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_13M09]
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_13M10', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_13M10.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_13M10]
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_13M11', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_13M11.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_13M11]
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLbyProductBK_13M12', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_13M12.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [DepWLbyProductBK_13M12]

ALTER DATABASE [bodb_Report] ADD FILE (NAME = 'DepWLbyProductBK_MAX', FILENAME = N'M:\IBC_DB\bodb_report\DepWLbyProduct\DepWLbyProductBK_MAX.ndf', SIZE = 1024KB ,FILEGROWTH = 100 MB ) TO filegroup [DepWLbyProductBK_MAX]

GO

USE [bodb_report]
GO
CREATE PARTITION FUNCTION pf_DepWLbyProductBK_monthly (DATETIME) AS
RANGE LEFT FOR VALUES
(    
    '2012/09/30 23:59:59.997',
    '2012/10/31 23:59:59.997',
	'2012/11/30 23:59:59.997',
	'2012/12/31 23:59:59.997',
	'2013/01/31 23:59:59.997',
	'2013/02/28 23:59:59.997',
	'2013/03/31 23:59:59.997',
	'2013/04/30 23:59:59.997',
	'2013/05/31 23:59:59.997',
	'2013/06/30 23:59:59.997',
	'2013/07/31 23:59:59.997',
	'2013/08/31 23:59:59.997',
	'2013/09/30 23:59:59.997',
    '2013/10/31 23:59:59.997',
	'2013/11/30 23:59:59.997',
	'2013/12/31 23:59:59.997'
)

--Create partition schema
CREATE PARTITION SCHEME ps_DepWLbyProductBK_monthly
AS PARTITION pf_DepWLbyProductBK_monthly
TO
    (
		[DepWLbyProductBK_12M09],
		[DepWLbyProductBK_12M10],
		[DepWLbyProductBK_12M11],
		[DepWLbyProductBK_12M12],
		[DepWLbyProductBK_13M01],
		[DepWLbyProductBK_13M02],
		[DepWLbyProductBK_13M03],
		[DepWLbyProductBK_13M04],
		[DepWLbyProductBK_13M05],
		[DepWLbyProductBK_13M06],
		[DepWLbyProductBK_13M07],
		[DepWLbyProductBK_13M08],
		[DepWLbyProductBK_13M09],
		[DepWLbyProductBK_13M10],
		[DepWLbyProductBK_13M11],
		[DepWLbyProductBK_13M12],
		
		[DepWLbyProductBK_MAX]	
 )                
GO

CREATE TABLE [dbo].[rptDepWinlostByProduct_BK](
	[winlostdate] [datetime] NOT NULL,
	[custid] [int] NOT NULL,
	[sporttype] [smallint] NOT NULL,
	[turnover] [money] NULL,
	[drawTO] [money] NULL,
	[winlost] [money] NULL,
	[playercomm] [money] NULL,
	[BetCount] [int] NULL,

)

CREATE UNIQUE CLUSTERED INDEX [CIX_rptDepWinlostByProduct_BK] ON [dbo].[rptDepWinlostByProduct_BK] 
(
	[custid] ASC,
	[winlostdate] ASC,
	[sporttype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) 
ON ps_DepWLbyProductBK_monthly(winlostdate)