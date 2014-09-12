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
	DB: DBAGE/bodb02   
	Original:     

	Revisions:  

	Param's Explanation:
		+ @CustID NOT NULL: Search by CustID
		+ @TransID NOT NULL: Search by TransID

	*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Data TABLE (
		bettype			INT
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
		)
	DECLARE @DetailData TABLE (
		refno			BIGINT
		,odds			SMALLMONEY
		,stake			MONEY
		,STATUS			NVARCHAR(50)
		,bettype		SMALLINT
		,betteam		NVARCHAR(50)
		)

	--Sportbooks  
	IF @CustID IS NULL 
	BEGIN 
		INSERT INTO @Data
		SELECT b.bettype
			,b.transid
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
		FROM bettrans AS b WITH (NOLOCK)
			INNER JOIN match AS m WITH (NOLOCK) ON b.matchid = m.matchid 
		WHERE	b.transid = @TransID 
				AND b.bettype < 19001
				AND b.bettype NOT IN (10,31, 32, 33, 71,72,73,1000)		-- NOT IN Racing, Outright, VS 
				AND b.bettype NOT BETWEEN 1201 AND 1299					-- NOT VS
				AND b.bettype NOT BETWEEN 1501 AND 1599					-- NOT IN Keno 
		UNION ALL 
		SELECT 9 bettype
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
		FROM bettrans AS b WITH (NOLOCK)
		WHERE	b.transid = @TransID 
				AND b.matchid = 9
				AND b.bettype = 9
		UNION ALL 
		SELECT b.bettype
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
		FROM bettrans AS b WITH (NOLOCK)
			INNER JOIN outright AS odds WITH (NOLOCK) ON b.matchid = odds.orid
			INNER JOIN league l WITH (NOLOCK) ON odds.leagueid = l.leagueid
		WHERE b.bettype = 10
			AND b.transid = @TransID 
	END
	ELSE 
	BEGIN 
		INSERT INTO @Data
		SELECT b.bettype
			,b.transid
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
		FROM bettrans AS b WITH (NOLOCK)
			INNER JOIN match AS m WITH (NOLOCK) ON b.matchid = m.matchid 
		WHERE	b.custid =@Custid 
				AND b.winlostdate BETWEEN @FromDate AND @ToDate 
				AND b.bettype < 19001
				AND b.bettype NOT IN (10,31, 32, 33, 71,72,73,1000)		-- NOT IN Racing, Outright, VS 
				AND b.bettype NOT BETWEEN 1201 AND 1299					-- NOT VS
				AND b.bettype NOT BETWEEN 1501 AND 1599					-- NOT IN Keno 
		UNION ALL 
		SELECT 9 bettype
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
		FROM bettrans AS b WITH (NOLOCK)
		WHERE	b.custid =@Custid 
				AND b.winlostdate BETWEEN @FromDate AND @ToDate 
				AND matchid = 9
				AND bettype = 9
		UNION ALL 
		SELECT b.bettype
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
		FROM bettrans AS b WITH (NOLOCK)
			INNER JOIN outright AS odds WITH (NOLOCK) ON b.matchid = odds.orid
			INNER JOIN league l WITH (NOLOCK) ON odds.leagueid = l.leagueid
		WHERE	b.bettype = 10
				AND b.custid =@Custid 
				AND b.winlostdate BETWEEN @FromDate AND @ToDate 
	END


	SELECT *
	FROM @Data
	ORDER BY transid

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

		SELECT *
		FROM @DetailData
	END

END

GO
GRANT EXECUTE ON [dbo].[NAP_BettransSpecialDelBetID_Sel] TO [bodbAdminNet]
GO



 