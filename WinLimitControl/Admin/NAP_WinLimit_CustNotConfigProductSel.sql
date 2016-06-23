USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustNotConfigProductSel_xtest]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustNotConfigProductSel_xtest];
GO
USE [CustDB];
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustNotConfigProductSel_xtest]    Script Date: 07/07/2015 16:09:00 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustNotConfigProductSel_xtest] @Username VARCHAR(100) = ''
AS
	
/*
	Created: Jacob	
	Date: 2016-06-30
	Task: #38608 - Implement function to control Player's Win Limit on specific Product
	
	DB: DBCust/CustDB
	
	Revisions:
	
	Parameters Explanation:	
	
	EXEC [NAP_WinLimit_CustNotConfigProductSel_xtest] @Username = '166HK488'
	
*/

     SET NOCOUNT ON;
     BEGIN -- @CustID, @CurrencyID.
         DECLARE @CustID INT, @CurrencyID INT, @CurrencyName NVARCHAR(50), @AgentId INT;
         SELECT @CustID = c.custid,
                @CurrencyID = e.exchangeid,
                @CurrencyName = e.currency,
                @AgentId = c.recommend
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
                pd.BetTypeId,
                pd.LevelId,
                pd.MaxWinLimit AS CurrencyWinLimit
         FROM dbo.Winlimit_ProductSetting ps WITH (NOLOCK)
              INNER JOIN DBPRO.bodb02.dbo.Products p ON ps.ProductId = p.ProductId
              INNER JOIN dbo.WinLimit_ProductSettingDetail pd WITH (NOLOCK) ON ps.ProductId = pd.ProductId
                                                                               AND ps.BetTypeId = pd.BetTypeId
                                                                               AND ps.LevelId = pd.LevelId
              LEFT JOIN @ExistedSetting e ON e.ProductId = ps.ProductId
                                             AND e.BetTypeId = ps.BetTypeId
                                             AND e.LevelId = ps.LevelId
         WHERE pd.SiteId = @SiteId
               AND pd.ExchangeId = @CurrencyId
               AND e.MaxWinLimit IS NULL
               AND ps.SettingStatus = 1;
     END;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustNotConfigProductSel_xtest] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustNotConfigProductSel_xtest] TO [vnteam];
GO