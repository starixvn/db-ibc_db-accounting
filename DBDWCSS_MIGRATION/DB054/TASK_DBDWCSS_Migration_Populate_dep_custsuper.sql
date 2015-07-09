CREATE PROCEDURE [dbo].[TASK_DBDWCSS_Migration_Populate_dep_custsuper]		
AS
/*
 Task: get data for dep_custsuper
 DB: DB054.bodb_staging
 Revisions:   
  - 20121016@viet: create SP   
*/  
SET NOCOUNT ON	
	
	SELECT custid, currency, username, site
	FROM bodb02.dbo.dep_custsuper with(rowlock)	
SET NOCOUNT OFF
