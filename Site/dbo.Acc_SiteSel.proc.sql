ALTER PROCEDURE [dbo].[Acc_SiteSel] 
 @System varchar(50) = 'ACCOUNTING'
AS
/*
DB: DB052.BODB02

Revisions:
	- 20100819@Ethan: get Sites by System
	- 20110310@Henry: get active credit sites and licensee sites
	
*/
SET NOCOUNT ON
IF(@System = 'ACCOUNTING')
BEGIN

SELECT [siteid], [site],  isLicensee
FROM [Site] with (NOLOCK)
WHERE isActive = 1 
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


