USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_BettransRecoverParlayBet_Sub]    Script Date: 10/20/2016 17:53:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_BettransRecoverParlayBet_Sub] 
	@UserId				INT,	
	@IP					VARCHAR(50),
	@BetType			VARCHAR(20)		= 'All',
	@MainTransIds		VARCHAR(4000)	= '',
	@matchid			BIGINT,
	
	@SettledMainTranIds	VARCHAR(4000) OUTPUT,
	@ErrCode			INT	OUTPUT,
	@ErrMsg				NVARCHAR(200) OUTPUT
AS
/*
	Created: Kent
	Date: 20161019
	DB: DBTXN/bodb02

	Revisions: 		
		- 20161019@Kent: Recover sub voided Parlay tickets [Redmine:#65531]
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @beforeDaysNum INT = 2
	
	DECLARE @before_yesterday	DATETIME		   
		   ,@MatchDate			DATETIME
		   ,@transids_29		VARCHAR(MAX) = ''
		   ,@refnos_29			VARCHAR(MAX) = ''
		   ,@LogData			NVARCHAR(500)
		   ,@SubTransIds		VARCHAR(4000) = ''
	
	DECLARE @tblRecoverBet TABLE (
		SubTransID				BIGINT		 
		,SubBetCheck			NVARCHAR(50)
		,SubOdds				MONEY   
		,SubBetTeam				NVARCHAR(20)  
		,SubBetType				INT  
		,SubHdp1				SMALLMONEY   
		,SubHdp2				SMALLMONEY
		,matchid				INT	
		
		,balance				MONEY					
		,custid					INT
		,isdeposit				TINYINT
		,mrecommend				INT
		,recommend				INT
		,srecommend				INT
		,transid				BIGINT
		,UserName				VARCHAR(30)
		,TransDate				DATETIME 
		,BetType				SMALLINT
		,Refno					BIGINT
		,Status					NVARCHAR(10)
		,StatusId				TINYINT
		,WinLost				MONEY
		,betid					BIGINT 
		,BetTeam				NVARCHAR(20)
		,livehomescore			SMALLINT 
		,liveawayscore			SMALLINT 
		,Stake					MONEY
		,Odds					MONEY
		,OddsType				TINYINT
		,hdp1					SMALLMONEY
		,hdp2					SMALLMONEY
		,betfrom				NVARCHAR(1)
		,homeid					INT 
		,awayid					INT 
		,sporttype				SMALLINT 
		,leagueid				INT 
		,betcheck				NVARCHAR(50)
		,transdesc				NVARCHAR(200)
	)	
	
	CREATE TABLE #tblMainTicket 
	(
		transid		BIGINT
	   ,refno		BIGINT	   
	   ,StatusId	TINYINT	   
	   ,custid		INT
	   ,balance		MONEY
	)
	CREATE CLUSTERED INDEX IDX_tblMainTicket_custid_transid ON #tblMainTicket(custid, transid)
	
	DECLARE @tblMainTransIds TABLE (transid BIGINT)
	
	DECLARE @tblSettledBeforeRecoveredMainTicket TABLE (transid	BIGINT)
								
	DECLARE @tblBeforeBalance TABLE (custid INT PRIMARY KEY, balance MONEY)
	
	DECLARE @tblAfterBalance TABLE (custid INT PRIMARY KEY, balance MONEY)
	
	DECLARE @tblDebitPending TVP_BalanceList
	
	DECLARE @tblCreditPending TVP_BalanceList		
	
	SELECT @before_yesterday = CONVERT(VARCHAR(10), DATEADD(day, - @beforeDaysNum, GETDATE()), 120)
		  ,@ErrCode = 0
		  ,@ErrMsg = ''
		  
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
	
	BEGIN TRY
		--> parse @MainTransIds
		INSERT INTO @tblMainTransIds(transid)
		SELECT ss.val AS transid
		FROM dbo.strSplit(@MainTransIds, ',') ss
		
		IF @@ROWCOUNT = 0
		BEGIN
			------ release Parlay procesee	
			UPDATE systemSettings WITH (ROWLOCK, UPDLOCK)
				SET VValue = '0'
			WHERE VName = 'isCalculatingParlay'
			
			SELECT @ErrCode = 99, @ErrMsg = 'No ticket found.'
			RETURN
		END
			
		--> query all sub tickets to recover
		INSERT INTO @tblRecoverBet(
				 SubTransID			 
				,SubBetCheck	
				,SubOdds
				,SubBetTeam	
				,SubBetType
				,SubHdp1		
				,SubHdp2
				,matchid
				
				,balance										
				,custid
				,isdeposit
				,mrecommend				
				,recommend	
				,srecommend			
				,transid
				,UserName
				,TransDate	
				,BetType	
				,Refno	
				,Status
				,StatusId
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
				,betfrom
				,homeid	
				,awayid 
				,sporttype 
				,leagueid 
				,betcheck
				,transdesc)
		SELECT  bm.transid AS SubTransID			 
				,bm.betcheck AS SubBetCheck	
				,bm.odds AS SubOdds
				,bm.betteam AS SubBetTeam	
				,bm.bettype AS SubBetType
				,bm.hdp1 AS SubHdp1		
				,bm.hdp2 AS SubHdp2	
				,bm.matchid AS matchid	
				
				,b.winlost - b.actual_stake + b.playercomm AS balance								
				,b.custid AS custid
				,case when EXISTS (select TOP 1 1 from custDB.dbo.Dep_CustSuper with(nolock) WHERE custid = b.srecommend) then 1 else 0 end AS isdeposit
				,b.mrecommend AS mrecommend
				,b.recommend AS recommend
				,b.srecommend AS srecommend
				,b.transid AS transid
				,b.Username AS UserName
				,b.transdate AS TransDate	
				,b.bettype AS BetType	
				,b.refno AS Refno	
				,b.[status] AS [Status]
				,b.statusID AS StatusId
				,b.winlost-b.actual_stake AS WinLost
				,b.betid AS betid	
				,b.betteam AS BetTeam
				,b.livehomescore AS livehomescore 
				,b.liveawayscore AS liveawayscore 
				,b.stake AS Stake	
				,b.odds AS Odds
				,b.OddsType AS OddsType
				,b.hdp1 AS hdp1
				,b.hdp2 AS hdp2
				,b.betfrom AS betfrom
				,m.homeid AS homeid	
				,m.awayid AS awayid 
				,m.sporttype AS sporttype 
				,m.leagueid AS leagueid 
				,b.betcheck AS betcheck
				,bm.transdesc AS transdesc
		FROM @tblMainTransIds t
			INNER JOIN dbo.bettrans b WITH (NOLOCK)
					ON t.transid = b.transid
			INNER JOIN bettransm bm WITH (NOLOCK)
					ON bm.refno	= b.refno	   							
			INNER JOIN dbo.match m WITH(NOLOCK)
					ON	bm.matchid = m.matchid
		WHERE bm.matchid = @MatchId
		  AND b.bettype = 29	
		  AND bm.statusid = 102
		  AND b.winlostdate >= @before_yesterday
		  AND (b.betfrom IS NULL OR b.betfrom <> 'p')
		  AND (m.sporttype BETWEEN 1 AND 99 OR m.sporttype = 154)
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
			
			SELECT @ErrCode = 99, @ErrMsg = 'No ticket found.'
			RETURN
		END										
	
		--> get list of MainTranIds	
		INSERT INTO #tblMainTicket(transid
								 , refno								 
								 , StatusId								 
								 , custid
								 , balance)
		SELECT t.transid
			 , t.refno			 
			 , t.StatusId			 
			 , t.custid
			 , t.balance
		FROM @tblRecoverBet t		
		
		--> capture list of settled main transIDs before do recover
		INSERT INTO @tblSettledBeforeRecoveredMainTicket(transid)
		SELECT transid
		FROM #tblMainTicket
		WHERE StatusId IN (111, 112, 113) -- 'DRAW', 'WON', 'LOSE'
				
		SELECT  @MatchDate = eventdate
		FROM	dbo.match WITH(NOLOCK)
		WHERE	matchid = @matchid				
			
		--> capture @tblBeforeBalance
		INSERT INTO @tblBeforeBalance (custid, balance)
		SELECT	t.custid
				,SUM(t.balance) balance
		FROM #tblMainTicket t					
		GROUP BY t.CustID
				  
		--> Do recover
		-- for bettransM
		SELECT @SubTransIds = @SubTransIds + 
							  CASE WHEN @SubTransIds <> '' THEN ',' ELSE '' END +
							  CONVERT(VARCHAR(20), SubTransID)
		FROM @tblRecoverBet
		
		EXEC dbo.NAP_Admin_Calculate_MP_broker
			@matchid = @matchid
			,@matchdate = @MatchDate
			,@mode = 'RECOVER' -- update bettransM + BetParlayDetail
			,@VoidTransID = @SubTransIds				
		
		SELECT @transids_29 = @transids_29 + CONVERT(VARCHAR(20), transid) + ','
			 , @refnos_29 = @refnos_29 + CONVERT(VARCHAR(20), refno) + '|' + CONVERT(VARCHAR(20), transid) + ','
		FROM #tblMainTicket
			
		-- call pre-cal: betparlaydetail/betparlayresult		
		EXEC dbo.NAP_Admin_Calculate_MP_broker 
			@matchid	= @MatchId
			,@matchdate = @MatchDate
			,@strXML	= @transids_29
			,@mode		= 'PRECAL-29'
				
		-- call cal_29: re-settle for main ticket
		EXEC dbo.NAP_Admin_Calculate_MP_broker
			@matchdate = @MatchDate
			,@strXML	= @refnos_29  -- main transid + refno: refno|transid,refno|transid...
			,@mode		= '29' 
		
		--> capture @tblAfterBalance
		INSERT INTO @tblAfterBalance (custid, balance)
		SELECT	t.custid
				,SUM (b.winlost - b.actual_stake + b.playercomm) balance
		FROM #tblMainTicket t	
			INNER JOIN bettrans b WITH (NOLOCK) 
				ON t.transid = b.transid		
		GROUP BY t.CustID
		
		--> update credit balance of cust
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

		--> update dedit balance of cust
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
				
		DELETE	z
		FROM	dbo.zzzbettrans z WITH(ROWLOCK, UPDLOCK)
			INNER JOIN @tblRecoverBet t 
				ON	z.custid = t.custid
					AND z.matchid = t.matchid
					AND z.transid = t.SubTransID
		
		DELETE	zm
		FROM	dbo.zzzbettransm zm WITH(ROWLOCK, UPDLOCK)
			INNER JOIN @tblRecoverBet t 
				ON	zm.custid = t.custid
					AND zm.matchid = t.matchid
					AND zm.transid = t.SubTransID				
				
		--> Build list of changed status main transids, exclude full-lose
		SET @SettledMainTranIds = ''
		SELECT @SettledMainTranIds = @SettledMainTranIds + 
									 CASE WHEN @SettledMainTranIds <> '' THEN ',' ELSE '' END +
									 CONVERT(VARCHAR(20), t.transid)
		FROM @tblSettledBeforeRecoveredMainTicket t			 
			 INNER JOIN dbo.bettrans b WITH(NOLOCK)
					 ON t.transid = b.transid
		WHERE b.statusID = 0				
		
		--> write log		
		SELECT @LogData = 'Recover Parlay bets having transid: IP=' + @Ip + ' ' + @transids_29
		EXEC WriteLog_UserLog 
			 @UserId = @UserId,
			 @Doing = @LogData 
	END TRY
	BEGIN CATCH
		------ release Parlay procesee	
		UPDATE systemSettings WITH (ROWLOCK, UPDLOCK)
			SET VValue = '0'
		WHERE VName = 'isCalculatingParlay'
	
		SELECT @ErrCode = 100,
				@ErrMsg = 'Recover Parlay failed with error : Unable to recover these parlay bets: list of bet id ' 
						  + @MainTransIds 
						  + ' Recover failed due to this error'
		RETURN				
	END CATCH		 								
	
	--> Data for sending mail: Rule R1 + Rule R2 + Rule R3 + Rule R4
	SELECT	t.SubTransID     
			 ,t.SubBetCheck  
			 ,t.SubOdds      
			 ,t.SubBetTeam  
			 ,t.SubBetType     
			 ,t.SubHdp1       
			 ,t.SubHdp2     
			 
			 ,T1.GroupName    
			 
			 ,t.transid    
			 ,t.UserName    
			 ,t.TransDate     
			 ,t.BetType    
			 ,t.Refno     
			 ,t.[Status]     
			 ,t.WinLost    
			 ,t.betid     
			 ,t.BetTeam    
			 ,t.livehomescore   
			 ,t.liveawayscore   
			 ,t.Stake     
			 ,t.Odds     
			 ,t.OddsType    
			 ,t.hdp1     
			 ,t.hdp2     
			 ,t.homeid     
			 ,t.awayid     
			 ,t.sporttype    
			 ,t.leagueid    
			 ,t.betcheck    
			 ,t.transdesc  
			 ,CASE
				WHEN EXISTS (SELECT 1 FROM CustDB.dbo.Customer c WITH(NOLOCK) WHERE c.currency <> 20 AND c.roleid = 4 AND c.custid = t.srecommend)
					 OR (EXISTS (SELECT 1 FROM CustDB.dbo.Customer c WITH(NOLOCK) WHERE c.currency = 20 AND c.roleid = 4 AND c.custid = t.srecommend)
						AND @UserID NOT IN (SELECT a.custid FROM DBPOLICY.bodb02.dbo.accCustomer_1 a WHERE a.GroupID = 1) -- Check UserID not in IT group
						)
							THEN CAST(1 AS BIT)
				ELSE CAST(0 AS BIT)
			  END AS IsCsd
			 ,CASE
				WHEN EXISTS (SELECT 1 FROM CustDB.dbo.Customer c WITH(NOLOCK) WHERE c.currency = 20 AND c.roleid = 4 AND c.custid = t.srecommend)
					 AND @UserID IN (SELECT a.custid FROM DBPOLICY.bodb02.dbo.accCustomer_1 a WHERE a.GroupID = 1)
							THEN CAST(1 AS BIT)
				ELSE CAST(0 AS BIT)
			  END AS IsItQa
			 ,CASE
				WHEN EXISTS (SELECT 1 FROM CustDB.dbo.Customer c WITH(NOLOCK) WHERE c.currency <> 20 AND c.roleid = 4 AND c.custid = t.srecommend)
					 AND @UserID IN (SELECT a.custid FROM DBPOLICY.bodb02.dbo.accCustomer_1 a WHERE a.GroupID = 1)
							THEN CAST(1 AS BIT)
				ELSE CAST(0 AS BIT)							
			  END AS IsItSupport
			 ,t.betfrom AS BetFrom
			 ,CURRENT_TIMESTAMP AS [DateTime]
	FROM	@tblRecoverBet t		
		LEFT JOIN dbo.f_GetBetDaqCustomer(1) f
			ON t.custid = f.CustID
		CROSS APPLY (SELECT CASE
								WHEN f.CustID IS NULL
									AND t.username <> '12EU'
									AND t.IsDeposit = 0
									AND t.mrecommend NOT IN (105181, 118473, 105183) -- MHC
									AND t.recommend NOT IN (11196380, 13423967, 52466) -- Foobet, 1E, 8RM
									AND t.custid NOT IN (1077687,2331,115770,15523642,15042477,16041068,16041058)
										THEN 'Credit' --1. For Normal bets
								WHEN t.recommend = 52466
										THEN '8RM' ----2: For 8RM
								WHEN f.CustID IS NULL -- Betdaq
									AND t.username <> '12EU' 
									AND t.IsDeposit = 1	
									AND t.mrecommend NOT IN (105181, 118473, 105183)
									AND t.recommend NOT IN (11196380, 13423967, 52466) -- Foobet: 11196380, 1E: 13423967, 8RM: 52466
									AND t.custid NOT IN (1077687,2331,115770,15523642,15042477,16041068,16041058) -- Betfair: BFOS, BF, ITibc102, BF3
										THEN 'Deposit' ----3. For Deposit bets
								WHEN t.custid IN (1077687,2331,115770,15523642,15042477,16041068,16041058) -- Betfair: BFOS, BF, ITibc102, BF3
										THEN 'Betfair' ----8: For Betfair
								ELSE NULL										
						  END AS GroupName) AS T1
	WHERE T1.GroupName IS NOT NULL						  			
			
	------ release Parlay procesee	
	UPDATE systemSettings WITH (ROWLOCK, UPDLOCK)
		SET VValue = '0'
	WHERE VName = 'isCalculatingParlay'
		
	RETURN;							
END
GO

GRANT EXECUTE ON [dbo].[NAP_BettransRecoverParlayBet_Sub] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_BettransRecoverParlayBet_Sub] TO [vnteam] AS [dbo]
GO


