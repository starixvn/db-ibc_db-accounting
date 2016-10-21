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
	@SubTransIds		VARCHAR(4000)	= '',
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
	
	DECLARE @beforeDaysNum INT = 3
	
	DECLARE @before_yesterday DATETIME	
		   ,@isExistMatch		BIT = 1
		   ,@isExistMG			BIT = 0
		   ,@isExistBT			BIT = 0
		   ,@avaiableProcess	BIT	= 0
		   ,@MatchDate			DATETIME
		   ,@transids_29 VARCHAR(MAX) = ''
		   ,@refnos_29	 VARCHAR(MAX) = ''
		   ,@LogData			NVARCHAR(500)
	
	DECLARE @tblRecoverBet TABLE (
		SubTransID				BIGINT		 
		,SubBetCheck			NVARCHAR(50)
		,SubOdds				MONEY   
		,SubBetTeam				NVARCHAR(20)  
		,SubBetType				INT  
		,SubHdp1				SMALLMONEY   
		,SubHdp2				SMALLMONEY
		,matchid				INT	
					
		,statuswinlost			TINYINT
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
	DECLARE @tblSubTransIds TABLE (transid BIGINT)	
	DECLARE @tblMainTicket		TABLE (transid			BIGINT
										,refno			BIGINT
										,winlost		MONEY
										,Status			NVARCHAR(10)
										,bettype		SMALLINT
								)
	DECLARE @tblSettledBeforeRecoveredMainTicket TABLE (transid	BIGINT)							
	DECLARE @tblBeforeBalance	TABLE (custid INT, balance MONEY)
	DECLARE @tblAfterBalance	TABLE (custid INT, balance MONEY)
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
		INSERT INTO @tblSubTransIds
		SELECT ss.val
		FROM dbo.strSplit(@SubTransIds, ',') ss				
		
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
										
				,statuswinlost
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
								
				,b.statuswinlost AS statuswinlost
				,b.custid AS custid
				,case when EXISTS (select TOP 1 1 from custDB.dbo.Dep_CustSuper with(nolock) WHERE custid = b.srecommend) then 1 else 0 end AS isdeposit
				,b.mrecommend AS mrecommend
				,b.recommend AS recommend
				,b.srecommend AS srecommend
				,b.transid AS transid
				,b.Username AS UserName
				,b.transdate AS TransDate	
				,b.bettype AS BetType	
				,bm.refno AS Refno	
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
		FROM @tblSubTransIds t
			INNER JOIN bettransm bm WITH (NOLOCK)
					ON t.transid = bm.transid
			INNER JOIN dbo.bettrans b WITH (NOLOCK)
					ON bm.refno	= b.refno	   							
			INNER JOIN dbo.match m WITH(NOLOCK)
					ON	m.matchid = bm.matchid			   
		WHERE	b.bettype = 29	
				AND bm.statusid = 102
				AND b.winlostdate >= @before_yesterday
				AND (m.sporttype BETWEEN 1 AND 99 OR m.sporttype = 154)	
				
		IF @@ROWCOUNT = 0
		BEGIN
			------ release Parlay procesee	
			UPDATE systemSettings WITH (ROWLOCK, UPDLOCK)
				SET VValue = '0'
			WHERE VName = 'isCalculatingParlay'
			
			SELECT @ErrCode = 99, @ErrMsg = 'No ticket found.'
			RETURN
		END								
		
		INSERT INTO @tblMainTicket (transid, refno, winlost, Status, bettype)
		SELECT DISTINCT b.transid, b.refno, b.winlost, b.status, b.bettype
		FROM	@tblRecoverBet t
			INNER JOIN dbo.bettrans b WITH(NOLOCK)
				ON	t.refno = b.refno
		WHERE	b.matchid IN (29)
				AND b.bettype IN (29)
				
		INSERT INTO @tblSettledBeforeRecoveredMainTicket(transid)
		SELECT transid
		FROM @tblMainTicket
		WHERE [Status] IN ('WON', 'LOSE', 'DRAW')
				
		SELECT  @MatchDate = eventdate
		FROM	dbo.match WITH(NOLOCK)
		WHERE	matchid = @matchid				
			
		--> capture @tblBeforeBalance
		INSERT INTO @tblBeforeBalance (custid, balance)
		SELECT	b.custid
				,SUM (b.winlost - b.actual_stake + b.playercomm) balance
		FROM	bettrans b WITH (NOLOCK)
			INNER JOIN @tblMainTicket t 
				ON	b.transid = t.transid
		WHERE	b.matchid IN (29) 
				AND b.bettype IN(29)
		GROUP BY b.CustID
				  
		--> Do recover
		-- for bettransM
		EXEC dbo.NAP_Admin_Calculate_MP_broker
		@matchid = @matchid
		,@matchdate = @MatchDate
		,@mode = 'RECOVER' -- update bettransM + BetParlayDetail
		,@VoidTransID = @SubTransIds
		
		-- for bettrans
		UPDATE bettrans
		SET statusid = 0
			,status = 'running'
		WHERE transid IN (SELECT transid FROM @tblMainTicket)
		
		SELECT @transids_29 = @transids_29 + CONVERT(VARCHAR(20), transid) + ','
			 , @refnos_29 = @refnos_29 + refno + '|' + CONVERT(VARCHAR(20), transid) + ','
		FROM @tblMainTicket
		
		-- betparlaydetail/betparlayresult
		-- call pre-cal		
		EXEC dbo.NAP_Admin_Calculate_MP_broker 
			@matchid	= @MatchId
			,@matchdate = @MatchDate
			,@strXML	= @transids_29
			,@mode		= 'PRECAL-29'
			
		-- re-settle for main ticket
		-- call cal_29	
		EXEC dbo.NAP_Admin_Calculate_MP_broker
			@matchdate = @MatchDate
			,@strXML	= @refnos_29  -- main transid + refno: refno|transid,refno|transid...
			,@mode		= '29' 
		
		--> capture @tblAfterBalance
		INSERT INTO @tblAfterBalance (custid, balance)
		SELECT	b.custid
				,SUM (b.winlost - b.actual_stake + b.playercomm) balance
		FROM	bettrans b WITH (NOLOCK)
			INNER JOIN @tblMainTicket t 
				ON	b.transid = t.transid
		WHERE	b.matchid IN(29)
				AND b.bettype IN(29)
		GROUP BY b.CustID
		
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
		SELECT @LogData = 'Recover Parlay bets having transid: ' + @transids_29 + ' IP=' + @Ip
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
				@ErrMsg = 'Invalid TransIds'
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
			 
			 ,CASE
					WHEN f.CustID IS NULL
						AND t.username <> '12EU'
						AND t.IsDeposit = 0
						AND t.mrecommend NOT IN (105181, 118473, 105183) -- MHC
						AND t.recommend NOT IN (11196380, 13423967, 52466) -- Foobet, 1E, 8RM
						AND t.custid NOT IN (1077687,2331,115770,15523642,15042477,16041068,16041058)
							THEN 'Normal' --1. For Normal bets
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
			  END AS GroupName    
			 
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
			
	------ release Parlay procesee	
	UPDATE systemSettings WITH (ROWLOCK, UPDLOCK)
		SET VValue = '0'
	WHERE VName = 'isCalculatingParlay'
		
	RETURN;							
END

