USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_Game_SelBlocked_xtest]    Script Date: 07/10/2015 14:23:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_WinLimit_Game_SelBlocked]
	@UserName		VARCHAR(100)	= '',
	@ExchangeID		INT				= 0,
	@ProductID		TINYINT			= 0,
	@PageIndex		INT				= 0,
	@PageSize		INT				= 50,
	@TotalRow		INT				= 0		OUTPUT
AS
	/*
		Created: Phillip	
		Date: 2015-06-30
		Task: #38608 - Implement function to control Player's Win Limit on specific Product
		
		DB: DBTXN/bodb02
		
		Description: Get All blocked users from Winlimit_Game table.
		
		Revisions:
		
		Parameters Explanation:	
			@UserName	: User Name.
			@ExchangeID : Currency ID.
			@ProductID	: Game ID.
			@PageIndex	: Current page.
			@PageSize	: Page size.
			@TotalRow	: Total Rows.
	*/
BEGIN
	SET NOCOUNT ON;
		
	DECLARE @searchCust BIT
	SET  @searchCust 	= CASE WHEN LEN(@UserName) > 0 THEN 1 ELSE 0 END
	
	--FITER product
	SELECT ProductID
	INTO #tempProduct
	FROM dbo.Products p
	WHERE p.Enabled 		= 1
		AND p.ProductType 	= 2
		AND (@ProductID 	= 0 
			OR ProductID 	= @ProductID)
	
	--FILER cust
	SELECT c.custid
	INTO #tempCust
	FROM CustDB.dbo.Customer c WITH(NOLOCK)
	WHERE @searchCust		= 1
		AND c.username 		LIKE '%' + @UserName + '%'
		AND (
			@ExchangeID 	= 0 
			OR c.currency 	= @ExchangeID
		)
		AND c.roleid		= 1
	
	;WITH CTE_Paging AS (
		SELECT RowNum = DENSE_RANK() OVER ( ORDER BY g.CustID)
			,g.Custid
			,c.username
			,c.currency AS ExchangeId
		FROM dbo.WinLimit_Game g WITH (NOLOCK)
			INNER JOIN #tempProduct p
			ON g.ProductID	= p.ProductID
			LEFT JOIN #tempCust sc 
			ON g.custid		= sc.custid
			INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK)
			ON g.CustID		= c.custid

		WHERE g.IsBlocked 		= 1
			AND (@searchCust 	= 0
				OR (@searchCust = 1 AND sc.custid > 0)
			)
			AND (@ExchangeID 	= 0 
				OR c.currency 	= @ExchangeID
			)
		GROUP BY g.Custid
			,c.username
			,c.currency
	)
	
	SELECT	
		tp.RowNum,
		g.CustID, 
		tp.username,
		tp.ExchangeId,
		g.ProductID,
		g.MaxWinLimit WinLimit, 
		g.TotalWinAmt WinningAmount, 
		g.CreateDate BlockedTime, 
		g.IsBlocked, 
		g.IsNotified
	INTO #tempResult
	FROM dbo.WinLimit_Game g WITH (NOLOCK)
		INNER JOIN #tempProduct p
		ON g.ProductID	= p.ProductID
		INNER JOIN CTE_Paging tp
		ON g.CustID = tp.CustID
		INNER JOIN dbo.exchange e
		ON tp.ExchangeId = e.exchangeid
	WHERE g.IsBlocked = 1
	ORDER BY tp.username, tp.ExchangeId, g.ProductID

	SELECT TOP 1 @TotalRow = MAX(RowNum)
	FROM #tempResult

	SELECT RowNum,
		CustID, 
		username,
		ExchangeId,
		ProductID,
		WinLimit, 
		WinningAmount, 
		BlockedTime, 
		IsBlocked, 
		IsNotified
	FROM #tempResult rs
	WHERE rs.RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageIndex * @PageSize)
	ORDER BY RowNum

	DROP TABLE #tempProduct
	DROP TABLE #tempCust
	DROP TABLE #tempResult

	RETURN;
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_Game_SelBlocked] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_Game_SelBlocked] TO [accteam]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_Game_SelBlocked] TO [vnteam]
GO