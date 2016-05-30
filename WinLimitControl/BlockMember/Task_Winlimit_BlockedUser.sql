ALTER PROCEDURE dbo.Task_Winlimit_BlockedUser
AS
/*   
	Create: 20151016@Patrick
	Task : Task scan winlimit amount & blocked member when they are reached max winlimit setting
	DB: DBTXN/bodb02
	Revisions:
		- 20151211@Patrick: Remove action blocked member [Redmine: #49194]
		- 20160507@Patrick: #57213 - Voidbridge integration
		- 20160520@Helen: Company Winlimit - Member reach red level, block Licensee only, not Credit [Redmine: 57680]
	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #CustWinlimitSetting(CustId INT, ProductId TINYINT, MaxWinLimit MONEY)
	CREATE TABLE #ProductSetting(ProductId TINYINT, Bettype SMALLINT)
	CREATE TABLE #DataTmp (CustId INT, Currency TINYINT, ProductId TINYINT, Bettype SMALLINT, TotalWinAmount MONEY, WinlostDate SMALLDATETIME)
	CREATE TABLE #HistoryData (CustId INT, ProductId TINYINT, MaxWinLimit MONEY, TotalWinAmt MONEY, IsBlocked BIT, BlockedDate DATETIME
		, UnBlockedDate DATETIME, IsNotified BIT, BetType SMALLINT, BlockedWinAmt MONEY, ModifiedBy INT, CreatedBy INT, WinlostDate SMALLDATETIME)

	--get product setting
	INSERT INTO #ProductSetting(ProductId, Bettype)
	SELECT ProductId, BetType
	FROM dbo.f_Winlimit_GetProductSetting() WHERE IsActive_Company = 1

	DECLARE @WinlostDate SMALLDATETIME, @BlockedDate DATETIME
	SELECT @WinlostDate = CAST(GETDATE() AS DATE)

	INSERT INTO #DataTmp(CustId, WinlostDate, Bettype, TotalWinAmount)
	SELECT CustId, WinlostDate, BetType, SUM(Winlost)
	FROM (
		SELECT CustId, WinlostDate, BetType, Winlost
		FROM dbo.Winlimit_CreditGame c WITH(NOLOCK)
		WHERE WinlostDate = @WinlostDate
			AND EXISTS (SELECT TOP 1 1 FROM #ProductSetting s WHERE c.BetType = s.Bettype)

		UNION ALL
		SELECT CustId, WinlostDate, BetType, - Winlost
		FROM dbo.Winlimit_DebitGame c WITH(NOLOCK)
		WHERE WinlostDate = @WinlostDate
			AND EXISTS (SELECT TOP 1 1 FROM #ProductSetting s WHERE c.BetType = s.Bettype)
	)t
	GROUP BY CustId, WinlostDate, BetType

	UPDATE t 
	SET Currency = cc.currency
		, ProductId = s.ProductId
	FROM #DataTmp t
		INNER JOIN #ProductSetting s on t.Bettype = s.Bettype
		INNER JOIN CustDB.dbo.Customer cc WITH(NOLOCK) ON t.CustId = cc.custid
	

	CREATE TABLE #CustBlockedList (CustId INT, ProductId TINYINT, Bettype SMALLINT, MaxWinLimit MONEY
		, TotalWinAmount MONEY, WinlostDate SMALLDATETIME, IsDep BIT)

	--need to check cust setting fisrt after check global setting
	--for WinLimit_CustSetting
	INSERT INTO #CustBlockedList(CustId, ProductId, Bettype, MaxwinLimit, TotalWinAmount, WinlostDate)
	SELECT t.CustId, t.ProductId, t.Bettype, s.MaxWinLimit, t.TotalWinAmount, t.WinlostDate
	FROM #DataTmp t
		INNER JOIN DBCUST.CustDB.dbo.WinLimit_CustSetting s WITH(NOLOCK) ON t.CustId = s.CustId AND t.ProductId = s.ProductId
	WHERE t.TotalWinAmount >= s.MaxWinLimit
		AND s.MaxWinLimit > 0
	
	--for WinLimit_GlobalSetting
	IF EXISTS (
		SELECT TOP 1 1 FROM #DataTmp t
			INNER JOIN dbo.WinLimit_GlobalSetting s WITH(NOLOCK) ON t.Currency = s.ExchangeID AND t.ProductId = s.ProductID
		WHERE t.TotalWinAmount >= s.MaxWinLimit
			AND s.MaxWinLimit > 0
	)
	BEGIN
		INSERT INTO #CustBlockedList(CustId, ProductId, Bettype, MaxwinLimit, TotalWinAmount, WinlostDate)
		SELECT t.CustId, t.ProductId, t.Bettype, s.MaxWinLimit, t.TotalWinAmount, t.WinlostDate
		FROM #DataTmp t
			INNER JOIN dbo.WinLimit_GlobalSetting s WITH(NOLOCK) ON t.Currency = s.ExchangeID AND t.ProductId = s.ProductID
			LEFT JOIN #CustBlockedList cc ON t.CustId = cc.CustId AND t.ProductId = cc.ProductId
		WHERE t.TotalWinAmount >= s.MaxWinLimit
			AND cc.CustId IS NULL
			AND s.MaxWinLimit > 0
	END

	UPDATE T
		SET IsDep = 1
	FROM #CustBlockedList T
		INNER JOIN CustDB.dbo.custInfo ci WITH (NOLOCK) ON T.CustId = CI.custid
		INNER JOIN CustDB.dbo.Dep_CustSuper CS WITH (NOLOCK) ON CS.custid = CI.srecommend
	

	IF NOT EXISTS (SELECT TOP 1 1 FROM #CustBlockedList)
	BEGIN
		DROP TABLE #HistoryData
		DROP TABLE #ProductSetting
		DROP TABLE #CustWinlimitSetting
		DROP TABLE #DataTmp
		DROP TABLE #CustBlockedList

		RETURN

	END

	SELECT @BlockedDate = GETDATE()
	--incase reached MaxWinLimit again
	
	UPDATE g
	SET MaxwinLimit = t.MaxWinLimit
		, TotalWinAmt = CASE WHEN g.IsBlocked = 0 AND g.WinlostDate = @WinlostDate THEN g.TotalWinAmt + t.TotalWinAmount
							ELSE t.TotalWinAmount END
		--, TotalWinAmt = t.TotalWinAmount
		, BlockedWinAmt = t.TotalWinAmount
		, IsBlocked = CASE WHEN t.IsDep = 1 THEN 1 ELSE NULL END
		, IsNotified = CASE WHEN t.IsDep = 1 THEN 0 ELSE G.IsNotified END
							
		, BlockedDate = CASE WHEN t.IsDep = 1 THEN @BlockedDate ELSE g.BlockedDate END
		, UnBlockedDate = NULL--CASE WHEN g.WinlostDate = @WinlostDate THEN @BlockedDate ELSE NULL END
		, WinlostDate = @WinlostDate
		, CreatedBy = NULL
		, ModifiedBy = NULL
		
	OUTPUT inserted.CustId, inserted.ProductId, inserted.MaxWinLimit, inserted.TotalWinAmt, inserted.IsBlocked, inserted.BlockedDate
		, inserted.UnBlockedDate, inserted.IsNotified, inserted.BetType, inserted.BlockedWinAmt, inserted.ModifiedBy, inserted.CreatedBy, inserted.WinlostDate
	INTO #HistoryData(CustId, ProductId, MaxWinLimit, TotalWinAmt, IsBlocked, BlockedDate
		, UnBlockedDate, IsNotified, BetType, BlockedWinAmt, ModifiedBy, CreatedBy, WinlostDate)

	FROM dbo.WinLimit_Game g WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #CustBlockedList t ON t.CustId = g.CustID AND g.WinlostDate = t.WinlostDate AND t.Bettype = g.Bettype
		
	WHERE g.IsBlocked = 0

	--insert
	INSERT INTO dbo.WinLimit_Game(CustId, ProductID, Bettype, MaxWinLimit, BlockedWinAmt, TotalWinAmt
		, IsBlocked, BlockedDate, UnBlockedDate, IsNotified, CreatedBy, WinlostDate)
		
		OUTPUT inserted.CustId, inserted.ProductId, inserted.MaxWinLimit, inserted.TotalWinAmt, inserted.IsBlocked
			, inserted.BlockedDate, inserted.UnBlockedDate, inserted.IsNotified, inserted.BetType, inserted.BlockedWinAmt
			, inserted.ModifiedBy, inserted.CreatedBy, inserted.WinlostDate
		INTO #HistoryData(CustId, ProductId, MaxWinLimit, TotalWinAmt, IsBlocked, BlockedDate
			, UnBlockedDate, IsNotified, BetType, BlockedWinAmt, ModifiedBy, CreatedBy, WinlostDate)
	
	SELECT t.CustId, t.ProductId, t.Bettype, t.MaxwinLimit, t.TotalWinAmount, t.TotalWinAmount
		, CASE WHEN t.IsDep = 1 THEN 1 ELSE NULL END, @BlockedDate, NULL, 0, NULL, @WinlostDate
	FROM #CustBlockedList t
		LEFT JOIN dbo.WinLimit_Game g WITH(NOLOCK) ON t.CustId = g.CustID AND t.WinlostDate = g.WinlostDate AND t.Bettype = g.Bettype
	WHERE g.CustID IS NULL
	
	
	DECLARE @StrData VARCHAR(MAX), @XmlData XML, @RowCount INT, @ReTry INT
	DECLARE @HistoryDataTmp TABLE (CustId INT, ProductId TINYINT, MaxWinLimit MONEY, TotalWinAmt MONEY, IsBlocked BIT, BlockedDate DATETIME
		, UnBlockedDate DATETIME, IsNotified BIT, BetType SMALLINT, BlockedWinAmt MONEY, ModifiedBy INT, CreatedBy INT, WinlostDate SMALLDATETIME)

	-- Do NOT save History for credit when it reach limit for the next times
	DELETE HD
	FROM #HistoryData HD
		INNER JOIN #CustBlockedList CBL ON HD.CustId = CBL.CustId
	WHERE CBL.IsDep IS NULL AND HD.IsNotified = 1	
		
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
