ALTER PROCEDURE [dbo].[Task_Archive_Transfer]  
	@BU_Date datetime -- BalanceUp Date  
AS  

/*
Created: 
Task : 
Process will archive
 - bodb_Report.dbo.statement
 - bodb_Archive.dbo.Transfer_BK
DB: DB06.bodb02
Original:

Revisions:
	- 20110516@Henry: change bettype to new range

	
Param's Explanation: 

*/	  
  
Declare @CurrentBU_Date datetime  
SELECT TOP 1 @CurrentBU_Date = winlostdate  
FROM dbo.bettrans with (nolock)  
WHERE matchid = 0 AND bettype = 20000  
  
-- OpenBalance & Transfer for Statement  
INSERT INTO bodb_Report.dbo.statement  (custid, accdate, totalamt, transtype, transdesc)  
select  
	custid, 
	transdate accdate,
	sum(winlost-actual_stake) totalamt,
	typenamee transtype,
	transdesc  
from  
	dbo.bettrans  with (nolock)  
	inner join dbo.bettype  with (nolock) on bettrans.bettype=bettype.typeid  
where  
	matchid = 0 AND bettype >= 20000 --between 100 and 106 --AND transdate >= @fromdate   
	AND winlostdate >= @CurrentBU_Date AND winlostdate < @BU_Date and custid <> 0  
	group by custid, typenamee,transdesc,transdate,transid  
	having sum(winlost-actual_stake) <> 0  
  
-- Transfer Archive  
INSERT INTO bodb_Archive.dbo.Transfer_BK  
	(transid, custid, transdate, Debit, Credit, TransDesc, winlostdate, recommend, mrecommend, srecommend, bettype, currency, refno, creator)  
SELECT  
	transid, 
	custid, 
	transdate, 
	actual_stake, 
	winlost, 
	TransDesc, 
	winlostdate, 
	recommend, 
	mrecommend, 
	srecommend, 
	bettype, 
	currency, 
	refno, 
	creator  
FROM dbo.bettrans with (nolock)  
WHERE  
	matchid = 0 AND bettype > 20000  
	AND winlostdate >= @CurrentBU_Date AND  winlostdate < @BU_Date  
	AND custid <> 0 AND (winlost + actual_stake) <> 0  
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Archive_Transfer] TO [vnteam]