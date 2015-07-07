USE [CustDB]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustSettingListSel]    Script Date: 07/07/2015 16:09:32 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingListSel]
	@CustID int
AS
	/*
		Created: Phillip	
		Date: 2015-06-30
		Task: #38608
		DB: DBCust/CustDB
		
		Revisions:
		
		Parameters Explanation:	
			@UserName : User Name.
			@ExchangeID : Currency ID.
			@ProductID: Game ID.
	*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @WLGlobalSettingTbl AS TABLE
	(
		ExchangeID int,
		ProductID int,
		MaxWinLimit money
	)
	
	DECLARE @ResultTbl AS TABLE
	(
		ProductID int,
		PlayerWinLimit money,
		CurrencyID int,
		CurrencyWinLimit money
	)
	
	INSERT INTO @ResultTbl
	SELECT cs.ProductID, cs.MaxWinLimit PlayerWinLimit, c.currency, NULL
	FROM (dbo.WinLimit_CustSetting cs WITH (NOLOCK)
		INNER JOIN dbo.Customer c WITH (NOLOCK)
		ON cs.CustID = c.custid)
	WHERE cs.CustID = @CustID
	
	DECLARE @CurrencyIDList VARCHAR(500)
	SELECT @CurrencyIDList = COALESCE (@CurrencyIDList + ',', '') + CONVERT (VARCHAR(10), CurrencyID)
	FROM @ResultTbl
	
	DECLARE @TSQL VARCHAR(4000)
	SET @TSQL = 'SELECT * FROM OPENQUERY(DBPRO, ''SELECT ExchangeID, ProductID, MaxWinLimit FROM DBPRO.bodb02.dbo.WinLimit_GlobalSetting WITH (NOLOCK) WHERE ExchangeID IN (' + @CurrencyIDList + ')'')'
	
	INSERT INTO @WLGlobalSettingTbl
	EXEC (@TSQL)
	
	SELECT rs.ProductID, rs.PlayerWinLimit, gs.MaxWinLimit CurrencyMaxWinLimit
	FROM @ResultTbl rs
		INNER JOIN @WLGlobalSettingTbl gs
		ON rs.CurrencyID = gs.ExchangeID AND rs.ProductID = gs.ProductID
END
GO

