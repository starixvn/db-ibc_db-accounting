
ALTER PROCEDURE  [dbo].[Acc_AllStatement_UsersList]
    @userlist VARCHAR(6000),
    @fromdate DATETIME,
    @todate DATETIME,
    @BalanceUpDay DATETIME
 AS
 
 /*
    Created by: KhoaTran
    Date: 20100203
    Task: Get Statement report by users list
    DB: DB06.BODB02
   
    Revisions:     
		- 20100602@Khoa: put accounts' currency to the temp table #TEMP_USER_LIST 
		- 20101224@Lukas: Re-arrange bettype
       
 */
SET NOCOUNT ON

    DECLARE @TEMP TABLE (username VARCHAR(50))
    CREATE TABLE #TEMP_USER_LIST (custid INT PRIMARY KEY, username VARCHAR(50), roleid INT, currency INT )

    INSERT INTO @TEMP (username)
    SELECT  val AS username
    FROM dbo.strSplit(@userlist, ',')

    INSERT INTO #TEMP_USER_LIST(custid, username, roleid, currency)
    SELECT custid, username, roleid, currency FROM custinfo (NOLOCK) WHERE username IN (SELECT username FROM @TEMP)

    DECLARE @StatementTable TABLE(
    accdate DATETIME,
    totalamt MONEY,
    transtype NVARCHAR(100),
    transdesc NVARCHAR(300),   
    roleid INT,
    username VARCHAR(50),
    currency INT
    )

