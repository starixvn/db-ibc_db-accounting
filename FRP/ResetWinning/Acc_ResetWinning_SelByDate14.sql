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
	
	IF (@SQL not like '%_xtest%')
	BEGIN 
		INSERT INTO @DummyBalance (CustID, Product, seq)
		SELECT CustID, Product, seq
		FROM bodb_ACC.dbo.Acc_DWLList WITH(NOLOCK)
		WHERE Product NOT IN ('Total Balance')
			AND IsDeleted = 0
		
		INSERT INTO @DummyExtraPT (CustID)
		SELECT CustID
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT l WITH (NOLOCK)
		
		/* INSERT INTO @dummyBalance ( seq, CustId, Product)
		VALUES ( 101, 37639217, 'CN88 SPL'),
			(102, 37639217, 'CN88 SPNL'),
			(103, 37639217, 'CN88 Parlay'),
			(104, 37639217, 'CN88 Outright'),
			(105, 37639217, 'CN88 Muay Thai'),
			(110, 37639217, 'CN88 Number Game'),
			(113, 37639217, 'CN88 Virtual Sports'),
			(114, 37639217, 'CN88 Virtual Sports 2'),
			(115, 37639217, 'CN88 RNG Keno'),
			(116, 37639217, 'CN88 Lottery')
			*/
				
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
		Product			VARCHAR (50),
	    winlost         MONEY,
		Bettype			INT
	)

	INSERT INTO #Transfer
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
	   AND b.statusid NOT IN (101, 102, 103, 121)
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
	 
	----- SPL, SPNL, MuayThai, Metric gaming, Bettrade, Palay, outright
	;WITH wl AS(
		SELECT  b.winlostdate,
				CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
					ELSE 0  ---MBC 
				END AS IsCN88,
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
		LEFT JOIN dbo.CS_CustSuper cs WITH (NOLOCK) ON cs.CustId = b.srecommend
		WHERE   b.Winlostdate = @winlostdate 
			AND b.statusid NOT IN (101, 102, 103, 121)			
		GROUP BY b.Winlostdate,
				CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
					ELSE 0  ---MBC 
				END ,
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
				)

	INSERT INTO #WLByProduct (Winlostdate, ProductId, ProductName, IsCN88, Winlost, ExtraPTWinlost) 
	SELECT Winlostdate, ProductId, ProductName, w.IsCN88, SUM(Winlost) as Winlost, SUM(ExtraPTWinlost) as ExtraPTWinlost
	FROM (
			SELECT  w.Winlostdate, w.ProductId, w.ProductName, w.IsCN88, 0 as Winlost, SUM(w.WinlostForExtraPT * ISNULL(s.ExtraPT,0)) as ExtraPTWinlost
			FROM	wl w
			INNER JOIN dbo.Acc_GroupExtraPTSetting s WITH(NOLOCK)
					ON w.srecommend = s.SuperId
					AND w.ProductId = s.ProductId
					AND w.SubProduct = s.SubProduct
					AND w.Sporttype = s.Sporttype 
					AND w.Winlostdate BETWEEN s.FromDate AND s.ToDate	
			GROUP BY w.Winlostdate, w.ProductId, w.ProductName, w.IsCN88 
			UNION ALL 
			SELECT	w.Winlostdate, w.ProductId, w.ProductName, w.IsCN88, 0 as Winlost, SUM(w.CommForExtraPT * ISNULL(s.ExtraCommRate,0)) as ExtraPTComm
			FROM	wl w
			INNER JOIN dbo.Acc_GroupExtraCommRateSetting s WITH(NOLOCK)
					ON w.srecommend = s.SuperId
					AND w.ProductId = s.ProductId
					AND w.SubProduct = s.SubProduct
					AND w.Sporttype = s.Sporttype 
					AND w.Winlostdate BETWEEN s.FromDate AND s.ToDate
			GROUP BY w.Winlostdate, w.ProductId, w.ProductName, w.IsCN88
	
			UNION ALL
			SELECT  w.Winlostdate, w.ProductId, w.ProductName, w.IsCN88, SUM(isnull( w.Winlost,0)) as Winlost , 0 as ExtraPTWinlost 
			FROM	wl w
			GROUP BY w.Winlostdate, w.ProductId, w.ProductName, w.IsCN88 
		) w
	GROUP BY w.Winlostdate, w.ProductId, w.ProductName, w.IsCN88

	UNION ALL
	SELECT w.Winlostdate, '' as ProductId,'Casino (Amount due to Jackpot Pool)' as ProductName, 0 as IsCN88, ISNULL(SUM(w.WinlostDueTo), 0) as Winlost, 0	as ExtraPTWinlost
    FROM wl w
	GROUP BY Winlostdate

	UNION ALL
	SELECT Winlostdate, '' as ProductId, 'Total Balance' as ProductName ,  -1 as IsCN88, SUM(ISNULL(Winlost, 0)+ ISNULL(WinlostDueTo, 0)) as Winlost, 0 as ExtraPTWinlost
    FROM wl w
    WHERE IsCN88 IN (1,0)
	GROUP BY Winlostdate
	
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
END
GO