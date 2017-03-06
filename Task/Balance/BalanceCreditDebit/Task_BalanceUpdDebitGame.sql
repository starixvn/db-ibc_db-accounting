use bodb02
go

ALTER PROCEDURE [dbo].[Task_BalanceUpdDebitGame]
AS
/*
		Created: Dan	
		Date: 20121008
		Task: accumulate balance for debit
		DB: DBTRANS.BODB02
		
		Revisions:
			- 20150710@Patrick: Support Gold Deluxe
			- 20151028@Patrick: Support Company Winlimit
			- 20161011@Helen: CWL - Phase 3 [Redmine:61220]
		Parameters Explanation:	
*/
	
SET NOCOUNT ON
Declare @rn bigint, @rnx bigint
SELECT @rn = MIN(rn), @rnx = MAX(rn)
FROM dbo.BalancePendingDebitGame with (nolock)

IF @rn IS NULL
BEGIN
	WAITFOR DELAY '000:00:01.000'
	RETURN -- no data to be update.
END

-- update maximum only 100 rows once
SET @rn = CASE WHEN @rnx - @rn > 100 THEN @rn + 100 ELSE @rnx END

-- collect balance value.
CREATE TABLE #Balance (custid int, winlostdate smalldatetime, bettype smallint, balance money)
INSERT INTO #Balance
SELECT custid, winlostdate, bettype, SUM(balance)
FROM dbo.BalancePendingDebitGame --with (rowlock)
WHERE rn <= @rn
GROUP BY custid, winlostdate, bettype


CREATE TABLE #Balance_CWL (custid int, winlostdate smalldatetime,bettypeID smallint, GameTypeid smallint, balance money)
INSERT INTO #Balance_CWL(custid, winlostdate,bettypeID, GameTypeid, balance)
SELECT custid, winlostdate, bettype, isnull(GameTypeid,bettype) AS GameTypeid, SUM(balance)
FROM dbo.BalancePendingDebitGame WITH (NOLOCK)
WHERE rn <= @rn
GROUP BY custid, winlostdate,bettype, isnull(GameTypeid,bettype)

DECLARE @today SMALLDATETIME
SET @today = convert(nvarchar(10), current_timestamp,120)

CREATE TABLE #ProductSetting(Bettype SMALLINT, IsCompany BIT, IsSMA BIT)
INSERT INTO #ProductSetting(Bettype, IsCompany, IsSMA)
SELECT BetType, IsActive_Company, IsActive_SMA
FROM dbo.f_Winlimit_GetProductSetting()

-- perform update
Declare @Retry int, @Success bit
SET @Retry = 0

TryAgain:

BEGIN TRY
	SET @Retry = @Retry + 1
	SET @Success = 1
	BEGIN TRANSACTION
	
	--for SMA Winlimit
	UPDATE bal
	SET Balance = bal.Balance + B.balance
	FROM dbo.BalanceDebitGame bal 	--WITH (rowlock, updlock)
		INNER JOIN #Balance B ON bal.custid = B.custid AND bal.winlostdate = B.winlostdate AND bal.bettype = b.bettype
	WHERE b.bettype IN (SELECT BetType FROM #ProductSetting WHERE IsSMA = 1)

	-- insert balance for not exist in balance table
	INSERT INTO dbo.BalanceDebitGame(custid, winlostdate, bettype, balance )
	SELECT b.custid, b.winlostdate, b.bettype, b.balance
	FROM #Balance B 
		LEFT JOIN dbo.BalanceDebitGame bal ON bal.custid = B.custid AND bal.winlostdate = B.winlostdate AND bal.bettype = b.bettype
	WHERE bal.Winlostdate IS NULL AND b.winlostdate = @today
		AND b.bettype IN (SELECT BetType FROM #ProductSetting WHERE IsSMA = 1)
	
	--for Company Winlimit
	UPDATE bal
	SET Winlost = bal.Winlost + B.balance
	FROM dbo.Winlimit_DebitGame bal
		INNER JOIN #Balance_CWL B ON bal.custid = B.custid AND bal.winlostdate = B.winlostdate AND bal.bettype = b.GameTypeid
	WHERE b.bettypeID IN (SELECT BetType FROM #ProductSetting WHERE IsCompany = 1)
	
	INSERT INTO dbo.Winlimit_DebitGame(custid, winlostdate, bettype, Winlost)
	SELECT b.custid, b.winlostdate, b.GameTypeid, b.balance
	FROM #Balance_CWL B 
		LEFT JOIN dbo.Winlimit_DebitGame bal (NOLOCK)  ON bal.custid = B.custid AND bal.winlostdate = B.winlostdate AND bal.bettype = b.GameTypeid
	WHERE bal.Winlostdate IS NULL AND b.winlostdate = @today
		AND b.bettypeID IN (SELECT BetType FROM #ProductSetting WHERE IsCompany = 1)
		
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
	DELETE FROM dbo.BalancePendingDebitGame
	WHERE rn <= @rn

DROP TABLE #ProductSetting

GO
GRANT VIEW DEFINITION ON [dbo].[Task_BalanceUpdDebitGame] TO [vnteam]