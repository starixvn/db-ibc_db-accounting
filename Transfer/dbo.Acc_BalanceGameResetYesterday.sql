ALTER PROCEDURE [dbo].[Acc_BalanceGameResetYesterday]
(
	@CustID		INT	,	
	@isResetYesterdayBalance	BIT OUTPUT,
	@YesterdayBalance	MONEY OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(1000) = '' OUTPUT	
)
AS
/*
	Create: 20121001@Dan
	Task: Reset yesterday balance for live casino
	DB: DBTXN/BODB02

	Revisions:		
		- 20131108@Elodie: Splitting bodb02 into CustDB (Call CustInfo by link database) 					       
*/
BEGIN
	SET NOCOUNT ON	
	SELECT @isResetYesterdayBalance = 0, @ErrCode = 0
	
	-- get current setting	
	DECLARE @isAutoResetLiveCasino BIT, @MaxWinLiveCasino SMALLMONEY
	SELECT @isAutoResetLiveCasino = ISNULL(isAutoResetLiveCasino,0),  
			@MaxWinLiveCasino = ISNULL(MaxWinLiveCasino,0)
	from CustDB.dbo.Custinfo WITH (NOLOCK)
	WHERE CustID=@CustID
	
	-- return if not weekly reset
	IF NOT(@isAutoResetLiveCasino = 0 AND @MaxWinLiveCasino>0)
		RETURN
		
	DECLARE @resetDate smalldatetime
	SELECT @resetDate = convert(nvarchar(10), current_timestamp,120)
	
	-- calculate yesterday balance to write log
	DECLARE @Credit MONEY, @Debit MONEY
	
	SELECT @Credit = SUM(Balance)
	FROM BalanceCreditGame credit WITH (NOLOCK) 
	WHERE custid=@custid and winlostdate<@resetDate
	
	SELECT @Debit = SUM(Balance)
	FROM BalanceDebitGame credit WITH (NOLOCK) 
	WHERE custid=@custid and winlostdate<@resetDate
	
	SET @YesterdayBalance = ISNULL(@Credit,0) -  ISNULL(@Debit,0)
	
	BEGIN TRY
		BEGIN TRANSACTION	
			--delete yesterday balance
			DELETE dbo.BalanceCreditGame with (ROWLOCK)
			WHERE custid=@CustID and winlostdate < @resetDate
			
			DELETE dbo.BalanceDebitGame with (ROWLOCK)
			WHERE custid=@CustID and winlostdate < @resetDate
			
			-- for testing:
			-- RAISERROR ('Reset yesterday balance live casino unsuccessful', 16, 1)
		COMMIT TRANSACTION
				
	END TRY
	BEGIN CATCH		
		ROLLBACK TRANSACTION
		SET @ErrCode = 101
	END CATCH

	SELECT @isResetYesterdayBalance = 1		
END



GO
GRANT EXECUTE ON [dbo].[Acc_BalanceGameResetYesterday] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_BalanceGameResetYesterday] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BalanceGameResetYesterday] TO [vnteam] AS [dbo]