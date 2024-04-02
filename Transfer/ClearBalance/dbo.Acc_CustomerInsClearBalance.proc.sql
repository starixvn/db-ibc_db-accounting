/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet,bodbExtAccNet,wsv_nap,wsv_xnap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerInsClearBalance]
 	@FromCustID int, --Agent ID here
	@ToCustIDs varchar(4000), 
	@UserID int,
	@ip varchar(45)='',
	@Language varchar(2)= 'E',
	@ErrMsg nvarchar(4000) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@CusStatus varchar(50)='All',
	@system VARCHAR(50) = ''
WITH RECOMPILE
AS
--ADMIN SITE
--Original: \account\customerbalance_clear.asp
 /*
Created: 
Task:	Clear balance all lines of agent 
		Agent level, left menu / button balance/ submit
DB: DBTXN/bodb02
Revisions:
	- 20090828@HuyNguyen: replace [Customer] --> [OtherTrans]
	- 20091003@Kiwi: Modify Write log and remove CustBetCreditUpdResync
	- 20091125@Kiwi: Remove comstatus because it's no used.	
	- 20100424@Henry: insert data to column StatusID of Bettrans (StatusID = 131 for bettype 104) + Update Status = 'Completed'
	- 20100521@Jamie: Remove checking account enabled or not 
	- 20100611@Henry: Write exact amount to log when transferring
	- 20100805@Shifu: Change function name to check permission [CustomerBalance] for [OtherTrans]
	- 20101225@Lukas: Re-arrange bettype
	- 20111024@Sophia: Update balance credit/debit for members
	- 20120411@Sophia: Revise balance credit/debit for members
	- 20121011@Dan: reset yesterday balance for live casino
	- 20121016@Dan: check existed transfer record to skip
	- 20121213@Viet: revise sp
	- 20121203@Dan: skip deleted transfer record when check existed transfer. Delay updating by batch (500 customer) to avoid affect replication
	- 20130208@Elodie: Change link server DB03 to DBPOLICY
					   Write more log on DBTXN server in case of DBLOG server failure
	- 20131025@Lukas: add system define permission checking when call from external accounting
	- 20131108@Elodie: Splitting bodb02 into CustDB (Call Customer, Exchange by link database)  								   
	- 20140826@Jamie: put RECOMPILE
	- 20150723@Patrick: Support Gold deluxe
	- 20150808@Elodie: Balance Improvement [Redmine:#40125]	
	- 20151021@Elodie: Set @IsForce = 1 for updating balance debit [Redmine:#40125]
	- 20150126@Elodie: Include to get balance from bettransRNG + bettransLC [Redmine:#50674]
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	- 20200602@Percy: Separate PendingTransfer3rd from Cash and Balance [RedmineID: #135200]
	- 20200821@Sophia: prevent duplicated transfer [Redmine: #137141]
	- 20200821@Sophia: Check UM Transfer Function [Redmine: #136992]
	- 20201005@Danny: Convert Ipv6 to dummy IPv4 [Redmine: #142511]
	- 20210310@Danny: Capture total cash before transfering  [Redmine: #146038]
	- 20210505@Sol: NAP - Alpha - Allow more time for transfer - [Redmine: #149927]
	- 20210817@Sophia: Fix overflow Refno [Redmine: #160262]
	- 20211122@Danny: Split transfer tickets out of bettrans [Redmine: #164196]
	- 20220315@Evan: SQL Server Upgrade STRING_SPLIT [Redmine: #168783]
	- 20220721@Danny: get transid and refno with new generation [Redmine: #175670]
	- 20230227@Evan: Balance-Up support transfer 247 [Redmine: #173554]
	- 20230609@Danny: support scale out credit [Redmine: #181595]
	- 20240313@Bobby: EC enhancement [Redmine: #202276]
	
Param's Explanation:
*/ 
BEGIN
	SET NOCOUNT ON

	--Check permission for account site: @phuc20080213
	DECLARE @ErrMsg_temp nvarchar(4000)   

	IF @system = 'EXTERNAL'
	BEGIN
		--- no check permssion in case of calling from external accounting
		SET @ErrMsg = ''
	END
	ELSE
	BEGIN
		-- must use temporary variable for @ErrMsg because of nvarchar(max) is not allowed in remote call
		EXEC DBPOL.NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[CustomerBalance]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg_temp output
		SELECT @ErrMsg = @ErrMsg_temp
		If @ErrCode <> 0
			RETURN
	END

	--Check disable user
	--EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @FromCustID, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	--if @ErrCode <>0 return
	--end

	Declare @LogData nvarchar(200)
	Declare @agentid int, @custid int
	DECLARE @currency int , @currName nvarchar(10), @actualrate float 
	DECLARE @agUser nvarchar(50), @User nvarchar(50)
	Declare @refno bigint, @ToCustID int, @Amount float, @Recommend1 int, @MRecommend1 int, @grefno bigint, @srecommend1 int, @TransID BIGINT
	DECLARE @WinlostDate datetime, @ABSamount MONEY
	DECLARE @ErrItems nvarchar(max), @SkipTransfer bit

	SELECT @WinlostDate = convert(nvarchar(10), current_timestamp,120)
	SELECT @ErrItems = ''    

	DECLARE @count int, @batch int
	SELECT @batch=200, @count=0 

	--TODO: get move bet date
	DECLARE @balanceUpDay SMALLDATETIME, @moveBetsDay SMALLDATETIME
	EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @moveBetsDay OUTPUT
	EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @balanceUpDay OUTPUT

	CREATE TABLE #Member (	custid int PRIMARY KEY,
							memberName nvarchar(50),	
							memberBalance money DEFAULT 0,
							UNIQUE(memberBalance,custid)
						 ) 

	if not exists (select 1 FROM CustDB.dbo.customer with (NOLOCK) where custid = @FromCustID)
	BEGIN
		Select @ErrMsg = case @Language 
								when 'E' then 'Customer does not exist.'
								when 'CS' then N'Customer does not exist.'
								when 'J' then N'ID確認できません。'
								else N'Customer does not exist.'
							end, @ErrCode = 101	
		
		return
	END

	Select @LogData = 'Admin ' + cast(@UserID as varchar(20))
					+ ' clear balance :' + convert(varchar(20), @FromCustID) 
					+ ' to [custid, balance] '

	SELECT @AgentID = @FromCustID
	
	---- #1 CHECK UM TRANSFER FUNCTION
	EXEC DBCUST.CUSTDB.dbo.Acc_Transfer_CheckUM  
		@CustID = @AgentID
		,@Language = @Language
		,@ErrMsg = @ErrMsg OUTPUT 
		,@ErrCode = @ErrCode OUTPUT
		 
	IF @ErrCode <> 0  -- Function Transfer is under UM 
	BEGIN	
		RETURN		
	END		

	---- #2 CHECK FLAG ISTRANSFERRING = 1 THEN RAISE ERROR
	EXEC DBCUST.CUSTDB.dbo.Acc_Transfer_CheckRunningByCust  
			@CustID = @AgentID
			,@Language = @Language
			,@ErrMsg = @ErrMsg OUTPUT 
			,@ErrCode = @ErrCode OUTPUT
			 
	IF @ErrCode <> 0  -- the auto transfer job is running this custid
	BEGIN
		RETURN		
	END


	SELECT @currency = c.currency, @actualrate = e.actualrate, @currName = e.currency ,
		   @agUser = c.username, @MRecommend1 = c.mrecommend ,@Recommend1 = c.recommend,@srecommend1 = c.srecommend
	FROM CustDB.dbo.customer c with (nolock) 
		INNER JOIN CustDB.dbo.Exchange e with (NOLOCK) on c.currency = e.exchangeid 
	WHERE custid = @agentid AND roleid = 2


	CREATE TABLE #ToCustIDs (custID INT)

	INSERT INTO #ToCustIDs (CustID)
	SELECT CONVERT(int, value) 
	FROM STRING_SPLIT (@ToCustIDs, ',' )

	DECLARE @IsDiff	SMALLINT = 1, @NewMoveBetDate SMALLDATETIME = NULL,@NewBalanceUpDate SMALLDATETIME = NULL
	
	WHILE (@IsDiff = 1)
	BEGIN
		
		DELETE FROM #Member

		IF( @CusStatus <> '' or @CusStatus <> null)
		BEGIN
			;WITH cte_Balance AS (
				SELECT
					b.custid,
					isnull(SUM(isnull(winlost-actual_stake+playercomm, 0)), 0) memberBal
				FROM  Bettrans AS b with (NOLOCK)
				INNER JOIN CustDB.dbo.customer as c with (NOLOCK) on b.custid = c.custid 
				WHERE c.recommend = @AgentID 
					and c.roleid = 1 
					and b.ruben = 1
					AND b.winlostdate > @moveBetsDay
					and b.winlostdate < @WinlostDate
				GROUP BY b.custid 
				UNION ALL 

				SELECT
					b.custid,
					isnull(SUM(isnull(winlost-actual_stake +playercomm, 0)), 0) memberBal
				FROM  dbo.Transfer AS b with (NOLOCK)
				INNER JOIN CustDB.dbo.customer as c with (NOLOCK) on b.custid = c.custid 
				WHERE c.recommend = @AgentID and c.roleid = 1 
					and b.bettype not in (21008, 21009)
					AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
                        WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
                        WHEN winlostdate < @balanceUpDay THEN 0 --> old data
                    ELSE 1 END
				GROUP BY b.custid 

				UNION ALL 
				SELECT b.custid, SUM(winlost - actual_stake + playercomm) memberBal
				FROM bettransRNG b WITH (NOLOCK)
				WHERE b.recommend = @AgentID AND statusID NOT IN (0,1) AND IsSum = 0 AND winlostdate < @WinlostDate
				GROUP BY b.custid

				UNION ALL 
				SELECT b.custid, SUM(winlost - actual_stake + playercomm) memberBal
				FROM bettransLC b WITH (NOLOCK)
				WHERE b.recommend = @AgentID AND statusID NOT IN (0,1) AND IsSum = 0 AND winlostdate < @WinlostDate
				GROUP BY b.custid
				)

			INSERT INTO #Member(custid,memberName,memberBalance)
			SELECT b.custid, c.username, SUM(memberBal)
			FROM cte_Balance b
				INNER JOIN CustDB.dbo.customer as c with (NOLOCK) on b.custid = c.custid 
			GROUP BY b.custid, c.username 
		END 
		ELSE 
		BEGIN

			;WITH cte_Balance AS (
				SELECT b.custid ,c.username,
					  isnull(SUM(isnull(winlost-actual_stake+playercomm, 0)), 0) memberBal
				FROM  Bettrans AS b with (NOLOCK)
				INNER JOIN CustDB.dbo.customer as c with (NOLOCK) on b.custid = c.custid 
				WHERE EXISTS (SELECT 1 FROM #ToCustIDs WHERE custid = b.custid)
					  and c.recommend = @AgentID 
					  and b.ruben = 1 
					  AND b.winlostdate > @moveBetsDay
					  and b.winlostdate < @WinlostDate
				GROUP BY b.custid ,c.username

				UNION ALL

				SELECT b.custid ,c.username,
					  isnull(SUM(isnull(winlost-actual_stake +playercomm, 0)), 0) memberBal
				FROM  dbo.Transfer AS b with (NOLOCK)
				INNER JOIN CustDB.dbo.customer as c with (NOLOCK) on b.custid = c.custid 
				WHERE EXISTS (SELECT 1 FROM #ToCustIDs WHERE custid = b.custid)
					  and c.recommend = @AgentID 
					  and b.bettype not in (21008, 21009)
					  AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
                        WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
                        WHEN winlostdate < @balanceUpDay THEN 0 --> old data
                    ELSE 1 END
				GROUP BY b.custid ,c.username
				UNION ALL 
				SELECT b.custid, c.username, SUM(winlost - actual_stake + playercomm) memberBal
				FROM bettransRNG b WITH (NOLOCK)
					INNER JOIN CustDB.dbo.customer as c with (NOLOCK) on b.custid = c.custid 
				WHERE EXISTS (SELECT 1 FROM #ToCustIDs WHERE custid = b.custid)
					AND c.recommend = @AgentID AND statusID NOT IN (0,1) AND IsSum = 0 AND winlostdate < @WinlostDate
				GROUP BY b.custid, c.username

				UNION ALL 
				SELECT b.custid, c.username, SUM(winlost - actual_stake + playercomm) memberBal
				FROM bettransLC b WITH (NOLOCK)
					INNER JOIN CustDB.dbo.customer as c with (NOLOCK) on b.custid = c.custid 
				WHERE EXISTS (SELECT 1 FROM #ToCustIDs WHERE custid = b.custid)
					AND c.recommend = @AgentID AND statusID NOT IN (0,1) AND IsSum = 0 AND winlostdate < @WinlostDate
				GROUP BY b.custid, c.username
			)
			INSERT INTO #Member(custid,memberName,memberBalance)
			SELECT b.custid, b.username, SUM(memberBal)
			FROM cte_Balance b
			GROUP BY b.custid, b.username 

		END 

		----check MB date, BU date again to make sure it is not changed
		SELECT @NewMoveBetDate = NULL, @NewBalanceUpDate = NULL
		EXEC dbo.Acc_ReCheck_MBUDate 
			@MBDate = @moveBetsDay,
			@BUDate = @balanceUpDay,
			@IsDiff = @IsDiff OUTPUT,
			@NewMBDate = @NewMoveBetDate OUTPUT,
			@NewBUDate = @NewBalanceUpDate OUTPUT

		IF @IsDiff = -1 
		BEGIN
			SELECT @ErrMsg = 'BalanceUpDate value is null. Please contact DBA for support.', @ErrCode = 108
			RETURN
		END

		IF @IsDiff = 1 
		BEGIN
			SELECT @moveBetsDay = @NewMoveBetDate, @balanceUpDay = @NewBalanceUpDate
		END
	END

	DELETE FROM #Member WHERE memberBalance = 0
	 
	IF not exists (SELECT 1 FROM #Member)
	BEGIN
		SELECT @ErrMsg = 'Cannot transfer because balance of all downlines is 0!', @ErrCode = 106
		RETURN
	END

	DECLARE CUR CURSOR FOR SELECT custid, memberName, memberBalance 
						   FROM #Member 
	OPEN CUR
	FETCH NEXT FROM CUR INTO @custid,@User,@Amount   
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		EXEC Get_Refno_Transid @RefNo = @RefNo OUTPUT
		
		SELECT @SkipTransfer = 0
		--Check for existing transfer (allow only one transfer per day) - Tho@09062008  
		IF(exists(  
			  SELECT 1 FROM dbo.Transfer t WITH (NOLOCK)   
			  LEFT JOIN dbo.TransferInfo ti WITH (NOLOCK)  ON t.TransId = ti.TransId
			  WHERE custid=@custid AND bettype in (21003, 21004)   
			  AND (transdate BETWEEN convert(varchar(10), current_timestamp, 120) AND convert(varchar(10), current_timestamp, 120) + ' 23:59:59')  
			  AND ISNULL(ti.IsDel,0) = 0
		 ))  
		BEGIN 
			SELECT @SkipTransfer = 1  
			SELECT @ErrItems = @ErrItems + @User + ', '  
		END
		
		IF (@amount > 0 and @SkipTransfer = 0)
		BEGIN
			
			EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
			INSERT INTO dbo.Transfer 
				(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
				winlostdate, currency,actualrate,currencyName, recommend, mrecommend, 
				srecommend, scomm, swinlost,ip,statusID, RepUpdateTime)
			VALUES (@TransID, @UserID, @agentid, @agUser, @refno, CURRENT_TIMESTAMP, 21004, 'To Customer via Multiple: ' + @User, @amount, 0, 
				@WinlostDate, @currency,@actualrate, @currName,@agentid, @MRecommend1, 
				@srecommend1, 0, 0,@ip,131,SYSDATETIME())
			if @@Error <> 0
			BEGIN
				Select @ErrMsg = case @Language 
							when 'E' then 'Clear balance failed. Please try again.'
							when 'CS' then N'Clear balance failed. Please try again.'
							when 'J' then N'もう一度残高ポイントを確認してください。'
							else N'Clear balance failed. Please try again.'
						end, @ErrCode = 102
				
				UPDATE dbo.Transfer WITH(ROWLOCK)
				SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0
				WHERE custid in (@agentid, @custid)
					and bettype = 21004
					and refno = @refno
					
				return
			END
			
			--update debit balance
			--EXEC Dot_BalanceUpdDebit @CustID = @CustID, @balance = @amount
					EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @amount, @Type = 2, @IsForced = 1, @ErrCode = @ErrCode OUTPUT
			if @ErrCode <> 0
			BEGIN
				Select @ErrMsg = case @Language 
							when 'E' then 'Clear balance failed. Please try again.'
							when 'CS' then N'Clear balance failed. Please try again.'
							when 'J' then N'もう一度残高ポイントを確認してください。'
							else N'Clear balance failed. Please try again.'
						end, @ErrCode = 102
				
				UPDATE dbo.Transfer WITH(ROWLOCK)
				SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0
				WHERE custid in (@agentid, @custid)
					and bettype = 21004
					and refno = @refno
					
				return
			END			

			DECLARE @TotalCash1 MONEY 
			EXEC Acc_CustomerSelCash_CaptureBalance @custid = @custid, @TotalCash  = @TotalCash1 OUTPUT

			EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
			INSERT INTO dbo.Transfer 
				(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
				winlostdate, currency,actualrate,currencyName, recommend, mrecommend, srecommend, 
				scomm, swinlost,ip,statusID,balance,RepUpdateTime)
			VALUES (@TransID, @UserID, @custid, @User, @refno, CURRENT_TIMESTAMP, 21004, 'To Customer via Multiple: ' + @agUser, 0, @amount,
				@WinlostDate, @currency, @actualrate, @currName, @agentid, @MRecommend1, @srecommend1,
				 0, 0,@ip,131,@TotalCash1,SYSDATETIME())
			if @@Error <> 0
			BEGIN
				Select @ErrMsg = case @Language 
							when 'E' then 'Clear balance failed. Please try again.'
							when 'CS' then N'Clear balance failed. Please try again.'
							when 'J' then N'もう一度残高ポイントを確認してください。'
							else N'Clear balance failed. Please try again.'
						end, @ErrCode = 103
				
				UPDATE dbo.Transfer WITH(ROWLOCK)
				SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0
				WHERE custid in (@agentid, @custid)
					and bettype = 21004
					and refno = @refno
				
				---rollback balance
				--EXEC Dot_BalanceUpdCredit @CustID = @CustID, @balance = @amount
				EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @amount, @Type = 2
				return
			END		
			
			--Add writelog for each amt transfered - Vinh 20080629
			Select @LogData = 'Clear balance: Transfer from Customer ' + @User 
							+ ' to Agent ' + @agUser 
							+ ' with amount ' + convert(varchar(20), @amount) 
							+ ' Ref.No ' + convert(varchar(20), @refno)		
			
		END
		ELSE if (@amount<0 and @SkipTransfer = 0)
		BEGIN
			--SET @amount = abs(@amount)
			EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
			INSERT INTO dbo.Transfer 
				(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
				 winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend,
				scomm, swinlost,ip,statusID,RepUpdateTime)
			VALUES (@TransID, @UserID, @agentid, @agUser, @refno, CURRENT_TIMESTAMP, 21004, 'To Customer via Multiple: ' + @User, 0, abs(@amount),
				@WinlostDate, @currency, @actualrate, @currName, @agentid, @MRecommend1, @srecommend1,
				0, 0, @ip,131,SYSDATETIME())
			if @@Error <> 0
			BEGIN
				Select @ErrMsg = case @Language 
							when 'E' then 'Clear balance failed. Please try again.'
							when 'CS' then N'Clear balance failed. Please try again.'
							when 'J' then N'もう一度残高ポイントを確認してください。'
							else N'Clear balance failed. Please try again.'
						end, @ErrCode = 104
				
				UPDATE dbo.Transfer WITH(ROWLOCK)
				SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0
				WHERE custid in (@agentid, @custid)
					and bettype = 21004
					and refno = @refno
					
				return
			END

			DECLARE @TotalCash3 MONEY 
			EXEC Acc_CustomerSelCash_CaptureBalance @custid = @custid, @TotalCash  = @TotalCash3 OUTPUT

			EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
			INSERT INTO dbo.Transfer 
				(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
				winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
				scomm, swinlost,ip,statusID,balance, RepUpdateTime)
			VALUES (@TransID, @UserID, @custid, @User, @refno, CURRENT_TIMESTAMP, 21004, 'To Customer via Multiple: ' + @agUser, abs(@amount), 0,
				@WinlostDate, @currency, @actualrate, @currName, @agentid, @MRecommend1, @srecommend1, 
				0, 0, @ip,131,@TotalCash3,SYSDATETIME())
			if @@Error <> 0
			BEGIN
				Select @ErrMsg = case @Language 
							when 'E' then 'Clear balance failed. Please try again.'
							when 'CS' then N'Clear balance failed. Please try again.'
							when 'J' then N'もう一度残高ポイントを確認してください。'
							else N'Clear balance failed. Please try again.'
						end, @ErrCode = 105
				
				UPDATE dbo.Transfer WITH(ROWLOCK)
				SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0
				WHERE custid in (@agentid, @custid)
					and bettype = 21004
					and refno = @refno
					
				return
			END
			
			---update credit balance
			SELECT @ABSamount = abs(@amount)
			--EXEC Dot_BalanceUpdCredit @CustID = @CustID, @balance = @ABSamount
			EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @ABSamount, @Type = 2
					
			--Add writelog for each amt transfered - Vinh 20080629
			Select @LogData = 'Clear balance: Transfer from Agent ' + @agUser 
							+ ' to Customer ' + @User 
							+ ' with amount ' + convert(varchar(20), @amount) 
							+ ' Ref.No ' + convert(varchar(20), @refno)						
		END
		
		IF(@SkipTransfer = 0)   
		BEGIN				
			DECLARE @isResetYesterdayBalance BIT, @ErrCode_ResetYesterdayBalance BIT, @YesterdayBalance MONEY
			-- reset yesterday balance for live casino						
									EXEC Acc_BalanceGameResetYesterday @CustID = @CustID, @isResetYesterdayBalance = @isResetYesterdayBalance OUTPUT, @YesterdayBalance = @YesterdayBalance	 OUTPUT, @ErrCode = @ErrCode_ResetYesterdayBalance OUTPUT	
			Select @LogData = @LogData + CASE WHEN @isResetYesterdayBalance = 1 THEN 										
											CASE WHEN @ErrCode_ResetYesterdayBalance = 0 THEN '. (ResetGameBalance = suscess, YesterdayBalance =' + CAST(@YesterdayBalance AS VARCHAR(50)) + ')' 
											ELSE '. (ResetGameBalance = fail)' END		
									ELSE '' END	
			BEGIN TRY
				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @FromCustID, @ToCustID = @custid, @IP = @IP, @Doing = @LogData		
			END TRY
			BEGIN CATCH
				Select @LogData = @LogData + ' ErrMsg=' + error_message()
				EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @FromCustID, @ToCustID = @custid, @IP = @IP, @Doing = @LogData					
			END CATCH

			SET @count=@count+1 
			IF @count%@batch = 0
				WAITFOR DELAY '000:00:01' 
		END
		
		FETCH NEXT FROM CUR INTO @custid,@User,@Amount
	END
	CLOSE CUR
	DEALLOCATE CUR
	DROP TABLE #Member
	DROP TABLE #ToCustIDs

	if @ErrItems <> ''  
	BEGIN  
		select @ErrCode = 107  
		select @ErrItems = LEFT(@ErrItems, len(@ErrItems)-1)  
		Select @ErrMsg = case @Language   
		   when 'E' then N'Clear balance failed: Allow only one transfer per day. Failed for the following user(s): ' + @ErrItems 
		   when 'CS' then N'结清余额不成功: 只允许每天转账一次。 不成功于会员: '+ @ErrItems 
		   when 'CT' then N'結清餘額不成功: 只允許每天轉賬一次。 不成功於會員: '+ @ErrItems 
		   when 'TH' then N' ไม่สามารถทำรายการชำระเงินได้ : เพราะระบบอนุญาตให้โอนเงินได้ 1 ครั้งใน 1 วันเท่านั้น' + @ErrItems 
		   when 'J' then N'Clear balance failed: Allow only one transfer per day. Failed for the following user(s): ' + @ErrItems 
		   when 'KO' then N'Clear balance failed: Allow only one transfer per day. Failed for the following user(s): ' + @ErrItems
		   else N'Clear balance failed: Allow only one transfer per day. Failed for the following user(s): ' + @ErrItems 
		  end  
	END
END	
GO
