USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CurrencySel]    Script Date: 07/07/2015 16:08:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_WinLimit_CurrencySel]
	@ExcludeUsed	BIT		= 0
AS
	/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608 - Implement function to control Player's Win Limit on specific Product

		DB: DBTXN/bodb02
		
		Revisions:
		
		Parameters Explanation:	
			@ExcludeUsed: Exclude used Currency.
	*/
BEGIN
	SET NOCOUNT ON;
	IF @ExcludeUsed = 0
	BEGIN
		SELECT		ExchangeID
					,Code + ' (' + currency + ')' AS ExchangeName
		FROM		dbo.exchange WITH (NOLOCK)
		WHERE		currency NOT IN('UUS', 'H', 'C')
		ORDER BY	ExchangeName
	END
	ELSE
	BEGIN
		DECLARE		@TotalProduct INT
		
		SELECT		@TotalProduct = COUNT(1)
		FROM		dbo.Products WITH (NOLOCK)
		WHERE		ProductType = 2
		
		SELECT		e.exchangeid
					,e.Code + ' (' + e.currency + ')' AS ExchangeName
		FROM		dbo.exchange e WITH (NOLOCK)
					LEFT OUTER JOIN dbo.WinLimit_GlobalSetting gs WITH (NOLOCK)
					ON e.exchangeid = gs.ExchangeID
		GROUP BY	e.exchangeid, e.Code, e.currency
		HAVING		COUNT(gs.ProductID) <> @TotalProduct
	END
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySel] TO [accteam]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CurrencySel] TO [vnteam]
GO