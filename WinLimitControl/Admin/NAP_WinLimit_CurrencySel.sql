USE [CustDB]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CurrencySel]    Script Date: 07/07/2015 16:08:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySel]
	@ExcludeUsed bit = 0
AS
	/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608
		DB: DBCust/CustDB
		
		Revisions:
		
		Parameters Explanation:	
	*/
BEGIN
	SET NOCOUNT ON;
	
	IF @ExcludeUsed = 0
	BEGIN
		SELECT ExchangeID, Code + ' (' + currency + ')' as ExchangeName
		FROM dbo.exchange WITH (NOLOCK)
		WHERE currency NOT IN('UUS', 'H', 'C')
		ORDER BY ExchangeName
	END
	ELSE
	BEGIN
		DECLARE @GlobalSettingTemp TABLE
		(
			ExchangeID int,
			ProductIDNum int
		)
		
		DECLARE @TotalProduct int
		SELECT @TotalProduct = COUNT(1)
		FROM bodb02.dbo.Products WITH (NOLOCK)
		WHERE ProductType = 2
		
		INSERT INTO @GlobalSettingTemp
		SELECT ExchangeID, COUNT(ProductID) ProductIDNum FROM bodb02.dbo.WinLimit_GlobalSetting WITH (NOLOCK) GROUP BY ExchangeID
		
		SELECT ExchangeID, Code + ' (' + currency + ')' as ExchangeName
		FROM dbo.exchange WITH (NOLOCK)
		WHERE currency NOT IN('UUS', 'H', 'C')
			AND ExchangeID NOT IN(SELECT ExchangeID
			FROM @GlobalSettingTemp gst
			WHERE gst.ProductIDNum = @TotalProduct
			)
		ORDER BY ExchangeName
	END
END
GO

