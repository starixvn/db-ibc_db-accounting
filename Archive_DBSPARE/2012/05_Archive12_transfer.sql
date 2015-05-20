---------------------------------------
USE bodb_Archive12
GO
ALTER DATABASE bodb_Archive12 ADD filegroup [TRANSFER_12M01]
ALTER DATABASE bodb_Archive12 ADD filegroup [TRANSFER_12M02]
ALTER DATABASE bodb_Archive12 ADD filegroup [TRANSFER_12M03]
ALTER DATABASE bodb_Archive12 ADD filegroup [TRANSFER_12M04]
ALTER DATABASE bodb_Archive12 ADD filegroup [TRANSFER_12M05]
ALTER DATABASE bodb_Archive12 ADD filegroup [TRANSFER_12M06]
ALTER DATABASE bodb_Archive12 ADD filegroup [TRANSFER_12M07]
ALTER DATABASE bodb_Archive12 ADD filegroup [TRANSFER_12M08]
ALTER DATABASE bodb_Archive12 ADD filegroup [TRANSFER_12M09]
ALTER DATABASE bodb_Archive12 ADD filegroup [TRANSFER_12M10]
ALTER DATABASE bodb_Archive12 ADD filegroup [TRANSFER_12M11]
ALTER DATABASE bodb_Archive12 ADD filegroup [TRANSFER_12M12]
-----------------


ALTER DATABASE bodb_Archive12 ADD FILE (name = 'TRANSFER_12M01', filename ='Q:\Archive\2012\TRANSFER\TRANSFER_12M01.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_12M01]
ALTER DATABASE bodb_Archive12 ADD FILE (name = 'TRANSFER_12M02', filename ='Q:\Archive\2012\TRANSFER\TRANSFER_12M02.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_12M02]
ALTER DATABASE bodb_Archive12 ADD FILE (name = 'TRANSFER_12M03', filename ='Q:\Archive\2012\TRANSFER\TRANSFER_12M03.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_12M03]
ALTER DATABASE bodb_Archive12 ADD FILE (name = 'TRANSFER_12M04', filename ='Q:\Archive\2012\TRANSFER\TRANSFER_12M04.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_12M04]
ALTER DATABASE bodb_Archive12 ADD FILE (name = 'TRANSFER_12M05', filename ='Q:\Archive\2012\TRANSFER\TRANSFER_12M05.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_12M05]
ALTER DATABASE bodb_Archive12 ADD FILE (name = 'TRANSFER_12M06', filename ='Q:\Archive\2012\TRANSFER\TRANSFER_12M06.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_12M06]
ALTER DATABASE bodb_Archive12 ADD FILE (name = 'TRANSFER_12M07', filename ='Q:\Archive\2012\TRANSFER\TRANSFER_12M07.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_12M07]
ALTER DATABASE bodb_Archive12 ADD FILE (name = 'TRANSFER_12M08', filename ='Q:\Archive\2012\TRANSFER\TRANSFER_12M08.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_12M08]
ALTER DATABASE bodb_Archive12 ADD FILE (name = 'TRANSFER_12M09', filename ='Q:\Archive\2012\TRANSFER\TRANSFER_12M09.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_12M09]
ALTER DATABASE bodb_Archive12 ADD FILE (name = 'TRANSFER_12M10', filename ='Q:\Archive\2012\TRANSFER\TRANSFER_12M10.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_12M10]
ALTER DATABASE bodb_Archive12 ADD FILE (name = 'TRANSFER_12M11', filename ='Q:\Archive\2012\TRANSFER\TRANSFER_12M11.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_12M11]
ALTER DATABASE bodb_Archive12 ADD FILE (name = 'TRANSFER_12M12', filename ='Q:\Archive\2012\TRANSFER\TRANSFER_12M12.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_12M12]
----


--2
USE bodb_Archive12
--Create partition function
CREATE PARTITION FUNCTION pf_TRANSFER_monthly (SMALLDATETIME) AS
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
'2012/11/30 23:59:00'

)

--Create partition schema
CREATE PARTITION SCHEME ps_TRANSFER_monthly
AS PARTITION pf_TRANSFER_monthly
TO
    (
	[TRANSFER_12M01], 
	[TRANSFER_12M02], 
	[TRANSFER_12M03], 
	[TRANSFER_12M04], 
	[TRANSFER_12M05], 
	[TRANSFER_12M06], 
	[TRANSFER_12M07], 
	[TRANSFER_12M08], 
	[TRANSFER_12M09], 
	[TRANSFER_12M10], 
	[TRANSFER_12M11], 
	[TRANSFER_12M12]
 )                
GO
---
--CREATE TABLE
CREATE TABLE [dbo].[Transfer_2012](
	[transid] [bigint] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[Debit] [money] NOT NULL,
	[Credit] [money] NOT NULL,
	[TransDesc] [nvarchar](300) NULL,
	[winlostdate] [smalldatetime] NOT NULL,
	[recommend] [int] NOT NULL,
	[mrecommend] [int] NOT NULL,
	[srecommend] [int] NOT NULL,
	[bettype] [smallint] NOT NULL,
	[currency] [tinyint] NULL,
	[refno] [bigint] NOT NULL,
	[creator] [int] NULL
) ON [PRIMARY]

GO

/****** Object:  Index [IX_Transfer_Data]    Script Date: 11/15/2009 09:44:04 ******/
CREATE CLUSTERED INDEX [CIX_winlostdate] ON [dbo].[Transfer_2012] 
(
	[winlostdate] ASC,
	[custid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF)
ON ps_TRANSFER_monthly(winlostdate)
-------------
--TO IMPORT DATA
SELECT [transid]
      ,[custid]
      ,[transdate]
      ,[Debit]
      ,[Credit]
      ,[TransDesc]
      ,[winlostdate]
      ,[recommend]
      ,[mrecommend]
      ,[srecommend]
      ,[bettype]
      ,[currency]
      ,[refno]
      ,[creator]
  FROM [bodb_Archive].[dbo].[Transfer_BK] with (nolock)
where winlostdate between 
'2012/01/01' AND 	'2012/12/31 23:59:00'


