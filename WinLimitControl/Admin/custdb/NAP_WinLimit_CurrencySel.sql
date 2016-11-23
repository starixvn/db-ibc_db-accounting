USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CurrencySel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CurrencySel];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySel] @SiteId              INT = 0,
                                                  @IsCreditSite        BIT = 0,
                                                  @ExcludeTestCurrency BIT = 0
AS  
   
/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].
Parameters Explanation:  
     @SiteId: Site Or Licensee ID.  
     @IsCreditSite: Is Credit Site.  
     @ExcludeTestCurrency: Exclude used Currency.  
     
Example:
EXEC [NAP_WinLimit_CurrencySel] @SiteId=32, @IsCreditSite = 1, @ExcludeTestCurrency = 0
*/

     SET NOCOUNT ON;
     IF @SiteId = 0 -- All Currencies
         BEGIN
             SELECT ex.exchangeid AS Id,
                    ex.Code+' ('+ex.currency+')' AS Name
             FROM dbo.exchange ex WITH (NOLOCK)
             WHERE(@ExcludeTestCurrency = 0
                   OR ex.currency NOT IN('UUS'))
             AND ex.currency NOT IN('H', 'C')
             ORDER BY Name;
         END;
     ELSE
     IF @IsCreditSite = 1 -- Currencies for credit site
         BEGIN
             DECLARE @Dual TABLE(DUMMY VARCHAR(1));
             INSERT INTO @Dual
             VALUES('X');
             SELECT 'MYR (RM)' Name,
                    2 Id
             UNION
             SELECT 'USD ($US)',
                    35
             UNION
             SELECT 'USD (US$)',
                    3
             UNION
             SELECT 'USD (UT)',
                    64
             UNION
             SELECT 'USD (IRR)',
                    40
             UNION
             SELECT 'USD (NTD)',
                    17
             UNION
             SELECT 'USD (Yen)',
                    16
             UNION
             SELECT 'EUR (EURO)',
                    6
             UNION
             SELECT 'HKD (HK$)',
                    5
             UNION
             SELECT 'HKD (HKK)',
                    67
             UNION
             SELECT 'CNY (RMB)',
                    13
             UNION
             SELECT 'THB (THB)',
                    43
             UNION
             SELECT 'IDR (DDD)',
                    47
             UNION
             SELECT 'IDR (IDD)',
                    33
             UNION
             SELECT 'IDR (IDR)',
                    34
             UNION
             SELECT 'IDR (IN)',
                    15
             UNION
             SELECT 'IDR (IND)',
                    22
             UNION
             SELECT 'KRW (Won)',
                    45
             UNION
             SELECT 'MMK (MKK)',
                    70
             UNION
             SELECT 'MMK (MMK)',
                    69
             UNION
             SELECT 'SGD (SD$)',
                    1
             UNION
             SELECT 'GBP (GBP)',
                    12
             UNION
             SELECT 'THB (TB)',
                    4
             UNION
             SELECT 'INH (INH)',
                    51
             UNION
             SELECT 'INR (INR)',
                    61
             UNION
             SELECT '(UUS)',
                    20
             UNION
             SELECT '(YNG)',
                    72
             FROM @Dual
             WHERE @ExcludeTestCurrency = 0
             ORDER BY Name;
         END;
     ELSE -- Currencies for deposit site
         BEGIN
             SELECT DISTINCT
                    ex.exchangeid AS Id,
                    ex.Code+' ('+ex.currency+')' AS Name
             FROM DBLIC.bodb_licensee.dbo.LicenseeCust lc WITH (NOLOCK)
                  INNER JOIN DBLIC.bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeID = lc.LicenseeID
                  INNER JOIN dbo.exchange ex WITH (NOLOCK) ON lc.Currency = ex.exchangeid
                  INNER JOIN dbo.site s WITH (NOLOCK) ON s.site = l.LicenseeName
                                                         AND S.isActive = 1
             WHERE s.siteid = @SiteId
                   AND (@ExcludeTestCurrency = 0
                        OR ex.currency NOT IN('UUS'))
                  AND ex.currency NOT IN('H', 'C')
             ORDER BY Name;
         END;;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CurrencySel] TO [vnteam];
GO