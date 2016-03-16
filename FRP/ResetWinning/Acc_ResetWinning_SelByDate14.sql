Use bodb02
GO 
ALTER PROCEDURE [dbo].[Acc_ResetWinning_SelByDate14]
	@winlostdate	DATETIME,	
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
	Explanation's Param:

*/
BEGIN	
	SET NOCOUNT ON

	DECLARE @DummyBalance AS TABLE (CustId INT, Product VARCHAR(50), seq TINYINT )

	DECLARE @isTest BIT,@SQL NVARCHAR(100) = OBJECT_NAME(@@PROCID)
	IF (@SQL like '%_xtest%' )
	BEGIN
		SELECT @isTest = 1
	END
	ELSE
	BEGIN
		SELECT @isTest = 0
	END
	
	IF @isTest = 0
	BEGIN 
		INSERT INTO @DummyBalance (CustID, Product, seq)
		SELECT CustID, Product, seq
		FROM bodb_ACC.dbo.Acc_DWLList WITH(NOLOCK)
		WHERE Product NOT IN ('Total Balance','Poker', 'Poker (Due to Partners)')----, 'Racing (Due to Partners)') 
	END 
	ELSE
	BEGIN 
		INSERT INTO @DummyBalance (CustID, Product, seq)
		SELECT CustID, Product, seq
		FROM bodb_ACC.dbo.Acc_DWLList_xtest WITH(NOLOCK)
		WHERE Product NOT IN ('Total Balance','Poker', 'Poker (Due to Partners)')  ---'Racing (Due to Partners)')
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
		Sporttype		smallint
	)

	INSERT INTO #bettranstmp
	SELECT b.custid, b.bettype,
	       b.liveindicator,
	       SUM(ISNULL((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
	               ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0)),0) * actualrate) as winlost,
			CASE WHEN ISNULL(m.Sporttype, 0) <> 0	THEN m.Sporttype ELSE 0 END AS Sporttype
	FROM dbo.bettrans14 b WITH(NOLOCK)	
	LEFT JOIN @DummyBalance d ON b.custid = d.custid   
	LEFT JOIN dbo.Match14 m WITH (NOLOCK) ON m.MatchId = b.MatchId AND m.eventdate = @winlostdate AND m.Sporttype = 44
	WHERE 1 = 1
       AND b.winlostdate = @winlostdate
	   AND b.ruben = 1
	   AND b.statusid NOT IN (101, 102, 103, 121)
	   AND ISNULL((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
	               ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0)),0) * actualrate <> 0      
    GROUP BY b.custid, b.bettype, b.liveindicator, 
			 CASE WHEN ISNULL(m.Sporttype, 0) <> 0 THEN m.Sporttype ELSE 0 END
			 

    CREATE NONCLUSTERED INDEX #IX_bettranstmp ON #bettranstmp( custid, bettype)
	 
	------------------------ 
    DECLARE @RB_LineTotal money,
            @Poker_LineTotal money

	/*calculating racing net income*/
	--insert company's comm setting that is recieved from Phumelela into this temp table.
	DECLARE @tmpIBCFee TABLE
	(
	    partnerID int,
	    IBCFee    bit
    ) 

	DECLARE @CommSetting TABLE
	(
	    MatchID		  int,
		IBCFee		  bit,
		ToteCommWin	  smallmoney,
		ToteCommPlace smallmoney,
		ToteCommWP	  smallmoney,
		ToteFee		  smallmoney	
	)

	INSERT INTO @tmpIBCFee(partnerID, IBCFee)
    SELECT 1, 1 --RACE-PHU
	 UNION ALL
	SELECT 2, 0 --RACE-ATRUK
	 UNION ALL
	SELECT 3, 0 --RACE-ATRIRL
	 UNION ALL
    SELECT 4, 0 --RACE-RUK
	 UNION ALL
	SELECT 5, 1 --RACE-TABCORP
	 UNION ALL
	SELECT 6, 1 --RACE-TABCORPNSW
	 UNION ALL
	SELECT 101, 1 --GREY-DTOTEUK
	 UNION ALL
	SELECT 102, 1 --GREY-DTOTEIRL
	 UNION ALL
	SELECT 103, 1 --GREY-TABCORP
	 UNION ALL
	SELECT 104, 1 --GREY-TABCORPNSW
	 UNION ALL
	SELECT 201, 1 --HAR-TABCORP
	 UNION ALL
	SELECT 202, 1 --HAR-TABCORPNSW

	INSERT INTO @CommSetting
	(
	    MatchID,
	    IBCFee,
	    ToteCommWin,
	    ToteCommPlace,
	    ToteCommWP,
	    ToteFee
    )
	SELECT o.orid,
	       t.IBCFee,
	       p.ToteCommWin,
	       p.ToteCommPlace,
	       (p.ToteCommWin + p.ToteCommPlace) / 2 as ToteCommWP,
	       p.ToteFee
	 FROM dbo.outright14 o WITH(NOLOCK)
		INNER JOIN dbo.LeagueDetail p WITH(NOLOCK) ON o.leagueID = p.LeagueID AND p.programDate = o.programDate
		INNER JOIN dbo.RacingMeeting r WITH(NOLOCK) ON r.meetingID = p.leagueid
		INNER JOIN @tmpIBCFee t ON r.partnerID = t.partnerID
	 WHERE o.eventdate = @Winlostdate


	INSERT INTO @Winning( product, winlost)
	---- sportsbook live & non-live
	SELECT CASE
	         WHEN liveindicator = 1 THEN 'SPL'
			 WHEN liveindicator = 0 THEN 'SPNL'
		   END Product,
		   ISNULL(SUM(winlost), 0) winlost
	FROM #bettranstmp
	WHERE ((bettype <= 999 AND bettype NOT IN (9, 10, 29, 31, 32, 33, 71, 72, 73) AND (bettype NOT BETWEEN 81 AND 120) AND (bettype NOT BETWEEN 801 AND 899) AND (bettype NOT BETWEEN 901 AND 903))
				or bettype between 1301 and 1334		
			) 
			AND (Sporttype <> 44 )
	GROUP BY liveindicator

  	UNION ALL

	SELECT  CASE
	     	 WHEN bettype BETWEEN 31 AND 33 THEN 'Racing gross income'
			 WHEN bettype BETWEEN 81 AND 120 THEN 'Number Game'	
			 WHEN bettype BETWEEN 1101 AND 1199 THEN 'Live Casino'
			 WHEN bettype IN (71, 72) OR bettype BETWEEN 2101 AND 2399 THEN 'Casino'
			 WHEN bettype = 73 THEN 'Bingo'
			-- WHEN bettype = 1000 THEN 'Poker gross income'
			 WHEN bettype = 10 THEN 'Outright'
			 WHEN bettype IN (9, 29) THEN 'Parlay'
			 WHEN bettype BETWEEN 1201 AND 1299 THEN 'Virtual Sports'
			 WHEN bettype BETWEEN 1501 AND 1599 THEN 'Keno'
			 WHEN bettype BETWEEN 1800 AND 1899 THEN 'AG Casino'
			 WHEN bettype = 1900 THEN 'Macau'
			 WHEN bettype BETWEEN 1700 AND 1799 THEN 'Gold Deluxe'
			 WHEN bettype BETWEEN 801 AND 899 THEN 'Metric Gaming - Super Live'
			 WHEN bettype BETWEEN 2001 AND 2007 THEN 'Microgaming - Live Casino'
			 WHEN bettype BETWEEN 2008 AND 2009 THEN 'Microgaming - RNG Casino'
			 WHEN bettype BETWEEN 901 AND 903 THEN 'Bettrade'
			 WHEN bettype BETWEEN 18000 AND 18099 THEN 'Colossus Bets'
			 WHEN bettype = 1003 THEN 'Cockfighting'
			 WHEN Sporttype = 44 THEN 'Muay Thai'
		   END AS Product,
		   ISNULL(SUM(winlost), 0) as winlost
	 FROM #bettranstmp
	 WHERE (bettype BETWEEN 1101 AND 1199
			OR bettype BETWEEN 31 AND 33
			OR bettype BETWEEN 80 AND 120
			OR bettype IN (71, 72, 73, 10,  9, 29) ---1000
			OR bettype BETWEEN 1201 AND 1299
			OR bettype BETWEEN 1501 AND 1599
			OR bettype BETWEEN 1800 AND 1899
			OR bettype = 1900
			OR bettype BETWEEN 1700 AND 1799 
			OR bettype BETWEEN 801 AND 899
			OR bettype BETWEEN 2001 AND 2007  
			OR bettype BETWEEN 2008 AND 2009 
			OR bettype BETWEEN 901 AND 903 
			OR bettype BETWEEN 18000 AND 18099  
			OR bettype = 1003
			OR bettype BETWEEN 2101 AND 2399
			OR Sporttype = 44
		   )
	GROUP BY CASE
	         WHEN bettype BETWEEN 31 AND 33 THEN 'Racing gross income'
			 WHEN bettype BETWEEN 81 AND 120 THEN 'Number Game'
			 WHEN bettype BETWEEN 1101 AND 1199 THEN 'Live Casino'
			 WHEN bettype IN(71, 72) OR bettype BETWEEN 2101 AND 2399 THEN 'Casino'
			 WHEN bettype = 73 THEN 'Bingo'
			--- WHEN bettype = 1000 THEN 'Poker gross income'
			 WHEN bettype = 10 THEN 'Outright'
			 WHEN bettype IN (9, 29) THEN 'Parlay'
			 WHEN bettype BETWEEN 1201 AND 1299 THEN 'Virtual Sports'
			 WHEN bettype BETWEEN 1501 AND 1599 THEN 'Keno'
			 WHEN bettype BETWEEN 1800 AND 1899 THEN 'AG Casino'
			 WHEN bettype = 1900 THEN 'Macau'
			 WHEN bettype BETWEEN 1700 AND 1799 THEN 'Gold Deluxe'
			 WHEN bettype BETWEEN 801 AND 899 THEN 'Metric Gaming - Super Live'
			 WHEN bettype BETWEEN 2001 AND 2007 THEN 'Microgaming - Live Casino'
			 WHEN bettype BETWEEN 2008 AND 2009 THEN 'Microgaming - RNG Casino'
			 WHEN bettype BETWEEN 901 AND 903 THEN 'Bettrade'
			 WHEN bettype BETWEEN 18000 AND 18099 THEN 'Colossus Bets'
			 WHEN bettype = 1003 THEN 'Cockfighting'
			 WHEN Sporttype = 44 THEN 'Muay Thai'
	         END
	

	---------------------------------------------------
    ---- get Racing line total
	INSERT INTO @Winning( product, winlost)
	SELECT 'Racing',
	       -(SUM((CASE 
	                WHEN bettype = 33 THEN bm.WLIBC
	                ELSE -(b.winlost - b.actual_stake) * ISNULL(b.oddsspread, 0)
	              END) * b.actualrate)
		   - SUM(CASE
			       WHEN cs.IBCFee = 0 THEN 0
				   ELSE (CASE
						   WHEN b.bettype = 33 THEN bm.TOPhum
						   WHEN bettype in (31, 32) THEN b.actual_stake * (1 - b.tpositiontaking - ISNULL(b.oddsspread, 0))
						   ELSE 0 
						 END) * b.actualrate * cs.ToteFee
			     END) --FeeDue2 
		   + SUM((CASE bettype 
					WHEN 31 THEN b.actual_stake * cs.ToteCommWin * (1 - b.tpositiontaking - ISNULL(oddsspread, 0))
					WHEN 32 THEN b.actual_stake * cs.ToteCommPlace * (1 - b.tpositiontaking - ISNULL(oddsspread, 0))
					WHEN 33 THEN bm.TOPhum * cs.ToteCommWP  
					ELSE 0
				  END) * b.actualrate) --commIncomeIBC
		   - SUM(b.scomm*b.actualrate))
	FROM dbo.bettrans14 b WITH(NOLOCK)
			INNER JOIN @CommSetting AS cs ON b.matchid = cs.matchid 
			LEFT JOIN (
				SELECT refno,
				   SUM(CASE
				    WHEN bettype = 32 and liveawayscore = 0 THEN 0
				         ELSE stake * ISNULL(oddsspread, 0)
				       END) TOIBC,
				   -SUM((winlost - stake) * ISNULL(oddsspread, 0)) WLIBC,
				   SUM(CASE
				         WHEN bettype = 32 and liveawayscore = 0 THEN 0
				         WHEN bettype = 31 or (bettype = 32 and liveawayscore <> 0) THEN stake * (1 -tpositiontaking - ISNULL(oddsspread, 0))
				         ELSE 0
				       END) TOPhum
  				FROM bettransm14 WITH(NOLOCK)
				GROUP BY refno
					) bm ON b.transid = bm.refno
	 WHERE 1 = 1
	   AND b.ruben = 1
	   AND b.bettype in (31, 32, 33)
	   AND b.matchid > 0
	   AND statusid NOT IN (101, 102, 103, 121)
	   AND b.winlostdate = @winlostdate
  
	/*end calculating racing net income*/
		
	UPDATE w1
    SET w1.product = 'Racing (Due to Partners)',
		w1.winlost = w1.winlost - w2.winlost
	FROM @Winning w1
	CROSS JOIN @Winning w2 
	WHERE w1.product = 'Racing gross income' 
	   and w2.product = 'Racing'

	
	---------------------------------------------------------------------------------------------------------
	--------------------------------------------Extra PT ---------------------------------------------------

	----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT,SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	SELECT * FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '')



	CREATE TABLE #ExtraPTWL
	(
	    ProductId		INT,
		ProductName		VARCHAR(50),
		ExtraPTwinlost  MONEY
	)
	----Non sportsbook
	;WITH wl AS(
		SELECT b.srecommend,	      
			   0 AS Sporttype,
			   s.ProductId,
			   '' AS SubProduct,
			   SUM(ISNULL(ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) + ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0),0) * actualrate) as winlost 		 
		FROM dbo.bettrans14 b WITH(NOLOCK)
		INNER JOIN @SportBettype s ON s.BetType = b.bettype
		WHERE  b.winlostdate = @winlostdate
		   --AND b.ruben = 1
		   AND b.statusid NOT IN (101, 102, 103, 121)	  
		   AND s.ProductID <> 1
		GROUP BY b.srecommend,	      
			   s.ProductId 
			   )
	INSERT INTO #ExtraPTWL (ProductId, ExtraPTwinlost) 
	SELECT	w.ProductId, SUM (w.winlost *s.ExtraPT) AS ExtraPTwinlost
	FROM	wl w
	INNER JOIN bodb_Acc.dbo.Acc_GroupExtraPTSetting s
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
					WHEN s.SubProduct IN ('BT-Sold','BT-Bought','BT-Comm') THEN 'Bettrade'
					WHEN ISNULL(m.Sporttype, 0) = 44 THEN 'Muay Thai'
					WHEN b.bettype = 10 THEN 'Outright'
					WHEN b.bettype IN (9,29) THEN'Parlay' 
					WHEN b.liveindicator = 1 THEN 'SPL' 
					WHEN b.liveindicator = 0 THEN 'SPNL'  								     
				END	AS ProductName,
			   CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm') THEN s.SubProduct ELSE '' END AS SubProduct,
			   CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm') OR ISNULL(m.matchid, 0) <> 0 OR B.Bettype IN (10,9,29) THEN 2 ELSE b.liveindicator END AS liveindicator ,
			   SUM(ISNULL(ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) + ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0), 0)* actualrate) as winlost 		 
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
					WHEN s.SubProduct IN ('BT-Sold','BT-Bought','BT-Comm') THEN 'Bettrade'
					WHEN ISNULL(m.Sporttype, 0) = 44 THEN 'Muay Thai'
					WHEN b.bettype = 10 THEN 'Outright'
					WHEN b.bettype IN (9,29) THEN'Parlay' 
					WHEN b.liveindicator = 1 THEN 'SPL'
					WHEN b.liveindicator = 0 THEN 'SPNL' 								     
			   END,			   
			   CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm') THEN s.SubProduct ELSE '' END,
			   CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm') OR ISNULL(m.matchid, 0) <> 0 OR B.Bettype IN (10,9,29) THEN 2 ELSE b.liveindicator END
			   )

	INSERT INTO #ExtraPTWL ( ProductId, ProductName, ExtraPTwinlost) 
	SELECT  w.ProductId, w.ProductName, SUM (w.winlost * s.ExtraPT) AS ExtraPTwinlost
	FROM	wl w
	INNER JOIN bodb_Acc.dbo.Acc_GroupExtraPTSetting s
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
			
		SELECT 'Openning Balance' as product, SUM(ISNULL(winlost, 0)) AS winlost, 0 AS WinlostAfterExtraPT, 0 AS Reset
		FROM #source 
		WHERE bettype = 20000
		HAVING SUM(ISNULL(winlost, 0))  <> 0

		UNION ALL
		
	    SELECT dm.product,
	           ROUND(ISNULL(w.winlost, 0), 2) AS winlost,
			   ROUND(ISNULL(w.winlost, 0), 2) -  ROUND(ISNULL(e.ExtraPTwinlost, 0), 2) AS WinlostAfterExtraPT,
			   ROUND(ISNULL(rs.reset, 0), 2) AS reset
	    FROM @Winning w
		FULL OUTER JOIN rs rs ON w.product = rs.product  
		RIGHT JOIN @DummyBalance dm ON dm.product = ISNULL(w.product, rs.product)
		LEFT JOIN #ExtraPTWL e ON e.ProductName = dm.product	 
		---ORDER BY dm.seq
 
       
END

GO

GRANT EXECUTE ON [dbo].[Acc_ResetWinning_SelByDate14] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_ResetWinning_SelByDate14] TO [vnteam] AS [dbo]
GO 