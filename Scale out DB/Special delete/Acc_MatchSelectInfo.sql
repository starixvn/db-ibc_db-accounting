


CREATE PROCEDURE Acc_MatchSelectInfo_xtest
(
	@matchid	INT = NULL,
	@matchCode	NVARCHAR(50) = NULL
)
AS
/*
	Created: 20120921@Lukas
	Task: Get match info
	DB: DB02.bodb02
	
	Revisions:
	
*/
BEGIN
	SET NOCOUNT ON 
	
	SELECT	matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore
			,finalhomescore, finalawayscore, creator, matchcode, kickofftime, closedtime, showtime
			,hthomescore, htawayscore, ruben, multiple, sporttype
	FROM match WITH(NOLOCK)
	WHERE matchid = COALESCE(@matchid,matchid) AND matchcode = COALESCE(@matchCode,matchcode)
	
END
GO
GRANT EXECUTE ON Acc_MatchSelectInfo_xtest TO bodbAdminNet

