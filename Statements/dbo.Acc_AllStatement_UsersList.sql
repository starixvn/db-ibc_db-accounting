/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  [dbo].[Acc_AllStatement_UsersList]
    @UserList       VARCHAR(6000),
    @FromDate       SMALLDATETIME,
    @ToDate         SMALLDATETIME,
    @BalanceUpDay   SMALLDATETIME
AS

/*
    Created by: KhoaTran
    Date: 20100203
    Task: NAP Accounting - Others - Export Multi Statement - Select Statement by users list
    DB: DBACC.bodb02
   
    Revisions:     
        - 20100602@Khoa: put accounts' currency to the temp table #TEMP_USER_LIST 
        - 20101224@Lukas: Re-arrange bettype
        - 20180628@Percy: Fix issue duplicated data [RedmineID: #97316]
        - 20180731@Percy: Expand column transdesc [RedmineID: #92841]
        - 20210817@Sol: Allow more time to transfer (phase 2) - [RedmineID: #160019]
        - 20210823@Sol: Alpha - Allow more time to transfer (phase 2b) - [RedmineID: #160440]
        - 20211122@Danny: Split transfer tickets out of bettrans [Redmine: #164196]
        - 20220519@Evan: Revise sp, Get Opening Balance from Statement_Accum table [Redmine: #168299]

*/
BEGIN
    SET NOCOUNT ON

    DECLARE @moveBetsDay SMALLDATETIME
    DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

    INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
    EXEC bodb02.dbo.Age_SelBalanceUpDay

    SELECT @moveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp

    ---- To avoid parametter sniffing
    DECLARE @_FromDate SMALLDATETIME, @_ToDate SMALLDATETIME
    SELECT @_FromDate = @FromDate, @_ToDate = @ToDate

    DECLARE @FromDate_Bk SMALLDATETIME
    SET @FromDate_Bk = @_FromDate

    CREATE TABLE #TEMP_USER_LIST (Custid INT PRIMARY KEY, UserName VARCHAR(50), Roleid INT, Currency INT, AccDate DATETIME )

    INSERT INTO #TEMP_USER_LIST (Custid, UserName, Roleid, Currency)
    SELECT Custid, UserName, Roleid, Currency
    FROM custinfo WITH (NOLOCK)
    WHERE UserName IN (SELECT value FROM STRING_SPLIT(@userlist, ','))

    CREATE TABLE #StatementTable
    (
        Accdate     SMALLDATETIME,
        TotalAmt    MONEY,
        TransType   NVARCHAR(100),
        TransDesc   NVARCHAR(1000),   
        Roleid      INT,
        UserName    VARCHAR(50),
        Currency    INT
    )

    IF @_ToDate >= @BalanceUpDay
    BEGIN

        -- always get all data from latest BUDate -> @todate for calculating ACCUMULATED BALANCE row
        IF (@_FromDate > @BalanceUpDay)  
        BEGIN  
            SELECT @Fromdate_bk = @_FromDate  
            SELECT @_FromDate = @BalanceUpDay  
        END  
        --IF @Roleid = 1
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST WHERE Roleid = 1)
        BEGIN
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT            
                winlostdate Accdate,
                SUM(winlost-actual_stake) TotalAmt,
                'BET' AS TransType,
                'Betting' AS TransDesc,
                1 AS Roleid,
                UserName, Currency
            FROM bettrans WITH (NOLOCK)
            WHERE
                bettype < 19999
                AND custid IN (SELECT Custid FROM #TEMP_USER_LIST WHERE Roleid=1)
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND winlostdate > @moveBetsDay
            GROUP BY winlostdate, UserName, Currency

            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT            
                winlostdate Accdate,
                SUM(winlost-actual_stake) TotalAmt,
                'BET' AS TransType,
                'Betting' AS TransDesc,
                1 AS Roleid,
                UserName, Currency
            FROM Transfer WITH (NOLOCK)
            WHERE
                bettype = 19999
                AND custid IN (SELECT Custid FROM #TEMP_USER_LIST WHERE Roleid = 1)
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND winlostdate <= @moveBetsDay
            GROUP BY winlostdate, UserName, Currency
           
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                winlostdate Accdate,
                SUM(playercomm) TotalAmt,
                'COM' TransType,
                'Commission' TransDesc,
                1 AS Roleid,
                t.UserName, t.Currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.custid = t.Custid AND t.Roleid = 1
            WHERE
                bettype < 19999     
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND playercomm<>0
                AND winlostdate > @moveBetsDay
            GROUP BY winlostdate, t.UserName, t.Currency
            
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                winlostdate Accdate,
                SUM(playercomm) TotalAmt,
                'COM' TransType,
                'Commission' TransDesc,
                1 AS Roleid,
                t.UserName, t.Currency
            FROM Transfer b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.custid = t.custid AND t.Roleid = 1
            WHERE
                bettype = 19999     
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND playercomm<>0
                AND winlostdate <= @moveBetsDay
            GROUP BY winlostdate, t.UserName, t.Currency

            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                transdate Accdate,
                SUM(winlost-actual_stake) TotalAmt,
                CONVERT(VARCHAR, bettype) TransType,
                TransDesc,
                1 AS Roleid,
                t.UserName, t.Currency
            FROM dbo.transfer b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.custid = t.Custid AND t.Roleid = 1
            WHERE
                bettype > 20000            
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
            GROUP BY bettype,TransDesc,transdate,t.UserName, t.Currency
           
            IF @_FromDate <= @MoveBetsDay
            BEGIN
                -- customer deleted/void ticket
                INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
                SELECT DISTINCT
                    eventdate Accdate,
                    0 TotalAmt,
                    'BET' TransType,
                    'Cancelled/Deleted Bets' TransDesc,
                    1 AS Roleid,
                    t. UserName,
                    t. Currency
                FROM zzzbettrans b WITH (NOLOCK)
                    INNER JOIN Match m WITH (NOLOCK) ON b.matchid = m.matchid
                    INNER JOIN #TEMP_USER_LIST t ON b.custid = t.custid AND t.Roleid = 1
                WHERE
                    bettype BETWEEN 1 AND 19999
                    AND eventdate BETWEEN @_FromDate AND @MoveBetsDay
                GROUP BY eventdate, t.UserName, t. Currency

                INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
                SELECT DISTINCT
                    eventdate Accdate,
                    0 TotalAmt,
                    'BET' TransType,
                    'Cancelled/Deleted Bets' TransDesc,
                    1 AS Roleid,
                    t.UserName,
                    t.Currency
                FROM zzzbettrans b WITH (NOLOCK)
                    INNER JOIN match14 m WITH (NOLOCK) ON b.matchid = m.matchid
                    INNER JOIN #TEMP_USER_LIST t ON b.custid = t.custid AND t.Roleid = 1
                WHERE
                    bettype <= 19999
                    AND eventdate BETWEEN @_FromDate AND @MoveBetsDay
                GROUP BY eventdate, t.UserName, t.Currency
            END
        END

        --IF @Roleid = 2
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST  WHERE Roleid = 2)
        BEGIN
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                transdate Accdate,
                SUM(winlost-actual_stake) TotalAmt ,
                CONVERT(VARCHAR, bettype) TransType,
                TransDesc,
                2 AS Roleid,
                UserName, Currency
            FROM dbo.Transfer WITH (NOLOCK)        
            WHERE
                bettype > 20000
                AND custid IN (SELECT custid FROM #TEMP_USER_LIST WHERE Roleid=2)
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                GROUP BY bettype,TransDesc,transdate,UserName,Currency
               
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                winlostdate Accdate,
                SUM(awinlost) TotalAmt,
                'POS' TransType,
                'Position' TransDesc,
                2 AS Roleid,
                t.UserName, t.Currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.recommend = t.custid AND Roleid=2
            WHERE
                bettype < 19999
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND winlostdate > @moveBetsDay
            GROUP BY winlostdate,  t.Currency, t.UserName
            HAVING SUM(awinlost) <> 0
            
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                winlostdate Accdate,
                SUM(awinlost) TotalAmt,
                'POS' TransType,
                'Position' TransDesc,
                2 AS Roleid,
                t.UserName, t.Currency
            FROM Transfer b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.recommend = t.custid AND Roleid=2
            WHERE
                bettype = 19999
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND winlostdate <= @moveBetsDay
            GROUP BY winlostdate,  t.Currency, t.UserName
            HAVING SUM(awinlost) <> 0

            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                winlostdate Accdate,
                SUM(comm-playercomm) TotalAmt,
                'COM' TransType,
                'Commission' TransDesc,
                2 AS Roleid,
                t.UserName, t.Currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.recommend = t.custid AND Roleid=2
            WHERE
                bettype < 19999       
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND winlostdate > @moveBetsDay
            GROUP BY winlostdate,  t.Currency , t.UserName
            HAVING SUM(comm-playercomm) <> 0
        END

        --IF @Roleid = 3
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST WHERE Roleid = 3)
        BEGIN
            
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                transdate Accdate,
                SUM(winlost-actual_stake) TotalAmt ,
                CONVERT(VARCHAR, bettype) TransType,
                TransDesc,
                3 AS Roleid,
                UserName, Currency
            FROM dbo.Transfer b WITH (NOLOCK)        
            WHERE
                bettype > 20000
                AND b.custid IN (SELECT custid FROM #TEMP_USER_LIST WHERE Roleid=3)
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                GROUP BY bettype,TransDesc,transdate,UserName, Currency
      
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                winlostdate Accdate,
                SUM(mwinlost) TotalAmt,
                'POS' TransType,
                'Position' TransDesc,
                3 AS Roleid,
                t.UserName, t.Currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.mrecommend = t.custid AND Roleid = 3
            WHERE
                bettype < 19999
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND winlostdate > @moveBetsDay
            GROUP BY winlostdate , t.Currency, t.UserName
            HAVING SUM(mwinlost) <> 0

            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                winlostdate Accdate,
                SUM(mwinlost) TotalAmt,
                'POS' TransType,
                'Position' TransDesc,
                3 AS Roleid,
                t.UserName, t.Currency
            FROM Transfer b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.mrecommend = t.custid AND Roleid = 3
            WHERE
                bettype = 19999
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND winlostdate <= @moveBetsDay
            GROUP BY winlostdate , t.Currency, t.UserName
            HAVING SUM(mwinlost) <> 0
       
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                winlostdate Accdate,
                SUM(acomm-comm) TotalAmt,
                'COM' TransType,
                'Commission' TransDesc,
                3 AS Roleid,
                t. UserName, t.Currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.mrecommend = t.custid AND Roleid = 3
            WHERE
                bettype < 19999
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND winlostdate > @moveBetsDay
            GROUP BY winlostdate ,  t.Currency, t.UserName
            HAVING SUM(acomm-comm) <> 0

            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                winlostdate Accdate,
                SUM(acomm-comm) TotalAmt,
                'COM' TransType,
                'Commission' TransDesc,
                3 AS Roleid,
                t. UserName, t.Currency
            FROM Transfer b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.mrecommend = t.custid AND Roleid = 3
            WHERE
                bettype = 19999
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND winlostdate <= @moveBetsDay
            GROUP BY winlostdate ,  t.Currency, t.UserName
            HAVING SUM(acomm-comm) <> 0

        END
   
        --IF @Roleid = 4
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST WHERE Roleid = 4)
        BEGIN       
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                transdate Accdate,
                SUM(winlost-actual_stake) TotalAmt ,
                CONVERT(VARCHAR, bettype) TransType,
                TransDesc,
                4 AS Roleid,
                t.UserName, t.Currency
            FROM dbo.Transfer b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.srecommend = t.custid
            WHERE
                bettype > 20000
                AND  b.custid IN (SELECT custid FROM #TEMP_USER_LIST WHERE Roleid = 4)       
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
            GROUP BY bettype,TransDesc,transdate, t.UserName, t.Currency
       
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                winlostdate Accdate,
                SUM(swinlost) TotalAmt,
                'POS' TransType,
                'Position' TransDesc,
                4 AS Roleid,
                t.UserName, t.Currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.srecommend = t.custid
            WHERE
                bettype < 19999
                AND srecommend IN (SELECT custid FROM #TEMP_USER_LIST WHERE Roleid = 4)       
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND winlostdate > @moveBetsDay
            GROUP BY winlostdate, t.Currency, t.UserName
            HAVING SUM(swinlost) <> 0
       
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                winlostdate Accdate,
                SUM(swinlost) TotalAmt,
                'POS' TransType,
                'Position' TransDesc,
                4 AS Roleid,
                t.UserName, t.Currency
            FROM Transfer b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.srecommend = t.custid
            WHERE
                bettype = 19999
                AND srecommend IN (SELECT custid FROM #TEMP_USER_LIST WHERE Roleid = 4)       
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND winlostdate <= @moveBetsDay
            GROUP BY winlostdate, t.Currency, t.UserName
            HAVING SUM(swinlost) <> 0
     
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                winlostdate Accdate,
                SUM(scomm-acomm) TotalAmt,
                'COM' TransType,
                'Commission' TransDesc,
                4 AS Roleid,
                t.UserName, t.Currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.srecommend = t.custid
            WHERE
                bettype < 19999
                AND srecommend IN (SELECT custid FROM #TEMP_USER_LIST WHERE Roleid = 4)       
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND  winlostdate > @moveBetsDay
            GROUP BY winlostdate,  t.Currency , t.UserName
            HAVING SUM(scomm-acomm) <> 0

            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                winlostdate Accdate,
                SUM(scomm-acomm) TotalAmt,
                'COM' TransType,
                'Commission' TransDesc,
                4 AS Roleid,
                t.UserName, t.Currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.srecommend = t.custid
            WHERE
                bettype = 19999
                AND srecommend IN (SELECT custid FROM #TEMP_USER_LIST WHERE Roleid = 4)       
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND  winlostdate <= @moveBetsDay
            GROUP BY winlostdate, t.Currency , t.UserName
            HAVING SUM(scomm-acomm) <> 0
        END
    END

    IF @_FromDate <= @BalanceUpDay
    BEGIN
        
        IF @_ToDate > @BalanceUpDay
            SELECT @_ToDate = @BalanceUpDay
        
        UPDATE a
        SET a.AccDate = CASE WHEN @_FromDate < @BalanceUpDay THEN ISNULL(b.Accdate,@FromDate_Bk) ELSE @_FromDate END
        FROM #TEMP_USER_LIST a 
            OUTER APPLY(SELECT TOP 1 Accdate
                        FROM bodb_Report.dbo.Statement_Accum b1 WITH (NOLOCK) 
                        WHERE   b1.custid = a.custid 
                                AND Accdate <= @Fromdate_bk
                        ORDER BY b1.Accdate DESC
                        ) b

        INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
        SELECT s.Accdate, TotalAmt, TransType, TransDesc, t.Roleid, t.UserName, t.Currency
        FROM bodb_Report.dbo.Statement s WITH (NOLOCK)
            INNER JOIN #TEMP_USER_LIST t ON s.custid = t.custid
        WHERE s.Accdate BETWEEN t.Accdate AND @_ToDate AND s.TransType <> 'Bal'

        INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
        SELECT a.Accdate, a.TotalAmt, 'Bal' TransType, 'OPENING BALANCE' TransDesc, t.Roleid, t.UserName, t.Currency
        FROM bodb_Report.dbo.Statement_Accum a WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON a.custid = t.custid
        WHERE a.Accdate BETWEEN t.Accdate AND @_ToDate
        
    END

    IF (@Fromdate_bk <> @BalanceUpDay)
    BEGIN
        
        ;WITH CTE_Sum AS (
            SELECT UserName,Roleid,ISNULL(SUM(TotalAmt),0) TotalAmt,Currency 
            FROM #StatementTable 
            WHERE Accdate < @Fromdate_bk 
            GROUP BY UserName,Roleid,Currency
        )
        INSERT INTO #StatementTable(UserName, Roleid , Accdate , TotalAmt , TransType , TransDesc , Currency)
        SELECT UserName,Roleid,'',TotalAmt,'BAL','ACCUMULATED BALANCE',Currency 
        FROM CTE_Sum 
        WHERE TotalAmt <> 0
         
    END

    SELECT
        UserName,
        Roleid ,
        Accdate ,
        TotalAmt ,
        TransType ,
        TransDesc ,       
        Currency
    FROM #StatementTable
    WHERE Accdate >= @Fromdate_bk
    OR TransDesc = 'ACCUMULATED BALANCE'
    ORDER BY UserName, Accdate, TransType, TransDesc, CASE WHEN TransDesc like '%opening balance%' THEN 1 ELSE 2 END
    
    DROP TABLE #TEMP_USER_LIST
    DROP TABLE #StatementTable
END
GO