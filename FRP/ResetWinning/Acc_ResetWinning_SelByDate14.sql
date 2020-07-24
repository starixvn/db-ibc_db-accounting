/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_ResetWinning_SelByDate14]
	@Winlostdate	SMALLDATETIME,	
	@TotalBalance	MONEY = 0 OUTPUT, 
	@Mode			BIT = 0,
	@Creator		INT = 10278938,   --- starixIT
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
	
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	SELECT ProductID, Bettype, SubProduct FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)
	
	----- End get sport bettype 
	
------------------------------------------
	DECLARE @DummyBalance TABLE (CustId INT, Product VARCHAR(250), seq SMALLINT, Currency INT )
	DECLARE @DummyExtraPT TABLE(CustId INT )
		
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
		INSERT INTO @dummyBalance ( seq, CustId, Product, currency)
		SELECT  CASE WHEN L.seq = 0 THEN 999 ELSE l.seq END  AS seq, l.Custid, l.product,
				CASE WHEN l.Product LIKE 'CN88%' THEN ISNULL(c.Currency,0) ELSE 0 END AS Currency
		FROM bodb_ACC.dbo.Acc_DWLList l WITH (NOLOCK)
		LEFT JOIN dbo.CustInfo c WITH (NOLOCK) ON c.CustID = l.CustID		
		WHERE l.IsDeleted = 0	
	
			
		INSERT INTO @dummyExtraPT (CustID)
		SELECT CustID
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT l WITH (NOLOCK)
						
	END 
	ELSE
	BEGIN 
		INSERT INTO @dummyBalance ( seq, CustId, Product, currency)
		SELECT  CASE WHEN L.seq = 0 THEN 999 ELSE l.seq END  AS seq, l.Custid, l.product,
				CASE WHEN l.Product LIKE 'CN88%' THEN ISNULL(c.Currency,0) ELSE 0 END AS Currency
		FROM bodb_ACC.dbo.Acc_DWLList_xtest l WITH (NOLOCK)
		LEFT JOIN dbo.CustInfo c WITH (NOLOCK) ON c.CustID = l.CustID		
		WHERE l.IsDeleted = 0
		
		INSERT INTO @DummyExtraPT (CustID)
		SELECT CustID
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT_xtest l WITH (NOLOCK)
	END 

	
	------------------------------------------------  
	
	CREATE TABLE #Transfer
	(
	    winlostdate     SMALLDATETIME, 
	    custid          INT,
		Currency		INT,
		bettype			INT,
		Product			NVARCHAR (250),
	    winlost         MONEY,
		Realwinlost		MONEY
		
	)

	
	INSERT INTO #Transfer (winlostdate, custid, Currency, bettype, Product, winlost, Realwinlost)
	SELECT	b.winlostdate,
			CASE
	         WHEN b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 then d.custid
	         ELSE -1
			END AS custid,
			CASE
	         WHEN (b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 AND ISNULL(d.Currency,0) <> 0 ) then b.Currency
	         ELSE 0
			END AS Currency,	
			CASE
	         WHEN b.bettype = 20000 then b.bettype
	         ELSE 0
			END AS bettype, 			
			CASE WHEN ISNULL(d.Currency,0) <> 0   --- CN88
				THEN 
					ISNULL(SUBSTRING (	b.transdesc, 
										CHARINDEX ('CN88', b.Transdesc ), 
										CASE WHEN CHARINDEX ('#', b.Transdesc ) <>  0 AND CHARINDEX ('CN88', b.Transdesc ) <> 0
											 THEN CHARINDEX ('#', b.Transdesc ) - CHARINDEX ('CN88', b.Transdesc ) 
											 ELSE 0 END 
									),'') 						 
				ELSE '' END AS Product,
			SUM((ISNULL(winlost, 0) - ISNULL(actual_stake, 0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)) * b.actualrate) AS Winlost,
			SUM(ISNULL(winlost, 0) - ISNULL(actual_stake, 0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)) AS RealWinlost 
	FROM dbo.bettrans b WITH (NOLOCK, INDEX = IX_Report)
	LEFT JOIN (SELECT DISTINCT CustId, currency FROM @dummyBalance) d 
		ON b.custid = d.custid  
	WHERE b.winlostdate = @winlostdate
	   AND b.ruben = 1
	   AND b.bettype > 19000 
	   AND b.bettype <> 21007 ---- exclude CN88 headline balance
	   and b.matchID = 0 
	   AND NOT EXISTS (SELECT 1 FROM @dummyExtraPT de WHERE de.CustID = b.Custid AND b.Bettype IN (21001,21002))   --- Not Get ticket transfer of reset winning extraPT
    GROUP BY b.winlostdate,
			CASE
	         WHEN b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 then d.custid
	         ELSE -1
			END ,
			CASE
	         WHEN (b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 AND ISNULL(d.Currency,0) <> 0 ) then b.Currency
	         ELSE 0
			END,	
			CASE
	         WHEN b.bettype = 20000 then b.bettype
	         ELSE 0
			END,			
			CASE WHEN ISNULL(d.Currency,0) <> 0   --- CN88
				THEN 
					ISNULL(SUBSTRING (  b.transdesc, 
										CHARINDEX ('CN88', b.Transdesc ), 
										CASE WHEN CHARINDEX ('#', b.Transdesc ) <>  0 AND CHARINDEX ('CN88', b.Transdesc ) <> 0
											 THEN CHARINDEX ('#', b.Transdesc ) - CHARINDEX ('CN88', b.Transdesc ) 
											 ELSE 0 END 
										),'') 
			 ELSE '' END

	UPDATE t 
	SET t.Product = d.Product
	FROM #Transfer t
		LEFT JOIN @dummyBalance d 
			ON t.custid = d.custid AND t.Currency = d.Currency
	WHERE ISNULL(t.Product,'') = ''
   
	---------------------------------------------------------------------------------------------------------
	--------------------------------------------Extra PT ---------------------------------------------------

	CREATE TABLE #WLByProduct
	(
	    winlostdate			smalldatetime, 		
		ProductId			INT,		
		ProductName			VARCHAR(250),
		SubProduct			VARCHAR(250),
		IsCN88				BIT,
		Currency			INT,
		Winlost				MONEY, 		
		ExtraPTWinlost		MONEY,
		eWinlost			MONEY,

		RealWinlost			MONEY, 		
		RealExtraPTWinlost	MONEY,		
		eRealWinlost		MONEY
	) 
	
		
	CREATE TABLE #wl 
	(	winlostdate 			SMALLDATETIME, 
		srecommend 				INT, 
		Currency				INT,
		Sporttype  				SMALLINT, 
		ProductId				INT, 
		ProductName				VARCHAR(250), 
		SubProduct				VARCHAR(250), 

		winlost					MONEY, 
		WinlostDueToRNG			MONEY, 
		WinlostDueToPP			MONEY, 
		eWinlost				MONEY,

		RealWinlost				MONEY, 
		RealWinlostDueToRNG		MONEY, 
		RealWinlostDueToPP		MONEY,  		
		eRealWinlost			MONEY
	)
		 
		INSERT INTO #wl (winlostdate, srecommend, Currency, Sporttype, ProductId, ProductName, SubProduct, 
						Winlost, WinlostDueToRNG, WinlostDueToPP, eWinlost,
						RealWinlost, RealWinlostDueToRNG, RealWinlostDueToPP, eRealWinlost)
		SELECT  b.winlostdate,
				b.srecommend,
				b.currency,      
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
				CASE WHEN b.bettype IN (2199, 2399, 2999, 4298) THEN 0
					ELSE
					(ISNULL(winlost,0)-ISNULL(actual_stake,0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)
						+ CASE
							-- Jackpot
							WHEN b.bettype IN (2198, 2398, 2998, 4297) THEN ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000),0)
							ELSE 0 END
					) * CASE WHEN @Istest = 1 AND currency = 20 THEN 1 ELSE b.actualrate END  END
				) AS Winlost,
				SUM(
					(CASE
							-- Jackpot
							WHEN b.bettype IN (2198, 2398, 2998) THEN -ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0)
							WHEN b.bettype IN (2199, 2399, 2999) THEN ISNULL(b.Winlost, 0) - ISNULL(b.actual_stake, 0)
						ELSE 0 END
					) * CASE WHEN @Istest = 1 AND currency = 20 THEN 1 ELSE b.actualrate END
				) AS WinlostDueToRNG,
				SUM(
					(CASE
							-- Jackpot
							WHEN b.bettype IN (4297) THEN -ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0)
							WHEN b.bettype IN (4298) THEN ISNULL(b.Winlost, 0) - ISNULL(b.actual_stake, 0)
						ELSE 0 END
					) * CASE WHEN @Istest = 1 AND currency = 20 THEN 1 ELSE b.actualrate END
				) AS WinlostDueToPP,
				SUM((CASE
						-- Jackpot
						WHEN b.bettype IN (2198, 2398, 2998, 4297) THEN
							CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
						WHEN b.bettype IN (2199, 2399, 2999, 4298) THEN 0
						ELSE
							CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END
						END
						) * CASE WHEN @Istest = 1 AND currency = 20 THEN 1 ELSE b.actualrate END * ISNULL(epositiontaking, 0)
					) AS eWinlost,
				
				--- Real					
				SUM(
				CASE WHEN b.bettype IN (2199, 2399, 2999, 4298) THEN 0
					ELSE
					(ISNULL(winlost,0)-ISNULL(actual_stake,0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)
						+ CASE
							-- Jackpot
							WHEN b.bettype IN (2198, 2398, 2998, 4297) THEN ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000),0)
							ELSE 0 END
					)  END
				) AS RealWinlost,
				SUM(
					(CASE
							-- Jackpot
							WHEN b.bettype IN (2198, 2398, 2998) THEN -ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0)
							WHEN b.bettype IN (2199, 2399, 2999) THEN ISNULL(b.Winlost, 0) - ISNULL(b.actual_stake, 0)
						ELSE 0 END
					)  
				) AS RealWinlostDueToRNG,
				SUM(
					(CASE
							-- Jackpot
							WHEN b.bettype IN (4297) THEN -ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0)
							WHEN b.bettype IN (4298) THEN ISNULL(b.Winlost, 0) - ISNULL(b.actual_stake, 0)
						ELSE 0 END
					)  
				) AS RealWinlostDueToPP,	
				SUM((CASE
						-- Jackpot
						WHEN b.bettype IN (2198, 2398, 2998, 4297) THEN
							CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
						WHEN b.bettype IN (2199, 2399, 2999, 4298) THEN 0
						ELSE
							CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END
						END
						) * ISNULL(epositiontaking, 0)
					) AS eRealWinlost
		FROM dbo.bettrans14 b WITH(NOLOCK)			
		INNER JOIN @SportBettype s ON s.BetType = b.bettype
		LEFT JOIN dbo.Match14 m WITH (NOLOCK) ON m.MatchId = b.MatchId AND m.eventdate = b.Winlostdate AND m.Sporttype = 44	
		WHERE   b.Winlostdate = @winlostdate 
			AND b.statusid NOT IN (101, 102, 103, 121)	
		GROUP BY b.Winlostdate,				
				b.srecommend,	
				b.currency,       
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
				

	INSERT INTO #WLByProduct (Winlostdate, ProductId, ProductName, IsCN88, Currency, Winlost, ExtraPTWinlost, RealWinlost, RealExtraPTWinlost) 
	SELECT Winlostdate, ProductId, ProductName, w.IsCN88, w.Currency, SUM(Winlost), SUM(ExtraPTWinlost), SUM(RealWinlost), SUM(RealExtraPTWinlost)---, SUM(eWinlost), SUM(eRealWinlost)
	FROM (
			--- WL by product		
			SELECT  w.Winlostdate, w.ProductId, w.ProductName,  
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
						ELSE 0  ---MBC 
					END IsCN88, 
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN w.Currency --- CN88
						ELSE 0  ---MBC 
					END AS Currency,
					SUM(ISNULL(w.Winlost,0)) as Winlost,
					SUM(ISNULL(w.eWinlost,0)) as ExtraPTWinlost,
					SUM(ISNULL(w.RealWinlost,0)) as RealWinlost,
					SUM(ISNULL(w.eRealWinlost,0)) as RealExtraPTWinlost 
			FROM	#wl w
			LEFT JOIN CS_CustSuper cs WITH (NOLOCK) 
				ON cs.CustId = w.srecommend
			WHERE (cs.CustId IS NULL OR w.Currency <> 20) -- exclude currency 20 for CN88 customer
			GROUP BY w.Winlostdate, w.ProductId, w.ProductName,
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
						ELSE 0  ---MBC 
					END,
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN w.Currency --- CN88
						ELSE 0  ---MBC 
					END
			
			/*			
			---ExtraPT
			UNION ALL
			SELECT  w.Winlostdate, w.ProductId, w.ProductName, 
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
						ELSE 0  ---MBC 
					END AS IsCN88, 
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN w.Currency --- CN88
						ELSE 0  ---MBC 
					END AS Currency,
					0 as Winlost,
					SUM(w.WinlostForExtraPT * ISNULL(s.ExtraPT,0)) as ExtraPTWinlost,
					0 as RealWinlost,
					SUM(w.RealWinlostForExtraPT * ISNULL(s.ExtraPT,0)) as RealExtraPTWinlost,
					0 as eWinlost,
					0 as eRealWinlost
			FROM	#wl w
			INNER JOIN dbo.Acc_GroupExtraPTSetting s WITH(NOLOCK)
					ON w.srecommend = s.SuperId
					AND w.ProductId = s.ProductId
					AND w.SubProduct = s.SubProduct
					AND w.Sporttype = s.Sporttype 
					AND w.Winlostdate BETWEEN s.FromDate AND s.ToDate	
			LEFT JOIN CS_CustSuper cs WITH (NOLOCK) 
					ON cs.CustId = w.srecommend
			WHERE (cs.CustId IS NULL OR w.Currency <> 20) -- exclude currency 20 for CN88 customer
			GROUP BY w.Winlostdate, w.ProductId, w.ProductName, 
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
						ELSE 0  ---MBC 
					END,
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN w.Currency --- CN88
						ELSE 0  ---MBC 
					END
				*/
		) w
	GROUP BY w.Winlostdate, w.ProductId, w.ProductName, w.IsCN88, w.Currency

	UNION ALL
	SELECT w.Winlostdate, '','Casino (Amount due to Jackpot Pool)', 0, 0 AS Currency, SUM(ISNULL(w.WinlostDueToRNG, 0)) AS Winlost, 0, SUM(ISNULL(w.RealWinlostDueToRNG, 0)) AS RealWinlost, 0 
    FROM #wl w
	WHERE w.WinlostDueToRNG <> 0
	GROUP BY Winlostdate
	
	UNION ALL
	SELECT w.Winlostdate, '','PP (Amount due to Jackpot Pool)', 0, 0 AS Currency, SUM(ISNULL(w.WinlostDueToPP, 0)) AS Winlost, 0, SUM(ISNULL(w.RealWinlostDueToPP, 0)) AS RealWinlost, 0 
    FROM #wl w
	WHERE w.WinlostDueToPP <> 0
	GROUP BY Winlostdate


	
	----- Update ProductName
	UPDATE e 
	SET ProductName = CASE WHEN e.IsCN88 = 1 THEN 'CN88 ' ELSE '' END 
					+ CASE WHEN e.ProductId = 6 THEN 'Casino' ELSE CASE WHEN e.ProductID <> 1 THEN p.ProductName ELSE e.ProductName END END 
	FROM #WLByProduct e
	INNER JOIN dbo.Products p WITH (NOLOCK)
		ON e.ProductId = p.ProductId
	 
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
						b.Currency,
					   ----ISNULL(SUM(b.Winlost), 0) AS reset,
					   SUM(CASE WHEN @Istest = 1 THEN ISNULL(b.RealWinlost, 0) ELSE ISNULL(b.Winlost, 0) END ) AS reset,
					   ISNULL(SUM(b.RealWinlost), 0) AS RealRreset
				 FROM #Transfer b
				 WHERE b.bettype <> 20000	     
				 GROUP BY b.product, b.Currency
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
				Currency			INT,

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
				 SELECT b.Product, b.currency,
					   SUM(CASE WHEN @Istest = 1 THEN ISNULL(b.RealWinlost, 0) ELSE ISNULL(b.Winlost, 0) END ) AS reset,
					   ISNULL(SUM(b.RealWinlost), 0) AS RealReset
				 FROM #Transfer b
				 WHERE b.bettype <> 20000	     
				 GROUP BY b.product, b.currency
			) 		
			INSERT INTO #reset( product, Currency, Winlost, WinlostAfterExtraPT, reset, LatestReset, RealWinlost, RealWinlostAfterExtraPT, RealReset, RealLatestReset)	
			SELECT dm.product, dm.Currency,
				   ROUND(SUM(ISNULL(e.Winlost, 0)), 2) AS Winlost, 
				   ROUND(SUM(ISNULL(e.Winlost, 0)), 2) - ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2)  AS WinlostAfterExtraPT,
				   ROUND(SUM(ISNULL(rs.reset, 0)), 2) AS reset, 
				   - (ROUND(SUM(ISNULL(e.Winlost, 0)), 2) - ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2)) - ROUND(SUM(ISNULL(rs.reset, 0)), 2) AS LatestReset,

				   ROUND(SUM(ISNULL(e.RealWinlost, 0)), 2) AS RealWinlost, 
				   ROUND(SUM(ISNULL(e.RealWinlost, 0)), 2) - ROUND(SUM(ISNULL(e.RealExtraPTWinlost, 0)), 2)  AS RealWinlostAfterExtraPT,
				   ROUND(SUM(ISNULL(rs.RealReset, 0)), 2) AS RealReset, 
				   - (ROUND(SUM(ISNULL(e.RealWinlost, 0)), 2) - ROUND(SUM(ISNULL(e.RealExtraPTWinlost, 0)), 2)) - ROUND(SUM(ISNULL(rs.RealReset, 0)), 2) AS RealLatestReset
			FROM @dummyBalance dm
				LEFT JOIN #WLByProduct e ON dm.product = e.productName  AND (dm.currency = e.currency OR @Istest = 1)
				LEFT JOIN reset rs ON dm.product = rs.product  AND dm.currency = rs.currency 
			WHERE dm.Product <> 'Total Balance'
			GROUP BY dm.product, dm.currency, dm.seq
			 
	 

			DECLARE @variance     money = 0, 
					@custid       int,
					@Product	  varchar(250),
					@resetCount   tinyint = 0,
					@transDesc    nvarchar(1000)= '',
					@seq		  smallint = 0,
					@maxseq		  smallint = 0,
					@ip			  VARCHAR(20) = '',
					@LogData	  NVARCHAR(200) = ''
                
			SELECT @seq = 1 

			SELECT @maxseq = MAX(r.seq),              
				   @resetCount =  ISNULL(SUM( CASE WHEN r.currency <> 0   ---CN88
												THEN
													CASE WHEN RealLatestReset <> 0 THEN 1 ELSE 0 END
												ELSE
													 CASE WHEN LatestReset <> 0 THEN 1 ELSE 0 END
												END),0)
			FROM   #reset r	


			IF (@resetCount = 0)
			BEGIN
				SELECT @ErrMsg = 'No products need to reset winning!',
					   @ErrCode = 2

				RETURN
			END


			WHILE (@seq <= @maxseq)
			BEGIN
				SET @variance = 0

				SELECT @variance = CASE WHEN d.currency <> 0   ---CN88
									THEN ROUND(r.RealLatestReset, 2)  
									ELSE ROUND(r.LatestReset, 2) 
									END ,
					   @custid = d.custid,
					   @Product = d.Product
				FROM #reset r
					INNER JOIN @dummyBalance d on r.product = d.product AND (r.currency = d.currency OR @isTest = 1)
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
					EXEC bodb_report.dbo.[Acc_StatementUpdateTransfer]
						@custid = @custid
						,@Amount = @variance
						,@winlostdate = @winlostdate
						,@ErrCode = @ErrCode OUTPUT
						,@ErrMsg = @ErrMsg OUTPUT							

					IF (@ErrCode <> 0) BREAK
					
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
										+  CONVERT(VARCHAR(100),	ISNULL( (CASE WHEN r.currency <> 0   ---CN88
																THEN
																	-(ISNULL(r.RealWinlostAfterExtraPT, 0)) - ISNULL(r.Realreset, 0) 
																ELSE
																	 -(ISNULL(r.WinlostAfterExtraPT, 0)) - ISNULL(r.reset, 0) 
																END),0) )
										+ ' '
										+ CASE WHEN r.currency <> 0 THEN e.currency ELSE 'RM' END
				FROM  #Reset r
					LEFT JOIN dbo.exchange e WITH (NOLOCK) 
						ON e.exchangeId = r.Currency
				WHERE ISNULL( (CASE WHEN r.currency <> 0   ---CN88
									THEN
										-(ISNULL(r.RealWinlostAfterExtraPT, 0)) - ISNULL(r.Realreset, 0) 
									ELSE
										 -(ISNULL(r.WinlostAfterExtraPT, 0)) - ISNULL(r.reset, 0) 
									END),0) <> 0
				 
											 
				
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
							,@copy_recipients = 'jetyee88@enpine.com;kwongyong@enpine.com;seanlau@enpine.com;byronchia@enpine.com;foo.mv@enpine.com;eric.lu@onelab.tw;tp@enpine.com;it@starixsoft.com;jackyting@enpine.com;vh@enpine.com'
							,@blind_copy_recipients = 'automail@enpine.com'
				ELSE
					SELECT  @recipients = 'sophia.nguyen@starixsoft.com'
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


		  
		DROP TABLE #Transfer
		DROP TABLE #WLByProduct   
		DROP TABLE #WL
END
GO 