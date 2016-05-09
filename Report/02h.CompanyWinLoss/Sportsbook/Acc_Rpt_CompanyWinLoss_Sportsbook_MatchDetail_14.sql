IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Acc_Rpt_CompanyWinLoss_Sportsbook_MatchDetail_14]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Sportsbook_MatchDetail_14];
GO
CREATE PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Sportsbook_MatchDetail_14] @StartDate SMALLDATETIME,
                                                                       @EndDate   SMALLDATETIME,
                                                                       @SportType SMALLINT      = 1,
                                                                       @BetType   INT           = 1,
                                                                       @IsHedge   BIT           = 0,
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
EXEC [Acc_Rpt_CompanyWinLoss_Sportsbook_MatchDetail_14] @EndDate='2020-01-01',@StartDate='2016-01-01', @SportType=1, @BetType=1, @IsHedge = 0, @IsLive = 2

*/

     SET NOCOUNT ON;
     BEGIN -- #Match

         CREATE TABLE #Match
         (matchid   INT,
          sporttype SMALLINT,
          type      VARCHAR(10),
          eventdate DATETIME
         );
         INSERT INTO #Match
                SELECT DISTINCT
                       m.matchid,
                       l.sporttype,
                       m.type,
                       eventdate
                FROM
                (
                    SELECT matchid,
                           leagueid,
                           eventdate,
                           'match' AS type
                    FROM match14 WITH (NOLOCK)
                    WHERE eventdate BETWEEN @StartDate AND @EndDate
                    UNION ALL
                    SELECT orid,
                           leagueid,
                           eventdate,
                           'outright' AS type
                    FROM outright14 WITH (NOLOCK)
                    WHERE eventdate BETWEEN @StartDate AND @EndDate
                ) m
                INNER JOIN league l WITH (NOLOCK) ON m.leagueid = l.leagueid
                WHERE l.sporttype = @SportType;
     END;
     BEGIN -- #Data

         CREATE TABLE #Data
         (MatchId         INT,
          MatchCode       VARCHAR(100),
          EventDate       DATETIME,
          SportType       INT,
          IsNeutral       BIT,
          HomeId          INT,
          AwayId          INT,
          LeagueId        INT,
          MemberWinLoss   MONEY,
          SMAWinLoss      MONEY,
          Commission      MONEY,
          RealIncome      MONEY,
          VirtualIncome   MONEY,
          RealTurnover    MONEY,
          VirtualTurnover MONEY
         );
     END;
     BEGIN -- Outright

         IF @BetType = 10
             BEGIN
                 INSERT INTO #Data
                        SELECT b.matchid,
                               o.matchcode,
                               o.eventdate,
                               1 AS SportType,
                               0 AS IsNeutral,
                               o.TeamId AS HomeId,
                               0 AS AwayId,
                               l.leagueid,
                               SUM((winlost - actual_stake) * actualrate) MemberWinLoss,
                               SUM((awinlost + mwinlost + swinlost) * actualrate) AS SMAWinLoss,
                               SUM(scomm * actualrate) Commission,
                               SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) RealIncome,
                               SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * virtualrate) VirtualIncome,
                               SUM((1 - tpositiontaking) * ABS(b.stake) * actualrate) RealTurnover,
                               SUM((1 - tpositiontaking) * ABS(b.stake) * virtualrate) VirtualTurnover
                        FROM bettrans14 b WITH (nolock)
                             INNER JOIN outright14 o WITH (nolock) ON b.matchid = o.orid
                             INNER JOIN league l WITH (nolock) ON o.leagueid = l.leagueid
                             INNER JOIN sports sp WITH (nolock) ON l.sporttype = sp.sporttype
                        WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                              AND b.matchid > 0
                              AND b.BetType = 10
                              AND b.ruben = 1
                              AND b.statusID NOT IN(101, 102, 103, 121)
                        GROUP BY b.matchid,
                                 o.matchcode,
                                 o.eventdate,
                                 o.TeamId,
                                 l.leagueid;
             END;
     END;
     BEGIN -- Hedge

         IF @BetType <> 10
            AND @IsHedge = 1
             BEGIN
                 INSERT INTO #Data
                        SELECT b.matchid,
                               m.matchcode,
                               m.eventdate,
                               m.sporttype,
                               ISNULL(m.isNeutral, 0) AS IsNeutral,
                               m.HomeId,
                               m.AwayId,
                               m.leagueid,
                               SUM((winlost - actual_stake) * actualrate) MemberWinLoss,
                               SUM((awinlost + mwinlost + swinlost) * actualrate) AS SMAWinLoss,
                               SUM(scomm * actualrate) Commission,
                               SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) RealIncome,
                               SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * virtualrate) VirtualIncome,
                               SUM((1 - tpositiontaking) * ABS(b.stake) * actualrate) RealTurnover,
                               SUM((1 - tpositiontaking) * ABS(b.stake) * virtualrate) VirtualTurnover
                        FROM bettrans14 b WITH (nolock)
                             INNER JOIN match14 m WITH (nolock) ON b.matchid = m.matchid
                        WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                              AND b.BetType = @BetType
                              AND (@IsLive > 1
                                   OR b.liveindicator = @IsLive)
                              AND matchcode LIKE '%hedge%'
                              AND b.matchid > 0
                              AND b.ruben = 1
                              AND statusID NOT IN(101, 102, 103, 121)
                        GROUP BY b.matchid,
                                 m.matchcode,
                                 m.eventdate,
                                 m.sporttype,
                                 m.HomeId,
                                 m.AwayId,
                                 m.leagueid,
                                 m.isNeutral
                        ORDER BY m.leagueid,
                                 m.matchcode,
                                 m.HomeId;
             END;
     END;
     BEGIN -- Non-Hedge

         IF @BetType <> 10
            AND @IsHedge = 0
             BEGIN
                 INSERT INTO #Data
                        SELECT b.matchid,
                               m.matchcode,
                               m.eventdate,
                               m.sporttype,
                               ISNULL(m.isNeutral, 0) AS IsNeutral,
                               m.HomeId,
                               m.AwayId,
                               m.leagueid,
                               SUM((winlost - actual_stake) * actualrate) MemberWinLoss,
                               SUM((awinlost + mwinlost + swinlost) * actualrate) AS SMAWinLoss,
                               SUM(scomm * actualrate) Commission,
                               SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) RealIncome,
                               SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * virtualrate) VirtualIncome,
                               SUM((1 - tpositiontaking) * ABS(b.stake) * actualrate) RealTurnover,
                               SUM((1 - tpositiontaking) * ABS(b.stake) * virtualrate) VirtualTurnover
                        FROM bettrans14 b WITH (nolock)
                             INNER JOIN match14 m WITH (nolock) ON b.matchid = m.matchid
                        WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                              AND b.BetType = @BetType
                              AND (@IsLive > 1
                                   OR b.liveindicator = @IsLive)
                              AND m.matchcode NOT LIKE '%hedge%'
                              AND b.matchid > 0
                              AND b.ruben = 1
                              AND statusID NOT IN(101, 102, 103, 121)
                        GROUP BY b.matchid,
                                 m.matchcode,
                                 m.eventdate,
                                 m.sporttype,
                                 m.HomeId,
                                 m.AwayId,
                                 b.liveindicator,
                                 b.BetType,
                                 m.leagueid,
                                 m.isNeutral
                        ORDER BY m.leagueid,
                                 m.matchcode,
                                 m.HomeId;
             END;
     END;
     BEGIN -- RM

         INSERT INTO #Data
                SELECT 0 AS matchid,
                       CASE
                           WHEN b.recommend = 52466
                           THEN '8RM'
                           ELSE 'BARM'
                       END MatchCode,
                       '1990-01-01' AS EventDate,
                       0 AS SportType,
                       0 AS IsNeutral,
                       0 HomeId,
                       0 AwayId,
                       0 LeagueId,
                       -SUM((winlost - actual_stake) * actualrate) MemberWinLoss,
                       -SUM((awinlost + mwinlost + swinlost) * actualrate) AS SMAWinLoss,
                       SUM(scomm * actualrate) Commission,
                       -SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) AS RealIncome,
                       -SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * virtualrate) AS VirtualIncome,
                       -SUM((1 - tpositiontaking) * stake * actualrate) AS RealTurnover,
                       -SUM((1 - tpositiontaking) * stake * virtualrate) AS VirtualTurnover
                FROM bettrans14 b WITH (NOLOCK)
                     INNER JOIN #Match m ON b.matchid = m.matchid
                WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                      AND b.BetType = @BetType
                      AND (@IsLive > 1
                           OR b.liveindicator = @IsLive)
                      AND m.type = CASE
                                       WHEN b.BetType = 10
                                       THEN 'outright'
                                       ELSE 'match'
                                   END
                      AND b.matchid > 0
                      AND b.ruben = 1
                      AND b.statusID NOT IN(101, 102, 103, 121)
                     AND b.recommend IN(52466, 5707545)
                GROUP BY CASE
                             WHEN b.recommend = 52466
                             THEN '8RM'
                             ELSE 'BARM'
                         END;
     END;
     BEGIN -- Query

         SELECT d.MatchId,
                d.MatchCode,
                d.EventDate,
                d.SportType,
                d.IsNeutral,
                d.HomeId,
                d.AwayId,
                d.LeagueId,
                d.MemberWinLoss AS MemberWinLoss,
                d.SMAWinLoss AS SMAWinLoss,
                d.Commission AS Commission,
                d.RealIncome AS RealIncome,
                d.VirtualIncome AS VirtualIncome,
                d.RealIncome - d.VirtualIncome AS VarianceIncome,
                d.RealTurnover AS RealTurnover,
                d.VirtualTurnover AS VirtualTurnover
         FROM #Data AS d
         ORDER BY LeagueId,
                  MatchCode;
     END;
     DROP TABLE #Match;
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinLoss_Sportsbook_MatchDetail_14] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CompanyWinLoss_Sportsbook_MatchDetail_14] TO [vnteam];
GO