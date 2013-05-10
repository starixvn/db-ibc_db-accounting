 ALTER PROCEDURE [dbo].[Admin_Match_UpdateSaveBet]
	@action varchar(20),
	@matchid INT
AS
/*
	Created: 20110620@Thien
	Task : Update SaveBet info (when run settlement)
	DB: DBACC/bodb02
	Original:

	Revisions:
		- 20130222@Elodie: Remove link server DB06.bodb02
*/

SET NOCOUNT ON
IF @action = 'UNDO'
BEGIN
	-- RESET 'SaveBet' of DB06
	DELETE FROM Save_Jobs WHERE matchid = @matchid
	UPDATE Save_ListMatch SET IsGameFinish = 1 WHERE matchid = @matchid

	INSERT INTO Save_Jobs (matchid, liveindicator, savetype, bettype, typename)
	SELECT @matchid, 1, 'DEL', 0, 0
END


GO
GRANT EXECUTE ON [dbo].[Admin_Match_UpdateSaveBet] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Match_UpdateSaveBet] TO [vnteam]