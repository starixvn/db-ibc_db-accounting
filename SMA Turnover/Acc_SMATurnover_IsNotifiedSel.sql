 
ALTER PROCEDURE [dbo].[Acc_SMATurnover_IsNotifiedSel]
AS
/*
	Created: 20130702@Lukas
	Task: get super-event that reached 80% Turnover used to notify
	DB: DBAGE/bodb02
	
	Revisions:
		-- 20140630@Lukas: add 1 more specific level for notification - 95% [Redmine:#18384]

*/
BEGIN
	SET NOCOUNT ON

	SELECT  m.sporttype, m.leagueid, m.matchid, m.homeid, m.awayid,m.eventdate,c.custid, c.username, e.currency,
			t.totalturnover, t.maxturnover, 95 as nlevel
	FROM DownlineTurnover_Setting t WITH(NOLOCK) 
		INNER JOIN match m WITH (NOLOCK) ON t.matchid = m.matchid
		INNER JOIN custInfo c WITH (NOLOCK) ON t.custID = c.custid
		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE CASE WHEN t.MaxTurnover <> 0 THEN (t.TotalTurnover/MaxTurnover)*100 ELSE 0 END >= 95.0
		AND IsNotified < 95

	UNION ALL
	SELECT  m.sporttype, m.leagueid, m.matchid, m.homeid, m.awayid,m.eventdate,c.custid, c.username, e.currency,
			t.totalturnover, t.maxturnover, 80 as nlevel
	FROM DownlineTurnover_Setting t WITH(NOLOCK) 
		INNER JOIN match m WITH (NOLOCK) ON t.matchid = m.matchid
		INNER JOIN custInfo c WITH (NOLOCK) ON t.custID = c.custid
		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE CASE WHEN t.MaxTurnover <> 0 THEN (t.TotalTurnover/MaxTurnover)*100 ELSE 0 END >= 80.0
		AND CASE WHEN t.MaxTurnover <> 0 THEN (t.TotalTurnover/MaxTurnover)*100 ELSE 0 END < 95.0
		AND IsNotified < 80
	ORDER BY Leagueid, matchid, username
	
END
GO
GRANT EXECUTE ON [dbo].[Acc_SMATurnover_IsNotifiedSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SMATurnover_IsNotifiedSel] TO vnteam
