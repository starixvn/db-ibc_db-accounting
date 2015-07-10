/*
	LCS -Winlimit:	Initialize default balance for today
*/
DECLARE @today smalldatetime
SET @today = convert(nvarchar(10), current_timestamp,120)
--SET @today = '2012-10-17'

CREATE TABLE #Balance(custid int PRIMARY KEY, balance money, Increased bit)
CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

--calculate balance for LCS
INSERT #Balance
SELECT custid, sum(winlost-actual_stake+playercomm), CASE WHEN sum(winlost-actual_stake+playercomm)>= 0 THEN 1 ELSE 0 END
FROM BETTRANS b WITH (NOLOCK)
WHERE BETTYPE IN (1101,1102)
AND WINLOSTDATE= @today
AND RUBEN=1
GROUP BY custid

--SELECT * FROM #Balance

-- insert today balance

INSERT INTO dbo.BalanceDebitGame (custid, winlostdate, balance)
SELECT custid, @today, ABS(balance)
FROM #Balance
WHERE Increased = 0

INSERT INTO dbo.BalanceCreditGame (custid, winlostdate, balance)
SELECT custid,@today, balance
FROM #Balance
WHERE Increased = 1

DROP TABLE #Balance
