set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[ExecRep_08] @recommend int,
	@winlostdate smalldatetime,
	@parlay bit = 0
AS
/*
Created by:[]
Date:
Task: 
DB: DB02.BODB02
Revisions:
    - 20110523@Henry: change bettype to new range
    - 20120209@Sophia: Add table bettransg14 for Live Casino
 */
IF @@SERVERNAME not in ('DB04', 'DB042', 'DB043')
BEGIN

	insert into bettrans14 
		(
		transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, 
		playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, 
		discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, 
		winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, 
		ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, 
		sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, Username, CurrencyName, 
		oddstype, statusID, currency2, balance, SecAcceptFlag, transid2
		)
	select 
		transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, 
		playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, 
		discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, 
		winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, 
		ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, 
		sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, Username, CurrencyName, 
		oddstype, statusID, currency2, balance, SecAcceptFlag, transid2
	from bettrans (nolock)
	where recommend = @recommend AND winlostdate=@winlostdate
		and bettype <= 19000
		
END
IF @@SERVERNAME = 'DB04'
BEGIN
	insert into bettrans14 
		(
		transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, 
		playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, 
		discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, 
		winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, 
		ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, 
		sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, Username, CurrencyName, 
		oddstype, statusID, currency2, balance, SecAcceptFlag, transid2
		)
	select 
		transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, 
		playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, 
		discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, 
		winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, 
		ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, 
		sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, Username, CurrencyName, 
		oddstype, statusID, currency2, balance, SecAcceptFlag, transid2
	from bettrans (nolock)
	where recommend = @recommend AND winlostdate=@winlostdate
		and bettype IN (9, 29)
END



IF @@SERVERNAME not in ('DB042', 'DB043')
BEGIN

	IF @parlay = 1
	BEGIN
		--set true for the flag isMovingBet on DB06.bodb02.dbo.SystemSettings
		--to prevent the Mix Parlay calculation while this process is running
		IF @@SERVERNAME = 'DB06'
		BEGIN
			if exists (select * from dbo.sysobjects where name = 'SystemSettings')
			BEGIN
				UPDATE SystemSettings set VValue = 1 where VName = 'isMovingBet'
			END
		END

		insert into bettransm14
			(
			transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, [status], winlost, livehomescore, 
			liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, 
			checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
			playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, 
			finalodds, isfinish, statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, 
			statusID
			)
		select
			transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, [status], winlost, livehomescore, 
			liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, 
			checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
			playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, 
			finalodds, isfinish, statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, 
			statusID
		from bettransm b (nolock)
			--INNER JOIN custinfo c (nolock) ON b.custid = c.custid
		where --recommend = @recommend AND 
			winlostdate=@winlostdate
			
		----insert bettransg14
		insert into bettransg14
			(
			transid, custid, transdate, oddsid, odds, stake, [status], winlost, 
			betteam, creator, refno, comstatus, winlostdate, betfrom, 
			checktime, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
			playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, 
			statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, 
			statusID
			)
		select
			transid, custid, transdate, oddsid, odds, stake, [status], winlost,  
			betteam, creator, refno, comstatus, winlostdate, betfrom,  
			checktime, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
			playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, 
			statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, 
			statusID
		from bettransg b (nolock)			
		where winlostdate=@winlostdate	
			
	END
	
END
GO
GRANT VIEW DEFINITION ON [dbo].[ExecRep_08] TO [vnteam]


