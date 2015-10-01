USE bodb_archive
GO

ALTER PROCEDURE [dbo].[Acc_BetsSelBetList_Old]
(
	@FromDate	DATETIME,
	@ToDate		DATETIME,
	@CustID		INT,
	@Bettype	INT = 0
)
AS

/*
	Created: 20100123@[Henry]
	Task : Get Bet List from Archive
	DB: DBARC/bodb_archive
	Original: 

	Revisions:
		- 20100123@[Henry]: Newly created
		- 20100409@Daniel: Support Mini game
		- 20100501@Daniel: Remove support Mini game, add agent W/L amount, agent's commission amount columns
		- 20100524@Jamie: Show currency2's exchange rate for OpenTote 
		- 20100611@Henry: For mix-parlay, match value is either 0 OR 9
		- 20100907@Henry: Add IBC Bingo bettype
		- 20101007@Henry: Change column transid from INT to BIGINT
		- 20101130@Henry: Add column betid for number game
		- 20101201@Henry: Return winlost-actual_stake for column winlost
		- 20110408@Amy: Change function to get Odds value and odds type
		- 20110516@Lukas: re-arrange bettype
		- 20110524@Henry: change to use winlostdate instead of transdate
		- 20110711@Johnson: show exchange rate for SA Tote(Pool Currency)
		- 20110802@Johnson:	- Add new column actual_stake into betlist
							- Add new bettype combination mix parlay
		- 20111207@Sophia: Add P2P
		- 20120120@Sophia: Add Showtime for Table-hand-shoe of Live Casino
						   Add sub detail for Live Casino
		- 20120405@Hurri: Exclude bettype 72 (P2P bet ticket) in the calculation of Casino
		- 20120416@Johnson: Correct column transid for p2p	
		- 20120418@Sophia: Edit sub detail for Live Casino
		- 20120423@Lukas: show transid of main ticket for all subticket of system parlay
		- 20120606@Sophia: Change datatype of stake to money	
		- 20120626@Lukas: exclude outright from sportbook ( in case of matchid = orid)
		- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype,f_GetChoice for odds, Oddstype, betteam
		- 20120927@Johnson: get commstatus column to check double comm losing
		- 20130226@Lukas: Move SP to bodb_archive	
		- 20130227@Elodie: Add Virtual HR product
		- 20130408@Lukas: return value odds.teamid to alias name homeid instead of awayid
		- 20130724@Elodie: Get winlostdate field
		- 20140306@Dom: Add Keno
		- 20140908@Dom:	[Redmine #22012] Update VS conditions
		- 20141103@Dom: Apply sport bettype matrix
		- 20150415@Sophia: Get Betcheck for Betradar
		- 20150506@Tom: Support Gold Deluxe Product [#34847]
		- 20150506@Bobby: Add transdesc column for metric gaming bettypes (801-899)
		- 20150615@Edward: Support for BetTrade
		- 20150625@Edward: Support for MicroGamming
		- 20150805@Bobby: Enhance code for SQL parameter sniffing
		- 20150826@Kos: Add OddsSpread column to support Myanmar Odds
		- 20150828@Kos: Support Colossus Bet
		- 20150930@Bobby: Enhance performance - re-arrange indexers
*/

