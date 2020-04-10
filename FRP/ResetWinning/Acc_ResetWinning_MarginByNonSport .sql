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


	DECLARE @MinTransID_RNG BIGINT,  @MinTransID_LC BIGINT, @MaxTransID_RNG BIGINT,  @MaxTransID_LC BIGINT

	SELECT  @MinTransID_RNG = MIN (TransID) , @MaxTransID_RNG = MAX(TransID) 
	FROM	dbo.BettransRNG WITH (NOLOCK)
	WHERE	@winlostdate = @Winlostdate


	SELECT  @MinTransID_LC = MIN (TransID), @MaxTransID_LC = MAX(TransID) 
	FROM	dbo.BettransLC WITH (NOLOCK)
	WHERE	@winlostdate = @Winlostdate


	------Get Sport Bettype Matrix------
	
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
			
	 
	----- End get sport bettype 
 	

	--------------------------------------------------------------------------------------------------------- 
		CREATE TABLE #WL 
		(	
			ProductId  		SMALLINT, 
			ProductName     VARCHAR(256),			
			TurnOver		MONEY,
			Winlost			MONEY, 		
			ExtraWinlost	MONEY
		) 


		------1. Bettrans
		INSERT INTO #WL (ProductId, ProductName, TurnOver, winlost, ExtraWinlost)
		SELECT  s.ProductId, s.ProductName,
				---Base currency
				SUM (   CASE WHEN b.StatusID = 111 OR b.Bettype IN (911,912) THEN 0 ELSE  ABS(Stake) END
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
										ELSE 0 END
								) * b.actualrate 
							END
					) AS winlost,						
			
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
						* ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)
						*  b.actualrate 
					) AS ExtraWinlost
					
		FROM dbo.bettrans b WITH (NOLOCK, index = CIX_matchid_bettype)  
		INNER JOIN #SportBettype s ON s.BetType = b.bettype 								  
		WHERE   b.Winlostdate = @WinlostDate
			AND b.statusid IN (111, 112, 113)		
			AND b.bettype < 19001
			AND b.MatchID >= 0
			AND s.RefTable NOT IN (1,2)
			AND NOT EXISTS (SELECT 1 FROM CS_CustSuper c WITH (NOLOCK) WHERE c.CustID = b.Srecommend)
		GROUP BY s.ProductId, s.ProductName			 

			 
		------2. BettransRNG
		INSERT INTO #WL (ProductId, ProductName, TurnOver, winlost, ExtraWinlost)
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
						(CASE
							WHEN b.gameId IN(2198, 2398, 2998)
								THEN b.ContributionRate * b.BetStake + awinlost + mwinlost + swinlost + scomm 
							WHEN b.GameId IN (2199,2399,2999,4299,4300)	THEN 0 /*Progressive Jackpot, PP Promotion Prize, PP Tournament Prize*/
							ELSE winlost - actual_stake + awinlost + mwinlost + swinlost + scomm 
							END) * actualrate
					) AS winlost,	

				SUM(			(CASE
                                    WHEN tpositiontaking = 1
                                    THEN 0
                                    WHEN b.GameId IN (2199,2399,2999,4299,4300)	THEN 0 /*Progressive Jackpot, PP Promotion Prize, PP Tournament Prize*/
                                    WHEN b.gameId IN(2198, 2398, 2998)
                                    THEN ContributionRate * BetStake + 1.0 * scomm / (1 - tpositiontaking) --Jackpot Contribution
                                    ELSE winlost - actual_stake + 1.0 * scomm / (1 - tpositiontaking)
                                END) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0) * actualrate
					) AS ExtraWinlost				
		FROM dbo.bettransRNG b WITH (NOLOCK, index = PK_bettransRnG)  
		INNER JOIN #SportBettype s ON s.BetType = b.gameID 								  
		WHERE   b.Winlostdate = @WinlostDate
			AND b.statusid IN (111, 112, 113)
			AND s.RefTable = 1	
			AND b.transID BETWEEN @MinTransID_RNG AND @MaxTransID_RNG
			AND NOT EXISTS (SELECT 1 FROM CS_CustSuper c WITH (NOLOCK) WHERE c.CustID = b.Srecommend)
		GROUP BY s.ProductId, s.ProductName			
	
		------3. BettransLC
		INSERT INTO #WL (ProductId, ProductName, TurnOver, winlost, ExtraWinlost)
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
						( winlost - actual_stake + awinlost + mwinlost + swinlost + scomm ) 
						* actualrate
					) AS winlost,	

				SUM(
						(winlost - actual_stake + 1.0 * scomm / (1 - tpositiontaking)) 
						* ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0) 
						* actualrate
					) AS ExtraWinlost	
		FROM dbo.bettransLC b WITH (NOLOCK, index = PK_bettransLC)  
		INNER JOIN #SportBettype s ON s.BetType = b.gameID 								  
		WHERE   b.Winlostdate = @WinlostDate
			AND b.statusid IN (111, 112, 113)
			AND s.RefTable = 2			
			AND NOT EXISTS (SELECT 1 FROM CS_CustSuper c WITH (NOLOCK) WHERE c.CustID = b.Srecommend)
			AND b.transID BETWEEN @MinTransID_LC AND @MaxTransID_LC
		GROUP BY s.ProductId, s.ProductName		
	
		-----------------------------------------------------------------------------------------------
		----- Get Data -----
		SELECt  a.ProductName, a.TurnOver, a.Margin, a.HouseWinlost
		FROM  (
				SELECT	w.ProductId, w.ProductName, SUM(w.TurnOver) as TurnOver, CASE WHEN SUM(w.TurnOver)  = 0 THEN 0 ELSE SUM(w.winlost - ExtraWinlost) / SUM(w.TurnOver)  * 100 END AS Margin , SUM (w.winlost - ExtraWinlost) AS HouseWinlost
				FROM 	#WL w 
				GROUP BY w.ProductId, w.ProductName 		
				UNION 
				SELECT	0 AS orderId, 'All Non Sports' AS ProductName, 
						SUM (w.TurnOver) AS TurnOver, 
						CASE WHEN SUM (w.TurnOver) = 0 THEN 0 ELSE SUM (w.winlost - ExtraWinlost) / SUM (w.TurnOver) * 100 END AS Margin , 
						SUM (w.winlost - ExtraWinlost) AS HouseWinlost
				FROM 	#WL w  
				HAVING  SUM (w.TurnOver) IS NOT NULL 
				) A
		ORDER BY A.ProductId

	DROP TABLE #SportBettype
	DROP TABLE #WL	 
		
END
GO