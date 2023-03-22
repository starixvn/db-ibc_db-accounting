/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_Int_BettransInsCancelTransfer_Cust]
	@custid				INT,
	@transid			BIGINT,	
	@transdesc			NVARCHAR(300)		=	'',
	@ip					VARCHAR(45)		=	'',
	@NewTransID			BIGINT				=	0			OUTPUT,	
	@ErrCode			INT					=	0			OUTPUT,
	@ErrMsg				NVARCHAR(200)		=	''			OUTPUT,
	@TheirPartyType		INT					=	1,
	@betcheck			NVARCHAR(50)		=	''
AS
/*
Creator : Thien
Date : 2007-12-05
Task : Cancel transfer to third party in case error returned from third party API
DB: DBTRANS/bodb02
User: API Licensee/12Bet

Revisions:	
	- 20091222@viet: get actualrate from exchange table instead
	- 20100310@Thien: remove CustBetCreditUpdResync
	- 20100521@viet: Update for Bettrans.StatusID
	- 20101007@Henry: Change column transid from INT to BIGINT
	- 20101224@Johnson: Apply new arrange of bettype
	- 20111031@Sophia: Update balance for customer
	- 20120412@Sophia: Revise update balance for customer
	- 20120511@Jamie: Fix - Indecate @DCAN when rollback transaction 
	- 20121110@viet: revise SP to reduce DBTrans's resources
	- 20130702@Benson: add @TheirPartyType Parameter for input
	- 20131108@Elodie: Splitting bodb02 into CustDB (call Exchange, CustInfo, Customer by link database)
	- 20140827@Don: Rearrange the hardcode about transfer bet types of 3rd party products
	- 20141226@Tom: Update Transfer Amount in bodb_report.dbo.rptStatement table before move bet day
	- 20150606@Kathy: Migrate custDB to new server DBCust. Get cust info from DBCust.CustDB in case of replication problem  [Redmine:#36216]		
	- 20150808@Elodie: Balance Improvement [Redmine:#40125]	
	- 20151022@Elodie: Don't update balance for dummy account
	- 20160203@Chun: Add new parameter 'betcheck' for 12BET
	- 20210518@Percy: Change way to get MoveBetsDay [RedmineID: #154866]
	- 20211112@Sol: Support IPv6 - Phase 2 - Add [Convert Ipv6 to dummy IPv4] - [Redmine: #163963]
	- 20211111@Sol: Split Transfer out of bettrans/Support IPv6 - [RedmineID: #164301]
	- 20220721@Evan: Integrate new transid [Redmine: #175640]
	- 20220724@Evan: Revise code rollback for scale-out [Redmine: #175297]
	- 20220923@Evan: Revise code rollback (issue) [Redmine: #178135]
	- 20221226@Evan: Wait for in-house service (2ms) to sync new value of rollback ticket to centraldb [Redmine: #182003]
	- 20230322@Evan: Change code write log into bodb_customerlog.UserLog_Transfer [Redmine: #185507]

Input 
    1) CustID (For Double check) 
    2) TransID get from Output transid of transaction insert (Dot_Dep_BettransInsTransaction_V2)
    1) Result (@ErrCode)
    2) NewTransID (Cancel)
    
‧ @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Specific Error.
‧ @ErrMsg: Error description.
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

	DECLARE	@alias VARCHAR(100), 
			@sqlCommand VARCHAR(MAX),
			@doNotRunInServer VARCHAR(1000),
			@remark VARCHAR(4000)

			---get server name that dont need to run
			EXEC bodb02.dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
			SELECT @alias = 'DBRPT', @remark = 'Dot_Int_BettransInsCancelTransfer_Cust -> Acc_StatementUpdateTransfer'
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

	DECLARE @trans_custid		INT,
		@username				VARCHAR(50),
		@currency				TINYINT,
		@currencyName			VARCHAR(5),
		@transdate				DATETIME,
		@bettype				INT,
		@newBettype				INT,
		@amount					MONEY,		
		@actualrate				FLOAT,
		@winlost				MONEY,
		@actual_stake			MONEY,
		@mrecommend				INT,
		@recommend				INT,
		@srecommend				INT,
		@roleid					TINYINT,
		@balance				MONEY,
		
		--Balance Account info
		@bal_custid				INT,
		@bal_mrecommend			INT,
		@bal_recommend			INT,
		@bal_srecommend			INT,
		@bal_Username			VARCHAR(50),
		@winlostdate			SMALLDATETIME,
		
		@RefNo					BIGINT,
		@DTRATP					INT,
		@DCAN					INT,
		@Cust_balance			MONEY,
		@Cust_balance_ABS		MONEY,
		@bal_balance			MONEY,
		@bal_balance_ABS		MONEY,
		@BalanceType			TINYINT

	SELECT @ErrCode = 0,
		@ErrMsg = ''

	/*
	22006  Playtech casino transfer
	22007  Playtech casino cancel transfer
	22008  Hogaming transfer
	22009  Hogaming cancel transfer
	22010  OPus transfer
	22011  OPus cancel transfer
	*/
	SELECT @DTRATP = 0,@DCAN=0

	SELECT @DTRATP=TransferBettype,@DCAN=CancelBettype
	FROM dbo.ThirdPartySetting WITH(NOLOCK)
	WHERE ThirdPartyType=@TheirPartyType

	/* === remove by darren===
	SET  @DTRATP=
	CASE
		WHEN @TheirPartyType = 1 THEN 22006
		WHEN @TheirPartyType = 2 THEN 22008
		WHEN @TheirPartyType = 3  THEN 22010
		ELSE 0
	END
	*/
	IF @DTRATP = 0
	BEGIN
		Select @ErrMsg = 'Sorry, transfer get DTRATP error !!.', @ErrCode = 108	
		RETURN		
	END
	/* === remove by darren===
	SET  @DCAN = 
	CASE
		WHEN @TheirPartyType = 1 THEN 22007
		WHEN @TheirPartyType = 2 THEN 22009
		WHEN @TheirPartyType = 3  THEN 22011
		ELSE 0
	END
	*/

	IF @DCAN = 0
	BEGIN
		SELECT @ErrMsg = 'Sorry, transfer get DCAN error !!.', @ErrCode = 109	
		RETURN
	END

	SELECT	@winlost			= winlost,
			@actual_stake		= actual_stake,
			@bettype			= bettype,
			@RefNo				= refno,
			@trans_custid		= custid,
			@winlostdate		= winlostdate,
			@currency			= currency,
			@currencyName		= currencyName 
	FROM dbo.Transfer t WITH(NOLOCK)
	WHERE transid = @transid

	SELECT @actualrate = actualrate
	FROM CustDB.dbo.exchange WITH(NOLOCK)
	WHERE exchangeid = @currency
	
	IF @@rowcount = 0
	BEGIN
		SELECT @actualrate = actualrate
		FROM DBCUST.CustDB.dbo.exchange WITH(NOLOCK)
		WHERE exchangeid = @currency
	END

	IF @trans_custid <> @custid
	BEGIN
		SELECT @ErrMsg = 'Invalid CustID.', @ErrCode = 101		
		RETURN
	END

	IF @bettype <> @DTRATP
	BEGIN
		SELECT @ErrMsg = 'This transaction is not a transfer from/to third party.', @ErrCode = 102		
		RETURN
	END

	--Get balance custid
	SELECT @bal_custid = custid
	FROM dbo.Transfer t WITH(NOLOCK)
	WHERE bettype = @bettype
		AND refno = @RefNo 
		AND transid <> @transid
		AND winlostdate = @winlostdate	

	IF EXISTS (
			SELECT TOP 1 1 
			FROM dbo.Transfer t WITH(NOLOCK) 
			WHERE refno = @RefNo 
				AND bettype = @DCAN
				AND custid IN (@custid, @bal_custid)
		)
	BEGIN
		SELECT @ErrMsg = 'This transaction has been cancelled before.', @ErrCode = 103		
		RETURN
	END

	-----------------------

	-----------------------

	SELECT @username = username, @mrecommend = mrecommend, @recommend = recommend, @srecommend = srecommend, @roleid = roleid
	FROM CustDB.dbo.custinfo AS ci WITH(NOLOCK) 
	WHERE ci.custid = @custid
	
	IF @@rowcount = 0
	BEGIN
		SELECT @username = username, @mrecommend = mrecommend, @recommend = recommend, @srecommend = srecommend, @roleid = roleid
		FROM DBCUST.CustDB.dbo.custinfo AS ci WITH(NOLOCK) 
		WHERE ci.custid = @custid
	END

	SELECT @transdesc = @username + ' - Cancel transfer from/to third party, transid' + CAST(@transid AS VARCHAR(20)) + ' - '
					+ CASE WHEN @transdesc <> '' THEN ' - ' + @transdesc END

	/*
	select 
		@winlost = @amount,
		@actual_stake = 0
	*/

	----------------------------------
	--Check balance Account
	SELECT @bal_custid = c.custid, @bal_Username = c.username,  
		   @bal_mrecommend = c.mrecommend, @bal_recommend = c.recommend, @bal_srecommend = c.srecommend	
	FROM CustDB.dbo.customer c WITH(NOLOCK)
		INNER JOIN CustDB.dbo.customer MAg WITH(NOLOCK) ON c.mrecommend =  MAg.custid
	WHERE c.custid = @bal_custid AND c.currency = @currency
	
	IF @@rowcount = 0
	BEGIN
		SELECT @bal_custid = c.custid, @bal_Username = c.username,  
			   @bal_mrecommend = c.mrecommend, @bal_recommend = c.recommend, @bal_srecommend = c.srecommend	
		FROM DBCUST.CustDB.dbo.customer c WITH(NOLOCK)
			INNER JOIN DBCUST.CustDB.dbo.customer MAg WITH(NOLOCK) ON c.mrecommend =  MAg.custid
		WHERE c.custid = @bal_custid AND c.currency = @currency
	END

	IF @bal_mrecommend IS NULL 
	BEGIN
		SELECT @ErrMSg = 'Invalid balance account or the currency is not supported.', @ErrCode = 104			
		RETURN
	END
	----------------------------------

	If @DCAN IN (22011, 22009, 22015, 22017, 22019, 22021, 22007) --CANCEL TRANSFER BETWEEN IBC AND THIRD PARTY SYSTEM, USE @BalanceType = 3
		SELECT @BalanceType = 3
	ELSE
		SELECT @BalanceType = 2

	------------------Insert trans into DB---------------------------------------------------------------
	---Update Debit Balance	
		SELECT @Cust_balance = @actual_stake - @winlost
		IF @Cust_balance < 0 
		BEGIN 
			SELECT @Cust_balance_ABS = ABS(@Cust_balance)
 			EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @Cust_balance_ABS, @type = @BalanceType, @errCode = @ErrCode OUTPUT

			IF @ErrCode <> 0
			BEGIN
				SELECT @ErrMsg = 'Update balance failed.', @ErrCode = 106
				RETURN
			END
		END 
		
	SELECT @transdate = CURRENT_TIMESTAMP

	---get new transid 
	EXEC Get_Bettrans_TransID @TransID = @NewTransID OUTPUT

	INSERT INTO dbo.Transfer 
		(TransId, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, winlostdate, 
		 creator,recommend,mrecommend,srecommend,currency,actualrate, currencyName, statusID, ip, SerialNo, RepUpdateTime)
	VALUES 
		(@NewTransID, @CustID, @username, @RefNo, @transdate, @DCAN, @transdesc, @actual_stake, @winlost, @winlostdate, 
		 @CustID, @Recommend, @MRecommend, @SRecommend, @Currency, @actualrate, @currencyName, 131, @ip, @betcheck, SYSDATETIME())

	SET @ErrCode = @@ERROR	

	-- Begin Update Transfer Amount in bodb_report.dbo.rptStatement table before move bet day
	DECLARE @MBBU TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	INSERT INTO @MBBU (BalanceUpDay, MoveBetsDay)
	EXEC dbo.Age_SelBalanceUpDay

	DECLARE @MoveBetsDay SMALLDATETIME
	SELECT  @MoveBetsDay = MoveBetsDay FROM @MBBU

	DECLARE @TransferAmount money

	IF @ErrCode = 0 
	BEGIN
		IF @winlostdate <= @MoveBetsDay
		BEGIN		
			SET @TransferAmount = -(@Winlost - @actual_stake)

			SELECT @SqlCommand = CONCAT('EXEC DBRPT.bodb_report.dbo.Acc_StatementUpdateTransfer ', ' @custid = ',@CustID,' ,@Amount = ',@TransferAmount,' ,@winlostdate = ''',CONVERT(VARCHAR(50), @winlostdate, 121), '''')
			SELECT @SqlCommand = REPLACE(@SqlCommand,'DBRPT.','')

			EXEC DBCTG.bodb02.dbo.Task_ExecRep_Wrapper 
				@ServerName = '', 
				@AliasName = @alias, 
				@SqlCommand = @SqlCommand, 
				@doNotRunInServer = @doNotRunInServer,
				@Remark = @remark

			IF @ErrCode = 0
			BEGIN
				SET @TransferAmount = @Winlost - @actual_stake

				SELECT @SqlCommand = CONCAT('EXEC DBRPT.bodb_report.dbo.Acc_StatementUpdateTransfer ', ' @custid = ',@bal_custid,' ,@Amount = ',@TransferAmount,' ,@winlostdate = ''',CONVERT(VARCHAR(50), @winlostdate, 121), '''')
				SELECT @SqlCommand = REPLACE(@SqlCommand,'DBRPT.','')

				EXEC DBCTG.bodb02.dbo.Task_ExecRep_Wrapper 
					@ServerName = '', 
					@AliasName = @alias, 
					@SqlCommand = @SqlCommand, 
					@doNotRunInServer = @doNotRunInServer,
					@Remark = @remark
			END

			--Rollback Amount in bodb_report.dbo.rptStatement table before move bet day
			IF @ErrCode <> 0
			BEGIN
				SET @TransferAmount = @Winlost - @actual_stake

				SELECT @SqlCommand = CONCAT('EXEC DBRPT.bodb_report.dbo.Acc_StatementUpdateTransfer ', ' @custid = ',@CustID,' ,@Amount = ',@TransferAmount,' ,@winlostdate = ''',CONVERT(VARCHAR(50), @winlostdate, 121), '''')
				SELECT @SqlCommand = REPLACE(@SqlCommand,'DBRPT.','')

				EXEC DBCTG.bodb02.dbo.Task_ExecRep_Wrapper 
					@ServerName = '', 
					@AliasName = @alias, 
					@SqlCommand = @SqlCommand, 
					@doNotRunInServer = @doNotRunInServer,
					@Remark = @remark

				SELECT @ErrCode = 107
			END
		END
	END
	-- End Update Transfer Amount in bodb_report.dbo.rptStatement table before move bet day

	IF @ErrCode <> 0
	BEGIN

		SELECT @ErrMsg = 'Insert transaction failed.'

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
		WHERE refno = @RefNo AND bettype = @DCAN AND custid = @custid
		
		--rollback balance
		IF @Cust_balance < 0 
		BEGIN 
			SELECT @Cust_balance_ABS = ABS(@Cust_balance)
			--EXEC dbo.Dot_BalanceUpdCredit @custid = @CustID, @Balance = @Cust_balance_ABS
			EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_balance_ABS, @type = @BalanceType
		END 

		IF @ErrCode <> 107 
		BEGIN
			SET @ErrCode = 105	
		END
		
		RETURN
	END

	---Update Credit Balance	
	IF @Cust_balance > 0 
	BEGIN 
 		EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_balance, @type = @BalanceType
	END
		
	---get new transid 
	DECLARE @TransId_New BIGINT
	EXEC Get_Bettrans_TransID @TransID = @TransId_New OUTPUT

	INSERT INTO dbo.Transfer 
		(TransId, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, winlostdate, 
		 creator,recommend,mrecommend,srecommend,currency,actualrate, currencyName, statusID, ip, SerialNo, RepUpdateTime)
	VALUES 
		(@TransId_New, @bal_custID, @bal_Username, @RefNo, @transdate, @DCAN, @transdesc, @winlost , @actual_stake, @winlostdate, 
		 @CustID, @bal_recommend, @bal_mrecommend, @bal_srecommend, @Currency, @actualrate, @currencyName, 131, @ip, @betcheck, SYSDATETIME())

	IF @@ERROR <> 0
	BEGIN
		--Manually rollbackDot_Dep_BettransInsTransaction_V2 
		
		IF @Cust_balance > 0 
		BEGIN 
 			EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @Cust_balance, @type = @BalanceType, @IsForced = 1
		END 
		
		WAITFOR DELAY '000:00:00.002' -- wait for in-house service

		UPDATE dbo.Transfer WITH(ROWLOCK)
		SET	custid = 0, 
			Recommend = 0, 
			MRecommend = 0, 
			SRecommend = 0, 
			Winlost = 0, 
			Actual_Stake = 0, 
			RepUpdateTime = SYSDATETIME()
		WHERE refno = @RefNo AND bettype = @DCAN AND custid IN (@custid, @bal_custid)

		--rollback balance @CustID
		IF @Cust_balance < 0 
		BEGIN 
			SELECT @Cust_balance_ABS = ABS(@Cust_balance)
 			EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_balance_ABS, @type = @BalanceType
		END

		SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 106	
	
		--Rollback Amount in bodb_report.dbo.rptStatement table before move bet day
		IF @winlostdate <= @MoveBetsDay
		BEGIN
			SET @TransferAmount = (@Winlost - @actual_stake)

			SELECT @SqlCommand = CONCAT('EXEC DBRPT.bodb_report.dbo.Acc_StatementUpdateTransfer ', ' @custid = ',@CustID,' ,@Amount = ',@TransferAmount,' ,@winlostdate = ''',CONVERT(VARCHAR(50), @winlostdate, 121), '''')
			SELECT @SqlCommand = REPLACE(@SqlCommand,'DBRPT.','')

			EXEC DBCTG.bodb02.dbo.Task_ExecRep_Wrapper 
				@ServerName = '', 
				@AliasName = @alias, 
				@SqlCommand = @SqlCommand, 
				@doNotRunInServer = @doNotRunInServer,
				@Remark = @remark

			SET @TransferAmount = -(@Winlost - @actual_stake)

			SELECT @SqlCommand = CONCAT('EXEC DBRPT.bodb_report.dbo.Acc_StatementUpdateTransfer ', ' @custid = ',@bal_custid,' ,@Amount = ',@TransferAmount,' ,@winlostdate = ''',CONVERT(VARCHAR(50), @winlostdate, 121), '''')
			SELECT @SqlCommand = REPLACE(@SqlCommand,'DBRPT.','')

			EXEC DBCTG.bodb02.dbo.Task_ExecRep_Wrapper 
				@ServerName = '', 
				@AliasName = @alias, 
				@SqlCommand = @SqlCommand, 
				@doNotRunInServer = @doNotRunInServer,
				@Remark = @remark

		END

		RETURN
	END
	
	UPDATE dbo.Transfer 
		SET transdesc = ISNULL(transdesc,'') + ' (transfer cancelled)',
			RepUpdateTime = SYSDATETIME()
	WHERE transid = @transid

	---------------------------------------------------------------------------------------------------

	DECLARE @LogData VARCHAR(300)

	SELECT @LogData = 
				'Cancel transfer trans custid = ' + CONVERT(VARCHAR(20), @custid) + ', old transid = ' + CONVERT(VARCHAR(20), @transid) + ', amount = ' + CONVERT(VARCHAR(20), @amount)

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