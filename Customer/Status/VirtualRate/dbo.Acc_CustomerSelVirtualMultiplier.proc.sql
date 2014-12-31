ALTER PROCEDURE  [dbo].[Acc_CustomerSelVirtualMultiplier] 
	@CustID int
AS
	/*
		Created: 
		Date: 
		DB: DBAGE/bodb02
		Task: Get virtual rate settings of customers
		
		Revisions:
			- 20141226@Johnson: Separate virtual rate by sporttype, bettype [Redmine: #25840]				
		Parameter's Explanation:
	*/
BEGIN
	SET NOCOUNT ON
	declare @ActualRate float
	
	select @ActualRate = actualrate
	from exchange with (nolock)
		inner join customer on exchange.exchangeid = customer.currency
	where custid = @CustID
		
	
	Select @ActualRate as ActualRate, 			
			virtualmultiplier as DisableVirtualrate, 
			-0.8 as Min_VirtualMultiplier,            ---- 0.2 - 1 
			 0.6 as Max_VirtualMultiplier             ---- 1.6 - 1 
	from CustInfo with (NOLOCK) where CustID = @CustID
	
	SELECT * 
	FROM CustVirtualRate WITH(NOLOCK)
	WHERE custid = @Custid
	
END

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelVirtualMultiplier] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelVirtualMultiplier] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelVirtualMultiplier] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelVirtualMultiplier] TO [bodbDownlineNetView]
