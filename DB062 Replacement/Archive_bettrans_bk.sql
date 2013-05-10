 
----------------------------------------------
---2
-- create folder G:\IBC_DB\bodb_Archive\BET

--- Calculate the no of record for each month. Using DB06
declare @SelDate smalldatetime, @FirstDay smalldatetime, @LastDay smalldatetime
select @SelDate = '2008-12-01'

SELECT @FirstDay = FLOOR(CAST(@SelDate AS DECIMAL(12, 5))) -  (DAY(@SelDate) - 1),
	@LastDay = DATEADD(dd, -DAY(DATEADD(m,1,@SelDate)), DATEADD(m,1,@SelDate))

select count(*) from bettrans_bk with (nolock) where winlostdate between @FirstDay and @LastDay

-------------------------------
--CREATE FILEGROUPS and FILES
USE bodb_Archive
GO

ALTER DATABASE bodb_Archive ADD filegroup [BET_08M07]
ALTER DATABASE bodb_Archive ADD filegroup [BET_08M08]
ALTER DATABASE bodb_Archive ADD filegroup [BET_08M09]
ALTER DATABASE bodb_Archive ADD filegroup [BET_08M10]
ALTER DATABASE bodb_Archive ADD filegroup [BET_08M11]
ALTER DATABASE bodb_Archive ADD filegroup [BET_08M12]

ALTER DATABASE bodb_Archive ADD filegroup [BET_09M01]
ALTER DATABASE bodb_Archive ADD filegroup [BET_09M02]
ALTER DATABASE bodb_Archive ADD filegroup [BET_09M03]
ALTER DATABASE bodb_Archive ADD filegroup [BET_09M04]
ALTER DATABASE bodb_Archive ADD filegroup [BET_09M05]
ALTER DATABASE bodb_Archive ADD filegroup [BET_09M06]
ALTER DATABASE bodb_Archive ADD filegroup [BET_09M07]
ALTER DATABASE bodb_Archive ADD filegroup [BET_09M08]
ALTER DATABASE bodb_Archive ADD filegroup [BET_09M09]
ALTER DATABASE bodb_Archive ADD filegroup [BET_09M10]
ALTER DATABASE bodb_Archive ADD filegroup [BET_09M11]
ALTER DATABASE bodb_Archive ADD filegroup [BET_09M12]

ALTER DATABASE bodb_Archive ADD filegroup [BET_10M01]
ALTER DATABASE bodb_Archive ADD filegroup [BET_10M02]
ALTER DATABASE bodb_Archive ADD filegroup [BET_10M03]
ALTER DATABASE bodb_Archive ADD filegroup [BET_10M04]
ALTER DATABASE bodb_Archive ADD filegroup [BET_10M05]
ALTER DATABASE bodb_Archive ADD filegroup [BET_10M06]
ALTER DATABASE bodb_Archive ADD filegroup [BET_10M07]
ALTER DATABASE bodb_Archive ADD filegroup [BET_10M08]
ALTER DATABASE bodb_Archive ADD filegroup [BET_10M09]
ALTER DATABASE bodb_Archive ADD filegroup [BET_10M10]
ALTER DATABASE bodb_Archive ADD filegroup [BET_10M11]
ALTER DATABASE bodb_Archive ADD filegroup [BET_10M12]

ALTER DATABASE bodb_Archive ADD filegroup [BET_MAX]

ALTER DATABASE bodb_Archive ADD filegroup [BET_INDEX]

