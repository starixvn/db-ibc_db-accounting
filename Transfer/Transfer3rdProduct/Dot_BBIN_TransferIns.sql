/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member,Dot_Bonus" isFunction="0" isNested="0"></info>*/ 
ALTER PROCEDURE [dbo].[Dot_BBIN_TransferIns]
	@CustId				INT,
	@TypeId				TINYINT,
	@Amount				MONEY,
	@Bettype			SMALLINT,
	@BatchRefNo			BIGINT = NULL,
	@RefTransID			BIGINT = NULL,
	@BetCheck			NVARCHAR(50) = '',
	@APositiontaking	SMALLMONEY,
	@MPositiontaking	SMALLMONEY,
	@SPositiontaking	SMALLMONEY,
	@EPositiontaking	SMALLMONEY,
	@PlayerDiscount		DECIMAL(9,8),
	@Discount			DECIMAL(9,8),
	@ADiscount			DECIMAL(9,8),
	@SDiscount			DECIMAL(9,8),
	@TransDesc			NVARCHAR(1000) = '',
	@IP					NVARCHAR(15) = '',
	@RefNo		BIGINT = 0 			OUTPUT,
	@TransID	BIGINT = 0 			OUTPUT,
	@TransDate	DATETIME = NULL 	OUTPUT,
	@ErrCode	INT = 0 			OUTPUT,
	@ErrMsg		NVARCHAR(200) = '' 	OUTPUT
