 --CREATE FILEGROUPS and FILES
USE bodb_Archive
GO

ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_08M07]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_08M08]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_08M09]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_08M10]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_08M11]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_08M12]

ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_09M01]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_09M02]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_09M03]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_09M04]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_09M05]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_09M06]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_09M07]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_09M08]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_09M09]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_09M10]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_09M11]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_09M12]

ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_10M01]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_10M02]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_10M03]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_10M04]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_10M05]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_10M06]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_10M07]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_10M08]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_10M09]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_10M10]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_10M11]
ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_10M12]

ALTER DATABASE bodb_Archive ADD filegroup [TRANSFER_MAX]

--------------
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_08M07', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_08M07.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_08M07]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_08M08', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_08M08.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_08M08]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_08M09', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_08M09.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_08M09]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_08M10', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_08M10.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_08M10]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_08M11', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_08M11.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_08M11]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_08M12', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_08M12.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_08M12]

ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_09M01', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_09M01.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_09M01]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_09M02', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_09M02.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_09M02]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_09M03', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_09M03.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_09M03]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_09M04', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_09M04.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_09M04]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_09M05', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_09M05.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_09M05]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_09M06', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_09M06.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_09M06]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_09M07', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_09M07.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_09M07]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_09M08', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_09M08.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_09M08]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_09M09', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_09M09.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_09M09]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_09M10', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_09M10.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_09M10]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_09M11', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_09M11.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_09M11]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_09M12', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_09M12.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_09M12]

ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_10M01', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_10M01.ndf', SIZE = 100MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_10M01]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_10M02', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_10M02.ndf', SIZE = 10 MB ,FILEGROWTH = 32 MB ) TO filegroup [TRANSFER_10M02]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_10M03', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_10M03.ndf', SIZE = 10 MB ,FILEGROWTH = 32 MB ) TO filegroup [TRANSFER_10M03]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_10M04', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_10M04.ndf', SIZE = 10 MB ,FILEGROWTH = 32 MB ) TO filegroup [TRANSFER_10M04]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_10M05', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_10M05.ndf', SIZE = 10 MB ,FILEGROWTH = 32 MB ) TO filegroup [TRANSFER_10M05]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_10M06', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_10M06.ndf', SIZE = 10 MB ,FILEGROWTH = 32 MB ) TO filegroup [TRANSFER_10M06]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_10M07', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_10M07.ndf', SIZE = 10 MB ,FILEGROWTH = 32 MB ) TO filegroup [TRANSFER_10M07]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_10M08', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_10M08.ndf', SIZE = 10 MB ,FILEGROWTH = 32 MB ) TO filegroup [TRANSFER_10M08]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_10M09', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_10M09.ndf', SIZE = 10 MB ,FILEGROWTH = 32 MB ) TO filegroup [TRANSFER_10M09]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_10M10', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_10M10.ndf', SIZE = 10 MB ,FILEGROWTH = 32 MB ) TO filegroup [TRANSFER_10M10]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_10M11', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_10M11.ndf', SIZE = 10 MB ,FILEGROWTH = 32 MB ) TO filegroup [TRANSFER_10M11]
ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_10M12', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_10M12.ndf', SIZE = 10 MB ,FILEGROWTH = 32 MB ) TO filegroup [TRANSFER_10M12]

ALTER DATABASE bodb_Archive ADD FILE (name = 'TRANSFER_MAX', filename ='G:\IBC_DB\bodb_Archive\TRANSFER\Transfer_MAX.ndf', SIZE = 10 MB ,FILEGROWTH = 32 MB ) TO filegroup [TRANSFER_MAX]

----

--2
--Create partition function
CREATE PARTITION FUNCTION pf_TRANSFER_monthly (SMALLDATETIME) AS
RANGE LEFT FOR VALUES
(
    '2008/07/31 23:59:00',
    '2008/08/31 23:59:00',
    '2008/09/30 23:59:00',
    '2008/10/31 23:59:00',
    '2008/11/30 23:59:00',
    '2008/12/31 23:59:00',
    
    '2009/01/31 23:59:00',
    '2009/02/28 23:59:00',
    '2009/03/31 23:59:00',
    '2009/04/30 23:59:00',
    '2009/05/31 23:59:00',
    '2009/06/30 23:59:00',
    '2009/07/31 23:59:00',
    '2009/08/31 23:59:00',
    '2009/09/30 23:59:00',
    '2009/10/31 23:59:00',
    '2009/11/30 23:59:00',
    '2009/12/31 23:59:00',
    
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
CREATE PARTITION SCHEME ps_TRANSFER_monthly
AS PARTITION pf_TRANSFER_monthly
TO
    (
	[TRANSFER_08M07], 
	[TRANSFER_08M08], 
	[TRANSFER_08M09], 
	[TRANSFER_08M10], 
	[TRANSFER_08M11], 
	[TRANSFER_08M12],
	
	[TRANSFER_09M01], 
	[TRANSFER_09M02], 
	[TRANSFER_09M03], 
	[TRANSFER_09M04], 
	[TRANSFER_09M05], 
	[TRANSFER_09M06], 
	[TRANSFER_09M07], 
	[TRANSFER_09M08], 
	[TRANSFER_09M09], 
	[TRANSFER_09M10], 
	[TRANSFER_09M11], 
	[TRANSFER_09M12],
	
	[TRANSFER_10M01], 
	[TRANSFER_10M02], 
	[TRANSFER_10M03], 
	[TRANSFER_10M04], 
	[TRANSFER_10M05], 
	[TRANSFER_10M06], 
	[TRANSFER_10M07], 
	[TRANSFER_10M08], 
	[TRANSFER_10M09], 
	[TRANSFER_10M10], 
	[TRANSFER_10M11], 
	[TRANSFER_10M12],
	
	[TRANSFER_MAX]
	
 )                
GO
---
--CREATE TABLE AND INDEX
---
--CREATE TABLE
CREATE TABLE [dbo].[transfer_bk](
	[transid] [int] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[Debit] [money] NOT NULL,
	[Credit] [money] NOT NULL,
	[TransDesc] [nvarchar](300) NULL,
	[winlostdate] [smalldatetime] NOT NULL,
	[recommend] [int] NOT NULL,
	[mrecommend] [int] NOT NULL,
	[srecommend] [int] NOT NULL,
	[bettype] [tinyint] NOT NULL,
	[currency] [tinyint] NULL,
	[refno] [bigint] NOT NULL,
	[creator] [int] NULL
) ON [PRIMARY]

GO

/****** Object:  Index [IX_Transfer_Data]    Script Date: 11/15/2009 09:44:04 ******/
CREATE CLUSTERED INDEX [IX_Transfer_Data] ON [dbo].[transfer_bk] 
(
	[winlostdate] ASC,
	[recommend] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF)
ON ps_TRANSFER_monthly(winlostdate)
--------------
--IMPORT DATA
--SHRINK ALL THE FILES
