/*<info serverAlias="DBEXT-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_ResetWinning_MarginByPH]
	@Winlostdate SMALLDATETIME 
AS 
 
/*	
	Created: 20200611@Sophia
	Task: Reset Winning - Margin By PoolHouse PH (adhoc) [redmind: #135755]
	DB: DBEXT.BODB02
	
	Revision:
		- 20200303@Sophia: Initial SPs  
		 
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
			AND SubProduct = 'PHAIO'
	
	--CREATE CLUSTERED INDEX CIX_Bettype ON #Bettype (bettype) 
	----- End get sport bettype  
	
	--------------------------------------------------------------------------------------------------------- 
		CREATE TABLE #WL 
		(	
			Sporttype  		VARCHAR(20), 			
			TurnOver		MONEY,
			Winlost			MONEY, 		
			ExtraWinlost	MONEY
		) 	 
		INSERT INTO #WL (Sporttype, TurnOver, winlost, ExtraWinlost)
		SELECT  'PHAIO' AS Sporttype,  	 						
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
		WHERE   b.Winlostdate = @WinlostDate
			AND b.statusid IN (111, 112, 113)		
			AND b.bettype < 19001
			AND b.MatchID >= 0
			AND b.Recommend NOT IN (52466,5707545)  --- Exclude 8RM, BARM
			AND NOT EXISTS (SELECT 1 FROM CS_CustSuper c WITH (NOLOCK) WHERE c.CustID = b.Srecommend)
		
	
		-----------------------------------------------------------------------------------------------
		----- Get Data -----
		SELECT	w.Sporttype, w.TurnOver, CASE WHEN w.TurnOver = 0 THEN 0 ELSE (w.winlost - ExtraWinlost) / w.TurnOver * 100 END AS Margin , (w.winlost - ExtraWinlost) AS HouseWinlost
		FROM 	#WL w 				
	

	DROP TABLE #Bettype 
	DROP TABLE #WL	 
		
END
GO