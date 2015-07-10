USE [bodb02]
GO
ALTER PROCEDURE [dbo].[ExecRep_APL_01]
	@Winlostdate Datetime
AS
/*
	Created by:Sophia
	Date: 20130831
	Task: Called by Task_DailySummary_DB02_Delete
		  Delete Event by WinlostDate		
	DB: DB02.BODB02 / SVRPRO.ProdDB
	Revisions:
		- 20130809@viet: revise SP, then add to DB02_odds_info publication.
		- 20140911@Lukas: add table MatchMaxbet 
		- 20141006@Lukas: remove table SS_GameState
		- 20141024@Lukas: add table ResultDetail
*/ 
BEGIN

	SET NOCOUNT ON 
	IF @@SERVERNAME = 'DBCLS1\SDBPROD' RETURN --- ProdDB of Apollo
		

	IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'match' AND type = 'U') RETURN -- no match table, do nothing

	-- delete odds			
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'odds' AND type = 'U')
	BEGIN
		delete from odds
		where matchid in (select matchid from match where eventdate=@winlostdate)
	END

	-- delete bingoball
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'BingoBall' AND type = 'U')
	BEGIN
		delete from BingoBall
		where MatchID in (SELECT MatchID from Match where eventdate = @winlostdate)
	END

	--delete Dot_Admin_Assignment_Operator
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'Dot_Admin_Assignment_Operator' AND type = 'U')
	BEGIN
		delete from Dot_Admin_Assignment_Operator 
		where MatchID in (SELECT MatchID from Match where eventdate = @winlostdate)

		IF DATEPART(weekday, @winlostdate) = 2
		BEGIN
			delete from Dot_Admin_Assignment_Operator 
			where MatchID not in (SELECT MatchID from Match with(nolock))
		END
	END

	-- delete SS_GameState
	--IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'SS_GameState' AND type = 'U')
	--BEGIN
	--	delete from SS_GameState
	--	where matchid in (select matchid from match where eventdate=@winlostdate)
	--END

	-- delete MatchMaxbet
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'MatchMaxbet' AND type = 'U')
	BEGIN
		delete from MatchMaxbet WITH(ROWLOCK)
		where matchid in (select matchid from match WITH(NOLOCK) where eventdate=@winlostdate)
	END

	-- delete ResultDetail
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'ResultDetail' AND type = 'U')
	BEGIN
		delete from ResultDetail WITH(ROWLOCK)
		where matchid in (select matchid from match WITH(NOLOCK) where eventdate=@winlostdate)
	END

	-- delete match	
	delete from match 
	where eventdate=@winlostdate

	-- delete outright
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'outright' AND type = 'U')
	BEGIN
		delete from outright
		where eventdate = @winlostdate AND oddsstatus = 'Completed'
	END

		
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'VSOutright' AND type = 'U')
	BEGIN
		delete from VSOutright
		where eventdate = @winlostdate AND EventStatus = 'Completed'
	END

END

	 