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
	WHERE ((sporttype = 1 AND LeagueGroupID IN (41, 42, 74, 108))
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
						--AND Sporttype IN (1, 2, 5, 43)
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
						--AND l.Sporttype IN (1, 2, 5, 43)
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

	--------------------------------------------------------------------------------------------------------- 
		CREATE TABLE #TicketDetail 
		(	srecommend		INT, 
			Sporttype  		SMALLINT,  
			TurnOver		decimal(19,4),
			Winloss			decimal(19,4),
			HouseTO			decimal(19,4),
			HouseIncome		decimal(19,4) 
		) 	 
		INSERT INTO #TicketDetail (srecommend, Sporttype, TurnOver, Winloss, HouseTO, HouseIncome)
		SELECT  b.srecommend,
				CASE WHEN b.bettype in (9,29) THEN -2 
				WHEN m.SportType = 1 and m.LeagueGroupID IN (42, 74, 108) then -3  -- Saba soccer
				WHEN m.SportType = 2 and m.LeagueGroupID = 42 then -4  -- Saba basketball
				WHEN m.SportType = 1 and m.LeagueGroupID = 41 then -5  -- Esoccer
				WHEN m.SportType = 2 and m.LeagueGroupID = 72 then -6  -- Ebasketball
				WHEN b.bettype = 999 then -7 -- Odds Spread Adjustment
				ELSE m.SportType end SportType, 
				--- Licensee
				SUM (   CASE WHEN b.StatusID = 111 THEN 0 ELSE 
						CASE WHEN ABS(modds) = 0.25 AND b.Bettype <> 29 THEN ABS(Stake) / 2 ELSE ABS(Stake) END END					
						* actualrate
					)	 AS TurnOver,
			
				- SUM (
						(ISNULL(winlost,0)-ISNULL(actual_stake,0)) * actualrate							
					) AS Winloss,

				---House
				SUM (   CASE WHEN b.StatusID = 111 THEN 0 ELSE 
						CASE WHEN ABS(modds) = 0.25 AND b.Bettype <> 29 THEN ABS(Stake) / 2 ELSE  ABS(Stake) END END
						* (1 - b.tpositiontaking - ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) 
						* CASE
							  WHEN virtualrate > actualrate
							  THEN virtualrate
							  ELSE actualrate
							END
					)	 AS HouseTO,
				- ( 
					SUM (
							(ISNULL(winlost,0)-ISNULL(actual_stake,0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)) 
							* actualrate				
						)  
					- 
					SUM(
							( CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END) 
								* ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)
								* actualrate 
						)
				) AS HouseIncome				
		FROM dbo.bettrans b WITH (NOLOCK)  
		INNER JOIN #Match AS m 
			ON 	b.MatchId = m.MatchId
			AND m.type = CASE b.BetType WHEN 10 THEN 'outright'
										WHEN 29 THEN 'Parlay'
										WHEN 999 THEN 'Oddspread'
										ELSE 'Match'                           
                         END	
		WHERE   b.Winlostdate = @WinlostDate
			AND b.statusid IN (111, 112, 113)		
			--AND b.bettype < 19001
			--AND b.MatchID >= 0
			AND b.Recommend NOT IN (52466,5707545)  --- Exclude 8RM, BARM 
			AND EXISTS (SELECT 1 FROM #Bettype s WHERE b.Bettype = s.Bettype) 
		GROUP BY 
			b.srecommend,			
			CASE WHEN b.bettype in (9,29) THEN -2 
				WHEN m.SportType = 1 and m.LeagueGroupID IN (42, 74, 108) then -3  -- Saba soccer
				WHEN m.SportType = 2 and m.LeagueGroupID = 42 then -4  -- Saba basketball
				WHEN m.SportType = 1 and m.LeagueGroupID = 41 then -5  -- Esoccer
				WHEN m.SportType = 2 and m.LeagueGroupID = 72 then -6  -- Ebasketball
				WHEN b.bettype = 999 then -7 -- Odds Spread Adjustment
				ELSE m.SportType end
				
				
		CREATE TABLE #Detail 
		(	site			VARCHAR(100),
			isLicensee		BIT,
			Sporttype  		SMALLINT,  
			TurnOver		decimal(19,4),
			Winloss			decimal(19,4),
			HouseTO			decimal(19,4),
			HouseIncome		decimal(19,4) 
		) 	 		  
		INSERT INTO #Detail  (site, isLicensee, Sporttype, TurnOver, Winloss, HouseTO, HouseIncome)
		SELECT  c.site, 
				CASE WHEN d.CustID IS NOT NULL THEN 1 ELSE 0 END AS isLicensee,
				Sporttype,
				SUM (TurnOver) AS TurnOver, 
				SUM (Winloss) AS Winloss,  
				SUM (HouseTO) AS HouseTO,  
				SUM (HouseIncome) AS HouseIncome
		FROM #TicketDetail b
		INNER JOIN dbo.vw_Customer c WITH (NOLOCK) ON c.CustID = b.srecommend AND c.RoleID = 4 		
		LEFT JOIN dbo.Dep_CustSuper d WITH (NOLOCK) ON d.CustID = b.srecommend 
		GROUP BY c.site,
				CASE WHEN d.CustID IS NOT NULL THEN 1 ELSE 0 END,
				Sporttype


		-----------------------------------------------------------------------------------------------
		----- Get Data ----------------
		-----#1 GROUP PERFORMANCE ----------------

			SELECT t.Site as Licensee,
				CASE WHEN t.HouseTO_AllSports = 0 then 0 else t.HouseIncome_AllSports/t.HouseTO_AllSports end MarginAllSport,
				CASE WHEN t.HouseTO_Soccer = 0 then 0 else t.HouseIncome_Soccer/t.HouseTO_Soccer end MarginSoccer,
				CASE WHEN t.HouseTO_Basketball = 0 then 0 else t.HouseIncome_Basketball/t.HouseTO_Basketball end MarginBasketball,
				CASE WHEN t.HouseTO_Esport = 0 then 0 else t.HouseIncome_Esport/t.HouseTO_Esport end MarginEsport,
				CASE WHEN t.HouseTO_Tennis = 0 then 0 else t.HouseIncome_Tennis/t.HouseTO_Tennis end MarginTennis,
				CASE WHEN t.HouseTO_Parlay = 0 then 0 else t.HouseIncome_Parlay/t.HouseTO_Parlay end MarginParlay,
				CASE WHEN t.HouseTO_SabaSoccer = 0 then 0 else t.HouseIncome_SabaSoccer/t.HouseTO_SabaSoccer end MarginSabaSoccer,
				CASE WHEN t.HouseTO_SabaBasketball = 0 then 0 else t.HouseIncome_SabaBasketball/t.HouseTO_SabaBasketball end MarginSabaBasketball,
				CASE WHEN t.HouseTO_Othersport = 0 then 0 else t.HouseIncome_Othersport/t.HouseTO_Othersport end MarginOthersport
			FROM (
				SELECT CASE 
							WHEN t1.isLicensee = 1 THEN 'Licensee'
							WHEN t1.site = '789Y' THEN '789Y'
							WHEN t1.site in ( 'XYZBET', 'BEST-ODDS') THEN 'XYZ & Bestodds'
							WHEN t1.site = '611111' THEN '611 (China)'
							WHEN t1.site = '733333' THEN '733 (Malaysia)'
							WHEN t1.site = '755555' THEN '755 (Thailand)'
							WHEN t1.site = 'INDO' THEN 'Indo'
							WHEN t1.site = 'IBCIndo' THEN 'IBCIndo'
							WHEN t1.isLicensee = 0 and t1.site not in ('789Y','XYZBET','BEST-ODDS','611111','733333','755555','INDO','CN88','IBCIndo') THEN 'Other MBC'		
							WHEN t1.site = 'CN88' THEN 'CN88'		
						END	SITE,				
					CASE 
						WHEN t1.isLicensee = 1 THEN 1
						WHEN t1.site = '789Y' THEN 2
						WHEN t1.site in ( 'XYZBET', 'BEST-ODDS') THEN 3
						WHEN t1.site = '611111' THEN 4
						WHEN t1.site = '733333' THEN 5
						WHEN t1.site = '755555' THEN 6
						WHEN t1.site = 'INDO' THEN 7
						WHEN t1.site = 'IBCIndo' THEN 8
						WHEN t1.isLicensee = 0 and t1.site not in ('789Y','XYZBET','BEST-ODDS','611111','733333','755555','INDO','CN88','IBCIndo') THEN 9		
						WHEN t1.site = 'CN88' THEN 11								
					END OrderBy,
					sum(isnull(t1.HouseTO,0)) HouseTO_AllSports,
					sum(isnull(t1.HouseIncome,0)) HouseIncome_AllSports,
					sum(case when sporttype = 1 then isnull(t1.HouseTO,0) else 0 end) HouseTO_Soccer,
					sum(case when sporttype = 1 then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_Soccer,
					sum(case when sporttype = 2 then isnull(t1.HouseTO,0) else 0 end) HouseTO_Basketball,
					sum(case when sporttype = 2 then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_Basketball,
					sum(case when sporttype = 43 then isnull(t1.HouseTO,0) else 0 end) HouseTO_Esport,
					sum(case when sporttype = 43 then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_Esport,
					sum(case when sporttype = 5 then isnull(t1.HouseTO,0) else 0 end) HouseTO_Tennis,
					sum(case when sporttype = 5 then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_Tennis,		
					sum(case when sporttype = -2 then isnull(t1.HouseTO,0) else 0 end) HouseTO_Parlay,
					sum(case when sporttype = -2 then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_Parlay,
					sum(case when sporttype = -3 then isnull(t1.HouseTO,0) else 0 end) HouseTO_SabaSoccer,
					sum(case when sporttype = -3 then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_SabaSoccer,
					sum(case when sporttype = -4 then isnull(t1.HouseTO,0) else 0 end) HouseTO_SabaBasketball,
					sum(case when sporttype = -4 then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_SabaBasketball,
					sum(case when sporttype not in (1, 2, 5, 43, -2, -3, -4, -5, -6) then isnull(t1.HouseTO,0) else 0 end) HouseTO_Othersport,
					sum(case when sporttype not in (1, 2, 5, 43, -2, -3, -4, -5, -6) then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_Othersport
				FROM  #Detail t1
				GROUP BY  CASE 
							WHEN t1.isLicensee = 1 THEN 'Licensee'
							WHEN t1.site = '789Y' THEN '789Y'
							WHEN t1.site in ( 'XYZBET', 'BEST-ODDS') THEN 'XYZ & Bestodds'
							WHEN t1.site = '611111' THEN '611 (China)'
							WHEN t1.site = '733333' THEN '733 (Malaysia)'
							WHEN t1.site = '755555' THEN '755 (Thailand)'
							WHEN t1.site = 'INDO' THEN 'Indo'
							WHEN t1.site = 'IBCIndo' THEN 'IBCIndo'
							WHEN t1.isLicensee = 0 and t1.site not in ('789Y','XYZBET','BEST-ODDS','611111','733333','755555','INDO','CN88','IBCIndo') THEN 'Other MBC'		
							WHEN t1.site = 'CN88' THEN 'CN88'		
						END,
					CASE 
						WHEN t1.isLicensee = 1 THEN 1
						WHEN t1.site = '789Y' THEN 2
						WHEN t1.site in ( 'XYZBET', 'BEST-ODDS') THEN 3
						WHEN t1.site = '611111' THEN 4
						WHEN t1.site = '733333' THEN 5
						WHEN t1.site = '755555' THEN 6
						WHEN t1.site = 'INDO' THEN 7
						WHEN t1.site = 'IBCIndo' THEN 8
						WHEN t1.isLicensee = 0 and t1.site not in ('789Y','XYZBET','BEST-ODDS','611111','733333','755555','INDO','CN88','IBCIndo') THEN 9		
						WHEN t1.site = 'CN88' THEN 11								
					END
	
				UNION ALL

				SELECT 	
					'ALL(w/o CN88)'	Licensee,
					10 OrderBy,
					sum(isnull(t1.HouseTO,0)) HouseTO_AllSports,
					sum(isnull(t1.HouseIncome,0)) HouseIncome_AllSports,
					sum(case when sporttype = 1 then isnull(t1.HouseTO,0) else 0 end) HouseTO_Soccer,
					sum(case when sporttype = 1 then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_Soccer,
					sum(case when sporttype = 2 then isnull(t1.HouseTO,0) else 0 end) HouseTO_Basketball,
					sum(case when sporttype = 2 then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_Basketball,
					sum(case when sporttype = 43 then isnull(t1.HouseTO,0) else 0 end) HouseTO_Esport,
					sum(case when sporttype = 43 then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_Esport,
					sum(case when sporttype = 5 then isnull(t1.HouseTO,0) else 0 end) HouseTO_Tennis,
					sum(case when sporttype = 5 then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_Tennis,		
					sum(case when sporttype = -2 then isnull(t1.HouseTO,0) else 0 end) HouseTO_Parlay,
					sum(case when sporttype = -2 then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_Parlay,
					sum(case when sporttype = -3 then isnull(t1.HouseTO,0) else 0 end) HouseTO_SabaSoccer,
					sum(case when sporttype = -3 then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_SabaSoccer,
					sum(case when sporttype = -4 then isnull(t1.HouseTO,0) else 0 end) HouseTO_SabaBasketball,
					sum(case when sporttype = -4 then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_SabaBasketball,
					sum(case when sporttype not in (1, 2, 5, 43, -2, -3, -4, -5, -6) then isnull(t1.HouseTO,0) else 0 end) HouseTO_Othersport,
					sum(case when sporttype not in (1, 2, 5, 43, -2, -3, -4, -5, -6) then isnull(t1.HouseIncome,0) else 0 end) HouseIncome_Othersport
				FROM  #Detail t1
				where t1.site <> 'CN88'	
			) T
			ORDER BY OrderBy

---------------------------

		
--LICENSEE
SELECT 
	CASE WHEN T.RankTO <= 50 THEN t.site 
			ELSE 'Other Licensees'
			end  as Licensee,
	CASE WHEN sum(t.Turnover_AllSports) = 0 then 0 else sum(t.Winloss_AllSports)/sum(t.Turnover_AllSports) end MarginAllSport,
	CASE WHEN sum(t.Turnover_Soccer) = 0 then 0 else sum(t.Winloss_Soccer)/sum(t.Turnover_Soccer) end MarginSoccer,
	CASE WHEN sum(t.Turnover_Basketball) = 0 then 0 else sum(t.Winloss_Basketball)/sum(t.Turnover_Basketball) end MarginBasketball,
	CASE WHEN sum(t.Turnover_Esport) = 0 then 0 else sum(t.Winloss_Esport)/sum(t.Turnover_Esport) end MarginEsport,
	CASE WHEN sum(t.Turnover_Tennis) = 0 then 0 else sum(t.Winloss_Tennis)/sum(t.Turnover_Tennis) end MarginTennis,	
	CASE WHEN sum(t.Turnover_Parlay) = 0 then 0 else sum(t.Winloss_Parlay)/sum(t.Turnover_Parlay) end MarginParlay,
	CASE WHEN sum(t.Turnover_SabaSoccer) = 0 then 0 else sum(t.Winloss_SabaSoccer)/sum(t.Turnover_SabaSoccer) end MarginSabaSoccer,
	CASE WHEN sum(t.Turnover_SabaBasketball) = 0 then 0 else sum(t.Winloss_SabaBasketball)/sum(t.Turnover_SabaBasketball) end MarginSabaBasketball,
	CASE WHEN sum(t.Turnover_Othersport) = 0 then 0 else sum(t.Winloss_Othersport)/sum(t.Turnover_Othersport) end MarginOthersport
FROM (
	SELECT 
		t1.site SITE,
		RANK() OVER (
			order by 
				sum(t1.Turnover) desc
		) RankTO,
		sum(isnull(t1.Turnover,0)) Turnover_AllSports,
		sum(isnull(t1.Winloss,0)) Winloss_AllSports,
		sum(case when t1.sporttype = 1 then isnull(t1.Turnover,0) else 0 end) Turnover_Soccer,
		sum(case when t1.sporttype = 1 then isnull(t1.Winloss,0) else 0 end) Winloss_Soccer,
		sum(case when t1.sporttype = 2 then isnull(t1.Turnover,0) else 0 end) Turnover_Basketball,
		sum(case when t1.sporttype = 2 then isnull(t1.Winloss,0) else 0 end) Winloss_Basketball,
		sum(case when t1.sporttype = 43 then isnull(t1.Turnover,0) else 0 end) Turnover_Esport,
		sum(case when t1.sporttype = 43 then isnull(t1.Winloss,0) else 0 end) Winloss_Esport,
		sum(case when t1.sporttype = 5 then isnull(t1.Turnover,0) else 0 end) Turnover_Tennis,
		sum(case when t1.sporttype = 5 then isnull(t1.Winloss,0) else 0 end) Winloss_Tennis,		
		sum(case when sporttype = -2 then isnull(t1.Turnover,0) else 0 end) Turnover_Parlay,
		sum(case when sporttype = -2 then isnull(t1.Winloss,0) else 0 end) Winloss_Parlay,
		sum(case when sporttype = -3 then isnull(t1.Turnover,0) else 0 end) Turnover_SabaSoccer,
		sum(case when sporttype = -3 then isnull(t1.Winloss,0) else 0 end) Winloss_SabaSoccer,
		sum(case when sporttype = -4 then isnull(t1.Turnover,0) else 0 end) Turnover_SabaBasketball,
		sum(case when sporttype = -4 then isnull(t1.Winloss,0) else 0 end) Winloss_SabaBasketball,
		sum(case when t1.sporttype not in (1, 2, 5, 43, -2, -3, -4, -5, -6) then isnull(t1.Turnover,0) else 0 end) Turnover_Othersport,
		sum(case when t1.sporttype not in (1, 2, 5, 43, -2, -3, -4, -5, -6) then isnull(t1.Winloss,0) else 0 end) Winloss_Othersport
	FROM #Detail t1
	WHERE t1.isLicensee = 1
	GROUP BY t1.site 
) T
GROUP BY CASE WHEN T.RankTO <= 50 THEN t.site 
			ELSE 'Other Licensees'
			end
ORDER BY MIN(RankTO)
 
	DROP TABLE #Bettype
    DROP TABLE #Sports
	DROP TABLE #Match 
	DROP TABLE #Detail	
	DROP TABLE #TicketDetail
	DROP TABLE #SabaVirtualSportsLeague
		
END
GO