ALTER PROCEDURE [dbo].[Task_RMS_SyncDataForBettransParlay]	
AS
/*   
 Task : arrange bettransParlay data
 DB: DBRMS/bodb_RMS 
 Revisions:   
  - 20121001@viet: create SP   
  - 20130125@Johnson: move sp from DB054.bodb02 to DBRMS.bodb_RMS and use rmSettings to store setting
  - 20140121@Johnson: add system parlay into rmTransaction
  - 20140417@Johnson: add column combo into rmBettrans to store number of selections 
*/  
SET NOCOUNT ON
SET DEADLOCK_PRIORITY LOW	

declare @tstamp_min binary(8), @tstamp_max binary(8)

SELECT @tstamp_min = CAST(CAST(ISNULL(VValue, 0) as bigint)+1 as binary(8))
FROM dbo.rmSettings with (rowlock)
WHERE VName = 'rmBettransSync'	

SELECT @tstamp_max = isnull(max(tstamp),@tstamp_min)  from bodb02.dbo.bettrans with(nolock)

IF @tstamp_min = 0x0000000000000001 -- 1: renew all data
BEGIN
	TRUNCATE TABLE dbo.rmBettrans
	
	INSERT INTO dbo.rmBettrans (transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, 
		apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, 
		liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
		recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, 
		scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, 
		SecAcceptFlag, transid2, combo
	)
	SELECT transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, 
			apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, 
			liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, 
			scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, 
			SecAcceptFlag, transid2, CASE when matchid = 9 then RIGHT(betcheck,LEN(betcheck)-1) else LEN(betteam) end
	FROM bodb02.dbo.bettrans with (NOLOCK)
	WHERE matchid in (9,29)	
END
ELSE 
BEGIN
	SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, 
			apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, 
			liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, 
			scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, 
			SecAcceptFlag, transid2, CASE when matchid = 9 then RIGHT(betcheck,LEN(betcheck)-1) else LEN(betteam) end as combo
	INTO #temp			
	FROM bodb02.dbo.bettrans with (NOLOCK)
	WHERE tstamp between @tstamp_min and @tstamp_max
		and matchid in (9,29)
		
	MERGE dbo.rmBettrans as d
		USING #temp s on d.transid = s.transid	
		WHEN MATCHED THEN 
			UPDATE SET 
				custid = s.custid
				,transdate = s.transdate
				,oddsid = s.oddsid
				,hdp1 = s.hdp1
				,hdp2 = s.hdp2
				,odds = s.odds
				,stake = s.stake
				,status = s.status
				,winlost = s.winlost
				,awinlost = s.awinlost
				,mwinlost = s.mwinlost
				,playercomm = s.playercomm
				,comm = s.comm
				,acomm = s.acomm
				,apositiontaking = s.apositiontaking
				,mpositiontaking = s.mpositiontaking
				,tpositiontaking = s.tpositiontaking
				,playerdiscount = s.playerdiscount
				,discount = s.discount
				,adiscount = s.adiscount
				,livehomescore = s.livehomescore
				,liveawayscore = s.liveawayscore
				,liveindicator = s.liveindicator
				,betteam = s.betteam
				,creator = s.creator
				,refno = s.refno
				,comstatus = s.comstatus
				,winlostdate = s.winlostdate
				,betfrom = s.betfrom
				,betcheck = s.betcheck
				,checktime = s.checktime
				,oddsspread = s.oddsspread
				,actualrate = s.actualrate
				,matchid = s.matchid
				,recommend = s.recommend
				,mrecommend = s.mrecommend
				,ruben = s.ruben
				,betid = s.betid
				,statuswinlost = s.statuswinlost
				,modds = s.modds
				,bettype = s.bettype
				,betdaqid = s.betdaqid
				,actual_stake = s.actual_stake
				,currency = s.currency
				,ip = s.ip
				,transdesc = s.transdesc
				,sdiscount = s.sdiscount
				,scomm = s.scomm
				,spositiontaking = s.spositiontaking
				,swinlost = s.swinlost
				,srecommend = s.srecommend
				,Username = s.Username
				,CurrencyName = s.CurrencyName
				,virtualrate = s.virtualrate
				,oddstype = s.oddstype
				,statusID = s.statusID
				,currency2 = s.currency2
				,balance = s.balance
				,SecAcceptFlag = s.SecAcceptFlag
				,transid2 = s.transid2
				,combo = s.combo
		WHEN NOT MATCHED THEN 
		INSERT (transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, 
			apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, 
			liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, 
			scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, 
			SecAcceptFlag, transid2, combo
			)
		VALUES (
			transid, s.custid, s.transdate, s.oddsid, s.hdp1, s.hdp2, s.odds, s.stake, s.status, s.winlost, s.awinlost, s.mwinlost, s.playercomm, 
			s.comm, s.acomm, s.apositiontaking, s.mpositiontaking, s.tpositiontaking, s.playerdiscount, s.discount, s.adiscount, s.livehomescore, 
			s.liveawayscore, s.liveindicator, s.betteam, s.creator, s.refno, s.comstatus, s.winlostdate, s.betfrom, s.betcheck, s.checktime, 
			s.oddsspread, s.actualrate, s.matchid, s.recommend, s.mrecommend, s.ruben, s.betid, s.statuswinlost, s.modds, s.bettype, s.betdaqid, 
			s.actual_stake, s.currency, s.ip, s.transdesc, s.sdiscount, s.scomm, s.spositiontaking, s.swinlost, s.srecommend, s.Username, 
			s.CurrencyName, s.virtualrate, s.oddstype, s.statusID, s.currency2, s.balance, s.SecAcceptFlag, s.transid2, s.combo
			)
	;--end MERGE
	
	MERGE	dbo.rmTransaction as dt
	USING	#temp s on dt.transid = s.transid	
	WHEN NOT MATCHED THEN 
		INSERT(transid, refno, custid, combo)
		VALUES(s.transid,s.refno,s.custid,s.combo)
	; -- END OF MERGE rmTransaction
	
END

UPDATE dbo.rmSettings with(rowlock, updlock)
SET VValue = CAST(CAST(@tstamp_max as bigint) as varchar(200))
WHERE VName = 'rmBettransSync'	

SET NOCOUNT OFF

