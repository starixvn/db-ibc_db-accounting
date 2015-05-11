ALTER PROCEDURE [dbo].[TASK_DBDWCSS_Migration_GetBettrans_stagingData]	
AS
/*   
 Task : SSIS - Get bettrans data to transfer to bettrans_staging
 DB: DBTP.TPDB
 Revisions:   
  - 20121010@viet: create SP   
*/  
SET NOCOUNT ON
SET DEADLOCK_PRIORITY LOW		
	
	DECLARE @t bigint
	EXEC DBDWCSS.bodb_staging.dbo.StagingSelTimestamp @tablename = 'bettrans' ,@tstamp = @t OUTPUT		

	IF @t > 100 SET @t = @t - 100 -- get 30 old rows to prevent previous locking
	
	Declare @old_tstamp binary(8)		
	SELECT @old_tstamp = cast(@t+1 as binary(8))		
		
	IF @t = 0 -- first time copy or renew all data
	BEGIN			
		SELECT * FROM dbo.bettrans with (rowlock)		
	END
	ELSE
	BEGIN
		SELECT *
		FROM dbo.bettrans with(rowlock, index=IX_tstamp)
		WHERE tstamp >= @old_tstamp
	END
SET NOCOUNT OFF	
