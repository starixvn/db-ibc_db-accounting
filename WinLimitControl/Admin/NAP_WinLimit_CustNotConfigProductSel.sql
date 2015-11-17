USE [CustDB]
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
	@CustName			VARCHAR(100)	= '',
	@ExcludeTestData	BIT				= 1,
	@ErrCode			INT				= 0		OUTPUT,
	@ErrMsg				VARCHAR(100)	= ''	OUTPUT
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
	DECLARE @ProductSetting TABLE(ProductId TINYINT, ProductName VARCHAR(50), BetType SMALLINT, IsActive_Company BIT)
	INSERT INTO @ProductSetting
	SELECT ProductId, ProductName, BetType, IsActive_Company
	FROM OPENQUERY(DBTXN,'SELECT ProductId, ProductName, BetType, IsActive_Company FROM bodb02.dbo.f_Winlimit_GetProductSetting()')

	DECLARE @ROLEID int = 1, -- Search member level only.
			@CustID int,
			@CurrencyID int,
			@CurrencyName nvarchar(50)
	
	-- check custname is valid or not.
	SELECT	@CustID = c.custid, @CurrencyID = e.exchangeid, @CurrencyName = e.currency
	FROM	dbo.Customer c WITH (NOLOCK)
			INNER JOIN dbo.exchange e WITH (NOLOCK)
			ON c.currency = e.exchangeid AND (@ExcludeTestData = 0 OR e.currency NOT IN ('UUS', 'H', 'C'))
	WHERE	c.username = @CustName 
			AND c.roleid = @ROLEID 
			
	IF @CustID IS NULL
	BEGIN
		SELECT	@ErrCode = 3
		SET NOCOUNT OFF;
		RETURN;
	END
	
	-- check Currency Win Limit is set or not
	DECLARE @hasCurrencySetting int
	SELECT	@hasCurrencySetting = COUNT(1)
	FROM	DBPRO.bodb02.dbo.WinLimit_GlobalSetting wg WITH (NOLOCK)
	WHERE	wg.ExchangeID = @CurrencyID
	IF @hasCurrencySetting = 0
	BEGIN
		SELECT	@ErrCode = 4,
				@ErrMsg = @CurrencyName
		SET NOCOUNT OFF;
		RETURN;
	END
	
	SELECT	c.custid,
			c.username,
			e.exchangeid,
			e.currency,
			p.ProductID,
			p.ProductName,
			cs.MaxWinLimit,
			wg.MaxWinLimit CurrencyWinLimit
	FROM	dbo.Customer c WITH (NOLOCK) 
			INNER JOIN dbo.exchange e WITH (NOLOCK)
			ON c.currency = e.exchangeid AND (@ExcludeTestData = 0 OR e.currency NOT IN ('UUS', 'H', 'C'))
			RIGHT JOIN @ProductSetting p
			ON p.IsActive_Company = 1
			LEFT JOIN dbo.WinLimit_CustSetting cs WITH (NOLOCK)
			ON cs.CustID = c.CustId AND cs.ProductID = p.ProductID
			INNER JOIN DBPRO.bodb02.dbo.WinLimit_GlobalSetting wg WITH (NOLOCK)
			ON wg.ProductID = p.ProductID AND wg.ExchangeID = e.exchangeid
	WHERE	c.custid = @CustID
			AND cs.MaxWinLimit IS NULL
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustNotConfigProductSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustNotConfigProductSel] TO [accteam]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustNotConfigProductSel] TO [vnteam]
GO