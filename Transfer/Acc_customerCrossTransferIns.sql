


ALTER PROCEDURE [dbo].[Acc_customerCrossTransferIns]
(
	@FromCustID		INT,
	@ToCustID		INT,
	@FromAmount		MONEY,
	@ToAmount		MONEY,
	@FromExRate		FLOAT,
	@ToExRate		FLOAT,
	@ForexUsername	NVARCHAR(50),
	@Remark			NVARCHAR(100),
	@UserID			INT, --custid of Admin
	@IP				NVARCHAR(15)='',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(200) = '' OUTPUT,
	@Language		VARCHAR(2)= 'E'
)
AS
/*
	Create: 20110902@Lukas
	Task: Get customer's currency info
	DB: DB053.BODB02

	Revisions:

*/
BEGIN
	SET NOCOUNT ON	
	
	--Check permission for account site: @phuc20080213
	EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherTrans]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
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
			@FromSrecommend	INT

	DECLARE @ToUsername		NVARCHAR(50),
			@ToCurrency		INT,
			@ToActualRate	FLOAT,
			@ToCurrName		NVARCHAR(50),
			@ToRecommend	INT,
			@ToMrecommend	INT,
			@ToSrecommend	INT

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
		@FromSrecommend	= c.srecommend
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
		@ToSrecommend	= c.srecommend
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

	IF @FromAmount*@ToAmount <= 0 OR @FromExRate <=0 OR @ToExRate <=0
	BEGIN	
		SELECT @ErrMsg =CASE @Language
							WHEN 'E' THEN 'Invalid amount or exchange rate.'
							WHEN 'CS' THEN N'Invalid amount or exchange rate.'
							WHEN 'J' THEN N'Invalid amount or exchange rate.'
							ELSE N'Invalid amount or exchange rate.'
						END, @ErrCode = 107	
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
	IF @FromExRate <> 1 
	BEGIN
		SELECT	@RemarkFromCurr =   ' - ' +@FromCurrName + ' '+ CONVERT(NVARCHAR(50),@FromAmount),
				@RemarkToCurr   =   ' - ' +@ForexCurrName+ ' '+ CONVERT(NVARCHAR(50),@FromAmount * @FromExRate)
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
				@ErrCode = 103

		DELETE bettrans WITH(ROWLOCK,UPDLOCK) WHERE refno = @refno AND matchid = 0 AND bettype = 21003
		RETURN
	END

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
				@ErrCode = 104

		DELETE bettrans WITH(ROWLOCK,UPDLOCK) WHERE refno = @refno and matchid = 0
		RETURN
	END

	----- transfer from @ForexAcc to @ToCustomer
	IF @ToExRate <> 1 
	BEGIN
		SELECT	@RemarkFromCurr =   ' - ' + @ForexCurrName	+ ' '+ CONVERT(NVARCHAR(50),@ToAmount* @ToExRate),
				@RemarkToCurr   =   ' - ' +	@ToCurrName		+ ' '+ CONVERT(NVARCHAR(50),@ToAmount )
	END

	INSERT INTO bettrans (creator, custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
						 status, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
						 scomm, swinlost,ip,statusID)
	VALUES(@UserID,@ForexCustID,@ForexUsername, @refno, @transdate, 0, 21003, 'To Customer: ' + @ToUsername + '('+ @Remark +')' + @RemarkToCurr, 
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
				@ErrCode = 103

		DELETE bettrans WITH(ROWLOCK,UPDLOCK) WHERE refno = @refno AND matchid = 0 AND bettype = 21003
		RETURN
	END

	INSERT INTO bettrans (creator, custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
						 status, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
						 scomm, swinlost,ip,statusID)
		VALUES(@UserID, @ToCustID, @ToUsername, @refno, @transdate, 0, 21003, 'From Customer: ' + @ForexUsername + '('+ @Remark +')' + @RemarkFromCurr, 
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
				@ErrCode = 104

		DELETE bettrans WITH(ROWLOCK,UPDLOCK) WHERE refno = @refno and matchid = 0
		RETURN
	END

	DECLARE @SystemExRate	FLOAT,
			@TransExRate	FLOAT,
			@LogData		VARCHAR(1000)

	SELECT	@SystemExRate = @FromExRate/@ToExRate,
			@TransExRate  = @ToAmount/@FromAmount

	SELECT @LogData = 'Transfer from Customer ' + @FromUserName + ' to Customer ' + @ToUserName + 
					  ' with from amount ' + CONVERT(VARCHAR(20), @FromAmount) + ' to amount ' + CONVERT(VARCHAR(20), @ToAmount) +
					  ' System Ex.Rate ' + CONVERT(VARCHAR(10),@SystemExRate) + ' Trans Ex.Rate ' + CONVERT(VARCHAR(10),@TransExRate) +
					  ' Ref.No ' + CONVERT(VARCHAR(20), @refno)

	EXEC db03.bodb02.dbo.Acc_ExchangeRateCheckValid 
				@FromExchangeID = @FromCurrency, 
				@ToExchangeID	= @ToCurrency, 
				@ExchangeRate	= @TransExRate,
				@UserID			= @UserID , 
				@FromCust		= @FromCustID, 
				@ToCust			= @ToCustID, 
				@Amount			= @FromAmount, 
				@transDate		= @transdate ,
				@refNo			= @refno

	
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @FromCustID, @ToCustID = @ToCustID, @IP = @IP, @Doing = @LogData


END


GO
GRANT  EXECUTE  ON [dbo].[Acc_customerCrossTransferIns]  TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_customerCrossTransferIns] TO [vnteam]