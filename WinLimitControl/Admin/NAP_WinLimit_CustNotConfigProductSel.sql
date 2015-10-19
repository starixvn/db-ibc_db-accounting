USE [bodb02]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustNotConfigProductSel]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[NAP_WinLimit_CustNotConfigProductSel]
GO

USE [CustDB]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustNotConfigProductSel]    Script Date: 07/07/2015 16:09:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_CustNotConfigProductSel]
	@CustId		VARCHAR(100)	= ''
AS
	/*
		Created: Phillip	
		Date: 2015-10-15
		Task: #38608 - Implement function to control Player's Win Limit on specific Product

		DB: DBCust/CustDB
		
		Revisions:
		
		Parameters Explanation:	
			@CustId	: Player ID.
	*/
BEGIN
	SET NOCOUNT ON;
	SELECT	c.username,
			e.exchangeid,
			e.currency,
			p.ProductID,
			p.ProductName,
			cs.MaxWinLimit,
			wg.MaxWinLimit CurrencyWinLimit
	FROM	dbo.Customer c WITH (NOLOCK) 
			INNER JOIN dbo.exchange e WITH (NOLOCK)
			ON c.currency = e.exchangeid
			RIGHT JOIN DBPRO.bodb02.dbo.Products p WITH (NOLOCK)
			ON p.ProductType = 2
			LEFT JOIN dbo.WinLimit_CustSetting cs WITH (NOLOCK)
			ON cs.CustID = c.CustId AND cs.ProductID = p.ProductID
			INNER JOIN DBPRO.bodb02.dbo.WinLimit_GlobalSetting wg WITH (NOLOCK)
			ON wg.ProductID = p.ProductID AND wg.ExchangeID = e.exchangeid
	WHERE	c.CustId = @CustId
			AND cs.MaxWinLimit IS NULL
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustNotConfigProductSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustNotConfigProductSel] TO [accteam]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustNotConfigProductSel] TO [vnteam]
GO