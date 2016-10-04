USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_HistorySel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_HistorySel];
GO
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_HistorySel] @ProductId INT,
                                                 @CustId    INT
AS

/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].

Parameters Explanation:	
   @ProductId: Product ID
   @CustId: Cust ID
Example:
EXEC [NAP_WinLimit_HistorySel] @ProductId = 13, @CustId = 18766106
*/


     SET NOCOUNT ON;
     BEGIN -- temp table data
         CREATE TABLE #WinLimitHistory
         (BetTypeId                INT,
          GroupId                  INT,
          ReachedLimitLevel        SMALLINT,
          MaxWinLimit              MONEY,
          TotalWinAmount           MONEY,
          WinAmount                MONEY,
          ActionName               NVARCHAR(50),
          ModifiedDate             DATETIME,
          ModifiedBy               INT,
          CreatedBy                INT,
          CurrencyMaxWinLimitLevel SMALLINT,
          CurrencyMaxWinLimit      MONEY,
          PlayerMaxWinLimitLevel   SMALLINT,
          PlayerMaxWinLimit        MONEY
         );
         INSERT INTO #WinLimitHistory
         (BetTypeId,
          GroupId,
          ReachedLimitLevel,
          MaxWinLimit,
          TotalWinAmount,
          WinAmount,
          ActionName,
          ModifiedDate,
          ModifiedBy,
          CreatedBy,
          CurrencyMaxWinLimitLevel,
          CurrencyMaxWinLimit,
          PlayerMaxWinLimitLevel,
          PlayerMaxWinLimit
         )
                SELECT h.BetTypeId,
                       gs.GroupId,
                       h.LevelID,
                       h.MaxWinLimit,
                       h.TotalWinAmt,
                       h.WinAmt,
                       a.ActionName,
                       h.ModifiedDate,
                       h.ModifiedBy,
                       h.CreatedBy,
                       ps.LevelID,
                       ps.MaxWinLimit,
                       cs.LevelID,
                       cs.MaxWinLimit
                FROM dbo.WinLimit_CustGameMonitoring_History h WITH (NOLOCK)
                     INNER JOIN dbo.WinLimit_GameGroupSetting gs WITH (NOLOCK) ON h.BettypeID = gs.BetTypeID
                                                                                  AND h.ProductID = gs.ProductID
                     INNER JOIN dbo.WinLimit_ProductSettingDetail ps WITH (NOLOCK) ON ps.ProductID = h.ProductID
                                                                                      AND ps.GroupID = gs.GroupID
                     LEFT JOIN dbo.WinLimit_CustGameSetting cs WITH (NOLOCK) ON cs.CustID = h.CustID
                                                                                AND cs.ProductID = h.ProductID
                                                                                AND cs.GroupID = gs.GroupID
                     INNER JOIN dbo.Winlimit_ActionSetting a WITH (NOLOCK) ON a.ActionID = h.ActionID
                WHERE h.ProductID = @ProductId
                      AND h.CustID = @CustId;
     END;
     BEGIN -- Query data
         SELECT DISTINCT
                h.GroupId,
                h.BetTypeId,
                h.ModifiedDate,
                ISNULL(h.PlayerMaxWinLimitLevel, h.CurrencyMaxWinLimitLevel) AS Level,
                CASE
                    WHEN(h.PlayerMaxWinLimit IS NULL)
                    THEN CASE
                             WHEN h.CurrencyMaxWinLimitLevel = h.ReachedLimitLevel
                             THEN h.MaxWinLimit
                             ELSE h.CurrencyMaxWinLimit
                         END
                    ELSE CASE
                             WHEN h.PlayerMaxWinLimitLevel = h.ReachedLimitLevel
                             THEN h.MaxWinLimit
                             ELSE h.PlayerMaxWinLimit
                         END
                END AS MaxWinLimit,
                h.TotalWinAmount,
                h.ReachedLimitLevel,
                h.ActionName,
                CASE
                    WHEN h.ModifiedBy IS NULL
                    THEN 'System'
                    ELSE
         (
             SELECT c.username
             FROM dbo.custInfo c WITH (NOLOCK)
             WHERE c.custid = h.ModifiedBy
         )
                END AS ProceededBy
         FROM #WinLimitHistory h
         ORDER BY h.ModifiedDate DESC;
     END;
     DROP TABLE #WinLimitHistory;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_HistorySel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_HistorySel] TO [vnteam];
GO