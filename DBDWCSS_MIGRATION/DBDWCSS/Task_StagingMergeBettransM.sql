ALTER PROCEDURE [dbo].[Task_StagingMergeBettransM]	
AS
/*   
 Task: merge bettransM_staging into TPDB.bettransM
 DB: DBDWCSS.bodb_staging
 Revisions:   
  - 20121001@viet: create SP   
*/  
SET NOCOUNT ON	
	SET IDENTITY_INSERT TPDB.dbo.bettransM ON
	MERGE TPDB.dbo.bettransM as d
		USING dbo.bettransM_staging s with(nolock) ON d.transid = s.transid
		WHEN MATCHED THEN 
			UPDATE SET 
				[custid] = s.[custid]
				,[transdate] = s.[transdate]
				,[oddsid] = s.[oddsid]
				,[hdp1] = s.[hdp1]
				,[hdp2] = s.[hdp2]
				,[odds] = s.[odds]
				,[stake] = s.[stake]
				,[status] = s.[status]
				,[winlost] = s.[winlost]
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
				,[apositiontaking] = s.[apositiontaking]
				,[mpositiontaking] = s.[mpositiontaking]
				,[tpositiontaking] = s.[tpositiontaking]
				,[awinlost] = s.[awinlost]
				,[mwinlost] = s.[mwinlost]
				,[playerdiscount] = s.[playerdiscount]
				,[discount] = s.[discount]
				,[adiscount] = s.[adiscount]
				,[playercomm] = s.[playercomm]
				,[comm] = s.[comm]
				,[acomm] = s.[acomm]
				,[actualrate] = s.[actualrate]
				,[matchid] = s.[matchid]
				,[matchdate] = s.[matchdate]
				,[finalodds] = s.[finalodds]
				,[isfinish] = s.[isfinish]
				,[statuswinlost] = s.[statuswinlost]
				,[ruben] = s.[ruben]
				,[bettype] = s.[bettype]
				,[spositiontaking] = s.[spositiontaking]
				,[swinlost] = s.[swinlost]
				,[sdiscount] = s.[sdiscount]
				,[scomm] = s.[scomm]
				,[statusID] = s.[statusID]
				,[recommid] = s.[recommid]
				,[recommdate] = s.[recommdate]
		WHEN NOT MATCHED THEN 
		INSERT (transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, 
			creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, 
			awinlost, mwinlost, playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, finalodds, isfinish, 
			statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, statusID, recommid, recommdate
		)
		VALUES (s.transid, s.custid, s.transdate, s.oddsid, s.hdp1, s.hdp2, s.odds, s.stake, s.status, s.winlost, s.livehomescore, s.liveawayscore, 
			s.liveindicator, s.betteam, s.creator, s.refno, s.comstatus, s.winlostdate, s.betfrom, s.betcheck, s.checktime, s.oddsspread, 
			s.apositiontaking, s.mpositiontaking, s.tpositiontaking, s.awinlost, s.mwinlost, s.playerdiscount, s.discount, s.adiscount, 
			s.playercomm, s.comm, s.acomm, s.actualrate, s.matchid, s.matchdate, s.finalodds, s.isfinish, s.statuswinlost, s.ruben, s.bettype, 
			s.spositiontaking, s.swinlost, s.sdiscount, s.scomm, s.statusID, s.recommid, s.recommdate		
		)
	;--end MERGE
	SET IDENTITY_INSERT TPDB.dbo.bettransM OFF
SET NOCOUNT OFF


