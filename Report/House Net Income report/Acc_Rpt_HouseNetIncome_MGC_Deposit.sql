USE bodb02
GO

ALTER PROCEDURE [dbo].[Acc_Rpt_HouseNetIncome_MGC_Deposit]
	@FromDate DATE,
	@ToDate	DATE
AS  
/*  
	Created:	20161206@Harper  
    Task :		House month-to-date Net Income report for MicroGaming
    DB:			DBEXT/bodb02  
   
    Revisions:  
	
	Param's Explanation:   

	EXEC Acc_Rpt_HouseNetIncome_MGC_Deposit '20160901', '20160930'
*/  
BEGIN  
	SET NOCOUNT ON  

	DECLARE @FDate DATE, @TDate DATE
	SELECT @FDate = @FromDate, @TDate = @ToDate
	
	-- Region: Get list of Products Ref
	DECLARE @ProductsRef AS TABLE (ProductId INT, BettypeRef INT, BettypeId INT, GameTypeName VARCHAR(100))

	INSERT INTO @ProductsRef (ProductId, BettypeId, BettypeRef, GameTypeName)
	SELECT CASE WHEN sp.Sporttype = 203 THEN 14
				WHEN sp.Sporttype = 205 THEN 17 
				ELSE 0 END AS ProductId, 
			sp.Bettype, pr.BettypeRef,
			CASE WHEN pr.BettypeRef = 2001
					THEN 'Generic Games' 
					ELSE 'Branded Games' 
			END AS GameTypeName
	FROM bodb_licensee.dbo.Sport_Bettype_Reference sp WITH (NOLOCK)
		INNER JOIN bodb_licensee.dbo.LA_Product3rdSub pr WITH (NOLOCK) ON sp.BettypeRef = pr.BettypeRef
	WHERE pr.BettypeRef IN (2001, 2005) -- 2001 - Generic; 2005 - Branded
	GROUP BY sp.Sporttype, sp.Bettype, pr.BettypeRef
	-- End Region
	
	-- Region: Get Product Codes -- MGCLC,MGCRNG
	DECLARE @ProductCodes VARCHAR(50)
	SELECT @ProductCodes = COALESCE(@ProductCodes + ',', '') + prd.ProductPrefix 
	FROM @ProductsRef pr
		INNER JOIN (
					SELECT Productid, ProductPrefix 
					FROM bodb_licensee..Product3rd WITH (NOLOCK) 
					WHERE Productid IN (SELECT [@ProductsRef].ProductId FROM @ProductsRef)
					) prd ON pr.ProductId = prd.Productid
	GROUP BY prd.Productid, prd.ProductPrefix
	-- End Region

	-- Region: Active Licensee
	DECLARE @tmpParty TABLE (PartyID INT, IsDeposit BIT)

	INSERT INTO @tmpParty (PartyID, IsDeposit)	
	SELECT DISTINCT ci.FromParty, pd.IsDeposit
	FROM bodb_licensee.dbo.OAS_Party p WITH (NOLOCK)
		INNER JOIN bodb_licensee.dbo.OAS_PartyDetail pd WITH (NOLOCK) ON pd.PartyID = p.PartyID
		INNER JOIN bodb_licensee.dbo.OAS_ChargeInfo ci WITH (NOLOCK) ON p.PartyID = ci.FromParty
		LEFT JOIN bodb_licensee.dbo.OAS_ChargeInfo ci2 WITH (NOLOCK) ON ci.ToParty = ci2.FromParty AND ci.ProductID = ci2.ProductID
		LEFT JOIN bodb_licensee.dbo.OAS_ChargeInfoSub cis WITH (NOLOCK) ON ci2.ChargeID = cis.ChargeIdRef
	WHERE p.PartyType = 1
		AND ci.ProductID IN (SELECT DISTINCT ProductId FROM @ProductsRef)
		AND EXISTS (SELECT 1 
					FROM bodb_licensee.dbo.LA_ChargeInfo_SystemMapping map WITH (NOLOCK) 
					WHERE map.ChargeID = ci.ChargeID and map.SystemID = 2)
			AND ((cis.FromDate BETWEEN @FDate AND @TDate)
				OR (cis.ToDate BETWEEN @FDate AND @TDate)
				OR (cis.FromDate < @FDate AND @TDate < cis.ToDate))

	DECLARE @PartyIDs VARCHAR(1000)
	SELECT	@PartyIDs = COALESCE(@PartyIDs + ',', '') + CONVERT(VARCHAR(10), PartyId) FROM @tmpParty
	-- End region	

	-- Region: ChargeInfo	
	DECLARE @PartyChargeInfo AS TABLE (
		ChargeId			INT,
		PartyId				INT,		
		LicenseeId			INT,
		ProductId			INT,
		BettypeRef			INT,
		Rate				MONEY,
		FromDate			DATETIME,
		ToDate				DATETIME)

	INSERT INTO @PartyChargeInfo (ChargeId, PartyId, LicenseeId, ProductID, BettypeRef, Rate, Fromdate, Todate)
	SELECT DISTINCT ci.ChargeID, ci.PartyID, LicenseeID, ci.ProductID, ci.Bettype, DI_Rate, ci.Fromdate, ci.Todate
	FROM bodb_licensee.dbo.LA_f_ChargeInfo(@PartyIDs, @FromDate, @ToDate, @ProductCodes, 'OA', 1) ci 	
	-- End region

	-- Region: Get exchange rate info
	CREATE	TABLE #Exchange		(ExchangeDate DATE, ExchangeID INT, Rate FLOAT)
	CREATE	TABLE #ExchangeOANDA(ExchangeDate DATE, ExchangeID INT, USD FLOAT, MYR FLOAT)

	INSERT INTO #Exchange(ExchangeDate, ExchangeID, Rate)
	SELECT ExchangeDate, Currency, Rate
	FROM DBWH.bodb_account.dbo.tbl_Currency_Daily WITH (NOLOCK) 
	WHERE ExchangeDate BETWEEN @FDate AND @TDate		

	INSERT INTO #ExchangeOANDA(ExchangeDate, ExchangeID, USD, MYR)
	SELECT ExchangeDate, ExchangeID, CompareCurrencyRate1, BaseCurrencyRate
	FROM bodb02.dbo.LA_f_ExchangeDailyForSpecRange(@FDate, @TDate, 'USD', 'USD', 'MYR')
	-- End region	
	
	CREATE TABLE #TempDataMGC(
		RptDate				DATE,
		BettypeRef			INT, 
		GameTypeName		VARCHAR(20),
		PartyId				INT, 		
		CurrencyId			INT, 
		ProductId			INT,	
		LicenseeWinLoss		MONEY,
		LicenseeNetWin		MONEY,
		ProgresCont			MONEY,		
		HouseIncomeDaily	MONEY)

	INSERT INTO #TempDataMGC (RptDate, BettypeRef, GameTypeName, PartyId, CurrencyId, ProductId,
							 LicenseeWinLoss, LicenseeNetWin, ProgresCont, HouseIncomeDaily)
	SELECT d.RptDate, d.BetTypeRef, d.GameTypeName, pci.PartyId, d.CurrencyId, d.ProductId,			
			SUM(LicenseeWinLoss) AS LicenseeWinLoss,
			SUM(LicenseeWinLoss - ProgresCont) AS LicenseeNetWin,
			SUM(ProgresCont) AS ProgresCont,
			SUM((LicenseeWinLoss - ProgresCont) * pci.Rate * e.Rate) AS HouseIncomeDaily
	FROM (
			SELECT rpt.RptDate, SiteId, pr.ProductId, pr.BettypeRef, pr.GameTypeName, CurrencyId, 				
				-SUM(ISNULL(Winloss, 0)) AS LicenseeWinLoss,
				CASE WHEN pr.ProductId = 17 THEN SUM(ISNULL(ProgressiveContribution, 0)) ELSE 0 END  AS ProgresCont -- IF RNG: Contr <> 0, else = 0
			FROM bodb_LicenseeReport.dbo.rpt_ThirdPartyWL_ExtraGMT rpt
				INNER JOIN @ProductsRef pr ON rpt.BetTypeId = pr.BettypeId
			WHERE rpt.RptDate BETWEEN @FromDate AND @ToDate
				  AND rpt.SiteId IN (SELECT DISTINCT LicenseeId FROM @PartyChargeInfo)
				  AND CurrencyID <> 20
				  AND StatusId NOT IN (-1, 101, 102, 103)
			GROUP BY rpt.RptDate, SiteId, pr.ProductId, pr.BettypeRef, CurrencyId, pr.GameTypeName
			) d
		INNER JOIN @PartyChargeInfo pci ON d.SiteId = pci.LicenseeID AND d.BettypeRef = pci.BettypeRef AND pci.ProductId = d.ProductId
		INNER JOIN #Exchange e ON e.ExchangeDate = d.RptDate AND e.ExchangeID = d.CurrencyId
	WHERE d.RptDate BETWEEN pci.Fromdate AND pci.ToDate
	GROUP BY d.RptDate, d.GameTypeName, d.BettypeRef, pci.PartyId, d.ProductId, d.CurrencyId
		
	CREATE NONCLUSTERED INDEX Idx_InvoiceData ON #TempDataMGC (PartyId)

	-- Region: Caculate PayToSupplier value
	DECLARE @ProductChargeInfo AS TABLE (
			ParentId		INT, 
			ProductId		INT, 
			BettypeRef		INT, 
			ChargeType		INT, 
			Rate			MONEY, 
			MinAmount		MONEY, 
			MaxAmount		MONEY, 
			CurrencyId		INT, 
			CurrencyCode	VARCHAR(3))
	
	INSERT INTO @ProductChargeInfo (ParentId, ProductId, BettypeRef, ChargeType, Rate, MinAmount, MaxAmount, CurrencyId, CurrencyCode)
	SELECT DISTINCT a.FromParty, a.ProductId, a.BettypeRef, a.ChargeType, a.Rate, 
					CASE WHEN a.ChargeType = 4 THEN a.MinAmount * ex.MYR ELSE 0 END MinAmount,
					CASE WHEN a.ChargeType = 4 THEN a.MaxAmount * ex.MYR ELSE 0 END MaxAmount,
					2, 'MYR' -- Convert to MYR to compare
	FROM (
			SELECT DISTINCT tp.ProductId, ci2.ChargeID, cis.FromParty, cis.BettypeRef, cis.ChargeType, cis.Rate, cis.MinAmount, cis.MaxAmount, cis.BaseCurrencyId
			FROM @PartyChargeInfo tp
				INNER JOIN bodb_licensee.dbo.OAS_ChargeInfo ci WITH (NOLOCK) ON tp.ChargeId = ci.ChargeID
				LEFT JOIN bodb_licensee.dbo.OAS_ChargeInfo ci2 WITH (NOLOCK) ON ci.ToParty = ci2.FromParty AND ci2.ProductID = tp.ProductID
				LEFT JOIN bodb_licensee.dbo.OAS_ChargeInfoSub cis WITH (NOLOCK) ON ci2.ChargeID = cis.ChargeIdRef
			WHERE tp.ChargeId > 0
		) a	
	LEFT JOIN #ExchangeOANDA ex ON a.BaseCurrencyId = ex.ExchangeID

	DECLARE @RateForPayToSupplier AS TABLE (			
			BettypeRef			INT,			
			Rate				FLOAT,
			PayToSupplier		MONEY,
			BonusValue			MONEY )
	SELECT b.BettypeRef, SUM(b.LicenseeNetWin * e.MYR) AS LicenseeNetWin
					FROM #TempDataMGC b
						INNER JOIN #ExchangeOANDA e ON e.ExchangeDate = b.RptDate AND e.ExchangeID = b.CurrencyId	
					GROUP BY b.BettypeRef
	; WITH sums AS 
				(	SELECT b.BettypeRef, SUM(b.LicenseeNetWin * e.MYR) AS LicenseeNetWin
					FROM #TempDataMGC b
						INNER JOIN #ExchangeOANDA e ON e.ExchangeDate = b.RptDate AND e.ExchangeID = b.CurrencyId	
					GROUP BY b.BettypeRef
				)
	--INSERT INTO @RateForPayToSupplier (BettypeRef, PayToSupplier, Rate, BonusValue)
	SELECT s.BettypeRef, 			 
			CASE 
				WHEN (ChargeType = 4 AND s.LicenseeNetWin BETWEEN MinAmount AND MaxAmount) 
				THEN CASE 
						WHEN MinAmount = 0 THEN (s.LicenseeNetWin - 0) * Rate 
						WHEN MinAmount > 0 THEN (s.LicenseeNetWin - MinAmount) * Rate 
						ELSE 0 END
				ELSE 0 END +
			CASE 
				WHEN (ChargeType = 4 AND s.LicenseeNetWin > MaxAmount) 
				THEN CASE 
						WHEN MinAmount = 0 THEN (MaxAmount - 0) * Rate						 
						ELSE 0 END
				ELSE 0 END +
			CASE 
				WHEN (ChargeType = 1) 
				THEN CASE WHEN s.LicenseeNetWin <= 0 THEN 0 ELSE s.LicenseeNetWin * Rate END
				ELSE 0 END 
			AS PayToSupplier,

			CASE 
				WHEN r.ChargeType = 1 THEN r.Rate
				WHEN r.ChargeType = 4 AND s.LicenseeNetWin BETWEEN r.MinAmount AND r.MaxAmount THEN r.Rate
				ELSE 0 
			END AS Rate,

			CASE WHEN r.ChargeType = 1 THEN 0
			     WHEN r.ChargeType = 4 AND s.LicenseeNetWin BETWEEN MinAmount AND MaxAmount
				 THEN CASE WHEN MinAmount = 0 THEN 0
						   WHEN MinAmount > 0 THEN ((r.MinAmount * (SELECT DISTINCT Rate FROM @ProductChargeInfo WHERE ChargeType = 4 AND MinAmount = 0)) - (r.MinAmount * r.Rate))
				 ELSE 0 END
			END AS BonusValue
	FROM sums s
		INNER JOIN ( SELECT DISTINCT BettypeRef, ChargeType, Rate, MinAmount, MaxAmount FROM @ProductChargeInfo) r ON s.BettypeRef = r.BettypeRef
	
	DECLARE @PayToSupplier MONEY
	SELECT @PayToSupplier = SUM (PayToSupplier) FROM @RateForPayToSupplier

	DECLARE @HouseNetIncome MONEY
	SELECT @HouseNetIncome = SUM(CASE WHEN s.SumByProduct <= 0 THEN 0 ELSE s.SumByProduct END) 
						  FROM ( SELECT SUM (HouseIncomeDaily) AS SumByProduct 
									   FROM #TempDataMGC GROUP BY ProductId) s

	-- Region: Full Range	
	CREATE TABLE #FinalResult (
		RptDate			VARCHAR(10),
		LicenseeWL			MONEY,
		PayToSupplier		MONEY
	)							
	INSERT INTO #FinalResult (RptDate, LicenseeWL, PayToSupplier)
	SELECT 'FullRange', @HouseNetIncome, (-1) * @PayToSupplier
	
	-- Handle daily data
	DECLARE @DailyPayAmt TABLE (RptDate DATE, AmountDaily MONEY)
	
	INSERT INTO @DailyPayAmt (RptDate, AmountDaily)
	SELECT b.RptDate, SUM(b.LicenseeNetWin * r.Rate + r.BonusValue)
	FROM #TempDataMGC b
		INNER JOIN @RateForPayToSupplier r ON b.BettypeRef = r.BettypeRef
	GROUP BY b.RptDate


	--SELECT * FROM @RateForPayToSupplier

	-- Processing daily data
	DECLARE @tmpDate DATE, @DateList VARCHAR(200)
	SELECT @tmpDate = @FDate

	WHILE @tmpDate <= @TDate
	BEGIN
		INSERT INTO #FinalResult (RptDate, LicenseeWL, PayToSupplier)
		SELECT CONVERT(VARCHAR(2), @tmpDate, 106), 
			(SELECT ISNULL(SUM(HouseIncomeDaily), 0) FROM #TempDataMGC WHERE RptDate = @tmpDate), -- LicenseeWL
			(SELECT ISNULL(SUM(AmountDaily), 0) FROM @DailyPayAmt WHERE RptDate = @tmpDate)		-- PayToSupplier

		SELECT @tmpDate = DATEADD(DAY, 1, @tmpDate)
	END

	SELECT @DateList = COALESCE(@DateList + ',', '') + '[' + CONVERT(VARCHAR(10), RptDate) + ']' FROM #FinalResult 
	-- End region

	---------------------------------------------------- Select the output -------------------------------------------------------
	DECLARE @SQL VARCHAR(1000)
	SELECT @SQL =	'SELECT * ' + CHAR(13) +
					'FROM	(SELECT ProductCode, [Order], [RptDate], Figure, ISNULL(value, 0) value FROM #FinalResult' + CHAR(13) +
							'CROSS APPLY' + CHAR(13) +
							'(SELECT ''MGC'', 1, ''House Income'', LicenseeWL' + CHAR(13) +
							'UNION ALL' + CHAR(13) +
							'SELECT ''MGC'', 4, ''Pay to supplier'', PayToSupplier) c (ProductCode, [Order], Figure, value)) a' + CHAR(13) +
					'PIVOT' + CHAR(13) +
					'(' + CHAR(13) +
						'MAX(value)' + CHAR(13) +
						'FOR [RptDate] in (' + @DateList + ')' + CHAR(13) +
					') piv' + CHAR(13) +
					'ORDER BY [Order]'

	EXEC(@SQL)

	-- Region: Drop tmp table
	DROP TABLE #Exchange
	DROP TABLE #ExchangeOANDA
	DROP TABLE #TempDataMGC
	DROP TABLE #FinalResult
END
GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_HouseNetIncome_MGC_Deposit] TO [bodbAdminNet]
GO
GRANT VIEW definition ON [dbo].[Acc_Rpt_HouseNetIncome_MGC_Deposit] TO vnteam
GO