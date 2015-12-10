USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_BetsSelBetList]    Script Date: 10/8/2015 9:37:36 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_BetsSelBetList]
	@FromDate		DATETIME,
	@ToDate			DATETIME,
	@MoveBetsDay	DATETIME,
	@CustID			INT,
	@Bettype		INT = 0
AS

/*
	Created by: [Creator]
	Date: 2008
	Task: Bet List 
	DB: DBAGE.bodb02 
	Original: account\betlist.asp
	
	Revisions:
		- 20060225@[]: remove refno 
		- 20081223@PhuongNguyen: Get sdiscount, adiscount, discount, placing
		- 20081230@PhuongNguyen: Get livehomescore and liveawayscore, hdp1, hdp2
		- 20081231@PhuongNguyen: Remove placing
		- 20090109@PhuongNguyen: Get eventdate
		- 20090325@PhuongNguyen: out put AllowDelete base on bet type
		- 20090408@PhuongDao: Get checktime as SettleTime
		- 20090415@Daniel: Fix AllowDelete status for void and settled tickets
		- 20090416@KhoaTran: Get column BetFrom ( if befrom = p then 'no need to typ msg to delete' else 'need to type msg')
		- 20090509@Simon: Bet List For Casino
		- 20090517@KhoaTran: get column matchid
		- 20090528@PhuongDao: Get PT for Horseracing 
		- 20091002@Simon: Get Odds && OddsType columns.
		- 20091003@Jamie: Remove comstatus out 
		- 20091023@Simon: Displays Odds at Bet/Settle time
		- 20091205@Henry: Get more column: refno for viewing Mix Parlay detail
		- 20091229@Henry: Enhance Betlist by filtering: Bettype + support search in bettrans14
		- 20100409@Daniel: Support Mini game
		- 20100501@Daniel: Remove support Mini game, add agent W/L amount, agent's commission amount columns
		- 20100524@Jamie: Show currency2's exchange rate for OpenTote 
		- 20100525@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100611@Henry: Change mix-parlay match from 0 to 9
		- 20100907@Henry: Add IBC Bingo bettype
		- 20101007@Henry: Change column transid from INT to BIGINT
		- 20101130@Henry: Add column betid for number game
		- 20101201@Henry: Return winlost-actual_stake for column winlost
		- 20110408@Amy: Change function to get Odds value and odds type	
		- 20110513@Lukas: re-arrange bettype
		- 20110524@Henry: change to use winlostdate instead of transdate
		- 20110711@Johnson: show exchange rate for SA Tote(Pool currency)
		- 20110802@Johnson:- Add column actual_stake into betlist 
						   - Add new bettype combination mix parlay
		- 20111122@Sophia: Add Checktime and SecAcceptFlag to show status waiting or running
		- 20111207@Sophia: Add P2P
		- 20120120@Sophia: Add Showtime for Table-hand-shoe of Live Casino
							Add sub detail for Live Casino
		- 20120217@Daniel: Allow to delete mix palay bet (whole ticket)
		- 20120405@Hurri: Exclude bettype 72 (P2P bet ticket) in the calculation of Casino
		- 20120416@Johnson: Correct column transid for p2p		
		- 20120423@Lukas: show transid of main ticket for all subticket of system parlay
		- 20120606@Sophia: Change datatype of stake to money
		- 20120626@Elodie: exclude outright, HR from sportbook ( in case of matchid = orid)
		- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype,f_GetChoice for odds, Oddstype, betteam
		- 20120927@Johnson: get commstatus column to check double comm losing
		- 20130227@Elodie: Add Virtual HR product
		- 20130405@Lukas: return value odds.teamid to alias name homeid instead of awayid
		- 20130718@Elodie: correct value of homeid and awayid
						   Get Winlostdate field
		- 20140306@Dom: Add Keno
		- 20140318@Dom: #13487 Prevent user to delete LAS ticket in bet list accounting site
		- 20140908@Dom:	[Redmine #22012] Update VS conditions
		- 20141103@Dom: Apply sport bettype matrix
		- 20150122@Dom: HotFix #29646 Fix bug virtual HR
		- 20150415@Sophia: Get Betcheck for Betradar
		- 20150506@Tom: Support Gold Deluxe Product [#34847]
		- 20150506@Bobby: Add transdesc column for metric gaming bettypes (801-899)
		- 20150615@Edward: Support for BetTrade
		- 20150707@Bobby: Exclude Metric Gaming running ticket from bettrans table
		- 20150625@Edward: Support for Microgaming
		- 20150805@Bobby: Enhance code for SQL parameter sniffing
		- 20150825@Kos: Add OddsSpread column to support Myanmar Odds
		- 20150828@Kos: Support Colossus Bet
		- 20150930@Bobby: Enhance performance - re-arrange indexers
		- 20151008@Kos: Support Microgaming RNG Game and AG Casino
		- 20151022@Kos: Return [translog].[transid3rd] and [bettransm].[betcheck] to support view CB ticket detail
		- 20151030@Kos: Change ProductId/SportType of Microgaming RNG Casino
		- 20151207@Kos: Add index hint to fix performance issue
		- 20151210@Kos: Change odds, modds data type from SMALLMONEY to MONEY [Redmine: #48660]
*/

