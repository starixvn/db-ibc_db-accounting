USE [bodb_Report]
GO
 
ALTER  PROCEDURE [dbo].[Acc_Rpt_WinlostSummary_Sporttype]
    @fromdate    DATETIME,
    @todate        DATETIME    
AS
    /*
        Created: Johnson
        Date: 2013-06-20
        Task: summary winlost by sporttype
        DB: DBRPT/bodb_Report
        
        Revisions:
            - 20130822@Johnson: change to use rptWinlost instead rptWinlost2
            - 20131206@Kathy: Add HR Fixed Odds (154) [Redmine:#6505]
			- 20140327@Dom: Add Keno
			- 20150525@Jim: apply sport& bettype matrix and also support GoldDeluxe & Metric Gaming (#35359 & #28309 )
			- 20150710@Jim: Super Balance fix and Microgaming integration (feature #38168 )
			- 20150723@Jim: Apply Bettrade [#38815]
			- 20150828@Jim: support Colossus Bet (#42608)
			- 20150921@Jim: support MO (#41935)
        Parameter's Explanation:
    */
BEGIN
	SET NOCOUNT ON
	----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT,SubProduct VARCHAR(500),SortKey TINYINT,liveindicator BIT)
	INSERT INTO @SportBettype (ProductID  , Bettype  ,EventType ,SubProduct )
	EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel    @mode=5
	UPDATE @SportBettype
	SET liveindicator =0
	
	INSERT INTO @SportBettype(ProductID,Bettype,EventType,SubProduct,liveindicator)
	SELECT ProductID
		 ,Bettype
		 ,EventType
		 ,SubProduct
		 ,1 AS liveindicator
	FROM @SportBettype
	WHERE liveindicator =0	
	
	UPDATE @SportBettype
	SET SortKey = CASE  WHEN Bettype =1   AND liveindicator =0   THEN 1
						WHEN Bettype =301 AND liveindicator =0   THEN 2
						WHEN Bettype =1   AND liveindicator =1   THEN 3
						WHEN Bettype =301 AND liveindicator =1   THEN 4
						WHEN Bettype =3   AND liveindicator =0   THEN 5
						WHEN Bettype =302 AND liveindicator =0   THEN 6
						WHEN Bettype =3   AND liveindicator =1   THEN 7
						WHEN Bettype =302 AND liveindicator =1   THEN 8
						WHEN Bettype =7   AND liveindicator =0   THEN 9
						WHEN Bettype =303 AND liveindicator =0   THEN 10
						WHEN Bettype =7   AND liveindicator =1   THEN 11
						WHEN Bettype =303 AND liveindicator =1   THEN 12
						WHEN Bettype =8   AND liveindicator =0   THEN 13
						WHEN Bettype =304 AND liveindicator =0   THEN 14
						WHEN Bettype =8   AND liveindicator =1   THEN 15
						WHEN Bettype =304 AND liveindicator =1   THEN 16
						ELSE 17
						END
	
	DECLARE @_fromdate    DATETIME,
			@_todate      DATETIME

	SELECT @_fromdate = @fromdate,
			@_todate = @todate

    CREATE TABLE #TempMatch (matchid int, matchcode varchar(50))
    CREATE TABLE #TempData (sporttype int, 
							bettype int, 
							liveindicator bit, 
							ibc int, 
							IsHedge bit, 
							status varchar(10),
							OrderKey tinyint,
							SortKey tinyint,
							realWinlost money, 
							realPosition money,
							realCommission money, 
							realLineTotal money, 
							virtualLineTotal money, 
							realTurnover money, 
							virtualTurnover money
							)

    DECLARE @movebetdate datetime,
			@balanceupdate datetime,
			@f_date datetime,
			@t_date datetime
    
        SELECT 
            TOP 1 @balanceupdate = winlostdate
        FROM bodb02.dbo.Bettrans WITH(NOLOCK)
        WHERE bettype = 20000 and matchid = 0 and custid = 3
    
        SELECT         
            @movebetdate = max(eventdate) 
        FROM  bodb02.dbo.match14 WITH(NOLOCK)
            
        IF @_todate > @movebetdate
        BEGIN
            IF @_fromdate < @movebetdate
                SELECT @f_date = @movebetdate
            ELSE
                SELECT @f_date = @_fromdate
            
            SELECT @t_date = @_todate
        
            INSERT INTO #TempMatch
            SELECT m.matchid,m.matchcode FROM bodb02.dbo.match(nolock) m WHERE m.eventdate BETWEEN @f_date AND @t_date
        END

        IF @_fromdate <=@movebetdate
        BEGIN
            IF @_todate < @movebetdate
                SELECT @t_date = @_todate
            ELSE
                SELECT @t_date = @movebetdate
            
            SELECT @f_date = @_fromdate

            INSERT INTO #TempMatch
            SELECT m.matchid,m.matchcode FROM bodb02.dbo.match14(nolock) m WHERE m.eventdate BETWEEN @f_date AND @t_date
        END
        IF @_fromdate <@balanceupdate
        BEGIN
            IF @_todate < @balanceupdate
                SELECT @t_date = @_todate
            ELSE
                SELECT @t_date = @balanceupdate - 1
            
            SELECT @f_date = @_fromdate

            INSERT INTO #TempMatch
            SELECT m.matchid,m.matchcode FROM bodb_archive.dbo.match_bk(nolock) m WHERE m.eventdate BETWEEN @f_date AND @t_date
        END

        INSERT INTO #TempData
        SELECT CASE s.SubProduct WHEN 'MG-SuperLive' THEN -1
								 WHEN 'BT-Comm' THEN -2
								 ELSE	b.sporttype
								 END sporttype
				,case when (b.bettype in (1,3,7,8,301,302,303,304) or (b.bettype between 801 and 899) or b.bettype IN (901,902,903)) then b.bettype else 19999 end 
					as bettypec
				,b.liveindicator
				,ibc
				, CASE WHEN m.matchcode LIKE '%Hedge%' THEN 1 ELSE 0 END IsHedge
				,'' status 
				,CASE s.SubProduct WHEN 'MG-SuperLive' THEN 2 
								   WHEN  'BT-Comm' THEN 15	
									ELSE 1 END AS OrderKey
				,s.SortKey					
				,ISNULL(SUM(realWinlost),0) as realWinlost
				,ISNULL(SUM(realPosition),0) as realPosition
				,ISNULL(SUM(realcommission),0) as realCommission
				,ISNULL(SUM(realLineTotal),0) as realLineTotal
				,ISNULL(SUM(virtualLineTotal),0) as virtualLineTotal
				,ISNULL(SUM(realTurnover),0) as realTurnover
				,ISNULL(SUM(virtualTurnover),0) as virtualTurnover
        FROM dbo.rptWinlost b WITH(NOLOCK)
			INNER JOIN #TempMatch m ON m.matchid = b.matchid
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype AND b.liveindicator=s.liveindicator
        WHERE b.winlostdate BETWEEN @_fromdate AND @_todate
           -- AND (sporttype BETWEEN 1 and 99 OR sporttype = 161)
		   AND ((s.ProductID = 1 AND s.SubProduct NOT IN ('BT-Sold','BT-Bought')) OR s.ProductID = 3) -- SB or NG
        GROUP BY CASE s.SubProduct WHEN 'MG-SuperLive' THEN -1 
								   WHEN 'BT-Comm' THEN -2
								   ELSE	b.sporttype END
				,case when (b.bettype in (1,3,7,8,301,302,303,304) or (b.bettype between 801 and 899)or b.bettype IN (901,902,903)) then b.bettype else 19999 end
				,b.liveindicator 
				,ibc
				,CASE WHEN b.bettype in (1,3,7,8) then b.bettype else 19999 end        
				,CASE WHEN m.matchcode LIKE '%Hedge%' THEN 1 ELSE 0 END
				,CASE s.SubProduct WHEN 'MG-SuperLive' THEN 2 
								    WHEN  'BT-Comm' THEN 15
									ELSE 1 END
				,s.SortKey						
    UNION ALL
        --Casino
        SELECT  251 as sporttype
				,b.bettype
				,0 as liveindicator
				,0 as ibc
				,0 as IsHedge
				,'' status
				,5 as OrderKey
				,17 as SortKey
				,ISNULL(SUM(realWinlost),0)
				,ISNULL(SUM(realPosition),0)
				,ISNULL(SUM(realCommission),0)
				,ISNULL(SUM(realLineTotal),0)
				,ISNULL(SUM(realLineTotal),0) as virtualLineTotal --copy data from actual value
				,0 as realTurnover
				,NULL as virtualTurnover
        FROM dbo.rptWinlost b WITH(NOLOCK)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype AND b.liveindicator=s.liveindicator
        WHERE b.winlostdate BETWEEN @_fromdate AND @_todate
            --AND bettype = 71
			AND s.ProductId=6
        GROUP BY b.bettype
    UNION ALL
        --Bingo
        SELECT 	252 as sporttype
				,b.bettype
				,0 as liveindicator
				,0 as ibc
				,0 as IsHedge
				,'' status
				,6 as OrderKey
				,17 as SortKey
				,ISNULL(SUM(realWinlost),0)
				,ISNULL(SUM(realPosition),0)
				,ISNULL(SUM(realCommission),0)
				,ISNULL(SUM(realLineTotal),0)
				,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
				,0 as realTurnover
				,NULL as virtualTurnover
        FROM dbo.rptWinlost b WITH(NOLOCK)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype AND b.liveindicator=s.liveindicator
        WHERE b.winlostdate BETWEEN @_fromdate AND @_todate
            --AND bettype = 73
			AND s.ProductId=7
        GROUP BY b.bettype
    UNION ALL
		SELECT 	202 sporttype
				,b.bettype
				,b.liveindicator
				,ibc
				,0 as IsHedge
				,'' status  
				,7 as OrderKey	
				,17 as SortKey
				,ISNULL(SUM(realWinlost),0) as realWinlost
				,ISNULL(SUM(realPosition),0) as realPosition
				,ISNULL(SUM(realcommission),0) as realCommission
				,ISNULL(SUM(realLineTotal),0) as realLineTotal
				,ISNULL(SUM(virtualLineTotal),0) as virtualLineTotal
				,ISNULL(SUM(realTurnover),0) as realTurnover
				,ISNULL(SUM(virtualTurnover),0) as virtualTurnover
        FROM dbo.rptWinlost b WITH(NOLOCK)
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype AND b.liveindicator=s.liveindicator
        WHERE b.winlostdate BETWEEN @_fromdate AND @_todate
            --and bettype BETWEEN 1501 AND 1599
			AND s.ProductId=8
        GROUP BY sporttype,b.liveindicator ,ibc
            ,b.bettype
    UNION ALL
        --Live casino
        SELECT  162 as sporttype
				,b.bettype
				,0 as liveindicator
				,0 as ibc
				,0 as IsHedge
				,'' status
				,8 as OrderKey
				,17 as SortKey
				,ISNULL(SUM(realWinlost),0)
				,ISNULL(SUM(realPosition),0) 
				,ISNULL(SUM(realCommission),0)
				,ISNULL(SUM(realLineTotal),0)
				,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
				,ISNULL(SUM(realTurnover),0)
				,ISNULL(SUM(realTurnover),0) as virtualTurnover
        FROM dbo.rptWinlost b WITH(NOLOCK)
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype AND b.liveindicator=s.liveindicator
        WHERE b.winlostdate BETWEEN @_fromdate AND @_todate
            --AND bettype between 1101 and 1199
			AND s.ProductId=4
        GROUP BY b.bettype
    UNION ALL
        SELECT  97 -- mix parlay
				,9 as bettype
				,0 as liveindicator
				,0 as ibc
				,0 as IsHedge
				,status
				,3 as OrderKey
				,17 as SortKey
				,ISNULL(SUM(realWinlost),0)
				,ISNULL(SUM(realPosition),0) 
				,ISNULL(SUM(realCommission),0)
				,ISNULL(SUM(realLineTotal),0)
				,ISNULL(SUM(virtualLineTotal),0)
				,ISNULL(SUM(realTurnover),0)
				,ISNULL(SUM(virtualTurnover),0)
        FROM dbo.rptWinlost b WITH(NOLOCK)
        WHERE b.winlostdate BETWEEN @_fromdate AND @_todate
            AND bettype = 9
        GROUP BY status
    UNION ALL
        SELECT  98 --system parlay
				,29 as bettype
				,0 as liveindicator
				,0 as ibc
				,0 as IsHedge
				,status
				,4 as OrderKey
				,17 as SortKey
				,ISNULL(SUM(realWinlost),0)
				,ISNULL(SUM(realPosition),0) 
				,ISNULL(SUM(realCommission),0)
				,ISNULL(SUM(realLineTotal),0)
				,ISNULL(SUM(virtualLineTotal),0)
				,ISNULL(SUM(realTurnover),0)
				,ISNULL(SUM(virtualTurnover),0)
        FROM dbo.rptWinlost b WITH(NOLOCK)
        WHERE b.winlostdate BETWEEN @_fromdate AND @_todate
            AND bettype = 29
        GROUP BY status
    UNION ALL
        --racing
        SELECT   sporttype
				,0 as bettype
				,0 as liveindicator
				,0 as ibc
				,0 as IsHedge
				,'' as status
				,13 as OrderKey
				,17 as SortKey
				,ISNULL(SUM(realWinlost),0)
				,ISNULL(SUM(realPosition),0) 
				,ISNULL(SUM(realCommission),0)
				,ISNULL(SUM(realLineTotal),0)
				,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
				,0 as realTurnover
				,0 as virtualTurnover
        FROM rptWinlost b WITH(NOLOCK)
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype AND b.liveindicator=s.liveindicator
        WHERE b.winlostdate BETWEEN @_fromdate AND @_todate
            --AND bettype BETWEEN 31 AND 33
			AND s.ProductId=2
        GROUP BY sporttype
    UNION ALL
        --virtual sports
        SELECT sporttype
            ,0 as bettype
            ,0 as liveindicator
            ,0 as ibc
            ,0 as IsHedge
            ,'' as status
			,14 as OrderKey
			,17 as SortKey
            ,ISNULL(SUM(realWinlost),0)
            ,ISNULL(SUM(realPosition),0) 
            ,ISNULL(SUM(realCommission),0)
            ,ISNULL(SUM(realLineTotal),0)
            ,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
            ,ISNULL(SUM(realTurnover),0)
            ,ISNULL(SUM(realTurnover),0) as virtualTurnover
        FROM rptWinlost b WITH(NOLOCK)
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype AND b.liveindicator=s.liveindicator
        WHERE winlostdate BETWEEN @_fromdate AND @_todate
            --AND bettype BETWEEN 1201 AND 1299
			AND s.ProductId=5
        GROUP BY sporttype

    UNION ALL
        -- HR Fixed Odds
        SELECT sporttype
            ,bettype
            ,b.liveindicator
            ,ibc
            ,0 as IsHedge
            ,'' status 
			,1 as OrderKey	
			,17 as SortKey
            ,ISNULL(SUM(realWinlost),0) as realWinlost
            ,ISNULL(SUM(realPosition),0) as realPosition
            ,ISNULL(SUM(realcommission),0) as realCommission
            ,ISNULL(SUM(realLineTotal),0) as realLineTotal
            ,ISNULL(SUM(virtualLineTotal),0) as virtualLineTotal
            ,ISNULL(SUM(realTurnover),0) as realTurnover
            ,ISNULL(SUM(virtualTurnover),0) as virtualTurnover
        FROM rptWinlost b WITH(NOLOCK)
		WHERE winlostdate BETWEEN @_fromdate AND @_todate
            AND sporttype = 154
        GROUP BY sporttype,bettype, b.liveindicator ,ibc
	--- GD	
     UNION ALL
        SELECT 255 sporttype
            ,b.bettype
            ,b.liveindicator
            ,ibc
            ,0 as IsHedge
            ,'' status 
			,9 as OrderKey	
			,17 as SortKey
            ,ISNULL(SUM(realWinlost),0) as realWinlost
            ,ISNULL(SUM(realPosition),0) as realPosition
            ,ISNULL(SUM(realcommission),0) as realCommission
            ,ISNULL(SUM(realLineTotal),0) as realLineTotal
            ,ISNULL(SUM(virtualLineTotal),0) as virtualLineTotal
            ,ISNULL(SUM(realTurnover),0) as realTurnover
            ,ISNULL(SUM(virtualTurnover),0) as virtualTurnover
        FROM rptWinlost b WITH(NOLOCK)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype AND b.liveindicator=s.liveindicator
		WHERE winlostdate BETWEEN @_fromdate AND @_todate
            AND s.ProductId=12
        GROUP BY sporttype,b.bettype, b.liveindicator ,ibc
	-- Micro Gaming
		UNION ALL
        SELECT 203 sporttype
            ,b.bettype
            ,b.liveindicator
            ,ibc
            ,0 as IsHedge
            ,'' status 
			,10 as OrderKey	
			,17 as SortKey
            ,ISNULL(SUM(realWinlost),0) as realWinlost
            ,ISNULL(SUM(realPosition),0) as realPosition
            ,ISNULL(SUM(realcommission),0) as realCommission
            ,ISNULL(SUM(realLineTotal),0) as realLineTotal
            ,ISNULL(SUM(virtualLineTotal),0) as virtualLineTotal
            ,ISNULL(SUM(realTurnover),0) as realTurnover
            ,ISNULL(SUM(virtualTurnover),0) as virtualTurnover
        FROM rptWinlost b WITH(NOLOCK)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype AND b.liveindicator=s.liveindicator
		WHERE winlostdate BETWEEN @_fromdate AND @_todate
            AND s.ProductId=13
        GROUP BY sporttype,b.bettype, b.liveindicator ,ibc
	--- AG Casino
		UNION ALL
        SELECT 250 sporttype
            ,b.bettype
            ,b.liveindicator
            ,ibc
            ,0 as IsHedge
            ,'' status 
			,11 as OrderKey	
			,17 as SortKey
            ,ISNULL(SUM(realWinlost),0) as realWinlost
            ,ISNULL(SUM(realPosition),0) as realPosition
            ,ISNULL(SUM(realcommission),0) as realCommission
            ,ISNULL(SUM(realLineTotal),0) as realLineTotal
            ,ISNULL(SUM(virtualLineTotal),0) as virtualLineTotal
            ,ISNULL(SUM(realTurnover),0) as realTurnover
            ,ISNULL(SUM(virtualTurnover),0) as virtualTurnover
        FROM rptWinlost b WITH(NOLOCK)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype AND b.liveindicator=s.liveindicator
		WHERE winlostdate BETWEEN @_fromdate AND @_todate
            AND s.ProductId=11
        GROUP BY sporttype,b.bettype, b.liveindicator ,ibc
	--	VegasGame aka Macau
		UNION ALL
        SELECT 249 sporttype
            ,b.bettype
            ,b.liveindicator
            ,ibc
            ,0 as IsHedge
            ,'' status 
			,12 as OrderKey	
			,17 as SortKey
            ,ISNULL(SUM(realWinlost),0) as realWinlost
            ,ISNULL(SUM(realPosition),0) as realPosition
            ,ISNULL(SUM(realcommission),0) as realCommission
            ,ISNULL(SUM(realLineTotal),0) as realLineTotal
            ,ISNULL(SUM(virtualLineTotal),0) as virtualLineTotal
            ,ISNULL(SUM(realTurnover),0) as realTurnover
            ,ISNULL(SUM(virtualTurnover),0) as virtualTurnover
        FROM rptWinlost b WITH(NOLOCK)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype AND b.liveindicator=s.liveindicator
		WHERE winlostdate BETWEEN @_fromdate AND @_todate
            AND s.ProductId=14
        GROUP BY sporttype,b.bettype, b.liveindicator ,ibc	
	--	ColossusBet
		UNION ALL
        SELECT 204 sporttype
            ,b.bettype
            ,b.liveindicator
            ,ibc
            ,0 as IsHedge
            ,'' status 
			,16 as OrderKey	
			,17 as SortKey
            ,ISNULL(SUM(realWinlost),0) as realWinlost
            ,ISNULL(SUM(realPosition),0) as realPosition
            ,ISNULL(SUM(realcommission),0) as realCommission
            ,ISNULL(SUM(realLineTotal),0) as realLineTotal
            ,ISNULL(SUM(virtualLineTotal),0) as virtualLineTotal
            ,ISNULL(SUM(realTurnover),0) as realTurnover
            ,ISNULL(SUM(virtualTurnover),0) as virtualTurnover
        FROM rptWinlost b WITH(NOLOCK)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype AND b.liveindicator=s.liveindicator
		WHERE winlostdate BETWEEN @_fromdate AND @_todate
            AND s.ProductId=15
        GROUP BY sporttype,b.bettype, b.liveindicator ,ibc			
	ORDER BY OrderKey ASC	
   -- ORDER BY 1,3 DESC,2,4,5
	
	UPDATE #TempData SET IsHedge =1,
						ibc = 0
	WHERE ibc = 1 AND IsHedge = 1
	
	SELECT sporttype,
           bettype,
           liveindicator,
           ibc,
           IsHedge,
           status,
           SUM(realWinlost) as realWinlost,
           SUM(realPosition) as realPosition, 
           SUM(realCommission) as realCommission,
           SUM(realLineTotal) as realLineTotal,
           SUM(virtualLineTotal) as virtualLineTotal,
           SUM(realTurnover) as realTurnover,
           SUM(virtualTurnover) as virtualTurnover 
	FROM #TempData
	GROUP BY sporttype,
           bettype,
           liveindicator,
           ibc,
           IsHedge,
           status,
           OrderKey
           ,SortKey
	ORDER BY OrderKey,SortKey, liveindicator
    DROP TABLE #TempMatch
	DROP TABLE #TempData
    --exec Acc_Rpt_WinlostSummary_Sporttype_xtest @fromdate='2014-07-24 00:00:00',@todate='2014-07-24 00:00:00'
END
GO 
 GRANT EXECUTE ON [dbo].[Acc_Rpt_WinlostSummary_Sporttype] TO [bodbAdminNet]
GO 