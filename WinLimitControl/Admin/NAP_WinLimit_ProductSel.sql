USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_ProductSel]    Script Date: 07/07/2015 17:03:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_WinLimit_ProductSel]
	@ExcludeUsed bit = 0
AS
	/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608 - Implement function to control Player's Win Limit on specific Product
		
		DB: DBTXN/bodb02
		
		Revisions:
		
		Parameters Explanation:	
			@ExcludeUsed:
				= 0: Get all game.
				= 1: Get game not config yet.
	*/
BEGIN
	SET NOCOUNT ON;
	IF @ExcludeUsed = 0
	BEGIN
		SELECT	ProductID
				,ProductName
		FROM	dbo.Products WITH (NOLOCK)
		WHERE	ProductType = 2 -- Game only
	END
	ELSE
	BEGIN
		DECLARE @TotalExchange INT
		SELECT	@TotalExchange = COUNT(1)
		FROM	dbo.exchange WITH (NOLOCK)
		WHERE	currency NOT IN('UUS', 'H', 'C')
		
		SELECT		p.ProductID
					,p.ProductName
		FROM		dbo.Products p WITH (NOLOCK)
					INNER JOIN dbo.WinLimit_GlobalSetting s WITH (NOLOCK)
					ON p.ProductID = s.ProductID
		WHERE		p.ProductType = 2 -- Game only
		GROUP BY	p.ProductID
					,p.ProductName
		HAVING		COUNT(DISTINCT(ExchangeID)) <>  @TotalExchange
		  
	END
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_ProductSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_ProductSel] TO [accteam]
GO