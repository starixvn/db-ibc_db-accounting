USE [bodb02]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_BlockedMemberSel]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[NAP_WinLimit_BlockedMemberSel]
GO

USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_BlockedMemberSel]
	@UserName		VARCHAR(100)	= '',
	@ExchangeID		INT				= 0,
	@ProductID		TINYINT			= 0,
	@PageIndex		INT				= 1,
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
			@IsBlocked	: Is blocked player.
			@ProductID	: Game ID.
			@PageIndex	: Current page.
			@PageSize	: Page size.
			@TotalRow	: Total Rows.
	*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Today		DATE,
			@Tomorrow	DATE
	
	SELECT @ToDay = CONVERT(DATE, GETDATE())
	SELECT @Tomorrow = DATEADD(DAY, 1, CONVERT(DATE, GETDATE(), 120))	
	SET @UserName = ISNULL(@UserName, '')
	SELECT ProductID, ProductName
	INTO #tempProduct
	FROM dbo.f_Winlimit_GetProductSetting() p
	WHERE p.IsActive_Company= 1
		AND (@ProductID = 0 OR ProductID = @ProductID)
	
	SELECT custid, username
	INTO #tempAdmin
	FROM CustDB.dbo.Customer WITH (NOLOCK)
	WHERE roleid > 4
		AND (custid IN (SELECT DISTINCT(CreatedBy) FROM dbo.WinLimit_Game WITH (NOLOCK) WHERE CreatedBy IS NOT NULL)
			OR custid IN (SELECT DISTINCT(ModifiedBy) FROM dbo.WinLimit_Game WITH (NOLOCK) WHERE ModifiedBy IS NOT NULL))
	
	SELECT c.custid, c.username, c.currency
	INTO #tempCust
	FROM CustDB.dbo.Customer c WITH(NOLOCK)
	WHERE  (@UserName ='' OR c.username = @UserName)
		AND (
			@ExchangeID 	= 0 
			OR c.currency 	= @ExchangeID
		)
		AND c.roleid		= 1
		AND c.CustID IN (SELECT CustID FROM dbo.WinLimit_Game WITH (NOLOCK))
		
	SELECT	RowNum = ROW_NUMBER() OVER ( ORDER BY g.BlockedDate),
			g.CustID,
			c.username,
			e.ExchangeID,
			e.currency,
			p.ProductID,
			p.ProductName,
			g.MaxWinLimit WinLimit,
			g.BlockedWinAmt BlockedWinningAmount,
			g.TotalWinAmt TotalWinningAmount, 
			g.BlockedDate BlockedTime, 
			g.IsBlocked,
			g.CreatedBy BlockedBy
	INTO	#tempResult
	FROM	dbo.WinLimit_Game g WITH (NOLOCK)
			INNER JOIN #tempCust c
			ON g.CustId = c.CustID
			INNER JOIN #tempProduct p
			ON g.ProductID = p.ProductID
			INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK)
			ON c.currency = e.exchangeid
	WHERE g.IsBlocked = 1
	ORDER BY g.BlockedDate
	
	SELECT TOP 1 @TotalRow = MAX(RowNum)
	FROM #tempResult
	
	SELECT		rs.*,
				ad.username BlockedByUserName
	FROM		#tempResult rs
				LEFT JOIN #tempAdmin ad
				ON rs.BlockedBy = ad.custid
	WHERE		rs.RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageIndex * @PageSize)
	ORDER BY	RowNum	
	
	DROP TABLE #tempProduct
	DROP TABLE #tempAdmin
	DROP TABLE #tempCust
	DROP TABLE #tempResult
	RETURN;
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_BlockedMemberSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_BlockedMemberSel] TO [accteam]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_BlockedMemberSel] TO [vnteam]
GO