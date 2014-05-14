ALTER PROCEDURE [dbo].[NAP_SMATurnover_MonitorList]
	@SportType INT,
	@LeagueID INT = 0,
	@UsedPercent INT = 50
AS
/*
	Created: Elodie
	Date: 20130515
	Task : Retrieve SMA Turnover Monitor list
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: 
	
	Example: EXEC NAP_SMATurnover_MonitorList @SportType = 1, @LeagueID = 0, @UsedPercent = 5
	
*/
SET NOCOUNT ON

SELECT l.leagueid, m.matchid, m.matchcode, m.homeid, m.awayid, c.custID, c.username, c.roleid, e.currency, c.credit, t.Value, t.MaxTurnover, t.TotalTurnover,
		CASE WHEN t.maxturnover = 0 THEN 100 ELSE CAST((t.totalturnover/t.maxturnover*100) AS INT) END AS PercentageUsed
	FROM DownlineTurnover_Setting t WITH(NOLOCK) 
		INNER JOIN match m WITH (NOLOCK) ON t.matchid = m.matchid
		INNER JOIN custInfo c WITH (NOLOCK) ON t.SMAID = c.custid
		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE m.sporttype = @SportType 
			AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END
			AND @UsedPercent <= CASE WHEN @UsedPercent <> 0 THEN CASE WHEN t.maxturnover = 0 THEN 100 ELSE CAST((t.totalturnover/t.maxturnover*100) AS INT) END ELSE @UsedPercent END
			AND m.eventstatus = 'running' AND m.matchcode NOT LIKE '%hedge%' AND getdate() >= m.kickofftime
	ORDER BY l.leaguename, m.matchcode, PercentageUsed desc, c.username	

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_MonitorList] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_MonitorList] TO [vnteam]

