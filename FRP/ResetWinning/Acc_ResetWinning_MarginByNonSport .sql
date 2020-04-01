/*<info serverAlias="DBEXT-bodb02" executers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_ResetWinning_MarginByNonSport]
	@Winlostdate SMALLDATETIME 
AS 
 
/*		
	Created: 20200321@Sophia
	Task: Reset Winning - Margin By Non Sport (adhoc) [redmind: #131624]
	DB: DBEXT.BODB02
	
	Revision:
		- 20200321@Sophia: Initial SPs  
		 
	Param Explanation:
		 
	   
*/
BEGIN	
	SET NOCOUNT ON
 	 	
	------Get Sport Bettype Matrix------
	
	CREATE TABLE  #SportBettype (ProductName VARCHAR(256), ProductID INT, Bettype INT )
	INSERT INTO #SportBettype
	SELECT	CASE WHEN s.SubProduct = 'MG-SuperLive' THEN 'Metric Gaming - Super Live'
			WHEN s.SubProduct = 'Bet Builder' THEN 'Bet Builder'
			ELSE p.ProductName END AS ProductName, 
			s.ProductID, s.Bettype 
	FROM dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', 0) s
	LEFT JOIN dbo.Products p WITH (NOLOCK) 
			ON p.ProductID = s.ProductID
	WHERE  s.ProductID <> 1 
		OR s.Bettype BETWEEN 801 and 806  ---'MG-SuperLive'
		OR s.Bettype = 38    ----'Bet Builder' 
			
	 
	----- End get sport bettype 
 	

	--------------------------------------------------------------------------------------------------------- 
		CREATE TABLE #wl 
		(	
			ProductId  		SMALLINT, 
			ProductName     VARCHAR(256),			
			TurnOver		MONEY,
			Winlost			MONEY, 		
			ExtraWinlost	MONEY
		) 	 
		INSERT INTO #wl (ProductId, ProductName, TurnOver, winlost, ExtraWinlost)
		SELECT  s.ProductId, s.ProductName,
				---Base currency
				SUM (   CASE WHEN b.StatusID = 111 THEN 0 ELSE ABS(Stake) END
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
		FROM dbo.bettrans b WITH (NOLOCK, index = CIX_matchid_bettype)  
		INNER JOIN #SportBettype s ON s.BetType = b.bettype 								  
		WHERE   b.Winlostdate = @WinlostDate
			AND b.statusid IN (111, 112, 113)		
			AND b.bettype < 19001
			AND b.MatchID >= 0
			AND NOT EXISTS (SELECT 1 FROM CS_CustSuper c WITH (NOLOCK) WHERE c.CustID = b.Srecommend)
		GROUP BY s.ProductId, s.ProductName			 

			 
	
		-----------------------------------------------------------------------------------------------
		----- Get Data -----
		SELECt  a.ProductName, a.TurnOver, a.Margin, a.HouseWinlost
		FROM  (
				SELECT	w.ProductId, w.ProductName, w.TurnOver, CASE WHEN w.TurnOver = 0 THEN 0 ELSE (w.winlost - ExtraWinlost) / w.TurnOver * 100 END AS Margin , (w.winlost - ExtraWinlost) AS HouseWinlost
				FROM 	#wl w 				
				UNION 
				SELECT	0 AS orderId, 'All Non Sports' AS ProductName, 
						SUM (w.TurnOver) AS TurnOver, 
						CASE WHEN SUM (w.TurnOver) = 0 THEN 0 ELSE SUM (w.winlost - ExtraWinlost) / SUM (w.TurnOver) * 100 END AS Margin , 
						SUM (w.winlost - ExtraWinlost) AS HouseWinlost
				FROM 	#wl w  
				HAVING  SUM (w.TurnOver) IS NOT NULL 
				) A
		ORDER BY A.ProductId

	DROP TABLE #SportBettype
	DROP TABLE #WL	 
		
END
GO