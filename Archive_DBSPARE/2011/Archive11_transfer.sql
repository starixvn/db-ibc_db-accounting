---------------------------------------
USE bodb_Archive11
GO
ALTER DATABASE bodb_Archive11 ADD filegroup [TRANSFER_11M01]
ALTER DATABASE bodb_Archive11 ADD filegroup [TRANSFER_11M02]
ALTER DATABASE bodb_Archive11 ADD filegroup [TRANSFER_11M03]
ALTER DATABASE bodb_Archive11 ADD filegroup [TRANSFER_11M04]
ALTER DATABASE bodb_Archive11 ADD filegroup [TRANSFER_11M05]
ALTER DATABASE bodb_Archive11 ADD filegroup [TRANSFER_11M06]
ALTER DATABASE bodb_Archive11 ADD filegroup [TRANSFER_11M07]
ALTER DATABASE bodb_Archive11 ADD filegroup [TRANSFER_11M08]
ALTER DATABASE bodb_Archive11 ADD filegroup [TRANSFER_11M09]
ALTER DATABASE bodb_Archive11 ADD filegroup [TRANSFER_11M10]
ALTER DATABASE bodb_Archive11 ADD filegroup [TRANSFER_11M11]
ALTER DATABASE bodb_Archive11 ADD filegroup [TRANSFER_11M12]
-----------------


ALTER DATABASE bodb_Archive11 ADD FILE (name = 'TRANSFER_11M01', filename ='Q:\Archive\2011\TRANSFER\TRANSFER_11M01.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_11M01]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'TRANSFER_11M02', filename ='Q:\Archive\2011\TRANSFER\TRANSFER_11M02.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_11M02]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'TRANSFER_11M03', filename ='Q:\Archive\2011\TRANSFER\TRANSFER_11M03.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_11M03]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'TRANSFER_11M04', filename ='Q:\Archive\2011\TRANSFER\TRANSFER_11M04.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_11M04]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'TRANSFER_11M05', filename ='Q:\Archive\2011\TRANSFER\TRANSFER_11M05.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_11M05]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'TRANSFER_11M06', filename ='Q:\Archive\2011\TRANSFER\TRANSFER_11M06.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_11M06]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'TRANSFER_11M07', filename ='Q:\Archive\2011\TRANSFER\TRANSFER_11M07.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_11M07]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'TRANSFER_11M08', filename ='Q:\Archive\2011\TRANSFER\TRANSFER_11M08.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_11M08]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'TRANSFER_11M09', filename ='Q:\Archive\2011\TRANSFER\TRANSFER_11M09.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_11M09]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'TRANSFER_11M10', filename ='Q:\Archive\2011\TRANSFER\TRANSFER_11M10.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_11M10]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'TRANSFER_11M11', filename ='Q:\Archive\2011\TRANSFER\TRANSFER_11M11.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_11M11]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'TRANSFER_11M12', filename ='Q:\Archive\2011\TRANSFER\TRANSFER_11M12.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_11M12]
----


--2
USE bodb_Archive11
--Create partition function
CREATE PARTITION FUNCTION pf_TRANSFER_monthly (SMALLDATETIME) AS
RANGE LEFT FOR VALUES
(
'2011/01/31 23:59:00',
'2011/02/28 23:59:00',
'2011/03/31 23:59:00',
'2011/04/30 23:59:00',
'2011/05/31 23:59:00',
'2011/06/30 23:59:00',
'2011/07/31 23:59:00',
'2011/08/31 23:59:00',
'2011/09/30 23:59:00',
'2011/10/31 23:59:00',
'2011/11/30 23:59:00'

)

--Create partition schema
CREATE PARTITION SCHEME ps_TRANSFER_monthly
AS PARTITION pf_TRANSFER_monthly
TO
    (
	[TRANSFER_11M01], 
	[TRANSFER_11M02], 
	[TRANSFER_11M03], 
	[TRANSFER_11M04], 
	[TRANSFER_11M05], 
	[TRANSFER_11M06], 
	[TRANSFER_11M07], 
	[TRANSFER_11M08], 
	[TRANSFER_11M09], 
	[TRANSFER_11M10], 
	[TRANSFER_11M11], 
	[TRANSFER_11M12]
 )                
GO
---
--CREATE TABLE
CREATE TABLE [dbo].[Transfer_2011](
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
CREATE CLUSTERED INDEX [CIX_winlostdate] ON [dbo].[Transfer_2011] 
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
'2011/01/01' AND 	'2011/12/31 23:59:00'


