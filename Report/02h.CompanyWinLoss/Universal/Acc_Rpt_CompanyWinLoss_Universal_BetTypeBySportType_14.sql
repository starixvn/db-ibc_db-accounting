IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Acc_Rpt_CompanyWinLoss_Universal_BetTypeBySportType_14]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Universal_BetTypeBySportType_14];
GO
CREATE PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Universal_BetTypeBySportType_14] @StartDate SMALLDATETIME,
                                                                             @EndDate   SMALLDATETIME,
                                                                             @SportType INT
AS

/*	
Creator: 20160921@Jacob
Task:  Integrate new product NG2 [#63460]
DB: DBACC/bodb02

Revisions: 
- 20160921@Jacob: NG2 - Redmine[#63460]
Example: 
EXEC [Acc_Rpt_CompanyWinLoss_Universal_BetTypeBySportType_14] @StartDate='2016-01-01', @EndDate='2020-01-01', @SportType = 213
		
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
                FROM dbo.f_SportBetTypeMatrix_Sel(0, 0, @SportType, 2, '', '', @isTest) s
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
                SUM((winlost - actual_stake) * actualrate) AS MemberWinLoss,
                SUM((awinlost + mwinlost + swinlost) * actualrate) AS SMAWinLoss,
                SUM(scomm * actualrate) Commission,
                SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) AS RealIncome,
                SUM((1 - tpositiontaking) * ABS(stake) * actualrate) AS RealTurnover
         FROM bettrans14 AS b WITH (NOLOCK)
              INNER JOIN #SportBetType AS sb ON sb.BetType = b.BetType
              LEFT JOIN #DepositSuper AS dep ON b.srecommend = dep.CustId
         WHERE b.winlostdate = @StartDate
               AND b.ruben = 1
               AND b.statusId NOT IN(101, 102, 103, 121)
         GROUP BY sb.BetType,
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
GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinLoss_Universal_BetTypeBySportType_14] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CompanyWinLoss_Universal_BetTypeBySportType_14] TO [vnteam];
GO