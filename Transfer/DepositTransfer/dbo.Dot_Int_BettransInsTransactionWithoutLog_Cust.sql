/*<info serverAlias="DBSID-bodb02" executers="Svc_Tig,Dot_Evolution" isFunction="0" isNested="1"></info>*/
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
	@ip					VARCHAR(45)		=	'',
	@RefNo				BIGINT				=	0			OUTPUT,
	@ExchangeRate		SMALLMONEY			=	1,
	@bal_transid		BIGINT				=	0			OUTPUT,
	@balance			MONEY				=	0			OUTPUT,
	@betcheck			VARCHAR(50)			=	'',
	@TheirPartyType		INT					=	1,
	@transdate			DATETIME			=	NULL		OUTPUT,
    @BonusID            INT                 = 	NULL,
	@InitialTime		DATETIME			= NULL,
	@DurationLimit		INT					= NULL -- in seconds
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
	- 20210518@Percy: Change code to adapt new Move Bets flow [RedmineID: #154866]
	- 20211111@Sol: Split Transfer out of bettrans/Support IPv6 - [RedmineID: #164301]
	- 20220721@Evan: Integrate new transid [Redmine: #175640]
	- 20220721@Evan: Revise code rollback, get balance from 8 table balance [Redmine: #175297]
	- 20220923@Evan: Revise code rollback (issue) [Redmine: #178135]
	- 20220929@Evan: Check available balance on BettransX+Transfer [Redmine: #178135]
	- 20221226@Evan: Wait for in-house service (2ms) to sync new value of rollback ticket to centraldb [Redmine: #182003]
	- 20230227@Evan: Ensure correct balance calculation when allow to transfer 247 (BU) [Redmine: #173554]
	- 20230322@Evan: Change code write log into bodb_customerlog.UserLog_Transfer [Redmine: #185507]
	- 20240304@Eddie: Change "Dot_Member" to "Svc_Tig" account [Redmine: #201841]
	- 20240318@Bobby: LAP - EC enhancement - [RedmineID: #191592]
	- 20240710@Kelvin: Deposit - Enhance rollback process in SP transfer (HOT FIX) - [RedmineID: #206265]
	- 20240502@Bobby: Deposit - Fix Transfer issue - [RedmineID: #204165]

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
	SET NOCOUNT ON;

	DECLARE @InitialTimeCheck		DATETIME,
			@DurationLimitCheck		INT;

	SELECT @InitialTimeCheck		=  ISNULL(@InitialTime, GETDATE())
		, @DurationLimitCheck		=  IIF(ISNULL(@DurationLimit, 0) <= 0, 300, @DurationLimit) -- 300 seconds by default
	
	---- #1 CHECK UM TRANSFER FUNCTION
	EXEC DBCUST.CUSTDB.dbo.Acc_Transfer_CheckUM  
		@CustID = @custid
		,@Language = 'E'
		,@ErrMsg = @ErrMsg OUTPUT 
		,@ErrCode = @ErrCode OUTPUT
	 
	IF @ErrCode <> 0  -- Function Transfer is under UM 
	BEGIN
		RETURN		
	END

	DECLARE @Cust_SiteDBGroupID SMALLINT, @Server_SiteDBGroupID SMALLINT;
	DECLARE @SiteGroupInfo TABLE
	(	
		CustID INT,
		SiteDBGroupID SMALLINT,
		LinkedServerName  VARCHAR(512),
		ClientAccessName VARCHAR(512),
		AGIP VARCHAR (50)
	)
	INSERT INTO @SiteGroupInfo (SiteDBGroupID, LinkedServerName, ClientAccessName, AGIP)
	EXEC DBCUST.CustDB.dbo.Acc_SiteDBConfigSel @CustID = @custid

	SELECT @Cust_SiteDBGroupID = SiteDBGroupID FROM @SiteGroupInfo
	SELECT @Server_SiteDBGroupID = dbo.f_Get_SiteDBGroupID()

	--Check the SiteDBGroupID of CustID and Server is match
	IF ISNULL(@Cust_SiteDBGroupID,-1) <> @Server_SiteDBGroupID
	BEGIN
		SELECT @ErrMsg = 'Executing on invalid server. Please check SiteDBGroupID information.', @ErrCode = 108	
		RETURN		
	END
	
	DECLARE 
		 @LogActionID			INT
		,@Count					INT
		
	SELECT @LogActionID = 2900
	
	DECLARE @username			VARCHAR(50),
		@currency				TINYINT,
		@currencyName			VARCHAR(5),
		@winlostdate			SMALLDATETIME,
		@beforebalance			MONEY,
		@postbalance			MONEY,
		@actualrate				FLOAT,
		@winlost				MONEY,
		@actual_stake			MONEY,
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
		@translogCredit 		MONEY,
		@balance_bettransRNG	MONEY,
		@balance_bettransLC		MONEY,
		@balance_Transfer		MONEY,

		@DDEP					SMALLINT,
		@DWIT					SMALLINT,
		@DBON					SMALLINT,
		@DADJ					SMALLINT,
		@DTRA					SMALLINT,
		@DTRAARC				SMALLINT,
		@DTRATP					SMALLINT,

		@BalanceType			TINYINT,
		@IsForced				BIT,
		@WalletType				TINYINT,
		@BonusWalletFlag		BIT,
		-- Rebate bonus
		@DBONRTRA				SMALLINT,
		@DBONRADJ				SMALLINT,

		@IsDiff					SMALLINT = 1,
		@BalanceUpDate			SMALLDATETIME,
		@MoveBetsDay			SMALLDATETIME,
		@NewMoveBetsDay			SMALLDATETIME,
		@NewBalanceUpDate		SMALLDATETIME

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
	
	IF @bettype IN (22006, 22010, 22014, 22016, 22018, 22008, 22020) --TRANSFER BETWEEN IBC AND THIRD PARTY SYSTEM, USE @BalanceType = 3
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
	
	--TODO: get MBU days
	SET @MoveBetsDay = NULL
	EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @MoveBetsDay OUTPUT
	EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @BalanceUpDate OUTPUT

	WHILE (@IsDiff = 1)
	BEGIN
		--Check enough balance for withdrawing
		SELECT @balance = 0, @translogCredit = 0, @balance_bettransRNG = 0, @balance_bettransLC = 0, @balance_Transfer = 0

		SELECT @balance = SUM(winlost-actual_stake+playercomm)
		FROM dbo.bettrans b WITH(NOLOCK)
		WHERE custid = @custid
			AND winlostdate > @MoveBetsDay

		---get data of transfer ticket from new table [transfer]
		SELECT @balance_Transfer = SUM(winlost-actual_stake+playercomm)
		FROM dbo.Transfer t WITH(NOLOCK)
		WHERE custid = @custid
			AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @MoveBetsDay THEN 0 --> new sum
					WHEN bettype = 20000 AND winlostdate > @BalanceUpDate THEN 0 --> new bal
					WHEN winlostdate < @BalanceUpDate THEN 0 --> old data
					ELSE 1 END
		---

		SELECT @translogCredit = SUM(ISNULL(actual_stake, 0))
		FROM dbo.translog t WITH(NOLOCK) 
		WHERE custid = @custid AND statusID=0	
	
		SELECT	@balance_bettransRNG = SUM(winlost - actual_stake + playercomm)
		FROM	dbo.bettransRnG b WITH(NOLOCK)
		WHERE	custid = @custID 
				AND IsSum=0
			
		SELECT	@balance_bettransLC = SUM(winlost - actual_stake + playercomm)
		FROM	dbo.bettransLC b WITH(NOLOCK)
		WHERE	custid = @custID 
				AND IsSum=0
	
		----check MB date, BU date again to make sure it is not changed
		SELECT @NewMoveBetsDay = NULL, @NewBalanceUpDate = NULL
		EXEC dbo.Acc_ReCheck_MBUDate 
			@MBDate = @moveBetsDay,
			@BUDate = @BalanceUpDate,
			@IsDiff = @IsDiff OUTPUT,
			@NewMBDate = @NewMoveBetsDay OUTPUT,
			@NewBUDate = @NewBalanceUpDate OUTPUT

		IF @IsDiff = -1 
		BEGIN
			SELECT @ErrMsg = 'BalanceUpDate value is null. Please contact DBA for support.', @ErrCode = 109				
			RETURN	
		END

		IF @IsDiff = 1 
		BEGIN
			SELECT @MoveBetsDay = @NewMoveBetsDay, @BalanceUpDate = @NewBalanceUpDate
		END
	END
	
	SELECT @beforebalance = ISNULL(@balance, 0) + ISNULL(@balance_Transfer, 0) + ISNULL(@balance_bettransRNG, 0) + ISNULL(@balance_bettransLC, 0)  - ISNULL(@translogCredit, 0)
	SELECT @postbalance = @beforebalance + @winlost - @actual_stake
	
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
		SELECT @Count	= 0
			,@ErrMSg	= ''
			,@ErrCode	= 0;

		------------------Insert trans into DB---------------------------------------------------------------
		IF @RefNo = 0
		BEGIN
			EXEC Get_Refno_Transid @RefNo = @RefNo OUTPUT
		END
		
		----------------------------------
		---- Checking the balance of customer before updating the amount on Credit or Debit table 

		DECLARE @Cust_Balance		MONEY,
				@Cust_Balance_ABS	MONEY,
				@diffDurationLimit	INT,
				@stepDone			INT;
		
		SELECT	@Cust_Balance		= @winlost - @actual_stake
			, @Cust_Balance_ABS		= ABS(@Cust_Balance)		
			, @stepDone				= 0;

		--TODO: implement CheckFundTransfer
		SELECT @diffDurationLimit = DATEDIFF(SECOND, @InitialTimeCheck, CURRENT_TIMESTAMP);
		IF @diffDurationLimit > @DurationLimitCheck AND @bettype IN (22001, 22002)
		BEGIN
			SELECT 
				@ErrCode = 107
				,@ErrMsg = 'Insert transaction failed. ERROR_MESSAGE: Violate the CheckFundTransfer rule.'
			
			RAISERROR(@ErrMsg, 11, 1); --- will be handled in the Begin...Catch block code
		END

		--Update BalanceDebit 
		IF @Cust_Balance < 0 
		BEGIN
			SELECT @Count = 1;
 			EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @Cust_balance_ABS, @type = @BalanceType, @IsForced = @IsForced, @errCode = @ErrCode OUTPUT
			IF @ErrCode <> 0
			BEGIN
				SELECT	@ErrCode = 105	
						,@ErrMsg = 'Insert transaction failed.' + ' STEP: ' + CONVERT(NVARCHAR(1), @Count) + '. ERROR_MESSAGE: Update balance debit failed'  + ' - ERROR_NUMBER: ' + CONVERT(VARCHAR(20), @ErrCode)
				
				RAISERROR(@ErrMsg, 11, 1); --- will be handled in the Begin...Catch block code
			END
			SET @stepDone += POWER(2*1, 1); --Done BalanceDebit-2^1
		END 

		SELECT @transdate = CURRENT_TIMESTAMP
			,@winlostdate = CAST(@transdate AS DATE);
		
		---get new @TransId 
		EXEC Get_Bettrans_TransID @TransID = @TransId OUTPUT
		---get new @bal_transid 
		EXEC Get_Bettrans_TransID @TransID = @bal_transid OUTPUT

		BEGIN TRY
			SELECT @Count = 2
			INSERT INTO dbo.Transfer 
				(TransId, custid, username, refno, transdate, bettype, transdesc,winlost, actual_stake, winlostdate, balance,
				 creator,recommend,mrecommend,srecommend,currency,actualrate, currencyName, statusID,ip, SerialNo, RepUpdateTime)
			VALUES 
				(@TransId, @CustID, @username, @RefNo, @transdate, @bettype, @transdesc,@winlost, @actual_stake, @winlostdate, ISNULL(@beforebalance, 0),
				 @CustID, @Recommend, @MRecommend, @SRecommend, @Currency,@actualrate, @currencyName, 131,@ip, @betcheck, SYSDATETIME()),
				 --dummy trans
				 (@bal_transid, @bal_custID, @bal_Username, @RefNo, @transdate, @bettype, @transdesc, @actual_stake * @ExchangeRate, @winlost * @ExchangeRate, @winlostdate, NULL, 
				 @CustID, @bal_recommend, @bal_mrecommend, @bal_srecommend, @bal_currency, @bal_actualrate, @bal_currencyName, 131, @ip, '0', SYSDATETIME())
			
			SET @stepDone += POWER(2*1, 2); --Done transfer-2^2
		END TRY
		BEGIN CATCH
			SELECT	@ErrCode = 108
					,@ErrMsg = 'Insert transaction failed.' + ' STEP: ' + CONVERT(NVARCHAR(1), @Count) + '. ERROR_MESSAGE: Insert transfer failed'  + ' - ERROR_NUMBER: ' + CONVERT(VARCHAR(20), @ErrCode) + '. Exception: ' + ERROR_MESSAGE();
				
			RAISERROR(@ErrMsg, 11, 1); --- will be handled in the Begin...Catch block code
		END CATCH

		--Update BalanceCredit 
		IF @Cust_Balance > 0  
		BEGIN
			SELECT @Count = 3
 			EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_Balance, @type = @BalanceType, @errCode = @ErrCode OUTPUT
			IF @ErrCode <> 0
			BEGIN
				SELECT	@ErrCode = 106	
						,@ErrMsg = 'Insert transaction failed.' + ' STEP: ' + CONVERT(NVARCHAR(1), @Count) + '. ERROR_MESSAGE: Update balance credit failed'  + ' - ERROR_NUMBER: ' + CONVERT(VARCHAR(20), @ErrCode);

				RAISERROR(@ErrMsg, 11, 1); --- will be handled in the Begin...Catch block code
			END
			SET @stepDone += POWER(2*1, 3); --Done BalanceCredit-2^3
		END 

		---insert into new table transferinfo
		IF NOT (@WalletType IS NULL AND @BonusID IS NULL)
		BEGIN
			SELECT @Count = 4
			INSERT INTO dbo.TransferInfo(TransId, WalletType, BonusID, RepUpdateTime)
			VALUES (@TransId, @WalletType, @BonusID, SYSDATETIME())
				,(@bal_transid, @WalletType, @BonusID, SYSDATETIME());

			SET @stepDone += POWER(2*1, 4); --Done transferinfo-2^4
		END
	END TRY
	BEGIN CATCH

		WAITFOR DELAY '000:00:00.002' -- wait for in-house service

		--TODO: Unhandle exception
		SELECT @ErrCode = 110
			, @ErrMsg	= CONCAT('Insert transaction failed. Exception:' + ERROR_MESSAGE(), ', ERROR_LINE: ', ERROR_LINE(), ', ERROR_NUMBER: ', ERROR_NUMBER())
		WHERE @ErrMsg <> ERROR_MESSAGE()

		--TODO: Rollback BalanceCredit 
		IF @Cust_balance > 0  AND @stepDone & 8 = 8
		BEGIN
			EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @Cust_Balance, @type = @BalanceType, @IsForced = 1
		END

		--TODO: Manually rollback transfer
		IF @stepDone & 4 = 4
		BEGIN
			UPDATE dbo.Transfer WITH(ROWLOCK)
			SET	custid = 0, 
				Recommend = 0, 
				MRecommend = 0, 
				SRecommend = 0, 
				Winlost = 0, 
				Actual_Stake = 0, 
				RepUpdateTime = SYSDATETIME()
			WHERE transid IN (@transid, @bal_transid) AND refno = @RefNo
				AND @stepDone & 4 = 4
		END

		--TODO: Rollback BalanceDebit 
		IF @Cust_balance < 0 AND @stepDone & 2 = 2
		BEGIN 
 			EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_Balance_ABS, @type = @BalanceType
		END

		--TODO: Manually rollback transferInfo
		IF @stepDone & 16 = 16
		BEGIN
			UPDATE TransferInfo WITH(ROWLOCK)
			SET		IsDel = 1,  RepUpdateTime = SYSDATETIME()
			WHERE TransId IN (@transid, @bal_transid)
				AND @stepDone & 16 = 16
		END
	END CATCH
	
	---------------------------------------------------------------------------------------------------
	--TODO: write userlog 
	DECLARE @LogData VARCHAR(1000)
	IF @ErrCode = 0 --success
	BEGIN
		SELECT @LogData = 
					'Insert trans custid = ' + CONVERT(VARCHAR(20), @custid) + ', bettype = ' + CONVERT(VARCHAR(20), @bettype) + ', amount = ' + CONVERT(VARCHAR(20), @amount) 
					+ CASE WHEN @BonusId > 0 THEN ', bonusId = ' + convert(varchar(20), @BonusId) ELSE '' END

		SELECT @LogData = @LogData
			+ CASE WHEN @InitialTime IS NOT NULL THEN CONCAT(', @InitialTime=', FORMAT(@InitialTimeCheck, 'yyyy-MM-dd HH:mm:ss')) ELSE CONCAT(', @InitialTimeCheck=', FORMAT(@InitialTimeCheck, 'yyyy-MM-dd HH:mm:ss')) END
			+ CASE WHEN ISNULL(@DurationLimit, 0) > 0 THEN CONCAT(', @DurationLimit=', @DurationLimitCheck) ELSE CONCAT(', @DurationLimitCheck=', @DurationLimitCheck) END
			+ CONCAT(', @diffDurationLimit=', @diffDurationLimit)
		WHERE @bettype IN (22001, 22002)
	END
	ELSE -- error logs
	BEGIN
		SELECT @LogData = CONCAT(@ErrMsg, '. Transfer @transid=',@transid,', @bal_transid=', @bal_transid)
	END

	BEGIN TRY	
	
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
								@UserID		= @custid, 
								@FromCustID = @custid, 
								@ToCustID	= @bal_custid, 
								@IP			= @IP, 
								@Doing		= @LogData 
	END TRY
	BEGIN CATCH
		-- IF write log error: not RETURN error code
		SELECT @LogData = @LogData + ' ErrMsg: ' + ERROR_MESSAGE()
			
		EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
							@UserID		= @custid, 
							@FromCustID = @custid, 
							@ToCustID	= @bal_custid, 
							@IP			= @IP, 
							@Doing		= @LogData
	END CATCH
END
GO