ALTER PROCEDURE [dbo].[TASK_DBDWCSS_Migration_Populate_Outright]	
AS
/*   
 Task : SSIS - Get OUTRIGHT data for exporting to DBDWCSS
 DB: DB02.bodb02
 Revisions:   
  - 20121016@viet: create SP   
*/  

SET NOCOUNT ON
	DECLARE @t bigint
	EXEC DBDWCSS.bodb_staging.dbo.StagingSelTimestamp @tablename = 'outright' ,@tstamp = @t OUTPUT		

	IF @t > 100 SET @t = @t - 100 -- get additional '100 changes' to prevent previous locking
	Declare @old_tstamp binary(8), @new_tstamp binary(8)
	SELECT @new_tstamp = MAX(tstamp) FROM dbo.outright with(nolock)
	SELECT @old_tstamp = cast(@t+1 as binary(8))
		,@t = CAST(@new_tstamp as bigint)
		
	SELECT 
		orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, 
		DisplayMode, ProgramID, HorseJockey, HorseDraw, HorseWgt, PlaceOdds, Placing, IsFavor, IsSCR, Colours, HorseTrainer, FOddsStatus, SCRTime, 
		changetime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadheat, StdDelBetCheck
	FROM dbo.outright with(rowlock)
	WHERE tstamp BETWEEN @old_tstamp AND @new_tstamp		
	
	EXEC DBDWCSS.bodb_staging.dbo.StagingUpdTimestamp @tablename = 'outright', @tstamp = @t
SET NOCOUNT OFF