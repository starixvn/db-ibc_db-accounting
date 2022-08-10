/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet,bodbExtAccNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_BettransDelTransaction]
	@refno bigint = 0,
	@custid int, --CustId of selected account
	@UserID int, --CustID of Login Admin
	@IP nvarchar(15)='',
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@SiteDBGroupID	SMALLINT
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
		- 20200828@Sol: hotfix - transfer - duplicated transid by page split/nolock [Redmine:140461]
		- 20211122@Danny: Split transfer tickets out of bettrans [Redmine: #164196]
		- 20220721@Danny: get transid and refno with new generation [Redmine: #175670]
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
		
		DECLARE @Reversal TABLE (	
				Seq INT IDENTITY(1,1) PRIMARY KEY,
				TransID BIGINT,
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
				actualrate FLOAT,
				recommend INT,
				mrecommend INT,
				srecommend INT,
				currency TINYINT,
				CurrencyName NVARCHAR(50),
				ip VARCHAR(45) ,
				statusID TINYINT,
				liveindicator BIT,
				OddsID INT
		)

		DECLARE @TransIDs AS TABLE (transID BIGINT, seq TINYINT)
		DECLARE @tblUniqueCustIds TABLE (CustId INT)

		----get unique custid to use in where condition of inserting @Reversal for index seek used
		INSERT INTO @tblUniqueCustIds (custid)
		SELECT	DISTINCT custid
		FROM	dbo.Transfer WITH (NOLOCK)
		WHERE	refno = @refno AND bettype > 20000

		-- handle sitegroup DB
		DECLARE @SiteGroupInfo TABLE(CustID INT, SiteDBGroupID SMALLINT, LinkedServerName  VARCHAR(512), ClientAccessName VARCHAR(512), AGIP VARCHAR (50))
		DECLARE @cs_CustID INT

		DECLARE CS_CustIDs
		CURSOR FOR  
		SELECT CustID FROM @tblUniqueCustIds 
	   		 
		OPEN CS_CustIDs  
		FETCH NEXT FROM CS_CustIDs INTO @cs_CustID
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			INSERT INTO @SiteGroupInfo (SiteDBGroupID, LinkedServerName, ClientAccessName, AGIP)
			EXEC DBCUST.CustDB.dbo.Acc_SiteDBConfigSel @CustID = @cs_CustID

			UPDATE @SiteGroupInfo SET CustID = @cs_CustID WHERE CustID IS NULL

			FETCH NEXT FROM CS_CustIDs INTO @cs_CustID
		END
		
		CLOSE CS_CustIDs  
		DEALLOCATE CS_CustIDs  

		----insert transfer data into @Reversal
		INSERT INTO @Reversal 
			(	transid, custid, transdate, Username, refno, winlost, actual_stake, winlostdate, transdesc, creator,
				bettype, actualrate, recommend, mrecommend, srecommend, currency, CurrencyName, ip, statusID, liveindicator, OddsID)
		SELECT	t.transid, custid, transdate, Username, refno, winlost, actual_stake, winlostdate, transdesc, creator,
				bettype, actualrate, recommend, mrecommend, srecommend, currency, CurrencyName, ip, statusID, ISNULL(ti.IsDel,0), ISNULL(ti.IsCollection,0)
		FROM	dbo.transfer t WITH (NOLOCK)
		LEFT JOIN dbo.TransferInfo ti WITH (NOLOCK) ON t.TransId = ti.TransId
		WHERE	refno = @refno  AND bettype > 20000 
				AND t.custid IN (SELECT custid FROM @SiteGroupInfo WHERE SiteDBGroupID = @SiteDBGroupID)

		DECLARE @rowCount TINYINT = 0
		SELECT @rowCount = COUNT(1) FROM @Reversal

		INSERT INTO @TransIDs (seq, TransID)
		EXEC Get_bettrans_transid_Range @total_transid = @rowCount

		SELECT	top 1 @winlostdate = winlostdate, @liveindicator = liveindicator, @transdesc = transdesc, @IsCollection = OddsID
		FROM	@Reversal

		--------------------------vvvvv-------------------------------------
		--Check to not allow to transfer before balance up date
		DECLARE @BalanceUpDay	SMALLDATETIME
			, @archivedDay		SMALLDATETIME
			, @constraintDay	SMALLDATETIME
			, @MoveBetsDay		SMALLDATETIME
		
		DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
		INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
		EXEC bodb02.dbo.Age_SelBalanceUpDay

		SELECT @BalanceUpDay = BalanceUpDay, @MoveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp

		SELECT @archivedDay	= MAX(winlostdate)
		FROM dbo.Task_ArchiveDate WITH (NOLOCK)

		SELECT @constraintDay =  CASE 
										WHEN @archivedDay > @BalanceUpDay THEN @BalanceUpDay+7 -- new BU
										ELSE @BalanceUpDay -- old BU
									END

		IF @winlostdate < @constraintDay --Before BU date
		BEGIN
			SELECT @ErrMsg = CASE @Language
					WHEN 'E'
						THEN 'Not allow to add transaction before balance up date - ' + convert(NVARCHAR(10), @constraintDay, 120) + '.'
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
		FROM	dbo.transfer b WITH (NOLOCK)
			INNER JOIN	CustDB.dbo.custInfo c WITH (NOLOCK) 
			ON	b.custid = c.custID
		WHERE	b.refno = @refno AND bettype > 20000
				AND c.roleid = 1
				AND b.custid IN (SELECT custid FROM @SiteGroupInfo WHERE SiteDBGroupID = @SiteDBGroupID)
		GROUP BY b.CustID
		
		---- Begin reversal
		SET @transdesc = '(Reversal) ' + @transdesc
		
		-----transfer
		INSERT INTO dbo.transfer (transid, custid, transdate, Username, refno, winlost, actual_stake, winlostdate, transdesc, creator,
								bettype, actualrate, recommend, mrecommend, srecommend, currency, CurrencyName, ip, statusID,RepUpdateTime)
		SELECT	t.TransID, custid, CURRENT_TIMESTAMP, Username, refno, actual_stake, winlost, winlostdate, @transdesc, @UserID,
				bettype, actualrate, recommend, mrecommend, srecommend, currency, CurrencyName, @IP, statusID, SYSDATETIME()
		FROM	@Reversal r
		INNER JOIN @TransIDs t ON r.Seq = t.seq

		IF @@ERROR <> 0
		BEGIN
			SELECT	@ErrMsg ='Delete the transaction unsuccessfully!',
					@ErrCode = 103
			RETURN 
		END

	 ---Update Liveindicator = 1 for marking deleted transaction
		MERGE dbo.TransferInfo t
		USING @Reversal s ON t.transid=s.transid
		WHEN MATCHED THEN
			UPDATE SET IsDel = 1
		WHEN NOT MATCHED THEN
			INSERT (Transid,IsDel)
			VALUES (s.Transid,1);
			
		IF @@ERROR <> 0
		BEGIN
			UPDATE dbo.Transfer WITH(ROWLOCK)
			SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0	
			WHERE transid IN (SELECT transid FROM @TransIDs)
	
			UPDATE Transfer_Coll WITH(ROWLOCK)
			SET		custid = 0, Debit = 0, Credit = 0, RepUpdateTime = SYSDATETIME()
			WHERE	transid IN (SELECT transid FROM @TransIDs)

			UPDATE TransferInfo WITH(ROWLOCK)
			SET		IsDel = 1,  RepUpdateTime = SYSDATETIME()
			WHERE  transid IN (SELECT transid FROM @TransIDs)

			SELECT	@ErrMsg ='Delete the transaction unsuccessfully!',
					@ErrCode = 104
			RETURN 
		END

		-----Transfer_Coll 
		IF @IsCollection = 1
		INSERT INTO Transfer_Coll 
				(CustId, WinlostDate, TransDate, Bettype, Debit, Credit, Currency, ActualRate, 
				TransID, RefNo, Username, Recommend, MRecommend, SRecommend, Creator ,TransDesc, IP , RepUpdateTime)
		SELECT 	CustId, WinlostDate, TransDate, Bettype, Actual_Stake, Winlost, Currency, ActualRate, 
				TransID, RefNo, Username, Recommend, MRecommend, SRecommend, Creator ,TransDesc, IP, SYSDATETIME()
		FROM 	dbo.transfer WITH (NOLOCK) 
		WHERE 	TransID IN (SELECT transid FROM @TransIDs)
		
		IF @@ERROR <> 0
		BEGIN
			UPDATE dbo.Transfer WITH(ROWLOCK)
			SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0		
			WHERE transid IN (SELECT transid FROM @TransIDs)
	
			UPDATE Transfer_Coll WITH(ROWLOCK)
			SET		custid = 0, Debit = 0, Credit = 0, RepUpdateTime = SYSDATETIME()
			WHERE	transid IN (SELECT transid FROM @TransIDs)

			UPDATE TransferInfo WITH(ROWLOCK)
			SET		IsDel = 1,  RepUpdateTime = SYSDATETIME()
			WHERE  transid IN (SELECT transid FROM @TransIDs)
					
			SELECT	@ErrMsg ='Delete the transaction unsuccessfully!',
					@ErrCode = 104
			RETURN 
		END

		-----TransferInfo
		INSERT INTO dbo.TransferInfo (TransId, IsDel, IsCollection, RepUpdateTime)
		SELECT	t.TransId, 1 IsDel, @IsCollection, SYSDATETIME() -- All tickets have the same refno also must have the same IsCollection value
		FROM	dbo.transfer t
		WHERE 	TransID IN (SELECT transid FROM @TransIDs)
		
		IF @@ERROR <> 0
		BEGIN
			UPDATE dbo.Transfer WITH(ROWLOCK)
			SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0		
			WHERE transid IN (SELECT transid FROM @TransIDs)
	
			UPDATE Transfer_Coll WITH(ROWLOCK)
			SET		custid = 0, Debit = 0, Credit = 0, RepUpdateTime = SYSDATETIME()
			WHERE	transid IN (SELECT transid FROM @TransIDs)

			UPDATE TransferInfo WITH(ROWLOCK)
			SET		IsDel = 1,  RepUpdateTime = SYSDATETIME()
			WHERE  transid IN (SELECT transid FROM @TransIDs)
			
			UPDATE	transferInfo WITH (ROWLOCK) 
			SET		isDel = 0, RepUpdateTime = SYSDATETIME()
			WHERE	transid IN (Select transid from @Reversal)
					
			SELECT	@ErrMsg ='Delete the transaction unsuccessfully!',
					@ErrCode = 104
			RETURN 
		END
				
		-- Update Transfer Amount in bodb_report.dbo.rptStatement table before move bet day
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
					UPDATE dbo.Transfer WITH(ROWLOCK)
					SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0		
					WHERE transid IN (SELECT transid FROM @TransIDs)
	
					UPDATE Transfer_Coll WITH(ROWLOCK)
					SET		custid = 0, Debit = 0, Credit = 0, RepUpdateTime = SYSDATETIME()
					WHERE	transid IN (SELECT transid FROM @TransIDs)

					UPDATE TransferInfo WITH(ROWLOCK)
					SET		IsDel = 1,  RepUpdateTime = SYSDATETIME()
					WHERE  transid IN (SELECT transid FROM @TransIDs)
						
					--20150808@Elodie: rollback liveindicator = 0
					UPDATE	dbo.TransferInfo WITH (ROWLOCK) 
					SET		IsDel = 0, RepUpdateTime = SYSDATETIME()
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
						UPDATE dbo.Transfer WITH(ROWLOCK)
						SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0		
						WHERE transid IN (SELECT transid FROM @TransIDs)
	
						UPDATE Transfer_Coll WITH(ROWLOCK)
						SET		custid = 0, Debit = 0, Credit = 0, RepUpdateTime = SYSDATETIME()
						WHERE	transid IN (SELECT transid FROM @TransIDs)

						UPDATE TransferInfo WITH(ROWLOCK)
						SET		IsDel = 1,  RepUpdateTime = SYSDATETIME()
						WHERE  transid IN (SELECT transid FROM @TransIDs)

						--20150808@Elodie: rollback liveindicator = 0
						UPDATE	transferInfo WITH (ROWLOCK) 
						SET		isDel = 0, RepUpdateTime = SYSDATETIME()
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
		FROM	dbo.Transfer b WITH (NOLOCK)
			INNER JOIN	CustDB.dbo.custInfo c WITH (NOLOCK) 
			ON	b.custid = c.custID
		WHERE	b.refno = @refno AND bettype > 20000
				AND c.roleid = 1
				AND b.custid IN (SELECT custid FROM @SiteGroupInfo WHERE SiteDBGroupID = @SiteDBGroupID)
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