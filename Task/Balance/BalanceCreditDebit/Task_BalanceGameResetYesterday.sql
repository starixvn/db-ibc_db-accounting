use bodb02
go
ALTER PROCEDURE [dbo].[Task_BalanceGameResetYesterday] @sporttype SMALLINT = -1
	, @bettype SMALLINT = 1101
AS
/*
		Created: Dan	
		Date: 20121009
		Task: reset yesterday balance for love casino
		DB: DBTRANS.BODB02
		
		Revisions:
			- 20131108@Elodie: Splitting bodb02 into CustDB (call CustInfo by link database)
			- 20150710@Patrick: Remove insert default balance value & remove deposit account & support Gold deluxe

		Parameters Explanation:	
*/
SET NOCOUNT ON	
CREATE TABLE #WeeklyResetCustomer(custid INT)

IF @bettype = 1101 --LiveCS
BEGIN
	INSERT INTO #WeeklyResetCustomer(custid)
	SELECT custid  
	FROM CustDB.dbo.custinfo WITH (NOLOCK)
	WHERE roleid = 1 AND MaxWinLiveCasino > 0 AND isAutoResetLiveCasino = 0
END
ELSE --others 3rd products
BEGIN
	INSERT INTO #WeeklyResetCustomer(custid)
	SELECT c.custid
	FROM CustDB.dbo.custinfo c WITH (NOLOCK)
		INNER JOIN DBCUST.CustDB.dbo.CustWinLimit cwl WITH (NOLOCK) ON cwl.CustId = c.custid AND cwl.sporttype = @sporttype AND cwl.bettype = @bettype
	WHERE c.roleid = 1 AND cwl.MaxWinLimit > 0 AND cwl.IsAutoReset = 0
END

DECLARE @today smalldatetime
SET @today = convert(nvarchar(10), current_timestamp,120)

--delete yesterday balance for daily reset and unlimited balance
WHILE 1 = 1
BEGIN
	DELETE TOP (50000)
	FROM dbo.BalanceCreditGame WITH (ROWLOCK)
	WHERE custid NOT IN (SELECT CustID FROM #WeeklyResetCustomer)
		AND winlostdate < @today
		AND bettype = @bettype
		
	IF @@ROWCOUNT < 50000
		BREAK
			
	WAITFOR DELAY '00:00:00.280'
END

WHILE 1 = 1
BEGIN
	DELETE TOP (50000) 
	FROM dbo.BalanceDebitGame WITH (ROWLOCK)
	WHERE custid NOT IN (SELECT CustID FROM #WeeklyResetCustomer)
		AND winlostdate < @today
		AND bettype = @bettype
		
	IF @@ROWCOUNT < 50000
		BREAK
			
	WAITFOR DELAY '00:00:00.280'
END

--remove deposit account
WHILE 1 = 1
BEGIN
	DELETE TOP (50000) bal
	FROM dbo.BalanceCreditGame bal WITH (ROWLOCK)
		INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON bal.custid = c.custid
	WHERE c.srecommend IN (SELECT CustId FROM CustDB.dbo.Dep_CustSuper WITH(NOLOCK))
		AND winlostdate < @today
		AND bettype = @bettype
		
	IF @@ROWCOUNT < 50000
		BREAK
			
	WAITFOR DELAY '00:00:00.280'
END

WHILE 1 = 1
BEGIN

	DELETE TOP (50000) bal
	FROM dbo.BalanceDebitGame bal WITH (ROWLOCK)
		INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON bal.custid = c.custid
	WHERE c.srecommend IN (SELECT CustId FROM CustDB.dbo.Dep_CustSuper WITH(NOLOCK))
		AND winlostdate < @today
		AND bettype = @bettype
	
	IF @@ROWCOUNT < 50000
		BREAK
			
	WAITFOR DELAY '00:00:00.280'
END


GO
GRANT VIEW DEFINITION ON [dbo].[Task_BalanceGameResetYesterday] TO [vnteam] AS [dbo]