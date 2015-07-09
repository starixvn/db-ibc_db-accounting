SELECT     transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, playercomm, comm, 
                      acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, livehomescore, 
                      liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, 
                      mrecommend, srecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype
FROM         bettrans_bk with (nolock)
where winlostdate between '2008/12/01' AND 	'2008/12/31 23:59:00'
--------------

--DELETE DATA
------------
--MERGE PARTITION
--
ALTER PARTITION FUNCTION pf_BET_monthly() MERGE RANGE ('2008-07-31 23:59:00.000')
GO
ALTER PARTITION FUNCTION pf_BET_monthly() MERGE RANGE ('2008-08-31 23:59:00.000')
GO
ALTER PARTITION FUNCTION pf_BET_monthly() MERGE RANGE ('2008-09-30 23:59:00.000')
GO
ALTER PARTITION FUNCTION pf_BET_monthly() MERGE RANGE ('2008-10-31 23:59:00.000')
GO
ALTER PARTITION FUNCTION pf_BET_monthly() MERGE RANGE ('2008-11-30 23:59:00.000')
GO
ALTER PARTITION FUNCTION pf_BET_monthly() MERGE RANGE ('2008-12-31 23:59:00.000')
GO
------------
USE [bodb_Archive]
GO
ALTER DATABASE [bodb_Archive]  REMOVE FILE [BET_08M08]
GO
ALTER DATABASE [bodb_Archive] REMOVE FILEGROUP [BET_08M08]
GO
----
--...
USE [bodb_Archive]
GO
ALTER DATABASE [bodb_Archive]  REMOVE FILE [BET_08M12]
GO
ALTER DATABASE [bodb_Archive] REMOVE FILEGROUP [BET_08M12]
GO
