ALTER PROCEDURE [dbo].[Acc_SiteSel] 
 @System varchar(50) = 'ACCOUNTING'
AS
/*
DB: DB052.BODB02

Revisions:
	- 20100819@Ethan: get Sites by System
	- 20110310@Henry: get active credit sites and licensee sites
	- 20130624@Jim: support to view active licensee only
*/
SET NOCOUNT ON
IF(@System = 'ACCOUNTING')
BEGIN
	WITH cte_systemlicensee
	as 
	(
	select l.licenseeid,l.licenseename
	from bodb_licensee.dbo.licensees l with (nolock)	
		inner join bodb_licensee.dbo.systemlicensee sl with (nolock) on l.licenseeid=sl.licenseeid and sl.systemid=3
	where sl.isActive=1	
	)
	SELECT [siteid], [site],  isLicensee
	FROM [Site] s with (NOLOCK)
		inner join cte_systemlicensee ce on ce.licenseename=s.[site]
	WHERE s.isActive = 1
	ORDER BY isLicensee, [site]
END
ELSE
BEGIN
	SELECT [siteid], [site], isLicensee
	FROM [Site] with (NOLOCK) 
	WHERE 
		siteid in (SELECT siteid FROM dbo.f_SiteBySystem(@System))
		and isActive = 1
	ORDER BY isLicensee, [site]
END

GO
GRANT EXECUTE ON [dbo].[Acc_SiteSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_SiteSel] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SiteSel] TO [vnteam]