IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Acc_Rpt_CompanyWinLoss_MetricGaming_MatchDetail]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_MetricGaming_MatchDetail];
GO
CREATE PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_MetricGaming_MatchDetail] @StartDate SMALLDATETIME,
                                                                         @EndDate   SMALLDATETIME,
                                                                         @BetType   INT           = 1,
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
EXEC [Acc_Rpt_CompanyWinLoss_MetricGaming_MatchDetail] @EndDate='2020-01-01',@StartDate='2016-01-01', @BetType=1, @IsLive = 2

*/

     SET NOCOUNT ON;
     BEGIN -- #Data

         CREATE TABLE #Data
         (MatchId         INT,
          MatchCode       VARCHAR(100),
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
     BEGIN -- INSERT INTO #Data

         INSERT INTO #Data
                SELECT b.matchid,
                       m.matchcode,
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
                FROM bettrans b WITH (nolock)
                     INNER JOIN match m WITH (nolock) ON b.matchid = m.matchid
                WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
                      AND b.BetType = @BetType
                      AND (@IsLive > 1
                           OR b.liveindicator = @IsLive)
                      AND b.matchid > 0
                      AND b.ruben = 1
                      AND statusID NOT IN(101, 102, 103, 121)
                GROUP BY b.matchid,
                         m.matchcode,
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
     BEGIN -- Query

         SELECT d.MatchId,
                d.MatchCode,
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
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinLoss_MetricGaming_MatchDetail] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CompanyWinLoss_MetricGaming_MatchDetail] TO [vnteam];
GO