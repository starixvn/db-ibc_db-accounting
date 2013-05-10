 ALTER PROCEDURE [dbo].[Acc_IOM_SiteSel_Licensee]
AS 
/*	Created by: Elodie
	Date: 20120709
	DB: DB06.bodb02
	Task: List of licensees			
	Original sp: Acc_LicenseeSelAll
	
	Revisions:	
	 
	Param's Explanation:
	
*/

SET NOCOUNT ON 
 
SELECT	siteid as LicenseeID, site as LicenseeName
FROM	site WITH(NOLOCK)
WHERE	isLicensee = 1 AND isActive =1 
		AND siteID = 36 -- Alog
ORDER BY site
 

GO
GRANT EXECUTE ON [dbo].[Acc_IOM_SiteSel_Licensee] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_IOM_SiteSel_Licensee] TO [vnteam]
GO
 
 