USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_Game_SelBlocked]    Script Date: 07/07/2015 16:10:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_Game_SelBlocked]
	@UserName varchar(100) = '',
	@PageIndex int = 0,
	@PageSize int = 50,
	@TotalRow int = 0 output,
	@ExchangeID int = 0,
	@ProductID	int = 0
AS
	/*
		Created: Phillip	
		Date: 2015-06-30
		Task: #38608
		DB: DBTXN/bodb02
		Description: Get All blocked users from Winlimit_Game table.
		Revisions:
		
		Parameters Explanation:	
			@UserName : User Name.
			@ExchangeID : Currency ID.
			@ProductID: Game ID.
			@PageIndex: Current page.
			@PageSize: Page size.
			@TotalRow: Total Rows.
	*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @ResultTempTable AS TABLE
	(
		RowNum int,
		CustID int,
		UserName varchar(50),
		ExchangeID int,
		ProductID int,
		WinLimit money,
		WinningAmount money,
		BlockedTime datetime,
		IsBlocked bit,
		IsNotified bit
	)
	
	INSERT INTO @ResultTempTable
	SELECT	0,
			g.CustID, 
			NULL,
			NULL,
			g.ProductID,
			g.MaxWinLimit WinLimit, 
			g.TotalWinAmt WinningAmount, 
			g.CreateDate BlockedTime, 
			g.IsBlocked, 
			g.IsNotified
	FROM dbo.WinLimit_Game g WITH (NOLOCK)
	WHERE (@ProductID = 0 OR ProductID = @ProductID) AND IsBlocked = 1
		
	DECLARE @CustIDList AS varchar(MAX)
	SELECT @CustIDList  = COALESCE(@CustIDList +',' ,'') + CONVERT(VARCHAR(50),CustID )
	FROM @ResultTempTable
	
	DECLARE @TSQL VARCHAR(8000)
	SET @TSQL = 'SELECT * 
				FROM OPENQUERY (DBTRANS, 
					''SELECT 
						CustID, 
						Username, 
						currency 
					FROM CustDB.dbo.Customer WITH (NOLOCK) 
					WHERE CustID IN (' + @CustIDList + ')'')'
	
	DECLARE @CustomerTempTable AS TABLE
	(
		CustID int,
		UserName varchar(30),
		ExchangeID int
	)
	
	INSERT INTO @CustomerTempTable
	EXEC(@TSQL)
	
	UPDATE @ResultTempTable 
	SET UserName = c.UserName, ExchangeID = c.ExchangeID
	FROM @ResultTempTable rs
		INNER JOIN @CustomerTempTable c ON rs.CustID = c.CustID
		
	SELECT @TotalRow = COUNT(DISTINCT(CustID)) FROM @ResultTempTable
	WHERE UserName LIKE @UserName + '%' 
		AND (@ExchangeID = 0 OR ExchangeID = @ExchangeID) 
	
	
	SELECT CustID, UserName, ExchangeID, ProductID, WinLimit, WinningAmount, BlockedTime, IsBlocked, IsNotified 
	FROM 
		(
		SELECT DENSE_RANK() OVER(ORDER BY CustID) AS RowNum, CustID, UserName, ExchangeID, ProductID, WinLimit, WinningAmount, BlockedTime, IsBlocked, IsNotified 
		FROM @ResultTempTable
		WHERE UserName LIKE @UserName + '%' 
			AND (@ExchangeID = 0 OR ExchangeID = @ExchangeID)
		) AS tbl
	WHERE
		RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageIndex * @PageSize)
END


GO

