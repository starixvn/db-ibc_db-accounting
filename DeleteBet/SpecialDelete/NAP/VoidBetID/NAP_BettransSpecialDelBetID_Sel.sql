ALTER PROCEDURE [dbo].[NAP_BettransSpecialDelBetID_Sel] 
	 @CustID	INT			= NULL 	
	,@TransID	BIGINT		= NULL 
	,@FromDate	DATETIME	= NULL
	,@ToDate	DATETIME	= NULL 
AS
/*  
	Created by: Jamie  
	Date: 20140908  
	Task: Get tickets by Bet ID/CustID : 
		  Normal SB, Outright, Mix Parlay (Allow to delete Running & Refunded), NG, and Live Casino 
	DB: DBTXN/bodb02   
	Original:     

	Revisions:  
		- 20150402@Dominic: Add new 60 bettypes [Redmine:#27214]
		- 20150611@Dominic: BetTrade Integration [Redmine:#36964]
		- 20150623@Dominic: Add Metric Gaming Super Live [Redmine:##38200]
		- 20151021@Kathy: Do not show ticket 901 if its owner is not BetTrade account(betdaqid = 0)[Redmine:#43233]
		- 20151102@Kathy: Enhance performance [Redmine:#43233]
		- 20150712@Kathy: Database - Change datatype [Redmine: #48660]
		
	Param's Explanation:
		+ @CustID NOT NULL: Search by CustID
		+ @TransID NOT NULL: Search by TransID

	*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #Data (
		GroupID			BIGINT
		,bettype		INT
		,transid		BIGINT PRIMARY KEY
		,betid			BIGINT
		,refno			BIGINT
		,matchcode		NVARCHAR(50)
		,homeid			INT
		,awayid			INT
		,hdp1			SMALLMONEY
		,hdp2			SMALLMONEY
		,odds			MONEY
		,finalodds		MONEY
		,finalodds2		MONEY
		,OddsType		TINYINT
		,STATUS			NVARCHAR(50)
		,comstatus		NVARCHAR(50)
		,stake			MONEY
		,transdate		DATETIME
		,betteam		NVARCHAR(10)
		,betcheck		NVARCHAR(50)
		,liveindicator	BIT
		,modds			MONEY
		,custid			INT
		,username		VARCHAR(30)
		,livehomescore	INT
		,liveawayscore	INT
		,leagueid		INT
		,sporttype		SMALLINT
		,betfrom		NVARCHAR(1)
		,matchid		INT
		,isNeutral		BIT
		,winlost		MONEY
		,commission		MONEY
		,showtime		NVARCHAR(50)
		,winlostdate	SMALLDATETIME
		,TransDesc		NVARCHAR(300)
		,betdaqid		BIGINT
		,SoldId			BIGINT
		)
		
	CREATE TABLE #DetailData (
		refno			BIGINT
		,odds			MONEY
		,stake			MONEY
		,STATUS			NVARCHAR(50)
		,bettype		SMALLINT
		,betteam		NVARCHAR(50)
		)

	--Search by TransID 
	IF @CustID IS NULL 
	BEGIN 
	
		SELECT	@FromDate = CONVERT(VARCHAR(10),CURRENT_TIMESTAMP - 3,120)		-- As defined, only get data within 3 days 
		
		-- MG tickets <> running in bettrans
		INSERT INTO #Data (
				GroupID			
				,bettype		
				,transid		
				,betid			
				,refno					
				,hdp1			
				,hdp2			
				,odds			
				,finalodds		
				,finalodds2		
				,OddsType		
				,STATUS			
				,comstatus		
				,stake						
				,transdate		
				,betteam		
				,betcheck		
				,liveindicator	
				,modds			
				,custid						
				,livehomescore	
				,liveawayscore					
				,betfrom		
				,matchid					
				,winlost		
				,commission					
				,winlostdate	
				,TransDesc		
				,betdaqid		
		)
		SELECT	b.refno AS GroupId
				,b.bettype
				,b.refno AS transid
				,isnull(b.BetID, 0) AS BetID
				,b.refno		
				,b.hdp1
				,b.hdp2
				,b.odds
				,0 finalodds
				,0 finalodds2
				,b.OddsType
				,CASE 
					WHEN b.STATUS = 'running'
						AND IsNull(b.SecAcceptFlag, 0) = 1
						AND IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
					ELSE b.STATUS
					END AS STATUS
				,CASE 
					WHEN b.comstatus = '1' THEN 1
					ELSE 0
					END AS comstatus
				,b.stake				
				,b.transdate
				,b.betteam
				,b.betcheck
				,b.liveindicator
				,b.modds
				,b.custid		
				,b.livehomescore
				,b.liveawayscore			
				,b.betfrom
				,b.matchid			
				,(b.winlost - b.actual_stake) winlost
				,b.playercomm AS commission		
				,b.winlostdate
				,b.transdesc
				,b.betdaqid
		FROM	bettrans AS b WITH (NOLOCK)
			INNER JOIN dbo.translog tl WITH(NOLOCK)
				ON	b.refno = tl.translogid
					AND b.matchid = tl.eventID
		WHERE	b.bettype IN (801,803,804,805,806)
				AND tl.translogid = @TransId
				AND b.winlostdate >=@FromDate
				AND b.statusID NOT IN (0, 101, 102)	-- RUNNING, REJECT, VOID 
		
		-- MG tickets running in translog
		INSERT INTO #Data(
				GroupID			
				,bettype		
				,transid		
				,betid			
				,refno	
				,hdp1			
				,hdp2			
				,odds			
				,finalodds		
				,finalodds2		
				,OddsType		
				,STATUS			
				,comstatus		
				,stake							
				,transdate		
				,betteam		
				,betcheck		
				,liveindicator	
				,modds			
				,custid						
				,livehomescore	
				,liveawayscore					
				,betfrom		
				,matchid					
				,winlost		
				,commission					
				,winlostdate	
				,TransDesc		
				,betdaqid		
		)
		SELECT	b.translogID GroupID
				,b.GameID
				,b.translogID as transid
				,0 AS BetID
				,b.translogID refno	
				,0 hdp1
				,0 hdp2
				,b.odds
				,0 finalodds
				,0 finalodds2
				,b.custom1 OddsType
				,b.STATUS
				,b.custom2 comstatus
				,b.stake				
				,b.transdate
				,NULL betteam
				,NULL betcheck
				,b.liveindicator liveindicator
				,NULL modds
				,b.custid
				,NULL livehomescore
				,NULL liveawayscore				
				,b.betfrom
				,b.EventID				
				,- b.actual_stake as winlost
				,0 AS commission			
				,b.winlostdate
				,b.transdesc
				,-1 -- normal ticket
		FROM	translog AS b WITH (NOLOCK)
		WHERE	b.translogid = @TransID 
				AND b.winlostdate >=@FromDate
				AND b.GameID IN (801, 803, 804, 805, 806) 
				AND b.statusID = 0
			
		-- Normal tickets	
		INSERT INTO #Data (
				GroupID			
				,bettype		
				,transid		
				,betid			
				,refno		
				,hdp1			
				,hdp2			
				,odds			
				,finalodds		
				,finalodds2		
				,OddsType		
				,STATUS			
				,comstatus		
				,stake							
				,transdate		
				,betteam		
				,betcheck		
				,liveindicator	
				,modds			
				,custid						
				,livehomescore	
				,liveawayscore					
				,betfrom		
				,matchid					
				,winlost		
				,commission					
				,winlostdate	
				,TransDesc		
				,betdaqid		
		)
		SELECT	b.transid AS GroupId
				,b.bettype
				,b.transid AS transid		
				,isnull(b.BetID, 0) AS BetID
				,b.refno			
				,b.hdp1
				,b.hdp2
				,b.odds
				,0 finalodds
				,0 finalodds2
				,b.OddsType
				,CASE 
					WHEN b.STATUS = 'running'
						AND IsNull(b.SecAcceptFlag, 0) = 1
						AND IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
					ELSE b.STATUS
					END AS STATUS
				,CASE 
					WHEN b.comstatus = '1' THEN 1
					ELSE 0
					END AS comstatus
				,b.stake				
				,b.transdate
				,b.betteam
				,b.betcheck
				,b.liveindicator
				,b.modds
				,b.custid
				,b.livehomescore
				,b.liveawayscore				
				,b.betfrom
				,b.matchid				
				,(b.winlost - b.actual_stake) winlost
				,b.playercomm AS commission				
				,b.winlostdate
				,b.transdesc
				,b.betdaqid
		FROM	bettrans AS b WITH (NOLOCK)
			INNER JOIN dbo.match m WITH(NOLOCK)
				ON b.matchid = m.matchid
		WHERE	b.transid = @TransId
				AND b.winlostdate >=@FromDate				
				AND b.bettype < 19001
				AND b.bettype NOT IN (10,31, 32, 33, 71,72,73,10, 801, 803, 804, 805, 806, 901, 902, 903)	-- NOT IN Racing, Outright, VS, MG, BT sub ticket
				AND b.bettype NOT BETWEEN 1201 AND 1299					-- NOT VS
				AND b.bettype NOT BETWEEN 1501 AND 1599					-- NOT IN Keno 
				AND b.statusID NOT IN (101, 102)	-- REJECT, VOID 
	
		-- Parlay ticket
		INSERT INTO #Data (				
				GroupID			
				,bettype		
				,transid		
				,betid			
				,refno			
				,matchcode	
				,homeid			
				,awayid		
				,hdp1			
				,hdp2			
				,odds			
				,finalodds		
				,finalodds2		
				,OddsType		
				,STATUS			
				,comstatus		
				,stake							
				,transdate		
				,betteam		
				,betcheck		
				,liveindicator	
				,modds			
				,custid			
				,username		
				,livehomescore	
				,liveawayscore	
				,leagueid		
				,sporttype		
				,betfrom		
				,matchid		
				,isNeutral		
				,winlost		
				,commission		
				,showtime		
				,winlostdate	
				,TransDesc		
				,betdaqid			
		)
		SELECT 
				b.transid GroupID
				,9 bettype
				,b.transid
				,isnull(b.BetID, 0) AS BetID
				,b.refno
				,'' matchcode
				,0 AS homeid
				,0 AS awayid
				,b.hdp1
				,b.hdp2
				,b.odds
				,0 finalodds
				,0 finalodds2
				,'' OddsType
				,b.STATUS
				,CASE 
					WHEN b.comstatus = '1' THEN 1
					ELSE 0
					END AS comstatus
				,b.stake				
				,b.transdate transdate
				,b.betteam
				,b.betcheck
				,0 liveindicator
				,b.modds
				,b.custid
				,b.username
				,b.livehomescore
				,b.liveawayscore
				,0 AS leagueid
				,0 AS sporttype
				,b.betfrom
				,0 matchid
				,CONVERT(BIT, 0) AS IsNeutral
				,(b.winlost - b.actual_stake) winlost
				,b.playercomm AS commission
				,'' AS showtime
				,b.winlostdate
				,b.transdesc
				,b.betdaqid
		FROM	bettrans AS b WITH (NOLOCK)
		WHERE	b.transid = @TransID 
				AND b.winlostdate >=@FromDate
				AND b.matchid = 9
				AND b.bettype = 9
				AND b.statusID NOT IN (101, 102)	-- REJECT, VOID 
				
		-- Outright
		INSERT INTO #Data(
				GroupID			
				,bettype		
				,transid		
				,betid			
				,refno			
				,matchcode	
				,homeid			
				,awayid		
				,hdp1			
				,hdp2			
				,odds			
				,finalodds		
				,finalodds2		
				,OddsType		
				,STATUS			
				,comstatus		
				,stake							
				,transdate		
				,betteam		
				,betcheck		
				,liveindicator	
				,modds			
				,custid			
				,username		
				,livehomescore	
				,liveawayscore	
				,leagueid		
				,sporttype		
				,betfrom		
				,matchid		
				,isNeutral		
				,winlost		
				,commission		
				,showtime		
				,winlostdate	
				,TransDesc		
				,betdaqid	
		)
		SELECT	b.transid GroupID
				,b.bettype
				,b.transid
				,isnull(b.BetID, 0) AS BetID
				,b.refno
				,odds.matchcode
				,0 AS homeid
				,odds.teamid AS awayid
				,b.hdp1
				,b.hdp2
				,b.odds
				,0 finalodds
				,0 finalodds2
				,'' OddsType
				,b.STATUS
				,CASE 
					WHEN b.comstatus = '1' THEN 1
					ELSE 0
					END AS comstatus
				,b.stake				
				,b.transdate transdate
				,b.betteam
				,b.betcheck
				,b.liveindicator
				,b.modds
				,b.custid
				,b.Username
				,b.livehomescore
				,b.liveawayscore
				,odds.leagueid
				,l.sporttype
				,b.betfrom
				,b.matchid
				,CONVERT(BIT, 0) AS IsNeutral
				,(b.winlost - b.actual_stake) winlost
				,b.playercomm AS commission
				,'' AS showtime
				,b.winlostdate
				,b.transdesc
				,b.betdaqid
		FROM	bettrans AS b WITH (NOLOCK)
			INNER JOIN outright AS odds WITH (NOLOCK) 
				ON	b.matchid = odds.orid
			INNER JOIN league l WITH (NOLOCK) 
				ON	odds.leagueid = l.leagueid
		WHERE	b.bettype = 10
				AND b.winlostdate >=@FromDate
				AND b.transid = @TransID 
				AND b.statusID NOT IN (101, 102)	-- REJECT, VOID 
	END
	ELSE --- Search by CustID 
	BEGIN 
		-- MG tickets <> running in bettrans
		INSERT INTO #Data(
				GroupID			
				,bettype		
				,transid		
				,betid			
				,refno		
				,hdp1			
				,hdp2			
				,odds			
				,finalodds		
				,finalodds2		
				,OddsType		
				,STATUS			
				,comstatus		
				,stake								
				,transdate		
				,betteam		
				,betcheck		
				,liveindicator	
				,modds			
				,custid						
				,livehomescore	
				,liveawayscore					
				,betfrom		
				,matchid					
				,winlost		
				,commission					
				,winlostdate	
				,TransDesc		
				,betdaqid		
		)
		SELECT 
				b.refno GroupID
				,b.bettype
				,b.refno  transid
				,isnull(b.BetID, 0) AS BetID
				,b.refno
				,b.hdp1
				,b.hdp2
				,b.odds
				,0 finalodds
				,0 finalodds2
				,b.OddsType
				,CASE 
					WHEN b.STATUS = 'running'
						AND IsNull(b.SecAcceptFlag, 0) = 1
						AND IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
					ELSE b.STATUS
					END AS STATUS
				,CASE 
					WHEN b.comstatus = '1' THEN 1
					ELSE 0
					END AS comstatus
				,stake				
				,b.transdate
				,b.betteam
				,b.betcheck
				,b.liveindicator
				,b.modds
				,b.custid				
				,b.livehomescore
				,b.liveawayscore
				,b.betfrom
				,b.matchid				
				,(b.winlost - b.actual_stake) winlost
				,b.playercomm AS commission				
				,b.winlostdate
				,b.transdesc
				,b.betdaqid
		FROM	bettrans AS b WITH (NOLOCK)
		WHERE	b.custid =@Custid 
				AND b.winlostdate BETWEEN @FromDate AND @ToDate 				
				AND b.bettype IN (801, 803, 804, 805, 806)
				AND b.statusID NOT IN (0, 101, 102)	-- RUNNING, REJECT, VOID 
				
		--MG in translog
		INSERT INTO #Data(
				GroupID			
				,bettype		
				,transid		
				,betid			
				,refno		
				,hdp1			
				,hdp2			
				,odds			
				,finalodds		
				,finalodds2		
				,OddsType		
				,STATUS			
				,comstatus		
				,stake							
				,transdate		
				,betteam		
				,betcheck		
				,liveindicator	
				,modds			
				,custid						
				,livehomescore	
				,liveawayscore					
				,betfrom		
				,matchid					
				,winlost		
				,commission					
				,winlostdate	
				,TransDesc		
				,betdaqid		
		)
		SELECT	b.translogid GroupID
				,b.GameID
				,b.translogid transid
				,0 AS BetID
				,b.translogid refno	
				,0 hdp1
				,0 hdp2
				,b.odds
				,0 finalodds
				,0 finalodds2
				,b.custom1 OddsType
				,b.STATUS
				,b.custom2 comstatus
				,b.stake				
				,b.transdate
				,NULL betteam
				,NULL betcheck
				,b.liveindicator liveindicator
				,NULL modds
				,b.custid			
				,NULL livehomescore
				,NULL liveawayscore				
				,b.betfrom
				,b.EventID				
				,- b.actual_stake as winlost
				,0 AS commission				
				,b.winlostdate
				,b.transdesc
				,-1
		FROM	dbo.translog AS b WITH (NOLOCK)
		WHERE	b.custid = @Custid 
				AND b.winlostdate BETWEEN @FromDate AND @ToDate 
				AND b.GameID IN (801, 803, 804, 805, 806) 
				AND b.statusID = 0
				
		-- Normal tickets
		INSERT INTO #Data(
				GroupID			
				,bettype		
				,transid		
				,betid			
				,refno		
				,hdp1			
				,hdp2			
				,odds			
				,finalodds		
				,finalodds2		
				,OddsType		
				,STATUS			
				,comstatus		
				,stake								
				,transdate		
				,betteam		
				,betcheck		
				,liveindicator	
				,modds			
				,custid						
				,livehomescore	
				,liveawayscore					
				,betfrom		
				,matchid					
				,winlost		
				,commission					
				,winlostdate	
				,TransDesc		
				,betdaqid		
		)
		SELECT 
				b.transid GroupID
				,b.bettype
				,b.transid transid
				,isnull(b.BetID, 0) AS BetID
				,b.refno
				,b.hdp1
				,b.hdp2
				,b.odds
				,0 finalodds
				,0 finalodds2
				,b.OddsType
				,CASE 
					WHEN b.STATUS = 'running'
						AND IsNull(b.SecAcceptFlag, 0) = 1
						AND IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
					ELSE b.STATUS
					END AS STATUS
				,CASE 
					WHEN b.comstatus = '1' THEN 1
					ELSE 0
					END AS comstatus
				,stake				
				,b.transdate
				,b.betteam
				,b.betcheck
				,b.liveindicator
				,b.modds
				,b.custid				
				,b.livehomescore
				,b.liveawayscore
				,b.betfrom
				,b.matchid				
				,(b.winlost - b.actual_stake) winlost
				,b.playercomm AS commission				
				,b.winlostdate
				,b.transdesc
				,b.betdaqid
		FROM	bettrans AS b WITH (NOLOCK)
			INNER JOIN dbo.match m WITH(NOLOCK)
				ON b.matchid = m.matchid
		WHERE	b.custid =@Custid 
				AND b.winlostdate BETWEEN @FromDate AND @ToDate 
				AND b.bettype < 19001
				AND b.bettype NOT IN (10,31, 32, 33, 71,72,73,10, 801, 803, 804, 805, 806, 901,902,903)		-- NOT IN Racing, Outright, VS, MG, BT sub ticket
				AND b.bettype NOT BETWEEN 1201 AND 1299					-- NOT VS
				AND b.bettype NOT BETWEEN 1501 AND 1599					-- NOT IN Keno 
				AND b.statusID NOT IN (101, 102)	-- REJECT, VOID 
				
		-- Parlay tickets
		INSERT INTO #Data(
				GroupID			
				,bettype		
				,transid		
				,betid			
				,refno			
				,matchcode	
				,homeid			
				,awayid		
				,hdp1			
				,hdp2			
				,odds			
				,finalodds		
				,finalodds2		
				,OddsType		
				,STATUS			
				,comstatus		
				,stake							
				,transdate		
				,betteam		
				,betcheck		
				,liveindicator	
				,modds			
				,custid			
				,username		
				,livehomescore	
				,liveawayscore
				,leagueid		
				,sporttype		
				,betfrom		
				,matchid		
				,isNeutral		
				,winlost		
				,commission		
				,showtime		
				,winlostdate	
				,TransDesc		
				,betdaqid			
		)
		SELECT	b.transid GroupID
				,9 bettype
				,b.transid
				,isnull(b.BetID, 0) AS BetID
				,b.refno
				,'' matchcode
				,0 AS homeid
				,0 AS awayid
				,b.hdp1
				,b.hdp2
				,b.odds
				,0 finalodds
				,0 finalodds2
				,'' OddsType
				,b.STATUS
				,CASE 
					WHEN b.comstatus = '1' THEN 1
					ELSE 0
					END AS comstatus
				,b.stake				
				,b.transdate transdate
				,b.betteam
				,b.betcheck
				,0 liveindicator
				,b.modds
				,b.custid
				,b.username
				,b.livehomescore
				,b.liveawayscore
				,0 AS leagueid
				,0 AS sporttype
				,b.betfrom
				,0 matchid
				,CONVERT(BIT, 0) AS IsNeutral
				,(b.winlost - b.actual_stake) winlost
				,b.playercomm AS commission
				,'' AS showtime
				,b.winlostdate
				,b.transdesc
				,b.betdaqid
		FROM	bettrans AS b WITH (NOLOCK)
		WHERE	b.custid =@Custid 
				AND b.winlostdate BETWEEN @FromDate AND @ToDate 
				AND matchid = 9
				AND bettype = 9
				AND b.statusID NOT IN (101, 102)	-- REJECT, VOID 
		
		-- Outright tickets
		INSERT INTO #Data(
				GroupID			
				,bettype		
				,transid		
				,betid			
				,refno			
				,matchcode	
				,homeid			
				,awayid	
				,hdp1			
				,hdp2			
				,odds			
				,finalodds		
				,finalodds2		
				,OddsType		
				,STATUS			
				,comstatus		
				,stake						
				,transdate		
				,betteam		
				,betcheck		
				,liveindicator	
				,modds			
				,custid			
				,username		
				,livehomescore	
				,liveawayscore	
				,leagueid		
				,sporttype		
				,betfrom		
				,matchid		
				,isNeutral		
				,winlost		
				,commission		
				,showtime		
				,winlostdate	
				,TransDesc		
				,betdaqid			
		)
		SELECT	b.transid GroupID
				,b.bettype
				,b.transid
				,isnull(b.BetID, 0) AS BetID
				,b.refno
				,odds.matchcode
				,0 AS homeid
				,odds.teamid AS awayid
				,b.hdp1
				,b.hdp2
				,b.odds
				,0 finalodds
				,0 finalodds2
				,'' OddsType
				,b.STATUS
				,CASE 
					WHEN b.comstatus = '1' THEN 1
					ELSE 0
					END AS comstatus
				,b.stake				
				,b.transdate transdate
				,b.betteam
				,b.betcheck
				,b.liveindicator
				,b.modds
				,b.custid
				,b.Username
				,b.livehomescore
				,b.liveawayscore
				,odds.leagueid
				,l.sporttype
				,b.betfrom
				,b.matchid
				,CONVERT(BIT, 0) AS IsNeutral
				,(b.winlost - b.actual_stake) winlost
				,b.playercomm AS commission
				,'' AS showtime
				,b.winlostdate
				,b.transdesc
				,b.betdaqid
		FROM	bettrans AS b WITH (NOLOCK)
			INNER JOIN outright AS odds WITH (NOLOCK) 
				ON	b.matchid = odds.orid
			INNER JOIN league l WITH (NOLOCK) 
				ON	odds.leagueid = l.leagueid
		WHERE	b.bettype = 10
				AND b.custid =@Custid 
				AND b.winlostdate BETWEEN @FromDate AND @ToDate 
				AND b.statusID NOT IN (101, 102)	-- REJECT, VOID 
	END

	-- update SoldId column: if main ticket is BT, update SoldId = transid of subticket(901)
	CREATE TABLE #tblSoldTicket (transid BIGINT PRIMARY KEY)
	
	UPDATE	main
		SET main.SoldId = sub.transid
	OUTPUT INSERTED.SoldId
	INTO #tblSoldTicket(transid)
	FROM #Data main 
		INNER JOIN dbo.bettrans sub WITH(NOLOCK)
			ON	main.transid = sub.refno
				AND main.betdaqid = 0 -- main ticket is BTrade
				AND sub.matchid = main.matchid
				AND sub.bettype = 901
	
	-- get sub ticket of BetTrade (901)
	INSERT INTO #Data(
				GroupID			
				,bettype		
				,transid		
				,betid			
				,refno		
				,hdp1			
				,hdp2			
				,odds			
				,finalodds		
				,finalodds2		
				,OddsType		
				,STATUS			
				,comstatus		
				,stake								
				,transdate		
				,betteam		
				,betcheck		
				,liveindicator	
				,modds			
				,custid						
				,livehomescore	
				,liveawayscore					
				,betfrom		
				,matchid					
				,winlost		
				,commission					
				,winlostdate	
				,TransDesc		
				,betdaqid		
	)
	SELECT	main.transid
			,main.bettype
			,sub.transid
			,sub.betid
			,sub.refno
			,main.hdp1
			,main.hdp2
			,main.odds
			,main.finalodds
			,main.finalodds2
			,main.OddsType
			,'SOLD'
			,main.comstatus
			,main.stake			
			,sub.transdate
			,main.betteam
			,main.betcheck
			,main.liveindicator
			,main.modds
			,sub.custid
			,main.livehomescore
			,main.liveawayscore
			,main.betfrom
			,main.matchid
			,sub.winlost - sub.actual_stake
			,main.commission
			,main.winlostdate
			,main.TransDesc
			,main.betdaqid
	FROM	#Data main
		INNER JOIN dbo.bettrans sub WITH(NOLOCK)
			ON	main.transid = sub.refno
				AND sub.matchid = main.matchid
				AND sub.bettype = 901
		INNER JOIN #tblSoldTicket sold 
			ON sold.transid = sub.transid
	
	-- update username/creatorname column
	UPDATE al
		SET username = ci.username
			,matchcode = m.matchcode
			,homeid = m.homeid
			,awayid = m.awayid
			,leagueid = m.leagueid
			,sporttype = m.sporttype
			,isNeutral = CAST (ISNULL(m.IsNeutral, 0) AS BIT)
			,showtime = m.showtime
	FROM	#Data al
		INNER JOIN CustDB.dbo.custInfo ci WITH(NOLOCK)
			ON al.custid = ci.custid
		INNER JOIN dbo.match m WITH(NOLOCK)
			ON al.matchid = m.matchid
	WHERE	m.sporttype BETWEEN 1 AND 99 OR m.sporttype = 154  -- SB
			OR m.sporttype = 161 -- NG
			OR m.sporttype = 162 -- LC
			
	DELETE 
	FROM #Data
	WHERE sporttype IS NULL
		
	-- ALL tickets	
	SELECT	
			bettype		
			,transid		
			,betid			
			,refno			
			,matchcode	
			,homeid			
			,awayid			
			,hdp1			
			,hdp2			
			,odds			
			,finalodds		
			,finalodds2		
			,OddsType		
			,STATUS			
			,comstatus		
			,stake			
			,transdate		
			,betteam		
			,betcheck		
			,liveindicator	
			,modds			
			,custid			
			,username		
			,livehomescore	
			,liveawayscore	
			,leagueid		
			,sporttype		
			,betfrom		
			,matchid		
			,isNeutral		
			,winlost		
			,commission		
			,showtime		
			,winlostdate	
			,TransDesc		
			,SoldId				
	FROM	#Data
	ORDER BY GroupID, transid
	
	-->> Ticket Details 
	-- LiveCS Detail 
	IF (EXISTS (SELECT TOP 1 1 FROM #Data WHERE bettype BETWEEN 1101 AND 1199))
	BEGIN
		INSERT INTO #DetailData
		SELECT BG.refno
			,BG.odds
			,BG.stake
			,BG.STATUS
			,BG.bettype
			,BG.betteam
		FROM bettransg BG WITH (NOLOCK)
			INNER JOIN #Data B ON BG.refno = B.refno
		WHERE B.Bettype BETWEEN 1101 AND 1199

		INSERT INTO #DetailData
		SELECT BG.refno
			,BG.odds
			,BG.stake
			,BG.STATUS
			,BG.bettype
			,BG.betteam
		FROM bettransg14 BG WITH (NOLOCK)
			INNER JOIN #Data B ON BG.refno = B.refno
		WHERE B.Bettype BETWEEN 1101 AND 1199
	END
	SELECT *
	FROM #DetailData

END
GO
GRANT EXECUTE ON [dbo].[NAP_BettransSpecialDelBetID_Sel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_BettransSpecialDelBetID_Sel] TO [vnteam] AS [dbo]