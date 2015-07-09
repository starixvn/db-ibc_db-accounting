ALTER PROCEDURE [dbo].[TASK_DBDWCSS_Migration_Populate_bettrans]	
AS
/*   
 Task : SSIS - Get bettrans bettrans_staging data for exporting to DBDWCSS
 DB: DBTP.TPDB
 Revisions:   
  - 20121010@viet: create SP   
*/  
SET NOCOUNT ON

	SELECT recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, 
		apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, 
		refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, 
		modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, 
		CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, dangerous, recommdate
	FROM dbo.BetTrans_staging with(rowlock)
	
SET NOCOUNT OFF	
GO