ALTER PROCEDURE [dbo].[NAP_SpecialDelete_VoidBetIdList_Sel] 
	@CustID			INT				= NULL 	
	,@TransIds		VARCHAR(MAX)	= NULL 
	,@FromDate		DATETIME		= NULL
	,@ToDate		DATETIME		= NULL
	,@Duration		INT = 0 OUTPUT	
AS
/*  
	Created by: Bobby  
	Date: 20160225
	Task: Get tickets by Bet ID/CustID : 
		  Normal SB, Outright, Mix Parlay (Allow to delete Running & Refunded), NG, and Live Casino 
	DB: DBTXN/bodb02   
	Original:NAP_BettransSpecialDelBetID_Sel     

	Revisions:  
		- 20150402@Dominic: Add new 60 bettypes [Redmine:#27214]
		- 20150611@Dominic: BetTrade Integration [Redmine:#36964]
		- 20150623@Dominic: Add Metric Gaming Super Live [Redmine:##38200]
		- 20151021@Kathy: Do not show ticket 901 if its owner is not BetTrade account(betdaqid = 0)[Redmine:#43233]
		- 20151102@Kathy: Enhance performance [Redmine:#43233]
		- 20150712@Kathy: Database - Change datatype [Redmine: #48660]
		- 20160113@Patrick: Support Cricket [Redmine: #50688]
		- 20160301@Bobby: #53123 - Enhance SP void bet by Id list (allow transId up to 1000 rows)
		
	Param's Explanation:
		+ @CustID NOT NULL: Search by CustID
		+ @TransIds NOT NULL: Search by TransID

	*/
