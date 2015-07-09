 
----------------------------------------------
---2
-- create folder P:\Archive\2008\BET\

USE bodb_Archive08
GO
ALTER DATABASE bodb_Archive08 ADD filegroup [BET_08M01]
ALTER DATABASE bodb_Archive08 ADD filegroup [BET_08M02]
ALTER DATABASE bodb_Archive08 ADD filegroup [BET_08M03]
ALTER DATABASE bodb_Archive08 ADD filegroup [BET_08M04]
ALTER DATABASE bodb_Archive08 ADD filegroup [BET_08M05]
ALTER DATABASE bodb_Archive08 ADD filegroup [BET_08M06]
ALTER DATABASE bodb_Archive08 ADD filegroup [BET_08M07]
ALTER DATABASE bodb_Archive08 ADD filegroup [BET_08M08]
ALTER DATABASE bodb_Archive08 ADD filegroup [BET_08M09]
ALTER DATABASE bodb_Archive08 ADD filegroup [BET_08M10]
ALTER DATABASE bodb_Archive08 ADD filegroup [BET_08M11]
ALTER DATABASE bodb_Archive08 ADD filegroup [BET_08M12]
ALTER DATABASE bodb_Archive08 ADD filegroup [BET_INDEX]

--- Calculate the no of record for each month. Using Julien's DBDW
declare @SelDate smalldatetime, @FirstDay smalldatetime, @LastDay smalldatetime
select @SelDate = '2008-12-01'

SELECT @FirstDay = FLOOR(CAST(@SelDate AS DECIMAL(12, 5))) -  (DAY(@SelDate) - 1),
	@LastDay = DATEADD(dd, -DAY(DATEADD(m,1,@SelDate)), DATEADD(m,1,@SelDate))

select count(*) from bettrans with (nolock) where winlostdate between @FirstDay and @LastDay

----
/*
Type	Data (MB)	Index (MB)	Rowcount
FULL	611,138.97	42,980.49	625,138,736
1	17,661.51	1,242.11	18,066,089
2	15,494.52	1,089.71	15,849,466
3	18,420.70	1,295.50	18,842,676
4	17,707.92	1,245.37	18,113,563
5	16,885.97	1,187.56	17,272,785
6	17,430.54	1,225.86	17,829,830
7	14,555.11	1,023.64	14,888,538
8	21,944.39	1,543.32	22,447,086
9	24,552.68	1,726.75	25,115,129
10	28,813.98	2,026.44	29,474,044
11	30,494.91	2,144.66	31,193,478
12	24,042.62	1,690.88	24,593,384
*/
----

ALTER DATABASE bodb_Archive08 ADD FILE (name = 'BET_08M01', filename ='P:\Archive\2008\BET\BET_08M01.ndf', SIZE = 17 GB ,FILEGROWTH = 1 GB ) TO filegroup [BET_08M01]
ALTER DATABASE bodb_Archive08 ADD FILE (name = 'BET_08M02', filename ='P:\Archive\2008\BET\BET_08M02.ndf', SIZE = 15 GB ,FILEGROWTH = 1 GB ) TO filegroup [BET_08M02]
ALTER DATABASE bodb_Archive08 ADD FILE (name = 'BET_08M03', filename ='P:\Archive\2008\BET\BET_08M03.ndf', SIZE = 18 GB ,FILEGROWTH = 1 GB ) TO filegroup [BET_08M03]
ALTER DATABASE bodb_Archive08 ADD FILE (name = 'BET_08M04', filename ='P:\Archive\2008\BET\BET_08M04.ndf', SIZE = 17 GB ,FILEGROWTH = 1 GB ) TO filegroup [BET_08M04]
ALTER DATABASE bodb_Archive08 ADD FILE (name = 'BET_08M05', filename ='P:\Archive\2008\BET\BET_08M05.ndf', SIZE = 17 GB ,FILEGROWTH = 1 GB ) TO filegroup [BET_08M05]
ALTER DATABASE bodb_Archive08 ADD FILE (name = 'BET_08M06', filename ='P:\Archive\2008\BET\BET_08M06.ndf', SIZE = 17 GB ,FILEGROWTH = 1 GB ) TO filegroup [BET_08M06]
ALTER DATABASE bodb_Archive08 ADD FILE (name = 'BET_08M07', filename ='P:\Archive\2008\BET\BET_08M07.ndf', SIZE = 1 GB ,FILEGROWTH = 1 GB ) TO filegroup [BET_08M07]
ALTER DATABASE bodb_Archive08 ADD FILE (name = 'BET_08M08', filename ='P:\Archive\2008\BET\BET_08M08.ndf', SIZE = 1 GB ,FILEGROWTH = 1 GB ) TO filegroup [BET_08M08]
ALTER DATABASE bodb_Archive08 ADD FILE (name = 'BET_08M09', filename ='P:\Archive\2008\BET\BET_08M09.ndf', SIZE = 1 GB ,FILEGROWTH = 1 GB ) TO filegroup [BET_08M09]
ALTER DATABASE bodb_Archive08 ADD FILE (name = 'BET_08M10', filename ='P:\Archive\2008\BET\BET_08M10.ndf', SIZE = 1 GB ,FILEGROWTH = 1 GB ) TO filegroup [BET_08M10]
ALTER DATABASE bodb_Archive08 ADD FILE (name = 'BET_08M11', filename ='P:\Archive\2008\BET\BET_08M11.ndf', SIZE = 1 GB ,FILEGROWTH = 1 GB ) TO filegroup [BET_08M11]
ALTER DATABASE bodb_Archive08 ADD FILE (name = 'BET_08M12', filename ='P:\Archive\2008\BET\BET_08M12.ndf', SIZE = 1 GB ,FILEGROWTH = 1 GB ) TO filegroup [BET_08M12]
ALTER DATABASE bodb_Archive08 ADD FILE (name = 'BET_INDEX', filename ='P:\Archive\2008\BET\BET_INDEX.ndf', SIZE = 17 GB ,FILEGROWTH = 1 GB ) TO filegroup [BET_INDEX]
----

