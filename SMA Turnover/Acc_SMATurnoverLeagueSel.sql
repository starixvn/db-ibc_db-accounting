ALTER PROCEDURE [dbo].[Acc_SMATurnoverLeagueSel]
	@SportType INT, 
	@FromDate DATETIME, 
	@ToDate DATETIME,
	@MoveBetsDay  DATETIME
AS
/*
	Created: Elodie
	Date: 20130515
	Task : Retrieve league by sport and eventdate
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: 
	
*/
SET NOCOUNT ON

DECLARE @League AS TABLE (LeagueID INT, LeagueName	NVARCHAR(200))

IF @Todate <= @MoveBetsDay
BEGIN
	INSERT INTO @League (LeagueID, LeagueName)
	SELECT DISTINCT l.leagueid, l.leaguename
	FROM League l WITH(NOLOCK) 
		INNER JOIN match14 m WITH (NOLOCK) ON l.leagueid = m.leagueid
	WHERE l.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @ToDate
END
ELSE IF @FromDate > @MoveBetsDay
BEGIN
	INSERT INTO @League (LeagueID, LeagueName)
	SELECT DISTINCT l.leagueid, l.leaguename
	FROM League l WITH(NOLOCK) 
		INNER JOIN match m WITH (NOLOCK) ON l.leagueid = m.leagueid
	WHERE l.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @ToDate
END
ELSE
BEGIN
	INSERT INTO @League (LeagueID, LeagueName)
	SELECT DISTINCT l.leagueid, l.leaguename
	FROM League l WITH(NOLOCK) 
		INNER JOIN match14 m WITH (NOLOCK) ON l.leagueid = m.leagueid
	WHERE l.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @MoveBetsDay
	
	INSERT INTO @League (LeagueID, LeagueName)
	SELECT DISTINCT l.leagueid, l.leaguename
	FROM League l WITH(NOLOCK) 
		INNER JOIN match m WITH (NOLOCK) ON l.leagueid = m.leagueid
	WHERE l.sporttype = @SportType AND m.eventdate BETWEEN @MoveBetsDay AND @ToDate
END

SELECT DISTINCT leagueid, leaguename
FROM @League
ORDER BY leaguename ASC

GO
GRANT EXECUTE ON [dbo].[Acc_SMATurnoverLeagueSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SMATurnoverLeagueSel] TO [vnteam]

--EXEC Acc_SMATurnoverLeagueSel @SportType = 1, @FromDate = '2013-05-10', @ToDate = '2013-05-15', @MoveBetsDay = '2013-05-05'