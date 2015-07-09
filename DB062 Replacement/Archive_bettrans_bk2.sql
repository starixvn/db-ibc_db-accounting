 
----------------------------------------------
---2
-- create folder G:\IBC_DB\bodb_Archive\BETBK
-------------------------------
--CREATE FILEGROUPS and FILES
USE bodb_Archive
GO

ALTER DATABASE bodb_Archive ADD filegroup [BETBK_10M01]
ALTER DATABASE bodb_Archive ADD filegroup [BETBK_10M02]
ALTER DATABASE bodb_Archive ADD filegroup [BETBK_10M03]
ALTER DATABASE bodb_Archive ADD filegroup [BETBK_10M04]
ALTER DATABASE bodb_Archive ADD filegroup [BETBK_10M05]
ALTER DATABASE bodb_Archive ADD filegroup [BETBK_10M06]
ALTER DATABASE bodb_Archive ADD filegroup [BETBK_10M07]
ALTER DATABASE bodb_Archive ADD filegroup [BETBK_10M08]
ALTER DATABASE bodb_Archive ADD filegroup [BETBK_10M09]
ALTER DATABASE bodb_Archive ADD filegroup [BETBK_10M10]
ALTER DATABASE bodb_Archive ADD filegroup [BETBK_10M11]
ALTER DATABASE bodb_Archive ADD filegroup [BETBK_10M12]

ALTER DATABASE bodb_Archive ADD filegroup [BETBK_MAX]


--------------

