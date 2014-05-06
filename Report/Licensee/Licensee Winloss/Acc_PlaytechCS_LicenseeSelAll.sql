CREATE PROCEDURE [dbo].[Acc_PlaytechCS_LicenseeSelAll]
AS

/*
	Created by: [20140506@Hannah]
	Task: Get List of all licenseeS offerred Playtech CS
	DB: DB052.bodb02
	Revisions:
	
*/

SET NOCOUNT ON

SELECT   
	l.LicenseeID, l.LicenseeName, ISNULL(ba.EnableBA,0) as EnableBA,l.brandname  
FROM 
	bodb_Licensee.dbo.Licensees l WITH (NOLOCK)  
	INNER JOIN bodb_Licensee.dbo.SystemLicensee sl (NOLOCK) ON l.LicenseeID=sl.LicenseeID 
	INNER JOIN bodb_Licensee.dbo.Systems s (NOLOCK) ON sl.SystemID=s.ID 
	INNER JOIN bodb_Licensee.dbo.LicenseeFunctions lf (NOLOCK) ON lf.LicenseeId=l.LicenseeID 
	LEFT JOIN bodb_Licensee.dbo.LicenseeBAConfig ba WITH (NOLOCK) ON l.LicenseeID = ba.LicenseeID
WHERE 
	LicenseeName <> 'IBC' AND
	IsDeposit = 1
	AND sl.IsActive = 1
	AND s.SystemName='Accounting'
	AND lf.FunctionID = 61
ORDER BY l.LicenseeName ASC

GO
GRANT EXECUTE ON [dbo].[Acc_PlaytechCS_LicenseeSelAll] TO [bodbLicenseeNet]
GO
GRANT EXECUTE ON [dbo].[Acc_PlaytechCS_LicenseeSelAll] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_PlaytechCS_LicenseeSelAll] TO [vnteam]