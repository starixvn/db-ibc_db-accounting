CREATE PROCEDURE [dbo].[Task_GetTickets]
AS

declare @bettrans_maxid bigint, @bettransM_maxid bigint

--bettrans
select @bettrans_maxid = max(transid) from bodb_review.dbo.bettrans with(nolock)

insert into bodb_review.dbo.bettrans (transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, 
	mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, 
	winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, 
	betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, 
	virtualrate, oddstype, statusID, currency2, balance
) 
SELECT transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, 
	mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, 
	winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, 
	betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, 
	virtualrate, oddstype, statusID, currency2, balance
FROM bettrans with(rowlock) where transid > @bettrans_maxid 	
	and (bettype<31 OR bettype between 81 and 19000)
	and matchid > 0

-- bettransM
select @bettransM_maxid = max(transid) from bodb_review.dbo.bettransM with(nolock)
INSERT INTO bodb_review.dbo.bettransM (transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, 
	refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
	playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, finalodds, isfinish, statuswinlost, ruben, bettype, 
	spositiontaking, swinlost, sdiscount, scomm, statusID
)
SELECT transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, 
	refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
	playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, finalodds, isfinish, statuswinlost, ruben, bettype, 
	spositiontaking, swinlost, sdiscount, scomm, statusID
FROM bettransM with(nolock) where transid > @bettransM_maxid