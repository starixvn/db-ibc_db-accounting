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

    DECLARE @MoveBetsDay SMALLDATETIME
    DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

    INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
    EXEC bodb02.dbo.Age_SelBalanceUpDay

    SELECT @MoveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp

    ---- To avoid parametter sniffing
    DECLARE @_FromDate SMALLDATETIME, @_ToDate SMALLDATETIME, @FromDate_Bk SMALLDATETIME, @_BalanceUpDay SMALLDATETIME
    SELECT @_FromDate = @FromDate, @_ToDate = @ToDate, @FromDate_Bk = @FromDate, @_BalanceUpDay = @BalanceUpDay

    DECLARE @Yesterday SMALLDATETIME 
    SELECT  @Yesterday = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
        
    ---- Get Sport Bettype Matrix 
    DECLARE @isTest BIT = 0
    SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)

    CREATE TABLE #SportBettype (ProductID INT, Bettype INT, RefTable TINYINT, VoidRejectGroup TINYINT) -- VoidRejectGroup for get data from zzzbettrans
    INSERT INTO  #SportBettype (ProductID, Bettype, RefTable)
    SELECT ProductID, Bettype, RefTable FROM dbo.f_SportBettypeMatrix_Sel(0, 0, 0, 2, '', '', @isTest)
    WHERE RefTable <> 0 -- get bettype in translog, bettransRnG, bettransLC (exclude bettype on bettrans)
    -- RefTable: 0-bettrans, 1-bettransRnG, 2-bettransLC, 3-translog

    CREATE TABLE #BetPosCom -- for bet, position, commission
    (
        Custid INT,
        Accdate SMALLDATETIME, 
        Bet_Totalamt MONEY DEFAULT ((0)), 
        Pos_Totalamt MONEY DEFAULT ((0)), 
        Com_Totalamt MONEY DEFAULT ((0))
    )

    CREATE TABLE #TEMP_USER_LIST 
    (   
        Custid INT PRIMARY KEY, 
        UserName    VARCHAR(30), 
        Roleid      INT, 
        Currency    INT, 
        AccDate     DATETIME 
    )

    INSERT INTO #TEMP_USER_LIST (Custid, UserName, Roleid, Currency)
    SELECT  Custid, UserName, Roleid, Currency
    FROM    custinfo WITH (NOLOCK)
    WHERE   UserName IN (SELECT value FROM STRING_SPLIT(@UserList, ','))

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
    CREATE TABLE #tmpBettrans
    (
        Custid          INT,
        Recommend       INT,
        Mrecommend      INT,
        Srecommend      INT,
        WinlostDate     SMALLDATETIME,
        Winlost         MONEY,
        aWinlost        MONEY,
        mWinlost        MONEY,
        sWinlost        MONEY,
        Actual_stake    MONEY,
        Playercomm      MONEY,
        Scomm           MONEY,
        Acomm           MONEY,   
        Comm            MONEY,
        StatusID        TINYINT,
        Bettype         SMALLINT
    )

    CREATE TABLE #tmpTransfer
    (
        Custid      INT,
        Transdate   DATETIME,
        TotalAmt    MONEY,
        TransDesc   NVARCHAR(1000),
        TransType   NVARCHAR(100)
    )

    IF @_ToDate >= @_BalanceUpDay
    BEGIN

        -- always get all data from latest BUDate -> @todate for calculating ACCUMULATED BALANCE row
        IF (@_FromDate > @_BalanceUpDay)  
        BEGIN  
            SELECT @Fromdate_bk = @_FromDate  
            SELECT @_FromDate = @_BalanceUpDay  
        END  
        -- bettrans
        INSERT INTO #tmpBettrans(Custid,Recommend,Mrecommend,Srecommend,WinlostDate,StatusID,b.Bettype,Winlost,aWinlost,mWinlost,sWinlost,Actual_stake,Playercomm,Scomm,Acomm,Comm)
        SELECT      Custid,Recommend,Mrecommend,Srecommend,WinlostDate,StatusID,b.Bettype,SUM(Winlost),SUM(aWinlost),SUM(mWinlost),SUM(sWinlost),SUM(Actual_stake),SUM(Playercomm),SUM(Scomm),SUM(Acomm),SUM(Comm)
        FROM        bettrans b WITH (NOLOCK)
        LEFT JOIN   #SportBettype s 
                    ON s.bettype = b.bettype 
        WHERE
            b.bettype < 19999
            AND (b.custid IN (SELECT Custid FROM #TEMP_USER_LIST WHERE  Roleid = 1)
                    OR b.recommend  IN  (SELECT Custid FROM #TEMP_USER_LIST WHERE  Roleid = 2)
                    OR b.mrecommend IN  (SELECT Custid FROM #TEMP_USER_LIST WHERE  Roleid = 3)
                    OR b.srecommend IN  (SELECT Custid FROM #TEMP_USER_LIST WHERE  Roleid = 4)
                )
            AND winlostdate BETWEEN @_FromDate AND @_ToDate
            AND (
                winlostdate < @Yesterday
                OR (winlostdate >= @Yesterday AND (s.RefTable IS NULL OR s.RefTable = 3)) -- exclude settle ticket on bettransRnG/LC today, yesterday
                )
            AND winlostdate > @MoveBetsDay
        GROUP BY Winlostdate,Custid,Recommend,Mrecommend,Srecommend,StatusID,b.Bettype
        UNION ALL
        -- bettransRnG
        SELECT  Custid,Recommend,Mrecommend,Srecommend,WinlostDate,StatusID,b.gameID,SUM(Winlost),SUM(aWinlost),SUM(mWinlost),SUM(sWinlost),SUM(Actual_stake),SUM(Playercomm),SUM(Scomm),SUM(Acomm),SUM(Comm)
        FROM    bettransRnG b 
        WHERE   winlostdate BETWEEN @_FromDate AND @_ToDate 
                AND (b.custid IN (SELECT Custid FROM #TEMP_USER_LIST WHERE  Roleid = 1)
                    OR b.recommend  IN  (SELECT Custid FROM #TEMP_USER_LIST WHERE  Roleid = 2)
                    OR b.mrecommend IN  (SELECT Custid FROM #TEMP_USER_LIST WHERE  Roleid = 3)
                    OR b.srecommend IN  (SELECT Custid FROM #TEMP_USER_LIST WHERE  Roleid = 4)
                )
                AND (
                    winlostdate >= @Yesterday 
                    OR StatusID IN (0, 1)
                    ) 
        GROUP BY Winlostdate,Custid,Recommend,Mrecommend,Srecommend,StatusID,b.gameID
        UNION ALL
        -- bettransLC
        SELECT  Custid,Recommend,Mrecommend,Srecommend,WinlostDate,StatusID,b.gameID,SUM(Winlost),SUM(aWinlost),SUM(mWinlost),SUM(sWinlost),SUM(Actual_stake),SUM(Playercomm),SUM(Scomm),SUM(Acomm),SUM(Comm)
        FROM    bettransLC b 
        WHERE   winlostdate BETWEEN @_FromDate AND @_ToDate 
                AND (b.custid IN (SELECT Custid FROM #TEMP_USER_LIST WHERE  Roleid = 1)
                    OR b.recommend  IN  (SELECT Custid FROM #TEMP_USER_LIST WHERE  Roleid = 2)
                    OR b.mrecommend IN  (SELECT Custid FROM #TEMP_USER_LIST WHERE  Roleid = 3)
                    OR b.srecommend IN  (SELECT Custid FROM #TEMP_USER_LIST WHERE  Roleid = 4)
                )
                AND (
                     winlostdate >= @Yesterday 
                     OR StatusID IN (0, 1)
                    ) 
        GROUP BY Winlostdate,Custid,Recommend,Mrecommend,Srecommend,StatusID,b.gameID

        -- Transfer
        INSERT INTO #tmpTransfer (Transdate,Custid,TotalAmt,TransType,TransDesc)
        SELECT  
                TransDate,
                Custid,
                SUM(winlost-actual_stake) AS TotalAmt,
                CASE WHEN ISNULL(ti.IsCollection,0) = 0 THEN bt.typenamee ELSE 'Coll' END  AS TransType,
                TransDesc
        FROM        Transfer b WITH (NOLOCK) 
        INNER JOIN  bettype bt WITH (NOLOCK) ON b.bettype = bt.typeid 
        LEFT JOIN   TransferInfo ti WITH (NOLOCK) ON b.TransId = ti.TransId 
        WHERE
            bettype > 20000            
            AND b.CustId IN (SELECT custid FROM #TEMP_USER_LIST)
            AND winlostdate BETWEEN @_FromDate AND @_ToDate
        GROUP BY TransDate,Custid,TransDesc,ti.IsCollection,bt.typenamee
        
        --IF @Roleid = 1
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST WHERE Roleid = 1)
        BEGIN
        
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT            
                WinlostDate AS Accdate,
                CASE WHEN b.StatusID IN (0,1,102,101) THEN 0 ELSE Winlost-Actual_stake END AS TotalAmt,
                'BET' AS TransType,
                CASE WHEN b.StatusID IN (0,1) THEN 'Outstanding Bet'
                     WHEN b.StatusID IN (102, 101) THEN 'Void/Cancelled Bet'
                    ELSE 'Betting Statement' END AS TransDesc,
                1 AS Roleid,
                UserName,
                Currency
            FROM        #tmpBettrans b 
            INNER JOIN  #TEMP_USER_LIST t ON  b.Custid = t.Custid AND t.Roleid = 1
            LEFT JOIN   #SportBettype s ON s.bettype = b.bettype
            WHERE 
                statusID NOT IN (0, 1)
                OR (statusID IN (0, 1) AND s.RefTable IS NULL)
            UNION ALL

            SELECT
                winlostdate AS Accdate,
                SUM(playercomm) AS TotalAmt,
                'COM' AS TransType,
                'Commission' AS TransDesc,
                1 AS Roleid,
                t.UserName, 
                t.Currency
            FROM        #tmpBettrans b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.custid = t.Custid AND t.Roleid = 1
            WHERE   
                playercomm <> 0
            GROUP BY winlostdate,t.UserName,t.Currency
            UNION ALL

            -- translog
            SELECT
                winlostdate AS Accdate,
                0 AS TotalAmt,
                'BET' AS TransType,
                'Outstanding Bet' AS TransDesc,
                1 AS Roleid,
                t.UserName, 
                t.Currency
            FROM        translog b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.custid = t.Custid AND t.Roleid = 1
            WHERE   
                winlostdate BETWEEN @_FromDate AND @_ToDate
                AND statusID IN (0, 1)
            GROUP BY winlostdate,t.UserName,t.Currency
                
            -- Grand Prize          
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                winlostdate AS Accdate
                ,SUM (WinAmount) AS TotalAmt
                ,'GP' AS TransType
                ,'Grand Prize' AS TransDesc,
                1 AS Roleid,
                t.UserName, 
                t.Currency
            FROM dbo.PayoutTrans b WITH (NOLOCK) 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.custid = t.Custid AND t.Roleid = 1
            WHERE
                winlostdate BETWEEN @_Fromdate AND @_ToDate
                AND WinlostDate > @_BalanceUpDay
                AND PayoutStatusId IN (4, 5)  ----- 'Completed', 'Expired'
            GROUP BY winlostdate,t.UserName,t.Currency
            
            -- Transfer
            INSERT INTO #BetPosCom(Custid,accdate,bet_totalamt,com_totalamt)
            SELECT b.Custid,winlostdate,SUM(winlost-actual_stake),SUM(playercomm)
            FROM        Transfer b WITH (NOLOCK) 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.custid = t.Custid AND t.Roleid = 1
            WHERE
                bettype = 19999
                AND winlostdate BETWEEN @_FromDate AND @_ToDate
                AND winlostdate <= @MoveBetsDay
            GROUP BY b.Custid,winlostdate
            
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                p.AccDate,
                com_totalamt,
                'COM' AS TransType,
                'Commission' AS TransDesc,
                1 AS Roleid,
                t.UserName, 
                t.Currency
            FROM #BetPosCom p
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  p.Custid = t.Custid AND Roleid = 1
            WHERE com_totalamt <> 0
            UNION ALL

            SELECT
                p.AccDate,
                bet_totalamt,
                'BET' AS TransType,
                'Betting' AS TransDesc,
                1 AS Roleid,
                t.UserName, 
                t.Currency
            FROM #BetPosCom p
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  p.Custid = t.Custid AND Roleid = 1 
            WHERE bet_totalamt <> 0

            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                Transdate AS Accdate,
                TotalAmt,
                TransType,
                TransDesc,
                1 AS Roleid,
                UserName, 
                Currency
            FROM        #tmpTransfer b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.Custid = t.Custid AND Roleid = 1
           
            IF @_FromDate <= @MoveBetsDay
            BEGIN
                -- For get data on zzzbettrans table --
                    /* VoidRejectGroup:
                        1. exclude zzzbettrans
                        2. zzzbettrans only
                        3. zzzbettrans inner join match/match14
                    */
                UPDATE #SportBettype
                SET VoidRejectGroup = 3 -- default: zzzbettrans inner join match/match14

                UPDATE #SportBettype
                SET VoidRejectGroup = 1 -- exclude zzzbettrans
                WHERE RefTable IN (1, 2) -- bettype in Casino Games (bettransRnG/LC)

                UPDATE #SportBettype
                SET VoidRejectGroup = 2 -- zzzbettrans only
                WHERE ProductID IN (8, 12, 13, 15) -- Keno, Gold Deluxe, MGC-Live Casino, Colossus Bet
                        -- (ProductID = 11 AND bettype = 1800) -- need to add AG Casino  (#SportBettype no have)

                --- zzzbettrans only
                INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
                SELECT DISTINCT
                    b.winlostdate accdate,
                    0 totalamt,
                    'BET' AS transtype,
                    'Void/Cancelled Bet' AS transdesc,
                    1 AS Roleid,
                    t.UserName, 
                    t.Currency
                FROM
                    zzzbettrans b WITH (NOLOCK)
                    INNER JOIN  #TEMP_USER_LIST t 
                            ON  b.custid = t.Custid AND t.Roleid = 1
                    INNER JOIN
                        (SELECT bettype FROM #SportBettype WHERE VoidRejectGroup = 2 --- zzzbettrans only
                         UNION SELECT 1800 -- AG Casino
                        ) s ON  s.Bettype = b.bettype
                WHERE
                    winlostdate BETWEEN @_Fromdate AND @MoveBetsDay
                    AND winlostdate >= @_BalanceUpDay
                GROUP BY winlostdate, t.UserName, t. Currency
            
                --- zzzbettrans inner join match/match14
                INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
                SELECT DISTINCT
                    eventdate AS Accdate,
                    0 AS TotalAmt,
                    'BET' AS TransType,
                    'Void/Cancelled Bet' AS TransDesc,
                    1 AS Roleid,
                    t. UserName,
                    t. Currency
                FROM        zzzbettrans b WITH (NOLOCK)
                INNER JOIN  Match m WITH (NOLOCK) ON b.matchid = m.matchid
                INNER JOIN  #TEMP_USER_LIST t ON b.custid = t.Custid AND t.Roleid = 1
                LEFT JOIN   #SportBettype s ON b.bettype = s.Bettype
                WHERE
                    b.bettype <= 19999
                    AND b.bettype NOT IN (903, 913, 914) -- exclude 903, 913, 914 (1800 for AG Casino: no need)
                    AND eventdate BETWEEN @_FromDate AND @MoveBetsDay
                    AND (s.VoidRejectGroup IS NULL OR s.VoidRejectGroup = 3) -- zzzbettrans inner join match/match14
                    AND ISNULL(b.comstatus, '') <> 'CO'
                GROUP BY eventdate, t.UserName, t. Currency
                UNION

                SELECT DISTINCT
                    eventdate AS Accdate,
                    0 AS TotalAmt,
                    'BET' AS TransType,
                    'Void/Cancelled Bet' AS TransDesc,
                    1 AS Roleid,
                    t.UserName,
                    t.Currency
                FROM        zzzbettrans b WITH (NOLOCK)
                INNER JOIN  match14 m WITH (NOLOCK) ON b.matchid = m.matchid
                INNER JOIN  #TEMP_USER_LIST t ON b.custid = t.Custid AND t.Roleid = 1
                LEFT JOIN   #SportBettype s ON b.bettype = s.Bettype
                WHERE
                    b.bettype <= 19999
                    AND b.bettype NOT IN (903, 913, 914) -- exclude 903, 913, 914 (1800 for AG Casino: no need)
                    AND eventdate BETWEEN @_FromDate AND @MoveBetsDay
                    AND (s.VoidRejectGroup IS NULL OR s.VoidRejectGroup = 3) -- zzzbettrans inner join match/match14
                    AND ISNULL(b.comstatus, '') <> 'CO'
                GROUP BY eventdate, t.UserName, t.Currency
                UNION

                SELECT DISTINCT
                    winlostdate AS Accdate,
                    0 AS TotalAmt,
                    'BET' TransType,
                    'Void/Cancelled Bet' TransDesc,
                    1 AS Roleid,
                    t.UserName,
                    t.Currency
                FROM        zzzbettrans b WITH (NOLOCK)
                INNER JOIN  #TEMP_USER_LIST t 
                        ON  b.custid = t.Custid AND t.Roleid = 1
                WHERE
                    b.bettype IN (9, 29)
                    AND b.winlostdate BETWEEN @_Fromdate AND @MoveBetsDay
                    AND ISNULL(b.comstatus, '') <> 'CO'
                GROUP BY winlostdate, t.UserName, t.Currency

            END
        END

        --IF @Roleid = 2
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST  WHERE Roleid = 2)
        BEGIN
            
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                Transdate AS Accdate,
                TotalAmt,
                TransType,
                TransDesc,
                2 AS Roleid,
                UserName, 
                Currency
            FROM        #tmpTransfer b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.Custid = t.Custid AND Roleid = 2
               
            INSERT INTO #BetPosCom(Custid,accdate,pos_totalamt,com_totalamt)
            SELECT t.Custid, WinlostDate, SUM(awinlost), SUM(Comm-Playercomm)
            FROM        #tmpBettrans b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.Recommend = t.Custid AND Roleid = 2
            GROUP BY t.Custid, WinlostDate

            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                p.AccDate,
                com_totalamt,
                'COM' AS TransType,
                'Commission' AS TransDesc,
                2 AS Roleid,
                t.UserName, 
                t.Currency
            FROM #BetPosCom p
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  p.Custid = t.Custid AND Roleid = 2 
            WHERE com_totalamt <> 0
            UNION ALL

            SELECT
                p.AccDate,
                pos_totalamt,
                'POS' TransType,
                'Position' TransDesc,
                2 AS Roleid,
                t.UserName, 
                t.Currency
            FROM #BetPosCom p
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  p.Custid = t.Custid AND Roleid = 2 
            WHERE pos_totalamt <> 0
            
        END

        --IF @Roleid = 3
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST WHERE Roleid = 3)
        BEGIN
           
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                Transdate AS Accdate,
                TotalAmt ,
                TransType,
                TransDesc,
                3 AS Roleid,
                UserName, 
                Currency
            FROM        #tmpTransfer b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.Custid = t.Custid AND Roleid = 3
      
            INSERT INTO #BetPosCom(Custid,accdate,pos_totalamt,com_totalamt)
            SELECT t.Custid, WinlostDate, SUM(mWinlost) ,SUM(acomm-comm)
            FROM        #tmpBettrans b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.Mrecommend = t.Custid AND Roleid = 3
            GROUP BY t.Custid, WinlostDate

            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                p.AccDate,
                com_totalamt,
                'COM' AS TransType,
                'Commission' AS TransDesc,
                3 AS Roleid,
                t.UserName, 
                t.Currency
            FROM #BetPosCom p
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  p.Custid = t.Custid  AND Roleid = 3
            WHERE com_totalamt <> 0
            UNION ALL

            SELECT
                p.AccDate,
                pos_totalamt,
                'POS' TransType,
                'Position' TransDesc,
                3 AS Roleid,
                t.UserName, 
                t.Currency
            FROM #BetPosCom p
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  p.Custid = t.Custid AND Roleid = 3
            WHERE pos_totalamt <> 0
            
        END
   
        --IF @Roleid = 4
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST WHERE Roleid = 4)
        BEGIN       
            
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                Transdate AS Accdate,
                TotalAmt,
                TransType,
                TransDesc,
                4 AS Roleid,
                UserName, 
                Currency
            FROM        #tmpTransfer b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.Custid = t.Custid AND Roleid = 4
        
            INSERT INTO #BetPosCom(Custid,accdate,pos_totalamt,com_totalamt)
            SELECT t.Custid, WinlostDate, SUM(sWinlost) ,SUM(Scomm-Acomm)
            FROM        #tmpBettrans b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.Srecommend = t.Custid AND Roleid = 4
            GROUP BY t.Custid, WinlostDate

            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
            SELECT
                p.AccDate,
                com_totalamt,
                'COM' AS TransType,
                'Commission' AS TransDesc,
                4 AS Roleid,
                t.UserName, 
                t.Currency
            FROM #BetPosCom p
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  p.Custid = t.Custid AND Roleid = 4 
            WHERE com_totalamt <> 0
            UNION ALL

            SELECT
                p.AccDate,
                pos_totalamt,
                'POS' AS TransType,
                'Position' AS TransDesc,
                4 AS Roleid,
                t.UserName, 
                t.Currency
            FROM #BetPosCom p
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  p.Custid = t.Custid AND Roleid = 4 
            WHERE pos_totalamt <> 0
        END
    END

    IF @_FromDate <= @_BalanceUpDay
    BEGIN
        
        IF @_ToDate > @_BalanceUpDay
            SELECT @_ToDate = @_BalanceUpDay
        
        UPDATE a
        SET a.AccDate = CASE WHEN @_FromDate < @_BalanceUpDay THEN ISNULL(b.Accdate,@FromDate_Bk) ELSE @_FromDate END
        FROM #TEMP_USER_LIST a 
        OUTER APPLY(SELECT TOP 1 Accdate
                    FROM bodb_Report.dbo.Statement_Accum b1 WITH (NOLOCK) 
                    WHERE   b1.custid = a.custid 
                            AND Accdate <= @Fromdate_bk
                    ORDER BY b1.Accdate DESC
                    ) b
        
        INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
        SELECT s.Accdate, TotalAmt, TransType, TransDesc, t.Roleid, t.UserName, t.Currency
        FROM        bodb_Report.dbo.Statement s WITH (NOLOCK)
        INNER JOIN  #TEMP_USER_LIST t 
                ON  s.custid = t.Custid
        WHERE 
            s.Accdate BETWEEN t.Accdate AND @_ToDate 
            AND s.TransType <> 'BAL'

        INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency)
        SELECT a.Accdate, a.TotalAmt, 'BAL' TransType, 'OPENING BALANCE' TransDesc, t.Roleid, t.UserName, t.Currency
        FROM        bodb_Report.dbo.Statement_Accum a WITH (NOLOCK) 
        INNER JOIN  #TEMP_USER_LIST t 
                ON  a.custid = t.Custid
        WHERE 
            a.Accdate BETWEEN t.Accdate AND @_ToDate
        
    END

    IF (@Fromdate_bk <> @_BalanceUpDay)
    BEGIN
        
        ;WITH CTE_Sum AS (
            SELECT UserName,Roleid,ISNULL(SUM(TotalAmt),0) TotalAmt,Currency 
            FROM #StatementTable s
            WHERE   s.Accdate < @Fromdate_bk 
                    AND EXISTS (SELECT TOP 1 1 FROM #StatementTable s1 WHERE s.UserName = s1.UserName AND s1.Accdate >= @Fromdate_bk)
            GROUP BY UserName,Roleid,Currency
        )
        INSERT INTO #StatementTable(UserName,Roleid,Accdate,TotalAmt,TransType,TransDesc,Currency)
        SELECT UserName,Roleid,NULL,TotalAmt,'BAL','ACCUMULATED BALANCE',Currency 
        FROM CTE_Sum 
        WHERE TotalAmt <> 0
         
    END

    SELECT
        UserName,
        Roleid ,
        Accdate ,
        SUM(TotalAmt) TotalAmt ,
        TransType ,
        TransDesc ,       
        Currency
    FROM #StatementTable
    WHERE 
        Accdate >= @Fromdate_bk
        OR TransDesc = 'ACCUMULATED BALANCE'
    GROUP BY UserName,Roleid,Accdate,TransType,TransDesc,Currency
    ORDER BY UserName, Accdate, TransType, TransDesc, CASE WHEN TransDesc like '%OPENING BALANCE%' THEN 1 ELSE 2 END
    
    DROP TABLE #SportBettype
    DROP TABLE #TEMP_USER_LIST
    DROP TABLE #BetPosCom
    DROP TABLE #StatementTable
    DROP TABLE #tmpBettrans
    DROP TABLE #tmpTransfer
END

GO