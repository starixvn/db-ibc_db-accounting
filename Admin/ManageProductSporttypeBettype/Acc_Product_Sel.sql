/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_Product_Sel
	@ProductID		INT = NULL,
	@ProductName	VARCHAR(50) = NULL,
	@ProductPrefix  VARCHAR(10) = NULL,
	@PageSize		INT = 0,
	@PageIndex		INT = 0,
	@TotalRows		INT = 0 OUTPUT

AS
/*
Created: 20200413@Malcolm
Task :  NAP Manage Products/Sporttype/Bettype
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20200413@Malcolm: NAP Manage Products/Sporttype/Bettype [Redmine: #131241]
		
*/
BEGIN
    SET NOCOUNT ON

	DECLARE @RowStart INT , @RowEnd INT

	SELECT @PageIndex = @PageIndex - 1, @RowStart =  @PageIndex * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #Tmp 
	(
	    ProductID 				TINYINT,
		ProductName 			VARCHAR(50),
		Description 			VARCHAR(100),
		ProductPrefix 			VARCHAR(10),
		Enabled 				BIT,
		ProductNameCh 			NVARCHAR(50),
		ProductNameCs 			NVARCHAR(50),
		ProductNameJp 			NVARCHAR(50),
		ProductNameIt 			NVARCHAR(50),
		ProductNameTh 			NVARCHAR(50),
		ProductNameKo 			NVARCHAR(50),
		ProductNameES 			NVARCHAR(50),
		ProductNameVN 			NVARCHAR(50),
		ProductNameEL 			NVARCHAR(50),
		ProductNameRU 			NVARCHAR(50),
		ProductNameID 			NVARCHAR(50),
		BalanceType 			TINYINT,
		SubProductBalanceType 	VARCHAR(512),
		GroupType 				TINYINT,
		CasinoType 				TINYINT,
		IsOfferPlayForFun 		BIT,
		EndOfSupportDate 		DATE,
		VendorID 				SMALLINT,
		OrderNo					INT,
		RowNum 					INT
	)

	INSERT INTO #Tmp 
	(
			ProductID,
			ProductName,
			Description,
			ProductPrefix,
			Enabled,
			ProductNameCh,
			ProductNameCs,
			ProductNameJp,
			ProductNameIt,
			ProductNameTh,
			ProductNameKo,
			ProductNameES,
			ProductNameVN,
			ProductNameEL,
			ProductNameRU,
			ProductNameID,
			BalanceType,
			SubProductBalanceType,
			GroupType,
			CasinoType,
			IsOfferPlayForFun,
			EndOfSupportDate,
			VendorID,
			OrderNo,
			RowNum
	)
    SELECT	ProductID,
			ProductName,
			Description,
			ProductPrefix,
			Enabled,
			ProductNameCh,
			ProductNameCs,
			ProductNameJp,
			ProductNameIt,
			ProductNameTh,
			ProductNameKo,
			ProductNameES,
			ProductNameVN,
			ProductNameEL,
			ProductNameRU,
			ProductNameID,
			BalanceType,
			SubProductBalanceType,
			GroupType,
			CasinoType,
			IsOfferPlayForFun,
			EndOfSupportDate,
			VendorID,
			OrderNo,
			ROW_NUMBER() OVER(ORDER BY ProductID) AS RowNum  
			
	FROM dbo.Products WITH(NOLOCK)
	WHERE (ProductID = @ProductID OR @ProductID IS NULL) 
	      AND (ProductName LIKE '%' + @ProductName + '%' OR ISNULL(@ProductName,'') = '')
		  AND (ProductPrefix LIKE '%' + @ProductPrefix + '%' OR ISNULL(@ProductPrefix,'') = '')

	ORDER BY ProductID

	SELECT @TotalRows = COUNT(*) FROM #Tmp

	SELECT  ProductID,
			ProductName,
			Description,
			ProductPrefix,
			Enabled,
			ProductNameCh,
			ProductNameCs,
			ProductNameJp,
			ProductNameIt,
			ProductNameTh,
			ProductNameKo,
			ProductNameES,
			ProductNameVN,
			ProductNameEL,
			ProductNameRU,
			ProductNameID,			
			SubProductBalanceType,
			BalanceType,
			GroupType,
			CasinoType,
			IsOfferPlayForFun,
			EndOfSupportDate,
			VendorID,
			OrderNo,
			RowNum
	FROM #Tmp
	WHERE @PageIndex < 0 OR @PageSize <= 0 OR (RowNum BETWEEN @RowStart AND @RowEnd) 
	
	DROP TABLE #Tmp

END

