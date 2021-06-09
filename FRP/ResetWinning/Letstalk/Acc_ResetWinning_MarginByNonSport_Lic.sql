/*<info serverAlias="DBEXT-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_ResetWinning_MarginByNonSport_Lic]
	@Winlostdate SMALLDATETIME,
	@BaseCurrency VARCHAR(10) = 'CNY'
AS 
 
/*		
	Created: 20210422@Sophia
	Task: Reset Winning - Margin By Non Sport (adhoc) for Licensee [Redmine: #153868]
	DB: DBEXT.BODB02
	
	Revision:
		- 20210422@Sophia: Initial SP [Redmine: #153868]
		- 20210524@Sophia: Add VGaming (Amount due to Jackpot Pool) [RedmineId: #155697]
		- 20200531@Sophia: Use base currency CNY and Licensee Rate of LA [Redmind: #155697]
		 
	Param Explanation:
		 
	   
*/ 
BEGIN	
	SET NOCOUNT ON

	DECLARE @MinTransID_RNG BIGINT,  @MinTransID_LC BIGINT, @MaxTransID_RNG BIGINT,  @MaxTransID_LC BIGINT
	DECLARE @WLdate SMALLDATETIME = @Winlostdate

	SELECT  @MinTransID_RNG = MIN (TransID) , @MaxTransID_RNG = MAX(TransID) 
	FROM	dbo.BettransRNG WITH (NOLOCK)
	WHERE	winlostdate = @WLdate


	SELECT  @MinTransID_LC = MIN (TransID), @MaxTransID_LC = MAX(TransID) 
	FROM	dbo.BettransLC WITH (NOLOCK)
	WHERE	winlostdate = @WLdate

	------Get Sport Bettype Matrix------
	/*
	CREATE TABLE  #SportBettype (ProductName VARCHAR(256), ProductID INT, Bettype INT, RefTable SMALLINT )
	INSERT INTO #SportBettype
	SELECT	CASE WHEN s.SubProduct = 'MG-SuperLive' THEN 'Metric Gaming - Super Live'
			WHEN s.SubProduct = 'Bet Builder' THEN 'Bet Builder'
			ELSE p.ProductName END AS ProductName, 
			s.ProductID, s.Bettype, s.RefTable
	FROM dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', 0) s
	LEFT JOIN dbo.Products p WITH (NOLOCK) 
			ON p.ProductID = s.ProductID
	WHERE  s.ProductID <> 1 
		OR s.Bettype BETWEEN 801 and 806  ---'MG-SuperLive'
		OR s.Bettype = 38    ----'Bet Builder' 
		*/
		
		
	CREATE TABLE  #SportBettype (SubProduct VARCHAR(256), ProductID INT, Bettype INT, RefTable SMALLINT, Product3rdId INT, ProductPrefix VARCHAR(10) )
	INSERT INTO #SportBettype
	SELECT	CASE WHEN s.SubProduct = 'MG-SuperLive' THEN 'Metric Gaming - Super Live'
			WHEN s.SubProduct = 'Bet Builder' THEN 'Bet Builder'
			ELSE '' END AS SubProduct, 
			s.ProductID, s.Bettype, s.RefTable, ISNULL(d.ProductId, 0) AS Product3rdId,
			p.ProductPrefix
	FROM dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', 0) s
	INNER JOIN dbo.Products p WITH (NOLOCK) 
			ON p.ProductID = s.ProductID
	LEFT JOIN bodb_Licensee.dbo.Product3rd d WITH (NOLOCK) 
			ON p.ProductPrefix = d.ProductPrefix
	WHERE  (p.Enabled = 1 OR d.Enabled = 1)
		AND (s.ProductID <> 1 
			OR s.Bettype BETWEEN 801 and 806  ---'MG-SuperLive'
			OR s.Bettype = 38    ----'Bet Builder' 
			)
		 	
		
	UPDATE s
	SET SubProduct = f.BettypeGroup
	FROM #SportBettype s 
	INNER JOIN f_BettypePrizeGroup() f 
		ON f.Bettype = s.Bettype

	
	UPDATE #SportBettype
	SET SubProduct = 'Tip'
	WHERE bettype = 3007
		AND ProductID = 39   ---- SA Gaming

	----- End get sport bettype 
	
	
	---- Get product list
	DECLARE @ProductCodes VARCHAR(MAX) = ''
	SELECT @ProductCodes = COALESCE(@ProductCodes + ',', '') + CONVERT(VARCHAR(10), p.ProductPrefix)  
	FROM (SELECT DISTINCT ProductPrefix FROM  #SportBettype p ) p
		
	

	------Get Base currency CNY ------- 
		CREATE TABLE #ExchangeOANDA(
				ExchangeDate    DATE
			  , ExchangeID      INT
			  , BaseCurrencyRate  FLOAT);

			INSERT INTO #ExchangeOANDA(ExchangeDate
								, ExchangeID
								, BaseCurrencyRate)
				 SELECT ExchangeDate
					 , ExchangeID
					 , BaseCurrencyRate
				 FROM bodb02.dbo.LA_f_ExchangeDailySel
					 (@Winlostdate, @Winlostdate, @BaseCurrency);
			
	------End of get Base currency CNY -------

	-------------- Get Charge Info -------------------
	
		----- Get Supers List -----
		CREATE TABLE #Supers (Custid INT, Site VARCHAR(50), PartyId INT)
		
		INSERT INTO #Supers (CustId, Site, PartyId)
		SELECT c.Custid, c.Site, ISNULL(p.PartyId,0) AS PartyId
		FROM dbo.Dep_CustSuper c WITH (NOLOCK) 	
		INNER JOIN bodb_Licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeName = c.site	
		LEFT JOIN bodb_licensee.dbo.OAS_Party p WITH (NOLOCK) ON p.OldRefID = l.LicenseeID AND p.PartyType = 1  
		LEFT JOIN bodb_licensee.dbo.OAS_PartyDetail pd WITH (NOLOCK) ON pd.PartyID = p.PartyID AND pd.IsDeposit = 1 
		WHERE  c.Site NOT IN ('Saba789')
			AND c.currency <> 20 
			
			
		--- Get party list		
		DECLARE @PartyIds VARCHAR(MAX) 	 
		SELECT @PartyIds = COALESCE(@PartyIds + ',', '') + CONVERT(VARCHAR(10), p.PartyId) 
		FROM (SELECT DISTINCT PartyId FROM  #Supers) p 

 		
		-- Get charge rate
		CREATE TABLE #PartyChargeInfo (ChargeId INT, PartyId INT, Product3rdId INT, FromDate DATE, ToDate DATE, Rate FLOAT, Bettype INT, ChargeType INT)	

		INSERT INTO #PartyChargeInfo (ChargeId, PartyId, Product3rdId, FromDate, ToDate, Rate, Bettype, ChargeType)					
		SELECT DISTINCT ci.ChargeId, ci.PartyId, ci.ProductId AS Product3rdId, ci.FromDate, ci.ToDate, ci.DI_Rate AS Rate, 
			   ci.Bettype AS Bettype, ci.ChargeType
		FROM bodb_licensee.dbo.LA_f_ChargeInfo (@PartyIds, @Winlostdate, @Winlostdate, @ProductCodes,'OA', 1) ci
		WHERE ci.DI_Rate > 0
			 AND (
				ci.ChargeType = 1		
				--OR ci.ChargeType IN (6, 7) AND ci.ProductId = 15 -- CB
				--OR ci.ChargeType = 5 AND ci.ProductId = 25 -- CO
				OR ci.ChargeType = 12 AND ci.ProductId = 39 -- SAG
			)
		
		CREATE TABLE #PartyChargeByCurrencyInfo (ChargeId INT, CurrencyId INT, Rate FLOAT)
		
		INSERT INTO #PartyChargeByCurrencyInfo (ChargeId, CurrencyId, Rate)		 
	    SELECT pc.ChargeId, pc.CurrencyId, pc.Rate
		FROM bodb_licensee.dbo.LA_f_ChargeInfo (@PartyIds, @Winlostdate, @Winlostdate, @ProductCodes,'OA', 1) ci
			INNER JOIN bodb_Licensee.dbo.LA_ChargeRateByCurrency pc WITH (NOLOCK) ON ci.ChargeId = pc.ChargeId
		WHERE ci.ChargeType = 1 AND ci.DI_Rate > 0	 

	---------------- End Get Charge Info ------------------				
			
	--------------------------------------------------------------------------------------------------------- 
		CREATE TABLE #WL 
		(	
			PartyID			INT,  			
			Currency		INT,	
			Product3rdId	INT,
			SubProduct 		VARCHAR(256),			
			BettypeType		VARCHAR(50),
			TurnOver		MONEY,
			Winlost			MONEY,   
			Comm			MONEY,
			FullContribution MONEY,
			HouseContribution MONEY,
			FreeBet 		MONEY
		) 


		------1. Bettrans
		INSERT INTO #WL (PartyID, Currency, Product3rdId, SubProduct, BettypeType, TurnOver, Winlost, Comm, FullContribution, HouseContribution, FreeBet) 
		SELECT  s.PartyID, b.Currency, 				
				CASE WHEN sb.productID = 1  
					THEN CASE WHEN ba.TransID IS NOT NULL THEN 3 ELSE 0 END 
					ELSE sb.Product3rdID END AS Product3rdId, 
				sb.SubProduct, 
				'' AS BettypeType,					
				SUM (   CASE 
							 WHEN b.StatusID = 111 OR b.Bettype IN (911,912) THEN 0
						     WHEN ABS(modds) = 0.25 AND b.Bettype <> 29 THEN ABS(Stake) / 2 ELSE  ABS(Stake) END 	
						* CASE WHEN @BaseCurrency = '' THEN b.actualrate ELSE e.BaseCurrencyRate END	 
					) AS TurnOver,
				SUM(	CASE WHEN sb.ProductId IN (15, 25)
							THEN (ISNULL(winlost,0) - ISNULL(actual_stake,0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)) 
							ELSE (ISNULL(winlost,0) - ISNULL(actual_stake,0))
							END	
						* CASE WHEN @BaseCurrency = '' THEN b.actualrate ELSE e.BaseCurrencyRate END
					) AS winlost,			
				SUM (CASE WHEN sb.productID = 1  
							THEN CASE WHEN ba.TransID IS NOT NULL THEN b.Comm ELSE 0 END   --- BA Commision
						  WHEN sb.productID = 31
							THEN playercomm + comm     --- Charge comm of Exchange product 
						  ELSE 0 END
						 * CASE WHEN @BaseCurrency = '' THEN b.actualrate ELSE e.BaseCurrencyRate END) AS Comm,
				0 AS FullContribution,
				0 AS HouseContribution,
				0 AS FreeBet
		FROM dbo.bettrans b WITH (NOLOCK)  
		INNER JOIN #SportBettype sb ON sb.BetType = b.bettype 
		LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction_Active ba WITH (NOLOCK)
			ON 	ba.TransID = b.TransID
		INNER JOIN #Supers s ON s.Custid = b.srecommend
		LEFT JOIN #ExchangeOANDA e ON e.ExchangeID = b.Currency	
		WHERE   b.Winlostdate = @WLdate
			AND b.statusid IN (111, 112, 113)		
			AND b.bettype < 19001
		--	AND b.Bettype <> 8000   --- exclude Exchange Product
			AND b.MatchID >= 0
			AND sb.RefTable NOT IN (1,2)	
			AND b.Recommend NOT IN (52466,5707545)  --- Exclude 8RM, BARM		
			AND CASE WHEN b.Bettype IN (8000, 1800) THEN BetID ELSE 0 END = 0    --- exclude adj tickets			
		GROUP BY s.PartyID, s.Site, b.Currency, sb.SubProduct,			
				CASE WHEN sb.productID = 1  
					THEN CASE WHEN ba.TransID IS NOT NULL THEN 3 ELSE 0 END 
					ELSE sb.Product3rdID END  			 
 
			 
		------2. BettransRNG
		INSERT INTO #WL (PartyID, Currency, Product3rdId, SubProduct, BettypeType, TurnOver, Winlost, Comm, FullContribution, HouseContribution, FreeBet) 
		SELECT  s.PartyID, b.Currency, 				
				sb.Product3rdID AS Product3rdId, 
				sb.SubProduct, 
				'' AS BettypeType,	 
				SUM (   CASE WHEN b.StatusID = 111 THEN 0 ELSE ABS(Stake) END 	
						* CASE WHEN @BaseCurrency = '' THEN b.actualrate ELSE e.BaseCurrencyRate END				
					)	 AS TurnOver,		 
				SUM(
						(CASE
							WHEN sb.SubProduct IN('Contribution','Prize') OR b.ProductID IN (150,173) --- freebet Saba.Cub and VGaming
							THEN 0  
							ELSE winlost - actual_stake  
							END) 
						* CASE WHEN @BaseCurrency = '' THEN b.actualrate ELSE e.BaseCurrencyRate END	
					) AS winlost, 
				0 AS Comm,
				SUM	((CASE
							WHEN sb.SubProduct IN('Contribution')
							THEN b.ContributionStake3rd 
							ELSE 0
							END) 
						* CASE WHEN @BaseCurrency = '' THEN b.actualrate ELSE e.BaseCurrencyRate END		
					)AS FullContribution,
				SUM	((CASE
							WHEN sb.SubProduct IN('Contribution')
								THEN b.ContributionStake3rd + b.swinlost + b.mwinlost + b.awinlost  
							ELSE 0
							END)
						* CASE WHEN @BaseCurrency = '' THEN b.actualrate ELSE e.BaseCurrencyRate END		
					) AS HouseContribution,					
				SUM (CASE WHEN b.ProductID IN (150,173) THEN winlost - actual_stake ELSE 0 END 
						* CASE WHEN @BaseCurrency = '' THEN b.actualrate ELSE e.BaseCurrencyRate END	
					) AS FreeBet --- freebet Saba.Cub and VGaming
				
		FROM dbo.bettransRNG b WITH (NOLOCK, index = PK_bettransRnG)  
		INNER JOIN #SportBettype sb ON sb.BetType = b.gameID	
		INNER JOIN #Supers s ON s.Custid = b.srecommend
		LEFT JOIN #ExchangeOANDA e ON e.ExchangeID = b.Currency	
		WHERE   b.Winlostdate = @WLdate
			AND b.statusid IN (111, 112, 113)
			AND sb.RefTable = 1	
			AND b.transID BETWEEN @MinTransID_RNG AND @MaxTransID_RNG
			AND b.srecommend IN (SELECT custid FROM #Supers)
		GROUP BY s.PartyID, b.Currency, 				
				sb.Product3rdID , 
				sb.SubProduct  	
	
		------3. BettransLC
		INSERT INTO #WL (PartyID, Currency, Product3rdId, SubProduct, BettypeType, TurnOver, Winlost, Comm, FullContribution, HouseContribution, FreeBet) 
		SELECT  s.PartyID, b.Currency, 				
				sb.Product3rdID AS Product3rdId, 
				sb.SubProduct, 
				CASE WHEN sb.SubProduct = 'Tip' THEN sb.SubProduct ELSE '' END AS BettypeType,	  
				SUM (   CASE WHEN b.StatusID = 111 THEN 0 ELSE ABS(Stake) END
						* CASE WHEN @BaseCurrency = '' THEN b.actualrate ELSE e.BaseCurrencyRate END	
					)	 AS TurnOver,				
					
				SUM(
						( winlost - actual_stake)
						* CASE WHEN @BaseCurrency = '' THEN b.actualrate ELSE e.BaseCurrencyRate END							
					) AS winlost,
				0 AS Comm,
				0 AS FullContribution,
				0 AS HouseContribution,
				0 AS FreeBet	
		FROM dbo.bettransLC b WITH (NOLOCK, index = PK_bettransLC)		
		INNER JOIN #SportBettype sb ON sb.BetType = b.gameID 
		INNER JOIN #Supers s ON s.Custid = b.srecommend
		LEFT JOIN #ExchangeOANDA e ON e.ExchangeID = b.Currency	
		WHERE   b.Winlostdate = @WLdate
			AND b.statusid IN (111, 112, 113)
			AND sb.RefTable = 2			
			AND b.srecommend IN (SELECT custid FROM #Supers)
			AND b.transID BETWEEN @MinTransID_LC AND @MaxTransID_LC
		GROUP BY s.PartyID, b.Currency, 				
				sb.Product3rdID , 
				sb.SubProduct,
				CASE WHEN sb.SubProduct = 'Tip' THEN sb.SubProduct ELSE '' END
	
		-----------------------------------------------------------------------------------------------
	
		
		----- Get Data -----		
		CREATE TABLE #Winlost (Product3rdId INT, ProductName VARCHAR(50), TurnOver MONEY, Margin MONEY , HouseWinlost MONEY )  
					
		INSERT INTO #Winlost (Product3rdId, ProductName, TurnOver, Margin, HouseWinlost)						
		SELECT  w.Product3rdId, 
				CASE WHEN w.Product3rdId IN (0,1) AND w.SubProduct <> '' THEN w.SubProduct ELSE rd.ProductName END AS ProductName,		 
				SUM(CASE WHEN w.Product3rdId IN (15, 25, 37) 
						THEN ISNULL(w.TurnOver,0)   ---- tpositiontaking = 0 
						ELSE ISNULL(w.TurnOver,0)* ISNULL(lc.Rate, p.Rate) 
						END  ) AS TurnOver, 
				
				CASE WHEN 	SUM(CASE WHEN w.Product3rdId IN (15, 25, 37) 
								THEN ISNULL(w.TurnOver,0)    
								ELSE ISNULL(w.TurnOver,0)* ISNULL(lc.Rate, p.Rate)  
								END  )  = 0 
					THEN 0 
					ELSE  SUM (CASE
								WHEN w.Product3rdId IN (15, 25) THEN -w.Winlost  ---- House WL of Colossusbet and Cashout
								WHEN w.Product3rdId IN (37) THEN -w.Winlost   -- Member WL of saba promotion 
								ELSE
									(- w.Winlost - (w.FullContribution - w.HouseContribution)) * ISNULL(lc.Rate, p.Rate)
									- w.HouseContribution  - FreeBet - CASE WHEN w.Product3rdId IN (3,31) THEN w.Comm ELSE 0 END -- exchange product & BAComm
									END  
								) /
							SUM(CASE WHEN w.Product3rdId IN (15, 25, 37) 
								THEN ISNULL(w.TurnOver,0)     
								ELSE ISNULL(w.TurnOver,0)* ISNULL(lc.Rate, p.Rate)  
								END ) 
								* 100 
					END 			
					AS Margin, 				
				SUM(CASE
						WHEN w.Product3rdId IN (15, 25, 37) THEN -w.Winlost  ---- House WL of Colossusbet and Cashout, Member WL of saba promotion 
						ELSE
							(- w.Winlost - (w.FullContribution - w.HouseContribution)) * ISNULL(lc.Rate, p.Rate)
							- w.HouseContribution - FreeBet 
							- (CASE	WHEN w.Product3rdId IN (3) THEN w.Comm     -- BA Comm of bet builder
									WHEN w.Product3rdId IN (31) THEN w.Comm * ISNULL(lc.Rate, p.Rate)    --- exchange product
									ELSE 0 END ) -- exchange product & BAComm
					END  ) AS HouseWinlost 
		FROM	#wl w 
		LEFT JOIN bodb_Licensee.dbo.Product3rd rd WITH (NOLOCK) ON rd.ProductID = w.Product3rdId
						
		LEFT JOIN #PartyChargeInfo p 
					ON 	p.PartyId = w.PartyId 
					AND p.Product3rdId = w.Product3rdId
					AND p.Bettype = -1
 					AND (
						(w.Product3rdId IN (39) AND p.ChargeType = 12 AND w.BettypeType = 'Tip')
						 OR (w.Product3rdId IN (39) AND p.ChargeType = 1 AND w.BettypeType = '')
						 OR (w.Product3rdId NOT IN (39))
						)					
		LEFT JOIN #PartyChargeByCurrencyInfo lc 
			ON 	p.ChargeId = lc.ChargeId 
			AND w.Currency = lc.CurrencyId	
		GROUP BY w.Product3rdId, CASE WHEN w.Product3rdId IN (0,1) AND w.SubProduct <> '' THEN w.SubProduct ELSE rd.ProductName END  

		
		----- Get Data -----
		SELECT  a.ProductName, a.TurnOver, -a.Margin AS Margin , -a.HouseWinlost AS HouseWinlost
		FROM  (
				SELECT	w.Product3rdId, w.ProductName, 
						w.TurnOver, 
						w.Margin ,
						w.HouseWinlost
				FROM 	#Winlost w 				
				UNION 
				SELECT	0 AS Product3rdId, 'All Non Sports' AS ProductName, 
						SUM (w.TurnOver) AS TurnOver, 
						CASE WHEN SUM (w.TurnOver) = 0 THEN 0 ELSE SUM (HouseWinlost) / SUM (w.TurnOver) * 100 END AS Margin , 
						SUM (w.HouseWinlost) AS HouseWinlost
				FROM 	#Winlost w  
				HAVING  SUM (w.TurnOver) IS NOT NULL 
				) A
		ORDER BY A.Product3rdId
				

	DROP TABLE #SportBettype
	DROP TABLE #WL
	DROP TABLE #Supers
	DROP TABLE #Winlost 
	DROP TABLE #ExchangeOANDA
	DROP TABLE #PartyChargeInfo
	DROP TABLE #PartyChargeByCurrencyInfo
		
END

