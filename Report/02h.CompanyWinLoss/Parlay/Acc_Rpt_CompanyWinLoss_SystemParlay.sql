IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Acc_Rpt_CompanyWinLoss_SystemParlay]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_SystemParlay];
GO
CREATE PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_SystemParlay] @StartDate SMALLDATETIME,
                                                             @EndDate   SMALLDATETIME,
                                                             @Site      VARCHAR(20)   = 'ALL'
AS

/*
Creator: Jacob
Date: 2016-03-01
Task:  Casino Integration Improvement - Implement Company Winloss By Products report [#48448]
DB: DBACC/bodb02

Revisions:
- 20160301@Jacob: Initialize Company Win Loss Report
Example:
EXEC [Acc_Rpt_CompanyWinLoss_SystemParlay] @EndDate='2020-01-01',@StartDate='2016-01-01', @Site= 'ALL'

*/

     SET NOCOUNT ON;
     BEGIN -- #DepositAgent

         CREATE TABLE #DepositAgent
         (CustId INT PRIMARY KEY,
          Site   NVARCHAR(50)
         );
         IF @Site = 'Deposit'
            OR @Site = 'ALL'
             BEGIN
                 INSERT INTO #DepositAgent
                        SELECT c.CustId,
                               Site
                        FROM customer AS c WITH (NOLOCK)
                        WHERE c.RoleID = 2
                              AND c.CustId <> 5707545
                              AND EXISTS
                        (
                            SELECT 1
                            FROM f_DepSuper_1('All') dep
                            WHERE c.srecommend = dep.CustId
                        );
                 INSERT INTO #DepositAgent
                        SELECT 5707545,
                               'BEST-ODDS'; --BARM
             END;
         IF @Site = 'Credit'
            OR @Site = 'ALL'
             BEGIN
                 INSERT INTO #DepositAgent
                        SELECT c.CustId,
                               Site
                        FROM customer AS c WITH (NOLOCK)
                        WHERE c.RoleID = 2
                              AND c.CustId <> 52466
                              AND NOT EXISTS
                        (
                            SELECT 1
                            FROM f_DepSuper_1('All') dep
                            WHERE c.srecommend = dep.CustId
                        );
                 INSERT INTO #DepositAgent
                        SELECT 52466,
                               'XYZBET';--8RM;
             END;
     END;
     BEGIN -- #Data

         CREATE TABLE #Data
         (GroupName       NVARCHAR(50),
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
     IF @Site = 'ALL'
         BEGIN
             INSERT INTO #Data
                    SELECT CASE liveawayscore
                               WHEN 1
                               THEN 'Soccer Sport Total'
                               WHEN 2
                               THEN 'Others Sport Total'
                               WHEN 3
                               THEN 'Multi Sport Total'
                               ELSE ''
                           END AS GroupName,
                           'System Parlay('+status+')' AS RowName,
                           SUM((winlost - actual_stake) * virtualrate) MemberWinLost,
                           SUM((awinlost + mwinlost + swinlost) * actualrate) AS SMAWinLoss,
                           SUM(scomm * actualrate) Commission,
                           SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) RealIncome,
                           SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * virtualrate) VirtualIncome,
                           SUM((1 - tpositiontaking) * stake * actualrate) RealTurnover,
                           SUM((1 - tpositiontaking) * stake * virtualrate) VirtualTurnover
                    FROM bettrans b WITH (NOLOCK)
                    WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                          AND BetType = 29
                          AND ruben = 1
                          AND statusID NOT IN(101, 102, 103, 121)
                    GROUP BY 'System Parlay('+status+')',
                             CASE liveawayscore
                                 WHEN 1
                                 THEN 'Soccer Sport Total'
                                 WHEN 2
                                 THEN 'Others Sport Total'
                                 WHEN 3
                                 THEN 'Multi Sport Total'
                                 ELSE ''
                             END;
         END;
     ELSE
         BEGIN -- Query
             INSERT INTO #Data
                    SELECT CASE liveawayscore
                               WHEN 1
                               THEN 'Soccer Sport Total'
                               WHEN 2
                               THEN 'Others Sport Total'
                               WHEN 3
                               THEN 'Multi Sport Total'
                               ELSE ''
                           END AS GroupName,
                           'System Parlay('+status+')' AS RowName,
                           SUM((winlost - actual_stake) * virtualrate) MemberWinLost,
                           SUM((awinlost + mwinlost + swinlost) * actualrate) AS SMAWinLoss,
                           SUM(scomm * actualrate) Commission,
                           SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) RealIncome,
                           SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * virtualrate) VirtualIncome,
                           SUM((1 - tpositiontaking) * stake * actualrate) RealTurnover,
                           SUM((1 - tpositiontaking) * stake * virtualrate) VirtualTurnover
                    FROM bettrans b WITH (NOLOCK)
                         INNER JOIN #DepositAgent dep ON b.recommend = dep.custid
                    WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                          AND BetType = 29
                          AND b.ruben = 1
                          AND statusID NOT IN(101, 102, 103, 121)
                    GROUP BY 'System Parlay('+status+')',
                             CASE liveawayscore
                                 WHEN 1
                                 THEN 'Soccer Sport Total'
                                 WHEN 2
                                 THEN 'Others Sport Total'
                                 WHEN 3
                                 THEN 'Multi Sport Total'
                                 ELSE ''
                             END;
         END;
     BEGIN -- Query

         SELECT d.GroupName AS GroupName,
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

-------------------

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinLoss_SystemParlay] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CompanyWinLoss_SystemParlay] TO [vnteam];
GO