BEGIN
	SET NOCOUNT ON  

	DECLARE @tempBettype INT
	
	SELECT @tempBettype = @Bettype
	
	--list of bettype not allowed to delete
	DECLARE @tableBettypeNotAllowDelete TABLE(typeid INT NOT NULL)

	INSERT INTO @tableBettypeNotAllowDelete (typeid) 
	SELECT 31 UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL 
	SELECT 51 UNION ALL SELECT 52 UNION ALL SELECT 53 UNION ALL SELECT 54 UNION ALL SELECT 55 UNION ALL SELECT 56 UNION ALL 
	SELECT 61 UNION ALL SELECT 62 UNION ALL SELECT 63 UNION ALL SELECT 64 UNION ALL SELECT 65 UNION SELECT 66
	--End

	--list of LAS agent not allowed to delete
	DECLARE @strLASAgent VARCHAR(1000)

	EXEC DBLAS.LASDB.dbo.Las_Get_recommend @StringRec = @strLASAgent OUTPUT
	SELECT val AS CustID 
	INTO #LASAgent
	FROM dbo.strSplit(@strLASAgent, '^')
	--END 

	----Get Sport Bettype Matrix------
	CREATE TABLE #SportBettype (ProductID TINYINT, Bettype SMALLINT, EventType TINYINT, SubProduct VARCHAR(500))

	INSERT INTO #SportBettype
	EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode = 5

	IF @tempBettype <> 0
	BEGIN
		DELETE #SportBettype 
		WHERE Bettype <> @tempBettype
	END

	CREATE TABLE #BetListData (
		bettype			INT,
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
		odds			MONEY,
		finalodds		MONEY,
		finalodds2		MONEY,
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
		liveindicator	 BIT,
		modds			MONEY,
		custid			INT,
		livehomescore	INT, 
		liveawayscore	INT, 
		finalhomescore	INT, 
		finalawayscore	INT, 
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
		odds			MONEY, 
		stake			MONEY,
		status			VARCHAR(50),
		apositiontaking SMALLMONEY, 
		mpositiontaking SMALLMONEY, 
		spositiontaking SMALLMONEY,
		bettype			SMALLINT,
		betteam			NVARCHAR(50),
		TransDesc		VARCHAR(300)
	)

	IF @Todate > @MoveBetsDay
	BEGIN
		/* normal tickets 
			- SB		: ProductID = 1
			- NG		: ProductID = 3
			- LC		: ProductID = 4
			- VS		: ProductID = 5
		*/
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID IN (1, 3, 4, 5))
		BEGIN
			INSERT INTO #BetListData
			SELECT
				b.bettype,
				b.transid,
				ISNULL(b.betid, 0),
				b.refno,
				m.matchcode,
				'' AS race,
				m.eventdate,
				0,
				0,
				b.sdiscount,
				b.adiscount,
				b.discount,
				m.homeid,
				m.awayid,
				ISNULL(b.checktime, '') settleTime,
				b.hdp1,
				b.hdp2,
				b.odds,
				0 finalodds,
				0 finalodds2,
				b.OddsType,  
				CASE 
					WHEN b.status = 'running' AND ISNULL(b.SecAcceptFlag, 0) = 1 AND ISNULL(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
					ELSE b.status 
				END AS status,
				CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus, 
				stake,
				actual_stake,
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
				--CASE WHEN b.bettype IN (SELECT typeid FROM @tableBettypeNotAllowDelete) OR status NOT IN('running', 'waiting', 'WON', 'LOSE', 'DRAW') THEN 0 ELSE 1 END AS allowdelete,
				CASE WHEN b.bettype IN (SELECT typeid FROM @tableBettypeNotAllowDelete) 
							OR b.recommend IN (SELECT custid FROM #LASAgent) 
							OR statusID NOT IN(0, 1, 112, 113, 111) THEN 0 ELSE 1 END AS allowdelete,
				(b.winlost-b.actual_stake)  winlost,
				b.playercomm AS commission,
				(b.scomm - b.acomm),
				(b.acomm - b.comm),
				(b.comm - b.playercomm),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				m.showtime,
				b.winlostdate,
				b.BetCheck,
				CASE WHEN b.bettype BETWEEN 801 AND 899 THEN b.transdesc ELSE '' END AS transdesc,
				ISNULL(b.oddsspread, 0) AS OddsSpread
			FROM 
				dbo.bettrans AS b WITH (NOLOCK, INDEX=IX_custid_matchid_bettype) 
				INNER JOIN dbo.match AS m WITH (NOLOCK) ON b.matchid = m.matchid --phuong.nguyen, remove left join match_remark
				INNER JOIN #SportBettype s ON s.Bettype = b.bettype
			WHERE b.custid = @Custid 
				AND b.matchid > 0
				AND s.EventType = 1
				--exclude metric gaming running ticket
				AND (s.SubProduct NOT IN('MG-SuperLive') OR (s.SubProduct IN('MG-SuperLive') AND b.statusID NOT IN (0, 1)))
				AND b.winlostdate BETWEEN @FromDate AND @ToDate 
			
			UNION ALL -- translog metric gaming
			SELECT 
				b.gameid AS bettype,  
				b.translogid AS transid,  
				0 AS BetID,  
				b.translogid AS refno,  
				m.matchcode,  
				'' AS race,  
				m.eventdate,  
				0 AS virtualrate,  
				0 AS isShowOTExRate,
				b.sdiscount,
				b.adiscount,
				b.discount,	
				m.homeid,
				m.awayid,
				'' AS settleTime,  
				0 AS hdp1,  
				0 AS hdp2,  
				b.odds,   
				0 finalodds,
				0 finalodds2,
				--b.OddsType,  
				CASE 
					WHEN b.gameid IN (801, 803, 804, 805, 806) THEN CONVERT(TINYINT, ISNULL(b.custom1, 0))
					ELSE 0 
				END AS OddsType,
				b.status,
				0 AS comstatus, 
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
				0 AS livehomescore, 
				0 AS liveawayscore, 
				m.finalhomescore, 
				m.finalawayscore, 
				m.leagueid,
				m.sporttype,
				b.ip,
				'' AS betfrom,
				b.eventID,
				ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
				--CASE WHEN b.bettype IN (SELECT typeid FROM @tableBettypeNotAllowDelete) OR status NOT IN('running', 'waiting', 'WON', 'LOSE', 'DRAW') THEN 0 ELSE 1 END AS allowdelete,
				CASE WHEN b.gameID IN (SELECT typeid FROM @tableBettypeNotAllowDelete) 
							OR b.recommend IN (SELECT custid FROM #LASAgent) 
							OR statusID NOT IN(0, 1, 112, 113, 111) THEN 0 ELSE 1 END AS allowdelete,
				0 AS winlost,  
				0 AS commission,  
				0 AS scomm,  
				0 AS acomm,  
				0 AS comm,  
				0 AS awinlost,  
				0 AS mwinlost,  
				0 AS swinlost,  
				m.showtime,
				b.winlostdate,
				'' AS BetCheck,
				b.transdesc,
				0 AS OddsSpread
			FROM
				dbo.translog AS b WITH (NOLOCK)
				INNER JOIN dbo.match AS m WITH (NOLOCK) ON b.eventid = m.matchid
				INNER JOIN #SportBettype s ON b.gameid = s.Bettype
			WHERE
				b.custid = @Custid 
				AND s.SubProduct IN('MG-SuperLive')
				AND b.statusID IN (0,1)
				AND b.winlostdate BETWEEN @FromDate AND @ToDate 

			--Mix Parlay
			IF (EXISTS(SELECT TOP 1 1 FROM  #SportBettype s WHERE ProductID = 1 AND Bettype = 9))
			BEGIN
				INSERT INTO #BetListData
				SELECT 
					9 bettype,
					b.transid,
					ISNULL(b.betid, 0),
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
					CONVERT(BIT, 0) AS IsNeutral,
					CASE WHEN statusID = 0 AND b.recommend NOT IN (SELECT custid FROM #LASAgent) THEN 1 ELSE 0 END AS allowdelete,
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
					0 AS OddsSpread
				FROM dbo.bettrans AS b WITH (NOLOCK)
				WHERE b.custid 		= @Custid  
					AND matchid 	= 9
					AND b.bettype 	= 9
					AND b.winlostdate 	BETWEEN @FromDate AND @ToDate
			END
			
			--Combination Mix Parlay
			IF (EXISTS(SELECT TOP 1 1 FROM  #SportBettype s WHERE ProductID = 1 AND Bettype = 29))
			BEGIN
				INSERT INTO #BetListData
				SELECT 
					29 bettype,
					CASE WHEN ISNULL(b.betID,0) = 0 THEN b.transid ELSE b.betID END AS transid,
					ISNULL(b.betid,0),
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
					b.transdate,
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
					CONVERT(BIT, 0) AS IsNeutral,
					0 AS allowdelete,
					(b.winlost - b.actual_stake)  winlost,
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
					0 AS OddsSpread
				FROM dbo.bettrans AS b WITH (NOLOCK)
				WHERE b.custid 		= @Custid
					AND matchid 	= 29
					AND b.bettype 	= 29
					AND b.winlostdate BETWEEN @FromDate AND @ToDate
			END
			
			-- Outright
			IF (EXISTS(SELECT TOP 1 1 FROM  #SportBettype s WHERE ProductID = 1 AND Bettype = 10))
			BEGIN
				INSERT INTO #BetListData
				SELECT 
					b.bettype,
					b.transid,
					ISNULL(b.betid, 0),
					b.refno,
					odds.matchcode, 
					odds.groupmatch AS race,
					odds.eventdate,
					0,
					0,
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
					--CASE WHEN b.bettype IN (SELECT typeid FROM @tableBettypeNotAllowDelete) OR b.status NOT IN('running', 'waiting', 'WON', 'LOSE', 'DRAW') THEN 0 ELSE 1 END AS allowdelete,
					CASE WHEN b.bettype IN (SELECT typeid FROM @tableBettypeNotAllowDelete) 
							OR b.statusID NOT IN(0, 1, 112, 113, 111) 
							OR b.recommend IN (SELECT custid FROM #LASAgent)
							THEN 0 ELSE 1 END AS allowdelete,
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
					0 AS OddsSpread
				FROM	dbo.bettrans AS b WITH (NOLOCK, INDEX=IX_custid_matchid_bettype)
					INNER JOIN dbo.outright AS odds WITH (NOLOCK) ON b.matchid = odds.orid
					INNER JOIN dbo.league l WITH (NOLOCK) ON odds.leagueid = l.leagueid
				WHERE b.custid 		= @Custid 
					AND b.matchid 	> 0
					AND b.bettype 	= 10
					AND b.winlostdate 	BETWEEN @FromDate AND @ToDate
			END

			UPDATE betList
			SET betList.Odds	= originBetList.Odds
				,betList.Stake	= originBetList.Stake
				,betList.comm	= CASE WHEN betList.Bettype = 902 THEN ISNULL(commBetList.awinlost, 0) ELSE betList.comm END
				,betList.BetID	= originBetList.Bettype
			FROM #BetListData AS betList
				INNER JOIN bettrans AS originBetList WITH(NOLOCK) ON betList.RefNO = originBetList.TransID
				LEFT JOIN #BetListData AS commBetList ON betList.RefNO = commBetList.RefNO AND commBetList.Bettype = 903
			WHERE betList.Sporttype = 1 AND betList.Bettype IN (901, 902)
		END
		
		-- Casino, Bingo
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID IN (6, 7))
		BEGIN	
			INSERT INTO #BetListData
			SELECT 
				b.bettype,
				b.betid transid,
				ISNULL(b.betid,0),
				b.refno,
				CONVERT(VARCHAR(50), b.refno) matchcode,
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
				CASE
					WHEN s.ProductId = 6 THEN 251
					WHEN s.ProductId = 7 THEN 252
				END AS sporttype, 
				b.ip,
				b.betfrom,
				b.matchid,
				CONVERT(BIT,0) AS IsNeutral,
				0 AS allowdelete,
				(b.winlost - b.actual_stake)  winlost,
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
				0 AS OddsSpread
			FROM dbo.bettrans b WITH (NOLOCK)
				INNER JOIN #SportBettype s ON s.Bettype = b.bettype
			WHERE b.custid 			= @Custid
				AND b.matchid 		= 0
				AND	s.ProductId IN (6, 7)
				AND b.winlostdate 	BETWEEN @FromDate AND @ToDate 	
		END
		
		-- Keno
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 8)
		BEGIN	
			INSERT INTO #BetListData
			SELECT 
				b.bettype,   
				b.betid transid, 
				ISNULL(b.betid,0),
				b.refno,
				CONVERT(VARCHAR(50), b.refno) AS matchcode,   
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
				0 AS OddsSpread
			FROM	bettrans b WITH (NOLOCK, INDEX=IX_custid_matchid_bettype)   
				INNER JOIN #SportBettype s ON s.Bettype = b.bettype
				OUTER APPLY dbo.[f_ParseTransDesc](b.TransDesc, b.bettype) d
			WHERE	b.custid 		= @Custid 
				AND b.matchid 		> 0
				AND	s.ProductId 	= 8
				AND b.winlostdate 	BETWEEN @FromDate AND @ToDate
					
			UNION ALL-- translog
			SELECT 
				b.gameid bettype,   
				0 AS transid, 
				0 AS betid,
				b.translogid ,
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
				0 hdp1,
				0 hdp2,
				b.odds,   
				0 finalodds,
				0 finalodds2,
				'' OddsType,  
				b.status,  
				0 AS comstatus, 
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
				0 liveindicator,   
				0 modds,   
				b.custid,
				0 livehomescore, 
				0 liveawayscore,
				0 AS finalhomescore, 
				0 AS finalawayscore,  
				0 AS leagueid,  
				202 AS sporttype, 
				b.ip,
				b.betfrom,
				d.GameId matchid,
				CONVERT(BIT,0) AS IsNeutral,
				0 AS allowdelete,
				(-b.actual_stake)  winlost,
				0 AS commission,
				0,
				0,
				0,
				0,
				0,
				0,
				'' AS showtime,
				b.winlostdate,
				'' AS BetCheck,
				'' AS transdesc,
				0 AS OddsSpread
			FROM translog b WITH (NOLOCK)   
				INNER JOIN #SportBettype s ON s.Bettype = b.gameID
				OUTER APPLY dbo.[f_ParseTransDesc](b.TransDesc, b.gameid) d
			WHERE b.custid 			= @Custid
				AND s.ProductId 	= 8	
				AND b.statusID 		= 0
				AND b.winlostdate 	BETWEEN @FromDate AND @ToDate
		END
		
		-- P2P
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 9)
		BEGIN	
			INSERT INTO #BetListData
			SELECT 
				b.bettype,  
				b.transid,   
				ISNULL(b.betid,0),
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
				CONVERT(BIT, 0) AS IsNeutral,
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
				0 AS OddsSpread
			FROM	dbo.bettrans b WITH (NOLOCK)   
				INNER JOIN #SportBettype s ON s.Bettype = b.bettype
			WHERE b.custid 			= @Custid
				AND b.matchid 		= 0
				AND	s.ProductId 	= 9
				AND b.winlostdate 	BETWEEN @FromDate AND @ToDate
		END
		
		-- HR
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 2)
		BEGIN
			INSERT INTO #BetListData 
			SELECT 
				b.bettype,
				b.transid,
				ISNULL(b.betid, 0),   
				b.refno,
				odds.matchcode, 
				odds.groupmatch AS race,
				odds.eventdate AS eventdate,
				b.virtualrate,
				--isnumeric(odds.programID),
				CASE WHEN b.currency2 IS NULL THEN CONVERT(BIT, 0) ELSE CONVERT(BIT, 1) END AS isShowOTExRate,
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
				CASE WHEN b.bettype IN (33,43) THEN bm.mpositiontaking ELSE b.mpositiontaking END,   
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
				CONVERT(BIT, 0) AS IsNeutral,
				0 AS allowdelete,
				(b.winlost - b.actual_stake)  winlost,
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
				0 AS OddsSpread
			FROM	bettrans AS b WITH (NOLOCK, INDEX=IX_custid_matchid_bettype)   
					INNER JOIN outright AS odds WITH (NOLOCK) ON b.matchid = odds.orid   
					INNER JOIN league l WITH (NOLOCK) ON odds.leagueid = l.leagueid    
					INNER JOIN #SportBettype s ON s.Bettype = b.bettype
					LEFT JOIN (
						SELECT
							t.refno, 
							t.apositiontaking , 
							t.mpositiontaking, 
							t.spositiontaking, 
							t.finalodds,
							f.apositiontaking apositiontaking2, 
							f.mpositiontaking mpositiontaking2, 
							f.spositiontaking spositiontaking2, 
							f.finalodds finalodds2
						FROM dbo.bettransm t WITH (NOLOCK)
							INNER JOIN dbo.bettransm f WITH (NOLOCK) 
							ON t.refno = f.refno 
						WHERE t.custid = @custid
							AND t.winlostdate BETWEEN @FromDate AND @ToDate
							AND t.bettype IN (31, 41) 
							AND f.bettype IN (32, 42)
					) bm ON b.transid = bm.refno 
			WHERE b.custid 			= @Custid
				AND b.matchid 		> 0
				AND	s.ProductId 	= 2
				AND b.winlostdate 	BETWEEN @FromDate AND @ToDate
		END
		
		-- Virtual HR
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 5)
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
				CASE WHEN b.bettype IN (SELECT typeid FROM @tableBettypeNotAllowDelete) 
						OR statusID NOT IN(0, 1, 112, 113, 111) 
						OR b.recommend IN (SELECT custid FROM #LASAgent)
						THEN 0 ELSE 1 END AS allowdelete,
				(b.winlost-b.actual_stake)  winlost,
				b.playercomm AS commission,
				(b.scomm - b.acomm),
				(b.acomm - b.comm),
				(b.comm - b.playercomm),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				r.EventTime showtime, -- Race Name
				b.winlostdate,
				b.BetCheck,
				'' AS transdesc,
				0 AS OddsSpread
			FROM 
				bettrans AS b WITH (NOLOCK, INDEX=IX_custid_matchid_bettype) 
				INNER JOIN VSOutright o WITH (NOLOCK) ON b.oddsid = o.Orid
				INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
				INNER JOIN #SportBettype s ON s.BetType = b.BetType 
				LEFT JOIN (
					SELECT 
						t.refno, 
						t.apositiontaking , 
						t.mpositiontaking, 
						t.spositiontaking,
						f.apositiontaking apositiontaking2, 
						f.mpositiontaking mpositiontaking2, 
						f.spositiontaking spositiontaking2
					FROM dbo.bettransm t WITH (NOLOCK)  
						INNER JOIN dbo.bettransm f WITH (NOLOCK) ON t.refno = f.refno   
					WHERE t.custid = @custid
						AND t.winlostdate BETWEEN @FromDate AND @ToDate
						AND t.bettype = 1231 
						AND f.bettype = 1232 
				) bm ON b.refno = bm.refno  
			WHERE b.custid 			= @Custid
				AND b.matchid		> 0
				AND s.ProductID 	= 5
				AND s.eventtype		= 3
				AND b.winlostdate 	BETWEEN @FromDate AND @ToDate
		END
		
		-- Gold Deluxe
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 12)
		BEGIN
			INSERT INTO #BetListData
			SELECT 
				b.bettype,   
				b.transid, 
				ISNULL(b.betid, 0) betid,
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
				(b.scomm - b.acomm),--Super comm
				(b.acomm - b.comm),--Master comm
				(b.comm - b.playercomm),--Agent comm
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				'' AS showtime,
				b.winlostdate,
				b.BetCheck,
				'' AS transdesc,
				0 AS OddsSpread
			FROM	dbo.bettrans b WITH (NOLOCK)   
				INNER JOIN #SportBettype s ON s.Bettype = b.bettype
			WHERE b.custid = @Custid 
				AND	b.matchid IN (0, 255)
				AND s.ProductID = 12
				AND b.winlostdate BETWEEN @FromDate AND @ToDate
					
			UNION ALL-- translog
			SELECT 
				b.gameid bettype,   
				0 AS transid, 
				0 AS betid,
				b.translogid refno,
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
				0 hdp1,
				0 hdp2,
				b.odds,   
				0 finalodds,
				0 finalodds2,
				'' OddsType,  
				b.status,  
				0 AS comstatus, 
				b.stake,  
				b.actual_stake,    
				b.transdate,   
				b.GameID3rd AS betteam,
				b.spositiontaking,  
				b.mpositiontaking,   
				b.apositiontaking, 
				0 spositiontaking2,
				0 mpositiontaking2,
				0 apositiontaking2,   
				0 liveindicator,   
				0 modds,   
				b.custid,
				0 livehomescore, 
				0 liveawayscore,
				0 AS finalhomescore, 
				0 AS finalawayscore,  
				0 AS leagueid,  
				255 AS sporttype, 
				b.ip,
				b.betfrom,
				0 matchid,
				CONVERT(BIT,0) AS IsNeutral,
				0 AS allowdelete,
				(-b.actual_stake)  winlost,
				0 AS commission,
				0,
				0,
				0,
				0,
				0,
				0,
				'' AS showtime,
				b.winlostdate,
				b.GameID3rd AS BetCheck,
				'' AS transdesc,
				0 AS OddsSpread
			FROM dbo.translog b WITH (NOLOCK)
				INNER JOIN #SportBettype s ON s.Bettype = b.gameid
			WHERE b.custid 			= @Custid
				AND b.statusid 		= 0
				AND s.ProductID 	= 12 	
				AND b.winlostdate 	BETWEEN @FromDate AND @ToDate
		END

		-- Microgaming Live Casino
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 13)
		BEGIN
			INSERT INTO #BetListData
			SELECT
				b.bettype,
				b.transid,
				ISNULL(b.betid, 0),
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
				0 AS finalodds,
				0 AS finalodds2,
				'' AS OddsType,
				b.status,
				CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus,
				b.stake,
				b.actual_stake,
				b.transdate,
				'' AS betteam,
				b.spositiontaking,
				b.mpositiontaking,
				b.apositiontaking,
				0 AS spositiontaking2,
				0 AS mpositiontaking2,
				0 AS apositiontaking2,
				b.liveindicator,
				b.modds,
				b.custid,
				0 AS livehomescore,
				0 AS liveawayscore,
				0 AS finalhomescore,
				0 AS finalawayscore,
				0 AS leagueid,
				203 AS sporttype,
				b.ip,
				b.betfrom,
				0 AS matchid,
				CONVERT(BIT, 0) AS IsNeutral,
				0 AS allowdelete,
				(b.winlost - b.actual_stake) AS winlost,
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
				0 AS OddsSpread
			FROM dbo.bettrans AS b WITH (NOLOCK)
				INNER JOIN #SportBettype AS s ON s.Bettype = b.bettype
			WHERE b.custid = @Custid 
				AND b.matchid = 203
				AND s.ProductId = 13
				AND b.winlostdate BETWEEN @FromDate AND @ToDate

			UNION ALL-- translog
			SELECT
				b.gameid AS bettype,
				0 AS transid,
				0 AS betid,
				b.translogid,
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
				'' AS settleTime,
				0 AS hdp1,
				0 AS hdp2,
				0 AS odds,
				0 AS finalodds,
				0 AS finalodds2,
				'' OddsType,
				b.status,
				0 AS comstatus,
				b.stake,
				b.actual_stake,
				b.transdate,
				'' AS betteam,
				b.spositiontaking,
				b.mpositiontaking,
				b.apositiontaking,
				0 AS spositiontaking2,
				0 AS mpositiontaking2,
				0 AS apositiontaking2,
				0 AS liveindicator,
				0 AS modds,
				b.custid,
				0 AS livehomescore,
				0 AS liveawayscore,
				0 AS finalhomescore,
				0 AS finalawayscore,
				0 AS leagueid,
				203 AS sporttype,
				b.ip,
				b.betfrom,
				0 AS matchid,
				CONVERT(BIT, 0) AS IsNeutral,
				0 AS allowdelete,
				(-b.actual_stake) winlost,
				0 AS commission,
				0,
				0,
				0,
				0,
				0,
				0,
				'' AS showtime,
				b.winlostdate,
				'' AS BetCheck,
				'' AS transdesc,
				0 AS OddsSpread
			FROM dbo.translog AS b WITH (NOLOCK)
				INNER JOIN #SportBettype AS s ON s.Bettype = b.gameID
			WHERE b.custid = @Custid 
				AND s.ProductId = 13
				AND b.statusID = 0
				AND b.winlostdate BETWEEN @FromDate AND @ToDate
		END

		-- Microgaming RNG Casino
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 17)
		BEGIN
			-- Microgaming - RNG Game (up to yesterday settled ticket)
			INSERT INTO #BetListData
			SELECT
				b.bettype,
				b.transid,
				ISNULL(b.betid, 0),
				b.refno,
				'' AS matchcode,
				'' AS race,
				'' AS eventdate,
				0,
				0,
				b.sdiscount,
				b.adiscount,
				b.discount,
				0 AS homeid,
				0 AS awayid,
				'' settleTime,
				0 AS hdp1,
				0 AS hdp2,
				0 AS odds,
				0 AS finalodds,
				0 AS finalodds2,
				'' AS OddsType,
				b.status,
				CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus,
				b.stake,
				b.actual_stake,
				b.transdate,
				'' AS betteam,
				b.spositiontaking,
				b.mpositiontaking,
				b.apositiontaking,
				0 AS spositiontaking2,
				0 AS mpositiontaking2,
				0 AS apositiontaking2,
				0 AS liveindicator,
				0 AS modds,
				b.custid,
				0 AS livehomescore,
				0 AS liveawayscore,
				0 AS finalhomescore,
				0 AS finalawayscore,
				0 AS leagueid,
				205 AS sporttype,
				b.ip,
				b.betfrom,
				0 AS matchid,
				CONVERT(BIT, 0) AS IsNeutral,
				0 AS allowdelete,
				(b.winlost - b.actual_stake) AS winlost,
				b.playercomm AS commission,
				(b.scomm - b.acomm),
				(b.acomm - b.comm),
				(b.comm - b.playercomm),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				'' AS showtime,
				b.winlostdate,
				'' AS BetCheck,
				'' AS transdesc,
				0 AS OddsSpread
			FROM dbo.bettrans AS b WITH (NOLOCK, INDEX=IX_custid_matchid_bettype)
				INNER JOIN #SportBettype AS s ON s.Bettype = b.bettype
			WHERE b.custid = @Custid 
				AND s.ProductId = 17
				AND b.winlostdate BETWEEN @FromDate AND @ToDate
				AND b.winlostdate < DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0)	-- not today

			IF @ToDate >= DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0)
				AND @FromDate <= DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0)	-- today
			BEGIN
				-- Today running ticket
				INSERT INTO #BetListData
				SELECT
					b.bettype,
					b.transid,
					ISNULL(b.betid, 0),
					b.refno,
					'' AS matchcode,
					'' AS race,
					'' AS eventdate,
					0,
					0,
					0 AS sdiscount,
					0 AS adiscount,
					0 AS discount,
					0 AS homeid,
					0 AS awayid,
					'' settleTime,
					0 AS hdp1,
					0 AS hdp2,
					0 AS odds,
					0 AS finalodds,
					0 AS finalodds2,
					'' AS OddsType,
					'Running' AS Status,
					CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus,
					SUM(brng.stake) AS stake,
					SUM(brng.actual_stake) AS actual_stake,
					b.transdate,
					'' AS betteam,
					0 AS spositiontaking,
					0 AS mpositiontaking,
					0 AS apositiontaking,
					0 AS spositiontaking2,
					0 AS mpositiontaking2,
					0 AS apositiontaking2,
					0 AS liveindicator,
					0 AS modds,
					b.custid,
					0 AS livehomescore,
					0 AS liveawayscore,
					0 AS finalhomescore,
					0 AS finalawayscore,
					0 AS leagueid,
					205 AS sporttype,
					b.ip,
					b.betfrom,
					0 AS matchid,
					CONVERT(BIT, 0) AS IsNeutral,
					0 AS allowdelete,
					0 AS winlost,
					0 AS commission,
					0 AS scomm,
					0 AS acomm,
					0 AS comm,
					0 AS awinlost,
					0 AS mwinlost,
					0 AS swinlost,
					'' AS showtime,
					b.winlostdate,
					'' AS BetCheck,
					'' AS transdesc,
					0 AS OddsSpread
				FROM dbo.bettrans AS b WITH (NOLOCK, INDEX=IX_custid_matchid_bettype)
					INNER JOIN dbo.bettransRnG AS brng WITH (NOLOCK) ON brng.RefNo = b.transid
					INNER JOIN #SportBettype AS s ON s.Bettype = b.bettype
				WHERE b.custid = @Custid 
					AND s.ProductId = 17
					AND b.winlostdate BETWEEN DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0) AND @ToDate		-- today
					AND brng.statusID = 0
				GROUP BY
					b.transid,
					ISNULL(b.BetID, 0),
					b.Bettype,
					b.refno,
					b.transdate,
					b.winlostdate,
					b.custid,
					b.IP,
					b.betfrom,
					b.currency,
					b.comstatus

				-- Today settled ticket
				INSERT INTO #BetListData
				SELECT
					b.bettype,
					b.transid,
					ISNULL(b.betid, 0),
					b.refno,
					'' AS matchcode,
					'' AS race,
					'' AS eventdate,
					0,
					0,
					b.sdiscount,
					b.adiscount,
					b.discount,
					0 AS homeid,
					0 AS awayid,
					'' settleTime,
					0 AS hdp1,
					0 AS hdp2,
					0 AS odds,
					0 AS finalodds,
					0 AS finalodds2,
					'' AS OddsType,
					CASE 
						WHEN SUM(brng.winlost - brng.actual_stake) = 0 THEN 'Draw'
						WHEN SUM(brng.winlost - brng.actual_stake) > 0 THEN 'Won'
						WHEN SUM(brng.winlost - brng.actual_stake) < 0 THEN 'Lose'
					END AS Status,
					CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus,
					SUM(brng.stake) AS stake,
					SUM(brng.actual_stake) AS actual_stake,
					b.transdate,
					'' AS betteam,
					b.spositiontaking,
					b.mpositiontaking,
					b.apositiontaking,
					0 AS spositiontaking2,
					0 AS mpositiontaking2,
					0 AS apositiontaking2,
					0 AS liveindicator,
					0 AS modds,
					b.custid,
					0 AS livehomescore,
					0 AS liveawayscore,
					0 AS finalhomescore,
					0 AS finalawayscore,
					0 AS leagueid,
					205 AS sporttype,
					b.ip,
					b.betfrom,
					0 AS matchid,
					CONVERT(BIT, 0) AS IsNeutral,
					0 AS allowdelete,
					SUM(brng.winlost - brng.actual_stake) AS winlost,
					SUM(brng.playercomm) AS commission,
					SUM(brng.scomm - brng.acomm) AS scomm,
					SUM(brng.acomm - brng.comm) AS acomm,
					SUM(brng.comm - brng.playercomm) AS comm,
					SUM(brng.awinlost) AS awinlost,
					SUM(brng.mwinlost) AS mwinlost,
					SUM(brng.swinlost) AS swinlost,
					'' AS showtime,
					b.winlostdate,
					'' AS BetCheck,
					'' AS transdesc,
					0 AS OddsSpread
				FROM dbo.bettrans AS b WITH (NOLOCK, INDEX=IX_custid_matchid_bettype)
					INNER JOIN dbo.bettransRnG AS brng WITH (NOLOCK) ON brng.RefNo = b.transid
					INNER JOIN #SportBettype AS s ON s.Bettype = b.bettype
				WHERE b.custid = @Custid 
					AND s.ProductId = 17
					AND b.winlostdate BETWEEN DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0) AND @ToDate		-- today
					AND brng.statusID <> 0
				GROUP BY
					b.transid,
					ISNULL(b.BetID, 0),
					b.Bettype,
					b.refno,
					b.transdate,
					b.winlostdate,
					b.custid,
					b.IP,
					b.betfrom,
					b.currency,
					b.comstatus,
					b.sdiscount,
					b.adiscount,
					b.discount,
					b.spositiontaking,
					b.mpositiontaking,
					b.apositiontaking
			END
		END

		-- AG Casino
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 11)
		BEGIN
			-- AG Casino (up to yesterday settled ticket)
			INSERT INTO #BetListData
			SELECT
				b.bettype,
				b.transid,
				ISNULL(b.betid, 0),
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
				0 AS finalodds,
				0 AS finalodds2,
				'' AS OddsType,
				b.status,
				CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus,
				b.stake,
				b.actual_stake,
				b.transdate,
				'' AS betteam,
				b.spositiontaking,
				b.mpositiontaking,
				b.apositiontaking,
				0 AS spositiontaking2,
				0 AS mpositiontaking2,
				0 AS apositiontaking2,
				0 AS liveindicator,
				0 AS modds,
				b.custid,
				0 AS livehomescore,
				0 AS liveawayscore,
				0 AS finalhomescore,
				0 AS finalawayscore,
				0 AS leagueid,
				250 AS sporttype,
				b.ip,
				b.betfrom,
				0 AS matchid,
				CONVERT(BIT, 0) AS IsNeutral,
				0 AS allowdelete,
				(b.winlost - b.actual_stake) AS winlost,
				b.playercomm AS commission,
				(b.scomm - b.acomm),
				(b.acomm - b.comm),
				(b.comm - b.playercomm),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				'' AS showtime,
				b.winlostdate,
				'' AS BetCheck,
				'' AS transdesc,
				0 AS OddsSpread
			FROM dbo.bettrans AS b WITH (NOLOCK, INDEX=IX_custid_matchid_bettype)
				INNER JOIN #SportBettype AS s ON s.Bettype = b.bettype
			WHERE b.custid = @Custid 
				AND s.ProductId = 11
				AND b.winlostdate BETWEEN @FromDate AND @ToDate
				AND b.winlostdate < DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0)	-- not today

			IF @ToDate >= DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0)
				AND @FromDate <= DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0)	-- today
			BEGIN
				-- Today running ticket
				INSERT INTO #BetListData
				SELECT
					b.bettype,
					b.transid,
					ISNULL(b.betid, 0),
					b.refno,
					'' AS matchcode,
					'' AS race,
					'' AS eventdate,
					0,
					0,
					0 AS sdiscount,
					0 AS adiscount,
					0 AS discount,
					0 AS homeid,
					0 AS awayid,
					'' settleTime,
					0 AS hdp1,
					0 AS hdp2,
					0 AS odds,
					0 AS finalodds,
					0 AS finalodds2,
					'' AS OddsType,
					'Running' AS Status,
					CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus,
					SUM(blc.stake) AS stake,
					SUM(blc.actual_stake) AS actual_stake,
					b.transdate,
					'' AS betteam,
					0 AS spositiontaking,
					0 AS mpositiontaking,
					0 AS apositiontaking,
					0 AS spositiontaking2,
					0 AS mpositiontaking2,
					0 AS apositiontaking2,
					0 AS liveindicator,
					0 AS modds,
					b.custid,
					0 AS livehomescore,
					0 AS liveawayscore,
					0 AS finalhomescore,
					0 AS finalawayscore,
					0 AS leagueid,
					250 AS sporttype,
					b.ip,
					b.betfrom,
					0 AS matchid,
					CONVERT(BIT, 0) AS IsNeutral,
					0 AS allowdelete,
					0 AS winlost,
					0 AS commission,
					0 AS scomm,
					0 AS acomm,
					0 AS comm,
					0 AS awinlost,
					0 AS mwinlost,
					0 AS swinlost,
					'' AS showtime,
					b.winlostdate,
					'' AS BetCheck,
					'' AS transdesc,
					0 AS OddsSpread
				FROM dbo.bettrans AS b WITH (NOLOCK, INDEX=IX_custid_matchid_bettype)
					INNER JOIN dbo.bettransLC AS blc WITH (NOLOCK) ON blc.RefNo = b.transid
					INNER JOIN #SportBettype AS s ON s.Bettype = b.bettype
				WHERE b.custid = @Custid 
					AND s.ProductId = 11
					AND b.winlostdate BETWEEN DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0) AND @ToDate		-- today
					AND blc.statusID = 0
				GROUP BY
					b.transid,
					ISNULL(b.BetID, 0),
					b.Bettype,
					b.refno,
					b.transdate,
					b.winlostdate,
					b.custid,
					b.IP,
					b.betfrom,
					b.currency,
					b.comstatus

				-- Today settled ticket
				INSERT INTO #BetListData
				SELECT
					b.bettype,
					b.transid,
					ISNULL(b.betid, 0),
					b.refno,
					'' AS matchcode,
					'' AS race,
					'' AS eventdate,
					0,
					0,
					b.sdiscount,
					b.adiscount,
					b.discount,
					0 AS homeid,
					0 AS awayid,
					'' settleTime,
					0 AS hdp1,
					0 AS hdp2,
					0 AS odds,
					0 AS finalodds,
					0 AS finalodds2,
					'' AS OddsType,
					CASE 
						WHEN SUM(blc.winlost - blc.actual_stake) = 0 THEN 'Draw'
						WHEN SUM(blc.winlost - blc.actual_stake) > 0 THEN 'Won'
						WHEN SUM(blc.winlost - blc.actual_stake) < 0 THEN 'Lose'
					END AS Status,
					CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END AS comstatus,
					SUM(blc.stake) AS stake,
					SUM(blc.actual_stake) AS actual_stake,
					b.transdate,
					'' AS betteam,
					b.spositiontaking,
					b.mpositiontaking,
					b.apositiontaking,
					0 AS spositiontaking2,
					0 AS mpositiontaking2,
					0 AS apositiontaking2,
					0 AS liveindicator,
					0 AS modds,
					b.custid,
					0 AS livehomescore,
					0 AS liveawayscore,
					0 AS finalhomescore,
					0 AS finalawayscore,
					0 AS leagueid,
					250 AS sporttype,
					b.ip,
					b.betfrom,
					0 AS matchid,
					CONVERT(BIT, 0) AS IsNeutral,
					0 AS allowdelete,
					SUM(blc.winlost - blc.actual_stake) AS winlost,
					SUM(blc.playercomm) AS commission,
					SUM(blc.scomm - blc.acomm) AS scomm,
					SUM(blc.acomm - blc.comm) AS acomm,
					SUM(blc.comm - blc.playercomm) AS comm,
					SUM(blc.awinlost) AS awinlost,
					SUM(blc.mwinlost) AS mwinlost,
					SUM(blc.swinlost) AS swinlost,
					'' AS showtime,
					b.winlostdate,
					'' AS BetCheck,
					'' AS transdesc,
					0 AS OddsSpread
				FROM dbo.bettrans AS b WITH (NOLOCK, INDEX=IX_custid_matchid_bettype)
					INNER JOIN dbo.bettransLC AS blc WITH (NOLOCK) ON blc.RefNo = b.transid
					INNER JOIN #SportBettype AS s ON s.Bettype = b.bettype
				WHERE b.custid = @Custid 
					AND s.ProductId = 11
					AND b.winlostdate BETWEEN DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0) AND @ToDate		-- today
					AND blc.statusID <> 0
				GROUP BY
					b.transid,
					ISNULL(b.BetID, 0),
					b.Bettype,
					b.refno,
					b.transdate,
					b.winlostdate,
					b.custid,
					b.IP,
					b.betfrom,
					b.currency,
					b.comstatus,
					b.sdiscount,
					b.adiscount,
					b.discount,
					b.spositiontaking,
					b.mpositiontaking,
					b.apositiontaking
			END
		END

		-- Colossus Bet
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 15)
		BEGIN
			INSERT INTO #BetListData
			SELECT
				b.bettype,
				b.transid,
				ISNULL(b.betid, 0),
				b.refno,
				'' AS matchcode,
				'' AS race,
				'' AS eventdate,
				0,
				0,
				b.sdiscount,
				b.adiscount,
				b.discount,
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
				0 AS livehomescore,
				0 AS liveawayscore,
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
				(b.scomm - b.acomm),
				(b.acomm - b.comm),
				(b.comm - b.playercomm),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				'' AS showtime,
				b.winlostdate,
				ISNULL(bm.betcheck, '') AS BetCheck,
				'' AS transdesc,
				0 AS OddsSpread
			FROM bettrans AS b WITH (NOLOCK)
				INNER JOIN #SportBettype AS s ON s.Bettype = b.bettype
				LEFT JOIN dbo.bettransm AS bm WITH (NOLOCK) ON b.transid = bm.refno AND bm.bettype = 18001
			WHERE b.custid 			= @Custid 
				AND b.matchid 		= 204
				AND s.ProductId 	= 15
				AND b.winlostdate 	BETWEEN @FromDate AND @ToDate

			UNION ALL-- translog
			SELECT
				b.gameid bettype,
				0 AS transid,
				0 AS betid,
				b.translogid,
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
				0 hdp1,
				0 hdp2,
				0 odds,
				0 finalodds,
				0 finalodds2,
				'' OddsType,
				b.status,
				0 AS comstatus,
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
				0 liveindicator,
				0 modds,
				b.custid,
				0 livehomescore,
				0 liveawayscore,
				0 AS finalhomescore,
				0 AS finalawayscore,
				0 AS leagueid,
				204 AS sporttype,
				b.ip,
				b.betfrom,
				0 AS matchid,
				CONVERT(BIT, 0) AS IsNeutral,
				0 AS allowdelete,
				(-b.actual_stake) winlost,
				0 AS commission,
				0,
				0,
				0,
				0,
				0,
				0,
				'' AS showtime,
				b.winlostdate,
				b.Tranid3rd AS BetCheck,
				'' AS transdesc,
				0 AS OddsSpread
			FROM translog AS b WITH (NOLOCK)
				INNER JOIN #SportBettype AS s ON s.Bettype = b.gameID
			WHERE b.custid 			= @Custid 
				AND s.ProductId 	= 15
				AND b.statusID 		= 0
				AND b.winlostdate 	BETWEEN @FromDate AND @ToDate
		END
	END

	IF @Fromdate <= @MoveBetsDay
	BEGIN
		/* normal tickets 
		- SB		: ProductID = 1
		- NG		: ProductID = 3
		- LC		: ProductID = 4
		- VS		: ProductID = 5
		*/
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID IN (1, 3, 4, 5))
		BEGIN
			INSERT INTO #BetListData
			SELECT 
				b.bettype,
				b.transid,
				ISNULL(b.betid,0),
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
				(b.scomm - b.acomm),
				(b.acomm - b.comm),
				(b.comm - b.playercomm),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				m.showtime,
				b.winlostdate,
				b.BetCheck,
				CASE WHEN b.bettype BETWEEN 801 AND 899 THEN b.transdesc ELSE '' END AS transdesc,
				ISNULL(b.oddsspread, 0) AS OddsSpread
			FROM 
				bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413) 
				INNER JOIN match14 AS m WITH (NOLOCK) ON b.matchid = m.matchid
				INNER JOIN #SportBettype s ON s.Bettype = b.bettype
			WHERE b.winlostdate 	BETWEEN @FromDate AND @ToDate
				AND b.custid 		= @Custid 
				AND b.matchid  		> 0
				AND s.EventType 	= 1

			-- Mix Parlay
			IF (EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 1 AND Bettype = 9))
			BEGIN
				INSERT INTO #BetListData
				SELECT 
					9 bettype,   
					b.transid,
					ISNULL(b.betid,0),   
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
					CASE WHEN statusID = 0 AND b.recommend NOT IN (SELECT custid FROM #LASAgent) THEN 1 ELSE 0 END AS allowdelete,
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
					0 AS OddsSpread
				FROM	dbo.bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)   
				WHERE	b.winlostdate 	BETWEEN @FromDate AND @ToDate   
					AND b.custid 	= @Custid  
					AND matchid 	= 9
					AND bettype 	= 9
			END

			--Combination Mix Parlay
			IF (EXISTS(SELECT TOP 1 1 FROM  #SportBettype s  WHERE ProductID = 1 AND Bettype = 29))
			BEGIN
				INSERT INTO #BetListData
				SELECT 
					29 bettype,   
					CASE WHEN ISNULL(b.betID,0) = 0 THEN b.transid ELSE b.betID END AS transid,
					ISNULL(b.betid,0),   
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
					0 AS OddsSpread
				FROM	dbo.bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)   
				WHERE b.winlostdate BETWEEN @FromDate AND @ToDate   
					AND b.custid = @Custid
					AND matchid = 29
					AND bettype = 29
			END

			-- Outright
			IF (EXISTS(SELECT TOP 1 1 FROM  #SportBettype s  WHERE ProductID = 1 AND Bettype = 10))
			BEGIN
				INSERT INTO #BetListData
				SELECT 
					b.bettype,
					b.transid,   
					ISNULL(b.betid, 0),
					b.refno,
					odds.matchcode, 
					odds.groupmatch AS race,
					odds.eventdate AS eventdate,
					0,
					0,
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
					0 AS OddsSpread
				FROM	dbo.bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)
						INNER JOIN dbo.outright14 AS odds WITH (NOLOCK) ON b.matchid=odds.orid
						INNER JOIN dbo.league l WITH (NOLOCK) ON odds.leagueid=l.leagueid
				WHERE b.winlostdate BETWEEN @FromDate AND @ToDate  
					AND b.custid = @Custid
					AND b.matchid > 0
					AND b.bettype = 10
			END

			UPDATE betList
			SET betList.Odds	= originBetList.Odds
				,betList.Stake	= originBetList.Stake
				,betList.comm	= CASE WHEN betList.Bettype = 902 THEN ISNULL(commBetList.awinlost, 0) ELSE betList.comm END
				,betList.BetID	= originBetList.Bettype
			FROM #BetListData AS betList
				INNER JOIN bettrans14 AS originBetList WITH(NOLOCK) ON betList.RefNO = originBetList.TransID
				LEFT JOIN #BetListData AS commBetList ON betList.RefNO = commBetList.RefNO AND commBetList.Bettype = 903
			WHERE betList.Sporttype = 1 AND betList.Bettype IN (901, 902)
		END
		
		-- Casino, Bingo
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID IN (6, 7))
		BEGIN
			INSERT INTO #BetListData
			SELECT 
				b.bettype,
				b.betid transid,
				ISNULL(b.betid, 0),
				b.refno,
				CONVERT(VARCHAR(50), b.refno) matchcode,
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
				CASE
					WHEN s.ProductId = 6 THEN 251
					WHEN s.ProductId = 7 THEN 252
				END AS sporttype, 
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
				0 AS OddsSpread
			FROM dbo.bettrans14 b WITH (NOLOCK, INDEX=bettrans1413)
				INNER JOIN #SportBettype s ON s.Bettype = b.bettype
			WHERE b.winlostdate BETWEEN @FromDate AND @ToDate
				AND b.custid = @Custid 
				AND b.matchid = 0
				AND s.ProductId IN (6, 7)
		END

		-- Keno
		IF EXISTS(SELECT TOP 1 1 FROM  #SportBettype s WHERE ProductID = 8)
		BEGIN
			INSERT INTO #BetListData
			SELECT 
				b.bettype,   
				b.betid transid, 
				ISNULL(b.betid,0),
				b.refno,
				CONVERT(VARCHAR(50), b.refno) AS matchcode,   
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
				0 AS OddsSpread
			FROM	dbo.bettrans14 b WITH (NOLOCK, INDEX=bettrans1413)   
				INNER JOIN #SportBettype s ON s.Bettype = b.bettype
				OUTER APPLY dbo.[f_ParseTransDesc](b.TransDesc, b.bettype) d
			WHERE	b.winlostdate 	BETWEEN @FromDate AND @ToDate 
				AND b.custid 		= @Custid 
				AND b.matchid		> 0
				AND	s.ProductID 	= 8
		END

		-- P2P
		IF EXISTS(SELECT TOP 1 1 FROM  #SportBettype s WHERE ProductID = 9)
		BEGIN
			INSERT INTO #BetListData
			SELECT 
				b.bettype,   
				b.transid,
				ISNULL(b.betid,0),   
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
				CONVERT(BIT, 0) AS IsNeutral,
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
				0 AS OddsSpread
			FROM dbo.bettrans14 b WITH (NOLOCK, INDEX=bettrans1413)
				INNER JOIN #SportBettype s ON s.Bettype = b.bettype
			WHERE	b.winlostdate 	BETWEEN @FromDate AND @ToDate 
				AND b.custid 		= @Custid 
				AND b.matchid		= 0
				AND s.ProductId 	= 9
		END

		-- HR
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 2)
		BEGIN
			INSERT INTO #BetListData 
			SELECT 
				b.bettype,
				b.transid,
				ISNULL(b.betid,0),   
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
				0 AS OddsSpread
			FROM	bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)   
					INNER JOIN outright14 AS odds WITH (NOLOCK) ON b.matchid=odds.orid   
					INNER JOIN league l WITH (NOLOCK) ON odds.leagueid=l.leagueid    
					INNER JOIN #SportBettype s ON s.Bettype = b.bettype
					/*LEFT JOIN (			
						SELECT	t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking, t.finalodds,
								f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2, f.finalodds finalodds2
						FROM	bettransm14 t WITH (NOLOCK)
								INNER JOIN bettransm14 f WITH (NOLOCK) ON t.refno = f.refno 
						WHERE	t.bettype IN (31,41) AND f.bettype IN (32,42)
					) bm ON b.transid = bm.refno */
					OUTER APPLY (			
						SELECT	
							t.refno, 
							t.apositiontaking , 
							t.mpositiontaking, 
							t.spositiontaking, 
							t.finalodds,
							f.apositiontaking apositiontaking2, 
							f.mpositiontaking mpositiontaking2, 
							f.spositiontaking spositiontaking2, 
							f.finalodds finalodds2
						FROM dbo.bettransm14 t WITH (NOLOCK)
							INNER JOIN dbo.bettransm14 f WITH (NOLOCK) ON t.refno = f.refno 
						WHERE t.refno = b.transid	
							AND t.bettype IN (31, 41) 
							AND f.bettype IN (32, 42)
					) bm
			WHERE b.winlostdate 	BETWEEN @FromDate AND @ToDate 
				AND b.custid 		= @Custid 
				AND b.matchid		> 0
				AND s.ProductId 	= 2	
		END

		-- Virtual HR
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 5)
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
				CASE WHEN b.bettype IN (SELECT typeid FROM @tableBettypeNotAllowDelete) 
						OR statusID NOT IN(0, 1, 112, 113, 111) 
						OR b.recommend IN (SELECT custid FROM #LASAgent)
						THEN 0 ELSE 1 END AS allowdelete,
				(b.winlost-b.actual_stake)  winlost,
				b.playercomm AS commission,
				(b.scomm - b.acomm),
				(b.acomm - b.comm),
				(b.comm - b.playercomm),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				r.EventTime showtime, -- Race Name			
				b.winlostdate,
				b.BetCheck,
				'' AS transdesc,
				0 AS OddsSpread
			FROM 
				bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413) 
				INNER JOIN VSOutright14 o WITH (NOLOCK) ON b.oddsid = o.Orid
				INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
				INNER JOIN #SportBettype s ON s.BetType = b.BetType 
				/*LEFT JOIN (     
					SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking,
					  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2
					FROM bettransm14 t WITH (NOLOCK)  
					  INNER JOIN bettransm14 f WITH (NOLOCK) ON t.refno = f.refno   
					WHERE t.bettype = 1231 AND f.bettype = 1232 
				) bm ON b.refno = bm.refno */
				OUTER APPLY (     
					SELECT t.refno, 
						t.apositiontaking, 
						t.mpositiontaking, 
						t.spositiontaking,
						f.apositiontaking apositiontaking2, 
						f.mpositiontaking mpositiontaking2, 
						f.spositiontaking spositiontaking2
					FROM dbo.bettransm14 t WITH (NOLOCK)  
						INNER JOIN dbo.bettransm14 f WITH (NOLOCK) ON t.refno = f.refno   
					WHERE t.refno = b.refno
						AND t.bettype = 1231 
						AND f.bettype = 1232 
				) bm 
			WHERE b.winlostdate 	BETWEEN @FromDate AND @ToDate 
				AND b.custid 		= @Custid 
				AND b.matchid		> 0
				AND (s.ProductId 	= 5	AND s.EventType = 3)
		END

		-- Gold Deluxe
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID = 12)
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
				0 AS OddsSpread
			FROM	dbo.bettrans14 b WITH (NOLOCK, INDEX=bettrans1413)   
				INNER JOIN #SportBettype s ON s.Bettype = b.bettype
			WHERE b.winlostdate 	BETWEEN @FromDate AND @ToDate 
				AND b.custid 		= @Custid 
				AND b.matchid		IN (0, 255)
				AND s.ProductId 	= 12
		END

		-- AG Casino, Microgaming Live Casino, Microgaming RNG Casino
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype s WHERE ProductID IN (11, 13, 17))
		BEGIN
			INSERT INTO #BetListData
			SELECT
				b.bettype,
				b.transid,
				ISNULL(b.betid, 0),
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
				'' AS settleTime,
				0 AS hdp1,
				0 AS hdp2,
				0 AS odds,
				0 AS finalodds,
				0 AS finalodds2,
				'' AS OddsType,
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
				0 AS livehomescore,
				0 AS liveawayscore,
				0 AS finalhomescore,
				0 AS finalawayscore,
				0 AS leagueid,
				CASE
					WHEN s.ProductId = 11 THEN 250
					WHEN s.ProductId = 13 THEN 203
					WHEN s.ProductId = 17 THEN 205
				END AS sporttype,
				b.ip,
				b.betfrom,
				0 AS matchid,
				CONVERT(BIT, 0) AS IsNeutral,
				0 AS allowdelete,
				(b.winlost - b.actual_stake) AS winlost,
				b.playercomm AS commission,
				(b.scomm - b.acomm),
				(b.acomm - b.comm),
				(b.comm - b.playercomm),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				'' AS showtime,
				b.winlostdate,
				CASE
					WHEN s.ProductId = 13 THEN b.BetCheck
					ELSE ''
				END AS BetCheck,
				'' AS transdesc,
				0 AS OddsSpread
			FROM bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)
				INNER JOIN #SportBettype AS s ON s.Bettype = b.bettype
			WHERE b.winlostdate BETWEEN @FromDate AND @ToDate 
				AND b.custid = @Custid 
				AND s.ProductId IN (11, 13, 17)
		END

		-- Colossus Bet
		IF EXISTS(SELECT TOP 1 1 FROM  #SportBettype s WHERE ProductID = 15)
		BEGIN
			INSERT INTO #BetListData
			SELECT
				b.bettype,
				b.transid,
				ISNULL(b.betid, 0),
				b.refno,
				'' AS matchcode,
				'' AS race,
				'' AS eventdate,
				0,
				0,
				b.sdiscount,
				b.adiscount,
				b.discount,
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
				0 AS livehomescore,
				0 AS liveawayscore,
				0 AS finalhomescore,
				0 AS finalawayscore,
				0 AS leagueid,
				204 AS sporttype,
				b.ip,
				b.betfrom,
				0 AS matchid,
				CONVERT(BIT, 0) AS IsNeutral,
				0 AS allowdelete,
				(b.winlost - b.actual_stake) AS winlost,
				b.playercomm AS commission,
				(b.scomm - b.acomm),
				(b.acomm - b.comm),
				(b.comm - b.playercomm),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				'' AS showtime,
				b.winlostdate,
				ISNULL(bm.betcheck, '') AS BetCheck,
				'' AS transdesc,
				0 AS OddsSpread
			FROM bettrans14 AS b WITH (NOLOCK, INDEX=bettrans1413)
				INNER JOIN #SportBettype AS s ON s.Bettype = b.bettype
				LEFT JOIN dbo.bettransm14 AS bm WITH (NOLOCK) ON b.transid = bm.refno AND bm.bettype = 18001
			WHERE b.winlostdate 	BETWEEN @FromDate AND @ToDate 
				AND b.custid 		= @Custid 
				AND b.matchid		IN (204)
				AND s.ProductId 	= 15
		END
	END

	DELETE #BetListData 
	WHERE Sporttype = 1 AND Bettype = 903

	SELECT * FROM #BetListData
	ORDER BY transid

	IF EXISTS (	SELECT TOP 1 1 
				FROM #SportBettype sp 
					INNER JOIN #BetListData d ON d.bettype = sp.bettype 
				WHERE ProductID IN (4, 12)) 
	BEGIN
		IF @Todate > @MoveBetsDay
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
				BG.betteam,
				BG.TransDesc 
			FROM dbo.bettransg BG WITH (NOLOCK)
				INNER JOIN #SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid IN (4)
				INNER JOIN #BetListData B1 ON (BG.refno = B1.refno AND BG.bettype = B1.bettype AND sp.Productid IN (4))
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
				INNER JOIN #BetListData B2 ON (BG.refno = B2.transid AND BG.bettype = B2.bettype AND sp.Productid IN (12))
		END 

		IF @Fromdate <= @MoveBetsDay
		BEGIN	
			INSERT INTO #BetListDetailData
			SELECT 
				BG.refno,
				BG.odds, 
				BG.stake,
				BG.[status],
				BG.apositiontaking, 
				BG.mpositiontaking, 
				BG.spositiontaking,
				BG.bettype,
				BG.betteam,
				BG.TransDesc
			FROM dbo.bettransg14 BG WITH (NOLOCK)
				INNER JOIN #SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid IN (4)
				INNER JOIN #BetListData B1 ON (BG.refno = B1.refno AND BG.bettype = B1.bettype AND sp.Productid IN (4))
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
			FROM dbo.bettransg14 BG WITH (NOLOCK)
				INNER JOIN #SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid IN (12)
				INNER JOIN #BetListData B2 ON (BG.refno = B2.transid AND BG.bettype = B2.bettype AND sp.Productid IN (12))
		END 
	END

	SELECT * FROM #BetListDetailData BG 
	ORDER BY BG.refno

	DROP TABLE #BetListData
	DROP TABLE #BetListDetailData
	DROP TABLE #LASAgent
	DROP TABLE #SportBettype
END


GRANT	VIEW DEFINITION	ON	Acc_BetsSelBetList	TO	vnteam
GRANT	EXECUTE	ON	Acc_BetsSelBetList	TO	bodbExtAccNet
GRANT	EXECUTE	ON	Acc_BetsSelBetList	TO	bodbAdminNet
