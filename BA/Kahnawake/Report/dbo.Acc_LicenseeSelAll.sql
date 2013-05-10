ALTER  PROCEDURE [dbo].[Acc_LicenseeSelAll]
AS

/*
	Created by: [20120220@Henry]
	Task: Get List of all licensee 
	DB: bodb_MoveBet
	Revisions:
	
*/

SET NOCOUNT ON

SELECT   
	l.LicenseeID, l.LicenseeName 
FROM Licensees l WITH (NOLOCK)  
INNER JOIN LicenseeBAConfig ba WITH (NOLOCK) ON l.LicenseeID = ba.LicenseeID

	
	



GO
GRANT EXECUTE ON [dbo].[Acc_LicenseeSelAll] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_LicenseeSelAll] TO [vnteam]

