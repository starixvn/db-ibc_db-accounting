USE [bodb_Archive]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_Event_Manually]    Script Date: 03/30/2013 23:49:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_Event_Manually]
	@winlostdate smalldatetime
AS

	INSERT INTO DBARCHIVE2.bodb_archive.dbo.odds_bk
		SELECT * FROM odds_bk WHERE matchid in (select matchid from match_bk with (nolock) where eventdate = @winlostdate)

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
	FROM SS_GameState_bk
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

	


