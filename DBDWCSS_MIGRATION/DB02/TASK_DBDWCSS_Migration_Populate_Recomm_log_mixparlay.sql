ALTER PROCEDURE [dbo].[TASK_DBDWCSS_Migration_Populate_Recomm_log_mixparlay]	
AS
/*   
 Task : SSIS - Get RECOMM_LOG_MIXPARLAY data for exporting to DBDWCSS
 DB: DB02.bodb02
 Revisions:   
  - 20121016@viet: create SP   
*/  

SET NOCOUNT ON
	DECLARE @t bigint
	EXEC DBDWCSS.bodb_staging.dbo.StagingSelTimestamp @tablename = 'recomm_log_mixparlay' ,@tstamp = @t OUTPUT		

	IF @t > 100 SET @t = @t - 100 -- get additional '100 changes' to prevent previous locking
	Declare @old_tstamp binary(8), @new_tstamp binary(8)
	
	SELECT @new_tstamp = MAX(tstamp) FROM dbo.recomm_log_mixparlay with(nolock)
	SELECT @old_tstamp = cast(@t+1 as binary(8))
		,@t = CAST(@new_tstamp as bigint)
		
	SELECT 
		transid, recommdate, matchid, sporttype, bettype, oddsid, hdp1, hdp2, odds, betteam, stake, status, statusID, 
		tpositiontaking, livehomescore, liveawayscore, liveindicator, actualrate, refno, winlostdate
	FROM dbo.recomm_log_mixparlay with(rowlock)
	WHERE tstamp BETWEEN @old_tstamp AND @new_tstamp		
	
	EXEC DBDWCSS.bodb_staging.dbo.StagingUpdTimestamp @tablename = 'recomm_log_mixparlay', @tstamp = @t
SET NOCOUNT OFF

GO


