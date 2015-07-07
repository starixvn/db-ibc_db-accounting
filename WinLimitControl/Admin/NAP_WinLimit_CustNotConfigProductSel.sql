USE [CustDB]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustNotConfigProductSel]    Script Date: 07/07/2015 16:09:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_CustNotConfigProductSel]
	@UserName varchar(100) = '',
	@ErrCode int = 0 output,
	@ErrMsg	varchar(100)='' output
AS
	/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608
		DB: DBCust/CustDB
		
		Revisions:
		
		Parameters Explanation:	
			@UserName : User Name.
	*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @CustID int
	DECLARE @ExchangeID int
	DECLARE @ExchangeName varchar(50)
	DECLARE @PlayerMaxWinLimit money
	SET @UserName = LTRIM(RTRIM(@UserName))
	
	SELECT @CustID = custid, @ExchangeID = c.currency, @ExchangeName = e.Code + ' (' + e.currency + ')'
	FROM dbo.Customer c WITH (NOLOCK)
		INNER JOIN dbo.exchange e WITH (NOLOCK) ON c.currency = e.exchangeid
	WHERE username = @UserName 
		AND roleid = 1 -- Search member level only.
	
	-- If CustID is NULL => Invalid UserName
	-- Else => Valid UserName
	IF @CustID IS NULL
	BEGIN
		SET @ErrCode = 3
		SET @ErrMsg = 'Invalid username.'
		RETURN;
	END
	
	DECLARE @CurrencySettingTable AS TABLE
	(
		ExchangeID INT,
		ProductID INT,
		MaxWinLimit MONEY
	)
	
	DECLARE @TSQL varchar(4000)
	SET @TSQL = 'SELECT * FROM OPENQUERY(DBTXN, ''SELECT ExchangeID, ProductID, MaxWinLimit FROM DBTXN.bodb02.dbo.WinLimit_GlobalSetting WITH (NOLOCK) WHERE ExchangeID = ' + CONVERT(varchar(10), @ExchangeID) + ''')'
	
	SELECT @CustID CustID, @ExchangeID CurrencyID, @ExchangeName CurrencyName
	INSERT INTO @CurrencySettingTable
	EXEC(@TSQL)
	
	IF NOT EXISTS (SELECT 1 FROM @CurrencySettingTable)
	BEGIN
		SET @ErrCode = 4
		SET @ErrMsg = 'Please set Currency Win Limit for currency of this Username.'
		RETURN;
	END
	
	SELECT ProductID, CustID, PlayerWinLimit, CurrencyMaxWinLimit
	FROM
		(	SELECT p.ProductID, @CustID CustID, cs.MaxWinLimit PlayerWinLimit, gs.MaxWinLimit CurrencyMaxWinLimit
			FROM bodb02.dbo.Products p WITH (NOLOCK)
				LEFT OUTER JOIN dbo.WinLimit_CustSetting cs WITH (NOLOCK)
				ON  p.ProductID = cs.ProductID and cs.CustID = @CustID
				LEFT OUTER JOIN @CurrencySettingTable gs
				ON p.ProductID = gs.ProductID
			WHERE p.ProductType = 2 AND gs.MaxWinLimit IS NOT NULL
		) cs_p
	WHERE
		cs_p.PlayerWinLimit IS NULL
END
GO