AS
/*
	Creator: 20200411@Sophia.Nguyen
	Task: Insert transfer ticket to BBIN wallet
	DB: DBTXN-bodb02

	Revision: 
		- 20200411@Sophia.Nguyen: Initial SP [Redmine: #131347]

	
	Param's Explanation:
	
	@TypeId		
			0: Cancel
			1: Transfer IN 
			2: Transfer OUT
	@Amount		
			IF @Amount > 0 THEN winlost
			IF @Amount < 0 THEN Actual_Stake
	@Bettype	 
			21008 BBIN Live Casino Transfer
			21009 BBIN Live Casino Cancel Transfer
			
	@BatchRefNo	
			IF NULL then insert new RefNo for new batch.
			IF <> NULL then continue WITHthis RefNo  
		
			EX: 1st Transfer in : Input @BatchRefno = NULL, SP Generate @RefNo and OUTPUT @RefNo
				2nd transfer in : Input @BatchRefNo NOT NULL = Lasted @RefNo , SP not generate new refno and OUTPUT @BatchRefNo 
	
	@RefTransID: Refer TransID when Cancel transfer	 
	
	@BetCheck	
	
	@TransDesc
			IF @TypeID = 1 THEN Bettrans.TransDesc will be: 'Transfer to 3rd party' + @TransDesc
			IF @TypeID = 2 THEN Bettrans.TransDesc will be: 'Transfer FROM 3rd party' + @TransDesc
			IF @TypeID = 0 THEN Bettrans.TransDesc will be: 'Transfer cancelled' + @TransDesc

	@RefNo:		the output Refno of this transaction
	@TransID:	the output TransID of this transaction		
	@TransDate:	the output TransDate of this transaction	
	
	@ErrCode		
			= 0: Transaction recorded successfully.
			> 0: Specific Error.		
	@ErrMsg:	Error description.

*/
BEGIN 
	SET NOCOUNT ON 

	
	DECLARE 
		@Username 		VARCHAR(50),
		@Currency 		TINYINT,
		@CurrencyName 	VARCHAR(5),	
		@ActualRate 	FLOAT,
		@Winlost 		MONEY,	
		@Actual_stake 	MONEY,		
		
		@mrecommend 	INT,
		@recommend 		INT,
		@srecommend 	INT,
		@RoleId 		TINYINT,
		
		@AmountABS 		MONEY,	
		@GivenCredit 	MONEY,	
		@Balance 		MONEY,	
		@NetPosition 	MONEY 
		
	IF @Amount = 0
	BEGIN
		SELECT @ErrMsg = 'Sorry, amount is invalid.', @ErrCode = 101	
		RETURN		
	END

	SELECT	 @Username = Username
			,@Currency = ci.Currency
			,@CurrencyName = e.Currency
			,@ActualRate = e.Actualrate
			,@Recommend = Recommend
			,@MRecommend = MRecommend
			,@SRecommend = SRecommend
			,@RoleId = RoleId 
	FROM CustDB.dbo.Custinfo AS ci WITH(NOLOCK)
	INNER JOIN CustDB.dbo.Exchange AS e WITH(NOLOCK) 
		ON ci.Currency = e.ExchangeId
	WHERE ci.CustId = @CustId	

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT	 @Username = Username
				,@Currency = ci.Currency
				,@CurrencyName = e.Currency
				,@ActualRate = e.Actualrate
				,@Recommend = Recommend
				,@MRecommend = MRecommend
				,@SRecommend = SRecommend
				,@RoleId = RoleId 
		FROM DBCUST.CustDB.dbo.Custinfo AS ci WITH(NOLOCK)
		INNER JOIN DBCUST.CustDB.dbo.Exchange AS e WITH(NOLOCK) 
			ON ci.Currency = e.ExchangeId
		WHERE ci.CustId = @CustId
	END
	
	IF @RoleId <> 1
	BEGIN
		SELECT @ErrMsg = 'Invalid Role ID.', @ErrCode = 102		
		RETURN
	END
		
	--IF @TypeID = 1 THEN Bettrans.TransDesc will be: 'Transfer to 3rd party' + @TransDesc
	--IF @TypeID = 2 THEN Bettrans.TransDesc will be: 'Transfer FROM 3rd party' + @TransDesc
	--IF @TypeID = 0 THEN Bettrans.TransDesc will be: 'Transfer cancelled' + @TransDesc 

	SELECT @TransDesc =  CASE WHEN @TypeId = 1 AND @Bettype = 21008 THEN 'Transfer to 3rd party'  ELSE
							CASE WHEN @TypeId = 2 AND @Bettype = 21008 THEN 'Transfer from 3rd party' ELSE
								CASE WHEN @TypeId = 0 AND @Bettype = 21009 THEN 'Transfer cancelled'  
									ELSE '' END	END END			
						+ CASE WHEN ISNULL(@TransDesc,'') <> '' THEN ' - ' + ISNULL(@TransDesc,'') ELSE '' END
						
	IF @Amount > 0  
	BEGIN	
		SELECT @Winlost = @Amount, @Actual_Stake = 0
	END
	ELSE
	BEGIN 
		SELECT @Actual_Stake = ABS(@Amount), @AmountABS = ABS(@Amount), @Winlost = 0
	END 

	------------------------------------------------
	----Check Member's Balance for tranfer in -------
	IF @Amount < 0 
	BEGIN		
			SELECT 	@GivenCredit = ISNULL(credit,0) 
			FROM 	CustDB.dbo.custinfo WITH(NOLOCK) 
			WHERE   custid = @custid	
			
			EXEC dbo.Acc_BalanceMemberSel 
				@CustID		 = @CustID,
				@Balance	 = @Balance OUTPUT,
				@NetPosition = @NetPosition OUTPUT		
		/*
			Check Member's Balance for tranfer in 
		*/ 	
		
			IF ISNULL(@GivenCredit,0) + ISNULL(@Balance,0) + ISNULL(@NetPosition,0) <= 0
			BEGIN
				SELECT @ErrMsg = 'Sorry, you do not have enough money to transfer in', @ErrCode = 103				
				RETURN		
			END
		END 		
 	
	------------------Insert trans into DB---------------------------------------------------------------
	IF ISNULL(@BatchRefNo,0) = 0  	
	BEGIN	
		EXEC dbo.Acc_SelRefNo @RefNo = @RefNo OUTPUT
		SELECT @RefNo = @RefNo + 100000000000			
	END
	ELSE
	BEGIN 
		SELECT @RefNo = @BatchRefNo
	END 
	
		IF @Amount < 0 
		BEGIN 
			---Update Debit Balance	 
			EXEC Dot_BalanceDebitUpd @CustID = @CustID, @Balance = @AmountABS, @type = 2, @ErrCode = @ErrCode OUTPUT
			
			IF @ErrCode <> 0
			BEGIN
				SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 105	
				RETURN
			END
		END 
		ELSE		
		BEGIN 
			---Update Credit Balance	 
			EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Amount, @type = 2, @ErrCode = @ErrCode OUTPUT
			
			IF @ErrCode <> 0
			BEGIN
				SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 106	
				RETURN
			END		
		END 

		SELECT @TransDate = CURRENT_TIMESTAMP
		
		INSERT INTO dbo.bettrans 
			(custid, username, refno, transdate, matchid, bettype, transdesc,winlost, actual_stake, winlostdate, 
			 creator, recommend, mrecommend, srecommend, currency, actualrate, currencyName, ruben, status, statusID, ip, betcheck, betid, 
			 APositiontaking, MPositiontaking, SPositiontaking, EPositiontaking, PlayerDiscount, Discount, ADiscount, SDiscount)
		VALUES 
			(@CustID, @username, @RefNo, @transdate, 0, @bettype, @transdesc, @winlost, @actual_stake, convert(nvarchar(10), @transdate, 120), 
			 @CustID, @Recommend, @MRecommend, @SRecommend, @Currency, @ActualRate, @CurrencyName, 1, 'Completed', 131, @ip, @BetCheck, 0, 
			 @APositiontaking, @MPositiontaking, @SPositiontaking, @EPositiontaking, @PlayerDiscount, @Discount, @ADiscount, @SDiscount)

		IF @@ERROR <> 0
		BEGIN						
			SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 107	
			
			--rollback balance
			IF @Amount < 0 
			BEGIN	
				---Rollback Credit Balance
				EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @AmountABS, @type = 2, @ErrCode = @ErrCode OUTPUT
			END 
			ELSE
			BEGIN 
				---Rollback Debit Balance
				EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @Amount, @type = 2, @ErrCode = @ErrCode OUTPUT
			END 
			
			RETURN
		END
		ELSE
		BEGIN 
			SELECT @TransID = @@IDENTITY
		END
 
		SET @TransDate = CONVERT(CHAR(30),@TransDate, 121)
		
		----- Mark Transfer in ticket which is cancelled------
		IF @Bettype = 21009 AND ISNULL(@RefTransId ,0) <> 0
		BEGIN 
			UPDATE 	dbo.Bettrans WITH (ROWLOCK)
			SET   	betId = 1
			WHERE 	TransID = @RefTransID					
		END
		
		IF @@ERROR <> 0
		BEGIN						
			SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 108	
			
			--Rollback transaction
			DELETE dbo.Bettrans WITH (ROWLOCK)
			WHERE TransID = @TransID

			--rollback balance
			IF @Amount < 0 
			BEGIN	
				---Rollback Credit Balance
				EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @AmountABS, @type = 2, @ErrCode = @ErrCode OUTPUT
			END 
			ELSE
			BEGIN 
				---Rollback Debit Balance
				EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @Amount, @type = 2, @ErrCode = @ErrCode OUTPUT
			END 
			
			RETURN		
		END
		
		------------Write Log ----------------
	DECLARE @LogData NVARCHAR(4000)	
	SELECT @LogData = '<R CustId="'+ COALESCE(CAST(@CustId AS VARCHAR(20)), SPACE(1)) + '" ' +
						   'TransDesc="'+ COALESCE(CAST(@TransDesc AS NVARCHAR(1000)), SPACE(1)) + '" ' +
	                       'TypeId="'+ COALESCE(CAST(@TypeId AS VARCHAR(20)), SPACE(1)) + '" ' +
						   'Amount="'+ COALESCE(CAST(@Amount AS VARCHAR(20)), SPACE(1)) + '" ' +
						   'Bettype="'+ COALESCE(CAST(@Bettype AS VARCHAR(20)), SPACE(1)) + '" ' +
						   'BatchRefNo="'+ COALESCE(CAST(@BatchRefNo AS VARCHAR(20)), SPACE(1)) + '" ' +
						   'RefTransID="'+ COALESCE(CAST(@RefTransID AS VARCHAR(20)), SPACE(1)) + '" ' +
						   'BetCheck="'+ COALESCE(CAST(@BetCheck AS NVARCHAR(50)), SPACE(1)) + '" ' +
						   'TransID="'+ COALESCE(CAST(@TransID AS VARCHAR(20)), SPACE(1)) + '" ' +
						   'TransDate="'+ COALESCE(CAST(@TransDate AS VARCHAR(20)), SPACE(1)) + '" ' +	
						   'RefNo="'+ COALESCE(CAST(@RefNo AS VARCHAR(20)), SPACE(1)) + '" ' +						   
						   'APositiontaking="'+ COALESCE(CAST(@APositiontaking AS VARCHAR(20)), SPACE(1)) + '" ' +
						   'MPositiontaking="'+ COALESCE(CAST(@MPositiontaking AS VARCHAR(20)), SPACE(1)) + '" ' +
						   'SPositiontaking="'+ COALESCE(CAST(@SPositiontaking AS VARCHAR(20)), SPACE(1)) + '" ' +
						   'EPositiontaking="'+ COALESCE(CAST(@EPositiontaking AS VARCHAR(20)), SPACE(1)) + '" ' +
						   'PlayerDiscount="'+ COALESCE(CAST(@PlayerDiscount AS VARCHAR(20)), SPACE(1)) + '" ' +
						   'Discount="'+ COALESCE(CAST(@Discount AS VARCHAR(20)), SPACE(1)) + '" ' +
						   'ADiscount="'+ COALESCE(CAST(@ADiscount AS VARCHAR(20)), SPACE(1)) + '" ' +
						   'SDiscount="'+ COALESCE(CAST(@SDiscount AS VARCHAR(20)), SPACE(1)) + '" ' +						  
						   'IP="'+ COALESCE(CAST(@IP AS VARCHAR(20)), SPACE(1)) + '" ' +	
						   'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(20)), SPACE(1)) + '" ' +						   
						   'ErrMsg="'+ COALESCE(CAST(@ErrMsg as NVARCHAR(200)),SPACE(1)) + '" ' +
						   'SPName ="'+ COALESCE(CAST('Dot_BBIN_TransferIns' AS VARCHAR(30)), SPACE(1))  + '" />'


	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @CustID, @FromCustID = 0, @ToCustID = @CustID, @IP = @IP, @Doing = @LogData
	END TRY
	BEGIN CATCH
		SELECT @LogData = @LogData + ' ErrMsg=' + ERROR_MESSAGE()
		EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @CustID, @FromCustID = 0, @ToCustID = @CustID, @IP = @IP, @Doing = @LogData
	END CATCH
	
 
END