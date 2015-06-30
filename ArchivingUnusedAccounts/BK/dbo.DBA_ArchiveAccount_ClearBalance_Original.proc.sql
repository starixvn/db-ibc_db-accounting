ALTER PROCEDURE [dbo].[DBA_ArchiveAccount_ClearBalance_All]
	@AccName varchar(50),	
	@UserID int = 360418,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT
AS
/*
 --Pre-check needed:
	--+Closed status
	--+Active transactions: bet, transfer
--Post-check needed:
	--+Check the REAL total balance of super: need to be clear also by Ah Wan
	--+For DIRECT Master: transfer to Parent Currency. Then need to ask Ah Wan to clear the Currency Super Agent
Created: 
Revisions:
		- 20091125@Kiwi: Remove comstatus because it's no used.	
		- 20100511@Henry: insert data to column statusID
		- 20101225@Henry: change bettype to new range
		- 20111031@Lukas: Update member's balance
Param's Explanation:
*/ 
print  'Start:' + convert(varchar(50), getdate(), 113)

Declare @roleid int, @AgentID int, @Amount MONEY,
		@custid int, @recommend int, @mrecommend int, @srecommend int, 
		@currency int, @actualrate float, @currencyName nvarchar(10),
		@membername varchar(50), @agentname varchar(50), @mastername varchar(50), @supername varchar(50),
		@memberBalance MONEY, @agentBalance MONEY, @masterBalance MONEY

Declare @refno bigint, @grefno int, @Now datetime


SELECT @roleid = roleid, @AgentID = custid
FROM custinfo (nolock)
WHERE username = @AccName

if isnull(@AgentID,0) = 0 or @roleid NOT in (2,3,4)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'Invalid Agent User Name', @ErrCode = 101	
	return
END

if exists (
		select 1
		from bettrans (nolock)
		where custid = @AgentID
		having count(*) > 2
		)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'There is active transactions. Please re-check!!', @ErrCode = 101
	return
END


