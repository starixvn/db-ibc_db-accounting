ALTER PROCEDURE [dbo].[Acc_FinanceTransferBettransIns]
	@FromCustID int,
	@ToUserName varchar(30), 
	@Amount money,
	@ExchangeRate float,
	@Remark nvarchar(200),
	@UserID int, --custid of Admin
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2)= 'E'
AS
/*
Created: Jamie
Date: 20101104
DB: DBTXN/BODB02
Original: Acc_BettransInsTransfer

Revisions:
	- 20101229@Lukas: Re-arrange bettype
	- 20111026@Lukas: update member's balance (credit/Debit tables)
	- 20111130@Lukas: Expand remark variable length
	- 20120412@Sophia Revise member's balance (credit/Debit tables)
	- 20120731@Sophia: Check To account not the same From account 
	- 20120813@Lukas: modify to avoid losing precision when convert a money datatype to varchar (remark)
	- 20121113@Viet: revise SP
	- 20130201@Elodie: Change link server DB03 to DBPOLICY
					   Write more log on DBTXN server in case of DBLOG server failure
	- 20131108@Elodie: Splitting bodb02 into CustDB (Call CustInfo, Exchange by link database)
	- 20150808@Elodie: Balance Improvement [Redmine:#40125]
	- 20151021@Elodie: Set @IsForce = 1 for updating balance debit [Redmine:#40125]

Param's Explanation:

*/

SET NOCOUNT ON

Declare @ToMrecommend int, @ToRecommend int, @ToSrecommend int, @ToCustID int, @Amt money, @ToRoleID TINYINT,
		@ToCurr int, @ToActualrate float, @ToCurrName nvarchar(10), @RemarkFromCurr nvarchar(70), @RemarkToCurr nvarchar(70)
Declare @FromMrecommend int, @FromRecommend int, @FromSrecommend int, @FromRoleID TINYINT,
		@FromCurr int, @FromActualrate float , @FromCurrName nvarchar(10),@FromUsername varchar(30)
Declare @LogData varchar(200)

Declare @refno bigint, @winlostdate datetime, @transdate datetime, @BalanceAmount MONEY

select  @RemarkFromCurr='',  @RemarkToCurr=''
select @Amt = @Amount 
select @transdate = current_timestamp 	
select @winlostdate = convert(nvarchar(10), current_timestamp,120)

select @FromUsername = c.username, 
	@FromCurr = c.currency,
	@FromCurrName = e.currency,
	@FromRecommend = c.recommend,
	@FromMrecommend = c.mrecommend,
	@FromSrecommend = c.srecommend,
	@FromActualrate = e.actualrate,
	@FromRoleID	= roleid
from CustDB.dbo.Custinfo c with (NOLOCK)
	INNER JOIN CustDB.dbo.Exchange e with (NOLOCK) on c.currency = e.exchangeid 
where c.CustID = @FromCustID


Select @ToCustID = null
select @ToCustID = c.CustID,
	   @ToCurr = c.currency,
	   @ToCurrName = e.currency,
	   @ToRecommend = c.recommend,
	   @ToMrecommend = c.mrecommend,
	   @ToSrecommend = c.srecommend,
	   @ToActualrate = actualrate,
	   @ToRoleID	= roleid
from CustDB.dbo.Custinfo c with (NOLOCK)
	INNER JOIN CustDB.dbo.Exchange e with (NOLOCK) ON c.currency = e.exchangeid 
where c.username = @ToUserName


if @ToCustID is NULL or @ToCustID = 0
BEGIN
	Select @ErrMsg = case @Language 
							when 'E' then 'Customer ' + @ToUserName + ' does not exist.'
							when 'CS' then N'Customer ' + @ToUserName + ' does not exist.'
							when 'J' then N'ID確認できません。'
							else N'Customer ' + @ToUserName + ' does not exist.'
					end, @ErrCode = 100
	return
END

