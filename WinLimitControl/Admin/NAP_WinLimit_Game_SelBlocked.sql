USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_Game_SelBlocked]    Script Date: 07/07/2015 16:10:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_WinLimit_Game_SelBlocked]
	@UserName		VARCHAR(100)	= '',
	@ExchangeID		INT				= 0,
	@ProductID		TINYINT			= 0,
	@PageIndex		INT				= 0,
	@PageSize		INT				= 50,
	@TotalRow		INT				= 0		OUTPUT
AS
	/*
		Created: Phillip	
		Date: 2015-06-30
		Task: #38608 - Implement function to control Player's Win Limit on specific Product
		
		DB: DBTXN/bodb02
		
		Description: Get All blocked users from Winlimit_Game table.
		
		Revisions:
		
		Parameters Explanation:	
			@UserName	: User Name.
			@ExchangeID : Currency ID.
			@ProductID	: Game ID.
			@PageIndex	: Current page.
			@PageSize	: Page size.
			@TotalRow	: Total Rows.
	*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @ResultTempTable AS TABLE
	(
		RowNum INT,
		CustID INT,
		UserName VARCHAR(50),
		ExchangeID INT,
		ProductID INT,
		WinLimit MONEY,
		WinningAmount MONEY,
		BlockedTime DATETIME,
		IsBlocked BIT,
		IsNotified BIT
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
	FROM	dbo.WinLimit_Game g WITH (NOLOCK)
	WHERE	(@ProductID = 0 OR ProductID = @ProductID) 
			AND IsBlocked = 1
		
	DECLARE @CustIDList AS VARCHAR(MAX)
	SELECT	@CustIDList  = COALESCE(@CustIDList +',' ,'') + CONVERT(VARCHAR(50),CustID )
	FROM	@ResultTempTable
	
	DECLARE @TSQL VARCHAR(8000)
	SELECT	@TSQL = 'SELECT *
				FROM OPENQUERY (DBCUST, 
					''SELECT 
						CustID, 
						Username, 
						currency 
					FROM CustDB.dbo.Customer WITH (NOLOCK) 
					WHERE CustID IN (' + @CustIDList + ')
							AND (' + CONVERT(VARCHAR(10), @ExchangeID) + ' = 0 OR currency=' + CONVERT(VARCHAR(10), @ExchangeID) + ')' +
 							'AND username LIKE ''''' + @UserName + '%' +
					''''''')'
					
	DECLARE @CustomerTempTable AS TABLE
	(
		CustID INT,
		UserName VARCHAR(30),
		ExchangeID INT
	)
	
	INSERT INTO @CustomerTempTable
	EXEC(@TSQL)
	
	UPDATE	@ResultTempTable 
	SET		UserName = c.UserName
			,ExchangeID = c.ExchangeID
	FROM	@ResultTempTable rs
			INNER JOIN @CustomerTempTable c 
			ON rs.CustID = c.CustID
			
	DELETE	@ResultTempTable
	WHERE	UserName IS NULL
	
	SELECT	@TotalRow = COUNT(DISTINCT(CustID)) 
	FROM	@ResultTempTable
	WHERE	UserName LIKE @UserName + '%' 
			AND (@ExchangeID = 0 OR ExchangeID = @ExchangeID) 
	
	SELECT	CustID
			,UserName
			,ExchangeID
			,ProductID
			,WinLimit
			,WinningAmount
			,BlockedTime
			,IsBlocked
			,IsNotified 
	FROM 
		(
			SELECT	DENSE_RANK() OVER(ORDER BY CustID) AS RowNum
					,CustID
					,UserName
					,ExchangeID
					,ProductID
					,WinLimit
					,WinningAmount
					,BlockedTime
					,IsBlocked
					,IsNotified 
			FROM	@ResultTempTable
			WHERE	UserName LIKE @UserName + '%' 
					AND (@ExchangeID = 0 OR ExchangeID = @ExchangeID)
		) AS tbl
	WHERE	RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageIndex * @PageSize)
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_Game_SelBlocked] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_Game_SelBlocked] TO [accteam]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_Game_SelBlocked] TO [vnteam]
GO