--------------
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_08M07', filename ='G:\IBC_DB\bodb_Archive\BET\BET_08M07.ndf', SIZE = 15 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_08M07]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_08M08', filename ='G:\IBC_DB\bodb_Archive\BET\BET_08M08.ndf', SIZE = 23 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_08M08]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_08M09', filename ='G:\IBC_DB\bodb_Archive\BET\BET_08M09.ndf', SIZE = 25 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_08M09]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_08M10', filename ='G:\IBC_DB\bodb_Archive\BET\BET_08M10.ndf', SIZE = 30 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_08M10]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_08M11', filename ='G:\IBC_DB\bodb_Archive\BET\BET_08M11.ndf', SIZE = 31 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_08M11]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_08M12', filename ='G:\IBC_DB\bodb_Archive\BET\BET_08M12.ndf', SIZE = 25 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_08M12]

ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_09M01', filename ='G:\IBC_DB\bodb_Archive\BET\BET_09M01.ndf', SIZE = 26 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_09M01]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_09M02', filename ='G:\IBC_DB\bodb_Archive\BET\BET_09M02.ndf', SIZE = 27 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_09M02]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_09M03', filename ='G:\IBC_DB\bodb_Archive\BET\BET_09M03.ndf', SIZE = 33 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_09M03]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_09M04', filename ='G:\IBC_DB\bodb_Archive\BET\BET_09M04.ndf', SIZE = 38 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_09M04]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_09M05', filename ='G:\IBC_DB\bodb_Archive\BET\BET_09M05.ndf', SIZE = 37 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_09M05]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_09M06', filename ='G:\IBC_DB\bodb_Archive\BET\BET_09M06.ndf', SIZE = 26 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_09M06]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_09M07', filename ='G:\IBC_DB\bodb_Archive\BET\BET_09M07.ndf', SIZE = 28 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_09M07]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_09M08', filename ='G:\IBC_DB\bodb_Archive\BET\BET_09M08.ndf', SIZE = 39 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_09M08]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_09M09', filename ='G:\IBC_DB\bodb_Archive\BET\BET_09M09.ndf', SIZE = 48 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_09M09]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_09M10', filename ='G:\IBC_DB\bodb_Archive\BET\BET_09M10.ndf', SIZE = 52 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_09M10]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_09M11', filename ='G:\IBC_DB\bodb_Archive\BET\BET_09M11.ndf', SIZE = 46 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_09M11]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_09M12', filename ='G:\IBC_DB\bodb_Archive\BET\BET_09M12.ndf', SIZE = 43 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_09M12]

ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_10M01', filename ='G:\IBC_DB\bodb_Archive\BET\BET_10M01.ndf', SIZE = 40 GB ,FILEGROWTH = 500 MB ) TO filegroup [BET_10M01]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_10M02', filename ='G:\IBC_DB\bodb_Archive\BET\BET_10M02.ndf', SIZE = 500 MB ,FILEGROWTH = 500 MB ) TO filegroup [BET_10M02]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_10M03', filename ='G:\IBC_DB\bodb_Archive\BET\BET_10M03.ndf', SIZE = 500 MB ,FILEGROWTH = 500 MB ) TO filegroup [BET_10M03]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_10M04', filename ='G:\IBC_DB\bodb_Archive\BET\BET_10M04.ndf', SIZE = 500 MB ,FILEGROWTH = 500 MB ) TO filegroup [BET_10M04]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_10M05', filename ='G:\IBC_DB\bodb_Archive\BET\BET_10M05.ndf', SIZE = 500 MB ,FILEGROWTH = 500 MB ) TO filegroup [BET_10M05]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_10M06', filename ='G:\IBC_DB\bodb_Archive\BET\BET_10M06.ndf', SIZE = 500 MB ,FILEGROWTH = 500 MB ) TO filegroup [BET_10M06]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_10M07', filename ='G:\IBC_DB\bodb_Archive\BET\BET_10M07.ndf', SIZE = 500 MB ,FILEGROWTH = 500 MB ) TO filegroup [BET_10M07]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_10M08', filename ='G:\IBC_DB\bodb_Archive\BET\BET_10M08.ndf', SIZE = 500 MB ,FILEGROWTH = 500 MB ) TO filegroup [BET_10M08]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_10M09', filename ='G:\IBC_DB\bodb_Archive\BET\BET_10M09.ndf', SIZE = 500 MB ,FILEGROWTH = 500 MB ) TO filegroup [BET_10M09]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_10M10', filename ='G:\IBC_DB\bodb_Archive\BET\BET_10M10.ndf', SIZE = 500 MB ,FILEGROWTH = 500 MB ) TO filegroup [BET_10M10]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_10M11', filename ='G:\IBC_DB\bodb_Archive\BET\BET_10M11.ndf', SIZE = 500 MB ,FILEGROWTH = 500 MB ) TO filegroup [BET_10M11]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_10M12', filename ='G:\IBC_DB\bodb_Archive\BET\BET_10M12.ndf', SIZE = 500 MB ,FILEGROWTH = 500 MB ) TO filegroup [BET_10M12]

ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_MAX', filename ='G:\IBC_DB\bodb_Archive\BET\BET_MAX.ndf', SIZE = 500 MB ,FILEGROWTH = 500 MB ) TO filegroup [BET_MAX]


ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_INDEX_01', filename ='G:\IBC_DB\bodb_Archive\BET\BET_INDEX_01.ndf', SIZE = 20 GB ,FILEGROWTH = 1GB ) TO filegroup [BET_INDEX]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_INDEX_02', filename ='G:\IBC_DB\bodb_Archive\BET\BET_INDEX_02.ndf', SIZE = 20 GB ,FILEGROWTH = 1GB ) TO filegroup [BET_INDEX]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BET_INDEX_03', filename ='G:\IBC_DB\bodb_Archive\BET\BET_INDEX_03.ndf', SIZE = 20 GB ,FILEGROWTH = 1GB ) TO filegroup [BET_INDEX]

