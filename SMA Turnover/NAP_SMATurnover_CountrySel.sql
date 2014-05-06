ALTER PROCEDURE [dbo].[NAP_SMATurnover_CountrySel]
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Retrieve CountryCode
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination:

	Example: EXEC NAP_SMATurnover_CountrySel
	
*/
SET NOCOUNT ON

SELECT DISTINCT l.CountryCode
FROM league l WITH(NOLOCK) 
WHERE l.IsActive = 1 AND l.CountryCode <> '0' AND l.CountryCode IS NOT NULL
ORDER BY l.CountryCode

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_CountrySel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_CountrySel] TO [vnteam]

