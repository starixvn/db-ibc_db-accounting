ALTER PROCEDURE [dbo].[StagingSelTimestamp]	
	@tablename varchar(30),
	@tstamp bigint OUTPUT
AS
/*   
 Task: get previous timestamp value
 DB: DBDWCSS.bodb_staging
 Revisions:   
  - 20121001@viet: create SP   
*/  
SET NOCOUNT ON

	SELECT @tstamp = isnull(tstamp, 0)
	FROM dbo.stateSetting with(rowlock)
	WHERE tablename = @tablename
		AND iscompleted = 1
	
SET NOCOUNT OFF