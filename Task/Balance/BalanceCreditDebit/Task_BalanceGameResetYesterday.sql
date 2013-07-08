ALTER PROCEDURE [dbo].[Task_BalanceGameResetYesterday]
AS
/*
		Created: Dan	
		Date: 20121009
		Task: reset yesterday balance for live casino
		DB: DBTRANS.BODB02
		
		Revisions:
			
		Parameters Explanation:	
*/
SET NOCOUNT ON	
CREATE TABLE #WeeklyResetCustomer(custid INT)

INSERT INTO #WeeklyResetCustomer(custid)
SELECT custid  
FROM custinfo WITH (NOLOCK)
WHERE roleid=1 AND MaxWinLiveCasino>0 AND isAutoResetLiveCasino = 0

DECLARE @today smalldatetime
SET @today = convert(nvarchar(10), current_timestamp,120)

--delete yesterday balance for daily reset and unlimited balance
DELETE dbo.BalanceCreditGame with (ROWLOCK)
WHERE custid NOT IN (SELECT CustID FROM #WeeklyResetCustomer)
	and winlostdate < @today

DELETE dbo.BalanceDebitGame WITH (ROWLOCK)
WHERE custid NOT IN (SELECT CustID FROM #WeeklyResetCustomer)
	and winlostdate < @today

-- insert default today balance values for weekly reset customer if missing
INSERT dbo.BalanceCreditGame(custid, winlostdate, Balance)
SELECT custid, @today, 0 
FROM #WeeklyResetCustomer cust 
WHERE NOT EXISTS(SELECT 1 
				FROM dbo.BalanceCreditGame bal WITH (NOLOCK)
				WHERE bal.custid=cust.custid AND bal.winlostdate=@today)
				
INSERT dbo.BalanceDebitGame(custid, winlostdate, Balance)
SELECT custid, @today, 0 
FROM #WeeklyResetCustomer cust 
WHERE NOT EXISTS(SELECT 1 
				FROM dbo.BalanceDebitGame bal WITH (NOLOCK)
				WHERE bal.custid=cust.custid AND bal.winlostdate=@today)

GO
GRANT VIEW DEFINITION ON [dbo].[Task_BalanceGameResetYesterday] TO [vnteam]