USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_MonitorSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_MonitorSel];
GO
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE NAP_WinLimit_MonitorSel @FromDate        DATETIME,
                                         @ToDate          DATETIME,
                                         @ProductId       INT          = 0,
                                         @UserName        NVARCHAR(50) = '',
                                         @SiteId          INT          = 0,
                                         @CurrencyId      INT          = 0,
                                         @ExcludeTestData BIT          = 1
AS

/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].

Parameters Explanation:	
   @FromDate: From date
   @ToDate: To Date
   @ProductId: Product ID
   @UserName: UserName
   @SiteId: Site ID
   @CurrencyId: Currency ID
   
Example:
EXEC NAP_WinLimit_MonitorSel @FromDate = '20160101', @ToDate = '20161231'
*/


     SET NOCOUNT ON;
     BEGIN -- #WinLimitMonitor
         CREATE TABLE #WinLimitMonitor
         (CustId             INT,
          UserName           NVARCHAR(50),
          ProductId          INT,
          BettypeId          INT,
          GroupId            INT,
          ReachedLimitLevel  SMALLINT,
          TotalWinAmount     MONEY,
          TotalWinAmountRM   MONEY,
          MaxWinLimitSetting XML,
          ModifiedDate       DATETIME,
          CurrencyId         INT,
          SiteId             INT,
          IsNotified         BIT
         );
         INSERT INTO #WinLimitMonitor
         (CustId,
          UserName,
          ProductId,
          BettypeId,
          GroupId,
          ReachedLimitLevel,
          TotalWinAmount,
          TotalWinAmountRM,
          MaxWinLimitSetting,
          ModifiedDate,
          CurrencyId,
          SiteId,
          IsNotified
         )
                SELECT cm.CustID,
                       ci.username,
                       cm.ProductID,
                       cm.BettypeID,
                       gs.GroupID,
                       cm.LevelID,
                       cm.TotalWinAmt,
                       cm.TotalWinAmt_RM,
                       cm.MaxWinLimitSetting,
                       cm.ModifiedDate,
                       c.currency,
                       s.siteid,
                       cm.IsNotified
                FROM WinLimit_CustGameMonitoring cm WITH (NOLOCK)
                     INNER JOIN dbo.WinLimit_GameGroupSetting gs WITH (NOLOCK) ON cm.BettypeID = gs.BetTypeID
                                                                                  AND cm.ProductID = gs.ProductID
                     INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON cm.CustID = ci.CustID
                     INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.custid = ci.recommend
                     INNER JOIN dbo.Site s WITH (NOLOCK) ON s.site = c.site
                WHERE cm.ModifiedDate BETWEEN @FromDate AND @Todate
                      AND (@ProductId = 0
                           OR cm.ProductID = @ProductId)
                      AND (@SiteId = 0
                           OR s.SiteId = @SiteId)
                      AND (@CurrencyId = 0
                           OR ci.currency = @CurrencyId)
                      AND (@ExcludeTestData = 0
                           OR ci.currency NOT IN(20, 72)) -- UUS & YNG
                     AND ci.roleid = 1
                     AND (LEN(@UserName) = 0
                          OR ci.username = @UserName);
     END;
     BEGIN -- Query data
         SELECT m.CustId,
                m.UserName,
                m.SiteId,
                m.CurrencyId,
                m.ProductId,
                m.BettypeId,
                m.GroupId,
                m.TotalWinAmount,
                m.TotalWinAmountRM,
                m.MaxWinLimitSetting,
                m.ModifiedDate AS ReachedLimitTime,
                m.ReachedLimitLevel,
         (
             SELECT COUNT(1)
             FROM dbo.WinLimit_CustGameMonitoring_History h WITH (NOLOCK)
             WHERE h.ModifiedDate BETWEEN CONVERT( DATETIME, CONVERT(NVARCHAR(101), m.ModifiedDate, 111)+' 00:00:00') AND CONVERT(DATETIME, CONVERT(NVARCHAR(101), m.ModifiedDate, 111)+' 23:59:59.997')
                   AND h.LevelID = m.ReachedLimitLevel
                   AND h.CustID = m.CustId
                   AND h.ProductID = m.ProductId
                   AND h.BetTypeId = m.BetTypeId
                   AND h.ActionID NOT IN(2, 4)
         ) AS NumberReachedLimit,
                m.IsNotified,
                cs.IsBlockedPlaceBet,
                cs.IsBlockedTransfer,
                CASE
                    WHEN cm.ModifiedDate IS NOT NULL
                    THEN 1
                    ELSE 0
                END AS IsEnableUnBlock
         FROM #WinLimitMonitor m
              INNER JOIN dbo.WinLimit_CustGameStatus cs WITH (NOLOCK) ON cs.ProductID = m.ProductId
                                                                         AND cs.BettypeID = m.BettypeId
                                                                         AND cs.CustID = m.CustId
              LEFT JOIN
         (
             SELECT CustID,
                    ProductID,
                    BettypeID,
                    MAX(ModifiedDate) AS ModifiedDate
             FROM dbo.WinLimit_CustGameMonitoring WITH (NOLOCK)
             GROUP BY CustID,
                      ProductID,
                      BettypeID
         ) AS cm ON cm.CustId = m.CustId
                    AND cm.ModifiedDate = m.ModifiedDate
                    AND cm.ProductID = m.ProductID
                    AND cm.BettypeID = m.BettypeID
         ORDER BY ReachedLimitTime DESC;
     END;
     DROP TABLE #WinLimitMonitor;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_MonitorSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_MonitorSel] TO [vnteam];
GO