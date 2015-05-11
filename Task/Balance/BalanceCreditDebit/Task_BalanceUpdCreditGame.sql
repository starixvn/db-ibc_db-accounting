ALTER PROCEDURE [dbo].[Task_BalanceUpdCreditGame]
AS
/*
		Created: Dan	
		Date: 20121008
		Task: accumulate balance for credit
		DB: DBTRANS.BODB02
		
		Revisions:
			
		Parameters Explanation:	
*/
	
SET NOCOUNT ON
Declare @rn bigint, @rnx bigint
SELECT @rn = MIN(rn), @rnx = MAX(rn)
FROM dbo.BalancePendingCreditGame with (nolock)

IF @rn IS NULL
BEGIN
	WAITFOR DELAY '000:00:01.000'
	RETURN -- no data to be update.
END

-- update maximum only 100 rows once
SET @rn = CASE WHEN @rnx - @rn > 100 THEN @rn + 100 ELSE @rnx END

-- collect balance value.
CREATE TABLE #Balance (custid int, winlostdate smalldatetime, balance money)
INSERT INTO #Balance
SELECT custid, winlostdate, SUM(balance)
FROM dbo.BalancePendingCreditGame --with (rowlock)
WHERE rn <= @rn
GROUP BY custid, winlostdate

DECLARE @today SMALLDATETIME
SET @today = convert(nvarchar(10), current_timestamp,120)

-- perform update
Declare @Retry int, @Success bit
SET @Retry = 0

TryAgain:

BEGIN TRY
	SET @Retry = @Retry + 1
	SET @Success = 1
	BEGIN TRANSACTION
	
	UPDATE bal
	SET Balance = bal.Balance + B.balance
	FROM dbo.BalanceCreditGame bal 	--WITH (rowlock, updlock)
		INNER JOIN #Balance B ON bal.custid = B.custid AND bal.winlostdate = B.winlostdate
		
	-- insert balance for today if not exist in balance table
	INSERT INTO dbo.BalanceCreditGame(custid, winlostdate, balance )
	select b.custid, b.winlostdate, b.balance
	from #Balance B 
		LEFT JOIN dbo.BalanceCreditGame bal ON bal.custid = B.custid AND bal.winlostdate = B.winlostdate
	WHERE bal.Winlostdate is null and b.winlostdate = @today
		
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SET @Success = 0
	ROLLBACK TRANSACTION
END CATCH

-- retry 3 times, in case some problem happen.
IF @Success = 0 AND @Retry < 3 GOTO TryAgain

-- remove data which already updated.
IF @Success = 1
	DELETE FROM dbo.BalancePendingCreditGame
	WHERE rn <= @rn

GO
GRANT VIEW DEFINITION ON [dbo].[Task_BalanceUpdCreditGame] TO [vnteam]