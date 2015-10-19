USE [CustDB]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustSettingSel]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[NAP_WinLimit_CustSettingSel]
GO

USE [CustDB]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustSettingSel]    Script Date: 07/07/2015 16:09:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingSel]
	@UserName	VARCHAR(100)	= '',
	@ExchangeID INT				= 0,
	@ProductID	TINYINT 		= 0,
	@PageIndex	INT 			= 1,
	@PageSize	INT 			= 50,
	@TotalRow	INT 			= 0		OUTPUT
AS
	/*
		Created: Phillip	
		Date: 2015-06-30
		Task: #38608 - Implement function to control Player's Win Limit on specific Product
		
		DB: DBCUST/CustDB
		
		Revisions:
		
		Parameters Explanation:	
			@UserName	: User Name.
			@ExchangeID : Currency ID.
			@ProductID	: Game ID.
			@PageIndex	: Page Index.
			@PageSize	: Page Size.
			@TotalRow	: Total Row.
	*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @TVP_CustSetting TABLE
	(
		RowNum INT,
		CustID INT,
		UserName VARCHAR(30),
		ExchangeID INT,
		ProductID TINYINT,
		PlayerWinLimit MONEY,
		CurrencyWinLimit MONEY
	)
	
	INSERT INTO @TVP_CustSetting
	SELECT	DENSE_RANK() OVER(ORDER BY cs.CustID) AS RowNum
			,cs.CustID
			,c.username
			,c.currency ExchangeID
			,cs.ProductID
			,cs.MaxWinLimit PlayerWinLimit
			,wg.MaxWinLimit CurrencyWinLimit
	FROM	dbo.WinLimit_CustSetting cs WITH (NOLOCK)
			INNER JOIN Customer c WITH (NOLOCK) 
			ON cs.CustID = c.custid
			INNER JOIN DBPRO.bodb02.dbo.WinLimit_GlobalSetting wg
			ON cs.ProductID = wg.ProductID AND c.currency = wg.ExchangeID
	WHERE	c.username LIKE '%' + @UserName + '%'
			AND (@ExchangeID = 0 OR c.currency = @ExchangeID)
			AND (@ProductID = 0 OR cs.ProductID = @ProductID)
		
	SELECT	@TotalRow = ISNULL(MAX(RowNum), 0) 
	FROM	@TVP_CustSetting
	
	SELECT	CustID
			,UserName
			,ExchangeID
			,ProductID
			,PlayerWinLimit 
			,CurrencyWinLimit
	FROM	@TVP_CustSetting
	WHERE	RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageIndex * @PageSize)
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingSel] TO [accteam]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustSettingSel] TO [vnteam]
GO