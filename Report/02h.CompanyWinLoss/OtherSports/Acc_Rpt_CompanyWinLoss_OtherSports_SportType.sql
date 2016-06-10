IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Acc_Rpt_CompanyWinLoss_OtherSports_SportType]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_OtherSports_SportType];
GO
CREATE PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_OtherSports_SportType] @StartDate SMALLDATETIME,
                                                                      @EndDate   SMALLDATETIME,
                                                                      @IsLive    INT           = 2
AS

/*
Creator: Jacob
Date: 2016-03-01
Task:  Casino Integration Improvement - Implement Company Winloss By Products report [#48448]
DB: DBACC/bodb02

Revisions:
- 20160301@Jacob: Initialize Company Win Loss Report

Parameters:
@IsLive: 2 - ALL. 0 - Non-Live. 1 - Live
Example:
EXEC [Acc_Rpt_CompanyWinLoss_OtherSports_SportType] @EndDate='2020-01-01',@StartDate='2016-01-01', @IsLive = 2

*/

     SET NOCOUNT ON;
     BEGIN --#SportBetType     
         DECLARE @isTest BIT= 0;
         SELECT @isTest = dbo.f_CheckSPVersion(@@PROCID);
         CREATE TABLE #SportBetType(BetType INT);
         INSERT INTO #SportBetType
                SELECT s.BetType
                FROM dbo.f_SportBetTypeMatrix_Sel(1, 0, 0, 2, '', '', @isTest) s
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
          type      VARCHAR(10),
          SportType INT,
          SportName NVARCHAR(50),
          PRIMARY KEY(MatchId, type)
         );
         INSERT INTO #Match
                SELECT m.MatchId,
                       m.type,
                       s.sporttype,
                       s.sportname
                FROM
                (
                    SELECT MatchId,
                           LeagueId,
                           'match' AS type
                    FROM Match WITH (NOLOCK)
                    WHERE EventDate BETWEEN @StartDate AND @EndDate
                    UNION ALL
                    SELECT orid,
                           LeagueId,
                           'outright' AS type
                    FROM outright WITH (NOLOCK)
                    WHERE EventDate BETWEEN @StartDate AND @EndDate
                ) m
                INNER JOIN league l WITH (NOLOCK) ON m.LeagueId = l.LeagueId
                INNER JOIN sports s WITH (NOLOCK) ON s.sporttype = l.sporttype
                WHERE l.sporttype > 1;
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
     BEGIN -- Sport Type
         INSERT INTO #Data
                SELECT m.SportType GroupId,
                       m.SportName GroupName,
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
                       SUM((1 - tpositiontaking) * stake * actualrate) AS RealTurnover,
                       SUM((1 - tpositiontaking) * stake * virtualrate) AS VirtualTurnover
                FROM bettrans AS b WITH (NOLOCK)
                     INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
                     LEFT JOIN #DepositAgent AS dep ON b.recommend = dep.CustId
                     INNER JOIN #Match AS m ON b.MatchId = m.MatchId
                WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                      AND (@IsLive > 1
                           OR b.liveindicator = @IsLive)
                      AND m.type = CASE
                                       WHEN b.BetType = 10
                                       THEN 'outright'
                                       ELSE 'match'
                                   END
                      AND b.ruben = 1
                      AND b.statusId NOT IN(101, 102, 103, 121)
                GROUP BY m.SportType,
                         m.SportName,
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
                           THEN '8RM'
                           WHEN b.recommend = 5707545
                           THEN 'BARM'
                           ELSE ''
                       END AS RowName,
                       -SUM((winlost - actual_stake) * actualrate) MemberWinLoss,
                       -SUM((awinlost + mwinlost + swinlost) * actualrate) AS SMAWinLoss,
                       SUM(scomm * actualrate) Commission,
                       -SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) AS RealIncome,
                       -SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * virtualrate) AS VirtualIncome,
                       -SUM((1 - tpositiontaking) * stake * actualrate) AS RealTurnover,
                       -SUM((1 - tpositiontaking) * stake * virtualrate) AS VirtualTurnover
                FROM bettrans b WITH (NOLOCK)
                     INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
                     INNER JOIN #Match AS m ON b.MatchId = m.MatchId
                WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                      AND (@IsLive > 1
                           OR b.liveindicator = @IsLive)
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
                             THEN '8RM'
                             WHEN b.recommend = 5707545
                             THEN 'BARM'
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
GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinLoss_OtherSports_SportType] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CompanyWinLoss_OtherSports_SportType] TO [vnteam];
GO