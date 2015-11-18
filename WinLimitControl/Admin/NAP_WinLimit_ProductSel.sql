USE [bodb02]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_ProductSel]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[NAP_WinLimit_ProductSel]
GO

USE [bodb02]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_ProductSel]
	@ExcludeUsed BIT = 0
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
		FROM	dbo.f_Winlimit_GetProductSetting()
		WHERE	IsActive_Company = 1 -- Game only
	END
	ELSE
	BEGIN
		DECLARE @TotalExchange INT
		SELECT	@TotalExchange = COUNT(1)
		FROM	dbo.exchange WITH (NOLOCK)
		WHERE	currency NOT IN('UUS', 'H', 'C')
		
		SELECT		p.ProductID
					,p.ProductName
		FROM		dbo.f_Winlimit_GetProductSetting() p
					INNER JOIN dbo.WinLimit_GlobalSetting s WITH (NOLOCK)
					ON p.ProductID = s.ProductID
		WHERE		p.IsActive_Company = 1 -- Game only
		GROUP BY	p.ProductID
					,p.ProductName
		HAVING		COUNT(DISTINCT(ExchangeID)) <>  @TotalExchange
		  
	END
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_ProductSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_ProductSel] TO [vnteam]
GO