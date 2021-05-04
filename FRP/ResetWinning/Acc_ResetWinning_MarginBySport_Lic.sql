/*<info serverAlias="DBEXT-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_ResetWinning_MarginBySport_Lic]
	@Winlostdate SMALLDATETIME 
AS 
 
/*	
	Created: 20210422@Sophia
	Task: Reset Winning - Margin By Non Sport (adhoc) for Licensee [Redmine: #153868]
	DB: DBEXT.BODB02
	
	Revision:
		- 20210422@Sophia: Initial SP [Redmine: #153868]
		
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
	 
	----- End get sport bettype  
	
	------Get Sporttype------	
	CREATE TABLE  #Sports (Sporttype INT, SportName VARCHAR(50), OrderId INT IDENTITY (1,1))
	INSERT INTO #Sports (Sporttype, SportName)	
	SELECT 	Sporttype, SportName
	FROM 	bodb02.dbo.Sports WITH (NOLOCK)
    WHERE 	Sporttype IN (1, 2, 5, 43, 50)	
	
	INSERT INTO #Sports (Sporttype, SportName)	
	SELECT 	0 AS Sporttype, 'Other Sports' AS SportName	 
	UNION  
	SELECT 	-29 AS Sporttype, 'Parlay' AS SportName	 
	 
	----- End get Sporttype  
	
	----- Get Saba League ---------
	CREATE TABLE #SabaVirtualSportsLeague (LeagueId INT)

	INSERT INTO #SabaVirtualSportsLeague
	SELECT leagueid
	FROM dbo.League WITH (NOLOCK)
	WHERE  LeagueGroupID IN (41, 42, 74, 108)
			/*((sporttype = 1 AND LeagueGroupID IN (41, 42, 74, 108))
			OR (sporttype = 2 AND LeagueGroupID IN (42, 72)) 
			OR (sporttype = 50 AND LeagueGroupID IN (42)) 
			)
			*/
		
	----- End get Saba League 
		
	------Get Match ------	
	 CREATE TABLE #Match
                     (MatchId   INT, 
                      type      VARCHAR(10), 
                      SportType INT, 
					  IsSaba	BIT
                      PRIMARY KEY(MatchId, type)
                     );
        INSERT INTO #Match
               SELECT DISTINCT 
                      m.MatchId, 
                      m.type, 
                      m.sporttype,
					  m.IsSaba
               FROM
               (
					SELECT MatchId, 
						  'match' AS type,
						  m.Sporttype,
						  CASE WHEN l.LeagueId IS NULL THEN 0 ELSE 1 END AS IsSaba
					FROM Match m WITH(NOLOCK)
					LEFT JOIN #SabaVirtualSportsLeague l 
						ON l.LeagueId = m.leagueid 
					WHERE EventDate = @WinlostDate
					UNION ALL
					SELECT orid,  
						  'outright' AS type,
						  ll.Sporttype,
						  CASE WHEN l.LeagueId IS NULL THEN 0 ELSE 1 END AS IsSaba
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
							0 AS IsSaba						   
               ) m              
			   
	------End Get Match ------	

	CREATE TABLE #Supers (Custid INT)
	
	INSERT INTO #Supers
	SELECT c.Custid  
	FROM dbo.Dep_CustSuper c WITH (NOLOCK) 		
	WHERE c.site NOT IN ('Saba789')
		AND c.currency <> 20	

	--------------------------------------------------------------------------------------------------------- 
		CREATE TABLE #wl 
		(	
			Sporttype  		SMALLINT, 			
			LiveIndicator	BIT,
			IsSaba 			BIT	,			
			TurnOver		MONEY,
			Winlost			MONEY, 		
			ExtraWinlost	MONEY
		) 	 
		INSERT INTO #wl (Sporttype, LiveIndicator, IsSaba, TurnOver, winlost, ExtraWinlost)
		SELECT  CASE WHEN m.Sporttype IN (1, 2, 5, 43, 50, -29) THEN m.Sporttype ELSE 0 END AS Sporttype, 
				b.LiveIndicator,		
				m.IsSaba,		
				---Base currency
				SUM (   CASE WHEN b.StatusID = 111 THEN 0 ELSE 
						CASE WHEN ABS(modds) = 0.25 AND b.Bettype <> 29 THEN ABS(Stake) / 2 ELSE  ABS(Stake) END END
						* (1 - b.tpositiontaking - ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) 
						* CASE
							  WHEN virtualrate > actualrate
							  THEN virtualrate
							  ELSE actualrate
							END
					)	 AS TurnOver,
				SUM(
						(ISNULL(winlost,0)-ISNULL(actual_stake,0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)) 
						* actualrate				
					) AS winlost,						
				SUM(
						( CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END) 
							* ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)
							* actualrate 
					) AS ExtraWinlost				
		FROM dbo.bettrans b WITH (NOLOCK)  
		INNER JOIN #Bettype s ON s.BetType = b.bettype
		INNER JOIN #Match AS m 
			ON 	b.MatchId = m.MatchId
			AND m.type = CASE b.BetType WHEN 10 THEN 'outright'
										WHEN 29 THEN 'Parlay'
										ELSE 'Match'                           
                         END			
		WHERE   b.Winlostdate = @WinlostDate
			AND b.statusid IN (111, 112, 113)		
			AND b.bettype < 19001
			AND b.MatchID >= 0
			AND b.Recommend NOT IN (52466,5707545)  --- Exclude 8RM, BARM
			AND b.srecommend IN (SELECT Custid FROM #Supers)
		GROUP BY CASE WHEN m.Sporttype IN (1, 2, 5, 43, 50, -29) THEN m.Sporttype ELSE 0 END, b.LiveIndicator, m.IsSaba
				 
	
		-----------------------------------------------------------------------------------------------
		----- Get Data -----
		SELECt  a.SportName, a.LiveIndicator, a.IsSaba, a.TurnOver, a.Margin, a.HouseWinlost
		FROM  (
				SELECT	s.orderId, s.SportName, w.LiveIndicator, w.IsSaba, w.TurnOver, CASE WHEN w.TurnOver = 0 THEN 0 ELSE (w.winlost - ExtraWinlost) / w.TurnOver * 100 END AS Margin , (w.winlost - ExtraWinlost) AS HouseWinlost
				FROM 	#wl w 
				INNER JOIN #Sports s ON s.Sporttype = w.sporttype
				UNION 
				SELECT	0 AS orderId, 'All Sports' AS SportName, 2 AS LiveIndicator, w.IsSaba, 
						SUM (w.TurnOver) AS TurnOver, 
						CASE WHEN SUM (w.TurnOver) = 0 THEN 0 ELSE SUM (w.winlost - ExtraWinlost) / SUM (w.TurnOver) * 100 END AS Margin , 
						SUM (w.winlost - ExtraWinlost) AS HouseWinlost
				FROM 	#wl w  
				GROUP BY w.IsSaba 
				HAVING  SUM (w.TurnOver) IS NOT NULL 
				) A
		ORDER BY A.OrderId

	DROP TABLE #Bettype
    DROP TABLE #Sports
	DROP TABLE #WL	
	DROP TABLE #Match
	DROP TABLE #Supers
	DROP TABLE #SabaVirtualSportsLeague 
		
END

