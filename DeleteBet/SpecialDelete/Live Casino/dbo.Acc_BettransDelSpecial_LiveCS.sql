ALTER PROCEDURE [Acc_BettransDelSpecial_LiveCS]
    @matchid		INT,     
    @f_transid		BIGINT,
    @t_transid		BIGINT,
    
    @transids_N		VARCHAR(4000)	= '',-- Normal bets
    @transids_D		VARCHAR(4000)	= '',-- Deposit bets
    @transids_BD	VARCHAR(4000)	= '',-- BetDaq
    @transids_12EU	VARCHAR(4000)	= '',-- for custom delete 12EU
    @transids_MHC	VARCHAR(4000)	= '',-- for custom delete master MHC   
     
    @UserName		NVARCHAR(50),
    @UserPwd		NVARCHAR(50),
    @UserID			INT,
	@IP				VARCHAR(15)		= '',
	@reason			NVARCHAR(500)	= '',
    @ErrMsg			NVARCHAR(200)	= '' OUTPUT,
    @ErrCode		INT				= 0 OUTPUT
AS
/*
	Created by: 20120208@Lukas
	Task : SP delete bet (Live Casino)
	DB: DBTXN/bodb02

	Revisions:
		- 20120703@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype for odds, Oddstype 
		- 20120914@Sophia: Add table TempVariableNumber to check and not to allow attempt to proceed on same game while it's still not finish
		- 20121107@Elodie: Allow to void settled tickets 
						   Allow user to delete deposit tickets
		- 20130103@Elodie: Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table																 						   
		- 20130128@Elodie: Change link server DB03 to DBPOLICY
						   Write more log on DBTXN server in case of DBLOG server failure
		- 20130526@Johnson: Add param @reason to log the reason delete bets
		- 20130702@Elodie: Add new bettype 1103, 1104
		- 20131108@Elodie: Splitting bodb02 into CustDB (call Customer from CustDB by link database)
		- 20131210@Kathy: Using Dep_CustSuper table to find deposit ticket instead of betfrom in ('D', 'M', 'E', 'L') [Redmine:#9321]	
	Param's Explanation: 
	
*/
BEGIN
	SET NOCOUNT ON

	--Check permission for account site
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[SpecialDeleteLivecasino]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	--end

	DECLARE @today SMALLDATETIME
	SET @today = convert(nvarchar(10), current_timestamp, 120)
	
	--Check settled Date
	DECLARE @eventdate Datetime 
	SELECT	@eventdate = eventdate
	FROM	match WITH (NOLOCK)
	WHERE	matchid = @matchid
			
	IF(@eventdate <> @today)
	BEGIN
		SELECT  @ErrCode = 103,
				@ErrMsg = 'You are only allowed to delete today tickets.'
		RETURN
	END
	
	EXEC dbo.Acc_CheckSettledDate @winlostdate = @eventdate, @UserID = @UserID, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	If @ErrCode <> 0
		RETURN
	--end
	
	DECLARE @LogData NVARCHAR(500)
	DECLARE @Remark VARCHAR(500)
	SELECT	@ErrCode = 0

	IF NOT EXISTS (	SELECT 1
					FROM CustDB.dbo.customer WITH (NOLOCK)
					WHERE   customer.userpwd = @UserPwd
						and custid = @UserID
						and roleid>=5)
	BEGIN
		SELECT @LogData ='fail to delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' from ' + CONVERT(VARCHAR(20), @f_transid) + ' to ' + CONVERT(VARCHAR(20), @t_transid) + ' reason: ' + @reason
		EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

		SELECT @ErrMsg = 'Sorry. You can not process delete bet due to either wrong password or insufficient permission!', @ErrCode = 101   
		RETURN
	END

	---- check and not allow attempt to delete same game while it's still not finish
	IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
	BEGIN
		SELECT  @ErrCode = 102,
				@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END

	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)
	IF (@@Error = 0)
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = 'ADD SUCCESS SPName=Acc_BettransDelSpecial_LiveCS'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransDelSpecial_LiveCS ErrMsg=' + left(error_message(), 400)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = @Remark
	END CATCH
	ELSE 
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END
	-----------	
	
	CREATE TABLE #BetDelete (transid BIGINT, custid INT, recommend INT, mrecommend INT, srecommend INT, betfrom NVARCHAR(1),statusID INT)
	DECLARE @UUSCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @RealCurrCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @12EUCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @DepositCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @MasterMHC TABLE (custid INT)
	DECLARE @BalanceCust TABLE (custid INT, Balance Money)
	DECLARE @NegativeBalanceCust TABLE (custid INT, IsNegative bit)		
	DECLARE @Status TABLE (statusID TINYINT)	
	
	INSERT INTO @Status
	SELECT 102 UNION ALL
	SELECT 101 UNION ALL
	SELECT 121 UNION ALL    ---- dummy ticket	
	SELECT 0	
	
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)			
			SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
			FROM bettrans b WITH (nolock)
			WHERE
				b.matchid=@matchid 						
				AND b.transid BETWEEN @f_transid AND @t_transid		
				and b.bettype in (1101, 1102, 1103, 1104)
				AND winlostdate = @today
				and (  b.transid in (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_N, ','))
					or b.transid in (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_D, ','))
					or b.transid in (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_BD, ','))
					or b.transid in (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_12EU, ','))
					or b.transid in (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_MHC, ','))
					)
				
	IF EXISTS (SELECT 1 FROM #BetDelete WHERE statusID = 0)
	BEGIN
		SELECT @ErrCode = 104, @ErrMsg = 'You can only delete the refunded or settled tickets.'
				
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid	
		IF (@@Error = 0)
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial_LiveCS'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial_LiveCS ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
		ELSE
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial_LiveCS'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial_LiveCS ErrMsg=' + left(error_message(), 400)
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH
		END
		RETURN
	END
	ELSE
	BEGIN
		DELETE FROM #BetDelete WHERE statusID IN (SELECT * FROM @Status)
	END

	--INSERT DEPOSIT CUSTOMER
	INSERT INTO @DepositCust (custid, username)
		SELECT INF.custid, INF.username 
		FROM CustDB.dbo.custinfo INF WITH(nolock) 
			INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
		WHERE	INF.srecommend in ( SELECT custid FROM CustDB.dbo.Dep_CustSuper WITH (NOLOCK))						
				  AND INF.roleid = 1
				 -- AND BD.betfrom IN ('D', 'M', 'E', 'L')
				  
	--INSERT 12EU CUSTOMER
	INSERT INTO @12EUCust (custid,username)
		SELECT INF.custid,INF.username 
		FROM CustDB.dbo.customer INF WITH (nolock)
			INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
			WHERE INF.username = '12EU'
				
	--INSERT UUS CUSTOMER
	Insert into @UUSCust(custid,username)
	SELECT INF.custid, INF.username 
	FROM CustDB.dbo.custinfo INF (nolock) 
		INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
		WHERE INF.srecommend IN(
				SELECT custid FROM CustDB.dbo.customer (nolock) Where CURRENCY = 20 AND roleid = 4
			) AND INF.roleid = 1

	--INSERT CUSTOMER HAVE REAL CURRENCIES AND CREATE USERNAME LIKE 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'		
	INSERT INTO @RealCurrCust (CustID, username)
	SELECT		INF.custid, INF.username 
	FROM		CustDB.dbo.custinfo INF WITH (NOLOCK) 
	INNER JOIN	#BetDelete BD ON INF.Custid = BD.Custid 
	WHERE		INF.srecommend IN( SELECT custid FROM CustDB.dbo.customer WITH(NOLOCK) Where CURRENCY <> 20 AND roleid = 4)	
				AND INF.roleid = 1 
				AND ( @Username LIKE 'dba%' OR @Username LIKE 'pgm%' OR @Username ='vndbateam' OR @Username = 'vnQaTeam')	
	
	INSERT INTO @MasterMHC(custid)
				SELECT 105181
				union all
				SELECT 118473
				union all
				SELECT 105183
		
	-- STEP 1 : BackUp
	INSERT INTO zzzbettrans
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT
		 transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
	FROM
		bettrans b WITH (nolock)
	WHERE
		b.transid IN (SELECT transid FROM #BetDelete)		 

	-- calculate a balance of customer
	INSERT INTO @BalanceCust (custid, Balance)
	SELECT custid, sum(winlost - actual_stake + playercomm)
	from bettrans with (nolock) 	
	where custid in (SELECT custid FROM #BetDelete)
	group BY custid
	
	CREATE TABLE #BeforeUpd (
				custid		 INT,
				winlostdate	 DATETIME,
				balance		 MONEY,
				winlost		 MONEY)
		
	CREATE TABLE #AfterUpd(
				custid		 INT,
				winlostdate	 DATETIME,
				balance		 MONEY,
				winlost		 MONEY)
	
	-- Get data before update
	INSERT INTO #BeforeUpd (custid, winlostdate, balance, winlost)
	SELECT	b.custid, winlostdate, SUM (b.winlost - b.actual_stake + b.playercomm), SUM(CASE WHEN ruben = 1 THEN winlost - actual_stake + playercomm ELSE 0 END)
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.transid in (SELECT transid FROM #BetDelete)
	GROUP BY b.CustID, winlostdate
	
	INSERT INTO @NegativeBalanceCust (custid, IsNegative)
	select  won.custid,
			case when won.balance > 0 and (c.credit + bal.balance - won.balance) < 0 THEN 1 ELSE 0 END 
	from #BeforeUpd won
		inner join @BalanceCust bal on won.custid= bal.custid
		INNER JOIN CustDB.dbo.custinfo c with (NOLOCK) ON bal.custid = c.custid
	
	-- Get ticket infomation to mail related department before void ticket
	CREATE TABLE #TicketInfo(custid int, odds smallmoney, oddstype tinyint, transdate datetime, bettype int, transid bigint, betteam nvarchar(20), hdp1 smallmoney, betfrom nvarchar(2), spositiontaking smallmoney, mpositiontaking smallmoney, apositiontaking smallmoney, stake money, winlost money, comm money, status nvarchar(20), currency tinyint, liveindicator bit, creator int)
	INSERT INTO #TicketInfo (custid, odds, oddstype, transdate, bettype, transid, betteam, hdp1, betfrom, spositiontaking, mpositiontaking, apositiontaking, stake, winlost, comm, status, currency, liveindicator, creator)
	SELECT			
			b.custid,
			b.odds,
			b.oddstype,
			b.transdate,
			b.bettype,
			b.transid,
			b.betteam,
			b.hdp1,
			b.betfrom,
			b.spositiontaking,
			b.mpositiontaking,
			b.apositiontaking,
			b.stake,
			b.winlost - b.actual_stake as winlost,
			b.playercomm as comm, 	
			b.status,	
			b.currency,          
			b.liveindicator,
			b.creator
	FROM bettrans b WITH (NOLOCK)			
	WHERE b.transid IN(SELECT transid FROM #BetDelete)
	
	-- STEP 2 : Update
	--    begin tran
	UPDATE 
		bettrans WITH (ROWLOCK, UPDLOCK)
	SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', creator = @UserID,
		awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0, statusID = 102       
	WHERE
		transid in (SELECT transid FROM #BetDelete)	

	--Get data after update
	INSERT INTO #AfterUpd (custid, winlostdate, balance, winlost)
	SELECT	b.custid, winlostdate, SUM (b.winlost - b.actual_stake + b.playercomm), SUM(CASE WHEN ruben = 1 THEN winlost - actual_stake + playercomm ELSE 0 END)
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.transid in (SELECT transid FROM #BetDelete)
	GROUP BY b.CustID, winlostdate

	---insert data into pending balance table 
	INSERT INTO BalancePendingCredit (custid,Balance)
	SELECT		a.custid, (a.balance - b.balance) as Balance
	FROM		#BeforeUpd b
	INNER JOIN	#AfterUpd a 	
			ON	a.custid = b.custid
	WHERE	    (a.balance - b.balance) > 0

	INSERT INTO BalancePendingDebit (custid,Balance)
	SELECT		a.custid, ABS(a.balance - b.balance) as Balance
	FROM		#BeforeUpd b
	INNER JOIN	#AfterUpd a 	
			ON	a.custid = b.custid
	WHERE	    (a.balance - b.balance) < 0

	---insert data into pending balance game table 
	INSERT INTO BalancePendingCreditGame (custid, winlostdate, balance)
	SELECT		a.custid, a.winlostdate, (a.winlost - b.winlost) as Balance
	FROM		#BeforeUpd b
	INNER JOIN	#AfterUpd a 	
			ON	a.custid = b.custid
	WHERE	    (a.winlost - b.winlost) > 0

	INSERT INTO BalancePendingDebitGame (custid, winlostdate, balance)
	SELECT		a.custid, a.winlostdate, ABS(a.winlost - b.winlost) as Balance
	FROM		#BeforeUpd b
	INNER JOIN	#AfterUpd a 	
			ON	a.custid = b.custid
	WHERE	    (a.winlost - b.winlost) < 0
	
	SELECT @LogData ='delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' from ' + CONVERT(VARCHAR(20), @f_transid) + ' to ' + CONVERT(VARCHAR(20), @t_transid) + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) + ' reason: ' + @reason
	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

	--after delete, return all deleted deposit bets and 12EU with additional information for mailing (not send mail for BETDAQ tickets)	
	SELECT
		homeid,
		awayid,
		matchcode,
		eventdate,
		leagueid,
		betstatus,
		eventstatus,
		GETDATE() AS [DATETIME],
		0 IsNeutral,
		showtime AS GameEvent
	FROM
		match WITH (NOLOCK)
	WHERE 
		matchid = @matchID
		
	SELECT
		customer.username,
		b.odds,
		b.oddstype,
		b.transdate,
		b.bettype,
		b.transid AS refno,
		b.betteam,
		b.hdp1,
		b.spositiontaking,
		b.mpositiontaking,
		b.apositiontaking,
		b.stake,
		b.winlost,
		b.comm, 	
		b.status,	          
		ag.site,
		b.currency,
		b.liveindicator,
		cr.username creator,	
		IsNegative						        
	FROM
		#TicketInfo b WITH (NOLOCK)
		INNER JOIN CustDB.dbo.customer  WITH (NOLOCK) ON customer.custid=b.custid
		INNER JOIN CustDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN CustDB.dbo.customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
		inner JOIN @NegativeBalanceCust nc on b.custid = nc.custid
	WHERE customer.custid IN (SELECT custid FROM @DepositCust)
			 OR customer.custid IN (SELECT custid FROM @12EUCust) --Email 12EU if delete  			
	ORDER BY transid		

	SELECT b.transid as refno, bg.odds, bg.stake, bg.status, bg.bettype, bg.betteam
	FROM bettransG bg WITH(NOLOCK)	
		INNER JOIN bettrans b WITH(NOLOCK) ON bg.refno = b.refno
	WHERE b.transid IN(SELECT transid FROM #BetDelete)	
		and (	
			b.custid IN (SELECT custid FROM @DepositCust)
			OR b.custid IN (SELECT custid FROM @12EUCust) --Email 12EU if delete  
			)	
	
	SELECT	transid,
			bd.custid, mem.UserName     AS CustUserName,
			bd.recommend, ag.UserName   AS AgUserName,
			bd.mrecommend, mag.UserName AS MagUserName,
			bd.srecommend, sag.Username AS SagUserName
	FROM #BetDelete bd (nolock)
			INNER JOIN CustDB.dbo.custinfo mem (nolock) ON bd.custid     = mem.custid
			INNER JOIN CustDB.dbo.custinfo ag  (nolock) ON bd.recommend  = ag.custid
			INNER JOIN CustDB.dbo.custinfo mag (nolock) ON bd.mrecommend = mag.custid
			INNER JOIN CustDB.dbo.custinfo sag (nolock) ON bd.srecommend = sag.custid
	
	----Begin : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR Currency is UUS	
	SELECT
		customer.username,
		b.odds,
		b.oddstype,
		b.transdate,
		b.bettype,
		b.transid AS refno,
		b.betteam,
		b.hdp1,
		b.spositiontaking,
		b.mpositiontaking,
		b.apositiontaking,
		b.stake,
		b.winlost,
		b.comm, 	
		b.status,	          
		ag.site,
		b.currency,
		b.liveindicator,
		cr.username creator,	
		IsNegative					
	FROM
		#TicketInfo b WITH (NOLOCK)
		INNER JOIN CustDB.dbo.customer  WITH (NOLOCK) ON customer.custid=b.custid
		INNER JOIN CustDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN CustDB.dbo.customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
		inner JOIN @NegativeBalanceCust nc on b.custid = nc.custid
	WHERE	customer.custid IN (SELECT custid FROM @UUSCust)
			or customer.custid IN (SELECT custid FROM @RealCurrCust) 					 
	ORDER BY transid

	SELECT b.transid as refno, bg.odds, bg.stake, bg.status, bg.bettype, bg.betteam
	FROM bettransG bg WITH(NOLOCK)	
		INNER JOIN bettrans b WITH(NOLOCK) ON bg.refno = b.refno
	WHERE b.transid IN(SELECT transid FROM #BetDelete)	
		AND ( b.custid IN (SELECT custid FROM @UUSCust)
				or b.custid IN (SELECT custid FROM @RealCurrCust) 
			)	
	-----End : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR Currency is UUS

	DROP TABLE #BetDelete	
	DROP TABLE #TicketInfo
	DROP TABLE #BeforeUpd
	DROP TABLE #AfterUpd
	-----
	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid	
	IF (@@Error = 0)
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial_LiveCS'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial_LiveCS ErrMsg=' + left(error_message(), 400)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = @Remark
	END CATCH
	ELSE
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial_LiveCS'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial_LiveCS ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
	END
END
GO

GRANT EXECUTE ON [Acc_BettransDelSpecial_LiveCS] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [Acc_BettransDelSpecial_LiveCS] TO [vnteam] AS [dbo]
GO


