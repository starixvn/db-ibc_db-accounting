USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CurrencySettingSel]    Script Date: 07/07/2015 16:10:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingSel]
	@ExchangeID		INT		= 0,
	@ProductID		TINYINT = 0
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
	DECLARE @ResultTbl TABLE
	(
		RowNum int,
		ExchangeID int, 
		ProductID int, 
		MaxWinLimit money
	)
	
	INSERT INTO @ResultTbl
	SELECT	DENSE_RANK() OVER(ORDER BY ExchangeID) AS RowNum
			, ExchangeID
			, ProductID
			, MaxWinLimit
	FROM	WinLimit_GlobalSetting WITH(NOLOCK)
	WHERE	(@ProductID = 0 OR ProductID = @ProductID)
			AND (@ExchangeID = 0 OR ExchangeID = @ExchangeID)
		
	SELECT		ExchangeID
				, ProductID
				, MaxWinLimit
	FROM		@ResultTbl
	ORDER BY	ExchangeID
				, ProductID
	
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySettingSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySettingSel] TO [accteam]
GO