ALTER PROCEDURE [dbo].[NAP_BettransDelSpecial]
	@MatchId INT,
	@FromTransId BIGINT, 
	@ToTransId BIGINT, 
	@BetTypes VARCHAR(128) = '',
	@BetTeam1378 NVARCHAR(10), 
	@BetTeam515 NVARCHAR(10),
	@BetTeam430 VARCHAR(120) = '',
    @BetTeam6 VARCHAR(120) = '',
	@BetTeam14 VARCHAR(120) = '',
	@BetTeam16 VARCHAR(120) = '',
	@Handicap SMALLMONEY,
    @UserName NVARCHAR(50),
    @UserPassword NVARCHAR(50),
    @UserID INT,
	@LiveIndicator SMALLINT = 0,
    @LiveHomeScore SMALLINT = NULL,
    @LiveAwayScore SMALLINT = NULL,
	@SecondAcceptFlag TINYINT = 0 ,

    @FromTransdate DATETIME = NULL,
	@ToTransdate DATETIME = NULL,
    
	@TransIdsCredit VARCHAR(MAX) = '', -- for custom delete (Credit bets)
	@TransIdsDeposit VARCHAR(MAX) = '', -- for custom delete (Deposit bets)
    @TransIdsBetDaq VARCHAR(MAX) = '',-- for custom delete BetDaq
    @TransIds12EU VARCHAR(MAX) = '',-- for custom delete 12EU
    @TransIdsMHC VARCHAR(MAX) = '',-- for custom delete master MHC	   
	@TransIdsFB VARCHAR(MAX) = '',-- for custom delete Foobet	   

	@IP VARCHAR(15) = '',
    @Reason NVARCHAR(500) = '',

	@ErrMsg NVARCHAR(200) = '' OUTPUT,
    @ErrCode INT = 0 OUTPUT

AS
	/*
	Created by: Kathy
	Task : Special Delete
	DB: DBTXN/bodb02
	Original:

	Revisions:

	Param's Explanation: Special bet delete option
		- @SecondAcceptFlag: 
		  + 0: All tickets
		  + 1: Normal tickets only
		  + 2: SA tickets only
     
		-@LiveIndicator:
		 + 0: Dead
		 + 1: Live
		 + 2: All

	*/
