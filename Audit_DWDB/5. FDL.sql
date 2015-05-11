-- Jan
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 
	CASE c.custid WHEN 52466 THEN 'Internal' ELSE 'Normal' END as ticketType
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.customer_0204 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Jan 2012' and '31 Jan 2012'
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
	
-- FEB
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 
	CASE c.custid WHEN 52466 THEN 'Internal' ELSE 'Normal' END as ticketType
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.customer_0329 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Feb 2012' and '29 Feb 2012'
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund		
	
-- Mar
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 
	CASE c.custid WHEN 52466 THEN 'Internal' ELSE 'Normal' END as ticketType
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.customer_0407 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Mar 2012' and '31 Mar 2012'
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund	

-- APR
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 
	CASE c.custid WHEN 52466 THEN 'Internal' ELSE 'Normal' END as ticketType
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.customer_0503 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Apr 2012' and '30 Apr 2012'
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund	
	
	
-- May
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 
	CASE c.custid WHEN 52466 THEN 'Internal' ELSE 'Normal' END as ticketType
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_0607 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 May 2012' and '31 May 2012'
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund	


-- Jun
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 
	CASE c.custid WHEN 52466 THEN 'Internal' ELSE 'Normal' END as ticketType
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_0705 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Jun 2012' and '30 Jun 2012'
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund	
	
-- JUL	
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 
	CASE c.custid WHEN 52466 THEN 'Internal' ELSE 'Normal' END as ticketType
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_0802 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Jul 2012' and '31 Jul 2012'
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund	
		
-- Aug
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 
	CASE c.custid WHEN 52466 THEN 'Internal' ELSE 'Normal' END as ticketType
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_0906 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Aug 2012' and '31 Aug 2012'
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund	
	
-- SEP
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 
	CASE c.custid WHEN 52466 THEN 'Internal' ELSE 'Normal' END as ticketType
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_1013 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Sep 2012' and '30 Sep 2012'
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund	
		
-- OCT
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 
	CASE c.custid WHEN 52466 THEN 'Internal' ELSE 'Normal' END as ticketType
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_1108 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 OCT 2012' and '31 OCT 2012'
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund		
	
-- NOV
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 
	CASE c.custid WHEN 52466 THEN 'Internal' ELSE 'Normal' END as ticketType
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_1206 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 NOV 2012' and '30 NOV 2012'
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund	

-- DEC

INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 
	CASE c.custid WHEN 52466 THEN 'Internal' ELSE 'Normal' END as ticketType
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join bodb_staging.dbo.customer_viet c with(nolock) on b.recommend = c.custid
where winlostdate between '1 DEC 2012' and '31 DEC 2012'
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)	
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund	
		
------------------
---------------------
-- exclude tickets under BARM from 6.Jun.2012 onwards
update bettrans_dw
set ticketType = 'Internal'
where lcsid = 4100200
and recommend = 5707545
and winlostdate between '6 Jun 2012' and '31 DEC 2012'


--------------------------------------------------------------------
--------------------------- TEST DATA ------------------------------
--------------------------------------------------------------------

-- jan
INSERT INTO DWDB.dbo.bettrans_test(
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
)
SELECT 
	NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.customer_0204 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Jan 2012' and '31 Jan 2012'
	and c.site in ('INDO','722222','733333','755555','222223','222225')
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	
-- feb
INSERT INTO DWDB.dbo.bettrans_test(
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
)
SELECT 
	NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_0329 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Feb 2012' and '29 Feb 2012'
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and c.currency = 20

-- Mar
INSERT INTO DWDB.dbo.bettrans_test(
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
)
SELECT 
	NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_0407 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Mar 2012' and '31 Mar 2012'
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and c.currency = 20

-- APR
DECLARE @fromdate smalldatetime, @todate smalldatetime

SET @fromdate = '1 Apr 2012'
SELECT @todate = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@fromdate)+1,0))

INSERT INTO DWDB.dbo.bettrans_test(
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
)
SELECT 
	NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_0503 c with(nolock) on b.recommend = c.custid
