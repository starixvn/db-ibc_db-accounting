ALTER PROCEDURE  [dbo].[Acc_CustomerSelVirtualMultiplier] 
	@CustID int
AS
	SET NOCOUNT ON
	declare @ActualRate float
	
	select @ActualRate = actualrate
	from exchange with (nolock)
		inner join customer on exchange.exchangeid = customer.currency
	where custid = @CustID
		
	
	Select @ActualRate as ActualRate, 
			virtualmultiplier-1 as VirtualMultiplier, 
			-0.8 as Min_VirtualMultiplier,            ---- 0.2 - 1 
			 0.6 as Max_VirtualMultiplier             ---- 1.6 - 1 
	from CustInfo with (NOLOCK) where CustID = @CustID

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelVirtualMultiplier] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelVirtualMultiplier] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelVirtualMultiplier] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelVirtualMultiplier] TO [bodbDownlineNetView]
