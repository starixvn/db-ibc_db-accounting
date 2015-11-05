ALTER PROCEDURE Acc_CustomerTotalAmountSel
	@custid INT
	,@TotalAmt money = 0 OUTPUT
AS
/*
	Creator: Elodie
	Date: 20150612
	Task: Get total amount by custid
	Revisions:
		- 20150707@Jim: exclude Metric Gaming running ticket from bettrans (Feature #38789)
*/
BEGIN	
	select  @TotalAmt = sum(winlost-actual_stake+playercomm)
    from bettrans with (nolock)
    where custid = @CustID
		AND (
				(bettrans.bettype NOT IN (801,802,803,804,805,806)
				AND ruben =0)
				OR ruben <> 0
				)
				
    select @TotalAmt = isnull(@TotalAmt, 0)
	SELECT  @TotalAmt = @TotalAmt + ISNULL(SUM(-actual_stake), 0) FROM translog WITH(NOLOCK) WHERE custid=@custid AND statusID=0
END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerTotalAmountSel] TO [bodbadminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerTotalAmountSel] TO [bodbExtAccNet] AS [dbo]