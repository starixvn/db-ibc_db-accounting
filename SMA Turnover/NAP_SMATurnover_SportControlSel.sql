ALTER PROCEDURE [dbo].[NAP_SMATurnover_SportControlSel]
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Retrieve configure TO information by sport
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		
	Example: EXEC NAP_SMATurnover_SportControlSel
	
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT s.SportType AS SportID, ISNULL(sc.Value,0) AS SportValue 
	FROM DownlineTo_SportControl sc WITH (NOLOCK)
		RIGHT JOIN bodb02.dbo.Sports s WITH (NOLOCK) ON s.SportType = sc.SportID
	WHERE s.SportType < 99
	ORDER BY s.SportType
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_SportControlSel] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_SportControlSel] TO [vnteam]