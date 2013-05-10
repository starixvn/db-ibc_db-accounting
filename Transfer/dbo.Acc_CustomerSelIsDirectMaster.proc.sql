ALTER PROCEDURE [dbo].[Acc_CustomerSelIsDirectMaster]
	@custid int, 
	@IsDirect bit output
AS
/*
Created: 
Task : 
DB: DB053.bodb02
Revisions:
	--Vinh@20080213: check direct master
	--Henry@20100805: grant permission to bodbExtAccNet
						
Parameters Explanation:
	
*/
	
	if exists
	(
		select 1 from customer with (nolock) 
		where custid = @custid 
			and roleid = 3 
			and srecommend IN(select custid from customer with (nolock) where roleid = 4 and custid < 100)
	)
		select @IsDirect = 1
	else
		select @IsDirect = 0
	
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelIsDirectMaster] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelIsDirectMaster] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelIsDirectMaster] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelIsDirectMaster] TO [bodbDownlineNetView]

