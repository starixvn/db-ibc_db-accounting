IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Acc_Rpt_CompanyWinLoss_Parlay]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Parlay];
GO
CREATE PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Parlay] @StartDate SMALLDATETIME,
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
EXEC [Acc_Rpt_CompanyWinLoss_Parlay] @EndDate='2020-01-01',@StartDate='2016-01-01'

*/

     SET NOCOUNT ON;
     BEGIN -- #DepositAgent
         CREATE TABLE #DepositAgent(custid INT PRIMARY KEY);
         INSERT INTO #DepositAgent
                SELECT c.CustId
                FROM customer AS c WITH (NOLOCK)
                WHERE c.RoleID = 2
                      AND EXISTS
                (
                    SELECT 1
                    FROM f_DepSuper_1('All') dep
                    WHERE c.srecommend = dep.CustId
                )
                AND CustId <> 5707545
                UNION
                SELECT 5707545; --BARM
     END;
     BEGIN -- #Data

         CREATE TABLE #Data
         (GroupId         INT,
          GroupName       NVARCHAR(50),
          RowName         NVARCHAR(50),
          MemberWinLoss   MONEY,
          SMAWinLoss      MONEY,
          Commission      MONEY,
          RealIncome      MONEY,
          VirtualIncome   MONEY,
          RealTurnover    MONEY,
          VirtualTurnover MONEY
         );
     END;
     BEGIN -- Query
         INSERT INTO #Data
                SELECT BetType AS GroupId,
                       CASE
                           WHEN BetType = 29
                           THEN 'System Parlay'
                           ELSE 'Mix Parlay'
                       END AS GroupName,
                       CASE
                           WHEN dep.CustId IS NULL
                           THEN 'Credit'
                           ELSE 'Deposit'
                       END AS RowName,
                       SUM((winlost - actual_stake) * virtualrate) MemberWinlost,
                       SUM((awinlost + mwinlost + swinlost) * actualrate) AS SMAWinLoss,
                       SUM(scomm * actualrate) Commission,
                       SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) RealIncome,
                       SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * virtualrate) VirtualIncome,
                       SUM((1 - tpositiontaking) * ABS(stake) * actualrate) RealTurnover,
                       SUM((1 - tpositiontaking) * ABS(stake) * virtualrate) VirtualTurnover
                FROM bettrans b WITH (NOLOCK)
                     LEFT JOIN #DepositAgent dep ON b.recommend = dep.custid
                WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                      AND BetType IN(9, 29)
                     AND b.ruben = 1
                     AND b.statusID NOT IN(101, 102, 103, 121)
                GROUP BY BetType,
                         CASE
                             WHEN BetType = 29
                             THEN 'System Parlay'
                             ELSE 'Mix Parlay'
                         END,
                         CASE
                             WHEN dep.CustId IS NULL
                             THEN 'Credit'
                             ELSE 'Deposit'
                         END;
     END;
     BEGIN -- Query

         SELECT d.GroupId AS GroupId,
                d.GroupName AS GroupName,
                d.RowName AS RowName,
                d.MemberWinLoss AS MemberWinLoss,
                d.SMAWinLoss AS SMAWinLoss,
                d.Commission AS Commission,
                d.RealIncome AS RealIncome,
                d.VirtualIncome AS VirtualIncome,
                d.RealIncome - d.VirtualIncome AS VarianceIncome,
                d.RealTurnover AS RealTurnover,
                d.VirtualTurnover AS VirtualTurnover
         FROM #Data AS d
         ORDER BY GroupName DESC,
                  RowName;
     END;
     DROP TABLE #Data;
     DROP TABLE #DepositAgent;
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinLoss_Parlay] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CompanyWinLoss_Parlay] TO [vnteam];
GO