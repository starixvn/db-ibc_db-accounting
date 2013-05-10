ALTER PROCEDURE [dbo].[Acc_BA_LicConfigSel]
AS
/*
Created: Henry
Date: 20110606
Task : Get Licensee Commission Template for all Licensee
DB: DB052.bodb_Licensee
Original:

Revisions:
	- 20110823@Johnson: get more column commission by group for hdp, odd/even , over/under bettype.
	- 20011120@Jim: remove ugroup column
Param's Explanation:
	
*/
BEGIN
	SET NOCOUNT ON
		
	SELECT 
		A.LicenseeName, 
		B.LicenseeID, 
		B.groupa,
		B.groupb,
		B.groupc,
		B.groupd,
		B.[1x2Comm], 
		B.OtherComm, 		 
		B.EnableBA, 
		CASE WHEN C.username IS NULL THEN 'Unknown' ELSE C.username END AS ModifyBy,
		B.ModifyDate
	FROM LicenseeBAConfig B WITH (NOLOCK) 
	INNER JOIN Licensees A WITH (NOLOCK) ON A.LicenseeID = B.LicenseeID
	LEFT JOIN bodb02.dbo.Custinfo c WITH (NOLOCK) ON B.ModifyBy = c.Custid
	ORDER BY A.LicenseeID 
	
	
END



GO
GRANT EXECUTE ON [dbo].[Acc_BA_LicConfigSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BA_LicConfigSel] TO [vnteam]