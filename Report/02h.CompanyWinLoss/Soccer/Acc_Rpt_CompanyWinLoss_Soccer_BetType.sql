IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Acc_Rpt_CompanyWinLoss_Soccer_BetType]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Soccer_BetType];
GO
CREATE PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Soccer_BetType] @StartDate SMALLDATETIME,
                                                               @EndDate   SMALLDATETIME,
                                                               @IsMajor   BIT           = 1,
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
EXEC [Acc_Rpt_CompanyWinLoss_Soccer_BetType] @EndDate='2020-01-01',@StartDate='2016-01-01', @IsMajor = 1, @IsLive = 2

*/

     SET NOCOUNT ON;
     BEGIN --#SportBetType     
         DECLARE @isTest BIT= 0;
         SELECT @isTest = dbo.f_CheckSPVersion(@@PROCID);
         CREATE TABLE #SportBetType(BetType INT);
         INSERT INTO #SportBetType
                SELECT s.BetType
                FROM dbo.f_SportBetTypeMatrix_Sel(1, 1, 0, 2, '', '', @isTest) s
                WHERE SubProduct NOT IN('MG-SuperLive', 'BT-Sold', 'BT-Bought', 'BT-Comm')
                AND EventType IN(1, 2);
     END;
     BEGIN -- Bet Type
         DECLARE @BetType TABLE
         (BetType      INT PRIMARY KEY,
          BetTypeName  NVARCHAR(50),
          DisplayOrder INT IDENTITY(1, 1)
         );
         INSERT INTO @BetType(BetType)
         VALUES(1), (301), (3), (302), (7), (303), (8), (304), (2), (5), (4), (6), (10);
         INSERT INTO @BetType(BetType)
                SELECT typeid
                FROM BetType b WITH (NOLOCK)
                     INNER JOIN #SportBetType sb ON sb.BetType = b.typeid
                WHERE b.typeid > 10
                      AND b.typeid NOT IN(301, 302, 303, 304);
         DELETE @BetType
         WHERE @IsMajor = 1
               AND BetType NOT IN(1, 2, 3, 5, 6, 7, 8, 12, 15, 24, 25, 28, 121, 122, 123, 126, 151, 301, 302, 303, 304);
         DELETE @BetType
         WHERE @IsMajor = 0
               AND BetType IN(1, 2, 3, 5, 6, 7, 8, 12, 15, 24, 25, 28, 121, 122, 123, 126, 151, 301, 302, 303, 304);
         UPDATE b
           SET
               b.BetTypeName = bt.typenamee
         FROM @BetType b
              INNER JOIN BetType(NOLOCK) bt ON b.BetType = bt.typeid;
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
     BEGIN -- #Match

         CREATE TABLE #Match
         (matchid   INT,
          matchcode NVARCHAR(50),
          type      VARCHAR(10),
          PRIMARY KEY(matchid, type)
         );
         INSERT INTO #Match
                SELECT m.matchid,
                       m.matchcode,
                       m.type
                FROM
                (
                    SELECT matchid,
                           leagueid,
                           matchcode,
                           'match' AS type
                    FROM Match WITH (NOLOCK)
                    WHERE eventdate BETWEEN @StartDate AND @EndDate
                    UNION ALL
                    SELECT orid,
                           leagueid,
                           matchcode,
                           'outright' AS type
                    FROM outright WITH (NOLOCK)
                    WHERE eventdate BETWEEN @StartDate AND @EndDate
                ) m
                INNER JOIN league l WITH (NOLOCK) ON m.leagueid = l.leagueid
                WHERE l.sporttype = 1;
     END;
     BEGIN -- #Data

         CREATE TABLE #Data
         (GroupId         INT,
          GroupName       NVARCHAR(50),
          DisplayOrder    INT,
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
     BEGIN -- Bet Type
         INSERT INTO #Data
                SELECT sb.BetType GroupId,
                       CASE
                           WHEN m.matchcode LIKE '%hedge%'
                           THEN sb.BetTypeName+' (hedge)'
                           ELSE sb.BetTypeName
                       END GroupName,
                       sb.DisplayOrder,
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
                     INNER JOIN @BetType AS sb ON sb.BetType = b.BetType
                     LEFT JOIN #DepositAgent AS dep ON b.recommend = dep.CustId
                     INNER JOIN #Match m ON b.matchid = m.matchid
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
                GROUP BY sb.BetType,
                         CASE
                             WHEN m.matchcode LIKE '%hedge%'
                             THEN sb.BetTypeName+' (hedge)'
                             ELSE sb.BetTypeName
                         END,
                         sb.DisplayOrder,
                         CASE
                             WHEN dep.CustId IS NULL
                             THEN 'Credit'
                             ELSE 'Deposit'
                         END;
     END;
     BEGIN -- RM   

         INSERT INTO #Data
                SELECT 0,
                       'RM',
                       10000000,
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
                     INNER JOIN @BetType AS sb ON sb.BetType = b.BetType
                     INNER JOIN #Match m ON b.matchid = m.matchid
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

         SELECT d.GroupId GroupId,
                d.GroupName AS GroupName,
                d.DisplayOrder,
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
         ORDER BY DisplayOrder,
                  RowName;
     END;
     DROP TABLE #SportBetType;
     DROP TABLE #DepositAgent;
     DROP TABLE #Match;
     DROP TABLE #Data;
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinLoss_Soccer_BetType] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CompanyWinLoss_Soccer_BetType] TO [vnteam];
GO