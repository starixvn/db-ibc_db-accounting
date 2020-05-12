/*<info serverAlias="DBEXT-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_ResetWinning_MarginBySport]
	@Winlostdate SMALLDATETIME 
AS 
 
/*	
	Created: 20200303@Sophia
	Task: Reset Winning - Margin By Sport (adhoc) [redmind: #129653]
	DB: DBEXT.BODB02
	
	Revision:
		- 20200303@Sophia: Initial SPs 
		- 20200305@Sophia: Exclude 8RM and BARM
		 
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
	
	------Get Match ------	
	 CREATE TABLE #Match
                     (MatchId   INT, 
                      type      VARCHAR(10), 
                      SportType INT
                      PRIMARY KEY(MatchId, type)
                     );
        INSERT INTO #Match
               SELECT DISTINCT 
                      m.MatchId, 
                      m.type, 
                      m.sporttype
               FROM
               (
					SELECT MatchId, 
						  'match' AS type,
						  Sporttype
					FROM Match WITH(NOLOCK)
					WHERE EventDate = @WinlostDate
						--AND Sporttype IN (1, 2, 5, 43)
					UNION ALL
					SELECT orid,  
						  'outright' AS type,
						  l.Sporttype
					FROM outright o WITH(NOLOCK)
					INNER JOIN league l WITH (NOLOCK) 
						ON l.leagueID = o.LeagueId					
					WHERE o.EventDate = @WinlostDate
						--AND l.Sporttype IN (1, 2, 5, 43)
					UNION ALL
					SELECT 29 AS MatchId,
						   'Parlay' AS type,
						   -29 AS Sporttype						
               ) m              
			   
	------End Get Match ------			   

	--------------------------------------------------------------------------------------------------------- 
		CREATE TABLE #wl 
		(	
			Sporttype  		SMALLINT, 			
			TurnOver		MONEY,
			Winlost			MONEY, 		
			ExtraWinlost	MONEY
		) 	 
		INSERT INTO #wl (Sporttype, TurnOver, winlost, ExtraWinlost)
		SELECT  CASE WHEN m.Sporttype IN (1, 2, 5, 43, -29) THEN m.Sporttype ELSE 0 END AS Sporttype,  	 						
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
			AND NOT EXISTS (SELECT 1 FROM CS_CustSuper c WITH (NOLOCK) WHERE c.CustID = b.Srecommend)
		GROUP BY CASE WHEN m.Sporttype IN (1, 2, 5, 43, -29) THEN m.Sporttype ELSE 0 END 
				 
	
		-----------------------------------------------------------------------------------------------
		----- Get Data -----
		SELECt  a.SportName, a.TurnOver, a.Margin, a.HouseWinlost
		FROM  (
				SELECT	s.orderId, s.SportName, w.TurnOver, CASE WHEN w.TurnOver = 0 THEN 0 ELSE (w.winlost - ExtraWinlost) / w.TurnOver * 100 END AS Margin , (w.winlost - ExtraWinlost) AS HouseWinlost
				FROM 	#wl w 
				INNER JOIN #Sports s ON s.Sporttype = w.sporttype
				UNION 
				SELECT	0 AS orderId, 'All Sports' AS SportName, 
						SUM (w.TurnOver) AS TurnOver, 
						CASE WHEN SUM (w.TurnOver) = 0 THEN 0 ELSE SUM (w.winlost - ExtraWinlost) / SUM (w.TurnOver) * 100 END AS Margin , 
						SUM (w.winlost - ExtraWinlost) AS HouseWinlost
				FROM 	#wl w  
				HAVING  SUM (w.TurnOver) IS NOT NULL 
				) A
		ORDER BY A.OrderId

	DROP TABLE #Bettype
    DROP TABLE #Sports
	DROP TABLE #WL	
	DROP TABLE #Match
		
END
GO