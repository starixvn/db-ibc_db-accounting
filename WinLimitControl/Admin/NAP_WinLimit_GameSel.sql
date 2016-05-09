USE bodb02
GO

ALTER PROCEDURE dbo.NAP_WinLimit_GameSel @FromDate SMALLDATETIME
	, @ToDate SMALLDATETIME
	, @UserName VARCHAR(50) = ''
	, @ExchangeID INT = 0
	, @ProductID TINYINT = 0
	, @ExcludeTestData BIT = 1
	
	, @PageIndex INT = 1
	, @PageSize INT = 50
	, @TotalRow INT = 0 OUTPUT
AS
	/*
		Created: 20150630@Phillip	
		Task: Get All users from Winlimit_Game table.
		DB: DBTXN/bodb02
		Revisions:
			- 20160507@Patrick: #57213 - Voidbridge integration
		Parameters Explanation:	
	*/
BEGIN
	SET NOCOUNT ON;
	--DECLARE @TestCurrency TABLE (ExchangeID INT, Currency NVARCHAR(50))

	IF ISNULL(@ExchangeID, 0) = 0
		SET @ExchangeID = 0
	IF ISNULL(@ProductID, 0) = 0
		SET @ProductID = 0

	--INSERT INTO @TestCurrency (ExchangeID, Currency)
	--SELECT ExchangeID, Currency
	--FROM CustDB.dbo.Exchange e WITH (NOLOCK)
	--WHERE Currency IN ('UUS', 'H', 'C')
	
	DECLARE @tempProduct TABLE (bettype SMALLINT, ProductName VARCHAR(100))

	INSERT INTO @tempProduct(bettype, ProductName)
	SELECT BetType, ProductName
	FROM dbo.f_Winlimit_GetProductSetting() p
	WHERE @ProductID = 0 OR ProductID = @ProductID

	DECLARE @CustId INT, @Today SMALLDATETIME
	
	SELECT @Today = CONVERT(DATE, CURRENT_TIMESTAMP)
	IF ISNULL(@UserName, '') = ''
		SET @UserName = ''
	ELSE
		SELECT @CustId = CustId, @ExchangeID = Currency
		FROM CustDB.dbo.Customer c WITH(NOLOCK) WHERE UserName = @UserName

	CREATE TABLE #tempResult (RowNum INT, CustID INT, ProductID TINYINT, MaxWinLimit MONEY, BlockedWinAmt MONEY
		, TotalWinAmt MONEY, BlockedDate DATETIME, IsBlocked BIT, CreatedBy INT, UserName VARCHAR(50)
		, Currency TINYINT, ProductName VARCHAR(50), IsNotified BIT, ModifiedDate DATETIME)

	IF @UserName = ''
	BEGIN
		SELECT @TotalRow = COUNT(1)
		FROM dbo.WinLimit_Game g WITH (NOLOCK)
			INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON g.CustId = c.CustId
			INNER JOIN @tempProduct p ON g.Bettype = p.bettype
		WHERE WinlostDate BETWEEN @FromDate AND @Today
			AND (@ExchangeID = 0 OR @ExchangeID = c.currency)
			AND (@ExcludeTestData = 0 OR c.currency NOT IN (20,27,28))
	
		;WITH DataTmp AS (
			SELECT ROW_NUMBER() OVER (ORDER BY g.BlockedDate DESC) AS RowNum
				, g.CustID
				, g.ProductID
				, g.MaxWinLimit
				, g.BlockedWinAmt
				, g.TotalWinAmt
				, g.BlockedDate
				, g.IsBlocked
				, g.CreatedBy
				, c.UserName
				, c.Currency
				, p.ProductName
				, g.IsNotified
				, g.UnBlockedDate
			FROM dbo.WinLimit_Game g WITH (NOLOCK)
				INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON g.CustId = c.CustId
				INNER JOIN @tempProduct p ON g.Bettype = p.bettype
			WHERE WinlostDate BETWEEN @FromDate AND @Today
				AND (@ExchangeID = 0 OR @ExchangeID = c.currency)
				AND (@ExcludeTestData = 0 OR c.currency NOT IN (20,27,28))
		)
		INSERT INTO #tempResult(RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, BlockedDate, IsBlocked
			, CreatedBy, UserName, Currency, ProductName, IsNotified, ModifiedDate)
		SELECT RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, BlockedDate, IsBlocked
			, CreatedBy, UserName, Currency, ProductName, IsNotified, UnBlockedDate
		FROM DataTmp
		WHERE RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageIndex * @PageSize)
	END
	ELSE
	BEGIN
		SELECT @TotalRow = COUNT(1)
		FROM dbo.WinLimit_Game g WITH (NOLOCK)
			INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON g.CustId = c.CustId
			INNER JOIN @tempProduct p ON g.Bettype = p.bettype
		WHERE WinlostDate BETWEEN @FromDate AND @Today
			AND (@ExchangeID = 0 OR @ExchangeID = c.currency)
			AND (@ExcludeTestData = 0 OR c.currency NOT IN (20,27,28))
			--AND g.WinlostDate = @ToDay
		;WITH DataTmp AS (
			SELECT ROW_NUMBER() OVER (ORDER BY g.BlockedDate DESC) AS RowNum
				, g.CustID
				, g.ProductID
				, g.MaxWinLimit
				, g.BlockedWinAmt
				, g.TotalWinAmt
				, g.BlockedDate
				, g.IsBlocked
				, g.CreatedBy
				, c.UserName
				, c.Currency
				, p.ProductName
				, g.IsNotified
				, g.UnBlockedDate
			FROM dbo.WinLimit_Game g WITH (NOLOCK)
				INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON g.CustId = c.CustId
				INNER JOIN @tempProduct p ON g.Bettype = p.bettype
			WHERE g.CustId = @CustId
				AND WinlostDate BETWEEN @FromDate AND @Today
				AND (@ExchangeID = 0 OR @ExchangeID = c.currency)
				AND (@ExcludeTestData = 0 OR c.currency NOT IN (20,27,28))
		)

		INSERT INTO #tempResult(RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, BlockedDate, IsBlocked
			, CreatedBy, UserName, Currency, ProductName, IsNotified, ModifiedDate)
		SELECT RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, BlockedDate, IsBlocked
			, CreatedBy, UserName, Currency, ProductName, IsNotified, UnBlockedDate
		FROM DataTmp
		WHERE RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageIndex * @PageSize)
	END
		
	SELECT rs.RowNum, rs.CustID, rs.username, e.ExchangeId, e.currency, rs.ProductId, rs.ProductName, rs.IsBlocked
		, rs.MaxWinLimit AS WinLimit
		, rs.BlockedWinAmt AS BlockedWinningAmount
		, rs.TotalWinAmt AS TotalWinningAmount
		, rs.BlockedDate AS BlockedTime
		, rs.CreatedBy AS BlockedBy
		, c.UserName AS BlockedByUserName
		, rs.IsNotified
		, CASE WHEN rs.ModifiedDate IS NULL THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END IsModified
	FROM #tempResult rs
		INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON rs.Currency = e.ExchangeId
		LEFT JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON rs.CreatedBy = c.CustId
	ORDER BY RowNum ASC
	
	--UPDATE	g
	--SET		g.IsNotified = 1
	--FROM	dbo.WinLimit_Game g WITH (ROWLOCK UPDLOCK)
	--		INNER JOIN #tempResult rs
	--		ON g.CustID = rs.CustID AND g.ProductId = rs.ProductId
			
	DROP TABLE #tempResult
END
GO

GRANT EXECUTE ON [dbo].[NAP_WinLimit_GameSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_GameSel] TO [vnteam]
GO