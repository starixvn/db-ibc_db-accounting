/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Task_ResetWinning_CS_ExtraPT]
	@fromdate SMALLDATETIME,
	@todate   SMALLDATETIME,
	@mode     TINYINT = 0,
	@creator  INT = 5838421,
	@ip       VARCHAR(20) = '',
	@ErrCode  INT = 0 output,
    @ErrMsg   VARCHAR(100) = '' output
AS
/*
	Creator: 20190826@Sophia 
	Remark: Daily Auto transfer for CN88 Headline (reset winning Extra PT for CN88) 
	DB: DBACC.bodb02

	Revisions:
		- 20190826@Sophia: initial SP [Redmine: #117863]
	 

	Param's explain:
		@mode:  0 _ view report
	            1 _ reset balance
	          
	    @ErrCode: 0 _ Success
	              1 _ Error
	              2 _ Already resets

	 
*/
BEGIN
	SET NOCOUNT ON

	--DECLARE @DummyExtraPT TABLE (SuperId INT, GroupID TINYINT, GroupName VARCHAR(50), Winlostdate SMALLDATETIME)
	CREATE TABLE #Headline(SuperID INT, UplineID INT, Winlostdate SMALLDATETIME)
	
	--CREATE TABLE #winning (ProductID TINYINT, Sporttype INT, SubProduct VARCHAR(500), Winlost MONEY, NewWinlost MONEY, Winlostdate SMALLDATETIME, GroupId TINYINT)
	
	CREATE TABLE #Transfer TABLE (UplineId INT, Reset MONEY, RealReset MONEY, Winlostdate SMALLDATETIME )
	
	--DECLARE @reset TABLE (CustID INT, Winlost MONEY, [Reset] MONEY, Variance MONEY, Winlostdate SMALLDATETIME, GroupID TINYINT, GroupName VARCHAR(50))
	

	DECLARE @wldate SMALLDATETIME = @todate
	DECLARE @Date TABLE (WLDate SMALLDATETIME)

	WHILE @wldate >= @fromdate
	BEGIN
		INSERT INTO @Date (WLDate)
		SELECT @wldate

		SELECT @wldate = DATEADD(DAY, -1, @wldate)
	END
	
	----Begin: Get Sport Bettype Matrix------
	-- Check SP Version
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	SELECT ProductID, Bettype, SubProduct FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)

	DELETE @SportBettype WHERE ProductId NOT IN (SELECT DISTINCT ProductID FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK))

	-----End: Get Sport Bettype Matrix------
	
	
	/*
	----Begin: Get DummyExtraPT ----
	DECLARE @SQL NVARCHAR(100) = ISNULL(OBJECT_NAME(@@PROCID),'')	
	SELECT @Istest = CASE WHEN @SQL like '%_xtest%' THEN 1 ELSE 0 END
	
	IF @Istest = 0
	BEGIN
		INSERT INTO @DummyExtraPT (SuperId, GroupID, GroupName, Winlostdate)	
		SELECT  DISTINCT e.CustID as SuperId, e.GroupID, e.GroupName, d.WLDate
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT_xtest e WITH (NOLOCK)
		CROSS JOIN @Date d
	END
	ELSE
	BEGIN
		INSERT INTO @DummyExtraPT (SuperId, GroupID, GroupName, Winlostdate)	
		SELECT  DISTINCT e.CustID as SuperId, e.GroupID, e.GroupName, d.WLDate
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT e WITH (NOLOCK)
		CROSS JOIN @Date d
	END
	----End: Get DummyExtraPT ----
	*/
	
	----Begin: Get Headline List ----
	
	INSERT INTO #Headline (SuperId, UplineId, Winlostdate) 
	SELECT c.CustID AS SuperId, c.UplineId, d.WLDate as Winlostdate
	FROM dbo.CustSuper c WITH (NOLOCK) 
		CROSS JOIN @Date d
	WHERE UplineID IS NOT NULL
		 	
	
	----End: Get Headline List ----
	
	
	--- Begin: Last reset	
	
	INSERT INTO #Transfer (Headline, RealReset, Reset, Winlostdate)
	SELECT b.custid as Headline, ROUND(SUM(b.winlost- b.actual_stake), 2) AS Reset, ROUND(SUM((b.winlost- b.actual_stake))* actual_stake, 2) AS Reset, b.winlostdate 
	FROM dbo.bettrans b WITH(NOLOCK) 	
	WHERE b.bettype = 21007
		AND b.winlostdate BETWEEN @fromdate AND @todate
		AND EXISTS (SELECT 1 FROM #Headline h WHERE h.Headline = b.CustID)
	GROUP BY b.custid, b.winlostdate 	
	--- End: Last reset


	
	-----Begin : Get Winlost on ticket ----------------
	 
	--------------------------------------------Extra PT ---------------------------------------------------
	CREATE TABLE #wl 
	(	winlostdate 	SMALLDATETIME, 
		srecommend 		INT, 		
		Sporttype  		SMALLINT, 
		ProductId		INT, 
		ProductName		VARCHAR(250), 
		SubProduct		VARCHAR(250), 
		CommForExtraPT	MONEY,
		WinlostForExtraPT MONEY,
		RealCommForExtraPT	MONEY,
		RealWinlostForExtraPT MONEY
	)
	
	CREATE TABLE #WLByProduct
	(
	    winlostdate			SMALLDATETIME, 
		ProductId			INT,
		ProductName			VARCHAR(250),
		SubProduct			VARCHAR(250),
		UplineId			INT,		
		ExtraPTWinlost		MONEY,		
		RealExtraPTWinlost	MONEY
	) 
	 
		INSERT INTO #wl (winlostdate, srecommend, Sporttype, ProductId, ProductName, SubProduct, 
						CommForExtraPT, WinlostForExtraPT, RealCommForExtraPT, RealWinlostForExtraPT)
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
				---Base currency			
				0 AS CommForExtraPT,
				
				SUM((
					CASE
						-- Jackpot
						WHEN b.bettype IN (2198, 2398, 2998) THEN
							CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
						WHEN b.bettype IN (2199, 2399, 2999) THEN 0
						ELSE
							CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END
						END) * b.actualrate
					) AS WinlostForExtraPT,				
				---Real currency				
				0 AS RealCommForExtraPT,
				SUM(
					CASE
						-- Jackpot
						WHEN b.bettype IN (2198, 2398, 2998) THEN
							CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
						WHEN b.bettype IN (2199, 2399, 2999) THEN 0
						ELSE
							CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END
						END
					) AS RealWinlostForExtraPT				
				
		FROM dbo.bettrans b WITH (NOLOCK)			
		INNER JOIN @SportBettype s ON s.BetType = b.bettype
		LEFT JOIN dbo.Match m WITH (NOLOCK) ON m.MatchId = b.MatchId  AND m.Sporttype = 44		
		WHERE   b.Winlostdate between @fromdate and @todate
			AND b.ruben = 1
			AND b.statusid NOT IN (101, 102, 103, 121)		
			AND b.Currency <> 20 
			AND EXISTS (SELECT 1 FROM dbo.CS_CustSuper cs WITH (NOLOCK) WHERE cs.CusTID = b.srecommend) 
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
				 

	INSERT INTO #WLByProduct (Winlostdate, ProductId, ProductName, UplineID, ExtraPTWinlost, RealExtraPTWinlost) 
	SELECT Winlostdate, ProductId, ProductName, UplineID, SUM(ExtraPTWinlost), SUM(RealExtraPTWinlost)
	FROM (		
			--- extraPT
			SELECT  w.Winlostdate, w.ProductId, w.ProductName, 				
					cs.UplineID,
				   SUM(w.WinlostForExtraPT * ISNULL(s.ExtraPT,0)) as ExtraPTWinlost,				
				   SUM(w.RealWinlostForExtraPT * ISNULL(s.ExtraPT,0)) as RealExtraPTWinlost  
			FROM	#wl w
			INNER JOIN dbo.Acc_GroupExtraPTSetting s WITH(NOLOCK)
					ON w.srecommend = s.SuperId
					AND w.ProductId = s.ProductId
					AND w.SubProduct = s.SubProduct
					AND w.Sporttype = s.Sporttype 
					AND w.Winlostdate BETWEEN s.FromDate AND s.ToDate	
			INNER JOIN dbo.CustSuper cs WITH (NOLOCK) 
					ON cs.CustId = w.srecommend AND cs.UplineID IS NOT NULL
			GROUP BY w.Winlostdate, w.ProductId, w.ProductName, cs.UplineID
			
		 
			--- extraComm	
			UNION ALL 
			SELECT	w.Winlostdate, w.ProductId, w.ProductName, 
					cs.UplineID,
					SUM(w.CommForExtraPT * ISNULL(s.ExtraCommRate,0)) as ExtraPTWinlost,
					SUM(w.RealCommForExtraPT * ISNULL(s.ExtraCommRate,0)) as RealExtraPTWinlost   --- ExtraComm if any
			FROM	#wl w
			INNER JOIN dbo.Acc_GroupExtraCommRateSetting s WITH (NOLOCK)
					ON w.srecommend = s.SuperId
					AND w.ProductId = s.ProductId
					AND w.SubProduct = s.SubProduct
					AND w.Sporttype = s.Sporttype 
					AND w.Winlostdate BETWEEN s.FromDate AND s.ToDate
			INNER JOIN dbo.CustSuper cs WITH (NOLOCK) 
					ON cs.CustId = w.srecommend AND cs.UplineID IS NOT NULL
			GROUP BY w.Winlostdate, w.ProductId, w.ProductName,
					 cs.UplineID		
	
		) w
	GROUP BY w.Winlostdate, w.ProductId, w.ProductName, cs.UplineID	
	
	
	----view report
    IF (@mode = 0)
    BEGIN 
	    ----- calculate reset 
		SELECT  h.Winlostdate, h.UplineID,
				ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2) AS ExtraPTWinlost,
				ROUND(SUM(ISNULL(e.RealExtraPTWinlost, 0)), 2) AS RealExtraPTWinlost,
				ROUND(SUM(ISNULL(rs.Reset, 0)), 2) AS Reset,
				ROUND(SUM(ISNULL(rs.RealReset, 0)), 2) AS RealReset
		FROM #Headline h
			LEFT JOIN #WLByProduct e ON h.Winlostdate = e.Winlostdate AND h.UplineID = e.UplineID
			LEFT JOIN #Transfer rs ON h.Winlostdate = rs.Winlostdate AND h.UplineID = rs.UplineID
		GROUP BY h.Winlostdate, h.UplineID  
  
	END
	
	ELSE ----- reset
    BEGIN 
	    ----- calculate reset 
		SELECT  h.Winlostdate, h.UplineID,
				ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2) AS ExtraPTWinlost,
				ROUND(SUM(ISNULL(e.RealExtraPTWinlost, 0)), 2) AS RealExtraPTWinlost,
				ROUND(SUM(ISNULL(rs.Reset, 0)), 2) AS Reset,
				ROUND(SUM(ISNULL(rs.RealReset, 0)), 2) AS RealReset
		FROM #Headline h
			LEFT JOIN #WLByProduct e ON h.Winlostdate = e.Winlostdate AND h.UplineID = e.UplineID
			LEFT JOIN #Transfer rs ON h.Winlostdate = rs.Winlostdate AND h.UplineID = rs.UplineID
		GROUP BY h.Winlostdate, h.UplineID  
  
	END
	
	-----------------------------------------------
	
	ELSE  -- reset
	BEGIN
		
		;WITH WL AS ( 	
			SELECT  GroupID,
					SUM(Winlost) AS Winlost,
					SUM(NewWinlost) AS NewWinlost,
					Winlostdate
			FROM #winning 
			GROUP BY GroupID, Winlostdate
		)
		SELECT DM.GroupId, DM.GroupName, ROUND(ISNULL(CASE WHEN DM.Winlostdate < @EffectedDate THEN W.Winlost ELSE W.NewWinlost END, 0), 2) AS Winlost, ROUND(ISNULL(W.[Reset],0), 2) AS [Reset], DM.Winlostdate
		FROM @DummyExtraPT AS DM
		LEFT JOIN (
			SELECT  ISNULL(w.GroupId, rs.GroupID) AS GroupID,
					ROUND(SUM(ISNULL(w.Winlost, 0)), 2) AS Winlost,
					ROUND(SUM(ISNULL(w.NewWinlost, 0)), 2) AS NewWinlost,
					ROUND(SUM(ISNULL(rs.[Reset], 0)), 2) AS [Reset],
					ISNULL(w.Winlostdate, rs.Winlostdate) AS Winlostdate
			FROM WL w
			FULL OUTER JOIN #Transfer rs
				ON w.GroupId = rs.GroupID AND w.Winlostdate = rs.Winlostdate
			GROUP BY ISNULL(w.GroupId, rs.GroupID), ISNULL(w.Winlostdate, rs.Winlostdate)
		) AS W
			ON DM.GroupID = W.GroupID AND DM.Winlostdate = W.Winlostdate
		ORDER BY DM.Winlostdate DESC, DM.GroupID ASC		

	END
	ELSE IF @mode = 1 -- reset
	BEGIN
		;WITH WL AS ( 	
			SELECT  GroupID,
					SUM(Winlost) AS Winlost,
					SUM(NewWinlost) AS NewWinlost,
					Winlostdate
			FROM #winning 
			GROUP BY GroupID, Winlostdate
		)
		INSERT INTO @reset (CustID, Winlost, [Reset], Variance, Winlostdate, GroupID, GroupName)
		SELECT DM.CustID,
				ROUND(ISNULL(CASE WHEN DM.Winlostdate < @EffectedDate THEN W.Winlost ELSE W.NewWinlost END, 0), 2) AS Winlost,
				ROUND(ISNULL(W.[Reset],0), 2) AS [Reset], ROUND(ISNULL(CASE WHEN DM.Winlostdate < @EffectedDate THEN W.Variance ELSE W.NewVariance END, 0), 2) as Variance,
			DM.Winlostdate, DM.GroupID, DM.GroupName
		FROM @DummyExtraPT DM
		LEFT JOIN (
			SELECT  ROUND(SUM(ISNULL(w.Winlost, 0)), 2) AS Winlost,
					ROUND(SUM(ISNULL(w.NewWinlost, 0)), 2) AS NewWinlost,
					ROUND(SUM(ISNULL(rs.[Reset], 0)), 2) AS [Reset],
					ROUND(SUM(-ISNULL(w.Winlost, 0)), 2) - ROUND(SUM(ISNULL(rs.[Reset], 0)), 2) AS Variance,
					ROUND(SUM(-ISNULL(w.NewWinlost, 0)), 2) - ROUND(SUM(ISNULL(rs.[Reset], 0)), 2) AS NewVariance,
					ISNULL(w.Winlostdate, rs.winlostdate) AS Winlostdate,
					ISNULL(w.GroupId, rs.GroupID) AS GroupID
			FROM WL w
			FULL OUTER JOIN #Transfer rs
				ON w.GroupId = rs.GroupID AND w.Winlostdate = rs.Winlostdate
			GROUP BY ISNULL(w.GroupId, rs.GroupID), ISNULL(w.Winlostdate, rs.Winlostdate)
		) AS W
		ON DM.GroupID = W.GroupID AND DM.Winlostdate = W.Winlostdate

 
		DECLARE @variance     MONEY = 0,
                @winlostdate  SMALLDATETIME,
                @custid       INT,
                @resetCount   TINYINT = 0,
                @transDesc    NVARCHAR(1000)= '',
				@seq		  TINYINT = 1,
				@maxseq		  TINYINT
                
        SELECT @winlostdate = @fromdate

		SELECT
			@maxseq = MAX(GroupID),
			@resetCount = ISNULL(SUM(CASE WHEN Variance <> 0 THEN 1 ELSE 0 END), 0)
        FROM   @reset
        WHERE  WinlostDate = @WinlostDate

        IF (@resetCount = 0)
        BEGIN
            SELECT @ErrMsg = 'No codes need to reset winning!',
                   @ErrCode = 2
            RETURN
        END

        WHILE (@seq <= @maxseq)
        BEGIN
            SET @variance = 0

            SELECT @variance = Variance,
                   @custid = CustID
            FROM @reset
            WHERE GroupID = @seq
				AND WinlostDate = @WinlostDate
				 

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
					@isExtraPT = 1,
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
      
        SELECT GroupID,
			   GroupName,
			   winlostdate,
               ISNULL(SUM(winlost), 0) AS winlost,
               ISNULL(SUM([reset]), 0) + ISNULL(SUM(Variance), 0) AS totalreset,
               ISNULL(SUM(Variance), 0) AS latestreset
        FROM @reset
		GROUP BY GroupID, GroupName, winlostdate
		ORDER BY winlostdate DESC, GroupID ASC
	END

	DROP TABLE #winning
END
GO