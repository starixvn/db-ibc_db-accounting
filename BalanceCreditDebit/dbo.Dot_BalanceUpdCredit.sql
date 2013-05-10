set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[Dot_BalanceUpdCredit]
	@custid int,
	@balance money,
	@stoptest bit = 0
AS

-- 20111220@Vivi: place bet SPs will input @stoptest=1, if want stop test then un-comment
-- IF @stoptest=1 return

Declare @Retry int, @Success bit
SET @Retry = 0

TryAgain:

BEGIN TRY
	SET @Retry = @Retry + 1
	SET @Success = 1
	BEGIN TRANSACTION
	
		UPDATE dbo.BalanceCredit WITH (rowlock, updlock)
		SET Balance = Balance + @balance
		WHERE custid = @custid
		
		IF @@ROWCOUNT = 0 INSERT INTO dbo.BalanceCredit (custid, balance) VALUES (@custid, @balance)
		
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SET @Success = 0
	ROLLBACK TRANSACTION
END CATCH

IF @Success = 0 AND @Retry < 3 GOTO TryAgain


GO 
GRANT VIEW DEFINITION ON [dbo].[Dot_BalanceUpdDebit] TO [VNTeam]

