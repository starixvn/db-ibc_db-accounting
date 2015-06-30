ALTER PROCEDURE [dbo].[StagingSelMaxCustID]	
	@custid int OUTPUT
AS
/*   
 Task: get max custid value
 DB: DBDWCSS.bodb_staging
 Revisions:   
  - 20121016@viet: create SP   
*/  
SET NOCOUNT ON

	SELECT @custid = isnull(MAX(custid),0) 
	FROM bodb_Licensee.dbo.customer WITH(NOLOCK)
	
SET NOCOUNT OFF