BEGIN
	SET NOCOUNT ON
	
	IF(@custid IS NULL AND @TransIds IS NULL) RETURN
	
	DECLARE @moveBetDay 	SMALLDATETIME
		,@startTime			DATETIME	
		
	SELECT @Duration 		= 0
		, @startTime		= CURRENT_TIMESTAMP
		
	
	SELECT @moveBetDay = MAX(winlostdate) 
	FROM dbo.bettrans14 WITH(NOLOCK)
	
	SELECT @FromDate	= ISNULL(@FromDate, @moveBetDay)
		, @FromDate 	= CASE WHEN @FromDate <= @moveBetDay THEN DATEADD(d, 1, @moveBetDay) ELSE @FromDate END
		, @ToDate 		= ISNULL(@ToDate, DATEADD(d, 90, @moveBetDay))
	
	CREATE TABLE #transIdTemp (transid BIGINT PRIMARY KEY)
	
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
		,recommend		INT
		,IsHideComm		BIT DEFAULT(0)
		,oddsid			INT
	)
	
	IF(LEN(@TransIds) > 0)
	BEGIN
		INSERT INTO #transIdTemp (transid)
		SELECT DISTINCT val 
		FROM dbo.strSplit(@TransIds, ',')
		WHERE val <> ''
	END
	
	IF(@custid > 0)
	BEGIN
		INSERT INTO #transIdTemp (transid)
		SELECT	b.translogid AS transid
		FROM	dbo.translog AS b WITH (NOLOCK)
		WHERE	b.custid = @Custid 
				AND b.winlostdate BETWEEN @FromDate AND @ToDate 
				AND b.GameID BETWEEN 801 AND 806
				AND b.statusID = 0
				
		UNION ALL
		SELECT CASE WHEN b.bettype BETWEEN 801 AND 806 THEN b.refno ELSE b.transid END
		FROM dbo.bettrans AS b WITH (NOLOCK)
		WHERE	b.custid = @Custid 
			AND b.winlostdate BETWEEN @FromDate AND @ToDate 
			AND 1 = CASE 
				WHEN (b.bettype BETWEEN 801 AND 806 AND b.statusID NOT IN (0, 101, 102)) THEN 1 
				WHEN (b.bettype < 19001
						AND b.bettype NOT IN (31, 32, 33, 71,72,73)	-- NOT IN [Racing, Casino]
						AND b.bettype NOT BETWEEN 801 AND 806-- MG
						AND b.bettype NOT IN (901, 902, 903) -- BT subticket
						AND b.bettype NOT BETWEEN 1501 AND 1599					-- NOT IN Keno
						AND b.statusID NOT IN (101, 102)
					) THEN 1
				ELSE 0 END
	END
	
	--Search by TransIds
	IF (EXISTS(SELECT TOP 1 1 FROM #transIdTemp))
	BEGIN 
		
		-- MG running tickets in translog
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
			,username
			,recommend
		)
		SELECT	
			b.translogID AS GroupID
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
			,username
			,recommend
			
		FROM dbo.translog AS b WITH (NOLOCK)
			INNER JOIN #transIdTemp temp
			ON b.translogid = temp.transid
			
		WHERE b.winlostdate >=@FromDate
			AND b.GameID BETWEEN 801 AND 806
			AND b.statusID = 0
				
		-- bettrans tickets	
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
			,username
			,recommend
			,IsHideComm
			,oddsid
		)
		SELECT	
			b.refno AS GroupId
			,b.bettype
			,b.transid
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
			,b.username
			,b.recommend			
			,0 AS IsHideComm
			,b.oddsid
		FROM dbo.bettrans AS b WITH (NOLOCK)
			INNER JOIN dbo.translog tl WITH(NOLOCK)
			ON b.custid 		= tl.custid
				AND b.refno 	= tl.translogid
				AND b.matchid 	= tl.eventid
			INNER JOIN #transIdTemp temp
			ON tl.translogid 	= temp.transid
			
		WHERE	b.winlostdate >=@FromDate				
			AND b.bettype BETWEEN 801 AND 806 
			AND b.statusID NOT IN (0, 101, 102)
			
		UNION ALL
		SELECT	
			b.transid AS GroupId
			,b.bettype
			,b.transid
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
			,b.username
			,b.recommend			
			,CASE WHEN b.bettype = 501 AND b.playerdiscount < 0 THEN 1 ELSE 0 END AS IsHideComm
			,b.oddsid
			
		FROM dbo.bettrans AS b WITH (NOLOCK)
			INNER JOIN #transIdTemp temp
				ON b.transid = temp.transid
				
		WHERE	b.winlostdate >=@FromDate				
			AND b.bettype < 19001
			AND b.bettype NOT IN (31, 32, 33, 71,72,73)	-- NOT IN [Racing, Casino]
			AND b.bettype NOT BETWEEN 801 AND 806 
			AND b.bettype NOT IN (901, 902, 903) -- BT subticket
			AND b.bettype NOT BETWEEN 1501 AND 1599	-- exclude Keno
			AND b.statusID NOT IN (101, 102)
				
		
	END
	
	-- update SoldId column: if main ticket is BT, update SoldId = transid of subticket(901)
	CREATE TABLE #tblSoldTicket (transid BIGINT PRIMARY KEY)
	
	UPDATE	main
	SET main.SoldId = sub.transid
	OUTPUT INSERTED.SoldId
	INTO #tblSoldTicket(transid)
	FROM #Data main 
		INNER JOIN dbo.bettrans sub WITH(NOLOCK)
			ON	main.transid 	= sub.refno
				AND sub.matchid = main.matchid
				
	WHERE main.betdaqid = 0 -- main ticket is BTrade
		AND sub.bettype = 901
	
	-- get sub ticket of BetTrade (901)
	IF(EXISTS (SELECT TOP 1 1 FROM #tblSoldTicket) )
	BEGIN
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
			,username
			,recommend			
		)
		SELECT	
			main.transid
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
			,sub.username
			,sub.recommend			
		FROM dbo.bettrans sub WITH(NOLOCK)
			INNER JOIN #tblSoldTicket sold 
				ON sub.transid 	= sold.transid
			INNER JOIN 	#Data main
				ON	sub.refno 	= main.transid 
				AND sub.matchid = main.matchid
	END
	
	-- UPDATE eventtype = 1
	IF(EXISTS(SELECT TOP 1 1 FROM #data WHERE bettype NOT IN (9)))
	BEGIN
		UPDATE d
		SET matchcode 	= m.matchcode
			,homeid 	= m.homeid
			,awayid 	= m.awayid
			,leagueid 	= m.leagueid
			,sporttype 	= m.sporttype
			,IsNeutral 	= ISNULL(m.IsNeutral, CONVERT(BIT, 0))
			,showtime	= ISNULL(m.showtime, '')  
			
		FROM #Data d
			INNER JOIN dbo.match m WITH (NOLOCK) 
			ON	d.matchid = m.matchid
			
		WHERE d.bettype NOT IN (9)
	END
	
	-- UPDATE eventtype = 2 [Outright bettype]
	IF(EXISTS(SELECT TOP 1 1 FROM #data WHERE bettype IN (10)))
	BEGIN
		UPDATE d
		SET matchcode 	= odds.matchcode
			,homeid		= odds.teamid
			,awayid 	= 0
			,leagueid 	= odds.leagueid
			,sporttype 	= l.sporttype
			,showtime	= ''
			
		FROM #Data d
			INNER JOIN dbo.outright AS odds WITH (NOLOCK) 
			ON	d.matchid = odds.orid
			INNER JOIN dbo.league l WITH (NOLOCK) 
			ON	odds.leagueid = l.leagueid
		WHERE d.bettype IN (10)
	END
	-- UPDATE eventtype = 3 [VS range  bettypes]
	IF(EXISTS(SELECT TOP 1 1 FROM #data WHERE bettype IN (1231,1232,1233,1237,1238)))
	BEGIN
		UPDATE d
		SET matchcode 	= CONVERT(NVARCHAR(50), o.RacerNum)
			,homeid 	= o.RacerID
			,awayid 	= 0
			,leagueid 	= r.leagueid
			,sporttype 	= r.sporttype
			,showtime	= CONVERT(VARCHAR(20), r.EventTime, 113) 
			
		FROM #Data d
			INNER JOIN dbo.VSOutright o WITH (NOLOCK) 
			ON d.oddsid = o.Orid
			INNER JOIN dbo.VSRaceInfo r WITH (NOLOCK) 
			ON r.EventID = o.EventID
			
		WHERE d.bettype IN (1231,1232,1233,1237,1238)
	END
	
	--- Remove invalid sporttype	
	DELETE 
	FROM #Data
	WHERE bettype NOT IN (9)
		AND (
			sporttype IS NULL
			OR bettype = 500 /*charge comm*/
		)
	
	-- UPDATE SiteName
	;WITH CustSiteName AS (
		SELECT DISTINCT ag.custid, ci.site, ci.srecommend
		FROM CUSTDB.dbo.Customer ci WITH(NOLOCK)
			INNER JOIN #Data ag
			ON ci.custid = ag.recommend
		
	)
	-- ALL tickets	
	SELECT
		d.*
		,CASE WHEN s.custid IS NOT NULL THEN 1 ELSE 0 END AS IsDeposit
		,cs.Site
	FROM #Data d
		INNER JOIN CustSiteName cs 
		ON d.custid = cs.custid
		LEFT JOIN CustDB.dbo.Dep_CustSuper s WITH(NOLOCK) 
		ON cs.srecommend = s.custid
	ORDER BY cs.Site
		,GroupID
		,transid
	
	-->> Ticket in Details for LiveCS
	SELECT BG.refno
		,BG.odds
		,BG.stake
		,BG.STATUS
		,BG.bettype
		,BG.betteam
	FROM dbo.bettransg BG WITH (NOLOCK)
		INNER JOIN #Data B 
		ON BG.refno = B.refno
	WHERE B.Bettype BETWEEN 1101 AND 1199
	
	-- invalid trans
	SELECT	transid AS InvalidTrans
			,ISNULL(bm.isMoved, 0) AS isMoved
	FROM #transIdTemp temp
		OUTER APPLY (
			SELECT TOP 1 CAST(1 AS BIT) AS isMoved
			FROM dbo.bettrans14 WITH(NOLOCK) 
			WHERE transid = temp.transid
		) bm
	WHERE	NOT EXISTS (SELECT 1 FROM #Data WHERE transid = temp.transid OR refno = temp.transid)
	
	SELECT @Duration 		= DATEDIFF(MS, @startTime, CURRENT_TIMESTAMP)
	
	RETURN;
END
GO
GRANT EXECUTE ON [dbo].[NAP_SpecialDelete_VoidBetIdList_Sel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialDelete_VoidBetIdList_Sel] TO [vnteam] AS [dbo]
GO
exec NAP_SpecialDelete_VoidBetIdList_Sel @ToDate=NULL,@FromDate=NULL
,@transids='8216246023,8216249324'
, @CustID=NULL