where winlostdate between @fromdate and @todate
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and c.currency = 20

-- May
DECLARE @fromdate smalldatetime, @todate smalldatetime

SET @fromdate = '1 May 2012'
SELECT @todate = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@fromdate)+1,0))

INSERT INTO DWDB.dbo.bettrans_test(
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
)
SELECT 
	NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_0607 c with(nolock) on b.recommend = c.custid
where winlostdate between @fromdate and @todate
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and c.currency = 20
					
-- JUN
DECLARE @fromdate smalldatetime, @todate smalldatetime

SET @fromdate = '1 JUN 2012'
SELECT @todate = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@fromdate)+1,0))

INSERT INTO DWDB.dbo.bettrans_test(
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
)
SELECT 
	NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_0705 c with(nolock) on b.recommend = c.custid
where winlostdate between @fromdate and @todate
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and c.currency = 20
							
-- JUL
DECLARE @fromdate smalldatetime, @todate smalldatetime

SET @fromdate = '1 JUL 2012'
SELECT @todate = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@fromdate)+1,0))

INSERT INTO DWDB.dbo.bettrans_test(
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
)
SELECT 
	NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_0802 c with(nolock) on b.recommend = c.custid
where winlostdate between @fromdate and @todate
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and c.currency = 20
GO				
-- AUG
DECLARE @fromdate smalldatetime, @todate smalldatetime

SET @fromdate = '1 AUG 2012'
SELECT @todate = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@fromdate)+1,0))

INSERT INTO DWDB.dbo.bettrans_test(
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
)
SELECT 
	NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_0906 c with(nolock) on b.recommend = c.custid
where winlostdate between @fromdate and @todate
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and c.currency = 20
GO									

-- SEP
DECLARE @fromdate smalldatetime, @todate smalldatetime

SET @fromdate = '1 SEP 2012'
SELECT @todate = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@fromdate)+1,0))

INSERT INTO DWDB.dbo.bettrans_test(
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
)
SELECT 
	NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_1013 c with(nolock) on b.recommend = c.custid
where winlostdate between @fromdate and @todate
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and c.currency = 20
GO

-- OCT
DECLARE @fromdate smalldatetime, @todate smalldatetime

SET @fromdate = '1 OCT 2012'
SELECT @todate = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@fromdate)+1,0))

INSERT INTO DWDB.dbo.bettrans_test(
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
)
SELECT 
	NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_1108 c with(nolock) on b.recommend = c.custid
where winlostdate between @fromdate and @todate
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and c.currency = 20
GO

-- NOV
DECLARE @fromdate smalldatetime, @todate smalldatetime

SET @fromdate = '1 NOV 2012'
SELECT @todate = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@fromdate)+1,0))

INSERT INTO DWDB.dbo.bettrans_test(
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
)
SELECT 
	NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.Customer_1206 c with(nolock) on b.recommend = c.custid
where winlostdate between @fromdate and @todate
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	and c.currency = 20
GO

-- DEC
INSERT INTO DWDB.dbo.bettrans_test(
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
)
SELECT 
	NULL as recommid, 
	CASE c.site 
		WHEN 'BEST-ODDS' THEN 4100200
		WHEN 'XYZBET' THEN 4100800
		WHEN '611111' THEN 4100900
		WHEN '222227' THEN 4100600
		WHEN 'spotico' THEN 4100400
		WHEN 'KORIBC' THEN 4100700
		WHEN 'INDO' THEN 4101500
		WHEN '722222' THEN 4101300
		WHEN '733333' THEN 4101100
		WHEN '755555' THEN 4101400
		WHEN '222223' THEN 4101000
		WHEN '222225' THEN 4101200
		ELSE NULL 
	END as LCSid, 
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
where winlostdate between '1 DEC 2012' and '31 DEC 2012'
	and c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and currency = 20
	and (bettype < 31 OR bettype between 121 and 999)	
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
GO