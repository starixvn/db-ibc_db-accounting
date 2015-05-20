ALTER PROCEDURE [dbo].[StagingConfirmCompleted]	
	@tablename varchar(30)
AS
/*   
 Task: confirm completed transfering data
 DB: DBDWCSS.bodb_staging
 Revisions:   
  - 20121001@viet: create SP   
*/  
SET NOCOUNT ON
		
	UPDATE d
	SET tstamp = s.tstamp
		,lastchange	= CURRENT_TIMESTAMP
	FROM stateSetting d with(rowlock, updlock)
		inner join stateSetting s with(nolock) on s.tablename = d.tablename
	WHERE d.iscompleted = 1
		and s.iscompleted = 0
		and d.tablename = @tablename
			
SET NOCOUNT OFF