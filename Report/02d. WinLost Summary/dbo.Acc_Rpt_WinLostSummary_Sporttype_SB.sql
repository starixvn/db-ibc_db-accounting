  ALTER PROCEDURE [dbo].[Acc_Rpt_WinlostSummary_Sporttype_SB]
    @fromdate    DATETIME,
    @todate        DATETIME,
    @sporttype    INT = 0,
    @bettype    INT = 0,
    @liveindicator BIT = 0
 AS
    /*
        Created: Johnson
        Date: 2013-06-24
        Task: Get winlost summary details by match for sportbook
        DB: DBRPT/bodb_Report
        
        Revisions:
            - 20130822@Johnson: change to use rptWinlost instead rptWinlost2]
            - 20131204@Johnson: get @movebetday base on match14
			- 20140327@Dom: Add Hedge Field
        Parameter's Explanation:
    */
SET NOCOUNT ON
    
    Declare @RPT TABLE (eventdate datetime,
        matchid int, matchcode nvarchar(50) COLLATE SQL_Latin1_General_CP1_CS_AS,
        HomeId int, AwayId int,        
        liveindicator bit, bettype smallint, leagueid int,
        realWinLost money, realPosition money, realCommission money, realTurnover money, realLineTotal money,
        virtualTurnover money, virtualLineTotal money, isNeutral bit
    )
    
    Declare @movebetdate datetime,
            @f_date datetime,
            @t_date datetime
    
    SELECT @movebetdate = max(eventdate) from bodb02.dbo.match14 with(nolock)
        
    
    IF @todate > @movebetdate
    BEGIN
        IF @fromdate <= @movebetdate
            SELECT @f_date = @movebetdate + 1
        ELSE
            SELECT @f_date = @fromdate
            
        SELECT @t_date = @todate
        
        INSERT INTO @RPT(eventdate,
            matchid, matchcode, homeid, awayid, liveindicator, bettype, leagueid, 
            realWinlost, realPosition, realCommission, realTurnover, realLineTotal, virtualTurnover, virtualLineTotal, isNeutral
        )
        SELECT m.eventdate,
            b.matchid
            ,matchcode
            ,homeid
            ,awayid
            ,b.liveindicator
            ,b.bettype
            ,m.leagueid
            ,ISNULL(SUM(realWinlost),0) 
            ,ISNULL(SUM(realPosition),0)
            ,ISNULL(SUM(realCommission),0)
            ,ISNULL(SUM(realTurnover),0)
            ,ISNULL(SUM(realLineTotal),0)            
            ,ISNULL(SUM(virtualTurnover),0)
            ,ISNULL(SUM(virtualLineTotal),0)
            ,m.isNeutral            
        FROM rptWinlost b WITH(NOLOCK)
            INNER JOIN bodb02.dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
        WHERE winlostdate BETWEEN @f_date AND @t_date
            AND b.sporttype = @sporttype
            AND CASE WHEN @bettype = 0 THEN 1
                    WHEN @bettype = b.bettype THEN 1
                    WHEN @bettype = 19999 AND b.bettype NOT IN (1,3,7,8) THEN 1
                    ELSE 0 END = 1
            AND CASE WHEN @bettype = 0 THEN 1
                    WHEN liveindicator = @liveindicator THEN 1
                    ELSE 0 END = 1
        GROUP BY eventdate,b.matchid, matchcode, homeid, awayid, liveindicator, bettype, leagueid, isNeutral
        
        IF @bettype IN (0,19999) AND @sporttype <=99
        BEGIN
            INSERT INTO @RPT(eventdate,
                matchid, matchcode, homeid, awayid, liveindicator, bettype, leagueid, 
                realWinlost, realPosition, realCommission, realTurnover, realLineTotal, virtualTurnover, virtualLineTotal, isNeutral
            )
            SELECT m.eventdate,
                b.matchid
                ,m.matchcode
                ,m.teamid as homeid
                ,0 as awayid
                ,0 as liveindicator
                ,b.bettype
                ,m.leagueid
                ,ISNULL(SUM(realWinlost),0) 
                ,ISNULL(SUM(realPosition),0)
                ,ISNULL(SUM(realCommission),0)
                ,ISNULL(SUM(realTurnover),0)
                ,ISNULL(SUM(realLineTotal),0)            
                ,ISNULL(SUM(virtualTurnover),0)
                ,ISNULL(SUM(virtualLineTotal),0)
                ,CONVERT(BIT,0) as IsNeutral    
            FROM rptWinlost b WITH(NOLOCK)
                INNER JOIN bodb02.dbo.outright m WITH(NOLOCK) ON b.matchid = m.orid
            WHERE winlostdate BETWEEN @f_date AND @t_date
                AND b.sporttype = @sporttype
                AND b.bettype = 10
                AND CASE WHEN @bettype = 0 THEN 1
                    WHEN liveindicator = @liveindicator THEN 1
                    ELSE 0 END = 1
            GROUP BY eventdate,b.matchid, m.matchcode, m.teamid, b.bettype, m.leagueid    
        END            
    END
    
    IF @fromdate <= @movebetdate
    BEGIN
        IF @todate <= @movebetdate
            SELECT @t_date = @todate
        ELSE
            SELECT @t_date = @movebetdate
            
        SELECT @f_date = @fromdate
        
        INSERT INTO @RPT(eventdate,
            matchid, matchcode, homeid, awayid, liveindicator, bettype, leagueid, 
            realWinlost, realPosition, realCommission, realTurnover, realLineTotal, virtualTurnover, virtualLineTotal, isNeutral
        )
        SELECT m.eventdate,
            b.matchid
            ,matchcode
            ,homeid
            ,awayid
            ,b.liveindicator
            ,b.bettype
            ,m.leagueid
            ,ISNULL(SUM(realWinlost),0) 
            ,ISNULL(SUM(realPosition),0)
            ,ISNULL(SUM(realCommission),0)
            ,ISNULL(SUM(realTurnover),0)
            ,ISNULL(SUM(realLineTotal),0)            
            ,ISNULL(SUM(virtualTurnover),0)
            ,ISNULL(SUM(virtualLineTotal),0)
            ,m.isNeutral            
        FROM rptWinlost b WITH(NOLOCK)
            INNER JOIN bodb02.dbo.match14 m WITH(NOLOCK) ON b.matchid = m.matchid
        WHERE winlostdate BETWEEN @f_date AND @t_date
            AND b.sporttype = @sporttype
            AND CASE WHEN @bettype = 0 THEN 1
                    WHEN @bettype = b.bettype THEN 1
                    WHEN @bettype = 19999 AND b.bettype NOT IN (1,3,7,8) THEN 1
                    ELSE 0 END = 1
            AND CASE WHEN @bettype = 0 THEN 1
                    WHEN liveindicator = @liveindicator THEN 1
                    ELSE 0 END = 1
        GROUP BY eventdate,b.matchid, matchcode, homeid, awayid, liveindicator, bettype, leagueid, isNeutral
        
        IF @bettype IN (0,19999) AND @sporttype <=99
        BEGIN
            INSERT INTO @RPT(eventdate,
                matchid, matchcode, homeid, awayid, liveindicator, bettype, leagueid, 
                realWinlost, realPosition, realCommission, realTurnover, realLineTotal, virtualTurnover, virtualLineTotal, isNeutral
            )
            SELECT m.eventdate,
                b.matchid
                ,m.matchcode
                ,m.teamid as homeid
                ,0 as awayid
                ,0 as liveindicator
                ,b.bettype
                ,m.leagueid
                ,ISNULL(SUM(realWinlost),0) 
                ,ISNULL(SUM(realPosition),0)
                ,ISNULL(SUM(realCommission),0)
                ,ISNULL(SUM(realTurnover),0)
                ,ISNULL(SUM(realLineTotal),0)            
                ,ISNULL(SUM(virtualTurnover),0)
                ,ISNULL(SUM(virtualLineTotal),0)
                ,CONVERT(BIT,0) as IsNeutral    
            FROM rptWinlost b WITH(NOLOCK)
                INNER JOIN bodb02.dbo.outright14 m WITH(NOLOCK) ON b.matchid = m.orid
            WHERE winlostdate BETWEEN @f_date AND @t_date
                AND b.sporttype = @sporttype
                AND b.bettype = 10
                AND CASE WHEN @bettype = 0 THEN 1
                    WHEN liveindicator = @liveindicator THEN 1
                    ELSE 0 END = 1
            GROUP BY eventdate,b.matchid, m.matchcode, m.teamid, b.bettype, m.leagueid    
        END            
    END
    
        declare @HedgeMatch table(evendate datetime,matchid int,matchcode nvarchar(50),leagueid int ,homeid int ,awayid int)
        insert into @HedgeMatch
        select eventdate, matchid,matchcode,leagueid,HomeId,AwayId
        from @RPT where matchcode like '%hedge%'
    
        SELECT  CASE WHEN d.matchcode like '%hedge%' OR r.matchcode like '%hedge%' THEN ISNULL(d.matchcode,r.matchcode) END HedgeGroup,
            CASE WHEN r.matchcode like '%hedge%' THEN 1 ELSE 0 END IsHedge,    
            r.* FROM @RPT r
        OUTER APPLY (
            select * from @HedgeMatch h where h.leagueid = r.leagueid and h.homeid = r.HomeId and h.awayid = r.AwayId and h.evendate = r.eventdate and h.matchid <> r.matchid
        )D
        ORDER BY r.HomeId,
                r.AwayId,
                r.leagueid,
                r.matchcode,
                r.bettype

    /*
    SELECT * FROM @RPT
    ORDER BY
    liveindicator DESC,
    bettype, 
    leagueid,
    --leaguename,
    CASE WHEN matchcode LIKE '%EX%' THEN 1 ELSE 0 END, 
    matchcode, 
    Homeid--home    
    */

	

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinlostSummary_Sporttype_SB] TO [bodbAdminNet]