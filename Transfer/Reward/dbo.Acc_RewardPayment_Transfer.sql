/*<info serverAlias="DBSIC-bodb02" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_RewardPayment_Transfer]
	@FromCustId		INT, --- super custid
	@ToCustId		INT, --- expense code custid
	@MaxTransId		BIGINT,
	@Amount			MONEY,
	@Creator		INT,
	@SiteDBGroupId	SMALLINT,
	@ExchangeRate	FLOAT = 1,
	@IP				VARCHAR(45)	= '',
	@Language		VARCHAR(2)	= 'E',
	@RefNo			BIGINT = 0 OUTPUT,
	@ErrCode		INT	=	0	OUTPUT,
	@ErrMsg			NVARCHAR(200) =	''	OUTPUT,
	@PaymentLog		NVARCHAR(MAX) = NULL OUTPUT
AS
/*
	Created by: 20240826@Bobby
	Task: 209633 - CreditReward - Add new transfer
	DB: DBAGE.bodb02
	
	Revisions:
		- 20240826@Bobby: Init [Redmine: #209633]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @mrecommend		INT,
		@recommend			INT,
		@srecommend			INT,
		@roleId				TINYINT,
		@transId			BIGINT,
		@to_transid			BIGINT,
		@currencyId			INT,
		@actualRate			FLOAT,
		@walletId			TINYINT = 1, --1: Whitelabel wallet, 2: Reward wallet
		@transDate			DATETIME,
		@winlostDate		SMALLDATETIME,
		@Server_SiteDBGroupID SMALLINT,
		@username			VARCHAR(50),

		---------------
		
		@to_mrecommend		INT,
		@to_recommend		INT,
		@to_srecommend		INT,
		@to_currencyId		INT,
		@to_actualRate		FLOAT,
		@to_username		VARCHAR(50),

		------------
		@bettype			INT,
		@from_TransDesc		NVARCHAR(4000),
		@to_TransDesc		NVARCHAR(4000),
		@ToCurrCode			VARCHAR(12),
		@FromCurrCode		VARCHAR(12),
		@ToCurrName			NVARCHAR(10),
		@FromCurrName		NVARCHAR(10),
		@Remark				NVARCHAR(4000),
		@RemarkFromCurr		NVARCHAR(70), 
		@RemarkToCurr		NVARCHAR(70),
		@PaymentDate		DATE,
		@IsDirectCheck		BIT
	;

	--Check the SiteDBGroupID of CustID and Server is match
	SELECT @Server_SiteDBGroupID = dbo.f_Get_SiteDBGroupID();
	IF ISNULL(@SiteDBGroupID,-1) <> @Server_SiteDBGroupID
	BEGIN
		SELECT @ErrCode = 101,
			@ErrMsg = 'Executing on invalid server. Please check SiteDBGroupID information.'
		RETURN;		
	END

	--Saba Rewards Promotion Code
	--SET @ToCustId = 7178333 --PHL-MYR

	SELECT 
		-----------from
		@currencyId		= IIF(@FromCustId = ci.custid, ci.currency, @currencyId)
		,@actualrate	= IIF(@FromCustId = ci.custid, e.actualrate, @actualrate)
		,@mrecommend	= IIF(@FromCustId = ci.custid, ci.mrecommend, @mrecommend)
		,@recommend		= IIF(@FromCustId = ci.custid, ci.recommend, @recommend)
		,@srecommend	= IIF(@FromCustId = ci.custid, ci.srecommend, @srecommend)
		,@username		= IIF(@FromCustId = ci.custid, ci.username, @username)
		,@roleId		= IIF(@FromCustId = ci.custid, ci.roleId, @roleId)
		,@FromCurrCode	= IIF(@FromCustId = ci.custid, e.Code, @FromCurrCode)
		,@FromCurrName	= IIF(@FromCustId = ci.custid, e.currency, @FromCurrName)
		-----------to
		,@to_currencyId	= IIF(@ToCustId = ci.custid, ci.currency, @to_currencyId)
		,@to_actualrate	= IIF(@ToCustId = ci.custid, e.actualrate, @to_actualrate)
		,@to_mrecommend	= IIF(@ToCustId = ci.custid, ci.mrecommend, @to_mrecommend)
		,@to_recommend	= IIF(@ToCustId = ci.custid, ci.recommend, @to_recommend)
		,@to_srecommend	= IIF(@ToCustId = ci.custid, ci.srecommend, @to_srecommend)
		,@to_username	= IIF(@ToCustId = ci.custid, ci.username, @to_username)
		,@ToCurrCode	= IIF(@ToCustId = ci.custid, e.Code, @ToCurrCode)
		,@ToCurrName	= IIF(@ToCustId = ci.custid, e.currency, @ToCurrName)

	FROM CustDB.dbo.customer AS ci WITH (NOLOCK)
		INNER JOIN CustDB.dbo.exchange AS e WITH (NOLOCK) ON ci.currency = e.exchangeid
		INNER JOIN CustDB.dbo.[Site] s WITH(NOLOCK) ON s.[site] = ci.[site]
	WHERE ci.custid IN (@FromCustId, @ToCustId)
		AND s.SiteDBGroupID = @Server_SiteDBGroupID
	;

	--TODO: check direct account status
	WITH CTE_DirectAccount AS (
		SELECT 
			SUM(IIF(cd.custid = @FromCustId, 1, 0)) AS DummyCount,
			SUM(IIF(cd.custid <> @FromCustId, 1, 0)) AS UplineCount
		FROM CUSTDB.dbo.Acc_CustDirect cd WITH(NOLOCK) 
		WHERE cd.custid IN (@srecommend, @mrecommend, @recommend, @FromCustId)
			AND cd.roleid >= @roleId
	)
	SELECT @IsDirectCheck = IIF(ck.DummyCount = 0 AND ck.UplineCount > 0, 1, 0)
	FROM CTE_DirectAccount ck;

	IF (@srecommend IS NULL AND @to_srecommend IS NULL) 
		OR @FromCustID = @ToCustID 
		OR (@roleId <> 4 AND @IsDirectCheck = 0)
	BEGIN
		SELECT @ErrCode = 102,
			@ErrMsg		= 'Sorry, invalid From Cust or To Cust.'
		RETURN
	END

	IF ISNULL(@Amount,0) = 0 OR ISNULL(@ExchangeRate, 0) = 0
	BEGIN
		SELECT @ErrCode = 103,
			@ErrMsg = 'Sorry, amount or Ex.rate is invalid.'	
		RETURN
	END

	IF (@FromCurrCode <> @ToCurrCode AND 'MYR' NOT IN (@FromCurrCode, @ToCurrCode))
	BEGIN
		SELECT @ErrMsg = N'The two accounts have different currency code, but neither of them includes the RM currency. Please check again Users Info.'
			, @ErrCode = 104
		RETURN
	END

	IF (@FromCurrName = @ToCurrName AND @ExchangeRate <> 1)
	BEGIN
		SELECT @ErrMsg = N'The two accounts have same currency name, but Ex.rate is different 1.'
			, @ErrCode = 104
		RETURN
	END

	--TODO: Control flow
	DECLARE @stepDone	SMALLINT,
		@confirmData	NVARCHAR(MAX)
	;

	SELECT @PaymentDate = NULL,
		@ErrCode		= 0, 
		@ErrMsg			= NULL,
		@stepDone		= 0
	;

	BEGIN TRY
		--GEN RefNo to refer SabaWalletTicket - TransferExtra - Transfer tables
		IF ISNULL(@RefNo, 0) = 0
			EXEC dbo.Get_Refno_Transid @RefNo = @RefNo OUTPUT;
		--GEN transid FROM
		IF @srecommend > 0
			EXEC dbo.Get_Bettrans_TransID @TransID = @transId OUTPUT;
		--GEN transId TO
		IF @to_srecommend > 0
			EXEC dbo.Get_Bettrans_TransID @TransID = @to_transid OUTPUT;
		
		SELECT @transDate			= GETDATE(),
			@WinlostDate			= CAST(ISNULL(@WinlostDate, @transDate) AS DATE),
			@bettype				= 30001, -- Transfer between Super vs Finance
			@from_TransDesc			= CONCAT(N'To Customer: ', @to_username, ' - ', @ToCurrName, ' ', (ABS(@Amount) * @ExchangeRate)),
			@to_TransDesc			= CONCAT(N'From Customer: ', @username, ' - ', @FromCurrName, ' ', ABS(@Amount))
		;

		--TODO: #1 - DO confirm payment status on @FromCustId
		SELECT @confirmData = (SELECT t.CustId, t.MaxTransId, t.RefNo, t.IsDirect
							FROM (VALUES(@FromCustId, @MaxTransId, @RefNo, @IsDirectCheck)) AS t (CustId, MaxTransId, RefNo,IsDirect)
							WHERE @srecommend > 0
							FOR JSON PATH);

		--select @confirmData [@confirmData]
		IF ISJSON(@confirmData) = 1
		BEGIN
			SET @PaymentLog = '';

			EXEC dbo.Acc_RewardPayment_Confirm 
				@Data		= @confirmData,
				--@Action		= 'Transfer',
				@Creator	= @Creator,
				@IP			= @IP,
				@Language	= @Language,
				@ErrCode	= @ErrCode OUTPUT,
				@ErrMsg		= @ErrMsg OUTPUT,
				@PaymentDate = @PaymentDate OUTPUT,
				@PaymentLog	 = @PaymentLog OUTPUT
			;

			--select @PaymentDate [@PaymentDate], @ErrCode, @ErrMsg

			IF @ErrCode > 0 --OR @PaymentDate IS NULL
			BEGIN
				SELECT @ErrMsg = IIF(LEN(@ErrMsg) > 0, @ErrMsg, 'There is no payment''s confirmation.')
					, @ErrCode = 105
				RETURN
			END
			ELSE
				SET @stepDone |= POWER(2, 1); --> Mark done payment confirmation on SUPER
		END

		--TODO: #2 - DO transfer on SMA vs Finance
		BEGIN TRAN
		--TODO: Insert transferExtra
		IF OBJECT_ID(N'dbo.TransferExtra') > 0
		BEGIN
			INSERT INTO dbo.TransferExtra (
				TransId
				,CustID
				,Recommend
				,Mrecommend
				,Srecommend
				,CurrencyID
				,ActualRate
				,Bettype
				,Credit
				,Debit
				,TransDate
				,WinlostDate
				,TransDesc
				,RefNo
				,WalletID
				,Creator
				,SiteDBGroupID
				,RepUpdateTime
			)
			SELECT TransId
				,CustID
				,Recommend
				,Mrecommend
				,Srecommend
				,CurrencyID
				,ActualRate
				,Bettype
				,Credit
				,Debit
				,TransDate
				,WinlostDate
				,TransDesc
				,RefNo
				,WalletID
				,Creator
				,SiteDBGroupID
				,RepUpdateTime
			FROM (
				VALUES(
					--- from customer
					@TransId
					,@FromCustID
					,@Recommend
					,@Mrecommend
					,@Srecommend
					,@CurrencyId
					,@ActualRate
					,@bettype
					,IIF(@Amount > 0, @Amount, 0) -- credit
					,IIF(@Amount > 0, 0, ABS(@Amount)) -- debit
					,@TransDate
					,@WinlostDate
					,@from_TransDesc
					,@RefNo
					,@WalletID
					,@Creator
					,IIF(@TransId > 0, @SiteDBGroupID, 0)
					,SYSDATETIME())
			) AS t (TransId,CustID,Recommend,Mrecommend,Srecommend,CurrencyID,ActualRate,Bettype,Credit,Debit,TransDate,WinlostDate,TransDesc,RefNo,WalletID,Creator,SiteDBGroupID,RepUpdateTime)
			WHERE SiteDBGroupID = @Server_SiteDBGroupID
			;SET @stepDone |= IIF(@@ROWCOUNT = 1 AND @@ERROR = 0, POWER(2, 2), 0); --MARK done insert transferExtra table
		END
		--- TODO: Insert Transfer
		INSERT INTO dbo.[Transfer](
			transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
			winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
			scomm, swinlost, [ip], statusID, RepUpdateTime
		)
		SELECT 
			transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
			winlostdate, currencyId, actualrate, currencyName, recommend, mrecommend, srecommend, 
			scomm, swinlost, [ip], 131 AS statusID, RepUpdateTime
		FROM (
			VALUES(
				--- to customer
				@to_TransId
				,@ToCustID, @to_username
				,@to_Recommend
				,@to_Mrecommend
				,@to_Srecommend
				,@to_CurrencyId, @ToCurrName
				,@to_ActualRate
				,@bettype
				,IIF(@Amount > 0, 0, ABS(@Amount)) * @ExchangeRate -- winlost
				,IIF(@Amount > 0, @Amount, 0) * @ExchangeRate -- actual_stake
				,@TransDate
				,@WinlostDate
				,@to_TransDesc
				,@RefNo
				,@Creator
				,IIF(@to_TransId > 0, @SiteDBGroupID, 0)
				,@IP, 0, 0
				,SYSDATETIME())
		) AS t (TransId,CustID,username,Recommend,Mrecommend,Srecommend,CurrencyID,CurrencyName,ActualRate,Bettype,winlost,actual_stake,TransDate,WinlostDate,TransDesc,RefNo,Creator,SiteDBGroupID
			,[IP],scomm,swinlost,RepUpdateTime)
		WHERE SiteDBGroupID = @Server_SiteDBGroupID
		;SET @stepDone |= IIF(@@ROWCOUNT = 1 AND @@ERROR = 0, POWER(2, 3), 0); --MARK done insert transfer table

		COMMIT;

	END TRY
	BEGIN CATCH 
		SELECT @ErrCode = 109,
			@ErrMsg = CONCAT('CreditReward: Insert reward payment transfer failed. Error: ', ERROR_MESSAGE())
		;

		IF @@TRANCOUNT > 0
			ROLLBACK;

		--TODO: rollback Confirm payment
		IF POWER(2, 1) & @stepDone > 0
		BEGIN
			EXEC dbo.Acc_RewardPayment_Confirm_Rollback 
				@Data			= @confirmData,
				@Action			= 'Transfer',
				@ErrCode		= @ErrCode OUTPUT,
				@ErrMsg			= @ErrMsg OUTPUT
			;
		END

		----TODO: rollback TransferExtra
		--UPDATE dbo.TransferExtra WITH(ROWLOCK, UPDLOCK)
		--SET custid = 0, Recommend = 0, Mrecommend=0, Srecommend=0, Credit=0, Debit=0, RepUpdateTime = SYSDATETIME()
		--WHERE TransId  IN (@TransId, @to_TransId)
		--	AND POWER(2, 2) & @stepDone > 0
		--;

		----TODO: rollback Transfer
		--UPDATE dbo.[Transfer] WITH(ROWLOCK, UPDLOCK)
		--SET custid = 0, Recommend = 0, Mrecommend=0, Srecommend=0, winlost=0, actual_stake=0, RepUpdateTime = SYSDATETIME()
		--WHERE TransId  IN (@TransId, @to_TransId)
		--	AND POWER(2, 3) & @stepDone > 0
		--;
			
	END CATCH

	--TODO: write userlog successfully
	DECLARE @LogData VARCHAR(1000)
	IF @ErrCode = 0 --success
	BEGIN
		SELECT @LogData = CONCAT('CreditReward: Insert transfer fromcustid = ', @fromcustid,' tocustid=', @tocustid ,', amount = ', @amount, ', refno = ', @refNo)
	END
	ELSE -- error logs
	BEGIN
		SELECT @LogData = CONCAT(@ErrMsg, '. Transfer fromcustid = ', @fromcustid,' tocustid=', @tocustid ,', amount = ', @amount, ', refno = ', @refNo)
	END

	BEGIN TRY	
		--SELECT @LogData [@LogData]
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
								@UserID		= @FromCustid, 
								@FromCustID = @FromCustID, 
								@ToCustID	= @ToCustID, 
								@IP			= @IP, 
								@Doing		= @LogData 
	END TRY
	BEGIN CATCH
		-- IF write log error: not RETURN error code
		SELECT @LogData = @LogData + ' ErrMsg: ' + ERROR_MESSAGE()
			
		EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
							@UserID		= @FromCustID, 
							@FromCustID = @FromCustID, 
							@ToCustID	= @ToCustID, 
							@IP			= @IP, 
							@Doing		= @LogData
	END CATCH
END