BEGIN

	SET NOCOUNT ON
	
	DECLARE @tempBettype 	INT
	
	SELECT @tempBettype = @Bettype
	
	CREATE TABLE #BetListData (
		bettype			SMALLINT,
		transid			BIGINT, 
		betid			BIGINT,
		refno			NVARCHAR(50), 
		matchcode		NVARCHAR(50),
		race			NVARCHAR(20),
		eventdate		SMALLDATETIME,
		virtualrate		FLOAT,
		isShowOTExRate	BIT,
		sdiscount		SMALLMONEY,
		adiscount		SMALLMONEY,
		discount		SMALLMONEY,
		homeid			INT, 
		awayid			INT, 
		settleTime		DATETIME,
		hdp1			SMALLMONEY, 
		hdp2			SMALLMONEY, 
		odds			SMALLMONEY,
		finalodds		SMALLMONEY,
		finalodds2		SMALLMONEY,
		OddsType		TINYINT,
		status			NVARCHAR(50),
		comstatus		NVARCHAR(50), 
		stake			MONEY,
		actual_stake	MONEY,
		transdate		DATETIME,
		betteam			NVARCHAR(50),
		spositiontaking SMALLMONEY,
		mpositiontaking SMALLMONEY,
		apositiontaking SMALLMONEY,
		spositiontaking2 SMALLMONEY,
		mpositiontaking2 SMALLMONEY,
		apositiontaking2 SMALLMONEY,
		liveindicator	BIT,
		modds			SMALLMONEY,
		custid			INT,
		livehomescore	SMALLINT, 
		liveawayscore	SMALLINT, 
		finalhomescore	SMALLINT, 
		finalawayscore	SMALLINT, 
		leagueid		INT, 
		sporttype		SMALLINT, 
		ip				NVARCHAR(15), 
		betfrom			NVARCHAR (1),
		matchid			INT,
		isNeutral		BIT,
		allowdelete		BIT,
		winlost			MONEY,
		commission		MONEY,
		scomm			MONEY,	
		acomm			MONEY,
		comm			MONEY,
		awinlost		MONEY,
		mwinlost		MONEY,
		swinlost		MONEY,
		showtime		NVARCHAR(50),
		winlostdate		SMALLDATETIME,
		BetCheck		NVARCHAR(50),
		transdesc		NVARCHAR(300),
		OddsSpread		SMALLMONEY
	)

	CREATE TABLE #BetListDetailData (
		refno			VARCHAR(50), 
		odds			SMALLMONEY, 
		stake			MONEY,
		status			VARCHAR(50),
		apositiontaking SMALLMONEY, 
		mpositiontaking SMALLMONEY, 
		spositiontaking SMALLMONEY,
		bettype			SMALLINT,
		betteam			NVARCHAR(50),
		TransDesc		VARCHAR(300)
	)

	----Get Sport Bettype Matrix------
	CREATE TABLE #SportBettype (ProductID TINYINT, Bettype SMALLINT, EventType TINYINT)

	INSERT INTO #SportBettype
	EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode = 4

	IF @tempBettype <> 0
	BEGIN
		DELETE #SportBettype 
		WHERE Bettype <> @tempBettype
	END

	IF (
		EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID IN (1,3,4,5))
	)
	BEGIN
		--Sport Book
		INSERT INTO #BetListData
		SELECT 
			b.bettype,
			b.transid,
			ISNULL(b.BetID,0),
			b.refno,
			m.matchcode,
			'' AS race,
			m.eventdate AS eventdate,
			0,
			0,
			b.sdiscount,
			b.adiscount,
			b.discount,	
			m.homeid,
			m.awayid,
			ISNULL(b.checktime,'') settleTime,
			b.hdp1,
			b.hdp2,
			b.odds,   
			0 finalodds,
			0 finalodds2,
			b.OddsType,  
			b.status,
			CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus,
			stake,
			b.actual_stake,
			b.transdate,
			b.betteam, 
			b.spositiontaking,     
			b.mpositiontaking,     
			b.apositiontaking,  
			0 spositiontaking2,  
			0 mpositiontaking2,  
			0 apositiontaking2, 
			b.liveindicator,   
			b.modds,   
			b.custid,
			b.livehomescore, 
			b.liveawayscore, 
			m.finalhomescore, 
			m.finalawayscore, 
			m.leagueid,
			m.sporttype,
			b.ip,
			b.betfrom,
			b.matchid,
			ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
			0 AS allowdelete,
			(b.winlost-b.actual_stake)  winlost,
			b.playercomm AS commission,
			(b.scomm - b.acomm) AS scomm,
			(b.acomm - b.comm) AS acomm,
			(b.comm - b.playercomm) AS comm,
			b.awinlost,
			b.mwinlost,
			b.swinlost,
			m.showtime,
			b.winlostdate,
			b.BetCheck,
			CASE WHEN b.bettype BETWEEN 801 AND 899 THEN b.transdesc ELSE '' END AS transdesc,
			ISNULL(b.oddsspread, 0) AS OddsSpread
		FROM 
			dbo.bettrans_bk AS b WITH (nolock,index=IX_custid) 
			INNER JOIN dbo.match_BK AS m WITH (NOLOCK) ON b.matchid = m.matchid 
			INNER JOIN #SportBettype s ON b.bettype = s.Bettype
		WHERE b.custid 			= @Custid	
			AND b.winlostdate 	BETWEEN @FromDate AND  @ToDate
			AND	s.EventType 	= 1

		--Mix Parlay
		IF (EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 1 AND Bettype = 9))
		BEGIN
			INSERT INTO #BetListData
			SELECT 
				 9 bettype,   
				 b.transid,   
				 ISNULL(b.BetID,0),
				 b.refno,
				 '' matchcode,  
				 '' AS race,
				 '' AS eventdate,
				 0,
				 0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 AS homeid,   
				 0 AS awayid,  
				 '' settleTime, 
				 b.hdp1,
				 b.hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status, 
				 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus,  
				 b.stake,   
				 b.actual_stake,
				 b.transdate transdate,   
				 b.betteam,   
				 b.spositiontaking,  
				 b.mpositiontaking,   
				 b.apositiontaking,  
				 0 spositiontaking2,
				 0 mpositiontaking2,
				 0 apositiontaking2,  
				 0 liveindicator,   
				 b.modds,   
				 b.custid,
				 b.livehomescore,
				 b.liveawayscore,
				 0 AS finalhomescore, 
				 0 AS finalawayscore,  
				 0 AS leagueid,  
				 0 AS sporttype, 
				 b.ip,
				 b.betfrom,
				 0 matchid,	
				 CONVERT(BIT,0) AS IsNeutral,
				 0 AS allowdelete,
				 (b.winlost-b.actual_stake)  winlost,
				 b.playercomm AS commission,
				 (b.scomm - b.acomm) AS scomm,
				 (b.acomm - b.comm) AS acomm,
				 (b.comm - b.playercomm) AS comm,
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' AS showtime,
				b.winlostdate,
				b.BetCheck,
				'' AS transdesc,
				0 AS OddSpread
			FROM dbo.bettrans_bk AS b WITH (nolock,index=IX_custid)
			WHERE b.custid 			= @Custid	
				AND b.winlostdate 	BETWEEN @FromDate AND  @ToDate	
				AND b.matchid 		IN (0,9)
				AND b.bettype 		= 9  
		END

		 --Combination Mix Parlay
		IF (EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 1 AND Bettype = 29))
		BEGIN
			INSERT INTO #BetListData
			SELECT 
				 29 bettype,   
				 CASE WHEN ISNULL(b.betID,0) = 0 THEN b.transid ELSE b.betID END AS transid,
				 ISNULL(b.BetID,0),
				 b.refno,
				 '' matchcode,  
				 '' AS race,
				 '' AS eventdate,
				 0,0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 AS homeid,   
				 0 AS awayid,  
				 '' settleTime, 
				 b.hdp1,
				 b.hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status,
				 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus,   
				 b.stake,
				 b.actual_stake,   
				 b.transdate transdate,   
				 b.betteam,   
				 b.spositiontaking,  
				 b.mpositiontaking,   
				 b.apositiontaking,  
				 0 spositiontaking2,
				 0 mpositiontaking2,
				 0 apositiontaking2,  
				 0 liveindicator,   
				 b.modds,   
				 b.custid,
				 b.livehomescore,
				 b.liveawayscore,
				 0 AS finalhomescore, 
				 0 AS finalawayscore,  
				 0 AS leagueid,  
				 0 AS sporttype, 
				 b.ip,
				 b.betfrom,
				 0 matchid,	
				 CONVERT(BIT,0) AS IsNeutral,
				 0 AS allowdelete,
				 (b.winlost-b.actual_stake)  winlost,
				 b.playercomm AS commission,
				 (b.scomm - b.acomm) AS scomm,
				 (b.acomm - b.comm) AS acomm,
				 (b.comm - b.playercomm) AS comm,
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' AS showtime,
				b.winlostdate,
				b.BetCheck,
				'' AS transdesc,
				0 AS OddSpread
			FROM dbo.bettrans_bk AS b WITH (nolock,index=IX_custid)
			WHERE b.custid 			= @Custid	
				AND b.winlostdate 	BETWEEN @FromDate AND  @ToDate	
				AND b.matchid 		= 29
				AND b.bettype 		= 29 
		END

		-- Outright
		IF (EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 1 AND Bettype = 10))
		BEGIN
			INSERT INTO #BetListData
			SELECT 
				b.bettype,
				b.transid,   
				ISNULL(b.BetID,0),
				b.refno,
				odds.matchcode, 
				odds.groupmatch AS race,
				odds.eventdate AS eventdate,
				0,0,
				b.sdiscount,
				b.adiscount,
				b.discount,	  
				0 AS homeid,
				odds.teamid AS awayid,
				'' settleTime, 
				b.hdp1,
				b.hdp2,
				b.odds,   
				0 finalodds,
				0 finalodds2,
				'' OddsType,  
				b.status,   
				CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus,
				b.stake,
				b.actual_stake,   
				b.transdate transdate,   
				b.betteam,   
				b.spositiontaking,   
				b.mpositiontaking,   
				b.apositiontaking,
				0 spositiontaking2,
				0 mpositiontaking2,
				0 apositiontaking2,    
				b.liveindicator,   
				b.modds,   
				b.custid,
				b.livehomescore,
				b.liveawayscore,
				0 AS finalhomescore, 
				0 AS finalawayscore,  
				odds.leagueid,
				l.sporttype,
				b.ip ,
				b.betfrom,
				b.matchid,
				CONVERT(BIT,0) AS IsNeutral,
				0 AS allowdelete,
				(b.winlost-b.actual_stake)  winlost,
				b.playercomm AS commission,
				(b.scomm - b.acomm) AS scomm,
				(b.acomm - b.comm) AS acomm,
				(b.comm - b.playercomm) AS comm,
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				'' AS showtime,
				b.winlostdate,
				b.BetCheck,
				'' AS transdesc,
				0 AS OddSpread
			FROM	
				dbo.bettrans_bk AS b WITH (nolock,index=IX_custid)   
				INNER JOIN dbo.Outright_bk AS odds WITH (NOLOCK) ON b.matchid=odds.orid   
				INNER JOIN bodb02.dbo.league l WITH (NOLOCK) ON odds.leagueid=l.leagueid     
			WHERE b.custid 			= @Custid	
				AND b.winlostdate 	BETWEEN @FromDate AND  @ToDate	
				AND b.bettype 		= 10
		END
	END

	-- Casino
	IF (
		EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 6)
	)
	BEGIN
		INSERT INTO #BetListData
		SELECT 
			 b.bettype,   
			 b.betid transid,   
			 ISNULL(b.BetID,0),
			 b.refno,
			 CONVERT(VARCHAR(50), b.refno) matchcode,   
			 '' AS race,
			 '' AS eventdate, 
			 0,0,
			 sdiscount,
			 adiscount,
			 discount,	 
			 0 AS homeid,   
			 0 AS awayid,  
			 '' settleTime, 
			 b.hdp1,
			 b.hdp2,
			 b.odds,   
			 0 finalodds,
			 0 finalodds2,
			 '' OddsType,  
			 b.status, 
			 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus,  
			 b.stake,   
			 b.actual_stake,
			 b.transdate,   
			 b.betteam,   
			 b.spositiontaking,  
			 b.mpositiontaking,   
			 b.apositiontaking, 
			 0 spositiontaking2,
			 0 mpositiontaking2,
			 0 apositiontaking2,   
			 b.liveindicator,   
			 b.modds,   
			 b.custid,
			 b.livehomescore, 
			 b.liveawayscore,
			 0 AS finalhomescore, 
			 0 AS finalawayscore,  
			 0 AS leagueid,  
			 251 AS sporttype, 
			 b.ip,
			 b.betfrom,
			 b.matchid,
			 CONVERT(BIT,0) AS IsNeutral,
			 0 AS allowdelete,
			 (b.winlost-b.actual_stake)  winlost,
			 b.playercomm AS commission,
			 (b.scomm - b.acomm) AS scomm,
			 (b.acomm - b.comm) AS acomm,
			 (b.comm - b.playercomm) AS comm,
			 b.awinlost,
			 b.mwinlost,
			 b.swinlost,
			 '' AS showtime,
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc,
			0 AS OddSpread
		FROM	dbo.bettrans_bk AS b WITH (nolock,index=IX_custid)	
			INNER JOIN #SportBettype s ON s.Bettype = b.bettype
		WHERE b.custid 			= @Custid	
			AND b.winlostdate 	BETWEEN @FromDate AND @ToDate	
			AND s.ProductId 	= 6 
	END

	-- IBC BIngo
	IF (
		EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 7)
	)
	BEGIN
		INSERT INTO #BetListData
		SELECT 
			 b.bettype,   
			 b.betid transid,   
			 ISNULL(b.BetID,0),
			 b.refno,
			 CONVERT(VARCHAR(50), b.refno) AS matchcode,   
			 '' AS race,
			 '' AS eventdate, 
			 0,0,
			 sdiscount,
			 adiscount,
			 discount,	 
			 0 AS homeid,   
			 0 AS awayid,  
			 '' settleTime, 
			 b.hdp1,
			 b.hdp2,
			 b.odds,   
			 0 finalodds,
			 0 finalodds2,
			 '' OddsType,  
			 b.status,  
			 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus, 
			 b.stake,  
			 b.actual_stake, 
			 b.transdate,   
			 b.betteam,   
			 b.spositiontaking,  
			 b.mpositiontaking,   
			 b.apositiontaking, 
			 0 spositiontaking2,
			 0 mpositiontaking2,
			 0 apositiontaking2,   
			 b.liveindicator,   
			 b.modds,   
			 b.custid,
			 b.livehomescore, 
			 b.liveawayscore,
			 0 AS finalhomescore, 
			 0 AS finalawayscore,  
			 0 AS leagueid,  
			 252 AS sporttype, 
			 b.ip,
			 b.betfrom,
			 b.matchid,
			 CONVERT(BIT,0) AS IsNeutral,
			 0 AS allowdelete,
			 (b.winlost-b.actual_stake)  winlost,
			 b.playercomm AS commission,
			 (b.scomm - b.acomm) AS scomm,
			 (b.acomm - b.comm) AS acomm,
			 (b.comm - b.playercomm) AS comm,
			 b.awinlost,
			 b.mwinlost,
			 b.swinlost,
			 '' AS showtime,
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc,
			0 AS OddSpread
		FROM dbo.bettrans_bk AS b WITH (nolock,index=IX_custid)	
			INNER JOIN #SportBettype s ON s.Bettype = b.bettype
		WHERE b.custid 			= @Custid	
			AND b.winlostdate 	BETWEEN @FromDate AND @ToDate 
			AND s.ProductId 	= 7 	
	END

	-- Keno
	IF (
		EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 8)
	)
	BEGIN
		INSERT INTO #BetListData
		SELECT 
			 b.bettype,   
			 b.betid transid,   
			 ISNULL(b.BetID,0),
			 b.refno,
			 CONVERT(VARCHAR(50), b.refno) AS matchcode,   
			 '' AS race,
			 '' AS eventdate, 
			 0,0,
			 sdiscount,
			 adiscount,
			 discount,	 
			 0 AS homeid,   
			 0 AS awayid,  
			 '' settleTime, 
			 b.hdp1,
			 b.hdp2,
			 b.odds,   
			 0 finalodds,
			 0 finalodds2,
			 '' OddsType,  
			 b.status,  
			 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus, 
			 b.stake,  
			 b.actual_stake, 
			 b.transdate,   
			 d.ChoiceId betteam,   
			 b.spositiontaking,  
			 b.mpositiontaking,   
			 b.apositiontaking, 
			 0 spositiontaking2,
			 0 mpositiontaking2,
			 0 apositiontaking2,   
			 b.liveindicator,   
			 b.modds,   
			 b.custid,
			 b.livehomescore, 
			 b.liveawayscore,
			 0 AS finalhomescore, 
			 0 AS finalawayscore,  
			 0 AS leagueid,  
			 202 AS sporttype, 
			 b.ip,
			 b.betfrom,
			 d.GameId matchid,
			 CONVERT(BIT,0) AS IsNeutral,
			 0 AS allowdelete,
			 (b.winlost-b.actual_stake)  winlost,
			 b.playercomm AS commission,
			 (b.scomm - b.acomm) AS scomm,
			 (b.acomm - b.comm) AS acomm,
			 (b.comm - b.playercomm) AS comm,
			 b.awinlost,
			 b.mwinlost,
			 b.swinlost,
			 '' AS showtime,
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc,
			0 AS OddSpread
		FROM dbo.bettrans_bk AS b WITH (nolock,index=IX_custid)	
			INNER JOIN #SportBettype s ON s.Bettype = b.bettype
			OUTER APPLY dbo.[f_ParseTransDesc](b.TransDesc, b.bettype) d
		WHERE b.custid 			= @Custid	
			AND b.winlostdate 	BETWEEN @FromDate AND @ToDate
			AND s.ProductId 	= 8 	
	END

	-- P2P
	IF (
		EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 9)
	)
	BEGIN
		
		INSERT INTO #BetListData
		SELECT 
			 b.bettype,   
			 b.transid,   
			 ISNULL(b.BetID,0),
			 b.refno,
			 '' matchcode,   
			 '' AS race,
			 '' AS eventdate, 
			 0,0,
			 sdiscount,
			 adiscount,
			 discount,	 
			 0 AS homeid,   
			 0 AS awayid,  
			 '' settleTime, 
			 b.hdp1,
			 b.hdp2,
			 b.odds,   
			 0 finalodds,
			 0 finalodds2,
			 '' OddsType,  
			 b.status,  
			 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus, 
			 b.stake,   
			 b.actual_stake,
			 b.transdate,   
			 b.betteam,   
			 b.spositiontaking,  
			 b.mpositiontaking,   
			 b.apositiontaking, 
			 0 spositiontaking2,
			 0 mpositiontaking2,
			 0 apositiontaking2,   
			 b.liveindicator,   
			 b.modds,   
			 b.custid,
			 b.livehomescore, 
			 b.liveawayscore,
			 0 AS finalhomescore, 
			 0 AS finalawayscore,  
			 0 AS leagueid,  
			 253 AS sporttype, 
			 b.ip,
			 b.betfrom,
			 b.matchid,
			 CONVERT(BIT,0) AS IsNeutral,
			 0 AS allowdelete,
			 (b.winlost-b.actual_stake)  winlost,
			 b.playercomm AS commission,
			 (b.scomm - b.acomm) AS scomm,
			 (b.acomm - b.comm) AS acomm,
			 (b.comm - b.playercomm) AS comm,
			 b.awinlost,
			 b.mwinlost,
			 b.swinlost,
			 '' AS showtime,
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc,
			0 AS OddSpread
		FROM dbo.bettrans_bk AS b WITH (nolock,index=IX_custid)	
			INNER JOIN #SportBettype s ON s.Bettype = b.bettype
		WHERE b.custid 			= @Custid	
			AND b.winlostdate 	BETWEEN @FromDate AND @ToDate
			AND s.ProductId 	= 9 	
	END

	-- HR
	IF (
		EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 2)
	)
	BEGIN
		INSERT INTO #BetListData 
		SELECT 
			b.bettype,
			b.transid,   
			ISNULL(b.BetID,0),
			b.refno,
			odds.matchcode, 
			odds.groupmatch AS race,
			odds.eventdate AS eventdate,
			b.virtualrate,
			--isnumeric(odds.programID),
			CASE WHEN b.currency2 IS NULL THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS isShowOTExRate,
			b.sdiscount,
			b.adiscount,
			b.discount,	  
			odds.teamid AS homeid,
			0 AS awayid,
			'' settleTime, 
			b.hdp1,
			b.hdp2,
			b.odds,   
			bm.finalodds,
			bm.finalodds2,
			'' OddsType,  
			b.status,   
			CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus,
			b.stake,   
			b.actual_stake,
			b.transdate transdate,   
			b.betteam,   
			CASE WHEN b.bettype IN (33,43) THEN bm.spositiontaking ELSE b.spositiontaking END,   
			CASE WHEN b.bettype IN (33,43) THEN bm.mpositiontaking ELSE b.mpositiontaking END ,   
			CASE WHEN b.bettype IN (33,43) THEN bm.apositiontaking ELSE b.apositiontaking END, 
			CASE WHEN b.bettype IN (33,43) THEN bm.spositiontaking2 ELSE 0 END ,   
			CASE WHEN b.bettype IN (33,43) THEN bm.mpositiontaking2 ELSE 0 END,   
			CASE WHEN b.bettype IN (33,43) THEN bm.apositiontaking2 ELSE 0 END,	  
			b.liveindicator,   
			b.modds,   
			b.custid,
			b.livehomescore,
			b.liveawayscore,
			0 AS finalhomescore, 
			0 AS finalawayscore,  
			odds.leagueid,
			l.sporttype,
			b.ip ,
			b.betfrom,
			b.matchid,
			CONVERT(BIT,0) AS IsNeutral,
			0 AS allowdelete,
			(b.winlost-b.actual_stake)  winlost,
			b.playercomm AS commission,
			(b.scomm - b.acomm) AS scomm,
			(b.acomm - b.comm) AS acomm,
			(b.comm - b.playercomm) AS comm,
			b.awinlost,
			b.mwinlost,
			b.swinlost,
			'' AS showtime,
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc,
			0 AS OddSpread
		FROM dbo.bettrans_bk AS b WITH (nolock,index=IX_custid)   
			INNER JOIN dbo.Outright_bk AS odds WITH (NOLOCK) ON b.matchid = odds.orid   
			INNER JOIN bodb02.dbo.league l WITH (NOLOCK) ON odds.leagueid = l.leagueid    
			INNER JOIN #SportBettype s ON s.Bettype = b.bettype
			/*LEFT JOIN (			
				SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking, t.finalodds,
					f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2, f.finalodds finalodds2
				FROM dbo.bettransm t WITH (NOLOCK)
					INNER JOIN dbo.bettransm f WITH (NOLOCK) 
					ON t.refno = f.refno 
				WHERE t.winlostdate BETWEEN @FromDate AND @ToDate
					AND t.custid = @Custid
					AND t.bettype IN (31,41) 
					AND f.bettype IN (32,42)
			) bm ON b.transid = bm.refno*/
			OUTER APPLY (			
				SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking, t.finalodds,
					f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2, f.finalodds finalodds2
				FROM dbo.bettransm t WITH (NOLOCK)
					INNER JOIN dbo.bettransm f WITH (NOLOCK) 
					ON t.refno 		= f.refno 
				WHERE t.refno		= b.transid
					AND t.bettype 	IN (31,41) 
					AND f.bettype 	IN (32,42)
			) bm 
		WHERE b.custid 			= @Custid	
			AND b.winlostdate 	BETWEEN @FromDate AND @ToDate 
			AND s.ProductId 	= 2
	END

	-- Virtual HR
	IF (
		EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 5)
	)
	BEGIN
		INSERT INTO #BetListData
		SELECT 
			b.bettype,
			b.transid,
			'' betid,
			b.refno,
			o.RacerNum matchcode, --Horse Number
			b.oddsid AS Race, --Outright ID
			'' eventdate,
			0,
			0,
			b.sdiscount,
			b.adiscount,
			b.discount,	
			o.RacerID AS homeID, 
			0 AS awayID,
			'' settleTime,
			b.hdp1,
			b.hdp2,
			b.odds,   
			0 finalodds,
			0 finalodds2,
			b.OddsType,  
			b.status,
			CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus, 
			stake,
			actual_stake,
			b.transdate,
			'' betteam, 
			CASE WHEN b.bettype = 1233 THEN bm.spositiontaking ELSE b.spositiontaking END,     
			CASE WHEN b.bettype = 1233 THEN bm.mpositiontaking ELSE b.mpositiontaking END ,     
			CASE WHEN b.bettype = 1233 THEN bm.apositiontaking ELSE b.apositiontaking END,   
			CASE WHEN b.bettype = 1233 THEN bm.spositiontaking2 ELSE 0 END ,     
			CASE WHEN b.bettype = 1233 THEN bm.mpositiontaking2 ELSE 0 END,     
			CASE WHEN b.bettype = 1233 THEN bm.apositiontaking2 ELSE 0 END,
			0 liveindicator,   
			b.modds,   
			b.custid,
			b.livehomescore, 
			b.liveawayscore, 
			0 finalhomescore, 
			0 finalawayscore, 
			r.leagueid,
			r.sporttype,
			b.ip,
			b.betfrom,
			b.matchid,
			CONVERT (BIT, 0) AS IsNeutral,
			0 AS allowdelete,
			(b.winlost-b.actual_stake)  winlost,
			b.playercomm AS commission,
			(b.scomm - b.acomm),
			(b.acomm - b.comm),
			(b.comm - b.playercomm),
			b.awinlost,
			b.mwinlost,
			b.swinlost,
			r.EventTime showtime, -- race name
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc,
			0 AS OddSpread
		FROM 
			bettrans_bk AS b WITH (nolock,index=IX_custid)    
			INNER JOIN VSOutright_bk o WITH (NOLOCK) ON b.oddsid = o.Orid
			INNER JOIN bodb02.dbo.VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
			INNER JOIN #SportBettype s ON s.BetType = b.BetType 
			/*LEFT JOIN (     
				SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking,
				  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2
				FROM bettransm t WITH (NOLOCK)  
					INNER JOIN bettransm f WITH (NOLOCK) 
					ON t.refno = f.refno   
				WHERE t.winlostdate BETWEEN @FromDate AND @ToDate
					AND t.custid 	= @Custid
					AND t.bettype 	= 1231 
					AND f.bettype 	= 1232 
			) bm ON b.refno = bm.refno*/
			OUTER APPLY (     
				SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking,
				  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2
				FROM dbo.bettransm t WITH (NOLOCK)  
					INNER JOIN dbo.bettransm f WITH (NOLOCK) 
					ON t.refno 		= f.refno   
				WHERE t.refno		= b.refno
					AND t.bettype 	= 1231 
					AND f.bettype 	= 1232 
			) bm
		WHERE b.custid 			= @Custid	
			AND b.winlostdate 	BETWEEN @FromDate AND @ToDate  
			AND s.ProductId 	= 5
			AND s.eventtype		= 3
			
	END

	-- Gold Deluxe
	IF (
		EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 12)
	)
	BEGIN
		INSERT INTO #BetListData
		SELECT 
			 b.bettype,   
			 b.transid, 
			 ISNULL(b.betid,0) betid,
			 b.refno,
			 '' AS matchcode,   
			 '' AS race,
			 '' AS eventdate, 
			 0,
			 0,
			 sdiscount,
			 adiscount,
			 discount,	 
			 0 AS homeid,   
			 0 AS awayid,  
			 '' settleTime, 
			 b.hdp1,
			 b.hdp2,
			 b.odds,   
			 0 finalodds,
			 0 finalodds2,
			 '' OddsType,  
			 b.status,  
			 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus, 
			 b.stake,  
			 b.actual_stake,    
			 b.transdate,   
			 b.betteam,   
			 b.spositiontaking,  
			 b.mpositiontaking,   
			 b.apositiontaking, 
			 0 spositiontaking2,
			 0 mpositiontaking2,
			 0 apositiontaking2,   
			 b.liveindicator,   
			 b.modds,   
			 b.custid,
			 b.livehomescore, 
			 b.liveawayscore,
			 0 AS finalhomescore, 
			 0 AS finalawayscore,  
			 0 AS leagueid,  
			 255 AS sporttype, 
			 b.ip,
			 b.betfrom,
			 b.matchid,
			 CONVERT(BIT,0) AS IsNeutral,
			 0 AS allowdelete,
			 (b.winlost-b.actual_stake)  winlost,
			 b.playercomm AS commission,
			 (b.scomm - b.acomm),
			 (b.acomm - b.comm),
			 (b.comm - b.playercomm),
			 b.awinlost,
			 b.mwinlost,
			 b.swinlost,
			 '' AS showtime,
			 b.winlostdate,
			 b.BetCheck,
			'' AS transdesc,
			0 AS OddSpread
		FROM	dbo.bettrans_bk b WITH (nolock,index=IX_custid)   
			INNER JOIN #SportBettype s ON s.Bettype = b.bettype
		WHERE b.custid 			= @Custid	
			AND b.winlostdate 	BETWEEN @FromDate AND @ToDate
			AND s.ProductId 	= 12
	END

	-- Micro Gaming
	IF (
		EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 13)
	)
	BEGIN
		INSERT INTO #BetListData
		SELECT 
			b.bettype,
			b.transid,
			ISNULL(b.BetID, 0),
			b.refno,
			'' AS matchcode,
			'' AS race,
			'' AS eventdate,
			0,
			0,
			sdiscount,
			adiscount,
			discount,
			0 AS homeid,
			0 AS awayid,
			'' settleTime,
			b.hdp1,
			b.hdp2,
			b.odds,
			0 finalodds,
			0 finalodds2,
			'' OddsType,
			b.status,
			CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus,
			b.stake,
			b.actual_stake,
			b.transdate,
			'' AS betteam,
			b.spositiontaking,
			b.mpositiontaking,
			b.apositiontaking,
			0 spositiontaking2,
			0 mpositiontaking2,
			0 apositiontaking2,
			b.liveindicator,
			b.modds,
			b.custid,
			b.livehomescore,
			b.liveawayscore,
			0 AS finalhomescore,
			0 AS finalawayscore,
			0 AS leagueid,
			203 AS sporttype,
			b.ip,
			b.betfrom,
			0 AS matchid,
			CONVERT(BIT, 0) AS IsNeutral,
			0 AS allowdelete,
			(b.winlost - b.actual_stake) winlost,
			b.playercomm AS commission,
			(b.scomm - b.acomm) AS scomm,
			(b.acomm - b.comm) AS acomm,
			(b.comm - b.playercomm) AS comm,
			b.awinlost,
			b.mwinlost,
			b.swinlost,
			'' AS showtime,
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc,
			0 AS OddSpread
		FROM dbo.bettrans_bk AS b WITH (nolock,index=IX_custid)
			INNER JOIN #SportBettype AS s ON s.Bettype = b.bettype
		WHERE b.custid 			= @Custid	
			AND b.winlostdate 	BETWEEN @FromDate AND @ToDate
			AND s.ProductId 	= 13
	END

	-- Colossus Bet
	IF (
		EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 15)
	)
	BEGIN
		INSERT INTO #BetListData
		SELECT 
			b.bettype,
			b.transid,
			ISNULL(b.BetID, 0),
			b.refno,
			'' AS matchcode,
			'' AS race,
			'' AS eventdate,
			0,
			0,
			sdiscount,
			adiscount,
			discount,
			0 AS homeid,
			0 AS awayid,
			'' settleTime,
			0 AS hdp1,
			0 AS hdp2,
			0 AS odds,
			0 finalodds,
			0 finalodds2,
			'' OddsType,
			b.status,
			CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus,
			b.stake,
			b.actual_stake,
			b.transdate,
			'' AS betteam,
			b.spositiontaking,
			b.mpositiontaking,
			b.apositiontaking,
			0 spositiontaking2,
			0 mpositiontaking2,
			0 apositiontaking2,
			0 AS liveindicator,
			0 AS modds,
			b.custid,
			b.livehomescore,
			b.liveawayscore,
			0 AS finalhomescore,
			0 AS finalawayscore,
			0 AS leagueid,
			204 AS sporttype,
			b.ip,
			b.betfrom,
			0 AS matchid,
			CONVERT(BIT, 0) AS IsNeutral,
			0 AS allowdelete,
			(b.winlost - b.actual_stake) winlost,
			b.playercomm AS commission,
			(b.scomm - b.acomm) AS scomm,
			(b.acomm - b.comm) AS acomm,
			(b.comm - b.playercomm) AS comm,
			b.awinlost,
			b.mwinlost,
			b.swinlost,
			'' AS showtime,
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc,
			0 AS OddSpread
		FROM dbo.bettrans_bk AS b WITH (nolock,index=IX_custid)
			INNER JOIN #SportBettype AS s ON s.Bettype = b.bettype
		WHERE b.custid 			= @Custid	
			AND b.winlostdate 	BETWEEN @FromDate AND @ToDate
			AND s.ProductId 	= 15
	END
	
	IF(EXISTS(SELECT TOP 1 1 FROM #BetListData WHERE Bettype IN (901, 902, 903)))
	BEGIN
		UPDATE betList
		SET betList.Odds	= originBetList.Odds
			,betList.Stake	= originBetList.Stake
			,betList.comm	= CASE WHEN betList.Bettype = 902 THEN ISNULL(commBetList.awinlost,0) ELSE betList.comm END
			,betList.BetID	= originBetList.Bettype
		FROM #BetListData AS betList
			INNER JOIN dbo.bettrans_bk AS originBetList WITH(NOLOCK) ON betList.RefNO = originBetList.TransID
			LEFT JOIN #BetListData AS commBetList ON betList.RefNO = commBetList.RefNO AND commBetList.Bettype = 903
		WHERE betList.Bettype IN (901, 902)

		DELETE #BetListData WHERE Sporttype = 1 AND Bettype = 903
	END
	
	SELECT * 
	FROM #BetListData 
	ORDER BY transid

	IF EXISTS (SELECT TOP 1 1 
				FROM #SportBettype sp 
					INNER JOIN #BetListData d ON d.bettype = sp.bettype 
				WHERE ProductID IN (4,12)) 
	BEGIN
		INSERT INTO #BetListDetailData
		SELECT 
			BG.refno,
			BG.odds, 
			BG.stake,
			BG.status,
			BG.apositiontaking, 
			BG.mpositiontaking, 
			BG.spositiontaking,
			BG.bettype,
			BG.betteam ,
			BG.TransDesc  
		FROM dbo.bettransg BG WITH (NOLOCK)
			INNER JOIN #SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid IN (4)
			INNER JOIN #BetListData B ON (BG.refno = B.refno AND BG.CustID = B.CustID AND sp.Productid IN (4))
		UNION ALL
		SELECT 
			BG.refno,
			BG.odds, 
			BG.stake,
			BG.status,
			BG.apositiontaking, 
			BG.mpositiontaking, 
			BG.spositiontaking,
			BG.bettype,
			BG.betteam,
			BG.TransDesc 
		FROM dbo.bettransg BG WITH (NOLOCK)
			INNER JOIN #SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid IN (12)
			INNER JOIN #BetListData B ON (BG.refno = B.transid AND BG.CustID = B.CustID AND sp.Productid IN (12))
	END 

	 SELECT * FROM #BetListDetailData BG ORDER BY refno

	 DROP TABLE #BetListData;
	 DROP TABLE #BetListDetailData;
	 DROP TABLE #SportBettype
END



GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetList_Old] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetList_Old] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetsSelBetList_Old] TO [vnteam]
