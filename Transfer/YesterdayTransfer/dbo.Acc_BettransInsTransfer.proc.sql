/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_BettransInsTransfer]
	@FromCustID int,
	@ToUserName varchar(30), 
	@Amount money,
	@ExchangeRate float,
	@Remark nvarchar(200),
	@UserID int, --custid of Admin
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2)= 'E',
	@isCollection BIT = 0
AS
/*
Task: Left menu / Button transfer
Created: 
DB: DBTXN/bodb02
Revisions:
	- 20090828@HuyNguyen: replace [Customer] --> [OtherTrans]
	- 20091003@Kiwi: Modify Write log and remove CustBetCreditUpdResync
	- 20091125@Kiwi: Remove comstatus because it's no used.		
	- 20100424@Henry: insert data to column StatusID of Bettrans (StatusID = 131 for bettype 103) + Update Status = 'Completed'
	- 20100611@Henry: Write exact amount to log when transferring
	- 20101225@Lukas: Re-arrange bettype
	- 20111025@Sophia: Update balance credit/debit for members
	- 20111130@Lukas: expand remark variable length
	- 20120411@Sophia: Revise credit/ debit balance
	- 20120731@Sophia: Check To account not the same From account 
	- 20120813@Lukas: modify to avoid losing precision when convert a money datatype to varchar (remark)
	- 20121011@Dan: reset yesterday balance for live casino
	- 20121113@Viet: revise SP
	- 20130208@Elodie: Change link server DB03 to DBPOLICY
					   Write more log on DBTXN server in case of DBLOG server failure
	- 20131108@Elodie: Splitting bodb02 into CustDB (Call CustInfo, Exchange by link database) 					       
	- 20150723@Patrick: Support Gold deluxe
	- 20150808@Elodie: Balance Improvement [Redmine:#40125]	
	- 20151021@Elodie: Set @IsForce = 1 for updating balance debit [Redmine:#40125]
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	- 20181112@Sophia: Add Transfer Collection [redmine: #98621]
					   
Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON
	--Check permission for account site: @phuc20080213
	EXEC DBPOL.NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherTrans]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN

	Declare @ToMrecommend int, @ToRecommend int, @ToSrecommend int, @ToCustID int, @Amt money,
			@ToCurr int, @ToActualrate float, @ToCurrName nvarchar(10), @RemarkFromCurr nvarchar(70), @RemarkToCurr nvarchar(70), @ToRoleID tinyint 
	Declare @FromMrecommend int, @FromRecommend int, @FromSrecommend int, 
			@FromCurr int, @FromActualrate float , @FromCurrName nvarchar(10),@FromUsername varchar(30), @FromRoleID tinyint
	Declare @LogData varchar(200), @TransID BIGINT

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
		@FromRoleID = c.roleid
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
		   @ToRoleID = c.roleid
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

	---check To account not the same From account 
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


	/*
	--end
	--Check disable user
	EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @FromCustID, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return

	EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @ToCustID, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
	--end
	*/
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
			
			---Insert into Bettrans
			
			INSERT INTO bettrans 
				(creator, custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
				 status, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
				 scomm, swinlost,ip,statusID, OddsId)
			VALUES (@UserID, @FromCustID, @FromUsername, @refno, @Transdate, 0, 21003, 'To Customer: ' + @ToUserName + '('+ @Remark +')' + @RemarkToCurr, @amount, 0, 
				 'Completed', 1, @winlostdate, @FromCurr, @FromActualrate, @FromCurrName, @FromRecommend, @FromMrecommend, @FromSrecommend, 
				 0, 0,@ip,131, @IsCollection)
			
			SELECT 	@TransID = @@Identity
				
			if @@Error <> 0
			BEGIN
				Select @ErrMsg = case @Language 
							when 'E' then 'Transfer failed. Please try again.'
							when 'CS' then N'Transfer failed. Please try again.'
							when 'J' then N'払戻処理上にエラーが発生しました。もう一度確認してください。'
							else N'Transfer failed. Please try again.'
						end, @ErrCode = 103		
				
				delete bettrans 
				where custid in (@FromCustID, @ToCustID)
					and refno = @refno 
					and matchid = 0
					and bettype = 21003
				
				delete Transfer_Coll
				where  custid in (@FromCustID, @ToCustID)
					and refno = @refno 
					and bettype = 21003
					
				return
			END		

			---Insert into Transfer_Coll
			INSERT INTO Transfer_Coll 
				( CustId, WinlostDate, TransDate, Bettype, Debit, Credit, Currency, ActualRate, 
				TransID, RefNo, Username, Recommend, MRecommend, SRecommend, 
				Creator ,TransDesc, IP )
			SELECT CustId, WinlostDate, TransDate, Bettype, Actual_Stake, Winlost, Currency, ActualRate, 
				TransID, RefNo, Username, Recommend, MRecommend, SRecommend, 
				Creator ,TransDesc, IP
			FROM dbo.Bettrans WITH (NOLOCK) 
			WHERE TransID = @TransID
						
				 
			if @@Error <> 0
			BEGIN
				Select @ErrMsg = case @Language 
							when 'E' then 'Transfer failed. Please try again.'
							when 'CS' then N'Transfer failed. Please try again.'
							when 'J' then N'払戻処理上にエラーが発生しました。もう一度確認してください。'
							else N'Transfer failed. Please try again.'
						end, @ErrCode = 103		
				
				delete bettrans 
				where custid in (@FromCustID, @ToCustID)
					and refno = @refno 
					and matchid = 0
					and bettype = 21003
				
				delete Transfer_Coll
				where  custid in (@FromCustID, @ToCustID)
					and refno = @refno  
					and bettype = 21003
					
				return
			END		
			
			--- update balance credit for @FromCustID
			IF @FromRoleID  = 1
			BEGIN
				--EXEC Dot_BalanceUpdCredit @CustID = @FromCustID, @balance = @amount 
				EXEC Dot_BalanceCreditUpd @CustID = @FromCustID, @balance = @amount, @Type = 2
			END 

			-------------------------------------------

			--- update balance Debit for @ToCustID
			IF @ToRoleID  = 1
			BEGIN
				SELECT @BalanceAmount = @amount * @ExchangeRate
				--EXEC Dot_BalanceUpdDebit @CustID = @ToCustID, @balance = @BalanceAmount 
							EXEC Dot_BalanceDebitUpd @CustID = @ToCustID, @balance = @BalanceAmount, @Type = 2, @IsForced = 1, @ErrCode = @ErrCode OUTPUT
				if @ErrCode <> 0
				BEGIN
					Select @ErrMsg = case @Language 
								when 'E' then 'Transfer failed. Please try again.'
								when 'CS' then N'Transfer failed. Please try again.'
								when 'J' then N'払戻処理上にエラーが発生しました。もう一度確認してください。'
								else N'Transfer failed. Please try again.'
							end, @ErrCode = 104
					--- rollback @FromCustID
					IF @FromRoleID  = 1
					BEGIN
						--EXEC Dot_BalanceUpdDebit @CustID = @FromCustID, @balance = @amount 
											EXEC Dot_BalanceDebitUpd @CustID = @FromCustID, @balance = @amount, @Type = 2, @IsForced = 1
					END 

					delete bettrans 
					where custid in (@FromCustID, @ToCustID)
						and refno = @refno 
						and matchid = 0
						and bettype = 21003		

					delete Transfer_Coll
					where  custid in (@FromCustID, @ToCustID)
					and refno = @refno  
					and bettype = 21003			
				
					return
				END
			END
			
			--- Inseret into bettrans
			INSERT INTO bettrans 
				(creator, custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
				 status, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
				 scomm, swinlost,ip,statusID, OddsId)
			VALUES (@UserID, @ToCustID, @ToUsername, @refno, @Transdate, 0, 21003, 'From Customer: ' + @FromUserName + '('+ @Remark +')' + @RemarkFromCurr, 0, @amount * @ExchangeRate, 
				 'Completed', 1, @winlostdate, @ToCurr, @ToActualrate, @ToCurrName, @ToRecommend, @ToMrecommend, @ToSrecommend, 
				 0, 0,@ip,131, @IsCollection)
				 
			SELECT 	@TransID = @@Identity 			
				 
			if @@Error <> 0
			BEGIN
				Select @ErrMsg = case @Language 
							when 'E' then 'Transfer failed. Please try again.'
							when 'CS' then N'Transfer failed. Please try again.'
							when 'J' then N'払戻処理上にエラーが発生しました。もう一度確認してください。'
							else N'Transfer failed. Please try again.'
						end, @ErrCode = 104
				--- rollback @FromCustID
				IF @FromRoleID  = 1
				BEGIN
					--EXEC Dot_BalanceUpdDebit @CustID = @FromCustID, @balance = @amount 
									EXEC Dot_BalanceDebitUpd @CustID = @FromCustID, @balance = @amount, @Type = 2, @IsForced = 1
				END 

				delete bettrans 
				where custid in (@FromCustID, @ToCustID)
					and refno = @refno 
					and matchid = 0
					and bettype = 21003
					
				delete Transfer_Coll
				where  custid in (@FromCustID, @ToCustID)
					and refno = @refno  
					and bettype = 21003

				--- rollback @ToCustID
				IF @ToRoleID  = 1
				BEGIN
					SELECT @BalanceAmount = @amount * @ExchangeRate
					--EXEC Dot_BalanceUpdCredit @CustID = @ToCustID, @balance = @BalanceAmount 
					EXEC Dot_BalanceCreditUpd @CustID = @ToCustID, @balance = @BalanceAmount, @Type = 2
				END
				
				return
			END	

			---Insert into Transfer_Coll
			INSERT INTO Transfer_Coll 
				( CustId, WinlostDate, TransDate, Bettype, Debit, Credit, Currency, ActualRate, 
				TransID, RefNo, Username, Recommend, MRecommend, SRecommend, 
				Creator ,TransDesc, IP )
			SELECT CustId, WinlostDate, TransDate, Bettype, Actual_Stake, Winlost, Currency, ActualRate, 
				TransID, RefNo, Username, Recommend, MRecommend, SRecommend, 
				Creator ,TransDesc, IP
			FROM dbo.Bettrans WITH (NOLOCK) 
			WHERE TransID = @TransID
						
				 
			if @@Error <> 0
			BEGIN
				Select @ErrMsg = case @Language 
							when 'E' then 'Transfer failed. Please try again.'
							when 'CS' then N'Transfer failed. Please try again.'
							when 'J' then N'払戻処理上にエラーが発生しました。もう一度確認してください。'
							else N'Transfer failed. Please try again.'
						end, @ErrCode = 103		
				
				delete bettrans 
				where custid in (@FromCustID, @ToCustID)
					and refno = @refno 
					and matchid = 0
					and bettype = 21003
				
				delete Transfer_Coll
				where  custid in (@FromCustID, @ToCustID)
					and refno = @refno  
					and bettype = 21003
					
				return
			END					
		
			Select @LogData = 'Transfer from Customer ' + @FromUserName + ' to Customer ' + @ToUserName + ' with amount ' + convert(varchar(20), @Amt) + ' Ref.No ' + convert(varchar(20), @refno)
			
		END
		ELSE
		BEGIN
			SET @amount = abs(@amount)
		
			----update balance Debit
			IF @FromRoleID  = 1
			BEGIN
				--EXEC Dot_BalanceUpdDebit @CustID = @FromCustID, @balance = @amount 
							EXEC Dot_BalanceDebitUpd @CustID = @FromCustID, @balance = @amount, @Type = 2, @IsForced = 1, @ErrCode = @ErrCode OUTPUT
				if @ErrCode <> 0
				BEGIN
					Select @ErrMsg = case @Language 
								when 'E' then 'Transfer failed. Please try again.'
								when 'CS' then N'Transfer failed. Please try again.'
								when 'J' then N'払戻処理上にエラーが発生しました。もう一度確認してください。'
								else N'Transfer failed. Please try again.'
							end, @ErrCode = 105					

					return
				END
			END
			
			INSERT INTO bettrans 
				(creator, custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
				 status, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
				 scomm, swinlost,ip,statusID, OddsId)
			VALUES (@UserID, @FromCustID, @FromUsername, @refno, @Transdate, 0, 21003, 'To Customer: ' + @ToUserName + '('+ @Remark +')'+@RemarkToCurr, 0, @amount, 
				 'Completed', 1, @winlostdate, @FromCurr, @FromActualrate, @FromCurrName, @FromRecommend, @FromMrecommend, @FromSrecommend, 
				 0, 0,@ip,131,@IsCollection)
			
			SELECT 	@TransID = @@Identity
			
			if @@Error <> 0
			BEGIN
				Select @ErrMsg = case @Language 
							when 'E' then 'Transfer failed. Please try again.'
							when 'CS' then N'Transfer failed. Please try again.'
							when 'J' then N'払戻処理上にエラーが発生しました。もう一度確認してください。'
							else N'Transfer failed. Please try again.'
						end, @ErrCode = 105
				
				delete bettrans 
				where custid in (@FromCustID, @ToCustID)
					and refno = @refno 
					and matchid = 0
					and bettype = 21003
					
				delete Transfer_Coll
				where  custid in (@FromCustID, @ToCustID)
					and refno = @refno  
					and bettype = 21003
					
				---rollback @FromCustID
				IF @FromRoleID  = 1
				BEGIN
					--EXEC Dot_BalanceUpdCredit @CustID = @FromCustID, @balance = @amount 
					EXEC Dot_BalanceCreditUpd @CustID = @FromCustID, @balance = @amount, @Type = 2
				END

				return
			END
			
			---Insert into Transfer_Coll
			INSERT INTO Transfer_Coll 
				( CustId, WinlostDate, TransDate, Bettype, Debit, Credit, Currency, ActualRate, 
				TransID, RefNo, Username, Recommend, MRecommend, SRecommend, 
				Creator ,TransDesc, IP )
			SELECT CustId, WinlostDate, TransDate, Bettype, Actual_Stake, Winlost, Currency, ActualRate, 
				TransID, RefNo, Username, Recommend, MRecommend, SRecommend, 
				Creator ,TransDesc, IP
			FROM dbo.Bettrans WITH (NOLOCK) 
			WHERE TransID = @TransID
						
				 
			if @@Error <> 0
			BEGIN
				Select @ErrMsg = case @Language 
							when 'E' then 'Transfer failed. Please try again.'
							when 'CS' then N'Transfer failed. Please try again.'
							when 'J' then N'払戻処理上にエラーが発生しました。もう一度確認してください。'
							else N'Transfer failed. Please try again.'
						end, @ErrCode = 103		
				
				delete bettrans 
				where custid in (@FromCustID, @ToCustID)
					and refno = @refno 
					and matchid = 0
					and bettype = 21003
				
				delete Transfer_Coll
				where  custid in (@FromCustID, @ToCustID)
					and refno = @refno  
					and bettype = 21003
					
				return
			END		

			--------------------------------------------------------------

			INSERT INTO bettrans 
				(creator, custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
				 status, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
				 scomm, swinlost,ip,statusID, OddsId)
			VALUES (@UserID, @ToCustID, @ToUsername, @refno, @Transdate, 0, 21003, 'From Customer: ' + @FromUserName + '('+ @Remark +')' + @RemarkFromCurr, @amount * @ExchangeRate, 0, 
				 'Completed', 1, @winlostdate, @ToCurr, @ToActualrate, @ToCurrName, @ToRecommend, @ToMrecommend, @ToSrecommend, 
				 0, 0,@ip,131, @IsCollection)
			
			SELECT 	@TransID = @@Identity
			
			if @@Error <> 0
			BEGIN
				Select @ErrMsg = case @Language 
							when 'E' then 'Transfer failed. Please try again.'
							when 'CS' then N'Transfer failed. Please try again.'
							when 'J' then N'払戻処理上にエラーが発生しました。もう一度確認してください。'
							else N'Transfer failed. Please try again.'
						end, @ErrCode = 106
				
				delete bettrans 
				where custid in (@FromCustID, @ToCustID)
					and refno = @refno 
					and matchid = 0
					and bettype = 21003
					
				delete Transfer_Coll
				where  custid in (@FromCustID, @ToCustID)
					and refno = @refno  
					and bettype = 21003
					
				---rollback @FromCustID
				IF @FromRoleID  = 1
				BEGIN
					--EXEC Dot_BalanceUpdCredit @CustID = @FromCustID, @balance = @amount 
					EXEC Dot_BalanceCreditUpd @CustID = @FromCustID, @balance = @amount, @Type = 2
				END

				return
			END
			
			---Insert into Transfer_Coll
			INSERT INTO Transfer_Coll 
				( CustId, WinlostDate, TransDate, Bettype, Debit, Credit, Currency, ActualRate, 
				TransID, RefNo, Username, Recommend, MRecommend, SRecommend, 
				Creator ,TransDesc, IP )
			SELECT CustId, WinlostDate, TransDate, Bettype, Actual_Stake, Winlost, Currency, ActualRate, 
				TransID, RefNo, Username, Recommend, MRecommend, SRecommend, 
				Creator ,TransDesc, IP
			FROM dbo.Bettrans WITH (NOLOCK) 
			WHERE TransID = @TransID
						
				 
			if @@Error <> 0
			BEGIN
				Select @ErrMsg = case @Language 
							when 'E' then 'Transfer failed. Please try again.'
							when 'CS' then N'Transfer failed. Please try again.'
							when 'J' then N'払戻処理上にエラーが発生しました。もう一度確認してください。'
							else N'Transfer failed. Please try again.'
						end, @ErrCode = 103		
				
				delete bettrans 
				where custid in (@FromCustID, @ToCustID)
					and refno = @refno 
					and matchid = 0
					and bettype = 21003
				
				delete Transfer_Coll
				where  custid in (@FromCustID, @ToCustID)
					and refno = @refno  
					and bettype = 21003
					
				return
			END		

			----update balance Credit
			IF @ToRoleID  = 1
			BEGIN
				SELECT @BalanceAmount = @amount * @ExchangeRate 
				--EXEC Dot_BalanceUpdCredit @CustID = @ToCustID, @balance = @BalanceAmount 
				EXEC Dot_BalanceCreditUpd @CustID = @ToCustID, @balance = @BalanceAmount, @Type = 2
			END
					
			Select @LogData = 'Transfer from Customer ' + @ToUserName + ' to Customer ' + @FromUserName + ' with amount ' + convert(varchar(20), @Amt) + ' Ref.No ' + convert(varchar(20), @refno)
			
		END
		
	IF @IsCollection = 1 
	BEGIN 
		SELECT @LogData = @LogData + ' is Credit Collection'
	END
	-- reset yesterday balance for live casino	(only transfer on the same line)			
	IF (@FromRoleID  = 1 AND @ToCustID IN (@FromRecommend, @FromMrecommend, @FromSrecommend)) OR 
		(@ToRoleID  = 1 AND @FromCustID IN (@ToRecommend, @ToMrecommend, @ToSrecommend))
	BEGIN	
		DECLARE @isResetYesterdayBalance BIT, @ErrCode_ResetYesterdayBalance BIT, @YesterdayBalance MONEY
		
		IF @FromRoleID = 1		
									EXEC Acc_BalanceGameResetYesterday @CustID = @FromCustID, @isResetYesterdayBalance = @isResetYesterdayBalance OUTPUT, @YesterdayBalance = @YesterdayBalance	 OUTPUT, @ErrCode = @ErrCode_ResetYesterdayBalance OUTPUT	
		ELSE		
									EXEC Acc_BalanceGameResetYesterday @CustID = @ToCustID, @isResetYesterdayBalance = @isResetYesterdayBalance OUTPUT, @YesterdayBalance = @YesterdayBalance	 OUTPUT, @ErrCode = @ErrCode_ResetYesterdayBalance OUTPUT	
			
		Select @LogData = @LogData + CASE WHEN @isResetYesterdayBalance = 1 THEN 
											CASE WHEN @ErrCode_ResetYesterdayBalance = 0 THEN '. (ResetGameBalance = suscess, YesterdayBalance =' + CAST(@YesterdayBalance AS VARCHAR(50)) + ')' 
											ELSE '. (ResetGameBalance = fail)' END		
									ELSE '' END			
	END
		
	--Write Log : Invalid Exchange Rate @Phuong20081023
	EXEC dbo.Acc_ExchangeRateCheckValid @FromExchangeID = @FromCurr, @ToExchangeID = @ToCurr, @ExchangeRate = @ExchangeRate,
													  @UserID = @UserID , @FromCust = @FromCustID, @ToCust = @ToCustID, @Amount = @Amt, @transDate =@transdate ,@refNo = @refno

	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @FromCustID, @ToCustID = @ToCustID, @IP = @IP, @Doing = @LogData
	END TRY
	BEGIN CATCH
		Select @LogData = @LogData + ' ErrMsg=' + error_message()
		EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @FromCustID, @ToCustID = @ToCustID, @IP = @IP, @Doing = @LogData
	END CATCH
END
GO
GRANT EXECUTE ON [dbo].[Acc_BettransInsTransfer] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransInsTransfer] TO [ITVivi] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransInsTransfer] TO [vnteam] AS [dbo]