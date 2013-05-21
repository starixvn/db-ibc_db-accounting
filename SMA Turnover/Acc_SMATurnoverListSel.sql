ALTER PROCEDURE [dbo].[Acc_SMATurnoverListSel]
	@SportType INT = 1, -- Soccer 
	@LeagueID INT = 0, -- All leagues
	@FromDate DATETIME, 
	@ToDate DATETIME,
	@MoveBetsDay  DATETIME	
AS
/*
	Created: Elodie
	Date: 20130515
	Task : Retrieve SMA Turnover list
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: 
	
	Example: EXEC Acc_SMATurnoverListSel @SportType = 1, @LeagueID = 0, @FromDate = '2013-05-10', @ToDate = '2013-05-15', @MoveBetsDay = '2013-05-05'
	
*/
SET NOCOUNT ON

IF @Todate <= @MoveBetsDay
BEGIN	
	SELECT c.custID, c.username, e.currency, l.leaguename, t.matchID, m.homeid, m.awayid, m.eventdate, m.ruben, t.MaxTurnover, t.TotalTurnover
	FROM DBTXN.bodb02.dbo.DownlineTurnover_Setting t WITH(NOLOCK) 
		INNER JOIN match14 m WITH (NOLOCK) ON t.matchid = m.matchid
		INNER JOIN custInfo c WITH (NOLOCK) ON t.custID = c.custid
		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE m.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @ToDate
			AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END		
	ORDER BY l.leaguename, t.matchid, c.username
END
ELSE IF @FromDate > @MoveBetsDay
BEGIN
	SELECT c.custID, c.username, e.currency, l.leaguename, t.matchID, m.homeid, m.awayid, m.eventdate, m.ruben, t.MaxTurnover, t.TotalTurnover
	FROM DBTXN.bodb02.dbo.DownlineTurnover_Setting t WITH(NOLOCK) 
		INNER JOIN match m WITH (NOLOCK) ON t.matchid = m.matchid
		INNER JOIN custInfo c WITH (NOLOCK) ON t.custID = c.custid
		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE m.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @ToDate
			AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END
	ORDER BY l.leaguename, t.matchid, c.username
END	
ELSE 
BEGIN
	SELECT c.custID, c.username, e.currency, l.leaguename, t.matchID, m.homeid, m.awayid, m.eventdate, m.ruben, t.MaxTurnover, t.TotalTurnover
	FROM DBTXN.bodb02.dbo.DownlineTurnover_Setting t WITH(NOLOCK) 
		INNER JOIN match14 m WITH (NOLOCK) ON t.matchid = m.matchid
		INNER JOIN custInfo c WITH (NOLOCK) ON t.custID = c.custid
		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE m.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @MoveBetsDay
			AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END
	UNION ALL
	SELECT c.custID, c.username, e.currency, l.leaguename, t.matchID, m.homeid, m.awayid, m.eventdate, m.ruben, t.MaxTurnover, t.TotalTurnover
	FROM DBTXN.bodb02.dbo.DownlineTurnover_Setting t WITH(NOLOCK) 
		INNER JOIN match m WITH (NOLOCK) ON t.matchid = m.matchid
		INNER JOIN custInfo c WITH (NOLOCK) ON t.custID = c.custid
		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE m.sporttype = @SportType AND m.eventdate BETWEEN @MoveBetsDay AND @ToDate
			AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END
	ORDER BY l.leaguename, t.matchid, c.username
END	

GO
GRANT EXECUTE ON [dbo].[Acc_SMATurnoverListSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SMATurnoverListSel] TO [vnteam]