----

--2
--Create partition function
CREATE PARTITION FUNCTION pf_BET_monthly (SMALLDATETIME) AS
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
CREATE PARTITION SCHEME ps_BET_monthly
AS PARTITION pf_BET_monthly
TO
    (
	[BET_08M07], 
	[BET_08M08], 
	[BET_08M09], 
	[BET_08M10], 
	[BET_08M11], 
	[BET_08M12],
	
	[BET_09M01], 
	[BET_09M02], 
	[BET_09M03], 
	[BET_09M04], 
	[BET_09M05], 
	[BET_09M06], 
	[BET_09M07], 
	[BET_09M08], 
	[BET_09M09], 
	[BET_09M10], 
	[BET_09M11], 
	[BET_09M12],
	
	[BET_10M01], 
	[BET_10M02], 
	[BET_10M03], 
	[BET_10M04], 
	[BET_10M05], 
	[BET_10M06], 
	[BET_10M07], 
	[BET_10M08], 
	[BET_10M09], 
	[BET_10M10], 
	[BET_10M11], 
	[BET_10M12],
	
	[BET_MAX]
	
 )                
GO
---
--CREATE TABLE AND INDEX

/****** Object:  Table [dbo].[bettrans_bk]    Script Date: 11/15/2009 08:50:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[bettrans_bk](
	[transid] [int] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[oddsid] [int] NOT NULL,
	[hdp1] [smallmoney] NULL,
	[hdp2] [smallmoney] NULL,
	[odds] [smallmoney] NULL,
	[stake] [money] NOT NULL,
	[actual_stake] [money] NULL,
	[status] [varchar](10) NULL,
	
	[winlost] [money] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,
	
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,

	[apositiontaking] [smallmoney] NULL,
	[mpositiontaking] [smallmoney] NULL,
	[spositiontaking] [smallmoney] NULL,
	[tpositiontaking] [smallmoney] NULL,
	
	[playerdiscount] [decimal](9, 8) NULL,
	[discount] [decimal](9, 8) NULL,
	[adiscount] [decimal](9, 8) NULL,
	[sdiscount] [decimal](9, 8) NULL,

	[livehomescore] [smallint] NULL,
	[liveawayscore] [smallint] NULL,
	[liveindicator] [bit] NULL,
	[betteam] [varchar](10) NULL,
	[creator] [int] NOT NULL,
	[refno] [bigint] NULL,
	--[comstatus] [nvarchar](20) NULL,--remove it
	[winlostdate] [smalldatetime] NULL,
	[betfrom] [varchar](1) NULL,
	[betcheck] [varchar](50) NULL,
	[checktime] [datetime] NULL,
	[oddsspread] [smallmoney] NULL,
	[actualrate] [float] NULL,
	[matchid] [int] NULL,
	
	[recommend] [int] NULL,
	[mrecommend] [int] NULL,
	[srecommend] [int] NULL,

	[ruben] [tinyint] NULL,
	[betid] [bigint] NULL,
	[statuswinlost] [tinyint] NULL,
	[modds] [smallmoney] NULL,
	[bettype] [tinyint] NULL,
	[betdaqid] [bigint] NULL,
	[tstamp] [binary](8) NULL,
	
	[currency] [tinyint] NULL,
	[ip] [varchar](15) NULL,
	[transdesc] [nvarchar](300) NULL,	
	
	
	[virtualrate] [float] NULL,
	[oddstype] [tinyint] NULL,
 CONSTRAINT [PK_bettrans_bk] PRIMARY KEY NONCLUSTERED 
(
	[transid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [BET_INDEX]
) ON [BET_INDEX]

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [CIX_winlostdate]    Script Date: 11/15/2009 08:50:10 ******/
CREATE CLUSTERED INDEX [CIX_winlostdate] ON [dbo].[bettrans_bk] 
(
	[winlostdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
ON ps_BET_monthly(winlostdate)
GO

/****** Object:  Index [IX_custid]    Script Date: 11/15/2009 08:50:10 ******/
CREATE NONCLUSTERED INDEX [IX_custid] ON [dbo].[bettrans_bk] 
(
	[custid] ASC
)
INCLUDE ( [winlostdate],
[matchid],
[bettype]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [BET_INDEX]
GO
-----------
--verify the field name, datatype to compare with old DB06
select so.name [Table Name], sc.name [Column Name], st.name [Data type], sc.length [Length], sc.prec [Precision],
	case when pk.Constraint_name is not null then 1 else 0 end [Primary Key]
from sysobjects so
	inner join syscolumns sc on so.id = sc.id
	inner join systypes st on sc.xtype = st.xusertype

	left join INFORMATION_SCHEMA.KEY_COLUMN_USAGE pk on so.name = pk.table_name and sc.name = pk.column_name
where so.xtype = 'U' and so.name = 'bettrans_bk'
order by 2
--------------
--IMPORT data from DB06
SELECT     transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, playercomm, comm, 
                      acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, livehomescore, 
                      liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, 
                      mrecommend, srecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype
FROM         bettrans_bk with (nolock)
where winlostdate between '2009/09/01' AND 	'2009/09/30 23:59:00'
-------------------
where winlostdate between '2008/07/01' AND 	'2008/07/31 23:59:00'
where winlostdate between '2008/08/01' AND 	'2008/08/31 23:59:00'
where winlostdate between '2008/09/01' AND 	'2008/09/30 23:59:00'
where winlostdate between '2008/10/01' AND 	'2008/10/31 23:59:00'

where winlostdate between '2008/11/01' AND 	'2008/11/30 23:59:00'
where winlostdate between '2008/12/01' AND 	'2008/12/31 23:59:00'
where winlostdate between '2009/01/01' AND 	'2009/01/31 23:59:00'
where winlostdate between '2009/02/01' AND 	'2009/02/28 23:59:00'
where winlostdate between '2009/03/01' AND 	'2009/03/31 23:59:00'
where winlostdate between '2009/04/01' AND 	'2009/04/30 23:59:00'
where winlostdate between '2009/05/01' AND 	'2009/05/31 23:59:00'
where winlostdate between '2009/06/01' AND 	'2009/06/30 23:59:00'
where winlostdate between '2009/07/01' AND 	'2009/07/31 23:59:00'
where winlostdate between '2009/08/01' AND 	'2009/08/31 23:59:00'
where winlostdate between '2009/09/01' AND 	'2009/09/30 23:59:00'
where winlostdate between '2009/10/01' AND 	'2009/10/31 23:59:00'
where winlostdate between '2009/11/01' AND 	'2009/11/30 23:59:00'
where winlostdate between '2009/12/01' AND 	'2009/12/31 23:59:00'
where winlostdate between '2010/01/01' AND 	'2010/01/31 23:59:00'

----------------
--CHeck the diskspace
create table #tmpspc (Fileid int, FileGroup int, TotalExtents int, UsedExtents int, Name sysname, FileName nchar(520))
            insert #tmpspc EXEC ('dbcc showfilestats')

SELECT
s.name AS [Name],
s.physical_name AS [FileName],
s.size * CONVERT(float,8)/1024 AS [Size-MB],
CAST(tspc.UsedExtents*convert(float,64) AS float)/1024 AS [UsedSpace-MB],
s.file_id AS [ID]
FROM
sys.filegroups AS g
INNER JOIN sys.master_files AS s ON (s.type = 0 and s.database_id = db_id() and (s.drop_lsn IS NULL)) AND (s.data_space_id=g.data_space_id)
INNER JOIN #tmpspc tspc ON tspc.Fileid = s.file_id
--WHERE
--(CAST(cast(g.name as varbinary(256)) AS sysname)=N'CustSetting')
ORDER BY
[ID] ASC

drop table #tmpspc
-------
--SHRINK ALL THE FILES