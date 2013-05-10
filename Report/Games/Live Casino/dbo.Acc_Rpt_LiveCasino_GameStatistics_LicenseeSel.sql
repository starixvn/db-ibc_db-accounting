USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_Rpt_LiveCasino_GameStatistics_LicenseeSel]    Script Date: 11/06/2012 03:48:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_Rpt_LiveCasino_GameStatistics_LicenseeSel    Script Date: 9/13/2012 1:49:08 PM ******/
ALTER PROCEDURE [dbo].[Acc_Rpt_LiveCasino_GameStatistics_LicenseeSel]
AS
/*
	Created: Daniel
	Date: 2012-02-27
	Task: Get list licensees offered Live Casino
	DB: DB052.bodb02
	
	Revisions:
	- 20120913@Henry: Using ProductPrefix instead of ProductName
	- 20121006@Daniel: Only get deposit licensees

	
	Parameters Explanation:
*/
SET NOCOUNT ON 

	SELECT l.LicenseeID, l.Licenseename
	FROM bodb_Licensee.dbo.Product3rd p WITH (nolock)
		INNER join bodb_Licensee.dbo.LicenseeProduct3rd lp WITH (nolock) ON lp.productid = p.productid
		INNER join bodb_Licensee.dbo.Licensees l WITH (nolock) ON l.licenseeid = lp.licenseeid
	WHERE ProductPrefix = 'LC' AND IsDeposit = 1
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_LiveCasino_GameStatistics_LicenseeSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_LiveCasino_GameStatistics_LicenseeSel] TO [vnteam]