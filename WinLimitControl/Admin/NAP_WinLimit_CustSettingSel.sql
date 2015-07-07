USE [CustDB]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustSettingSel]    Script Date: 07/07/2015 16:09:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingSel]
	@UserName varchar(100) = '',
	@ExchangeID int = 0,
	@ProductID	int = 0,
	@PageIndex int = 1,
	@PageSize int = 50,
	@TotalRow int = 0 output
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
	DECLARE @ResultTable TABLE
	(
		RowNum int,
		CustID int,
		UserName varchar(30),
		ExchangeID int,
		ProductID tinyint,
		MaxWinLimit money
	)
	
	INSERT INTO @ResultTable
	SELECT DENSE_RANK() OVER(ORDER BY cs.CustID) AS RowNum, cs.CustID, c.username, c.currency ExchangeID, ProductID, cs.MaxWinLimit
	FROM WinLimit_CustSetting cs WITH (NOLOCK)
		INNER JOIN Customer c WITH (NOLOCK) ON cs.CustID = c.custid
	WHERE c.username LIKE '%' + @UserName + '%'
		AND (@ExchangeID = 0 OR c.currency = @ExchangeID)
		AND (@ProductID = 0 OR cs.ProductID = @ProductID)
		
	SELECT @TotalRow = ISNULL(MAX(RowNum), 0) FROM @ResultTable
	
	SELECT CustID, UserName, ExchangeID, ProductID, MaxWinLimit 
	FROM @ResultTable
	WHERE RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageIndex * @PageSize)
END


GO

