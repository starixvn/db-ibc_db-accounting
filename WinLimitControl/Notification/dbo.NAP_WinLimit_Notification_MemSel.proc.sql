/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_Notification_MemSel]    Script Date: 7/1/2016 10:22:38 AM ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/*
Created: 20150702@bobby.nguyen
Task : #35215 - Win Limit Control - Notification select member
DB: DBCUST.CustDB
Original:
Revisions:
	- 20150702@bobby.nguyen: Initial
	- 20160507@Patrick: #57213 - Voidbridge integration
	- 20160523@Helen: Hardcode for UUS - [Redmine: 57940]
	- 20160524@Helen: Change condition to send email - [Redmine: 57940]
	- 20160701@Robert: CWL - Phase 2 - Support RED and Yellow level - [Redmine: 57722]
	- 20160802@Robert: CWL Phase 2 - Wrong Exchange Rate using in the email notification - [Redmine: 61839]
	- 20160802@Robert: CWL Phase 2 - email notification Enhancement - [Redmine: 62253]
	- 20161027@Robert: CWL Phase 3 - email notification Enhancement - [Redmine: 61220]
	- 20170329@Robert: CWL Phase 3A - email notification Enhancement - [Redmine: 72604]
	
Param's Explanation:
	• @ErrCode:
		= 0: Transaction recorded successfully.
		> 0: Specific Error.
	• @ErrMsg: Error description.
*/

ALTER PROCEDURE [dbo].[NAP_WinLimit_Notification_MemSel]
AS
     BEGIN
         DECLARE @Fromdate DATE= GETDATE(), @Todate DATE= GETDATE();
         SELECT DISTINCT
                wl.custid,
                c.username,
                CASE
                    WHEN e.CurrencyId = 20
                    THEN 'UUS'
                    ELSE e.CurrencyCode
                END AS code,
                ag.site,
                s.isLicensee AS IsDeposit,
                p.ProductName,
                p.ProductId,
                wl.GroupID,
                wl.MaxWinLimit AS WinlimitAmount,
                wl.TotalWinAmt AS TotalWinAmt_OriginalCurrency,
                wl.TotalWinAmt * e.Rate AS TotalWinAmt_BaseCurrency,
                wl.ModifiedDate,
                wl.WinlostDate,
                wl.LevelId,
                l.LevelName,
                e.Rate AS ExchangeRate
         FROM WinLimit_CustGameMonitoring wl WITH (NOLOCK)
              INNER JOIN WinLimit_GameGroupSetting GGS WITH (NOLOCK) ON WL.GroupID = GGS.GroupID
              INNER JOIN Customer c WITH (NOLOCK) ON c.custid = wl.CustID
              INNER JOIN Customer ag WITH (NOLOCK) ON ag.custid = c.recommend
              INNER JOIN Site S WITH (NOLOCK) ON S.site = ag.site
              INNER JOIN DBPRO.bodb02.dbo.Products p WITH (NOLOCK) ON p.ProductID = wl.ProductID
              INNER JOIN Winlimit_LevelSetting l WITH (NOLOCK) ON l.LevelId = wl.LevelId
              INNER JOIN
         (
             SELECT fEx.ExchangeId AS CurrencyId,
                    fEx.Code AS CurrencyCode,
                    fEx.MYR AS Rate
             FROM Lrf_f_GetExchangeDaily(@Fromdate, @Todate) AS fEx
         ) e ON c.currency = e.CurrencyId
         WHERE wl.IsNotified = 0
               AND S.isActive = 1;
     END;
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_Notification_MemSel] TO [vnteam];
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_Notification_MemSel] TO [bodbAdminNet];