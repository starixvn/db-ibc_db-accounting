ALTER PROCEDURE [dbo].[Acc_LiveCS_SelGameByID]
	@matchid int
AS

/*
	Created by: 20120116@Lukas
	Task: get gamehand info
	DB: DBTRANS.BODB02 
	
	Revisions:

*/
BEGIN

	SET NOCOUNT ON 

	SELECT 
		matchid
		,matchcode
		,eventdate
		, kickofftime
		,showtime AS GameEvent
		,finalhomescore
		,finalawayscore
		,betstatus
		,eventstatus
		,leagueid
		,CASE WHEN eventstatus = 'completed' THEN 1 ELSE 0 END IsSettled
		, 'Full Time' AS FTStatus
	FROM match WITH(NOLOCK)
	WHERE sporttype = 162 
		AND matchid = @matchid
END

GO
GRANT VIEW DEFINITION ON [Acc_LiveCS_SelGameByID] TO vnteam
GO
GRANT EXECUTE ON [Acc_LiveCS_SelGameByID] TO bodbAdminNet