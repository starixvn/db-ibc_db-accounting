USE [bodb_Archive]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_Event]    Script Date: 03/31/2013 00:43:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_Event]
AS

Declare @winlostdate smalldatetime
SELECT TOP 1 @winlostdate = winlostdate
FROM dbo.Task_ArchiveDate
WHERE isDone = 0
ORDER BY 1 ASC

    

	INSERT INTO DBARCHIVE2.bodb_archive.dbo.Dot_Admin_Assignment_Operator_bk
		SELECT * FROM Dot_Admin_Assignment_Operator_bk with (nolock) WHERE matchid in (select matchid from match_bk with (nolock) where eventdate = @winlostdate)
	

	INSERT INTO DBARCHIVE2.bodb_archive.dbo.Dot_Admin_LiveLog
		SELECT * FROM Dot_Admin_LiveLog with (nolock) WHERE matchid in (select matchid from match_bk with (nolock) where eventdate = @winlostdate)
	
	---

	INSERT INTO DBARCHIVE2.bodb_archive.dbo.odds_bk
		SELECT * FROM odds_bk with (nolock) WHERE matchid in (select matchid from match_bk with (nolock) where eventdate = @winlostdate)

	INSERT INTO DBARCHIVE2.bodb_archive.dbo.match_bk
		SELECT
			matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore,
			finalhomescore, finalawayscore, creator, matchcode, kickofftime, closedtime, showtime,
			hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, tstamp,
			homeid2, awayid2, DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, GoalRecord
		FROM match_bk with (nolock) WHERE eventdate = @winlostdate

	INSERT INTO DBARCHIVE2.bodb_archive.dbo.bingoBall_bk
		([Matchid], [Seq], [Number], [UpdateTime])
	SELECT
		[Matchid], [Seq], [Number], [UpdateTime]
	FROM bingoBall_bk with (nolock)
	WHERE MatchID in (SELECT MatchID from match_bk with (nolock) where eventdate = @winlostdate)

	INSERT INTO DBARCHIVE2.bodb_archive.dbo.SS_GameState_bk
		(Matchid, ResultKey, ResultValue)
	SELECT
		Matchid, ResultKey, ResultValue
	FROM SS_GameState_bk with (nolock)
	WHERE MatchID in (SELECT MatchID from match_bk with (nolock) where eventdate = @winlostdate)
	
	INSERT INTO DBARCHIVE2.bodb_archive.dbo.outright_bk
		(orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, 
        DisplayMode, PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, 
		FOddsStatus, SCRTime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadHeat)
		SELECT
			orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, 
			DisplayMode, PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, FOddsStatus, SCRTime, LeaguePatternID, TeamPatternID, 
			ProgramDate, IsDeadHeat
		FROM outright_bk with (nolock) WHERE eventdate = @winlostdate

	


GO
GRANT VIEW DEFINITION ON [dbo].[Task_Archive_Event] TO [vnteam] AS [dbo]