/*<info serverAlias="DBEXT-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_ResetWinning_MarginBySite_Lic]
	@Winlostdate SMALLDATETIME,
	@BaseCurrency VARCHAR(10) = 'CNY'
AS 
 
/*		
	Created: 20200531@Sophia
	Task: Reset Winning - Margin By Site by Licensee (adhoc) [Redmind: #155697]
	DB: DBEXT.BODB02
	
	Revision:
		- 20200531@Sophia: Initial SPs - Use base currency CNY and Licensee Rate of LA [Redmind: #155697]
		
	Param Explanation:
	Original SPs: Acc_ResetWinning_MarginBySite	 
	   
*/ 
BEGIN	
	SET NOCOUNT ON


	DECLARE @MinTransID_RNG BIGINT,  @MinTransID_LC BIGINT, @MaxTransID_RNG BIGINT,  @MaxTransID_LC BIGINT

	SELECT  @MinTransID_RNG = MIN (TransID) , @MaxTransID_RNG = MAX(TransID) 
	FROM	dbo.BettransRNG WITH (NOLOCK)
	WHERE	winlostdate = @Winlostdate


	SELECT  @MinTransID_LC = MIN (TransID), @MaxTransID_LC = MAX(TransID) 
	FROM	dbo.BettransLC WITH (NOLOCK)
	WHERE	winlostdate = @Winlostdate


	------Get Sport Bettype Matrix------
	
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
	WHERE  ---s.ProductID <> 31    ---  exclude exchange product 
			(p.Enabled = 1 OR d.Enabled = 1)
			
