USE [bodb_Summary]
GO
/****** Object:  StoredProcedure [dbo].[Task_Sum_TransferDaily]    Script Date: 06/12/2010 10:11:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_Sum_TransferDaily]
	@winlostdate datetime
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
WHILE 1=1
BEGIN
    DELETE TOP(20000) FROM [dbo].sum_transfer where winlostdate = @winlostdate and bettype = 0
    IF @@ROWCOUNT < 20000
        BREAK

END

declare @BalanceUpDay smalldatetime, @MoveBetsDay smalldatetime
SELECT 
	TOP 1 @BalanceUpDay = winlostdate
FROM  bodb02.dbo.Bettrans WITH(NOLOCK)
WHERE bettype = 20000 and matchid = 0	and custid = 3

SELECT 		
	@MoveBetsDay = max(winlostdate) 
	FROM  bodb02.dbo.Bettrans14 WITH(NOLOCK)

if @winlostdate < @BalanceUpDay or @winlostdate > @MoveBetsDay
BEGIN
	RAISERROR ('FAILED: Cal-Date is not VALID!', 16, 1)
	RETURN
END	

------------------------------------
--TRANSFER
------------------------------------
--super
INSERT INTO dbo.sum_transfer
	(winlostdate,
	roleid, custid, recommend, mrecommend, srecommend,
	TotalAmt, bettype, currency)
SELECT @winlostdate,
	4, b.srecommend as custid, 0 recommend, 0 mrecommend, b.srecommend srecommend,
	sum(winlost-actual_stake)  TotalAmt, 0, currency
FROM  bodb02.dbo.bettrans b with (nolock)
	
WHERE		
	b.winlostdate = @winlostdate and
	--b.status not in ('running','waiting','VOID','REJECT','REFUND') and
	b.statusID NOT IN (0,1,101,102,103) and 
	b.bettype > 20000 and ruben=1 and matchid = 0		
GROUP BY
	b.srecommend, currency

--master
INSERT INTO dbo.sum_transfer
	(winlostdate,
	roleid, custid, recommend, mrecommend, srecommend,
	TotalAmt, bettype, currency)
SELECT @winlostdate,
	3, b.mrecommend custid, 0 recommend, b.mrecommend mrecommend, b.srecommend srecommend,
	sum(winlost-actual_stake)  TotalAmt, 0, currency
FROM  bodb02.dbo.bettrans b with (nolock)
WHERE		
	b.winlostdate = @winlostdate and
	--b.status not in ('running','waiting','VOID','REJECT','REFUND') and
	b.statusID NOT IN (0,1,101,102,103) and 
	b.bettype > 20000 and ruben=1 and matchid = 0
	and b.mrecommend > 0
GROUP BY
	b.srecommend, b.mrecommend, currency

--agent
INSERT INTO dbo.sum_transfer
	(winlostdate,
	roleid, custid, recommend, mrecommend, srecommend,
	TotalAmt, bettype, currency)
SELECT @winlostdate,
	2, b.recommend custid, b.recommend, b.mrecommend, b.srecommend,
	sum(winlost-actual_stake)  TotalAmt, 0, currency
FROM  bodb02.dbo.bettrans b with (nolock)
WHERE		
	b.winlostdate = @winlostdate and
	--b.status not in ('running','waiting','VOID','REJECT','REFUND') and
	b.statusID NOT IN (0,1,101,102,103) and 
	b.bettype > 20000 and ruben=1 and matchid = 0
	and b.recommend > 0	
GROUP BY
	b.srecommend, b.mrecommend, b.recommend, currency


--member
INSERT INTO dbo.sum_transfer
	(winlostdate,
	roleid, custid, recommend, mrecommend, srecommend,
	TotalAmt, bettype, currency)
SELECT @winlostdate,
	1, b.custid custid, b.recommend, b.mrecommend, b.srecommend,
	sum(winlost-actual_stake)  TotalAmt, 0, currency
FROM  bodb02.dbo.bettrans b with (nolock)
WHERE		
	b.winlostdate = @winlostdate and
	--b.status not in ('running','waiting','VOID','REJECT','REFUND') and
	b.statusID NOT IN (0,1,101,102,103) and 
	b.bettype > 20000 and ruben=1 and matchid = 0
	and b.custid <> b.recommend and
		b.custid <> b.mrecommend and
		b.custid <> b.srecommend	
GROUP BY
	b.srecommend, b.mrecommend, b.recommend, b.custid, currency



GO
GRANT VIEW DEFINITION ON [dbo].[Task_Sum_TransferDaily] TO [vnteam]