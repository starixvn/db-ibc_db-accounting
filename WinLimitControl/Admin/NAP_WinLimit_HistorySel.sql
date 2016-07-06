CREATE PROCEDURE [dbo].[NAP_WinLimit_HistorySel] @ProductId  INT,
                                                 @CustId     INT,
                                                 @SiteId     INT,
                                                 @CurrencyId INT
AS

/*
	Created: Franklin	
	Date: 2016-06-29
	Task: #57722 - Implement Game Win Limit Control phase2
	
	DB: DBCUST/CustDB
	
	Revisions:
	
	Parameters Explanation:	
	   @ProductId: Product ID
	   @CustId: Cust ID
	   @SiteId: Site ID
	   @CurrencyId: Currency ID
*/

     BEGIN
         SET NOCOUNT ON;
         BEGIN -- temp table data
             CREATE TABLE #WinLimitHistory
             (ReachedLimitLevel        SMALLINT,
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
             (ReachedLimitLevel,
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
                    SELECT wlcgmh.LevelID,
                           wlcgmh.MaxWinLimit,
                           wlcgmh.TotalWinAmt,
                           wlcgmh.WinAmt,
                           was.ActionName,
                           wlcgmh.ModifiedDate,
                           wlcgmh.ModifiedBy,
                           wlcgmh.CreatedBy,
                           wlpsd.LevelID,
                           wlpsd.MaxWinLimit,
                           wlcgs.LevelID,
                           wlcgs.MaxWinLimit
                    FROM dbo.WinLimit_CustGameMonitoring_History wlcgmh WITH (NOLOCK)
                         INNER JOIN dbo.WinLimit_ProductSettingDetail wlpsd WITH (NOLOCK) ON wlpsd.ProductID = wlcgmh.ProductID
                                                                                             AND wlpsd.BettypeID = wlcgmh.BettypeID
                         LEFT JOIN dbo.WinLimit_CustGameSetting wlcgs WITH (NOLOCK) ON wlcgs.CustID = wlcgmh.CustID
                                                                                       AND wlcgs.ProductID = wlcgmh.ProductID
                                                                                       AND wlcgs.BettypeID = wlcgmh.BettypeID
                         INNER JOIN dbo.Winlimit_ActionSetting was WITH (NOLOCK) ON was.ActionID = wlcgmh.ActionID
                    WHERE wlcgmh.ProductID = @ProductId
                          AND wlcgmh.CustID = @CustId
                          AND wlpsd.ExchangeID = @CurrencyId
                          AND wlpsd.SiteID = @SiteId;
         END;
         BEGIN -- Query data
             SELECT DISTINCT
                    wlh.ModifiedDate,
                    ISNULL(wlh.PlayerMaxWinLimitLevel, wlh.CurrencyMaxWinLimitLevel) AS Level,
                    CASE
                        WHEN(wlh.PlayerMaxWinLimit IS NULL)
                        THEN CASE
                                 WHEN wlh.CurrencyMaxWinLimitLevel = wlh.ReachedLimitLevel
                                 THEN wlh.MaxWinLimit
                                 ELSE wlh.CurrencyMaxWinLimit
                             END
                        ELSE CASE
                                 WHEN wlh.PlayerMaxWinLimitLevel = wlh.ReachedLimitLevel
                                 THEN wlh.MaxWinLimit
                                 ELSE wlh.PlayerMaxWinLimit
                             END
                    END AS MaxWinLimit,
                    wlh.TotalWinAmount,
                    wlh.ReachedLimitLevel,
                    wlh.ActionName,
                    CASE
                        WHEN wlh.ModifiedBy IS NULL
                        THEN 'System'
                        ELSE
             (
                 SELECT ci.username
                 FROM dbo.custInfo ci
                 WHERE ci.custid = wlh.ModifiedBy
             )
                    END AS ProceededBy
             FROM #WinLimitHistory wlh
             ORDER BY wlh.ModifiedDate DESC;
         END;
         DROP TABLE #WinLimitHistory;
     END;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_HistorySel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_HistorySel] TO [vnteam];
GO