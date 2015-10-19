USE [bodb02]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_NotConfigProductSel]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[NAP_WinLimit_NotConfigProductSel]
GO

USE [bodb02]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_NotConfigProductSel]
	@ExchangeID INT
AS
	/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608 - Implement function to control Player's Win Limit on specific Product
		
		DB: DBTXN/bodb02
		
		Revisions:
		
		Parameters Explanation:	
			@ExchangeID: Currency ID.
	*/
BEGIN
	SET NOCOUNT ON;
	SELECT	ProductID
			,ProductName
	FROM	dbo.Products WITH (NOLOCK)
	WHERE	ProductType = 2
			AND ProductID NOT IN 
			(
				SELECT ProductID 
				FROM dbo.WinLimit_GlobalSetting WITH (NOLOCK) 
				WHERE ExchangeID = @ExchangeID
			)
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_NotConfigProductSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_NotConfigProductSel] TO [accteam]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_NotConfigProductSel] TO [vnteam]
GO