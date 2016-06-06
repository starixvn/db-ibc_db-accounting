ALTER PROCEDURE [dbo].[Acc_Rpt_HouseNetIncome_SB_Deposit]
	@FromDate DATE,
	@ToDate	DATE
AS  
/*  
	Created: Victor  
	Date: 2016-05-23  
    Task : House month-to-date Net Income report
    DB: DBEXT/bodb02  
   
    Revisions:
	Param's Explanation:   
*/  
BEGIN  
	SET NOCOUNT ON  

	DECLARE @FDate DATE, @TDate DATE
	SELECT @FDate = @FromDate, @TDate = @ToDate

	-- Region: Active licensees
	DECLARE @tmpParty TABLE (PartyID INT, IsDeposit BIT)
	INSERT INTO @tmpParty (PartyID, IsDeposit)
	SELECT DISTINCT ci.FromParty, pd.IsDeposit
	FROM bodb_licensee.dbo.OAS_Party p WITH (NOLOCK)
		INNER JOIN bodb_licensee.dbo.OAS_PartyDetail pd WITH (NOLOCK) ON pd.PartyID = p.PartyID
		INNER JOIN bodb_licensee.dbo.OAS_ChargeInfo ci WITH (NOLOCK) ON p.PartyID = ci.FromParty
		INNER JOIN bodb_licensee.dbo.LA_ChargeInfo_SystemMapping map ON map.ChargeID = ci.ChargeID and map.SystemID = 2
	WHERE	p.PartyType = 1 AND
			ci.ProductId = 0 -- SB
			AND ((ci.FromDate BETWEEN @FDate AND @TDate)
				OR (ci.ToDate BETWEEN @FDate AND @TDate)
				OR (ci.FromDate < @FDate AND @TDate < ci.ToDate))

	DECLARE @PartyIDs VARCHAR(1000)
	SELECT	@PartyIDs = COALESCE(@PartyIDs + ',', '') + CONVERT(VARCHAR(10), PartyId) FROM @tmpParty WHERE IsDeposit = 1
	-- End region

	-- Region: Get exchange rate info
	CREATE	TABLE #Exchange			(ExchangeDate DATE, ExchangeID INT, Rate FLOAT)
	CREATE	TABLE #ExchangeOANDA	(ExchangeDate DATE, ExchangeID INT, Rate FLOAT)

	INSERT INTO #Exchange(ExchangeDate, ExchangeID, Rate)
	SELECT ExchangeDate, Currency, Rate
	FROM DBWH.bodb_account.dbo.tbl_Currency_Daily WITH (NOLOCK) 
	WHERE ExchangeDate BETWEEN @FDate AND @TDate

	INSERT INTO #ExchangeOANDA(ExchangeDate, ExchangeID, Rate)
	SELECT ExchangeDate, ExchangeID, BaseCurrencyRate
	FROM bodb02.dbo.LA_f_ExchangeDailySel(@FDate, @TDate, 'MYR')
	-- End region

	-- Region: Discount & Rebate Settings
	BEGIN
	DECLARE @DiscountGroupHeader AS TABLE (
			DiscountGroupId		INT,
			DiscountGroupType	TINYINT,
			PartyId				INT,
			CurrencyId			INT,
			FromDate			DATETIME,
			ToDate				DATETIME)

	INSERT INTO @DiscountGroupHeader(DiscountGroupId,DiscountGroupType,PartyId,CurrencyId,FromDate,ToDate)
	(
		SELECT	dg.DiscountGroupId,dg.DiscountGroupType,dga.PartyId, dg.CurrencyId, dg.FromDate, dg.ToDate
		FROM	bodb_Licensee.dbo.LA_DiscountGroupHeader dg WITH(NOLOCK)
				INNER JOIN bodb_Licensee.dbo.LA_DiscountGroupAssignment dga WITH(NOLOCK) ON dga.DiscountGroupId = dg.DiscountGroupId
		WHERE	@FDate<= ToDate AND FromDate<=@TDate
	)

	DELETE	d FROM @DiscountGroupHeader d
	WHERE	d.ToDate < (SELECT	MAX(g.ToDate)
					FROM	@DiscountGroupHeader g
					WHERE	g.DiscountGroupType = 1 AND d.PartyId = g.PartyId)
			AND d.DiscountGroupType = 1

	DELETE	d FROM @DiscountGroupHeader d
	WHERE	d.ToDate < (SELECT	MAX(g.ToDate)
					FROM	@DiscountGroupHeader g
					WHERE	g.DiscountGroupType = 2 AND d.PartyId = g.PartyId)
			AND d.DiscountGroupType = 2

	DECLARE @DiscountGroup AS TABLE(
			DiscountGroupId		SMALLINT,
			DiscountGroupType	TINYINT,
			FromAmount			MONEY,
			ToAmount			MONEY,
			Rate				MONEY,
			PartyId				INT,
			ProductId			TINYINT,
			BaseCurrency		INT)

	INSERT INTO @DiscountGroup (DiscountGroupId, DiscountGroupType, FromAmount, ToAmount, Rate, PartyId, ProductId , BaseCurrency)	
	(
		SELECT	dg.DiscountGroupId,
				dg.DiscountGroupType,
				dgd.FromAmount,
				dgd.ToAmount,
				dgd.Rate,
				dg.PartyID,
				dgp.ProductId,
				dg.CurrencyId
		FROM	@DiscountGroupHeader dg 
				INNER JOIN bodb_Licensee.dbo.LA_DiscountGroupDetail dgd WITH(NOLOCK) ON dg.DiscountGroupId = dgd.DiscountGroupId
				INNER JOIN bodb_Licensee.dbo.LA_DiscountGroupProduct dgp WITH(NOLOCK) ON dg.DiscountGroupId = dgp.DiscountGroupId
	)

	DECLARE @ProductList VARCHAR(1000) = 'BA'

	SELECT @ProductList = COALESCE(@ProductList + ',', '') + CONVERT(VARCHAR(10), ProductPrefix) 
	FROM (SELECT DISTINCT CASE WHEN d.ProductId = 0 THEN 'SB' ELSE p.ProductPrefix END AS ProductPrefix
		FROM @DiscountGroup d
			LEFT JOIN bodb_licensee.dbo.Product3rd p WITH (NOLOCK) ON p.Productid = d.ProductId
		WHERE DiscountGroupType = 1) t

	-- Convert discount amount to base currency
	UPDATE d SET
		d.FromAmount = d.FromAmount * e.Rate,
		d.ToAmount = d.ToAmount * e.Rate
	FROM @DiscountGroup d
	INNER JOIN #Exchange e ON
		e.ExchangeDate = @TDate AND
		d.BaseCurrency = e.ExchangeID AND
		d.DiscountGroupType = 1 -- discount = 1

	END
	-- End Region

	-- Region: Party charge info
	DECLARE @PartyChargeInfo AS TABLE (
			PartyId		INT,
			LicenseeId	INT,
			IsDeposit	BIT,
			ProductID	INT,
			Rate		MONEY,
			FromDate	SMALLDATETIME,
			ToDate		SMALLDATETIME,
			Bettype		INT)

	INSERT INTO @PartyChargeInfo(PartyId, LicenseeId, IsDeposit, ProductID, Rate, Fromdate, Todate, Bettype)
	(
		SELECT	ci.PartyID, ci.LicenseeID, ci.isDeposit, ci.ProductID, ci.DI_Rate, ci.Fromdate, ci.ToDate, ISNULL(sbr.Bettype, ci.Bettype)
		FROM	bodb_licensee.dbo.LA_f_ChargeInfo(@PartyIDs, @FDate, @TDate, @ProductList, 'OA', 1) ci
			LEFT JOIN bodb_licensee..Sport_Bettype_Reference sbr WITH(NOLOCK) ON sbr.BettypeRef = ci.Bettype
		WHERE	DI_Rate > 0 AND ProductId <> 1 --exclude RB
	)
	-- End region
	
	--  Minimum fee is calculated for all currencies that licensee offer. There is no minimum fee when data display individual currency.
	-- Region: MinfeeGroup Date range
	DECLARE @Month TINYINT = MONTH(@FDate)
	DECLARE @FirstDate DATETIME = DATEADD(mm, DATEDIFF(mm, 0, @FDate), 0)
	DECLARE @LastDate DATETIME = DATEADD (dd, -1, DATEADD(mm, DATEDIFF(mm, 0, @FDate) + 1, 0))
	DECLARE @DaysInMonth INT = DATEDIFF(day, @FirstDate, @LastDate) + 1

	DECLARE @PartyGroup AS TABLE (PartyGroupId INT, PartyId INT)
	INSERT	INTO @PartyGroup(PartyGroupId, PartyId)
	(
		SELECT	PartyGroupId, PartyId
		FROM	bodb_licensee.dbo.LA_PartyGroupAssignment WITH(NOLOCK)
		WHERE	PartyGroupId IN (	SELECT	p1.PartyGroupId
									FROM	bodb_licensee.dbo.LA_PartyGroupAssignment p1 WITH(NOLOCK)
									WHERE	p1.PartyId IN (SELECT p2.PartyId FROM @tmpParty p2))
	)

	DECLARE @MinFeeGroup TABLE(
			FeeType			TINYINT,
			PartyId			INT,
			ProductId		INT,
			CurrencyId		INT,
			FeeAmount		MONEY,
			FromDate		DATETIME,
			ToDate			DATETIME,
			MinFeeProrate	MONEY,
			WaivedAmount	MONEY,
			TotalAmount		MONEY,
			MinFeeAmount	MONEY,
			AmountToCompany	MONEY)

	INSERT INTO @MinFeeGroup(FeeType ,PartyId,ProductId, CurrencyId ,FeeAmount ,FromDate ,ToDate)
	(
		SELECT	mf.FeeTypeId,
				mf.PartyId,
				mf.ProductId,
				mf.CurrencyId,
				mf.FeeAmount,
				CASE WHEN @FDate >= mf.FromDate THEN @FDate ELSE mf.FromDate END AS FromDate,
				CASE WHEN @TDate < mf.ToDate THEN @TDate ELSE mf.ToDate END AS ToDate
		FROM	bodb_licensee.dbo.LA_MinFee mf WITH(NOLOCK)
		WHERE	((mf.FeeTypeId = 1)
					OR mf.FeeTypeId = 2 AND EXISTS (SELECT	PartyId
													FROM	bodb_licensee.dbo.LA_MinFee m WITH(NOLOCK)
													WHERE	m.FeeTypeId = 1
															AND m.PartyId = mf.PartyId
															AND m.ProductId = mf.ProductId
															AND ((m.FromDate BETWEEN @FirstDate AND @LastDate)
																OR (m.ToDate BETWEEN @FirstDate AND @LastDate)
																OR (m.FromDate<@FirstDate AND @LastDate < m.ToDate)
															)
													)
				)
				AND mf.ProductId IN (SELECT ProductId FROM @PartyChargeInfo)
				AND ((mf.FromDate BETWEEN @FirstDate AND @LastDate) 
					OR (mf.ToDate BETWEEN @FirstDate AND @LastDate) 
					OR (mf.FromDate<@FirstDate AND @LastDate < mf.ToDate)
				)
	)

	-- End region

	UPDATE m SET m.FeeAmount = m.FeeAmount * e.Rate
	FROM @MinFeeGroup m
		INNER JOIN #Exchange e ON e.ExchangeDate = @TDate AND m.CurrencyId = e.ExchangeID

	-- Region: Get Amount by Product
	CREATE	TABLE #TempData (
			PartyId			INT,
			rptDate			DATETIME,
			CurrencyId		INT,
			WinLoss			MONEY,
			AComm			MONEY,
			ProductId		TINYINT,
			AmountToCompany MONEY,
			IsApplyMinFee	BIT)
	INSERT INTO #TempData (PartyId,rptDate,CurrencyId,WinLoss,AComm,ProductId,AmountToCompany, IsApplyMinFee)
	(
		SELECT	p.PartyId,
				b.rptDate,
				b.CurrencyID,
				SUM(ISNULL(b.MemberWL, 0)) * e.Rate,
				SUM(ISNULL(b.CommissionA, 0)) * e.Rate,
				p.ProductId,
				SUM((-ISNULL(b.MemberWL, 0) * p.Rate) - (CASE WHEN b.ProductId = 3 THEN ISNULL(b.CommissionA, 0) ELSE 0 END)) * e.Rate,
				1 AS IsApplyMinFee
		FROM	bodb_LicenseeReport.dbo.rpt_BettingByProduct b WITH (NOLOCK)
				INNER JOIN #Exchange e ON b.rptDate = e.ExchangeDate AND b.CurrencyId = e.ExchangeID
				INNER JOIN @PartyChargeInfo p ON	b.ProductId = p.ProductID 
													AND p.LicenseeId = b.SiteId
													AND (b.rptDate BETWEEN p.FromDate AND p.ToDate)
													AND (p.Bettype = -1 OR p.Bettype = b.Bettype)
		WHERE	b.rptDate BETWEEN @FDate AND @TDate
				AND b.CurrencyID <> 20
				AND b.customercategory NOT IN (27, 28)
				AND b.Bettype NOT IN (901,902,903)
				AND b.StatusId NOT IN (-1, 103) -- Exclude Reject , Void, Refund
		GROUP BY b.rptdate, b.SiteId, p.PartyId,b.CurrencyID, p.ProductId, e.Rate
	)

	CREATE NONCLUSTERED INDEX Idx_InvoiceData ON #TempData (PartyId, ProductId)

	--  Minimum fee is calculated for all currencies that licensee offer. There is no minimum fee when data display individual currency.

	UPDATE  t
	SET		t.IsApplyMinFee = 0
	FROM	#TempData t 
		INNER JOIN @MinFeeGroup m ON t.rptDate BETWEEN m.FromDate AND m.ToDate
			AND t.ProductId = m.ProductId
			AND t.PartyId = m.PartyId
	WHERE	m.FeeType=2
	-- End region

	-- Region: Check min fee group
	--- calculate waived prorate (*)
	UPDATE	amf
	SET		MinFeeProrate = ((	SELECT	TOP 1 mfg.FeeAmount
								FROM	@MinFeeGroup mfg
								WHERE	mfg.FeeType = 1
										AND mfg.PartyId = amf.PartyId
										AND mfg.ProductId = amf.ProductId)
							/ @DaysInMonth) * (DATEDIFF(DAY, FromDate, ToDate) + 1)
	FROM	@MinFeeGroup amf
	WHERE	FeeType = 2

	--- sum amount under waived
	UPDATE	amf
	SET		amf.WaivedAmount = ISNULL((	SELECT	SUM(td.AmountToCompany)
										FROM	#TempData td 
										WHERE	amf.PartyId = td.PartyId
												AND amf.ProductId = td.ProductId
												AND td.rptDate BETWEEN amf.FromDate AND amf.ToDate), 0)
	FROM	@MinFeeGroup amf
	WHERE	amf.FeeType = 2

	--- calculate min fee prorate (fee amount in month - waived amount (*))
	UPDATE	amf
	SET		amf.MinFeeProrate = ROUND((	amf.FeeAmount / @DaysInMonth) * (DATEDIFF(DAY, FromDate, ToDate) + 1) -
										ISNULL((SELECT	SUM(f.MinFeeProrate)
												FROM	@MinFeeGroup f
												WHERE	f.FeeType = 2
														AND amf.PartyId = f.PartyId
														AND amf.ProductId = f.ProductId), 0), 2),
			amf.WaivedAmount =  ISNULL((SELECT	CASE WHEN SUM(f.WaivedAmount) < 0 THEN 0 ELSE SUM(f.WaivedAmount) END
										FROM	@MinFeeGroup f
										WHERE	f.FeeType = 2
												AND amf.PartyId = f.PartyId
												AND amf.ProductId = f.ProductId), 0),
			amf.MinFeeAmount =  ISNULL((SELECT	SUM(td.AmountToCompany)
										FROM	#TempData td 
										WHERE	amf.PartyId = td.PartyId
												AND td.rptDate BETWEEN amf.FromDate AND amf.ToDate
												AND td.IsApplyMinFee = 1
												AND amf.ProductId = td.ProductId), 0)
	FROM	@MinFeeGroup amf
	WHERE	amf.FeeType = 1

	--- sum min fee amount
	UPDATE	amf
	SET		amf.TotalAmount =  amf.MinFeeAmount + amf.WaivedAmount
	FROM	@MinFeeGroup amf
	WHERE	amf.FeeType = 1
	
	DECLARE @TotalMinFees TABLE(
		PartyGroupId		INT,
		ProductId			INT,
		TotalMinFee			MONEY,
		TotalMinFeeAmount	MONEY
	)
	INSERT	INTO @TotalMinFees(PartyGroupId, ProductId, TotalMinFee, TotalMinFeeAmount)
	SELECT	pg.PartyGroupId, mf.ProductId,
			SUM(mf.MinFeeProrate),
			SUM(CASE WHEN mf.MinFeeAmount < 0 THEN 0 ELSE mf.MinFeeAmount END)
	FROM	@MinFeeGroup mf
	INNER JOIN @PartyGroup pg ON mf.PartyId = pg.PartyId
	WHERE	mf.FeeType = 1
	GROUP BY pg.PartyGroupId,mf.ProductId

	-- update minfee group
	UPDATE	amf
	SET		amf.AmountToCompany =	CASE
										WHEN t.TotalMinFeeAmount < t.TotalMinFee AND amf.MinFeeAmount < amf.MinFeeProrate 
											THEN amf.MinFeeProrate + amf.WaivedAmount
										ELSE amf.TotalAmount
									END
	FROM	@MinFeeGroup amf
	INNER JOIN @PartyGroup pg ON pg.PartyId = amf.PartyId
	INNER JOIN @TotalMinFees t ON amf.ProductId = t.ProductId AND t.PartyGroupId = pg.PartyGroupId
	WHERE	amf.FeeType = 1
		
	-- update minfee non-group
	UPDATE	amf
	SET		amf.AmountToCompany =	CASE WHEN amf.MinFeeAmount < amf.MinFeeProrate
											THEN amf.MinFeeProrate + amf.WaivedAmount
										ELSE amf.TotalAmount
									END
	FROM	@MinFeeGroup amf
	WHERE	amf.FeeType = 1 AND amf.AmountToCompany IS NULL

	-- Sum products
	BEGIN
		DECLARE @SumByProducts TABLE(
			PartyId			INT,
			WinLoss			MONEY,
			AComm			MONEY,
			MinFeeApplied	MONEY,
			WLFeeApplied	MONEY,
			AmountToCompany	MONEY,
			ProductId		INT
		)
		-- sum by product
		INSERT INTO @SumByProducts (PartyId,ProductId,WinLoss,AComm,MinFeeApplied,WLFeeApplied,AmountToCompany)
		SELECT	PartyId
				,ProductId
				,SUM(WinLoss) WinLoss
				,SUM(AComm) AComm
				,0
				,SUM(AmountToCompany) WLFeeApplied
				,SUM(AmountToCompany) AmountToCompany
		FROM #TempData
		GROUP BY PartyId, ProductId, CASE WHEN MONTH(rptDate) = MONTH(@FDate) THEN 1 ELSE 0 END

		-- merge to minfee group
		UPDATE s 
		SET AmountToCompany = m.AmountToCompany
			, MinFeeApplied = CASE WHEN m.AmountToCompany=m.TotalAmount THEN 0 ELSE m.MinFeeProrate END
			, WLFeeApplied = CASE WHEN m.AmountToCompany=m.TotalAmount THEN m.TotalAmount ELSE m.WaivedAmount END
		FROM @SumByProducts s
			INNER JOIN @MinFeeGroup m ON m.PartyId = s.PartyId AND m.ProductId = s.ProductId
		WHERE m.FeeType = 1 -- min fee

		-- Update negative amount
		UPDATE @SumByProducts
		SET WLFeeApplied = CASE WHEN WLFeeApplied > 0 THEN WLFeeApplied ELSE 0 END,
			AmountToCompany = CASE WHEN AmountToCompany > 0 THEN AmountToCompany ELSE 0 END

		-- filter discount
		;WITH t AS(
			SELECT SUM(s.AmountToCompany) Total, s.PartyId,d.DiscountGroupId
			FROM @SumByProducts s
			INNER JOIN (SELECT DISTINCT DiscountGroupId,PartyId,ProductId FROM @DiscountGroup WHERE DiscountGroupType = 1) AS d
				ON s.PartyId=d.PartyId AND s.ProductId=d.ProductId
			GROUP BY s.PartyId, d.DiscountGroupId
		)
		DELETE d
		FROM @DiscountGroup d
			INNER JOIN t ON t.DiscountGroupId = d.DiscountGroupId AND t.PartyId = d.PartyId
		WHERE d.DiscountGroupType = 1 AND t.Total NOT BETWEEN d.FromAmount AND d.ToAmount
	END

	-- Region: Result
	CREATE TABLE #SBResult (
		PartyId			INT,
		MinFeeApplied	MONEY,
		WLFeeApplied	MONEY,
		SportBookFee	MONEY,
		Discount		MONEY,
		Rebate			MONEY
	)


	INSERT INTO #SBResult (PartyId, SportbookFee, Discount, Rebate, MinFeeApplied, WLFeeApplied)
	SELECT	p.PartyId, 
			s.AmountToCompany,
			CASE WHEN s.AmountToCompany < 0 THEN 0 ELSE (s.AmountToCompany * ISNULL(d.Rate, 0)) END AS Discount,
			CASE WHEN s.AmountToCompany < 0 THEN 0 ELSE (s.AmountToCompany - (s.AmountToCompany * ISNULL(d.Rate, 0))) * ISNULL(r.Rate,0) END AS Rebate,
			s.MinFeeApplied,
			s.WLFeeApplied
	FROM	@tmpParty p
			INNER JOIN bodb_licensee.dbo.OAS_Party (NOLOCK) op ON p.PartyId = op.PartyID
			INNER JOIN @SumByProducts s ON p.PartyId = s.PartyId
			LEFT JOIN @DiscountGroup d ON s.PartyId = d.PartyId AND d.ProductId = s.ProductId AND d.DiscountGroupType = 1 -- discount = 1
			LEFT JOIN @DiscountGroup r ON s.PartyId = r.PartyId AND r.ProductId = s.ProductId AND r.DiscountGroupType = 2 -- rebate = 2
	WHERE	s.ProductId = 0

	CREATE TABLE #FinalResult (
		RptDate				VARCHAR(10),
		LicenseeWL			MONEY,
		OtherFees			MONEY,
		PayToMuayThai		MONEY,
		PayToMetricGaming	MONEY
	)

	DECLARE @BAComm MONEY = 0, @BAWinloss MONEY = 0
	SELECT	@BAComm = ISNULL(SUM(AComm), 0),
			@BAWinloss = ISNULL(SUM(AmountToCompany), 0)
	FROM #TempData WHERE ProductId = 3

	INSERT INTO #FinalResult (rptDate, LicenseeWL, OtherFees, PayToMuayThai, PayToMetricGaming)
	SELECT 'FullRange', ISNULL(SUM(WLFeeApplied) + @BAWinloss, 0), ISNULL(SUM(MinFeeApplied - Discount - Rebate) - @BAComm, 0), 0, 0
	FROM #SBResult

	DECLARE @tmpDate DATE, @DateList VARCHAR(200)
	SELECT @tmpDate = @FDate

	WHILE @tmpDate <= @TDate
	BEGIN
		INSERT INTO #FinalResult (RptDate, LicenseeWL, OtherFees, PayToMuayThai, PayToMetricGaming)
		SELECT CONVERT(VARCHAR(2), @tmpDate, 106), 
			(SELECT ISNULL(SUM(AmountToCompany), 0) FROM #TempData WHERE ProductId IN (0, 3) AND rptDate = @tmpDate), -- LicenseeWL + BA Winloss
			(SELECT ISNULL(SUM(AComm), 0) FROM #TempData WHERE ProductId = 3 AND rptDate = @tmpDate), -- BA Commission
			0, 0

		SELECT @tmpDate = DATEADD(DAY, 1, @tmpDate)
	END

	SELECT @DateList = COALESCE(@DateList + ',', '') + '[' + CONVERT(VARCHAR(10), RptDate) + ']' FROM #FinalResult 
	-- End region

	---------------------------------------------------- Pay to Metric Gaming -------------------------------------------------------
	-- Get Party list, including credit licensees
	SET @PartyIDs = NULL
	SELECT	@PartyIDs = COALESCE(@PartyIDs + ',', '') + CONVERT(VARCHAR(10), PartyId) FROM @tmpParty

	DELETE FROM @PartyChargeInfo
	INSERT INTO @PartyChargeInfo(PartyId, LicenseeId, IsDeposit, ProductID, Rate, Fromdate, Todate)
	SELECT	PartyID, LicenseeID, isDeposit, ProductID, DI_Rate, Fromdate, Todate
	FROM	bodb_licensee.dbo.LA_f_ChargeInfo(@PartyIds, @FDate, @TDate, 'SB', 'OA', 0)
	WHERE	DI_Rate > 0

	CREATE TABLE #MetricGamingData (LicenseeID INT, PartyID INT, RptDate DATE, CurrencyID INT, LicenseeWL MONEY, AmtLicensee MONEY)
	INSERT INTO #MetricGamingData (LicenseeID, PartyId, RptDate, CurrencyId, LicenseeWL, AmtLicensee)
	SELECT	b.SiteID,
			p.PartyId,
			b.rptDate,
			b.CurrencyID,
			SUM(CASE WHEN p.IsDeposit = 0 
						THEN (-b.WinLoss - b.WinLossA - b.WinLossS - b.WinLossM - b.CommissionS)
						ELSE -b.WinLoss
				END) LicenseeWL,
			SUM(CASE WHEN p.IsDeposit = 0 
						THEN (-b.WinLoss - b.WinLossA - b.WinLossS - b.WinLossM - b.CommissionS) * p.Rate
						ELSE -b.WinLoss * p.Rate 
				END) AmtLicensee
	FROM	bodb_licensee.dbo.rpt_Betting b WITH (NOLOCK)
			INNER JOIN @PartyChargeInfo p ON b.SiteID = p.LicenseeId 
			AND b.rptDate BETWEEN p.FromDate AND p.ToDate
	WHERE	b.rptDate BETWEEN @FDate AND @TDate
			AND (b.CurrencyID <> 20)
			AND b.[Status] BETWEEN 111 AND 113
			AND b.customercategory NOT IN (27, 28)
			AND b.Bettype BETWEEN 800 AND 899 -- Metric Gaming Bettype In Sportsbook
	GROUP BY b.rptdate, b.SiteId, b.CurrencyID, p.PartyId

	-- Apply currency rate
	UPDATE b
	SET LicenseeWL = LicenseeWL * e.Rate,
		AmtLicensee = AmtLicensee * e.Rate
	FROM #MetricGamingData b
		INNER JOIN #ExchangeOANDA e ON e.ExchangeDate = b.RptDate AND e.ExchangeID = b.CurrencyID

	-- Get Metric Gaming charge info
	DECLARE @ProductChargeInfo TABLE (
			Rate FLOAT,
			FromDate SMALLDATETIME,
			ToDate SMALLDATETIME,
			MinAmount MONEY,
			MaxAmount MONEY)

	INSERT INTO @ProductChargeInfo(Rate, FromDate, ToDate, MinAmount, MaxAmount)
	SELECT	ci.Rate,
			CASE WHEN @FDate >= ci.FromDate THEN @FDate ELSE ci.FromDate END AS FromDate,
			CASE WHEN @TDate < ci.ToDate THEN @TDate ELSE ci.ToDate END AS ToDate,
			ci.MinAmount * ex.Rate,
			ci.MaxAmount * ex.Rate
	FROM bodb_licensee.dbo.OAS_ChargeInfo ci
	INNER JOIN #ExchangeOANDA ex ON ci.BaseCurrencyId = ex.ExchangeID AND ex.ExchangeDate = @TDate
	WHERE ci.ProductID = 0 AND ci.FromParty = 1 AND ci.ChargeType = 4 -- Get Charge Rate to Billing for Metric Gaming
		AND ((ci.FromDate BETWEEN @FDate AND @TDate)
			OR (ci.ToDate BETWEEN @FDate AND @TDate)
			OR (ci.FromDate < @FDate AND @TDate < ci.ToDate))

	; WITH WLAmount AS
	(
		SELECT CONVERT(VARCHAR(2), RptDate, 106) rptDate,
			rptDate FullDate,
			SUM(AmtLicensee) AS AmtLicensee
		FROM #MetricGamingData
		GROUP BY CONVERT(VARCHAR(2), RptDate, 106), rptDate
	),
	MetricGamingFee AS
	(
		SELECT wl.*, ci.MinAmount, ci.MaxAmount, ci.Rate, 
			CASE 
				WHEN (AmtLicensee < 0 AND ci.MinAmount = 0) OR (AmtLicensee >= ci.MinAmount) THEN 
					CASE 
						WHEN AmtLicensee > MaxAmount THEN ci.MaxAmount - ci.MinAmount
						ELSE AmtLicensee - ci.MinAmount
					END
				ELSE 0
			END * ci.Rate AS AmtByRange
		FROM WLAmount wl
			INNER JOIN @ProductChargeInfo ci ON wl.FullDate BETWEEN ci.FromDate AND ci.ToDate
	),
	AmtByDate AS
	(
		SELECT m.rptDate, SUM(AmtByRange) AS AmtByDate	
		FROM MetricGamingFee m
		GROUP BY m.rptDate
	)
	UPDATE r
	SET PayToMetricGaming = AmtByDate
	FROM AmtByDate m
		INNER JOIN #FinalResult r ON r.RptDate = m.rptDate

	-- Calculate Pay to Metric gaming amount
	;WITH WLAmount AS
	(
		SELECT ci.*, SUM(d.AmtLicensee) AS AmtLicensee
		FROM @ProductChargeInfo ci
			INNER JOIN #MetricGamingData d ON d.RptDate BETWEEN ci.FromDate AND ci.ToDate
		GROUP BY ci.Rate, ci.FromDate, ci.ToDate, ci.MinAmount, ci.MaxAmount
	),
	AmtByRange AS
	(
		SELECT wl.*, 
			CASE 
				WHEN AmtLicensee>MinAmount THEN 
					CASE 
						WHEN AmtLicensee > MaxAmount THEN MaxAmount - MinAmount 
						ELSE AmtLicensee - MinAmount 
					END
				ELSE 0 
			END * Rate AS AmtDue
		FROM WLAmount wl
	)
	UPDATE #FinalResult
	SET PayToMetricGaming = (SELECT SUM(AmtDue) FROM AmtByRange)
	WHERE RptDate LIKE 'FullRange'

	---------------------------------------------------- Pay to Muay Thai -------------------------------------------------------

	DELETE FROM @PartyChargeInfo
	INSERT INTO @PartyChargeInfo(PartyId, LicenseeId, IsDeposit, ProductID, Rate, Fromdate, Todate)
	SELECT	PartyID, LicenseeID, isDeposit, ProductID, DI_Rate, Fromdate, Todate
	FROM	bodb_licensee.dbo.LA_f_ChargeInfo(@PartyIds, @FDate, @TDate, 'SB', 'OA', 0)

	DECLARE @MuayThaiData TABLE (rptDate DATE, AmtDueMuayThai MONEY)
	INSERT INTO @MuayThaiData
	SELECT	b.rptDate,
			SUM(ISNULL(b.WLShare * e.Rate, 0) + ISNULL(b.CommShare * e.Rate, 0)) AmtDueMuayThai
	FROM	bodb_LicenseeReport.dbo.rpt_BettingBySport b WITH (NOLOCK)
			INNER JOIN @PartyChargeInfo p ON b.ProductID = p.ProductID 
											AND b.SiteID = p.LicenseeId
											AND b.rptDate BETWEEN p.FromDate AND p.ToDate
			INNER JOIN #ExchangeOANDA e ON e.ExchangeDate = b.rptDate AND e.ExchangeID = b.CurrencyId
	WHERE	b.rptDate BETWEEN @FDate AND @TDate
			AND (b.CurrencyID <> 20)
			AND b.StatusId BETWEEN 111 AND 113
			AND b.customercategory NOT IN (27, 28)
			AND b.SportType = 44 -- Muay Thai
	GROUP BY b.rptdate

	-- Update Full range value
	UPDATE #FinalResult 
	SET PayToMuayThai = (SELECT ISNULL(SUM(AmtDueMuayThai), 0) FROM @MuayThaiData)
	WHERE RptDate LIKE 'FullRange'

	-- Update daily amount
	UPDATE r
	SET PayToMuayThai = d.AmtDueMuayThai
	FROM #FinalResult r
		INNER JOIN @MuayThaiData d ON r.RptDate = CONVERT(VARCHAR(2), d.RptDate, 106)

	---------------------------------------------------- Select the output -------------------------------------------------------
	DECLARE @SQL VARCHAR(1000)
	SELECT @SQL =	'SELECT * ' + CHAR(13) +
					'FROM	(SELECT [Order], [RptDate], Figure, ISNULL(value, 0) value FROM #FinalResult' + CHAR(13) +
							'CROSS APPLY' + CHAR(13) +
							'(SELECT 1, ''House Income'', LicenseeWL' + CHAR(13) +
							'UNION ALL' + CHAR(13) +
							'SELECT 3, ''Other Fees Charge Licensees'', OtherFees' + CHAR(13) +
							'UNION ALL' + CHAR(13) +
							'SELECT 4, ''Pay to Muay Thai'', PayToMuayThai' + CHAR(13) +
							'UNION ALL' + CHAR(13) +
							'SELECT 5, ''Pay to Metric Gaming'', PayToMetricGaming) c ([Order], Figure, value)) a' + CHAR(13) +
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
	DROP TABLE #TempData
	DROP TABLE #SBResult
	DROP TABLE #FinalResult
	DROP TABLE #MetricGamingData
END
GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_HouseNetIncome_SB_Deposit] TO [bodbAdminNet]
GO
GRANT VIEW definition ON [dbo].[Acc_Rpt_HouseNetIncome_SB_Deposit] TO vnteam