/*<info serverAlias="DBEXT-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_ResetWinning_MarginBySite]
	@Winlostdate SMALLDATETIME 
AS 
 
/*		
	Created: 20200321@Sophia
	Task: Reset Winning - Margin By Site (adhoc) [redmind: #133879]
	DB: DBEXT.BODB02
	
	Revision:
		- 20200321@Sophia: Initial SPs  
		- 20200512@Sophia: Margin By Site - break down by Sport / Non Sports [Redmine: #134035]
		- 20200516@Sophia: add code BARM/8RM; exclude MG-SuperLive/ Bet Builder; parlay /2 [Redmine: #134281]
		- 20200518@Sophia: add by groupHeadline [Redmine: #134281]
		- 2020714@Sophia: Add PP Jackpot[Redmine: #137270]
		- 20201124@Sophia: Add detail by Myanmar (site 76666b) [Redmine: #145938]
		- 20210226@Sophia: Exclude Saba.club (Amount due to Jackpot Pool)[RedmineId: #149409] 
		- 20210524@Sophia: Add VGaming (Amount due to Jackpot Pool) [RedmineId: #155697]
		- 20210614@Sophia: Do not separate Exchange Product anymore [Redmine: #156908]
		- 20210917@Sophia: Remove Cashout and Exchange product[Redmine: #161826]
		- 20211224@Sophia: Remove Saba Promotion products [Redmine: #166556]
		- 20220106@Evan: Add SG Jackpot - [Redmine: #166685]	
 		- 20220425@Evan: Remove Casino Amount Jackpot [Redmine: #171865]
	Param Explanation:
		 
	   
*/ 
BEGIN	
	SET NOCOUNT ON


	DECLARE @MinTransID_RNG BIGINT,  @MinTransID_LC BIGINT, @MaxTransID_RNG BIGINT,  @MaxTransID_LC BIGINT

	SELECT  @MinTransID_RNG = MIN (TransID) , @MaxTransID_RNG = MAX(TransID) 
	FROM	dbo.BettransRNG WITH (NOLOCK)
	WHERE	winlostdate = @Winlostdate


	SELECT  @MinTransID_LC = MIN (TransID), @MaxTransID_LC = MAX(TransID) 
	FROM	dbo.BettransLC WITH (NOLOCK)
	WHERE	winlostdate = @Winlostdate


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
	WHERE  s.ProductID NOT IN (25,31, 37)    ---  exclude exchange product, cashout, Saba Promotion
						
	 
	----- End get sport bettype 
	--------------------------------------------------------------------------------------------------------- 
		CREATE TABLE #WL 
		(	
			srecommend 		INT, 
			SB				TINYINT,
			TurnOver		MONEY,
			Winlost			MONEY, 
			WinlostDueTo	MONEY, 
			ExtraWinlost	MONEY
		) 


		------1. Bettrans
		INSERT INTO #WL (srecommend, SB, TurnOver, winlost, WinlostDueTo, ExtraWinlost)
		SELECT  b.srecommend,
				CASE WHEN s.productID = 1 AND ProductName = 'Sportsbook' THEN 1 ELSE 0 END AS SB,
				---Base currency
				SUM (   CASE WHEN b.StatusID = 111 OR b.Bettype IN (911,912) THEN 0 ELSE
						CASE WHEN ABS(modds) = 0.25 AND b.Bettype <> 29 THEN ABS(Stake) / 2 ELSE  ABS(Stake) END END
						* (1 - b.tpositiontaking - ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) 
						* CASE
							  WHEN virtualrate > actualrate
							  THEN virtualrate
							  ELSE actualrate
							END
					)	 AS TurnOver,
				SUM(
						CASE WHEN b.bettype IN (1699, 3899, 4298, 4600) THEN 0
							ELSE
								(ISNULL(winlost,0)-ISNULL(actual_stake,0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)
									+ CASE
										-- Jackpot
										WHEN b.bettype IN (1698, 3898, 4297, 4599) THEN ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000),0)
										ELSE 0 END
								) * b.actualrate 
							END
					) AS winlost,	
										
				--SUM(
				--		(	
				--			CASE
				--				-- Jackpot
				--				WHEN b.bettype IN (2198, 2398, 2998) THEN -ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0)
				--				WHEN b.bettype IN (2199, 2399, 2999) THEN ISNULL(b.Winlost, 0) - ISNULL(b.actual_stake, 0)
				--			ELSE 0 
				--			END
				--		) * b.actualrate
				--	) AS WinlostDueTo,
				0 AS WinlostDueTo,
				SUM(
						(	
							CASE
							-- Jackpot
							WHEN b.bettype IN (1698, 3898, 4297, 4599) THEN
								CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
							WHEN b.bettype IN (1699, 3899, 4298, 4600) THEN 0
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
			AND b.Bettype <> 8000   --- exclude Exchange Product
			AND b.MatchID >= 0
			AND s.RefTable NOT IN (1,2)	
			AND b.Recommend NOT IN (52466,5707545)  --- Exclude 8RM, BARM			
		GROUP BY b.srecommend,
			CASE WHEN s.productID = 1 AND ProductName = 'Sportsbook' THEN 1 ELSE 0 END		

			 
		------2. BettransRNG
		INSERT INTO #WL (srecommend, SB, TurnOver, winlost, WinlostDueTo, ExtraWinlost)
		SELECT  b.srecommend,
				0 AS SB,
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
							WHEN b.gameId IN(1698, 3898, 4297, 4599)
								THEN b.ContributionRate * b.BetStake + awinlost + mwinlost + swinlost + scomm 
							WHEN b.GameId IN (1699, 3899, 4298, 4299, 4300, 4600)	THEN 0 /*Progressive Jackpot, PP Promotion Prize, PP Tournament Prize*/
							ELSE winlost - actual_stake + awinlost + mwinlost + swinlost + scomm 
							END) * actualrate
					) AS winlost,	

				SUM(
						(	
							CASE
								-- Jackpot
								WHEN b.gameid IN (1698, 3898, 4297, 4599) THEN - (b.ContributionRate * b.BetStake)
								WHEN b.gameid IN (1699, 3899, 4298, 4600) THEN ISNULL(b.Winlost, 0) - ISNULL(b.actual_stake, 0)
							ELSE 0 
							END
						) * b.actualrate
					) AS WinlostDueTo,

				SUM(			(CASE
                                    WHEN tpositiontaking = 1
                                    THEN 0
                                    WHEN b.GameId IN (1699, 3899, 4298, 4299, 4300, 4600)	THEN 0 /*Progressive Jackpot, PP Promotion Prize, PP Tournament Prize*/
                                    WHEN b.gameId IN(1698, 3898, 4297, 4599)
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
		GROUP BY b.srecommend			
	
		------3. BettransLC
		INSERT INTO #WL (srecommend, SB, TurnOver, winlost, WinlostDueTo, ExtraWinlost)
		SELECT  b.srecommend,
				0 AS SB,
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

				0 AS WinlostDueTo,

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
			AND b.transID BETWEEN @MinTransID_LC AND @MaxTransID_LC
		GROUP BY b.srecommend	
	

		-----------------------------------------------------------------------------------------------
		----- Get Data -----		
		CREATE TABLE #Winlost (Site VARCHAR(50), SB TINYINT, TurnOver MONEY, Winlost MONEY, ExtraWinlost MONEY)  
					
		INSERT INTO #Winlost (Site, SB, TurnOver, Winlost, ExtraWinlost)						
		SELECT Site, s.SB  AS SB, SUM (s.TurnOver) AS TurnOver, SUM (s.Winlost) AS Winlost, SUM (s.ExtraWinlost) AS ExtraWinlost
		FROM 
		(SELECT c.Site, w.SB, SUM(ISNULL(w.TurnOver,0)) AS TurnOver, 
				SUM(ISNULL( w.Winlost,0)) AS Winlost,
				SUM(ISNULL(w.ExtraWinlost,0)) AS ExtraWinlost
		FROM	#wl w
		INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) 
				ON c.CustID = w.srecommend AND c.roleid = 4			
		GROUP BY c.Site, w.SB 
		) s
		GROUP BY Site, s.SB 

		SELECT a.Site, a.SB, a.TurnOver, a.Margin, a.HouseWinlost, IsDeposit
		FROM  (  
				---- Listed all Site included CN88
				SELECT	Site, SB, SUM(w.TurnOver) as TurnOver, 
						CASE WHEN SUM(w.TurnOver) = 0 THEN 0 ELSE SUM(w.winlost - ExtraWinlost) / SUM(w.TurnOver) * 100 END AS Margin ,
						SUM (w.winlost - ExtraWinlost) AS HouseWinlost,
						CASE WHEN s.SiteID > 1000 OR Site IN ('Saba789') THEN 0 ELSE 1 END AS IsDeposit
				FROM 	#Winlost w 
				INNER JOIN bodb_licensee.dbo.view_site_list s 
					ON s.SiteName = w.Site
				GROUP BY Site, SB, CASE WHEN s.SiteID > 1000 OR Site IN ('Saba789') THEN 0 ELSE 1 END 
				HAVING  SUM (w.TurnOver) IS NOT NULL 
				UNION 
				----- Sum total excluded CN88
				SELECT	'Total (w/o CN88)' AS Site, 
						SB,
						SUM (w.TurnOver) AS TurnOver, 
						CASE WHEN SUM (w.TurnOver) = 0 THEN 0 ELSE SUM (w.winlost - ExtraWinlost) / SUM (w.TurnOver) * 100 END AS Margin , 
						SUM (w.winlost - ExtraWinlost) AS HouseWinlost,
						2 AS IsDeposit
				FROM 	#Winlost w 
				WHERE	Site <> 'CN88'
				GROUP BY SB
				HAVING  SUM (w.TurnOver) IS NOT NULL 
				
				----- Detail Group Headline of 789Y		
				UNION				
				SELECT  ISNULL(g.GroupName, 'Unassigned') AS Site,				         
						w.SB, 
						SUM (w.TurnOver) AS TurnOver, 
						CASE WHEN SUM (w.TurnOver) = 0 THEN 0 ELSE SUM (w.winlost - ExtraWinlost) / SUM (w.TurnOver) * 100 END AS Margin , 
						SUM (w.winlost - ExtraWinlost) AS HouseWinlost,
						CASE WHEN c.Site ='76666b' THEN 5 ELSE 3 END AS isDeposit 
				FROM	#wl w
				INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) 
						ON c.CustID = w.srecommend AND c.roleid = 4	 	 
				LEFT JOIN  (
						SELECT	DISTINCT GroupName , SuperID 
						FROM	bodb02.dbo.Acc_GroupExtraPTSetting E WITH (NOLOCK)   
						WHERE 	@Winlostdate  BETWEEN FromDate AND ToDate 							
							) g
					ON G.SuperId = c.custid  
				WHERE	c.Site IN ('789y', '76666b') and Currency <> 20 				
				GROUP BY ISNULL(g.GroupName, 'Unassigned'),  
						w.SB,
						CASE WHEN c.Site ='76666b' THEN 5 ELSE 3 END

				) a
	 		

		ORDER BY  IsDeposit, Site

	DROP TABLE #SportBettype
	DROP TABLE #WL		
	DROP TABLE #Winlost
	 

END
GO