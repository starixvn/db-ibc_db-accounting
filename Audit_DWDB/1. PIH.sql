--PIH

-- MAR 2012 [billing: 38,080,985 diff: +2, void/reject/refund: 792,515
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT 
	NULL as recommid, 4100300 as LCSid, b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'Normal' as ticketType
FROM dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.customer_0407 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Mar 2012' and '31 Mar 2012'
	and c.site in ('789y')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
--

-- APR [billing: 38,266,798 diff: -2, void/reject/refund: 790,914]
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 4100300 as LCSid, b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'Normal' as ticketType
FROM dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.customer_0503 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Apr 2012' and '30 Apr 2012'
	and c.site in ('789y')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2	
	
-- MAY [billing: 29,898,405 diff: 0], [void/reject/refund: 615,274] 	
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 4100300 as LCSid, b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'Normal' as ticketType
FROM dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.customer_0607 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 May 2012' and '31 may 2012'
	and c.site in ('789y')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2	
	

-- JUN [billing 23,632,630 diff: 0, void/reject/refund: 451,994]
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 4100300 as LCSid, b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'Normal' as ticketType
FROM dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.customer_0705 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Jun 2012' and '30 Jun 2012'
	and c.site in ('789y')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2		
	

-- JUL [billing 16,245,631, diff: 0, void/reject/refund: 379,840] 	
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 4100300 as LCSid, b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'Normal' as ticketType
FROM dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.customer_0802 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Jul 2012' and '31 Jul 2012'
	and c.site in ('789y')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2		
	
-- AUG [billing: 25,822,696, diff: 0, void/reject/refund: 549,850] 	
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 4100300 as LCSid, b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'Normal' as ticketType
FROM dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.customer_0906 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Aug 2012' and '31 Aug 2012'
	and c.site in ('789y')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2		

-- SEP [25,989,948, diff: 0, void/reject/refund: 528,711] 	
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 4100300 as LCSid, b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'Normal' as ticketType
FROM dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.customer_1013 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 SEP 2012' and '30 Sep 2012'
	and c.site in ('789y')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2		
	
-- OCT [billing: 27,144,648 diff: 0, void/reject/refund: 572,951]
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 4100300 as LCSid, b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'Normal' as ticketType
FROM dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.customer_1108 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 OCT 2012' and '31 OCT 2012'
	and c.site in ('789y')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2	

GO	

-- NOV [billing: 24,715,338 diff: 0, void/reject/refund: 443,214] 	
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 4100300 as LCSid, b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'Normal' as ticketType
FROM dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.customer_1227 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 NOV 2012' and '30 NOV 2012'
	and c.site in ('789y')
	and c.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2	

GO	

-- DEC [billing: 20130173 diff: 0, void/reject/refund: 401,185] 	
INSERT INTO DWDB.dbo.bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 4100300 as LCSid, b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'Normal' as ticketType
FROM dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join bodb_staging.dbo.customer_viet c with(nolock) on b.recommend = c.custid
where winlostdate between '1 DEC 2012' and '31 DEC 2012'
	and c.site in ('789y')
	and b.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)

GO	

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- test

-- JAN & FEB
INSERT INTO DWDB.dbo.bettrans_test(
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, isBA
)
SELECT 
	NULL as recommid, 4100300 as LCSid, --789y
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 0 as isBA
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join customer.dbo.customer_0407 c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Jan 2012' and '29 Feb 2012'
	and c.site in ('789y')
	and statusID in (101,102,103,111,112,113) -- won/lose/draw/void/reject/refund
	and (bettype < 31 OR bettype between 121 and 999)
	and c.roleid = 2
	
-- FROM Mar.2012 onwards, just need to put UUS tickets into 'test' table, but as checked, there is no UUS tickets for PIH. then no script is required. 
	