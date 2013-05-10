ALTER PROCEDURE [dbo].[TASK_DBDWCSS_Migration_Populate_customer]		
AS
/*
 Task: get data for customer
 DB: DB054.bodb_staging
 Revisions:   
  - 20121016@viet: create SP   
*/  
SET NOCOUNT ON

	DECLARE @custid int
	EXEC DBDWCSS.bodb_staging.dbo.StagingSelMaxCustID @custid = @custid OUTPUT
	
	SELECT custid, creatdate, creator, username, currency, roleid, mrecommend, recommend, site, srecommend, username2
	FROM bodb02.dbo.Customer with(nolock)
	where custid > @custid	
SET NOCOUNT OFF
