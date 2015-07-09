---LDL

USE DWDB
GO

DROP TABLE TEMP

CREATE TABLE [dbo].[TEMP](
	[mm] tinyint NOT NULL,
	[fromdate] [datetime] NOT NULL,
	[todate] [datetime] NOT NULL,
	[status] [varchar](10) NOT NULL,
	[updatetime] [datetime] NULL
) ON [DATA]

INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (1, '1 Jan 2012', '31 Jan 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (2, '1 Feb 2012', '29 Feb 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (3, '1 Mar 2012', '31 Mar 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (4, '1 Apr 2012', '30 Apr 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (5, '1 May 2012', '31 May 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (6, '1 Jun 2012', '30 Jun 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (7, '1 Jul 2012', '31 Jul 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (8, '1 Aug 2012', '31 Aug 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (9, '1 Sep 2012', '30 Sep 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (10, '1 Oct 2012', '31 Oct 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (11, '1 Nov 2012', '30 Nov 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (12, '1 Dec 2012', '31 Dec 2012', '')


UPDATE TEMP SET status = '', updatetime = NULL

-- select * from site

--update bettrans_dw
--set LCSid = 4100300 -- 789y
--where winlostdate >= '1 Jan 2012'
--	and LCSid = 4130
	
select top 1 * from bettrans_dw with(nolock) where winlostdate = '1 Dec 2012' and LCSid = 4200300

WHILE (1 = 1)
BEGIN
	DECLARE @mm tinyint, @fromdate datetime, @todate datetime

	SELECT TOP 1 @mm = mm 
	FROM TEMP with(nolock) 
	where status <> 'done'
	order by 1
	
	IF @@ROWCOUNT = 0 BREAK

	UPDATE TEMP
	SET status = 'processing'
		,updatetime = CURRENT_TIMESTAMP
		,@fromdate = fromdate
		,@todate = todate
	WHERE mm = @mm
	
	SELECT @mm, @fromdate, @todate		
			
	------ start copying ------------------------	
		-- mansion88		
		INSERT INTO bettrans_dw (
			recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
			playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
			livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
			currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
		)
		SELECT NULL as recommid, 4200300 as LCSid, -- m88
			b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
			b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
			b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
			b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
			b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
			b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
			b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
			b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'Normal' as ticketType
		FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
			inner join bodb_staging.dbo.customer_viet c with(nolock) on b.recommend = c.custid
		where winlostdate between @fromdate and @todate
			and c.site in ('mansion88')
			and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
			and b.currency <> 20
			and (bettype < 31 OR bettype between 121 and 999)
		
		
		-- dela	[NO DATA]
		INSERT INTO bettrans_dw (
			recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
			playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
			livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
			currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
		)
		SELECT NULL as recommid, 4200600 as LCSid, -- DELA
			b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
			b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
			b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
			b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
			b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
			b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
			b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
			b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'Normal' as ticketType
		FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
			inner join bodb_staging.dbo.customer_viet c with(nolock) on b.recommend = c.custid
		where winlostdate between @fromdate and @todate
			and c.site in ('dela')
			and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
			and b.currency <> 20
			and (bettype < 31 OR bettype between 121 and 999)	
		
			
		-- 4200900 as LCSid, -- MayFair	
		INSERT INTO bettrans_dw (
			recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
			playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
			livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
			currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
		)
		SELECT NULL as recommid, 4200900 as LCSid, -- MayFair	
			b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
			b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
			b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
			b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
			b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
			b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
			b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
			b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'Normal' as ticketType
		FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
			inner join bodb_staging.dbo.customer_viet c with(nolock) on b.recommend = c.custid
		where winlostdate between @fromdate and @todate
			and c.site in ('MayFair')
			and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
			and b.currency <> 20
			and (bettype < 31 OR bettype between 121 and 999)	
			
		--4201000 as LCSid, -- SunGame	
		INSERT INTO bettrans_dw (
			recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
			playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
			livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
			currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
		)
		SELECT NULL as recommid, 4201000 as LCSid, -- SunGame	
			b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
			b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
			b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
			b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
			b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
			b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
			b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
			b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'Normal' as ticketType
		FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
			inner join bodb_staging.dbo.customer_viet c with(nolock) on b.recommend = c.custid
		where winlostdate between @fromdate and @todate
			and c.site in ('SunGame')
			and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
			and b.currency <> 20
			and (bettype < 31 OR bettype between 121 and 999)
			
		-- 4200700 as LCSid, -- ZZun88
		INSERT INTO bettrans_dw (
			recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
			playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
			livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
			currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
		)
		SELECT NULL as recommid, 4200700 as LCSid, -- ZZun88
			b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
			b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
			b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
			b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
			b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
			b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
			b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
			b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'Normal' as ticketType
		FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
			inner join bodb_staging.dbo.customer_viet c with(nolock) on b.recommend = c.custid
		where winlostdate between @fromdate and @todate
			and c.site in ('ZZun88')
			and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
			and b.currency <> 20
			and (bettype < 31 OR bettype between 121 and 999)
	------/ finished copying -----------------------------	
	
	UPDATE TEMP
	SET status = 'done'
		,updatetime = CURRENT_TIMESTAMP
	WHERE mm = @mm		
END
	
--select * from TEMP	
GO
----------------------------------------------------------------------------
----------------------------------------------------------------------------
---LDL TEST

USE DWDB
GO

DROP TABLE TEMP_Test

CREATE TABLE [dbo].[TEMP_Test](
	[mm] tinyint NOT NULL,
	[fromdate] [datetime] NOT NULL,
	[todate] [datetime] NOT NULL,
	[status] [varchar](10) NOT NULL,
	[updatetime] [datetime] NULL
) ON [DATA]

INSERT INTO DWDB.dbo.TEMP_Test (mm, fromdate, todate, status) values (1, '1 Jan 2012', '31 Jan 2012', '')
INSERT INTO DWDB.dbo.TEMP_Test (mm, fromdate, todate, status) values (2, '1 Feb 2012', '29 Feb 2012', '')
INSERT INTO DWDB.dbo.TEMP_Test (mm, fromdate, todate, status) values (3, '1 Mar 2012', '31 Mar 2012', '')
INSERT INTO DWDB.dbo.TEMP_Test (mm, fromdate, todate, status) values (4, '1 Apr 2012', '30 Apr 2012', '')
INSERT INTO DWDB.dbo.TEMP_Test (mm, fromdate, todate, status) values (5, '1 May 2012', '31 May 2012', '')
INSERT INTO DWDB.dbo.TEMP_Test (mm, fromdate, todate, status) values (6, '1 Jun 2012', '30 Jun 2012', '')
INSERT INTO DWDB.dbo.TEMP_Test (mm, fromdate, todate, status) values (7, '1 Jul 2012', '31 Jul 2012', '')
INSERT INTO DWDB.dbo.TEMP_Test (mm, fromdate, todate, status) values (8, '1 Aug 2012', '31 Aug 2012', '')
INSERT INTO DWDB.dbo.TEMP_Test (mm, fromdate, todate, status) values (9, '1 Sep 2012', '30 Sep 2012', '')
INSERT INTO DWDB.dbo.TEMP_Test (mm, fromdate, todate, status) values (10, '1 Oct 2012', '31 Oct 2012', '')
INSERT INTO DWDB.dbo.TEMP_Test (mm, fromdate, todate, status) values (11, '1 Nov 2012', '30 Nov 2012', '')
INSERT INTO DWDB.dbo.TEMP_Test (mm, fromdate, todate, status) values (12, '1 Dec 2012', '31 Dec 2012', '')


-- select * from site

WHILE (1 = 1)
BEGIN
	DECLARE @mm tinyint, @fromdate datetime, @todate datetime

	SELECT TOP 1 @mm = mm 
	FROM TEMP_Test with(nolock) 
	where status <> 'done'
	order by 1
	
	IF @@ROWCOUNT = 0 BREAK

	UPDATE TEMP_Test
	SET status = 'processing'
		,updatetime = CURRENT_TIMESTAMP
		,@fromdate = fromdate
		,@todate = todate
	WHERE mm = @mm
	
	SELECT @mm, @fromdate, @todate		
			
	------ start copying ------------------------	
		-- mansion88		
		INSERT INTO bettrans_test (
			recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
			playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
			livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
			currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
		)
		SELECT NULL as recommid, 4200300 as LCSid, -- m88
			b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
			b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
			b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
			b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
			b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
			b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
			b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
			b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
		FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
			inner join bodb_staging.dbo.customer_viet c with(nolock) on b.recommend = c.custid
		where winlostdate between @fromdate and @todate
			and c.site in ('mansion88')
			and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
			and b.currency = 20
			and (bettype < 31 OR bettype between 121 and 999)
		
		/*
		-- dela	[NO DATA]
		INSERT INTO bettrans_test (
			recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
			playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
			livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
			currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
		)
		SELECT NULL as recommid, 4200600 as LCSid, -- DELA
			b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
			b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
			b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
			b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
			b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
			b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
			b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
			b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
		FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
			inner join bodb_staging.dbo.customer_viet c with(nolock) on b.recommend = c.custid
		where winlostdate between @fromdate and @todate
			and c.site in ('dela')
			and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
			and b.currency = 20
			and (bettype < 31 OR bettype between 121 and 999)	
		*/
			
		-- 4200900 as LCSid, -- MayFair	
		INSERT INTO bettrans_test (
			recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
			playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
			livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
			currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
		)
		SELECT NULL as recommid, 4200900 as LCSid, -- MayFair	
			b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
			b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
			b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
			b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
			b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
			b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
			b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
			b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
		FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
			inner join bodb_staging.dbo.customer_viet c with(nolock) on b.recommend = c.custid
		where winlostdate between @fromdate and @todate
			and c.site in ('MayFair')
			and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
			and b.currency = 20
			and (bettype < 31 OR bettype between 121 and 999)	
			
		--4201000 as LCSid, -- SunGame	
		INSERT INTO bettrans_test (
			recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
			playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
			livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
			currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
		)
		SELECT NULL as recommid, 4201000 as LCSid, -- SunGame	
			b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
			b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
			b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
			b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
			b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
			b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
			b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
			b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
		FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
			inner join bodb_staging.dbo.customer_viet c with(nolock) on b.recommend = c.custid
		where winlostdate between @fromdate and @todate
			and c.site in ('SunGame')
			and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
			and b.currency = 20
			and (bettype < 31 OR bettype between 121 and 999)
			
		-- 4200700 as LCSid, -- ZZun88
		INSERT INTO bettrans_test (
			recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
			playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
			livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
			currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
		)
		SELECT NULL as recommid, 4200700 as LCSid, -- ZZun88
			b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
			b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
			b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
			b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
			b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
			b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
			b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
			b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
		FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
			inner join bodb_staging.dbo.customer_viet c with(nolock) on b.recommend = c.custid
		where winlostdate between @fromdate and @todate
			and c.site in ('ZZun88')
			and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
			and b.currency = 20
			and (bettype < 31 OR bettype between 121 and 999)
	------/ finished copying -----------------------------	
	
	UPDATE TEMP_Test
	SET status = 'done'
		,updatetime = CURRENT_TIMESTAMP
	WHERE mm = @mm		
END
	
select * from TEMP_Test	