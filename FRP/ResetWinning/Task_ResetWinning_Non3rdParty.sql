/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE bodb02
GO
ALTER PROCEDURE [dbo].[Task_ResetWinning_Non3rdParty]
	@fromdate smalldatetime,
	@todate   smalldatetime,
	@mode     tinyint = 0,
	@creator  INT = 5838421,
	@ip       VARCHAR(45) = '',
	@MoveBetDay SMALLDATETIME = NULL,
	@ErrCode  INT = 0 output,
    @ErrMsg   VARCHAR(100) = '' output
AS
 
/*	
	Created: 20140619@Logan
	Task: Reset Winning - Reset Company Balance for a period
	DB: DBACC.BODB02
	
	Revision:
		- 20140619@Logan: Initial version - Redmine: 17345
		- 20150604@Sophia: . Apply Gold Deluxe 
						   . Remove P2P (Poker)
						   . Revise Code
						   . Apply AG Casino and Vegas Game [#37683]
		- 20150702@Sophia: Apply Metric Gaming, Microgaming and Bettrade [#36906]
		- 20150922@Sophia: Apply Colossus Bets and expand the range of AG Casino [#43352]
		- 20151102@Sophia: Apply Microgaming LC and RNG [RedmineID: #46450]
		- 20151210@Sophia: Apply Cock Fighting [Redmine: #48602]
		- 20151217@Sophia: Apply Muay Thai [Redmine: #48667]
		- 20160114@Sophia: Apply OW RNG [Redmine: #48285]
		- 20160307@Sophia: Apply Extra PT [Redmind: #51721]
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
		- 20180412@Percy:
			. Apply OneRnG Jackpot [RedmineID: #90357]
			. Increase Transdesc length to 1000 [RedmineID: #92841]
		- 20180521@Percy: Apply PP - Pragmatic, update bettype range of Macau Games [RedmineID: #95529]
		- 20180821@Percy: Apply Poker Games [RedmineID: #100168]
		- 20180830@Sophia: Apply Poker Games Phase 2 - Insurance [RedmineID: #100168]
		- 20181130@Percy: Apply E-Sports & Happy 5 [RedmineID: #105112]
		- 20190412@Percy: Apply BetBuilder & Pragmatic [RedmineID: #106981]
		- 20190516@Percy: Bet Builder - Change Due to Partner's formula [RedmineID: #113550]
		- 20190522@Sophia: Rename Keno to RNG Keno [RedmineID: #113490]
		- 20190701@Percy: Remove WL due to partner [RedmineID: #115802]
		- 20190701@Percy: Apply Card Club [RedmineID: #117005]
		- 20190729@Sophia: Exclude CN88 data [Redmine: #117169]
		- 20190801@Sophia: Integrate CN88 & refactor code[Redmine: #117809]		 
		- 20190829@Sophia: Tuning Code high memory [redmine: #119435]
		- 20190903@Sophia: fix bug [remine: #119553]
		- 20190826@Sophia: exclude CN88 Headline balance out of total balance [Redmine: #117863]
		- 20191210@Percy: Set actualrate = 1 of UUS currency (exchangeid = 20) for testing (version xtest) [RedmineID: #124484]
		- 20191216@Percy: Using new column bettrans.epositiontaking instead of Acc_GroupExtraPTSetting.ExtraPT [RedmineID: #125418]
		- 2020714@Sophia: Add PP Jackpot & revise code [Redmine: #137270]
		- 20210203@Malcolm : Add Saba.club (Amount due to Jackpot Pool) into Reset winning [RedmineId : #149409]
		- 20210426@Sol: Alpha/NAP - Migrate from DBACC to DBCust - [Redmine: #154041]
		- 20210512@Malcolm : Add VGaming (Amount due to Jackpot Pool) into Reset winning [RedmineId : #154643]
		- 20210505@Sol: NAP - Alpha - Allow more time for transfer - [Redmine: #149927]
		- 20210816@Sol: fix nested insert exec - [Redmine: #160212]
		- 20210907@Evan: Exclude CN88 data, Tuning Code - [Redmine: #161262]
		- 20220112@Evan: Add SG Jackpot & revise SP [Redmine: #166685]
		- 20211122@Danny: Split transfer tickets out of bettrans [Redmine: #164196]
		- 20220425@Evan: Change product name and remove Casino Jackpot Amount [Redmine: #171865]
		- 20230609@Danny: support scale out credit [Redmine: #181595]

	Param Explanation:
	    @mode:  0 _ view report
	            1 _ reset balance
	            
	    @ErrCode: 0 _ Success
	              1 _ Error
	              2 _ Already reset
*/
BEGIN	
	SET NOCOUNT ON

	-- get move bet date
	DECLARE @balanceUpDay SMALLDATETIME, @moveBetsDay SMALLDATETIME
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	IF (@MoveBetDay IS NULL)
	BEGIN
		INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
		EXEC bodb02.dbo.Age_SelBalanceUpDay

		SELECT @balanceUpDay = BalanceUpDay, @moveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp
	END
	ELSE
	BEGIN
		SELECT @moveBetsDay = @MoveBetDay
	END
	
	--validate movebet date
	IF (@fromdate < DATEADD(DAY, 1, @moveBetsDay))
	BEGIN
		SELECT @ErrMsg = 'The Move Bets Day is changed. Please click on OK button to reload this page.',
               @ErrCode = 1
		RETURN
	END

	------Get Sport Bettype Matrix------
	-- Check SP Version
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	CREATE TABLE #SportBettype (Bettype INT, ProductID INT, SubProduct VARCHAR(500), PRIMARY KEY (Bettype, ProductID, SubProduct))
	INSERT INTO #SportBettype (Bettype, ProductID, SubProduct)
	SELECT DISTINCT Bettype, ProductID, SubProduct FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)
	----- End get sport bettype 
    
	DECLARE @SQL NVARCHAR(100) = ISNULL(OBJECT_NAME(@@PROCID),'')
	SELECT @Istest = CASE WHEN @SQL like '%[_]xtest' THEN 1 ELSE 0 END -- just _xtest version only
	
	DECLARE @dummyBalance TABLE (CustId INT, Product VARCHAR(250), seq INT, IsExtraPT BIT)
	IF @Istest = 0
	BEGIN
		INSERT INTO @dummyBalance (CustId, Product, IsExtraPT, Seq)
		SELECT CustId, Product, 0, CASE WHEN Seq = 0 THEN 999 ELSE Seq END
		FROM dbo.Acc_DWLList WITH (NOLOCK)
		WHERE IsDeleted = 0

		INSERT INTO @dummyBalance (CustId, IsExtraPT)
		SELECT CustId, 1
		FROM dbo.Acc_DWLList_ExtraPT WITH (NOLOCK)
	END
	ELSE
	BEGIN 
		INSERT INTO @dummyBalance (CustId, Product, IsExtraPT, Seq)
		SELECT CustId, Product, 0, CASE WHEN Seq = 0 THEN 999 ELSE Seq END
		FROM dbo.Acc_DWLList_xtest WITH (NOLOCK)
		WHERE IsDeleted = 0

		INSERT INTO @dummyBalance (CustId, IsExtraPT)
		SELECT CustId, 1
		FROM dbo.Acc_DWLList_ExtraPT_xtest WITH (NOLOCK)
	END

	------------------------------------------------  
	CREATE TABLE #Transfer
	(
		winlostdate     SMALLDATETIME,
		custid          INT,
		product			VARCHAR(250),
	    Winlost         MONEY,
		RealWinlost 	MONEY
	)

	INSERT INTO #Transfer (winlostdate, custid, product, winlost, Realwinlost)
	SELECT winlostdate, CASE WHEN bettype IN (21001, 21002) THEN custid ELSE -1 END AS custid, '' AS product
		,SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) AS Winlost
		,SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm)) AS RealWinlost
	FROM dbo.transfer WITH (NOLOCK)
	WHERE winlostdate BETWEEN @fromdate AND @todate
	   AND ((bettype = 19999 AND winlostdate <= @moveBetsDay)  OR (bettype > 19999 ))
	   AND bettype <> 21007 -- Exclude CN88 headline balance
	GROUP BY winlostdate, CASE WHEN bettype IN (21001, 21002) THEN custid ELSE -1 END
	
	DELETE t FROM #Transfer t WHERE t.CustId IN (SELECT d.CustId FROM @dummyBalance d WHERE d.IsExtraPT = 1)
	DELETE @dummyBalance WHERE IsExtraPT = 1

	;WITH CTE_Transfer AS (
		SELECT t.winlostdate, ISNULL(d.CustId, -1) AS CustId, ISNULL(d.Product, '') AS Product
			,SUM(t.Winlost) AS Winlost, SUM(t.RealWinlost) AS RealWinlost
		FROM #Transfer t
			LEFT JOIN @dummyBalance d ON t.CustId = d.CustId
		GROUP BY t.winlostdate, ISNULL(d.CustId, -1), ISNULL(d.Product, '')
	)
	MERGE #Transfer AS t
	USING CTE_Transfer AS s ON t.winlostdate = s.winlostdate AND t.CustId = s.CustId
	WHEN MATCHED THEN UPDATE
		SET t.Product = s.Product, t.Winlost = s.Winlost, t.RealWinlost = s.RealWinlost
	WHEN NOT MATCHED BY SOURCE THEN DELETE;

	--------------------------------------------------------------------------------------------------------- 
	/* Get bet tickets*/
	CREATE TABLE #tmpData (
		winlostdate		smalldatetime
		,MatchId		int
		,bettype		smallint
		,liveindicator	bit 
		,winlost				money
		,eWinlost				money
		,WinlostDueToPP			money default (0)
		,WinlostDueToSaba		money default (0)
		,WinlostDueToVgaming	money default (0)
		,WinlostDueToSG		    money default (0)
		,RealWinlost				money
		,eRealWinlost				money
		,RealWinlostDueToPP			money default (0)
		,RealWinlostDueToSaba		money default (0)
		,RealWinlostDueToVgaming	money default (0)
		,RealWinlostDueToSG			money default (0)
		PRIMARY KEY (winlostdate, bettype, MatchId, liveindicator)
	)
	
	;WITH CTE_tmpData AS (
		SELECT winlostdate, bettype, matchId, liveindicator,winlost, actual_stake ,awinlost, mwinlost, swinlost, scomm, betid, actualrate, epositiontaking,tpositiontaking,statusID
		FROM dbo.bettrans WITH (NOLOCK)
		WHERE Winlostdate between @fromdate and @todate
			AND bettype < 19999
			AND winlostdate > @moveBetsDay
			AND ruben = 1
			AND statusID IN (111, 112, 113)
	) 
	INSERT INTO #tmpData (winlostdate, bettype, MatchId, liveindicator
		,winlost, eWinlost, WinlostDueToPP, WinlostDueToSaba, WinlostDueToVgaming, WinlostDueToSG
		,RealWinlost, eRealWinlost, RealWinlostDueToPP, RealWinlostDueToSaba, RealWinlostDueToVgaming, RealWinlostDueToSG)
	---------Jackpot contribution tickets --------------
	SELECT winlostdate, bettype, 0 AS MatchId, 0 AS liveindicator,
		-- Base Currency
		SUM(CASE
				-- Jackpot Prize
				WHEN bettype IN (1699, 3899, 4298, 4600) THEN 0
				-- Jackpot full Contribution
				WHEN bettype IN (1698, 3898, 4297, 4599) 
					THEN winlost - actual_stake + awinlost + mwinlost + swinlost + scomm + ISNULL(betid/CONVERT(DECIMAL(19,8), 100000000), 0)
				ELSE 0 END 
				* CASE WHEN @Istest = 1 THEN 1 ELSE actualrate END) AS winlost,
		SUM(CASE
				-- Jackpot Prize
				WHEN bettype IN (1699, 3899, 4298, 4600) THEN 0
				-- Jackpot full Contribution
				WHEN bettype IN (1698, 3898, 4297, 4599) 
					THEN ISNULL(betid/CONVERT(DECIMAL(19,8), 100000000), 0)
				ELSE 0 END 
				* CASE WHEN @Istest = 1 THEN 1 ELSE actualrate END 
				* ISNULL(epositiontaking, 0)) AS eWinlost,
		SUM(CASE
				WHEN bettype IN (4297) THEN -ISNULL(betid/CONVERT(DECIMAL(19,8), 100000000), 0)
				WHEN bettype IN (4298) THEN winlost - actual_stake
				ELSE 0 END 
				* CASE WHEN @Istest = 1 THEN 1 ELSE actualrate END) AS WinlostDueToPP,
		SUM(CASE
				WHEN bettype IN (1698) THEN -ISNULL(betid/CONVERT(DECIMAL(19,8), 100000000), 0)
				WHEN bettype IN (1699) THEN winlost - actual_stake
				ELSE 0 END 
				* CASE WHEN @Istest = 1 THEN 1 ELSE actualrate END) AS WinlostDueToSaba,
		SUM(CASE
				WHEN bettype IN (3898) THEN -ISNULL(betid/CONVERT(DECIMAL(19,8), 100000000), 0)
				WHEN bettype IN (3899) THEN winlost - actual_stake
				ELSE 0 END 
				* CASE WHEN @Istest = 1 THEN 1 ELSE actualrate END) AS WinlostDueToVgaming,
		SUM(CASE
				WHEN bettype IN (4599) THEN -ISNULL(betid/CONVERT(DECIMAL(19,8), 100000000), 0)
				WHEN bettype IN (4600) THEN winlost - actual_stake
				ELSE 0 END 
				* CASE WHEN @Istest = 1 THEN 1 ELSE actualrate END) AS WinlostDueToSG,
		-- Real Currency
		SUM(CASE
				-- Jackpot Prize
				WHEN bettype IN (1699, 3899, 4298, 4600) THEN 0
				-- Jackpot full Contribution
				WHEN bettype IN (1698, 3898, 4297, 4599) 
					THEN winlost - actual_stake + awinlost + mwinlost + swinlost + scomm + ISNULL(betid/CONVERT(DECIMAL(19,8), 100000000), 0)
				ELSE 0 END) AS winlost,
		SUM(CASE
				-- Jackpot Prize
				WHEN bettype IN (1699, 3899, 4298, 4600) THEN 0
				-- Jackpot full Contribution
				WHEN bettype IN (1698, 3898, 4297, 4599) THEN ISNULL(betid/CONVERT(DECIMAL(19,8), 100000000), 0)
				ELSE 0 END 
				* ISNULL(epositiontaking, 0)) AS eWinlost,
		SUM(CASE
				WHEN bettype IN (4297) THEN -ISNULL(betid/CONVERT(DECIMAL(19,8), 100000000), 0)
				WHEN bettype IN (4298) THEN winlost - actual_stake
				ELSE 0 END) AS WinlostDueToPP,
		SUM(CASE
				WHEN bettype IN (1698) THEN -ISNULL(betid/CONVERT(DECIMAL(19,8), 100000000), 0)
				WHEN bettype IN (1699) THEN winlost - actual_stake
				ELSE 0 END) AS WinlostDueToSaba,
		SUM(CASE
				WHEN bettype IN (3898) THEN -ISNULL(betid/CONVERT(DECIMAL(19,8), 100000000), 0)
				WHEN bettype IN (3899) THEN winlost - actual_stake
				ELSE 0 END) AS WinlostDueToVgaming,
		SUM(CASE
				WHEN bettype IN (4599) THEN -ISNULL(betid/CONVERT(DECIMAL(19,8), 100000000), 0)
				WHEN bettype IN (4600) THEN winlost - actual_stake
				ELSE 0 END) AS WinlostDueToSG
	FROM CTE_tmpData
	WHERE bettype IN (1698, 1699, 3898, 3899, 4297, 4298, 4599, 4600)
	GROUP BY winlostdate, bettype
	
	--------Normal bet tickets ---------------
	UNION ALL	
	SELECT winlostdate, bettype, matchId, liveindicator,
		-- Base Currency
		SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) 
				* CASE WHEN @Istest = 1 THEN 1 ELSE actualrate END) AS winlost,
		SUM(CASE WHEN tpositiontaking = 1 THEN 0 ELSE (winlost - actual_stake + scomm / (1 - tpositiontaking)) END
				* CASE WHEN @Istest = 1 THEN 1 ELSE actualrate END 
				* ISNULL(epositiontaking, 0)) AS eWinlost, 0, 0, 0, 0,
		-- Real Currency
		SUM(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) AS RealWinlost,
		SUM(CASE WHEN tpositiontaking = 1 THEN 0 ELSE (winlost - actual_stake + scomm / (1 - tpositiontaking)) END
				* ISNULL(epositiontaking, 0)) AS eRealWinlost, 0, 0, 0, 0
	FROM CTE_tmpData 
	WHERE bettype NOT IN (1698, 1699, 3898, 3899, 4297, 4298, 4599, 4600)
	GROUP BY winlostdate, bettype, matchId, liveindicator

	/* Get MatchID for MuayThai */
	DECLARE @FDate DATETIME = @fromdate, @TDate DATETIME = @todate
	
	CREATE TABLE #tmpMatch (matchid INT PRIMARY KEY, sporttype INT) -- current use for MuayThai
	INSERT INTO #tmpMatch (matchid, sporttype)
	SELECT matchid, sporttype
	FROM dbo.match WITH (NOLOCK)
	WHERE eventdate BETWEEN @FDate AND @TDate -- datetime type
		AND sporttype = 44 -- MuayThai

	/* Sum WL by Product */
	CREATE TABLE #WLByProduct
	(
	    winlostdate			SMALLDATETIME, 
		ProductId			INT,
		ProductName			VARCHAR(250),
		SubProduct			VARCHAR(250),
		Winlost				MONEY, 		
		ExtraPTWinlost		MONEY,
		RealWinlost			MONEY, 		
		RealExtraPTWinlost	MONEY 
	)
	 
	;WITH CTE_tmpWL AS (
		SELECT b.winlostdate, s.ProductId
			,CASE
				WHEN s.SubProduct = 'MG-SuperLive' THEN 'Metric Gaming - Super Live'
				WHEN s.SubProduct IN ('BT-Sold','BT-Bought','BT-Comm','BT-Winloss') THEN 'Bettrade'
				WHEN s.SubProduct = 'Bet Builder' THEN 'Bet Builder'
				WHEN ISNULL(m.Sporttype, 0) = 44 THEN 'Muay Thai'
				WHEN b.bettype = 10 THEN 'Outright'
				WHEN b.bettype IN (9,29) THEN'Parlay' 
				WHEN b.liveindicator = 1 AND s.ProductID = 1 THEN 'SPL' 
				WHEN b.liveindicator = 0 AND s.ProductID = 1 THEN 'SPNL'  	
				ELSE '' END	AS ProductName
			,CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm','BT-Winloss','Bet Builder') THEN s.SubProduct ELSE '' END AS SubProduct
			,SUM(b.Winlost)		AS Winlost
			,SUM(b.eWinlost)	AS eWinlost
			,SUM(b.WinlostDueToPP)		AS WinlostDueToPP
			,SUM(b.WinlostDueToSaba)	AS WinlostDueToSaba
			,SUM(b.WinlostDueToVgaming) AS WinlostDueToVgaming
			,SUM(b.WinlostDueToSG) AS WinlostDueToSG
			,SUM(b.RealWinlost)		AS RealWinlost
			,SUM(b.eRealWinlost)	AS eRealWinlost
			,SUM(b.RealWinlostDueToPP)		AS RealWinlostDueToPP
			,SUM(b.RealWinlostDueToSaba)	AS RealWinlostDueToSaba
			,SUM(b.RealWinlostDueToVgaming) AS RealWinlostDueToVgaming
			,SUM(b.RealWinlostDueToSG) AS RealWinlostDueToSG
		FROM #tmpData b
			INNER JOIN #SportBettype s ON s.BetType = b.bettype
			LEFT JOIN #tmpMatch m ON m.MatchId = b.MatchId
		GROUP BY b.winlostdate, s.ProductId,
			CASE
				WHEN s.SubProduct = 'MG-SuperLive' THEN 'Metric Gaming - Super Live'
				WHEN s.SubProduct IN ('BT-Sold','BT-Bought','BT-Comm','BT-Winloss') THEN 'Bettrade'
				WHEN s.SubProduct = 'Bet Builder' THEN 'Bet Builder'
				WHEN ISNULL(m.Sporttype, 0) = 44 THEN 'Muay Thai'
				WHEN b.bettype = 10 THEN 'Outright'
				WHEN b.bettype IN (9,29) THEN'Parlay' 
				WHEN b.liveindicator = 1 AND s.ProductID = 1 THEN 'SPL' 
				WHEN b.liveindicator = 0 AND s.ProductID = 1 THEN 'SPNL'  	
				ELSE '' END,
				CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm','BT-Winloss','Bet Builder') THEN s.SubProduct ELSE '' END
	)
	INSERT INTO #WLByProduct (Winlostdate, ProductId, ProductName, Winlost, ExtraPTWinlost, RealWinlost, RealExtraPTWinlost)
	SELECT c.winlostdate, d.ProductId, d.ProductName, SUM(ISNULL(d.Winlost, 0)), SUM(ISNULL(d.eWinlost, 0)), SUM(ISNULL(d.RealWinlost, 0)), SUM(ISNULL(d.eRealWinlost, 0))
	FROM CTE_tmpWL c
		CROSS APPLY (
			SELECT c.ProductId, c.ProductName, c.Winlost, c.eWinlost, c.RealWinlost, c.eRealWinlost
			UNION ALL SELECT 0, 'PP (Amount due to Jackpot Pool)', c.WinlostDueToPP, 0, c.RealWinlostDueToPP, 0 WHERE c.WinlostDueToPP <> 0
			UNION ALL SELECT 0, 'Saba.club (Amount due to Jackpot Pool)', c.WinlostDueToSaba, 0, c.RealWinlostDueToSaba, 0 WHERE c.WinlostDueToSaba <> 0
			UNION ALL SELECT 0, 'VGaming (Amount due to Jackpot Pool)', c.WinlostDueToVgaming, 0, c.RealWinlostDueToVgaming, 0 WHERE c.WinlostDueToVgaming <> 0
			UNION ALL SELECT 0, 'SG (Amount due to Jackpot Pool)', c.WinlostDueToSG, 0, c.RealWinlostDueToSG, 0 WHERE c.WinlostDueToSG <> 0
		) d
	GROUP BY c.winlostdate, d.ProductId, d.ProductName

	-- Update ProductName
	UPDATE e 
	SET ProductName = p.ProductName 
	FROM #WLByProduct e
		INNER JOIN dbo.Products p WITH (NOLOCK) ON e.ProductId = p.ProductId
	WHERE e.ProductId NOT IN (0, 1)

	---------------------------------------------------------------------------------------------------------
    --view report
    IF (@mode = 0)
    BEGIN 
	    ----- calculate reset
	   ;WITH reset AS
	    (
		     SELECT b.Winlostdate,
		           b.Product,
		           SUM(ISNULL(b.Winlost, 0)) AS Reset,
				   SUM(ISNULL(b.RealWinlost, 0)) AS RealReset
		     FROM #Transfer b	     
			 WHERE CustID <> -1
			 GROUP BY b.Winlostdate, b.product
	    )
		,TotalBalance AS
	    (
			SELECT Winlostdate, product, SUM(Balance) As Balance
			FROM (
					SELECT b.Winlostdate,
					'Total Balance' as Product,
					SUM(ISNULL(b.Winlost, 0)) AS balance
					FROM #Transfer b	     
					WHERE CustID = -1
					GROUP BY b.Winlostdate 

					UNION ALL
					SELECT  b.Winlostdate,
					'Total Balance' as Product,
					SUM(ISNULL(b.Winlost, 0)) AS balance
					FROM #WLByProduct b
					GROUP BY b.Winlostdate 
			 ) b
			 GROUP BY winlostdate, product
	    ), CTE_Date AS (
			SELECT @fromdate AS WinlostDate
			UNION ALL SELECT DATEADD(DAY, 1, WinlostDate) FROM CTE_Date WHERE WinlostDate < @todate
		)
		SELECT d.Winlostdate,
				dm.product,
				CASE dm.product
					WHEN 'Total Balance' THEN ROUND(SUM(ISNULL(bl.balance, 0)), 2) ELSE ROUND(SUM(ISNULL(e.Winlost, 0)), 2) END AS Winlost,
				CASE dm.product
					WHEN 'Total Balance' THEN 0 ELSE ROUND(SUM(ISNULL(e.Winlost, 0)), 2) - ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2) END AS WinlostAfterExtraPT,
				CASE dm.product
					WHEN 'Total Balance' THEN 0
					ELSE CASE WHEN @istest = 1 THEN ROUND(SUM(ISNULL(rs.RealReset, 0)), 2) ELSE ROUND(SUM(ISNULL(rs.reset, 0)), 2) END
				END AS reset,				
				dm.seq
		FROM @dummyBalance dm
			CROSS JOIN CTE_Date d
			LEFT JOIN #WLByProduct e ON dm.product = e.productName and d.Winlostdate = e.Winlostdate
			LEFT JOIN reset rs ON dm.product = rs.product and d.Winlostdate = rs.Winlostdate 
			LEFT JOIN TotalBalance bl ON bl.Product = dm.Product AND bl.winlostdate = d.WinlostDate
		GROUP BY d.Winlostdate, dm.product, dm.seq
		ORDER BY d.Winlostdate DESC, dm.seq ASC
		OPTION (MAXRECURSION 0)
	END
	--reset balance
	ELSE IF (@mode = 1)
	BEGIN
		CREATE TABLE #reset
		(
			winlostdate 		SMALLDATETIME,
			product     		VARCHAR(250),
			winlost				MONEY,
			WinlostAfterExtraPT MONEY,
			reset       		MONEY,
			latestreset 		MONEY,
			Realwinlost				MONEY,
			RealWinlostAfterExtraPT MONEY,
			Realreset       		MONEY,
			Reallatestreset 		MONEY,
			seq         		INT IDENTITY (1,1)
		)
		 ----- calculate reset
	    ;WITH reset AS
	    (
		     SELECT b.Winlostdate,
		            b.Product,
		           SUM(CASE WHEN @Istest = 1 THEN ISNULL(b.RealWinlost, 0) ELSE ISNULL(b.Winlost, 0) END ) AS reset,
				   SUM(ISNULL(b.RealWinlost, 0)) AS RealReset
		     FROM #Transfer b	     
			 WHERE CustID <> -1
			 GROUP BY b.Winlostdate, b.product
	    )
		,TotalBalance AS
	    (
			SELECT Winlostdate, product, SUM(Balance) As Balance
			FROM (
		     SELECT b.Winlostdate,
		           'Total Balance' as Product,
		            SUM(ISNULL(b.Winlost, 0)) AS balance
		     FROM #Transfer b	     
			 WHERE CustID = -1
			 GROUP BY b.Winlostdate 
			 UNION ALL
			 SELECT  b.Winlostdate,
		           'Total Balance' as Product,
				   SUM(ISNULL(b.Winlost, 0)) AS balance
			 FROM #WLByProduct b
			 GROUP BY b.Winlostdate 
			 ) b
			 GROUP BY winlostdate, product
	    ), CTE_Date AS (
			SELECT @fromdate AS WinlostDate
			UNION ALL SELECT DATEADD(DAY, 1, WinlostDate) FROM CTE_Date WHERE WinlostDate < @todate
		)
		INSERT INTO #reset(Winlostdate, product,  Winlost, WinlostAfterExtraPT, reset, latestreset, RealWinlost, RealWinlostAfterExtraPT, RealReset, RealLatestReset)
	    SELECT d.Winlostdate,
	           dm.product,
	           CASE dm.product
	             WHEN 'Total Balance' THEN ROUND(SUM(ISNULL(bl.balance, 0)), 2) ELSE ROUND(SUM(ISNULL(e.Winlost, 0)), 2) END AS Winlost,
			   CASE dm.product
	             WHEN 'Total Balance' THEN 0 ELSE ROUND(SUM(ISNULL(e.Winlost, 0)), 2) - ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2) END AS WinlostAfterExtraPT,
	           CASE dm.product
	             WHEN 'Total Balance' THEN 0
	             ELSE ROUND(SUM(ISNULL(rs.reset, 0)), 2)
	           END AS reset,
			   CASE
	             WHEN dm.Product IN ('Total Balance') THEN 0 
	             ELSE - (ROUND(SUM(ISNULL(e.Winlost, 0)), 2) - ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2)) - ROUND(SUM(ISNULL(rs.reset, 0)), 2) 
	           END AS latestreset,
			   
			   CASE dm.product
	             WHEN 'Total Balance' THEN ROUND(SUM(ISNULL(bl.balance, 0)), 2) ELSE ROUND(SUM(ISNULL(e.RealWinlost, 0)), 2) END AS RealWinlost,
			   CASE dm.product
	             WHEN 'Total Balance' THEN 0 ELSE ROUND(SUM(ISNULL(e.RealWinlost, 0)), 2) - ROUND(SUM(ISNULL(e.RealExtraPTWinlost, 0)), 2) END AS RealWinlostAfterExtraPT,
	           CASE dm.product
	             WHEN 'Total Balance' THEN 0
	             ELSE ROUND(SUM(ISNULL(rs.RealReset, 0)), 2)
	           END AS Realreset,
			   CASE
	             WHEN dm.Product IN ('Total Balance') THEN 0 
	             ELSE - (ROUND(SUM(ISNULL(e.RealWinlost, 0)), 2) - ROUND(SUM(ISNULL(e.RealExtraPTWinlost, 0)), 2)) - ROUND(SUM(ISNULL(rs.RealReset, 0)), 2) 
	           END AS RealLatestReset
	    FROM @dummyBalance dm
			CROSS JOIN CTE_Date d
			LEFT JOIN #WLByProduct e ON dm.product = e.productName and d.Winlostdate = e.Winlostdate
			LEFT JOIN reset rs ON dm.product = rs.product and d.Winlostdate = rs.Winlostdate
			LEFT JOIN TotalBalance bl ON bl.Product = dm.Product AND bl.winlostdate = d.WinlostDate
		GROUP BY d.Winlostdate, dm.product, dm.seq
		ORDER BY d.Winlostdate DESC, dm.seq ASC
		OPTION (MAXRECURSION 0)

        DECLARE	@variance		money = 0
                ,@Winlostdate	smalldatetime = @FromDate
                ,@custid		int
				,@Product		varchar(250)
                ,@resetCount	tinyint = 0
                ,@transDesc		nvarchar(1000) = ''
				,@seq			int = 1
				,@maxseq		int = 0
                
		SELECT 	@maxseq = MAX(r.seq),
				@resetCount = ISNULL(SUM(CASE WHEN -(ISNULL(r.WinlostAfterExtraPT, 0)) - ISNULL(r.reset, 0) <> 0 AND r.Product NOT IN ('Total Balance') THEN 1 
						                      ELSE 0 END ),0)
        FROM   #reset r
        WHERE  r.WinlostDate = @WinlostDate
				AND r.Product NOT IN ('Total Balance') 

        IF (@resetCount = 0)
        BEGIN
            SELECT @ErrMsg = 'No products need to reset winning!',
                   @ErrCode = 2

            RETURN
        END

		; WITH CTE_Date AS (
		SELECT @fromdate AS WinlostDate
		UNION ALL SELECT DATEADD(DAY, 1, WinlostDate) FROM CTE_Date WHERE WinlostDate < @todate
			)
        SELECT 
				@Winlostdate AS  Winlostdate,
                dm.custid,
				ROUND(r.LatestReset, 2) amount,
				'DWL-' + CAST(dm.Product as varchar(250))
									 + '# ' + CAST(@fromdate as varchar(30))
                                           + CAST(dm.custid as varchar(50)) + ':'
                                           + CAST(ROUND(r.LatestReset, 2) as varchar(100)) transDesc,
				 @creator AS creator,
				 @ip AS ip

        FROM #reset r
			CROSS JOIN CTE_Date d
			INNER JOIN @dummyBalance dm on r.product = dm.product AND r.WinlostDate = d.WinlostDate
        WHERE  ROUND(r.LatestReset, 2) <> 0
		OPTION (MAXRECURSION 0);

		DROP TABLE #reset		
	END

	DROP TABLE #SportBettype
	DROP TABLE #tmpData
	DROP TABLE #tmpMatch
	DROP TABLE #Transfer
	DROP TABLE #WLByProduct
END
GO