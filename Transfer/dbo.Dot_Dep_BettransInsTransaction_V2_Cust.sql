/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member,Dot_Bonus" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  [dbo].[Dot_Dep_BettransInsTransaction_V2_Cust] 
	@amount money,	
	@custid int,
	@bal_custid int,	
	@transdesc nvarchar(300),
	@transid bigint = 0 OUTPUT,	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@bettype smallint = 22001,
	@IsCharge bit = 0,	
	@ip	nvarchar(15)='',
	@RefNo bigint = 0 OUTPUT,
	@ExchangeRate smallmoney = 1,
	@bal_transid bigint = 0 OUTPUT,
	@transdate DateTime = NULL OUTPUT,
	@BetCheck NVARCHAR(50) = NULL,
	@BonusID INT = NULL

AS
/*
Creator : Thien
Date : 2007-11-23
Task : record all kinds of transactions for Deposit sites
DB: DBTXN/bodb02
User: NON API Licensee/12Bet

History:
	- V2_20080623: Add @bettype param to handle all kinds of transactions
	- 20080906: + Transfer between dummies and Adjustment will use 111-bettype
				+ Add @ExchangeRate to support transfer with different currency accounts
	- 20080916: add @bal_transid
	- 20081202: Affiliate A refer member Z, member Z got 500 bonus, this bonus to be deducted from Affiliate A. 
	- 20090414: @VietHoang: Update case BONUS with negative value (In order to get money back in case we found bonus fraud).
	- 20100219@Viet: Fix bonus deduction for Affiliates' trouble.
	- 20100310@Thien: remove CustBetCreditUpdResync
	- 20100521@viet: Update for Bettrans.StatusID
	- 20100908@Vivi: add try catch for wirte userlog
	- 20101007@Henry: Change column transid from INT to BIGINT
	- 20101224@Johnson: Apply new arrange of bettype
	- 20111031@Sophia: Update balance for customer
	- 20120412@Sophia: Revise update balance for customer
	- 20130129@Viet: block cross currency transfers.
	- 20131108@Elodie: Splitting bodb02 into CustDB (call Exchange, CustInfo, Customer by link database)
	- 20140512@Elodie: hot fix, amend the SP to include @translogCredit (for Keno product)
	- 20141029@KevinLin: modify @transdate for output
	- 20150606@Kathy: Migrate custDB to new server DBCust. Get cust info from DBCust.CustDB in case of replication problem  [Redmine:#36216]		
	- 20150808@Elodie: Balance Improvement [Redmine:#40125]	
	- 20151022@Elodie:	Don't update balance for dummy account
						Set @IsForced = 1 if is is charge transation
	- 20151105@Cooper: set @IsForced = 1 if @bettype in ( 21003 = adjustment , 22004 = bonus adjustment ) and Remove hardcode value = 1 for temporary
	- 20151230@Cooper:add 	IF @RefNo <> 0 Set @IsForced = 1   -- if @Refno <> 0 = Approved action
	- 20160105@Cooper:add bettype 22005 set  @IsForced = 1 for 12bet dummy to dummy transfer 
	- 20160118@Kathy: get balance from bettransRNG & bettransLC [Redmine:#50674]
	- 20160921@Scott(DBTrans): Add @BetCheck of parameter for record Licensee DB transation ID.
	- 20171102:Patrick: Can't make transfer/withdrawal during MB/BU time [Redmine:#82768]
	- 20170815@Bobby: 80775 - Update bonus info when depositing cash to join into bonus program

Param's Explanation:
? @bal_custid: Custid of "Balance" (dummy) account to record opposite value for transaction
				For ex: 12BetManilaBankUS$, 12BetNetellerGBP
	
		Full structure of balance accounts:
		--ACC Super		12BETSuperUS$		12BETSuperEURO
		--ACC Master	12BetACCUS$			12BetACCEURO
		--ACC Agent		12BetACCUS$01		12BetACCEURO01

		--ACC Member	12BETMBankUS$		12BETMBankEURO

? @amount:
	Deposit, Withdrawal, Bonus: positive value
	Adjustment: can be either positive or negative, depend on the inputted amount

? @bettype:
		
	22001: DEPOSIT
	22002: WITHDRAWAL
	22004: BONUS
	21003: ADJUSTMENT
	22005: TRANSFER
	22006: TRANSFER BETWEEN IBC AND THIRD PARTY SYSTEM (For Playtech and AsiaBet88)
	
	
? @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Specific Error.
	
? @ErrMsg: Error description.

? @IsCharge:
	= 1: is charge transation, so not check the negative balance

*/
SET NOCOUNT ON


