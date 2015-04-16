
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE Acc_StatementSelCancelBetList_14
	@custid		INT	
	,@fromdate	SMALLDATETIME
	,@todate	SMALLDATETIME
	,@transtype	INT = 0
	,@language	NVARCHAR(2) = 'en'
AS
/*
Created: CODY
Date: 2015-04-10 
Task : Cancel Bet List for downline Statement
DB: DBACC/bodb02

Param's Explanation: 
	+ @transtype: 1-Betting Statement; 2-VOID/Cancelled Bet; 3-Outstanding Bet 
*/
BEGIN
	DECLARE @SportBettype TABLE(
				ProductID	INT
				,Bettype	INT
				,EventType	INT
			)
				
	INSERT INTO @SportBettype
	EXEC dbo.Acc_SportBettypeMatrix_Sel @mode=4

	DECLARE	@tmpStatus TABLE ([statusID] tinyint)
	IF(@transtype = 1) 
	BEGIN
		INSERT INTO @tmpStatus([statusID])
		SELECT 111 UNION ALL SELECT 112 UNION ALL SELECT 113 UNION ALL SELECT 103
	END
	ELSE IF(@transtype = 2)
	BEGIN
		INSERT INTO @tmpStatus([statusID])
		SELECT 101 UNION ALL SELECT 102
	END 
	ELSE IF(@transtype = 3)
	BEGIN
		INSERT INTO @tmpStatus([statusID])
		SELECT 0 UNION ALL SELECT 1
	END
	
	CREATE TABLE #Data (
		sporttype int, 
		leagueid int, 
		homeid int, 
		awayid int, 
		bettype smallint,	
		matchcode nvarchar(50),
		race nvarchar(20),
		matchid int, 
		transid bigint, 
		transdate datetime, 
		winlostdate datetime,
		refno nvarchar(50), 
		betid bigint,
		oddsid int, 	
		hdp1 smallmoney, 
		hdp2 smallmoney, 
		Modds smallmoney,
		oddstype tinyint,
		odds smallmoney, 
		betteam nvarchar(10), 
		status nvarchar(50), 
		betstatus nvarchar(50), 
		stake money, 
		actual_stake money,
		winlost money,
		awinlost money,
		mwinlost money,
		swinlost money,
		 
		playercomm money,
		comm money,
		acomm money,
		scomm money,
		
		livehomescore smallint, 
		liveawayscore smallint, 
		liveindicator bit,
		finalhomescore smallint, 
		finalawayscore smallint, 
		hthomescore smallint, 
		htawayscore smallint, 
		--creator varchar(50), 
		ip nvarchar(15), 
		username nvarchar(30),
		isNeutral bit,
		showtime NVARCHAR(50),
		betcheck nvarchar(50),
		comstatus nvarchar(20)
	)

	-- single bet
	INSERT INTO #Data SELECT
		m.sporttype, 
		m.leagueid,
		m.homeID,
		m.awayID,
		b.bettype,
		m.matchcode,
		'' as race,
		m.matchid, 
		b.transid, 
		b.transdate, 
		b.winlostdate,
		b.refno, 
		--case when b.bettype = 87 then b.betid else 0 end, --- 87- High Low for NG: Current Live Ball 
		b.betid,
		b.oddsid, 
		b.hdp1, 
		b.hdp2,
		modds, 
		b.oddstype as OddsType, 
		b.odds, 	
		b.betteam,
		b.status as status,
		m.betstatus, 
		b.stake, 
		b.actual_stake,
		(b.winlost-b.actual_stake) as winlost, 
		b.awinlost,
		b.mwinlost,
		b.swinlost,
		
		b.playercomm,
		(b.comm - b.playercomm) as comm,
		(b.acomm - b.comm) as acomm ,
		(b.scomm - b.acomm) as scomm,
		
		b.livehomescore, 
		b.liveawayscore, 
		b.liveindicator, 
		m.finalhomescore, 
		m.finalawayscore,
		m.hthomescore, 
		m.htawayscore,
		--b.username, 
		b.IP as IP,
		b.Username,
		isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
		m.showtime,
		'' as betcheck,
		CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
	from 
		dbo.bettrans14 b with (nolock, index=IX_bettrans14)
		INNER JOIN dbo.match14 m with (nolock) ON b.matchid = m.matchid		
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where
		b.custid=@custid 		
		AND b.winlostdate BETWEEN @fromdate  AND @todate 
		--AND b.bettype<= 19000 
		--AND b.bettype not in (10,31,32,33,41,42,43,1231,1232,1233,1237,1238) --20120626@Elodie: exclude outright, HR from sportbook
		--AND b.bettype NOT BETWEEN 1501 AND 1599 -- exclude Keno from Sportbook
		AND s.eventtype = 1
		AND b.statusID IN (SELECT [statusID] FROM @tmpStatus)

	-- Virtual HR
	INSERT INTO #Data 
	SELECT
		r.sporttype, 
		r.leagueid,
		o.RacerID as HomeID,
		0 as AwayID, 
		b.bettype,
		o.RacerNum as Matchcode, 
		b.oddsid as Race,
		b.matchid, 
		b.transid, 
		b.transdate, 
		b.winlostdate,
		b.refno, 
		b.betid,
		b.oddsid, 
		b.hdp1, 
		b.hdp2,
		modds, 
		0 as OddsType, 
		b.odds, 	
		'' as betteam,
		b.status as status,
		'' as betstatus, 
		b.stake, 
		b.actual_stake,
		(b.winlost-b.actual_stake) as winlost, 
		b.awinlost,
		b.mwinlost,
		b.swinlost,
		
		b.playercomm,
		(b.comm - b.playercomm) as comm,
		(b.acomm - b.comm) as acomm ,
		(b.scomm - b.acomm) as scomm,
		
		b.livehomescore, 
		b.liveawayscore, 
		0 as liveindicator, 
		0 as finalhomescore, 
		0 as finalawayscore,
		0 as hthomescore, 
		0 as htawayscore,
		b.IP as IP,
		b.Username,
		CONVERT(BIT,0) as IsNeutral,
		r.eventTime as showtime,
		'' as betcheck,
		CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
	from 
		dbo.bettrans14 b with (nolock, index=IX_bettrans14)
		INNER JOIN VSOutright14 o with (NOLOCK) ON b.oddsid=o.Orid
		INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where
		b.custid=@custid 		
		AND s.productid=5
		AND s.eventtype=3
		AND b.winlostdate BETWEEN @fromdate  AND @todate
		--AND b.bettype in (1231, 1232, 1233, 1237, 1238)
		AND b.statusID IN (SELECT [statusID] FROM @tmpStatus)
		
	-- CASINO
	INSERT INTO #Data 
		SELECT
			251, --m.sporttype, 
			0, --m.leagueid,
			0, --m.homeID,
			0, --m.awayID,
			b.bettype,
			'', --m.matchcode,
			'' as race,
			0, --m.matchid, 
			b.betid, 
			b.transdate, 
			b.winlostdate,
			b.refno, 
			isnull(b.betID,0),
			b.oddsid, 
			b.hdp1, 
			b.hdp2,
			0 as modds,
			0 as OddsType, 
			b.odds, 
			b.betteam, 
			b.status, 
			b.actual_stake,
			'',
			b.stake, 
			(b.winlost-b.actual_stake) as winlost, 
			b.awinlost,
			b.mwinlost,
			b.swinlost,
			
			b.playercomm,
			(b.comm - b.playercomm) as comm,
			(b.acomm - b.comm) as acomm ,
			(b.scomm - b.acomm) as scomm,
			
			b.livehomescore, 
			b.liveawayscore, 
			b.liveindicator, 
			0,
			0,
			0,
			0,
			b.IP as IP,
			b.Username,
			0 as IsNeutral,
			'' as showtime,
			'' as betcheck,
			CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
		from 
			dbo.bettrans14 b with (nolock, index=IX_bettrans14)		
		where
			b.custid=@custid 		
			AND b.winlostdate BETWEEN @fromdate  AND @todate
			AND b.bettype in (71, 72, 23002)	
			AND b.matchID in (0, 71)
			AND b.statusID IN (SELECT [statusID] FROM @tmpStatus)
			
	-- P2P -- 20120405@Hurri
	INSERT INTO #Data 
	SELECT
		253,
		0,
		0,
		0,
		b.bettype,
		'',
		'' as race,
		0,
		b.transid, 
		b.transdate, 
		b.winlostdate,
		b.refno, 
		isnull(b.betID,0),
		b.oddsid, 
		b.hdp1, 
		b.hdp2,
		0 as modds,
		0 as OddsType, 
		b.odds, 
	    b.betteam, 
		b.status, 
		b.actual_stake,
		'', 
		b.stake, 
		(b.winlost-b.actual_stake) as winlost, 
		b.awinlost,
		b.mwinlost,
		b.swinlost,
		
		b.playercomm,
		(b.comm - b.playercomm) as comm,
		(b.acomm - b.comm) as acomm ,
		(b.scomm - b.acomm) as scomm,
		
		b.livehomescore, 
		b.liveawayscore, 
		b.liveindicator, 
		0,
		0,
		0, 
		0,
		b.IP as IP,
		b.Username,
		0 as IsNeutral,
		'' as showtime,
		b.betcheck as sessionID,
		CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
	from 
		dbo.bettrans14 b with (nolock, index=IX_bettrans14)		
	where
		b.custid=@custid 		
		AND b.winlostdate BETWEEN @fromdate  AND @todate
		AND b.bettype in (1000,23102)	
		AND b.matchID in(0, 1000)
		AND b.statusID IN (SELECT [statusID] FROM @tmpStatus)

	-- IBCBET Bingo
	INSERT INTO #Data 
	SELECT
		252, --m.sporttype, 
		0, --m.leagueid,
		0, --m.homeID,
		0, --m.awayID,
		b.bettype,
		'', --m.matchcode,
		'' as race,
		0, --m.matchid, 
		b.betid, 
		b.transdate, 
		b.winlostdate,
		b.refno, 
		isnull(b.betID,0),
		b.oddsid, 
		0 as hdp1, 
		0 as hdp2,
		0 as modds,
		0 as OddsType, 
		b.odds, 
		b.betteam, 
		b.status, 
		'', --m.betstatus, 
		b.stake, 
		b.actual_stake,
		(b.winlost-b.actual_stake) as winlost, 
		b.awinlost,
		b.mwinlost,
		b.swinlost,
		
		b.playercomm,
		(b.comm - b.playercomm) as comm,
		(b.acomm - b.comm) as acomm,
		(b.scomm - b.acomm) as scomm,
		
		0 as livehomescore, 
		0 as liveawayscore, 
		0 as liveindicator, 
		0, --m.finalhomescore, 
		0, --m.finalawayscore,
		0, --m.hthomescore, 
		0, --m.htawayscore,
		--b.username, 
		b.IP as IP,
		b.Username,
		0 as IsNeutral,
		'' as showtime,
		'' as betcheck,
		CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
	from 
		dbo.bettrans14 b with (nolock, index=IX_bettrans14)		
	where
		b.custid = @custid 		
		AND b.winlostdate BETWEEN @fromdate  AND @todate 
		AND b.bettype in (73,23202)
		AND b.matchID in (0, 73)
		AND b.statusID IN (SELECT [statusID] FROM @tmpStatus)
	
	-- mix parlay
	INSERT INTO #Data SELECT
		0,
		0, 
		0, 
		0, 
		b.bettype,		
		'', 
		'' as race, 
		0, 
		CASE WHEN ISNULL(b.betID,0) = 0 THEN b.transid ELSE b.betID END AS transid, 
		b.transdate, 
		b.winlostdate, 
		b.refno,
		isnull(b.betID,0),
		0, 
		0, 
		0, 
		modds,
		0 as OddsType,
		b.odds, 
		b.betteam,
		b.status, 
		'' betstatus, 
		b.stake, 
		b.actual_stake,
		(b.winlost-b.actual_stake) as winlost, 
		b.awinlost,
		b.mwinlost,
		b.swinlost,
		
		b.playercomm,
		(b.comm - b.playercomm) as comm,
		(b.acomm - b.comm) as acomm ,
		(b.scomm - b.acomm) as scomm,
		
		0, 
		0, 
		0, 
		0, 
		0, 
		0, 
		0,
		--b.username creator, 
		b.IP as IP,
		b.Username,
		CONVERT(BIT,0) as IsNeutral,
		'' as showtime,
		'' as betcheck,
		CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
	from 
		dbo.bettrans14 b with (nolock, index=IX_bettrans14)		
	where
		b.custid=@custid
		and b.winlostdate BETWEEN @fromdate  AND @todate
		--and b.matchid=0 
		and b.matchid IN (9, 29)
		and b.bettype IN (9, 29)
		AND b.statusID IN (SELECT [statusID] FROM @tmpStatus)


	-- outright
	INSERT INTO #Data SELECT
		l.sporttype,
		m.leagueID,
		m.teamID as homeid,
		0 as awayid,
		b.bettype, 
		m.matchcode,
		m.groupmatch as race, 
		m.orid, 
		b.transid, 
		b.transdate, 
		b.winlostdate, 
		b.transid,
		isnull(b.betID,0),
		10, 
		b.hdp1, 
		b.hdp2, 
		modds,
		0 as OddsType,
		b.odds, 
		'',
		b.status, 
		'', 
		b.stake, 
		b.actual_stake,
		(b.winlost-b.actual_stake) as winlost,
		b.awinlost,
		b.mwinlost,
		b.swinlost,
		 
		b.playercomm,
		(b.comm - b.playercomm) as comm,
		(b.acomm - b.comm) as acomm ,
		(b.scomm - b.acomm) as scomm,
		
		b.livehomescore, 
		b.liveawayscore, 
		0, 
		0, 
		0, 
		0, 
		0,
		--b.username creator,
		b.IP as IP,
		b.Username,
		CONVERT(BIT,0) as IsNeutral,
		'' as showtime,
		'' as betcheck,
		CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
	from 
		dbo.bettrans14 b with (nolock, index=IX_bettrans14)
		INNER JOIN dbo.outright14 m with (nolock) on b.matchid = m.orid	
		INNER JOIN dbo.league l with (nolock) on m.leagueid = l.leagueid
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where
		b.custid=@custid 
		AND s.eventtype=2
		--AND b.bettype in (10,31,32,33,41,42,43)
		AND b.winlostdate BETWEEN @fromdate  AND @todate
		AND b.statusID IN (SELECT [statusID] FROM @tmpStatus)

	-- Keno
	IF(@transtype = 1 or @transtype = 2)
		INSERT INTO #Data 
		SELECT
			202, --m.sporttype, 
			0, --m.leagueid,
			0, --m.homeID,
			0, --m.awayID,
			b.bettype,
			'', --m.matchcode,
			'' as race,
			t.GameId, --m.matchid, 
			b.transid, 
			b.transdate, 
			b.winlostdate,
			b.refno, 
			0,
			0, 
			0, 
			0,
			b.modds,
			0, 
			b.odds, 
			t.ChoiceId, 
			b.status, 
			'', --m.betstatus, 
			b.stake, 
			b.actual_stake,
			(b.winlost-b.actual_stake) as winlost, 
			b.awinlost,
			b.mwinlost,
			b.swinlost,
		
			b.playercomm,
			(b.comm - b.playercomm) as comm,
			(b.acomm - b.comm) as acomm ,
			(b.scomm - b.acomm) as scomm,
		
			0,--livehomescore, 
			0,--liveawayscore, 
			0,--liveindicator, 
			0, --m.finalhomescore, 
			0, --m.finalawayscore,
			0, --m.hthomescore, 
			0, --m.htawayscore,
			--b.username, 
			b.IP as IP,
			b.Username,
			0 as IsNeutral,
			'' as showtime,
			'' as betcheck,
			CASE WHEN b.comstatus = '1' THEN '1' ELSE '0' END AS comstatus
		from 
			dbo.bettrans14 b with (nolock, index=IX_bettrans14)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
			OUTER APPLY dbo.[f_ParseTransDesc](b.TransDesc, b.bettype) t
		where
			b.custid=@custid 		
			AND b.winlostdate BETWEEN @fromdate  AND @todate
			AND s.productid=8
			--AND b.bettype BETWEEN 1501 AND 1599
			AND b.statusID IN (SELECT [statusID] FROM @tmpStatus)
	END
	SELECT * FROM #Data 
	ORDER BY transid, refno
	
	--get data from bettransm14 for bettype 33,43
	SELECT 
		BM.refno, 
		BM.Stake, 
		BM.finalodds,
		BM.odds, 
		BM.status, 
		BM.bettype,
		BM.Betteam  
	FROM bettransm14 BM with (NOLOCK, INDEX =IX_bettransm14 )
	INNER JOIN #Data B ON BM.refno = B.transid
	WHERE B.Bettype IN (33,43)
	
	UNION ALL
	--get data from bettransm14 for bettype 1233
	SELECT 
		BM.refno, 
		BM.Stake, 
		BM.finalodds,
		BM.odds, 
		BM.status, 
		BM.bettype,
		BM.Betteam  
	FROM bettransm14 BM with (NOLOCK, INDEX =IX_bettransm14 )
	INNER JOIN #Data B ON BM.refno = B.refno
	WHERE B.Bettype = 1233
	
	UNION ALL
	-- Get data form Live Casino
	SELECT 
		BG.refno, 
		BG.Stake, 
		0 as finalodds,
		BG.odds, 
		BG.status, 
		BG.bettype,
		BG.Betteam  
	FROM bettransg14 BG with (NOLOCK, INDEX =IX_bettransg14 )
	INNER JOIN #Data B ON BG.refno = B.refno
	WHERE B.Bettype  BETWEEN 1101 AND 1199

