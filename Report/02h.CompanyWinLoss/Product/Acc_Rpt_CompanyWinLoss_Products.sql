IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Acc_Rpt_CompanyWinLoss_Products]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Products];
GO
CREATE PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Products] @StartDate SMALLDATETIME,
                                                         @EndDate   SMALLDATETIME
AS

/*
Creator: Jacob
Date: 2016-03-01
Task:  Casino Integration Improvement - Implement Company Winloss By Products report [#48448]
DB: DBACC/bodb02

Revisions:
- 20160301@Jacob: Initialize Company Win Loss Report
Example:
EXEC [Acc_Rpt_CompanyWinLoss_Products] @EndDate='2020-01-01',@StartDate='2016-01-01'

*/

     SET NOCOUNT ON;
     BEGIN --#SportBetType     
         DECLARE @isTest BIT= 0;
         SELECT @isTest = dbo.f_CheckSPVersion(@@PROCID);
         CREATE TABLE #SportBetType
         (ProductId  INT,
          BetType    INT,
          EventType  INT,
          SubProduct NVARCHAR(50),
          RefTable   INT,
          CasinoType INT
         );
         INSERT INTO #SportBetType
                SELECT ProductId,
                       BetType,
                       EventType,
                       SubProduct,
                       RefTable,
                       CasinoType
                FROM dbo.f_SportBetTypeMatrix_Sel(0, 0, 0, 2, '', '', @isTest);
     END;
     BEGIN -- @Order Configuration
         DECLARE @RMOrder TABLE
         (OrderNumber INT IDENTITY(1, 1),
          Product     VARCHAR(20)
         );
         INSERT INTO @RMOrder(Product)
         VALUES('Soccer 8RM'), ('Soccer BARM'), ('Other Sports 8RM'), ('Other Sports BARM');
         DECLARE @ProductOrder TABLE
         (OrderNumber INT IDENTITY(1, 1),
          Product     NVARCHAR(50)
         );
         INSERT INTO @ProductOrder(Product)
         VALUES('Soccer'), ('Metric Gaming - Superlive'), ('Other Sports'), ('Parlay'), ('Sportsbook Total'), ('Sportsbook Live Total'), ('Sportsbook Non-Live Total'), ('Number Game'), ('Live Casino'), ('Casino'), ('Virtual Sports'), ('Keno'), ('Racing'), ('Bettrade'), ('Colossus Bets'), ('RM');
     END;
     BEGIN -- @LiveCasinoBetType Configuration
         DECLARE @LiveCasinoBetType TABLE(BetType INT);
         INSERT INTO @LiveCasinoBetType
                SELECT DISTINCT
                       BetType
                FROM #SportBetType
                WHERE CasinoType = 2;
     END;
     BEGIN -- @CasinoBetType Configuration
         DECLARE @CasinoBetType TABLE(BetType INT);
         INSERT INTO @CasinoBetType
                SELECT DISTINCT
                       BetType
                FROM #SportBetType
                WHERE CasinoType = 1;
     END;
     BEGIN -- @UniversalProduct Configuration

         DECLARE @UniversalProduct TABLE
         (Id   INT,
          Name NVARCHAR(50)
         );
         INSERT INTO @UniversalProduct
                SELECT ProductId,
                       ProductName
                FROM Products
                WHERE ProductID IN(3, 5, 8, 15);
     END;
     BEGIN -- @AllCasinoBetType Configuration
         DECLARE @AllCasinoBetType TABLE(BetType INT);
         INSERT INTO @AllCasinoBetType
                SELECT DISTINCT
                       BetType
                FROM #SportBetType
                WHERE CasinoType <> 0;
     END;
     BEGIN -- #Match

         CREATE TABLE #Match
         (matchid   INT,
          sporttype SMALLINT,
          type      VARCHAR(10)
         );
         INSERT INTO #Match
                SELECT DISTINCT
                       m.matchid,
                       l.sporttype,
                       m.type
                FROM
                (
                    SELECT matchid,
                           leagueid,
                           'match' AS type
                    FROM Match WITH (NOLOCK)
                    WHERE eventdate BETWEEN @StartDate AND @EndDate
                    UNION ALL
                    SELECT orid,
                           leagueid,
                           'outright' AS type
                    FROM outright WITH (NOLOCK)
                    WHERE eventdate BETWEEN @StartDate AND @EndDate
                ) m
                INNER JOIN league l WITH (NOLOCK) ON m.leagueid = l.leagueid;
     END;
     BEGIN -- #DepositAgent

         CREATE TABLE #DepositAgent
         (CustId INT PRIMARY KEY
         );
         INSERT INTO #DepositAgent
                SELECT CustId
                FROM custInfo WITH (NOLOCK)
                WHERE srecommend IN
                (
                    SELECT CustId
                    FROM f_DepSuper_1('All')
                )
                AND roleid = 2
                AND CustId <> 5707545
                UNION
                SELECT 5707545; --BARM	

     END;
     BEGIN -- #Data

         CREATE TABLE #Data
         (Product         NVARCHAR(50),
          Site            NVARCHAR(50),
          MemberWinLoss   MONEY,
          SMAWinLoss      MONEY,
          Commission      MONEY,
          RealIncome      MONEY,
          VirtualIncome   MONEY,
          RealTurnover    MONEY,
          VirtualTurnover MONEY
         );
     END;
     BEGIN -- Racing

         BEGIN -- @IBCFee

             DECLARE @IBCFee TABLE
             (PartnerId INT,
              IBCFee    BIT
             );
             INSERT INTO @IBCFee
             (PartnerId,
              IBCFee
             )
             VALUES
             (1,
              1
             ), --RACE-PHU
             
             (2,
              0
             ), --RACE-ATRUK
             
             (3,
              0
             ), --RACE-ATRIRL
             
             (4,
              0
             ), --RACE-RUK
             
             (5,
              1
             ), --RACE-TABCORP
             
             (6,
              1
             ), --RACE-TABCORPNSW
             
             (101,
              1
             ), --GREY-DTOTEUK
             
             (102,
              1
             ), --GREY-DTOTEIRL
             
             (103,
              1
             ), --GREY-TABCORP
             
             (104,
              1
             ), --GREY-TABCORPNSW
             
             (201,
              1
             ), --HAR-TABCORP
             
             (202,
              1
             ); --HAR-TABCORPNSW	
         END;
         BEGIN -- #CommSetting

             CREATE TABLE #CommSetting
             (MatchId       INT,
              IBCFee        BIT,
              ToteCommWin   SMALLMONEY,
              ToteCommPlace SMALLMONEY,
              ToteCommWP    SMALLMONEY,
              ToteFee       SMALLMONEY
             );
             INSERT INTO #CommSetting
             (MatchId,
              IBCFee,
              ToteCommWin,
              ToteCommPlace,
              ToteCommWP,
              ToteFee
             )
                    SELECT DISTINCT
                           o.orid AS matchid,
                           t.IBCFee,
                           p.ToteCommWin,
                           p.ToteCommPlace,
                           (p.ToteCommWin + p.ToteCommPlace) / 2 AS ToteCommWP,
                           p.ToteFee
                    FROM outright AS o WITH (NOLOCK)
                         INNER JOIN LeagueDetail AS p WITH (NOLOCK) ON o.leagueId = p.LeagueId
                                                                       AND p.programDate = o.programDate
                         INNER JOIN RacingMeeting AS r WITH (NOLOCK) ON r.meetingId = p.leagueid
                         INNER JOIN @IBCFee AS t ON r.PartnerId = t.PartnerId
                    WHERE o.eventdate BETWEEN @StartDate AND @EndDate;
             DECLARE @RBWinlost TABLE
             (Site          VARCHAR(20),
              MemberWinLoss MONEY,
              SMAWinLoss    MONEY,
              Commission    MONEY,
              RealIncome    MONEY,
              RealTurnover  MONEY
             );
             INSERT INTO @RBWinlost
             (Site,
              MemberWinLoss,
              SMAWinLoss,
              Commission,
              RealIncome,
              RealTurnover
             )
                    SELECT CASE
                               WHEN dep.CustId IS NULL
                               THEN 'Credit'
                               ELSE 'Deposit'
                           END AS Site,
                           SUM((b.winlost - b.actual_stake) * b.actualrate) AS MemberWinLoss,
                           SUM((b.awinlost + b.mwinlost + b.swinlost) * b.actualrate) AS SMAWinLoss,
                           SUM(b.scomm * b.actualrate) AS Commission,
                           -(SUM((CASE
                                      WHEN b.BetType = 33
                                      THEN bm.WLIBC
                                      ELSE-(b.winlost - b.actual_stake) * ISNULL(b.oddsspread, 0)
                                  END) * b.actualrate) - SUM(CASE
                                                                 WHEN cs.IBCFee = 0
                                                                 THEN 0
                                                                 ELSE(CASE
                                                                          WHEN b.BetType = 33
                                                                          THEN bm.TOPhum
                                                                          WHEN b.BetType IN(31, 32)
                                                                          THEN b.actual_stake * (1 - b.tpositiontaking - ISNULL(b.oddsspread, 0))
                                                                          ELSE 0
                                                                      END) * b.actualrate * cs.ToteFee
                                                             END) --FeeDue2 
                    + SUM((CASE b.BetType
                               WHEN 31
                               THEN b.actual_stake * cs.ToteCommWin * (1 - b.tpositiontaking - ISNULL(oddsspread, 0))
                               WHEN 32
                               THEN b.actual_stake * cs.ToteCommPlace * (1 - b.tpositiontaking - ISNULL(oddsspread, 0))
                               WHEN 33
                               THEN bm.TOPhum * cs.ToteCommWP
                               ELSE 0
                           END) * b.actualrate) --commIncomeIBC
                    - SUM(b.scomm * b.actualrate)) AS RealIncome,
                           SUM(CASE
                                   WHEN b.BetType = 33
                                   THEN bm.TOIBC * b.actualrate
                                   ELSE b.actual_stake * ISNULL(oddsspread, 0) * b.actualrate
                               END) AS RealTurnover
                    FROM bettrans AS b WITH (nolock)
                         INNER JOIN #CommSetting AS cs ON b.matchid = cs.matchid
                         LEFT JOIN
                    (
                        SELECT refno,
                               SUM(CASE
                                       WHEN BetType = 32
                                            AND liveawayscore = 0
                                       THEN 0
                                       ELSE stake * ISNULL(oddsspread, 0)
                                   END) AS TOIBC,
                               -SUM((winlost - stake) * ISNULL(oddsspread, 0)) AS WLIBC,
                               SUM(CASE
                                       WHEN BetType = 32
                                            AND liveawayscore = 0
                                       THEN 0
                                       WHEN BetType = 31
                                            OR (BetType = 32
                                                AND liveawayscore <> 0)
                                       THEN stake * (1 - tpositiontaking - ISNULL(oddsspread, 0))
                                       ELSE 0
                                   END) AS TOPhum
                        FROM bettransm WITH (nolock)
                        GROUP BY refno
                    ) AS bm ON b.transid = bm.refno
                         INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
                         LEFT JOIN #DepositAgent AS dep ON b.recommend = dep.CustId
                    WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                          AND sb.ProductId = 2
                          AND b.matchid > 0
                          AND b.ruben = 1
                          AND b.statusId NOT IN(101, 102, 103, 121)
                    GROUP BY CASE
                                 WHEN dep.CustId IS NULL
                                 THEN 'Credit'
                                 ELSE 'Deposit'
                             END;
         END;
         BEGIN -- INSERT INTO #Data

             INSERT INTO #Data
                    SELECT 'Racing',
                           Site,
                           MemberWinLoss,
                           SMAWinLoss,
                           Commission,
                           RealIncome,
                           RealIncome AS VirtualIncome,
                           RealTurnover AS RealTurnover,
                           0 AS VirtualTurnover
                    FROM @RBWinlost;
         END;
     END;
     BEGIN -- #SumTable
         BEGIN -- CREATE TABLE #SumTable
             CREATE TABLE #SumTable
             (site                   VARCHAR(10),
              matchid                INT,
              BetType                INT,
              liveindicator          BIT,
              winlost_actualrate     MONEY,
              winlost_virtualrate    MONEY,
              position_actualrate    MONEY,
              position_virtualrate   MONEY,
              commission_actualrate  MONEY,
              commission_virtualrate MONEY,
              income_actualrate      MONEY,
              income_virtualrate     MONEY,
              turnover_actualrate    MONEY,
              turnover_virtualrate   MONEY
             );
         END;
         BEGIN -- bettrans

             INSERT INTO #SumTable
                    SELECT CASE
                               WHEN dep.CustId IS NULL
                               THEN 'Credit'
                               ELSE 'Deposit'
                           END AS site,
                           matchid,
                           b.BetType,
                           liveindicator,
                           SUM((winlost - actual_stake) * actualrate) AS winlost_actualrate,
                           SUM((winlost - actual_stake) * virtualrate) AS winlost_virtualrate,
                           SUM((awinlost + mwinlost + swinlost) * actualrate) AS position_actualrate,
                           SUM((awinlost + mwinlost + swinlost) * virtualrate) AS position_virtualrate,
                           SUM(scomm * actualrate) AS commission_actualrate,
                           SUM(scomm * virtualrate) AS commission_virtualrate,
                           SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) AS income_actualrate,
                           SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * virtualrate) AS income_virtualrate,
                           SUM((1 - tpositiontaking) * stake * actualrate) AS turnover_actualrate,
                           SUM((1 - tpositiontaking) * stake * virtualrate) AS turnover_virtualrate
                    FROM bettrans AS b WITH (NOLOCK)
                         LEFT JOIN #DepositAgent AS dep ON b.recommend = dep.CustId
                         LEFT JOIN @AllCasinoBetType c ON c.BetType = b.BetType
                    WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                          AND c.BetType IS NULL
                          AND b.ruben = 1
                          AND b.statusId NOT IN(101, 102, 103, 121)
                    GROUP BY matchid,
                             b.BetType,
                             liveindicator,
                             CASE
                                 WHEN dep.CustId IS NULL
                                 THEN 'Credit'
                                 ELSE 'Deposit'
                             END;
         END;
         BEGIN -- bettransRNG

             INSERT INTO #SumTable
                    SELECT CASE
                               WHEN dep.CustId IS NULL
                               THEN 'Credit'
                               ELSE 'Deposit'
                           END AS site,
                           0 AS matchid,
                           71 AS BetType,
                           0 AS liveindicator,
                           SUM((winlost - actual_stake) * actualrate) AS winlost_actualrate,
                           SUM((winlost - actual_stake) * virtualrate) AS winlost_virtualrate,
                           SUM((awinlost + mwinlost + swinlost) * actualrate) AS position_actualrate,
                           SUM((awinlost + mwinlost + swinlost) * virtualrate) AS position_virtualrate,
                           SUM(scomm * actualrate) AS commission_actualrate,
                           SUM(scomm * virtualrate) AS commission_virtualrate,
                           SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) AS income_actualrate,
                           SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * virtualrate) AS income_virtualrate,
                           SUM((1 - tpositiontaking) * stake * actualrate) AS turnover_actualrate,
                           SUM((1 - tpositiontaking) * stake * virtualrate) AS turnover_virtualrate
                    FROM bettransRNG AS b WITH (NOLOCK)
                         LEFT JOIN #DepositAgent AS dep ON b.recommend = dep.CustId
                         INNER JOIN @CasinoBetType c ON c.BetType = b.gameID
                    WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                          AND b.statusId NOT IN(0, 1, 101, 102, 103, 121)
                    GROUP BY CASE
                                 WHEN dep.CustId IS NULL
                                 THEN 'Credit'
                                 ELSE 'Deposit'
                             END;
         END;
         BEGIN -- bettransLC

             INSERT INTO #SumTable
                    SELECT CASE
                               WHEN dep.CustId IS NULL
                               THEN 'Credit'
                               ELSE 'Deposit'
                           END AS site,
                           0 AS matchid,
                           b.gameId AS BetType,
                           0 AS liveindicator,
                           SUM((winlost - actual_stake) * actualrate) AS winlost_actualrate,
                           SUM((winlost - actual_stake) * virtualrate) AS winlost_virtualrate,
                           SUM((awinlost + mwinlost + swinlost) * actualrate) AS position_actualrate,
                           SUM((awinlost + mwinlost + swinlost) * virtualrate) AS position_virtualrate,
                           SUM(scomm * actualrate) AS commission_actualrate,
                           SUM(scomm * virtualrate) AS commission_virtualrate,
                           SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) AS LineTotal_actualrate,
                           SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * virtualrate) AS LineTotal_virtualrate,
                           SUM((1 - tpositiontaking) * ABS(b.gameId) * actualrate) AS turnover_actualrate,
                           SUM((1 - tpositiontaking) * ABS(b.gameId) * virtualrate) AS turnover_virtualrate
                    FROM bettransLC AS b WITH (NOLOCK)
                         LEFT JOIN #DepositAgent AS dep ON b.recommend = dep.CustId
                         INNER JOIN @LiveCasinoBetType c ON c.BetType = b.gameID
                    WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                          AND b.statusId NOT IN(0, 1, 101, 102, 103, 121)
                    GROUP BY b.gameId,
                             CASE
                                 WHEN dep.CustId IS NULL
                                 THEN 'Credit'
                                 ELSE 'Deposit'
                             END;
         END;
         BEGIN -- Update MatchId
             UPDATE #SumTable
               SET
                   MatchID = CASE
                                 WHEN MatchID IN(0, 71, 208, 209, 210)
                                 THEN 0
                                 ELSE MatchID
                             END,
                   BetType = CASE
                                 WHEN BetType BETWEEN 2101 AND 2399
                                 THEN 71
                                 ELSE BetType
                             END;
         END;
     END;
     BEGIN -- Soccer
         INSERT INTO #Data
                SELECT 'Soccer',
                       Site AS Site,
                       SUM(winlost_virtualrate) AS MemberWinLoss,
                       SUM(position_virtualrate) AS SMAWinLoss,
                       SUM(commission_virtualrate) AS Commission,
                       SUM(income_actualrate) AS RealIncome,
                       SUM(income_virtualrate) AS VirtualIncome,
                       SUM(turnover_actualrate) AS RealTurnover,
                       SUM(turnover_virtualrate) AS VirtualTurnover
                FROM #SumTable AS b WITH (NOLOCK)
                     INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
                     INNER JOIN #Match m ON b.matchid = m.matchid
                WHERE sb.ProductId = 1
                      AND sb.EventType IN(1, 2)
                     AND m.SportType = 1
                     AND sb.SubProduct NOT IN('MG-SuperLive', 'BT-Sold', 'BT-Bought', 'BT-Comm')
                AND m.type = CASE
                                 WHEN b.BetType = 10
                                 THEN 'outright'
                                 ELSE 'match'
                             END
                GROUP BY Site;
     END;
     BEGIN -- Metric Gaming - Superlive

         INSERT INTO #Data
                SELECT 'Metric Gaming - Superlive',
                       Site AS Site,
                       SUM(winlost_virtualrate) AS MemberWinLoss,
                       SUM(position_virtualrate) AS SMAWinLoss,
                       SUM(commission_virtualrate) AS Commission,
                       SUM(income_actualrate) AS RealIncome,
                       SUM(income_virtualrate) AS VirtualIncome,
                       SUM(turnover_actualrate) AS RealTurnover,
                       SUM(turnover_virtualrate) AS VirtualTurnover
                FROM #SumTable AS b WITH (NOLOCK)
                     INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
                WHERE sb.ProductId = 1
                      AND sb.EventType = 1
                      AND sb.SubProduct = 'MG-SuperLive'
                GROUP BY Site;
     END;
     BEGIN -- Other Sports

         INSERT INTO #Data
                SELECT 'Other Sports',
                       Site AS Site,
                       SUM(winlost_virtualrate) AS MemberWinLoss,
                       SUM(position_virtualrate) AS SMAWinLoss,
                       SUM(commission_virtualrate) AS Commission,
                       SUM(income_actualrate) AS RealIncome,
                       SUM(income_virtualrate) AS VirtualIncome,
                       SUM(turnover_actualrate) AS RealTurnover,
                       SUM(turnover_virtualrate) AS VirtualTurnover
                FROM #SumTable AS b WITH (NOLOCK)
                     INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
                     INNER JOIN #Match AS m ON m.matchid = b.matchid
                WHERE sb.ProductId = 1
                      AND sb.EventType IN(1, 2)
                     AND m.SportType > 1
                     AND sb.SubProduct NOT IN('MG-SuperLive', 'BT-Sold', 'BT-Bought', 'BT-Comm')
                AND m.type = CASE
                                 WHEN b.BetType = 10
                                 THEN 'outright'
                                 ELSE 'match'
                             END
                GROUP BY Site;
     END;
     BEGIN -- Parlay

         INSERT INTO #Data
                SELECT 'Parlay',
                       Site AS Site,
                       SUM(winlost_virtualrate) AS MemberWinLoss,
                       SUM(position_virtualrate) AS SMAWinLoss,
                       SUM(commission_virtualrate) AS Commission,
                       SUM(income_actualrate) AS RealIncome,
                       SUM(income_virtualrate) AS VirtualIncome,
                       SUM(turnover_actualrate) AS RealTurnover,
                       SUM(turnover_virtualrate) AS VirtualTurnover
                FROM #SumTable AS b WITH (NOLOCK)
                     INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
                WHERE b.BetType IN(9, 29)
                GROUP BY Site;
     END;
     BEGIN -- Sportsbook Total

         INSERT INTO #Data
                SELECT 'Sportsbook Total',
                       Site AS Site,
                       SUM(winlost_virtualrate) AS MemberWinLoss,
                       SUM(position_virtualrate) AS SMAWinLoss,
                       SUM(commission_virtualrate) AS Commission,
                       SUM(income_actualrate) AS RealIncome,
                       SUM(income_virtualrate) AS VirtualIncome,
                       SUM(turnover_actualrate) AS RealTurnover,
                       SUM(turnover_virtualrate) AS VirtualTurnover
                FROM #SumTable AS b WITH (NOLOCK)
                     INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
                     INNER JOIN #Match AS m ON m.matchid = b.matchid
                WHERE sb.ProductId = 1
                      AND ((sb.EventType IN(1, 2)
                      AND sb.SubProduct NOT IN('MG-SuperLive', 'BT-Sold', 'BT-Bought', 'BT-Comm')
                     AND m.type = CASE
                                      WHEN b.BetType = 10
                                      THEN 'outright'
                                      ELSE 'match'
                                  END)
                OR (sb.EventType = 1
                    AND sb.SubProduct = 'MG-SuperLive')
                OR (b.BetType IN(9, 29)))
                GROUP BY Site;
     END;
     BEGIN -- Sportsbook Live Total

         INSERT INTO #Data
                SELECT 'Sportsbook Live Total',
                       Site AS Site,
                       SUM(winlost_virtualrate) AS MemberWinLoss,
                       SUM(position_virtualrate) AS SMAWinLoss,
                       SUM(commission_virtualrate) AS Commission,
                       SUM(income_actualrate) AS RealIncome,
                       SUM(income_virtualrate) AS VirtualIncome,
                       SUM(turnover_actualrate) AS RealTurnover,
                       SUM(turnover_virtualrate) AS VirtualTurnover
                FROM #SumTable AS b WITH (NOLOCK)
                     INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
                     INNER JOIN #Match AS m ON m.matchid = b.matchid
                WHERE sb.ProductId = 1
                      AND ((sb.EventType IN(1, 2)
                      AND sb.SubProduct NOT IN('MG-SuperLive', 'BT-Sold', 'BT-Bought', 'BT-Comm')
                     AND m.type = CASE
                                      WHEN b.BetType = 10
                                      THEN 'outright'
                                      ELSE 'match'
                                  END)
                OR (sb.EventType = 1
                    AND sb.SubProduct = 'MG-SuperLive')
                OR (b.BetType IN(9, 29)))
         AND b.liveindicator = 1
                GROUP BY Site;
     END;
     BEGIN -- Sportsbook Non-Live Total

         INSERT INTO #Data
                SELECT 'Sportsbook Non-Live Total',
                       Site AS Site,
                       SUM(winlost_virtualrate) AS MemberWinLoss,
                       SUM(position_virtualrate) AS SMAWinLoss,
                       SUM(commission_virtualrate) AS Commission,
                       SUM(income_actualrate) AS RealIncome,
                       SUM(income_virtualrate) AS VirtualIncome,
                       SUM(turnover_actualrate) AS RealTurnover,
                       SUM(turnover_virtualrate) AS VirtualTurnover
                FROM #SumTable AS b WITH (NOLOCK)
                     INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
                     INNER JOIN #Match AS m ON m.matchid = b.matchid
                WHERE sb.ProductId = 1
                      AND ((sb.EventType IN(1, 2)
                      AND sb.SubProduct NOT IN('MG-SuperLive', 'BT-Sold', 'BT-Bought', 'BT-Comm')
                     AND m.type = CASE
                                      WHEN b.BetType = 10
                                      THEN 'outright'
                                      ELSE 'match'
                                  END)
                OR (sb.EventType = 1
                    AND sb.SubProduct = 'MG-SuperLive')
                OR (b.BetType IN(9, 29)))
         AND b.liveindicator = 0
                GROUP BY Site;
     END;
     BEGIN -- RM

         INSERT INTO #Data
                SELECT 'RM',
                       CASE
                           WHEN m.sporttype = 1
                                AND b.recommend = 52466
                           THEN 'Soccer 8RM'
                           WHEN m.sporttype = 1
                                AND b.recommend = 5707545
                           THEN 'Soccer BARM'
                           WHEN m.sporttype > 1
                                AND b.recommend = 52466
                           THEN 'Other Sports 8RM'
                           WHEN m.sporttype > 1
                                AND b.recommend = 5707545
                           THEN 'Other Sports BARM'
                           ELSE ''
                       END AS Site,
                       -SUM(winlost - actual_stake) MemberWinLoss,
                       -SUM(awinlost + mwinlost + swinlost) SMAWinLoss,
                       SUM(scomm) Commission,
                       -SUM(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) RealIncome,
                       -SUM(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) VirtualIncome,
                       -SUM((1 - tpositiontaking) * stake) RealTurnover,
                       -SUM((1 - tpositiontaking) * stake) VirtualTurnover
                FROM bettrans b WITH (NOLOCK)
                     INNER JOIN #Match m ON b.matchid = m.matchid
                WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                      AND b.ruben = 1
                      AND b.statusID NOT IN(101, 102, 103, 121)
                     AND b.recommend IN(52466, 5707545)
                GROUP BY CASE
                             WHEN m.sporttype = 1
                                  AND b.recommend = 52466
                             THEN 'Soccer 8RM'
                             WHEN m.sporttype = 1
                                  AND b.recommend = 5707545
                             THEN 'Soccer BARM'
                             WHEN m.sporttype > 1
                                  AND b.recommend = 52466
                             THEN 'Other Sports 8RM'
                             WHEN m.sporttype > 1
                                  AND b.recommend = 5707545
                             THEN 'Other Sports BARM'
                             ELSE ''
                         END;
     END;
     BEGIN -- BetTrade

         INSERT INTO #Data
                SELECT 'Bettrade',
                       Site AS Site,
                       SUM(b.winlost_actualrate) AS MemberWinLoss,
                       SUM(b.position_actualrate) AS SMAWinLoss,
                       0 AS Commission,
                       SUM(income_actualrate) AS RealIncome,
                       SUM(income_actualrate) AS VirtualIncome,
                       0 AS RealTurnover,
                       0 AS VirtualTurnover
                FROM #SumTable AS b WITH (NOLOCK)
                     INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
                WHERE sb.ProductId = 1
                      AND sb.EventType = 1
                      AND sb.SubProduct = 'BT-Comm'
                GROUP BY Site;
     END;
     BEGIN -- Live Casino

         INSERT INTO #Data
                SELECT 'Live Casino',
                       Site AS Site,
                       SUM(winlost_actualrate) AS MemberWinLoss,
                       SUM(position_actualrate) AS SMAWinLoss,
                       SUM(commission_actualrate) AS Commission,
                       SUM(income_actualrate) AS RealIncome,
                       SUM(income_virtualrate) AS VirtualIncome,
                       SUM(turnover_actualrate) AS RealTurnover,
                       SUM(turnover_virtualrate) AS VirtualTurnover
                FROM #SumTable AS b WITH (NOLOCK)
                     INNER JOIN @LiveCasinoBetType AS s ON s.BetType = b.BetType
                GROUP BY Site;
     END;
     BEGIN -- Casino
         INSERT INTO #Data
                SELECT 'Casino',
                       Site AS Site,
                       SUM(winlost_actualrate) AS MemberWinLoss,
                       SUM(position_actualrate) AS SMAWinLoss,
                       SUM(commission_actualrate) AS Commission,
                       SUM(income_actualrate) AS RealIncome,
                       SUM(income_virtualrate) AS VirtualIncome,
                       SUM(turnover_actualrate) AS RealTurnover,
                       SUM(turnover_virtualrate) AS VirtualTurnover
                FROM #SumTable AS b WITH (NOLOCK)
                     INNER JOIN @CasinoBetType AS s ON s.BetType = b.BetType
                GROUP BY Site;
     END;
     BEGIN -- INSERT #Data - UniversalProduct

         INSERT INTO #Data
                SELECT u.Name,
                       Site AS Site,
                       SUM(winlost_virtualrate) AS MemberWinLoss,
                       SUM(position_virtualrate) AS SMAWinLoss,
                       SUM(commission_virtualrate) AS Commission,
                       SUM(income_actualrate) AS RealIncome,
                       SUM(income_virtualrate) AS VirtualIncome,
                       SUM(turnover_actualrate) AS RealTurnover,
                       SUM(turnover_virtualrate) AS VirtualTurnover
                FROM #SumTable AS b WITH (NOLOCK)
                     INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
                     INNER JOIN @UniversalProduct u ON u.Id = sb.ProductId
                GROUP BY Site,
                         u.Name;
     END;
     BEGIN -- Query

         SELECT ISNULL(p.OrderNumber, 0) GroupId,
                d.Product AS GroupName,
                d.Site AS RowName,
                d.MemberWinLoss AS MemberWinLoss,
                d.SMAWinLoss AS SMAWinLoss,
                d.Commission AS Commission,
                d.RealIncome AS RealIncome,
                d.VirtualIncome AS VirtualIncome,
                d.RealIncome - d.VirtualIncome AS VarianceIncome,
                d.RealTurnover AS RealTurnover,
                d.VirtualTurnover AS VirtualTurnover,
                ISNULL(so.OrderNumber, 0) Order2
         FROM #Data AS d
              LEFT JOIN @RMOrder so ON d.Site = so.Product
              LEFT JOIN @ProductOrder p ON p.Product = d.Product
         ORDER BY GroupId,
                  Order2,
                  RowName;
     END;
     DROP TABLE #SportBetType;
     DROP TABLE #DepositAgent;
     DROP TABLE #CommSetting;
     DROP TABLE #SumTable;
     DROP TABLE #Data;
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinLoss_Products] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CompanyWinLoss_Products] TO [vnteam];
GO