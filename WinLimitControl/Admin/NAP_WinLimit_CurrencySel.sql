CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySel] @SiteId              INT = NULL,
                                                  @IsCreditSite        BIT = 0,
                                                  @ExcludeTestCurrency BIT = 0
AS
	
/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608 - Implement function to control Player's Win Limit on specific Product

		DB: DBCUST/CustDB
		
		Revisions:
		20160616@Franklin: Implement Game Win Limit Control phase2 [#57722].
		
		Parameters Explanation:	
		   @SiteId: Site Or Licensee ID.
		   @IsCreditSite: Is Credit Site.
		   @ExcludeTestCurrency: Exclude used Currency.
*/

     BEGIN
         SET NOCOUNT ON;
         IF @SiteId IS NULL
            OR @IsCreditSite = 1
             BEGIN
                 SELECT ex.exchangeid AS ExchangeId,
                        ex.Code+' ('+ex.currency+')' AS ExchangeName
                 FROM dbo.exchange ex WITH (NOLOCK)
                 WHERE(@ExcludeTestCurrency = 0
                       OR ex.currency NOT IN('UUS'))
                 AND ex.currency NOT IN('H', 'C')
                 ORDER BY ExchangeName;
             END;
         ELSE
             BEGIN
                 SELECT DISTINCT
                        ex.exchangeid AS ExchangeId,
                        ex.Code+' ('+ex.currency+')' AS ExchangeName
                 FROM DBLIC.bodb_licensee.dbo.LicenseeCust lc WITH (NOLOCK)
                      INNER JOIN DBLIC.bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeID = lc.LicenseeID
                      INNER JOIN dbo.exchange ex WITH (NOLOCK) ON lc.Currency = ex.exchangeid
                      INNER JOIN dbo.site s WITH (NOLOCK) ON s.site = l.LicenseeName
                 WHERE s.siteid = @SiteId
                       AND (@ExcludeTestCurrency = 0
                            OR ex.currency NOT IN('UUS'))
                      AND ex.currency NOT IN('H', 'C')
                 ORDER BY ExchangeName;
             END;
     END;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CurrencySel] TO [vnteam];
GO