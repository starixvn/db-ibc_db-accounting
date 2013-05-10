ALTER PROCEDURE [dbo].[NAP_Acc_SelSports]
	@isGetAll BIT = 0
AS
/*
	Created by: 20120924@Dan
	Task: Get the list of sports for Settlement function
	DB:DB02.BODB02
	Original: Acc_SelSports
	
	Revisions:
		@isGetAll: 1 - get all sports for view result, 0- get only sportbook + number game for calculating settlement
		
*/

BEGIN
	SET NOCOUNT ON 
	
	SELECT * 
	FROM	Sports WITH (NOLOCK)
	WHERE	sporttype not in(
				201, --Financial 				
				251,252,253,  --Casino, Bingo, Game 
				162, --live casino		
				161 --number games
			) 
			AND
			(@isGetAll=1 or sporttype not in(				
				151,152,153,  --Racing								
				180, 181, 182, 183, 184, 185, 186 --virtual sports
			))
END	

GO	
GRANT EXECUTE ON [dbo].NAP_Acc_SelSports TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].NAP_Acc_SelSports TO [VNTeam]