--------------------------------

declare @username varchar(50),
	@currency tinyint,
	@currencyName varchar(5),
	-- @transdate datetime,	
	@actualrate float,
	@winlost money,	
	@actual_stake money,
	@tmpAmount money,
	@mrecommend int,
	@recommend int,
	@srecommend int,
	@roleid tinyint,
	@balance money,
	
	--Balance Account info
	@bal_mrecommend int,
	@bal_recommend int,
	@bal_srecommend int,
	@bal_Username varchar(50),
	@bal_currency tinyint,
	@bal_actualrate float,
	@bal_currencyName nvarchar(5),

	@DDEP smallint,
	@DWIT smallint,
	@DBON smallint,
	@DADJ smallint,
	@DTRA smallint,
	@Cust_balance money,
	@Cust_balance_ABS money,
	@bal_balance money,
	@bal_balance_ABS money,
	@translogCredit money,
	@IsForced BIT,
	@balance_bettransRNG	MONEY,
	@balance_bettransLC		MONEY,
	@WalletType TINYINT


Select @ErrCode = 0,
		@ErrMsg = '',
		@RefNo = isnull(@RefNo,0),
		@amount = @amount,

		@DADJ = 21003,
		@DDEP = 22001,
		@DWIT = 22002,
		@DBON = 22004,
		@DTRA = 22005,
		@WalletType = CASE WHEN @BonusID > 0 THEN 2 ELSE NULL END

select @bettype = 
	case @bettype when 103 then 21003 
		when 107 then 22001 
		when 108 then 22002
		when 110 then 22004
		when 111 then 22005
		when 115 then 22006
		else @bettype
	end

if @amount = 0
BEGIN
	Select @ErrMsg = 'Sorry, amount is invalid.', @ErrCode = 101	
	return		
