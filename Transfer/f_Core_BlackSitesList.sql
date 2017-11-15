
ALTER FUNCTION dbo.f_Core_BlackSitesList()
RETURNS TABLE    
AS
RETURN (
	WITH __siteList AS (
		SELECT NULL AS siteName
		--//add more site here
	)
	SELECT siteName
	FROM __siteList
	WHERE siteName IS NOT NULL
)