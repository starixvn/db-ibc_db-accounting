USE bodb_Archive09
GO
ALTER DATABASE bodb_Archive09 ADD filegroup [BET_09M01]
ALTER DATABASE bodb_Archive09 ADD filegroup [BET_09M02]
ALTER DATABASE bodb_Archive09 ADD filegroup [BET_09M03]
ALTER DATABASE bodb_Archive09 ADD filegroup [BET_09M04]
ALTER DATABASE bodb_Archive09 ADD filegroup [BET_09M05]
ALTER DATABASE bodb_Archive09 ADD filegroup [BET_09M06]
ALTER DATABASE bodb_Archive09 ADD filegroup [BET_09M07]
ALTER DATABASE bodb_Archive09 ADD filegroup [BET_09M08]
ALTER DATABASE bodb_Archive09 ADD filegroup [BET_09M09]
ALTER DATABASE bodb_Archive09 ADD filegroup [BET_09M10]
ALTER DATABASE bodb_Archive09 ADD filegroup [BET_09M11]
ALTER DATABASE bodb_Archive09 ADD filegroup [BET_09M12]

----

ALTER DATABASE bodb_Archive09 ADD FILE (name = 'BET_09M01', filename ='P:\Archive\2009\BET\BET_09M01.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [BET_09M01]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'BET_09M02', filename ='P:\Archive\2009\BET\BET_09M02.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [BET_09M02]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'BET_09M03', filename ='P:\Archive\2009\BET\BET_09M03.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [BET_09M03]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'BET_09M04', filename ='P:\Archive\2009\BET\BET_09M04.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [BET_09M04]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'BET_09M05', filename ='P:\Archive\2009\BET\BET_09M05.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [BET_09M05]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'BET_09M06', filename ='P:\Archive\2009\BET\BET_09M06.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [BET_09M06]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'BET_09M07', filename ='P:\Archive\2009\BET\BET_09M07.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [BET_09M07]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'BET_09M08', filename ='P:\Archive\2009\BET\BET_09M08.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [BET_09M08]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'BET_09M09', filename ='P:\Archive\2009\BET\BET_09M09.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [BET_09M09]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'BET_09M10', filename ='P:\Archive\2009\BET\BET_09M10.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [BET_09M10]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'BET_09M11', filename ='P:\Archive\2009\BET\BET_09M11.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [BET_09M11]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'BET_09M12', filename ='P:\Archive\2009\BET\BET_09M12.ndf', SIZE = 32MB ,FILEGROWTH = 16MB ) TO filegroup [BET_09M12]
----

--2
--Create partition function
CREATE PARTITION FUNCTION pf_BET_monthly (SMALLDATETIME) AS
RANGE LEFT FOR VALUES
(
 '2009-01-31 23:59:00',
 '2009-02-28 23:59:00',
 '2009-03-31 23:59:00',
 '2009-04-30 23:59:00',
 '2009-05-31 23:59:00',
 '2009-06-30 23:59:00',
 '2009-07-31 23:59:00',
 '2009-08-31 23:59:00',
 '2009-09-30 23:59:00',
 '2009-10-31 23:59:00',
 '2009-11-30 23:59:00'
)

--Create partition schema
CREATE PARTITION SCHEME ps_BET_monthly
AS PARTITION pf_BET_monthly
TO
    (
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
	[BET_09M12]
 )                
GO
---
--CREATE TABLE AND INDEX


/****** Object:  Table [dbo].[bettrans_2009]    Script Date: 11/15/2009 08:50:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[bettrans_2009](
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
	[bettype] [smallint] NULL
) 

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [CIX_winlostdate]    Script Date: 11/15/2009 08:50:10 ******/
CREATE CLUSTERED INDEX [CIX_winlostdate] ON [dbo].[bettrans_2009] 
(
	[winlostdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
ON ps_BET_monthly(winlostdate)
GO

/****** Object:  Index [IX_custid]    Script Date: 11/15/2009 08:50:10 ******/
CREATE NONCLUSTERED INDEX [IX_custid] ON [dbo].[bettrans_2009] 
(
	[custid] ASC
)
INCLUDE ( [winlostdate],
[matchid],
[bettype]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON  ps_BET_monthly(winlostdate)

GO
-----
USE [bodb_Archive09]
GO
CREATE  NONCLUSTERED INDEX [IX_transid] ON [dbo].[bettrans_2009] 
(
	[transid] ASC
)WITH (STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ps_BET_monthly]([winlostdate])
GO

------
SELECT    custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, 
                      scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, livehomescore, 
                      liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, 
                      mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, currency2, 
                      transid, bettype
FROM         bettrans_bk WITH (nolock)

where winlostdate between '2009/12/01' AND 	'2009/12/31 23:59:00'

--------------------------
where winlostdate between '2009-01-01' and '2009-01-31 23:59:00'
where winlostdate between '2009-02-01' and '2009/02/28 23:59:00'
where winlostdate between '2009-03-01' and '2009/03/31 23:59:00'

where winlostdate between '2009-04-01' and '2009/04/30 23:59:00'
where winlostdate between '2009-05-01' and '2009/05/31 23:59:00'
where winlostdate between '2009-06-01' and '2009/06/30 23:59:00'

where winlostdate between '2009/07/01' AND 	'2009/07/31 23:59:00'
where winlostdate between '2009/08/01' AND 	'2009/08/31 23:59:00'
where winlostdate between '2009/09/01' AND 	'2009/09/30 23:59:00'
where winlostdate between '2009/10/01' AND 	'2009/10/31 23:59:00'
where winlostdate between '2009/11/01' AND 	'2009/11/30 23:59:00'
where winlostdate between '2009/12/01' AND 	'2009/12/31 23:59:00'

-------------------------

--DELETE DATA

USE [bodb_Archive]
GO
ALTER PROCEDURE [dbo].[DBA_DelBettrans_bk]
    @winlostdate smalldatetime
AS

if @winlostdate >= '2010-01-01' --to prevent mistake
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