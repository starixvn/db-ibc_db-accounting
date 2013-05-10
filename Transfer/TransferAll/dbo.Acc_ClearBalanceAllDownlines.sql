
ALTER PROCEDURE [dbo].[Acc_ClearBalanceAllDownlines]
	@AgentName varchar(50),	
	@UserID int = 8,
	@IP nvarchar(15)='', 
	@ErrMsg nvarchar(max) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT
AS

 /*
	Created: Daniel
	Original: DBA_ArchiveAccount_ClearBalance
	Task: Customer/ Tranfer All/ Transfer All Downlines
	Revisions:
		- 20091013@Daniel: added
		- 20091125@Kiwi: Remove comstatus because it's no used.
		- 20100424@Henry: insert data to column StatusID of Bettrans (StatusID = 131 for bettype 103) + Update Status = 'Completed'
		- 20100611@Henry: Write exact amount to log when transferring
		- 20100803@Henry: grant execute permission to [bodbExtAccNet]
		- 20101229@Lukas: Re-arrange bettype
		- 20111011@Viet: revise SP
		- 20111022@Viet: use NOLOCK for select part
		- 20111024@Sophia: Update balance credit/debit for members
		- 20120411@Sophia: Revise balance credit/debit for members
		- 20121015@Dan: reset yesterday balance for live casino
		- 20121016@Dan: check existed transfer record to skip
		- 20121109@Viet: do not allow this SP to run once cpu is high
		- 20121203@Dan: skip deleted transfer record when check existed transfer. Delay updating by batch (500 customer) to avoid affect replication
		- 20130208@Elodie: Change link server DB03 to DBPOLICY
					       Write more log on DBTXN server in case of DBLOG server failure
	Param's Explanation:
		@AgentName: username of agent/master/super to clear his all downlines' balance
*/ 

SET NOCOUNT ON

------ 20121109@Viet: do not allow this SP to run once cpu is high --------
declare @ispermit bit
EXEC dbo.Server_IsHeavyLoadPermitted @ispermit OUTPUT
IF @ispermit = 0 
BEGIN
	SELECT @errcode = 1, @errmsg = 'oops! Server is too busy, please try again later!'
	RETURN
END
------ /20121109@Viet: do not allow this SP to run once cpu is high --------

--Check permission
DECLARE @ErrMsg_temp nvarchar(4000)   
-- must use temporary variable for @ErrMsg because of nvarchar(max) is not allowed in remote call

EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherTrans]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg_temp output
SELECT @ErrMsg = @ErrMsg_temp
If @ErrCode <> 0
	RETURN

Declare @roleid int, @AgentID int, @Amount MONEY,
		@custid int, @recommend int, @mrecommend int, @srecommend int, 
		@currency int, @actualrate float, @currencyName nvarchar(10),
		@membername varchar(50), @agentusername varchar(50), @mastername varchar(50), @supername varchar(50),
		@memberBalance MONEY, @agentBalance MONEY, @masterBalance MONEY, 
		@ABSmemberBalance MONEY

DECLARE @LogData varchar(1000)

Declare @refno bigint, @grefno int, @Now datetime

DECLARE @ErrItems nvarchar(max), @SkipTransfer bit, @isSucc varchar(10)  
SELECT @isSucc='false', @ErrItems = ''    

DECLARE @count int, @batch int
SELECT @batch=200, @count=0 

DECLARE @WinlostDate datetime  
SELECT @WinlostDate = convert(nvarchar(10),current_timestamp,120) 

SELECT @roleid = roleid, @AgentID = custid
FROM custinfo (nolock)
WHERE username = @AgentName

if isnull(@AgentID,0) = 0 or @roleid NOT in (2,3,4)
BEGIN
	Select @ErrMsg = @AgentName +':'+ 'Invalid Agent Username', @ErrCode = 101	
	return
END

/*--20091017@Thien: not check this function so that upline can get back the used credit
--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @AgentID, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
*/
--==========================================================
--CREATING TEMP TABLES
--==========================================================

CREATE TABLE #Member (
	custid int PRIMARY KEY, recommend int, mrecommend int, srecommend int, 
	currency int, actualrate float, currencyName nvarchar(10),
	membername varchar(50), agentname varchar(50), memberBalance MONEY default 0)

