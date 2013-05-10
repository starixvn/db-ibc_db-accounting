 
ALTER PROCEDURE [dbo].[DBA_DeleteBet_Parlay_Recover]
	@transid bigint	

AS
/*
	Create:
	Task:
	Original:
	
	Revisions:
		- 20111028@Lukas: update member balance
		- 20120412@Sophia: Revise update member balance 
*/
SET NOCOUNT ON

Declare @LogData nvarchar(200), @custid int, @statusID int, @balance_bf money, @balance_at money, @balance money

---Get balance before recover
select @custid = custid, @statusID = statusID,
	   @balance_bf = winlost - actual_stake + playercomm
from bettrans (nolock)
where transid = @transid

If @statusID = 0
BEGIN
	PRINT  'STILL RUNNING' + cast(@transid as varchar(20))	
	return
END

---Get balance after recover
select  @balance_at = -actual_stake
from bettrans (nolock)
where transid = @transid

---get balance
SELECT @balance= @balance_bf - @balance_at

--update debit balance 
IF @balance > 0
	EXEC Dot_BalanceUpdDebit @custid = @custid, @balance = @balance

update  
	bettrans with (ROWLOCK, UPDLOCK)
SET winlost=0,ruben=0,statuswinlost=0, status = 'running', statusID=0 , creator = custid,
	awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0
where transid = @transid

--update credit balance 
IF @balance < 0
BEGIN
	SET @balance = ABS(@balance)
	EXEC Dot_BalanceUpdCredit @custid = @custid, @balance = @balance
END
