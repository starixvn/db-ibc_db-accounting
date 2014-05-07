ALTER PROCEDURE [dbo].[NAP_SMATurnover_SMAControlByEventSel]
	@SportID INT,
	@LeagueID INT
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Retrieve configure TO SMA by event
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		
	Example: EXEC NAP_SMATurnover_SMAControlByEventSel @SportID = 1, @LeagueID = 33828
	
*/
BEGIN
	SET NOCOUNT ON
			
	SELECT	m.matchid, m.matchcode, m.eventdate, m.homeid, m.awayid, c.custid, c.username, c.roleid, e.currency, c.credit, ms.Value, (c.credit/100 * ms.Value) AS MaxTurnover
	FROM DownlineTo_Match_SMAControl ms WITH (NOLOCK)
		RIGHT JOIN bodb02.dbo.match m WITH (NOLOCK) ON m.matchid = ms.MatchID
		LEFT JOIN bodb02.dbo.custInfo c WITH (NOLOCK) ON ms.SMAID = c.custid			
		LEFT JOIN bodb02.dbo.exchange e WITH (NOLOCK) ON e.exchangeid = c.currency	
	WHERE m.leagueid = @LeagueID AND m.sporttype = @SportID AND 
			m.eventstatus <> 'completed' AND m.matchcode NOT LIKE '%hedge%'
	ORDER BY m.matchid, c.username
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_SMAControlByEventSel] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_SMAControlByEventSel] TO [vnteam]