USE bodb02
GO 
 
ALTER PROCEDURE [dbo].[Acc_Rpt_NonSportsProductStatistic_SiteSel]
AS
/*
	Created by: 20160908@Sophia.Nguyen
	Task : Get Company 
	DB: DBACC/bodb02
	
	Revisions:	
	Param Explaination:


*/

BEGIN
SET NOCOUNT ON

	SELECT Site 
	FROM (
			--SELECT 'ALL' as Site , -1 AS OrderId --- All: Credit and Deposit
			--UNION 
			SELECT 'MBC' as Site,  0 AS OrderId  --- Credit only
			UNION
			SELECT	Licenseename as Site, LicenseeId As OrderId 
			FROM	DBLIC.bodb_Licensee.dbo.Licensees
			WHERE	IsDeposit = 1
		) A
	ORDER BY A.OrderId

END 
 

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_NonSportsProductStatistic_SiteSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_NonSportsProductStatistic_SiteSel] TO [vnteam]
GO