--==========================================================
--CREATING TEMP TABLES
--==========================================================

	CREATE TABLE #Member 
	(
		custid int PRIMARY KEY, recommend int, mrecommend int, srecommend int, 
		currency int, actualrate float, currencyName nvarchar(10),
		membername varchar(50), agentname varchar(50), mastername varchar(50), supername varchar(50), 
		memberBalance MONEY default 0
	)
	CREATE TABLE #Agent 
	   (recommend int PRIMARY KEY, mrecommend int, srecommend int, 
	    currency int, actualrate float, currencyName nvarchar(10),
		agentname varchar(50), mastername varchar(50), agentBalance MONEY default 0)
	
	CREATE TABLE #Master 
		   (mrecommend int PRIMARY KEY, srecommend int, currency int, actualrate float, currencyName nvarchar(10),
			mastername varchar(50), supername varchar(50), masterBalance MONEY default 0)
		
	IF @roleid NOT IN (2,3,4) RETURN 0
		
	IF @roleid = 2
	BEGIN
		INSERT INTO #Member 
		      (custid, recommend, mrecommend, srecommend, currency, actualrate, currencyName,
			   membername, agentname, mastername, supername)
		SELECT c.custid, c.recommend, c.mrecommend, c.srecommend, c.currency,e.actualrate, e.currency,
				c.username, ag.username, mag.username, sag.username
		FROM custinfo c (nolock)
			inner join custinfo ag (nolock) on c.recommend = ag.custid
			inner join custinfo mag (nolock) on c.mrecommend = mag.custid
			inner join custinfo sag (nolock) on c.srecommend = sag.custid
			inner join exchange e  (nolock) on c.currency = e.exchangeid 
		WHERE  c.recommend = @AgentID AND c.roleid = 1
		
		INSERT INTO #Agent (recommend, mrecommend, srecommend, currency, actualrate, currencyName, 
						agentname, mastername)
		SELECT distinct c.recommend, c.mrecommend, c.srecommend, c.currency, e.actualrate, e.currency,
				        c.username, mag.username 
		FROM custinfo c (nolock)			
			inner join custinfo mag (nolock) on c.mrecommend = mag.custid
			inner join exchange e (nolock) on c.currency = e.exchangeid 
		WHERE  c.recommend = @AgentID AND c.roleid = 2
		
		
	END
	IF @roleid = 3
	BEGIN
		INSERT INTO #Member (custid, recommend, mrecommend, srecommend, currency, actualrate, currencyName,
							membername, agentname, mastername, supername)
		SELECT c.custid, c.recommend, c.mrecommend, c.srecommend, c.currency, e.actualrate, e.currency,
				c.username, ag.username, mag.username, sag.username
		FROM custinfo c (nolock)
			inner join custinfo ag (nolock) on c.recommend = ag.custid
			inner join custinfo mag (nolock) on c.mrecommend = mag.custid
			inner join custinfo sag (nolock) on c.srecommend = sag.custid
			inner join exchange e (nolock) on c.currency = e.exchangeid 
		WHERE c.mrecommend = @AgentID AND c.roleid = 1
		
		INSERT INTO #Agent (recommend, mrecommend, srecommend, currency,actualrate, currencyName, 
						agentname, mastername)
		SELECT distinct c.recommend, c.mrecommend, c.srecommend, c.currency, e.actualrate, e.currency,
						c.username, mag.username 
		FROM custinfo c (nolock)			
			inner join custinfo mag (nolock) on c.mrecommend = mag.custid
			inner join exchange e (nolock) on c.currency = e.exchangeid 
		WHERE  c.mrecommend = @AgentID AND c.roleid = 2
		
		INSERT INTO #Master (mrecommend, srecommend, currency, actualrate, currencyName,
							mastername, supername)
		SELECT distinct c.mrecommend, c.srecommend, c.currency, e.actualrate, e.currency,
					c.username, sag.username
		FROM custinfo c (nolock)			
			inner join custinfo sag (nolock) on c.srecommend = sag.custid
			inner join exchange e (nolock) on c.currency = e.exchangeid 
		WHERE  c.mrecommend = @AgentID AND c.roleid = 3
		
	END
	IF @roleid = 4
	BEGIN
		INSERT INTO #Member (custid, recommend, mrecommend, srecommend, currency, actualrate, currencyName,
							membername, agentname, mastername, supername)
		SELECT c.custid, c.recommend, c.mrecommend, c.srecommend, c.currency, e.actualrate, e.currency,
				c.username, ag.username, mag.username, sag.username
		FROM custinfo c (nolock)
			inner join custinfo ag (nolock) on c.recommend = ag.custid
			inner join custinfo mag (nolock) on c.mrecommend = mag.custid
			inner join custinfo sag (nolock) on c.srecommend = sag.custid
			inner join exchange e (nolock) on c.currency = e.exchangeid 
		WHERE c.srecommend = @AgentID AND c.roleid = 1
		
		INSERT INTO #Agent (recommend, mrecommend, srecommend, currency,actualrate, currencyName, 
						agentname, mastername)
		SELECT distinct c.recommend, c.mrecommend, c.srecommend, c.currency,e.actualrate, e.currency,
				c.username, mag.username 
		FROM custinfo c (nolock)			
			inner join custinfo mag (nolock) on c.mrecommend = mag.custid
			inner join exchange e (nolock) on c.currency = e.exchangeid 
		WHERE  c.srecommend = @AgentID AND c.roleid = 2
		
		INSERT INTO #Master (mrecommend, srecommend, currency, actualrate, currencyName,
							mastername, supername)
		SELECT distinct c.mrecommend, c.srecommend, c.currency, e.actualrate, e.currency,
			c.username, sag.username
		FROM custinfo c (nolock)			
			inner join custinfo sag (nolock) on c.srecommend = sag.custid
			inner join exchange e (nolock) on c.currency = e.exchangeid 
		WHERE  c.srecommend = @AgentID AND c.roleid = 3
	END
	

	print @AccName +':'+ 'Temp Table Done:' + convert(varchar(50), getdate(), 113)	
	
	Update #Member set memberBalance = b.MemberBalance
	from #Member
		inner join (
			Select custid, isnull(SUM(isnull(case when ruben=0 then 0 else winlost-actual_stake+playercomm end, 0)), 0) as MemberBalance
			From bettrans with (NOLOCK)
			group by custid
			) b on #Member.custid = b.custid	

	print @AccName +':'+ 'Member Balance Done:' + convert(varchar(50), getdate(), 113)	
	
	-- Start Transfer (CURSOR Loop) 
	SET @Now = CURRENT_TIMESTAMP
	
	--------------------------START:MEMBER-AGENT-------------------------------
	
	DECLARE CS_custid
		CURSOR FOR
		SELECT custid, recommend, mrecommend, srecommend, currency, actualrate, currencyName,
			   membername, agentname, memberBalance
		FROM #Member
		WHERE memberBalance <> 0		

	OPEN CS_custid
	FETCH NEXT FROM CS_custid INTO @custid, @recommend, @mrecommend, @srecommend, @currency, @actualrate, @currencyName, 
								   @membername, @agentname, @memberBalance

	WHILE @@FETCH_STATUS = 0
	BEGIN		
		
		print @AccName +':'+ 'MEMBER-AGENT-->Member:' + @membername + ' ' + cast(@memberBalance as varchar(30))
		
			UPDATE ref with (rowlock, UPDLOCK)  SET   @grefno=transcode=transcode+1
			WHERE  refid='acc'
			if @@Error <> 0
			BEGIN
				delete bettrans where refno = @refno and matchid = 0
				return
			END
			select @refno=200000000000+@grefno
		
			IF (@memberBalance > 0) 
			BEGIN
				INSERT INTO bettrans 
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status,statusID, ruben, winlostdate, currency, actualrate, currencyName, 
					recommend, mrecommend, srecommend, scomm, swinlost,ip)
				VALUES (0, @UserID, @recommend, @agentname, @refno, @Now, 21004, 'For Delete Account - From Customer::'+@membername, @memberBalance, 0, 
					'Completed',131, 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					@recommend, @MRecommend, @srecommend, 0, 0,'')
				if @@Error <> 0
				BEGIN
					RaisError (@ErrMsg, 16, 1)
					delete bettrans where refno = @refno and matchid = 0
					return
				END
				
				INSERT INTO bettrans
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status,statusID, ruben, winlostdate, currency, actualrate, currencyName,
					recommend, mrecommend, srecommend, scomm, swinlost,ip)
				VALUES 
				   (0, @UserID, @custid, @membername, @refno, @Now, 21004, 'For Delete Account - To Customer::'+@agentname, 0, @memberBalance,
					'Completed',131, 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					@recommend, @MRecommend, @srecommend, 0, 0,'')
				if @@Error <> 0
				BEGIN
					RaisError (@ErrMsg, 16, 1)
					delete bettrans where refno = @refno and matchid = 0
					return
				END
				
				-- update member balance
				EXEC Dot_BalanceUpdDebit @custid = @custid, @balance = @memberbalance		
			END
			ELSE if (@memberBalance<0) 
			BEGIN
				SET @memberBalance = abs(@memberBalance) 			
				INSERT INTO bettrans 
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status,statusID, ruben, winlostdate, currency, actualrate, currencyName, 
					recommend, mrecommend, srecommend, scomm, swinlost,ip)
				VALUES 
				   (0, @UserID, @recommend, @agentname, @refno, CURRENT_TIMESTAMP, 21004, 'For Delete Account - To Customer::'+@membername, 0, @memberBalance,
					'Completed',131, 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					@recommend, @MRecommend, @srecommend, 0, 0,'')
				if @@Error <> 0
				BEGIN
					RaisError (@ErrMsg, 16, 1)
					delete bettrans where refno = @refno and matchid = 0
					return
				END
				
				INSERT INTO bettrans
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status,statusID, ruben, winlostdate, currency, actualrate, currencyName,
					recommend, mrecommend, srecommend, scomm, swinlost,ip)
				VALUES 
				   (0, @UserID, @custid, @membername, @refno, CURRENT_TIMESTAMP, 21004, 'For Delete Account - From Customer::'+@agentname, @memberBalance, 0,
					'Completed',131, 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					@recommend, @MRecommend, @srecommend, 0, 0,'')
				if @@Error <> 0
				BEGIN
					RaisError (@ErrMsg, 16, 1)
					delete bettrans where refno = @refno and matchid = 0
					return
				END
				
				--- update member's balance
				EXEC Dot_BalanceUpdCredit @custid = @custid, @balance = @memberbalance
			END		
			
		FETCH NEXT FROM CS_custid INTO @custid, @recommend, @mrecommend, @srecommend, @currency, @actualrate, @currencyName,
									   @membername, @agentname, @memberBalance
	END

	CLOSE CS_custid
	DEALLOCATE CS_custid
	--------------------------END:MEMBER-AGENT-------------------------------	
	print @AccName +':'+ 'Member cursor Done:' + convert(varchar(50), getdate(), 113)


	--------------------------START:AGENT-MASTER-------------------------------	
	
	Update #Agent set agentBalance = b.agentBalance
	from #Agent
		inner join (
			Select recommend, isnull(sum(case when custid=recommend then winlost-actual_stake else awinlost+comm-playercomm end), 0) + isnull(sum(case when custid<>recommend and ruben=1 then winlost-actual_stake+playercomm else 0 end), 0) as agentBalance
			From bettrans with (NOLOCK)
			group by recommend
			) b on #Agent.recommend = b.recommend

	print @AccName +':'+ 'Agent Balance Done:' + convert(varchar(50), getdate(), 113)
			
				
	DECLARE CS_agent
		CURSOR FOR
		SELECT distinct recommend, mrecommend, srecommend, currency, actualrate, currencyName,
						agentname, mastername, agentBalance
		FROM #Agent
		WHERE agentBalance <> 0

	OPEN CS_agent
	FETCH NEXT FROM CS_agent INTO @recommend, @mrecommend, @srecommend, @currency, @actualrate, @currencyName,
								  @agentname, @mastername, @agentBalance

	WHILE @@FETCH_STATUS = 0
	BEGIN		
		print @AccName +':'+ 'AGENT-MASTER-->Agent:' + @agentname+ ' ' + cast(@agentBalance as varchar(30))
		
			UPDATE ref with (rowlock, UPDLOCK)  SET   @grefno=transcode=transcode+1
			WHERE  refid='acc'
			if @@Error <> 0
			BEGIN
				delete bettrans where refno = @refno and matchid = 0
				return
			END
			select @refno=200000000000+@grefno
		
			IF @agentBalance > 0
			BEGIN					
				INSERT INTO bettrans 
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status,statusID, ruben, winlostdate, currency, actualrate, currencyName,
					recommend, mrecommend, srecommend, scomm, swinlost, ip)
				VALUES 
				   (0, @UserID, @mrecommend, @mastername, @refno, @Now, 21003, 'For Delete Account - From Customer::'+@agentname, @agentBalance, 0, 
					'Completed',131, 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					0, @mrecommend, @srecommend, 0, 0, '')
				if @@Error <> 0
				BEGIN								
					select @ErrCode = 102
					
					delete bettrans where refno = @refno and matchid = 0
					return
				END
				INSERT INTO bettrans
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status,statusID, ruben, winlostdate, currency, actualrate, currencyName,
					recommend, mrecommend, srecommend, scomm, swinlost, ip)
				VALUES 
				   (0, @UserID, @recommend, @agentname, @refno, @Now, 21003, 'For Delete Account - To Customer::'+@mastername, 0, @agentBalance,
					'Completed',131, 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					@recommend, @mrecommend, @srecommend, 0, 0, '')
				if @@Error <> 0
				BEGIN						
					select @ErrCode = 103						
					delete bettrans where refno = @refno and matchid = 0
					return
				END
				
			END
			ELSE if @agentBalance<0
			BEGIN
				SET @agentBalance = abs(@agentBalance)
			
				INSERT INTO bettrans 
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status,statusID, ruben, winlostdate, currency, actualrate, currencyName,
					recommend, mrecommend, srecommend, scomm, swinlost, ip)
				VALUES (0, @UserID, @mrecommend, @mastername, @refno, @Now, 21003, 'For Delete Account - To Customer::'+@agentname, 0, @agentBalance,
					'Completed',131, 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					0, @mrecommend, @srecommend, 0, 0, '')
				if @@Error <> 0
				BEGIN						
					select @ErrCode = 107						
					delete bettrans where refno = @refno and matchid = 0
					return
				END
				
				INSERT INTO bettrans
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status,statusID, ruben, winlostdate, currency, actualrate, currencyName,
					recommend, mrecommend, srecommend, scomm, swinlost, ip)
				VALUES 
				   (0, @UserID, @recommend, @agentname, @refno, @Now, 21003, 'For Delete Account - From Customer::'+@mastername, @agentBalance, 0,
					'Completed',131, 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					@recommend, @mrecommend, @srecommend, 0, 0, '')
				if @@Error <> 0
				BEGIN
					select @ErrCode = 104						
					delete bettrans where refno = @refno and matchid = 0
					return
				END			
			END	
	
			
		FETCH NEXT FROM CS_agent INTO @recommend, @mrecommend, @srecommend, @currency, @actualrate, @currencyName,
									  @agentname, @mastername, @agentBalance
	END

	CLOSE CS_agent
	DEALLOCATE CS_agent
	DROP TABLE #Agent
	--------------------------END:AGENT-MASTER-------------------------------
	print @AccName +':'+ 'Agent cursor Done:' + convert(varchar(50), getdate(), 113)

	--------------------------START:MASTER-SUPER-------------------------------
