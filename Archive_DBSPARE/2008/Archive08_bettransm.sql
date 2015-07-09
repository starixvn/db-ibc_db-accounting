 USE [master]
GO
ALTER DATABASE [bodb_Archive08] ADD FILEGROUP [Bettransm]
GO
ALTER DATABASE [bodb_Archive08] ADD FILE ( NAME = N'bodb_Archive08_bettransm-1', FILENAME = N'P:\Archive\2008\bodb_Archive08_bettransm-1.ndf' , SIZE = 2048KB , FILEGROWTH = 32MB ) TO FILEGROUP [Bettransm]
GO
ALTER DATABASE [bodb_Archive08] ADD FILE ( NAME = N'bodb_Archive08_bettransm-2', FILENAME = N'P:\Archive\2008\bodb_Archive08_bettransm-2.ndf' , SIZE = 2048KB , FILEGROWTH = 32MB ) TO FILEGROUP [Bettransm]
GO
------------------
USE [bodb_Archive08]
GO
CREATE TABLE [dbo].[bettransm_2008](
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
	
 CONSTRAINT [PK_bettransm_2008] PRIMARY KEY NONCLUSTERED 
(
	[transid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Bettransm]
) ON [Bettransm]

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [IX_bettransm_2008]    Script Date: 11/22/2009 15:36:48 ******/
CREATE CLUSTERED INDEX [IX_bettransm_2008] ON [dbo].[bettransm_2008] 
(
	[refno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
ON [Bettransm]

GO
CREATE NONCLUSTERED INDEX [IX_winlostdate] ON [dbo].[bettransm_2008] 
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
----------------
'2008/04/01' AND 	'2008/04/30 23:59:00'
'2008/05/01' AND 	'2008/05/31 23:59:00'
'2008/06/01' AND 	'2008/06/30 23:59:00'
'2008/07/01' AND 	'2008/07/31 23:59:00'
'2008/08/01' AND 	'2008/08/31 23:59:00'
'2008/09/01' AND 	'2008/09/30 23:59:00'
'2008/10/01' AND 	'2008/10/31 23:59:00'
'2008/11/01' AND 	'2008/11/30 23:59:00'
'2008/12/01' AND 	'2008/12/31 23:59:00'

SELECT [refno]
      ,[transid]
      ,[custid]
      ,[transdate]
      ,[oddsid]
      ,[hdp1]
      ,[hdp2]
      ,[odds]
      ,[stake]
      ,[status]
      ,[winlost]
      ,[betteam]
      ,[winlostdate]
      ,[matchid]
      ,[bettype]
      , 0 as creator
from bettransm with (nolock) 
where winlostdate BETWEEN
'2008/01/01' AND 	'2008/01/31 23:59:00'
'2008/02/01' AND 	'2008/02/29 23:59:00'
'2008/03/01' AND 	'2008/03/31 23:59:00'
'2008/04/01' AND 	'2008/04/30 23:59:00'


------------
--DOUBLE CHECK THE DATA
select datepart(month, winlostdate), count(*)
from bettransm with (nolock)
where winlostdate BETWEEN 
'2008/01/01' AND 	'2008/12/31 23:59:00'
group by datepart(month, winlostdate)
order by datepart(month, winlostdate)
 /*
4	68740
5	1158270
6	776469
7	1094178
8	2007467
9	2331783
10	2917250
11	3644424
12	2904521
 */
select datepart(month, winlostdate), count(*)
from bettransm_2008 with (nolock)
group by datepart(month, winlostdate)
order by datepart(month, winlostdate)
--DROP INDEX IX_winlostdate
-------------------
--DELETE DATA