CREATE TABLE #SkippedMember (
	custid int PRIMARY KEY, recommend int, mrecommend int, srecommend int)
		
CREATE TABLE #Agent (
	recommend int PRIMARY KEY, mrecommend int, srecommend int, 
	currency int, actualrate float, currencyName nvarchar(10),
	agentname varchar(50), mastername varchar(50), agentBalance MONEY default 0)

CREATE TABLE #Master (
	mrecommend int PRIMARY KEY, srecommend int, currency int, actualrate float, currencyName nvarchar(10),
	mastername varchar(50), supername varchar(50), masterBalance MONEY default 0)		
		
IF @roleid = 2
BEGIN
	INSERT INTO #Member 
		(custid, recommend, mrecommend, srecommend, currency, actualrate, currencyName,
		membername, agentname)
	SELECT c.custid, c.recommend, c.mrecommend, c.srecommend, c.currency,e.actualrate, e.currency,
			c.username, ag.username
	FROM custinfo c with(nolock)
		inner join custinfo ag with(nolock) on c.recommend = ag.custid
		inner join exchange e with(nolock) on c.currency = e.exchangeid 
	WHERE  c.recommend = @AgentID AND c.roleid = 1
	
END
IF @roleid = 3
BEGIN
	INSERT INTO #Member (custid, recommend, mrecommend, srecommend, currency, actualrate, currencyName,
						membername, agentname)
	SELECT c.custid, c.recommend, c.mrecommend, c.srecommend, c.currency, e.actualrate, e.currency,
			c.username, ag.username
	FROM custinfo c with(nolock)
		inner join custinfo ag with(nolock) on c.recommend = ag.custid
		inner join exchange e with(nolock) on c.currency = e.exchangeid 
	WHERE c.mrecommend = @AgentID AND c.roleid = 1
	
	INSERT INTO #Agent (recommend, mrecommend, srecommend, currency,actualrate, currencyName, 
					agentname, mastername)
	SELECT distinct c.recommend, c.mrecommend, c.srecommend, c.currency, e.actualrate, e.currency,
					c.username, mag.username 
	FROM custinfo c with(nolock)			
		inner join custinfo mag with(nolock) on c.mrecommend = mag.custid
		inner join exchange e with(nolock) on c.currency = e.exchangeid 
	WHERE  c.mrecommend = @AgentID AND c.roleid = 2
	
END
IF @roleid = 4
BEGIN
	INSERT INTO #Member (custid, recommend, mrecommend, srecommend, currency, actualrate, currencyName,
						membername, agentname)
	SELECT c.custid, c.recommend, c.mrecommend, c.srecommend, c.currency, e.actualrate, e.currency,
			c.username, ag.username
	FROM custinfo c with(nolock)
		inner join custinfo ag with(nolock) on c.recommend = ag.custid
		inner join exchange e with(nolock) on c.currency = e.exchangeid 
	WHERE c.srecommend = @AgentID AND c.roleid = 1
	
	INSERT INTO #Agent (recommend, mrecommend, srecommend, currency,actualrate, currencyName, 
					agentname, mastername)
	SELECT distinct c.recommend, c.mrecommend, c.srecommend, c.currency,e.actualrate, e.currency,
			c.username, mag.username 
	FROM custinfo c with(nolock)			
		inner join custinfo mag with(nolock) on c.mrecommend = mag.custid
		inner join exchange e with(nolock) on c.currency = e.exchangeid 
	WHERE  c.srecommend = @AgentID AND c.roleid = 2
	
	INSERT INTO #Master (mrecommend, srecommend, currency, actualrate, currencyName,
						mastername, supername)
	SELECT distinct c.mrecommend, c.srecommend, c.currency, e.actualrate, e.currency,
		c.username, sag.username
	FROM custinfo c with(nolock)			
		inner join custinfo sag with(nolock) on c.srecommend = sag.custid
		inner join exchange e with(nolock) on c.currency = e.exchangeid 
	WHERE  c.srecommend = @AgentID AND c.roleid = 3
