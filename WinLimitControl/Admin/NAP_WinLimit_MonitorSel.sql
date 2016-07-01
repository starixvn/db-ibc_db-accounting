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
         BEGIN -- temp table #Site
             CREATE TABLE #Site
             (AgentId  INT,
              SiteId   INT,
              SiteName NVARCHAR(50),
             );
             INSERT INTO #Site
                    SELECT c.custid,
                           s.siteid,
                           s.site
                    FROM dbo.Customer c WITH (NOLOCK)
                         INNER JOIN dbo.Site s WITH (NOLOCK) ON s.site = c.site
                    WHERE c.roleid = 2;
         END;
         BEGIN -- temp table #CustInfo
             CREATE TABLE #CustInfo
             (CustId     INT,
              UserName   NVARCHAR(50),
              SiteId     INT,
              SiteName   NVARCHAR(50),
              CurrencyId INT
             );
             INSERT INTO #CustInfo
             (CustId,
              UserName,
              SiteId,
              SiteName,
              CurrencyId
             )
             (
                 SELECT ci.custid,
                        ci.username,
                        s.SiteId,
                        s.SiteName,
                        ci.currency AS CurrencyId
                 FROM dbo.custInfo ci WITH (NOLOCK)
                      INNER JOIN #Site s WITH (NOLOCK) ON s.AgentId = ci.recommend
                 WHERE(@SiteId IS NULL
                       OR s.SiteId = @SiteId)
                      AND (@CurrencyId IS NULL
                           OR ci.currency = @CurrencyId)
                      AND ci.roleid = 1
                      AND (@UserName IS NULL
                           OR ci.username = @UserName)
             );
         END;
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
              PlayerMaxWinLimit        MONEY
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
              PlayerMaxWinLimit
             )
                    SELECT wlcgm.CustID,
                           ci.UserName,
                           wlcgm.ProductID,
                           wlcgm.BettypeID,
                           wlcgm.LevelID,
                           wlcgm.MaxWinLimit,
                           wlcgm.TotalWinAmt,
                           wlcgm.WinAmt,
                           wlcgm.ModifiedDate,
                           ci.CurrencyId,
                           ci.SiteId,
                           ci.SiteName,
                           wlpsd.LevelID,
                           wlpsd.MaxWinLimit,
                           wlcgs.LevelID,
                           wlcgs.MaxWinLimit
                    FROM WinLimit_CustGameMonitoring wlcgm WITH (NOLOCK)
                         INNER JOIN #CustInfo ci WITH (NOLOCK) ON ci.CustId = wlcgm.CustID
                         INNER JOIN dbo.WinLimit_ProductSettingDetail wlpsd WITH (NOLOCK) ON wlpsd.ProductID = wlcgm.ProductID
                                                                                             AND wlpsd.BettypeID = wlcgm.BettypeID
                                                                                             AND ci.CurrencyId = wlpsd.ExchangeID
                                                                                             AND ci.SiteId = wlpsd.SiteID
                         LEFT JOIN dbo.WinLimit_CustGameSetting wlcgs WITH (NOLOCK) ON wlcgs.CustID = wlcgm.CustID
                                                                                       AND wlcgs.ProductID = wlcgm.ProductID
                                                                                       AND wlcgs.BettypeID = wlcgm.BettypeID
                    WHERE wlcgm.ModifiedDate BETWEEN @FromDate AND @Todate
                          AND (@ProductId IS NULL
                               OR wlcgm.ProductID = @ProductId);
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
                 WHERE wlcgmh.ModifiedDate BETWEEN @FromDate AND @Todate
                       AND wlcgmh.LevelID = wlm.ReachedLimitLevel
                       AND wlcgmh.CustID = wlm.CustId
                       AND wlcgmh.ProductID = wlm.ProductId
                       AND wlcgmh.ActionID NOT IN(2, 4)
             ) AS NumberReachedLimit,
                    wlcgs.IsBlockedPlaceBet,
                    wlcgs.IsBlockedTransfer
             FROM #WinLimitMonitor wlm
                  INNER JOIN dbo.WinLimit_CustGameStatus wlcgs WITH (NOLOCK) ON wlcgs.ProductID = wlm.ProductId
                                                                                AND wlcgs.BettypeID = wlm.BettypeId
                                                                                AND wlcgs.CustID = wlm.CustId
             ORDER BY ReachedLimitTime DESC;
         END;
         DROP TABLE #Site;
         DROP TABLE #CustInfo;
         DROP TABLE #WinLimitMonitor;
     END;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_MonitorSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_MonitorSel] TO [vnteam];
GO