--2
--Create partition function
CREATE PARTITION FUNCTION pf_BET_monthly (SMALLDATETIME) AS
RANGE LEFT FOR VALUES
(
 '2008-01-31 23:59:00',
 '2008-02-29 23:59:00',
 '2008-03-31 23:59:00',
 '2008-04-30 23:59:00',
 '2008-05-31 23:59:00',
 '2008-06-30 23:59:00',
 '2008-07-31 23:59:00',
 '2008-08-31 23:59:00',
 '2008-09-30 23:59:00',
 '2008-10-31 23:59:00',
 '2008-11-30 23:59:00'
)

--Create partition schema
CREATE PARTITION SCHEME ps_BET_monthly
AS PARTITION pf_BET_monthly
TO
    (
	[BET_08M01], 
	[BET_08M02], 
	[BET_08M03], 
	[BET_08M04], 
	[BET_08M05], 
	[BET_08M06], 
	[BET_08M07], 
	[BET_08M08], 
	[BET_08M09], 
	[BET_08M10], 
	[BET_08M11], 
	[BET_08M12]
 )                
GO
---
--CREATE TABLE AND INDEX


/****** Object:  Table [dbo].[bettrans_2008]    Script Date: 11/15/2009 08:50:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[bettrans_2008](
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
 CONSTRAINT [PK_bettrans_2008] PRIMARY KEY NONCLUSTERED 
(
	[transid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [BET_INDEX]
) ON [BET_INDEX]

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [CIX_winlostdate]    Script Date: 11/15/2009 08:50:10 ******/
CREATE CLUSTERED INDEX [CIX_winlostdate] ON [dbo].[bettrans_2008] 
(
	[winlostdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
ON ps_BET_monthly(winlostdate)
GO

/****** Object:  Index [IX_custid]    Script Date: 11/15/2009 08:50:10 ******/
CREATE NONCLUSTERED INDEX [IX_custid] ON [dbo].[bettrans_2008] 
(
	[custid] ASC
)
INCLUDE ( [winlostdate],
[matchid],
[bettype]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [BET_INDEX]
GO
-----
SELECT     transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, playercomm, comm, 
                      acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, livehomescore, 
                      liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, 
                      mrecommend, srecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype
FROM         bettrans_bk with (nolock)
where winlostdate between '2008-01-01' and '2008-01-31 23:59:00'

--------------------------
where winlostdate between '2008-01-01' and '2008-01-31 23:59:00'
where winlostdate between '2008-02-01' and '2008/02/29 23:59:00'
where winlostdate between '2008-03-01' and '2008/03/31 23:59:00'

where winlostdate between '2008-04-01' and '2008/04/30 23:59:00'
where winlostdate between '2008-05-01' and '2008/05/31 23:59:00'
where winlostdate between '2008-06-01' and '2008/06/30 23:59:00'

where winlostdate between '2008/07/01' AND 	'2008/07/31 23:59:00'
where winlostdate between '2008/08/01' AND 	'2008/08/31 23:59:00'
where winlostdate between '2008/09/01' AND 	'2008/09/30 23:59:00'
where winlostdate between '2008/10/01' AND 	'2008/10/31 23:59:00'
where winlostdate between '2008/11/01' AND 	'2008/11/30 23:59:00'
where winlostdate between '2008/12/01' AND 	'2008/12/31 23:59:00'

-------------------------

--DELETE DATA

USE [bodb_Archive]
GO
ALTER PROCEDURE [dbo].[DBA_DelBettrans_bk]
    @winlostdate smalldatetime
AS

if @winlostdate >= '2008-07-01' --to prevent mistake
    RETURN
    
Declare @RowsEffected int
Declare @RowsCnt int

SELECT @RowsEffected = 0

SET NOCOUNT ON
WHILE 1=1
BEGIN
    DELETE TOP(10000) FROM bettrans_bk where
        winlostdate between @winlostdate and dateadd(mi, 1439, @winlostdate) -- plus '23:59:00'
    
	SELECT @RowsCnt = @@ROWCOUNT
	SELECT @RowsEffected = @RowsEffected + @RowsCnt   

	IF @RowsCnt < 10000
        BREAK

END

SET NOCOUNT OFF

print convert(varchar(20), @winlostdate,0) + '-' + convert(varchar(20), dateadd(mi, 1439, @winlostdate),0) + ' - '+ convert(varchar,@RowsEffected) 
GO