/*INSERT INTO #SportBettype
	SELECT SubProduct, ProductID, Bettype , RefTable, 3 AS Product3rdId  --- BA product
	FROM #SportBettype
	WHERE ProductID = 1
	*/
	
	UPDATE s
	SET SubProduct = f.BettypeGroup
	FROM #SportBettype s 
	INNER JOIN f_BettypePrizeGroup() f 
		ON f.Bettype = s.Bettype
		
	UPDATE #SportBettype
	SET SubProduct = 'OddsSpreadAdj'
	WHERE bettype = 999
		AND ProductID = 1

	
	UPDATE #SportBettype
	SET SubProduct = 'Tip'
	WHERE bettype = 3007
		AND ProductID = 39   ---- SA Gaming
		 
	
	----- End get sport bettype -----	
	
	---- Get product list
	DECLARE @ProductCodes VARCHAR(MAX) = 'BA'
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
		FROM (SELECT DISTINCT PartyId FROM #Supers) p 
 		
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
			Site			VARCHAR(50),			
			Currency		INT,
			SB				TINYINT,
			Product3rdId	INT,
			BettypeType		VARCHAR(50),
			TurnOver		MONEY,
			Winlost			MONEY,  
			OddsSpreadAdj	MONEY,
			Comm			MONEY,
			FullContribution MONEY,
			HouseContribution MONEY,
			FreeBet 		MONEY
		) 

		------1. Bettrans: 
		INSERT INTO #WL (PartyID, Site, Currency, SB, Product3rdId, BettypeType, TurnOver, winlost, OddsSpreadAdj, Comm, FullContribution, HouseContribution, FreeBet)
		SELECT  s.PartyID, s.Site, b.Currency,
				CASE WHEN sb.productID = 1 AND sb.SubProduct = '' THEN 1 ELSE 0 END AS SB,
				
				CASE WHEN sb.productID = 1  
					THEN CASE WHEN ba.TransID IS NOT NULL THEN 3 ELSE 0 END 
					ELSE sb.Product3rdID END AS Product3rdId, 
				'' AS BettypeType,						
				SUM (   CASE WHEN b.StatusID = 111 OR b.Bettype IN (911,912) THEN 0 ELSE
						CASE WHEN ABS(modds) = 0.25 AND b.Bettype <> 29 THEN ABS(Stake) / 2 ELSE  ABS(Stake) END END						
					) AS TurnOver,
				SUM(	CASE WHEN sb.ProductId IN (15, 25)
							THEN (ISNULL(winlost,0) - ISNULL(actual_stake,0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)) 
							ELSE (ISNULL(winlost,0) - ISNULL(actual_stake,0))
							END									 
					) AS winlost,			
				SUM (CASE WHEN sb.productID = 1 AND sb.SubProduct = 'OddsSpreadAdj' THEN awinlost ELSE 0 END ) AS OddsSpreadAdj,
				SUM (CASE WHEN sb.productID = 1  
							THEN CASE WHEN ba.TransID IS NOT NULL THEN b.Comm ELSE 0 END   --- BA Commision
						  WHEN sb.productID = 31
							THEN playercomm + comm     --- Charge comm of Exchange product 
						 ELSE 0 END) AS Comm,
				0 AS FullContribution,
				0 AS HouseContribution,
				0 AS FreeBet
		FROM dbo.bettrans b WITH (NOLOCK)  
		INNER JOIN #SportBettype sb ON sb.BetType = b.bettype 
		LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction_Active ba WITH (NOLOCK)
			ON 	ba.TransID = b.TransID
		INNER JOIN #Supers s ON s.Custid = b.srecommend
		WHERE   b.Winlostdate = @WinlostDate
			AND b.statusid IN (111, 112, 113)		
			AND b.bettype < 19001
		--	AND b.Bettype <> 8000   --- exclude Exchange Product
			AND b.MatchID >= 0
			AND sb.RefTable NOT IN (1,2)	
			AND b.Recommend NOT IN (52466,5707545)  --- Exclude 8RM, BARM			
		GROUP BY s.PartyID, s.Site, b.Currency,
				CASE WHEN sb.productID = 1 AND sb.SubProduct = '' THEN 1 ELSE 0 END ,				
				CASE WHEN sb.productID = 1  
					THEN CASE WHEN ba.TransID IS NOT NULL THEN 3 ELSE 0 END 
					ELSE sb.Product3rdID END  
			 
		------2. BettransRNG
		INSERT INTO #WL ( PartyID, Site, Currency, SB, Product3rdId, BettypeType, TurnOver, winlost,OddsSpreadAdj,Comm,FullContribution,HouseContribution, FreeBet)
		SELECT  s.PartyID, s.Site, b.Currency,
				0 AS SB, 
				sb.Product3rdID  AS Product3rdId,
				'' AS BettypeType,
				SUM (   CASE WHEN b.StatusID = 111 THEN 0 ELSE ABS(Stake) END 
					)	 AS TurnOver,				
					
				SUM(
						(CASE
							WHEN sb.SubProduct IN('Contribution','Prize') OR b.ProductID IN (150,173) --- freebet Saba.Cub and VGaming
							THEN 0  
							ELSE winlost - actual_stake  
							END) 
					) AS winlost,	
				0 AS OddsSpreadAdj,
				0 AS Comm,
				SUM	((CASE
							WHEN sb.SubProduct IN('Contribution')
							THEN b.ContributionStake3rd 
							ELSE 0
							END)   
					)AS FullContribution,
				SUM	((CASE
							WHEN sb.SubProduct IN('Contribution')
								THEN b.ContributionStake3rd + b.swinlost + b.mwinlost + b.awinlost  
							ELSE 0
							END) 
					) AS HouseContribution,					
				SUM (CASE WHEN b.ProductID IN (150,173) THEN winlost - actual_stake ELSE 0 END ) AS FreeBet --- freebet Saba.Cub and VGaming
		FROM dbo.bettransRNG b WITH (NOLOCK, index = PK_bettransRnG)  
		INNER JOIN #SportBettype sb ON sb.BetType = b.gameID 		 
		INNER JOIN #Supers s ON s.Custid = b.srecommend
		WHERE   b.Winlostdate = @WinlostDate
			AND b.statusid IN (111, 112, 113)
			AND sb.RefTable = 1	
			AND b.transID BETWEEN @MinTransID_RNG AND @MaxTransID_RNG
		GROUP BY s.PartyID, s.Site, b.Currency, sb.Product3rdID 	
	
		------3. BettransLC
		INSERT INTO #WL (PartyID, Site, Currency, SB, Product3rdID, BettypeType, TurnOver, winlost, OddsSpreadAdj,Comm,FullContribution,HouseContribution, FreeBet)
		SELECT  s.PartyID, s.Site, b.Currency,
				0 AS SB, 
				sb.Product3rdID AS Product3rdID,
				CASE WHEN sb.SubProduct = 'Tip' THEN sb.SubProduct ELSE '' END AS BettypeType,	
				SUM (   CASE WHEN b.StatusID = 111 THEN 0 ELSE ABS(Stake) END
					)	 AS TurnOver,					
					
				SUM(
						( winlost - actual_stake)			
					) AS winlost,
				0 AS OddsSpreadAdj,
				0 AS Comm,
				0 AS FullContribution,
				0 AS HouseContribution,
				0 AS FreeBet
		FROM dbo.bettransLC b WITH (NOLOCK, index = PK_bettransLC)  
		INNER JOIN #SportBettype sb ON sb.BetType = b.gameID 
		INNER JOIN #Supers s ON s.Custid = b.srecommend
		WHERE   b.Winlostdate = @WinlostDate
			AND b.statusid IN (111, 112, 113)
			AND sb.RefTable = 2			
			AND b.transID BETWEEN @MinTransID_LC AND @MaxTransID_LC
		GROUP BY s.PartyID, s.Site, b.Currency, sb.Product3rdID, CASE WHEN sb.SubProduct = 'Tip' THEN sb.SubProduct ELSE '' END 
	

		-----------------------------------------------------------------------------------------------
 

		-----------------------------------------------------------------------------------------------
		----- Get Data -----		
		CREATE TABLE #Winlost (Site VARCHAR(50), SB TINYINT, TurnOver MONEY, Winlost MONEY )  
					
		INSERT INTO #Winlost (Site, SB, TurnOver, Winlost)						
		SELECT  w.Site, w.SB, 
				SUM(CASE WHEN w.Product3rdId IN (15, 25, 37) 
						THEN ISNULL(w.TurnOver,0)* e.BaseCurrencyRate   ---- tpositiontaking = 0 
						ELSE ISNULL(w.TurnOver,0)* ISNULL(lc.Rate, p.Rate) * CASE WHEN @BaseCurrency = '' THEN b.actualrate ELSE e.BaseCurrencyRate END  
						END) AS TurnOver, 	
				SUM(CASE
					WHEN w.Product3rdId IN (15, 25, 37) THEN -w.Winlost  ---- House WL of Colossusbet and Cashout, Member WL of saba promotion 
					ELSE
						(- w.Winlost - (w.FullContribution - w.HouseContribution)- w.OddsSpreadAdj) * ISNULL(lc.Rate, p.Rate)
						- w.HouseContribution - w.OddsSpreadAdj -w.FreeBet 
						- (CASE	WHEN w.Product3rdId IN (3) THEN w.Comm     -- BA Comm of bet builder
								WHEN w.Product3rdId IN (31) THEN w.Comm * ISNULL(lc.Rate, p.Rate)    --- exchange product
								ELSE 0 END ) -- exchange product & BAComm
				END * CASE WHEN @BaseCurrency = '' THEN b.actualrate ELSE e.BaseCurrencyRate END ) AS Winlost  
		FROM	#wl w 
		LEFT JOIN #ExchangeOANDA e ON e.ExchangeID = w.Currency					
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
		GROUP BY w.Site, w.SB  
		

		SELECT a.Site, a.SB, a.TurnOver, - a.Margin as Margin, - a.HouseWinlost as HouseWinlost, IsDeposit
		FROM  (  
				---- Listed all Site  
				SELECT	Site, SB, SUM(w.TurnOver) as TurnOver, 
						CASE WHEN SUM(w.TurnOver) = 0 THEN 0 ELSE SUM(w.winlost) / SUM(w.TurnOver) * 100 END AS Margin ,
						SUM (w.winlost) AS HouseWinlost,
						1 AS IsDeposit
				FROM 	#Winlost w  
				GROUP BY Site, SB 
				HAVING  SUM (w.TurnOver) IS NOT NULL 
				UNION 
				----- Sum total  
				SELECT	'Total' AS Site, 
						SB,
						SUM (w.TurnOver) AS TurnOver, 
						CASE WHEN SUM (w.TurnOver) = 0 THEN 0 ELSE SUM (w.winlost) / SUM (w.TurnOver) * 100 END AS Margin , 
						SUM (w.winlost) AS HouseWinlost,
						2 AS IsDeposit
				FROM 	#Winlost w 
				GROUP BY SB
				HAVING  SUM (w.TurnOver) IS NOT NULL 
				) a
	 
		---exchange product
		/*UNION
		SELECT 'Exchange Product', 0 AS SB, 0 AS TurnOver, 0 AS Margin , -1 * SUM(LicenseeWL+PayToSupplier) AS HouseWinlost, 3 AS IsDeposit
		FROM	#FinalResult
		HAVING  SUM(LicenseeWL+PayToSupplier) IS NOT NULL 
		*/

		ORDER BY  IsDeposit, Site

	DROP TABLE #SportBettype
	DROP TABLE #WL		
	DROP TABLE #Winlost
	DROP TABLE #ExchangeOANDA
	DROP TABLE #PartyChargeInfo
	DROP TABLE #PartyChargeByCurrencyInfo

END
GO