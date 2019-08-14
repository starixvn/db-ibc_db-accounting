/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet,bodbExtAccNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_BettransDelTransaction]
	@refno bigint = 0,
	@custid int, --CustId of selected account
	@UserID int, --CustID of Login Admin
	@IP nvarchar(15)='',
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT 
AS
/*	Created by: [Creator]
	Task:	For Delete Transaction (transfer)
			Account / Lefmenu / Statement / Detail/ Del
			
	Original: Admin_DeleteTransaction
	Revisions:
		- 20090524@Thien: no longer use CustBetCredit, so remove temp table and update section
		- 20090828@HuyNguyen: replace [DeleteBets] --> [DeleteTrans]
		- 20091012@Kiwi: modify written log	
		- 20101225@Lukas: Re-arrange bettype
		- 20110921@Lukas: change the way searching effected transactions.		
		- 20111125@Sophia: Update banlance credit/ debit for customer
		- 20111028@Jamie: Correct UPDATE Credit/Debit Balance & check settled date 
		- 20120411@Sophia: Revise UPDATE Credit/Debit Balance
		- 20120719@Sophia:  . Add new reverse rows to delete transaction, not update transaction to zero anymore
							. Add new parameter @IP
		- 20120720@Thien: Check to not allow to transfer before balance up date
		- 20120723@Sophia: Add column ruben to temp table @Reversal
		- 20120731@Sophia: Update Liveindicator = 1 for marking deleted transactions
		- 20120810@Sophia: Use @transdesc to avoid SQL insert error
		- 20130201@Elodie: Change link server DB03 to DBPOLICY
						   Write more log on DBTXN server in case of DBLOG server failure
		- 20131108@Elodie: Splitting bodb02 into CustDB (Call CustInfo by link database)  	
		- 20141226@Tom: Update Transfer Amount in bodb_report.dbo.rptStatement table before move bet day(Redmine#15274)							   						   
		- 20150808@Elodie: Balance Improvement [Redmine:#40125]
		- 20151021@Elodie: Set @IsForce = 1 for updating balance debit [Redmine:#40125]
		- 20180808@Helen: Get Code from Production  + DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20181112@Sophia: Add Transfer Collection [redmine: #98621]
		- 20190812@Bobby: AddDelTXN - Update checking constraint [Redmine:118530]
*/
BEGIN

	SET NOCOUNT ON 
	--Check permission for account site: @phuc20080213
	EXEC DBPOL.NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[DeleteTrans]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN

	IF @refno <> 0 
	BEGIN
		DECLARE	@winlostdate	DATETIME,
				@liveindicator	BIT,
				@transdesc		NVARCHAR(300),
				@IsCollection   BIT
				

		DECLARE @Reversal TABLE (	TransID BIGINT,
									custid INT,
									transdate DATETIME,
									Username NVARCHAR(50),
									refno BIGINT,
									winlost MONEY,
									actual_stake MONEY,
									winlostdate SMALLDATETIME,
									transdesc NVARCHAR(300),
									creator INT,
									bettype SMALLINT,
									matchid INT,
									actualrate FLOAT,
									recommend INT,
									mrecommend INT,
									srecommend INT,
									currency TINYINT,
									CurrencyName NVARCHAR(50),
									ip NVARCHAR(15) ,
									status NVARCHAR(10),
									statusID TINYINT,
									ruben TINYINT,
									liveindicator BIT,
									OddsID INT
								)

		DECLARE @TransIDs AS TABLE (transID BIGINT)

	----insert transfer data into @Reversal
		INSERT INTO @Reversal 
			(	transid, custid, transdate, Username, refno, winlost, actual_stake, winlostdate, transdesc, creator,
				bettype, matchid, actualrate, recommend, mrecommend, srecommend, currency, CurrencyName, ip, status, statusID, ruben, liveindicator, OddsID )
		SELECT	transid, custid, transdate, Username, refno, winlost, actual_stake, winlostdate, transdesc, creator,
				bettype, matchid, actualrate, recommend, mrecommend, srecommend, currency, CurrencyName, ip, status, statusID, ruben, liveindicator, OddsID
		FROM	bettrans WITH (NOLOCK)
		WHERE	refno = @refno AND matchid = 0 AND bettype > 20000 


		SELECT	top 1 @winlostdate = winlostdate, @liveindicator = liveindicator, @transdesc = transdesc, @IsCollection = OddsID
		FROM	@Reversal

		--------------------------vvvvv-------------------------------------
		--Check to not allow to transfer before balance up date
		DECLARE @BalanceUpDay SMALLDATETIME
			, @archivedDate SMALLDATETIME
			, @transferDate SMALLDATETIME

		SELECT TOP 1 @BalanceUpDay = winlostdate
		FROM dbo.Bettrans WITH (NOLOCK)
		WHERE bettype = 20000
			AND matchid = 0
			AND custid = 3

		SELECT @archivedDate = MAX(winlostdate)
			, @transferDate = GETDATE()
		FROM dbo.Task_ArchiveDate WITH (NOLOCK)

		-- at this time, server is processing adding tickets into transfer_fi table. So not allow to transfer.
		IF DATENAME(WEEKDAY, @transferDate) IN ('Thursday')
			AND @BalanceUpDay + 7 < @transferDate --this week day BU not processed yet
		BEGIN
			IF @winlostdate <= @archivedDate -- Before the new BU date
			BEGIN
				SELECT @ErrMsg = CASE @Language
						WHEN 'E'
							THEN 'Not allow to add transaction before balance up date - ' + convert(NVARCHAR(10), @BalanceUpDay + 7, 120) + '.'
						END
					, @ErrCode = 100

				RETURN
			END
		END
		ELSE IF @winlostdate < @BalanceUpDay --Before last BU date
		BEGIN
			SELECT @ErrMsg = CASE @Language
					WHEN 'E'
						THEN 'Not allow to add transaction before balance up date - ' + convert(NVARCHAR(10), @BalanceUpDay, 120) + '.'
					END
				, @ErrCode = 101

			RETURN
		END

		----------------------^^^^^^----------------------------------

		------ Check transaction had been deleted or not
		IF @liveindicator = 1
		BEGIN 
			SELECT	@ErrMsg ='Unable to delete this transaction due to it is marked as "Deleted"!',
					@ErrCode = 102
			RETURN 		
		END

	---*** Update balance
		CREATE TABLE #BeforeUpd (
				custid		 INT,
				balance		 MONEY)
			
		CREATE TABLE #AfterUpd(
					custid		 INT,
					balance		 MONEY)
					
		--Get data before update
		INSERT INTO #BeforeUpd (custid, balance)
		SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
		FROM	bettrans b WITH (NOLOCK)
			INNER JOIN	CustDB.dbo.custInfo c WITH (NOLOCK) 
			ON	b.custid = c.custID
		WHERE	b.refno = @refno AND matchid = 0 AND bettype > 20000
				AND c.roleid = 1
		GROUP BY b.CustID
		


	---- Begin reversal
		SET @transdesc = '(Reversal) ' + @transdesc
		
		-----Bettrans
		INSERT INTO bettrans (	custid, transdate, Username, refno, winlost, actual_stake, winlostdate, transdesc, creator,
								bettype, matchid, actualrate, recommend, mrecommend, srecommend, currency, CurrencyName, ip, status, statusID, ruben, liveindicator, OddsID)
		OUTPUT  INSERTED.transid into @TransIDs
		SELECT	custid, CURRENT_TIMESTAMP, Username, refno, actual_stake, winlost, winlostdate, @transdesc, @UserID,
				bettype, matchid, actualrate, recommend, mrecommend, srecommend, currency, CurrencyName, @IP, status, statusID, ruben, 1, OddsID
		FROM	@Reversal

		IF @@ERROR <> 0
		BEGIN
			SELECT	@ErrMsg ='Delete the transaction unsuccessfully!',
					@ErrCode = 103
			RETURN 
		END

	 ---Update Liveindicator = 1 for marking deleted transaction
		UPDATE	bettrans WITH (ROWLOCK) 
		SET		liveindicator = 1
		WHERE	transid IN (Select transid from @Reversal)

		IF @@ERROR <> 0
		BEGIN
			DELETE  bettrans WITH (ROWLOCK) 
			WHERE	transid IN (SELECT transid FROM @TransIDs)
			
			DELETE  Transfer_Coll WITH (ROWLOCK) 
			WHERE	transid IN (SELECT transid FROM @TransIDs)
		
			SELECT	@ErrMsg ='Delete the transaction unsuccessfully!',
					@ErrCode = 104
			RETURN 
		END

		-----Transfer_Coll 
		IF @IsCollection = 1
		INSERT INTO Transfer_Coll 
				(CustId, WinlostDate, TransDate, Bettype, Debit, Credit, Currency, ActualRate, 
				TransID, RefNo, Username, Recommend, MRecommend, SRecommend, Creator ,TransDesc, IP )
		SELECT 	CustId, WinlostDate, TransDate, Bettype, Actual_Stake, Winlost, Currency, ActualRate, 
				TransID, RefNo, Username, Recommend, MRecommend, SRecommend, Creator ,TransDesc, IP
		FROM 	dbo.Bettrans WITH (NOLOCK) 
		WHERE 	TransID IN (SELECT transid FROM @TransIDs)
		
		IF @@ERROR <> 0
		BEGIN
			DELETE  bettrans WITH (ROWLOCK) 
			WHERE	transid IN (SELECT transid FROM @TransIDs)
			
			DELETE  Transfer_Coll WITH (ROWLOCK) 
			WHERE	transid IN (SELECT transid FROM @TransIDs)		
		
			UPDATE	bettrans WITH (ROWLOCK) 
			SET		liveindicator = 0
			WHERE	transid IN (Select transid from @Reversal)
					
			SELECT	@ErrMsg ='Delete the transaction unsuccessfully!',
					@ErrCode = 104
			RETURN 
		END
				
		
		-- Update Transfer Amount in bodb_report.dbo.rptStatement table before move bet day
		DECLARE @MoveBetsDay DATETIME
		SELECT @MoveBetsDay = MAX(eventdate)
		FROM dbo.match14 WITH (NOLOCK)

		DECLARE @amount money

		IF @winlostdate <= @MoveBetsDay
		BEGIN
			SELECT TOP 1 @custid = custid,@amount = -(b.winlost - b.actual_stake) FROM	@Reversal b

			EXEC [DBRPT].bodb_report.dbo.[Acc_StatementUpdateTransfer]
				@custid = @custid
				,@Amount = @amount
				,@winlostdate = @winlostdate
				,@ErrCode = @ErrCode OUTPUT
				,@ErrMsg = @ErrMsg OUTPUT
			
			IF @ErrCode <> 0
				BEGIN
					DELETE  dbo.bettrans WITH (ROWLOCK) 
					WHERE	transid IN (SELECT transid FROM @TransIDs)
					
					DELETE  Transfer_Coll WITH (ROWLOCK) 
					WHERE	transid IN (SELECT transid FROM @TransIDs)
						
					--20150808@Elodie: rollback liveindicator = 0
					UPDATE	bettrans WITH (ROWLOCK) 
					SET		liveindicator = 0
					WHERE	transid IN (Select transid from @Reversal)

					SELECT	@ErrMsg ='Delete the transaction unsuccessfully!',
							@ErrCode = 105
					RETURN 
				END
						
			SELECT TOP 1 @custid = custid,@amount = -(b.winlost - b.actual_stake) FROM	@Reversal b WHERE @custid <> custid

			IF @@ROWCOUNT = 1
			BEGIN
				EXEC [DBRPT].bodb_report.dbo.[Acc_StatementUpdateTransfer]
					@custid = @custid
					,@Amount = @amount
					,@winlostdate = @winlostdate
					,@ErrCode = @ErrCode OUTPUT
					,@ErrMsg = @ErrMsg OUTPUT		
			
				IF @ErrCode <> 0
					BEGIN
						DELETE  dbo.bettrans WITH (ROWLOCK) 
						WHERE	transid IN (SELECT transid FROM @TransIDs)
						
						DELETE  Transfer_Coll WITH (ROWLOCK) 
						WHERE	transid IN (SELECT transid FROM @TransIDs)

						--20150808@Elodie: rollback liveindicator = 0
						UPDATE	bettrans WITH (ROWLOCK) 
						SET		liveindicator = 0
						WHERE	transid IN (Select transid from @Reversal)

						SELECT TOP 1 @custid = custid,@amount = (b.winlost - b.actual_stake) FROM	@Reversal b WHERE @custid <> custid

						EXEC [DBRPT].bodb_report.dbo.[Acc_StatementUpdateTransfer]
							@custid = @custid
							,@Amount = @amount
							,@winlostdate = @winlostdate
							--,@ErrCode = @ErrCode OUTPUT
							--,@ErrMsg = @ErrMsg OUTPUT
		
						SELECT	@ErrMsg ='Delete the transaction unsuccessfully!',
								@ErrCode = 106
						RETURN 
					END		
			END
		END

	--Get data after update
		INSERT INTO #AfterUpd (custid, balance)
		SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
		FROM	bettrans b WITH (NOLOCK)
			INNER JOIN	CustDB.dbo.custInfo c WITH (NOLOCK) 
			ON	b.custid = c.custID
		WHERE	b.refno = @refno AND matchid = 0 AND bettype > 20000
				AND c.roleid = 1
		GROUP BY b.CustID


		DECLARE @tblPending TABLE (CustID INT, Balance	MONEY)
		DECLARE @MemID INT, @Balance	MONEY
		INSERT INTO @tblPending (CustID, Balance)
		SELECT		a.custid, (a.balance - b.balance) as Balance
		FROM		#BeforeUpd b
		INNER JOIN	#AfterUpd a 	
				ON	a.custid = b.custid
		
		DECLARE CS_MemBal 
		CURSOR FOR  
		SELECT CustID, Balance
		FROM @tblPending 
	   		 
		OPEN CS_MemBal  
		FETCH NEXT FROM CS_MemBal INTO @MemID, @Balance
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			IF @Balance > 0
				EXEC Dot_BalanceCreditUpd @CustID = @MemID, @balance = @Balance, @type = 2

			IF @Balance < 0
			BEGIN
				DECLARE @ABS_Balance MONEY
				SELECT @ABS_Balance = ABS(@Balance)
							EXEC Dot_BalanceDebitUpd @CustID = @MemID, @balance = @ABS_Balance, @type = 2, @IsForced = 1
			END

			FETCH NEXT FROM CS_MemBal INTO @MemID, @Balance 
		END  
	  
		CLOSE CS_MemBal  
		DEALLOCATE CS_MemBal  

		EXEC dbo.Acc_ExchangeRateUpdisDeleted @refNo = @refno

		declare @LogData varchar(200)
		Select @LogData = 'Delete transaction for custid :' + convert(varchar(20), @CustID) + ' Ref.NO ' + convert(varchar(20), @RefNo)
		
		BEGIN TRY

			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = 0, @ToCustID = @CustID, @IP = @IP, @Doing = @LogData
		END TRY
		BEGIN CATCH 
			Select @LogData = @LogData + ' ErrMsg=' + error_message()
			EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = 0, @ToCustID = @CustID, @IP = @IP, @Doing = @LogData
		END CATCH

	END
END
GO	