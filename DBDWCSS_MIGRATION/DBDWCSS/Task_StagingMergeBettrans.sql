USE [bodb_staging]
GO
/****** Object:  StoredProcedure [dbo].[TASK_StagingMergeBettrans]    Script Date: 10/18/2012 00:23:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[TASK_StagingMergeBettrans]	
AS
/*   
 Task: merge bettrans_staging into TPDB.bettrans
 DB: DBDWCSS.bodb_staging
 Revisions:   
  - 20121001@viet: create SP   
*/  
SET NOCOUNT ON	
	MERGE TPDB.dbo.bettrans as d
		USING dbo.bettrans_staging s with(nolock) ON d.recommid = s.recommid
		WHEN MATCHED THEN 
			UPDATE SET 
				[LCSid] = s.[LCSid]
				,[transid] = s.[transid]
				,[custid] = s.[custid]
				,[transdate] = s.[transdate]
				,[oddsid] = s.[oddsid]
				,[hdp1] = s.[hdp1]
				,[hdp2] = s.[hdp2]
				,[odds] = s.[odds]
				,[stake] = s.[stake]
				,[status] = s.[status]
				,[winlost] = s.[winlost]
				,[awinlost] = s.[awinlost]
				,[mwinlost] = s.[mwinlost]
				,[playercomm] = s.[playercomm]
				,[comm] = s.[comm]
				,[acomm] = s.[acomm]
				,[apositiontaking] = s.[apositiontaking]
				,[mpositiontaking] = s.[mpositiontaking]
				,[tpositiontaking] = s.[tpositiontaking]
				,[playerdiscount] = s.[playerdiscount]
				,[discount] = s.[discount]
				,[adiscount] = s.[adiscount]
				,[livehomescore] = s.[livehomescore]
				,[liveawayscore] = s.[liveawayscore]
				,[liveindicator] = s.[liveindicator]
				,[betteam] = s.[betteam]
				,[creator] = s.[creator]
				,[refno] = s.[refno]
				,[comstatus] = s.[comstatus]
				,[winlostdate] = s.[winlostdate]
				,[betfrom] = s.[betfrom]
				,[betcheck] = s.[betcheck]
				,[checktime] = s.[checktime]
				,[oddsspread] = s.[oddsspread]
				,[actualrate] = s.[actualrate]
				,[matchid] = s.[matchid]
				,[recommend] = s.[recommend]
				,[mrecommend] = s.[mrecommend]
				,[ruben] = s.[ruben]
				,[betid] = s.[betid]
				,[statuswinlost] = s.[statuswinlost]
				,[modds] = s.[modds]
				,[bettype] = s.[bettype]
				,[betdaqid] = s.[betdaqid]
				,[actual_stake] = s.[actual_stake]
				,[currency] = s.[currency]
				,[ip] = s.[ip]
				,[transdesc] = s.[transdesc]
				,[sdiscount] = s.[sdiscount]
				,[scomm] = s.[scomm]
				,[spositiontaking] = s.[spositiontaking]
				,[swinlost] = s.[swinlost]
				,[srecommend] = s.[srecommend]
				,[Username] = s.[Username]
				,[CurrencyName] = s.[CurrencyName]
				,[virtualrate] = s.[virtualrate]
				,[oddstype] = s.[oddstype]
				,[statusID] = s.[statusID]
				,[currency2] = s.[currency2]
				,[balance] = s.[balance]
				,[SecAcceptFlag] = s.[SecAcceptFlag]
				,[dangerous] = s.[dangerous]
				,[recommdate] = s.[recommdate]
		WHEN NOT MATCHED THEN 
		INSERT (recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, 
			comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, 
			liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, 
			recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, 
			scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, 
			SecAcceptFlag, dangerous, recommdate
			)
		VALUES (s.recommid, s.LCSid, s.transid, s.custid, s.transdate, s.oddsid, s.hdp1, s.hdp2, s.odds, s.stake, s.status, s.winlost, s.awinlost, 
			s.mwinlost, s.playercomm, s.comm, s.acomm, s.apositiontaking, s.mpositiontaking, s.tpositiontaking, s.playerdiscount, s.discount, 
			s.adiscount, s.livehomescore, s.liveawayscore, s.liveindicator, s.betteam, s.creator, s.refno, s.comstatus, s.winlostdate, s.betfrom, 
			s.betcheck, s.checktime, s.oddsspread, s.actualrate, s.matchid, s.recommend, s.mrecommend, s.ruben, s.betid, s.statuswinlost, s.modds, 
			s.bettype, s.betdaqid, s.actual_stake, s.currency, s.ip, s.transdesc, s.sdiscount, s.scomm, s.spositiontaking, s.swinlost, s.srecommend, 
			s.Username, s.CurrencyName, s.virtualrate, s.oddstype, s.statusID, s.currency2, s.balance, s.SecAcceptFlag, s.dangerous, s.recommdate
			)
	;--end MERGE
	
	IF @@ERROR = 0 EXEC dbo.StagingConfirmCompleted @tablename = 'bettrans'
SET NOCOUNT OFF

