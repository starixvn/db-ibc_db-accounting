IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Acc_Rpt_CompanyWinLoss_VirtualSportsbook_MatchDetail]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_VirtualSportsbook_MatchDetail];
GO
CREATE PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_VirtualSportsbook_MatchDetail] @StartDate SMALLDATETIME,
                                                                              @EndDate   SMALLDATETIME,
                                                                              @SportType SMALLINT,
                                                                              @BetType   INT
AS

/*
Creator: Jacob
Date: 2016-03-01
Task:  Casino Integration Improvement - Implement Company Winloss By Products report [#48448]
DB: DBACC/bodb02

Revisions:
- 20160301@Jacob: Initialize Company Win Loss Report
Example: 
EXEC [Acc_Rpt_CompanyWinLoss_VirtualSportsbook_MatchDetail] @StartDate='2016-01-01', @EndDate='2020-01-01', @SportType = 180, @BetType = 1201
*/

     SET NOCOUNT ON;
     SELECT m.MatchId,
            m.matchcode,
            m.HomeId,
            m.AwayId,
            m.leagueid,
            SUM((winlost - actual_stake) * actualrate) MemberWinLoss,
            SUM((awinlost + mwinlost + swinlost) * actualrate) AS SMAWinLoss,
            SUM(scomm * actualrate) Commission,
            SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) AS RealIncome,
            SUM((1 - tpositiontaking) * ABS(b.stake) * actualrate) AS RealTurnover
     FROM bettrans AS b WITH (nolock)
          INNER JOIN match AS m WITH (nolock) ON b.matchid = m.matchid
     WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
           AND b.BetType = @BetType
           AND m.SportType = @SportType
           AND b.matchid > 0
           AND b.ruben = 1
           AND statusId NOT IN(101, 102, 103, 121)
     GROUP BY m.MatchId,
              m.matchcode,
              m.HomeId,
              m.AwayId,
              m.leagueid
     ORDER BY m.leagueid,
              m.matchcode,
              m.HomeId,
              m.awayid;

-------------------

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinLoss_VirtualSportsbook_MatchDetail] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CompanyWinLoss_VirtualSportsbook_MatchDetail] TO [vnteam];
GO