if @RoleID >= 3
BEGIN	
	
	Update #Master set masterBalance = b.masterBalance
	from #Master
		inner join (
			Select mrecommend, isnull(sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end), 0) + 
						isnull(sum(case when custid<>mrecommend and custid <> recommend and custid<>srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end), 0) 
						+ IsNull(sum(case when custid=recommend then winlost-actual_stake else awinlost+comm-playercomm end),0)	 as masterBalance
			From bettrans with (NOLOCK)
			group by mrecommend
			) b on #Master.mrecommend = b.mrecommend		
	
	
	print @AccName +':'+ 'Master Balance Done:' + convert(varchar(50), getdate(), 113)

	DECLARE CS_master
		CURSOR FOR
		SELECT distinct mrecommend, srecommend, currency, actualrate, currencyName,
						mastername, supername, masterBalance
		FROM #Master
		WHERE masterBalance <> 0

	OPEN CS_master
	FETCH NEXT FROM CS_master INTO @mrecommend, @srecommend, @currency, @actualrate, @currencyName,
								   @mastername, @supername, @masterBalance

	WHILE @@FETCH_STATUS = 0
	BEGIN
		print @AccName +':'+ 'MASTER-SUPER-->Master:' + @mastername+ ' ' + cast(@masterBalance as varchar(30))
		
			UPDATE ref with (rowlock, UPDLOCK)  SET   @grefno=transcode=transcode+1
			WHERE  refid='acc'
			if @@Error <> 0
			BEGIN
				delete bettrans where refno = @refno and matchid = 0
				return
			END
			select @refno=200000000000+@grefno
		
			IF @masterBalance > 0
			BEGIN			
				INSERT INTO bettrans 
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status,statusID, ruben, winlostdate, currency, actualrate, currencyName,
					mrecommend, srecommend, scomm, swinlost, recommend, ip)
				VALUES 
				   (0, @UserID, @srecommend, @supername, @refno, @Now, 21003, 'For Delete Account - From Customer::'+@mastername, @masterBalance, 0, 
					'Completed',131, 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					0, @srecommend, 0, 0, 0, '')
				if @@Error <> 0
				BEGIN
					select @ErrCode = 103						
					delete bettrans where refno = @refno and matchid = 0
					return
				END
				INSERT INTO bettrans
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status,statusID, ruben, winlostdate, currency, actualrate, currencyName, 
					mrecommend, srecommend, scomm, swinlost, recommend, ip)
				VALUES 
				   (0, @UserID, @mrecommend, @mastername, @refno, @Now, 21003, 'For Delete Account - To Customer::'+@supername, 0, @masterBalance,
					'Completed',131, 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					@mrecommend, @srecommend, 0, 0, 0, '')
				if @@Error <> 0
				BEGIN
					select @ErrCode = 104						
					delete bettrans where refno = @refno and matchid = 0
					return
				END
			
			END
			ELSE if @masterBalance<0
			BEGIN
				SET @masterBalance = abs(@masterBalance)
			
				INSERT INTO bettrans 
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status,statusID, ruben, winlostdate, currency, actualrate, currencyName,
					mrecommend, srecommend, scomm, swinlost, recommend, ip)
				VALUES 
				   (0, @UserID, @srecommend, @supername, @refno, @Now, 21003, 'For Delete Account - To Customer::'+@mastername, 0, @masterBalance,
					'Completed',131, 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					0, @srecommend, 0, 0, 0, '')
				if @@Error <> 0
				BEGIN
					select @ErrCode = 105						
					delete bettrans where refno = @refno and matchid = 0
					return
				END
				INSERT INTO bettrans
				   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					status,statusID, ruben, winlostdate, currency, actualrate, currencyName, 
					mrecommend, srecommend, scomm, swinlost, recommend, ip)
				VALUES 
				   (0, @UserID, @mrecommend, @mastername, @refno, CURRENT_TIMESTAMP, 21003, 'For Delete Account - From Customer::'+@supername, @masterBalance, 0,
					'Completed',131, 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
					@mrecommend, @srecommend, 0, 0, 0, '')
				if @@Error <> 0
				BEGIN
					select @ErrCode = 106						
					delete bettrans where refno = @refno and matchid = 0
					return
				END				
				
			END		
			
		FETCH NEXT FROM CS_master INTO @mrecommend, @srecommend, @currency, @actualrate, @currencyName,
									   @mastername, @supername, @masterBalance
	END

	CLOSE CS_master
	DEALLOCATE CS_master
	DROP TABLE #Master
END
	--------------------------END:MASTER-SUPER-------------------------------
print @AccName +':'+ 'Master Cursor Done:' + convert(varchar(50), getdate(), 113)
DROP TABLE #Member


GO
GRANT VIEW DEFINITION ON [dbo].[DBA_ArchiveAccount_ClearBalance_All] TO [vnteam]