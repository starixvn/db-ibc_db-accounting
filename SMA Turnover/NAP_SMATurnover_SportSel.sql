ALTER PROCEDURE [dbo].[NAP_SMATurnover_SportSel]
	@Mode TINYINT = 0
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Retrieve Sport type
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: @Mode  = 0: Sport of sportbook
									 = 1: All sports
	Example: EXEC NAP_SMATurnover_SportSel @Mode = 1									 
	
*/
SET NOCOUNT ON
SELECT DISTINCT s.sporttype, s.sportname 
FROM sports s WITH(NOLOCK) 
	INNER JOIN match m WITH (NOLOCK) ON s.sporttype = m.sporttype
WHERE 1 = CASE  WHEN @Mode = 0 AND s.SportType < 99 THEN 1
				WHEN @Mode = 1 THEN 1
				ELSE 0 END			
	AND m.eventstatus <> 'completed' AND m.matchcode NOT LIKE '%hedge%'
ORDER BY s.sporttype

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_SportSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_SportSel] TO [vnteam]