END
	
;WITH B AS (
	SELECT b.custid,
		SUM(isnull(CASE WHEN bettype < 19999 and winlostdate < @winlostdate OR bettype >=19999 THEN winlost-actual_stake +playercomm ELSE 0 END,0)) as MemberBalance
	FROM bettrans b with(nolock, index=IX_custid)
		inner join #Member m on b.custid = m.custid
	WHERE ruben = 1
	GROUP BY b.custid
)
UPDATE #Member
SET memberBalance = isnull(B.MemberBalance,0)
FROM B where #Member.custid = B.custid
	
delete #Member where memberBalance = 0
	
-- Start Transfer (CURSOR Loop) 
SET @Now = CURRENT_TIMESTAMP
	
--------------------------START:MEMBER-AGENT-------------------------------

DECLARE CS_custid
	CURSOR FOR
	SELECT custid, recommend, mrecommend, srecommend, currency, actualrate, currencyName,
		   membername, agentname, memberBalance
	FROM #Member

OPEN CS_custid
FETCH NEXT FROM CS_custid INTO @custid, @recommend, @mrecommend, @srecommend, @currency, @actualrate, @currencyName, 
							   @membername, @agentusername, @memberBalance

WHILE @@FETCH_STATUS = 0
BEGIN		
	
	print @agentusername +':'+ 'MEMBER-AGENT-->Member:' + @membername + ' ' + cast(@memberBalance as varchar(30))
	
		UPDATE ref with (rowlock, UPDLOCK)  SET   @grefno=transcode=transcode+1
		WHERE  refid='acc'
		if @@Error <> 0
		BEGIN
			SELECT @ErrMsg = 'Insert Failed', @ErrCode = 114			
			return
		END
		select @refno=200000000000+@grefno
		
		SELECT @SkipTransfer = 0
		--Check for existing transfer (allow only one transfer per day) - Tho@09062008  
		IF(exists(  
			  SELECT 1 FROM bettrans WITH (NOLOCK)   
			  WHERE custid=@custid AND bettype in (21003, 21004)   
			  AND (transdate BETWEEN convert(varchar(10), current_timestamp, 120) AND convert(varchar(10), current_timestamp, 120) + ' 23:59:59')  
			  AND liveindicator = 0
		 ))  
		BEGIN 
			SELECT @SkipTransfer = 1  
			SELECT @ErrItems = @ErrItems + @membername + ', '  

			INSERT #SkippedMember (custid, recommend , mrecommend , srecommend )
			SELECT @custid, @recommend , @mrecommend , @srecommend 
		END
	
		IF (@memberBalance > 0 and @SkipTransfer = 0)
		BEGIN
			INSERT INTO bettrans 
			   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
				status, ruben, winlostdate, currency, actualrate, currencyName, 
				recommend, mrecommend, srecommend, scomm, swinlost,ip,statusID)
			VALUES (0, @UserID, @recommend, @agentusername, @refno, @Now, 21004, 'From Customer::'+@membername, @memberBalance, 0, 
				'Completed', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
				@recommend, @MRecommend, @srecommend, 0, 0,@IP,131)
			if @@Error <> 0
			BEGIN
				SELECT @ErrMsg = 'Insert Failed', @ErrCode = 101  
				
				DELETE dbo.bettrans
				WHERE custid in (@recommend, @custid)
					and matchid = 0			
					and bettype in (21003, 21004)			
					and refno = @refno
						
				return
			END
			
			---update debit balance
			EXEC Dot_BalanceUpdDebit @CustID = @CustID, @balance = @memberBalance
			
			INSERT INTO bettrans
			   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
				status, ruben, winlostdate, currency, actualrate, currencyName,
				recommend, mrecommend, srecommend, scomm, swinlost,ip,statusID)
			VALUES 
			   (0, @UserID, @custid, @membername, @refno, @Now, 21004, 'To Customer::'+@agentusername, 0, @memberBalance,
				'Completed', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
				@recommend, @MRecommend, @srecommend, 0, 0,@IP,131)
			if @@Error <> 0
			BEGIN
				SELECT @ErrMsg = 'Insert Failed', @ErrCode = 102  
				
				DELETE dbo.bettrans
				WHERE custid in (@recommend, @custid)
					and matchid = 0	
					and bettype in (21003, 21004)						
					and refno = @refno
						
				--rollback balance
				EXEC Dot_BalanceUpdCredit @CustID = @CustID, @balance = @memberBalance
				return
			END
			
			
			SELECT @LogData = 'Transfer (clear balance) all downlines: Transfer from Member ' + @membername + ' to Agent ' + @agentusername + ' with amount ' + convert(varchar(20), @memberBalance) + ' Ref.No ' + convert(varchar(20), @refno)
			
			DECLARE @isResetYesterdayBalance BIT, @ErrCode_ResetYesterdayBalance BIT, @YesterdayBalance MONEY
			-- reset yesterday balance for live casino							
			EXEC Acc_BalanceGameResetYesterday @CustID = @CustID, @isResetYesterdayBalance = @isResetYesterdayBalance OUTPUT, @YesterdayBalance = @YesterdayBalance	 OUTPUT, @ErrCode = @ErrCode_ResetYesterdayBalance OUTPUT	
			Select @LogData = @LogData + CASE WHEN @isResetYesterdayBalance = 1 THEN 
												CASE WHEN @ErrCode_ResetYesterdayBalance = 0 THEN '. (ResetLiveCSBalance = suscess, YesterdayBalance =' + CAST(@YesterdayBalance AS VARCHAR(50)) + ')' 
												ELSE '. (ResetLiveCSBalance = fail)' END		
										ELSE '' END			
			
			set @isSucc='true'  						
			BEGIN TRY
				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @custid, @ToCustID = @recommend, @IP = @IP, @Doing = @LogData
			END TRY
			BEGIN CATCH
				Select @LogData = @LogData + ' ErrMsg=' + error_message()
				EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @custid, @ToCustID = @recommend, @IP = @IP, @Doing = @LogData
			END CATCH
			
			SET @count=@count+1 
			IF @count%@batch = 0
				WAITFOR DELAY '000:00:01' 
							
		END
		ELSE if (@memberBalance<0 and @SkipTransfer = 0)		
		BEGIN
			--SET @memberBalance = abs(@memberBalance) 			
			INSERT INTO bettrans 
			   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
				status, ruben, winlostdate, currency, actualrate, currencyName, 
				recommend, mrecommend, srecommend, scomm, swinlost,ip,statusID)
			VALUES 
			   (0, @UserID, @recommend, @agentusername, @refno, CURRENT_TIMESTAMP, 21004, 'To Customer::'+@membername, 0, abs(@memberBalance) ,
				'Completed', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
				@recommend, @MRecommend, @srecommend, 0, 0,@IP,131)
			if @@Error <> 0
			BEGIN
				SELECT @ErrMsg = 'Insert Failed', @ErrCode = 103  
				
				DELETE dbo.bettrans
				WHERE custid in (@recommend, @custid)
					and matchid = 0	
					and bettype in (21003, 21004)						
					and refno = @refno
					
				return
			END
			
			INSERT INTO bettrans
			   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
				status, ruben, winlostdate, currency, actualrate, currencyName,
				recommend, mrecommend, srecommend, scomm, swinlost,ip,statusID)
			VALUES 
			   (0, @UserID, @custid, @membername, @refno, CURRENT_TIMESTAMP, 21004, 'From Customer::'+@agentusername, abs(@memberBalance) , 0,
				'Completed', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
				@recommend, @MRecommend, @srecommend, 0, 0,@IP,131)
			if @@Error <> 0
			BEGIN
				SELECT @ErrMsg = 'Insert Failed', @ErrCode = 104 
				
				DELETE dbo.bettrans
				WHERE custid in (@recommend, @custid)
					and matchid = 0	
					and bettype in (21003, 21004)						
					and refno = @refno
					
				return
			END
			
			---update credit balance
			SELECT @ABSmemberBalance = abs(@memberBalance)
			EXEC Dot_BalanceUpdCredit @CustID = @CustID, @balance = @ABSmemberBalance	
			
			SELECT @LogData = 'Transfer (clear balance) all downlines: Transfer from Agent ' + @agentusername + ' to Member ' + @membername + ' with amount ' + convert(varchar(20), @memberBalance) + ' Ref.No ' + convert(varchar(20), @refno)
						
			-- reset yesterday balance for live casino							
			EXEC Acc_BalanceGameResetYesterday @CustID = @CustID, @isResetYesterdayBalance = @isResetYesterdayBalance OUTPUT, @YesterdayBalance = @YesterdayBalance	 OUTPUT, @ErrCode = @ErrCode_ResetYesterdayBalance OUTPUT	
			Select @LogData = @LogData + CASE WHEN @isResetYesterdayBalance = 1 THEN 
												CASE WHEN @ErrCode_ResetYesterdayBalance = 0 THEN '. (ResetLiveCSBalance = suscess, YesterdayBalance =' + CAST(@YesterdayBalance AS VARCHAR(50)) + ')' 
												ELSE '. (ResetLiveCSBalance = fail)' END		
										ELSE '' END			
			
			set @isSucc='true'  	
			BEGIN TRY						
				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @recommend, @ToCustID = @custid, @IP = @IP, @Doing = @LogData
			END TRY
			BEGIN CATCH
				Select @LogData = @LogData + ' ErrMsg=' + error_message()
				EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @recommend, @ToCustID = @custid, @IP = @IP, @Doing = @LogData
			END CATCH
			
			SET @count=@count+1 
			IF @count%@batch = 0
				WAITFOR DELAY '000:00:01' 

		END
		
	FETCH NEXT FROM CS_custid INTO @custid, @recommend, @mrecommend, @srecommend, @currency, @actualrate, @currencyName,
								   @membername, @agentusername, @memberBalance
