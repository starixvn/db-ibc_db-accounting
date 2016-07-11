USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustSettingSel_xtest]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustSettingSel_xtest];
GO
USE [CustDB];
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustSettingSel]    Script Date: 07/07/2015 16:09:41 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingSel_xtest] @UserName            NVARCHAR(100) = '',
                                                           @Site                VARCHAR(50)   = NULL,
                                                           @CurrencyID          INT           = NULL,
                                                           @ProductID           TINYINT       = NULL,
                                                           @ExcludeTestCurrency BIT           = 1
AS
	
/*
Created: Jacob	
Date: 2016-06-30
Task: #57722 - CWL - Phase 2 - Support RED and Yellow level

DB: DBCUST/CustDB		
Revisions:
	
Parameters Explanation:	

Example: 
EXEC [NAP_WinLimit_CustSettingSel_xtest] @ExcludeTestCurrency = 0

*/

     SET NOCOUNT ON;
     SELECT c.CustID,
            c.username AS UserName,
            c.currency AS CurrencyId,
            s.Site,
            ps.ProductId AS ProductId,
            ps.BetTypeId AS BetTypeId,
            ps.LevelID AS LevelID,
            ISNULL(cs.MaxWinLimit, 0) PlayerWinLimit,
            ISNULL(pd.MaxWinLimit, 0) CurrencyWinLimit
     FROM dbo.Winlimit_ProductSetting ps WITH (NOLOCK)
          INNER JOIN dbo.WinLimit_CustGameSetting cs WITH (NOLOCK) ON ps.ProductID = cs.ProductID
                                                                      AND ps.BettypeID = cs.BettypeID
                                                                      AND ps.LevelID = cs.LevelID
          INNER JOIN dbo.custInfo c WITH (NOLOCK) ON cs.CustID = c.custid
          INNER JOIN dbo.customer a WITH (NOLOCK) ON a.custid = c.recommend
                                                     AND a.roleid = 2
          INNER JOIN dbo.[Site] s WITH (NOLOCK) ON s.[site] = a.[site]
          LEFT JOIN dbo.WinLimit_ProductSettingDetail pd WITH (NOLOCK) ON ps.ProductID = pd.ProductID
                                                                          AND ps.BettypeID = pd.BettypeID
                                                                          AND ps.LevelID = pd.LevelID
                                                                          AND pd.SiteId = s.SiteId
                                                                          AND pd.ExchangeId = c.currency
     WHERE ps.SettingStatus = 1
           AND (ISNULL(@UserName, '') = ''
                OR c.username = @UserName)
           AND (@CurrencyID IS NULL
                OR c.currency = @CurrencyID)
           AND (@ProductID IS NULL
                OR ps.ProductID = @ProductID)
           AND (@ExcludeTestCurrency = 0
                OR c.currency NOT IN(20, 27, 28))
     ORDER BY c.Username;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingSel_xtest] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustSettingSel_xtest] TO [vnteam];
GO