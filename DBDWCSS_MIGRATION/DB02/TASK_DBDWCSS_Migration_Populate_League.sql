ALTER PROCEDURE [dbo].[TASK_DBDWCSS_Migration_Populate_League]	
AS
/*   
 Task : SSIS - Get LEAGUE data for exporting to DBDWCSS
 DB: DB02.bodb02
 Revisions:   
  - 20121016@viet: create SP   
*/  

SET NOCOUNT ON
	DECLARE @t bigint
	EXEC DBDWCSS.bodb_staging.dbo.StagingSelTimestamp @tablename = 'league' ,@tstamp = @t OUTPUT		

	IF @t > 100 SET @t = @t - 100 -- get additional '100 changes' to prevent previous locking
	Declare @old_tstamp binary(8), @new_tstamp binary(8)
	SELECT @new_tstamp = MAX(tstamp) FROM dbo.league with(nolock)
	SELECT @old_tstamp = cast(@t+1 as binary(8))
		,@t = CAST(@new_tstamp as bigint)
		
	SELECT 
		leagueid, leaguename, maxstake, minstake, maxstakeou, maxstakeoe, leaguenamec, leaguenametc, creator, lcolor, hdp_min, hdp_max, 
		hdp_risk, hdp_range, hdp_allowance, hdp_gapodds, hdp_gapoddsr, ou_min, ou_max, ou_risk, ou_range, ou_allowance, ou_gapodds, ou_gapoddsr, 
		oe_min, oe_max, oe_risk, oe_range, oe_gapodds, cs_min, cs_max, cs_risk, cs_range, cs_gapodds, b1x2_min, b1x2_max, b1x2_risk, b1x2_range, 
		b1x2_gapodds, tg_min, tg_max, tg_risk, tg_range, tg_gapodds, ht_min, ht_max, ht_risk, ht_range, ht_allowance, ht_gapodds, ht_gapoddsr, ht1x2_min, 
		ht1x2_max, ht1x2_risk, ht1x2_range, ht1x2_gapodds, leaguenamec_uni, leaguenamej, sporttype, createdate, leaguenamecn, oe_gapoddsr, 
		DisplayMode, isTest, leaguenameth, ProgramID, TrackCondition, IsActive, leaguenameko, TrackConditionCh, TrackConditionCs, leaguenameES, 
		CountryCode, leaguenameVN, GameSession, SessionTime, OverTime, leaguenameEL, OverTimeSession, IsCountDownTimer
	FROM dbo.league with(rowlock)
	WHERE tstamp BETWEEN @old_tstamp AND @new_tstamp		
	
	EXEC DBDWCSS.bodb_staging.dbo.StagingUpdTimestamp @tablename = 'league', @tstamp = @t
SET NOCOUNT OFF