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
        - 20221208@Bobby: Fix bug (correct winlostdate vs RefTable) [Redmine: #181466,181480]
        - 20221219@Bobby: Correct statement in case difference between winlostdate and transdate of transfer [Redmine: #181771]
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
        Currency    INT
    )

    INSERT INTO #TEMP_USER_LIST (Custid, UserName, Roleid, Currency)
    SELECT  Custid, UserName, Roleid, Currency
    FROM    custinfo WITH (NOLOCK)
    WHERE   UserName IN (SELECT value FROM STRING_SPLIT(@UserList, ','))

	DROP TABLE IF EXISTS #tempCust;
	CREATE TABLE #tempCust (custid INT PRIMARY KEY);

    INSERT INTO #tempCust (custid)
    SELECT DISTINCT custid
    FROM (
	    SELECT custid
	    FROM #TEMP_USER_LIST
	
	    UNION ALL
	    SELECT ci.custid
	    FROM #TEMP_USER_LIST t
	    INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON ci.recommend = t.Custid AND ci.roleid = 1
	    WHERE t.Roleid = 2
	
	    UNION ALL
	    SELECT ci.custid
	    FROM #TEMP_USER_LIST t
	    INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON ci.mrecommend = t.Custid AND ci.roleid = 1
	    WHERE t.Roleid = 3
	
	    UNION ALL
	    SELECT ci.custid
	    FROM #TEMP_USER_LIST t
	    INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON ci.srecommend = t.Custid AND ci.roleid = 1
	    WHERE t.Roleid = 4
    ) AS t


    CREATE TABLE #StatementTable
    (
		custid		INT,
        Accdate     DATETIME,
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
        WinlostDate SMALLDATETIME,  
        Recommend       INT,  
        Mrecommend      INT,  
        Srecommend      INT,  
        TotalAmt    MONEY,  
        TransDesc   NVARCHAR(1000),  
        TransType   NVARCHAR(100),
        winlost     MONEY,
        actual_stake    MONEY,
        awinlost    MONEY,
        mwinlost    MONEY,
        swinlost    MONEY,
        Comm        MONEY,  
        scomm       MONEY,
        acomm       MONEY,
        Playercomm  MONEY,
        Bettype     SMALLINT  
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
        SELECT      b.Custid,Recommend,Mrecommend,Srecommend,WinlostDate,StatusID,b.Bettype,SUM(Winlost),SUM(aWinlost),SUM(mWinlost),SUM(sWinlost),SUM(Actual_stake),SUM(Playercomm),SUM(Scomm),SUM(Acomm),SUM(Comm)
        FROM        bettrans b WITH (NOLOCK)
		INNER JOIN #tempCust u on u.Custid = b.custid
        LEFT JOIN   #SportBettype s 
                    ON s.bettype = b.bettype 
        WHERE
            b.bettype < 19999
            AND winlostdate BETWEEN @_FromDate AND @_ToDate
            AND (
                winlostdate < @Yesterday
                OR (winlostdate >= @Yesterday AND (s.RefTable IS NULL OR s.RefTable = 3)) -- exclude settle ticket on bettransRnG/LC today, yesterday
                )
            AND winlostdate > @MoveBetsDay
        GROUP BY Winlostdate,b.Custid,Recommend,Mrecommend,Srecommend,StatusID,b.Bettype
        UNION ALL
        -- bettransRnG
        SELECT  b.Custid,Recommend,Mrecommend,Srecommend,WinlostDate,StatusID,b.gameID,SUM(Winlost),SUM(aWinlost),SUM(mWinlost),SUM(sWinlost),SUM(Actual_stake),SUM(Playercomm),SUM(Scomm),SUM(Acomm),SUM(Comm)
        FROM    bettransRnG b  with(nolock)
		INNER JOIN #tempCust u on u.Custid = b.custid
        WHERE   winlostdate BETWEEN @_FromDate AND @_ToDate 
                AND (
                    winlostdate >= @Yesterday 
                    OR StatusID IN (0, 1)
                    ) 
        GROUP BY Winlostdate,b.Custid,Recommend,Mrecommend,Srecommend,StatusID,b.gameID
        UNION ALL
        -- bettransLC
        SELECT  b.Custid,Recommend,Mrecommend,Srecommend,WinlostDate,StatusID,b.gameID,SUM(Winlost),SUM(aWinlost),SUM(mWinlost),SUM(sWinlost),SUM(Actual_stake),SUM(Playercomm),SUM(Scomm),SUM(Acomm),SUM(Comm)
        FROM    bettransLC b with(nolock)
		INNER JOIN #tempCust u on u.Custid = b.custid
        WHERE   winlostdate BETWEEN @_FromDate AND @_ToDate 
                AND (
                     winlostdate >= @Yesterday 
                     OR StatusID IN (0, 1)
                    ) 
        GROUP BY Winlostdate,b.Custid,Recommend,Mrecommend,Srecommend,StatusID,b.gameID

        -- Transfer
        INSERT INTO #tmpTransfer (Transdate,WinlostDate,Custid,Recommend,Mrecommend,Srecommend,TotalAmt,TransType,TransDesc,winlost,actual_stake,awinlost,mwinlost,swinlost,Comm,scomm,acomm,Playercomm,Bettype)  
        SELECT    
                TransDate,  
                WinlostDate,  
                b.Custid,Recommend,Mrecommend,Srecommend,
                SUM(winlost-actual_stake) AS TotalAmt,  
                CASE WHEN ISNULL(ti.IsCollection,0) = 0 THEN bt.typenamee ELSE 'Coll' END  AS TransType,  
                TransDesc,
                SUM(winlost),SUM(actual_stake),SUM(awinlost),SUM(mwinlost),SUM(swinlost),SUM(Comm),SUM(scomm),SUM(acomm),SUM(Playercomm),Bettype
        FROM        Transfer b WITH (NOLOCK)   
		INNER JOIN #tempCust u on u.Custid = b.custid
        INNER JOIN  bettype bt WITH (NOLOCK) ON b.bettype = bt.typeid   
        LEFT JOIN   TransferInfo ti WITH (NOLOCK) ON b.TransId = ti.TransId   
        WHERE  
            (bettype > 20000  
            OR (bettype = 19999  AND winlostdate <= @MoveBetsDay))
            AND winlostdate BETWEEN @_FromDate AND @_ToDate
        GROUP BY Bettype,TransDate,WinlostDate,b.Custid,Recommend,Mrecommend,Srecommend,TransDesc,ti.IsCollection,bt.typenamee
        
        --IF @Roleid = 1
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST WHERE Roleid = 1)
        BEGIN
        
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency, custid)
            SELECT            
                WinlostDate AS Accdate,
                CASE WHEN b.StatusID IN (0,1,102,101) THEN 0 ELSE Winlost-Actual_stake END AS TotalAmt,
                'BET' AS TransType,
                CASE WHEN b.StatusID IN (0,1) THEN 'Outstanding Bet'
                     WHEN b.StatusID IN (102, 101) THEN 'Void/Cancelled Bet'
                    ELSE 'Betting Statement' END AS TransDesc,
                1 AS Roleid,
                UserName,
                Currency,
				t.Custid
            FROM        #tmpBettrans b 
            INNER JOIN  #TEMP_USER_LIST t ON  b.Custid = t.Custid AND t.Roleid = 1
            LEFT JOIN   #SportBettype s ON s.bettype = b.bettype
            WHERE 
                statusID NOT IN (0, 1)
                OR (statusID IN (0, 1) AND ISNULL(s.RefTable,0) <> 3)
            UNION ALL

            SELECT
                winlostdate AS Accdate,
                SUM(playercomm) AS TotalAmt,
                'COM' AS TransType,
                'Commission' AS TransDesc,
                1 AS Roleid,
                t.UserName, 
                t.Currency,
				t.Custid
            FROM        #tmpBettrans b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.custid = t.Custid AND t.Roleid = 1
            WHERE   
                playercomm <> 0
            GROUP BY winlostdate,t.UserName,t.Currency,t.Custid
            UNION ALL

            -- translog
            SELECT
                winlostdate AS Accdate,
                0 AS TotalAmt,
                'BET' AS TransType,
                'Outstanding Bet' AS TransDesc,
                1 AS Roleid,
                t.UserName, 
                t.Currency,
				t.Custid
            FROM        translog b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.custid = t.Custid AND t.Roleid = 1
            WHERE   
                winlostdate BETWEEN @_FromDate AND @_ToDate
                AND statusID IN (0, 1)
            GROUP BY winlostdate,t.UserName,t.Currency, t.Custid
                
            -- Grand Prize          
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency, custid)
            SELECT
                winlostdate AS Accdate
                ,SUM (WinAmount) AS TotalAmt
                ,'GP' AS TransType
                ,'Grand Prize' AS TransDesc,
                1 AS Roleid,
                t.UserName, 
                t.Currency,
				t.custid
            FROM dbo.PayoutTrans b WITH (NOLOCK) 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.custid = t.Custid AND t.Roleid = 1
            WHERE
                winlostdate BETWEEN @_Fromdate AND @_ToDate
                AND WinlostDate > @_BalanceUpDay
                AND PayoutStatusId IN (4, 5)  ----- 'Completed', 'Expired'
            GROUP BY winlostdate,t.UserName,t.Currency,t.Custid
            
            -- Transfer  
            INSERT INTO #BetPosCom(Custid,accdate,bet_totalamt,com_totalamt)  
            SELECT b.Custid,winlostdate,SUM(winlost-actual_stake),SUM(playercomm)  
            FROM        #tmpTransfer b    
            INNER JOIN  #TEMP_USER_LIST t   
                    ON  b.custid = t.Custid AND t.Roleid = 1  
            WHERE  
                bettype = 19999  
            GROUP BY b.Custid,winlostdate
            
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency, custid)  
            SELECT  
                Transdate AS Accdate,  
                TotalAmt,  
                TransType,  
                TransDesc,  
                1 AS Roleid,  
                UserName,   
                Currency ,
				t.Custid
            FROM        #tmpTransfer b   
            INNER JOIN  #TEMP_USER_LIST t   
                    ON  b.Custid = t.Custid AND Roleid = 1  
            WHERE bettype > 19999

            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency, custid)
            SELECT
                p.AccDate,
                com_totalamt,
                'COM' AS TransType,
                'Commission' AS TransDesc,
                1 AS Roleid,
                t.UserName, 
                t.Currency,
				t.Custid
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
                t.Currency,
				t.Custid
            FROM #BetPosCom p
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  p.Custid = t.Custid AND Roleid = 1 
            WHERE bet_totalamt <> 0

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
                INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency, custid)
                SELECT DISTINCT
                    b.winlostdate accdate,
                    0 totalamt,
                    'BET' AS transtype,
                    'Void/Cancelled Bet' AS transdesc,
                    1 AS Roleid,
                    t.UserName, 
                    t.Currency,
					t.Custid
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
                GROUP BY winlostdate, t.UserName, t.Currency, t.Custid
            
                --- zzzbettrans inner join match/match14
                INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency, custid)
                SELECT DISTINCT
                    eventdate AS Accdate,
                    0 AS TotalAmt,
                    'BET' AS TransType,
                    'Void/Cancelled Bet' AS TransDesc,
                    1 AS Roleid,
                    t.UserName,
                    t.Currency,
					t.Custid
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
                GROUP BY eventdate, t.UserName, t.Currency, t.Custid
                UNION

                SELECT DISTINCT
                    eventdate AS Accdate,
                    0 AS TotalAmt,
                    'BET' AS TransType,
                    'Void/Cancelled Bet' AS TransDesc,
                    1 AS Roleid,
                    t.UserName,
                    t.Currency,
					t.Custid
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
                GROUP BY eventdate, t.UserName, t.Currency, t.Custid
                UNION

                SELECT DISTINCT
                    winlostdate AS Accdate,
                    0 AS TotalAmt,
                    'BET' TransType,
                    'Void/Cancelled Bet' TransDesc,
                    1 AS Roleid,
                    t.UserName,
                    t.Currency,
					t.Custid
                FROM        zzzbettrans b WITH (NOLOCK)
                INNER JOIN  #TEMP_USER_LIST t 
                        ON  b.custid = t.Custid AND t.Roleid = 1
                WHERE
                    b.bettype IN (9, 29)
                    AND b.winlostdate BETWEEN @_Fromdate AND @MoveBetsDay
                    AND ISNULL(b.comstatus, '') <> 'CO'
                GROUP BY winlostdate, t.UserName, t.Currency, t.Custid

            END
        END

        --IF @Roleid = 2
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST  WHERE Roleid = 2)
        BEGIN
            
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency,custid)
            SELECT
                Transdate AS Accdate,
                TotalAmt,
                TransType,
                TransDesc,
                2 AS Roleid,
                UserName, 
                Currency,
				t.Custid
            FROM        #tmpTransfer b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.Custid = t.Custid AND Roleid = 2

            INSERT INTO #BetPosCom(Custid,accdate,pos_totalamt,com_totalamt)
            SELECT t.Custid, WinlostDate, SUM(awinlost), SUM(Comm-Playercomm)
            FROM        #tmpBettrans b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.Recommend = t.Custid AND Roleid = 2
            GROUP BY t.Custid, WinlostDate

            -- Transfer  
            INSERT INTO #BetPosCom(Custid,accdate,pos_totalamt,com_totalamt)  
            SELECT t.Custid,winlostdate,SUM(awinlost),SUM(comm-playercomm)  
            FROM        #tmpTransfer b 
            INNER JOIN  #TEMP_USER_LIST t   
                    ON  b.Recommend = t.Custid AND t.Roleid = 2  
            WHERE  
                bettype = 19999  
            GROUP BY t.Custid,winlostdate 

            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency,custid)
            SELECT
                p.AccDate,
                com_totalamt,
                'COM' AS TransType,
                'Commission' AS TransDesc,
                2 AS Roleid,
                t.UserName, 
                t.Currency,
				t.Custid
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
                t.Currency,
				t.Custid
            FROM #BetPosCom p
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  p.Custid = t.Custid AND Roleid = 2 
            WHERE pos_totalamt <> 0
            
        END

        --IF @Roleid = 3
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST WHERE Roleid = 3)
        BEGIN
           
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency, custid)
            SELECT
                Transdate AS Accdate,
                TotalAmt ,
                TransType,
                TransDesc,
                3 AS Roleid,
                UserName, 
                Currency,
				t.Custid
            FROM        #tmpTransfer b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.Custid = t.Custid AND Roleid = 3

            INSERT INTO #BetPosCom(Custid,accdate,pos_totalamt,com_totalamt)
            SELECT t.Custid, WinlostDate, SUM(mWinlost) ,SUM(acomm-comm)
            FROM        #tmpBettrans b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.Mrecommend = t.Custid AND Roleid = 3
            GROUP BY t.Custid, WinlostDate

            -- Transfer  
            INSERT INTO #BetPosCom(Custid,accdate,pos_totalamt,com_totalamt)  
            SELECT t.Custid,winlostdate,SUM(mwinlost),SUM(acomm-comm)  
            FROM        #tmpTransfer b 
            INNER JOIN  #TEMP_USER_LIST t   
                    ON  b.Mrecommend = t.Custid AND t.Roleid = 3  
            WHERE  
                bettype = 19999  
            GROUP BY t.Custid,winlostdate 

            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency, custid)
            SELECT
                p.AccDate,
                com_totalamt,
                'COM' AS TransType,
                'Commission' AS TransDesc,
                3 AS Roleid,
                t.UserName, 
                t.Currency,
				t.Custid
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
                t.Currency,
				t.Custid
            FROM #BetPosCom p
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  p.Custid = t.Custid AND Roleid = 3
            WHERE pos_totalamt <> 0
            
        END
   
        --IF @Roleid = 4
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST WHERE Roleid = 4)
        BEGIN       
            
            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency, custid)
            SELECT
                Transdate AS Accdate,
                TotalAmt,
                TransType,
                TransDesc,
                4 AS Roleid,
                UserName, 
                Currency,
				t.Custid
            FROM        #tmpTransfer b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.Custid = t.Custid AND Roleid = 4

            INSERT INTO #BetPosCom(Custid,accdate,pos_totalamt,com_totalamt)
            SELECT t.Custid, WinlostDate, SUM(swinlost),SUM(scomm-acomm) 
            FROM        #tmpBettrans b 
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  b.Srecommend = t.Custid AND Roleid = 4
            GROUP BY t.Custid, WinlostDate

            -- Transfer  
            INSERT INTO #BetPosCom(Custid,accdate,pos_totalamt,com_totalamt)  
            SELECT t.Custid,winlostdate,SUM(swinlost),SUM(scomm-acomm)  
            FROM        #tmpTransfer b 
            INNER JOIN  #TEMP_USER_LIST t   
                    ON  b.Srecommend = t.Custid AND t.Roleid = 4  
            WHERE  
                bettype = 19999  
            GROUP BY t.Custid,winlostdate 

            INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency, custid)
            SELECT
                p.AccDate,
                com_totalamt,
                'COM' AS TransType,
                'Commission' AS TransDesc,
                4 AS Roleid,
                t.UserName, 
                t.Currency,
				t.Custid
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
                t.Currency,
				t.Custid
            FROM #BetPosCom p
            INNER JOIN  #TEMP_USER_LIST t 
                    ON  p.Custid = t.Custid AND Roleid = 4 
            WHERE pos_totalamt <> 0
        END
    END

    IF @_FromDate <= @_BalanceUpDay
    BEGIN
        DECLARE @lateTransaction BIT
			, @_ToAccdate DATETIME
			, @_FromAccdate DATETIME;
		
		SELECT @_ToAccdate = @_ToDate
			,@_FromAccdate = @_FromDate

        IF @_ToDate >= @_BalanceUpDay
        BEGIN
            SELECT @lateTransaction = 1
                ,@_ToAccdate = DATEADD(SECOND, -1, CAST(@_BalanceUpDay AS DATETIME))
        END
        ELSE
            SELECT @_ToAccdate = DATEADD(SECOND, 86399, @_ToAccdate)

        IF @_FromDate < @_BalanceUpDay
            SELECT TOP 1 @_FromAccdate = ISNULL(AccDate, @FromDate_Bk)
            FROM bodb_Report.dbo.Statement_Accum WITH (NOLOCK)
            WHERE AccDate <= @FromDate_Bk
            ORDER BY AccDate DESC

        
        INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency, custid)
        SELECT s.Accdate, TotalAmt, TransType, TransDesc, t.Roleid, t.UserName, t.Currency,t.Custid
        FROM    bodb_Report.dbo.Statement s WITH (NOLOCK)
        INNER JOIN  #TEMP_USER_LIST t 
                ON  s.custid = t.Custid
        WHERE s.Accdate BETWEEN @_FromAccdate AND @_ToAccdate
            AND s.TransType <> 'BAL'
		
        -- CORRECT: @lateTransaction
        SELECT @_ToAccdate = DATEADD(SECOND, 86399, CAST(@ToDate AS DATETIME));
        INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency, custid)
        SELECT s.Accdate, s.TotalAmt, s.TransType, s.TransDesc, t.Roleid, t.UserName, t.Currency, t.Custid
        FROM    bodb_Report.dbo.Statement s WITH (NOLOCK)
        INNER JOIN  #TEMP_USER_LIST t 
                ON  s.custid = t.Custid
        LEFT JOIN #StatementTable ck ON ck.custid = s.custid AND ck.transtype = s.transtype AND ck.accdate = s.accdate
        WHERE @lateTransaction = 1
            AND s.Accdate BETWEEN @_BalanceUpDay AND @_ToAccdate
            AND s.TransType IN ('Dep','Wit','Trac')
            AND ck.custid IS NULL

        INSERT INTO #StatementTable (Accdate, TotalAmt, TransType, TransDesc, Roleid, UserName, Currency, custid)
        SELECT a.Accdate, a.TotalAmt, 'BAL' TransType, 'OPENING BALANCE' TransDesc, t.Roleid, t.UserName, t.Currency, t.Custid
        FROM        bodb_Report.dbo.Statement_Accum a WITH (NOLOCK) 
        INNER JOIN  #TEMP_USER_LIST t 
                ON  a.custid = t.Custid
        WHERE 
            a.Accdate BETWEEN @_FromAccdate AND @_ToAccdate
            AND a.AccDate <= @_BalanceUpDay
        
    END

    IF (@Fromdate_bk <> @_BalanceUpDay)
    BEGIN
        
        ;WITH CTE_Sum AS (
            SELECT UserName,Roleid,ISNULL(SUM(TotalAmt),0) TotalAmt,Currency, custid
            FROM #StatementTable s
            WHERE   s.Accdate < @Fromdate_bk 
                    AND EXISTS (SELECT TOP 1 1 FROM #StatementTable s1 WHERE s.UserName = s1.UserName AND s1.Accdate >= @Fromdate_bk)
            GROUP BY UserName,Roleid,Currency, custid
        )
        INSERT INTO #StatementTable(UserName,Roleid,Accdate,TotalAmt,TransType,TransDesc,Currency, custid)
        SELECT UserName,Roleid,NULL,TotalAmt,'BAL','ACCUMULATED BALANCE',Currency, custid
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