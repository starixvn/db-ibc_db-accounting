ALTER PROCEDURE [dbo].[NAP_SMATurnover_SpecialLeagueSel]
AS  
/*
	Created: Elodie
	Date: 20140416
	Task : Retrieve Special league
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination:

	Example: EXEC NAP_SMATurnover_SpecialLeagueSel
	
*/
BEGIN
	SET NOCOUNT ON
		
	SELECT l.displaymode, l.ProgramID
	FROM league l with (nolock) 
		INNER JOIN Dot_Admin_LeagueDisplayMode ldm with (nolock) ON ldm.LDisplayMode = l.[displaymode]
	WHERE l.ProgramID is not null and ldm.[Enabled] = 1 AND l.IsActive = 1
	group by l.displaymode, l.ProgramID 
	ORDER BY l.displaymode, l.ProgramID	
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_SpecialLeagueSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_SpecialLeagueSel] TO [vnteam]