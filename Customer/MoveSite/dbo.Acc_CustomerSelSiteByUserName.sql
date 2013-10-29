ALTER PROCEDURE [dbo].[Acc_CustomerSelSiteByUserName]
	@username varchar(50) = ''
AS 
/*	Created by: [Khoa] 
	Date: 20100130
	Task: Get Site, Upline id by username
	DB: DB052.bodb02

	Revisions:		
	20100312@huynguyen get recommend, mrecommend, srecommend 
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON
	SELECT site, roleid, custid, recommend, mrecommend, srecommend  FROM customer (NOLOCK) WHERE username = @username
END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelSiteByUserName] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelSiteByUserName] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelSiteByUserName] TO [vnteam]

