ALTER PROCEDURE [dbo].[TASK_DBDWCSS_Migration_Populate_bettransM]	
AS
/*   
 Task : SSIS - Get bettrans bettransG data for exporting to DBDWCSS
 DB: DBTP.TPDB
 Revisions:   
  - 20121010@viet: create SP   
*/  
SET NOCOUNT ON
	SELECT transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, 
		refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
		playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, finalodds, isfinish, statuswinlost, ruben, bettype, 
		spositiontaking, swinlost, sdiscount, scomm, statusID, recommid, recommdate 
	FROM dbo.BetTransM with(rowlock)
	WHERE refno in (			
			select refno from dbo.BetTrans_staging with(nolock) where bettype in (9,29) --parlay
			UNION ALL
			select transid from dbo.BetTrans_staging with(nolock) where bettype = 33 --racing
		)	
SET NOCOUNT OFF	