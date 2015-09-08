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
	Param's Explanation:
		+ @CustID NOT NULL: Search by CustID
		+ @TransID NOT NULL: Search by TransID

	*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Data TABLE (
		GroupID			BIGINT
		,bettype		INT
		,transid		BIGINT
		,betid			BIGINT
		,refno			BIGINT
		,matchcode		NVARCHAR(50)
		,eventdate		SMALLDATETIME
		,homeid			INT
		,awayid			INT
		,settleTime		DATETIME
		,hdp1			SMALLMONEY
		,hdp2			SMALLMONEY
		,odds			SMALLMONEY
		,finalodds		SMALLMONEY
		,finalodds2		SMALLMONEY
		,OddsType		TINYINT
		,STATUS			NVARCHAR(50)
		,comstatus		NVARCHAR(50)
		,stake			MONEY
		,actual_stake	MONEY
		,transdate		DATETIME
		,betteam		NVARCHAR(10)
		,betcheck		NVARCHAR(50)
		,liveindicator	BIT
		,modds			SMALLMONEY
		,custid			INT
		,username		VARCHAR(30)
		,livehomescore	INT
		,liveawayscore	INT
		,finalhomescore INT
		,finalawayscore INT
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
		)
	DECLARE @DetailData TABLE (
		refno			BIGINT
		,odds			SMALLMONEY
		,stake			MONEY
		,STATUS			NVARCHAR(50)
		,bettype		SMALLINT
		,betteam		NVARCHAR(50)
		)

	--Search by TransID 
	IF @CustID IS NULL 
	BEGIN 
	
		SELECT	@FromDate = CONVERT(VARCHAR(10),CURRENT_TIMESTAMP - 3,120)		-- As defined, only get data within 3 days 
		
		INSERT INTO @Data
		SELECT CASE WHEN b.Bettype IN (801,803,804,805,806) THEN b.refno ELSE b.transid END GroupID, b.bettype
			,CASE WHEN b.Bettype IN (801,803,804,805,806) THEN b.refno ELSE b.transid END transid
			,isnull(b.BetID, 0) AS BetID
			,b.refno
			,m.matchcode
			,m.eventdate AS eventdate
			,m.homeid
			,m.awayid
			,ISNULL(b.checktime, '') settleTime
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
			,b.actual_stake
			,b.transdate
			,b.betteam
			,b.betcheck
			,b.liveindicator
			,b.modds
			,b.custid
			,b.username
			,b.livehomescore
			,b.liveawayscore
			,m.finalhomescore
			,m.finalawayscore
			,m.leagueid
			,m.sporttype
			,b.betfrom
			,b.matchid
			,isnull(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
			,(b.winlost - b.actual_stake) winlost
			,b.playercomm AS commission
			,m.showtime
			,b.winlostdate
			,b.transdesc
		FROM bettrans AS b WITH (NOLOCK)
			INNER JOIN match AS m WITH (NOLOCK) ON b.matchid = m.matchid 
		WHERE	CASE WHEN b.Bettype IN (801,803,804,805,806) THEN b.refno  ELSE b.transid END = @TransID
				AND b.winlostdate >=@FromDate
				AND b.bettype < 19001
				AND b.bettype NOT IN (10,31, 32, 33, 71,72,73,1000)		-- NOT IN Racing, Outright, VS 
				AND b.bettype NOT BETWEEN 1201 AND 1299					-- NOT VS
				AND b.bettype NOT BETWEEN 1501 AND 1599					-- NOT IN Keno 
				AND b.statusID NOT IN (101, 102)	-- REJECT, VOID 
				AND b.Bettype NOT IN (901,902,903)
		UNION ALL
		--Metric Gaming SUper Live
		SELECT b.translogID GroupID, b.GameID
			,b.translogID as transid
			,0 AS BetID
			,b.translogID refno
			,m.matchcode
			,m.eventdate AS eventdate
			,m.homeid
			,m.awayid
			,'' settleTime
			,0 hdp1
			,0 hdp2
			,b.odds
			,0 finalodds
			,0 finalodds2
			,b.custom1 OddsType
			,b.STATUS
			,b.custom2 comstatus
			,b.stake
			,b.actual_stake
			,b.transdate
			,NULL betteam
			,NULL betcheck
			,b.liveindicator liveindicator
			,NULL modds
			,b.custid
			,b.username
			,NULL livehomescore
			,NULL liveawayscore
			,m.finalhomescore
			,m.finalawayscore
			,m.leagueid
			,m.sporttype
			,b.betfrom
			,b.EventID
			,isnull(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
			,- b.actual_stake as winlost
			,0 AS commission
			,m.showtime
			,b.winlostdate
			,b.transdesc
		FROM translog AS b WITH (NOLOCK)
			INNER JOIN match AS m WITH (NOLOCK) ON b.EventID = m.matchid 
			LEFT JOIN bettrans bs WITH(NOLOCK) ON b.gameid = bs.bettype AND bs.matchid = b.eventid AND bs.custid = b.Custid AND b.translogid = bs.refno
		WHERE	b.translogid = @TransID 
				AND b.winlostdate >=@FromDate
				AND b.GameID IN (801, 803, 804, 805, 806) AND bs.refno IS NULL
				AND b.statusID NOT IN (101, 102)	-- REJECT, VOID 
		UNION ALL 
		SELECT b.transid GroupID, 9 bettype
			,b.transid
			,isnull(b.BetID, 0) AS BetID
			,b.refno
			,'' matchcode
			,'' AS eventdate
			,0 AS homeid
			,0 AS awayid
			,'' settleTime
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
			,b.actual_stake
			,b.transdate transdate
			,b.betteam
			,b.betcheck
			,0 liveindicator
			,b.modds
			,b.custid
			,b.username
			,b.livehomescore
			,b.liveawayscore
			,0
			,0
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
		FROM bettrans AS b WITH (NOLOCK)
		WHERE	b.transid = @TransID 
				AND b.winlostdate >=@FromDate
				AND b.matchid = 9
				AND b.bettype = 9
				AND b.statusID NOT IN (101, 102)	-- REJECT, VOID 
		UNION ALL 
		SELECT b.transid GroupID, b.bettype
			,b.transid
			,isnull(b.BetID, 0) AS BetID
			,b.refno
			,odds.matchcode
			,odds.eventdate AS eventdate
			,0 AS homeid
			,odds.teamid AS awayid
			,'' settleTime
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
			,b.actual_stake
			,b.transdate transdate
			,b.betteam
			,b.betcheck
			,b.liveindicator
			,b.modds
			,b.custid
			,b.Username
			,b.livehomescore
			,b.liveawayscore
			,0
			,0
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
		FROM bettrans AS b WITH (NOLOCK)
			INNER JOIN outright AS odds WITH (NOLOCK) ON b.matchid = odds.orid
			INNER JOIN league l WITH (NOLOCK) ON odds.leagueid = l.leagueid
		WHERE b.bettype = 10
			AND b.winlostdate >=@FromDate
			AND b.transid = @TransID 
			AND b.statusID NOT IN (101, 102)	-- REJECT, VOID 
	END
	ELSE --- Search by CustID 
	BEGIN 
		INSERT INTO @Data
		SELECT b.transid GroupID, b.bettype
			,CASE WHEN b.Bettype IN (801,803,804,805,806) THEN b.refno ELSE b.transid END transid
			,isnull(b.BetID, 0) AS BetID
			,b.refno
			,m.matchcode
			,m.eventdate AS eventdate
			,m.homeid
			,m.awayid
			,ISNULL(b.checktime, '') settleTime
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
			,b.actual_stake
			,b.transdate
			,b.betteam
			,b.betcheck
			,b.liveindicator
			,b.modds
			,b.custid
			,b.username
			,b.livehomescore
			,b.liveawayscore
			,m.finalhomescore
			,m.finalawayscore
			,m.leagueid
			,m.sporttype
			,b.betfrom
			,b.matchid
			,isnull(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
			,(b.winlost - b.actual_stake) winlost
			,b.playercomm AS commission
			,m.showtime
			,b.winlostdate
			,b.transdesc
		FROM bettrans AS b WITH (NOLOCK)
			INNER JOIN match AS m WITH (NOLOCK) ON b.matchid = m.matchid 
		WHERE	b.custid =@Custid 
				AND b.winlostdate BETWEEN @FromDate AND @ToDate 
				AND b.bettype < 19001
				AND b.bettype NOT IN (10,31, 32, 33, 71,72,73,1000)		-- NOT IN Racing, Outright, VS 
				AND b.bettype NOT BETWEEN 1201 AND 1299					-- NOT VS
				AND b.bettype NOT BETWEEN 1501 AND 1599					-- NOT IN Keno 
				AND b.statusID NOT IN (101, 102)	-- REJECT, VOID 
				AND b.Bettype NOT IN (901,902,903)
		UNION ALL
		--Metric Gaming Super Live
		SELECT b.translogid GroupID, b.GameID
			,b.translogid transid
			,0 AS BetID
			,b.translogid refno
			,m.matchcode
			,m.eventdate AS eventdate
			,m.homeid
			,m.awayid
			,'' settleTime
			,0 hdp1
			,0 hdp2
			,b.odds
			,0 finalodds
			,0 finalodds2
			,b.custom1 OddsType
			,b.STATUS
			,b.custom2 comstatus
			,b.stake
			,b.actual_stake
			,b.transdate
			,NULL betteam
			,NULL betcheck
			,b.liveindicator liveindicator
			,NULL modds
			,b.custid
			,b.username
			,NULL livehomescore
			,NULL liveawayscore
			,m.finalhomescore
			,m.finalawayscore
			,m.leagueid
			,m.sporttype
			,b.betfrom
			,b.EventID
			,isnull(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
			,- b.actual_stake as winlost
			,0 AS commission
			,m.showtime
			,b.winlostdate
			,b.transdesc
		FROM translog AS b WITH (NOLOCK)
			INNER JOIN match AS m WITH (NOLOCK) ON b.EventID = m.matchid 
			LEFT JOIN bettrans bs WITH(NOLOCK) ON b.gameid = bs.bettype AND bs.matchid = b.eventid AND bs.custid = b.Custid AND b.translogid = bs.refno
		WHERE	b.custid =@Custid 
				AND b.winlostdate BETWEEN @FromDate AND @ToDate 
				AND b.GameID IN (801, 803, 804, 805, 806) AND bs.refno IS NULL
				AND b.statusID NOT IN (101, 102)	-- REJECT, VOID 
		UNION ALL 
		SELECT b.transid GroupID, 9 bettype
			,b.transid
			,isnull(b.BetID, 0) AS BetID
			,b.refno
			,'' matchcode
			,'' AS eventdate
			,0 AS homeid
			,0 AS awayid
			,'' settleTime
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
			,b.actual_stake
			,b.transdate transdate
			,b.betteam
			,b.betcheck
			,0 liveindicator
			,b.modds
			,b.custid
			,b.username
			,b.livehomescore
			,b.liveawayscore
			,0
			,0
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
		FROM bettrans AS b WITH (NOLOCK)
		WHERE	b.custid =@Custid 
				AND b.winlostdate BETWEEN @FromDate AND @ToDate 
				AND matchid = 9
				AND bettype = 9
				AND b.statusID NOT IN (101, 102)	-- REJECT, VOID 
		UNION ALL 
		SELECT b.transid GroupID, b.bettype
			,b.transid
			,isnull(b.BetID, 0) AS BetID
			,b.refno
			,odds.matchcode
			,odds.eventdate AS eventdate
			,0 AS homeid
			,odds.teamid AS awayid
			,'' settleTime
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
			,b.actual_stake
			,b.transdate transdate
			,b.betteam
			,b.betcheck
			,b.liveindicator
			,b.modds
			,b.custid
			,b.Username
			,b.livehomescore
			,b.liveawayscore
			,0
			,0
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
		FROM bettrans AS b WITH (NOLOCK)
			INNER JOIN outright AS odds WITH (NOLOCK) ON b.matchid = odds.orid
			INNER JOIN league l WITH (NOLOCK) ON odds.leagueid = l.leagueid
		WHERE	b.bettype = 10
				AND b.custid =@Custid 
				AND b.winlostdate BETWEEN @FromDate AND @ToDate 
				AND b.statusID NOT IN (101, 102)	-- REJECT, VOID 
	END


	SELECT * FROM
	(SELECT t.*, b.transid AS SoldID
	FROM @Data t
	LEFT JOIN bettrans AS b WITH (NOLOCK) ON b.refno = t.transid AND b.bettype = 901
	UNION ALL
	SELECT b.refno GroupID, b.bettype
			,b.transid
			,t.bettype AS BetID
			,b.refno
			,m.matchcode
			,m.eventdate AS eventdate
			,m.homeid
			,m.awayid
			,ISNULL(b.checktime, '') settleTime
			,b.hdp1
			,b.hdp2
			,t.odds
			,0 finalodds
			,0 finalodds2
			,b.OddsType
			,'SOLD' STATUS
			,CASE 
				WHEN b.comstatus = '1' THEN 1
				ELSE 0
				END AS comstatus
			,t.stake
			,b.actual_stake
			,b.transdate
			,b.betteam
			,b.betcheck
			,b.liveindicator
			,b.modds
			,b.custid
			,b.username
			,b.livehomescore
			,b.liveawayscore
			,m.finalhomescore
			,m.finalawayscore
			,m.leagueid
			,m.sporttype
			,b.betfrom
			,b.matchid
			,isnull(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
			,(b.winlost - b.actual_stake) winlost
			,b.playercomm AS commission
			,m.showtime
			,b.winlostdate
			,b.transdesc
			,b.transid SoldID
	FROM @Data t
			INNER JOIN bettrans AS b WITH (NOLOCK) ON b.refno = t.transid AND b.bettype = 901
			INNER JOIN match AS m WITH (NOLOCK) ON b.matchid = m.matchid 
		WHERE	b.winlostdate >=@FromDate
				AND b.bettype < 19001
				AND b.bettype NOT IN (10,31, 32, 33, 71,72,73,1000)		-- NOT IN Racing, Outright, VS 
				AND b.bettype NOT BETWEEN 1201 AND 1299					-- NOT VS
				AND b.bettype NOT BETWEEN 1501 AND 1599					-- NOT IN Keno 
				AND b.statusID NOT IN (101, 102)	-- REJECT, VOID 
	) tmp			
	ORDER BY GroupID, transid

	-->> Ticket Details 
	-- LiveCS Detail 
	IF (EXISTS (SELECT TOP 1 1 FROM @Data WHERE bettype BETWEEN 1101 AND 1199))
	BEGIN
		INSERT INTO @DetailData
		SELECT BG.refno
			,BG.odds
			,BG.stake
			,BG.STATUS
			,BG.bettype
			,BG.betteam
		FROM bettransg BG WITH (NOLOCK)
			INNER JOIN @Data B ON BG.refno = B.refno
		WHERE B.Bettype BETWEEN 1101 AND 1199

		INSERT INTO @DetailData
		SELECT BG.refno
			,BG.odds
			,BG.stake
			,BG.STATUS
			,BG.bettype
			,BG.betteam
		FROM bettransg14 BG WITH (NOLOCK)
			INNER JOIN @Data B ON BG.refno = B.refno
		WHERE B.Bettype BETWEEN 1101 AND 1199
	END
	SELECT *
	FROM @DetailData

END

GO
GRANT EXECUTE ON [dbo].[NAP_BettransSpecialDelBetID_Sel] TO [bodbAdminNet]
GO



 