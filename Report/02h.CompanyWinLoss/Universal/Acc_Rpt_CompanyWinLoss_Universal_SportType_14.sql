IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Acc_Rpt_CompanyWinLoss_Universal_SportType_14]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Universal_SportType_14];
GO
CREATE PROCEDURE [dbo].[Acc_Rpt_CompanyWinLoss_Universal_SportType_14] @StartDate SMALLDATETIME,
                                                                    @EndDate   SMALLDATETIME,
                                                                    @ProductId INT
AS

/*	
Creator: 20160921@Jacob
Task:  Integrate new product NG2 [#63460]
DB: DBACC/bodb02

Revisions: 
- 20160921@Jacob: NG2 - Redmine[#63460]
Example: 
EXEC [Acc_Rpt_CompanyWinLoss_Universal_SportType_14] @StartDate='2016-01-01', @EndDate='2020-01-01', @ProductId = 23
		
*/


     SET NOCOUNT ON;
     BEGIN --#SportBetType     
         DECLARE @isTest BIT= 0;
         SELECT @isTest = dbo.f_CheckSPVersion(@@PROCID);
         CREATE TABLE #SportBetType(BetType INT);
         INSERT INTO #SportBetType
                SELECT s.BetType
                FROM dbo.f_SportBetTypeMatrix_Sel(@ProductId, 0, 0, 2, '', '', @isTest) s;
     END;
     BEGIN -- #DepositSuper

         CREATE TABLE #DepositSuper
         (CustId INT PRIMARY KEY
         );
         INSERT INTO #DepositSuper
                SELECT CustId
                FROM f_DepSuper_1('All');
     END;
     BEGIN -- #Data

         CREATE TABLE #Data
         (SportType     INT,
          Site          NVARCHAR(50),
          MemberWinLoss MONEY,
          SMAWinLoss    MONEY,
          Commission    MONEY,
          RealIncome    MONEY,
          RealTurnover  MONEY
         );
     END;
     BEGIN --  INSERT INTO #Data
         INSERT INTO #Data
                SELECT m.sporttype,
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
                     INNER JOIN match14 AS m WITH (NOLOCK) ON b.MatchId = m.MatchId
                WHERE b.winlostdate = @StartDate
                      AND b.ruben = 1
                      AND b.statusId NOT IN(101, 102, 103, 121)
                GROUP BY m.sporttype,
                         CASE
                             WHEN dep.CustId IS NULL
                             THEN 'Credit'
                             ELSE 'Deposit'
                         END;
     END;
     BEGIN -- Query

         SELECT s.SportType AS GroupId,
                s.SportName AS GroupName,
                d.Site AS RowName,
                d.MemberWinLoss AS MemberWinLoss,
                d.SMAWinLoss AS SMAWinLoss,
                d.Commission AS Commission,
                d.RealIncome AS RealIncome,
                d.RealTurnover AS RealTurnover
         FROM #Data AS d
              INNER JOIN Sports AS s WITH (NOLOCK) ON d.SportType = s.SportType
         ORDER BY GroupName,
                  RowName;
     END;
     DROP TABLE #Data;
     DROP TABLE #SportBetType;
     DROP TABLE #DepositSuper;
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinLoss_Universal_SportType_14] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CompanyWinLoss_Universal_SportType_14] TO [vnteam];
GO