/*
	From Justin's email: 
	the 'official' start date for Boping will be 1st June, 
	so the ONEworks admin should show Boping transactions only from 1st June onwards
*/
-- BA
INSERT INTO bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 
	CASE c.site
		WHEN 'Tycoon' THEN 4201200
		WHEN 'Macaubet' THEN 4201800
		WHEN 'ibobet' THEN 4201900
		WHEN 'Aoncash' THEN 4202100
		WHEN 'Bwinning' THEN 4202200
		WHEN 'ITCBet' THEN 4202400
		WHEN 'Livebet365' THEN 4202500
		WHEN 'SG8' THEN 4201500
	END as LCSid, -- Haifa
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 'BA' as ticketType
FROM bodb_Archive12.dbo.bettrans_2012 b with(nolock, index=IX_report)
	inner join bodb_staging.dbo.customer_viet c with(nolock) on b.recommend = c.custid
where winlostdate between '1 Jun 2012' and '31 dec 2012'
	and c.site in ('SG8',
		'Aoncash','Bwinning','Ibobet','ITCBet','Livebet365','Macaubet','Tycoon')
	and statusID in (111,112,113,101,102,103) -- won/lose/draw/void/reject/refund
	and b.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and transid in (select transid from dbo.LicenseeBATransaction_bk with(nolock))
	
-- Normal
INSERT INTO bettrans_dw (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 
	CASE c.site
		WHEN 'Tycoon' THEN 4201200
		WHEN 'Macaubet' THEN 4201800
		WHEN 'ibobet' THEN 4201900
		WHEN 'Aoncash' THEN 4202100
		WHEN 'Bwinning' THEN 4202200
		WHEN 'ITCBet' THEN 4202400
		WHEN 'Livebet365' THEN 4202500
		WHEN 'SG8' THEN 4201500
	END as LCSid,
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
where winlostdate between '1 Jun 2012' and '31 dec 2012'
	and c.site in ('SG8','Aoncash','Bwinning','Ibobet','ITCBet','Livebet365','Macaubet','Tycoon')
	and statusID in (111,112,113,101,102,103) -- won/lose/draw/void/reject/refund
	and b.currency <> 20
	and (bettype < 31 OR bettype between 121 and 999)
	and transid not in (select transid from dbo.LicenseeBATransaction_bk with(nolock))	
	
	
--- TEST

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
		WHEN 'Tycoon' THEN 4201200
		WHEN 'Macaubet' THEN 4201800
		WHEN 'ibobet' THEN 4201900
		WHEN 'Aoncash' THEN 4202100
		WHEN 'Bwinning' THEN 4202200
		WHEN 'ITCBet' THEN 4202400
		WHEN 'Livebet365' THEN 4202500
		WHEN 'SG8' THEN 4201500
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
where winlostdate between '1 Jun 2012' and '31 dec 2012'
	and c.site in ('SG8','Aoncash','Bwinning','Ibobet','ITCBet','Livebet365','Macaubet','Tycoon')
	and statusID in (111,112,113,101,102,103) -- won/lose/draw/void/reject/refund
	and b.currency = 20
	and (bettype < 31 OR bettype between 121 and 999)