USE [bodb02]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_UnblockedMemberSel]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[NAP_WinLimit_UnblockedMemberSel]
GO

USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_UnblockedMemberSel]
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
	
	SELECT	RowNum = ROW_NUMBER() OVER ( ORDER BY tbl.UnblockedTime),
			CustID,
			username,
			ExchangeID,
			currency,
			ProductID,
			ProductName,
			WinLimit,
			TodayWinningAmount,
			SUM(CreditTodayWinningAmount) CreditTodayWinningAmount,
			SUM(DebitTodayWinningAmount) DebitTodayWinningAmount,
			TotalWinningAmount,
			BlockedTime,
			UnblockedTime,
			IsBlocked,
			UnblockedBy
	INTO	#tempResult
	FROM	(
			SELECT	g.CustID,
					c.username,
					e.ExchangeID,
					e.currency,
					p.ProductID,
					p.ProductName,
					g.MaxWinLimit WinLimit,
					NULL TodayWinningAmount,
					wc.Winlost CreditTodayWinningAmount,
					wd.Winlost DebitTodayWinningAmount,
					CASE WHEN g.WinlostDate BETWEEN @Today AND @Tomorrow THEN g.TotalWinAmt ELSE 0 END TotalWinningAmount,
					g.BlockedDate BlockedTime, 
					g.UnblockedDate UnblockedTime, 
					g.IsBlocked,
					g.ModifiedBy UnblockedBy
			FROM	dbo.WinLimit_Game g WITH (NOLOCK)
					INNER JOIN #tempCust c
					ON g.CustId = c.CustID
					INNER JOIN #tempProduct p
					ON g.ProductID = p.ProductID
					INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK)
					ON c.currency = e.exchangeid
					LEFT JOIN dbo.WinLimit_CreditGame wc WITH (NOLOCK)
					ON g.custid = wc.custid AND g.bettype = wc.Bettype AND wc.Winlostdate BETWEEN @Today AND @Tomorrow
					LEFT JOIN dbo.WinLimit_DebitGame wd WITH (NOLOCK)
					ON g.custid = wd.custid AND g.bettype = wd.Bettype AND wd.Winlostdate BETWEEN @Today AND @Tomorrow
			WHERE g.IsBlocked = 0
			) tbl
	GROUP BY	CustID,
				username,
				ExchangeID,
				currency,
				ProductID,
				ProductName,
				WinLimit,
				TodayWinningAmount,
				TotalWinningAmount,
				BlockedTime,
				UnblockedTime,
				IsBlocked,
				UnblockedBy
	ORDER BY tbl.UnblockedTime
	
	UPDATE	#tempResult
	SET		TodayWinningAmount = TotalWinningAmount + CreditTodayWinningAmount - DebitTodayWinningAmount
	
	SELECT TOP 1 @TotalRow = MAX(RowNum)
	FROM #tempResult
	
	SELECT		rs.*,
				ad.username UnblockedByUserName
	FROM		#tempResult rs
				LEFT JOIN #tempAdmin ad
				ON rs.UnblockedBy = ad.custid
	WHERE		rs.RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageIndex * @PageSize)
	ORDER BY	RowNum	
	
	DROP TABLE #tempProduct
	DROP TABLE #tempAdmin
	DROP TABLE #tempCust
	DROP TABLE #tempResult
	RETURN;
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_UnblockedMemberSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_UnblockedMemberSel] TO [accteam]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_UnblockedMemberSel] TO [vnteam]
GO