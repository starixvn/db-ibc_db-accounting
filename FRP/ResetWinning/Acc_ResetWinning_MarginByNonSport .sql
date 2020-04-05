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
			WinlostDueTo    MONEY,
			ExtraWinlost	MONEY
		) 	 
		INSERT INTO #wl (ProductId, ProductName, TurnOver, Winlost, WinlostDueTo, ExtraWinlost)
		SELECT  s.ProductId, s.ProductName,
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
						CASE WHEN b.bettype IN (2199, 2399, 2999) THEN 0 
							ELSE
							(ISNULL(winlost,0)-ISNULL(actual_stake,0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)
								+ CASE
									-- Jackpot
									WHEN b.bettype IN (2198, 2398, 2998) THEN ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000),0)
									-- Bet Builder
									WHEN b.bettype = 38 THEN - ((ISNULL(b.winlost,0) - ISNULL(b.actual_stake,0) + ISNULL(b.scomm,0)) * ISNULL(b.oddsspread,0))
									ELSE 0 END
							) *  actualrate  END
					) AS Winlost, 
				
				SUM(
						(CASE
								-- Jackpot
								WHEN b.bettype IN (2198, 2398, 2998) THEN -ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0)
								WHEN b.bettype IN (2199, 2399, 2999) THEN ISNULL(b.winlost, 0) - ISNULL(b.actual_stake, 0)
								-- Bet Builder
								WHEN b.bettype = 38 THEN (ISNULL(b.winlost,0) - ISNULL(b.actual_stake,0) + ISNULL(b.scomm,0)) * ISNULL(b.oddsspread,0)
								ELSE 0 END
						) * b.actualrate
					) AS winlostDueTo,
					
				SUM(
						(
							CASE
							-- Jackpot
							WHEN b.bettype IN (2198, 2398, 2998) THEN
								CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
							WHEN b.bettype IN (2199, 2399, 2999) THEN 0					  
							ELSE
								CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END
							END
						) 
							* b.actualrate 
							* ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)
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
				SELECT	w.ProductId, w.ProductName, 
						w.TurnOver, 
						CASE WHEN w.TurnOver = 0 THEN 0 ELSE (w.winlost - ExtraWinlost) / w.TurnOver * 100 END AS Margin , 
						(w.winlost - ExtraWinlost) AS HouseWinlost
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