ALTER PROCEDURE [dbo].[NAP_SMATurnover_LeagueSel]
	@SportID INT = 1
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Retrieve League list
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: 

	Example: EXEC NAP_SMATurnover_LeagueSel @SportID = 1									 
	
*/
SET NOCOUNT ON
SELECT DISTINCT l.leagueid, l.leaguename 
FROM League l WITH(NOLOCK) 
	INNER JOIN match m WITH (NOLOCK) ON l.leagueid = m.leagueid
WHERE l.sporttype = @SportID		
	AND l.IsActive = 1
ORDER BY l.leaguename

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_LeagueSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_LeagueSel] TO [vnteam]

