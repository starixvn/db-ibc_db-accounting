ALTER PROCEDURE [dbo].[NAP_SMATurnover_IsNotifiedSel]
	@ThresholdValue INT = 80
AS
/*
	Created: 20140416@Elodie
	Task: get super-event that reached 80% Turnover used to notify
	DB: DBAGE/bodb02
	
	Revisions:
*/
BEGIN
	SET NOCOUNT ON

	SELECT  m.sporttype, m.leagueid, m.matchid, m.matchcode, m.homeid, m.awayid, m.eventdate, c.custid, c.username, c.roleid, e.currency,
			t.maxturnover, t.totalturnover, CASE WHEN t.MaxTurnover = 0 THEN 0 ELSE CAST((t.totalturnover/t.MaxTurnover*100) AS INT) END AS PercentageUsed
	FROM DownlineTurnover_Setting t WITH(NOLOCK) 
		INNER JOIN match m WITH (NOLOCK) ON t.matchid = m.matchid				
		INNER JOIN custInfo c WITH (NOLOCK) ON t.SMAID = c.custid		
		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE CASE WHEN t.maxturnover = 0 THEN 0 ELSE CAST((t.totalturnover/t.maxturnover*100) AS INT) END >= @ThresholdValue
		AND IsNotified = 0
	ORDER BY m.sporttype, m.leagueid, m.matchcode, c.username	
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_IsNotifiedSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_IsNotifiedSel] TO [vnteam]
