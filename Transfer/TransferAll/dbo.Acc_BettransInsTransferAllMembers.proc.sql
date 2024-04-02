/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet,wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_BettransInsTransferAllMembers]	
	@AgentName varchar(50),  
	@UserID int,  
	@IP varchar(45)='',  
	@IsJob BIT = 0,
	@ErrMsg nvarchar(4000) = '' OUTPUT,  
	@ErrCode int = 0 OUTPUT  
AS  
 /*
	Created: 
	Task:	Transfer all
			Customer/Transfer all
	DB: DBTXN/bodb02
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [OtherTrans]	
		- 20091003@Kiwi: Modify write log and remove CustBetCreditUpdResync
		- 20091125@Kiwi: Remove comstatus because it's no used.	
		- 20100424@Henry: insert data to column StatusID of Bettrans (StatusID = 131 for bettype 103)+ Update Status = 'Completed'
		- 20100611@Henry: Write exact amount to log when transferring
		- 20101225@Lukas: Re-arrange bettype
		- 20111025@Sophia: Update balance credit/debit for members
		- 20120411@Sophia: Revise balance credit/debit for members
		- 20121015@Dan: reset yesterday balance for live casino
		- 20121016@Dan: check existed transfer record to skip	
		- 20121113@Viet: revise sp
		- 20121203@Dan: skip deleted transfer record when check existed transfer. Delay updating by batch (500 customer) to avoid affect replication
		- 20130208@Elodie: Change link server DB03 to DBPOLICY
						   Write more log on DBTXN server in case of DBLOG server failure
		- 20131108@Elodie: Splitting bodb02 into CustDB (Call CustInfo, Exchange by link database) 					   
		- 20150723@Patrick: Support Gold deluxe
		- 20150808@Elodie: Balance Improvement [Redmine:#40125]	
		- 20151021@Elodie: Set @IsForce = 1 for updating balance debit [Redmine:#40125]
		- 20160126@Kathy: get balance from bettransRNG + bettransLC [Redmine:#50674]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20200602@Percy: Separate PendingTransfer3rd from Cash and Balance [RedmineID: #135200]
		- 20200730@Sophia: prevent duplicated transfer [Redmine: #137141]
		- 20200730@Sophia: Check UM Transfer Function [Redmine: #136992]
		- 20210310@Danny: Capture total cash before transfering  [Redmine: #146038]
		- 20210505@Sol: NAP - Alpha - Allow more time for transfer - [Redmine: #149927]
		- 20210817@Sophia: Fix overflow Refno [Redmine: #160262]
		- 20211115@Danny: Split transfer tickets out of bettrans [Redmine: #164196]
		- 20220721@Danny: get transid and refno with new generation [Redmine: #175670]
		- 20230227@Evan: Balance-Up support transfer 247 [Redmine: #173554]
		- 20230609@Danny: support scale out credit [Redmine: #181595]
		- 20240312@Bobby: EC enhancement [Redmine: #202276]
		
	Param's Explanation:
*/ 
BEGIN
	--Check permission for account site: @phuc20080213  
	DECLARE @ErrMsg_temp nvarchar(4000)   
	-- must use temporary variable for @ErrMsg because of nvarchar(max) is not allowed in remote call
	EXEC DBPOL.NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherTrans]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg_temp output  
	SELECT @ErrMsg = @ErrMsg_temp
	If @ErrCode <> 0  
	 RETURN
	--end  


	 DECLARE @roleid int, @AgentID int, @ABSamount MONEY
	 DECLARE @ErrItems nvarchar(max), @SkipTransfer bit , @isSucc varchar(10) 
	 SELECT @isSucc='false', @ErrItems = ''  
	 
	 DECLARE @count int, @batch int
	 SELECT @batch=200, @count=0 	
	  
	 SELECT @roleid = roleid, @AgentID = custid 
	 from CustDB.dbo.Custinfo (nolock)  
	 WHERE username = @AgentName  
	  
	 if isnull(@AgentID,0) = 0 or @roleid NOT in (2,3,4)  
	 BEGIN  
		Select @ErrMsg = 'Invalid Agent User Name', @ErrCode = 101  
		return  
	 END  
	 
	---- #1 CHECK UM TRANSFER FUNCTION
	EXEC DBCUST.CUSTDB.dbo.Acc_Transfer_CheckUM  
		@CustID = @AgentID
		,@ErrMsg = @ErrMsg OUTPUT 
		,@ErrCode = @ErrCode OUTPUT
		 
	IF @ErrCode <> 0  -- Function Transfer is under UM 
	BEGIN
		RETURN		
	END		
	
	---- #2 CHECK FLAG ISTRANSFERRING = 1 THEN RAISE ERROR, IF THIS SP IS CALLED BY JOB THEN NO NEED TO CHECK
	IF @IsJob = 0
	BEGIN 
		EXEC DBCUST.CUSTDB.dbo.Acc_Transfer_CheckRunningByCust  
			@CustID = @AgentID
			,@ErrMsg = @ErrMsg OUTPUT 
			,@ErrCode = @ErrCode OUTPUT
			 
		IF @ErrCode <> 0  -- the auto transfer job is running this custid
		BEGIN
			RETURN		
		END
	END
	
	/*--Thien removed on 2009-10-17
	--Check disable user
	EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @username = @AgentName, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
	--end
	*/

	--TODO: get move bet date
	DECLARE @balanceUpDay SMALLDATETIME, @moveBetsDay SMALLDATETIME
	EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @moveBetsDay OUTPUT
	EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @balanceUpDay OUTPUT

	-- create temp table for member balance sum detail
	CREATE TABLE #MemberBalance
	(
		CustId		INT PRIMARY KEY,
		MemBalance	MONEY
	)

	 -- CREATE TEMP TABLE CONTAIN MEMBER'S BALANCE @Phuong20080915
	 CREATE TABLE #Member(	custid		int PRIMARY KEY,
							recommend	int,
							mrecommend  int,
							srecommend  int,
							memberName	nvarchar(50),
							agentName	nvarchar(50),
							memBalance	money default 0,
							UNIQUE(memBalance,custid)
				 )
							
	 IF @roleid = 2 
	 BEGIN
		INSERT INTO #Member( custid,recommend,mrecommend, srecommend, memberName, agentName, memBalance)
		SELECT ci.custid, ci.recommend,ci.mrecommend, ci.srecommend, ci.username,ag.username, 0
		from CustDB.dbo.Custinfo ci with (NOLOCK)
			INNER JOIN CustDB.dbo.custinfo ag with (NOLOCK) on ci.recommend = ag.custid 
		WHERE ci.recommend = @AgentID and ci.roleid =1 
	 END 
	 
	 IF @roleid = 3 
	 BEGIN
		INSERT INTO #Member( custid,recommend,mrecommend, srecommend, memberName,agentName, memBalance)
		SELECT ci.custid, ci.recommend,ci.mrecommend, ci.srecommend, ci.username, ag.username, 0
		from CustDB.dbo.Custinfo ci with (NOLOCK)
			INNER JOIN CustDB.dbo.custinfo ag with (NOLOCK) on ci.recommend = ag.custid 
		WHERE ci.mrecommend = @AgentID and ci.roleid =1 
	 END 
	 
	 IF @roleid = 4
	 BEGIN 
		INSERT INTO #Member( custid,recommend,mrecommend, srecommend, memberName, agentName, memBalance)
		SELECT ci.custid, ci.recommend,ci.mrecommend, ci.srecommend, ci.username,ag.username, 0
		from CustDB.dbo.Custinfo ci with (NOLOCK)
			INNER JOIN CustDB.dbo.custinfo ag with (NOLOCK) on ci.recommend = ag.custid 
		WHERE ci.srecommend = @AgentID and ci.roleid =1  
	 END 
	 -- Mark for A/C which need to transfer  
	 /*  
	 if @YesterdayData = 1   
	  UPDATE #c  
	  SET NeedTransfer = 1  
	  WHERE custid in (  
	   SELECT b.custid  
	   FROM bettrans b (nolock)  
	   WHERE custid in (SELECT custid FROM #c)   
		and b.winlostdate < convert(varchar(10), CURRENT_TIMESTAMP, 120)  
	   GROUP BY custid  
	   HAVING isnull(SUM(isnull(case when ruben=0 then 0 else winlost-actual_stake+playercomm end, 0)), 0) <> 0  
	  )  
	 else  
	  UPDATE #c  
	  SET NeedTransfer = 1  
	  WHERE custid in (  
	   SELECT b.custid  
	   FROM bettrans b (nolock)  
	   WHERE custid in (SELECT custid FROM #c)  
	   GROUP BY custid  
	   HAVING isnull(SUM(isnull(case when ruben=0 then 0 else winlost-actual_stake+playercomm end, 0)), 0) <> 0  
	  ) 
	  --DELETE FROM #c WHERE NeedTransfer = 0   
	 */
	  DECLARE @WinlostDate datetime  
	  SELECT @WinlostDate = convert(nvarchar(10),current_timestamp,120) 

	  DECLARE @IsDiff SMALLINT = 1, @NewMoveBetDate SMALLDATETIME = NULL,@NewBalanceUpDate SMALLDATETIME = NULL

	  WHILE (@IsDiff = 1)
	  BEGIN 
			
			DELETE FROM #MemberBalance

			;WITH cteBalanceMember
			  AS(
				SELECT	b.custid, b.bettype, b.winlostdate, b.winlost, b.actual_stake, b.playercomm
				FROM	dbo.bettrans b WITH(NOLOCK)
				WHERE	b.custid IN (SELECT custid FROM #Member)
						AND b.winlostdate > @moveBetsDay
						AND b.ruben = 1

				UNION ALL
				SELECT	r.custid, r.gameID, r.winlostdate, r.winlost, r.actual_stake, r.playercomm
				FROM	dbo.bettransRnG r WITH(NOLOCK)
				WHERE	r.custid IN (SELECT custid FROM #Member)
						AND r.IsSum = 0
						AND r.statusID NOT IN (0,1)
				UNION ALL
				SELECT	l.custid, l.gameID, l.winlostdate, l.winlost, l.actual_stake, l.playercomm
				FROM	dbo.bettransLC l WITH(NOLOCK)
				WHERE	custid IN (SELECT custid FROM #Member)
						AND l.IsSum = 0
						AND l.statusID NOT IN (0,1)

				UNION ALL
				SELECT	b.custid, b.bettype, b.winlostdate, b.winlost, b.actual_stake, b.playercomm
				FROM	dbo.Transfer b WITH(NOLOCK)
				WHERE	b.custid IN (SELECT custid FROM #Member)
						AND bettype NOT IN (21008, 21009)
						AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
			                        WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
			                        WHEN winlostdate < @balanceUpDay THEN 0 --> old data
			                    ELSE 1 END
			  			)
			  INSERT INTO #MemberBalance(CustId, MemBalance)
			  SELECT custid,
					 isnull(SUM(isnull(case when bettype < 19999 and winlostdate < @WinlostDate then winlost-actual_stake+playercomm 
											when bettype >= 19999 then winlost-actual_stake +playercomm 
											else 0 
											end , 0)), 0) memBal	
			  FROM cteBalanceMember 
			  GROUP BY custid

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

	  UPDATE #Member 
	  SET memBalance = b.MemBalance 
	  FROM #Member 
			INNER JOIN #MemberBalance b 
				ON #Member.custid = b.custid 
	 
	  DELETE FROM #Member WHERE memBalance =0
	  IF not exists (SELECT 1 FROM #Member)
	  BEGIN
		SELECT @ErrMsg = 'Cannot transfer because balance of all downlines is 0!', @ErrCode = 106
		RETURN
	  END
	    
	  DECLARE @LogData nvarchar(200)
	  DECLARE @custid int, @recommend int, @mrecommend int, @srecommend int
	  DECLARE @memberName nvarchar(50), @agName nvarchar(50)
	  DECLARE @currency int, @currName nvarchar(10),@actualrate float,@amount money
	  DECLARE @refno bigint, @grefno BIGINT, @TransID BIGINT
	  
	  SELECT @currency = ci.currency, @actualrate = e.actualrate ,@currName = e.currency 
	  from CustDB.dbo.Custinfo ci with (NOLOCK) 
		INNER JOIN CustDB.dbo.Exchange e with (NOLOCK) on ci.currency = e.exchangeid
	  WHERE custid = @agentid 
		
	   -- Start Transfer (CURSOR Loop)
	  DECLARE CS_recommend  
	  CURSOR FOR  
	  SELECT custid, recommend, mrecommend, srecommend, memberName, agentName, memBalance 
	  FROM #Member 
	   		 
	  OPEN CS_recommend  
	  FETCH NEXT FROM CS_recommend INTO @custid, @recommend, @mrecommend, @srecommend,
										@memberName, @agName, @amount 
	  WHILE @@FETCH_STATUS = 0  
	  BEGIN    
	  --Thien@20080212: Fix raisError with new @ReturnErrCode param  
	  --EXEC dbo.CustAccountInsClearBalance @recommend, @custid, @Now, @UserID    
	 -- EXEC dbo.Age_Transfer_InsClearBalance_Ag_1
	 --  @FromCustID = @recommend,  
	  -- @ToCustIDs = @custid,  
	  -- @creator = @UserID,     
	 --  @YesterdayData = @YesterdayData,  
	 --  @ReturnErrCode = 1,  
	 --  @ErrMsg  = @ErrMsg OUTPUT,  
	 --  @ErrCode = @ErrCode OUTPUT  
	 
 
		---- #2 CHECK FLAG ISTRANSFERRING = 1 THEN RAISE ERROR, IF THIS SP IS CALLED BY JOB THEN NO NEED TO CHECK
		IF @IsJob = 0
		BEGIN 
			EXEC DBCUST.CustDB.dbo.Acc_Transfer_CheckRunningByCust  
				@CustID = @recommend
				,@ErrMsg = @ErrMsg OUTPUT 
				,@ErrCode = @ErrCode OUTPUT
				 
			IF @ErrCode <> 0  -- the auto transfer job is running this custid
			BEGIN
				RETURN		
			END
		END
	
			EXEC Get_Refno_Transid @RefNo = @RefNo OUTPUT
	    
			SELECT @SkipTransfer = 0
			--Check for existing transfer (allow only one transfer per day) - Tho@09062008  
			IF(exists(  
				  SELECT 1 FROM dbo.Transfer  t WITH (NOLOCK)   
				  LEFT JOIN dbo.TransferInfo ti WITH (NOLOCK)  ON t.TransId = ti.TransId
				  WHERE t.custid=@custid AND t.bettype in (21003, 21004)   
				  AND (t.transdate BETWEEN convert(varchar(10), current_timestamp, 120) AND convert(varchar(10), current_timestamp, 120) + ' 23:59:59')  
				  AND ISNULL(ti.IsDel,0) = 0
			 ))  
			BEGIN 
				SELECT @SkipTransfer = 1  
				SELECT @ErrItems = @ErrItems + @memberName + ', '  
			END
			
			IF (@amount > 0 and @SkipTransfer = 0)
			BEGIN
				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO dbo.Transfer 
					(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					winlostdate, currency, actualrate,currencyName, recommend, mrecommend, srecommend, scomm, swinlost,ip,statusID,RepUpdateTime)
				VALUES (@TransID, @Userid, @recommend, @agName, @refno, CURRENT_TIMESTAMP, 21004, 'From Customer :: ' + @memberName, @amount, 0, 
					@WinlostDate, @currency, @actualrate, @currName, @recommend, @MRecommend, @srecommend, 0, 0,@ip,131,SYSDATETIME())
				if @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 102  
					
					UPDATE dbo.Transfer WITH(ROWLOCK)
					SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0
					WHERE custid in (@recommend, @custid)
						and bettype = 21004
						and refno = @refno
						
					return
				END
				
				---update debit balance
				--EXEC Dot_BalanceUpdDebit @CustID = @CustID, @balance = @amount
							EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @amount, @Type = 2, @IsForced = 1, @ErrCode = @ErrCode OUTPUT
				if @ErrCode <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 103
					
					UPDATE dbo.Transfer WITH(ROWLOCK)
					SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0
					WHERE custid in (@recommend, @custid)
						and bettype = 21004
						and refno = @refno
						
					return
				END

				DECLARE @TotalCash1 MONEY 
				EXEC Acc_CustomerSelCash_CaptureBalance @custid = @custid, @TotalCash  = @TotalCash1 OUTPUT

				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO dbo.Transfer
					(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					winlostdate, currency,actualrate,currencyName, recommend, mrecommend, srecommend, scomm, swinlost,ip,statusID, balance, RepUpdateTime)
				VALUES (@TransID, @Userid , @custid, @memberName, @refno, CURRENT_TIMESTAMP, 21004, 'To Customer :: ' + @agName, 0, @amount,
					@WinlostDate, @currency,@actualrate,@currName, @recommend, @MRecommend, @srecommend, 0, 0,@ip,131, @TotalCash1, SYSDATETIME())

				if @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 103
					
					UPDATE dbo.Transfer WITH(ROWLOCK)
					SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0
					WHERE custid in (@recommend, @custid)
						and bettype = 21004
						and refno = @refno
						
					---rollback balance
					--EXEC Dot_BalanceUpdCredit @CustID = @CustID, @balance = @amount
					EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @amount, @Type = 2
					return
				END

				--Add writelog for each amt transfered - Vinh 20080629
				Select @LogData = 'Transfer all members: Transfer from Customer ' + @memberName + ' to Agent ' + @agName + ' with amount ' + convert(varchar(20), @amount) + ' Ref.No ' + convert(varchar(20), @refno)
						
			END
			ELSE if (@amount<0 and @SkipTransfer = 0)
			BEGIN

				--SET @amount = abs(@amount) 			
				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO  dbo.Transfer 
				   (transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					winlostdate, currency,actualrate, currencyName,recommend, mrecommend, srecommend, 
					scomm, swinlost,ip,statusID,RepUpdateTime)
				VALUES (@TransID, @Userid, @recommend, @agName, @refno, CURRENT_TIMESTAMP, 21004, 'To Customer :: ' + @memberName, 0, abs(@amount),
					 @WinlostDate, @currency,@actualrate,@currName, @recommend, @MRecommend, @srecommend, 
					0, 0,@ip,131,SYSDATETIME())
				if @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 104
					
					UPDATE dbo.Transfer WITH(ROWLOCK)
					SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0
					WHERE custid in (@recommend, @custid)
						and bettype = 21004
						and refno = @refno
						
					return
				END

				DECLARE @TotalCash3 MONEY 
				EXEC Acc_CustomerSelCash_CaptureBalance @custid = @custid, @TotalCash  = @TotalCash3 OUTPUT

				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO dbo.Transfer 
				   (transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					winlostdate, currency,actualrate,currencyName, recommend, mrecommend, srecommend, 
					scomm, swinlost,ip,statusID, balance, RepUpdateTime)
				VALUES (@TransID, @Userid, @custid, @memberName, @refno, CURRENT_TIMESTAMP, 21004, 'From Customer :: ' + @agName, abs(@amount), 0,
					@WinlostDate, @currency,@actualrate,@currName, @recommend, @MRecommend, @srecommend, 
					0, 0,@ip,131, @TotalCash3, SYSDATETIME())

				if @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 105
					
					UPDATE dbo.Transfer WITH(ROWLOCK)
					SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0
					WHERE custid in (@recommend, @custid)
						and bettype = 21004
						and refno = @refno
						
					return
				END
				
				---update credit balance
				SELECT @ABSamount = abs(@amount)
				--EXEC Dot_BalanceUpdCredit @CustID = @CustID, @balance = @ABSamount
				EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @ABSamount, @Type = 2
			
				--Add writelog for each amt transfered - Vinh 20080629
				SELECT @LogData = 'Transfer all members: Transfer from Agent ' + @agName + ' to Customer ' + @memberName + ' with amount ' + convert(varchar(20), @amount) + ' Ref.No ' + convert(varchar(20), @refno)
				
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
				
				set @isSucc='true'  
				
				BEGIN TRY			
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @AgentID, @ToCustID = @custid, @IP = @IP, @Doing = @LogData			
				END TRY
				BEGIN CATCH
					Select @LogData = @LogData + ' ErrMsg=' + error_message()
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @AgentID, @ToCustID = @custid, @IP = @IP, @Doing = @LogData			
				END CATCH				

				SET @count=@count+1 
				IF @count%@batch = 0
					WAITFOR DELAY '000:00:01' 
			END		
				------------------------------------------------------------------------------------------
			
		FETCH NEXT FROM CS_recommend INTO @custid, @recommend, @mrecommend, @srecommend,
										  @memberName, @agName, @amount 
	  END  
	  
	  CLOSE CS_recommend  
	  DEALLOCATE CS_recommend  
	  DROP TABLE #Member
	 
	IF (@isSucc='true') 
	BEGIN
		SELECT @LogData = 'Transfer all members: for Agent/Master/Super ' + @AgentName
		BEGIN TRY
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @AgentID, @ToCustID = 0, @IP = @IP, @Doing = @LogData
		END TRY
		BEGIN CATCH
			Select @LogData = @LogData + ' ErrMsg=' + error_message()
			EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @AgentID, @ToCustID = 0, @IP = @IP, @Doing = @LogData		
		END CATCH
	END	

	if @ErrItems <> ''  
	BEGIN  
		select @ErrCode = 107  
		select @ErrItems = LEFT(@ErrItems, len(@ErrItems)-1)  
		Select @ErrMsg = N'Clear balance failed: Allow only one transfer per day. Failed for the following user(s): ' + @ErrItems
	END
END	
GO
