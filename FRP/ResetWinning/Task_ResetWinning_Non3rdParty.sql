/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Task_ResetWinning_Non3rdParty]
	@fromdate smalldatetime,
	@todate   smalldatetime,
	@mode     tinyint = 0,
	@creator  INT = 5838421,
	@ip       VARCHAR(20) = '',
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

	Param Explanation:
	    @mode:  0 _ view report
	            1 _ reset balance
	            
	    @ErrCode: 0 _ Success
	              1 _ Error
	              2 _ Already reset
*/
BEGIN	
	SET NOCOUNT ON
	 
	------Get Sport Bettype Matrix------
	-- Check SP Version
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	CREATE TABLE  #SportBettype (ProductID INT, Bettype INT,SubProduct VARCHAR(500))
	INSERT INTO #SportBettype
	SELECT ProductID, Bettype, SubProduct FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)
	
	CREATE CLUSTERED INDEX CIX_Bettype ON #SportBettype (bettype) 
	----- End get sport bettype 
	
------------------------------------------
	DECLARE @dummyBalance TABLE
	(   
	    WinlostDate SMALLDATETIME,
	    seq         INT,
	    CustId      INT,
	    Product     VARCHAR(250),
		Currency	INT
    )
    
	DECLARE @dummyExtraPT TABLE
	(   
	    CustId      int
    )
		
    DECLARE @wldate DATE = @todate,
            @seq    smallint = 0,
            @maxseq smallint = 0 
	
	DECLARE @Date AS TABLE (WLDate DATE )
	
	WHILE (@FromDate <= @wldate)
	BEGIN 
		INSERT INTO @Date (WLDate)
		VALUES (@wldate)

		SELECT @wldate = DATEADD( DAY, -1, @wldate)
	END


	DECLARE @SQL NVARCHAR(100) = ISNULL(OBJECT_NAME(@@PROCID),'')
	SELECT @Istest = CASE WHEN @SQL like '%_xtest%' THEN 1 ELSE 0 END

	
	IF @Istest = 0
	BEGIN 
		INSERT INTO @dummyBalance (WinlostDate, seq, CustId, Product, Currency)
		SELECT  d.WLDate, CASE WHEN L.seq = 0 THEN 999 ELSE l.seq END  AS seq, 
				l.Custid, l.product, 
				CASE WHEN l.Product LIKE 'CN88%' THEN ISNULL(c.Currency,0) ELSE 0 END AS Currency
		FROM bodb_ACC.dbo.Acc_DWLList l WITH (NOLOCK)
		LEFT JOIN dbo.CustInfo c WITH (NOLOCK) ON c.CustID = l.CustID
		CROSS JOIN @Date d
		WHERE l.IsDeleted = 0
				
			
		INSERT INTO @dummyExtraPT (CustID)
		SELECT CustID
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT l WITH (NOLOCK)

		
	END
	ELSE
	BEGIN 
		INSERT INTO @dummyBalance (WinlostDate, seq, CustId, Product, Currency)
		SELECT  d.WLDate, CASE WHEN L.seq = 0 THEN 999 ELSE l.seq END  AS seq, 
				l.Custid, l.product, 
				CASE WHEN l.Product LIKE 'CN88%' THEN ISNULL(c.Currency,0) ELSE 0 END AS Currency
		FROM bodb_ACC.dbo.Acc_DWLList_xtest l WITH (NOLOCK)
		LEFT JOIN dbo.CustInfo c WITH (NOLOCK) ON c.CustID = l.CustID
		CROSS JOIN @Date d
		WHERE l.IsDeleted = 0
			
		INSERT INTO @dummyExtraPT (CustID)	
		SELECT CustID
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT_xtest l WITH (NOLOCK)
	END
	 
	------------------------------------------------  
	
	CREATE TABLE #Transfer
	(
	    winlostdate     SMALLDATETIME, 
	    custid          INT,
		Currency		INT,
		Product			VARCHAR(250),
	    Winlost         MONEY,
		RealWinlost 	MONEY
	)

	INSERT INTO #Transfer (winlostdate, custid, Currency, Product, winlost, Realwinlost)
	SELECT	b.winlostdate,
			CASE
	         WHEN b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 then d.custid
	         ELSE -1
			END AS custid,
			CASE
	         WHEN (b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 AND ISNULL(d.Currency,0) <> 0 ) then b.Currency
	         ELSE 0
			END AS Currency,		   
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
	LEFT JOIN (SELECT DISTINCT CustId, WinlostDate, currency FROM @dummyBalance) d 
		ON b.custid = d.custid AND d.WinlostDate= b.WinlostDate 
	WHERE b.winlostdate between @fromdate and @todate
	   AND b.ruben = 1
	   AND b.bettype > 19000 
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
			CASE WHEN ISNULL(d.Currency,0) <> 0   --- CN88
				THEN 
					ISNULL(SUBSTRING (  b.transdesc, 
										CHARINDEX ('CN88', b.Transdesc ), 
										CASE WHEN CHARINDEX ('#', b.Transdesc ) <>  0 AND CHARINDEX ('CN88', b.Transdesc ) <> 0
											 THEN CHARINDEX ('#', b.Transdesc ) - CHARINDEX ('CN88', b.Transdesc ) 
											 ELSE 0 END 
										),'') 
			 ELSE '' END
	
	-----Update Product for MBC	
	UPDATE t 
	SET t.Product = d.Product
	FROM #Transfer t
		INNER JOIN @dummyBalance d 
			ON t.custid = d.custid
				AND t.Currency = d.Currency
				AND d.WinlostDate= t.WinlostDate 
	WHERE ISNULL(t.Product,'') = ''
    
	---------------------------------------------------------------------------------------------------------
	--------------------------------------------Extra PT ---------------------------------------------------
	CREATE TABLE #wl 
	(	winlostdate 	SMALLDATETIME, 
		srecommend 		INT, 
		Currency		INT,
		Sporttype  		SMALLINT, 
		ProductId		INT, 
		ProductName		VARCHAR(250), 
		SubProduct		VARCHAR(250), 
		Winlost			MONEY, 
		WinlostDueTo	MONEY, 
		CommForExtraPT	MONEY,
		WinlostForExtraPT MONEY,
		RealWinlost			MONEY, 
		RealWinlostDueTo	MONEY, 
		RealCommForExtraPT	MONEY,
		RealWinlostForExtraPT MONEY
	)
	
	CREATE TABLE #WLByProduct
	(
	    winlostdate			SMALLDATETIME, 
		ProductId			INT,
		ProductName			VARCHAR(250),
		SubProduct			VARCHAR(250),
		IsCN88				BIT,
		Currency			INT,
		Winlost				MONEY, 		
		ExtraPTWinlost		MONEY,
		RealWinlost			MONEY, 		
		RealExtraPTWinlost	MONEY
	) 
	 
		INSERT INTO #wl (winlostdate, srecommend, Currency, Sporttype, ProductId, ProductName, SubProduct, 
						 winlost, WinlostDueTo, CommForExtraPT, WinlostForExtraPT,
						 Realwinlost, RealWinlostDueTo, RealCommForExtraPT, RealWinlostForExtraPT)
		SELECT  b.winlostdate,
				b.srecommend,
				b.Currency,				
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
				---Base currency
				SUM(
						CASE WHEN b.bettype IN (2199, 2399, 2999) THEN 0
							ELSE
								(ISNULL(winlost,0)-ISNULL(actual_stake,0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)
									+ CASE
										-- Jackpot
										WHEN b.bettype IN (2198, 2398, 2998) THEN ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000),0)
										ELSE 0 END
								) * actualrate  
							END
					) AS winlost,
				SUM(
						(	
							CASE
								-- Jackpot
								WHEN b.bettype IN (2198, 2398, 2998) THEN -ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0)
								WHEN b.bettype IN (2199, 2399, 2999) THEN ISNULL(b.Winlost, 0) - ISNULL(b.actual_stake, 0)
							ELSE 0 
							END
						) * b.actualrate
					) AS WinlostDueTo,
				0 AS CommForExtraPT,
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
						)* b.actualrate
					) AS WinlostForExtraPT,
				
				---Real currency
				SUM(
						CASE WHEN b.bettype IN (2199, 2399, 2999) THEN 0
							ELSE
								(ISNULL(winlost,0)-ISNULL(actual_stake,0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)
									+ CASE
										-- Jackpot
										WHEN b.bettype IN (2198, 2398, 2998) THEN ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000),0)
										ELSE 0 END
								)  
							END
					) AS RealWinlost,
				SUM(
						(	
							CASE
								-- Jackpot
								WHEN b.bettype IN (2198, 2398, 2998) THEN -ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0)
								WHEN b.bettype IN (2199, 2399, 2999) THEN ISNULL(b.Winlost, 0) - ISNULL(b.actual_stake, 0)
							ELSE 0 
							END
						) 
					) AS RealWinlostDueTo,
				0 AS RealCommForExtraPT,
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
					) AS RealWinlostForExtraPT				
				
		FROM dbo.bettrans b WITH (NOLOCK)			
		INNER JOIN #SportBettype s ON s.BetType = b.bettype
		LEFT JOIN dbo.Match m WITH (NOLOCK) ON m.MatchId = b.MatchId AND m.Sporttype = 44		
		WHERE   b.Winlostdate between @fromdate and @todate
			AND b.ruben = 1
			AND b.statusid NOT IN (101, 102, 103, 121)		
			AND b.Currency <> 20 
			AND b.bettype < 19001
		GROUP BY b.Winlostdate,				
				b.srecommend,	
				b.Currency,
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
	SELECT Winlostdate, ProductId, ProductName, IsCN88, Currency, SUM(Winlost), SUM(ExtraPTWinlost), SUM(RealWinlost), SUM(RealExtraPTWinlost)
	FROM (
			--- WL by product			
			SELECT  w.Winlostdate, w.ProductId, w.ProductName, 
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
						ELSE 0  ---MBC 
					END AS IsCN88, 
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN w.Currency --- CN88
						ELSE 0  ---MBC 
					END AS Currency,
					SUM(ISNULL( w.Winlost,0)) as Winlost, 
					0 as ExtraPTWinlost,
					SUM(ISNULL( w.RealWinlost,0)) as RealWinlost, 
					0 as RealExtraPTWinlost 					
			FROM	#wl w
			LEFT JOIN CS_CustSuper cs WITH (NOLOCK) 
				ON cs.CustId = w.srecommend
			GROUP BY w.Winlostdate, w.ProductId, w.ProductName,
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
						ELSE 0  ---MBC 
					END,
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN w.Currency --- CN88
						ELSE 0  ---MBC 
					END
					
			-----Casino (Amount due to Jackpot Pool)
			UNION ALL
			SELECT  w.Winlostdate, '' AS ProductId, 'Casino (Amount due to Jackpot Pool)' as ProductName, 
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
						ELSE 0  ---MBC 
					END AS IsCN88,
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN w.Currency --- CN88
						ELSE 0  ---MBC 
					END AS Currency,
					SUM(ISNULL(w.WinlostDueTo, 0)) AS Winlost, 
					0 AS ExtraPTWinlost, 
					SUM(ISNULL(w.RealWinlostDueTo, 0)) AS RealWinlost, 
					0 AS RealExtraPTWinlost
			FROM #wl w
			LEFT JOIN CS_CustSuper cs WITH (NOLOCK) 
				ON cs.CustId = w.srecommend
			WHERE w.WinlostDueTo <> 0 
			GROUP BY Winlostdate, 
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
						ELSE 0  ---MBC 
					END,
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN w.Currency --- CN88
						ELSE 0  ---MBC 
					END

			
			--- extraPT
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
				   SUM(w.RealWinlostForExtraPT * ISNULL(s.ExtraPT,0)) as RealExtraPTWinlost  
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
					END,
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN w.Currency --- CN88
						ELSE 0  ---MBC 
					END
			
			
			--- extraComm	
			UNION ALL 
			SELECT	w.Winlostdate, w.ProductId, w.ProductName, 
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN 1 --- CN88
						ELSE 0  ---MBC 
					END AS IsCN88,
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN w.Currency --- CN88
						ELSE 0  ---MBC 
					END AS Currency,
					0 as Winlost, 
					SUM(w.CommForExtraPT * ISNULL(s.ExtraCommRate,0)) as ExtraPTWinlost,
					0 as RealWinlost, 
					SUM(w.RealCommForExtraPT * ISNULL(s.ExtraCommRate,0)) as RealExtraPTWinlost   --- ExtraComm if any
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
					END,
					CASE WHEN ISNULL(cs.CustID, '') <> '' THEN w.Currency --- CN88
						ELSE 0  ---MBC 
					END
								
	
		) w
	GROUP BY w.Winlostdate, w.ProductId, w.ProductName, w.IsCN88, w.Currency
	

	----- Update ProductName
	UPDATE e 
	SET ProductName = CASE WHEN e.IsCN88 = 1 THEN 'CN88 ' ELSE '' END 
					+ CASE WHEN e.ProductId = 6 THEN 'Casino' ELSE CASE WHEN e.ProductID <> 1 THEN p.ProductName ELSE e.ProductName END END 
	FROM #WLByProduct e
	INNER JOIN dbo.Products p WITH (NOLOCK)
		ON e.ProductId = p.ProductId 
	 
	---------------------------------------------------------------------------------------------------------
 
    --view report
    IF (@mode = 0)
    BEGIN 
	    ----- calculate reset
	   ;WITH reset AS
	    (
		     SELECT b.Winlostdate,
		           b.Product,
				   b.Currency,
		           SUM(ISNULL(b.Winlost, 0)) AS Reset,
				   SUM(ISNULL(b.RealWinlost, 0)) AS RealReset
		     FROM #Transfer b	     
			 WHERE CustID <> -1
			 GROUP BY b.Winlostdate, b.product, b.Currency
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
	    )		
		SELECT dm.Winlostdate,
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
			LEFT JOIN #WLByProduct e ON dm.product = e.productName and dm.Winlostdate = e.Winlostdate AND (dm.currency = e.currency OR @Istest = 1)
			LEFT JOIN reset rs ON dm.product = rs.product and dm.Winlostdate = rs.Winlostdate AND dm.currency = rs.currency
			LEFT JOIN TotalBalance bl ON bl.Product = dm.Product AND bl.winlostdate = dm.WinlostDate
		GROUP BY dm.Winlostdate, dm.product, dm.seq
		ORDER BY dm.Winlostdate DESC, dm.seq ASC 
  
	END
	--reset balance
	ELSE IF (@mode = 1)
	BEGIN
	
		CREATE TABLE #reset
		(
			winlostdate 		SMALLDATETIME,
			product     		VARCHAR(250),
			Currency			INT,
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
					b.Currency,				   
		           SUM(CASE WHEN @Istest = 1 THEN ISNULL(b.RealWinlost, 0) ELSE ISNULL(b.Winlost, 0) END ) AS reset,
				   SUM(ISNULL(b.RealWinlost, 0)) AS RealReset
		     FROM #Transfer b	     
			 WHERE CustID <> -1
			 GROUP BY b.Winlostdate, b.product,b.Currency
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
	    )
		INSERT INTO #reset(Winlostdate, product, currency, Winlost, WinlostAfterExtraPT, reset, latestreset, RealWinlost, RealWinlostAfterExtraPT, RealReset, RealLatestReset)
	    SELECT dm.Winlostdate,
	           dm.product,
			   dm.currency,
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
			LEFT JOIN #WLByProduct e ON dm.product = e.productName and dm.Winlostdate = e.Winlostdate AND (dm.currency = e.currency OR @Istest = 1)
			LEFT JOIN reset rs ON dm.product = rs.product and dm.Winlostdate = rs.Winlostdate AND dm.currency = rs.currency 
			LEFT JOIN TotalBalance bl ON bl.Product = dm.Product AND bl.winlostdate = dm.WinlostDate
		GROUP BY dm.Winlostdate, dm.product, dm.currency, dm.seq
		ORDER BY dm.Winlostdate DESC, dm.seq ASC
	 

        DECLARE @variance     money = 0,
                @Winlostdate  smalldatetime,
                @custid       int,
				@Product	  varchar(250),
                @resetCount   tinyint = 0,
                @transDesc    nvarchar(1000)= '' 
                
        SELECT @seq = 1, @WinlostDate = @FromDate

		SELECT @maxseq = MAX(r.seq),              
               @resetCount =  ISNULL(SUM( CASE WHEN r.currency <> 0   ---CN88
											THEN
												CASE WHEN -(ISNULL(r.RealWinlostAfterExtraPT, 0)) - ISNULL(r.Realreset, 0) <> 0 AND r.Product NOT IN ('Total Balance') THEN 1
															  ELSE 0
															END
											ELSE
												 CASE
															  WHEN -(ISNULL(r.WinlostAfterExtraPT, 0)) - ISNULL(r.reset, 0) <> 0 AND r.Product NOT IN ('Total Balance') THEN 1
															  ELSE 0
															END
											END),0)
        FROM   #reset r
        WHERE  r.WinlostDate = @WinlostDate
				AND r.Product NOT IN ('Total Balance') 


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
				INNER JOIN @dummyBalance d on r.product = d.product AND r.WinlostDate = d.WinlostDate AND (r.currency = d.currency OR @isTest = 1)
            WHERE r.seq = @seq


            IF (@variance <> 0) 
            BEGIN
                SELECT @transDesc = 'DWL-' + CAST(@Product as varchar(250))
									 + '# ' + CAST(@fromdate as varchar(30))
                                           + CAST(@custid as varchar(50)) + ':'
                                           + CAST(@variance as varchar(100))

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
                    
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Transfer
					@UserID = @creator,
					@FromCustID = 0,
					@ToCustID = @custid,
					@IP = @ip,
					@Doing = @transDesc
                
            END

            SET @seq = @seq + 1

            SELECT @ErrMsg = 'The process has been successful!'
        END
      
         SELECT r.Winlostdate,  
               r.product,
			   SUM (r.Winlost) AS Winlost ,
               SUM (r.WinlostAfterExtraPT) AS WinlostAfterExtraPT, 
              -- SUM (CASE WHEN d.Currency <> 0  THEN r.Realreset + r.RealLatestReset ELSE r.reset + r.latestreset END) AS totalreset,
               --SUM (CASE WHEN d.Currency <> 0  THEN r.RealLatestReset ELSE r.LatestReset END ) latestreset 
			   SUM ( r.reset + r.latestreset ) AS totalreset,
               SUM ( r.LatestReset  ) latestreset 
        FROM #reset r
		INNER JOIN @dummyBalance d 
			ON d.CustID = d.custID and r.product = d.Product
		GROUP BY r.Winlostdate, r.product, d.seq
		ORDER BY d.seq
		
		DROP TABLE #reset		
		
	END 
    DROP TABLE #WLByProduct
	DROP TABLE #Transfer 
	DROP TABLE #WL
END
GO