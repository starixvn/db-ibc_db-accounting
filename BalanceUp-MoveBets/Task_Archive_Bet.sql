set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

/****** Object:  Stored Procedure dbo.Task_Archive_Bet    Script Date: 5/23/2011 6:34:19 PM ******/
ALTER PROCEDURE [dbo].[Task_Archive_Bet]
	@winlostdate datetime
AS
/*
Created: 
Task : 
Process will archive 3 tables
 - bettrans14
 - bettransm14
 - sum_winloss
DB: DB06.bodb02
Original:

Revisions:
	- 20100428@Henry: insert data to column statusID of bodb_archive.dbo.bettrans_BK & bodb_archive.dbo.bettransm
	- 20101228@Henry: change bettype to new range
	- 20110715@Vivi(DB06): Add moving for data from bettrans14.balance
	- 20120209@Sophia: Add table bettransg for Live Casino
	
Param's Explanation: 

*/	



DECLARE @bet TABLE (bettype int)
INSERT INTO @bet
	SELECT distinct bettype
	FROM dbo.bettrans14 with (nolock)
	WHERE winlostdate = @winlostdate

DECLARE bettypeCursor CURSOR
READ_ONLY
FOR select bettype from @bet

DECLARE @bettype int
OPEN bettypeCursor

FETCH NEXT FROM bettypeCursor INTO @bettype
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN

	INSERT INTO bodb_archive.dbo.bettrans_BK (
		transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, [status],statusID,
		winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking,
		playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam,
		creator, refno,  winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate,
		matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, tstamp,
		actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, oddstype, balance
	)
	SELECT transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, [status],statusID,
		winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking,
		playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam,
		creator, refno,  winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate,
		matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, tstamp,
		actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, oddstype, balance
	FROM dbo.bettrans14 with (nolock)
	WHERE winlostdate = @winlostdate AND bettype = @bettype

	END

	FETCH NEXT FROM bettypeCursor INTO @bettype
END

CLOSE bettypeCursor
DEALLOCATE bettypeCursor

--- ==============================================================

	INSERT INTO bodb_Summary.dbo.sum_winloss_old
		(  winlostdate, username, custid, roleid, recommend, mrecommend, srecommend, turnover, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, betcount, grosscomm, sporttype, bettype  )
	SELECT winlostdate, username, custid, roleid, recommend, mrecommend, srecommend, turnover, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, betcount, grosscomm, sporttype, bettype
		FROM sum_winloss WHERE winlostdate = @winlostdate

--- ==============================================================

	INSERT INTO bodb_archive.dbo.bettransm (
transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, statusID,
winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, 
comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, 
apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, 
matchid, matchdate, finalodds, isfinish, statuswinlost, ruben, bettype,
spositiontaking, swinlost, sdiscount, scomm
)
	SELECT transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, statusID,
	winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, 
		comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, 
		apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
		playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, 
		matchid, matchdate, finalodds, isfinish, statuswinlost, ruben, bettype,
		spositiontaking, swinlost, sdiscount, scomm
		FROM bettransm14 WHERE winlostdate = @winlostdate
--refno in (select refno FROM bettrans14 (nolock) WHERE winlostdate = @winlostdate AND matchid = 0 AND bettype = 9)

------ ==============================================================
	INSERT INTO bodb_archive.dbo.bettransg (
transid, custid, transdate, oddsid, odds, stake, status, statusID,
winlost, betteam, creator, refno, 
comstatus, winlostdate, betfrom, checktime, 
apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, 
matchid, matchdate, statuswinlost, ruben, bettype,
spositiontaking, swinlost, sdiscount, scomm
)
	SELECT transid, custid, transdate, oddsid, odds, stake, status, statusID,
	winlost, betteam, creator, refno, 
		comstatus, winlostdate, betfrom, checktime,  
		apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
		playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, 
		matchid, matchdate, statuswinlost, ruben, bettype,
		spositiontaking, swinlost, sdiscount, scomm
		FROM bettransg14 WHERE winlostdate = @winlostdate



GO
GRANT VIEW DEFINITION ON [dbo].[Task_Archive_Bet] TO [vnteam]

