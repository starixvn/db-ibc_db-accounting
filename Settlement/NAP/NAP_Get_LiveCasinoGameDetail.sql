ALTER PROCEDURE [dbo].[NAP_Get_LiveCasinoGameDetail]
	@matchid int
AS

/*
	Created by: 20121205@Dan
	Task: get gamehand to settle
	DB: DB02.BODB02 
	Orifgial SP: Acc_Get_LiveCasinoGameResult
	
	Revisions:
	
*/
BEGIN

	SET NOCOUNT ON 

	SELECT 
		matchid
		,matchcode
		,eventdate
		,kickofftime
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
GRANT VIEW DEFINITION ON [NAP_Get_LiveCasinoGameDetail] TO vnteam
GO
GRANT EXECUTE ON [NAP_Get_LiveCasinoGameDetail] TO bodbAdminNet
