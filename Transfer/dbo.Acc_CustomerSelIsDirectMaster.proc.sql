ALTER PROCEDURE [dbo].[Acc_CustomerSelIsDirectMaster]
	@custid		INT, 
	@IsDirect	BIT OUTPUT
AS

/*
	Created: Unknown
	Date: Unknown
	Task: Check if is direct master
	DB: DBCUST.CustDB

	Revisions:
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
	Parameters Explanation:	
*/

SET NOCOUNT ON

--Vinh@20080213: check direct master
IF EXISTS
(
	SELECT 1 FROM customer WITH (NOLOCK) 
	WHERE custid = @custid 
		AND roleid = 3 
		AND srecommend IN(SELECT custid FROM customer WITH (NOLOCK) WHERE roleid = 4 and custid < 100)
)
	SELECT @IsDirect = 1
ELSE
	SELECT @IsDirect = 0

	
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelIsDirectMaster] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelIsDirectMaster] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelIsDirectMaster] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelIsDirectMaster] TO [bodbDownlineNetView]

