USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustNotConfigProductCheck_xtest]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustNotConfigProductCheck_xtest];
GO
USE [CustDB];
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustNotConfigProductCheck_xtest]    Script Date: 07/07/2015 16:09:00 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustNotConfigProductCheck_xtest] @Username        VARCHAR(100) = '',
                                                                      @ExcludeTestData BIT          = 1
AS
	
/*
	Created: Jacob	
	Date: 2016-06-30
	Task: #38608 - Implement function to control Player's Win Limit on specific Product
	
	DB: DBCust/CustDB
	
	Revisions:
	
	Parameters Explanation:	
	
	EXEC [NAP_WinLimit_CustNotConfigProductCheck_xtest] @Username = '166HK488' , @ExcludeTestData = 0
	
*/

     SET NOCOUNT ON;
     BEGIN -- Check custname is valid or not.
         DECLARE @CustID INT, @CurrencyID INT, @CurrencyName NVARCHAR(50), @AgentId INT;
         SELECT @CustID = c.custid,
                @CurrencyID = e.exchangeid,
                @CurrencyName = e.currency,
                @AgentId = c.recommend
         FROM dbo.Customer c WITH (NOLOCK)
              INNER JOIN dbo.exchange e WITH (NOLOCK) ON c.currency = e.exchangeid
                                                         AND (@ExcludeTestData = 0
                                                              OR e.currency NOT IN('UUS', 'H', 'C'))
         WHERE c.username = @Username
               AND c.roleid = 1;
         IF @CustID IS NULL
             BEGIN
                 SELECT 3 AS ErrorCode,
                        '' AS ErrorMessage;
                 RETURN;
             END;
     END;
     BEGIN -- SiteId
         DECLARE @SiteId INT, @SiteName VARCHAR(50);
         SELECT @SiteId = s.siteid,
                @SiteName = c.[site]
         FROM dbo.Customer c WITH (NOLOCK)
              INNER JOIN dbo.[Site] s WITH (NOLOCK) ON c.site = s.site
         WHERE CustId = @AgentId;
     END;
     BEGIN -- Check Currency Win Limit is set or not
         DECLARE @CurrencySettingCount INT;
         SELECT @CurrencySettingCount = COUNT(1)
         FROM WinLimit_ProductSettingDetail WITH (NOLOCK)
         WHERE ExchangeID = @CurrencyID
               AND SiteId = @SiteId;
         IF @CurrencySettingCount = 0
             BEGIN
                 SELECT 4 AS ErrorCode,
                        'Site: '+@SiteName+'. Currency: '+@CurrencyName AS ErrorMessage;
                 RETURN;
             END;
     END;
     SELECT 0 AS ErrorCode,
            '' AS ErrorMessage;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustNotConfigProductCheck_xtest] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustNotConfigProductCheck_xtest] TO [vnteam];
GO