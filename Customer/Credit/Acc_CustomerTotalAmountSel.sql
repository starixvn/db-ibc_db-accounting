ALTER PROCEDURE Acc_CustomerTotalAmountSel
	@custid INT
	,@TotalAmt money = 0 OUTPUT
AS
/*
	Creator: Elodie
	Date: 20150612
	Task: Get total amount by custid
*/
BEGIN	
	select  @TotalAmt = sum(winlost-actual_stake+playercomm)
    from bettrans with (nolock)
    where custid = @CustID
    
    select @TotalAmt = isnull(@TotalAmt, 0)
	SELECT  @TotalAmt = @TotalAmt + ISNULL(SUM(-actual_stake), 0) FROM translog WITH(NOLOCK) WHERE custid=@custid AND statusID=0
END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerTotalAmountSel] TO [bodbadminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerTotalAmountSel] TO [bodbExtAccNet] AS [dbo]