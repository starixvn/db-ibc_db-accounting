CREATE PROCEDURE NAP_WinLimit_ExchangeRateSel
AS
     SET NOCOUNT ON;
     DECLARE @Fromdate DATE= GETDATE(), @Todate DATE= GETDATE();
     SELECT fEx.ExchangeId AS CurrencyId,
            fEx.Code AS CurrencyCode,
            fEx.MYR AS Rate
     FROM Lrf_f_GetExchangeDaily(@Fromdate, @Todate) fEx;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_ExchangeRateSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_ExchangeRateSel] TO [vnteam];
GO