BEGIN
	SET NOCOUNT ON;
	--Check permission for account site:	
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission 
		@custid=@UserID,
		@funcname='[SpecialDelete]',
		@ErrCode=@ErrCode OUTPUT,
		@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	--end

	--Check settled Date
	DECLARE @eventdate DATETIME 
	SELECT	@eventdate = eventdate
	FROM	match WITH (NOLOCK)
	WHERE	matchid = @MatchId
			
	EXEC dbo.Acc_CheckSettledDate
		@winlostdate = @eventdate, 
		@UserID = @UserID, 
		@ErrCode = @ErrCode OUTPUT, 
		@ErrMsg = @ErrMsg OUTPUT
	If @ErrCode <> 0
		RETURN
	--end	

	-- Check password
	DECLARE @LogData NVARCHAR(500)
	IF not exists (SELECT 1
					FROM customer WITH (NOLOCK)
					WHERE   customer.userpwd = @UserPassword
						AND custid = @UserID
						AND roleid>=5)
	BEGIN
		SELECT @LogData ='fail to void bet for matchid ' + CONVERT(VARCHAR(20), 
			@MatchId) + ' from ' + CONVERT(VARCHAR(20), @FromTransId) + ' to ' + CONVERT(VARCHAR(20), @ToTransId) + ' reason: ' + @Reason
		EXEC WriteLog_UserLog 
			@UserID = @UserID, 
			@Doing = @LogData
		SELECT @ErrMsg = 'Sorry. You can not process void bet due to either wrong password or insufficient permission!', @ErrCode = 101   
		RETURN
	END
	---- check AND not allow attempt to delete same game while it's still not finish
	DECLARE @Remark VARCHAR(500)
	DECLARE @KeyID INT

	IF EXISTS(SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^') WHERE CONVERT(INT, val) = 10) -- bettype 10: outright
	BEGIN 	
		SET @KeyID = 2
	END
	ELSE
	BEGIN 	
		SET @KeyID = 1
	END
	IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = @KeyID AND KeyValue = @MatchId)
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'This match is being calculated or some tickets of 
						this match are being voided, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END
	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (@KeyID, @MatchId)
	IF (@@Error = 0)
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @UserID, 
			@MatchId = @MatchId, 
			@KeyID = @KeyID,
			@ActionID = 0, 
			@Remark = 'ADD SUCCESS SPName=NAP_BettransDelSpecial'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS SPName=NAP_BettransDelSpecial ErrMsg=' + LEFT(error_message(), 400)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @UserID, 
			@MatchId = @MatchId, 
			@KeyID = @KeyID,
			@ActionID = 0, 
			@Remark = @Remark
	END CATCH
	ELSE 
	BEGIN
		SELECT @ErrCode = 100, 
			@ErrMsg = 'This match is being calculated or some tickets of this match are being voided, 
						please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END
	-------------------		
	CREATE TABLE #BetDelete (
		transid BIGINT PRIMARY KEY, 
		custid INT, 
		recommend INT, 
		mrecommend INT, 
		srecommend INT, 
		betfrom NVARCHAR(1),
		statusID INT, 
		status NVARCHAR(10), 
		SecAcceptFlag BIT, 
		username VARCHAR(30),
		creator VARCHAR(30), 
		hdp1 SMALLMONEY,  
		hdp2 SMALLMONEY,
		bettype SMALLINT, 
		betteam nVARCHAR(10),
		odds SMALLMONEY, 
		OddsType INT,
		transdate DATETIME,
		livehomescore SMALLINT, 
		liveawayscore SMALLINT,
		Stake money,
		CurrencyName VARCHAR(10)
		)

	DECLARE @12EUCust TABLE (custid INT, username VARCHAR(30))

	DECLARE @DepositCust TABLE (custid INT, username VARCHAR(30))
	
	DECLARE @UUSCust TABLE (custid INT, username VARCHAR(30))

	DECLARE @RealCurrCust TABLE (custid INT, username VARCHAR(30))

	DECLARE @FoobetCust TABLE (custid INT, username VARCHAR(30))

	DECLARE @Status TABLE (statusID TINYINT)
	INSERT INTO @Status
	SELECT 102 UNION ALL -- Void
	SELECT 101 UNION ALL -- Reject
	SELECT 112 UNION ALL -- Won
	SELECT 113 UNION ALL -- Lose
	SELECT 111 -- Draw


	DECLARE @tblTransCredit TABLE(transid BIGINT PRIMARY KEY)
	DECLARE @tblTransDeposit TABLE(transid BIGINT PRIMARY KEY)
	DECLARE @tblTransBetDaq TABLE(transid BIGINT PRIMARY KEY)
	DECLARE @tblTrans12EU TABLE(transid BIGINT PRIMARY KEY)
	DECLARE @tblTransMHC TABLE(transid BIGINT PRIMARY KEY)
	DECLARE @tblTransIdsFB TABLE(transid BIGINT PRIMARY KEY)

	INSERT INTO @tblTransCredit
	SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(ISNULL(@TransIdsCredit, ''), ',')
		
	INSERT INTO @tblTransDeposit
	SELECT CONVERT(BIGINT, val) FROM dbo.strSplit( ISNULL(@TransIdsDeposit,''), ',')

	INSERT INTO @tblTransBetDaq
	SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(ISNULL(@TransIdsBetDaq,''), ',')
	
	INSERT INTO @tblTrans12EU
	SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(ISNULL(@TransIds12EU,''), ',')
	
	INSERT INTO @tblTransMHC
	SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(ISNULL(@TransIdsMHC,''), ',')

	INSERT INTO @tblTransIdsFB
	SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(ISNULL(@TransIdsFB,''), ',')

	------------------***** Insert all data into #BetDelete *****------------------

 -- bettype <> 4 - Handicap(1), Over/Under(3), 1st Handicap(7), 1st Over/Under(8) - FT.1X2(5)/ 1st 1X2(15)
 INSERT INTO #BetDelete
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID, status, SecAcceptFlag, 
		b.Username, b.creator, b.hdp1, b.hdp2, b.bettype, b.betteam, b.odds, b.oddstype, b.transdate, b.livehomescore, 
		b.liveawayscore, b.stake, b.CurrencyName
	FROM bettrans b WITH (nolock)
		INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=b.bettype
	WHERE b.matchid=@matchid 
		AND b.transid between @FromTransId AND @ToTransId
		AND (b.transid IN (SELECT transid FROM @tblTransCredit)
			OR b.transid IN (SELECT transid FROM @tblTransDeposit )
			OR b.transid IN (SELECT transid FROM @tblTransBetDaq )
			OR b.transid IN (SELECT transid FROM @tblTrans12EU )
			OR b.transid IN (SELECT transid FROM @tblTransMHC )
			OR b.transid IN (SELECT transid FROM @tblTransIdsFB )
			)
		AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
		AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END 
		AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END 
		AND b.transdate between CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END
							AND CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
		AND b.betteam = CASE WHEN b.bettype IN (1,3,7,8,2,12) THEN CASE WHEN @BetTeam1378 = 'ALL' THEN b.betteam ELSE @BetTeam1378 END
							WHEN b.bettype IN (5,15) THEN CASE WHEN @BetTeam515 = 'ALL' THEN b.betteam ELSE @BetTeam515 END
							ELSE b.betteam END 
		AND b.bettype not in (4,6,14,16,30)
		AND CASE WHEN b.bettype IN (1,3,7,8) THEN CASE WHEN @Handicap = 9999 THEN 1
														WHEN @Handicap = (hdp1 + hdp2) THEN 1
													ELSE 0 END 
			ELSE 1 END = 1
		AND ISNULL(b.SecAcceptFlag, 0)  = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(b.SecAcceptFlag, 0)  
														 WHEN 1 THEN 0 
														 WHEN 2 THEN 1 END
					 
 -- bettype = 4 -- Correct score
 INSERT INTO #BetDelete
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID, status, SecAcceptFlag, 
		Username, creator, hdp1,hdp2, bettype, betteam, b.odds, b.oddstype, b.transdate, b.livehomescore, 
		b.liveawayscore, b.stake, b.CurrencyName
	FROM bettrans b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam430,'^') AS bt ON b.betteam=CONVERT(VARCHAR(3),bt.val)
	WHERE b.matchid=@matchid
		AND b.transid between @FromTransId AND @ToTransId
		AND (b.transid IN (SELECT transid FROM @tblTransCredit)
			OR b.transid IN (SELECT transid FROM @tblTransDeposit )
			OR b.transid IN (SELECT transid FROM @tblTransBetDaq )
			OR b.transid IN (SELECT transid FROM @tblTrans12EU )
			OR b.transid IN (SELECT transid FROM @tblTransMHC )
			OR b.transid IN (SELECT transid FROM @tblTransIdsFB  )
			)
		AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
		AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
		AND b.bettype in (4,30)
		AND (@betteam430='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(SecAcceptFlag,0) 
													 WHEN 1 THEN 0 
													 WHEN 2 THEN 1 END


-- bettype = 6: Total Goal
 INSERT INTO #BetDelete 
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID, status, SecAcceptFlag,
		Username, creator, hdp1,hdp2, bettype, betteam, b.odds, b.oddstype, b.transdate, b.livehomescore, 
		b.liveawayscore, b.stake, b.CurrencyName
	FROM dbo.bettrans AS b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam6,'^') AS bt ON bt.val=b.betteam
	WHERE b.matchid=@matchid
		AND b.transid between @FromTransId AND @ToTransId	
		AND (b.transid IN (SELECT transid FROM @tblTransCredit)
			OR b.transid IN (SELECT transid FROM @tblTransDeposit )
			OR b.transid IN (SELECT transid FROM @tblTransBetDaq )
			OR b.transid IN (SELECT transid FROM @tblTrans12EU )
			OR b.transid IN (SELECT transid FROM @tblTransMHC)
			OR b.transid IN (SELECT transid FROM @tblTransIdsFB )
			)
		AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
		AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 	
		AND b.bettype = 6
		AND (@betteam6='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(SecAcceptFlag,0) 
													 WHEN 1 THEN 0 
													 WHEN 2 THEN 1 END

-- bettype = 14: First Goal/Last Goal
 INSERT INTO #BetDelete  
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID, status, SecAcceptFlag,
		Username, creator, hdp1,hdp2, bettype, betteam, b.odds, b.oddstype, b.transdate, b.livehomescore, 
		b.liveawayscore, b.stake, b.CurrencyName
	FROM bettrans b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam14,'^') AS bt ON b.betteam=CONVERT(VARCHAR(3),bt.val)
	WHERE b.matchid=@matchid AND           
		b.transid between @FromTransId AND @ToTransId
		AND (b.transid IN (SELECT transid FROM @tblTransCredit)
			OR b.transid IN (SELECT transid FROM @tblTransDeposit )
			OR b.transid IN (SELECT transid FROM @tblTransBetDaq )
			OR b.transid IN (SELECT transid FROM @tblTrans12EU )
			OR b.transid IN (SELECT transid FROM @tblTransMHC )
			OR b.transid IN (SELECT transid FROM @tblTransIdsFB )
			)
		AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
		AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
		AND b.bettype = 14
		AND (@betteam14='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END

-- bettype = 16: HT/FT
	INSERT INTO #BetDelete 
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID, status, SecAcceptFlag,
		Username, creator, hdp1,hdp2, bettype, betteam, b.odds, b.oddstype, b.transdate, b.livehomescore, 
		b.liveawayscore, b.stake, b.CurrencyName
	FROM dbo.bettrans AS b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam16,'^') AS bt ON bt.val=b.betteam
	WHERE b.matchid=@matchid AND           
		b.transid between @FromTransId AND @ToTransId		
		AND (b.transid IN (SELECT transid FROM @tblTransCredit)
			OR b.transid IN (SELECT transid FROM @tblTransDeposit )
			OR b.transid IN (SELECT transid FROM @tblTransBetDaq )
			OR b.transid IN (SELECT transid FROM @tblTrans12EU )
			OR b.transid IN (SELECT transid FROM @tblTransMHC )
			OR b.transid IN (SELECT transid FROM @tblTransIdsFB )
			)
		AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator	
		AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
		AND b.bettype = 16
		AND (@betteam16='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 then ISNULL(SecAcceptFlag,0) 
													WHEN 1 THEN 0 
													WHEN 2 THEN 1 END					
										 												 								 
------------------***** End of insert all data into #BetDelete *****------------------

------------------***** Insert Custid of each type into its temp table *****------------------	
	
	 -- get deposit tickets voided 
	 INSERT INTO @DepositCust(custid, username)
		SELECT c.custid, c.username
		FROM custInfo c WITH (NOLOCK)
		INNER JOIN #BetDelete b ON b.custid = c.custid
		WHERE c.srecommend IN (SELECT custid FROM Dep_CustSuper WITH(NOLOCK))
		AND c.roleid = 1
		AND b.betfrom IN ('D', 'M', 'E', 'L')
		--AND @UserID NOT IN (SELECT a.custid FROM DBPOLICY.bodb02.dbo.accCustomer_1 a WHERE a.GroupID = 1) -- not in IT group

	 ---- get 12EU tickets voided 
	 INSERT INTO @12EUCust (custid,username)
		SELECT INF.custid,INF.username 
		FROM customer INF WITH (nolock)
		INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
		WHERE INF.UserName = '12EU'
		--AND @UserID NOT IN (SELECT a.custid FROM DBPOLICY.bodb02.dbo.accCustomer_1 a WHERE a.GroupID = 1)

	 ---- get UUS tickets 
	 INSERT INTO @UUSCust(custid,username)
		SELECT INF.custid, INF.username 
		FROM custinfo INF WITH(nolock) 
		INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
		WHERE INF.srecommend IN( SELECT custid FROM customer WITH(nolock) WHERE CURRENCY = 20 AND roleid = 4 ) 
		AND INF.roleid = 1

	 ---- get any real tickets voided by IT
	 INSERT INTO @RealCurrCust (CustID, username)
		SELECT INF.custid, INF.username 
		FROM custinfo INF WITH (NOLOCK) 
		INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
		WHERE INF.srecommend IN( SELECT custid FROM customer WITH(NOLOCK) WHERE CURRENCY <> 20 AND roleid = 4)	
		AND INF.roleid = 1 
		AND @UserID IN (SELECT a.custid FROM DBPOLICY.bodb02.dbo.accCustomer_1 a WHERE a.GroupID = 1) -- Check UserID in IT group

	-- get Foobet tickets
	INSERT INTO @FoobetCust (custid, username)
		SELECT bd.custid, ci.username
		FROM custInfo ci with(NOLOCK)
		INNER JOIN #BetDelete bd ON bd.custid = ci.custid
		where bd.recommend = 11196380
		and ci.roleid = 1 


	IF EXISTS (SELECT 1 FROM #BetDelete WHERE statusID IN (111,112,113))
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can only void the unsettled or refunded tickets.'
		-----
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = @KeyID AND KeyValue = @MatchId	
		IF (@@Error = 0)
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@MatchId = @MatchId, 
				@KeyID = @KeyID,
				@ActionID = 0, 
				@Remark = 'VOID SUCCESS SPName=NAP_BettransDelSpecial'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'VOID SUCCESS SPName=NAP_BettransDelSpecial ErrMsg=' + LEFT(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@MatchId = @MatchId, 
				@KeyID = @KeyID,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
		ELSE
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@MatchId = @MatchId, 
					@KeyID = @KeyID,
					@ActionID = 0, 
					@Remark = 'VOID FAILED SPName=NAP_BettransDelSpecial'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'VOID FAILED SPName=NAP_BettransDelSpecial ErrMsg=' + LEFT(error_message(), 400)
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@MatchId = @MatchId, 
					@KeyID = @KeyID,
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
	------------------***** Begin Special Delete *****------------------
	-- Step 1: backup
	INSERT INTO zzzbettrans (transid,custid,transdate,oddsid,hdp1,hdp2,odds,stake,status,
				winlost,livehomescore,liveawayscore,liveindicator,betteam,creator, refno, 
				winlostdate,betfrom,betcheck,checktime,matchid, bettype)
		SELECT  transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, 
				winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, 
				winlostdate, betfrom, betcheck, checktime, matchid, bettype
		FROM
			bettrans b WITH (nolock)
		WHERE
			b.transid IN (SELECT transid FROM #BetDelete)
			AND b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^'))
			AND b.matchid = @MatchId
			--AND b.liveindicator = @LiveIndicator
			AND CASE
				WHEN b.bettype IN (1,3,7,8) THEN CASE WHEN @BetTeam1378 = 'ALL' THEN betteam ELSE @BetTeam1378 END
				WHEN b.bettype IN (5,15) THEN CASE WHEN @BetTeam515 = 'ALL' THEN betteam ELSE @BetTeam515 END
				ELSE betteam
			END = betteam    

	CREATE TABLE #BeforeUpd (
			custid		 INT,
			balance		 MONEY)
		
	CREATE TABLE #AfterUpd(
				custid		 INT,
				balance		 MONEY)

	INSERT INTO #BeforeUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.transid IN (SELECT transid FROM #BetDelete)
	GROUP BY b.CustID
	
	-- STEP 2 : Update
	--  begin tran
	UPDATE 
		bettrans WITH (ROWLOCK, UPDLOCK)
	SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', creator = @UserID,
		awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0, statusID = 102       
	WHERE
		transid IN (SELECT transid FROM #BetDelete)

	-- update totalbets
	DECLARE @Total TABLE (oddsid INT, HomeTotal MONEY, AwayTotal MONEY)
	INSERT INTO @Total
		SELECT oddsid,
			SUM(CASE WHEN betteam='h' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) 
					 ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) homeTotal,
			SUM(CASE WHEN betteam='a' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) 
					 ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) awayTotal
		FROM bettrans b WITH (nolock)
			INNER JOIN exchange e WITH (nolock) ON b.currency = e.exchangeid
		WHERE bettype IN (1,3,7,8) AND ruben = 0 AND oddsid <> 0 AND matchid = @MatchId
		GROUP BY oddsid

	UPDATE odds WITH (rowlock, updlock)
	SET hometotal = t.HomeTotal, awaytotal = t.AwayTotal
	FROM @Total t WHERE odds.oddsid = t.oddsid AND odds.matchid = @MatchId

	--Get data after update
	INSERT INTO #AfterUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.transid IN (SELECT transid FROM #BetDelete)
	GROUP BY b.CustID

	---INSERT data into pending balance table 
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
------------------***** End of Special Delete *****------------------

	SELECT @LogData ='void bet for matchid ' + CONVERT(VARCHAR(20), @MatchId) 
			+ ' from ' + CONVERT(VARCHAR(20), @FromTransId) + ' to ' 
			+ CONVERT(VARCHAR(20), @ToTransId) + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) 
			+ ' reason: ' + @Reason
	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

	-- Match info
	IF EXISTS(SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^') WHERE CONVERT(INT, val) = 10)  --@bettype = 10
	BEGIN
		SELECT MATCH.teamid AS homeid,
			0 AS awayid,
			MATCH.matchcode,
			MATCH.eventdate,
			MATCH.leagueid,
			GETDATE() AS DATETIME,
			CONVERT(BIT,0) AS IsNeutral
		FROM
			Outright AS MATCH WITH (NOLOCK)
		WHERE 
			MATCH.orid = @MatchId
	END   
	ELSE
	BEGIN
		SELECT MATCH.homeid,
			MATCH.awayid,
			MATCH.matchcode,
			MATCH.eventdate,
			MATCH.leagueid,
			GETDATE() AS DATETIME,
			ISNULL(MATCH.isNeutral, CONVERT(BIT,0)) AS IsNeutral
		FROM
			MATCH WITH (NOLOCK)
		WHERE 
			MATCH.matchid = @MatchId
	END

	-- All ticket voided
	SELECT transid, bd.custid, mem.UserName AS CustUserName, bd.recommend, ag.UserName AS AgUserName,
	bd.mrecommend, mag.UserName AS MagUserName, bd.srecommend, sag.Username AS SagUserName,
	bd.status, bd.SecAcceptFlag
	FROM #BetDelete bd (nolock)
	INNER JOIN custinfo mem (nolock) ON bd.custid     = mem.custid
	INNER JOIN custinfo ag  (nolock) ON bd.recommend  = ag.custid
	INNER JOIN custinfo mag (nolock) ON bd.mrecommend = mag.custid
	INNER JOIN custinfo sag (nolock) ON bd.srecommend = sag.custid
	
	-- Send mail when void deposit
	SELECT customer.username, customer.username2, b.odds, b.OddsType, b.transdate, b.bettype,
		b.transid AS refno, betteam, hdp1, hdp2, betfrom, livehomescore, liveawayscore, cr.username creator,
		stake, b.CurrencyName, ag.site, b.status, b.SecAcceptFlag
	FROM
		#BetDelete b WITH (NOLOCK)
		INNER JOIN customer  WITH (NOLOCK) ON customer.custid=b.custid
		INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
	WHERE ( b.betfrom  IN ('D', 'M', 'E', 'L') AND customer.custid IN (SELECT custid FROM @DepositCust)) -- Email deposit if voided		
	ORDER BY transid

	-- Send mail when void 12EU tickets 
		SELECT customer.username, customer.username2, b.odds, b.OddsType, b.transdate, b.bettype,
		b.transid AS refno, betteam, hdp1, hdp2, betfrom, livehomescore, liveawayscore, cr.username creator,
		stake, b.CurrencyName, '12EU' as site, b.status, b.SecAcceptFlag
	FROM
		#BetDelete b WITH (NOLOCK)
		INNER JOIN customer  WITH (NOLOCK) ON customer.custid=b.custid
		INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
	WHERE b.custid IN (SELECT [@12EUCust].custid FROM @12EUCust) -- Email 12EU if voided			
	ORDER BY transid

	
	-----Send mail when void any real tickets by IT
	SELECT customer.username, customer.username2, b.odds, b.OddsType, b.transdate, b.bettype,
		b.transid AS refno, betteam, hdp1, hdp2, betfrom, livehomescore, liveawayscore,
		cr.username creator, stake, b.CurrencyName, ag.site,
		b.status, b.SecAcceptFlag
	FROM #BetDelete b WITH (NOLOCK)
		INNER JOIN customer  WITH (NOLOCK) ON customer.custid=b.custid
		INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
	WHERE customer.custid IN (SELECT custid FROM @RealCurrCust)			     					   
	ORDER BY transid    	   

	-- Send mail when void UUS tickets
		SELECT customer.username, customer.username2, b.odds, b.OddsType, b.transdate, b.bettype,
		b.transid AS refno, betteam, hdp1, hdp2, betfrom, livehomescore, liveawayscore,
		cr.username creator, stake, b.CurrencyName, ag.site,
		b.status, b.SecAcceptFlag
	FROM #BetDelete b WITH (NOLOCK)
		INNER JOIN customer  WITH (NOLOCK) ON customer.custid=b.custid
		INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
	WHERE customer.custid IN (SELECT custid FROM @UUSCust)				     					   
	ORDER BY transid    

		-----Send mail when void Foobet tickets
	SELECT customer.username, customer.username2, b.odds, b.OddsType, b.transdate, b.bettype,
		b.transid AS refno, betteam, hdp1, hdp2, betfrom, livehomescore, liveawayscore,
		cr.username creator, stake, b.CurrencyName, 'Foobet' as site,
		b.status, b.SecAcceptFlag
	FROM #BetDelete b WITH (NOLOCK)
		INNER JOIN customer  WITH (NOLOCK) ON customer.custid=b.custid
		INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
	WHERE customer.custid IN (SELECT custid FROM @FoobetCust)			     					   
	ORDER BY transid    

	DROP TABLE #BetDelete
	DROP TABLE #BeforeUpd
	DROP TABLE #AfterUpd

	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = @KeyID AND KeyValue = @MatchId	
	IF (@@Error = 0)
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@MatchId = @MatchId, 
				@KeyID = @KeyID,
				@ActionID = 0, 
				@Remark = 'VOID SUCCESS SPName=NAP_BettransDelSpecial'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'VOID SUCCESS SPName=NAP_BettransDelSpecial ErrMsg=' + LEFT(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@MatchId = @MatchId, 
				@KeyID = @KeyID,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
		ELSE
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@MatchId = @MatchId, 
					@KeyID = @KeyID,
					@ActionID = 0, 
					@Remark = 'VOID FAILED SPName=NAP_BettransDelSpecial'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'VOID FAILED SPName=NAP_BettransDelSpecial ErrMsg=' + LEFT(error_message(), 400)
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@MatchId = @MatchId, 
					@KeyID = @KeyID,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH
		END	
	SET NOCOUNT OFF
END

GO
GRANT EXECUTE ON [dbo].[NAP_BettransDelSpecial] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_BettransDelSpecial] TO [vnteam]

 