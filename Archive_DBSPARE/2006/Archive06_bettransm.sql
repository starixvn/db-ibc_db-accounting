 USE [master]
GO
ALTER DATABASE [bodb_Archive06] ADD FILEGROUP [Bettransm]
GO
ALTER DATABASE [bodb_Archive06] ADD FILE ( NAME = N'bodb_Archive06_bettransm', FILENAME = N'P:\Archive\2006\bodb_Archive06_bettransm.ndf' , SIZE = 2048KB , FILEGROWTH = 16384KB ) TO FILEGROUP [Bettransm]
GO
------------------
USE [bodb_Archive06]
GO
CREATE TABLE [dbo].[bettransm_2006](
	[transid] [int] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[oddsid] [int] NOT NULL,
	[hdp1] [smallmoney] NULL,
	[hdp2] [smallmoney] NULL,
	[odds] [smallmoney] NULL,
	[stake] [money] NOT NULL,
	[status] [varchar](10) NULL,
	[winlost] [money] NULL,
	[livehomescore] [smallint] NULL,
	[liveawayscore] [smallint] NULL,
	[liveindicator] [bit] NULL,
	[betteam] [varchar](10) NULL,
	[creator] [int] NOT NULL,
	[refno] [bigint] NOT NULL,
	[comstatus] [varchar](20) NULL,
	[winlostdate] [smalldatetime] NULL,
	[betfrom] [varchar](1) NULL,
	[betcheck] [varchar](50) NULL,
	[checktime] [smalldatetime] NULL,
	[oddsspread] [smallmoney] NULL,
	
	[apositiontaking] [smallmoney] NULL,
	[mpositiontaking] [smallmoney] NULL,
	[spositiontaking] [smallmoney] NULL,
	[tpositiontaking] [smallmoney] NULL,
	
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,

	[playerdiscount] [decimal](9, 8) NULL,
	[discount] [decimal](9, 8) NULL,
	[adiscount] [decimal](9, 8) NULL,
	[sdiscount] [decimal](9, 8) NULL,

	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,

	[actualrate] [float] NULL,
	[matchid] [int] NULL,
	[matchdate] [smalldatetime] NULL,
	[finalodds] [smallmoney] NULL,
	[isfinish] [char](1) NULL,
	[statuswinlost] [tinyint] NULL,
	[ruben] [tinyint] NULL,
	[bettype] [tinyint] NULL,
	
 CONSTRAINT [PK_bettransm_2006] PRIMARY KEY NONCLUSTERED 
(
	[transid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Bettransm]
) ON [Bettransm]

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [IX_bettransm_2006]    Script Date: 11/22/2009 15:36:48 ******/
CREATE CLUSTERED INDEX [IX_bettransm_2006] ON [dbo].[bettransm_2006] 
(
	[refno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
ON [Bettransm]

GO
CREATE NONCLUSTERED INDEX [IX_winlostdate] ON [dbo].[bettransm_2006] 
(
	[winlostdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
ON [Bettransm]
-----------
--IMPORT DATA

SELECT  transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, 
                      refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, awinlost, 
                      mwinlost, swinlost, playerdiscount, discount, adiscount, sdiscount, playercomm, comm, acomm, scomm, actualrate, matchid, matchdate, finalodds, 
                      isfinish, statuswinlost, ruben, bettype
from bettransm with (nolock) 
where winlostdate BETWEEN
'2006/12/01' AND 	'2006/12/31 23:59:00'

-----------------------
'2006/01/01' AND 	'2006/01/31 23:59:00'
'2006/02/01' AND 	'2006/02/28 23:59:00'
'2006/03/01' AND 	'2006/03/31 23:59:00'
'2006/04/01' AND 	'2006/04/30 23:59:00'
'2006/05/01' AND 	'2006/05/31 23:59:00'
'2006/06/01' AND 	'2006/06/30 23:59:00'
'2006/07/01' AND 	'2006/07/31 23:59:00'
'2006/08/01' AND 	'2006/08/31 23:59:00'
'2006/09/01' AND 	'2006/09/30 23:59:00'
'2006/10/01' AND 	'2006/10/31 23:59:00'
'2006/11/01' AND 	'2006/11/30 23:59:00'
'2006/12/01' AND 	'2006/12/31 23:59:00'

------------
--DOUBLE CHECK THE DATA
select datepart(month, winlostdate), count(*)
from bettransm with (nolock)
where winlostdate BETWEEN 
'2006/01/01' AND 	'2006/12/31 23:59:00'
group by datepart(month, winlostdate)
order by datepart(month, winlostdate)
1	491114
2	541551
3	739722
4	829337
5	492872
6	372233
7	470147
8	910495
9	1462915
10	1632216
11	2093049
12	1979039
select datepart(month, winlostdate), count(*)
from bettransm_2006 with (nolock)
group by datepart(month, winlostdate)
order by datepart(month, winlostdate)
--DROP INDEX IX_winlostdate
