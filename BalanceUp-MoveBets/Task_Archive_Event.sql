ALTER PROCEDURE [dbo].[Task_Archive_Event]
	@winlostdate datetime
AS
/*
	DB: DB02.bodb02
	Revisions:    
		- 20101229@Viet: Add moving for data from BingoBall table
    
 */

	INSERT INTO DB06.bodb_archive.dbo.odds_bk
		SELECT * FROM odds14 WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)

	INSERT INTO DB06.bodb_archive.dbo.match_bk
		SELECT
			matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore,
			finalhomescore, finalawayscore, creator, matchcode, kickofftime, closedtime, showtime,
			hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, tstamp,
			homeid2, awayid2, DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, GoalRecord
		FROM match14 WHERE eventdate = @winlostdate

	INSERT INTO DB06.bodb_archive.dbo.bingoBall_bk
		([Matchid], [Seq], [Number], [UpdateTime])
	SELECT
		[Matchid], [Seq], [Number], [UpdateTime]
	FROM BingoBall14
	WHERE MatchID in (SELECT MatchID from Match14 where eventdate = @winlostdate)

	INSERT INTO DB06.bodb_archive.dbo.outright_bk
		(orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, 
        DisplayMode, PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, 
		FOddsStatus, SCRTime)
		SELECT orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, 
                      DisplayMode, PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, FOddsStatus, SCRTime
		FROM outright14 WHERE eventdate = @winlostdate

	DELETE FROM odds14  WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)
	DELETE FROM BingoBall14 WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)
	DELETE FROM match14 WHERE eventdate = @winlostdate
	DELETE FROM outright14 WHERE eventdate = @winlostdate

	--EXEC ExecRep_02 @winlostdate

	DELETE FROM bettranssum WHERE winlostdate = @winlostdate



GO
GRANT VIEW DEFINITION ON [dbo].[Task_Archive_Event] TO [vnteam]