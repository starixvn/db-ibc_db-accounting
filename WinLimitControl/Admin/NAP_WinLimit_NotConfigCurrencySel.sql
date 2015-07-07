USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_NotConfigCurrencySel]    Script Date: 07/07/2015 16:11:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_NotConfigCurrencySel]
	@ProductID int
AS
	/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608
		DB: DBCust/CustDB
		
		Revisions:
		
		Parameters Explanation:	
			@ProductID: Product ID.
	*/
BEGIN
	SET NOCOUNT ON;
	
	SELECT exchangeid, Code + ' (' + currency + ')' as ExchangeName
	FROM exchange WITH (NOLOCK)
	WHERE currency NOT IN('UUS', 'H', 'C')
		AND exchangeid NOT IN(SELECT ExchangeID FROM bodb02.dbo.WinLimit_GlobalSetting WITH (NOLOCK) WHERE ProductID = @ProductID)
END
GO

