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
	
Param's Explanation:
	• @ErrCode:
		= 0: Transaction recorded successfully.
		> 0: Specific Error.
	• @ErrMsg: Error description.
*/

ALTER PROCEDURE [dbo].[NAP_WinLimit_Notification_MemSel]
AS
     BEGIN
         SELECT wl.custid,
                c.username,
                CASE
                    WHEN e.ExchangeID = 20
                    THEN 'UUS'
                    ELSE e.code
                END AS code,
                ag.site,
                p.ProductName,
                p.ProductId,
			 wl.BettypeId,
                wl.TotalWinAmt AS TotalWinAmt_OriginalCurrency,
                wl.TotalWinAmt * e.actualrate AS TotalWinAmt_BaseCurrency,
                wl.ModifiedDate,
                wl.WinlostDate,
                wl.LevelId,
                l.LevelName
         FROM WinLimit_CustGameMonitoring wl WITH (NOLOCK)
              INNER JOIN Customer c WITH (NOLOCK) ON c.custid = wl.CustID
              INNER JOIN Customer ag WITH (NOLOCK) ON ag.custid = c.recommend
              INNER JOIN DBPRO.bodb02.dbo.Products p WITH (NOLOCK) ON p.ProductID = wl.ProductID
              INNER JOIN exchange e WITH (NOLOCK) ON c.currency = e.exchangeid
              INNER JOIN Winlimit_LevelSetting l WITH (NOLOCK) ON l.LevelId = wl.LevelId
         WHERE wl.IsNotified = 0;
     END;
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_Notification_MemSel] TO [vnteam];
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_Notification_MemSel] TO [bodbAdminNet];


