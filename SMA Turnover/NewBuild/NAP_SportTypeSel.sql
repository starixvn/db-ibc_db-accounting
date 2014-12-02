CREATE PROCEDURE [dbo].[NAP_SportTypeSel]
	@Mode TINYINT = 0
AS
/*
	Created: Elodie
	Date: 20130515
	Task : Retrieve Sport type
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: @Mode  = 0: Sport of sportbook
									 = 1: All sports
	Example: EXEC Acc_SportTypeSel @Mode = 1									 
	
*/
SET NOCOUNT ON
SELECT DISTINCT sporttype, sportname 
FROM sports s WITH(NOLOCK) 
WHERE 1 = CASE  WHEN @Mode = 0 AND SportType <= 99 THEN 1
				WHEN @Mode = 1 THEN 1
				ELSE 0 END			
ORDER BY sporttype

GO
GRANT EXECUTE ON [dbo].[Acc_SportTypeSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SportTypeSel] TO [vnteam]

