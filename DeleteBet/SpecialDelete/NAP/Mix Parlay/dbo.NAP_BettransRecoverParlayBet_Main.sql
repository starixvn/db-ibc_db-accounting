ALTER PROCEDURE [dbo].[NAP_BettransRecoverParlayBet_Main] 
	@BetType			VARCHAR(20)		= 'All',
	@TransIds			VARCHAR(MAX)	= '',
	@UserId				INT, 
	@IP					VARCHAR(50),

	@SettledMainTranIds	VARCHAR(4000)	= ''	OUTPUT,
	@ErrCode			INT				= 0		OUTPUT,
	@ErrMsg				VARCHAR(300)	= ''	OUTPUT
AS
/*
	Created: Elodie
	Date: 20161017
	DB: DBTXN/bodb02

	Revisions: 		

	Example: 
		DECLARE @ErrCode INT, @ErrMsg VARCHAR(300)
		EXEC NAP_BettransRecoverParlayBet_Main @BetType = 'All', @TransIds = '10094287060761,10094287060762,10094287060763,10094287060764', @UserID = 8, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
		SELECT ErrCode, @ErrMsg

	Param's Explanation:			
		- @BetType: 'all': All
					'Mix Parlay': Mix Parlay
					'System Parlay': System Parlay
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @LogData			VARCHAR(MAX)
			,@RowNumber			INT	= 1
			,@tmp_TransIds		VARCHAR(MAX)
			,@refnos_29			VARCHAR(MAX)
			,@tmp_MatchId		INT
			,@MatchDate			DATETIME
			,@IsITAdmin			BIT = 0

	DECLARE @tblTransIds TABLE (transid BIGINT PRIMARY KEY)
	DECLARE @tblNoResettleTransIds TABLE (transid BIGINT PRIMARY KEY)
	DECLARE @beforeDaysNum INT = 3
	DECLARE @before_yesterday DATETIME	

	SELECT @before_yesterday = CONVERT(VARCHAR(10), DATEADD(day, - @beforeDaysNum, GETDATE()), 120)

	CREATE TABLE #tblRecoverBet( transid		BIGINT
								,matchid		INT
								,refno			BIGINT 
								,custid			INT
								)
	CREATE INDEX IX_RecoverBet ON #tblRecoverBet (refno)
	
	DECLARE @tblMatchIds		TABLE ( RowNumber		INT 										
										,matchid		INT
										,transid		BIGINT
										,refno			BIGINT
								)								
											
	DECLARE @tblBeforeBalance	TABLE (custid INT, balance MONEY)
	DECLARE @tblAfterBalance	TABLE (custid INT, balance MONEY)
	
	--- Check for concurrent running
	IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingParlay')
	BEGIN
		SELECT @ErrCode = 101
			,@ErrMsg	= 'Another parlay settlement is in progress or some parlay tickets are being voided, please wait a few seconds until the on-going process has finished and try again.'
		 
		RETURN
	END
	ELSE 
	BEGIN
		UPDATE SystemSettings WITH (ROWLOCK, UPDLOCK)
			SET VValue = '1'
		WHERE VName = 'isCalculatingParlay'
	END

	--Transid which user input
	INSERT INTO @tblTransIds
	SELECT val
	FROM dbo.strSplit(@TransIds, ',') 

	--Transid list is recovered
	INSERT INTO #tblRecoverBet (
				transid
				,matchid
				,refno
				,custid
	)
	SELECT	b.transid
			,b.matchid
			,b.refno
			,b.custid
	FROM	@tblTransIds s 
		INNER JOIN bettrans b WITH(NOLOCK) ON s.transid = b.transid
	WHERE b.matchid = 29 AND b.bettype = 29
		AND b.winlostdate >= @before_yesterday
		AND CASE
				WHEN @BetType = 'all' THEN 1
				WHEN @BetType = 'Mix Parlay' THEN CASE WHEN b.betteam = 1 THEN 1 ELSE 0 END
				WHEN @BetType = 'System Parlay' THEN CASE WHEN b.betteam = 1 THEN 0 ELSE 1 END
				ELSE 0
			END	= 1	
	
	IF @@ROWCOUNT = 0
	BEGIN
			------ release Parlay procesee	
		UPDATE systemSettings WITH (ROWLOCK, UPDLOCK)
		SET VValue = '0'
		WHERE VName = 'isCalculatingParlay'
	    
		RETURN
	END
	
	INSERT INTO @tblNoResettleTransIds (transid)
	SELECT t.transid
	FROM dbo.bettransm b WITH(NOLOCK) 
		INNER JOIN #tblRecoverBet t ON t.refno = b.refno
		INNER JOIN dbo.match m WITH (NOLOCK) ON b.matchid = m.matchid
	WHERE m.eventstatus <> 'completed'
	GROUP BY t.transid

	-- Get match list
	SELECT	ROW_NUMBER() OVER (PARTITION BY t.transid ORDER BY m.eventdate DESC) AS RowNumber,
			b.matchid, t.transid, t.refno
	INTO #tmpMatch
	FROM	dbo.bettransm b WITH(NOLOCK) 
		INNER JOIN #tblRecoverBet t ON t.refno = b.refno	
		INNER JOIN dbo.match m WITH (NOLOCK) ON b.matchid = m.matchid			
	WHERE NOT EXISTS (SELECT 1 FROM @tblNoResettleTransIds WHERE transid = t.transid)

	-- Match list is auto settled
	INSERT INTO @tblMatchIds (RowNumber, matchid, transid, refno)
	SELECT	DENSE_RANK() OVER (ORDER BY t.matchid) AS RowNumber,
			t.matchid, t.transid, t.refno
	FROM	#tmpMatch t
	WHERE RowNumber = 1

	---- capture balance before recover
	INSERT INTO @tblBeforeBalance (custid, balance)
	SELECT	b.custid
			,SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
		INNER JOIN #tblRecoverBet t ON b.transid = t.transid
	GROUP BY b.CustID
	---- end capture
	
	UPDATE	b WITH(ROWLOCK, UPDLOCK)
	SET status = 'running'
		,statusID = 0
		,ruben = 0
		,modds = 0
		,winlost = 0
		,awinlost = 0
		,mwinlost = 0
		,swinlost = 0
		,playercomm = 0
		,comm = 0
		,acomm = 0
		,scomm = 0				
	FROM dbo.bettrans b
		INNER JOIN #tblRecoverBet t ON b.transid = t.transid

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @tmp_MatchId = matchid
		FROM	@tblMatchIds
		WHERE	RowNumber = @RowNumber
		
		IF @@rowcount = 0
			BREAK		
		
		SET @RowNumber = @RowNumber + 1
		
		SELECT  @MatchDate = eventdate
		FROM	dbo.match WITH(NOLOCK)
		WHERE	matchid = @tmp_MatchId

		SELECT @tmp_TransIds = ''
		SELECT  @tmp_TransIds = @tmp_TransIds + CONVERT(VARCHAR(20), transid) + ','
		FROM	@tblMatchIds
		WHERE	matchid = @tmp_MatchId

		SELECT @refnos_29 = ''
		SELECT 	@refnos_29 = @refnos_29 + ',' + CONVERT(VARCHAR(20), refno) + '|' + CONVERT(VARCHAR(20), transid)
		FROM	@tblMatchIds
		WHERE	matchid = @tmp_MatchId

		SET @refnos_29 = STUFF(@refnos_29,1,1,'')
		
		EXEC dbo.NAP_Admin_Calculate_MP_broker 
			@matchid = @tmp_MatchId
			,@mode = 'PRECAL-29'
			,@matchdate = @matchdate
			,@strXML = @tmp_TransIds

		EXEC dbo.NAP_Admin_Calculate_MP_broker
				@matchdate = @MatchDate
				,@strXML	= @refnos_29
				,@mode		= '29' 
	END

	-- capture after recover
	INSERT INTO @tblAfterBalance (custid, balance)
	SELECT	b.custid
			,SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
		INNER JOIN #tblRecoverBet t ON b.transid = t.transid
	GROUP BY b.CustID
	
	DECLARE @tblDebitPending TVP_BalanceList
	DECLARE @tblCreditPending TVP_BalanceList
	
	INSERT INTO @tblCreditPending (custID, balance)
	SELECT		a.custid, (a.balance - b.balance) AS Balance
	FROM		@tblBeforeBalance b
	INNER JOIN	@tblAfterBalance a 	
			ON	a.custid = b.custid
	WHERE	    (a.balance - b.balance) > 0
	
	IF @@rowcount <> 0
		EXEC dbo.Dot_BalancePendingCreditIns 
			@BalancePending = @tblCreditPending
			,@Type			= 1 -- Sports		

	INSERT INTO @tblDebitPending (custID, balance)
	SELECT		a.custid, ABS(a.balance - b.balance) AS Balance
	FROM		@tblBeforeBalance b
	INNER JOIN	@tblAfterBalance a 	
			ON	a.custid = b.custid
	WHERE	    (a.balance - b.balance) < 0	
	
	IF @@rowcount <> 0
		EXEC dbo.Dot_BalancePendingDebitIns 
			@BalancePending = @tblDebitPending
			,@Type			= 1 -- Sports
	
	-- end capture

	--transid is auto settled
	SELECT @SettledMainTranIds = ''
	SELECT  @SettledMainTranIds = @SettledMainTranIds + ',' + CONVERT(VARCHAR(20), transid) 
	FROM	@tblMatchIds

	SET @SettledMainTranIds = STUFF(@SettledMainTranIds,1,1,'')

	IF @UserID IN (SELECT a.custid FROM DBPOLICY.bodb02.dbo.accCustomer_1 a WHERE a.GroupID = 1)
		SELECT @IsITAdmin = 1

	SELECT	CASE WHEN c.currency <> 20 AND @IsITAdmin = 1 THEN 1 ELSE 0 END AS IsITSupport -- Recover real tickets by IT ==> Send mail with recipient list "IT Support"
			,CASE WHEN c.currency <> 20 OR (c.currency = 20 AND @IsITAdmin = 0 )THEN 1 ELSE 0 END AS IsCSD --Recover real tickets => send mail to CSD , Recover UUS tickets by CSD: send mail CSD
			,CASE WHEN c.currency = 20 AND @IsITAdmin = 1 THEN 1 ELSE 0 END AS IsITQA -- Recover UUS tickets by IT => Send mail with recipient list "IT QA"
			,CASE
				WHEN f.CustID IS NULL
					AND b.username <> '12EU'
					AND NOT EXISTS (SELECT TOP 1 1 FROM custDB.dbo.Dep_CustSuper WITH(NOLOCK) WHERE custid = b.srecommend)
					AND b.mrecommend NOT IN (105181, 118473, 105183) -- MHC
					AND b.recommend NOT IN (11196380, 13423967, 52466) -- Foobet, 1E, 8RM
					AND b.custid NOT IN (1077687,2331,115770,15523642,15042477,16041068,16041058)
						THEN 'Normal' --1. For Normal bets
				WHEN b.recommend = 52466
						THEN '8RM' ----2: For 8RM
				WHEN f.CustID IS NULL -- Betdaq
					AND b.username <> '12EU' 
					--AND EXISTS (select TOP 1 1 from custDB.dbo.Dep_CustSuper with(nolock) WHERE custid = b.srecommend)
					AND b.mrecommend NOT IN (105181, 118473, 105183)
					AND b.recommend NOT IN (11196380, 13423967, 52466) -- Foobet: 11196380, 1E: 13423967, 8RM: 52466
					AND b.custid NOT IN (1077687,2331,115770,15523642,15042477,16041068,16041058) -- Betfair: BFOS, BF, ITibc102, BF3
						THEN 'Deposit' ----3. For Deposit bets
				WHEN t.custid IN (1077687,2331,115770,15523642,15042477,16041068,16041058) -- Betfair: BFOS, BF, ITibc102, BF3
						THEN 'Betfair' ----8: For Betfair
			END AS GroupName    
			,b.transid    
			,b.Username
			,TransDate     
			,BetType    
			,b.Refno     
			,Status     
			,WinLost    
			,betid      
			,BetTeam    
			,livehomescore    
			,liveawayscore    
			,Stake     
			,Odds     
			,OddsType    
			,hdp1     
			,hdp2     
			,NULL AS homeid      
			,NULL AS awayid      
			,NULL AS sporttype     
			,NULL AS leagueid     
			,betcheck    
			,transdesc   
			,'' AS BetFrom
			,GETDATE() AS [DateTime] 
	FROM	#tblRecoverBet t
			INNER JOIN bettrans b WITH (NOLOCK) ON b.transid = t.transid
			INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON c.custid = b.srecommend
			LEFT JOIN dbo.f_GetBetDaqCustomer(1) f ON t.custid = f.CustID	

	DELETE	z
	FROM	dbo.zzzbettrans z WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #tblRecoverBet t  ON	z.custid = t.custid AND z.matchid = t.matchid AND z.transid = t.transid
		
	
	SELECT @LogData =	'NAP_BettransRecoverParlayBet_Main: Recover bet have transid: ' + @TransIds + ' IP: ' + @IP
						
	EXEC WriteLog_UserLog 
	     @UserId = @UserId,
	     @Doing = @LogData 
	
	------ release Parlay procesee	
	UPDATE systemSettings WITH (ROWLOCK, UPDLOCK)
	    SET VValue = '0'
    WHERE VName = 'isCalculatingParlay'

END

GO
GRANT EXECUTE ON [dbo].[NAP_BettransRecoverParlayBet_Main] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_BettransRecoverParlayBet_Main] TO [vnteam] AS [dbo]
GO


