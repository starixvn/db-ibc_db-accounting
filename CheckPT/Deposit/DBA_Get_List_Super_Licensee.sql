USE CheckResultDB
GO 

ALTER PROCEDURE [dbo].DBA_Get_List_Super_Licensee
(
	@Site varchar(100)=NULL,
	@srecommend VARCHAR(1000)=NULL OUTPUT
)
AS
/*
	Created: 20131015@Tom.Vo	
	Task :  Retrieve list Super licensee's by site
	DB: DB054.CheckResultDB
	Original:

	Revisions:
		
	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS (Select TOP 1 1  From CheckCustDB.dbo.[Site] WITH(NOLOCK) WHERE [Site] = @Site)
		BEGIN
			RETURN
		END

	SELECT @srecommend=''

	SELECT @srecommend = COALESCE(@srecommend + ',', '') + convert(NVARCHAR(50),ISNULL(tbl.Custid,'')) 
	FROM CheckCustDB.dbo.Dep_CustSuper tbl WITH(NOLOCK)
		WHERE Site = @Site AND Currency NOT IN (20,27,28)

END
 