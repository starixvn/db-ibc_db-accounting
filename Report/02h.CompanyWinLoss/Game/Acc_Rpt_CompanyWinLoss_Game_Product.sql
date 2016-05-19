IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Acc_Rpt_CompanyWinLoss_Game_Product]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Game_Product];
GO
CREATE PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Game_Product] @StartDate  SMALLDATETIME,
                                                             @EndDate    SMALLDATETIME,
                                                             @CasinoType INT
AS

/*
Creator: Franklin
Date: 2016-02-22
Task:  Casino Integration Improvement - Implement Company Winloss By Products report [#48448]
DB: DBACC/bodb02

Revisions:
- 20160222@Franklin: Initialize Company Win Loss Report

Example:
EXEC [Acc_Rpt_CompanyWinLoss_Game_Product] @EndDate='2020-01-01',@StartDate='2016-01-01', @CasinoType = 1
*/

     SET NOCOUNT ON;
     BEGIN --#SportBetType     
         DECLARE @isTest BIT= 0;
         SELECT @isTest = dbo.f_CheckSPVersion(@@PROCID);
         CREATE TABLE #SportBetType
         (ProductID   INT,
          ProductName NVARCHAR(50),
          BetType     INT,
          RefTable    INT
         );
         INSERT INTO #SportBetType
                SELECT s.ProductID,
                       CASE
                           WHEN s.ProductID = 4
                           THEN 'SLI'
                           WHEN s.ProductID = 6
                           THEN 'MBC - RNG Casino'
                           ELSE p.ProductName
                       END,
                       s.BetType,
                       s.RefTable
                FROM dbo.f_SportBetTypeMatrix_Sel(0, 0, 0, 2, '', '', @isTest) s
                     INNER JOIN Products p WITH (NOLOCK) ON p.ProductID = s.ProductID
                WHERE s.CasinoType = @CasinoType;
     END;
     BEGIN -- #DepositSuper

         CREATE TABLE #DepositSuper
         (CustId INT PRIMARY KEY
         );
         INSERT INTO #DepositSuper
                SELECT CustId
                FROM f_DepSuper_1('All');
     END;
     BEGIN --#ExtraPT
         CREATE TABLE #ExtraPT
         (ProductID  INT,
          Sporttype  INT,
          SubProduct VARCHAR(100),
          SuperID    INT,
          FromDate   DATETIME,
          ToDate     DATETIME,
          ExtraPT    DECIMAL(9, 8)
         );
         INSERT INTO #ExtraPT
                SELECT ProductID,
                       SportType,
                       SubProduct,
                       SuperId,
                       FromDate,
                       ToDate,
                       SUM(ExtraPT) AS ExtraPT
                FROM bodb_ACC.dbo.Acc_GroupExtraPTSetting a WITH (NOLOCK)
                WHERE @StartDate BETWEEN FromDate AND Todate
                      OR @EndDate BETWEEN FromDate AND Todate
                GROUP BY ProductID,
                         SportType,
                         SubProduct,
                         SuperId,
                         FromDate,
                         ToDate;
     END;
     BEGIN -- #Data

         CREATE TABLE #Data
         (GroupId       INT,
          GroupName     NVARCHAR(50),
          RowName       NVARCHAR(50),
          MemberWinLoss MONEY,
          SMAWinLoss    MONEY,
          Commission    MONEY,
          RealIncome    MONEY,
          RealTurnover  MONEY,
          ExtraPT       MONEY
         );
     END;
     IF EXISTS -- BetTrans
     (
         SELECT 1
         FROM #SportBetType
         WHERE RefTable <> 1
               AND RefTable <> 2
     )
         BEGIN
             INSERT INTO #Data
                    SELECT sb.ProductId AS GroupId,
                           sb.ProductName AS GroupName,
                           CASE
                               WHEN dep.CustId IS NULL
                               THEN 'Credit'
                               ELSE 'Deposit'
                           END AS RowName,
                           SUM((winlost - actual_stake) * actualrate) AS MemberWinLoss,
                           SUM((awinlost + mwinlost + swinlost) * actualrate) AS SMAWinLoss,
                           SUM(scomm * actualrate) Commission,
                           SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) AS RealIncome,
                           SUM((1 - tpositiontaking) * stake * actualrate) AS RealTurnover,
                           SUM((winlost - actual_stake) * actualrate * ISNULL(e.ExtraPT, 0)) AS ExtraPT
                    FROM bettrans AS b WITH (NOLOCK)
                         INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
                         LEFT JOIN #DepositSuper AS dep ON b.srecommend = dep.CustId
                         LEFT JOIN #ExtraPT e ON b.srecommend = e.superID
                    WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                          AND sb.RefTable = 0
                          AND b.ruben = 1
                          AND b.statusId NOT IN(101, 102, 103, 121)
                    GROUP BY sb.ProductId,
                             sb.ProductName,
                             CASE
                                 WHEN dep.CustId IS NULL
                                 THEN 'Credit'
                                 ELSE 'Deposit'
                             END;
         END;
     IF EXISTS -- bettransRNG
     (
         SELECT 1
         FROM #SportBetType
         WHERE RefTable = 1
     )
         BEGIN
             INSERT INTO #Data
                    SELECT sb.ProductId AS GroupId,
                           sb.ProductName AS GroupName,
                           CASE
                               WHEN dep.CustId IS NULL
                               THEN 'Credit'
                               ELSE 'Deposit'
                           END AS RowName,
                           SUM((winlost - actual_stake) * actualrate) MemberWinLoss,
                           SUM((awinlost + mwinlost + swinlost) * actualrate) SMAWinLoss,
                           SUM(scomm * actualrate) Commission,
                           SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) RealIncome,
                           SUM((1 - tpositiontaking) * stake * actualrate) RealTurnover,
                           SUM((winlost - actual_stake) * actualrate * ISNULL(e.ExtraPT, 0)) AS ExtraPT
                    FROM bettransRNG b WITH (NOLOCK)
                         INNER JOIN #SportBetType sb ON sb.BetType = b.gameID
                         LEFT JOIN #DepositSuper dep ON b.srecommend = dep.custid
                         LEFT JOIN #ExtraPT e ON b.srecommend = e.superID
                    WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                          AND sb.RefTable = 2
                          AND b.statusID NOT IN(0, 1, 101, 102, 103, 121)
                    GROUP BY sb.ProductId,
                             sb.ProductName,
                             CASE
                                 WHEN dep.CustId IS NULL
                                 THEN 'Credit'
                                 ELSE 'Deposit'
                             END
                    ORDER BY GroupName,
                             RowName;
         END;
     IF EXISTS -- bettransLC
     (
         SELECT 1
         FROM #SportBetType
         WHERE RefTable = 2
     )
         BEGIN -- 

             INSERT INTO #Data
                    SELECT sb.ProductId AS GroupId,
                           sb.ProductName AS GroupName,
                           CASE
                               WHEN dep.CustId IS NULL
                               THEN 'Credit'
                               ELSE 'Deposit'
                           END AS RowName,
                           SUM((winlost - actual_stake) * actualrate) MemberWinLoss,
                           SUM((awinlost + mwinlost + swinlost) * actualrate) SMAWinLoss,
                           SUM(scomm * actualrate) Commission,
                           SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) RealIncome,
                           SUM((1 - tpositiontaking) * stake * actualrate) RealTurnover,
                           SUM((winlost - actual_stake) * actualrate * ISNULL(e.ExtraPT, 0)) AS ExtraPT
                    FROM bettransLC b WITH (NOLOCK)
                         INNER JOIN #SportBetType sb ON sb.BetType = b.gameID
                         LEFT JOIN #DepositSuper dep ON b.srecommend = dep.custid
                         LEFT JOIN #ExtraPT e ON b.srecommend = e.superID
                    WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                          AND sb.RefTable = 3
                          AND b.statusID NOT IN(0, 1, 101, 102, 103, 121)
                    GROUP BY sb.ProductId,
                             sb.ProductName,
                             CASE
                                 WHEN dep.CustId IS NULL
                                 THEN 'Credit'
                                 ELSE 'Deposit'
                             END
                    ORDER BY GroupName,
                             RowName;
         END;
     BEGIN -- Query

         SELECT d.GroupId AS GroupId,
                d.GroupName AS GroupName,
                d.RowName AS RowName,
                d.MemberWinLoss AS MemberWinLoss,
                d.SMAWinLoss AS SMAWinLoss,
                d.Commission AS Commission,
                d.RealIncome AS RealIncome,
                d.RealTurnover AS RealTurnover,
                d.ExtraPT AS ExtraPT,
                d.RealIncome - d.ExtraPT AS AfterExtraPT
         FROM #Data AS d
         ORDER BY GroupName,
                  RowName;
     END;
     DROP TABLE #SportBetType;
     DROP TABLE #DepositSuper;
     DROP TABLE #Data;
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinLoss_Game_Product] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CompanyWinLoss_Game_Product] TO [vnteam];
GO