USE bodb02
GO

ALTER PROCEDURE dbo.Task_Winlimit_BlockedUser
AS
/*   
	Create: 20151016@Patrick
	Task : Task scan winlimit amount & blocked member when they are reached max winlimit setting
	DB: DBTXN/bodb02
	Revisions:
	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #CustWinlimitSetting(CustId INT, ProductId TINYINT, MaxWinLimit MONEY)
	CREATE TABLE #ProductSetting(ProductId TINYINT, Bettype SMALLINT)
	CREATE TABLE #DataTmp (CustId INT, Currency TINYINT, ProductId TINYINT, Bettype SMALLINT, TotalWinAmount MONEY, WinlostDate SMALLDATETIME)
	CREATE TABLE #HistoryData (CustId INT, ProductId TINYINT, MaxWinLimit MONEY, TotalWinAmt MONEY, IsBlocked BIT, BlockedDate DATETIME
		, UnBlockedDate DATETIME, IsNotified BIT, BetType SMALLINT, BlockedWinAmt MONEY, ModifiedBy INT, CreatedBy INT, WinlostDate SMALLDATETIME)

	--get setting from DBCUST via linked server
	INSERT INTO #CustWinlimitSetting(CustId, ProductId, MaxWinLimit)
	SELECT CustId, ProductId, ISNULL(MaxWinLimit, 0)
	FROM DBCUST.CustDB.dbo.WinLimit_CustSetting WITH(NOLOCK)
	--WHERE ISNULL(MaxWinLimit, 0) > 0

	--get product setting
	INSERT INTO #ProductSetting(ProductId, Bettype)
	SELECT ProductId, BetType
	FROM dbo.f_Winlimit_GetProductSetting() WHERE IsActive_Company = 1

	DECLARE @WinlostDate SMALLDATETIME, @BlockedDate DATETIME
	SELECT @WinlostDate = CAST(GETDATE() AS DATE), @BlockedDate = GETDATE()

	INSERT INTO #DataTmp(CustId, ProductId, Bettype, TotalWinAmount, WinlostDate, Currency)
	SELECT ISNULL(c.CustId, d.CustId) AS CustId
		, p.ProductId
		, ISNULL(c.BetType, d.BetType) AS Bettype
		, SUM(ISNULL(c.Winlost, 0) - ISNULL(d.Winlost, 0)) AS TotalWinAmount
		, @WinlostDate AS WinlostDate
		, cc.currency
	FROM dbo.Winlimit_CreditGame c WITH(NOLOCK)
		FULL OUTER JOIN dbo.Winlimit_DebitGame d WITH(NOLOCK)
			ON c.CustId = d.CustId AND c.WinlostDate = d.WinlostDate AND c.BetType = d.Bettype
		INNER JOIN #ProductSetting p ON ISNULL(c.BetType, d.BetType) = p.Bettype
		INNER JOIN CustDB.dbo.Customer cc WITH(NOLOCK) ON ISNULL(c.CustId, d.CustId) = cc.custid
	WHERE ISNULL(c.WinlostDate, d.WinlostDate) = @WinlostDate
	GROUP BY ISNULL(c.CustId, d.CustId), p.ProductId, ISNULL(c.BetType, d.BetType), cc.currency
	
	CREATE TABLE #CustBlockedList (CustId INT, ProductId TINYINT, Bettype SMALLINT, MaxWinLimit MONEY
		, TotalWinAmount MONEY, WinlostDate SMALLDATETIME)

	--need to check cust setting fisrt after check global setting
	--for WinLimit_CustSetting
	INSERT INTO #CustBlockedList(CustId, ProductId, Bettype, MaxwinLimit, TotalWinAmount, WinlostDate)
	SELECT t.CustId, t.ProductId, t.Bettype, s.MaxWinLimit, t.TotalWinAmount, t.WinlostDate
	FROM #DataTmp t
		INNER JOIN #CustWinlimitSetting s ON t.CustId = s.CustId AND t.ProductId = s.ProductId
	WHERE t.TotalWinAmount >= s.MaxWinLimit
		AND s.MaxWinLimit > 0
	
	--for WinLimit_GlobalSetting
	IF EXISTS (
		SELECT TOP 1 1 FROM #DataTmp t
			INNER JOIN dbo.WinLimit_GlobalSetting s WITH(NOLOCK) ON t.Currency = s.ExchangeID AND t.ProductId = s.ProductID
		WHERE t.TotalWinAmount >= s.MaxWinLimit
			AND ISNULL(s.MaxWinLimit, 0) > 0
	)
	BEGIN
		INSERT INTO #CustBlockedList(CustId, ProductId, Bettype, MaxwinLimit, TotalWinAmount, WinlostDate)
		SELECT t.CustId, t.ProductId, t.Bettype, s.MaxWinLimit, t.TotalWinAmount, t.WinlostDate
		FROM #DataTmp t
			INNER JOIN dbo.WinLimit_GlobalSetting s WITH(NOLOCK) ON t.Currency = s.ExchangeID AND t.ProductId = s.ProductID
			LEFT JOIN #CustBlockedList cc ON t.CustId = cc.CustId AND t.ProductId = cc.ProductId
		WHERE t.TotalWinAmount >= s.MaxWinLimit
			AND cc.CustId IS NULL
			AND ISNULL(s.MaxWinLimit, 0) > 0
	END

	--remove members who is setting unlimited
	DELETE t
	FROM #CustBlockedList t
		INNER JOIN #CustWinlimitSetting s ON t.CustId = s.CustId AND t.ProductId = s.ProductId
	WHERE s.MaxWinLimit = 0

	--select * from @CustBlockedList
	IF NOT EXISTS (SELECT TOP 1 1 FROM #CustBlockedList)
	BEGIN
		DROP TABLE #HistoryData
		DROP TABLE #ProductSetting
		DROP TABLE #CustWinlimitSetting
		DROP TABLE #DataTmp
		DROP TABLE #CustBlockedList

		RETURN

	END

	--incase reached MaxWinLimit again
	UPDATE g
	SET MaxwinLimit = t.MaxWinLimit
		, TotalWinAmt = CASE WHEN g.IsBlocked = 0 AND g.WinlostDate = @WinlostDate THEN g.TotalWinAmt + t.TotalWinAmount
							ELSE t.TotalWinAmount END
		, BlockedWinAmt = t.TotalWinAmount
		, IsBlocked = 1
		, IsNotified = 0
		, BlockedDate = @BlockedDate
		, UnBlockedDate = NULL
	FROM dbo.WinLimit_Game g WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #CustBlockedList t ON t.CustId = g.CustID AND t.Bettype = g.Bettype
	
	--insert
	INSERT INTO dbo.WinLimit_Game(CustId, ProductID, Bettype, MaxWinLimit, BlockedWinAmt, TotalWinAmt, IsBlocked, BlockedDate
		, UnBlockedDate, IsNotified, CreatedBy, WinlostDate)
	SELECT t.CustId, t.ProductId, t.Bettype, t.MaxwinLimit, t.TotalWinAmount, t.TotalWinAmount, 1, @BlockedDate
		, NULL, 0, NULL, @WinlostDate
	FROM #CustBlockedList t
		LEFT JOIN dbo.WinLimit_Game g WITH(NOLOCK) ON t.CustId = g.CustID AND t.Bettype = g.Bettype
	WHERE g.CustID IS NULL

	--history data
	INSERT INTO #HistoryData(CustId, ProductId, MaxWinLimit, TotalWinAmt, IsBlocked, BlockedDate
		, UnBlockedDate, IsNotified, BetType, BlockedWinAmt, ModifiedBy, CreatedBy, WinlostDate)
	SELECT CustId, ProductId, MaxWinLimit, TotalWinAmt, IsBlocked, BlockedDate
		, UnBlockedDate, IsNotified, BetType, BlockedWinAmt, ModifiedBy, CreatedBy, WinlostDate
	FROM dbo.WinLimit_Game WITH(NOLOCK)
	WHERE IsBlocked = 1
		AND WinlostDate = @WinlostDate
		AND BlockedDate = @BlockedDate

	DECLARE @StrData VARCHAR(MAX), @XmlData XML, @RowCount INT, @ReTry INT
	DECLARE @HistoryDataTmp TABLE (CustId INT, ProductId TINYINT, MaxWinLimit MONEY, TotalWinAmt MONEY, IsBlocked BIT, BlockedDate DATETIME
		, UnBlockedDate DATETIME, IsNotified BIT, BetType SMALLINT, BlockedWinAmt MONEY, ModifiedBy INT, CreatedBy INT, WinlostDate SMALLDATETIME)

	WHILE 1 = 1 --exec by batch
	BEGIN
		--clear data
		DELETE @HistoryDataTmp
		SELECT @XmlData = NULL, @StrData = NULL

		DELETE TOP(500) #HistoryData
		OUTPUT DELETED.*
		INTO @HistoryDataTmp

		SET @RowCount = @@ROWCOUNT

		SET @XmlData = (
				SELECT CustId '@a1'
					, ProductId '@a2'
					, MaxWinLimit '@a3'
					, TotalWinAmt '@a4'
					, IsBlocked '@a5'
					, BlockedDate '@a6'
					, UnBlockedDate '@a7'
					, IsNotified '@a8'
					, BetType '@a9'
					, BlockedWinAmt '@b1'
					, ModifiedBy '@b2'
					, CreatedBy '@b3'
					, WinlostDate '@b4'
				FROM @HistoryDataTmp
				FOR XML PATH('r'), ROOT ('root'), TYPE
			)
		SET @StrData = CONVERT(NVARCHAR(MAX), @XmlData)
		
		IF @StrData IS NULL
			BREAK

		SET @ReTry = 1
		WHILE @ReTry <= 3
		BEGIN
			BEGIN TRY
				--call insert data to log
				EXEC DBLOG.bodb_CustomerLog.dbo.Task_Winlimit_InsertHistoryData @XmlData = @StrData
				BREAK
			END TRY
			BEGIN CATCH
				--write log
				SET @ReTry += 1
			END CATCH
		END
		IF @RowCount < 100
			BREAK
	END
	
	DROP TABLE #HistoryData
	DROP TABLE #ProductSetting
	DROP TABLE #CustWinlimitSetting
	DROP TABLE #DataTmp
	DROP TABLE #CustBlockedList
	
END
GO
