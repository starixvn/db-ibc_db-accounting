select so.name [Table Name], sc.name [Column Name], st.name [Data type], sc.length [Length], sc.prec [Precision],
	case when pk.Constraint_name is not null then 1 else 0 end [Primary Key]
from sysobjects so
	inner join syscolumns sc on so.id = sc.id
	inner join systypes st on sc.xtype = st.xusertype	
	left join INFORMATION_SCHEMA.KEY_COLUMN_USAGE pk on so.name = pk.table_name and sc.name = pk.column_name
where so.xtype = 'U'
	and sc.name like '%bettype%'

SELECT
    t.name as tableName,ind.name, ind.index_id, ic.index_column_id, col.name
FROM
    sys.indexes ind
    INNER join sys.index_columns ic ON
        ind.OBJECT_ID = ic.OBJECT_ID and ind.index_id = ic.index_id
    INNER join   sys.columns col ON
        ic.OBJECT_ID = col.OBJECT_ID and ic.column_id = col.column_id
    INNER join sys.tables t ON
        ind.OBJECT_ID = t.OBJECT_ID
WHERE col.name like '%bettype%'
---------


ALTER TABLE dbo.bettrans_bk ADD
    bettype2 SMALLINT NULL
GO
-----------
CREATE PROCEDURE [dbo].[DBA_UpdateBettransBettype2]
    @winlostdate SMALLDATETIME
AS
DECLARE @StartTime DATETIME
SET @StartTime = CURRENT_TIMESTAMP

UPDATE bettrans_bk WITH (ROWLOCK, UPDLOCK)
    SET bettype2 = bettype
WHERE winlostdate between @winlostdate and DATEADD(mi, 1439, @winlostdate) -- plus '23:59:00'

PRINT 'DONE: ' + CAST(@winlostdate AS VARCHAR(11)) + + N' (' + CAST(DATEDIFF(SECOND, @StartTime, CURRENT_TIMESTAMP) AS VARCHAR(50)) + ' sec) '
GO
--------
EXEC DBA_UpdateBettransBettype2 '2008/07/01' 
 GO 
 CHECKPOINT 
 GO 

EXEC DBA_UpdateBettransBettype2 '2008/07/02' 
 GO 
 CHECKPOINT 
 GO 

EXEC DBA_UpdateBettransBettype2 '2008/07/03' 
 GO 
 CHECKPOINT 
 GO 
 
 --Excel function: ="EXEC DBA_UpdateBettransBettype2 '"&TEXT(A1,"yyyy/mm/dd")&"' ;GO CHECKPOINT ;GO"
 
 
 ---
--ZZZBETTRANS table
ALTER TABLE zzzbettrans
ALTER COLUMN bettype smallint
---------
--TRANSFER_BK table
ALTER TABLE dbo.transfer_bk ADD
    bettype2 SMALLINT NULL
GO
----------
ALTER PROCEDURE [dbo].[DBA_UpdateTransferBettype2]
    @winlostdate SMALLDATETIME
AS
DECLARE @StartTime DATETIME
SET @StartTime = CURRENT_TIMESTAMP

UPDATE transfer_bk WITH (ROWLOCK, UPDLOCK)
    SET bettype2 =  bettype 
WHERE winlostdate between @winlostdate and DATEADD(mi, 1439, @winlostdate) -- plus '23:59:00'

PRINT 'DONE: ' + CAST(@winlostdate AS VARCHAR(11)) + + N' (' + CAST(DATEDIFF(SECOND, @StartTime, CURRENT_TIMESTAMP) AS VARCHAR(50)) + ' sec) '
GO
-------------
EXEC DBA_UpdateTransferBettype2 '2010/03/20' 
 GO 
 CHECKPOINT 
 GO 

EXEC DBA_UpdateTransferBettype2 '2010/03/21' 
 GO 
 CHECKPOINT 
 GO 

EXEC DBA_UpdateTransferBettype2 '2010/03/22' 
 GO 
 CHECKPOINT 
 GO 
------------
EXEC sp_RENAME 'transfer_bk.bettype' , 'bettype_old', 'COLUMN'
GO
EXEC sp_RENAME 'transfer_bk.bettype2' , 'bettype', 'COLUMN'
--------
--verify data
select top 1 bettype, bettype_old, * from transfer_bk with (nolock)
where bettype <> bettype_old
-------
ALTER TABLE transfer_bk DROP COLUMN bettype_old
-----------

--BETTRANSM table
ALTER TABLE dbo.bettransm ADD
    bettype2 SMALLINT NULL
GO
----------
ALTER PROCEDURE [dbo].[DBA_UpdateBettransmBettype2]
    @winlostdate SMALLDATETIME
AS
DECLARE @StartTime DATETIME
SET @StartTime = CURRENT_TIMESTAMP

UPDATE bettransm WITH (ROWLOCK, UPDLOCK)
    SET bettype2 = bettype
WHERE winlostdate between @winlostdate and DATEADD(mi, 1439, @winlostdate) -- plus '23:59:00'

PRINT 'DONE: ' + CAST(@winlostdate AS VARCHAR(11)) + + N' (' + CAST(DATEDIFF(SECOND, @StartTime, CURRENT_TIMESTAMP) AS VARCHAR(50)) + ' sec) '
GO
---------
EXEC DBA_UpdateBettransmBettype2 '2008/12/11' 
 GO 
 CHECKPOINT 
 GO 

EXEC DBA_UpdateBettransmBettype2 '2008/12/12' 
 GO 
 CHECKPOINT 
 GO 

EXEC DBA_UpdateBettransmBettype2 '2008/12/13' 
 GO 
 CHECKPOINT 
 GO 
 ----------------------------
 EXEC sp_RENAME 'bettransm.bettype' , 'bettype_old', 'COLUMN'
