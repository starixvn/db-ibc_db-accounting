use bodb02
go
ALTER PROCEDURE [dbo].[Task_BalanceGameResetYesterday] @sporttype SMALLINT = -1
	, @bettype SMALLINT = 1101
AS
/*
		Created: Dan	
		Date: 20121009
		Task: reset yesterday balance for live casino
		DB: DBTRANS.BODB02
		
		Revisions:
			- 20131108@Elodie: Splitting bodb02 into CustDB (call CustInfo by link database)
			- 20150710@Patrick: Remove insert default balance value & remove deposit account & support Gold deluxe
			- 20150910@Patrick: Re-arrange code to reduce time & CPU cost

		Parameters Explanation:	
*/
SET NOCOUNT ON	

CREATE TABLE #WeeklyResetCustomer(custid INT, srecommend INT)
IF @bettype = 1101 --LiveCS
BEGIN
	INSERT INTO #WeeklyResetCustomer(custid, srecommend)
	SELECT custid, srecommend
	FROM CustDB.dbo.custinfo WITH (NOLOCK)
	WHERE roleid = 1 AND MaxWinLiveCasino > 0 AND isAutoResetLiveCasino = 0
END
ELSE --others 3rd products
BEGIN
	INSERT INTO #WeeklyResetCustomer(custid, srecommend)
	SELECT c.custid, srecommend
	FROM CustDB.dbo.custinfo c WITH (NOLOCK)
		INNER JOIN DBCUST.CustDB.dbo.CustWinLimit cwl WITH (NOLOCK) ON cwl.CustId = c.custid AND cwl.sporttype = @sporttype AND cwl.bettype = @bettype
	WHERE c.roleid = 1 AND cwl.MaxWinLimit > 0 AND cwl.IsAutoReset = 0
END

DECLARE @Yesterday SMALLDATETIME
SET @Yesterday = DATEADD(dd, -1, CAST(GETDATE() AS DATE))

--delete yesterday balance for daily reset and unlimited balance
WHILE 1 = 1
BEGIN
	DELETE TOP (50000) bal
	FROM dbo.BalanceCreditGame bal WITH (ROWLOCK)
		LEFT JOIN #WeeklyResetCustomer t ON bal.CustId = t.CustId
	WHERE winlostdate = @Yesterday AND bettype = @bettype
		 AND t.CustId IS NULL
	OPTION (MAXDOP 4)
		
	IF @@ROWCOUNT < 50000
		BREAK
			
	WAITFOR DELAY '00:00:00.280'
END

WHILE 1 = 1
BEGIN
	DELETE TOP (50000) bal
	FROM dbo.BalanceDebitGame bal WITH (ROWLOCK)
		LEFT JOIN #WeeklyResetCustomer t ON bal.CustId = t.CustId
	WHERE winlostdate = @Yesterday AND bettype = @bettype
		 AND t.CustId IS NULL
	OPTION (MAXDOP 4)
		
	IF @@ROWCOUNT < 50000
		BREAK
			
	WAITFOR DELAY '00:00:00.280'
END

--remove credit account
DELETE t
FROM #WeeklyResetCustomer t
	LEFT JOIN CustDB.dbo.Dep_CustSuper s WITH(NOLOCK) ON t.srecommend = s.custid
WHERE s.custid IS NULL

IF NOT EXISTS (SELECT TOP 1 1 FROM #WeeklyResetCustomer)
BEGIN
	DROP TABLE #WeeklyResetCustomer
	RETURN
END

--remove deposit account
IF EXISTS (SELECT TOP 1 1 FROM dbo.BalanceCreditGame bal WITH(NOLOCK)
				INNER JOIN #WeeklyResetCustomer t ON bal.CustId = t.custid AND bal.bettype = @bettype AND winlostdate = @Yesterday
		)
BEGIN
	WHILE 1 = 1
	BEGIN
		DELETE TOP (50000) bal
		FROM dbo.BalanceCreditGame bal WITH (ROWLOCK)
			INNER JOIN #WeeklyResetCustomer t ON bal.CustId = t.custid AND bal.bettype = @bettype AND winlostdate = @Yesterday
		
		IF @@ROWCOUNT < 50000
			BREAK
			
		WAITFOR DELAY '00:00:00.280'
	END
END

IF EXISTS (SELECT TOP 1 1 FROM dbo.BalanceDebitGame bal WITH(NOLOCK)
				INNER JOIN #WeeklyResetCustomer t ON bal.CustId = t.custid AND bal.bettype = @bettype AND winlostdate = @Yesterday
		)
BEGIN
	WHILE 1 = 1
	BEGIN
		DELETE TOP (50000) bal
		FROM dbo.BalanceDebitGame bal WITH (ROWLOCK)
			INNER JOIN #WeeklyResetCustomer t ON bal.CustId = t.custid AND bal.bettype = @bettype AND winlostdate = @Yesterday
		
		IF @@ROWCOUNT < 50000
			BREAK
			
		WAITFOR DELAY '00:00:00.280'
	END
END	
DROP TABLE #WeeklyResetCustomer

GO
GRANT VIEW DEFINITION ON [dbo].[Task_BalanceGameResetYesterday] TO [vnteam] AS [dbo]