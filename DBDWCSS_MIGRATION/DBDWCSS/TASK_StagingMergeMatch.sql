ALTER PROCEDURE [dbo].[TASK_StagingMergeMatch]
AS
/*   
 Task: merge match_staging into TPDB.match
 DB: DBDWCSS.bodb_staging
 Revisions:   
  - 20121016@viet: create SP   
*/  
SET NOCOUNT ON

	SET IDENTITY_INSERT TPDB.dbo.match ON
	MERGE TPDB.dbo.match as d
		USING dbo.match_staging s with(nolock) ON d.matchid = s.matchid
		WHEN MATCHED THEN 
			UPDATE SET 
				leagueid = s.leagueid
				,homeid = s.homeid
				,awayid = s.awayid
				,eventdate = s.eventdate
				,eventstatus = s.eventstatus
				,betstatus = s.betstatus
				,livehomescore = s.livehomescore
				,liveawayscore = s.liveawayscore
				,finalhomescore = s.finalhomescore
				,finalawayscore = s.finalawayscore
				,creator = s.creator
				,matchcode = s.matchcode
				,kickofftime = s.kickofftime
				,closedtime = s.closedtime
				,showtime = s.showtime
				,hthomescore = s.hthomescore
				,htawayscore = s.htawayscore
				,ruben = s.ruben
				,multiple = s.multiple
				,yenbet = s.yenbet
				,exrisk = s.exrisk
				,sporttype = s.sporttype				
				,homeid2 = s.homeid2
				,awayid2 = s.awayid2
				,DisplayMode = s.DisplayMode
				,LeaguePatternID = s.LeaguePatternID
				,HomeDisplayPatternID = s.HomeDisplayPatternID
				,AwayDisplayPatternID = s.AwayDisplayPatternID
				,IsNeutral = s.IsNeutral
				,InjuryTime = s.InjuryTime
				,GoalRecord = s.GoalRecord
				,ParentID = s.ParentID
				,ChildMatchType = s.ChildMatchType
				,GlobalShowTime = s.GlobalShowTime
				,HasLive = s.HasLive
				,changetime = s.changetime
				,settletime = s.settletime
		WHEN NOT MATCHED THEN 
		INSERT (
			matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, creator, 
			matchcode, kickofftime, closedtime, showtime, hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, homeid2, awayid2, 
			DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, InjuryTime, GoalRecord, ParentID, ChildMatchType, 
			GlobalShowTime, HasLive, changetime, settletime
			)
		VALUES (
			s.matchid, s.leagueid, s.homeid, s.awayid, s.eventdate, s.eventstatus, s.betstatus, s.livehomescore, s.liveawayscore, s.finalhomescore, 
			s.finalawayscore, s.creator, s.matchcode, s.kickofftime, s.closedtime, s.showtime, s.hthomescore, s.htawayscore, s.ruben, s.multiple, s.yenbet, 
			s.exrisk, s.sporttype, s.homeid2, s.awayid2, s.DisplayMode, s.LeaguePatternID, s.HomeDisplayPatternID, s.AwayDisplayPatternID, 
			s.IsNeutral, s.InjuryTime, s.GoalRecord, s.ParentID, s.ChildMatchType, s.GlobalShowTime, s.HasLive, s.changetime, s.settletime
			)
	;--end MERGE
	SET IDENTITY_INSERT TPDB.dbo.match OFF

	IF @@ERROR = 0 EXEC dbo.StagingConfirmCompleted @tablename = 'match'
SET NOCOUNT OFF

GO