---Check To account not the same From account 
IF @FromCustID = @ToCustID 
BEGIN
	SELECT @ErrMsg = 'You cannot do TRANSFER due to the destination account is the same as the source account.', @ErrCode = 101
	RETURN
END

if not exists (select 1 from CustDB.dbo.Custinfo with (NOLOCK) where custid = @FromCustID)
BEGIN
	Select @ErrMsg = case @Language 
							when 'E' then 'Customer does not exist.'
							when 'CS' then N'Customer does not exist.'
							when 'J' then N'ID確認できません。'
							else N'Customer does not exist.'
						end, @ErrCode = 102	
	return
END


if @Amount = 0 or @ExchangeRate = 0 
BEGIN
	SELECT @ErrMsg =  case @Language
						when 'E' then 'Invalid amount or exchange rate.'
						when 'CS' then N'Invalid amount or exchange rate.'
						when 'J' then N'Invalid amount or exchange rate.'
						else N'Invalid amount or exchange rate.'
					end, @ErrCode = 107	
	return
END

IF @ExchangeRate <> 1 
BEGIN
	SELECT @RemarkFromCurr =   ' - ' +@FromCurrName + ' '+ convert(nvarchar(50),@Amount)
	SELECT @RemarkToCurr   =   ' - ' +@ToCurrName   + ' '+ convert(nvarchar(50),CONVERT(NUMERIC(20,4),@amount * @ExchangeRate))
	
END 
BEGIN TRANSACTION
	EXEC dbo.Acc_SelTransCode @transcode = @refno OUTPUT
	select @refno=200000000000+@refno	
