 CREATE PROCEDURE [NAP_Admin_Match_UpdateSaveBet]
	@action varchar(20),
	@matchid INT
AS
/*
	Created: Kathy
	Date 20140213
	Task : Update SaveBet info (when run settlement)
	DB: DB06.bodb02
	Original: Admin_Match_UpdateSaveBet

	Revisions:
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

GRANT EXECUTE ON [NAP_Admin_Match_UpdateSaveBet] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Match_UpdateSaveBet] TO [vnteam] AS [dbo]
GO


