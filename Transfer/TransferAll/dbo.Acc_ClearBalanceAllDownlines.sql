/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet,bodbExtAccNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ClearBalanceAllDownlines]
	@AgentName varchar(50),	-- S99BD
	@UserID int = 8,
	@IP nvarchar(15)='', 
	@IsJob BIT = 0,
	@ErrMsg nvarchar(4000) = '' OUTPUT,
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
		- 20131108@Elodie: Splitting bodb02 into CustDB (Call CustInfo, Exchange by link database) 	
		- 20140826@Lukas: use maxdop hint to avoid parallelism operators -> reduce CPU usage  
		- 20150723@Patrick: Support Gold deluxe & override code from production with 20140826@Lukas version 
		- 20150808@Elodie: Balance Improvement [Redmine:#40125]	
		- 20151021@Elodie: Set @IsForce = 1 for updating balance debit [Redmine:#40125]
		- 20150126@Elodie: Include to get balance from bettransRNG + bettransLC [Redmine:#50674]
		- 20160722@Viet: Improve performance [Redmine:#58288]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20200602@Percy: Separate PendingTransfer3rd from Cash and Balance [RedmineID: #135200]
		- 20200730@Sophia: prevent duplicated transfer [Redmine: #137141]
		- 20200730@Sophia: Check UM Transfer Function [Redmine: #136992]
		- 20201006@sophia: Comment SP Server_IsHeavyLoadPermitted due to cannot transfer [Redmine: #136992]
		- 20201217@Sol: Optimize - mofidied code to get index seek on IX_ProductID_Issum_StatuaID [RedmineID: #147335]
		 				       
	Param's Explanation:
		@AgentName: username of agent/master/super to clear his all downlines' balance
*/ 
BEGIN
	SET NOCOUNT ON

	------ 20121109@Viet: do not allow this SP to run once cpu is high --------  
	DECLARE @ispermit BIT

	---EXEC dbo.Server_IsHeavyLoadPermitted @ispermit OUTPUT

	IF @ispermit = 0
	BEGIN
		SELECT @errcode = 1, @errmsg = 'oops! Server is too busy, please try again later!'
		RETURN
	END

	------ /20121109@Viet: do not allow this SP to run once cpu is high --------  
	--Check permission  
	DECLARE @ErrMsg_temp NVARCHAR(4000)

	-- must use temporary variable for @ErrMsg because of nvarchar(max) is not allowed in remote call  
	EXEC DBPOL.NAP_UserControl.dbo.Acc_Con_CheckPermission @custid = @UserID, @funcname = '[OtherTrans]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg_temp OUTPUT

	SELECT @ErrMsg = @ErrMsg_temp

	IF @ErrCode <> 0 RETURN

	DECLARE @roleid INT, @AgentID INT, @Amount MONEY, @custid INT, @recommend INT, @mrecommend INT, @srecommend INT, @currency INT, @actualrate FLOAT, @currencyName NVARCHAR(10), @membername VARCHAR(50), @agentusername VARCHAR(50), @mastername VARCHAR(50), @supername VARCHAR(50), @memberBalance MONEY, @agentBalance MONEY, @masterBalance MONEY, @ABSmemberBalance MONEY
	DECLARE @LogData VARCHAR(1000)
	DECLARE @refno BIGINT, @grefno INT, @Now DATETIME
	DECLARE @ErrItems NVARCHAR(max), @SkipTransfer BIT, @isSucc VARCHAR(10)

	SELECT @isSucc = 'false', @ErrItems = ''

	DECLARE @count INT, @batch INT

	SELECT @batch = 500, @count = 0

	DECLARE @WinlostDate DATETIME

	SELECT @WinlostDate = convert(NVARCHAR(10), current_timestamp, 120)

	SELECT @roleid = roleid, @AgentID = custid, @AgentName = username
	FROM CustDB.dbo.Custinfo(NOLOCK)
	WHERE username = @AgentName

	IF isnull(@AgentID, 0) = 0
		OR @roleid NOT IN (2, 3, 4)
	BEGIN
		SELECT @ErrMsg = @AgentName + ':' + 'Invalid Agent Username', @ErrCode = 101

		RETURN
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
	

	/*--20091017@Thien: not check this function so that upline can get back the used credit  
	--Check disable user  
	EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @AgentID, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output  
	if @ErrCode <>0 return  
	*/
	--==========================================================  
	--CREATING TEMP TABLES  
	--==========================================================  
	DECLARE @agList as table (custid int primary key, username varchar(50))
	CREATE TABLE #tempdata (custid int, recommend int, mrecommend int, winlost money, actual_stake money, playercomm money, awinlost money, comm money, mwinlost money, acomm money)

	DECLARE @tblSportTypeRNG AS TABLE (SportType SMALLINT)
	DECLARE @tblSportTypeLC AS TABLE (SportType SMALLINT)

	INSERT INTO @tblSportTypeRNG(SportType)
	SELECT DISTINCT SportType FROM SportBettypeMatrix WITH(NOLOCK) WHERE RefTable = 1

	INSERT INTO @tblSportTypeLC(SportType)
	SELECT DISTINCT SportType FROM SportBettypeMatrix WITH(NOLOCK) WHERE RefTable = 2
	
	IF @roleid = 2
	BEGIN
		INSERT INTO @agList(custid, username) values(@AgentID, @AgentName)
	END
	
	IF @roleid = 3
	BEGIN
		INSERT INTO @agList (custid, username)
		SELECT custid, username
		FROM CustDB.dbo.custInfo WITH(NOLOCK)
		WHERE mrecommend = @AgentID
			AND roleid = 2
	END
	
	IF @roleid = 4
	BEGIN
		INSERT INTO @agList (custid, username)
		SELECT custid, username
		FROM CustDB.dbo.custInfo WITH(NOLOCK)
		WHERE srecommend = @AgentID
			AND roleid = 2
			
		DECLARE @masterlist AS TABLE (custid INT)
		INSERT INTO @masterlist (custid)
		SELECT custid
		FROM custdb.dbo.custinfo WITH (NOLOCK)
		WHERE srecommend = @agentID
			AND roleid = 3
			
		-- master data		
		INSERT INTO #tempdata (custid, recommend, mrecommend, winlost, actual_stake, playercomm, awinlost, comm, mwinlost, acomm)
		SELECT b.custid, b.recommend, b.mrecommend
			,SUM(winlost) winlost
			,SUM(actual_stake) actual_stake
			,SUM(playercomm) playercomm
			,SUM(awinlost) awinlost
			,SUM(comm) comm
			,SUM(mwinlost) mwinlost
			,SUM(acomm) acomm
		FROM @masterlist c
			INNER JOIN dbo.bettrans b WITH(NOLOCK) ON c.custid = b.custid
		WHERE (winlostdate < @winlostdate OR (winlostdate >= @winlostdate AND bettype > 20000))
			AND ruben = 1
			AND bettype NOT IN (21008, 21009)
		GROUP BY b.custid, b.recommend, b.mrecommend
		
		INSERT INTO #tempdata (custid, recommend, mrecommend, winlost, actual_stake, playercomm, awinlost, comm, mwinlost, acomm)
		SELECT b.custid, b.recommend, b.mrecommend
			,SUM(winlost) winlost
			,SUM(actual_stake) actual_stake
			,SUM(playercomm) playercomm
			,SUM(awinlost) awinlost
			,SUM(comm) comm
			,SUM(mwinlost) mwinlost
			,SUM(acomm) acomm
		FROM @masterlist c
			INNER JOIN dbo.bettransRnG b WITH(NOLOCK) ON c.custid = b.custid
		WHERE 
			b.productID IN (SELECT SportType FROM @tblSportTypeRNG)
			AND IsSum = 0
			AND statusID NOT IN (0,1)
			AND winlostdate < @winlostdate
		GROUP BY b.custid, b.recommend, b.mrecommend
		
		INSERT INTO #tempdata (custid, recommend, mrecommend, winlost, actual_stake, playercomm, awinlost, comm, mwinlost, acomm)
		SELECT b.custid, b.recommend, b.mrecommend
			,SUM(winlost) winlost
			,SUM(actual_stake) actual_stake
			,SUM(playercomm) playercomm
			,SUM(awinlost) awinlost
			,SUM(comm) comm
			,SUM(mwinlost) mwinlost
			,SUM(acomm) acomm
		FROM @masterlist c
			INNER JOIN dbo.bettransLC b WITH(NOLOCK) ON c.custid = b.custid
		WHERE b.productID IN (SELECT SportType FROM @tblSportTypeLC)
			AND IsSum = 0
			AND statusID NOT IN (0,1)
			AND winlostdate < @winlostdate
		GROUP BY b.custid, b.recommend, b.mrecommend
	END
		
	-- member & agent data	
	INSERT INTO #tempdata (custid, recommend, mrecommend, winlost, actual_stake, playercomm, awinlost, comm, mwinlost, acomm)
	SELECT b.custid, b.recommend, b.mrecommend	
		,SUM(winlost) winlost
		,SUM(actual_stake) actual_stake
		,SUM(playercomm) playercomm
		,SUM(awinlost) awinlost
		,SUM(comm) comm
		,SUM(mwinlost) mwinlost
		,SUM(acomm) acomm
	FROM @agList ag
		INNER JOIN dbo.bettrans b WITH(NOLOCK, INDEX=IX_Recommend) ON ag.custid = b.recommend
	WHERE (winlostdate < @winlostdate OR (winlostdate >= @winlostdate AND bettype > 20000))
		AND ruben = 1
		AND bettype NOT IN (21008, 21009)
	GROUP BY b.custid, b.recommend, b.mrecommend

	INSERT INTO #tempdata (custid, recommend, mrecommend, winlost, actual_stake, playercomm, awinlost, comm, mwinlost, acomm)
	SELECT b.custid, b.recommend, b.mrecommend	
		,SUM(winlost) winlost
		,SUM(actual_stake) actual_stake
		,SUM(playercomm) playercomm
		,SUM(awinlost) awinlost
		,SUM(comm) comm
		,SUM(mwinlost) mwinlost
		,SUM(acomm) acomm
	FROM @agList ag
		INNER JOIN dbo.bettransRnG b WITH(NOLOCK) ON ag.custid = b.recommend
	WHERE b.productID IN (SELECT SportType FROM @tblSportTypeRNG)
		AND IsSum = 0
		AND statusID NOT IN (0,1)
		AND winlostdate < @winlostdate
	GROUP BY b.custid, b.recommend, b.mrecommend
		
	INSERT INTO #tempdata (custid, recommend, mrecommend, winlost, actual_stake, playercomm, awinlost, comm, mwinlost, acomm)
	SELECT b.custid, b.recommend, b.mrecommend	
		,SUM(winlost) winlost
		,SUM(actual_stake) actual_stake
		,SUM(playercomm) playercomm
		,SUM(awinlost) awinlost
		,SUM(comm) comm
		,SUM(mwinlost) mwinlost
		,SUM(acomm) acomm
	FROM @agList ag
		INNER JOIN dbo.bettransLC b WITH(NOLOCK) ON ag.custid = b.recommend
	WHERE b.productID IN (SELECT SportType FROM @tblSportTypeLC)
		AND IsSum = 0
		AND statusID NOT IN (0,1)
		AND winlostdate < @winlostdate
	GROUP BY b.custid, b.recommend, b.mrecommend
		
	CREATE TABLE #Member (custid INT PRIMARY KEY, recommend INT, mrecommend INT, srecommend INT, currency INT, actualrate FLOAT, currencyName NVARCHAR(10), membername VARCHAR(50), agentname VARCHAR(50), memberBalance MONEY DEFAULT 0)
	CREATE TABLE #SkippedMember (custid INT PRIMARY KEY, recommend INT, mrecommend INT, srecommend INT)
	CREATE TABLE #Agent (recommend INT PRIMARY KEY, mrecommend INT, srecommend INT, currency INT, actualrate FLOAT, currencyName NVARCHAR(10), agentname VARCHAR(50), mastername VARCHAR(50), agentBalance MONEY DEFAULT 0)
	CREATE TABLE #Master (mrecommend INT PRIMARY KEY, srecommend INT, currency INT, actualrate FLOAT, currencyName NVARCHAR(10), mastername VARCHAR(50), supername VARCHAR(50), masterBalance MONEY DEFAULT 0)

	;WITH b AS (
		select custid, SUM(isnull(winlost-actual_stake+playercomm, 0)) as memberBalance
		FROM #tempdata
		WHERE custid <> recommend AND custid <> mrecommend		
		group by custid
		having SUM(isnull(winlost-actual_stake+playercomm, 0)) <> 0		
	)
	INSERT INTO #Member (custid, recommend, mrecommend, srecommend, currency, actualrate, currencyName, membername, agentname, memberBalance)
	SELECT c.custid, c.recommend, c.mrecommend, c.srecommend, c.currency, e.actualrate, e.currency, c.username, ag.username, isnull(b.memberBalance, 0)
	FROM b
		INNER JOIN CustDB.dbo.Custinfo c WITH (NOLOCK) ON b.custid = c.custid
		INNER JOIN @agList ag ON c.recommend = ag.custid
		INNER JOIN CustDB.dbo.Exchange e WITH (NOLOCK) ON c.currency = e.exchangeid
	WHERE c.roleid = 1
			 
	IF @roleid IN (3,4)
	BEGIN	
		;WITH b AS (
			SELECT recommend, sum(awinlost + comm + winlost - actual_stake)	AS agentBalance	
			FROM #tempdata
			GROUP BY recommend
			having sum(awinlost + comm + winlost - actual_stake) <> 0
		)
		
		INSERT INTO #Agent (recommend, mrecommend, srecommend, currency, actualrate, currencyName, agentname, mastername, agentBalance)
		SELECT c.recommend, c.mrecommend, c.srecommend, c.currency, e.actualrate, e.currency, c.username, mag.username, isnull(b.agentBalance, 0)
		FROM b
			INNER JOIN CustDB.dbo.Custinfo c WITH(NOLOCK) ON b.recommend = c.custid
			INNER JOIN CustDB.dbo.Custinfo mag WITH(NOLOCK) ON c.mrecommend = mag.custid
			INNER JOIN CustDB.dbo.Exchange e WITH(NOLOCK) ON c.currency = e.exchangeid 
		WHERE c.roleid = 2		
	END

	IF @roleid = 4
	BEGIN
		;WITH b AS (
			SELECT mrecommend, sum(winlost - actual_stake + mwinlost + acomm + awinlost) as masterBalance		
			FROM #tempdata b
			GROUP BY mrecommend
			having sum(winlost - actual_stake + mwinlost + acomm + awinlost) <> 0
		)

		INSERT INTO #Master (mrecommend, srecommend, currency, actualrate, currencyName, mastername, supername, masterBalance)
		SELECT c.mrecommend, c.srecommend, c.currency, e.actualrate, e.currency, c.username, @AgentName, isnull(b.masterBalance, 0)
		FROM b
			INNER JOIN CustDB.dbo.Custinfo c WITH(NOLOCK) on b.mrecommend = c.custid
			INNER JOIN CustDB.dbo.Exchange e WITH(NOLOCK) ON c.currency = e.exchangeid 			
		WHERE c.roleid = 3		
	END;	

	-- Start Transfer (CURSOR Loop)   
	SET @Now = CURRENT_TIMESTAMP

	--------------------------START:MEMBER-AGENT-------------------------------  
	DECLARE CS_custid CURSOR
	FOR
	SELECT custid, recommend, mrecommend, srecommend, currency, actualrate, currencyName, membername, agentname, memberBalance
	FROM #Member

	OPEN CS_custid

	FETCH NEXT
	FROM CS_custid
	INTO @custid, @recommend, @mrecommend, @srecommend, @currency, @actualrate, @currencyName, @membername, @agentusername, @memberBalance


		
	WHILE @@FETCH_STATUS = 0
	BEGIN		
		
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
	
	
		-- print @agentusername +':'+ 'MEMBER-AGENT-->Member:' + @membername + ' ' + cast(@memberBalance as varchar(30))  
		UPDATE ref WITH (ROWLOCK, UPDLOCK)
		SET @grefno = transcode = transcode + 1
		WHERE refid = 'acc'

		IF @@Error <> 0
		BEGIN
			SELECT @ErrMsg = 'Insert Failed', @ErrCode = 114

			RETURN
		END

		SELECT @refno = 200000000000 + @grefno

		SELECT @SkipTransfer = 0

		--Check for existing transfer (allow only one transfer per day) - Tho@09062008    
		IF (
				EXISTS (
					SELECT 1
					FROM bettrans WITH (NOLOCK)
					WHERE custid = @custid
						AND bettype IN (21003, 21004)
						AND (
							transdate BETWEEN convert(VARCHAR(10), current_timestamp, 120)
								AND convert(VARCHAR(10), current_timestamp, 120) + ' 23:59:59'
							)
						AND liveindicator = 0
					)
				)
		BEGIN
			SELECT @SkipTransfer = 1

			SELECT @ErrItems = @ErrItems + @membername + ', '

			INSERT #SkippedMember (custid, recommend, mrecommend, srecommend)
			SELECT @custid, @recommend, @mrecommend, @srecommend
		END

		IF (
				@memberBalance > 0
				AND @SkipTransfer = 0
				)
		BEGIN
			INSERT INTO bettrans (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, STATUS, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, scomm, swinlost, ip, statusID)
			VALUES (0, @UserID, @recommend, @agentusername, @refno, @Now, 21004, 'From Customer::' + @membername, @memberBalance, 0, 'Completed', 1, convert(NVARCHAR(10), @Now, 120), @currency, @actualrate, @currencyName, @recommend, @MRecommend, @srecommend, 0, 0, @IP, 131)

			IF @@Error <> 0
			BEGIN
				SELECT @ErrMsg = 'Insert Failed', @ErrCode = 101

				DELETE dbo.bettrans
				WHERE custid IN (@recommend, @custid)
					AND matchid = 0
					AND bettype IN (21003, 21004)
					AND refno = @refno

				RETURN
			END

			---update debit balance  
			--EXEC Dot_BalanceUpdDebit @CustID = @CustID, @balance = @memberBalance
					EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @memberBalance, @Type = 2, @IsForced = 1, @ErrCode = @ErrCode OUTPUT
			IF @ErrCode <> 0
			BEGIN
				SELECT @ErrMsg = 'Insert Failed', @ErrCode = 102

				DELETE dbo.bettrans
				WHERE custid IN (@recommend, @custid)
					AND matchid = 0
					AND bettype IN (21003, 21004)
					AND refno = @refno

				RETURN
			END

			INSERT INTO bettrans (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, STATUS, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, scomm, swinlost, ip, statusID)
			VALUES (0, @UserID, @custid, @membername, @refno, @Now, 21004, 'To Customer::' + @agentusername, 0, @memberBalance, 'Completed', 1, convert(NVARCHAR(10), @Now, 120), @currency, @actualrate, @currencyName, @recommend, @MRecommend, @srecommend, 0, 0, @IP, 131)

			IF @@Error <> 0
			BEGIN
				SELECT @ErrMsg = 'Insert Failed', @ErrCode = 102

				DELETE dbo.bettrans
				WHERE custid IN (@recommend, @custid)
					AND matchid = 0
					AND bettype IN (21003, 21004)
					AND refno = @refno

				--rollback balance  
				--EXEC Dot_BalanceUpdCredit @CustID = @CustID, @balance = @memberBalance
				EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @memberBalance, @Type = 2
				RETURN
			END

			SELECT @LogData = 'Transfer (clear balance) all downlines: Transfer from Member ' + @membername + ' to Agent ' + @agentusername + ' with amount ' + convert(VARCHAR(20), @memberBalance) + ' Ref.No ' + convert(VARCHAR(20), @refno)

			DECLARE @isResetYesterdayBalance BIT, @ErrCode_ResetYesterdayBalance BIT, @YesterdayBalance MONEY

			-- reset yesterday balance for live casino         
			EXEC Acc_BalanceGameResetYesterday @CustID = @CustID, @isResetYesterdayBalance = @isResetYesterdayBalance OUTPUT, @YesterdayBalance = @YesterdayBalance OUTPUT, @ErrCode = @ErrCode_ResetYesterdayBalance OUTPUT

			SELECT @LogData = @LogData + CASE 
					WHEN @isResetYesterdayBalance = 1 THEN CASE 
							WHEN @ErrCode_ResetYesterdayBalance = 0 THEN '. (ResetBalanceGame = suscess, YesterdayBalance =' + CAST(@YesterdayBalance AS VARCHAR(50)) + ')'
							ELSE '. (ResetBalanceGame = fail)'
							END
					ELSE ''
					END

			SET @isSucc = 'true'

			BEGIN TRY
				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @custid, @ToCustID = @recommend, @IP = @IP, @Doing = @LogData
			END TRY

			BEGIN CATCH
				SELECT @LogData = @LogData + ' ErrMsg=' + error_message()

				EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @custid, @ToCustID = @recommend, @IP = @IP, @Doing = @LogData
			END CATCH

			SET @count = @count + 1

			IF @count % @batch = 0
				WAITFOR DELAY '000:00:00.280'
		END
		ELSE IF (
				@memberBalance < 0
				AND @SkipTransfer = 0
				)
		BEGIN
			--SET @memberBalance = abs(@memberBalance)      
			INSERT INTO bettrans (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, STATUS, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, scomm, swinlost, ip, statusID)
			VALUES (0, @UserID, @recommend, @agentusername, @refno, CURRENT_TIMESTAMP, 21004, 'To Customer::' + @membername, 0, abs(@memberBalance), 'Completed', 1, convert(NVARCHAR(10), @Now, 120), @currency, @actualrate, @currencyName, @recommend, @MRecommend, @srecommend, 0, 0, @IP, 131)

			IF @@Error <> 0
			BEGIN
				SELECT @ErrMsg = 'Insert Failed', @ErrCode = 103

				DELETE dbo.bettrans
				WHERE custid IN (@recommend, @custid)
					AND matchid = 0
					AND bettype IN (21003, 21004)
					AND refno = @refno

				RETURN
			END

			INSERT INTO bettrans (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, STATUS, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, scomm, swinlost, ip, statusID)
			VALUES (0, @UserID, @custid, @membername, @refno, CURRENT_TIMESTAMP, 21004, 'From Customer::' + @agentusername, abs(@memberBalance), 0, 'Completed', 1, convert(NVARCHAR(10), @Now, 120), @currency, @actualrate, @currencyName, @recommend, @MRecommend, @srecommend, 0, 0, @IP, 131)

			IF @@Error <> 0
			BEGIN
				SELECT @ErrMsg = 'Insert Failed', @ErrCode = 104

				DELETE dbo.bettrans
				WHERE custid IN (@recommend, @custid)
					AND matchid = 0
					AND bettype IN (21003, 21004)
					AND refno = @refno

				RETURN
			END

			---update credit balance  
			SELECT @ABSmemberBalance = abs(@memberBalance)

			--EXEC Dot_BalanceUpdCredit @CustID = @CustID, @balance = @ABSmemberBalance
			EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @ABSmemberBalance, @Type = 2

			SELECT @LogData = 'Transfer (clear balance) all downlines: Transfer from Agent ' + @agentusername + ' to Member ' + @membername + ' with amount ' + convert(VARCHAR(20), @memberBalance) + ' Ref.No ' + convert(VARCHAR(20), @refno)

			-- reset yesterday balance for live casino         
									EXEC Acc_BalanceGameResetYesterday @CustID = @CustID, @isResetYesterdayBalance = @isResetYesterdayBalance OUTPUT, @YesterdayBalance = @YesterdayBalance OUTPUT, @ErrCode = @ErrCode_ResetYesterdayBalance OUTPUT

			SELECT @LogData = @LogData + CASE 
					WHEN @isResetYesterdayBalance = 1 THEN CASE 
							WHEN @ErrCode_ResetYesterdayBalance = 0 THEN '. (ResetBalanceGame = suscess, YesterdayBalance =' + CAST(@YesterdayBalance AS VARCHAR(50)) + ')'
							ELSE '. (ResetBalanceGame = fail)'
							END
					ELSE ''
					END

			SET @isSucc = 'true'

			BEGIN TRY
				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @recommend, @ToCustID = @custid, @IP = @IP, @Doing = @LogData
			END TRY

			BEGIN CATCH
				SELECT @LogData = @LogData + ' ErrMsg=' + error_message()

				EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @recommend, @ToCustID = @custid, @IP = @IP, @Doing = @LogData
			END CATCH

			SET @count = @count + 1

			IF @count % @batch = 0
				WAITFOR DELAY '000:00:00.280'
		END

		FETCH NEXT
		FROM CS_custid
		INTO @custid, @recommend, @mrecommend, @srecommend, @currency, @actualrate, @currencyName, @membername, @agentusername, @memberBalance
	END

	CLOSE CS_custid

	DEALLOCATE CS_custid

	-- skip master, agent of skipped member  
	IF @ErrItems <> ''
	BEGIN
		DELETE #Agent
		WHERE #Agent.recommend IN (
				SELECT recommend
				FROM #SkippedMember
				)

		DELETE #Master
		WHERE #Master.mrecommend IN (
				SELECT mrecommend
				FROM #SkippedMember
				)
	END

	--------------------------END:MEMBER-AGENT-------------------------------   
	--------------------------START:AGENT-MASTER-------------------------------   
	IF (@roleid > 2)
	BEGIN		
		DECLARE CS_agent CURSOR
		FOR
		SELECT recommend, mrecommend, srecommend, currency, actualrate, currencyName, agentname, mastername, agentBalance
		FROM #Agent

		OPEN CS_agent

		FETCH NEXT
		FROM CS_agent
		INTO @recommend, @mrecommend, @srecommend, @currency, @actualrate, @currencyName, @agentusername, @mastername, @agentBalance

		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			---- #2 CHECK FLAG ISTRANSFERRING = 1 THEN RAISE ERROR, IF THIS SP IS CALLED BY JOB THEN NO NEED TO CHECK
			IF @IsJob = 0
			BEGIN 
				EXEC DBCUST.CustDB.dbo.Acc_Transfer_CheckRunningByCust  
					@CustID = @mrecommend
					,@ErrMsg = @ErrMsg OUTPUT 
					,@ErrCode = @ErrCode OUTPUT
					 
				IF @ErrCode <> 0  -- the auto transfer job is running this custid
				BEGIN
					RETURN		
				END
			END		
		
			-- print @agentusername +':'+ 'AGENT-MASTER-->Agent:' + @agentusername+ ' ' + cast(@agentBalance as varchar(30))  
			UPDATE ref WITH (ROWLOCK, UPDLOCK)
			SET @grefno = transcode = transcode + 1
			WHERE refid = 'acc'

			IF @@Error <> 0
			BEGIN
				SELECT @ErrMsg = 'Insert Failed', @ErrCode = 115

				RETURN
			END

			SELECT @refno = 200000000000 + @grefno

			IF @agentBalance > 0
			BEGIN
				INSERT INTO bettrans (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, STATUS, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, scomm, swinlost, ip, statusID)
				VALUES (0, @UserID, @mrecommend, @mastername, @refno, @Now, 21003, 'From Customer::' + @agentusername, @agentBalance, 0, 'Completed', 1, convert(NVARCHAR(10), @Now, 120), @currency, @actualrate, @currencyName, 0, @mrecommend, @srecommend, 0, 0, @IP, 131)

				IF @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 105

					DELETE dbo.bettrans
					WHERE custid IN (@mrecommend, @recommend)
						AND matchid = 0
						AND bettype IN (21003, 21004)
						AND refno = @refno

					RETURN
				END

				INSERT INTO bettrans (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, STATUS, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, scomm, swinlost, ip, statusID)
				VALUES (0, @UserID, @recommend, @agentusername, @refno, @Now, 21003, 'To Customer::' + @mastername, 0, @agentBalance, 'Completed', 1, convert(NVARCHAR(10), @Now, 120), @currency, @actualrate, @currencyName, @recommend, @mrecommend, @srecommend, 0, 0, @IP, 131)

				IF @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 106

					DELETE dbo.bettrans
					WHERE custid IN (@mrecommend, @recommend)
						AND matchid = 0
						AND bettype IN (21003, 21004)
						AND refno = @refno

					RETURN
				END

				SET @isSucc = 'true'

				SELECT @LogData = 'Transfer (clear balance) all downlines: Transfer from agent ' + @agentusername + ' to Master ' + @mastername + ' with amount ' + convert(VARCHAR(20), @agentBalance) + ' Ref.No ' + convert(VARCHAR(20), @refno)

				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @recommend, @ToCustID = @mrecommend, @IP = @IP, @Doing = @LogData
				END TRY

				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + error_message()

					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @recommend, @ToCustID = @mrecommend, @IP = @IP, @Doing = @LogData
				END CATCH

				SET @count = @count + 1

				IF @count % @batch = 0
					WAITFOR DELAY '000:00:00.280'
			END
			ELSE IF @agentBalance < 0
			BEGIN
				--SET @agentBalance = abs(@agentBalance)  
				INSERT INTO bettrans (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, STATUS, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, scomm, swinlost, ip, statusID)
				VALUES (0, @UserID, @mrecommend, @mastername, @refno, @Now, 21003, 'To Customer::' + @agentusername, 0, abs(@agentBalance), 'Completed', 1, convert(NVARCHAR(10), @Now, 120), @currency, @actualrate, @currencyName, 0, @mrecommend, @srecommend, 0, 0, @IP, 131)

				IF @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 107

					DELETE dbo.bettrans
					WHERE custid IN (@mrecommend, @recommend)
						AND matchid = 0
						AND bettype IN (21003, 21004)
						AND refno = @refno

					RETURN
				END

				INSERT INTO bettrans (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, STATUS, ruben, winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, scomm, swinlost, ip, statusID)
				VALUES (0, @UserID, @recommend, @agentusername, @refno, @Now, 21003, 'From Customer::' + @mastername, abs(@agentBalance), 0, 'Completed', 1, convert(NVARCHAR(10), @Now, 120), @currency, @actualrate, @currencyName, @recommend, @mrecommend, @srecommend, 0, 0, @IP, 131)

				IF @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 108

					DELETE dbo.bettrans
					WHERE custid IN (@mrecommend, @recommend)
						AND matchid = 0
						AND bettype IN (21003, 21004)
						AND refno = @refno

					RETURN
				END

				SET @isSucc = 'true'

				SELECT @LogData = 'Transfer (clear balance) all downlines: Transfer from Master ' + @mastername + ' to Agent ' + @agentusername + ' with amount ' + convert(VARCHAR(20), @agentBalance) + ' Ref.No ' + convert(VARCHAR(20), @refno)

				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @mrecommend, @ToCustID = @recommend, @IP = @IP, @Doing = @LogData
				END TRY

				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + error_message()

					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @mrecommend, @ToCustID = @recommend, @IP = @IP, @Doing = @LogData
				END CATCH

				SET @count = @count + 1

				IF @count % @batch = 0
					WAITFOR DELAY '000:00:00.280'
			END

			FETCH NEXT
			FROM CS_agent
			INTO @recommend, @mrecommend, @srecommend, @currency, @actualrate, @currencyName, @agentusername, @mastername, @agentBalance
		END

		CLOSE CS_agent

		DEALLOCATE CS_agent

		DROP TABLE #Agent
			--------------------------END:AGENT-MASTER-------------------------------  
	END

	--------------------------START:MASTER-SUPER-------------------------------  
	IF @RoleID = 4
	BEGIN		
		DECLARE CS_master CURSOR
		FOR
		SELECT mrecommend, srecommend, currency, actualrate, currencyName, mastername, supername, masterBalance
		FROM #Master

		OPEN CS_master

		FETCH NEXT
		FROM CS_master
		INTO @mrecommend, @srecommend, @currency, @actualrate, @currencyName, @mastername, @supername, @masterBalance

		WHILE @@FETCH_STATUS = 0
		BEGIN
			---- #2 CHECK FLAG ISTRANSFERRING = 1 THEN RAISE ERROR, IF THIS SP IS CALLED BY JOB THEN NO NEED TO CHECK
			IF @IsJob = 0
			BEGIN 
				EXEC DBCUST.CustDB.dbo.Acc_Transfer_CheckRunningByCust  
					@CustID = @srecommend
					,@ErrMsg = @ErrMsg OUTPUT 
					,@ErrCode = @ErrCode OUTPUT
					 
				IF @ErrCode <> 0  -- the auto transfer job is running this custid
				BEGIN
					RETURN		
				END
			END		
			
			-- print @agentusername +':'+ 'MASTER-SUPER-->Master:' + @mastername+ ' ' + cast(@masterBalance as varchar(30))  
			UPDATE ref WITH (ROWLOCK, UPDLOCK)
			SET @grefno = transcode = transcode + 1
			WHERE refid = 'acc'

			IF @@Error <> 0
			BEGIN
				SELECT @ErrMsg = 'Insert Failed', @ErrCode = 116

				RETURN
			END

			SELECT @refno = 200000000000 + @grefno

			IF @masterBalance > 0
			BEGIN
				INSERT INTO bettrans (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, STATUS, ruben, winlostdate, currency, actualrate, currencyName, mrecommend, srecommend, scomm, swinlost, recommend, ip, statusID)
				VALUES (0, @UserID, @srecommend, @supername, @refno, @Now, 21003, 'From Customer::' + @mastername, @masterBalance, 0, 'Completed', 1, convert(NVARCHAR(10), @Now, 120), @currency, @actualrate, @currencyName, 0, @srecommend, 0, 0, 0, @ip, 131)

				IF @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 109

					DELETE dbo.bettrans
					WHERE custid IN (@srecommend, @mrecommend)
						AND matchid = 0
						AND bettype IN (21003, 21004)
						AND refno = @refno

					RETURN
				END

				INSERT INTO bettrans (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, STATUS, ruben, winlostdate, currency, actualrate, currencyName, mrecommend, srecommend, scomm, swinlost, recommend, ip, statusID)
				VALUES (0, @UserID, @mrecommend, @mastername, @refno, @Now, 21003, 'To Customer::' + @supername, 0, @masterBalance, 'Completed', 1, convert(NVARCHAR(10), @Now, 120), @currency, @actualrate, @currencyName, @mrecommend, @srecommend, 0, 0, 0, @ip, 131)

				IF @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 110

					DELETE dbo.bettrans
					WHERE custid IN (@srecommend, @mrecommend)
						AND matchid = 0
						AND bettype IN (21003, 21004)
						AND refno = @refno

					RETURN
				END

				SET @isSucc = 'true'

				SELECT @LogData = 'Transfer (clear balance) all downlines: Transfer from Master ' + @mastername + ' to Super ' + @supername + ' with amount ' + convert(VARCHAR(20), @masterBalance) + ' Ref.No ' + convert(VARCHAR(20), @refno)

				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @mrecommend, @ToCustID = @srecommend, @IP = @IP, @Doing = @LogData
				END TRY

				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + error_message()

					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @mrecommend, @ToCustID = @srecommend, @IP = @IP, @Doing = @LogData
				END CATCH

				SET @count = @count + 1

				IF @count % @batch = 0
					WAITFOR DELAY '000:00:00.280'
			END
			ELSE IF @masterBalance < 0
			BEGIN
				--SET @masterBalance = abs(@masterBalance)  
				INSERT INTO bettrans (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, STATUS, ruben, winlostdate, currency, actualrate, currencyName, mrecommend, srecommend, scomm, swinlost, recommend, ip, statusID)
				VALUES (0, @UserID, @srecommend, @supername, @refno, @Now, 21003, 'To Customer::' + @mastername, 0, abs(@masterBalance), 'Completed', 1, convert(NVARCHAR(10), @Now, 120), @currency, @actualrate, @currencyName, 0, @srecommend, 0, 0, 0, @ip, 131)

				IF @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 111

					DELETE dbo.bettrans
					WHERE custid IN (@srecommend, @mrecommend)
						AND matchid = 0
						AND bettype IN (21003, 21004)
						AND refno = @refno

					RETURN
				END

				INSERT INTO bettrans (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, STATUS, ruben, winlostdate, currency, actualrate, currencyName, mrecommend, srecommend, scomm, swinlost, recommend, ip, statusID)
				VALUES (0, @UserID, @mrecommend, @mastername, @refno, CURRENT_TIMESTAMP, 21003, 'From Customer::' + @supername, abs(@masterBalance), 0, 'Completed', 1, convert(NVARCHAR(10), @Now, 120), @currency, @actualrate, @currencyName, @mrecommend, @srecommend, 0, 0, 0, @ip, 131)

				IF @@Error <> 0
				BEGIN
					SELECT @ErrMsg = 'Insert Failed', @ErrCode = 112

					DELETE dbo.bettrans
					WHERE custid IN (@srecommend, @mrecommend)
						AND matchid = 0
						AND bettype IN (21003, 21004)
						AND refno = @refno

					RETURN
				END

				SET @isSucc = 'true'

				SELECT @LogData = 'Transfer (clear balance) all downlines: Transfer from Super ' + @supername + ' to Master ' + @mastername + ' with amount ' + convert(VARCHAR(20), @masterBalance) + ' Ref.No ' + convert(VARCHAR(20), @refno)

				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @srecommend, @ToCustID = @mrecommend, @IP = @IP, @Doing = @LogData
				END TRY

				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + error_message()

					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @srecommend, @ToCustID = @mrecommend, @IP = @IP, @Doing = @LogData
				END CATCH

				SET @count = @count + 1

				IF @count % @batch = 0
					WAITFOR DELAY '000:00:00.280'
			END

			FETCH NEXT
			FROM CS_master
			INTO @mrecommend, @srecommend, @currency, @actualrate, @currencyName, @mastername, @supername, @masterBalance
		END

		CLOSE CS_master

		DEALLOCATE CS_master

		DROP TABLE #Master
	END

	--------------------------END:MASTER-SUPER-------------------------------  
	DROP TABLE #Member
	DROP TABLE #tempdata
	DROP TABLE #SkippedMember	

	IF (@isSucc = 'true')
	BEGIN
		SELECT @LogData = 'Transfer (clear balance) all downlines: for Agent/Master/Super ' + @AgentName

		BEGIN TRY
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @AgentID, @ToCustID = 0, @IP = @IP, @Doing = @LogData
		END TRY

		BEGIN CATCH
			SELECT @LogData = @LogData + ' ErrMsg=' + error_message()

			EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @AgentID, @ToCustID = 0, @IP = @IP, @Doing = @LogData
		END CATCH
	END

	IF @ErrItems <> ''
	BEGIN
		SELECT @ErrCode = 113

		SELECT @ErrItems = LEFT(@ErrItems, len(@ErrItems) - 1)

		SELECT @ErrMsg = N'Clear balance failed: Allow only one transfer per day. Failed for the following user(s) and their upline (master, agent): ' + @ErrItems

		RETURN
	END

END
GO