COMMIT TRANSACTION

	IF @amount > 0
	BEGIN
		INSERT INTO bettrans 
			(creator, custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
			 status, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
			 scomm, swinlost,ip,statusID)
		VALUES (@UserID, @FromCustID, @FromUsername, @refno, @Transdate, 0, 21003, 'To Customer: ' + @ToUserName + '('+ @Remark +')' + @RemarkToCurr, @amount, 0, 
			 'Completed', 1, @winlostdate, @FromCurr, @FromActualrate, @FromCurrName, @FromRecommend, @FromMrecommend, @FromSrecommend, 
			 0, 0,@ip,131)
		if @@Error <> 0
		BEGIN
			Select @ErrMsg = case @Language 
						when 'E' then 'Transfer failed. Please try again.'
						when 'CS' then N'Transfer failed. Please try again.'
						when 'J' then N'払戻処理上にエラーが発生しました。もう一度確認してください。'
						else N'Transfer failed. Please try again.'
					end, @ErrCode = 103		
			
			DELETE dbo.bettrans
			WHERE custid in (@FromCustID, @ToCustID)
				and matchid = 0 and bettype = 21003 and refno = @refno
				
			return
		END
		--update credit balance of @FromCustID
		IF @FromRoleID  = 1
		BEGIN
			--EXEC Dot_BalanceUpdCredit @CustID = @FromCustID, @balance = @amount 
			EXEC Dot_BalanceCreditUpd @CustID = @FromCustID, @balance = @amount, @type = 2
		END 
		
		----------------------------------------------------------------------		
		--update debit balance of @ToCustID
		IF @ToRoleID  = 1
		BEGIN
			SELECT @BalanceAmount = @amount * @ExchangeRate
			--EXEC Dot_BalanceUpdDebit @CustID = @ToCustID, @balance = @BalanceAmount
						EXEC Dot_BalanceDebitUpd @CustID = @ToCustID, @balance = @BalanceAmount, @type = 2, @IsForced = 1, @errCode = @ErrCode OUTPUT
			IF @ErrCode <> 0
			BEGIN
				DELETE dbo.bettrans
				WHERE custid in (@FromCustID, @ToCustID)
					and matchid = 0 and bettype = 21003 and refno = @refno
				
				IF @FromRoleID  = 1
										EXEC Dot_BalanceDebitUpd @CustID = @FromCustID, @balance = @amount, @type = 2, @IsForced = 1
			END
		END
		
		INSERT INTO bettrans 
			(creator, custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
			 status, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
			 scomm, swinlost,ip,statusID)
		VALUES (@UserID, @ToCustID, @ToUsername, @refno, @Transdate, 0, 21003, 'From Customer: ' + @FromUserName + '('+ @Remark +')' + @RemarkFromCurr, 0, @amount * @ExchangeRate, 
			 'Completed', 1, @winlostdate, @ToCurr, @ToActualrate, @ToCurrName, @ToRecommend, @ToMrecommend, @ToSrecommend, 
			 0, 0,@ip,131)
		if @@Error <> 0
		BEGIN
			Select @ErrMsg = case @Language 
						when 'E' then 'Transfer failed. Please try again.'
						when 'CS' then N'Transfer failed. Please try again.'
						when 'J' then N'払戻処理上にエラーが発生しました。もう一度確認してください。'
						else N'Transfer failed. Please try again.'
					end, @ErrCode = 104
			
			DELETE dbo.bettrans
			WHERE custid in (@FromCustID, @ToCustID)
				and matchid = 0 and bettype = 21003 and refno = @refno
			
			--rollback balance of @FromCustID
			IF @FromRoleID  = 1
			BEGIN
				--EXEC Dot_BalanceUpdDebit @CustID = @FromCustID, @balance = @amount 
								EXEC Dot_BalanceDebitUpd @CustID = @FromCustID, @balance = @amount, @type = 2, @IsForced = 1
			END 
		
			--rollback balance of @ToCustID
			IF @ToRoleID  = 1
			BEGIN
				SELECT @BalanceAmount = @amount * @ExchangeRate
				--EXEC Dot_BalanceUpdCredit @CustID = @ToCustID, @balance = @BalanceAmount 
				EXEC Dot_BalanceCreditUpd @CustID = @ToCustID, @balance = @BalanceAmount, @type = 2
			END		
			return
		END

		Select @LogData = 'Finance Transfer from Customer ' + @FromUserName + ' to Customer ' + @ToUserName + ' with amount ' + convert(varchar(20), @Amt) + ' Ref.No ' + convert(varchar(20), @refno)		
		
	END
	ELSE
	BEGIN
		SET @amount = abs(@amount)
		
		--update debit balance of @FromCustID
		IF @FromRoleID  = 1
		BEGIN
			--EXEC Dot_BalanceUpdDebit @CustID = @FromCustID, @balance = @amount 
						EXEC Dot_BalanceDebitUpd @CustID = @FromCustID, @balance = @amount, @type = 2, @IsForced = 1, @errCode = @ErrCode OUTPUT
			IF @ErrCode <> 0
			BEGIN
				Select @ErrMsg = case @Language 
						when 'E' then 'Transfer failed. Please try again.'
						when 'CS' then N'Transfer failed. Please try again.'
						when 'J' then N'払戻処理上にエラーが発生しました。もう一度確認してください。'
						else N'Transfer failed. Please try again.'
					end, @ErrCode = 104
				RETURN
			END
		END
		
		INSERT INTO bettrans 
			(creator, custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
			 status, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
			 scomm, swinlost,ip,statusID)
		VALUES (@UserID, @FromCustID, @FromUsername, @refno, @Transdate, 0, 21003, 'To Customer: ' + @ToUserName + '('+ @Remark +')'+@RemarkToCurr, 0, @amount, 
			 'Completed', 1, @winlostdate, @FromCurr, @FromActualrate, @FromCurrName, @FromRecommend, @FromMrecommend, @FromSrecommend, 
			 0, 0,@ip,131)
		if @@Error <> 0
		BEGIN
			Select @ErrMsg = case @Language 
						when 'E' then 'Transfer failed. Please try again.'
						when 'CS' then N'Transfer failed. Please try again.'
						when 'J' then N'払戻処理上にエラーが発生しました。もう一度確認してください。'
						else N'Transfer failed. Please try again.'
					end, @ErrCode = 105
			
			DELETE dbo.bettrans
			WHERE custid in (@FromCustID, @ToCustID)
				and matchid = 0 and bettype = 21003 and refno = @refno
			
			--rollback balance @FromCustID
			IF @FromRoleID  = 1
			BEGIN
				--EXEC Dot_BalanceUpdCredit @CustID = @FromCustID, @balance = @amount 
				EXEC Dot_BalanceCreditUpd @CustID = @FromCustID, @balance = @amount, @type = 2
			END
			return
		END
		-----------------------------------------------
		INSERT INTO bettrans 
			(creator, custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
			 status, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
			 scomm, swinlost,ip,statusID)
		VALUES (@UserID, @ToCustID, @ToUsername, @refno, @Transdate, 0, 21003, 'From Customer: ' + @FromUserName + '('+ @Remark +')' + @RemarkFromCurr, @amount * @ExchangeRate, 0, 
			 'Completed', 1, @winlostdate, @ToCurr, @ToActualrate, @ToCurrName, @ToRecommend, @ToMrecommend, @ToSrecommend, 
			 0, 0,@ip,131)
		if @@Error <> 0
		BEGIN
			Select @ErrMsg = case @Language 
						when 'E' then 'Transfer failed. Please try again.'
						when 'CS' then N'Transfer failed. Please try again.'
						when 'J' then N'払戻処理上にエラーが発生しました。もう一度確認してください。'
						else N'Transfer failed. Please try again.'
					end, @ErrCode = 106
			
			DELETE dbo.bettrans
			WHERE custid in (@FromCustID, @ToCustID)
				and matchid = 0 and bettype = 21003 and refno = @refno
				
			--rollback balance @FromCustID
			IF @FromRoleID  = 1
			BEGIN
				--EXEC Dot_BalanceUpdCredit @CustID = @FromCustID, @balance = @amount 
				EXEC Dot_BalanceCreditUpd @CustID = @FromCustID, @balance = @amount, @type = 2
			END
			return
		END	
		
		---update credit balance of @ToCustID
		IF @ToRoleID  = 1
		BEGIN
			SELECT @BalanceAmount = @amount * @ExchangeRate 
			--EXEC Dot_BalanceUpdCredit @CustID = @ToCustID, @balance = @BalanceAmount 
			EXEC Dot_BalanceCreditUpd @CustID = @ToCustID, @balance = @BalanceAmount, @type = 2
		END

		Select @LogData = 'Finance Transfer from Customer ' + @ToUserName + ' to Customer ' + @FromUserName + ' with amount ' + convert(varchar(20), @Amt) + ' Ref.No ' + convert(varchar(20), @refno)		
		
	END
	
	
--Write Log : Invalid Exchange Rate @Phuong20081023
EXEC DBPOLICY.bodb02.dbo.Acc_ExchangeRateCheckValid @FromExchangeID = @FromCurr, @ToExchangeID = @ToCurr, @ExchangeRate = @ExchangeRate,
												  @UserID = @UserID , @FromCust = @FromCustID, @ToCust = @ToCustID, @Amount = @Amt, @transDate =@transdate ,@refNo = @refno
BEGIN TRY
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @FromCustID, @ToCustID = @ToCustID, @IP = @IP, @Doing = @LogData
END TRY
BEGIN CATCH
	Select @LogData = @LogData + ' ErrMsg=' + error_message()
	EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @FromCustID, @ToCustID = @ToCustID, @IP = @IP, @Doing = @LogData
END CATCH

GO
GRANT EXECUTE ON [dbo].[Acc_FinanceTransferBettransIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_FinanceTransferBettransIns] TO [vnteam] AS [dbo]