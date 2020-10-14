/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_Int_BettransInsTransactionWithoutLog_Cust]
	@amount				MONEY,	
	@custid				INT,
	@bal_custid			INT,	
	@transdesc			NVARCHAR(300),
	@transid			BIGINT				=	0			OUTPUT,	
	@ErrCode			INT					=	0			OUTPUT,
	@ErrMsg				NVARCHAR(200)		=	''			OUTPUT,
	@bettype			SMALLINT			=	22001,
	@IsCharge			BIT					=	0,
	@ip					NVARCHAR(15)		=	'',
	@RefNo				BIGINT				=	0			OUTPUT,
	@ExchangeRate		SMALLMONEY			=	1,
	@bal_transid		BIGINT				=	0			OUTPUT,
	@balance			MONEY				=	0			OUTPUT,
	@betcheck			VARCHAR(50)			=	'',
	@TheirPartyType		INT					=	1,
	@transdate			DATETIME			=	NULL		OUTPUT,
    @BonusID            INT                 = 	NULL
AS
/*
Creator : Thien
Date : 2007-11-23
Task : record all kinds of transactions for Deposit sites
DB: DBTXN/bodb02
User: API Licensee/12Bet

Revision:
	- V2_20080623: Add @bettype param to handle all kinds of transactions
	- 20080906: + Transfer between dummies and Adjustment will use 111-bettype
				+ Add @ExchangeRate to support transfer with different currency accounts
	- 20080916: add @bal_transid
	- 20100310@Thien: remove CustBetCreditUpdResync
	- 20100521@viet: Update for Bettrans.StatusID
	- 20101007@Henry: Change column transid from INT to BIGINT
	- 20101224@Johnson: Apply new arrange of bettype
	- 20120523@Jamie: Update BalanceCredit/Debit table 
	- 20121106@Viet: revise sp
	- 20121117@Viet: add @betcheck, requested by Eddie
	- 20130129@Viet: block cross currency transfers.
	- 20130704@Benson: add @TheirPartyType Parameter for input
	- 20131007@Benson: modify @transdate for output
	- 20131108@Elodie: Splitting bodb02 into CustDB (call Exchange, CustInfo, Customer by link database)
	- 20140512@Elodie: hot fix, amend the SP to include @translogCredit (for Keno product)
	- 20140827@Don: Rearrange the hardcode about transfer bet types of 3rd party products
	- 20141009@Don: Writelog for deposit transfer
	- 20150203@Don: Use "try catch" to catch errors when adding real transaction
	- 20150206@Don: Add more checkpoints to check if there are something wrong when getting Refno number
	- 20150303@Don: Add more checkpoints to check if there are something wrong when updating customer's balance and adding real transaction
	- 20150606@Kathy: Migrate custDB to new server DBCust. Get cust info from DBCust.CustDB in case of replication problem  [Redmine:#36216]		
	- 20150808@Elodie: Balance Improvement [Redmine:#40125]	
	- 20151022@Elodie: Set @IsForced = 1 if is is charge transation
	- 20151106@Cooper: remove hardcode value = 1 for temporary
	- 20151120@Francis: remove unecessary log values, remove calling linkserver DBLOG and return log params
	- 20160118@Kathy: get balance from bettransRNG & bettransLC [Redmine:#50674]
	- 20170110@Walter: Insert before balance into bettrans.balance
	- 20171102:Patrick: Can't make transfer/withdrawal during MB/BU time [Redmine:#82768]
	- 20170815@Bobby: 80775 - Update bonus info when depositing cash to join into bonus program
	- 20180514@Patrick: Remove check deposit case during MBU process
	- 20180913@Dominic: Add a new bettype (23203) to transfer money for dormant members in deposit archive process [Redmine:#99882]
	- 20190705@Bobby: Add Rebate Bonus [RedmineID: #116358]
	- 20190710@Jamie: Check Bonus wallet if a member is joining a Bonus campaign [Redmine:#116273]
	- 20201014@Danny: Convert Ipv6 to dummy IPv4 [Redmine: #143323]

Param's Explanation:
@bal_custid: Custid of "Balance" (dummy) account to record opposite value for transaction
				For ex: 12BetManilaBankUS$, 12BetNetellerGBP
	
		Full structure of balance accounts:
		--ACC Super		12BETSuperUS$		12BETSuperEURO
		--ACC Master	12BetACCUS$			12BetACCEURO
		--ACC Agent		12BetACCUS$01		12BetACCEURO01

		--ACC Member	12BETMBankUS$		12BETMBankEURO

@amount:
	Deposit, Withdrawal, Bonus: positive value
	Adjustment: can be either positive or negative, depend on the inputted amount
	TRANSFER BETWEEN IBC AND THIRD PARTY SYSTEM: negative --> transfer to third party; positive: transfer from third-party
		
@bettype:
	22001: DEPOSIT
	22002: WITHDRAWAL
	22004: BONUS
	21003: ADJUSTMENT
	22005: TRANSFER
	22006: TRANSFER BETWEEN IBC AND THIRD PARTY SYSTEM (For Playtech and AsiaBet88)
	23203: TRANSFER MONEY FOR DORMANT MEMBERS IN DEPOSIT ARCHIVE PROCESS
	22202: DBONRTRA - Rebate Bonus Transfer 
	22203: DBONRADJ - Rebate Bonus Adjustment
	
@ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Specific Error.
	
@ErrMsg: Error description.

@IsCharge:
	= 1: is charge transation, so not check the negative balance

*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE 
		 @LogActionID			INT
		,@Count					INT
		
	SELECT @LogActionID = 2900
	
	select @ip = dbo.f_ConvertIPv6ToDummy(@ip)		
	
	DECLARE @username			VARCHAR(50),
		@currency				TINYINT,
		@currencyName			VARCHAR(5),
		--@transdate				DATETIME,
		@beforebalance			MONEY,
		@postbalance			MONEY,
		@actualrate				FLOAT,
		@winlost				MONEY,
		@actual_stake			MONEY,
		@tmpAmount				MONEY,
		@mrecommend				INT,
		@recommend				INT,
		@srecommend				INT,
		@roleid					TINYINT,
		
		--Balance Account info
		@bal_mrecommend			INT,
		@bal_recommend			INT,
		@bal_srecommend			INT,
		@bal_Username			VARCHAR(50),
		@bal_currency			TINYINT,
		@bal_actualrate			FLOAT,
		@bal_currencyName		NVARCHAR(5),
		@translogCredit			MONEY,

		@DDEP					SMALLINT,
		@DWIT					SMALLINT,
		@DBON					SMALLINT,
		@DADJ					SMALLINT,
		@DTRA					SMALLINT,
		@DTRAARC				SMALLINT,
		@DTRATP					SMALLINT,

		@BalanceType			TINYINT,
		@IsForced				BIT,
		@balance_bettransRNG	MONEY,
		@balance_bettransLC		MONEY,
		@WalletType				TINYINT,
		@BonusWalletFlag		BIT,
		-- Rebate bonus
		@DBONRTRA				SMALLINT,
		@DBONRADJ				SMALLINT

	SELECT	@ErrCode		= 0,
			@ErrMsg			= '',
			@RefNo			= ISNULL(@RefNo, 0),
			@amount			= @amount,

			@DADJ			= 21003,
			@DDEP			= 22001,
			@DWIT			= 22002,
			@DBON			= 22004,
			@DTRA			= 22005,
			@DTRAARC		= 23203,
			@DBONRTRA		= 22202,
			@DBONRADJ		= 22203,
			@WalletType = CASE	WHEN @bettype IN (@DBONRTRA, @DBONRADJ) THEN 1 -- Rebate bonus
									WHEN @BonusID > 0 THEN 2
									ELSE NULL END,
			@BonusWalletFlag = 0 

	/*
	22006  Playtech casino transfer
	22008  Hogaming transfer
	22010  OPus transfer
	*/

	SELECT @DTRATP = 0

	SELECT @DTRATP=TransferBettype
	FROM dbo.ThirdPartySetting
	WHERE ThirdPartyType=@TheirPartyType

	/* === remove by darren===
	SET  @DTRATP =
	CASE
		WHEN @TheirPartyType = 1 THEN 22006
		WHEN @TheirPartyType = 2 THEN 22008
		WHEN @TheirPartyType = 3  THEN 22010
			ELSE 0
	END
	*/
	IF @DTRATP = 0
	BEGIN
		SELECT @ErrMsg = 'Sorry, transfer get DTRATP error !!.', @ErrCode = 108	
		RETURN
	END

	SELECT @bettype = 
		CASE @bettype 
			WHEN 103 THEN 21003 
			WHEN 107 THEN 22001 
			WHEN 108 THEN 22002
			WHEN 110 THEN 22004
			WHEN 111 THEN 22005
			WHEN 115 THEN 22006
			ELSE @bettype
		END	
	
	If @bettype IN (22006, 22010, 22014, 22016, 22018, 22008, 22020) --TRANSFER BETWEEN IBC AND THIRD PARTY SYSTEM, USE @BalanceType = 3
		SELECT @BalanceType = 3
	ELSE
		SELECT @BalanceType = 2

	IF @amount = 0
	BEGIN
		SELECT @ErrMsg = 'Sorry, amount is invalid.', @ErrCode = 101	
		RETURN		
	END

	SELECT @username = username
		,@currency = ci.currency
		,@currencyName = e.currency
		,@actualrate = e.actualrate
		,@mrecommend = mrecommend
		,@recommend = recommend
		,@srecommend = srecommend
		,@roleid = roleid
		,@BonusWalletFlag = ISNULL(BonusWalletFlag,0) 
	FROM CustDB.dbo.custinfo AS ci WITH (NOLOCK)
	INNER JOIN CustDB.dbo.exchange AS e WITH (NOLOCK) ON ci.currency = e.exchangeid
	WHERE ci.custid = @custid

	IF @@rowcount = 0
	BEGIN
		SELECT @username = username
			,@currency = ci.currency
			,@currencyName = e.currency
			,@actualrate = e.actualrate
			,@mrecommend = mrecommend
			,@recommend = recommend
			,@srecommend = srecommend
			,@roleid = roleid
			,@BonusWalletFlag = ISNULL(BonusWalletFlag,0) 
		FROM DBCUST.CustDB.dbo.custinfo AS ci WITH (NOLOCK)
		INNER JOIN DBCUST.CustDB.dbo.exchange AS e WITH (NOLOCK) ON ci.currency = e.exchangeid
		WHERE ci.custid = @custid
	END


	SELECT @transdesc = @username + ' - ' +
						CASE @bettype 
							WHEN @DDEP THEN 'Deposit'
							WHEN @DWIT THEN 'Withdraw'
							WHEN @DBON THEN 'Bonus'
							WHEN @DADJ THEN 'Adjustment'
							WHEN @DTRA THEN 'Transfer'
							WHEN @DTRAARC THEN 'Transfer'
							when @DBONRTRA THEN 'Bonus'
							when @DBONRADJ THEN 'Bonus'
							WHEN @DTRATP THEN
									CASE 
										WHEN (@amount >0) THEN 'Transfer from third party' 
										ELSE 'Transfer to third party' 
									END
							ELSE '' 
						END
					+ CASE WHEN @transdesc <> '' THEN ' - ' + @transdesc END

	SELECT 
		@winlost = CASE 
			WHEN @bettype  IN (@DDEP, @DBON, @DTRA, @DTRAARC, @DADJ, @DTRATP, @DBONRTRA, @DBONRADJ) THEN @amount 
			ELSE 0 END,
		@actual_stake = CASE @bettype WHEN @DWIT THEN ABS(@amount) ELSE 0 END

	IF @winlost < 0 --then swap the winlost and actual_stake
	BEGIN	
		SELECT @actual_stake = -@winlost,  @winlost = 0	
	END

	IF @roleid <> 1
	BEGIN
		SELECT @ErrMsg = 'Invalid Role ID.', @ErrCode = 102		
		RETURN
	END

	IF (@bettype = @DWIT AND @IsCharge = 0) OR (@bettype = @DTRATP AND @amount < 0) --only check when not Charge transaction, and is Withdrawal
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
	END
	----------------------------------
	--Check enough balance for withdrawing
	SELECT @balance = SUM(winlost-actual_stake+playercomm) FROM dbo.bettrans WITH(NOLOCK) WHERE custid = @custid
	SELECT @balance = ISNULL(@balance, 0)

	SELECT @translogCredit = ISNULL(SUM(ISNULL(actual_stake,0)) ,0)
	FROM dbo.translog WITH(NOLOCK) 
	WHERE custid=@custid AND statusID=0	
	
	SELECT	@balance_bettransRNG = SUM(winlost - actual_stake + playercomm)
	FROM	dbo.bettransRnG WITH(NOLOCK)
	WHERE	custid = @custID 
			AND IsSum=0
			
	SELECT	@balance_bettransLC = SUM(winlost - actual_stake + playercomm)
	FROM	dbo.bettransLC WITH(NOLOCK)
	WHERE	custid = @custID 
			AND IsSum=0
	
	IF (@bettype = @DWIT AND @IsCharge = 0) OR (@bettype = @DTRATP AND @amount < 0) --only check when not Charge transaction, and is Withdrawal
	BEGIN
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
	END

	SELECT @balance_bettransRNG = ISNULL(@balance_bettransRNG,0)
			,@balance_bettransLC = ISNULL(@balance_bettransLC,0)

	SELECT @beforebalance = @balance + @balance_bettransRNG + @balance_bettransLC  - @translogCredit
	SELECT @postbalance = @balance + @balance_bettransRNG + @balance_bettransLC + @winlost - @actual_stake - @translogCredit

	IF (@bettype=@DWIT AND @IsCharge = 0) OR (@bettype=@DTRATP AND @amount < 0) --only check when not Charge transaction, and is Withdrawal
	BEGIN
		----------------------------------------------------------
		--- Check Member's Balance for WITHDRAWAL or TRANSFER OUT 
		----------------------------------------------------------	
		IF @postbalance < 0
		BEGIN
			SELECT @ErrMsg = 
				CASE @bettype 
					WHEN @DWIT THEN 'Sorry, you do not have enough money to withdraw.'
					ELSE 'Sorry, you do not have enough money to trasfer out.' 
				END, @ErrCode = 103
			RETURN
		END
		----------------------------------
		-- Check Bonus Wallet 
		----------------------------------
		DECLARE @FinalBalance	MONEY
		DECLARE @BonusAmount	MONEY
		SELECT	@FinalBalance	= 0,
				@BonusAmount	= 0  
		IF @BonusWalletFlag = 1
		BEGIN
			EXEC dbo.Dot_BalanceMemberSel @CustID = @CustID, @Balance = @FinalBalance OUT, @BonusWalletFlag = @BonusWalletFlag, @Amount = @BonusAmount OUT 

			IF (@postbalance-@BonusAmount) <0 
			BEGIN
				SELECT @ErrMsg = 
					CASE @bettype 
						WHEN @DWIT THEN 'Sorry, you do not have enough money to withdraw.'
						ELSE 'Sorry, you do not have enough money to trasfer out.' 
					END, @ErrCode = 201
				RETURN
			END
		END
		------------------------------

	END
	----------------------------------

	----------------------------------
	--Check balance Account

	SELECT		@bal_custid = c.custid, @bal_Username = c.username,
				@bal_mrecommend = c.mrecommend, @bal_recommend = c.recommend, @bal_srecommend = c.srecommend,
				@bal_currency = c.currency, @bal_actualrate = e.actualrate, @bal_currencyName = e.currency
	FROM CustDB.dbo.customer c WITH(NOLOCK)
		INNER JOIN CustDB.dbo.exchange AS e ON c.currency = e.exchangeid
	WHERE c.custid = @bal_custid
	
	IF @@rowcount = 0
	BEGIN
		SELECT		@bal_custid = c.custid, @bal_Username = c.username,
					@bal_mrecommend = c.mrecommend, @bal_recommend = c.recommend, @bal_srecommend = c.srecommend,
					@bal_currency = c.currency, @bal_actualrate = e.actualrate, @bal_currencyName = e.currency
		FROM DBCUST.CustDB.dbo.customer c WITH(NOLOCK)
			INNER JOIN DBCUST.CustDB.dbo.exchange AS e ON c.currency = e.exchangeid
		WHERE c.custid = @bal_custid
	END

	IF @bal_mrecommend IS NULL 
	BEGIN
		SELECT @ErrMSg = 'Invalid balance account.', @ErrCode = 104			
		RETURN
	END

	--- 20130129@Viet: block cross currency transfers. ----
	IF @currencyName <> @bal_currencyName
	BEGIN
		SELECT @ErrMSg = 'Sorry, cross currency transfers are not allowed!', @ErrCode = 107
		RETURN
	END
	---------------------------------------------

	IF @IsCharge = 1 -- 1: is charge transation, so not check the negative balance
		SELECT @IsForced = 1
	ELSE 
		SELECT @IsForced = 0

	BEGIN TRY
		SELECT @Count = 0
		------------------Insert trans into DB---------------------------------------------------------------
		IF @RefNo = 0
		BEGIN
			EXEC dbo.Acc_SelRefNo @RefNo = @RefNo OUTPUT
			SELECT @RefNo = @RefNo + 100000000000
		END
		
		----------------------------------
		---- Checking the balance of customer before updating the amount on Credit or Debit table 

		DECLARE @Cust_Balance MONEY,
				@Cust_Balance_ABS MONEY

		SELECT	@Cust_Balance = @winlost - @actual_stake
		SELECT	@Cust_Balance_ABS = abs(@Cust_Balance)		

		SELECT @Count = 1
		--Update BalanceDebit 
		IF @Cust_Balance < 0 
		BEGIN
			--EXEC dbo.Dot_BalanceUpdDebit @custid = @CustID, @Balance = @Cust_Balance_ABS
			EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @Cust_balance_ABS, @type = @BalanceType, @IsForced = @IsForced, @errCode = @ErrCode OUTPUT
			IF @ErrCode <> 0
			BEGIN
				SELECT	@ErrCode = 105	
						,@ErrMsg = 'Insert transaction failed.' + ' STEP: ' + CONVERT(NVARCHAR(1), @Count) + '. ERROR_MESSAGE: Update balance failed'  + ' - ERROR_NUMBER: ' + CONVERT(VARCHAR(20), @ErrCode)
				RETURN
			END
		END 

		SELECT @transdate = CURRENT_TIMESTAMP
		
		SELECT @Count = 2
		INSERT INTO dbo.bettrans 
			(custid, username, refno, transdate, matchid, bettype, transdesc,winlost, actual_stake, winlostdate, balance,
			 creator,recommend,mrecommend,srecommend,currency,actualrate, currencyName, ruben, status, statusID,ip, betcheck, WalletType,BonusID)
		VALUES 
			(@CustID, @username, @RefNo, @transdate, 0, @bettype, @transdesc,@winlost, @actual_stake, CONVERT(NVARCHAR(10), @transdate, 120), @beforebalance,
			 @CustID, @Recommend, @MRecommend, @SRecommend, @Currency,@actualrate, @currencyName, 1, 'Completed', 131,@ip, @betcheck,@WalletType,@BonusID)
	END TRY
	BEGIN CATCH
		--Manually rollback
		DELETE FROM dbo.bettrans 
		WHERE custid = @custid 
			AND refno = @RefNo 
			AND matchid = 0
			AND bettype = @bettype
		
		SELECT 
			@ErrCode = 105	
			,@ErrMsg = 'Insert transaction failed.' + ' STEP: ' + CONVERT(NVARCHAR(1), @Count) + '. ERROR_MESSAGE: ' + CONVERT(NVARCHAR(100), LEFT(ERROR_MESSAGE(),100)) + ' - ERROR_NUMBER: ' + CONVERT(VARCHAR(20), ERROR_NUMBER())

		--Rollback BalanceDebit 
		IF @Cust_balance < 0 
		BEGIN 
			--EXEC dbo.Dot_BalanceUpdCredit @custid = @CustID, @Balance = @Cust_Balance_ABS
			EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_Balance_ABS, @type = @BalanceType
		END 
		RETURN
	END CATCH
	
	SELECT @TransID = @@IDENTITY

	IF @Cust_Balance > 0  --Update BalanceCredit 
	BEGIN
		--EXEC dbo.Dot_BalanceUpdCredit @custid = @CustID, @Balance = @Cust_Balance
		EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_Balance, @type = @BalanceType
	END 

	----ADD DUMMY TRANSACTION
	INSERT INTO dbo.bettrans 
		(custid, username, refno, transdate, matchid, bettype, transdesc,winlost, actual_stake, winlostdate, balance,
		 creator,recommend,mrecommend,srecommend,currency,actualrate, currencyName, ruben, status, statusID,ip, WalletType,BonusID)
	VALUES 
		(@bal_custID, @bal_Username, @RefNo, @transdate, 0, @bettype, @transdesc, @actual_stake * @ExchangeRate, @winlost * @ExchangeRate, CONVERT(NVARCHAR(10), @transdate, 120), @beforebalance,
		 @CustID, @bal_recommend, @bal_mrecommend, @bal_srecommend, @bal_currency, @bal_actualrate, @bal_currencyName, 1, 'Completed', 131,@ip,@WalletType,@BonusID)
		 
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 106
		
		--Manually rollback
		DELETE FROM dbo.bettrans 
		WHERE custid IN (@custid, @bal_custID) 
			AND refno = @RefNo 
			AND matchid = 0
			AND bettype = @bettype

		--Rollback Balance Table  
		IF @Cust_balance < 0  --Rollback BalanceDebit 
		BEGIN 
			--EXEC dbo.Dot_BalanceUpdCredit @custid = @CustID, @Balance = @Cust_Balance_ABS
			EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_Balance_ABS, @type = @BalanceType
		END 
		ELSE  --Rollback BalanceCredit 
		BEGIN
			--EXEC dbo.Dot_BalanceUpdDebit @custid = @CustID, @Balance = @Cust_Balance
			EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @Cust_Balance, @type = @BalanceType, @IsForced = 1
		END	
		RETURN
	END
	ELSE
	BEGIN
		SELECT @balance = @postbalance
	END
	
	SELECT @bal_transid = @@IDENTITY
	SET @transdate = CONVERT(CHAR(8),@transdate,112)
	---------------------------------------------------------------------------------------------------

	DECLARE @LogData VARCHAR(300)

	SELECT @LogData = 
				'Insert trans custid = ' + CONVERT(VARCHAR(20), @custid) + ', bettype = ' + CONVERT(VARCHAR(20), @bettype) + ', amount = ' + CONVERT(VARCHAR(20), @amount) 
				+ CASE WHEN @BonusId > 0 THEN ', bonusId = ' + convert(varchar(20), @BonusId) ELSE '' END

	EXEC dbo.WriteLog_UserLog @UserID = @custid, @Doing = @LogData

END
GO