GO
EXEC sp_RENAME 'bettransm.bettype2' , 'bettype', 'COLUMN'

-------
ALTER TABLE bettransm DROP COLUMN bettype_old
------------------------


4. Create temp/dummy bettrans_bk2 table

4.1 Create temp file/filegroup
[tsql]
ALTER DATABASE [bodb_Archive] ADD FILEGROUP [BETTEMP] 
 GO 
ALTER DATABASE [bodb_Archive] ADD FILE ( NAME = N'BETTEMP_01',
FILENAME = N'M:\IBC_DB\bodb_Archive\BETTEMP\BETTEMP_01.ndf' ,
SIZE = 1MB , FILEGROWTH = 32MB ) TO FILEGROUP [BETTEMP] 
 GO 
ALTER DATABASE [bodb_Archive] ADD FILE ( NAME = N'BETTEMP_02', 
FILENAME = N'M:\IBC_DB\bodb_Archive\BETTEMP\BETTEMP_02.ndf' , 
SIZE = 1MB , FILEGROWTH = 32MB ) TO FILEGROUP [BETTEMP] 
GO
------
ALTER DATABASE [bodb_Archive] ADD FILEGROUP [BETTEMP_INDEX] 
 GO 
ALTER DATABASE [bodb_Archive] ADD FILE ( NAME = N'BETTEMP_INDEX_01',
FILENAME = N'M:\IBC_DB\bodb_Archive\BETTEMP\BETTEMP_INDEX_01.ndf' ,
SIZE = 1MB , FILEGROWTH = 32MB ) TO FILEGROUP [BETTEMP_INDEX] 
 GO 
ALTER DATABASE [bodb_Archive] ADD FILE ( NAME = N'BETTEMP_INDEX_02', 
FILENAME = N'M:\IBC_DB\bodb_Archive\BETTEMP\BETTEMP_INDEX_02.ndf' , 
SIZE = 1MB , FILEGROWTH = 32MB ) TO FILEGROUP [BETTEMP_INDEX] 
GO
[/tsql]

4.2 Create temp table bettrans_bk2
[tsql]
USE [bodb_Archive]
GO
/****** Object:  Table [dbo].[bettrans_bk2]    Script Date: 12/16/2010 23:43:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[bettrans_bk2](
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
	[statusID] [tinyint] NULL,
	[currency2] [tinyint] NULL,
	[transid] [bigint] NOT NULL,
	[bettype2] [smallint] NULL,
 CONSTRAINT [PK_bettrans_bk2] PRIMARY KEY NONCLUSTERED 
(
	[transid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [BETTEMP]
)

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [CIX_winlostdate]    Script Date: 12/16/2010 23:43:01 ******/
CREATE CLUSTERED INDEX [CIX_winlostdate] ON [dbo].[bettrans_bk2] 
(
	[winlostdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [BETTEMP]
GO

/****** Object:  Index [IX_custid]    Script Date: 12/16/2010 23:43:01 ******/
CREATE NONCLUSTERED INDEX [IX_custid] ON [dbo].[bettrans_bk2] 
(
	[custid] ASC
)
INCLUDE ( [winlostdate],
[matchid],
[bettype]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [BETTEMP_INDEX]
GO
GRANT SELECT ON [dbo].[bettrans_bk2] TO [bodbAdminNet]
GO
GRANT SELECT ON [dbo].[bettrans_bk2] TO [bodbDownlineNet]
GO
GRANT SELECT ON [dbo].[bettrans_bk2] TO [bodbDownlineNetView]
GO
GRANT SELECT ON [dbo].[bettrans_bk2] TO [bodbExtAccNet]
-------------
[/tsql]

4.3 Copy data of Dec-2010 to new temp table. It's required to copy day by day since the number of data is quite huge
[tsql]
SELECT     custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, 
                      apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, livehomescore, liveawayscore, 
                      liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, 
                      srecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, currency2, transid, 
                      bettype2
FROM         bettrans_bk WITH (nolock)
WHERE winlostdate between '2010/12/03' AND 	'2010/12/04 23:59:00'
[/tsql]

'2010/12/01' AND 	'2010/12/31 23:59:00'

Step 5--> will be performed at downtime

5. Rename tables
[tsql]
EXEC SP_RENAME 'bettrans_bk', 'bettrans_bk_main'
GO
EXEC SP_RENAME 'bettrans_bk2', 'bettrans_bk'
[/tsql]

6. Drop IX_CustID index

[tsql]DROP INDEX [IX_custid] ON [dbo].[bettrans_bk_main] WITH ( ONLINE = OFF )[/tsql]

7. Rename columns

[tsql]EXEC sp_RENAME 'bettrans_bk_main.bettype' , 'bettype_old', 'COLUMN'
GO
EXEC sp_RENAME 'bettrans_bk_main.bettype2' , 'bettype', 'COLUMN'[/tsql]

8. Re-create index [IX_custid]

[tsql]CREATE NONCLUSTERED INDEX [IX_custid] ON [dbo].[bettrans_bk_main]
(
    [custid] ASC
)
INCLUDE ( [winlostdate],
[matchid],
[bettype]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [BET_INDEX][/tsql]

9. Drop bettype_old column
[tsql]
 ALTER TABLE bettrans_bk_main DROP COLUMN bettype_old 
 [/tsql]
 
10. Rename back tables
[tsql]
EXEC SP_RENAME 'bettrans_bk', 'bettrans_bk2'
GO
EXEC SP_RENAME 'bettrans_bk_main', 'bettrans_bk'
[/tsql]
