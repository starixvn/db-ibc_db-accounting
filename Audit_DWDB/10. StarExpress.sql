--FDL: start from: 17 DEC 2012
INSERT INTO DWDB.dbo.bettrans_wl (
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
	'Normal' as ticketType
from bodb_Archive12.dbo.bettrans_2012 b with(nolock)
	inner join bodb_staging.dbo.customer_viet c with(nolock) on c.custid = b.recommend	
where c.site in ('BEST-ODDS','XYZBET','611111','222227','spotico','KORIBC','INDO','722222','733333','755555','222223','222225')
	and b.currency <> 20
	and winlostdate >= '17 DEC 2012'
	and bettype BETWEEN 1101 AND 1199 -- Live Casino
	and statusID in (101,102,103,111,112,113) -- void/reject/refund/won/lose/draw
	
----------------------------------
-------------------------------------------------------------------
--------------------------------------------------------------------
----- IMPORT DATA --------------------------------------------------
--------------------------------------------------------------------
DECLARE @date smalldatetime, @maxdate smalldatetime

SET @date = '1 DEC 2012'
SELECT @maxdate = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@date)+1,0))

INSERT INTO DWDB_2012.dbo.ReportWL_12M12 (
	transid, LCSid, custid, transdate, status, winlostdate, isBA, isInternal, 
	matchid, actual_stake, winlost, LicenseeComm, SportType, currency, PositionTaking
)
SELECT b.transid, b.LCSid, b.custid, b.transdate, b.status, b.winlostdate, 
	case tickettype when 'ba' then 1 else 0 end, --isBA	
	case tickettype when 'internal' then 1 else 0 end, --isInternal, 
	matchid, actual_stake, winlost, 
	comm, --LicenseeComm
	'LiveCasino', -- sporttype
	e.code, --currency
	tpositiontaking -- positiontaking
FROM dbo.bettrans_WL b with(nolock)
	inner join exchange e with(nolock) on b.currency = e.exchangeid
WHERE winlostdate between @date and @maxdate
	and bettype BETWEEN 1101 AND 1199 -- Live Casino
	
----------------------------------
---------------------------------
--- check data -----------------

SELECT YEAR, MONTH, Licensee, 
 SUM(GrossWIN) GrossWIN,
 CASE WHEN SUM(GrossWIN) > 0 THEN SUM(GrossWIN*DistributorCharge) ELSE 0 END DistributorRevenue,
 CASE WHEN SUM(GrossWIN) > 0 THEN SUM(GrossWIN*PartnerCharge) ELSE 0 END PartnerRevenue,
 CASE WHEN SUM(GrossWIN) > 0 THEN SUM(GrossWIN*PartnerCharge*OneworksCharge) ELSE 0 END ONEworksRevenue
FROM ( 
 select YEAR,
  MONTH,   
  Licensee,
  positiontaking, 
  DistributorCharge, 
  PartnerCharge,
  OneworksCharge,   
  -SUM((winlost-actual_stake)*rate) as GrossWIN
 from dbo.ReportWL_12M12 r with(nolock)
  INNER JOIN dbo.ProductSettings p with(nolock) on r.LCSid = p.LCSid and r.Sporttype = p.Sporttype
  INNER JOIN dbo.Exchange e with(nolock) on r.Currency = e.Currency and YEAR(winlostdate) = e.year and MONTH(winlostdate) = e.month
  INNER JOIN dbo.site s with(nolock) on r.LCSid = s.LCSid
 where r.sporttype = 'LiveCasino'
  and status in ('WON','LOSE','DRAW')
  and ChargeType = 1 -- charge base on grosswin
 group by YEAR, month, Licensee, positiontaking, DistributorCharge, PartnerCharge, OneworksCharge
) D
GROUP BY YEAR, MONTH, Licensee
UNION ALL
SELECT YEAR, MONTH, Licensee, 
 SUM(GrossWIN) GrossWIN,
 CASE WHEN SUM(GrossWIN) > 0 THEN SUM(GrossWIN*(1-positiontaking)) ELSE 0 END DistributorRevenue,
 CASE WHEN SUM(GrossWIN) > 0 THEN SUM(GrossWIN*(1-positiontaking)*PartnerCharge) ELSE 0 END PartnerRevenue,
 CASE WHEN SUM(GrossWIN) > 0 THEN SUM(GrossWIN*(1-positiontaking)*PartnerCharge*OneworksCharge) ELSE 0 END ONEworksRevenue 
FROM ( 
 select YEAR,
  MONTH,   
  Licensee,
  positiontaking, 
  DistributorCharge, 
  PartnerCharge,
  OneworksCharge,   
  -SUM((winlost-actual_stake)*rate) as GrossWIN
 from dbo.ReportWL_12M12 r with(nolock)
  INNER JOIN dbo.ProductSettings p with(nolock) on r.LCSid = p.LCSid and r.Sporttype = p.Sporttype
  INNER JOIN dbo.Exchange e with(nolock) on r.Currency = e.Currency and YEAR(winlostdate) = e.year and MONTH(winlostdate) = e.month
  INNER JOIN dbo.site s with(nolock) on r.LCSid = s.LCSid
 where r.sporttype = 'LiveCasino'
  and status in ('WON','LOSE','DRAW')  
  and ChargeType = 2 -- charge base on revenue
 group by YEAR, month, Licensee, positiontaking, DistributorCharge, PartnerCharge, OneworksCharge
) D
GROUP BY YEAR, MONTH, Licensee
ORDER BY 2,3