USE [bodb02]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CurrencySettingSel]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingSel]
GO

USE [bodb02]

GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingSel]
	@ExchangeID			INT		= 0,
	@ProductID			TINYINT,
	@ExcludeTestData	BIT = 1
AS
	/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608 - Implement function to control Player's Win Limit on specific Product
		
		DB: DBTXN/bodb02
		
		Revisions:
		
		Parameters Explanation:	
			@ExchangeID	: Currency ID
			@ProductID	: Product ID
	*/
BEGIN
	SET NOCOUNT ON;
	SELECT	c.exchangeid as CurrencyID
			, currency as CurrencyName
			, Code as CurrencyCode
			, wg.MaxWinLimit
	FROM	CustDB.dbo.exchange c WITH (NOLOCK)
			LEFT JOIN dbo.WinLimit_GlobalSetting wg WITH (NOLOCK)
			ON c.exchangeid = wg.ExchangeID AND (wg.ProductID IS NULL OR wg.ProductID = @ProductID)
	WHERE	(@ExcludeTestData = 0 OR c.currency NOT IN ('UUS', 'H', 'C'))
			AND (@ExchangeID = 0 OR c.exchangeid = @ExchangeID)
END

GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySettingSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CurrencySettingSel] TO [vnteam]
GO