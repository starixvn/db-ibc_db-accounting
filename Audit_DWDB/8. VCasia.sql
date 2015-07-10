INSERT INTO DWDB.dbo.bettrans_wl (
	recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, 
	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, 
	livehomescore, liveawayscore, liveindicator, betteam, creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
	recommend, mrecommend, srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID, 
	currency2, bettype, balance, transid2, SecAcceptFlag, recommdate, ticketType
)
SELECT NULL as recommid, 
	4202000 as LCSid, --vcasia
	b.transid, b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 
	b.actual_stake, b.status, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, 
	b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, 
	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator, 
	b.betteam, b.creator, b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.oddsspread, 
	b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend, b.ruben, b.betid, b.statuswinlost, 
	b.modds, b.betdaqid, b.tstamp, b.currency, b.ip, b.transdesc, b.virtualrate, b.oddstype, b.statusID, 
	b.currency2, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.recommdate, 
	'Normal' as ticketType
from bodb_Archive12.dbo.bettrans_2012 b with(nolock)
	inner join bodb_staging.dbo.customer_viet c with(nolock) on c.custid = b.recommend	
where c.site = 'vcasia'
	and b.currency = 13
	and winlostdate between '1 aug 2012' and '31 dec 2012'
	and (bettype < 31 or bettype between 121 and 999)
	
-- update BA
update b
	set tickettype = 'BA'
from bettrans_WL b
	inner join dbo.LicenseeBATransaction_bk ba with(nolock) on b.transid = ba.transid
	
----- check data
select month(winlostdate), SUM(winlost-actual_stake)*0.15,
	sum(-(winlost-actual_stake)*0.15/ 
		case month(winlostdate) 
			when 10 then 8.13007
			when 11 then 8.13668
			when 12 then 8.32639
		else 8.12346 end
	)
from bettrans_wl with(nolock)
where winlostdate between '1 aug 2012' and '31 dec 2012'
	and currency = 13
	and tickettype = 'normal'
	and (bettype < 31 or bettype between 121 and 999)
group by MONTH(winlostdate)
order by 1
------ /check data
	

----------------------------------------------
-----------------------------------------------
-- IMPORT TO REPORT --


INSERT INTO DWDB_2012.dbo.ReportWL_12M08 (
	transid, LCSid, custid, transdate, status, winlostdate, isBA, isInternal, 
	matchid, actual_stake, winlost, LicenseeComm, sporttype, currency, PositionTaking
)
SELECT b.transid, b.LCSid, b.custid, b.transdate, b.status, b.winlostdate, 
	case tickettype when 'ba' then 1 else 0 end, --isBA	
	case tickettype when 'internal' then 1 else 0 end, --isInternal, 
	matchid, actual_stake, winlost, 
	comm, --LicenseeComm
	'Sportsbook', -- sporttype
	e.code, --currency
	0 PositionTaking
FROM dbo.bettrans_WL b with(nolock)
	inner join exchange e with(nolock) on b.currency = e.exchangeid
WHERE winlostdate between '1 aug 2012' and '31 aug 2012'
	and (bettype < 31 or bettype between 121 and 999)


INSERT INTO DWDB_2012.dbo.ReportWL_12M09 (
	transid, LCSid, custid, transdate, status, winlostdate, isBA, isInternal, 
	matchid, actual_stake, winlost, LicenseeComm, sporttype, currency, PositionTaking
)
SELECT b.transid, b.LCSid, b.custid, b.transdate, b.status, b.winlostdate, 
	case tickettype when 'ba' then 1 else 0 end, --isBA	
	case tickettype when 'internal' then 1 else 0 end, --isInternal, 
	matchid, actual_stake, winlost, 
	comm, --LicenseeComm
	'Sportsbook', -- sporttype
	e.code, --currency
	0 PositionTaking
FROM dbo.bettrans_WL b with(nolock)
	inner join exchange e with(nolock) on b.currency = e.exchangeid
WHERE winlostdate between '1 sep 2012' and '30 sep 2012'
	and (bettype < 31 or bettype between 121 and 999)

INSERT INTO DWDB_2012.dbo.ReportWL_12M10 (
	transid, LCSid, custid, transdate, status, winlostdate, isBA, isInternal, 
	matchid, actual_stake, winlost, LicenseeComm, sporttype, currency, PositionTaking
)
SELECT b.transid, b.LCSid, b.custid, b.transdate, b.status, b.winlostdate, 
	case tickettype when 'ba' then 1 else 0 end, --isBA	
	case tickettype when 'internal' then 1 else 0 end, --isInternal, 
	matchid, actual_stake, winlost, 
	comm, --LicenseeComm
	'Sportsbook', -- sporttype
	e.code, --currency
	0 PositionTaking
FROM dbo.bettrans_WL b with(nolock)
	inner join exchange e with(nolock) on b.currency = e.exchangeid
WHERE winlostdate between '1 oct 2012' and '31 oct 2012'
	and (bettype < 31 or bettype between 121 and 999)

INSERT INTO DWDB_2012.dbo.ReportWL_12M11 (
	transid, LCSid, custid, transdate, status, winlostdate, isBA, isInternal, 
	matchid, actual_stake, winlost, LicenseeComm, sporttype, currency, PositionTaking
)
SELECT b.transid, b.LCSid, b.custid, b.transdate, b.status, b.winlostdate, 
	case tickettype when 'ba' then 1 else 0 end, --isBA	
	case tickettype when 'internal' then 1 else 0 end, --isInternal, 
	matchid, actual_stake, winlost, 
	comm, --LicenseeComm
	'Sportsbook', -- sporttype
	e.code, --currency
	0 PositionTaking
FROM dbo.bettrans_WL b with(nolock)
	inner join exchange e with(nolock) on b.currency = e.exchangeid
WHERE winlostdate between '1 nov 2012' and '30 nov 2012'
	and (bettype < 31 or bettype between 121 and 999)


INSERT INTO DWDB_2012.dbo.ReportWL_12M12 (
	transid, LCSid, custid, transdate, status, winlostdate, isBA, isInternal, 
	matchid, actual_stake, winlost, LicenseeComm, sporttype, currency, PositionTaking
)
SELECT b.transid, b.LCSid, b.custid, b.transdate, b.status, b.winlostdate, 
	case tickettype when 'ba' then 1 else 0 end, --isBA	
	case tickettype when 'internal' then 1 else 0 end, --isInternal, 
	matchid, actual_stake, winlost, 
	comm, --LicenseeComm
	'Sportsbook', -- sporttype
	e.code, --currency
	0 PositionTaking
FROM dbo.bettrans_WL b with(nolock)
	inner join exchange e with(nolock) on b.currency = e.exchangeid
WHERE winlostdate between '1 dec 2012' and '31 dec 2012'
	and (bettype < 31 or bettype between 121 and 999)