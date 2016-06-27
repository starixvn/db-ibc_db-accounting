IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Acc_Rpt_CompanyWinLoss_NumberGame_BetType]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_NumberGame_BetType];
GO
CREATE PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_NumberGame_BetType] @StartDate SMALLDATETIME,
                                                                   @EndDate   SMALLDATETIME
AS
 
/*
Creator: Jacob
Date: 2016-03-01
Task:  Casino Integration Improvement - Implement Company Winloss By Products report [#48448]
DB: DBACC/bodb02

Revisions:
- 20160301@Jacob: Initialize Company Win Loss Report
Example :
EXEC [Acc_Rpt_CompanyWinLoss_NumberGame_BetType]  @StartDate = '2016-01-06', @EndDate='2020-01-01'	   
*/

     SET NOCOUNT ON;
     BEGIN --#SportBetType     
         DECLARE @isTest BIT= 0;
         SELECT @isTest = dbo.f_CheckSPVersion(@@PROCID);
         CREATE TABLE #SportBetType
         (BetType     INT,
          BetTypeName NVARCHAR(50)
         );
         INSERT INTO #SportBetType
                SELECT b.typeid,
                       b.typenamee
                FROM dbo.f_SportBetTypeMatrix_Sel(3, 0, 0, 2, '', '', @isTest) s
                     INNER JOIN BetType b WITH (NOLOCK) ON s.BetType = b.typeid;
     END;
     BEGIN -- #DepositSuper

         CREATE TABLE #DepositSuper
         (CustId INT PRIMARY KEY
         );
         INSERT INTO #DepositSuper
                SELECT CustId
                FROM f_DepSuper_1('All');
     END;
     BEGIN -- Query

         SELECT sb.BetType AS GroupId,
                sb.BetTypeName AS GroupName,
                CASE
                    WHEN dep.CustId IS NULL
                    THEN 'Credit'
                    ELSE 'Deposit'
                END AS RowName,
                b.liveindicator AS IsLive,
                SUM((winlost - actual_stake) * actualrate) MemberWinLoss,
                SUM((awinlost + mwinlost + swinlost) * actualrate) AS SMAWinLoss,
                SUM(scomm * actualrate) Commission,
                SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) AS RealIncome,
                SUM((1 - tpositiontaking) * ABS(stake) * actualrate) AS RealTurnover
         FROM bettrans AS b WITH (NOLOCK)
              INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
              LEFT JOIN #DepositSuper AS dep ON b.srecommend = dep.CustId
         WHERE b.winlostdate BETWEEN @StartDate AND @EndDate
               AND b.ruben = 1
               AND b.statusId NOT IN(101, 102, 103, 121)
         GROUP BY b.liveindicator,
                  sb.BetType,
                  sb.BetTypeName,
                  CASE
                      WHEN dep.CustId IS NULL
                      THEN 'Credit'
                      ELSE 'Deposit'
                  END
         ORDER BY GroupName,
                  RowName;
     END;
     DROP TABLE #SportBetType;
     DROP TABLE #DepositSuper;
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinLoss_NumberGame_BetType] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CompanyWinLoss_NumberGame_BetType] TO [vnteam];
GO