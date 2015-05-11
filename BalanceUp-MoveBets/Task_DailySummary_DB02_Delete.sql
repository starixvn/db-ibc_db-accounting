ALTER PROCEDURE [dbo].[Task_DailySummary_DB02_Delete]
	@winlostdate datetime
AS
/*
Created: 
Task :	call by TransDB : Task_DailySummary
DB: DBPRO/bodb02
Original:  	
Revisions:
	-- 20110802@Sylvia: Delete Dot_Admin_Assignment_Operator to archive
	-- 20121031@Sylvia: Delete SS_GameState
	-- 20130412@Elodie: Delete VSOutright

*/
BEGIN
	delete from odds
	where matchid in (select matchid from match where eventdate=@winlostdate)

	delete from BingoBall
	where MatchID in (SELECT MatchID from Match where eventdate = @winlostdate)

	delete from Dot_Admin_Assignment_Operator 
	where MatchID in (SELECT MatchID from Match where eventdate = @winlostdate)

	IF DATEPART(weekday, @winlostdate) = 2
	BEGIN
		delete from Dot_Admin_Assignment_Operator 
		where MatchID not in (SELECT MatchID from Match nolock)
	END

	delete from SS_GameState
	where matchid in (select matchid from match where eventdate=@winlostdate)
	
	delete from match 
	where eventdate=@winlostdate

	delete from outright
	where eventdate = @winlostdate AND oddsstatus = 'Completed'
	
	delete from VSOutright
	where eventdate = @winlostdate AND EventStatus = 'Completed'
	
END
