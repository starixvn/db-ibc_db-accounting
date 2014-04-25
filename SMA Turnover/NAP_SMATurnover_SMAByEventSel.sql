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
		
	Example: EXEC NAP_SMATurnover_SMAControlByEventSel @SportID = 5, @LeagueID = 23123
	
*/
BEGIN
	SET NOCOUNT ON
			
	SELECT	m.matchid, m.matchcode, m.eventdate, m.homeid, m.awayid, c.username, c.roleid, c.currency, c.credit, ms.Value, (c.credit * ms.Value)/100 AS MaxTurnover
	FROM DownlineTo_Match_SMAControl ms WITH (NOLOCK)
		INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON m.matchid = ms.MatchID
		INNER JOIN bodb02.dbo.custInfo c WITH (NOLOCK) ON ms.SMAID = c.custid					
	WHERE m.leagueid = @LeagueID AND m.sporttype = @SportID AND 
			m.eventstatus <> 'completed' AND m.matchcode NOT LIKE '%hedge%'
	ORDER BY m.matchid, c.username
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_SMAControlByEventSel] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_SMAControlByEventSel] TO [vnteam]