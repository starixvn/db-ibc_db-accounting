/*<info serverAlias="DBEXT-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_ResetWinning_TopLicenseeMargin]
	@Winlostdate SMALLDATETIME 
AS  
 
/*	
	Created: 20201230@Sophia
	Task: Reset Winning - Margin By Sport - TOP Licensee Margin  (adhoc) [redmind: #147907]
	DB: DBEXT.BODB02
	
	Revision:
		- 20201230@Sophia: Initial SPs [Redmine: #147907]
		- 20210422@Sophia: Exclude Saba789 out of Licensee [Redmind: #153777]
		- 20210524@Sophia: Add Saba Pin Goal [RedmineId: #155697]
		- 20210529@Sophia: use base currency CNY and Licensee Rate of LA [RedmineId: #155697]
	
	Original: Acc_Rpt_Letstalk_TopLicenseeMargin 
	Param Explanation:
		 
	   
*/
BEGIN	
	SET NOCOUNT ON
  
	------Get Sport Bettype Matrix------	
	CREATE TABLE  #Bettype (Bettype INT PRIMARY KEY)
	INSERT INTO #Bettype
	SELECT  Bettype FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', 0)
	WHERE  ProductID = 1 
			AND Bettype NOT BETWEEN 801 and 806 
			AND bettype NOT BETWEEN 901 and 904
			AND Bettype <> 38 
	
	--CREATE CLUSTERED INDEX CIX_Bettype ON #Bettype (bettype) 
	----- End get sport bettype  
	
	------Get Sporttype------	
	CREATE TABLE  #Sports (Sporttype INT, SportName VARCHAR(50), OrderId INT IDENTITY (1,1))
	INSERT INTO #Sports (Sporttype, SportName)	
	SELECT 	Sporttype, SportName
	FROM 	bodb02.dbo.Sports WITH (NOLOCK)
    WHERE 	Sporttype IN (1, 2, 5, 43)	
	
	INSERT INTO #Sports (Sporttype, SportName)	
	SELECT 	0 AS Sporttype, 'Other Sports' AS SportName	 
	UNION  
	SELECT 	-29 AS Sporttype, 'Parlay' AS SportName	 
	 
	----- End get Sporttype  
	
	----- Get Saba League ---------
	CREATE TABLE #SabaVirtualSportsLeague (LeagueId INT, LeagueGroupID INT)

	INSERT INTO #SabaVirtualSportsLeague (LeagueId, LeagueGroupID) 
	SELECT leagueid, LeagueGroupID
	FROM dbo.League WITH (NOLOCK)
	WHERE ((sporttype = 1 AND LeagueGroupID IN (41, 42, 74, 108, 113))
			OR (sporttype = 2 AND LeagueGroupID IN (42, 72))
			)
	----- End get Saba League  	
	
	------Get Match ------	
	 CREATE TABLE #Match
                     (MatchId   INT, 
                      type      VARCHAR(10), 
                      SportType INT,
					  LeagueGroupID	INT
                      PRIMARY KEY(MatchId, type)
                     );
        INSERT INTO #Match
               SELECT DISTINCT 
                      m.MatchId, 
                      m.type, 
                      m.sporttype,
					  m.LeagueGroupID
               FROM
               (
					SELECT MatchId, 
						  'match' AS type,
						  Sporttype,
						  l.LeagueGroupID
					FROM Match m WITH(NOLOCK)
					LEFT JOIN #SabaVirtualSportsLeague l 
						ON l.LeagueId = m.leagueid 
					WHERE EventDate = @WinlostDate
					UNION ALL
					SELECT orid,  
						  'outright' AS type,
						  ll.Sporttype,
						  l.LeagueGroupID
					FROM outright o WITH(NOLOCK)
					INNER JOIN league ll WITH (NOLOCK) 
						ON ll.leagueID = o.LeagueId
					LEFT JOIN #SabaVirtualSportsLeague l 
						ON l.LeagueId = o.leagueid 						
					WHERE o.EventDate = @WinlostDate
					UNION ALL
					SELECT 29 AS MatchId,
						   'Parlay' AS type,						   
						   -29 AS Sporttype,
							0 AS LeagueGroupID			
					UNION ALL
					SELECT 999 AS MatchId,
						   'Oddspread' AS type,						   
						   999 AS Sporttype,
						   0 AS LeagueGroupID	
               ) m              
			   
	------End Get Match ------			   
	
	------Get Base Currency CNY -------

	DECLARE @Exchange AS TABLE (ExchangeId INT, CNY float)
	
	INSERT INTO @Exchange (ExchangeId, CNY)
	SELECT ExchangeId, CNY FROM dbo.ExchangeDailyOanda WITH (NOLOCK) WHERE ExchangeDate = @Winlostdate

	------Enf Get Base Currency CNY -------


	-------------- Get Charge Info -------------------
	
		----- Get Supers List -----
		CREATE TABLE #Supers (Custid INT, Site VARCHAR(20), PartyId INT)
		
		INSERT INTO #Supers (CustId, Site, PartyId)
		SELECT c.Custid, c.Site, p.PartyId 
		FROM dbo.Dep_CustSuper c WITH (NOLOCK) 		
		INNER JOIN bodb_licensee.dbo.OAS_Party p WITH (NOLOCK) ON p.PartyName = c.Site
		INNER JOIN bodb_licensee.dbo.OAS_PartyDetail pd WITH (NOLOCK) ON pd.PartyID = p.PartyID
		WHERE p.PartyType = 1 AND pd.IsDeposit = 1 
			AND c.Site NOT IN ('Saba789')
			AND c.currency <> 20
			
		---- Get Charge Info ----
		
		DECLARE @PartyIds VARCHAR(MAX), @ProductCodes VARCHAR(MAX)
		-- Get party list 
		SELECT @PartyIds = COALESCE(@PartyIds + ',', '') + CONVERT(VARCHAR(10), p.PartyId) 
		FROM #Supers p

		-- Get product list
		SELECT @ProductCodes = 'SB,BA'

		-- Get charge rate
		CREATE TABLE #PartyChargeInfo (ChargeId INT, PartyId INT, Product3rdId INT, FromDate DATE, ToDate DATE, Rate FLOAT)
		
		INSERT INTO #PartyChargeInfo (ChargeId, PartyId, Product3rdId, FromDate, ToDate, Rate)					
		SELECT DISTINCT ci.ChargeId, ci.PartyId, ci.ProductId AS Product3rdId, ci.FromDate, ci.ToDate, ci.DI_Rate AS Rate 
		FROM bodb_licensee.dbo.LA_f_ChargeInfo (@PartyIds, @Winlostdate, @Winlostdate, @ProductCodes,'OA', 1) ci 
		WHERE ci.DI_Rate > 0
			AND ci.ChargeType = 1 
				
		CREATE TABLE #PartyChargeByCurrencyInfo (ChargeId INT, CurrencyId INT, Rate FLOAT)

		INSERT INTO #PartyChargeByCurrencyInfo (ChargeId, CurrencyId, Rate)		 
	    SELECT pc.ChargeId, pc.CurrencyId, pc.Rate
		FROM #PartyChargeInfo ci
			INNER JOIN bodb_Licensee.dbo.LA_ChargeRateByCurrency pc WITH (NOLOCK) ON ci.ChargeId = pc.ChargeId
		
	-------------- End Get Charge Info -------------------
		
	--------------------------------------------------------------------------------------------------------- 
		CREATE TABLE #TicketDetail 
		(	PartyID			INT,			
			Currency		INT,
			Site 			VARCHAR(20),
			Product3rdId	INT,			 			
			Sporttype  		SMALLINT,  
			TurnOver		DECIMAL(19,4),
			Winloss			DECIMAL(19,4)
		) 	 

					
		CREATE TABLE #Detail 
		(	site			VARCHAR(100),
			Sporttype  		SMALLINT,  
			TurnOver		DECIMAL(19,4),
			Winloss			DECIMAL(19,4)
		) 

		INSERT INTO #TicketDetail (PartyID, Currency, Site, Product3rdId, Sporttype, TurnOver, Winloss)
		SELECT  s.PartyID, b.Currency, s.Site, 
				CASE WHEN ba.TransID IS NOT NULL THEN 3 ELSE 0 END AS Product3rdId,
				CASE WHEN b.bettype in (9,29) THEN -2 
				WHEN m.SportType = 1 and m.LeagueGroupID IN (42, 74, 108, 113) then -3  -- Saba soccer
				WHEN m.SportType = 2 and m.LeagueGroupID = 42 then -4  -- Saba basketball
				WHEN m.SportType = 1 and m.LeagueGroupID = 41 then -5  -- Esoccer
				WHEN m.SportType = 2 and m.LeagueGroupID = 72 then -6  -- Ebasketball
				WHEN b.bettype = 999 then -7 -- Odds Spread Adjustment
				ELSE m.SportType end SportType, 
				--- Licensee
				SUM (   CASE WHEN b.StatusID = 111 THEN 0 ELSE 
						CASE WHEN ABS(modds) = 0.25 AND b.Bettype <> 29 THEN ABS(Stake) / 2 ELSE ABS(Stake) END END					
						* e.CNY
					)	 AS TurnOver,
			
				- SUM (
						(ISNULL(winlost,0)-ISNULL(actual_stake,0)) * e.CNY							
					) AS Winloss						
		FROM dbo.bettrans b WITH (NOLOCK)
		INNER JOIN @Exchange e ON e.ExchangeId = b.Currency
		INNER JOIN #Supers s ON s.Custid = b.srecommend
		INNER JOIN #Match AS m 
			ON 	b.MatchId = m.MatchId
			AND m.type = CASE b.BetType WHEN 10 THEN 'outright'
										WHEN 29 THEN 'Parlay'
										WHEN 999 THEN 'Oddspread'
										ELSE 'Match'                           
                         END
		LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction_Active ba WITH (NOLOCK)
			ON 	ba.TransID = b.TransID								 
		WHERE   b.Winlostdate = @WinlostDate
			AND b.statusid IN (111, 112, 113)	
			AND b.Recommend NOT IN (52466,5707545)  --- Exclude 8RM, BARM 
			AND EXISTS (SELECT 1 FROM #Bettype s WHERE b.Bettype = s.Bettype) 
			--AND EXISTS (SELECT 1 FROM dbo.Dep_CustSuper d WITH (NOLOCK) WHERE d.custid = b.srecommend AND Site <> 'Saba789')
			--AND NOT EXISTS (SELECT 1 FROM bodb_Licensee.dbo.LicenseeBATransaction_active ba WITH (NOLOCK) WHERE ba.TransID = b.TransID)
		GROUP BY 
			s.PartyID, b.Currency, s.Site,
			CASE WHEN ba.TransID IS NOT NULL THEN 3 ELSE 0 END, 	
			CASE WHEN b.bettype in (9,29) THEN -2 
				WHEN m.SportType = 1 and m.LeagueGroupID IN (42, 74, 108, 113) then -3  -- Saba soccer
				WHEN m.SportType = 2 and m.LeagueGroupID = 42 then -4  -- Saba basketball
				WHEN m.SportType = 1 and m.LeagueGroupID = 41 then -5  -- Esoccer
				WHEN m.SportType = 2 and m.LeagueGroupID = 72 then -6  -- Ebasketball
				WHEN b.bettype = 999 then -7 -- Odds Spread Adjustment
				ELSE m.SportType end
				 

		-----------------------------------------------------------------------------------------------
		----- Get Data ----------------  
		
		--LICENSEE
		SELECT 
			CASE WHEN T.RankTO <= 50 THEN t.site 
					ELSE 'Other Licensees'
					END  as Licensee,
			CASE WHEN SUM(t.Turnover_AllSports) = 0 THEN 0 ELSE SUM(t.Winloss_AllSports)/SUM(t.Turnover_AllSports) END MarginAllSport,
			CASE WHEN SUM(t.Turnover_Soccer) = 0 THEN 0 ELSE SUM(t.Winloss_Soccer)/SUM(t.Turnover_Soccer) END MarginSoccer,
			CASE WHEN SUM(t.Turnover_Basketball) = 0 THEN 0 ELSE SUM(t.Winloss_Basketball)/SUM(t.Turnover_Basketball) END MarginBasketball,
			CASE WHEN SUM(t.Turnover_Esport) = 0 THEN 0 ELSE SUM(t.Winloss_Esport)/SUM(t.Turnover_Esport) END MarginEsport,
			CASE WHEN SUM(t.Turnover_Tennis) = 0 THEN 0 ELSE SUM(t.Winloss_Tennis)/SUM(t.Turnover_Tennis) END MarginTennis,	
			CASE WHEN SUM(t.Turnover_Parlay) = 0 THEN 0 ELSE SUM(t.Winloss_Parlay)/SUM(t.Turnover_Parlay) END MarginParlay,
			CASE WHEN SUM(t.Turnover_SabaSoccer) = 0 THEN 0 ELSE SUM(t.Winloss_SabaSoccer)/SUM(t.Turnover_SabaSoccer) END MarginSabaSoccer,
			CASE WHEN SUM(t.Turnover_SabaBasketball) = 0 THEN 0 ELSE SUM(t.Winloss_SabaBasketball)/SUM(t.Turnover_SabaBasketball) END MarginSabaBasketball,
			CASE WHEN SUM(t.Turnover_Othersport) = 0 THEN 0 ELSE SUM(t.Winloss_Othersport)/SUM(t.Turnover_Othersport) END MarginOthersport,
			SUM(t.Turnover_AllSports) as TurnoverAllSport
		FROM (
			SELECT 
				t1.site SITE,
				RANK() OVER (
					order by 
						SUM(t1.Turnover * ISNULL(lc.Rate, p.Rate)) desc
				) RankTO,
				SUM(ISNULL(t1.Turnover,0) * ISNULL(lc.Rate, p.Rate)) Turnover_AllSports,
				SUM(ISNULL(t1.Winloss,0)) Winloss_AllSports,
				SUM(CASE WHEN t1.sporttype = 1 THEN ISNULL(t1.Turnover,0) * ISNULL(lc.Rate, p.Rate) ELSE 0 END) Turnover_Soccer,
				SUM(CASE WHEN t1.sporttype = 1 THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_Soccer,
				SUM(CASE WHEN t1.sporttype = 2 THEN ISNULL(t1.Turnover,0) * ISNULL(lc.Rate, p.Rate) ELSE 0 END) Turnover_Basketball,
				SUM(CASE WHEN t1.sporttype = 2 THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_Basketball,
				SUM(CASE WHEN t1.sporttype = 43 THEN ISNULL(t1.Turnover,0) * ISNULL(lc.Rate, p.Rate) ELSE 0 END) Turnover_Esport,
				SUM(CASE WHEN t1.sporttype = 43 THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_Esport,
				SUM(CASE WHEN t1.sporttype = 5 THEN ISNULL(t1.Turnover,0) * ISNULL(lc.Rate, p.Rate) ELSE 0 END) Turnover_Tennis,
				SUM(CASE WHEN t1.sporttype = 5 THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_Tennis,		
				SUM(CASE WHEN sporttype = -2 THEN ISNULL(t1.Turnover,0) * ISNULL(lc.Rate, p.Rate) ELSE 0 END) Turnover_Parlay,
				SUM(CASE WHEN sporttype = -2 THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_Parlay,
				SUM(CASE WHEN sporttype = -3 THEN ISNULL(t1.Turnover,0) * ISNULL(lc.Rate, p.Rate) ELSE 0 END) Turnover_SabaSoccer,
				SUM(CASE WHEN sporttype = -3 THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_SabaSoccer,
				SUM(CASE WHEN sporttype = -4 THEN ISNULL(t1.Turnover,0) * ISNULL(lc.Rate, p.Rate) ELSE 0 END) Turnover_SabaBasketball,
				SUM(CASE WHEN sporttype = -4 THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_SabaBasketball,
				SUM(CASE WHEN t1.sporttype not in (1, 2, 5, 43, -2, -3, -4, -5, -6) THEN ISNULL(t1.Turnover,0) * ISNULL(lc.Rate, p.Rate) ELSE 0 END) Turnover_Othersport,
				SUM(CASE WHEN t1.sporttype not in (1, 2, 5, 43, -2, -3, -4, -5, -6) THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_Othersport
			FROM #TicketDetail t1 
			INNER JOIN #PartyChargeInfo p 
				ON 	p.PartyId = t1.PartyId 
					AND p.Product3rdId = t1.Product3rdId					
			LEFT JOIN #PartyChargeByCurrencyInfo lc 
				ON 	p.ChargeId = lc.ChargeId 
					AND t1.Currency = lc.CurrencyId	
			GROUP BY t1.site 
		) T
		GROUP BY CASE WHEN T.RankTO <= 50 THEN t.site 
					ELSE 'Other Licensees'
					END
		ORDER BY MIN(RankTO)
		 
  

	DROP TABLE #Bettype
    DROP TABLE #Sports
	DROP TABLE #Match 
	DROP TABLE #Detail	
	DROP TABLE #TicketDetail
	DROP TABLE #SabaVirtualSportsLeague
		
END