ALTER  PROCEDURE [dbo].[Acc_LicenseeSelAll]
AS

/*
	Created by: [20120220@Henry]
	Task: Get List of all licensee 
	DB: bodb_MoveBet
	Revisions:
		- 20130624@Jim: support to view active licensee only
*/

SET NOCOUNT ON

SELECT   
	l.LicenseeID, l.LicenseeName 
FROM Licensees l WITH (NOLOCK)  
	INNER JOIN dbo.SystemLicensee sl WITH (NOLOCK) ON l.LicenseeID=sl.LicenseeID AND sl.SystemID=3
	INNER JOIN LicenseeBAConfig ba WITH (NOLOCK) ON l.LicenseeID = ba.LicenseeID
WHERE sl.isActive=1	

GO
GRANT EXECUTE ON [dbo].[Acc_LicenseeSelAll] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_LicenseeSelAll] TO [vnteam]