ALTER DATABASE bodb_Archive ADD FILE (name = 'BETBK_10M01', filename ='G:\IBC_DB\bodb_Archive\BETBK\BETBK_10M01.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [BETBK_10M01]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETBK_10M02', filename ='G:\IBC_DB\bodb_Archive\BETBK\BETBK_10M02.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [BETBK_10M02]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETBK_10M03', filename ='G:\IBC_DB\bodb_Archive\BETBK\BETBK_10M03.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [BETBK_10M03]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETBK_10M04', filename ='G:\IBC_DB\bodb_Archive\BETBK\BETBK_10M04.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [BETBK_10M04]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETBK_10M05', filename ='G:\IBC_DB\bodb_Archive\BETBK\BETBK_10M05.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [BETBK_10M05]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETBK_10M06', filename ='G:\IBC_DB\bodb_Archive\BETBK\BETBK_10M06.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [BETBK_10M06]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETBK_10M07', filename ='G:\IBC_DB\bodb_Archive\BETBK\BETBK_10M07.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [BETBK_10M07]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETBK_10M08', filename ='G:\IBC_DB\bodb_Archive\BETBK\BETBK_10M08.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [BETBK_10M08]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETBK_10M09', filename ='G:\IBC_DB\bodb_Archive\BETBK\BETBK_10M09.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [BETBK_10M09]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETBK_10M10', filename ='G:\IBC_DB\bodb_Archive\BETBK\BETBK_10M10.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [BETBK_10M10]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETBK_10M11', filename ='G:\IBC_DB\bodb_Archive\BETBK\BETBK_10M11.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [BETBK_10M11]
ALTER DATABASE bodb_Archive ADD FILE (name = 'BETBK_10M12', filename ='G:\IBC_DB\bodb_Archive\BETBK\BETBK_10M12.ndf', SIZE = 2MB ,FILEGROWTH = 32MB ) TO filegroup [BETBK_10M12]

ALTER DATABASE bodb_Archive ADD FILE (name = 'BETBK_MAX', filename ='G:\IBC_DB\bodb_Archive\BETBK\BETBK_MAX.ndf', SIZE = 1MB ,FILEGROWTH = 32MB ) TO filegroup [BETBK_MAX]


----

--2
--Create partition function
CREATE PARTITION FUNCTION pf_BETBK_monthly (SMALLDATETIME) AS
RANGE LEFT FOR VALUES
(    
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
CREATE PARTITION SCHEME ps_BETBK_monthly
AS PARTITION pf_BETBK_monthly
TO
    (	
	[BETBK_10M01], 
	[BETBK_10M02], 
	[BETBK_10M03], 
	[BETBK_10M04], 
	[BETBK_10M05], 
	[BETBK_10M06], 
	[BETBK_10M07], 
	[BETBK_10M08], 
	[BETBK_10M09], 
	[BETBK_10M10], 
	[BETBK_10M11], 
	[BETBK_10M12],
	
	[BETBK_MAX]
	
 )                
GO
---
--CREATE TABLE AND INDEX

/****** Object:  Table [dbo].[bettrans_bk2]    Script Date: 11/15/2010 08:50:10 ******/
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
	[bettype] [smallint] NULL,
	[balance] [money] NULL
) 

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [CIX_winlostdate]    Script Date: 11/15/2010 08:50:10 ******/
CREATE CLUSTERED INDEX [CIX_winlostdate] ON [dbo].[bettrans_bk2] 
(
	[winlostdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
ON ps_BETBK_monthly(winlostdate)
GO

/****** Object:  Index [IX_custid]    Script Date: 11/15/2010 08:50:10 ******/
CREATE NONCLUSTERED INDEX [IX_custid] ON [dbo].[bettrans_bk2] 
(
	[custid] ASC
)
INCLUDE ( [winlostdate],
[matchid],
[bettype]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON  ps_BETBK_monthly(winlostdate)

GO
-----
USE [bodb_Archive]
GO
CREATE  NONCLUSTERED INDEX [IX_transid] ON [dbo].[bettrans_bk2] 
(
	[transid] ASC
)WITH (STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ps_BETBK_monthly]([winlostdate])
GO
------------------------------

SELECT    custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, 
                      scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, livehomescore, 
                      liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, 
                      mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, currency2, 
                      transid, bettype, balance
FROM         bettrans_bk WITH (nolock)
where winlostdate between '2010/12/01' AND 	'2010/12/31 23:59:00'

--------------------------
-------------
where winlostdate between '2010-01-01' and '2010-01-31 23:59:00'
where winlostdate between '2010-02-01' and '2010/02/28 23:59:00'
where winlostdate between '2010-03-01' and '2010/03/31 23:59:00'

where winlostdate between '2010-04-01' and '2010/04/30 23:59:00'
where winlostdate between '2010-05-01' and '2010/05/31 23:59:00'
where winlostdate between '2010-06-01' and '2010/06/30 23:59:00'

where winlostdate between '2010/07/01' AND 	'2010/07/31 23:59:00'
where winlostdate between '2010/08/01' AND 	'2010/08/31 23:59:00'
where winlostdate between '2010/09/01' AND 	'2010/09/30 23:59:00'
where winlostdate between '2010/10/01' AND 	'2010/10/31 23:59:00'
where winlostdate between '2010/11/01' AND 	'2010/11/30 23:59:00'
where winlostdate between '2010/12/01' AND 	'2010/12/31 23:59:00'

---------
where winlostdate between '2011/01/01' AND 	'2011/01/31 23:59:00'
where winlostdate between '2011/02/01' AND 	'2011/02/28 23:59:00'
where winlostdate between '2011/03/01' AND 	'2011/03/31 23:59:00'
where winlostdate between '2011/04/01' AND 	'2011/04/30 23:59:00'
where winlostdate between '2011/05/01' AND 	'2011/05/31 23:59:00'
where winlostdate between '2011/06/01' AND 	'2011/06/30 23:59:00'
where winlostdate between '2011/07/01' AND 	'2011/07/31 23:59:00'
where winlostdate between '2011/08/01' AND 	'2011/08/31 23:59:00'
where winlostdate between '2011/09/01' AND 	'2011/09/30 23:59:00'
where winlostdate between '2011/10/01' AND 	'2011/10/31 23:59:00'
where winlostdate between '2011/11/01' AND 	'2011/11/30 23:59:00'
where winlostdate between '2011/12/01' AND 	'2011/12/31 23:59:00'