END

CLOSE CS_custid
DEALLOCATE CS_custid

-- skip master, agent of skipped member
if @ErrItems <> ''  
BEGIN  
	DELETE #Agent
	WHERE #Agent.recommend IN (SELECT recommend FROM #SkippedMember)
	
	DELETE #Master
	WHERE #Master.mrecommend IN (SELECT mrecommend FROM #SkippedMember)
	
END

--------------------------END:MEMBER-AGENT-------------------------------	

--------------------------START:AGENT-MASTER-------------------------------	
if (@roleid > 2)
BEGIN	
	;WITH B AS (
		SELECT b.recommend, 
				isnull(sum(case when b.custid=b.recommend then winlost-actual_stake else awinlost+comm-playercomm end), 0) 
				+ isnull(sum(case when b.custid<>b.recommend and ruben=1 then winlost-actual_stake+playercomm else 0 end), 0) 
				- isnull(sum(case when bettype < 19999 and winlostdate >= @WinlostDate and ruben =1 then awinlost+comm + winlost-actual_stake else 0 end ),0) as agentBalance
		FROM bettrans b with(nolock, index=IX_recommend)
			inner join #Agent a on b.recommend = a.recommend
		GROUP BY b.recommend
	)
	UPDATE #Agent
	SET agentBalance = isnull(B.agentBalance,0)
	FROM B where #Agent.recommend = B.recommend

	delete #Agent where agentBalance = 0
				
	DECLARE CS_agent
		CURSOR FOR
		SELECT distinct recommend, mrecommend, srecommend, currency, actualrate, currencyName,
						agentname, mastername, agentBalance
		FROM #Agent

	OPEN CS_agent
	FETCH NEXT FROM CS_agent INTO @recommend, @mrecommend, @srecommend, @currency, @actualrate, @currencyName,
								  @agentusername, @mastername, @agentBalance

	WHILE @@FETCH_STATUS = 0
	BEGIN		
		print @agentusername +':'+ 'AGENT-MASTER-->Agent:' + @agentusername+ ' ' + cast(@agentBalance as varchar(30))
		
			UPDATE ref with (rowlock, UPDLOCK)  SET   @grefno=transcode=transcode+1
			WHERE  refid='acc'
			if @@Error <> 0
			BEGIN
				SELECT @ErrMsg = 'Insert Failed', @ErrCode = 115	
				return
			END
			select @refno=200000000000+@grefno
		
			IF @agentBalance > 0
			BEGIN					
				INSERT INTO bettrans 
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status, ruben, winlostdate, currency, actualrate, currencyName,
					recommend, mrecommend, srecommend, scomm, swinlost, ip,statusID)
				VALUES 
				   (0, @UserID, @mrecommend, @mastername, @refno, @Now, 21003, 'From Customer::'+@agentusername, @agentBalance, 0, 
					'Completed', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					0, @mrecommend, @srecommend, 0, 0, @IP,131)
				if @@Error <> 0
				BEGIN								
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 105  				
					
					DELETE dbo.bettrans
					WHERE custid in (@mrecommend, @recommend)
						and matchid = 0	
						and bettype in (21003, 21004)						
						and refno = @refno
						
					return
				END
				INSERT INTO bettrans
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status, ruben, winlostdate, currency, actualrate, currencyName,
					recommend, mrecommend, srecommend, scomm, swinlost, ip,statusID)
				VALUES 
				   (0, @UserID, @recommend, @agentusername, @refno, @Now, 21003, 'To Customer::'+@mastername, 0, @agentBalance,
					'Completed', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					@recommend, @mrecommend, @srecommend, 0, 0, @IP,131)
				if @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 106
					
					DELETE dbo.bettrans
					WHERE custid in (@mrecommend, @recommend)
						and matchid = 0	
						and bettype in (21003, 21004)						
						and refno = @refno
						
					return
				END
				set @isSucc='true'  
				SELECT @LogData = 'Transfer (clear balance) all downlines: Transfer from agent ' + @agentusername + ' to Master ' + @mastername + ' with amount ' + convert(varchar(20), @agentBalance) + ' Ref.No ' + convert(varchar(20), @refno)
				
				BEGIN TRY				
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @recommend, @ToCustID = @mrecommend, @IP = @IP, @Doing = @LogData
				END TRY
				BEGIN CATCH
					Select @LogData = @LogData + ' ErrMsg=' + error_message()
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @recommend, @ToCustID = @mrecommend, @IP = @IP, @Doing = @LogData
				END CATCH				
				
				SET @count=@count+1 
				IF @count%@batch = 0
					WAITFOR DELAY '000:00:01' 				
			END
			ELSE if @agentBalance<0
			BEGIN
				--SET @agentBalance = abs(@agentBalance)
			
				INSERT INTO bettrans 
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status, ruben, winlostdate, currency, actualrate, currencyName,
					recommend, mrecommend, srecommend, scomm, swinlost, ip,statusID)
				VALUES (0, @UserID, @mrecommend, @mastername, @refno, @Now, 21003, 'To Customer::'+@agentusername, 0, abs(@agentBalance),
					'Completed', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					0, @mrecommend, @srecommend, 0, 0, @IP,131)
				if @@Error <> 0
				BEGIN						
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 107
					
					DELETE dbo.bettrans
					WHERE custid in (@mrecommend, @recommend)
						and matchid = 0	
						and bettype in (21003, 21004)						
						and refno = @refno
						
					return
				END
				
				INSERT INTO bettrans
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status, ruben, winlostdate, currency, actualrate, currencyName,
					recommend, mrecommend, srecommend, scomm, swinlost, ip,statusID)
				VALUES 
				   (0, @UserID, @recommend, @agentusername, @refno, @Now, 21003, 'From Customer::'+@mastername, abs(@agentBalance), 0,
					'Completed', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					@recommend, @mrecommend, @srecommend, 0, 0, @IP,131)
				if @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 108
					
					DELETE dbo.bettrans
					WHERE custid in (@mrecommend, @recommend)
						and matchid = 0	
						and bettype in (21003, 21004)						
						and refno = @refno
						
					return
				END			
				
				set @isSucc='true'  
				SELECT @LogData = 'Transfer (clear balance) all downlines: Transfer from Master ' + @mastername + ' to Agent ' + @agentusername + ' with amount ' + convert(varchar(20), @agentBalance) + ' Ref.No ' + convert(varchar(20), @refno)
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @mrecommend, @ToCustID = @recommend, @IP = @IP, @Doing = @LogData
				END TRY
				BEGIN CATCH
					Select @LogData = @LogData + ' ErrMsg=' + error_message()
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @mrecommend, @ToCustID = @recommend, @IP = @IP, @Doing = @LogData
				END CATCH
				SET @count=@count+1 
				IF @count%@batch = 0
					WAITFOR DELAY '000:00:01' 
			END	
	
			
		FETCH NEXT FROM CS_agent INTO @recommend, @mrecommend, @srecommend, @currency, @actualrate, @currencyName,
									  @agentusername, @mastername, @agentBalance
	END

	CLOSE CS_agent
	DEALLOCATE CS_agent
	DROP TABLE #Agent
	--------------------------END:AGENT-MASTER-------------------------------
