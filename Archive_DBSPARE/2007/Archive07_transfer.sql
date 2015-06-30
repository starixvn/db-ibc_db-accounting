---------------------------------------
USE bodb_Archive07
GO
ALTER DATABASE bodb_Archive07 ADD filegroup [TRANSFER_07M01]
ALTER DATABASE bodb_Archive07 ADD filegroup [TRANSFER_07M02]
ALTER DATABASE bodb_Archive07 ADD filegroup [TRANSFER_07M03]
ALTER DATABASE bodb_Archive07 ADD filegroup [TRANSFER_07M04]
ALTER DATABASE bodb_Archive07 ADD filegroup [TRANSFER_07M05]
ALTER DATABASE bodb_Archive07 ADD filegroup [TRANSFER_07M06]
ALTER DATABASE bodb_Archive07 ADD filegroup [TRANSFER_07M07]
ALTER DATABASE bodb_Archive07 ADD filegroup [TRANSFER_07M08]
ALTER DATABASE bodb_Archive07 ADD filegroup [TRANSFER_07M09]
ALTER DATABASE bodb_Archive07 ADD filegroup [TRANSFER_07M10]
ALTER DATABASE bodb_Archive07 ADD filegroup [TRANSFER_07M11]
ALTER DATABASE bodb_Archive07 ADD filegroup [TRANSFER_07M12]
-----------------


ALTER DATABASE bodb_Archive07 ADD FILE (name = 'TRANSFER_07M01', filename ='P:\Archive\2007\TRANSFER\Transfer_07M01.ndf', SIZE = 190MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_07M01]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'TRANSFER_07M02', filename ='P:\Archive\2007\TRANSFER\Transfer_07M02.ndf', SIZE = 160MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_07M02]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'TRANSFER_07M03', filename ='P:\Archive\2007\TRANSFER\Transfer_07M03.ndf', SIZE = 193MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_07M03]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'TRANSFER_07M04', filename ='P:\Archive\2007\TRANSFER\Transfer_07M04.ndf', SIZE = 220MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_07M04]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'TRANSFER_07M05', filename ='P:\Archive\2007\TRANSFER\Transfer_07M05.ndf', SIZE = 205MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_07M05]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'TRANSFER_07M06', filename ='P:\Archive\2007\TRANSFER\Transfer_07M06.ndf', SIZE = 165MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_07M06]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'TRANSFER_07M07', filename ='P:\Archive\2007\TRANSFER\Transfer_07M07.ndf', SIZE = 200MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_07M07]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'TRANSFER_07M08', filename ='P:\Archive\2007\TRANSFER\Transfer_07M08.ndf', SIZE = 205MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_07M08]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'TRANSFER_07M09', filename ='P:\Archive\2007\TRANSFER\Transfer_07M09.ndf', SIZE = 215MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_07M09]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'TRANSFER_07M10', filename ='P:\Archive\2007\TRANSFER\Transfer_07M10.ndf', SIZE = 241MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_07M10]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'TRANSFER_07M11', filename ='P:\Archive\2007\TRANSFER\Transfer_07M11.ndf', SIZE = 231MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_07M11]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'TRANSFER_07M12', filename ='P:\Archive\2007\TRANSFER\Transfer_07M12.ndf', SIZE = 235MB ,FILEGROWTH = 32MB ) TO filegroup [TRANSFER_07M12]
----


--2
USE bodb_Archive07
--Create partition function
CREATE PARTITION FUNCTION pf_TRANSFER_monthly (SMALLDATETIME) AS
RANGE LEFT FOR VALUES
(
'2007/01/31 23:59:00',
'2007/02/28 23:59:00',
'2007/03/31 23:59:00',
'2007/04/30 23:59:00',
'2007/05/31 23:59:00',
'2007/06/30 23:59:00',
'2007/07/31 23:59:00',
'2007/08/31 23:59:00',
'2007/09/30 23:59:00',
'2007/10/31 23:59:00',
'2007/11/30 23:59:00'
)

--Create partition schema
CREATE PARTITION SCHEME ps_TRANSFER_monthly
AS PARTITION pf_TRANSFER_monthly
TO
    (
	[TRANSFER_07M01], 
	[TRANSFER_07M02], 
	[TRANSFER_07M03], 
	[TRANSFER_07M04], 
	[TRANSFER_07M05], 
	[TRANSFER_07M06], 
	[TRANSFER_07M07], 
	[TRANSFER_07M08], 
	[TRANSFER_07M09], 
	[TRANSFER_07M10], 
	[TRANSFER_07M11], 
	[TRANSFER_07M12]
 )                
GO
---
--CREATE TABLE
CREATE TABLE [dbo].[Transfer_2007](
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
CREATE CLUSTERED INDEX [IX_Transfer_Data] ON [dbo].[Transfer_2007] 
(
	[winlostdate] ASC,
	[recommend] ASC
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
'2007/01/01' AND 	'2007/01/31 23:59:00'
'2007/02/01' AND 	'2007/02/28 23:59:00'
'2007/03/01' AND 	'2007/03/31 23:59:00'
'2007/04/01' AND 	'2007/04/30 23:59:00'
'2007/05/01' AND 	'2007/05/31 23:59:00'
'2007/06/01' AND 	'2007/06/30 23:59:00'
'2007/07/01' AND 	'2007/07/31 23:59:00'
'2007/08/01' AND 	'2007/08/31 23:59:00'
'2007/09/01' AND 	'2007/09/30 23:59:00'
'2007/10/01' AND 	'2007/10/31 23:59:00'
'2007/11/01' AND 	'2007/11/30 23:59:00'
'2007/12/01' AND 	'2007/12/31 23:59:00'
-------------------------
--DOUBLE CHECK DATA
SELECT datepart(month, winlostdate), count(*)
  FROM [bodb_Archive].[dbo].[Transfer_BK] with (nolock)
where winlostdate between 
'2007/01/01' and '2007/12/31 23:59:00'
group by datepart(month, winlostdate)
order by datepart(month, winlostdate)
--1	1104080
--2	944048
--3	1122172
--4	1262545
--5	1178199
--6	952258
--7	1157917
--8	1175426
--9	1247491
--10	1393845
--11	1338408
--12	1354627

select * from [partitionDetail]
