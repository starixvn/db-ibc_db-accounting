/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_ResetWinning_SelByDate14]
	@winlostdate	SMALLDATETIME,	
	@totalBalance	MONEY = 0 OUTPUT
AS
/*	
	Created: 20120612@Lukas
	Task: Reset Winning - Get data by Date
	DB: DBACC.BODB02
	
	Revision:
		- 20120723@Lukas: Excluding transfered transactions of dummy balance accounts
		- 20120725@Lukas: define IBC racing net income instead of gross income
		- 20120820@Sophia: Separate Poker into 2 rows, 1 for IBC net income and Poker (Due to Partners)
		- 20120919@Sophia: Add Virtual Sports
		- 20121102@Elodie: No need execute Acc_ResetWinning_SelByDate_Original (@winlostdate < '2012-09-01')		
		- 20140310@Kathy: Automation of Keno's income account. [Redmine:#13106]
		- 20140626@Logan: Improve performance. [Redmine: #17345]
		- 20150604@Sophia: . Apply Gold Deluxe  
						   . Remove P2P (Poker)
						   . Revise Code
						   . Apply AG Casino and Vegas Game [#37683]
		- 20160308@Sophia: Apply Extra PT [Redmind: #51721]
		- 20160318@Sophia: Exclude data transfer of ExtraPT [Redmine: #54423]
		- 20160324@Sophia:  . Exclude Reset data of ExtraPT, include other transfer tickets
							. Remove Bingo [Redmine: #54719]
		- 20160404@Sophia: Apply Allbet [Redmine: #50588]
		- 20160412@Percy: support Voidbridge single wallet [Redmine: #55258]
		- 20160815@Percy: Apply new bettype of Bettrade: 904 [RedmineID: #61786]
		- 20161004@Percy: Refno Issue [RedmineID: #65007]
		- 20161013@Percy: Apply NG2 [RedmineID: #64117]
		- 20161222@Percy: Apply Fishing World [RedmineID: #65734]
		- 20161227@Percy: Clean up code Cockfighting [RedmineID: #69446]
		- 20170112@Percy: Change Extra PT formula [RedmineID: #70060]
		- 20170213@Percy: Remove SLI [RedmineID: #70036]
		- 20170323@Percy: Apply Cash Out [RedmineID: #72164]
		- 20170706@Percy: Apply Betradar VS and Keno Lottery [RedmineID: #79521]
		- 20170727@Percy: Expand bettype range of OneRNG Casino [RedmineID: #78424]
		- 20170915@Percy: Apply Lucky 3 [RedmineID: #83227]
		- 20180116@Percy: Apply Exchange [RedmineID: #88810]
		- 20180313@Percy: Apply Bullfighting, Remove Racing [RedmineID: #84691]
		- 20180412@Percy: Apply OneRnG Jackpot [RedmineID: #90357]
		- 20180521@Percy: Apply PP - Pragmatic, update bettype range of Macau Games [RedmineID: #95529]
		- 20180821@Percy: Apply Poker Games [RedmineID: #100168]
		
	Explanation's Param:

*/
BEGIN	
	SET NOCOUNT ON

	DECLARE @EffectedDate DATETIME -- 20160112@Percy: Applying date of changing extra PT formula [RedmineID: #70060]
	SELECT  @EffectedDate = '2017-01-19'

	DECLARE @DummyBalance AS TABLE (CustId INT, Product VARCHAR(50), seq TINYINT )
	DECLARE @dummyExtraPT TABLE(CustId INT )

	------Get Sport Bettype Matrix------
	-- Check SP Version
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	SELECT ProductID, Bettype, SubProduct FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)	
	----- End get sport bettype
	
	DECLARE @SQL NVARCHAR(100) = OBJECT_NAME(@@PROCID)	
	
	IF (@SQL not like '%_xtest%')
	BEGIN 
		INSERT INTO @DummyBalance (CustID, Product, seq)
		SELECT CustID, Product, seq
		FROM bodb_ACC.dbo.Acc_DWLList WITH(NOLOCK)
		WHERE Product NOT IN ('Total Balance')
			AND IsDeleted = 0
		
		INSERT INTO @dummyExtraPT (CustID)
		SELECT CustID
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT l WITH (NOLOCK)
				
	END 
	ELSE
	BEGIN 
		INSERT INTO @DummyBalance (CustID, Product, seq)
		SELECT CustID, Product, seq
		FROM bodb_ACC.dbo.Acc_DWLList_xtest WITH(NOLOCK)
		WHERE Product NOT IN ('Total Balance')
			AND IsDeleted = 0
		
		INSERT INTO @dummyExtraPT (CustID)
		SELECT CustID
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT_xtest l WITH (NOLOCK)
	END 

