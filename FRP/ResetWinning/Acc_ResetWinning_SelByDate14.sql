/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_ResetWinning_SelByDate14]
	@Winlostdate	SMALLDATETIME,	
	@TotalBalance	MONEY = 0 OUTPUT, 
	@Mode			BIT = 0,
	@Creator		INT = 10278938,   --- starixIT
	@RequestID		VARCHAR(4000) = '',
	@ErrCode		INT = 0 OUTPUT,
    @ErrMsg			VARCHAR(100) = '' OUTPUT
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
		- 20180830@Sophia: Apply Poker Games Phase 2 - Insurance [RedmineID: #100168]
		- 20181130@Percy: Apply E-Sports & Happy 5 [RedmineID: #105112]
		- 20190412@Percy: Apply BetBuilder & Pragmatic [RedmineID: #106981]
		- 20190516@Percy: Bet Builder - Change Due to Partner's formula [RedmineID: #113550]
		- 20190522@Sophia: Rename Keno to RNG Keno [RedmineID: #113490]
		- 20190701@Percy: Remove WL due to partner [RedmineID: #115802]
		- 20190701@Percy: Apply Card Club [RedmineID: #117005]
		- 20190729@Sophia: Exclude CN88 data [Redmine: #117169]
		- 20190801@Sophia: Integrate CN88 & refactor code[Redmine: #117809] 
		- 20190829@Sophia: Tuning Code [redmine: #119435]
		- 20190903@Sophia: fix bug [remine: #119553]
		- 20190826@Sophia: exclude CN88 Headline balance out of total balance [Redmine: #117863]
		- 20190909@Sophia: reset winning on bettrans14 - recover ticket 7 days [redmine: #115377]
		- 20191210@Percy: Set actualrate = 1 of UUS currency (exchangeid = 20) for testing (version xtest) [RedmineID: #124484]
		- 20191216@Percy: Using new column bettrans.epositiontaking instead of Acc_GroupExtraPTSetting.ExtraPT [RedmineID: #125418]
		- 2020714@Sophia: Add PP Jackpot & revise SP [Redmine: #137270]
		- 20201012@Malcolm :  Change email Starixsoft.com to starixvn.com [RedmineId : #143312]
		- 20210203@Malcolm : Add Saba.club (Amount due to Jackpot Pool) into Reset winning [RedmineId : #149409]
		- 20210426@Sol: Alpha/NAP - Migrate from DBACC to DBCust - [Redmine: #154041]
		- 20210512@Malcolm : Add VGaming (Amount due to Jackpot Pool) into Reset winning [RedmineId : #154643]
		- 20210907@Evan: Exclude CN88 data, Tuning Code - [Redmine: #161262]
		- 20220112@Evan: Add SG Jackpot & revise SP [Redmine: #166685]
		- 20211122@Danny: Split transfer tickets out of bettrans [Redmine: #164196]
		- 20220425@Evan: Change product name and remove Casino Jackpot Amount [Redmine: #171865]
		- 20221005@Danny: Remove not valid user in automail for reset winning's change [Redmine: #178761]
		- 20230522@Lewis: Call sum Sps on other servers - [RedmineID: #188463]
		- 20230227@Evan: Balance-Up support transfer 247 [Redmine: #173554]
		- 20221024@Sol: Database - Sync-up Standby Server data - [RedmineID: #167261]
		
	Explanation's Param:
	    @mode:  0 _ view report
	            1 _ reset balance
	            
	    @ErrCode: 0 _ Success
	              1 _ Error

*/
BEGIN	
	SET NOCOUNT ON
	 
	------Get Sport Bettype Matrix------
	-- Check SP Version
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	CREATE TABLE #SportBettype (Bettype INT, ProductID INT, SubProduct VARCHAR(500), PRIMARY KEY (Bettype, ProductID, SubProduct))  
	INSERT INTO #SportBettype (Bettype, ProductID, SubProduct)  
	SELECT DISTINCT Bettype, ProductID, SubProduct FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest) 
	----- End get sport bettype 


	DECLARE @balanceUpDay SMALLDATETIME, @moveBetsDay SMALLDATETIME
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @balanceUpDay = BalanceUpDay, @moveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp
	
------------------------------------------
	DECLARE @dummyBalance TABLE (CustId INT, Product VARCHAR(250), seq INT, IsExtraPT BIT)  
	
    DECLARE @reset TABLE
    (
        winlostdate smalldatetime,
        product     VARCHAR(250),
		winlost		money,
        WinlostAfterExtraPT     money,
        reset       money,
        latestreset money,
        seq         SMALLINT
    )
  
	DECLARE @SQL NVARCHAR(100) = ISNULL(OBJECT_NAME(@@PROCID),'')
	SELECT @Istest = CASE WHEN @SQL like '%_xtest%' THEN 1 ELSE 0 END
	
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
		Product			NVARCHAR (250),
		bettype			INT,
	    winlost         MONEY,
		Realwinlost		MONEY
	)
	
	INSERT INTO #Transfer (winlostdate, custid, bettype, Product, winlost, Realwinlost)
	SELECT	b.winlostdate, 
			CASE WHEN b.bettype IN (21001, 21002) THEN custid ELSE -1 END as custid,			
			CASE WHEN b.bettype = 20000 then b.bettype ELSE 0 END as bettype, 			
			''  AS Product,
			SUM((ISNULL(winlost, 0) - ISNULL(actual_stake, 0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)) * b.actualrate) AS Winlost,
			SUM(ISNULL(winlost, 0) - ISNULL(actual_stake, 0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)) AS RealWinlost 
	FROM dbo.transfer b WITH (NOLOCK)
	WHERE b.winlostdate = @winlostdate
	   AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
                        WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
                        WHEN winlostdate < @balanceUpDay THEN 0 --> old data
                    ELSE 1 END
	   AND b.bettype <> 21007 ---- exclude CN88 headline balance
    GROUP BY b.winlostdate, 
			CASE WHEN b.bettype IN (21001, 21002) THEN custid ELSE -1 END  ,			
			CASE WHEN b.bettype = 20000 then b.bettype ELSE 0 END

	DELETE t FROM #Transfer t WHERE t.CustId IN (SELECT d.CustId FROM @dummyBalance d WHERE d.IsExtraPT = 1)  
	DELETE @dummyBalance WHERE IsExtraPT = 1	

	;WITH CTE_Transfer AS (  
		SELECT t.winlostdate, ISNULL(d.CustId, -1) AS CustId, bettype, ISNULL(d.Product, '') AS Product  
		,SUM(t.Winlost) AS Winlost, SUM(t.RealWinlost) AS RealWinlost  
		FROM #Transfer t  
		LEFT JOIN @dummyBalance d ON t.CustId = d.CustId  
		GROUP BY t.winlostdate, bettype, ISNULL(d.CustId, -1), ISNULL(d.Product, '')  
	)  
	MERGE #Transfer AS t  
	USING CTE_Transfer AS s ON t.winlostdate = s.winlostdate AND t.CustId = s.CustId  AND t.bettype = s.bettype
	WHEN MATCHED THEN UPDATE  
	SET t.Product = s.Product, t.Winlost = s.Winlost, t.RealWinlost = s.RealWinlost  
	WHEN NOT MATCHED BY SOURCE THEN DELETE;
	
	--------------------------------------------------------------------------------------------------------- 

	 /* Get bet tickets*/  
	CREATE TABLE #tmpData 
		(  
		  winlostdate  smalldatetime  
		  ,MatchId  int  
		  ,bettype  smallint  
		  ,liveindicator bit   
		  ,winlost    money  
		  ,eWinlost    money  
		  ,WinlostDueToPP   money default (0)  
		  ,WinlostDueToSaba  money default (0)  
		  ,WinlostDueToVgaming money default (0)  
		  ,WinlostDueToSG money default (0)  
		  ,RealWinlost    money  
		  ,eRealWinlost    money  
		  ,RealWinlostDueToPP   money default (0)  
		  ,RealWinlostDueToSaba  money default (0)  
		  ,RealWinlostDueToVgaming money default (0)  
		  ,RealWinlostDueToSG money default (0)  
		  PRIMARY KEY (winlostdate, bettype, MatchId, liveindicator)  
		)  

	;WITH CTE_tmpData AS (
		SELECT winlostdate, bettype, MatchId, liveindicator,winlost, actual_stake ,awinlost, mwinlost, swinlost, scomm, betid, actualrate, epositiontaking,tpositiontaking
	FROM dbo.bettrans14 b WITH (NOLOCK)
	WHERE   winlostdate = @Winlostdate
			AND b.statusID IN (111, 112, 113)
	) 
	INSERT INTO #tmpData (winlostdate, bettype, MatchId, liveindicator
		,winlost, eWinlost, WinlostDueToPP, WinlostDueToSaba, WinlostDueToVgaming,WinlostDueToSG
		,RealWinlost, eRealWinlost, RealWinlostDueToPP, RealWinlostDueToSaba, RealWinlostDueToVgaming,RealWinlostDueToSG)
	---------Jackpot Contribution Tickets ------------
	 SELECT winlostdate, bettype, 0 AS MatchId, 0 AS liveindicator,
		-- Base Currency
		SUM(CASE
				-- Jackpot Prize
				WHEN bettype IN (1699, 3899, 4298, 4600) THEN 0
				-- Jackpot full Contribution
				WHEN bettype IN (1698,  3898, 4297, 4599) 
				THEN winlost - actual_stake + awinlost + mwinlost + swinlost + scomm + ISNULL(betid/CONVERT(DECIMAL(19,8), 100000000), 0)
				ELSE 0 END 
				* CASE WHEN @Istest = 1 THEN 1 ELSE actualrate END) AS winlost,
		SUM(CASE
				-- Jackpot Prize
				WHEN bettype IN (1699, 3899, 4298, 4600) THEN 0
				-- Jackpot full Contribution
				WHEN bettype IN (1698,  3898, 4297, 4599) THEN ISNULL(betid/CONVERT(DECIMAL(19,8), 100000000), 0)
				ELSE 0 END 
				* CASE WHEN @Istest = 1 THEN 1 ELSE actualrate END * ISNULL(epositiontaking, 0)) AS eWinlost,
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
	
	-----------Normal bet Tickets------------
	UNION ALL
	SELECT winlostdate, bettype, MatchId, liveindicator,
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
	GROUP BY winlostdate, bettype, MatchId, liveindicator
	 
	DECLARE @wlDate DATETIME = @winlostdate;
	
	CREATE TABLE #tmpMatch (matchid INT PRIMARY KEY, sporttype INT) -- current use for MuayThai
	INSERT INTO #tmpMatch (matchid, sporttype)
	SELECT matchid, sporttype
	FROM dbo.match14 WITH (NOLOCK)
	WHERE eventdate = @wlDate -- datetime type
		AND sporttype = 44 -- MuayThai

	/* Sum WL by Product */  
	CREATE TABLE #WLByProduct
		(
			winlostdate			smalldatetime, 		
			ProductId			INT,		
			ProductName			VARCHAR(250),
			SubProduct			VARCHAR(250),
			Winlost				MONEY, 		
			ExtraPTWinlost		MONEY,
			RealWinlost			MONEY, 		
			RealExtraPTWinlost	MONEY		
		) 
	 
	;WITH CTE_tmpWL AS (  
	SELECT	b.winlostdate, s.ProductId  
			,CASE  
				WHEN s.SubProduct = 'MG-SuperLive' THEN 'Metric Gaming - Super Live'  
				WHEN s.SubProduct IN ('BT-Sold','BT-Bought','BT-Comm','BT-Winloss') THEN 'Bettrade'  
				WHEN s.SubProduct = 'Bet Builder' THEN 'Bet Builder'  
				WHEN ISNULL(m.Sporttype, 0) = 44 THEN 'Muay Thai'  
				WHEN b.bettype = 10 THEN 'Outright'  
				WHEN b.bettype IN (9,29) THEN'Parlay'   
				WHEN b.liveindicator = 1 AND s.ProductID = 1 THEN 'SPL'   
				WHEN b.liveindicator = 0 AND s.ProductID = 1 THEN 'SPNL'     
				ELSE '' END AS ProductName  
			,CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm','BT-Winloss','Bet Builder') THEN s.SubProduct ELSE '' END AS SubProduct  
			,SUM(b.Winlost)  AS Winlost
			,SUM(b.eWinlost) AS eWinlost
			,SUM(b.WinlostDueToPP)  AS WinlostDueToPP
			,SUM(b.WinlostDueToSaba) AS WinlostDueToSaba
			,SUM(b.WinlostDueToVgaming) AS WinlostDueToVgaming
			,SUM(b.WinlostDueToSG) AS WinlostDueToSG
			,SUM(b.RealWinlost)  AS RealWinlost
			,SUM(b.eRealWinlost) AS eRealWinlost
			,SUM(b.RealWinlostDueToPP)  AS RealWinlostDueToPP
			,SUM(b.RealWinlostDueToSaba) AS RealWinlostDueToSaba
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
	
	----- Update ProductName
	UPDATE e 
	SET ProductName = p.ProductName 
	FROM #WLByProduct e
		INNER JOIN dbo.Products p WITH (NOLOCK) ON e.ProductId = p.ProductId
	WHERE e.ProductId NOT IN (0, 1)
	 
	---------------------------------------------------------------------------------------------------------
	
	--- output total balance
	
		SELECT @totalBalance = SUM(ISNULL(b.Winlost, 0))
		FROM #Transfer b	     
		WHERE CustID = -1	
			  AND b.bettype <> 20000
     ---------------------------------------------------------------------------

		IF @Mode = 0 --- view only
		BEGIN 
			----- calculate reset
			;WITH reset AS
			(
				 SELECT b.Product,
					   ----ISNULL(SUM(b.Winlost), 0) AS reset,
					   SUM(CASE WHEN @Istest = 1 THEN ISNULL(b.RealWinlost, 0) ELSE ISNULL(b.Winlost, 0) END ) AS reset,
					   ISNULL(SUM(b.RealWinlost), 0) AS RealRreset
				 FROM #Transfer b
				 WHERE b.bettype <> 20000	     
				 GROUP BY b.product
			)
			,OpenningBalance AS
			(
				SELECT 'Openning Balance' as product, 
						SUM(ISNULL(winlost, 0)) AS winlost
				FROM #Transfer b
				WHERE b.bettype = 20000
				HAVING SUM(ISNULL(winlost, 0)) <> 0
			)
			SELECT product, winlost AS Winlost , 0 AS WinlostAfterExtraPT, 0 as reset, 0 as seq
			FROM OpenningBalance
			UNION ALL
			SELECT dm.product,
				   ROUND(ISNULL(e.Winlost, 0), 2) AS Winlost, 
				   ROUND(ISNULL(e.Winlost, 0), 2) - ROUND(ISNULL(e.ExtraPTWinlost, 0), 2) AS WinlostAfterExtraPT,
				   ROUND(ISNULL(rs.reset, 0), 2) AS reset, 
				   dm.seq
			FROM @dummyBalance dm
				LEFT JOIN #WLByProduct e ON dm.product = e.productName  
				LEFT JOIN reset rs ON dm.product = rs.product  
			WHERE dm.Product <> 'Total Balance'
			ORDER BY seq ASC

		END 
		ELSE  --- adjust reset 
		BEGIN 

			CREATE TABLE #reset
			(	seq         		INT IDENTITY (1,1),			
				product     		VARCHAR(250),
				winlost				MONEY,
				WinlostAfterExtraPT MONEY,
				reset       		MONEY,
				latestreset 		MONEY,
				Realwinlost				MONEY,
				RealWinlostAfterExtraPT MONEY,
				Realreset       		MONEY,
				Reallatestreset 		MONEY 			
			)

			;WITH reset AS
			(
				 SELECT b.Product,
					   SUM(CASE WHEN @Istest = 1 THEN ISNULL(b.RealWinlost, 0) ELSE ISNULL(b.Winlost, 0) END ) AS reset,
					   ISNULL(SUM(b.RealWinlost), 0) AS RealReset
				 FROM #Transfer b
				 WHERE b.bettype <> 20000	     
				 GROUP BY b.product
			) 		
			INSERT INTO #reset( product,  Winlost, WinlostAfterExtraPT, reset, LatestReset, RealWinlost, RealWinlostAfterExtraPT, RealReset, RealLatestReset)	
			SELECT dm.product,
				   ROUND(SUM(ISNULL(e.Winlost, 0)), 2) AS Winlost, 
				   ROUND(SUM(ISNULL(e.Winlost, 0)), 2) - ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2)  AS WinlostAfterExtraPT,
				   ROUND(SUM(ISNULL(rs.reset, 0)), 2) AS reset, 
				   - (ROUND(SUM(ISNULL(e.Winlost, 0)), 2) - ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2)) - ROUND(SUM(ISNULL(rs.reset, 0)), 2) AS LatestReset,

				   ROUND(SUM(ISNULL(e.RealWinlost, 0)), 2) AS RealWinlost, 
				   ROUND(SUM(ISNULL(e.RealWinlost, 0)), 2) - ROUND(SUM(ISNULL(e.RealExtraPTWinlost, 0)), 2)  AS RealWinlostAfterExtraPT,
				   ROUND(SUM(ISNULL(rs.RealReset, 0)), 2) AS RealReset, 
				   - (ROUND(SUM(ISNULL(e.RealWinlost, 0)), 2) - ROUND(SUM(ISNULL(e.RealExtraPTWinlost, 0)), 2)) - ROUND(SUM(ISNULL(rs.RealReset, 0)), 2) AS RealLatestReset
			FROM @dummyBalance dm
				LEFT JOIN #WLByProduct e ON dm.product = e.productName  
				LEFT JOIN reset rs ON dm.product = rs.product 
			WHERE dm.Product <> 'Total Balance'
			GROUP BY dm.product, dm.seq
			 
			DECLARE @variance     money = 0, 
					@custid       int,
					@Product	  varchar(250),
					@resetCount   tinyint = 0,
					@transDesc    nvarchar(1000)= '',
					@seq		  smallint = 0,
					@maxseq		  smallint = 0,
					@ip			  VARCHAR(45) = '',
					@LogData	  NVARCHAR(200) = '',
					---
					@alias VARCHAR(100), 
					@sqlCommand VARCHAR(MAX),
					@doNotRunInServer VARCHAR(1000),
					@remark VARCHAR(4000)
                
			SELECT @seq = 1 

			SELECT @maxseq = MAX(r.seq),              
				   @resetCount =  ISNULL(SUM( CASE WHEN LatestReset <> 0 THEN 1 ELSE 0 END),0)
			FROM   #reset r	


			IF (@resetCount = 0)
			BEGIN
				SELECT @ErrMsg = 'No products need to reset winning!',
					   @ErrCode = 2

				RETURN
			END

			---get server name that dont need to run
			EXEC DBTXN.bodb02.dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
			SELECT @alias = 'DBACC', @remark = CASE WHEN ISNULL(@RequestID,'') = '' THEN '' ELSE 'step 5.1' END

			WHILE (@seq <= @maxseq)
			BEGIN
				SET @variance = 0
				SET @sqlCommand = ''

				SELECT @variance = ROUND(r.LatestReset, 2) ,
					   @custid = d.custid,
					   @Product = d.Product
				FROM #reset r
					INNER JOIN @dummyBalance d on r.product = d.product 
				WHERE r.seq = @seq


				IF (@variance <> 0) 
				BEGIN
					SELECT @transDesc = 'DWL-' + CAST(@Product as varchar(250))
										 + '# ' + CAST(@Winlostdate as varchar(30))
											   + CAST(@custid as varchar(50)) + ':'
											   + CAST(@variance as varchar(100))
					
					--- Add ticket reset winning
					EXEC DBTXN.bodb02.dbo.Task_ResetWinning_Non3rdParty_Add
						@Winlostdate = @Winlostdate,
						@custid = @custid,
						@amount = @variance,
						@transdesc = @transDesc,
						@creator = @creator,
						@ip = @ip,
						@ErrCode = @ErrCode OUTPUT,
						@ErrMsg = @ErrMsg OUTPUT
						
					IF (@ErrCode <> 0) BREAK
					
					----Adjust statement
					--EXEC bodb_report.dbo.[Acc_StatementUpdateTransfer]
					--	@custid = @custid
					--	,@Amount = @variance
					--	,@winlostdate = @winlostdate
					--	,@ErrCode = @ErrCode OUTPUT
					--	,@ErrMsg = @ErrMsg OUTPUT							

					--IF (@ErrCode <> 0) BREAK

					----Adjust statement
					SELECT @SqlCommand = CONCAT('EXEC bodb_report.dbo.[Acc_StatementUpdateTransfer] ', ' @custid = ',@custid,' ,@Amount = ',@variance,' ,@winlostdate = ''',@winlostdate, '''')

					EXEC DBTXN.bodb02.dbo.Task_ExecRep_Wrapper 
						@RequestID = @RequestID, 
						@ServerName = '', 
						@AliasName = @alias, 
						@SqlCommand = @SqlCommand, 
						@doNotRunInServer = @doNotRunInServer,
						@Remark = @remark
					
                    --- write log 
					BEGIN TRY
						EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Transfer
							@UserID = @creator,
							@FromCustID = 0,
							@ToCustID = @custid,
							@ip = @ip,
							@Doing = @transDesc
					END TRY	
					BEGIN CATCH						
						SELECT @LogData = @LogData + ' ErrMsg=' + error_message()
						EXEC DBTXN.bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
							@UserID = @creator, 
							@FromCustID = 0, 
							@ToCustID = @CustID, 
							@IP = @IP, 
							@Doing = @LogData						
					END CATCH
					
				END

				SET @seq = @seq + 1

				SELECT @ErrMsg = 'The process has been successful!'
			END
			
			--------Email 
			IF @resetCount > 0
			BEGIN
				DECLARE @Subject VARCHAR(1000) = '', @body VARCHAR(MAX) = '', 
						@ProductList VARCHAR(1000)  , @ProductVariance VARCHAR(1000),
						@recipients VARCHAR(MAX), @copy_recipients VARCHAR(MAX), @blind_copy_recipients VARCHAR(MAX)
						
				SELECT @ProductList = COALESCE(@ProductList + ', ', '') + Product,
					   @ProductVariance = COALESCE(@ProductVariance + ', ', '') + Product +' : '
										+  CONVERT(VARCHAR(100),	ISNULL( (-(ISNULL(r.WinlostAfterExtraPT, 0)) - ISNULL(r.reset, 0)),0) )
										+ ' RM'
				FROM  #Reset r
				WHERE ISNULL( (-(ISNULL(r.WinlostAfterExtraPT, 0)) - ISNULL(r.reset, 0)),0) <> 0
				 
											 
				
				SELECT @Subject = 'Reset Winning report changed on ' + CONVERT(VARCHAR(20),@Winlostdate, 107)
					
				SELECT @body = 'Dear Ah Wan, </br> 
								Kindly be informed that the Reset Winning report has been changed on '+ CONVERT(VARCHAR(20),@Winlostdate, 107) + '</br>
								Time of Reset Winning: '+ CONVERT(VARCHAR(20),Getdate(),109) +' (GMT-4) </br></br> 

								Product: '+ @ProductList + ' </br> </br> 

								Reason: void/recovered tickets </br> 
								Variance: '+ @ProductVariance + '</br> 
								Performed by IT. </br></br>  

								Best regards, </br> 
								This is an auto-mail from ONEworks Report System. Please do not reply.'									 
										
				IF @Istest = 0 AND @@SERVERNAME = 'DB061'
					SELECT	@recipients = 'kudanaga@enpine.com'
							,@copy_recipients = 'jetyee88@enpine.com;kwongyong@enpine.com;seanlau@enpine.com;foo.mv@enpine.com;tp@enpine.com;it@starixvn.com;jackyting@enpine.com;vh@enpine.com'
							,@blind_copy_recipients = 'automail@enpine.com'
				ELSE
					SELECT  @recipients = 'dba_local@starixvn.com'
							,@copy_recipients = ''
							,@blind_copy_recipients = ''
					
				EXEC msdb.dbo.sp_send_dbmail
					@recipients = @recipients
					, @copy_recipients = @copy_recipients
					, @blind_copy_recipients = @blind_copy_recipients
					, @subject = @subject
					, @body = @body
					, @body_format = 'HTML' 
			END
			
			DROP TABLE #reset	

		END 
		DROP TABLE #SportBettype
		DROP TABLE #Transfer
		DROP TABLE #WLByProduct   
		DROP TABLE #tmpData
		DROP TABLE #tmpMatch
END
GO 