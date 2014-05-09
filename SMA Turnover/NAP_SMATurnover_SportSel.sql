ALTER PROCEDURE [dbo].[NAP_SMATurnover_SportSel]
	@Mode TINYINT = 0,
	@FromDate DATETIME = NULL,
	@ToDate DATETIME = NULL
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Retrieve Sport type
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: @Mode  = 0: Sport which have a unsettled match
									 = 1: All sports
									 = 2: Get sport in turnover monitor list
									 = 3: Get sports which have a live match
	Example: EXEC NAP_SMATurnover_SportSel @Mode = 0								 
	
*/
SET NOCOUNT ON

SELECT DISTINCT s.sporttype, s.sportname 
FROM sports s WITH(NOLOCK) 
	INNER JOIN match m WITH (NOLOCK) ON s.sporttype = m.sporttype
WHERE 1 = CASE  WHEN @Mode = 0 AND m.eventstatus <> 'completed' AND m.matchcode NOT LIKE '%hedge%' THEN 1
				WHEN @Mode = 1 THEN 1
				WHEN @Mode = 2 AND @FromDate IS NOT NULL AND @ToDate IS NOT NULL AND m.eventdate BETWEEN @FromDate AND @ToDate THEN 1
				WHEN @Mode = 3 AND m.eventstatus = 'running' AND m.matchcode NOT LIKE '%hedge%' AND m.kickofftime >= getdate() THEN 1
				ELSE 0 END
	AND s.sporttype < 99								
ORDER BY s.sporttype

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_SportSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_SportSel] TO [vnteam]

