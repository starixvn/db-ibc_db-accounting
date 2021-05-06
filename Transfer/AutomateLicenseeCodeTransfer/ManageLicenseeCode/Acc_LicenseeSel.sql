/*<info serverAlias="DBLIC-bodb_Licensee" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_LicenseeSel
AS
/*
	Created: 20200615@Sol
	Task : Get list licensee
	DB: DBLIC-bodb_Licensee
	
	Revisions:
		- 20200615@Sol: NAP - Auto Assign Licensee code to the Licensee accordingly - [Redmine: #120670]
		- 20210506@Sol: NAP - Remove Saba789 from auto mail informing the code needed - [Redmine: #154676]

*/
BEGIN
	
	SET NOCOUNT ON;

	SELECT DISTINCT l.LicenseeID, l.LicenseeName
	FROM dbo.Licensees l WITH(NOLOCK)
			INNER JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK)
				on cs.[site] = l.LicenseeName
	WHERE 
		l.IsActive = 1
		AND cs.currency <> 20
		AND l.LicenseeName <> 'Saba789'
	ORDER BY l.LicenseeName

END
GO