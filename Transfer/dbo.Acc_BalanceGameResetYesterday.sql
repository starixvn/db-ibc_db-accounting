ALTER PROCEDURE dbo.Acc_BalanceGameResetYesterday (@CustID INT
	, @IsResetYesterdayBalance BIT OUTPUT
	, @YesterdayBalance	MONEY OUTPUT
	, @ErrCode INT = 0 OUTPUT
	, @ErrMsg NVARCHAR(1000) = '' OUTPUT	
)
AS
/*
	Create: 20121001@Dan
	Task: Reset yesterday balance for live casino
	DB: DBTXN/BODB02

	Revisions:		
		- 20131108@Elodie: Splitting bodb02 into CustDB (Call CustInfo by link database) 					       
		- 20150723@Patrick: Support Gold deluxe
		- 20151223@Patrick: Add Max/Loss limit for RnG Casino [Redmine: #49528]
		- 20160201@Elodie: Apply new rule for auto reset of OneRNG 
		- 20160204@Elodie: Add WinLossLimit setting type for DCS [Redmine: #49606]
*/
BEGIN
	SET NOCOUNT ON	
	SELECT @IsResetYesterdayBalance = 0, @ErrCode = 0
	DECLARE @BetTypeIds TABLE(BetType SMALLINT)

	--for LiveCS
	INSERT INTO @BetTypeIds(BetType)
	SELECT 1101 AS BetType
	FROM CustDB.dbo.Custinfo WITH (NOLOCK)
	WHERE CustID = @CustID AND ISNULL(isAutoResetLiveCasino, 0) = 0 AND ISNULL(MaxWinLiveCasino, 0) > 0

	--for GD & RnG CS
	INSERT INTO @BetTypeIds(BetType)
	SELECT bettype
	FROM DBCUST.CustDB.dbo.CustWinLimit WITH (NOLOCK)
	WHERE CustId = @CustID AND IsAutoReset = 0 AND ((BetType = 1701 AND MaxWinlimit > 0) OR BetType = 2101)

	--for DCS Product
	INSERT INTO @BetTypeIds(BetType)
	SELECT bettype
	FROM DBCUST.CustDB.dbo.CustWinLossLimit_Member WITH (NOLOCK)
	WHERE CustId = @CustID AND IsAutoReset = 0
		
	IF NOT EXISTS (SELECT TOP 1 1 FROM @BetTypeIds)
		RETURN

	DECLARE @resetDate SMALLDATETIME, @Credit MONEY, @Debit MONEY
	SELECT @resetDate = CONVERT(NVARCHAR(10), CURRENT_TIMESTAMP, 120)
	
	SELECT @Credit = SUM(Balance)
	FROM BalanceCreditGame credit WITH (NOLOCK) 
	WHERE CustId = @custid 
		AND winlostdate < @resetDate
		AND bettype IN (SELECT bt.BetType FROM @BetTypeIds bt)
	
	SELECT @Debit = SUM(Balance)
	FROM BalanceDebitGame credit WITH (NOLOCK) 
	WHERE custid=@custid 
		AND winlostdate < @resetDate
		AND bettype IN (SELECT bt.BetType FROM @BetTypeIds bt)
	
	SET @YesterdayBalance = ISNULL(@Credit, 0) -  ISNULL(@Debit, 0)
	
	BEGIN TRY
		BEGIN TRANSACTION	
			--delete yesterday balance
			DELETE dbo.BalanceCreditGame WITH (ROWLOCK)
			WHERE custid = @CustID 
				AND winlostdate < @resetDate
				AND bettype IN (SELECT bt.BetType FROM @BetTypeIds bt)
			
			DELETE dbo.BalanceDebitGame WITH (ROWLOCK)
			WHERE custid = @CustID 
				AND winlostdate < @resetDate
				AND bettype IN (SELECT bt.BetType FROM @BetTypeIds bt)
			
			-- for testing:
			-- RAISERROR ('Reset yesterday balance live casino unsuccessful', 16, 1)
		COMMIT TRANSACTION
				
	END TRY
	BEGIN CATCH		
		ROLLBACK TRANSACTION
		SET @ErrCode = 101
	END CATCH

	SELECT @IsResetYesterdayBalance = 1		
END



GO
GRANT EXECUTE ON [dbo].[Acc_BalanceGameResetYesterday] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_BalanceGameResetYesterday] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BalanceGameResetYesterday] TO [vnteam] AS [dbo]