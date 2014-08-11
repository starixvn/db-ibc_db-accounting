ALTER PROCEDURE [dbo].[NAP_Set_LeagueSelOutright]
	@FromDate datetime,
	@ToDate datetime,
	@sporttype tinyint = 0
AS
/**
 * Created by	: Jamie
 * Date			: 20130808
 * Task			: League Outright results 
 * DB			: DBPRO/bodb02

 * Revisions	:

 * Parameters:
 *  @FromDate: From  date,
	@ToDate: To date ,
	@sporttype: Sport type,	
	@sporttype: = 0: show info of all leagues     

 */
BEGIN 
	SET NOCOUNT ON
	IF @sporttype = 0
	BEGIN 
		SELECT DISTINCT o.leagueid, l.leaguename, l.sporttype
		FROM outright o (NOLOCK)
			INNER JOIN league l (NOLOCK) ON o.leagueid = l.leagueid 
		WHERE o.eventdate BETWEEN @FromDate AND @ToDate		
			  AND l.sporttype <=99 
		ORDER BY l.sporttype, l.leaguename
	END 
	ELSE 
	BEGIN 
		SELECT DISTINCT o.leagueid, l.leaguename, l.sporttype
		FROM outright o (NOLOCK)
			INNER JOIN league l (NOLOCK) ON o.leagueid = l.leagueid 
		WHERE o.eventdate BETWEEN @FromDate AND @ToDate		
			AND l.sporttype = @sporttype
		ORDER BY l.leaguename 
	END 
END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_LeagueSelOutright] TO [bodbAdminNet]	
GO 



