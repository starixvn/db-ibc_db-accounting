ALTER PROCEDURE [dbo].[TASK_DBDWCSS_Migration_Populate_Match]	
AS
/*   
 Task : SSIS - Get match data for exporting to DBDWCSS
 DB: DB02.bodb02
 Revisions:   
  - 20121016@viet: create SP   
*/  

SET NOCOUNT ON
	DECLARE @t bigint
	EXEC DBDWCSS.bodb_staging.dbo.StagingSelTimestamp @tablename = 'match' ,@tstamp = @t OUTPUT		

	IF @t > 100 SET @t = @t - 100 -- get additional '100 changes' to prevent previous locking
	Declare @old_tstamp binary(8), @new_tstamp binary(8)
	SELECT @new_tstamp = MAX(tstamp) FROM dbo.match with(nolock)
	SELECT @old_tstamp = cast(@t+1 as binary(8))
		,@t = CAST(@new_tstamp as bigint)
		
	SELECT matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, creator, 
		matchcode, kickofftime, closedtime, showtime, hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, homeid2, awayid2, 
		DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, InjuryTime, GoalRecord, ParentID, ChildMatchType, 
		GlobalShowTime, HasLive, changetime, settletime
	FROM dbo.match with(rowlock)
	WHERE tstamp BETWEEN @old_tstamp AND @new_tstamp		
	
	EXEC DBDWCSS.bodb_staging.dbo.StagingUpdTimestamp @tablename = 'match', @tstamp = @t
SET NOCOUNT OFF