END

	Select @username = username, @currency = ci.currency, @currencyName = e.currency, @actualrate = e.actualrate,
		@mrecommend = mrecommend, @recommend = recommend, @srecommend = srecommend, @roleid = roleid
	from CustDB.dbo.custinfo as ci with (NOLOCK) 
	INNER JOIN CustDB.dbo.exchange as e with (NOLOCK) on ci.currency = e.exchangeid
	where ci.custid = @custid
	
	IF @@rowcount = 0
	BEGIN
		Select @username = username, @currency = ci.currency, @currencyName = e.currency, @actualrate = e.actualrate,
			@mrecommend = mrecommend, @recommend = recommend, @srecommend = srecommend, @roleid = roleid
		from DBCUST.CustDB.dbo.custinfo as ci with (NOLOCK) 
		INNER JOIN DBCUST.CustDB.dbo.exchange as e with (NOLOCK) on ci.currency = e.exchangeid
		where ci.custid = @custid
	END

	select @transdesc = @username + ' - ' +
						case @bettype when @DDEP then 'Deposit'
										when @DWIT then 'Withdraw'
										when @DBON then 'Bonus'
										when @DADJ then 'Adjustment'
										when @DTRA then 'Transfer'
										else '' end				
					+ case when @transdesc <> '' then ' - ' + @transdesc end

	select 
		@winlost = case when @bettype = @DDEP or @bettype = @DBON or @bettype = @DTRA or @bettype = @DADJ then @amount else 0 end,
		@actual_stake = case @bettype when @DWIT then abs(@amount) else 0 end

	if @winlost < 0 --then swap the winlost and actual_stake
	BEGIN	
		select @actual_stake = -@winlost, @winlost = 0	
	END

	if @roleid <> 1
	BEGIN
		Select @ErrMsg = 'Invalid Role ID.', @ErrCode = 102		
		return
	END

	----------------------------------
	--Check enough balance for withdrawing
	if @bettype=@DWIT
		AND @IsCharge = 0 --only check when not Charge transaction, and is Withdrawal
	BEGIN
		--//1st check: MB/BU is running?
		EXEC dbo.Acc_Core_IsMainProcessRunning
			  @CustId = @custid
			, @UplineId = @recommend
			, @IsDepositMember = 1
			, @ErrCode = @ErrCode OUTPUT
			, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			SELECT @ErrMsg = @ErrMsg, @ErrCode = 333
			RETURN
		END

		select @balance = sum(winlost-actual_stake+playercomm) from bettrans with (NOLOCK) where custid = @custid
		select @balance = isnull(@balance, 0)	
		
		select @translogCredit = isnull(sum(isnull(actual_stake,0)) ,0)
		from translog with (nolock) 
		where custid=@custid and statusID=0	
		
		SELECT	@balance_bettransRNG = SUM(winlost - actual_stake + playercomm)
		FROM	dbo.bettransRnG WITH(NOLOCK)
		WHERE	custid = @custID 
				AND IsSum=0
				
		SELECT	@balance_bettransLC = SUM(winlost - actual_stake + playercomm)
		FROM	dbo.bettransLC WITH(NOLOCK)
		WHERE	custid = @custID 
				AND IsSum=0
		
		--//2nd check: MB/BU is running?
		EXEC dbo.Acc_Core_IsMainProcessRunning
			  @CustId = @custid
			, @UplineId = @recommend
			, @IsDepositMember = 1
			, @ErrCode = @ErrCode OUTPUT
			, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			SELECT @ErrMsg = @ErrMsg, @ErrCode = 333
			RETURN
		END

		SELECT @balance_bettransRNG = ISNULL(@balance_bettransRNG,0)
				,@balance_bettransLC = ISNULL(@balance_bettransLC,0)

		if @balance + @balance_bettransRNG + @balance_bettransLC + @winlost-@actual_stake-@translogCredit<0
		BEGIN
			Select @ErrMsg = 'Sorry, you do not have enough money to withdraw.', @ErrCode = 103				
			return		
		END
	END
	----------------------------------

	----------------------------------
	--Check balance Account

	select @bal_custid = c.custid, @bal_Username = c.username,
		@bal_mrecommend = c.mrecommend, @bal_recommend = c.recommend, @bal_srecommend = c.srecommend,
		@bal_currency = c.currency, @bal_actualrate = e.actualrate, @bal_currencyName = e.currency
	from CustDB.dbo.customer c with (nolock)
	inner join CustDB.dbo.exchange as e with (nolock) on c.currency = e.exchangeid
	where c.custid = @bal_custid
	
	IF @@rowcount = 0
	BEGIN
		select @bal_custid = c.custid, @bal_Username = c.username,
			@bal_mrecommend = c.mrecommend, @bal_recommend = c.recommend, @bal_srecommend = c.srecommend,
			@bal_currency = c.currency, @bal_actualrate = e.actualrate, @bal_currencyName = e.currency
		from DBCUST.CustDB.dbo.customer c with (nolock)
		inner join DBCUST.CustDB.dbo.exchange as e with (nolock) on c.currency = e.exchangeid
		where c.custid = @bal_custid
	END

	if @bal_mrecommend is NULL 
	BEGIN
		Select @ErrMSg = 'Invalid balance account.', @ErrCode = 104			
			return
	END
	----------------------------------

	--- 20130129@Viet: block cross currency transfers. ----
	IF @currencyName <> @bal_currencyName
	BEGIN
		SELECT @ErrMSg = 'Sorry, cross currency transfers are not allowed!', @ErrCode = 107
		RETURN
	END
	---------------------------------------------
	-- 1: is charge transation, so not check the negative balance
	-- 2: @bettype in ( 21003 = adjustment , 22004 = bonus adjustment , 22005 = 12bet dummy to dummy )
	IF @IsCharge = 1 or  @bettype in ( 21003 , 22004 , 22005 )
		SELECT @IsForced = 1
	ELSE 
		SELECT @IsForced = 0

	IF @RefNo <> 0 Set @IsForced = 1   -- if @Refno <> 0 = Approved action
	------------------Insert trans into DB---------------------------------------------------------------
	if @RefNo = 0
	BEGIN	
		EXEC dbo.Acc_SelRefNo @RefNo = @RefNo OUTPUT
		select @RefNo = @RefNo + 100000000000	
	END

	---Update Debit Balance	
	SELECT @Cust_balance = @winlost - @actual_stake
	IF @Cust_balance < 0 
	BEGIN 
		SELECT @Cust_balance_ABS = ABS(@Cust_balance)
		--EXEC Dot_BalanceUpdDebit @custid = @CustID, @Balance = @Cust_balance_ABS
		EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @Cust_balance_ABS, @type = 2, @IsForced = @IsForced, @errCode = @ErrCode OUTPUT
		IF @ErrCode <> 0
		BEGIN
			Select @ErrMsg = 'Insert transaction failed.', @ErrCode = 105	
			return
		END
	END 

	select @transdate = current_timestamp

	INSERT INTO bettrans 
		(custid, username, refno, transdate, matchid, bettype, transdesc,winlost, actual_stake, winlostdate, 
		 creator,recommend,mrecommend,srecommend,currency,actualrate, currencyName, ruben, status, statusID, ip, betcheck, WalletType,BonusID)
	VALUES 
		(@CustID, @username, @RefNo, @transdate, 0, @bettype, @transdesc,@winlost, @actual_stake, convert(nvarchar(10), @transdate, 120), 
		 @CustID, @Recommend, @MRecommend, @SRecommend, @Currency,@actualrate, @currencyName, 1, 'Completed', 131, @ip, @BetCheck,@WalletType,@BonusID)

	if @@ERROR <> 0
	BEGIN						
		Select @ErrMsg = 'Insert transaction failed.', @ErrCode = 105	
		
		--Manually rollback
		DELETE FROM bettrans where refno = @RefNo and matchid = 0 and bettype = @bettype and custid in (@custid, @bal_custID)
		
		--rollback balance
		IF @Cust_balance < 0 
		BEGIN 
			SELECT @Cust_balance_ABS = ABS(@Cust_balance)
			--EXEC Dot_BalanceUpdCredit @custid = @CustID, @Balance = @Cust_balance_ABS
			EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_balance_ABS, @type = 2
		END  
		return
	END
	Select @TransID = @@IDENTITY
	
	---Update Credit Balance	
	IF @Cust_balance > 0 
	BEGIN 
		--EXEC Dot_BalanceUpdCredit @custid = @CustID, @Balance = @Cust_balance
		EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_balance, @type = 2
	END 

