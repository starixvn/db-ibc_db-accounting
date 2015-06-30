---------------------------------------
USE bodb_Archive09
GO
ALTER DATABASE bodb_Archive09 ADD filegroup [TRANSFER_09M01]
ALTER DATABASE bodb_Archive09 ADD filegroup [TRANSFER_09M02]
ALTER DATABASE bodb_Archive09 ADD filegroup [TRANSFER_09M03]
ALTER DATABASE bodb_Archive09 ADD filegroup [TRANSFER_09M04]
ALTER DATABASE bodb_Archive09 ADD filegroup [TRANSFER_09M05]
ALTER DATABASE bodb_Archive09 ADD filegroup [TRANSFER_09M06]
ALTER DATABASE bodb_Archive09 ADD filegroup [TRANSFER_09M07]
ALTER DATABASE bodb_Archive09 ADD filegroup [TRANSFER_09M08]
ALTER DATABASE bodb_Archive09 ADD filegroup [TRANSFER_09M09]
ALTER DATABASE bodb_Archive09 ADD filegroup [TRANSFER_09M10]
ALTER DATABASE bodb_Archive09 ADD filegroup [TRANSFER_09M11]
ALTER DATABASE bodb_Archive09 ADD filegroup [TRANSFER_09M12]
-----------------


ALTER DATABASE bodb_Archive09 ADD FILE (name = 'TRANSFER_09M01', filename ='P:\Archive\2009\TRANSFER\Transfer_09M01.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_09M01]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'TRANSFER_09M02', filename ='P:\Archive\2009\TRANSFER\Transfer_09M02.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_09M02]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'TRANSFER_09M03', filename ='P:\Archive\2009\TRANSFER\Transfer_09M03.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_09M03]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'TRANSFER_09M04', filename ='P:\Archive\2009\TRANSFER\Transfer_09M04.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_09M04]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'TRANSFER_09M05', filename ='P:\Archive\2009\TRANSFER\Transfer_09M05.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_09M05]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'TRANSFER_09M06', filename ='P:\Archive\2009\TRANSFER\Transfer_09M06.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_09M06]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'TRANSFER_09M07', filename ='P:\Archive\2009\TRANSFER\Transfer_09M07.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_09M07]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'TRANSFER_09M08', filename ='P:\Archive\2009\TRANSFER\Transfer_09M08.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_09M08]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'TRANSFER_09M09', filename ='P:\Archive\2009\TRANSFER\Transfer_09M09.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_09M09]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'TRANSFER_09M10', filename ='P:\Archive\2009\TRANSFER\Transfer_09M10.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_09M10]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'TRANSFER_09M11', filename ='P:\Archive\2009\TRANSFER\Transfer_09M11.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_09M11]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'TRANSFER_09M12', filename ='P:\Archive\2009\TRANSFER\Transfer_09M12.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [TRANSFER_09M12]
----


--2
USE bodb_Archive09
--Create partition function
CREATE PARTITION FUNCTION pf_TRANSFER_monthly (SMALLDATETIME) AS
RANGE LEFT FOR VALUES
(
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
'2009/11/30 23:59:00'

)

--Create partition schema
CREATE PARTITION SCHEME ps_TRANSFER_monthly
AS PARTITION pf_TRANSFER_monthly
TO
    (
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
	[TRANSFER_09M12]
 )                
GO
---
--CREATE TABLE
CREATE TABLE [dbo].[Transfer_2009](
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
CREATE CLUSTERED INDEX [IX_Transfer_Data] ON [dbo].[Transfer_2009] 
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
'2009/01/01' AND 	'2009/12/31 23:59:00'


-------------------------
--DOUBLE CHECK DATA
SELECT datepart(month, winlostdate), count(*)
  FROM [bodb_Archive].[dbo].[Transfer_BK] with (nolock)
where winlostdate between 
'2009/01/01' and '2009/12/31 23:59:00'
group by datepart(month, winlostdate)
order by datepart(month, winlostdate)
/*
1	1435819
2	1185150
3	1379488
4	1443722
5	1262718
6	1713913
7	1024102
8	1605225
9	1642090
10	1919669
11	2042806
12	2224198
*/
select * from [partitionDetail]
--------------
USE [bodb_Archive]
GO

ALTER PROCEDURE [dbo].[DBA_DelTransfer_bk]
    @winlostdate smalldatetime
AS

if @winlostdate >= '2009-07-01' --to prevent mistake
    RETURN
    
Declare @RowsEffected int
Declare @RowsCnt int

SELECT @RowsEffected = 0

SET NOCOUNT ON
WHILE 1=1
BEGIN
    DELETE TOP(10000) FROM Transfer_bk where
        winlostdate between @winlostdate and dateadd(mi, 1439, @winlostdate) -- plus '23:59:00'
    
	SELECT @RowsCnt = @@ROWCOUNT
	SELECT @RowsEffected = @RowsEffected + @RowsCnt   

	IF @RowsCnt < 10000
        BREAK

END

SET NOCOUNT OFF

print convert(varchar(20), @winlostdate,0) + '-' + convert(varchar(20), dateadd(mi, 1439, @winlostdate),0) + ' - '+ convert(varchar,@RowsEffected) 
-----