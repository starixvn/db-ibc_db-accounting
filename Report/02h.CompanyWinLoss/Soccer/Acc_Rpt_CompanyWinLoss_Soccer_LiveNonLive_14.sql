IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Acc_Rpt_CompanyWinLoss_Soccer_LiveNonLive_14]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Soccer_LiveNonLive_14];
GO
CREATE PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Soccer_LiveNonLive_14] @StartDate SMALLDATETIME,
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
EXEC [Acc_Rpt_CompanyWinLoss_Soccer_LiveNonLive_14] @EndDate='2020-01-01',@StartDate='2016-01-01'

*/

     SET NOCOUNT ON;
     BEGIN -- #SportBetType	
         DECLARE @isTest BIT= 0;
         SELECT @isTest = dbo.f_CheckSPVersion(@@PROCID);
         CREATE TABLE #SportBetType(BetType INT);
         INSERT INTO #SportBetType
                SELECT BetType
                FROM bodb02.dbo.f_SportBetTypeMatrix_Sel(1, 1, 0, 2, '', '', @isTest)
                WHERE SubProduct NOT IN('MG-SuperLive', 'BT-Sold', 'BT-Bought', 'BT-Comm')
                AND EventType IN(1, 2);
     END;
     BEGIN -- #DepositAgent

         CREATE TABLE #DepositAgent
         (CustId INT PRIMARY KEY
         );
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
     BEGIN -- #Match

         CREATE TABLE #Match
         (MatchId   INT,
          MatchCode NVARCHAR(50),
          type      VARCHAR(10),
          PRIMARY KEY(MatchId, type)
         );
         INSERT INTO #Match
                SELECT m.MatchId,
                       m.MatchCode,
                       m.type
                FROM
                (
                    SELECT MatchId,
                           LeagueId,
                           MatchCode,
                           'match' AS type
                    FROM match14 WITH (NOLOCK)
                    WHERE EventDate BETWEEN @StartDate AND @EndDate
                    UNION ALL
                    SELECT orid,
                           LeagueId,
                           MatchCode,
                           'outright' AS type
                    FROM outright14 WITH (NOLOCK)
                    WHERE EventDate BETWEEN @StartDate AND @EndDate
                ) m
                INNER JOIN league l WITH (NOLOCK) ON m.LeagueId = l.LeagueId
                WHERE l.sporttype = 1;
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
     BEGIN -- Live AND Non-Live
         INSERT INTO #Data
                SELECT liveindicator AS GroupId,
                       CASE liveindicator
                           WHEN 1
                           THEN 'Soccer Live'
                           ELSE 'Soccer Non-Live'
                       END AS GroupName,
                       CASE
                           WHEN dep.CustId IS NULL
                           THEN 'Credit'
                           ELSE 'Deposit'
                       END AS RowName,
                       SUM((winlost - actual_stake) * actualrate) MemberWinLoss,
                       SUM((awinlost + mwinlost + swinlost) * actualrate) AS SMAWinLoss,
                       SUM(scomm * actualrate) Commission,
                       SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) AS RealIncome,
                       SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * virtualrate) AS VirtualIncome,
                       SUM((1 - tpositiontaking) * ABS(stake) * actualrate) AS RealTurnover,
                       SUM((1 - tpositiontaking) * ABS(stake) * virtualrate) AS VirtualTurnover
                FROM bettrans14 AS b WITH (NOLOCK)
                     INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
                     LEFT JOIN #DepositAgent AS dep ON b.recommend = dep.CustId
                     INNER JOIN #Match m ON b.MatchId = m.MatchId
                WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                      AND m.type = CASE
                                       WHEN b.BetType = 10
                                       THEN 'outright'
                                       ELSE 'match'
                                   END
                      AND b.ruben = 1
                      AND b.statusId NOT IN(101, 102, 103, 121)
                GROUP BY liveindicator,
                         CASE liveindicator
                             WHEN 1
                             THEN 'Soccer Live'
                             ELSE 'Soccer Non-Live'
                         END,
                         CASE
                             WHEN dep.CustId IS NULL
                             THEN 'Credit'
                             ELSE 'Deposit'
                         END;
     END;
     BEGIN -- RM   

         INSERT INTO #Data
                SELECT 0 AS GroupId,
                       'RM' AS GroupName,
                       CASE
                           WHEN b.recommend = 52466
                           THEN '8RM Total'
                           WHEN b.recommend = 5707545
                           THEN 'BARM Total'
                           ELSE ''
                       END AS Site,
                       -SUM((winlost - actual_stake) * actualrate) MemberWinLoss,
                       -SUM((awinlost + mwinlost + swinlost) * actualrate) AS SMAWinLoss,
                       SUM(scomm * actualrate) Commission,
                       -SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) AS RealIncome,
                       -SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * virtualrate) AS VirtualIncome,
                       SUM((1 - tpositiontaking) * ABS(stake) * actualrate) AS RealTurnover,
                       SUM((1 - tpositiontaking) * ABS(stake) * virtualrate) AS VirtualTurnover
                FROM bettrans14 b WITH (NOLOCK)
                     INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
                     INNER JOIN #Match m ON b.MatchId = m.MatchId
                WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                      AND m.type = CASE
                                       WHEN b.BetType = 10
                                       THEN 'outright'
                                       ELSE 'match'
                                   END
                      AND b.ruben = 1
                      AND b.statusID NOT IN(101, 102, 103, 121)
                     AND b.recommend IN(52466, 5707545)
                GROUP BY CASE
                             WHEN b.recommend = 52466
                             THEN '8RM Total'
                             WHEN b.recommend = 5707545
                             THEN 'BARM Total'
                             ELSE ''
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
         ORDER BY GroupName,
                  RowName;
     END;
     DROP TABLE #SportBetType;
     DROP TABLE #DepositAgent;
     DROP TABLE #Match;
     DROP TABLE #Data;
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinLoss_Soccer_LiveNonLive_14] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CompanyWinLoss_Soccer_LiveNonLive_14] TO [vnteam];
GO