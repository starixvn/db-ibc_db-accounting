/*<info serverAlias="DBLIC-bodb_Licensee" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_LicenseeSel
AS
/*
	Created: 20200615@Sol
	Task : Get list licensee
	DB: DBLIC-bodb_Licensee
	
	Revisions:
		- 20200615@Sol: NAP - Auto Assign Licensee code to the Licensee accordingly - [Redmine: #120670]
		- 20210506@Sol: NAP - Remove Saba789 from auto mail informing the code needed - [Redmine: #154676]
		- 20210802@Sol: NAP - Remove Athena000 and Sabademo from auto mail informing the code needed - [Redmine: #159565]
		- 20220822@Danny: change code to support SiteDB [Redmine: #175253]
		- 20241206@Eddie: Hide special licensees [Redmine: #207696]

*/
BEGIN

	SET NOCOUNT ON;

	SELECT DISTINCT l.LicenseeID, l.LicenseeName
	FROM dbo.Licensees l WITH(NOLOCK)
		INNER JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK) ON cs.[site] = l.LicenseeName
	WHERE l.IsActive = 1 AND cs.currency <> 20 AND l.LicenseeName NOT IN (SELECT LicenseeName FROM dbo.f_Hide_Licensee())
	ORDER BY l.LicenseeName

END
GO