IF @todate >= @BalanceUpDay
BEGIN
    --IF @roleid = 1
    BEGIN
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST (NOLOCK) WHERE roleId = 1)
        BEGIN
            INSERT INTO @StatementTable (accdate, totalamt, transtype, transdesc, username, currency)

            SELECT            
                winlostdate accdate,
                SUM(winlost-actual_stake) totalamt,
                'BET' AS transtype,
                'Betting' AS transdesc,
                username, currency
            FROM bettrans WITH (NOLOCK)
            WHERE
                bettype between 1 and 19999
                and custid IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=1)
                and winlostdate between @fromdate and @todate
            GROUP BY winlostdate, username, currency
           
            UNION ALL   
            SELECT
                winlostdate accdate,
                SUM(playercomm) totalamt,
                'COM' transtype,
                'Commission' transdesc ,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.custid = t.custid
            WHERE
                bettype between 1 and 19999            
                and winlostdate between @fromdate and @todate
                and playercomm<>0
            GROUP BY winlostdate, t.username, t.currency

            UNION ALL
            SELECT
                transdate accdate,
                SUM(winlost-actual_stake) totalamt,
                CONVERT(VARCHAR, bettype) transtype,
                transdesc,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.custid = t.custid
            WHERE
                bettype >= 20000            
                and winlostdate between @fromdate and @todate
            GROUP BY bettype,transdesc,transdate,t.username,t.currency

            -- customer deleted/void ticket
            UNION ALL
            SELECT DISTINCT
                eventdate accdate,
                0 totalamt,
                'BET' transtype,
                'Cancelled/Deleted Bets' transdesc,            
                t. username,
                t. currency
     
            FROM zzzbettrans b WITH (NOLOCK)
                INNER join MATCH m (NOLOCK) ON b.matchid = m.matchid
                INNER join #TEMP_USER_LIST t ON b.custid = t.custid
               
            WHERE
                bettype between 1 and 19999
                and eventdate between @fromdate and @todate
            GROUP BY eventdate, t.username, t. currency
           
            --Remove All
            UNION ALL
            SELECT DISTINCT
                eventdate accdate,
                0 totalamt,
                'BET' transtype,
                'Cancelled/Deleted Bets' transdesc,
                t. username,
                t. currency
            FROM zzzbettrans b WITH (NOLOCK)
                INNER join match14 m (NOLOCK) ON b.matchid = m.matchid
                INNER join #TEMP_USER_LIST t ON b.custid = t.custid
            WHERE
                bettype between 1 and 19999
                and eventdate between @fromdate and @todate
            GROUP BY eventdate, t.username, t. currency
        END
    END

    -- AGENT
    --IF @roleid = 2
    BEGIN
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST (NOLOCK) WHERE roleId = 2)
        BEGIN
            INSERT INTO @StatementTable (accdate, totalamt, transtype, transdesc, username, currency)
       
            SELECT
                transdate accdate,
                SUM(winlost-actual_stake) totalamt ,
                CONVERT(VARCHAR, bettype) transtype,
                transdesc ,
                username, currency
            FROM bettrans WITH (NOLOCK)        
            WHERE
                bettype >= 20000
                and custid IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=2)
                and winlostdate between @fromdate and @todate
                GROUP BY bettype,transdesc,transdate,username,currency
               
            UNION ALL
            SELECT
                winlostdate accdate,
                SUM(awinlost) totalamt,
                'POS' transtype,
                'Position' transdesc,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.recommend = t.custid and roleid=2
            WHERE
                bettype between 1 and 19999
                and winlostdate between @fromdate and @todate
                GROUP BY winlostdate,  t.currency, t.username
            HAVING SUM(awinlost) <> 0
           
            UNION ALL
            SELECT
                winlostdate accdate,
                SUM(comm-playercomm) totalamt,
                'COM' transtype,
                'Commission' transdesc,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.recommend = t.custid and roleid=2
            WHERE
                bettype between 1 and 19999            
                and winlostdate between @fromdate and @todate
            GROUP BY winlostdate,  t.currency , t.username
            HAVING SUM(comm-playercomm) <> 0
        END
    END

    -- MASTER
    --IF @roleid = 3
    BEGIN
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST (NOLOCK) WHERE roleId = 3)
        BEGIN
            INSERT INTO @StatementTable (accdate, totalamt, transtype, transdesc, username, currency)
            SELECT
                transdate accdate,
                SUM(winlost-actual_stake) totalamt ,
                CONVERT(VARCHAR, bettype) transtype,
                transdesc,
                username, currency
            FROM bettrans WITH (NOLOCK)        
            WHERE
                bettype >= 20000
                and bettrans.custid IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=3)
                and winlostdate between @fromdate and @todate
                GROUP BY bettype,transdesc,transdate,username, currency
       
            UNION ALL
            SELECT
                winlostdate accdate,
                SUM(mwinlost) totalamt,
                'POS' transtype,
                'Position' transdesc,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.mrecommend = t.custid
            WHERE
                bettype between 1 and 19999
                and mrecommend IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=3)
                and winlostdate between @fromdate and @todate
                GROUP BY winlostdate , t.currency, t.username
            HAVING SUM(mwinlost) <> 0
       
            UNION ALL
            SELECT
                winlostdate accdate,
                SUM(acomm-comm) totalamt,
                'COM' transtype,
                'Commission' transdesc,
                t. username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.mrecommend = t.custid
            WHERE
                bettype between 1 and 19999
                and mrecommend IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=3)
                and winlostdate between @fromdate and @todate
                GROUP BY winlostdate ,  t.currency, t.username
            HAVING SUM(acomm-comm) <> 0
        END
    END

    -- SUPER
    --IF @roleid = 4
    BEGIN
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST (NOLOCK) WHERE roleId = 4)
        BEGIN       
            INSERT INTO @StatementTable (accdate, totalamt, transtype, transdesc, username, currency)
            SELECT
                transdate accdate,
                SUM(winlost-actual_stake) totalamt ,
                CONVERT(VARCHAR, bettype) transtype,
                transdesc,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.srecommend = t.custid
            WHERE
            bettype >= 20000
            and  b.custid IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=4)       
            and winlostdate between @fromdate and @todate
            GROUP BY bettype,transdesc,transdate, t.username, t.currency
       
            UNION ALL
            SELECT
                winlostdate accdate,
                SUM(swinlost) totalamt,
                'POS' transtype,
                'Position' transdesc,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.srecommend = t.custid
            WHERE
                bettype between 1 and 19999
                and srecommend IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=4)       
                and winlostdate between @fromdate and @todate
                GROUP BY winlostdate, t.currency, t.username
                HAVING SUM(swinlost) <> 0
       
            UNION ALL
            SELECT
                winlostdate accdate,
                SUM(scomm-acomm) totalamt,
                'COM' transtype,
                'Commission' transdesc,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.srecommend = t.custid
            WHERE
                bettype between 1 and 19999
                and srecommend IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=4)       
                and winlostdate between @fromdate and @todate
                GROUP BY winlostdate,  t.currency , t.username
            HAVING SUM(scomm-acomm) <> 0
        END
    END

END

IF @fromdate < @BalanceUpDay
BEGIN
    IF @todate >= DATEADD(dd, -1, @BalanceUpDay)
        SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay) + ' 23:59:59'

    INSERT INTO @StatementTable (accdate, totalamt, transtype, transdesc, username, currency)
    SELECT
        accdate,
        totalamt,
        transtype,
        transdesc,
        t. username, t. currency
    FROM bodb_Report.dbo.STATEMENT s WITH (NOLOCK) INNER join #TEMP_USER_LIST t ON s.custid = t.custid
    WHERE s.custid IN (SELECT custid FROM #TEMP_USER_LIST ) AND accdate between @fromdate and @todate
END

SELECT
    s.username,
    t.roleid ,
    accdate ,
    totalamt ,
    transtype ,
    transdesc ,       
    s.currency
FROM @StatementTable s LEFT join #TEMP_USER_LIST t ON s.username = t.username
ORDER BY username, accdate, transtype, transdesc, CASE WHEN transdesc like '%opening balance%' THEN 1 ELSE 2 END

DROP TABLE #TEMP_USER_LIST


GO
GRANT EXECUTE ON [dbo].[Acc_AllStatement_UsersList] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AllStatement_UsersList] TO [vnteam]

 

