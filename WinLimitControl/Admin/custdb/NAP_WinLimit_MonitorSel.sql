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
CREATE PROCEDURE NAP_WinLimit_MonitorSel @FromDate   DATETIME,
                                         @ToDate     DATETIME,
                                         @ProductId  INT          = NULL,
                                         @UserName   NVARCHAR(50) = NULL,
                                         @SiteId     INT          = NULL,
                                         @CurrencyId INT          = NULL
AS

/*
	Created: Franklin	
	Date: 2016-06-29
	Task: #57722 - Implement Game Win Limit Control phase2
	
	DB: DBCUST/CustDB
	
	Revisions:
	
	Parameters Explanation:	
	   @FromDate: From date
	   @ToDate: To Date
	   @ProductId: Product ID
	   @UserName: UserName
	   @SiteId: Site ID
	   @CurrencyId: Currency ID
*/

     BEGIN
         SET NOCOUNT ON;
         BEGIN -- temp table data
             CREATE TABLE #WinLimitMonitor
             (CustId                   INT,
              UserName                 NVARCHAR(50),
              ProductId                INT,
              BettypeId                INT,
              ReachedLimitLevel        SMALLINT,
              MaxWinLimit              MONEY,
              TotalWinAmount           MONEY,
              WinAmount                MONEY,
              ModifiedDate             DATETIME,
              CurrencyId               INT,
              SiteId                   INT,
              SiteName                 NVARCHAR(50),
              CurrencyMaxWinLimitLevel SMALLINT,
              CurrencyMaxWinLimit      MONEY,
              PlayerMaxWinLimitLevel   SMALLINT,
              PlayerMaxWinLimit        MONEY,
              IsNotified               BIT
             );
             INSERT INTO #WinLimitMonitor
             (CustId,
              UserName,
              ProductId,
              BettypeId,
              ReachedLimitLevel,
              MaxWinLimit,
              TotalWinAmount,
              WinAmount,
              ModifiedDate,
              CurrencyId,
              SiteId,
              SiteName,
              CurrencyMaxWinLimitLevel,
              CurrencyMaxWinLimit,
              PlayerMaxWinLimitLevel,
              PlayerMaxWinLimit,
              IsNotified
             )
                    SELECT wlcgm.CustID,
                           ci.username,
                           wlcgm.ProductID,
                           wlcgm.BettypeID,
                           wlcgm.LevelID,
                           wlcgm.MaxWinLimit,
                           wlcgm.TotalWinAmt,
                           wlcgm.WinAmt,
                           wlcgm.ModifiedDate,
                           c.currency,
                           s.siteid,
                           s.site,
                           wlpsd.LevelID,
                           wlpsd.MaxWinLimit,
                           wlcgs.LevelID,
                           wlcgs.MaxWinLimit,
                           wlcgm.IsNotified
                    FROM WinLimit_CustGameMonitoring wlcgm WITH (NOLOCK)
                         INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON wlcgm.CustID = ci.CustID
                         INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.custid = ci.recommend
                         INNER JOIN dbo.Site s WITH (NOLOCK) ON s.site = c.site
                         INNER JOIN dbo.WinLimit_ProductSettingDetail wlpsd WITH (NOLOCK) ON wlpsd.ProductID = wlcgm.ProductID
                                                                                             AND wlpsd.BettypeID = wlcgm.BettypeID
                                                                                             AND c.currency = wlpsd.ExchangeID
                                                                                             AND s.siteid = wlpsd.SiteID
                         LEFT JOIN dbo.WinLimit_CustGameSetting wlcgs WITH (NOLOCK) ON wlcgs.CustID = wlcgm.CustID
                                                                                       AND wlcgs.ProductID = wlcgm.ProductID
                                                                                       AND wlcgs.BettypeID = wlcgm.BettypeID
                    WHERE wlcgm.ModifiedDate BETWEEN @FromDate AND @Todate
                          AND (@ProductId IS NULL
                               OR wlcgm.ProductID = @ProductId)
                          AND (@SiteId IS NULL
                               OR s.SiteId = @SiteId)
                          AND (@CurrencyId IS NULL
                               OR ci.currency = @CurrencyId)
                          AND ci.roleid = 1
                          AND (@UserName IS NULL
                               OR ci.username = @UserName);
         END;
         BEGIN -- Query data
             SELECT DISTINCT
                    wlm.CustId,
                    wlm.UserName,
                    wlm.SiteId,
                    wlm.SiteName,
                    wlm.CurrencyId,
                    wlm.ProductId,
                    wlm.BettypeId,
                    ISNULL(wlm.PlayerMaxWinLimitLevel, wlm.CurrencyMaxWinLimitLevel) AS Level,
                    CASE
                        WHEN(wlm.PlayerMaxWinLimit IS NULL)
                        THEN CASE
                                 WHEN wlm.CurrencyMaxWinLimitLevel = wlm.ReachedLimitLevel
                                 THEN wlm.MaxWinLimit
                                 ELSE wlm.CurrencyMaxWinLimit
                             END
                        ELSE CASE
                                 WHEN wlm.PlayerMaxWinLimitLevel = wlm.ReachedLimitLevel
                                 THEN wlm.MaxWinLimit
                                 ELSE wlm.PlayerMaxWinLimit
                             END
                    END AS MaxWinLimit,
                    wlm.TotalWinAmount,
                    wlm.ModifiedDate AS ReachedLimitTime,
                    wlm.ReachedLimitLevel,
             (
                 SELECT COUNT(1)
                 FROM dbo.WinLimit_CustGameMonitoring_History wlcgmh WITH (NOLOCK)
                 WHERE wlcgmh.ModifiedDate BETWEEN CONVERT( DATETIME, CONVERT(NVARCHAR(101), wlm.ModifiedDate, 111)+' 00:00:00') AND CONVERT(DATETIME, CONVERT(NVARCHAR(101), wlm.ModifiedDate, 111)+' 23:59:59.997')
                       AND wlcgmh.LevelID = wlm.ReachedLimitLevel
                       AND wlcgmh.CustID = wlm.CustId
                       AND wlcgmh.ProductID = wlm.ProductId
                       AND wlcgmh.ActionID NOT IN(2, 4)
             ) AS NumberReachedLimit,
                    wlm.IsNotified,
                    wlcgs.IsBlockedPlaceBet,
                    wlcgs.IsBlockedTransfer,
                    CASE
                        WHEN custWinLimitMaxTime.ModifiedDate IS NOT NULL
                        THEN 1
                        ELSE 0
                    END AS IsEnableUnBlock
             FROM #WinLimitMonitor wlm
                  INNER JOIN dbo.WinLimit_CustGameStatus wlcgs WITH (NOLOCK) ON wlcgs.ProductID = wlm.ProductId
                                                                                AND wlcgs.BettypeID = wlm.BettypeId
                                                                                AND wlcgs.CustID = wlm.CustId
                  LEFT JOIN
             (
                 SELECT wlcgm.CustID,
                        MAX(wlcgm.ModifiedDate) AS ModifiedDate
                 FROM dbo.WinLimit_CustGameMonitoring wlcgm
                 GROUP BY wlcgm.CustID,
                          wlcgm.ProductID,
                          wlcgm.BettypeID
             ) AS custWinLimitMaxTime ON custWinLimitMaxTime.CustId = wlm.CustId
                                         AND custWinLimitMaxTime.ModifiedDate = wlm.ModifiedDate
             ORDER BY ReachedLimitTime DESC;
         END;
         DROP TABLE #WinLimitMonitor;
     END;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_MonitorSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_MonitorSel] TO [vnteam];
GO