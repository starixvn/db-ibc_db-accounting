USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustNotConfigProductSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustNotConfigProductSel];
GO
USE [CustDB];
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustNotConfigProductSel]    Script Date: 07/07/2015 16:09:00 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustNotConfigProductSel] @Username VARCHAR(100) = ''
AS
	
/*
	Created: Jacob	
	Date: 2016-06-30
	Task: #38608 - Implement function to control Player's Win Limit on specific Product
	
	DB: DBCust/CustDB
	
	Revisions:
	
	Parameters Explanation:	
	
	EXEC [NAP_WinLimit_CustNotConfigProductSel] @Username = 'SPONUUS01045'
	
*/

     SET NOCOUNT ON;
     BEGIN -- @CustID, @CurrencyID.
         DECLARE @CustID INT, @CurrencyID INT, @CurrencyName NVARCHAR(50), @AgentId INT, @SuperId INT;
         SELECT @CustID = c.custid,
                @CurrencyID = e.exchangeid,
                @CurrencyName = e.currency,
                @AgentId = c.recommend,
                @SuperId = c.srecommend
         FROM dbo.Customer c WITH (NOLOCK)
              INNER JOIN dbo.exchange e WITH (NOLOCK) ON c.currency = e.exchangeid
         WHERE c.username = @Username
               AND c.roleid = 1;
     END;
     BEGIN -- @SiteId
         DECLARE @SiteId INT, @SiteName VARCHAR(50);
         SELECT @SiteId = s.siteid,
                @SiteName = c.[site]
         FROM dbo.Customer c WITH (NOLOCK)
              INNER JOIN dbo.[Site] s WITH (NOLOCK) ON c.site = s.site
         WHERE CustId = @AgentId;
     END;
     BEGIN-- @IsDeposit
         DECLARE @IsDeposit INT;
         SELECT @IsDeposit = CASE
                                 WHEN EXISTS
         (
             SELECT 1
             FROM f_DepSuper_1('All')
             WHERE CustId = @SuperId
         )
                                 THEN 1
                                 ELSE 0
                             END;
     END;
     BEGIN -- @OfferProducts
         DECLARE @OfferProducts TABLE
         (ProductId   INT,
          ProductName NVARCHAR(50),
          BetTypeId   INT,
          LevelId     INT
         );
         IF @IsDeposit = 0
             BEGIN
                 INSERT INTO @OfferProducts
                        SELECT p.ProductId,
                               p.ProductName,
                               ps.BettypeID,
                               ps.LevelId
                        FROM dbo.Winlimit_ProductSetting ps WITH (NOLOCK)
                             INNER JOIN DBPRO.bodb02.dbo.Products p WITH (NOLOCK) ON ps.ProductId = p.ProductId;
             END;
         ELSE
             BEGIN
                 INSERT INTO @OfferProducts
                        SELECT p.ProductId,
                               p.ProductName,
                               ps.BettypeID,
                               ps.LevelId
                        FROM dbo.Winlimit_ProductSetting ps WITH (NOLOCK)
                             INNER JOIN DBPRO.bodb02.dbo.Products p ON ps.ProductId = p.ProductId
                             INNER JOIN DBLIC.bodb_licensee.dbo.LicenseeProduct3rd lp WITH (NOLOCK) ON ps.ProductId = lp.ProductId
                             INNER JOIN DBLIC.bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeID = lp.licenseeId
                             INNER JOIN dbo.[Site] s WITH (NOLOCK) ON l.LicenseeName = s.[site]
                        WHERE s.[siteid] = @SiteId
                              AND ps.SettingStatus = 1;
             END;
     END;
     BEGIN -- @ExistedSetting
         DECLARE @ExistedSetting TABLE
         (CustI       INT,
          ProductId   INT,
          BetTypeId   INT,
          LevelId     INT,
          MaxWinLimit MONEY
         );
         INSERT INTO @ExistedSetting
                SELECT CustID,
                       ProductID,
                       BettypeID,
                       LevelID,
                       MaxWinLimit
                FROM dbo.WinLimit_CustGameSetting wc WITH (NOLOCK)
                WHERE wc.CustId = @CustId;
     END;
     BEGIN -- Query
         SELECT @CustId CustId,
                @Username Username,
                @SiteId SiteId,
                @SiteName [Site],
                @CurrencyId CurrencyId,
                @CurrencyName Currency,
                p.ProductId,
                p.ProductName,
                p.BetTypeId,
                p.LevelId,
                ISNULL(pd.MaxWinLimit, 0) AS CurrencyWinLimit,
                CASE
                    WHEN pd.MaxWinLimit IS NULL
                    THEN 0
                    ELSE 1
                END HasCurrencySetting
         FROM @OfferProducts p
              LEFT JOIN @ExistedSetting e ON e.ProductId = p.ProductId
                                             AND e.BetTypeId = p.BetTypeId
                                             AND e.LevelId = p.LevelId
              LEFT JOIN dbo.WinLimit_ProductSettingDetail pd WITH (NOLOCK) ON p.ProductId = pd.ProductId
                                                                              AND p.BetTypeId = pd.BetTypeId
                                                                              AND p.LevelId = pd.LevelId
                                                                              AND pd.ExchangeId = @CurrencyId
                                                                              AND pd.SiteId = @SiteId
         WHERE e.MaxWinLimit IS NULL;
     END;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustNotConfigProductSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustNotConfigProductSel] TO [vnteam];
GO