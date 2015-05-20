
ALTER PROCEDURE [dbo].[DBA_DelTicket]
	@transid bigint
AS
/*
Created: 
DB: DB02.bodb02
Revisions:
	- 20101007@Henry: Change column transid from INT to BIGINT
	- 20111028@Lukas: update member's balance
	- 20120412@Sophia: Revise update member's balance
Param's Explanation:
*/

	Declare @custid int, @balance money
	select	@custid = custid ,
			@balance = winlost-actual_stake+playercomm
	from bettrans with (nolock) where transid = @transid
	
	-- update member's debit balance
	IF @balance > 0
		EXEC Dot_BalanceUpdDebit @custid = @custid, @balance = @balance
	
	delete bettrans where transid = @transid and bettype < 20000

	-- update member's credit balance
	IF @balance < 0
	BEGIN
		SET @balance = ABS(@balance)
		EXEC Dot_BalanceUpdCredit @custid = @custid, @balance = @balance
	END


GO
GRANT EXECUTE ON [dbo].[DBA_DelTicket] TO [vnteam]
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_DelTicket] TO [vnteam]