ALTER PROCEDURE [dbo].[NAP_SMATurnover_EventSel]
	@SportID INT = 0,
	@LeagueID INT = 0,
	@MatchCode NVARCHAR(50) = '',

	@ViewMode INT = 1,
	@OnlyShowException BIT = 0
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Retrieve configure TO information by event
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		@ViewMode:  1: Sport view
					2: League view
					3: Match view
	Example: EXEC NAP_SMATurnover_EventSel @SportID = 5, @LeagueID = 23123, @MatchCode = '', @ViewMode = 3, @OnlyShowException = 1
	
*/
BEGIN
	SET NOCOUNT ON
	
	IF @ViewMode = 1
	BEGIN
		SELECT s.SportType AS SportID, ISNULL(sc.Value,0) AS SportValue 
		FROM DownlineTo_SportControl sc WITH (NOLOCK)
			RIGHT JOIN bodb02.dbo.Sports s WITH (NOLOCK) ON s.SportType = sc.SportID
		WHERE s.SportType < 99
		ORDER BY s.SportType
	END
	IF @ViewMode = 2
	BEGIN
		SELECT @SportID AS SportID, ISNULL(sc.Value,0) AS SportValue, 
				l.LeagueID, 
				CASE WHEN lc.Value IS NULL AND sc.Value IS NULL THEN 0 
						WHEN lc.Value IS NULL THEN sc.Value 
						ELSE lc.Value END AS LeagueValue, 
				CASE WHEN lc.Value IS NULL THEN 0 ELSE 1 END AS Exception
			FROM DownlineTo_LeagueControl lc WITH (NOLOCK) 
				RIGHT JOIN bodb02.dbo.League l WITH (NOLOCK) ON l.leagueid = lc.LeagueID
				LEFT JOIN DownlineTo_SportControl sc WITH (NOLOCK) ON l.sporttype = sc.SportID
			WHERE l.sporttype = @SportID AND l.IsActive = 1 AND 
					l.leagueid = CASE WHEN @LeagueID = 0 THEN l.leagueid ELSE @LeagueID END AND
					1= CASE WHEN lc.Value IS NOT NULL AND @OnlyShowException = 1 THEN 1 
							WHEN @OnlyShowException = 0 THEN 1 ELSE 0 END 
			ORDER BY l.leagueName
	END
	IF @ViewMode = 3
	BEGIN
		SELECT	@SportID AS SportID, ISNULL(sc.Value,0) AS SportValue, 
				@LeagueID AS LeagueID, ISNULL(lc.Value,0) AS LeagueValue,  
				m.matchid, m.matchcode, m.homeid, m.awayid, m.eventdate, 
				CASE WHEN mc.Value IS NULL AND lc.Value IS NULL AND sc.Value IS NULL THEN 0
						WHEN mc.Value IS NULL AND lc.Value IS NULL THEN sc.Value
						WHEN mc.Value IS NULL THEN lc.Value
						ELSE mc.Value END AS MatchValue, 
				CASE WHEN mc.Value IS NULL THEN 0 ELSE 1 END AS Exception
		FROM DownlineTo_MatchControl mc WITH (NOLOCK)
			RIGHT JOIN bodb02.dbo.match m WITH (NOLOCK) ON m.matchid = mc.MatchID
			LEFT JOIN DownlineTo_LeagueControl lc WITH (NOLOCK) ON m.leagueid = lc.LeagueID
			LEFT JOIN DownlineTo_SportControl sc WITH (NOLOCK) ON m.sporttype = sc.SportID				
		WHERE m.leagueid = @LeagueID AND m.sporttype = @SportID AND 
				m.matchcode = CASE WHEN @MatchCode = '' THEN m.matchcode ELSE @MatchCode END AND
				m.eventstatus <> 'completed' AND m.matchcode NOT LIKE '%hedge%' AND 
				1= CASE WHEN mc.Value IS NOT NULL AND @OnlyShowException = 1 THEN 1 
						WHEN @OnlyShowException = 0 THEN 1 ELSE 0 END 
		ORDER BY m.matchcode
	END
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_EventSel] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_EventSel] TO [vnteam]