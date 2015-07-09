ALTER PROCEDURE [dbo].[StagingUpdTimestamp]	
	@tablename varchar(30),
	@tstamp bigint
AS
/*   
 Task: update new timestamp value
 DB: DBDWCSS.bodb_staging
 Revisions:   
  - 20121001@viet: create SP   
*/  
SET NOCOUNT ON

	UPDATE dbo.stateSetting with(rowlock, updlock)
	SET tstamp = @tstamp
		,lastchange = CURRENT_TIMESTAMP
	WHERE tablename = @tablename
		and iscompleted = 0
			
SET NOCOUNT OFF