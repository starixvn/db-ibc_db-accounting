ALTER PROCEDURE [dbo].[Acc_Rpt_HouseNetIncome_DiscountRebate]
	@FromDate DATE,
	@ToDate	DATE
AS  
/*  
	Created: Victor  
	Date: 2016-06-24  
    Task : House month-to-date Net Income report
    DB: DBEXT/bodb02  
   
    Revisions: 20160909@Harper - #63899 - Rebate and Discount should be included when calculating the Pay to Suplplier

	Param's Explanation:   
*/  
BEGIN  
	SET NOCOUNT ON
	
	DECLARE @FDate DATE, @TDate DATE
	SELECT @FDate = @FromDate, @TDate = @ToDate

	CREATE	TABLE #Exchange			(ExchangeDate DATE, ExchangeID INT, Rate FLOAT)

	INSERT INTO #Exchange(ExchangeDate, ExchangeID, Rate)
	SELECT ExchangeDate, Currency, Rate
	FROM DBWH.bodb_account.dbo.tbl_Currency_Daily WITH (NOLOCK) 
	WHERE ExchangeDate BETWEEN @FDate AND @TDate

	CREATE TABLE #DiscountGroupHeader (	DiscountGroupId		INT,
										DiscountGroupType	TINYINT,
										PartyId				INT,
										CurrencyId			INT,
										FromDate			DATETIME,
										ToDate				DATETIME)

	INSERT INTO #DiscountGroupHeader(DiscountGroupId,DiscountGroupType,PartyId,CurrencyId,FromDate,ToDate)
	(
		SELECT	dg.DiscountGroupId,dg.DiscountGroupType,dga.PartyId, dg.CurrencyId, dg.FromDate, dg.ToDate
		FROM	bodb_Licensee.dbo.LA_DiscountGroupHeader dg WITH(NOLOCK)
				INNER JOIN bodb_Licensee.dbo.LA_DiscountGroupAssignment dga WITH(NOLOCK) ON dga.DiscountGroupId = dg.DiscountGroupId
		WHERE	@FDate<= ToDate AND FromDate<=@TDate
	)

	DELETE	d FROM #DiscountGroupHeader d
	WHERE	d.ToDate < (SELECT	MAX(g.ToDate)
					FROM	#DiscountGroupHeader g
					WHERE	g.DiscountGroupType = 1 AND d.PartyId = g.PartyId)
			AND d.DiscountGroupType = 1

	DELETE	d FROM #DiscountGroupHeader d
	WHERE	d.ToDate < (SELECT	MAX(g.ToDate)
					FROM	#DiscountGroupHeader g
					WHERE	g.DiscountGroupType = 2 AND d.PartyId = g.PartyId)
			AND d.DiscountGroupType = 2

	CREATE TABLE #DiscountGroup(DiscountGroupId		SMALLINT,
								DiscountGroupType	TINYINT,
								FromAmount			MONEY,
								ToAmount			MONEY,
								Rate				MONEY,
								PartyId				INT,
								ProductId			TINYINT,
								BaseCurrency		INT)

	INSERT INTO #DiscountGroup (DiscountGroupId, DiscountGroupType, FromAmount, ToAmount, Rate, PartyId, ProductId , BaseCurrency)	
	(
		SELECT	dg.DiscountGroupId,
				dg.DiscountGroupType,
				dgd.FromAmount,
				dgd.ToAmount,
				dgd.Rate,
				dg.PartyID,
				dgp.ProductId,
				dg.CurrencyId
		FROM	#DiscountGroupHeader dg 
				INNER JOIN bodb_Licensee.dbo.LA_DiscountGroupDetail dgd WITH(NOLOCK) ON dg.DiscountGroupId = dgd.DiscountGroupId
				INNER JOIN bodb_Licensee.dbo.LA_DiscountGroupProduct dgp WITH(NOLOCK) ON dg.DiscountGroupId = dgp.DiscountGroupId
	)

	DECLARE @ProductList VARCHAR(1000) = NULL

	SELECT @ProductList = COALESCE(@ProductList + ',', '') + CONVERT(VARCHAR(10), ProductPrefix) 
	FROM (SELECT DISTINCT CASE WHEN d.ProductId = 0 THEN 'SB' ELSE p.ProductPrefix END AS ProductPrefix
		FROM #DiscountGroup d
			LEFT JOIN bodb_licensee.dbo.Product3rd p WITH (NOLOCK) ON p.Productid = d.ProductId
		WHERE DiscountGroupType = 1) t

	-- Convert discount amount to base currency
	UPDATE d SET
		d.FromAmount = d.FromAmount * e.Rate,
		d.ToAmount = d.ToAmount * e.Rate
	FROM #DiscountGroup d
	INNER JOIN #Exchange e ON
		e.ExchangeDate = @TDate AND
		d.BaseCurrency = e.ExchangeID AND
		d.DiscountGroupType = 1 -- discount = 1
	
	CREATE TABLE #FeeData (	PartyId			INT,
							ProductId		INT,
							AComm			MONEY,
							MinFeeApplied	MONEY,
							WLFeeApplied	MONEY,
							AmountToCompany	MONEY)

	INSERT INTO #FeeData (PartyId, ProductId, AComm, MinFeeApplied, WLFeeApplied, AmountToCompany)
	EXEC dbo.Acc_Rpt_HouseNetIncome_LicenseeFee @FromDate = @FDate, @ToDate = @TDate, @Products = @ProductList

	-- Apply discount & rebate
	;WITH t AS(
			SELECT SUM(s.AmountToCompany) Total, s.PartyId,d.DiscountGroupId
			FROM #FeeData s
			INNER JOIN (SELECT DISTINCT DiscountGroupId,PartyId,ProductId FROM #DiscountGroup WHERE DiscountGroupType = 1) AS d
				ON s.PartyId=d.PartyId AND s.ProductId=d.ProductId
			GROUP BY s.PartyId, d.DiscountGroupId
		)
		DELETE d
		FROM #DiscountGroup d
			INNER JOIN t ON t.DiscountGroupId = d.DiscountGroupId AND t.PartyId = d.PartyId
		WHERE d.DiscountGroupType = 1 AND t.Total NOT BETWEEN d.FromAmount AND d.ToAmount
	
	CREATE TABLE #RebateDiscount (	ProductId		INT,
									ProductCode		VARCHAR(10),
									[Order]			INT,
									Figure			VARCHAR(200),
									FullRange		MONEY)

	INSERT INTO #RebateDiscount (ProductId, ProductCode, [Order], Figure, FullRange)	
	SELECT	s.ProductId,
			CASE WHEN s.ProductId = 0 THEN 'SB' ELSE p.ProductPrefix END ProductCode,
			CASE WHEN s.ProductId = 0 THEN 4 ELSE 3 END [Order],
			'Rebate & Discount' Figure,
			-SUM(CASE WHEN s.AmountToCompany < 0 THEN 0 ELSE s.AmountToCompany * (ISNULL(d.Rate, 0) + (1 - ISNULL(d.Rate, 0)) * ISNULL(r.Rate,0)) END) AS FullRange
	FROM	#FeeData s
		LEFT JOIN bodb_licensee.dbo.Product3rd p ON p.Productid = s.ProductId
		LEFT JOIN #DiscountGroup d ON s.PartyId = d.PartyId AND d.ProductId = s.ProductId AND d.DiscountGroupType = 1 -- discount = 1
		LEFT JOIN #DiscountGroup r ON s.PartyId = r.PartyId AND r.ProductId = s.ProductId AND r.DiscountGroupType = 2 -- rebate = 2
	GROUP BY	s.ProductId,
				CASE WHEN s.ProductId = 0 THEN 'SB' ELSE p.ProductPrefix END, 
				CASE WHEN s.ProductId = 0 THEN 4 ELSE 3 END
	UNION ALL
	SELECT	ProductId,
			ProductPrefix AS ProductCode,
			3 AS [Order],
			'Rebate & Discount' Figure,
			0 AS FullRange
	FROM bodb_licensee.dbo.Product3rd WITH (NOLOCK)
	WHERE Productid NOT IN (SELECT DISTINCT ProductID FROM #FeeData)
		AND Productid IN (2,4,5,6,8)
	UNION ALL
	SELECT  0,
			'SB' AS ProductCode,
			4 AS [Order],
			'Rebate & Discount' Figure,
			0 AS FullRange 
	WHERE NOT EXISTS (SELECT 1 FROM #FeeData WHERE ProductId = 0)

	SELECT	r.ProductCode, 
			r.[Order], 
			r.Figure, 
			r.FullRange
	FROM #RebateDiscount r	
	UNION ALL
	SELECT	r.ProductCode, 
			4 AS [Order], 
			'Pay to supplier' AS Figure, 
			ISNULL(r.FullRange, 0) * -0.4 AS FullRange
	FROM #RebateDiscount r
	WHERE r.ProductId IN (2, 4)
			
	DROP TABLE #Exchange
	DROP TABLE #DiscountGroupHeader
	DROP TABLE #DiscountGroup
	DROP TABLE #FeeData
	DROP TABLE #RebateDiscount
END
GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_HouseNetIncome_DiscountRebate] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_HouseNetIncome_DiscountRebate] TO vnteam