END

--------------------------START:MASTER-SUPER-------------------------------
if @RoleID = 4
BEGIN	
	;WITH B AS (
		SELECT b.mrecommend, 
				isnull(sum(case when b.custid=b.mrecommend then winlost-actual_stake else mwinlost+acomm-comm end), 0)
				+ isnull(sum(case when b.custid<>b.mrecommend and b.custid <> b.recommend and b.custid<>b.srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end), 0) 
				+ IsNull(sum(case when b.custid=b.recommend then winlost-actual_stake else awinlost+comm-playercomm end),0) 
				- IsNull(sum(case when bettype < 19999 and winlostdate >= @WinlostDate and ruben =1 then winlost-actual_stake + mwinlost + acomm + awinlost else 0 end),0) as masterBalance
		FROM bettrans b with(nolock, index=IX_custid)
			INNER JOIN Custinfo c on c.custid = b.custid
		WHERE c.mrecommend in (select mrecommend from #Master)			
		GROUP BY b.mrecommend
	)
	UPDATE #Master
	SET masterBalance = isnull(B.masterBalance,0)
	FROM B where #Master.mRecommend = B.mRecommend

	delete #Master where masterBalance = 0	

	DECLARE CS_master
		CURSOR FOR
		SELECT distinct mrecommend, srecommend, currency, actualrate, currencyName,
						mastername, supername, masterBalance
		FROM #Master

	OPEN CS_master
	FETCH NEXT FROM CS_master INTO @mrecommend, @srecommend, @currency, @actualrate, @currencyName,
								   @mastername, @supername, @masterBalance

	WHILE @@FETCH_STATUS = 0
	BEGIN
		print @agentusername +':'+ 'MASTER-SUPER-->Master:' + @mastername+ ' ' + cast(@masterBalance as varchar(30))
		
			UPDATE ref with (rowlock, UPDLOCK)  SET   @grefno=transcode=transcode+1
			WHERE  refid='acc'
			if @@Error <> 0
			BEGIN
				SELECT @ErrMsg = 'Insert Failed', @ErrCode = 116	
				return
			END
			select @refno=200000000000+@grefno
		
			IF @masterBalance > 0
			BEGIN			
				INSERT INTO bettrans 
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status, ruben, winlostdate, currency, actualrate, currencyName,
					mrecommend, srecommend, scomm, swinlost, recommend, ip,statusID)
				VALUES 
				   (0, @UserID, @srecommend, @supername, @refno, @Now, 21003, 'From Customer::'+@mastername, @masterBalance, 0, 
					'Completed', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					0, @srecommend, 0, 0, 0, @ip,131)
				if @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 109
					
					DELETE dbo.bettrans
					WHERE custid in (@srecommend, @mrecommend)
						and matchid = 0	
						and bettype in (21003, 21004)						
						and refno = @refno
						
					return
				END
				INSERT INTO bettrans
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status, ruben, winlostdate, currency, actualrate, currencyName, 
					mrecommend, srecommend, scomm, swinlost, recommend, ip,statusID)
				VALUES 
				   (0, @UserID, @mrecommend, @mastername, @refno, @Now, 21003, 'To Customer::'+@supername, 0, @masterBalance,
					'Completed', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					@mrecommend, @srecommend, 0, 0, 0, @ip,131)
				if @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 110
					
					DELETE dbo.bettrans
					WHERE custid in (@srecommend, @mrecommend)
						and matchid = 0	
						and bettype in (21003, 21004)						
						and refno = @refno
						
					return
				END

				set @isSucc='true'  
				SELECT @LogData = 'Transfer (clear balance) all downlines: Transfer from Master ' + @mastername + ' to Super ' + @supername + ' with amount ' + convert(varchar(20), @masterBalance) + ' Ref.No ' + convert(varchar(20), @refno)
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @mrecommend, @ToCustID = @srecommend, @IP = @IP, @Doing = @LogData
				END TRY
				BEGIN CATCH
					Select @LogData = @LogData + ' ErrMsg=' + error_message()
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @mrecommend, @ToCustID = @srecommend, @IP = @IP, @Doing = @LogData
				END CATCH
				SET @count=@count+1 
				IF @count%@batch = 0
					WAITFOR DELAY '000:00:01' 
			END
			ELSE if @masterBalance<0
			BEGIN
				--SET @masterBalance = abs(@masterBalance)
			
				INSERT INTO bettrans 
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status, ruben, winlostdate, currency, actualrate, currencyName,
					mrecommend, srecommend, scomm, swinlost, recommend, ip,statusID)
				VALUES 
				   (0, @UserID, @srecommend, @supername, @refno, @Now, 21003, 'To Customer::'+@mastername, 0, abs(@masterBalance),
					'Completed', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					0, @srecommend, 0, 0, 0, @ip,131)
				if @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 111
					
					DELETE dbo.bettrans
					WHERE custid in (@srecommend, @mrecommend)
						and matchid = 0	
						and bettype in (21003, 21004)						
						and refno = @refno
						
					return
				END
				INSERT INTO bettrans
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status, ruben, winlostdate, currency, actualrate, currencyName, 
					mrecommend, srecommend, scomm, swinlost, recommend, ip,statusID)
				VALUES 
				   (0, @UserID, @mrecommend, @mastername, @refno, CURRENT_TIMESTAMP, 21003, 'From Customer::'+@supername, abs(@masterBalance), 0,
					'Completed', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					@mrecommend, @srecommend, 0, 0, 0, @ip,131)
				if @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 112
					
					DELETE dbo.bettrans
					WHERE custid in (@srecommend, @mrecommend)
						and matchid = 0	
						and bettype in (21003, 21004)						
						and refno = @refno
						
					return
				END				
				
				set @isSucc='true'  
				SELECT @LogData = 'Transfer (clear balance) all downlines: Transfer from Super ' + @supername + ' to Master ' + @mastername + ' with amount ' + convert(varchar(20), @masterBalance) + ' Ref.No ' + convert(varchar(20), @refno)
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @srecommend, @ToCustID = @mrecommend, @IP = @IP, @Doing = @LogData
				END TRY
				BEGIN CATCH
					Select @LogData = @LogData + ' ErrMsg=' + error_message()
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @srecommend, @ToCustID = @mrecommend, @IP = @IP, @Doing = @LogData
				END CATCH
				SET @count=@count+1 
				IF @count%@batch = 0
					WAITFOR DELAY '000:00:01' 
			END		
			
		FETCH NEXT FROM CS_master INTO @mrecommend, @srecommend, @currency, @actualrate, @currencyName,
									   @mastername, @supername, @masterBalance
	END

	CLOSE CS_master
	DEALLOCATE CS_master
	DROP TABLE #Master
END
--------------------------END:MASTER-SUPER-------------------------------

DROP TABLE #Member
DROP TABLE #SkippedMember

IF (@isSucc='true') 
BEGIN
	SELECT @LogData = 'Transfer (clear balance) all downlines: for Agent/Master/Super ' + @AgentName
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
	select @ErrCode = 113
	select @ErrItems = LEFT(@ErrItems, len(@ErrItems)-1)  
	Select @ErrMsg = N'Clear balance failed: Allow only one transfer per day. Failed for the following user(s) and their upline (master, agent): ' + @ErrItems
	return
END

GO
GRANT EXECUTE ON [dbo].[Acc_ClearBalanceAllDownlines] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_ClearBalanceAllDownlines] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ClearBalanceAllDownlines] TO [vnteam]
