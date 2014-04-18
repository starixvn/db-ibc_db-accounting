CREATE PROCEDURE [NAP_SelSports]
	@isGetAll BIT = 0
AS
/*
	Created by: 20131223@Kathy
	Task: Get the list of sports for Settlement function
	DB:DB02.BODB02
	Original: Acc_SelSports
	
	Revisions:

	Param's Explanation:
		@isGetAll: 1 - get all sports for view result, 0- get only sportbook
		
*/

BEGIN
	SET NOCOUNT ON 
	
	SELECT * 
	FROM	Sports WITH (NOLOCK)
	WHERE	sporttype not in(
				201, --Financial 				
				251,252,253,  --Casino, Bingo, Game 
				162, --live casino	
				161, -- Number game
				180, 181, 182, 183, 184, 185, 186 --virtual sports
			) 
			AND
			(@isGetAll=1 or sporttype not in(				
				151,152,153  --Racing												
			))
END	


GO

GRANT EXECUTE ON [NAP_SelSports] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_SelSports] TO [vnteam] AS [dbo]
GO


