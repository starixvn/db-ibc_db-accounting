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

	--------------------------------------------------------------------------------------------------------- 
		CREATE TABLE #TicketDetail 
		(	srecommend			INT, 
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


		INSERT INTO #TicketDetail (srecommend, Sporttype, TurnOver, Winloss)
		SELECT b.srecommend,
				CASE WHEN b.bettype in (9,29) THEN -2 
				WHEN m.SportType = 1 and m.LeagueGroupID IN (42, 74, 108) then -3  -- Saba soccer
				WHEN m.SportType = 2 and m.LeagueGroupID = 42 then -4  -- Saba basketball
				WHEN m.SportType = 1 and m.LeagueGroupID = 41 then -5  -- Esoccer
				WHEN m.SportType = 2 and m.LeagueGroupID = 72 then -6  -- Ebasketball
				WHEN b.bettype = 999 then -7 -- Odds Spread Adjustment
				WHEN m.SportType = 1 and m.LeagueGroupID IN (113) then -8  -- Saba Pin Goal
				ELSE m.SportType end SportType, 
				--- Licensee
				SUM (   CASE WHEN b.StatusID = 111 THEN 0 ELSE 
						CASE WHEN ABS(modds) = 0.25 AND b.Bettype <> 29 THEN ABS(Stake) / 2 ELSE ABS(Stake) END END					
						* actualrate
					)	 AS TurnOver,
			
				- SUM (
						(ISNULL(winlost,0)-ISNULL(actual_stake,0)) * actualrate							
					) AS Winloss						
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
			AND b.Recommend NOT IN (52466,5707545)  --- Exclude 8RM, BARM 
			AND EXISTS (SELECT 1 FROM #Bettype s WHERE b.Bettype = s.Bettype) 
			AND EXISTS (SELECT 1 FROM dbo.Dep_CustSuper d WITH (NOLOCK) WHERE d.custid = b.srecommend AND Site <> 'Saba789')
			AND NOT EXISTS (SELECT 1 FROM bodb_Licensee.dbo.LicenseeBATransaction_active ba WITH (NOLOCK) WHERE ba.TransID = b.TransID)
		GROUP BY 
			b.srecommend,	
			CASE WHEN b.bettype in (9,29) THEN -2 
				WHEN m.SportType = 1 and m.LeagueGroupID IN (42, 74, 108) then -3  -- Saba soccer
				WHEN m.SportType = 2 and m.LeagueGroupID = 42 then -4  -- Saba basketball
				WHEN m.SportType = 1 and m.LeagueGroupID = 41 then -5  -- Esoccer
				WHEN m.SportType = 2 and m.LeagueGroupID = 72 then -6  -- Ebasketball
				WHEN b.bettype = 999 then -7 -- Odds Spread Adjustment
				WHEN m.SportType = 1 and m.LeagueGroupID IN (113) then -8
				ELSE m.SportType end
				

		INSERT INTO #Detail (site, Sporttype,TurnOver,Winloss) 		   
		SELECT	site, Sporttype, 
				SUM (TurnOver) AS TurnOver, 
				SUM (Winloss) AS Winloss
		FROM #TicketDetail b
		CROSS APPLY (SELECT site FROM dbo.Dep_CustSuper d WITH (NOLOCK) WHERE d.custid = b.srecommend AND Site <> 'Saba789') d
		GROUP BY site, Sporttype

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
						SUM(t1.Turnover) desc
				) RankTO,
				SUM(isnull(t1.Turnover,0)) Turnover_AllSports,
				SUM(isnull(t1.Winloss,0)) Winloss_AllSports,
				SUM(CASE WHEN t1.sporttype = 1 THEN ISNULL(t1.Turnover,0) ELSE 0 END) Turnover_Soccer,
				SUM(CASE WHEN t1.sporttype = 1 THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_Soccer,
				SUM(CASE WHEN t1.sporttype = 2 THEN ISNULL(t1.Turnover,0) ELSE 0 END) Turnover_Basketball,
				SUM(CASE WHEN t1.sporttype = 2 THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_Basketball,
				SUM(CASE WHEN t1.sporttype = 43 THEN ISNULL(t1.Turnover,0) ELSE 0 END) Turnover_Esport,
				SUM(CASE WHEN t1.sporttype = 43 THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_Esport,
				SUM(CASE WHEN t1.sporttype = 5 THEN ISNULL(t1.Turnover,0) ELSE 0 END) Turnover_Tennis,
				SUM(CASE WHEN t1.sporttype = 5 THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_Tennis,		
				SUM(CASE WHEN sporttype = -2 THEN ISNULL(t1.Turnover,0) ELSE 0 END) Turnover_Parlay,
				SUM(CASE WHEN sporttype = -2 THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_Parlay,
				SUM(CASE WHEN sporttype = -3 THEN ISNULL(t1.Turnover,0) ELSE 0 END) Turnover_SabaSoccer,
				SUM(CASE WHEN sporttype = -3 THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_SabaSoccer,
				SUM(CASE WHEN sporttype = -4 THEN ISNULL(t1.Turnover,0) ELSE 0 END) Turnover_SabaBasketball,
				SUM(CASE WHEN sporttype = -4 THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_SabaBasketball,
				SUM(CASE WHEN t1.sporttype not in (1, 2, 5, 43, -2, -3, -4, -5, -6) THEN ISNULL(t1.Turnover,0) ELSE 0 END) Turnover_Othersport,
				SUM(CASE WHEN t1.sporttype not in (1, 2, 5, 43, -2, -3, -4, -5, -6) THEN ISNULL(t1.Winloss,0) ELSE 0 END) Winloss_Othersport
			FROM #Detail t1 
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

