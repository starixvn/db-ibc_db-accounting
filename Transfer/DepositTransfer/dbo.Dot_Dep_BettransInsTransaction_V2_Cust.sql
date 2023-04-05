/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member,Dot_Bonus" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  [dbo].[Dot_Dep_BettransInsTransaction_V2_Cust] 
	@amount MONEY,	
	@custid INT,
	@bal_custid INT,	
	@transdesc NVARCHAR(300),
	@transid BIGINT = 0 OUTPUT,	
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
	@bettype SMALLINT = 22001,
	@IsCharge BIT = 0,	
	@ip	VARCHAR(45)='',
	@RefNo BIGINT = 0 OUTPUT,
	@ExchangeRate SMALLMONEY = 1,
	@bal_transid BIGINT = 0 OUTPUT,
	@transdate DATETIME = NULL OUTPUT,
	@BetCheck NVARCHAR(50) = NULL,
	@BonusID INT = NULL

AS
/*
Creator : Thien
Date : 2007-11-23
Task : record all kinds of transactions for Deposit sites
DB: DBTXN/bodb02
User: NON API Licensee/12Bet

Revisions:
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
	- 20190705@Bobby: Add Rebate Bonus [RedmineID: #116358]
	- 20190710@Jamie: Check Bonus wallet if a member is joining a Bonus campaign [Redmine:#116273]
	- 20201014@Danny: Convert Ipv6 to dummy IPv4 [Redmine: #143323]
	- 20210518@Percy: Change code to adapt new Move Bets flow [RedmineID: #154866]
	- 20211021@Benson: add update betcheck for balance accounts(@bal_custid)
	- 20211111@Sol: Split Transfer out of bettrans/Support IPv6 - [RedmineID: #164301]
	- 20220721@Evan: Integrate new transid [Redmine: #175640]
	- 20220724@Evan: Revise code rollback, get balance from 8 table balance [Redmine: #175297]
	- 20220923@Evan: Revise code rollback (issue) [Redmine: #178135]
	- 20220929@Evan: Check available balance on BettransX+Transfer [Redmine: #178135]
	- 20221226@Evan: Wait for in-house service (2ms) to sync new value of rollback ticket to centraldb [Redmine: #182003]
	- 20230227@Evan: Ensure correct balance calculation when allow to transfer 247 (BU) [Redmine: #173554]

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
	22202: DBONRTRA - Rebate Bonus Transfer 
	22203: DBONRADJ - Rebate Bonus Adjustment
	
	
? @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Specific Error.
	
? @ErrMsg: Error description.

? @IsCharge:
	= 1: is charge transation, so not check the negative balance

*/
BEGIN
	SET NOCOUNT ON

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

	DECLARE @username VARCHAR(50),
		@currency TINYINT,
		@currencyName VARCHAR(5),
		-- @transdate datetime,	
		@actualrate FLOAT,
		@winlost MONEY,	
		@actual_stake MONEY,
		@mrecommend INT,
		@recommend INT,
		@srecommend INT,
		@roleid TINYINT,
		@balance MONEY,
	
		--Balance Account info
		@bal_mrecommend INT,
		@bal_recommend INT,
		@bal_srecommend INT,
		@bal_Username VARCHAR(50),
		@bal_currency TINYINT,
		@bal_actualrate FLOAT,
		@bal_currencyName NVARCHAR(5),

		@DDEP SMALLINT,
		@DWIT SMALLINT,
		@DBON SMALLINT,
		@DADJ SMALLINT,
		@DTRA SMALLINT,
		@Cust_balance MONEY,
		@Cust_balance_ABS MONEY,
		@IsForced BIT,
		@WalletType TINYINT,
		@BonusWalletFlag BIT, 
		@translogCredit 		MONEY,
		@balance_bettransRNG	MONEY,
		@balance_bettransLC		MONEY,
		@balance_Transfer		MONEY,

		-- Rebate bonus
		@DBONRTRA SMALLINT,
		@DBONRADJ SMALLINT,
		@MoveBetsDay smalldatetime,
		@BalanceUpDate smalldatetime,
		@IsDiff SMALLINT = 1,
		@NewMoveBetsDay smalldatetime,
		@NewBalanceUpDate smalldatetime

	DECLARE @MBBU TABLE (BalanceUpDay smalldatetime, MoveBetsDay smalldatetime)

	SELECT @ErrCode = 0,
			@ErrMsg = '',
			@RefNo = isnull(@RefNo,0),
			@amount = @amount,
			@DADJ = 21003,
			@DDEP = 22001,
			@DWIT = 22002,
			@DBON = 22004,
			@DTRA = 22005,
			@DBONRTRA = 22202,
			@DBONRADJ = 22203,
			@WalletType = CASE	WHEN @bettype IN (@DBONRTRA, @DBONRADJ) THEN 1 -- Rebate bonus
								WHEN @BonusID > 0 THEN 2
								ELSE NULL end,
			@BonusWalletFlag = 0

	SELECT @bettype = 
		CASE @bettype WHEN 103 THEN 21003 
			WHEN 107 THEN 22001 
			WHEN 108 THEN 22002
			WHEN 110 THEN 22004
			WHEN 111 THEN 22005
			WHEN 115 THEN 22006
			ELSE @bettype
		END

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
		,@BonusWalletFlag = ISNULL(ci.BonusWalletFlag,0)
	FROM CustDB.dbo.custinfo AS ci WITH(NOLOCK)
	INNER JOIN CustDB.dbo.exchange AS e WITH(NOLOCK) ON ci.currency = e.exchangeid
	WHERE ci.custid = @custid

	
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @username = username
			,@currency = ci.currency
			,@currencyName = e.currency
			,@actualrate = e.actualrate
			,@mrecommend = mrecommend
			,@recommend = recommend
			,@srecommend = srecommend
			,@roleid = roleid
			,@BonusWalletFlag = ISNULL(ci.BonusWalletFlag,0)
		FROM DBCUST.CustDB.dbo.custinfo AS ci WITH(NOLOCK)
		INNER JOIN DBCUST.CustDB.dbo.exchange AS e WITH(NOLOCK) ON ci.currency = e.exchangeid
		WHERE ci.custid = @custid
	END

	SELECT @transdesc = @username + ' - ' +
						CASE @bettype WHEN @DDEP THEN 'Deposit'
										WHEN @DWIT THEN 'Withdraw'
										WHEN @DBON THEN 'Bonus'
										WHEN @DADJ THEN 'Adjustment'
										WHEN @DTRA THEN 'Transfer'
										WHEN @DBONRTRA THEN 'Bonus'
										WHEN @DBONRADJ THEN 'Bonus'
										ELSE '' END				
					+ CASE WHEN @transdesc <> '' THEN ' - ' + @transdesc END

	SELECT 
		@winlost = CASE WHEN @bettype IN (@DDEP, @DBON, @DTRA, @DADJ, @DBONRTRA, @DBONRADJ) THEN @amount 
						ELSE 0 end,
		@actual_stake = CASE @bettype WHEN @DWIT THEN abs(@amount) ELSE 0 END

	IF @winlost < 0 --then swap the winlost and actual_stake
	BEGIN	
		SELECT @actual_stake = -@winlost, @winlost = 0	
	END

	IF @roleid <> 1
	BEGIN
		SELECT @ErrMsg = 'Invalid Role ID.', @ErrCode = 102		
		RETURN
	END
		
	----------------------------------
	--Check enough balance for withdrawing
	IF @bettype=@DWIT
		AND @IsCharge = 0 --only check when not Charge transaction, and is Withdrawal
	BEGIN

		-- get MB day
		SET @MoveBetsDay = NULL
		INSERT INTO @MBBU (BalanceUpDay, MoveBetsDay)
		EXEC dbo.Age_SelBalanceUpDay
		SELECT @MoveBetsDay = MoveBetsDay, @BalanceUpDate = BalanceUpDay FROM @MBBU
		
		WHILE (@IsDiff = 1)
		BEGIN
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
			WHERE custid = @custid AND statusId = 0
		
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

		/*
			Check Member's Balance for Withdrawal 
		*/

		IF (ISNULL(@balance, 0) + ISNULL(@balance_Transfer, 0) + ISNULL(@balance_bettransRNG, 0) + ISNULL(@balance_bettransLC, 0) - ISNULL(@translogCredit, 0)
				+ @winlost - @actual_stake) < 0
		BEGIN
			SELECT @ErrMsg = 'Sorry, you do not have enough money to withdraw.', @ErrCode = 103				
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

			IF (ISNULL(@balance, 0) + ISNULL(@balance_Transfer, 0) + ISNULL(@balance_bettransRNG, 0) + ISNULL(@balance_bettransLC, 0) + @winlost - @actual_stake - ISNULL(@translogCredit, 0) - @BonusAmount) <0 
			BEGIN
				SELECT	@ErrMsg = 'Sorry, you do not have enough money to withdraw.', @ErrCode = 201	
				RETURN
			END
		END

	END
	----------------------------------

	--Check balance Account
	SELECT @bal_custid = c.custid
		,@bal_Username = c.username
		,@bal_mrecommend = c.mrecommend
		,@bal_recommend = c.recommend
		,@bal_srecommend = c.srecommend
		,@bal_currency = c.currency
		,@bal_actualrate = e.actualrate
		,@bal_currencyName = e.currency
	FROM CustDB.dbo.customer c WITH(NOLOCK)
	INNER JOIN CustDB.dbo.exchange AS e WITH(NOLOCK) ON c.currency = e.exchangeid
	WHERE c.custid = @bal_custid

	IF @@ROWCOUNT = 0
	BEGIN
	SELECT @bal_custid = c.custid
		,@bal_Username = c.username
		,@bal_mrecommend = c.mrecommend
		,@bal_recommend = c.recommend
		,@bal_srecommend = c.srecommend
		,@bal_currency = c.currency
		,@bal_actualrate = e.actualrate
		,@bal_currencyName = e.currency
	FROM DBCUST.CustDB.dbo.customer c WITH (NOLOCK)
	INNER JOIN DBCUST.CustDB.dbo.exchange AS e WITH (NOLOCK) ON c.currency = e.exchangeid
	WHERE c.custid = @bal_custid
	END

	IF @bal_mrecommend is NULL 
	BEGIN
		SELECT @ErrMSg = 'Invalid balance account.', @ErrCode = 104			
			RETURN
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

	IF @RefNo <> 0 Set @IsForced = 1   -- IF @Refno <> 0 = Approved action
	------------------Insert trans into DB---------------------------------------------------------------
	IF @RefNo = 0
	BEGIN
		EXEC Get_Refno_Transid @RefNo = @RefNo OUTPUT
	END	

	---Update Debit Balance	
	SELECT @Cust_balance = @winlost - @actual_stake
	IF @Cust_balance < 0 
	BEGIN 
		SELECT @Cust_balance_ABS = ABS(@Cust_balance)

		EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @Cust_balance_ABS, @type = 2, @IsForced = @IsForced, @errCode = @ErrCode OUTPUT
		IF @ErrCode <> 0
		BEGIN
			SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 105	
			RETURN
		END
	END 

	SELECT @transdate = current_timestamp
	---get new transid 
	EXEC Get_Bettrans_TransID @TransID = @TransId OUTPUT

	BEGIN TRY

		INSERT INTO dbo.transfer
			(TransId, custid, username, refno, transdate, bettype, transdesc,winlost, actual_stake, winlostdate, 
				creator,recommend,mrecommend,srecommend,currency,actualrate, currencyName, statusID, ip, SerialNo, RepUpdateTime)
		VALUES 
			(@TransId, @CustID, @username, @RefNo, @transdate, @bettype, @transdesc,@winlost, @actual_stake, CONVERT(NVARCHAR(10), @transdate, 120),
				@CustID, @recommend, @mrecommend, @srecommend, @Currency,@actualrate, @currencyName, 131, @ip, @BetCheck, SYSDATETIME())

		---insert into new table transferinfo

		IF NOT (@WalletType IS NULL AND @BonusID IS NULL)
		BEGIN
			INSERT INTO dbo.TransferInfo(TransId, WalletType, BonusID, RepUpdateTime)
			VALUES (@TransId, @WalletType, @BonusID, SYSDATETIME())
		END

	END TRY
	BEGIN CATCH
							
		SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 105	

		WAITFOR DELAY '000:00:00.002' -- wait for in-house service

		--Manually rollback
		UPDATE dbo.Transfer WITH(ROWLOCK)
		SET	custid = 0, 
			Recommend = 0, 
			MRecommend = 0, 
			SRecommend = 0, 
			Winlost = 0, 
			Actual_Stake = 0, 
			RepUpdateTime = SYSDATETIME()
		WHERE refno = @RefNo and bettype = @bettype and custid = @custid
			
		UPDATE TransferInfo WITH(ROWLOCK)
		SET		IsDel = 1,  RepUpdateTime = SYSDATETIME()
		WHERE TransId = @TransId

		--rollback balance
		IF @Cust_balance < 0 
		BEGIN 
			SELECT @Cust_balance_ABS = ABS(@Cust_balance)
			EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_balance_ABS, @type = 2
		END  

		RETURN

	END CATCH

	---Update Credit Balance	
	IF @Cust_balance > 0 
	BEGIN 
		EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_balance, @type = 2
	END 

	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------

	--get new transid 
	EXEC Get_Bettrans_TransID @TransID = @bal_transid OUTPUT

	BEGIN TRY

		INSERT INTO dbo.Transfer 
			(TransId, custid, username, refno, transdate, bettype, transdesc,winlost, actual_stake, winlostdate, 
				creator,recommend,mrecommend,srecommend,currency,actualrate, currencyName, statusID, ip, SerialNo, RepUpdateTime)
		VALUES 
			(@bal_transid, @bal_custID, @bal_Username, @RefNo, @transdate, @bettype, @transdesc, @actual_stake * @ExchangeRate, @winlost * @ExchangeRate, CONVERT(NVARCHAR(10), @transdate, 120), 
				@CustID, @bal_recommend, @bal_mrecommend, @bal_srecommend, @bal_currency, @bal_actualrate, @bal_currencyName, 131, @ip, @BetCheck, SYSDATETIME())

		---insert into new table transferinfo

		IF NOT (@WalletType IS NULL AND @BonusID IS NULL)
		BEGIN
			INSERT INTO dbo.TransferInfo(TransId, WalletType, BonusID, RepUpdateTime)
			VALUES (@bal_transid, @WalletType, @BonusID, SYSDATETIME())
		END


	END TRY
	BEGIN CATCH
		
		SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 106
			
		IF @Cust_balance > 0 
		BEGIN 
			EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @Cust_balance, @type = 2, @isForced = 1
		END 	
		
		WAITFOR DELAY '000:00:00.002' -- wait for in-house service
			
		--Manually rollback
		UPDATE dbo.Transfer WITH(ROWLOCK)
		SET	custid = 0, 
			Recommend = 0, 
			MRecommend = 0, 
			SRecommend = 0,  
			Winlost = 0, 
			Actual_Stake = 0, 
			RepUpdateTime = SYSDATETIME()
		WHERE refno = @RefNo and bettype = @bettype and custid in (@custid, @bal_custID)
			
		UPDATE TransferInfo WITH(ROWLOCK)
		SET		IsDel = 1,  RepUpdateTime = SYSDATETIME()
		WHERE TransId IN (@transid, @bal_transid)

		--rollback balance @CustID
		IF @Cust_balance < 0 
		BEGIN 
			SELECT @Cust_balance_ABS = ABS(@Cust_balance)
			EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_balance_ABS, @type = 2
		END 

		RETURN

	END CATCH

	SET @transdate = CONVERT(CHAR(30),@transdate, 121)
	
	DECLARE @LogData VARCHAR(300)

	SELECT @LogData = 
				'Insert trans custid = ' + CONVERT(VARCHAR(20), @custid) + ', bettype = ' + CONVERT(VARCHAR(20), @bettype) + ', amount = ' + CONVERT(VARCHAR(20), @amount) 
				+ CASE WHEN @BonusId > 0 THEN ', bonusId = ' + CONVERT(VARCHAR(20), @BonusId) ELSE '' END

	BEGIN TRY	
		EXEC dbo.WriteLog_UserLog @UserID = @custid, @Doing = @LogData
	END TRY
	BEGIN CATCH
		-- if write log error: not return error code
	END CATCH
END
GO


