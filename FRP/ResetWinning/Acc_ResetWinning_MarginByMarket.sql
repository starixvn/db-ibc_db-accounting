/*<info serverAlias="DBEXT-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_ResetWinning_MarginByMarket]
	@Winlostdate SMALLDATETIME 
AS 
 
/*	
	Created: 20200611@Sophia
	Task: Reset Winning - Margin By PoolHouse PH (adhoc) [redmind: #135755]
	DB: DBEXT.BODB02
	
	Revision:
		- 20200303@Sophia: Initial SPs  
		- 20200922@Danny:  Adhoc of Reset winning for PHAIO [redmind: #142019]
	Param Explanation:
		 
	   
*/
BEGIN	
	SET NOCOUNT ON
 
	 
	------Get Sport Bettype Matrix------	
	CREATE TABLE  #Bettype (Bettype INT PRIMARY KEY)
	INSERT INTO #Bettype
	SELECT  Bettype 
	FROM dbo.f_BettypeSportBook_PHAIO()
	
	----- End get sport bettype  

	------Get Match ------	
	CREATE TABLE #Match
                     (MatchId   INT, 
                      type      VARCHAR(10)
                      PRIMARY KEY(MatchId, type)
                     );
    INSERT INTO #Match
               SELECT DISTINCT 
                      m.MatchId, 
                      m.type
               FROM
               (
					SELECT MatchId, 
						  'match' AS type
					FROM Match WITH(NOLOCK)
					WHERE EventDate = @WinlostDate
					UNION ALL
					SELECT orid,  
						  'outright' AS type
					FROM outright o WITH(NOLOCK)
					INNER JOIN league l WITH (NOLOCK) 
						ON l.leagueID = o.LeagueId					
					WHERE o.EventDate = @WinlostDate
					UNION ALL
					SELECT 29 AS MatchId,
						   'Parlay' AS type						
               ) m              
			   
	------End Get Match ------			   

	
	--------------------------------------------------------------------------------------------------------- 
		CREATE TABLE #WL 
		(	
			Market  		VARCHAR(20), 			
			TurnOver		MONEY,
			Winlost			MONEY, 		
			ExtraWinlost	MONEY
		) 	 
		INSERT INTO #WL (Market, TurnOver, winlost, ExtraWinlost)
		SELECT  'PHAIO' AS Market,  	 						
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
		INNER JOIN #Match AS m 
				ON 	b.MatchId = m.MatchId
		INNER JOIN #Bettype s ON s.BetType = b.bettype								  
		WHERE   b.Winlostdate = @WinlostDate
			AND b.statusid IN (111, 112, 113)		
			AND b.bettype < 19001
			AND b.MatchID >= 0
			AND b.Recommend NOT IN (52466,5707545)  --- Exclude 8RM, BARM
			AND NOT EXISTS (SELECT 1 FROM CS_CustSuper c WITH (NOLOCK) WHERE c.CustID = b.Srecommend)
		
	
		-----------------------------------------------------------------------------------------------
		----- Get Data -----
		SELECT	w.Market, w.TurnOver, CASE WHEN w.TurnOver = 0 THEN 0 ELSE (w.winlost - ExtraWinlost) / w.TurnOver * 100 END AS Margin , (w.winlost - ExtraWinlost) AS HouseWinlost
		FROM 	#WL w 				
	

	DROP TABLE #Bettype 
	DROP TABLE #WL	 
	DROP TABLE #Match
		
END
GO