ALTER PROCEDURE [dbo].[NAP_SMATurnover_LeagueControlSel]
	@SportID INT = 1,
	@ProgramID VARCHAR(10) = '',
	@DisplayMode TINYINT = 0,
	@CountryCode VARCHAR(20) = '',
	@AllMarket BIT = 1,
	@LeagueName NVARCHAR(100) = '',
	@OnlyShowException BIT = 0
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Retrieve configure TO information by league
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		@AllMarket: 1: All
					0: Main market
	Example: EXEC NAP_SMATurnover_LeagueControlSel @SportID = 1, @LeagueName = 'Champion'
	
*/
BEGIN
	SET NOCOUNT ON
	IF EXISTS (	SELECT 1 
				FROM bodb02.dbo.League l WITH (NOLOCK)
				WHERE	l.sporttype = @SportID AND l.IsActive = 1 AND 
						ISNULL(l.ProgramID,'') = CASE WHEN @ProgramID = '' THEN ISNULL(l.ProgramID,'') ELSE @ProgramID END AND
						l.DisplayMode = CASE WHEN @DisplayMode = 0 THEN l.DisplayMode ELSE @DisplayMode END AND
						ISNULL(l.CountryCode,'') = CASE WHEN @CountryCode = '' THEN ISNULL(l.CountryCode,'') ELSE @CountryCode END AND
						l.IsMainMarket = CASE WHEN @AllMarket = 1 THEN l.IsMainMarket ELSE 1 END AND
						1= CASE WHEN @LeagueName = '' THEN 1
								WHEN l.LeagueName like '%' + @LeagueName + '%' THEN 1
								ELSE 0 END)
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
				ISNULL(l.ProgramID,'') = CASE WHEN @ProgramID = '' THEN ISNULL(l.ProgramID,'') ELSE @ProgramID END AND
				l.DisplayMode = CASE WHEN @DisplayMode = 0 THEN l.DisplayMode ELSE @DisplayMode END AND
				ISNULL(l.CountryCode,'') = CASE WHEN @CountryCode = '' THEN ISNULL(l.CountryCode,'') ELSE @CountryCode END AND
				l.IsMainMarket = CASE WHEN @AllMarket = 1 THEN l.IsMainMarket ELSE 1 END AND
				1= CASE WHEN @LeagueName = '' THEN 1
						WHEN l.LeagueName like '%' + @LeagueName + '%' THEN 1
						ELSE 0 END AND
				1= CASE WHEN lc.Value IS NOT NULL AND @OnlyShowException = 1 THEN 1 
						WHEN @OnlyShowException = 0 THEN 1 ELSE 0 END 
		ORDER BY l.leagueName
	ELSE
	BEGIN
		DECLARE @SportValue INT
		SELECT @SportValue = NULL

		SELECT @SportValue = Value FROM DownlineTo_SportControl WITH (NOLOCK) WHERE SportID = @SportID

		SELECT @SportID AS SportID, ISNULL(@SportValue,0) AS SportValue, 
				NULL AS LeagueID, NULL LeagueValue,  				
				NULL Exception
	END
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_LeagueControlSel] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_LeagueControlSel] TO [vnteam]