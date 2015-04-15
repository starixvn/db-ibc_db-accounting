ALTER PROCEDURE NAP_Rpt_SettlementStatistic
	@FromDate DATETIME
	,@ToDate DATETIME
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		s.SportName AS 'Sport'
		,CONVERT(VARCHAR(10),m.matchid) + '/' + m.matchcode AS 'Match Code/ID'
		,th.teamname + '-vs-' + ta.teamname AS Event
		,ss.Action
		,ss.StartTime AS 'Key Score'
		,DATEDIFF(MILLISECOND,ss.StartTime,ss.ExecTime) AS 'Settlement Delay'
		,DATEDIFF(MILLISECOND,ss.StartTime,ss.FinishTime) AS 'Result Delay'
		,DATEDIFF(MILLISECOND,ss.StartTime,ss.FinishTime) AS 'Balance Delay'
		,DATEDIFF(MILLISECOND,ss.StartTime,ss.repFinishTime) AS 'Statement Delay'
	FROM dbo.SettlementStatistics ss WITH(NOLOCK)
	INNER JOIN dbo.match14 m WITH(NOLOCK) ON m.matchid = ss.MatchId
	INNER JOIN dbo.League l WITH(NOLOCK)ON m.leagueid = l.leagueid
	INNER JOIN dbo.Sports s WITH(NOLOCK) ON s.SportType = m.sporttype
	INNER JOIN dbo.Team th WITH(NOLOCK) on th.teamid = m.homeid
	INNER JOIN dbo.Team ta WITH(NOLOCK) on ta.teamid = m.awayid
	WHERE StartTime BETWEEN @FromDate AND @ToDate 
	UNION ALL
	SELECT 
		s.SportName AS 'Sport'
		,CONVERT(VARCHAR(10),m.matchid) + '/' + m.matchcode AS 'Match Code/ID'
		,th.teamname + '-vs-' + ta.teamname AS Event
		,ss.Action
		,ss.StartTime AS 'Key Score'
		,DATEDIFF(MILLISECOND,ss.StartTime,ss.ExecTime) AS 'Settlement Delay'
		,DATEDIFF(MILLISECOND,ss.StartTime,ss.FinishTime) AS 'Result Delay'
		,DATEDIFF(MILLISECOND,ss.StartTime,ss.FinishTime) AS 'Balance Delay'
		,DATEDIFF(MILLISECOND,ss.StartTime,ss.repFinishTime) AS 'Statement Delay'
	FROM dbo.SettlementStatistics ss WITH(NOLOCK)
	INNER JOIN dbo.match m WITH(NOLOCK) ON m.matchid = ss.MatchId
	INNER JOIN dbo.League l WITH(NOLOCK)ON m.leagueid = l.leagueid
	INNER JOIN dbo.Sports s WITH(NOLOCK) ON s.SportType = m.sporttype
	INNER JOIN dbo.Team th WITH(NOLOCK) on th.teamid = m.homeid
	INNER JOIN dbo.Team ta WITH(NOLOCK) on ta.teamid = m.awayid
	WHERE StartTime BETWEEN @FromDate AND @ToDate 
	
END

