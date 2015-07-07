USE [CustDB]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_GreaterWinLimitPlayerSel]    Script Date: 07/07/2015 16:09:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_GreaterWinLimitPlayerSel]
	@ExchangeID		INT,
	@ProductID		INT,
	@MaxWinLimit	MONEY
AS
	/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608
		DB: DBCust/CustDB
		
		Revisions:
		
		Parameters Explanation:	
			@ExchangeID: Currency ID.
			@ProductID: Product ID.
			@MaxWinLimit: Max Win Limit amount.
	*/
BEGIN
	SET NOCOUNT ON;
	SELECT cs.CustID, c.username, cs.ProductID,cs.MaxWinLimit AS CurrentWinLimit, @MaxWinLimit AS NewWinLimit
	FROM dbo.WinLimit_CustSetting cs WITH (NOLOCK)
		LEFT OUTER JOIN dbo.Customer c WITH (NOLOCK) ON cs.CustID = c.custid
	WHERE c.currency = @ExchangeID
		AND cs.ProductID = @ProductID
		AND cs.MaxWinLimit > @MaxWinLimit
END
GO

