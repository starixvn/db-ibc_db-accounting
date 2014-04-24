ALTER PROCEDURE [dbo].[NAP_SMATurnover_MatchControlSel]
	@SportID INT = 1,
	@LeagueID INT,
	@MatchCode NVARCHAR(50) = '',

	@OnlyShowException BIT = 0
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Retrieve configure TO information by match
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		
	Example: EXEC NAP_SMATurnover_MatchControlSel @SportID = 5, @LeagueID = 23123
	
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT	@SportID AS SportID, ISNULL(sc.Value,0) AS SportValue, 
			@LeagueID AS LeagueID, ISNULL(lc.Value,sc.Value) AS LeagueValue,  
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

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_MatchControlSel] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_MatchControlSel] TO [vnteam] 