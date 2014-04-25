ALTER PROCEDURE [dbo].[NAP_SMATurnover_MonitorList]
	@FromDate DATETIME,
	@ToDate DATETIME,

	@SportType INT = 0,
	@LeagueID INT = 0,
	@MatchID INT = 0,
	@UsedPercent INT = 0,
	@SMAName VARCHAR(30) = '',
	@Top INT = 20,

	@MoveBetsDay  DATETIME	
AS
/*
	Created: Elodie
	Date: 20130515
	Task : Retrieve SMA Turnover Monitor list
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: 
	
	Example: EXEC [NAP_SMATurnover_MonitorList @SportType = 1, @LeagueID = 0, @FromDate = '2013-05-10', @ToDate = '2013-05-15', @MoveBetsDay = '2013-05-05'
	
*/
SET NOCOUNT ON

--IF @Todate <= @MoveBetsDay
--BEGIN	
--	SELECT c.custID, c.username, e.currency, l.leaguename, l.leagueid, t.matchID, m.homeid, m.awayid, m.eventdate, m.eventstatus, t.MaxTurnover, t.TotalTurnover,
--			CASE WHEN t.maxturnover = 0 THEN 0 ELSE t.totalturnover*100/t.maxturnover END AS PercentageUsed
--	FROM DownlineTurnover_Setting t WITH(NOLOCK) 
--		INNER JOIN match14 m WITH (NOLOCK) ON t.matchid = m.matchid
--		INNER JOIN custInfo c WITH (NOLOCK) ON t.custID = c.custid
--		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
--		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
--	WHERE m.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @ToDate
--			AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END		
--	ORDER BY l.leaguename, t.matchid, c.username
--END
--ELSE IF @FromDate > @MoveBetsDay
--BEGIN
--	SELECT c.custID, c.username, e.currency, l.leaguename, l.leagueid, t.matchID, m.homeid, m.awayid, m.eventdate, m.eventstatus, t.MaxTurnover, t.TotalTurnover,
--			CASE WHEN t.maxturnover = 0 THEN 0 ELSE t.totalturnover*100/t.maxturnover END AS PercentageUsed
--	FROM DownlineTurnover_Setting t WITH(NOLOCK) 
--		INNER JOIN match m WITH (NOLOCK) ON t.matchid = m.matchid
--		INNER JOIN custInfo c WITH (NOLOCK) ON t.custID = c.custid
--		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
--		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
--	WHERE m.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @ToDate
--			AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END
--	ORDER BY l.leaguename, t.matchid, c.username
--END	
--ELSE 
--BEGIN
--	SELECT c.custID, c.username, e.currency, l.leaguename, l.leagueid, t.matchID, m.homeid, m.awayid, m.eventdate, m.eventstatus, t.MaxTurnover, t.TotalTurnover,
--		CASE WHEN t.maxturnover = 0 THEN 0 ELSE t.totalturnover*100/t.maxturnover END AS PercentageUsed
--	FROM DownlineTurnover_Setting t WITH(NOLOCK) 
--		INNER JOIN match14 m WITH (NOLOCK) ON t.matchid = m.matchid
--		INNER JOIN custInfo c WITH (NOLOCK) ON t.custID = c.custid
--		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
--		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
--	WHERE m.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @MoveBetsDay
--			AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END
--	UNION ALL
--	SELECT c.custID, c.username, e.currency, l.leaguename, l.leagueid, t.matchID, m.homeid, m.awayid, m.eventdate, m.eventstatus, t.MaxTurnover, t.TotalTurnover,
--		CASE WHEN t.maxturnover = 0 THEN 0 ELSE t.totalturnover*100/t.maxturnover END AS PercentageUsed
--	FROM DownlineTurnover_Setting t WITH(NOLOCK) 
--		INNER JOIN match m WITH (NOLOCK) ON t.matchid = m.matchid
--		INNER JOIN custInfo c WITH (NOLOCK) ON t.custID = c.custid
--		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
--		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
--	WHERE m.sporttype = @SportType AND m.eventdate BETWEEN @MoveBetsDay AND @ToDate
--			AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END
--	ORDER BY l.leaguename, t.matchid, c.username
--END	

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_MonitorList] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_MonitorList] TO [vnteam]