-------------------------------------------------  
	
	DECLARE @Winning TABLE 
	(
	   	product     varchar(50),
		winlost     money
	)
		
	CREATE TABLE #source
	(
	    custid        INT,
	    bettype       INT,
	    winlost       MONEY
	)

	INSERT INTO #source
	SELECT CASE
	         WHEN b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 then d.custid
	         ELSE -1
	       END AS custid,
           bettype,
           SUM(ISNULL((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
               ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0)) * (CASE
	                                                                              WHEN ISNULL(d.custid, -1) <> -1 AND b.bettype IN (21001, 21002) THEN 1
	                                                                              ELSE actualrate
	                                                                            END), 0)) as winlost
    FROM bettrans b WITH(READPAST, INDEX = IX_Report)
	LEFT JOIN @DummyBalance d ON b.custid = d.custid
	WHERE b.ruben = 1
	   AND b.winlostdate = @winlostdate
	   AND b.statusid NOT IN (101, 102, 103, 121)
	   AND b.bettype > 19000 
	   AND (CASE WHEN b.CustId IN (SELECT CustId FROM @dummyExtraPT) AND Bettype IN (21001,21002) THEN 0 ELSE 1 END = 1)
	GROUP BY CASE
             WHEN b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 then d.custid
             ELSE -1
           END, b.bettype
	HAVING SUM(ISNULL((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
               ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0)) * (CASE
	                                                                              WHEN ISNULL(d.custid, -1) <> -1 AND b.bettype IN (21001, 21002) THEN 1
	                                                                              ELSE actualrate
	                                                                            END), 0)) <> 0

	-- get total balance
	SELECT @totalBalance = ISNULL(SUM(winlost), 0)
	FROM #source
	WHERE custid NOT IN (SELECT custid FROM @DummyBalance)
	   AND bettype <> 20000


	CREATE TABLE #bettranstmp
	(
	 	custid			INT,
	    bettype         int,
	    liveindicator   bit,
	    winlost         money,
		winlostDueTo	money,
		Sporttype		smallint
	)

	INSERT INTO #bettranstmp
	SELECT	b.custid, b.bettype,
			b.liveindicator,
			SUM(
				CASE WHEN b.bettype IN (2199, 2399, 2999) THEN 0
					ELSE
					(ISNULL(winlost,0)-ISNULL(actual_stake,0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)
					+ CASE
						-- Jackpot
						WHEN b.bettype IN (2198, 2398, 2998) THEN ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000),0)
						-- Poker Games
						WHEN b.bettype BETWEEN 1401 AND 1499 THEN ISNULL(b.oddsspread,0) * ISNULL(b.modds,0)
						ELSE 0 END
					) * b.actualrate END
			) AS winlost,
			SUM(
				(CASE
						-- Jackpot
						WHEN b.bettype IN (2198, 2398, 2998) THEN -ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0)
						WHEN b.bettype IN (2199, 2399, 2999) THEN ISNULL(b.winlost, 0) - ISNULL(b.actual_stake, 0)
						-- Poker Games
						WHEN b.bettype BETWEEN 1401 AND 1499 THEN -ISNULL(b.oddsspread,0) * ISNULL(b.modds,0)
					ELSE 0 END
				) * b.actualrate
			) AS winlostDueTo,
			CASE WHEN ISNULL(m.Sporttype, 0) <> 0	THEN m.Sporttype ELSE 0 END AS Sporttype
	FROM dbo.bettrans14 b WITH(NOLOCK)	
	LEFT JOIN @DummyBalance d ON b.custid = d.custid   
	LEFT JOIN dbo.Match14 m WITH (NOLOCK) ON m.MatchId = b.MatchId AND m.eventdate = @winlostdate AND m.Sporttype = 44
	WHERE 1 = 1
       AND b.winlostdate = @winlostdate
	   AND b.ruben = 1
	   AND b.statusid NOT IN (101, 102, 103, 121)  
    GROUP BY b.custid, b.bettype, b.liveindicator, 
			 CASE WHEN ISNULL(m.Sporttype, 0) <> 0 THEN m.Sporttype ELSE 0 END
	HAVING
			SUM(
				CASE WHEN b.bettype IN (2199, 2399, 2999) THEN 0
					ELSE
					(ISNULL(winlost,0)-ISNULL(actual_stake,0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)
					+ CASE
						-- Jackpot
						WHEN b.bettype IN (2198, 2398, 2998) THEN ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000),0)
						-- Poker Games
						WHEN b.bettype BETWEEN 1401 AND 1499 THEN ISNULL(b.oddsspread,0) * ISNULL(b.modds,0)
						ELSE 0 END
					) * b.actualrate END
			) <> 0
		OR
			SUM(
				(CASE
						-- Jackpot
						WHEN b.bettype IN (2198, 2398, 2998) THEN -ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0)
						WHEN b.bettype IN (2199, 2399, 2999) THEN ISNULL(b.winlost, 0) - ISNULL(b.actual_stake, 0)
						-- Poker Games
						WHEN b.bettype BETWEEN 1401 AND 1499 THEN -ISNULL(b.oddsspread,0) * ISNULL(b.modds,0)
					ELSE 0 END
				) * b.actualrate
			) <> 0
			 

    CREATE NONCLUSTERED INDEX #IX_bettranstmp ON #bettranstmp( custid, bettype)

	INSERT INTO @Winning( product, winlost)
	---- sportsbook live & non-live
	SELECT CASE
	         WHEN liveindicator = 1 THEN 'SPL'
			 WHEN liveindicator = 0 THEN 'SPNL'
		   END Product,
		   ISNULL(SUM(winlost), 0) winlost
	FROM #bettranstmp
	WHERE
		(
			(
				bettype <= 999
				AND bettype NOT IN (9, 10, 29, 71, 72) -- Parlay, Outright, Casino
				AND (bettype NOT BETWEEN 81 AND 120) -- Number Game
				AND (bettype NOT BETWEEN 801 AND 899) -- Metric Gaming
				AND (bettype NOT BETWEEN 901 AND 904) -- Bettrade
				AND (bettype NOT BETWEEN 911 AND 914) -- Cash Out
			)
			OR bettype BETWEEN 1301 AND 1334		
		) 
		AND (Sporttype <> 44) -- Muay Thai
	GROUP BY liveindicator

  	UNION ALL

	SELECT  CASE
			 WHEN bettype BETWEEN 81 AND 120 THEN 'Number Game'	
			 WHEN
				bettype IN (71, 72)
				OR bettype BETWEEN 2101 AND 2399
				OR bettype BETWEEN 2901 AND 2999
				THEN 'Casino'
			 WHEN bettype = 10 THEN 'Outright'
			 WHEN bettype IN (9, 29) THEN 'Parlay'
			 WHEN bettype BETWEEN 1201 AND 1299 THEN 'Virtual Sports'
			 WHEN bettype BETWEEN 2700 AND 2899 THEN 'Virtual Sports 2'
			 WHEN bettype BETWEEN 1501 AND 1599 THEN 'Keno'
			 WHEN bettype BETWEEN 1800 AND 1899 THEN 'AG Casino'
			 WHEN bettype = 1900 THEN 'Macau'
			 WHEN bettype BETWEEN 1700 AND 1799 THEN 'Gold Deluxe'
			 WHEN bettype BETWEEN 801 AND 899 THEN 'Metric Gaming - Super Live'
			 WHEN bettype BETWEEN 2001 AND 2007 THEN 'Microgaming - Live Casino'
			 WHEN bettype BETWEEN 2008 AND 2009 THEN 'Microgaming - RNG Casino'
			 WHEN bettype BETWEEN 901 AND 904 THEN 'Bettrade'
			 WHEN bettype BETWEEN 18000 AND 18099 THEN 'Colossus Bets'
			 WHEN Sporttype = 44 THEN 'Muay Thai'
			 WHEN bettype BETWEEN 2401 AND 2499 THEN 'Allbet' 
			 WHEN bettype BETWEEN 4001 AND 4100 THEN 'Macau Games'
			 WHEN bettype BETWEEN 2501 AND 2699 THEN 'NG2'
			 WHEN bettype BETWEEN 1011 AND 1020 THEN 'Fishing World'
			 WHEN bettype BETWEEN 911 AND 914 THEN 'Cash Out'
			 WHEN bettype BETWEEN 1021 AND 1049 THEN 'Lottery'
			 WHEN bettype BETWEEN 1600 AND 1610 THEN 'Lucky 3'
			 WHEN bettype BETWEEN 8000 AND 8099 THEN 'Exchange'
			 WHEN bettype = 1004 THEN 'Bullfighting'
			 WHEN bettype BETWEEN 4101 AND 4300 THEN 'PP'
			 WHEN bettype BETWEEN 1401 AND 1499 THEN 'Poker Games'
		   END AS Product,
		   ISNULL(SUM(winlost), 0) AS winlost
	 FROM #bettranstmp
	 WHERE (bettype BETWEEN 80 AND 120
			OR bettype IN (71, 72, 10, 9, 29) ---1000
			OR bettype BETWEEN 1201 AND 1299
			OR bettype BETWEEN 2700 AND 2899
			OR bettype BETWEEN 1501 AND 1599
			OR bettype BETWEEN 1800 AND 1899
			OR bettype = 1900
			OR bettype BETWEEN 1700 AND 1799 
			OR bettype BETWEEN 801 AND 899
			OR bettype BETWEEN 2001 AND 2007  
			OR bettype BETWEEN 2008 AND 2009 
			OR bettype BETWEEN 901 AND 904 
			OR bettype BETWEEN 18000 AND 18099  
			OR bettype BETWEEN 2101 AND 2399
			OR bettype BETWEEN 2901 AND 2999
			OR Sporttype = 44
			OR bettype BETWEEN 2401 AND 2499
			OR bettype BETWEEN 4001 AND 4100
			OR bettype BETWEEN 2501 AND 2699
			OR bettype BETWEEN 1011 AND 1020
			OR bettype BETWEEN 911 AND 914
			OR bettype BETWEEN 1021 AND 1049
			OR bettype BETWEEN 1600 AND 1610
			OR bettype BETWEEN 8000 AND 8099
			OR bettype = 1004
			OR bettype BETWEEN 4101 AND 4300
			OR bettype BETWEEN 1401 AND 1499
		   )
	GROUP BY CASE
			 WHEN bettype BETWEEN 81 AND 120 THEN 'Number Game'
			 WHEN
				bettype IN(71, 72)
				OR bettype BETWEEN 2101 AND 2399
				OR bettype BETWEEN 2901 AND 2999
				THEN 'Casino'
			 WHEN bettype = 10 THEN 'Outright'
			 WHEN bettype IN (9, 29) THEN 'Parlay'
			 WHEN bettype BETWEEN 1201 AND 1299 THEN 'Virtual Sports'
			 WHEN bettype BETWEEN 2700 AND 2899 THEN 'Virtual Sports 2'
			 WHEN bettype BETWEEN 1501 AND 1599 THEN 'Keno'
			 WHEN bettype BETWEEN 1800 AND 1899 THEN 'AG Casino'
			 WHEN bettype = 1900 THEN 'Macau'
			 WHEN bettype BETWEEN 1700 AND 1799 THEN 'Gold Deluxe'
			 WHEN bettype BETWEEN 801 AND 899 THEN 'Metric Gaming - Super Live'
			 WHEN bettype BETWEEN 2001 AND 2007 THEN 'Microgaming - Live Casino'
			 WHEN bettype BETWEEN 2008 AND 2009 THEN 'Microgaming - RNG Casino'
			 WHEN bettype BETWEEN 901 AND 904 THEN 'Bettrade'
			 WHEN bettype BETWEEN 18000 AND 18099 THEN 'Colossus Bets'
			 WHEN Sporttype = 44 THEN 'Muay Thai'
			 WHEN bettype BETWEEN 2401 AND 2499 THEN 'Allbet' 
			 WHEN bettype BETWEEN 4001 AND 4100 THEN 'Macau Games'
			 WHEN bettype BETWEEN 2501 AND 2699 THEN 'NG2'
			 WHEN bettype BETWEEN 1011 AND 1020 THEN 'Fishing World'
			 WHEN bettype BETWEEN 911 AND 914 THEN 'Cash Out'
			 WHEN bettype BETWEEN 1021 AND 1049 THEN 'Lottery'
			 WHEN bettype BETWEEN 1600 AND 1610 THEN 'Lucky 3'
			 WHEN bettype BETWEEN 8000 AND 8099 THEN 'Exchange'
			 WHEN bettype = 1004 THEN 'Bullfighting'
			 WHEN bettype BETWEEN 4101 AND 4300 THEN 'PP'
			 WHEN bettype BETWEEN 1401 AND 1499 THEN 'Poker Games'
	         END

	UNION ALL

	SELECT
		'Casino (Amount due to Jackpot pool)' AS Product,
		ISNULL(SUM(winlostDueTo), 0) winlost
	FROM #bettranstmp
	WHERE bettype IN (2198, 2398, 2998, 2199, 2399, 2999)

	UNION ALL

	SELECT
		'Poker Games (Due To Partners)' AS Product,
		ISNULL(SUM(winlostDueTo), 0) winlost
	FROM #bettranstmp
	WHERE bettype BETWEEN 1401 AND 1499

	---------------------------------------------------------------------------------------------------------
	--------------------------------------------Extra PT ---------------------------------------------------

	CREATE TABLE #ExtraPTWL
	(
	    ProductId			INT,
		ProductName			VARCHAR(50),
		ExtraPTwinlost		MONEY,
		NewExtraPTwinlost	MONEY
	)
	----Non sportsbook
	;WITH wl AS(
		SELECT b.srecommend,	      
			   0 AS Sporttype,
			   s.ProductId,
			   '' AS SubProduct,
			   SUM((winlost - actual_stake) * actualrate) AS winlost,
			   SUM((
				CASE
					-- Jackpot
					WHEN b.bettype IN (2198, 2398, 2998) THEN
						CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
					WHEN b.bettype IN (2199, 2399, 2999) THEN 0
					-- Poker Games
					WHEN b.bettype BETWEEN 1401 AND 1499 THEN -ISNULL(b.oddsspread, 0)
					ELSE
						CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END
					END) * b.actualrate) AS newwinlost
		FROM dbo.bettrans14 b WITH(NOLOCK)
		INNER JOIN @SportBettype s ON s.BetType = b.bettype
		WHERE  b.winlostdate = @winlostdate
		   --AND b.ruben = 1
		   AND b.statusid NOT IN (101, 102, 103, 121)
		   AND s.ProductID <> 1
		GROUP BY b.srecommend,	      
			   s.ProductId 
			   )
	INSERT INTO #ExtraPTWL (ProductId, ExtraPTwinlost, NewExtraPTwinlost) 
	SELECT	w.ProductId, SUM(w.winlost * s.ExtraPT), SUM(w.newwinlost * s.ExtraPT)
	FROM	wl w
	INNER JOIN dbo.Acc_GroupExtraPTSetting s WITH (NOLOCK)
			ON w.srecommend = s.SuperId
			AND w.ProductId = s.ProductId
			AND w.SubProduct = s.SubProduct
			AND w.Sporttype = s.Sporttype 
			AND @winlostdate BETWEEN s.FromDate AND s.ToDate
	GROUP BY w.Sporttype, w.ProductId, w.SubProduct

	UPDATE e 
	SET ProductName = CASE WHEN e.ProductId = 6 THEN 'Casino' ELSE p.ProductName END
	FROM #ExtraPTWL e
		INNER JOIN dbo.Products p WITH (NOLOCK)
		ON e.ProductId = p.ProductId


	----- SPL, SPNL, MuayThai, Metric gaming, Bettrade, Palay, outright
	;WITH wl AS(
		SELECT b.srecommend,	      
			   CASE WHEN ISNULL(m.Sporttype, 0) <> 0 THEN m.Sporttype ELSE 0 END AS Sporttype,
			   1 AS ProductId,
			   CASE WHEN s.SubProduct = 'MG-SuperLive' THEN 'Metric Gaming - Super Live'
					WHEN s.SubProduct IN ('BT-Sold','BT-Bought','BT-Comm','BT-Winloss') THEN 'Bettrade'
					WHEN ISNULL(m.Sporttype, 0) = 44 THEN 'Muay Thai'
					WHEN b.bettype = 10 THEN 'Outright'
					WHEN b.bettype IN (9,29) THEN'Parlay' 
					WHEN b.liveindicator = 1 THEN 'SPL' 
					WHEN b.liveindicator = 0 THEN 'SPNL'  								     
				END	AS ProductName,
			   CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm','BT-Winloss') THEN s.SubProduct ELSE '' END AS SubProduct,
			   CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm','BT-Winloss') OR ISNULL(m.matchid, 0) <> 0 OR B.Bettype IN (10,9,29) THEN 2 ELSE b.liveindicator END AS liveindicator,
			   SUM((winlost - actual_stake) * actualrate) AS winlost,
			   SUM((CASE WHEN tpositiontaking = 1 THEN 0 ELSE winlost - actual_stake + scomm / (1 - tpositiontaking) END) * actualrate) AS newwinlost
		FROM dbo.bettrans14 b WITH(NOLOCK)	
		INNER JOIN @SportBettype s ON s.BetType = b.bettype
		LEFT JOIN dbo.Match14 m WITH (NOLOCK) ON m.MatchId = b.MatchId AND m.eventdate = @Winlostdate AND m.Sporttype = 44
		WHERE   b.winlostdate = @winlostdate
			---AND b.ruben = 1
			AND b.statusid NOT IN (101, 102, 103, 121)
			AND s.ProductID = 1 		
		GROUP BY b.srecommend,
			   CASE WHEN ISNULL(m.Sporttype, 0) <> 0 THEN m.Sporttype ELSE 0 END,
			   CASE WHEN s.SubProduct = 'MG-SuperLive' THEN 'Metric Gaming - Super Live'
					WHEN s.SubProduct IN ('BT-Sold','BT-Bought','BT-Comm','BT-Winloss') THEN 'Bettrade'
					WHEN ISNULL(m.Sporttype, 0) = 44 THEN 'Muay Thai'
					WHEN b.bettype = 10 THEN 'Outright'
					WHEN b.bettype IN (9,29) THEN'Parlay' 
					WHEN b.liveindicator = 1 THEN 'SPL'
					WHEN b.liveindicator = 0 THEN 'SPNL' 								     
			   END,			   
			   CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm','BT-Winloss') THEN s.SubProduct ELSE '' END,
			   CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm','BT-Winloss') OR ISNULL(m.matchid, 0) <> 0 OR B.Bettype IN (10,9,29) THEN 2 ELSE b.liveindicator END
			   )

	INSERT INTO #ExtraPTWL ( ProductId, ProductName, ExtraPTwinlost, NewExtraPTwinlost) 
	SELECT  w.ProductId, w.ProductName, SUM(w.winlost * s.ExtraPT), SUM(w.newwinlost * s.ExtraPT)
	FROM	wl w
	INNER JOIN dbo.Acc_GroupExtraPTSetting s WITH (NOLOCK)
			ON w.srecommend = s.SuperId
			AND w.ProductId = s.ProductId
			AND w.SubProduct = s.SubProduct
			AND w.Sporttype = s.Sporttype 
			AND @winlostdate BETWEEN s.FromDate AND s.ToDate	
	GROUP BY w.ProductId, w.ProductName
	
	CREATE NONCLUSTERED INDEX #IX_ExtraPTWL ON #ExtraPTWL ( ProductName)
			
	---------------------------------------------------------------------------------------------------------

    --view report
	    ----- calculate reset
	    ;WITH rs AS
	    (
		     SELECT dm.Product,
		           ISNULL(SUM(b.winlost), 0) AS reset
		     FROM #source b
			 INNER JOIN @DummyBalance dm ON b.custid = dm.custid 
	 	     WHERE bettype > 20000
		     GROUP BY dm.product
	    )
		,OpenningBalance AS
		(
			SELECT 'Openning Balance' as product, SUM(ISNULL(winlost, 0)) AS winlost, 0 AS WinlostAfterExtraPT, 0 AS Reset, 0 AS seq
			FROM #source 
			WHERE bettype = 20000
			HAVING SUM(ISNULL(winlost, 0))  <> 0
		)
		,Result AS
		(
			SELECT product, winlost, WinlostAfterExtraPT, reset, seq
			FROM OpenningBalance

			UNION ALL

			SELECT dm.product,
				   ROUND(ISNULL(w.winlost, 0), 2) AS winlost,
				   ROUND(ISNULL(w.winlost, 0), 2) -  ROUND(ISNULL(CASE WHEN @winlostdate < @EffectedDate THEN e.ExtraPTwinlost ELSE e.NewExtraPTwinlost END, 0), 2) AS WinlostAfterExtraPT,
				   ROUND(ISNULL(rs.reset, 0), 2) AS reset,
				   dm.seq
			FROM @Winning w
			FULL OUTER JOIN rs rs ON w.product = rs.product  
			RIGHT JOIN @DummyBalance dm ON dm.product = ISNULL(w.product, rs.product)
			LEFT JOIN #ExtraPTWL e ON e.ProductName = dm.product
		)
		SELECT product, winlost, WinlostAfterExtraPT, reset
		FROM Result
		ORDER BY seq


		DROP TABLE #bettranstmp
		DROP TABLE #ExtraPTWL
		DROP TABLE #source
END
GO