---------------------------------------------------------------
	--20151022@Elodie: Don't update balance for dummy account
	---Update Debit Balance	
	--SELECT @bal_balance = @actual_stake * @ExchangeRate - @winlost * @ExchangeRate
	--IF @bal_balance < 0 
	--BEGIN 
	--	SELECT @bal_balance_ABS = ABS(@bal_balance)
	--	--EXEC Dot_BalanceUpdDebit @custid = @bal_custID, @Balance = @bal_balance_ABS
	--	EXEC Dot_BalanceDebitUpd @CustID = @bal_custID, @balance = @bal_balance_ABS, @type = 2, @IsForced = 1, @errCode = @ErrCode OUTPUT
	--	IF @ErrCode <> 0
	--	BEGIN
	--		Select @ErrMsg = 'Insert transaction failed.', @ErrCode = 106
		
	--		--Manually rollback
	--		DELETE FROM bettrans where refno = @RefNo and matchid = 0 and bettype = @bettype and custid in (@custid, @bal_custID)
	--		--rollback balance @CustID
	--		IF @Cust_balance < 0 
	--		BEGIN 
	--			SELECT @Cust_balance_ABS = ABS(@Cust_balance)
	--			--EXEC Dot_BalanceUpdCredit @custid = @CustID, @Balance = @Cust_balance_ABS
	--			EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_balance_ABS, @type = 2
	--		END 
	--		ELSE
	--		IF @Cust_balance > 0 
	--		BEGIN 
	--			--EXEC Dot_BalanceUpdDebit @custid = @CustID, @Balance = @Cust_balance
	--			EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @Cust_balance, @type = 2, @isForced = 1
	--		END 				
	--		return
	--	END
	--END 


	INSERT INTO bettrans 
		(custid, username, refno, transdate, matchid, bettype, transdesc,winlost, actual_stake, winlostdate, 
		 creator,recommend,mrecommend,srecommend,currency,actualrate, currencyName, ruben, status, statusID, ip, WalletType,BonusID)
	VALUES 
		(@bal_custID, @bal_Username, @RefNo, @transdate, 0, @bettype, @transdesc, @actual_stake * @ExchangeRate, @winlost * @ExchangeRate, convert(nvarchar(10), @transdate, 120), 
		 @CustID, @bal_recommend, @bal_mrecommend, @bal_srecommend, @bal_currency, @bal_actualrate, @bal_currencyName, 1, 'Completed', 131, @ip,@WalletType,@BonusID)

	if @@ERROR <> 0
	BEGIN
		Select @ErrMsg = 'Insert transaction failed.', @ErrCode = 106
		
		--Manually rollback
		DELETE FROM bettrans where refno = @RefNo and matchid = 0 and bettype = @bettype and custid in (@custid, @bal_custID)
		--rollback balance @CustID
		IF @Cust_balance < 0 
		BEGIN 
			SELECT @Cust_balance_ABS = ABS(@Cust_balance)
			--EXEC Dot_BalanceUpdCredit @custid = @CustID, @Balance = @Cust_balance_ABS
			EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_balance_ABS, @type = 2
		END 
		ELSE
		IF @Cust_balance > 0 
		BEGIN 
			--EXEC Dot_BalanceUpdDebit @custid = @CustID, @Balance = @Cust_balance
			EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @Cust_balance, @type = 2, @isForced = 1
		END 	
		----rollback balance @bal_custID
		--IF @bal_balance < 0 
		--BEGIN 
		--	SELECT @bal_balance_ABS = ABS(@bal_balance)
		--	--EXEC Dot_BalanceUpdCredit @custid = @bal_custID, @Balance = @bal_balance_ABS
		--	EXEC Dot_BalanceCreditUpd @CustID = @bal_custID, @balance = @bal_balance_ABS, @type = 2
		--END 	
		return
	END
	Select @bal_transid = @@IDENTITY
	SET @transdate = CONVERT(CHAR(30),@transdate, 121)
	
	--20151022@Elodie: Don't update balance for dummy account
	---Update Credit Balance	
	--IF @bal_balance > 0 
	--BEGIN 
	--	--EXEC Dot_BalanceUpdCredit @custid = @bal_custID, @Balance = @bal_balance
	--	EXEC Dot_BalanceCreditUpd @CustID = @bal_custID, @balance = @bal_balance, @type = 2
	--END 

	---------------------------------------------------------------------------------------------------

	declare @LogData varchar(300)

	Select @LogData = 
				'Insert trans custid = ' + convert(varchar(20), @custid) + ', bettype = ' + convert(varchar(20), @bettype) + ', amount = ' + convert(varchar(20), @amount) 
				+ CASE WHEN @BonusId > 0 THEN ', bonusId = ' + convert(varchar(20), @BonusId) ELSE '' END
BEGIN TRY
	EXEC dbo.WriteLog_UserLog @UserID = @custid, @Doing = @LogData
END TRY
BEGIN CATCH
	-- if write log error: not return error code
END CATCH
GO 

