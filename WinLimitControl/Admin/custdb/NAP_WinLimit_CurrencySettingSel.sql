USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CurrencySettingSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingSel];
GO
USE [CustDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE PROCEDURE NAP_WinLimit_CurrencySettingSel @ProductId           INT,
                                                 @SiteId              INT,
                                                 @IsCreditSite        BIT = 0,
                                                 @CurrencyId          INT = NULL,
                                                 @ExcludeTestCurrency BIT = 0
AS

/*
	Created: Phillip	
	Date: 2015-06-26
	Task: #38608 - Implement function to control Player's Win Limit on specific Product
	
	DB: DBCUST/CustDB
	
	Revisions:
	20160614@Franklin: Implement Game Win Limit Control phase2 [#57722].
	
	Parameters Explanation:	
	   @ProductId: Product ID
	   @SiteId	: Site or Licensee ID
	   @IsCreditSite: Is Credit Site
	   @CurrencyId	: Currency ID
*/

     BEGIN
         SET NOCOUNT ON;
         BEGIN
             CREATE TABLE #ProductSetting
             (ProductId TINYINT,
              BettypeId SMALLINT,
              LevelId   TINYINT
             );
             CREATE TABLE #ProductSiteCurrencySetting
             (ProductId  TINYINT,
              SiteId     SMALLINT,
              CurrencyId TINYINT
             );
             INSERT INTO #ProductSetting
             (ProductId,
              BettypeId,
              LevelId
             )
                    SELECT fps.ProductId,
                           fps.BettypeId,
                           fps.LevelId
                    FROM dbo.f_Nap_WinLimit_ProductSettingSel(@ProductId) fps;
             IF @IsCreditSite = 0
                 INSERT INTO #ProductSiteCurrencySetting
                        SELECT DISTINCT
                               @ProductId,
                               @SiteId,
                               lc.Currency
                        FROM DBLIC.bodb_licensee.dbo.LicenseeCust lc WITH (NOLOCK)
                             INNER JOIN DBLIC.bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeID = lc.LicenseeID
                             INNER JOIN dbo.site s ON s.site = l.LicenseeName
                        WHERE s.siteid = @SiteId
                              AND (@CurrencyId IS NULL
                                   OR lc.Currency = @CurrencyId)
                              AND (@ExcludeTestCurrency = 0
                                   OR lc.CurrencyName NOT IN('UUS'))
                             AND lc.CurrencyName NOT IN('H', 'C');
             ELSE
             INSERT INTO #ProductSiteCurrencySetting
                    SELECT @ProductId,
                           @SiteId,
                           ex.exchangeid
                    FROM dbo.exchange ex WITH (NOLOCK)
                    WHERE(@CurrencyId IS NULL
                          OR ex.exchangeid = @CurrencyId)
                         AND (@ExcludeTestCurrency = 0
                              OR ex.currency NOT IN('UUS'))
                    AND ex.currency NOT IN('H', 'C');
         END;
         BEGIN -- Query Data
             SELECT pscs.ProductId,
                    ps.BettypeId,
                    pscs.CurrencyId,
                    pscs.SiteId,
                    ps.LevelId AS Level,
                    ISNULL(wlpsd.MaxWinLimit, 0) AS MaxWinLimit,
                    ISNULL(wlpsd.IsBlockedPlaceBet, 0) AS IsBlockedPlaceBet,
                    ISNULL(wlpsd.IsBlockedTransfer, 0) AS IsBlockedTransfer
             FROM #ProductSiteCurrencySetting pscs
                  INNER JOIN #ProductSetting ps ON pscs.ProductId = ps.ProductId
                  LEFT JOIN dbo.WinLimit_ProductSettingDetail wlpsd WITH (NOLOCK) ON wlpsd.ProductID = pscs.ProductId
                                                                                     AND wlpsd.BettypeID = ps.BettypeId
                                                                                     AND wlpsd.SiteID = pscs.SiteId
                                                                                     AND wlpsd.LevelID = ps.LevelId
                                                                                     AND wlpsd.ExchangeID = pscs.CurrencyId
             ORDER BY pscs.CurrencyId,
                      ps.LevelId;
         END;
     END;
         DROP TABLE #ProductSetting;
         DROP TABLE #ProductSiteCurrencySetting;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySettingSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CurrencySettingSel] TO [vnteam];
GO