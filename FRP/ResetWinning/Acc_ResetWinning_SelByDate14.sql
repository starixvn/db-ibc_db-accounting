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
		- 20180830@Sophia: Apply Poker Games Phase 2 - Insurance [RedmineID: #100168]
		- 20181130@Percy: Apply E-Sports & Happy 5 [RedmineID: #105112]
		- 20190412@Percy: Apply BetBuilder & Pragmatic [RedmineID: #106981]
		- 20190516@Percy: Bet Builder - Change Due to Partner's formula [RedmineID: #113550]
		- 20190522@Sophia: Rename Keno to RNG Keno [RedmineID: #113490]
		- 20190701@Percy: Remove WL due to partner [RedmineID: #115802]
		- 20190701@Percy: Apply Card Club [RedmineID: #117005]
		- 20190729@Sophia: Exclude CN88 data [Redmine: #117169]
		- 20190801@Sophia: Integrate CN88 & refactor code[Redmine: #117809]
		- 20190812@Sophia: insert manual dummy data for UAT testing [Redmine: #117809] 
		
	Explanation's Param:

*/
BEGIN	
	SET NOCOUNT ON
	 
	------Get Sport Bettype Matrix------
	-- Check SP Version
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	SELECT ProductID, Bettype, SubProduct FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)
	
	----- End get sport bettype 
	
------------------------------------------
	DECLARE @DummyBalance TABLE (CustId INT, Product VARCHAR(50), seq SMALLINT )
	DECLARE @DummyExtraPT TABLE(CustId INT )
		
    DECLARE @reset TABLE
    (
        winlostdate smalldatetime,
        product     varchar(50),
		winlost		money,
        WinlostAfterExtraPT     money,
        reset       money,
        latestreset money,
        seq         SMALLINT
    )
  
	DECLARE @SQL NVARCHAR(100) = ISNULL(OBJECT_NAME(@@PROCID),'')
	
	DECLARE @Acc_DWLList TABLE ( seq INT, CustId INT, Product  varchar(50))
	INSERT INTO @Acc_DWLList
	VALUES
(0,0,'Total Balance'),
(1,6911909,'SPL'),
(2,6911911,'SPNL'),
(3,6911913,'Parlay'),
(4,6911914,'Outright'),
(8,6911916,'Casino'),
(10,6911918,'Number Game'),
(13,8158305,'Virtual Sports'),
(15,14054918,'RNG Keno'),
(20,18123442,'Metric Gaming - Super Live'),
(19,18123445,'Gold Deluxe'),
(17,18188766,'AG Casino'),
(18,18188815,'Macau'),
(21,18256397,'Microgaming - Live Casino'),
(23,18371760,'Bettrade'),
(24,19236210,'Colossus Bets'),
(22,19692521,'Microgaming - RNG Casino'),
(25,20174356,'Muay Thai'),
(27,20664406,'Allbet'),
(28,21535688,'Macau Games'),
(29,23765766,'NG2'),
(30,24569216,'Fishing World'),
(31,25477229,'Cash Out'),
(16,26513853,'Lottery'),
(14,26513859,'Virtual Sports 2'),
(33,28435541,'Exchange'),
(9,28601563,'Casino (Amount due to Jackpot Pool)'),
(35,29712506,'PP'),
(5,35739415,'Bet Builder'),
(39,37499112,'Card Club'),
(101,37639217,'CN88 SPL'),
(102,37639217,'CN88 SPNL'),
(103,37639217,'CN88 Parlay'),
(104,37639217,'CN88 Outright'),
(105,37639217,'CN88 Muay Thai'),
(110,37639217,'CN88 Number Game'),
(113,37639217,'CN88 Virtual Sports'),
(114,37639217,'CN88 Virtual Sports 2'),
(115,37639217,'CN88 RNG Keno'),
(116,37639217,'CN88 Lottery') 
 
 
 DECLARE @Acc_DWLList_ExtraPT TABLE ( CUSTID INT)

INSERT INTO @Acc_DWLList_ExtraPT 
VALUES
(14424987),
(21080505),
(21080771),
(21080784),
(21080808),
(21080812),
(21080836),
(21080850),
(21080870),
(21080883),
(21080896),
(21080917),
(21080930),
(21080939),
(21080958),
(21080986),
(21080997),
(21081014),
(21081023),
(21289307),
(23385736),
(35476102),
(35854105),
(35854106),
(35854107),
(37049556),
(37049557),
(37049559),
(37049560),
(37049561),
(37049564),
(37049566),
(37049568),
(37049572),
(37049574),
(37049576),
(37049577)
	
	
	IF (@SQL not like '%_xtest%')
	BEGIN 
		/*INSERT INTO @dummyBalance ( seq, CustId, Product)
		SELECT  CASE WHEN L.seq = 0 THEN 999 ELSE l.seq END  AS seq, l.Custid, l.product
		FROM bodb_ACC.dbo.Acc_DWLList l WITH (NOLOCK)
		CROSS JOIN @Date d
		WHERE l.IsDeleted = 0*/
		
		INSERT INTO @dummyBalance ( seq, CustId, Product)
		SELECT CASE WHEN L.seq = 0 THEN 999 ELSE l.seq END  AS seq, l.Custid, l.product
		FROM @Acc_DWLList l  
		 

			
		/*INSERT INTO @dummyExtraPT (CustID)
		SELECT CustID
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT l WITH (NOLOCK)*/

		INSERT INTO @dummyExtraPT (CustID)
		SELECT CustID
		FROM @Acc_DWLList_ExtraPT  
						
	END 
	ELSE
	BEGIN 
		INSERT INTO @DummyBalance (CustID, Product, seq)
		SELECT CustID, Product, seq
		FROM bodb_ACC.dbo.Acc_DWLList_xtest WITH(NOLOCK)
		WHERE Product NOT IN ('Total Balance')
			AND IsDeleted = 0
		
		INSERT INTO @DummyExtraPT (CustID)
		SELECT CustID
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT_xtest l WITH (NOLOCK)
	END 

	
	------------------------------------------------  
	
	CREATE TABLE #Transfer
	(
	    winlostdate     SMALLDATETIME, 
	    custid          INT,
		Product			NVARCHAR (250),
	    winlost         MONEY,
		Bettype			INT
	)

	
	INSERT INTO #Transfer (winlostdate, custid, Product, winlost, Bettype)
	SELECT	b.winlostdate,
			CASE
	         WHEN b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 then d.custid
	         ELSE -1
	        END AS custid,
			SUBSTRING (b.transdesc, 5, CASE WHEN CHARINDEX ('#', b.Transdesc, 4) <>  0 THEN CHARINDEX ('#', b.Transdesc, 4) -5 ELSE 0 END ) AS Product,
			SUM((ISNULL(winlost, 0) - ISNULL(actual_stake, 0)) * b.actualrate) AS winlost ,
			CASE WHEN b.Bettype = 20000 THEN b.Bettype ELSE 0 END
	FROM dbo.bettrans b WITH(NOLOCK)
	LEFT JOIN (SELECT DISTINCT CustId FROM @dummyBalance) d 
		ON b.custid = d.custid 
	WHERE b.winlostdate = @winlostdate
	   AND b.ruben = 1
	   AND b.bettype > 19000 
	   AND b.matchID = 0
	   AND (CASE WHEN b.CustId IN (SELECT CustId FROM @dummyExtraPT) AND Bettype IN (21001,21002) THEN 0 ELSE 1 END = 1)   --- Not Get ticket transfer of reset winning extraPT
    GROUP BY b.winlostdate,
			SUBSTRING (b.transdesc, 5, CASE WHEN CHARINDEX ('#', b.Transdesc, 4) <>  0 THEN CHARINDEX ('#', b.Transdesc, 4) -5 ELSE 0 END ),
			CASE
	         WHEN b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 then d.custid
	         ELSE -1
	        END ,
			CASE WHEN b.Bettype = 20000 THEN  b.Bettype ELSE 0 END 

	UPDATE t 
	SET t.Product = d.Product
	FROM #Transfer t
		LEFT JOIN @dummyBalance d ON t.custid = d.custid 
	WHERE t.Product = ''
   
	---------------------------------------------------------------------------------------------------------
	--------------------------------------------Extra PT ---------------------------------------------------

	CREATE TABLE #WLByProduct
	(
	    winlostdate			smalldatetime, 
		ProductId			INT,
		ProductName			VARCHAR(50),
		SubProduct			VARCHAR(50),
		IsCN88				BIT,
		winlost				MONEY, 		
		ExtraPTWinlost	MONEY
	) 
	
		
	CREATE TABLE #wl 
	(	winlostdate 	SMALLDATETIME, 
		srecommend 		INT, 
		Sporttype  		SMALLINT, 
		ProductId		INT, 
		ProductName		VARCHAR(250), 
		SubProduct		VARCHAR(250), 
		winlost			MONEY, 
		WinlostDueTo	MONEY, 
		CommForExtraPT	MONEY,
		WinlostForExtraPT MONEY
	)
		 
		INSERT INTO #wl (winlostdate, srecommend, Sporttype, ProductId, ProductName, SubProduct, winlost, WinlostDueTo, CommForExtraPT, WinlostForExtraPT)
		SELECT  b.winlostdate,
				b.srecommend,	      
				CASE WHEN ISNULL(m.Sporttype, 0) <> 0 THEN m.Sporttype ELSE 0 END AS Sporttype,
				s.ProductId,
				CASE WHEN s.SubProduct = 'MG-SuperLive' THEN 'Metric Gaming - Super Live'
					WHEN s.SubProduct IN ('BT-Sold','BT-Bought','BT-Comm','BT-Winloss') THEN 'Bettrade'
					WHEN s.SubProduct = 'Bet Builder' THEN 'Bet Builder'
					WHEN ISNULL(m.Sporttype, 0) = 44 THEN 'Muay Thai'
					WHEN b.bettype = 10 THEN 'Outright'
					WHEN b.bettype IN (9,29) THEN'Parlay' 
					WHEN b.liveindicator = 1 AND s.ProductID = 1 THEN 'SPL' 
					WHEN b.liveindicator = 0 AND s.ProductID = 1 THEN 'SPNL'  	
					ELSE ''
					END	AS ProductName,
				CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm','BT-Winloss','Bet Builder') THEN s.SubProduct ELSE '' END AS SubProduct,
				
				SUM(
				CASE WHEN b.bettype IN (2199, 2399, 2999) THEN 0
					ELSE
					(ISNULL(winlost,0)-ISNULL(actual_stake,0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)
						+ CASE
							-- Jackpot
							WHEN b.bettype IN (2198, 2398, 2998) THEN ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000),0)
							ELSE 0 END
					) * actualrate  END
				) AS winlost,
				SUM(
					(CASE
							-- Jackpot
							WHEN b.bettype IN (2198, 2398, 2998) THEN -ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0)
							WHEN b.bettype IN (2199, 2399, 2999) THEN ISNULL(b.Winlost, 0) - ISNULL(b.actual_stake, 0)
						ELSE 0 END
					) * b.actualrate
				) AS WinlostDueTo,
				0 AS CommForExtraPT,
				SUM((CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.Winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END) * b.actualrate) AS WinlostForExtraPT 
		FROM dbo.bettrans14 b WITH(NOLOCK)			
		INNER JOIN @SportBettype s ON s.BetType = b.bettype
		LEFT JOIN dbo.Match14 m WITH (NOLOCK) ON m.MatchId = b.MatchId AND m.eventdate = b.Winlostdate AND m.Sporttype = 44	
		WHERE   b.Winlostdate = @winlostdate 
			AND b.statusid NOT IN (101, 102, 103, 121)			
		GROUP BY b.Winlostdate,				
				b.srecommend,	      
				CASE WHEN ISNULL(m.Sporttype, 0) <> 0 THEN m.Sporttype ELSE 0 END,
				s.ProductId,
				CASE WHEN s.SubProduct = 'MG-SuperLive' THEN 'Metric Gaming - Super Live'
					WHEN s.SubProduct IN ('BT-Sold','BT-Bought','BT-Comm','BT-Winloss') THEN 'Bettrade'
					WHEN s.SubProduct = 'Bet Builder' THEN 'Bet Builder'
					WHEN ISNULL(m.Sporttype, 0) = 44 THEN 'Muay Thai'
					WHEN b.bettype = 10 THEN 'Outright'
					WHEN b.bettype IN (9,29) THEN'Parlay' 
					WHEN b.liveindicator = 1 AND s.ProductID = 1 THEN 'SPL' 
					WHEN b.liveindicator = 0 AND s.ProductID = 1 THEN 'SPNL'  	
					ELSE ''
					END	,
				CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm','BT-Winloss','Bet Builder') THEN s.SubProduct ELSE '' END
				

	INSERT INTO #WLByProduct (Winlostdate, ProductId, ProductName, IsCN88, Winlost, ExtraPTWinlost) 
	SELECT Winlostdate, ProductId, ProductName, w.IsCN88, SUM(Winlost), SUM(ExtraPTWinlost)
	FROM (
			--- WL by product		
			SELECT  w.Winlostdate, w.ProductId, w.ProductName, 
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
						ELSE 0  ---MBC 
					END IsCN88, 
					SUM(ISNULL( w.Winlost,0)) as Winlost , 0 as ExtraPTWinlost 
			FROM	#wl w
			LEFT JOIN CS_CustSuper cs WITH (NOLOCK) 
				ON cs.CustId = w.srecommend
			GROUP BY w.Winlostdate, w.ProductId, w.ProductName,
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
						ELSE 0  ---MBC 
					END 
					
			---ExtraPT
			UNION ALL
			SELECT  w.Winlostdate, w.ProductId, w.ProductName, 
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
						ELSE 0  ---MBC 
					END AS IsCN88, 
				   0 as Winlost, SUM(w.WinlostForExtraPT * ISNULL(s.ExtraPT,0)) as ExtraPTWinlost
			FROM	#wl w
			INNER JOIN dbo.Acc_GroupExtraPTSetting s WITH(NOLOCK)
					ON w.srecommend = s.SuperId
					AND w.ProductId = s.ProductId
					AND w.SubProduct = s.SubProduct
					AND w.Sporttype = s.Sporttype 
					AND w.Winlostdate BETWEEN s.FromDate AND s.ToDate	
			LEFT JOIN CS_CustSuper cs WITH (NOLOCK) 
					ON cs.CustId = w.srecommend
			GROUP BY w.Winlostdate, w.ProductId, w.ProductName, 
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
						ELSE 0  ---MBC 
					END
					
			---Extra Comm
			UNION ALL 
			SELECT	w.Winlostdate, w.ProductId, w.ProductName, 
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
						ELSE 0  ---MBC 
					END AS IsCN88,
					0 as Winlost, SUM(w.CommForExtraPT * ISNULL(s.ExtraCommRate,0)) as ExtraPTComm
			FROM	#wl w
			INNER JOIN dbo.Acc_GroupExtraCommRateSetting s WITH (NOLOCK)
					ON w.srecommend = s.SuperId
					AND w.ProductId = s.ProductId
					AND w.SubProduct = s.SubProduct
					AND w.Sporttype = s.Sporttype 
					AND w.Winlostdate BETWEEN s.FromDate AND s.ToDate
			LEFT JOIN CS_CustSuper cs WITH (NOLOCK) 
					ON cs.CustId = w.srecommend
			GROUP BY w.Winlostdate, w.ProductId, w.ProductName,
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
						ELSE 0  ---MBC 
					END		
		) w
	GROUP BY w.Winlostdate, w.ProductId, w.ProductName, w.IsCN88

	UNION ALL
	SELECT w.Winlostdate, '','Casino (Amount due to Jackpot Pool)', 0, SUM(ISNULL(w.WinlostDueTo, 0)) AS Winlost, 0	
    FROM #wl w
	WHERE w.WinlostDueTo <> 0 
	GROUP BY Winlostdate

	
	----- Update ProductName
	UPDATE e 
	SET ProductName = CASE WHEN e.IsCN88 = 1 THEN 'CN88 ' ELSE '' END + CASE WHEN e.ProductId = 6 THEN 'Casino' ELSE CASE WHEN e.ProductID <> 1 THEN p.ProductName ELSE e.ProductName END END 
	FROM #WLByProduct e
	INNER JOIN dbo.Products p WITH (NOLOCK)
		ON e.ProductId = p.ProductId
	 
	---------------------------------------------------------------------------------------------------------
	SELECT @totalBalance = SUM (Winlost)
	FROM #WLByProduct
	WHERE ProductName = 'Total Balance'

	    ----- calculate reset
	    ;WITH reset AS
	    (
		     SELECT b.Product,
		           ISNULL(SUM(b.Winlost), 0) AS reset
		     FROM #Transfer b
			 WHERE b.bettype <> 20000	     
			 GROUP BY b.product
	    )
		,OpenningBalance AS
		(
			SELECT 'Openning Balance' as product, SUM(ISNULL(winlost, 0)) AS winlost
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
		  
		DROP TABLE #Transfer
		DROP TABLE #WLByProduct   
		DROP TABLE #WL
END
GO