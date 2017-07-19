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

	Param Explanation:
	    @mode:  0 _ view report
	            1 _ reset balance
	            
	    @ErrCode: 0 _ Success
	              1 _ Error
	              2 _ Already reset
*/
BEGIN	
	SET NOCOUNT ON

	DECLARE @EffectedDate DATETIME -- 20160112@Percy: Applying date of changing extra PT formula [RedmineID: #70060]
	SELECT  @EffectedDate = '2017-01-19'

	------Get Sport Bettype Matrix------
	-- Check SP Version
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	SELECT ProductID, Bettype, SubProduct FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)
	
	----- End get sport bettype 
	
------------------------------------------
	DECLARE @dummyBalance TABLE
	(   
	    WinlostDate smalldatetime,
	    seq         tinyint,
	    CustId      int,
	    Product     varchar(50)
    )
    
	DECLARE @dummyExtraPT TABLE
	(   
	    CustId      int
    )
		
    declare @reset table
    (
        winlostdate smalldatetime,
        product     varchar(50),
		winlost		money,
        WinlostAfterExtraPT     money,
        reset       money,
        latestreset money,
        seq         tinyint
    )

    declare @wldate DATE = @todate,
            @seq    smallint = 0,
            @maxseq smallint = 0 
	
	DECLARE @Date AS TABLE (WLDate DATE )
	
	WHILE (@FromDate <= @wldate)
	BEGIN 
		INSERT INTO @Date (WLDate)
		VALUES (@wldate)

		SELECT @wldate = DATEADD( DAY, -1, @wldate)
	END

	DECLARE @SQL NVARCHAR(100) = OBJECT_NAME(@@PROCID)
	
	IF (@SQL not like '%_xtest%')	
	BEGIN 
		INSERT INTO @dummyBalance (WinlostDate, seq, CustId, Product)
		SELECT  d.WLDate, CASE WHEN L.seq = 0 THEN 99 ELSE l.seq END  AS seq, l.Custid, l.product
		FROM bodb_ACC.dbo.Acc_DWLList l WITH (NOLOCK)
		CROSS JOIN @Date d 
			
		INSERT INTO @dummyExtraPT (CustID)
		SELECT CustID
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT l WITH (NOLOCK)
		
	END
	ELSE
	BEGIN 
		INSERT INTO @dummyBalance (WinlostDate, seq, CustId, Product)
		SELECT  d.WLDate, CASE WHEN L.seq = 0 THEN 99 ELSE l.seq END  AS seq, l.Custid, l.product
		FROM bodb_ACC.dbo.Acc_DWLList_xtest l WITH (NOLOCK)
		CROSS JOIN @Date d 
			
		INSERT INTO @dummyExtraPT (CustID)	
		SELECT CustID
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT_xtest l WITH (NOLOCK)
	END
	
	------------------------------------------------  
	
	CREATE TABLE #bettranstmp
	(
	    winlostdate     smalldatetime, 
	    custid          int,
	    bettype         int,
	    liveindicator   bit,
	    winlost         money,
		Sporttype		smallint
	)

	INSERT INTO #bettranstmp
	SELECT	b.winlostdate,
			CASE
				WHEN b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 THEN d.custid
				ELSE -1
			END AS custid,
			b.bettype,
			b.liveindicator,
			SUM(ISNULL((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
	               ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0)) * (CASE
	                                                                                  WHEN ISNULL(d.custid, -1) <> -1 AND b.bettype IN (21001, 21002) THEN 1
	                                                                                  ELSE actualrate
	                                                                                END), 0)) as winlost,
			CASE WHEN ISNULL(m.matchid, 0) <> 0	THEN m.Sporttype ELSE 0 END AS Sporttype
	FROM dbo.bettrans b WITH(READPAST, INDEX = IX_Report)
	LEFT JOIN @dummyBalance d ON b.custid = d.custid AND d.WinlostDate= b.WinlostDate
	LEFT JOIN dbo.Match m WITH (NOLOCK) ON m.MatchId = b.MatchId AND m.eventdate = b.Winlostdate AND m.Sporttype = 44
	WHERE 1 = 1
       AND b.winlostdate between @fromdate and @todate
	   AND b.ruben = 1
	   AND b.statusid NOT IN (101, 102, 103, 121)
	   AND (CASE WHEN b.CustId IN (SELECT CustId FROM @dummyExtraPT) AND Bettype IN (21001,21002) THEN 0 ELSE 1 END = 1)
	   AND ISNULL((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
	               ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0)) * (CASE
	                                                                                  WHEN ISNULL(d.custid, -1) <> -1 AND b.bettype IN (21001, 21002) THEN 1
	                                                                                  ELSE actualrate
	                                                                                END), 0) <> 0
    GROUP BY b.winlostdate, CASE WHEN b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 then d.custid ELSE -1 END,
			 b.bettype, b.liveindicator, 
			 CASE WHEN ISNULL(m.matchid, 0) <> 0 THEN m.Sporttype ELSE 0 END
			 

    CREATE NONCLUSTERED INDEX #IX_bettranstmp ON #bettranstmp(custid, winlostdate, bettype)
	 
	------------------------ 

    DECLARE @RB_LineTotal money

	/*calculating racing net income*/
	--insert company's comm setting that is recieved from Phumelela into this temp table.
	DECLARE @tmpIBCFee TABLE
	(
	    partnerID int,
	    IBCFee    bit
    ) 

	DECLARE @CommSetting TABLE
	(
	    winlostdate   smalldatetime,
	    MatchID		  int,
		IBCFee		  bit,
		ToteCommWin	  smallmoney,
		ToteCommPlace smallmoney,
		ToteCommWP	  smallmoney,
		ToteFee		  smallmoney	
	)

	DECLARE @Winning TABLE 
	(
	    winlostdate smalldatetime,
		product     varchar(50),
		winlost     money
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
	    winlostdate,
	    MatchID,
	    IBCFee,
	    ToteCommWin,
	    ToteCommPlace,
	    ToteCommWP,
	    ToteFee
    )
	SELECT o.eventdate,
	       o.orid,
	       t.IBCFee,
	       p.ToteCommWin,
	       p.ToteCommPlace,
	       (p.ToteCommWin + p.ToteCommPlace) / 2 as ToteCommWP,
	       p.ToteFee
	 FROM dbo.outright o WITH(NOLOCK)
		INNER JOIN dbo.LeagueDetail p WITH(NOLOCK) ON o.leagueID = p.LeagueID AND p.programDate = o.programDate
		INNER JOIN dbo.RacingMeeting r WITH(NOLOCK) ON r.meetingID = p.leagueid
		INNER JOIN @tmpIBCFee t ON r.partnerID = t.partnerID
	 WHERE o.eventdate BETWEEN @fromdate AND @todate


	INSERT INTO @Winning(winlostdate, product, winlost)
	---- sportsbook live & non-live
	SELECT winlostdate,
	       CASE
	         WHEN liveindicator = 1 THEN 'SPL'
			 WHEN liveindicator = 0 THEN 'SPNL'
		   END Product,
		   ISNULL(SUM(winlost), 0) winlost
	FROM #bettranstmp
	WHERE
		(
			(
				bettype <= 999
				AND bettype NOT IN (9, 10, 29, 31, 32, 33, 71, 72) -- Parlay, Outright, Racing, Casino
				AND (bettype NOT BETWEEN 81 AND 120) -- Number Game
				AND (bettype NOT BETWEEN 801 AND 899) -- Metric Gaming
				AND (bettype NOT BETWEEN 901 AND 904) -- Bettrade
				AND (bettype NOT BETWEEN 911 AND 914) -- Cash Out
			)
			OR bettype BETWEEN 1301 AND 1334		
		) 
		AND (Sporttype <> 44) -- Muay Thai
	GROUP BY liveindicator, winlostdate

  	UNION ALL

	SELECT winlostdate,
	       CASE
	     	 WHEN bettype BETWEEN 31 AND 33 THEN 'Racing gross income'
			 WHEN bettype BETWEEN 81 AND 120 THEN 'Number Game'	
			 --WHEN bettype BETWEEN 1101 AND 1199 THEN 'Live Casino'
			 WHEN bettype IN (71, 72) OR bettype BETWEEN 2101 AND 2399 THEN 'Casino'
			 WHEN bettype = 10 THEN 'Outright'
			 WHEN bettype IN (9, 29) THEN 'Parlay'
			 WHEN bettype BETWEEN 1201 AND 1299 THEN 'Virtual Sports'
			 WHEN bettype BETWEEN 2700 AND 2899 THEN 'Betradar Virtual Sports'
			 WHEN bettype BETWEEN 1501 AND 1599 THEN 'Keno'
			 WHEN bettype BETWEEN 1800 AND 1899 THEN 'AG Casino'
			 WHEN bettype = 1900 THEN 'Macau'
			 WHEN bettype BETWEEN 1700 AND 1799 THEN 'Gold Deluxe'
			 WHEN bettype BETWEEN 801 AND 899 THEN 'Metric Gaming - Super Live'
			 WHEN bettype BETWEEN 2001 AND 2007 THEN 'Microgaming - Live Casino'
			 WHEN bettype BETWEEN 2008 AND 2009 THEN 'Microgaming - RNG Casino'
			 WHEN bettype BETWEEN 901 AND 904 THEN 'Bettrade'
			 WHEN bettype BETWEEN 18000 AND 18099 THEN 'Colossus Bets'
			 --WHEN bettype = 1003 THEN 'Cockfighting'
			 WHEN Sporttype = 44 THEN 'Muay Thai'
			 WHEN bettype BETWEEN 2401 AND 2499 THEN 'Allbet' 
			 WHEN bettype BETWEEN 4001 AND 7999 THEN 'Macau Games'
			 WHEN bettype BETWEEN 2501 AND 2699 THEN 'NG2'
			 WHEN bettype BETWEEN 1011 AND 1020 THEN 'Fishing World'
			 WHEN bettype BETWEEN 911 AND 914 THEN 'Cash Out'
			 WHEN bettype BETWEEN 1021 AND 1049 THEN 'Lottery'
		   END AS Product,
		   ISNULL(SUM(winlost), 0) as winlost
	 FROM #bettranstmp
	 WHERE (--bettype BETWEEN 1101 AND 1199
			--OR 
			bettype BETWEEN 31 AND 33
			OR bettype BETWEEN 80 AND 120
			OR bettype IN (71, 72, 73, 10,  9, 29) ---1000
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
			--OR bettype = 1003
			OR bettype BETWEEN 2101 AND 2399
			OR Sporttype = 44
			OR bettype BETWEEN 2401 AND 2499 
			OR bettype BETWEEN 4001 AND 7999
			OR bettype BETWEEN 2501 AND 2699
			OR bettype BETWEEN 1011 AND 1020
			OR bettype BETWEEN 911 AND 914
			OR bettype BETWEEN 1021 AND 1049
		   )
	GROUP BY CASE
	         WHEN bettype BETWEEN 31 AND 33 THEN 'Racing gross income'
			 WHEN bettype BETWEEN 81 AND 120 THEN 'Number Game'
			 --WHEN bettype BETWEEN 1101 AND 1199 THEN 'Live Casino'
			 WHEN bettype IN(71, 72) OR bettype BETWEEN 2101 AND 2399 THEN 'Casino'
			 WHEN bettype = 10 THEN 'Outright'
			 WHEN bettype IN (9, 29) THEN 'Parlay'
			 WHEN bettype BETWEEN 1201 AND 1299 THEN 'Virtual Sports'
			 WHEN bettype BETWEEN 2700 AND 2899 THEN 'Betradar Virtual Sports'
			 WHEN bettype BETWEEN 1501 AND 1599 THEN 'Keno'
			 WHEN bettype BETWEEN 1800 AND 1899 THEN 'AG Casino'
			 WHEN bettype = 1900 THEN 'Macau'
			 WHEN bettype BETWEEN 1700 AND 1799 THEN 'Gold Deluxe'
			 WHEN bettype BETWEEN 801 AND 899 THEN 'Metric Gaming - Super Live'
			 WHEN bettype BETWEEN 2001 AND 2007 THEN 'Microgaming - Live Casino'
			 WHEN bettype BETWEEN 2008 AND 2009 THEN 'Microgaming - RNG Casino'
			 WHEN bettype BETWEEN 901 AND 904 THEN 'Bettrade'
			 WHEN bettype BETWEEN 18000 AND 18099 THEN 'Colossus Bets'
			 --WHEN bettype = 1003 THEN 'Cockfighting'
			 WHEN Sporttype = 44 THEN 'Muay Thai'
			 WHEN bettype BETWEEN 2401 AND 2499 THEN 'Allbet' 
			 WHEN bettype BETWEEN 4001 AND 7999 THEN 'Macau Games'
			 WHEN bettype BETWEEN 2501 AND 2699 THEN 'NG2'
			 WHEN bettype BETWEEN 1011 AND 1020 THEN 'Fishing World'
			 WHEN bettype BETWEEN 911 AND 914 THEN 'Cash Out'
			 WHEN bettype BETWEEN 1021 AND 1049 THEN 'Lottery'
		   END, winlostdate

	UNION ALL

    SELECT winlostdate,
           'Total Balance',
           ISNULL(SUM(winlost), 0) winlost
    FROM #bettranstmp
    WHERE CustId = -1
		-----custid NOT IN (SELECT custid FROM @dummyBalance WHERE custid <> 0)	  
	GROUP BY winlostdate

	---------------------------------------------------

    ---- get Racing line total
	INSERT INTO @Winning(winlostdate, product, winlost)
	SELECT b.winlostdate,
	       'Racing',
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
	FROM dbo.bettrans b WITH(NOLOCK)
			INNER JOIN @CommSetting AS cs ON b.matchid = cs.matchid and b.winlostdate = cs.winlostdate
			LEFT JOIN (SELECT refno,
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
  			  FROM bettransm WITH(NOLOCK)
			  WHERE bettype IN (31,32,33)
		  GROUP BY refno
		   ) bm ON b.transid = bm.refno
	WHERE 1 = 1
	   AND b.ruben = 1
	   AND b.bettype in (31, 32, 33)
	   AND b.matchid > 0
	   AND b.statusid NOT IN (101, 102, 103, 121)
	   AND b.winlostdate between @fromdate and @todate
	GROUP BY b.winlostdate
	/*end calculating racing net income*/
	
	UPDATE w1
    SET w1.product = 'Racing (Due to Partners)',
		w1.winlost = w1.winlost - w2.winlost
	FROM @Winning w1
	INNER JOIN @Winning w2 on w1.winlostdate = w2.winlostdate
	WHERE w1.product = 'Racing gross income' 
	   and w2.product = 'Racing'

	---------------------------------------------------------------------------------------------------------
	--------------------------------------------Extra PT ---------------------------------------------------

	CREATE TABLE #ExtraPTWL
	(
	    winlostdate			smalldatetime, 
		ProductId			INT,
		ProductName			VARCHAR(50),
		ExtraPTwinlost		MONEY,
		NewExtraPTwinlost	MONEY
	)
	
	----Non sportsbook
	;WITH wl AS(
		SELECT b.winlostdate,
			   b.srecommend,	      
			   0 AS Sporttype,
			   s.ProductId,
			   '' AS SubProduct,
			   SUM((winlost - actual_stake) * actualrate) AS winlost,
			   SUM((CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END) * b.actualrate) AS newwinlost
		FROM dbo.bettrans b WITH(READPAST, INDEX = IX_Report)
		INNER JOIN @SportBettype s ON s.BetType = b.bettype
		WHERE  b.winlostdate between @fromdate and @todate
		   AND b.ruben = 1
		   AND b.statusid NOT IN (101, 102, 103, 121)
		   AND b.bettype < 19001	  
		   AND s.ProductID IN (SELECT DISTINCT ProductID FROM bodb_ACC.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE ProductID <> 1)
		GROUP BY b.winlostdate,
			   b.srecommend,	      
			   s.ProductId 
			   )

	INSERT INTO #ExtraPTWL (winlostdate, ProductId, ExtraPTwinlost, NewExtraPTwinlost) 
	SELECT	w.winlostdate, w.ProductId, SUM(w.winlost * s.ExtraPT), SUM(w.newwinlost * s.ExtraPT)
	FROM	wl w
	INNER JOIN bodb_Acc.dbo.Acc_GroupExtraPTSetting s WITH(NOLOCK)
			ON w.srecommend = s.SuperId
			AND w.ProductId = s.ProductId
			AND w.SubProduct = s.SubProduct
			AND w.Sporttype = s.Sporttype 
			AND w.winlostdate BETWEEN s.FromDate AND s.ToDate	
	GROUP BY w.winlostdate, w.Sporttype, w.ProductId, w.SubProduct


	UPDATE e 
	SET ProductName = CASE WHEN e.ProductId = 6 THEN 'Casino' ELSE p.ProductName END
	FROM #ExtraPTWL e
		INNER JOIN dbo.Products p WITH (NOLOCK)
		ON e.ProductId = p.ProductId


	----- SPL, SPNL, MuayThai, Metric gaming, Bettrade, Palay, outright
	;WITH wl AS(
		SELECT b.winlostdate,
			   b.srecommend,	      
			   CASE WHEN ISNULL(m.Sporttype, 0) <> 0	THEN m.Sporttype ELSE 0 END AS Sporttype,
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
			   SUM((CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END) * b.actualrate) AS newwinlost
		FROM dbo.bettrans b WITH(READPAST, INDEX = IX_Report)	
		INNER JOIN @SportBettype s ON s.BetType = b.bettype
		LEFT JOIN dbo.Match m WITH (NOLOCK) ON m.MatchId = b.MatchId AND m.eventdate = b.Winlostdate AND m.Sporttype = 44
		WHERE   b.winlostdate between @fromdate and @todate
			AND b.ruben = 1
			AND b.statusid NOT IN (101, 102, 103, 121)
			AND b.bettype < 19001 
			AND s.ProductID = 1 		
		GROUP BY b.winlostdate,
			   b.srecommend,
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

	INSERT INTO #ExtraPTWL (winlostdate, ProductId, ProductName, ExtraPTwinlost, NewExtraPTwinlost) 
	SELECT	w.winlostdate, w.ProductId, w.ProductName, SUM(w.winlost * s.ExtraPT), SUM(w.newwinlost * s.ExtraPT)
	FROM	wl w
	INNER JOIN bodb_Acc.dbo.Acc_GroupExtraPTSetting s WITH(NOLOCK)
			ON w.srecommend = s.SuperId
			AND w.ProductId = s.ProductId
			AND w.SubProduct = s.SubProduct
			AND w.Sporttype = s.Sporttype 
			AND w.winlostdate BETWEEN s.FromDate AND s.ToDate	
	GROUP BY w.winlostdate, w.ProductId, w.ProductName
	

	CREATE NONCLUSTERED INDEX #IX_ExtraPTWL ON #ExtraPTWL ( winlostdate, ProductName)
			
	---------------------------------------------------------------------------------------------------------

    --view report
    IF (@mode = 0)
    BEGIN
	    ----- calculate reset
	    ;WITH rs AS
	    (
		     SELECT dm.winlostdate,
		           dm.Product,
		           ISNULL(SUM(b.winlost), 0) AS reset
		     FROM #bettranstmp b
			 INNER JOIN @dummyBalance dm ON b.custid = dm.custid and b.winlostdate = dm.winlostdate
	 	     WHERE bettype > 20000
			 GROUP BY dm.winlostdate, dm.product
	    )
	    SELECT dm.winlostdate,
	           dm.product,
	           ROUND(ISNULL(w.winlost, 0), 2) AS winlost,
			   CASE dm.product
	             WHEN 'Total Balance' then 0 ELSE ROUND(ISNULL(w.winlost, 0), 2) - ROUND(ISNULL(CASE WHEN dm.winlostdate < @EffectedDate THEN e.ExtraPTwinlost ELSE e.NewExtraPTwinlost END, 0), 2) END AS WinlostAfterExtraPT,
	           CASE dm.product
	             WHEN 'Total Balance' then 0
	             ELSE ROUND(ISNULL(rs.reset, 0), 2)
	           END AS reset
	    FROM @Winning w
		FULL OUTER JOIN rs rs ON w.product = rs.product and w.winlostdate = rs.winlostdate
		RIGHT JOIN @dummyBalance dm ON dm.product = ISNULL(w.product, rs.product) and dm.winlostdate = w.winlostdate
		LEFT JOIN #ExtraPTWL e ON e.ProductName = dm.product and e.winlostdate = dm.winlostdate
		ORDER BY dm.winlostdate DESC, dm.seq ASC

	END
	--reset balance
	ELSE IF (@mode = 1)
	BEGIN
		;WITH rs AS
	    (
		    SELECT dm.winlostdate,
		           dm.Product,
		           ISNULL(SUM(b.winlost), 0) AS reset
		    FROM #bettranstmp b
				INNER JOIN @dummyBalance dm ON b.custid = dm.custid and b.winlostdate = dm.winlostdate
	 	    WHERE b.bettype > 20000
			GROUP BY dm.winlostdate, dm.product
	    )
        INSERT INTO @reset(winlostdate, product, winlost, WinlostAfterExtraPT, reset, latestreset, seq)
	    SELECT dm.winlostdate,
	           dm.product,
			   ROUND(ISNULL(w.winlost, 0), 2) AS winlost,
			   ROUND(ISNULL(w.winlost, 0), 2) - ROUND(ISNULL(CASE WHEN dm.winlostdate < @EffectedDate THEN e.ExtraPTwinlost ELSE e.NewExtraPTwinlost END, 0), 2) AS WinlostAfterExtraPT,
	           ROUND(ISNULL(rs.reset, 0), 2) AS reset,
	           CASE
	             WHEN  dm.Product IN ('Racing (Due to Partners)', 'Total Balance') THEN 0 
	             ELSE  -(ROUND(ISNULL(w.winlost, 0), 2) - ROUND(ISNULL(CASE WHEN dm.winlostdate < @EffectedDate THEN e.ExtraPTwinlost ELSE e.NewExtraPTwinlost END, 0), 2)) - ROUND(ISNULL(rs.reset, 0), 2)
	           END AS latestreset,
			   dm.seq
	     FROM @winning w	
		 FULL OUTER JOIN rs rs ON w.product = rs.product and w.winlostdate = rs.winlostdate
	     RIGHT JOIN @dummyBalance dm ON dm.product = ISNULL(w.product, rs.product) and dm.winlostdate = w.winlostdate
		 LEFT JOIN #ExtraPTWL e ON e.ProductName = dm.product and e.winlostdate = dm.winlostdate

        declare @variance     money = 0,
                @winlostdate  smalldatetime,
                @custid       int,
                @resetCount   tinyint = 0,
                @transDesc    varchar(300)= ''
                --@creator      int = 5838421,--dbaAdmin
                
        SELECT @seq = 1, @WinlostDate = @FromDate

		SELECT @maxseq = MAX(r.seq),              
               @resetCount = ISNULL(SUM(CASE
                                          WHEN -(ISNULL(r.WinlostAfterExtraPT, 0)) - ISNULL(r.reset, 0) <> 0 AND r.Product NOT IN ('Racing (Due to Partners)', 'Total Balance') THEN 1
                                          ELSE 0
                                        END), 0)
        FROM   @reset r
        WHERE  r.WinlostDate = @WinlostDate

        IF (@resetCount = 0)
        BEGIN
            SELECT @ErrMsg = 'No products need to reset winning!',
                   @ErrCode = 2

            RETURN
        END

        WHILE (@seq <= @maxseq)
        BEGIN
            SET @variance = 0

            SELECT @variance = r.latestreset,
                   @custid = d.custid
            FROM @reset r
				INNER JOIN @dummyBalance d on r.product = d.product AND r.WinlostDate = d.WinlostDate
            WHERE r.seq = @seq
				AND r.Product NOT IN ('Racing (Due to Partners)') 
				AND r.WinlostDate = @WinlostDate

            IF (@variance <> 0) 
            BEGIN
                SELECT @transDesc = 'DWL-' + CAST(@fromdate as varchar(30))
                                           + CAST(@custid as varchar(50)) + ':'
                                           + CAST(@variance as varchar(100))

                EXEC DBTXN.bodb02.dbo.Task_ResetWinning_Non3rdParty_Add
                    @winlostdate = @winlostdate,
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
      
        SELECT winlostdate,
               product,
			   winlost,
               WinlostAfterExtraPT, 
               reset + latestreset AS totalreset,
               latestreset
        FROM @reset
		ORDER BY seq
	END
	DROP TABLE #bettranstmp
    DROP TABLE #ExtraPTWL
END
GO