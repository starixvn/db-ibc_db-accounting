 ALTER PROCEDURE [dbo].[Acc_Rpt_WinlostSummary_Sporttype]
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
        Parameter's Explanation:
    */
SET NOCOUNT ON

    CREATE TABLE #TempMatch (matchid int, matchcode varchar(50))
    CREATE TABLE #TempData(sporttype int, 
							bettype int, 
							liveindicator bit, 
							ibc int, 
							IsHedge bit, 
							status varchar(10),
							realWinlost money, 
							realPosition money,
							realCommission money, 
							realLineTotal money, 
							virtualLineTotal money, 
							realTurnover money, 
							virtualTurnover money)

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
            
        IF @todate >= @movebetdate
        BEGIN
            IF @fromdate < @movebetdate
                SELECT @f_date = @movebetdate
            ELSE
                SELECT @f_date = @fromdate
            
            SELECT @t_date = @todate
        
            INSERT INTO #TempMatch
            SELECT m.matchid,m.matchcode FROM bodb02.dbo.match(nolock) m WHERE m.eventdate BETWEEN @f_date AND @t_date
        END

        IF @fromdate <@movebetdate
        BEGIN
            IF @todate < @movebetdate
                SELECT @t_date = @todate
            ELSE
                SELECT @t_date = @movebetdate
            
            SELECT @f_date = @fromdate

            INSERT INTO #TempMatch
            SELECT m.matchid,m.matchcode FROM bodb02.dbo.match14(nolock) m WHERE m.eventdate BETWEEN @f_date AND @t_date
        END
        IF @fromdate <@balanceupdate
        BEGIN
            IF @todate < @balanceupdate
                SELECT @t_date = @todate
            ELSE
                SELECT @t_date = @balanceupdate - 1
            
            SELECT @f_date = @fromdate

            INSERT INTO #TempMatch
            SELECT m.matchid,m.matchcode FROM bodb_archive.dbo.match_bk(nolock) m WHERE m.eventdate BETWEEN @f_date AND @t_date
        END

        INSERT INTO #TempData
        SELECT sporttype
            ,case when bettype in (1,3,7,8) then bettype else 19999 end as bettype
            ,liveindicator
            ,ibc
            , CASE WHEN m.matchcode LIKE '%Hedge%' THEN 1 ELSE 0 END IsHedge
            ,'' status        
            ,ISNULL(SUM(realWinlost),0) as realWinlost
            ,ISNULL(SUM(realPosition),0) as realPosition
            ,ISNULL(SUM(realcommission),0) as realCommission
            ,ISNULL(SUM(realLineTotal),0) as realLineTotal
            ,ISNULL(SUM(virtualLineTotal),0) as virtualLineTotal
            ,ISNULL(SUM(realTurnover),0) as realTurnover
            ,ISNULL(SUM(virtualTurnover),0) as virtualTurnover
        FROM rptWinlost b WITH(NOLOCK)
        LEFT JOIN #TempMatch m ON m.matchid = b.matchid
        WHERE winlostdate BETWEEN @fromdate AND @todate
            AND (sporttype BETWEEN 1 and 99 OR sporttype = 161)
        GROUP BY sporttype,liveindicator ,ibc
            ,case when bettype in (1,3,7,8) then bettype else 19999 end        
            , CASE WHEN m.matchcode LIKE '%Hedge%' THEN 1 ELSE 0 END
    UNION ALL
        --Casino
        SELECT 251 as sporttype
            ,bettype
            ,0 as liveindicator
            ,0 as ibc
            ,0 as IsHedge
            ,'' status
            ,ISNULL(SUM(realWinlost),0)
            ,ISNULL(SUM(realPosition),0)
            ,ISNULL(SUM(realCommission),0)
            ,ISNULL(SUM(realLineTotal),0)
            ,ISNULL(SUM(realLineTotal),0) as virtualLineTotal --copy data from actual value
            ,0 as realTurnover
            ,NULL as virtualTurnover
        FROM rptWinlost WITH(NOLOCK)
        WHERE winlostdate BETWEEN @fromdate AND @todate
            AND bettype = 71
        GROUP BY bettype
    UNION ALL
        --Bingo
        SELECT 252 as sporttype
            ,bettype
            ,0 as liveindicator
            ,0 as ibc
            ,0 as IsHedge
            ,'' status
            ,ISNULL(SUM(realWinlost),0)
            ,ISNULL(SUM(realPosition),0)
            ,ISNULL(SUM(realCommission),0)
            ,ISNULL(SUM(realLineTotal),0)
            ,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
            ,0 as realTurnover
            ,NULL as virtualTurnover
        FROM rptWinlost WITH(NOLOCK)
        WHERE winlostdate BETWEEN @fromdate AND @todate
            AND bettype = 73
        GROUP BY bettype
    UNION ALL
    SELECT 202 sporttype
            ,bettype
            ,liveindicator
            ,ibc
            ,0 as IsHedge
            ,'' status        
            ,ISNULL(SUM(realWinlost),0) as realWinlost
            ,ISNULL(SUM(realPosition),0) as realPosition
            ,ISNULL(SUM(realcommission),0) as realCommission
            ,ISNULL(SUM(realLineTotal),0) as realLineTotal
            ,ISNULL(SUM(virtualLineTotal),0) as virtualLineTotal
            ,ISNULL(SUM(realTurnover),0) as realTurnover
            ,ISNULL(SUM(virtualTurnover),0) as virtualTurnover
        FROM rptWinlost WITH(NOLOCK)
        WHERE winlostdate BETWEEN @fromdate AND @todate
            and bettype BETWEEN 1501 AND 1599
        GROUP BY sporttype,liveindicator ,ibc
            ,bettype
    UNION ALL
        --Live casino
        SELECT 162 as sporttype
            ,bettype
            ,0 as liveindicator
            ,0 as ibc
            ,0 as IsHedge
            ,'' status
            ,ISNULL(SUM(realWinlost),0)
            ,ISNULL(SUM(realPosition),0) 
            ,ISNULL(SUM(realCommission),0)
            ,ISNULL(SUM(realLineTotal),0)
            ,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
            ,ISNULL(SUM(realTurnover),0)
            ,ISNULL(SUM(realTurnover),0) as virtualTurnover
        FROM rptWinlost WITH(NOLOCK)
        WHERE winlostdate BETWEEN @fromdate AND @todate
            AND bettype between 1101 and 1199
        GROUP BY bettype
    UNION ALL
        SELECT 97 -- mix parlay
            ,9 as bettype
            ,0 as liveindicator
            ,0 as ibc
            ,0 as IsHedge
            ,status
            ,ISNULL(SUM(realWinlost),0)
            ,ISNULL(SUM(realPosition),0) 
            ,ISNULL(SUM(realCommission),0)
            ,ISNULL(SUM(realLineTotal),0)
            ,ISNULL(SUM(virtualLineTotal),0)
            ,ISNULL(SUM(realTurnover),0)
            ,ISNULL(SUM(virtualTurnover),0)
        FROM rptWinlost WITH(NOLOCK)
        WHERE winlostdate BETWEEN @fromdate AND @todate
            AND bettype = 9
        GROUP BY status
    UNION ALL
        SELECT 98 --system parlay
            ,29 as bettype
            ,0 as liveindicator
            ,0 as ibc
            ,0 as IsHedge
            ,status
            ,ISNULL(SUM(realWinlost),0)
            ,ISNULL(SUM(realPosition),0) 
            ,ISNULL(SUM(realCommission),0)
            ,ISNULL(SUM(realLineTotal),0)
            ,ISNULL(SUM(virtualLineTotal),0)
            ,ISNULL(SUM(realTurnover),0)
            ,ISNULL(SUM(virtualTurnover),0)
        FROM rptWinlost WITH(NOLOCK)
        WHERE winlostdate BETWEEN @fromdate AND @todate
            AND bettype = 29
        GROUP BY status
    UNION ALL
        --racing
        SELECT sporttype
            ,0 as bettype
            ,0 as liveindicator
            ,0 as ibc
            ,0 as IsHedge
            ,'' as status
            ,ISNULL(SUM(realWinlost),0)
            ,ISNULL(SUM(realPosition),0) 
            ,ISNULL(SUM(realCommission),0)
            ,ISNULL(SUM(realLineTotal),0)
            ,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
            , 0 as realTurnover
            ,0 as virtualTurnover
        FROM rptWinlost WITH(NOLOCK)
        WHERE winlostdate BETWEEN @fromdate AND @todate
            AND bettype BETWEEN 31 AND 33
        GROUP BY sporttype
    UNION ALL
        --virtual sports
        SELECT sporttype
            ,0 as bettype
            ,0 as liveindicator
            ,0 as ibc
            ,0 as IsHedge
            ,'' as status
            ,ISNULL(SUM(realWinlost),0)
            ,ISNULL(SUM(realPosition),0) 
            ,ISNULL(SUM(realCommission),0)
            ,ISNULL(SUM(realLineTotal),0)
            ,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
            ,ISNULL(SUM(realTurnover),0)
            ,ISNULL(SUM(realTurnover),0) as virtualTurnover
        FROM rptWinlost WITH(NOLOCK)
        WHERE winlostdate BETWEEN @fromdate AND @todate
            AND bettype BETWEEN 1201 AND 1299
        GROUP BY sporttype

    UNION ALL
        -- HR Fixed Odds
        SELECT sporttype
            ,bettype
            ,liveindicator
            ,ibc
            ,0 as IsHedge
            ,'' status        
            ,ISNULL(SUM(realWinlost),0) as realWinlost
            ,ISNULL(SUM(realPosition),0) as realPosition
            ,ISNULL(SUM(realcommission),0) as realCommission
            ,ISNULL(SUM(realLineTotal),0) as realLineTotal
            ,ISNULL(SUM(virtualLineTotal),0) as virtualLineTotal
            ,ISNULL(SUM(realTurnover),0) as realTurnover
            ,ISNULL(SUM(virtualTurnover),0) as virtualTurnover
        FROM rptWinlost WITH(NOLOCK)
        WHERE winlostdate BETWEEN @fromdate AND @todate
            AND sporttype = 154
        GROUP BY sporttype,bettype, liveindicator ,ibc
                
    ORDER BY 1,3 DESC,2,4,5

    SELECT * from #TempData

    DROP TABLE #TempMatch
    --exec Acc_Rpt_WinlostSummary_Sporttype @fromdate='2014-03-11 00:00:00',@todate='2014-03-11 00:00:00'
	
	
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinlostSummary_Sporttype] TO [bodbAdminNet]