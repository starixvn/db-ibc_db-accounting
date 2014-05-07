ALTER PROCEDURE [dbo].[NAP_SMATurnover_MatchSel]
	@LeagueID INT,
	@FromDate DATETIME = NULL,
	@ToDate DATETIME = NULL
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Retrieve Match list in usage list
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: 
	Example: EXEC NAP_SMATurnover_MatchSel @LeagueID = 1564, @FromDate = '2014-05-06', @ToDate = '2014-05-11'									 
	
*/
SET NOCOUNT ON
SELECT m.matchid, m.homeid, m.awayid
FROM match m WITH (NOLOCK)
WHERE m.leagueid = 	@LeagueID AND m.eventdate BETWEEN @FromDate AND @ToDate AND matchcode NOT LIKE '%hedge%'
ORDER BY m.matchid

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_MatchSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_MatchSel] TO [vnteam]

