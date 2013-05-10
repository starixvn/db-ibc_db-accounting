

ALTER PROCEDURE [dbo].[Acc_Get_LiveCasinoGameResult]
	@matchid int
AS

/*
	Created by: 20120116@Lukas
	Task: get gamehand to settle
	DB: DB02.BODB02 
	
	Revisions:
	- 20120911@Sophia: Change server name DB02 instead of DBTRANS
		
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
GRANT VIEW DEFINITION ON [Acc_Get_LiveCasinoGameResult] TO vnteam
GO
GRANT EXECUTE ON [Acc_Get_LiveCasinoGameResult] TO bodbAdminNet
