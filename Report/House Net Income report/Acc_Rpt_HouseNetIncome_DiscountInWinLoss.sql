USE bodb02
GO

CREATE PROCEDURE Acc_Rpt_HouseNetIncome_DiscountInWinLoss
	@FromDate DATE,
	@ToDate	DATE,
	@ProductID INT
AS 
/*
	Created:	Harper@20161024
	Task:		#65699: HAIFA - Apply new charge rate discount for HNI report
	DB:			DBEXT.bodb02

	Revisions:
	Param's Explanation:
*/ 
BEGIN
	SET NOCOUNT ON  
		
	DECLARE @FDate DATE, @TDate DATE
	SELECT @FDate = @FromDate, @TDate = @ToDate

	CREATE	TABLE #Exchange	(ExchangeDate DATE, ExchangeID INT, Rate FLOAT)

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

	INSERT INTO #DiscountGroupHeader(DiscountGroupId, DiscountGroupType, PartyId,CurrencyId, FromDate, ToDate)
	(
		SELECT	dg.DiscountGroupId,dg.DiscountGroupType,dga.PartyId, dg.CurrencyId, dg.FromDate, dg.ToDate
		FROM	bodb_Licensee.dbo.LA_DiscountGroupHeader dg (NOLOCK)
				INNER JOIN bodb_Licensee.dbo.LA_DiscountGroupAssignment dga (NOLOCK) ON dga.DiscountGroupId = dg.DiscountGroupId
		WHERE	dg.DiscountGroupType = 3 AND @FDate <= ToDate AND FromDate <= @TDate
	)

	DELETE	d FROM #DiscountGroupHeader d
	WHERE	d.ToDate < (SELECT	MAX(g.ToDate)
						FROM	#DiscountGroupHeader g
						WHERE	d.PartyId = g.PartyId)
	
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
				INNER JOIN bodb_Licensee.dbo.LA_DiscountGroupDetail dgd (NOLOCK) ON dg.DiscountGroupId = dgd.DiscountGroupId
				INNER JOIN bodb_Licensee.dbo.LA_DiscountGroupProduct dgp (NOLOCK) ON dg.DiscountGroupId = dgp.DiscountGroupId
		WHERE	dgp.ProductId = @ProductID
	)
	
	UPDATE d SET
		d.FromAmount = d.FromAmount * e.Rate,
		d.ToAmount = d.ToAmount * e.Rate
	FROM #DiscountGroup d
		INNER JOIN #Exchange e ON e.ExchangeDate = @TDate AND d.BaseCurrency = e.ExchangeID

	SELECT DiscountGroupId, 
		DiscountGroupType, 
		FromAmount, 
		ToAmount, 
		Rate, 
		PartyId, 
		ProductId , 
		BaseCurrency
	FROM #DiscountGroup
	
	DROP TABLE #Exchange
	DROP TABLE #DiscountGroup
	DROP TABLE #DiscountGroupHeader
END
GO
