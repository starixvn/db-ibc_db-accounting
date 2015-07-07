USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_ProductSel]    Script Date: 07/07/2015 16:11:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_ProductSel]
	@ExcludeUsed bit = 0
AS
	/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608
		DB: DBCust/CustDB
		
		Revisions:
		
		Parameters Explanation:	
			@ExcludeUsed:
				0: Get all game.
				1: Get game not config yet.
	*/
BEGIN
	SET NOCOUNT ON;
	IF @ExcludeUsed = 0
	BEGIN
		SELECT ProductID, ProductName
		FROM dbo.Products WITH (NOLOCK)
		WHERE ProductType = 2 -- Game only
	END
	ELSE
	BEGIN
		DECLARE @GlobalSettingTemp TABLE
		(
			ProductID int,
			ExchangeIDNum int
		)
		
		DECLARE @TotalExchange int
		SELECT @TotalExchange = COUNT(1)
		FROM CustDB.dbo.exchange WITH (NOLOCK)
		WHERE currency NOT IN('UUS', 'H', 'C')
		
		INSERT INTO @GlobalSettingTemp
		SELECT ProductID, COUNT(DISTINCT(ExchangeID)) ExchangeIDNum 
		FROM dbo.WinLimit_GlobalSetting WITH (NOLOCK)
		GROUP BY ProductID
	
		SELECT ProductID, ProductName
		FROM dbo.Products WITH (NOLOCK)
		WHERE ProductType = 2 -- Game only
			AND ProductID NOT IN (SELECT ProductID FROM @GlobalSettingTemp WHERE ExchangeIDNum = @TotalExchange)
	END
END

GO

