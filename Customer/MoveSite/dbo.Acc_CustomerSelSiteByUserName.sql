ALTER PROCEDURE [dbo].[Acc_CustomerSelSiteByUserName]
	@username VARCHAR(50) = ''
AS 
/*	Created by: [Khoa] 
	Date: 20100130
	Task: Get Site by username
	DB: DBCUST.CustDB

	Revisions:
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	SELECT site, roleid, custid 
	FROM customer WITH (NOLOCK) 
	WHERE username = @username
END


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelSiteByUserName] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelSiteByUserName] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelSiteByUserName] TO [vnteam]

