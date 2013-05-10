GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Sum_TransferBalanceUp]	
AS
/*  
 Created by:   
 Date:   
 Task:  
 DB: DB053.bodb_Summary  
 Original:   
   
 Revisions:   
  - 20111213@Sophia: change the range of bettype 
  
 Param's Explanation:
 */

SET NOCOUNT ON

declare @BalanceUpDay smalldatetime
SELECT 
	TOP 1 @BalanceUpDay = winlostdate
FROM bodb02.dbo.Bettrans WITH(NOLOCK)
WHERE bettype = 100 and matchid = 0	and custid = 3

WHILE 1=1
BEGIN
    DELETE TOP(20000) FROM [dbo].sum_transfer where winlostdate = @BalanceUpDay and bettype = 100
    IF @@ROWCOUNT < 20000
        BREAK

END

------------------------------------
--BALANCE UP
------------------------------------
--Super
INSERT INTO dbo.sum_transfer
	(winlostdate,
	roleid, custid, recommend, mrecommend, srecommend,
	TotalAmt, bettype, currency)
SELECT @BalanceUpDay,		
	4, srecommend custid, 0 recommend, 0 mrecommend, srecommend,
	sum(winlost-actual_stake)  TotalAmt, 100, currency	
FROM bodb02.dbo.bettrans b with (nolock)
WHERE		
	b.winlostdate = @BalanceUpDay and
	b.bettype = 20000 and ruben=1 and matchid = 0		
GROUP BY
	b.srecommend, currency

--Master
INSERT INTO dbo.sum_transfer
	(winlostdate,
	roleid, custid, recommend, mrecommend, srecommend,
	TotalAmt, bettype, currency)
SELECT @BalanceUpDay,		
	3, mrecommend custid, 0 recommend, mrecommend, srecommend,
	sum(winlost-actual_stake)  TotalAmt, 100, currency	
FROM bodb02.dbo.bettrans b with (nolock)
	
WHERE		
	b.winlostdate = @BalanceUpDay and
	b.bettype = 20000 and ruben=1 and matchid = 0
	and mrecommend > 0
GROUP BY
	srecommend, mrecommend, currency


--Agent
INSERT INTO dbo.sum_transfer
	(winlostdate,
	roleid, custid, recommend, mrecommend, srecommend,
	TotalAmt, bettype, currency)
SELECT @BalanceUpDay,		
	2, recommend custid, recommend, mrecommend, srecommend,
	sum(winlost-actual_stake + awinlost) TotalAmt, 100, currency	
FROM bodb02.dbo.bettrans b with (nolock)
	
WHERE		
	b.winlostdate = @BalanceUpDay and
	b.bettype = 20000 and ruben=1 and matchid = 0
	and recommend > 0
GROUP BY
	srecommend, mrecommend, recommend, currency


--member
INSERT INTO dbo.sum_transfer
	(winlostdate,
	roleid, custid, recommend, mrecommend, srecommend,
	TotalAmt, bettype, currency)
SELECT @BalanceUpDay,		
	1, custid, recommend, mrecommend, srecommend,
	sum(winlost-actual_stake) TotalAmt, 100, currency	
FROM bodb02.dbo.bettrans b with (nolock)
	
WHERE		
	b.winlostdate = @BalanceUpDay and
	b.bettype = 20000 and ruben=1 and matchid = 0
	and b.custid <> b.recommend and
		b.custid <> b.mrecommend and
		b.custid <> b.srecommend
GROUP BY
	srecommend, mrecommend, recommend, custid, currency

GO
GRANT VIEW DEFINITION ON [dbo].[Task_Sum_TransferBalanceUp] TO [vnteam]








