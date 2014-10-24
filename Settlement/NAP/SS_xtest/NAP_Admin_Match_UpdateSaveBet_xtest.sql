ALTER PROCEDURE [dbo].[NAP_Admin_Match_UpdateSaveBet_xtest]
	@action varchar(20),
	@matchid INT,
	@SelectedSet VARCHAR(50)=NULL 
AS
/*
	Created: Kathy
	Date 20140213
	Task : Update SaveBet info (when run settlement)
	DB: DB06.bodb02
	Original: Admin_Match_UpdateSaveBet

	Revisions:
		- 20141022@Jamie: Sporting Solution for Tennis [Redmine:#23034]
*/

SET NOCOUNT ON
IF @action = 'UNDO' AND (@SelectedSet IS NULL OR @SelectedSet LIKE '%6%' )
BEGIN
	-- RESET 'SaveBet' of DB06
	DELETE FROM Save_Jobs WHERE matchid = @matchid
	UPDATE Save_ListMatch SET IsGameFinish = 1 WHERE matchid = @matchid

	INSERT INTO Save_Jobs (matchid, liveindicator, savetype, bettype, typename)
	SELECT @matchid, 1, 'DEL', 0, 0
END
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Match_UpdateSaveBet_xtest] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Match_UpdateSaveBet_xtest] TO [vnteam] AS [dbo]