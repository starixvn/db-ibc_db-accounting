ALTER PROCEDURE [dbo].[Acc_SelSports]
AS
/*
	Created by:[]
	Task: Get the list of sports for Settlement function
	DB:DB02.BODB02
	
	Revisions:
		- 20110503@Jamie: Exclude the sports: Greyhound & Hardness , Games
		- 20120208@Lukas: Exclude Live Casino
		
*/

BEGIN
	SET NOCOUNT ON 
	
	SELECT * 
	FROM	Sports WITH (NOLOCK)
	WHERE	sporttype not in(
				201, --Financial 
				151,152,153,  --Racing
				251,253,  --Casino & Game 
				162 --live casino
			)
END	

GO	
GRANT EXECUTE ON [dbo].Acc_SelSports TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].Acc_SelSports TO [VNTeam]