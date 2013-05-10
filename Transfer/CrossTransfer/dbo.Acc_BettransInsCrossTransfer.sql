ALTER PROCEDURE [dbo].[Acc_BettransInsCrossTransfer]
(
	@FromCustID		INT,
	@ToCustID		INT,
	@FromAmount		MONEY,
	@ToAmount		MONEY,
	@FromExRate		FLOAT,
	@ToExRate		FLOAT,
	@ForexUsername	NVARCHAR(50),
	@Remark			NVARCHAR(200),
	@UserID			INT, --custid of Admin
	@IP				NVARCHAR(15)='',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(200) = '' OUTPUT,
	@Language		VARCHAR(2)= 'E'
)
AS
/*
	Create: 20110902@Lukas
	Task: Insert transfer transactions
	DB: DBTXN/bodb02

	Revisions:
		- 20111010@Lukas: fix bug - overflow datatype varchar
		- 20111026@Lukas: update member's balance (credit/Debit tables)
		- 20120216@Lukas: Edit transfer description to make transactions more clear (support finance team)
		- 20120731@Sophia: Check To account not the same From account 
		- 20120813@Lukas: modify to avoid losing precision when convert a money datatype to varchar (remark)
		- 20121113@Viet: revise sp
		- 20130208@Elodie: Change link server DB03 to DBPOLICY
					       Write more log on DBTXN server in case of DBLOG server failure
*/
BEGIN
	SET NOCOUNT ON	
	
	--Check To account not the same From account 
	IF @FromCustID = @ToCustID 
	BEGIN
		SELECT @ErrMsg = 'You cannot do TRANSFER due to the destination account is the same as the source account.', @ErrCode = 100 
		RETURN
	END 
		
	--Check permission for account site: @phuc20080213
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[FinanceTransfer]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	If @ErrCode <> 0
		RETURN
		
	DECLARE @refno			BIGINT,
			@winlostdate	DATETIME, 
			@transdate		DATETIME,
			@RemarkFromCurr	NVARCHAR(70),
			@RemarkToCurr	NVARCHAR(70)


	DECLARE @FromUsername	NVARCHAR(50),
			@FromCurrency	INT,
			@FromActualRate FLOAT,
			@FromCurrName	NVARCHAR(50),
			@FromRecommend	INT,
			@FromMrecommend	INT,
			@FromSrecommend	INT,
			@FromRoleID		TINYINT

	DECLARE @ToUsername		NVARCHAR(50),
			@ToCurrency		INT,
			@ToActualRate	FLOAT,
			@ToCurrName		NVARCHAR(50),
			@ToRecommend	INT,
			@ToMrecommend	INT,
			@ToSrecommend	INT,
			@ToRoleID		TINYINT

	DECLARE @ForexCustID 		INT,
			@ForexCurrency		INT,
			@ForexActualRate	FLOAT,
			@ForexCurrName		NVARCHAR(50),
			@ForexRecommend		INT,
			@ForexMrecommend	INT,
			@ForexSrecommend	INT

	--- Get @FromCustomer info 
	SELECT 
		@FromUsername	= c.username,
		@FromCurrency	= c.currency,
		@FromActualRate = e.actualrate,
		@FromCurrName	= e.currency,
		@FromRecommend	= c.recommend,
		@FromMrecommend	= c.mrecommend,
		@FromSrecommend	= c.srecommend,
		@FromRoleID		= c.roleid
	FROM custinfo c WITH(NOLOCK)
			INNER JOIN exchange e WITH(NOLOCK) ON c.currency = e.exchangeid
	WHERE c.custid = @FromCustID

	--- Get @ToCustomer info
	SELECT 
		@ToUsername		= c.username,
		@ToCurrency		= c.currency,
		@ToActualRate	= e.actualrate,
		@ToCurrName		= e.currency,
		@ToRecommend	= c.recommend,
		@ToMrecommend	= c.mrecommend,
		@ToSrecommend	= c.srecommend,
		@ToRoleID		= c.roleid
	FROM custinfo c WITH(NOLOCK)
			INNER JOIN exchange e WITH(NOLOCK) ON c.currency = e.exchangeid
	WHERE c.custid = @ToCustID	

	-- Get @ForexCustomer info
	SELECT 
		@ForexCustID	= c.custID,
		@ForexCurrency	= c.currency,
		@ForexActualRate= e.actualrate,
		@ForexCurrName	= e.currency,
		@ForexRecommend	= c.recommend,
		@ForexMrecommend= c.mrecommend,
		@ForexSrecommend= c.srecommend
	FROM custinfo c WITH(NOLOCK)
			INNER JOIN exchange e WITH(NOLOCK) ON c.currency = e.exchangeid
	WHERE c.username = @ForexUsername

	IF	@FromUsername IS NULL OR @FromUsername = '' OR
		@ToUsername IS NULL OR @ToUsername = '' OR 
		@ForexCustID IS NULL OR @ForexCustID = 0
	BEGIN
		SELECT @ErrMsg =CASE @Language 
							WHEN 'E' THEN 'Customer does not exist.'
							WHEN 'CS' THEN N'Customer does not exist.'
							WHEN 'J' THEN N'ID確認できません。'
							ELSE N'Customer does not exist.'
						END, @ErrCode = 101
		RETURN
	END

	IF @ToCurrency = @FromCurrency
	BEGIN
		SELECT @ErrMsg =CASE @Language 
							WHEN 'E' THEN 'This is not cross-currency transfer.'
							WHEN 'CS' THEN N'This is not cross-currency transfer.'
							WHEN 'J' THEN N'This is not cross-currency transfer.'
							ELSE N'This is not cross-currency transfer.'
						END, @ErrCode = 102
		RETURN
	END

	IF @ToAmount/@FromAmount <= 0 OR @FromExRate <=0 OR @ToExRate <=0
	BEGIN	
		SELECT @ErrMsg =CASE @Language
							WHEN 'E' THEN 'Invalid amount or exchange rate.'
							WHEN 'CS' THEN N'Invalid amount or exchange rate.'
							WHEN 'J' THEN N'Invalid amount or exchange rate.'
							ELSE N'Invalid amount or exchange rate.'
						END, @ErrCode = 103	
		RETURN
	END
	
	SELECT	@transdate		= CURRENT_TIMESTAMP,
			@RemarkFromCurr	= '',  
			@RemarkToCurr	= '',
			@winlostdate = CONVERT(NVARCHAR(10), CURRENT_TIMESTAMP,120)

	BEGIN TRANSACTION
		EXEC dbo.Acc_SelTransCode @transcode = @refno OUTPUT
		SET @refno = 200000000000 + @refno
	COMMIT TRANSACTION

	----- transfer from @FromCustomer to @ForexAcc
	
	SELECT	@RemarkFromCurr =   ' - ' +@FromCurrName + ' '+ CONVERT(NVARCHAR(50),@FromAmount),
			@RemarkToCurr   =   ' - ' +@ForexCurrName+ ' '+ CONVERT(NVARCHAR(50),CONVERT(NUMERIC(20,4),@FromAmount * @FromExRate))


	--- update @FromCustID's credit if this action reduce balance, then insert transfer transaction into bettrans
	--- whereas this action increase balance, insert bettrans first then update credit	
	DECLARE @tmp MONEY
	IF @FromAmount < 0 AND @FromRoleID = 1	
	BEGIN		
		SET @tmp = ABS(@FromAmount)
		EXEC Dot_BalanceUpdDebit @CustID = @FromCustID, @balance = @tmp
	END

	INSERT INTO bettrans (creator, custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
						 status, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
						 scomm, swinlost,ip,statusID)
	VALUES(@UserID, @FromCustID, @FromUsername, @refno, @transdate, 0, 21003, 'To Customer: ' + @ForexUsername + '('+ @Remark +')' + @RemarkToCurr, 
						CASE WHEN @FromAmount > 0 THEN @FromAmount ELSE 0 END , CASE WHEN @FromAmount > 0 THEN 0 ELSE ABS(@FromAmount) END,
						'Completed',1, @winlostdate, @FromCurrency, @FromActualRate, @FromCurrName, @FromRecommend, @FromMrecommend, @FromSrecommend,
						0, 0, @ip,131)
	IF @@ERROR <> 0
	BEGIN
		SELECT  @ErrMsg = CASE @Language WHEN 'E'  THEN 'Transfer failed. Please try again.'
										 WHEN 'CS' THEN N'Transfer failed. Please try again.'
										 WHEN 'J'  THEN N'払戻処理上にエラーが発生しました。もう一度確認してください。'
										 ELSE N'Transfer failed. Please try again.'
						 END, 
				@ErrCode = 104		
				
		DELETE bettrans WITH(ROWLOCK,UPDLOCK) 
		WHERE custid in (@FromCustID, @ForexCustID, @ToCustID)
			AND refno = @refno 
			AND matchid = 0 
			AND bettype = 21003
			
		--- rollback credit
		IF @FromAmount < 0 AND @FromRoleID = 1
			EXEC Dot_BalanceUpdCredit @CustID = @FromCustID, @balance = @tmp
		RETURN
	END
	---- update @FromCustID's credit if this action increase balance
	IF @FromAmount > 0 AND @FromRoleID = 1	
		EXEC Dot_BalanceUpdCredit @CustID = @FromCustID, @balance = @FromAmount	

	
	---- update Forex account's credit
	
	INSERT INTO bettrans (creator, custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
						 status, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
						 scomm, swinlost,ip,statusID)
	VALUES(@UserID,@ForexCustID,@ForexUsername, @refno, @transdate, 0, 21003, 'From Customer: ' + @FromUsername + '('+ @Remark +')' + @RemarkFromCurr, 
						CASE WHEN @FromAmount > 0 THEN 0 ELSE ABS(@FromAmount)*@FromExRate END, CASE WHEN @FromAmount > 0 THEN @FromAmount*@FromExRate ELSE 0 END,
						'Completed', 1, @winlostdate, @ForexCurrency, @ForexActualRate, @ForexCurrName, @ForexRecommend, @ForexMrecommend, @ForexSrecommend,
						0, 0, @ip,131)


	IF @@ERROR <> 0
	BEGIN
		SELECT  @ErrMsg = CASE @Language WHEN 'E'  THEN 'Transfer failed. Please try again.'
										 WHEN 'CS' THEN N'Transfer failed. Please try again.'
										 WHEN 'J'  THEN N'払戻処理上にエラーが発生しました。もう一度確認してください。'
										 ELSE N'Transfer failed. Please try again.'
						 END, 
				@ErrCode = 105

		DELETE bettrans WITH(ROWLOCK,UPDLOCK) 
		WHERE custid in (@FromCustID, @ForexCustID, @ToCustID)
			AND refno = @refno 
			AND matchid = 0 
			AND bettype = 21003		

		IF @FromAmount > 0 AND @FromRoleID = 1	--- rollback for add to credit
			EXEC Dot_BalanceUpdDebit @CustID = @FromCustID, @balance = @FromAmount	
		IF @FromAmount < 0 AND @FromRoleID = 1	--- rollback for add to debit
			EXEC Dot_BalanceUpdCredit @CustID = @FromCustID, @balance = @tmp		
		RETURN
	END

	----- transfer from @ForexAcc to @ToCustomer
	IF @FromAmount > 0
	BEGIN
		SELECT	@RemarkFromCurr =   ' - ' + @ForexCurrName	+ ' -'+ CONVERT(NVARCHAR(50),CONVERT(NUMERIC(20,4),@ToAmount* @ToExRate)),
				@RemarkToCurr   =   ' - ' +	@ToCurrName		+ ' -'+ CONVERT(NVARCHAR(50),@ToAmount )
	END	
	IF @FromAmount < 0
	BEGIN
		SELECT	@RemarkFromCurr =   ' - ' + @ForexCurrName	+ ' '+ CONVERT(NVARCHAR(50),CONVERT(NUMERIC(20,4),ABS(@ToAmount)* @ToExRate)),
				@RemarkToCurr   =   ' - ' +	@ToCurrName		+ ' '+ CONVERT(NVARCHAR(50),ABS(@ToAmount) )
	END

	INSERT INTO bettrans (creator, custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
						 status, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
						 scomm, swinlost,ip,statusID)
	VALUES(@UserID,@ForexCustID,@ForexUsername, @refno, @transdate, 0, 21003, 'From Customer: ' + @ToUsername + '('+ @Remark +')' + @RemarkToCurr, 
						CASE WHEN @FromAmount > 0 THEN @ToAmount*@ToExRate ELSE 0 END, CASE WHEN @FromAmount > 0 THEN 0 ELSE ABS(@ToAmount)*@ToExRate END,
						'Completed', 1, @winlostdate, @ForexCurrency, @ForexActualRate, @ForexCurrName, @ForexRecommend, @ForexMrecommend, @ForexSrecommend,
						0, 0, @ip,131)

	IF @@ERROR <> 0
	BEGIN
		SELECT  @ErrMsg = CASE @Language WHEN 'E'  THEN 'Transfer failed. Please try again.'
										 WHEN 'CS' THEN N'Transfer failed. Please try again.'
										 WHEN 'J'  THEN N'払戻処理上にエラーが発生しました。もう一度確認してください。'
										 ELSE N'Transfer failed. Please try again.'
						 END, 
				@ErrCode = 106

		DELETE bettrans WITH(ROWLOCK,UPDLOCK) 
		WHERE custid in (@FromCustID, @ForexCustID, @ToCustID)
			AND refno = @refno 
			AND matchid = 0 
			AND bettype = 21003
	
		IF @FromAmount > 0 AND @FromRoleID = 1	--- rollback for add to credit
			EXEC Dot_BalanceUpdDebit @CustID = @FromCustID, @balance = @FromAmount	
		IF @FromAmount < 0 AND @FromRoleID = 1	--- rollback for add to debit
			EXEC Dot_BalanceUpdCredit @CustID = @FromCustID, @balance = @tmp	

		RETURN
	END
	
	--- update @ToCustID's credit if this action reduce balance, then insert transfer transaction into bettrans
	--- whereas this action increase balance, insert bettrans first then update credit
	IF @FromAmount > 0 AND @ToRoleID = 1
		EXEC Dot_BalanceUpdDebit @CustID = @ToCustID, @balance = @ToAmount
	
	INSERT INTO bettrans (creator, custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
						 status, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
						 scomm, swinlost,ip,statusID)
		VALUES(@UserID, @ToCustID, @ToUsername, @refno, @transdate, 0, 21003, 'To Customer: ' + @ForexUsername + '('+ @Remark +')' + @RemarkFromCurr, 
						CASE WHEN @FromAmount > 0 THEN 0 ELSE ABS(@ToAmount) END, CASE WHEN @FromAmount > 0 THEN ABS(@ToAmount) ELSE 0 END,
						'Completed',1, @winlostdate, @ToCurrency, @ToActualRate, @ToCurrName, @ToRecommend, @ToMrecommend, @ToSrecommend,
						0, 0, @ip,131)	

	IF @@ERROR <> 0
	BEGIN
		SELECT  @ErrMsg = CASE @Language WHEN 'E'  THEN 'Transfer failed. Please try again.'
										 WHEN 'CS' THEN N'Transfer failed. Please try again.'
										 WHEN 'J'  THEN N'払戻処理上にエラーが発生しました。もう一度確認してください。'
										 ELSE N'Transfer failed. Please try again.'
						 END, 
				@ErrCode = 107

		DELETE bettrans WITH(ROWLOCK,UPDLOCK) 
		WHERE custid in (@FromCustID, @ForexCustID, @ToCustID)
			AND refno = @refno 
			AND matchid = 0 
			AND bettype = 21003
	
		IF @FromAmount > 0 AND @FromRoleID = 1	--- rollback for add to credit
			EXEC Dot_BalanceUpdDebit @CustID = @FromCustID, @balance = @FromAmount	
		IF @FromAmount < 0 AND @FromRoleID = 1	--- rollback for add to debit
			EXEC Dot_BalanceUpdCredit @CustID = @FromCustID, @balance = @tmp	

		IF @FromAmount > 0 AND @ToRoleID = 1
			EXEC Dot_BalanceUpdCredit @CustID = @ToCustID, @balance = @ToAmount
		RETURN
	END

	DECLARE @amtTo MONEY

	IF @FromAmount < 0 AND @ToRoleID = 1
	BEGIN
		SET @amtTo = ABS(@ToAmount)
		EXEC Dot_BalanceUpdCredit @CustID = @ToCustID, @balance = @amtTo
	END	

	---- update forex's balance		
	DECLARE @ForexDebit MONEY,
			@ForexCredit MONEY

	SELECT	@ForexDebit		= ABS(@FromAmount*@FromExrate),
			@ForexCredit	= ABS(@ToAmount*@ToExrate)

	IF @ForexCredit > @ForexDebit
	BEGIN
		SET @tmp = @ForexCredit - @ForexDebit
		EXEC Dot_BalanceUpdCredit @CustID = @ForexCustID, @balance = @tmp 
	END
	IF @ForexCredit < @ForexDebit
	BEGIN
		SET @tmp = @ForexDebit - @ForexCredit
		EXEC Dot_BalanceUpdDebit @CustID = @ForexCustID, @balance = @tmp 
	END		
	
	


	DECLARE @SystemExRate	FLOAT,
			@TransExRate	FLOAT,
			@LogData		VARCHAR(1000)

	SELECT	@SystemExRate = ROUND(@FromExRate/@ToExRate,4),
			@TransExRate  = ROUND(@ToAmount/@FromAmount,4)

	SELECT @LogData = 'Transfer from Customer ' + @FromUserName + ' to Customer ' + @ToUserName + 
					  ' with from amount ' + CONVERT(VARCHAR(20), @FromAmount) + ' to amount ' + CONVERT(VARCHAR(20), @ToAmount) +
					  ' (System Ex.Rate' + '(' + @FromCurrName + '/' + @ToCurrName + ') ' + CONVERT(VARCHAR(20),@SystemExRate) + 
					  ' Trans Ex.Rate' + '(' + @FromCurrName + '/' + @ToCurrName + ') ' + CONVERT(VARCHAR(20),@TransExRate) + ')' + 
					  ' Ref.No ' + CONVERT(VARCHAR(20), @refno)

	EXEC DBPOLICY.bodb02.dbo.Acc_ExchangeRateCheckValid 
				@FromExchangeID = @FromCurrency, 
				@ToExchangeID	= @ToCurrency, 
				@ExchangeRate	= @TransExRate,
				@UserID			= @UserID , 
				@FromCust		= @FromCustID, 
				@ToCust			= @ToCustID, 
				@Amount			= @FromAmount, 
				@transDate		= @transdate ,
				@refNo			= @refno

	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @FromCustID, @ToCustID = @ToCustID, @IP = @IP, @Doing = @LogData
	END TRY
	BEGIN CATCH
		Select @LogData = @LogData + ' ErrMsg=' + error_message()
		EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @FromCustID, @ToCustID = @ToCustID, @IP = @IP, @Doing = @LogData
	END CATCH
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransInsCrossTransfer] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransInsCrossTransfer] TO [vnteam] AS [dbo]