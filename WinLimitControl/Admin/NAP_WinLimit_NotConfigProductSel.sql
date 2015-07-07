USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_NotConfigProductSel]    Script Date: 07/07/2015 16:11:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_NotConfigProductSel]
	@ExchangeID int
AS
	/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608
		DB: DBCust/CustDB
		
		Revisions:
		
		Parameters Explanation:	
			@ExchangeID: Currency ID.
	*/
BEGIN
	SET NOCOUNT ON;
	SELECT ProductID, ProductName
	FROM dbo.Products WITH (NOLOCK)
	WHERE ProductType = 2
		AND ProductID NOT IN (SELECT ProductID FROM dbo.WinLimit_GlobalSetting WITH (NOLOCK) WHERE ExchangeID = @ExchangeID)
END

GO

