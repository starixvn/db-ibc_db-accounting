/*<info serverAlias="DBLIC-bodb_Licensee" selecters="wsv_nap" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[f_Hide_Licensee]()
RETURNS @OutPutTable TABLE (LicenseeID INT, LicenseeName VARCHAR(50))	
AS
/*
	Created: 20241206@Eddie
	Task : Hide special licensees from Auto mail and [Manage Licensee Code] function
	DB: DBLIC-bodb_Licensee
	
	Revisions:
		- 20241206@Eddie: Initialize function [Redmine: #207696]

*/
BEGIN

	INSERT INTO @OutPutTable(LicenseeID, LicenseeName)
	SELECT LicenseeID, LicenseeName
	FROM dbo.Licensees WITH (NOLOCK)
	WHERE LicenseeName IN ('Spondemo', 'Athena000', 'SampleSite', 'Sabademo', 'Saba789', 'Seal888', 'N8I', 'SabaCoins', 'NovaCasino', 'NSDemo1SW')

	RETURN
END
GO