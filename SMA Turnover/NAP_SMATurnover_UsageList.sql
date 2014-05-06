ALTER PROCEDURE [dbo].[NAP_SMATurnover_UsageList]
	@FromDate DATETIME,
	@ToDate DATETIME,

	@SportType INT,
	@LeagueID INT,
	@MatchID INT,
	@UsedPercent INT = 0,
	@SMAName VARCHAR(30) = ''
AS
/*
	Created: Elodie
	Date: 20130515
	Task : Retrieve SMA Turnover Usage list
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: 
	
	Example: EXEC NAP_SMATurnover_UsageList @SportType = 1, @LeagueID = 33828, @MatchID = 6880531, @FromDate = '2014-06-10', @ToDate = '2014-06-15'
	
*/
SET NOCOUNT ON

SELECT c.custID, c.username, c.roleid, e.currency, c.credit, t.Value, t.MaxTurnover, t.TotalTurnover,
			CASE WHEN t.maxturnover = 0 THEN 0 ELSE CAST((t.totalturnover*100/t.maxturnover) AS INT) END AS PercentageUsed
	FROM DownlineTurnover_Setting t WITH(NOLOCK) 
		INNER JOIN match m WITH (NOLOCK) ON t.matchid = m.matchid
		INNER JOIN custInfo c WITH (NOLOCK) ON t.SMAID = c.custid
		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE m.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @ToDate
			AND m.leagueid = @LeagueID AND m.matchid = @MatchID 
			AND @UsedPercent <= CASE WHEN @UsedPercent <> 0 THEN t.totalturnover*100/t.maxturnover ELSE @UsedPercent END
			AND c.username like '%' + CASE WHEN @SMAName <> '' THEN @SMAName ELSE c.username END + '%'
	ORDER BY PercentageUsed desc, c.username	

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_UsageList] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_UsageList] TO [vnteam]

