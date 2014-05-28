ALTER PROCEDURE [dbo].[NAP_SMATurnover_LeagueSel]
	@SportID INT = 1,
	@FromDate DATETIME = NULL,
	@ToDate DATETIME = NULL,
	@Mode TINYINT = 0
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Retrieve League list
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: @Mode  = 0: League which have a unsettled match
									 = 1: All League
									 = 2: Get League in turnover usage list
									 = 3: Get League in turnover monitor list
	Example: EXEC NAP_SMATurnover_LeagueSel @SportID = 1, @Mode = 0								 
	
*/
SET NOCOUNT ON
SELECT DISTINCT l.leagueid, l.leaguename 
FROM League l WITH(NOLOCK) 
	INNER JOIN match m WITH (NOLOCK) ON m.leagueid = l.leagueid
WHERE l.sporttype = @SportID		
	AND l.IsActive = 1
	AND 1 = CASE WHEN @Mode = 0 AND m.eventstatus <> 'completed' AND m.matchcode NOT LIKE '%hedge%' THEN 1
				 WHEN @Mode = 1 THEN 1
				 WHEN @Mode = 2 AND @FromDate IS NOT NULL AND @ToDate IS NOT NULL AND m.eventdate BETWEEN @FromDate AND @ToDate THEN 1
				 --WHEN @Mode = 3 AND m.eventstatus = 'running' AND m.matchcode NOT LIKE '%hedge%' AND getdate() >= m.kickofftime THEN 1
				 ELSE 0 END	
ORDER BY l.leaguename

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_LeagueSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_LeagueSel] TO [vnteam]

