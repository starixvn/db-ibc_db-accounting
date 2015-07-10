USE bodb02
GO

ALTER PROCEDURE [dbo].[Acc_BetsSelBetList]  
	@FromDate datetime,  
	@ToDate datetime,  
	@MoveBetsDay datetime, 
	@CustID int,
	@Bettype int = 0
AS  
/*
	Acc_BetsSelBetList
	 @FromDate = '2014-02-06',
	 @ToDate = '2014-02-24',
	 @MoveBetsDay ='2014-02-24', 
	 @CustID = 8252986,
	 @Bettype = 1

	Created by: [Creator]
	Date: 2008
	Task: Bet List 
	DB: DBAGE/bodb02 
	Original:  account\betlist.asp  
	
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
		-- 20100525@Henry: Change to use StatusID instead of Status in WHERE statement
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
		- 20150625@Edward: Support for MicroGamming
*/		
BEGIN
	SET NOCOUNT ON  

	--list of bettype not allowed to delete
	DECLARE @tableBettypeNotAllowDelete  TABLE(typeid int not null)
	INSERT INTO @tableBettypeNotAllowDelete (typeid) 
		SELECT 31 UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL 
		SELECT 51 UNION ALL SELECT 52 UNION ALL SELECT 53 UNION ALL SELECT 54 UNION ALL SELECT 55 UNION ALL SELECT 56 UNION ALL 
		SELECT 61 UNION ALL SELECT 62 UNION ALL SELECT 63 UNION ALL SELECT 64 UNION ALL SELECT 65 UNION SELECT 66
	--End

	--list of LAS agent not allowed to delete
	DECLARE @strLASAgent varchar(1000)
	EXEC DBLAS.LASDB.dbo.Las_Get_recommend @StringRec = @strLASAgent output
	SELECT val as CustID 
	INTO #LASAgent
	FROM dbo.strSplit(@strLASAgent,'^')
	--END 

	----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT)
	INSERT INTO @SportBettype
	EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode=4

	IF @Bettype <> 0
	BEGIN
		DELETE @SportBettype WHERE Bettype <> @Bettype
	END

	CREATE TABLE #BetListData(
		bettype			int,
		transid			bigint, 
		betid			bigint,
		refno			nvarchar(50), 
		matchcode		nvarchar(50),
		race			nvarchar(20),
		eventdate		smalldatetime,
		virtualrate		float,
		isShowOTExRate	bit,
		sdiscount		smallmoney,
		adiscount		smallmoney,
		discount		smallmoney,
		homeid			int, 
		awayid			int, 
		settleTime		datetime,
		hdp1			smallmoney, 
		hdp2			smallmoney, 
		odds			smallmoney,
		finalodds		smallmoney,
		finalodds2		smallmoney,
		OddsType		tinyint,
		status			nvarchar(50),
		comstatus		nvarchar(50), 
		stake			money,
		actual_stake	money,
		transdate		datetime,
		betteam			nvarchar(50),
		spositiontaking smallmoney,
		mpositiontaking smallmoney,
		apositiontaking smallmoney,
		spositiontaking2 smallmoney,
		mpositiontaking2 smallmoney,
		apositiontaking2 smallmoney,
		liveindicator	 bit,
		modds			smallmoney,
		custid			int,
		livehomescore	int, 
		liveawayscore	int, 
		finalhomescore	int, 
		finalawayscore	int, 
		leagueid		int, 
		sporttype		smallint, 
		ip				nvarchar(15), 
		betfrom			nvarchar (1),
		matchid			int,
		isNeutral		bit,
		allowdelete		bit,
		winlost			money,
		commission		money,
		scomm			money,	
		acomm			money,
		comm			money,
		awinlost		money,
		mwinlost		money,
		swinlost		money,
		showtime		nvarchar(50),
		winlostdate		smalldatetime,
		BetCheck		NVARCHAR(50),
		transdesc		NVARCHAR(300)
	)

	CREATE TABLE #BetListDetailData (
		refno			varchar(50), 
		odds			smallmoney, 
		stake			money,
		status			varchar(50),
		apositiontaking smallmoney, 
		mpositiontaking smallmoney, 
		spositiontaking smallmoney,
		bettype			smallint,
		betteam			nvarchar(50),
		TransDesc		varchar(300)
	)

	IF @Todate > @MoveBetsDay
	BEGIN
		/* normal tickets 
			- SB		: ProductID = 1
			- NG		: ProductID = 3
			- LC		: ProductID = 4
			- VS		: ProductID = 5
		*/
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID IN (1, 3, 4, 5) AND Bettype = @Bettype)
		)
		BEGIN	
			
			INSERT INTO #BetListData
			select 
				b.bettype,
				b.transid,
				isnull(b.betid,0),
				b.refno,
				m.matchcode,
				'' as race,
				m.eventdate as eventdate,
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
				CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
					 ELSE b.status 
					 END as status,
				CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				--CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or status NOT IN('running', 'waiting', 'WON', 'LOSE', 'DRAW') THEN 0 ELSE 1 END as allowdelete,
				CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) 
							or b.recommend IN (SELECT custid from #LASAgent) 
							or statusID NOT IN(0, 1, 112, 113, 111) THEN 0 ELSE 1 END as allowdelete,
				(b.winlost-b.actual_stake)  winlost,
				b.playercomm as commission,
				(b.scomm - b.acomm),
				(b.acomm - b.comm),
				(b.comm - b.playercomm),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				m.showtime,
				b.winlostdate,
				b.BetCheck,
				CASE WHEN b.bettype BETWEEN 801 AND 899 THEN b.transdesc ELSE '' END AS transdesc
				
			from 
				bettrans as b with (nolock) 
				inner join match as m with (nolock) 
				on b.matchid = m.matchid --phuong.nguyen, remove left join match_remark
				INNER JOIN @SportBettype s ON s.Bettype = b.bettype
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid 
					--b.bettype < 19001 and
					--b.bettype not in (10,31,32,33,41,42,43/*,1231,1232,1233,1237,1238*/) and 
					--b.bettype not between 1501 and 1599 AND--20120626@Elodie: exclude outright, HR from sportbook
					--b.bettype NOT IN (SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
					AND	(
						s.EventType = 1
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
					--exclude metric gaming running ticket
					AND (b.bettype NOT BETWEEN 801 AND 806 AND b.statusID NOT IN (0, 1))
					
			UNION ALL -- translog metric gaming
			SELECT 
				b.gameid AS bettype,  
				b.translogid AS transid,  
				0 AS BetID,  
				b.translogid AS refno,  
				m.matchcode,  
				'' as race,  
				m.eventdate,  
				0 as virtualrate,  
				0 as isShowOTExRate,
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
				CASE WHEN b.gameid IN (801,803,804,805,806) THEN CONVERT(TINYINT, ISNULL(b.custom1, 0))  ELSE 0 END AS OddsType,
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
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				--CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or status NOT IN('running', 'waiting', 'WON', 'LOSE', 'DRAW') THEN 0 ELSE 1 END as allowdelete,
				CASE WHEN b.gameID in (SELECT typeid FROM @tableBettypeNotAllowDelete) 
							or b.recommend IN (SELECT custid from #LASAgent) 
							or statusID NOT IN(0, 1, 112, 113, 111) THEN 0 ELSE 1 END as allowdelete,
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
				b.transdesc
			FROM   
				dbo.translog as b with (nolock)   
				inner join dbo.match as m with (nolock) 
				on b.eventid = m.matchid
				INNER JOIN @SportBettype s 
				ON b.gameid = s.Bettype
			WHERE    
				b.custid 			= @Custid 
				AND s.Bettype 		BETWEEN 801 AND 899
				AND b.winlostdate>= @FromDate 
				AND b.winlostdate<= @ToDate 
				AND b.statusID		IN (0,1)
				
			--Mix Parlay
			IF (EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 1 AND Bettype = 9))
			BEGIN	
				INSERT INTO #BetListData
				select 
					 9 bettype,   
					 b.transid,   
					 isnull(b.betid,0),
					 b.refno,
					 '' matchcode,  
					 '' as race,
					 '' as eventdate,
					 0,
					 0,
					 sdiscount,
					 adiscount,
					 discount,	 
					 0 as homeid,   
					 0 as awayid,  
					 '' settleTime, 
					 b.hdp1,
					 b.hdp2,
					 b.odds,   
					 0 finalodds,
					 0 finalodds2,
					 '' OddsType,  
					 b.status,
					 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
					 0 as finalhomescore, 
					 0 as finalawayscore,  
					 0 as leagueid,  
					 0 as sporttype, 
					 b.ip,
					 b.betfrom,
					 0 matchid,	
					 CONVERT(BIT,0) as IsNeutral,
					 CASE WHEN statusID = 0 and b.recommend NOT IN (SELECT custid from #LASAgent) THEN 1 ELSE 0 END as allowdelete,
					 (b.winlost-b.actual_stake)  winlost,
					 b.playercomm as commission,
					 (b.scomm - b.acomm),
					 (b.acomm - b.comm),
					 (b.comm - b.playercomm),
					 b.awinlost,
					 b.mwinlost,
					 b.swinlost,
					 '' as showtime,
					 b.winlostdate,
					 b.BetCheck,
					 '' AS transdesc
					 
				from	bettrans as b with (nolock)   
				where	b.winlostdate>= @FromDate and    
						b.winlostdate<= @ToDate and   
						b.custid = @Custid  
						--and matchid=0  
						and matchid = 9
						and bettype = 9  
			END
			
			--Combination Mix Parlay
			IF (EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 1 AND Bettype = 29))
			BEGIN
				INSERT INTO #BetListData
				select 
					 29 bettype,   
					 CASE WHEN ISNULL(b.betID,0) = 0 THEN b.transid ELSE b.betID END AS transid,
					 isnull(b.betid,0),
					 b.refno,
					 '' matchcode,  
					 '' as race,
					 '' as eventdate,
					 0,
					 0,
					 sdiscount,
					 adiscount,
					 discount,	 
					 0 as homeid,   
					 0 as awayid,  
					 '' settleTime, 
					 b.hdp1,
					 b.hdp2,
					 b.odds,   
					 0 finalodds,
					 0 finalodds2,
					 '' OddsType,  
					 b.status,
					 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
					 0 as finalhomescore, 
					 0 as finalawayscore,  
					 0 as leagueid,  
					 0 as sporttype, 
					 b.ip,
					 b.betfrom,
					 0 matchid,	
					 CONVERT(BIT,0) as IsNeutral,
					 0 as allowdelete,
					 (b.winlost-b.actual_stake)  winlost,
					 b.playercomm as commission,
					 (b.scomm - b.acomm),
					 (b.acomm - b.comm),
					 (b.comm - b.playercomm),
					 b.awinlost,
					 b.mwinlost,
					 b.swinlost,
					 '' as showtime,
					 b.winlostdate,
					 b.BetCheck,
					 '' AS transdesc
					 
				from	bettrans as b with (nolock)   
				where	b.winlostdate>= @FromDate and    
						b.winlostdate<= @ToDate and   
						b.custid = @Custid  
						--and matchid=0  
						and matchid = 29
						and bettype = 29 
			END
			
			-- Outright
			IF (EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 1 AND Bettype = 10))
			BEGIN
				INSERT INTO #BetListData
				select 
					b.bettype,
					b.transid,
					isnull(b.betid,0),   
					b.refno,
					odds.matchcode, 
					odds.groupmatch as race,
					odds.eventdate as eventdate,
					0,
					0,
					b.sdiscount,
					b.adiscount,
					b.discount,	  
					0 as homeid,
					odds.teamid as awayid,
					'' settleTime, 
					b.hdp1,
					b.hdp2,
					b.odds,   
					0 finalodds,
					0 finalodds2,
					'' OddsType,  
					b.status,  
					CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
					0 as finalhomescore, 
					0 as finalawayscore,  
					odds.leagueid,
					l.sporttype,
					b.ip ,
					b.betfrom,
					b.matchid,
					CONVERT(BIT,0) as IsNeutral,
					--CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or b.status NOT IN('running', 'waiting', 'WON', 'LOSE', 'DRAW') THEN 0 ELSE 1 END as allowdelete,
					CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) 
							or b.statusID NOT IN(0, 1, 112, 113, 111) 
							or b.recommend IN (SELECT custid from #LASAgent)
							THEN 0 ELSE 1 END as allowdelete,
					(b.winlost-b.actual_stake)  winlost,
					b.playercomm as commission,
					(b.scomm - b.acomm),
					(b.acomm - b.comm),
					(b.comm - b.playercomm),
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					'' as showtime,
					 b.winlostdate,
					 b.BetCheck,
					 '' AS transdesc
					 
				from	bettrans as b with (nolock)   
						inner join outright as odds with (nolock) on b.matchid=odds.orid   
						inner join league l with (nolock) on odds.leagueid=l.leagueid     
				where b.bettype = 10
				and b.winlostdate >= @FromDate and   
				b.winlostdate<= @ToDate  and
				b.custid = @Custid 
			END
		END
		
		--- Casino
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 6 AND Bettype = @Bettype)
		)
		BEGIN	
			
			INSERT INTO #BetListData
			select 
				 b.bettype,   
				 b.betid transid,   
				 isnull(b.betid,0),
				 b.refno,
				 CONVERT(varchar(50), b.refno) matchcode,   
				 '' as race,
				 '' as eventdate, 
				 0,
				 0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 as homeid,   
				 0 as awayid,  
				 '' settleTime, 
				 b.hdp1,
				 b.hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status, 
				 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				 0 as finalhomescore, 
				 0 as finalawayscore,  
				 0 as leagueid,  
				 251 as sporttype, 
				 b.ip,
				 b.betfrom,
				 b.matchid,
				 CONVERT(BIT,0) as IsNeutral,
				 0 as allowdelete,
				 (b.winlost-b.actual_stake)  winlost,
				 b.playercomm as commission,
				 (b.scomm - b.acomm),
				 (b.acomm - b.comm),
				 (b.comm - b.playercomm),
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' as showtime,
				 b.winlostdate,
				 b.BetCheck,
				 '' AS transdesc
				 
			from	bettrans b with (nolock)   
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid  
					--AND bettype = 71								--20120405@Hurri
					AND	(
						s.ProductId 	= 6 	
						AND s.EventType = 0
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
		END
		
		--ibc bingo
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 7 AND Bettype = @Bettype)
		)
		BEGIN	
			INSERT INTO #BetListData
			select 
				 b.bettype,   
				 b.betid transid, 
				 isnull(b.betid,0),
				 b.refno,
				 CONVERT(varchar(50), b.refno) as matchcode,   
				 '' as race,
				 '' as eventdate, 
				 0,
				 0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 as homeid,   
				 0 as awayid,  
				 '' settleTime, 
				 b.hdp1,
				 b.hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status,  
				 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				 0 as finalhomescore, 
				 0 as finalawayscore,  
				 0 as leagueid,  
				 252 as sporttype, 
				 b.ip,
				 b.betfrom,
				 b.matchid,
				 CONVERT(BIT,0) as IsNeutral,
				 0 as allowdelete,
				 (b.winlost-b.actual_stake)  winlost,
				 b.playercomm as commission,
				 (b.scomm - b.acomm),
				 (b.acomm - b.comm),
				 (b.comm - b.playercomm),
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' as showtime,
				 b.winlostdate,
				 b.BetCheck,
				 '' AS transdesc
				 
			from	bettrans b with (nolock)   
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid 
					--AND bettype = 73
					AND	(
						s.ProductId 	= 7 	
						AND s.EventType = 0
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					) 
		END
		
		--ibc KENO
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 8 AND Bettype = @Bettype)
		)
		BEGIN	
			INSERT INTO #BetListData
			select 
				 b.bettype,   
				 b.betid transid, 
				 isnull(b.betid,0),
				 b.refno,
				 CONVERT(varchar(50), b.refno) as matchcode,   
				 '' as race,
				 '' as eventdate, 
				 0,
				 0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 as homeid,   
				 0 as awayid,  
				 '' settleTime, 
				 b.hdp1,
				 b.hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status,  
				 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				 0 as finalhomescore, 
				 0 as finalawayscore,  
				 0 as leagueid,  
				 202 as sporttype, 
				 b.ip,
				 b.betfrom,
				 d.GameId matchid,
				 CONVERT(BIT,0) as IsNeutral,
				 0 as allowdelete,
				 (b.winlost-b.actual_stake)  winlost,
				 b.playercomm as commission,
				 (b.scomm - b.acomm),
				 (b.acomm - b.comm),
				 (b.comm - b.playercomm),
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' as showtime,
				 b.winlostdate,
				 b.BetCheck,
				 '' AS transdesc
				 
			from	bettrans b with (nolock)   
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
				outer apply dbo.[f_ParseTransDesc](b.TransDesc, b.bettype) d

			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid 
					--AND bettype BETWEEN 1501 AND 1599
					AND	(
						s.ProductId 	= 8 	
						AND s.EventType = 0
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
					
			union all-- translog
			select 
				 b.gameid bettype,   
				 0 as transid, 
				 0 as betid,
				 b.translogid ,
				 '' as matchcode,   
				 '' as race,
				 '' as eventdate, 
				 0,
				 0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 as homeid,   
				 0 as awayid,  
				 '' settleTime, 
				 0 hdp1,
				 0 hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status,  
				 0 as comstatus, 
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
				 0 as finalhomescore, 
				 0 as finalawayscore,  
				 0 as leagueid,  
				 202 as sporttype, 
				 b.ip,
				 b.betfrom,
				 d.GameId matchid,
				 CONVERT(BIT,0) as IsNeutral,
				 0 as allowdelete,
				 (-b.actual_stake)  winlost,
				 0 as commission,
				 0,
				 0,
				 0,
				 0,
				 0,
				 0,
				 '' as showtime,
				 b.winlostdate	 ,
				 '' as BetCheck,
				 '' AS transdesc
				 
			from translog b with (nolock)   
				INNER JOIN @SportBettype s ON s.Bettype = b.gameID
				outer apply dbo.[f_ParseTransDesc](b.TransDesc, b.gameid) d
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid AND
					--AND b.gameID BETWEEN 1501 AND 1599
					b.statusID = 0
					AND	(
						s.ProductId 	= 8	
						AND s.EventType = 1
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
		END		
		
		--- P2P
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 9 AND Bettype = @Bettype)
		)
		BEGIN	
			INSERT INTO #BetListData
			select 
				 b.bettype,   
				 b.transid,   
				 isnull(b.betid,0),
				 b.refno,
				 '' matchcode,   
				 '' as race,
				 '' as eventdate, 
				 0,
				 0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 as homeid,   
				 0 as awayid,  
				 '' settleTime, 
				 b.hdp1,
				 b.hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status, 
				 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				 0 as finalhomescore, 
				 0 as finalawayscore,  
				 0 as leagueid,  
				 253 as sporttype, 
				 b.ip,
				 b.betfrom,
				 b.matchid,
				 CONVERT(BIT,0) as IsNeutral,
				 0 as allowdelete,
				 (b.winlost-b.actual_stake)  winlost,
				 b.playercomm as commission,
				 (b.scomm - b.acomm),
				 (b.acomm - b.comm),
				 (b.comm - b.playercomm),
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' as showtime,
				 b.winlostdate,
				 b.BetCheck,
				 '' AS transdesc
				 
			from	bettrans b with (nolock)   
				INNER JOIN @SportBettype s ON s.Bettype = b.bettype
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid  
					AND	(
						s.ProductId 	= 9 	
						AND s.EventType = 0
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
					
		END
		
		-- HR		
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 2 AND Bettype = @Bettype)
		)
		BEGIN
			INSERT INTO #BetListData 
			select 
				b.bettype,
				b.transid,
				isnull(b.betid,0),   
				b.refno,
				odds.matchcode, 
				odds.groupmatch as race,
				odds.eventdate as eventdate,
				b.virtualrate,
				--isnumeric(odds.programID),
				CASE WHEN b.currency2 IS NULL THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS isShowOTExRate,
				b.sdiscount,
				b.adiscount,
				b.discount,	  
				odds.teamid as homeid,
				0 as awayid,
				'' settleTime, 
				b.hdp1,
				b.hdp2,
				b.odds,   
				bm.finalodds,
				bm.finalodds2,
				'' OddsType,  
				b.status,
				CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				0 as finalhomescore, 
				0 as finalawayscore,  
				odds.leagueid,
				l.sporttype,
				b.ip ,
				b.betfrom,
				b.matchid,
				CONVERT(BIT,0) as IsNeutral,
				0 as allowdelete,
				(b.winlost-b.actual_stake)  winlost,
				b.playercomm as commission,
				(b.scomm - b.acomm),
				(b.acomm - b.comm),
				(b.comm - b.playercomm),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				'' as showtime,
				 b.winlostdate,
				 b.BetCheck,
				 '' AS transdesc
				 
			from	bettrans as b with (nolock)   
					inner join outright as odds with (nolock) on b.matchid=odds.orid   
					inner join league l with (nolock) on odds.leagueid=l.leagueid    
					INNER JOIN @SportBettype s ON s.Bettype = b.bettype
					left join (			
						SELECT	t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking, t.finalodds,
								f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2, f.finalodds finalodds2
						FROM	bettransm t WITH (NOLOCK)
								INNER JOIN bettransm f WITH (NOLOCK) ON t.refno = f.refno 
						WHERE	t.bettype in (31,41) AND f.bettype in (32,42)
					) bm on b.transid = bm.refno 
			where	b.winlostdate >= @FromDate 
					and b.winlostdate<= @ToDate 
					and b.custid = @Custid  
					--and  s.ProductID = 2 --b.bettype in (31,32,33,41,42,43) 
					AND	(
						s.ProductId 	= 2 	
						AND s.EventType = 2
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
		END		
		
		-- Virtual HR
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 5 AND Bettype = @Bettype)
		)
		BEGIN
			INSERT INTO #BetListData
			select 
				b.bettype,
				b.transid,
				'' betid,
				b.refno,
				o.RacerNum matchcode, --Horse Number
				b.oddsid as Race, --Outright ID
				'' eventdate,
				0,
				0,
				b.sdiscount,
				b.adiscount,
				b.discount,	
				o.RacerID as homeID, 
				0 as awayID,
				'' settleTime,
				b.hdp1,
				b.hdp2,
				b.odds,   
				0 finalodds,
				0 finalodds2,
				b.OddsType,  
				b.status,
				CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) 
						or statusID NOT IN(0, 1, 112, 113, 111) 
						or b.recommend IN (SELECT custid from #LASAgent)
						THEN 0 ELSE 1 END as allowdelete,
				(b.winlost-b.actual_stake)  winlost,
				b.playercomm as commission,
				(b.scomm - b.acomm),
				(b.acomm - b.comm),
				(b.comm - b.playercomm),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				r.EventTime showtime, -- Race Name
				b.winlostdate,
				b.BetCheck,
				'' AS transdesc
				 
			from 
				bettrans as b with (nolock) 
				INNER JOIN VSOutright o WITH (NOLOCK) ON b.oddsid = o.Orid
				INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
				INNER JOIN @SportBettype s ON s.BetType = b.BetType 
				left join (     
					SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking,
					  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2
					FROM bettransm t WITH (NOLOCK)  
					  INNER JOIN bettransm f WITH (NOLOCK) ON t.refno = f.refno   
					WHERE t.bettype = 1231 AND f.bettype = 1232 
					) bm on b.refno = bm.refno  
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid
					--s.ProductID = 5 AND
					--s.EventType = 3
					AND	(
						s.ProductId 	= 5
						AND s.EventType = 3
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
					
					--b.bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())					 
		END
		
		--Gold Deluxe
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 12 AND Bettype = @Bettype)
		)
		BEGIN
			INSERT INTO #BetListData
			select 
				 b.bettype,   
				 b.transid, 
				 isnull(b.betid,0) betid,
				 b.refno,
				 '' as matchcode,   
				 '' as race,
				 '' as eventdate, 
				 0,
				 0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 as homeid,   
				 0 as awayid,  
				 '' settleTime, 
				 b.hdp1,
				 b.hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status,
				 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				 0 as finalhomescore,
				 0 as finalawayscore,
				 0 as leagueid,
				 255 as sporttype,
				 b.ip,
				 b.betfrom,
				 b.matchid,
				 CONVERT(BIT,0) as IsNeutral,
				 0 as allowdelete,
				 (b.winlost-b.actual_stake)  winlost,
				 b.playercomm as commission,
				 (b.scomm - b.acomm),--Super comm
				 (b.acomm - b.comm),--Master comm
				 (b.comm - b.playercomm),--Agent comm
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' as showtime,
				 b.winlostdate,
				 b.BetCheck,
				 '' AS transdesc				 
				 
			from	dbo.bettrans b with (nolock)   
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid 
					--AND	s.ProductID = 12
					AND	(
						s.ProductId 	= 12
						AND s.EventType = 0
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
					
			union all-- translog
			select 
				 b.gameid bettype,   
				 0 as transid, 
				 0 as betid,
				 b.translogid refno,
				 '' as matchcode,   
				 '' as race,
				 '' as eventdate, 
				 0,
				 0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 as homeid,   
				 0 as awayid,  
				 '' settleTime, 
				 0 hdp1,
				 0 hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status,  
				 0 as comstatus, 
				 b.stake,  
				 b.actual_stake,    
				 b.transdate,   
				 b.GameID3rd as betteam,
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
				 0 as finalhomescore, 
				 0 as finalawayscore,  
				 0 as leagueid,  
				 255 as sporttype, 
				 b.ip,
				 b.betfrom,
				 NULL matchid,
				 CONVERT(BIT,0) as IsNeutral,
				 0 as allowdelete,
				 (-b.actual_stake)  winlost,
				 0 as commission,
				 0,
				 0,
				 0,
				 0,
				 0,
				 0,
				 '' as showtime,
				 b.winlostdate,
				 b.GameID3rd as BetCheck,
				 '' AS transdesc
			from dbo.translog b with (nolock)
				INNER JOIN @SportBettype s ON s.Bettype = b.gameid
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid AND
					b.statusid = 0
					--AND s.ProductID = 12 
					AND	(
						s.ProductId 	= 12
						AND s.EventType = 0
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
					
		END

		-- MicroGamming
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 13 AND Bettype = @Bettype)
		)
		BEGIN	
			INSERT INTO #BetListData
			select 
				 b.bettype,   
				 b.transid transid, 
				 isnull(b.betid,0),
				 b.refno,
				 '' as matchcode,   
				 '' as race,
				 '' as eventdate, 
				 0,
				 0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 as homeid,   
				 0 as awayid,  
				 '' settleTime, 
				 b.hdp1,
				 b.hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status,  
				 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				 0 as finalhomescore, 
				 0 as finalawayscore,  
				 0 as leagueid,  
				 203 as sporttype, 
				 b.ip,
				 b.betfrom,
				 0 AS matchid,
				 CONVERT(BIT,0) as IsNeutral,
				 0 as allowdelete,
				 (b.winlost-b.actual_stake)  winlost,
				 b.playercomm as commission,
				 (b.scomm - b.acomm),
				 (b.acomm - b.comm),
				 (b.comm - b.playercomm),
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' as showtime,
				 b.winlostdate,
				 b.BetCheck,
				 '' AS transdesc
				 
			from	bettrans b with (nolock)   
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype

			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid 
					AND	(
						s.ProductId 	= 13
						AND s.EventType = 0
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
					
			union all-- translog
			select 
				 b.gameid bettype,   
				 0 as transid, 
				 0 as betid,
				 b.translogid ,
				 '' as matchcode,   
				 '' as race,
				 '' as eventdate, 
				 0,
				 0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 as homeid,   
				 0 as awayid,  
				 '' settleTime, 
				 0 hdp1,
				 0 hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status,  
				 0 as comstatus, 
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
				 0 as finalhomescore, 
				 0 as finalawayscore,  
				 0 as leagueid,  
				 203 as sporttype, 
				 b.ip,
				 b.betfrom,
				 0 AS matchid,
				 CONVERT(BIT,0) as IsNeutral,
				 0 as allowdelete,
				 (-b.actual_stake)  winlost,
				 0 as commission,
				 0,
				 0,
				 0,
				 0,
				 0,
				 0,
				 '' as showtime,
				 b.winlostdate	 ,
				 '' as BetCheck,
				 '' AS transdesc
				 
			from translog b with (nolock)   
				INNER JOIN @SportBettype s ON s.Bettype = b.gameID
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid AND
					b.statusID = 0
					AND	(
						s.ProductId 	= 13
						AND s.EventType = 0
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
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
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID IN (1, 3, 4, 5) AND Bettype = @Bettype)
		)
		BEGIN
			
			INSERT INTO #BetListData
			select 
				b.bettype,
				b.transid,
				isnull(b.betid,0),
				b.refno,
				m.matchcode,
				'' as race,
				m.eventdate as eventdate,
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
				CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				0 as allowdelete,
				(b.winlost-b.actual_stake)  winlost,
				b.playercomm as commission,
				(b.scomm - b.acomm),
				(b.acomm - b.comm),
				(b.comm - b.playercomm),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				m.showtime,
				b.winlostdate,
				b.BetCheck,
				CASE WHEN b.bettype BETWEEN 801 AND 899 THEN b.transdesc ELSE '' END AS transdesc
					
			from 
				bettrans14 as b with (nolock) 
				inner join match14 as m with (nolock) 
				on b.matchid = m.matchid
				INNER JOIN @SportBettype s ON s.Bettype = b.bettype
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid 
					AND	(
						s.EventType = 1
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
					--and	s.EventType = 1
					--b.bettype < 19001 and
					--b.bettype not in (10,31,32,33,41,42,43/*,1231,1232,1233,1237,1238*/) and 
					--b.bettype NOT BETWEEN 1501 and 1599 and --20120626@Elodie: exclude outright, HR from sportbook
					--b.bettype NOT IN (SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
			
			--Mix Parlay
			IF (EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 1 AND Bettype = 9))
			BEGIN
				INSERT INTO #BetListData
				select 
					 9 bettype,   
					 b.transid,
					 isnull(b.betid,0),   
					 b.refno,
					 '' matchcode,  
					 '' as race,
					 '' as eventdate,
					 0,
					 0,
					 sdiscount,
					 adiscount,
					 discount,	 
					 0 as homeid,   
					 0 as awayid,  
					 '' settleTime, 
					 b.hdp1,
					 b.hdp2,
					 b.odds,   
					 0 finalodds,
					 0 finalodds2,
					 '' OddsType,  
					 b.status,   
					 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
					 0 as finalhomescore, 
					 0 as finalawayscore,  
					 0 as leagueid,  
					 0 as sporttype, 
					 b.ip,
					 b.betfrom,
					 0 matchid,	
					 CONVERT(BIT,0) as IsNeutral,
					 CASE WHEN statusID = 0 and b.recommend NOT IN (SELECT custid from #LASAgent) THEN 1 ELSE 0 END as allowdelete,
					 (b.winlost-b.actual_stake)  winlost,
					 b.playercomm as commission,
					 (b.scomm - b.acomm),
					 (b.acomm - b.comm),
					 (b.comm - b.playercomm),
					 b.awinlost,
					 b.mwinlost,
					 b.swinlost,
					 '' as showtime,
					 b.winlostdate,
					 b.BetCheck,
					 '' AS transdesc
						
				from	bettrans14 as b with (nolock)   
				where	b.winlostdate>= @FromDate and    
						b.winlostdate<= @ToDate and   
						b.custid = @Custid  
						--and matchid=0  
						and matchid = 9
						and bettype = 9  		
			END
				
			--Combination Mix Parlay
			IF (EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 1 AND Bettype = 29))
			BEGIN
				INSERT INTO #BetListData
				select 
					 29 bettype,   
					 CASE WHEN ISNULL(b.betID,0) = 0 THEN b.transid ELSE b.betID END AS transid,
					 isnull(b.betid,0),   
					 b.refno,
					 '' matchcode,  
					 '' as race,
					 '' as eventdate,
					 0,
					 0,
					 sdiscount,
					 adiscount,
					 discount,	 
					 0 as homeid,   
					 0 as awayid,  
					 '' settleTime, 
					 b.hdp1,
					 b.hdp2,
					 b.odds,   
					 0 finalodds,
					 0 finalodds2,
					 '' OddsType,  
					 b.status,  
					 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
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
					 0 as finalhomescore, 
					 0 as finalawayscore,  
					 0 as leagueid,  
					 0 as sporttype, 
					 b.ip,
					 b.betfrom,
					 0 matchid,	
					 CONVERT(BIT,0) as IsNeutral,
					 0 as allowdelete,
					 (b.winlost-b.actual_stake)  winlost,
					 b.playercomm as commission,
					 (b.scomm - b.acomm),
					 (b.acomm - b.comm),
					 (b.comm - b.playercomm),
					 b.awinlost,
					 b.mwinlost,
					 b.swinlost,
					 '' as showtime,
					 b.winlostdate,
					 b.BetCheck,
					'' AS transdesc			 
					
				from	bettrans14 as b with (nolock)   
				where	b.winlostdate>= @FromDate and    
						b.winlostdate<= @ToDate and   
						b.custid = @Custid  
						--and matchid=0  
						and matchid = 29
						and bettype = 29  	
			END	
			-- Outright
			IF (EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 1 AND Bettype = 10))
			BEGIN
				INSERT INTO #BetListData
				select 
					b.bettype,
					b.transid,   
					isnull(b.betid,0),
					b.refno,
					odds.matchcode, 
					odds.groupmatch as race,
					odds.eventdate as eventdate,
					0,0,
					b.sdiscount,
					b.adiscount,
					b.discount,	  
					0 as homeid,
					odds.teamid as awayid,
					'' settleTime, 
					b.hdp1,
					b.hdp2,
					b.odds,   
					0 finalodds,
					0 finalodds2,
					'' OddsType,  
					b.status,   
					CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
					0 as finalhomescore, 
					0 as finalawayscore,  
					odds.leagueid,
					l.sporttype,
					b.ip ,
					b.betfrom,
					b.matchid,
					CONVERT(BIT,0) as IsNeutral,
					0 as allowdelete,
					(b.winlost-b.actual_stake)  winlost,
					b.playercomm as commission,
					(b.scomm - b.acomm),
					(b.acomm - b.comm),
					(b.comm - b.playercomm),
					b.awinlost,
					b.mwinlost,
					b.swinlost,
					'' as showtime,
					 b.winlostdate,
					 b.BetCheck,
					'' AS transdesc
						
				from	bettrans14 as b with (nolock)   
						inner join outright14 as odds with (nolock) on b.matchid=odds.orid   
						inner join league l with (nolock) on odds.leagueid=l.leagueid     
				where b.bettype = 10
				and b.winlostdate >= @FromDate and   
				b.winlostdate<= @ToDate  and
				b.custid = @Custid 	
			END
		END
		
		--- Casino
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 6 AND Bettype = @Bettype)
		)
		BEGIN
			
			INSERT INTO #BetListData
			select 
				 b.bettype,   
				 b.betid transid,
				 isnull(b.betid,0),   
				 b.refno,
				 CONVERT(varchar(50), b.refno) matchcode,   
				 '' as race,
				 '' as eventdate, 
				 0,0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 as homeid,   
				 0 as awayid,  
				 '' settleTime, 
				 b.hdp1,
				 b.hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status,   
				 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				 0 as finalhomescore, 
				 0 as finalawayscore,  
				 0 as leagueid,  
				 251 as sporttype, 
				 b.ip,
				 b.betfrom,
				 b.matchid,
				 CONVERT(BIT,0) as IsNeutral,
				 0 as allowdelete,
				 (b.winlost-b.actual_stake)  winlost,
				 b.playercomm as commission,
				 (b.scomm - b.acomm),
				 (b.acomm - b.comm),
				 (b.comm - b.playercomm),
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' as showtime,
				 b.winlostdate,
				 b.BetCheck,
				'' AS transdesc
					
			from	bettrans14 b with (nolock)   
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid 
					--AND	s.ProductID = 6 
					--AND bettype = 71								--20120405@Hurri	
					AND	(
						s.ProductId 	= 6
						AND s.EventType = 0
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
		END
		
		--ibc bingo
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 9 AND Bettype = @Bettype)
		)
		BEGIN		
			
			INSERT INTO #BetListData
			select 
				 b.bettype,   
				 b.betid transid, 
				 isnull(b.betid,0),
				 b.refno,
				 CONVERT(varchar(50), b.refno) as matchcode,   
				 '' as race,
				 '' as eventdate, 
				 0,
				 0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 as homeid,   
				 0 as awayid,  
				 '' settleTime, 
				 b.hdp1,
				 b.hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status,   
				 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				 0 as finalhomescore, 
				 0 as finalawayscore,  
				 0 as leagueid,  
				 252 as sporttype, 
				 b.ip,
				 b.betfrom,
				 b.matchid,
				 CONVERT(BIT,0) as IsNeutral,
				 0 as allowdelete,
				 (b.winlost-b.actual_stake)  winlost,
				 b.playercomm as commission,
				 (b.scomm - b.acomm),
				 (b.acomm - b.comm),
				 (b.comm - b.playercomm),
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' as showtime,
				 b.winlostdate,
				 b.BetCheck,
				'' AS transdesc
					
			from	bettrans14 b with (nolock)   
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid 
					--AND	s.ProductID = 7
					--AND bettype = 73
					AND	(
						s.ProductId 	= 7
						AND s.EventType = 0
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
		END
		
		--ibc KENO
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 8 AND Bettype = @Bettype)
		)
		BEGIN		
			
			INSERT INTO #BetListData
			select 
				 b.bettype,   
				 b.betid transid, 
				 isnull(b.betid,0),
				 b.refno,
				 CONVERT(varchar(50), b.refno) as matchcode,   
				 '' as race,
				 '' as eventdate, 
				 0,
				 0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 as homeid,   
				 0 as awayid,  
				 '' settleTime, 
				 b.hdp1,
				 b.hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status,  
				 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				 0 as finalhomescore, 
				 0 as finalawayscore,  
				 0 as leagueid,  
				 202 as sporttype, 
				 b.ip,
				 b.betfrom,
				 d.GameId matchid,
				 CONVERT(BIT,0) as IsNeutral,
				 0 as allowdelete,
				 (b.winlost-b.actual_stake)  winlost,
				 b.playercomm as commission,
				 (b.scomm - b.acomm),
				 (b.acomm - b.comm),
				 (b.comm - b.playercomm),
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' as showtime,
				b.winlostdate,
				b.BetCheck,
				'' AS transdesc
					
			from	bettrans14 b with (nolock)   
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
				outer apply dbo.[f_ParseTransDesc](b.TransDesc, b.bettype) d
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid 
					--AND	s.ProductID = 8
					--AND bettype BETWEEN 1501 AND 1599
					AND	(
						s.ProductId 	= 8
						AND s.EventType = 0
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
		END
		
		--- P2P
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 9 AND Bettype = @Bettype)
		)
		BEGIN	
		
			INSERT INTO #BetListData
			select 
				 b.bettype,   
				 b.transid,
				 isnull(b.betid,0),   
				 b.refno,
				 '' matchcode,   
				 '' as race,
				 '' as eventdate, 
				 0,0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 as homeid,   
				 0 as awayid,  
				 '' settleTime, 
				 b.hdp1,
				 b.hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status,   
				 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				 0 as finalhomescore, 
				 0 as finalawayscore,  
				 0 as leagueid,  
				 253 as sporttype, 
				 b.ip,
				 b.betfrom,
				 b.matchid,
				 CONVERT(BIT,0) as IsNeutral,
				 0 as allowdelete,
				 (b.winlost-b.actual_stake)  winlost,
				 b.playercomm as commission,
				 (b.scomm - b.acomm),
				 (b.acomm - b.comm),
				 (b.comm - b.playercomm),
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' as showtime,
				 b.winlostdate,
				 b.BetCheck,
				'' AS transdesc
					
			from	bettrans14 b with (nolock)   
				INNER JOIN @SportBettype s ON s.Bettype = b.bettype
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid  
					--AND bettype  = 1000
					AND	(
						s.ProductId 	= 9
						AND s.EventType = 0
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
					
		END
		
		-- HR		
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 2 AND Bettype = @Bettype)
		)
		BEGIN	
			INSERT INTO #BetListData 
			select 
				b.bettype,
				b.transid,
				isnull(b.betid,0),   
				b.refno,
				odds.matchcode, 
				odds.groupmatch as race,
				odds.eventdate as eventdate,
				b.virtualrate,
				--isnumeric(odds.programID),
				CASE WHEN b.currency2 IS NULL THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS isShowOTExRate,
				b.sdiscount,
				b.adiscount,
				b.discount,	  
				odds.teamid as homeid,
				0 as awayid,
				'' settleTime, 
				b.hdp1,
				b.hdp2,
				b.odds,   
				bm.finalodds,
				bm.finalodds2,
				'' OddsType,  
				b.status,   
				CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				0 as finalhomescore, 
				0 as finalawayscore,  
				odds.leagueid,
				l.sporttype,
				b.ip ,
				b.betfrom,
				b.matchid,
				CONVERT(BIT,0) as IsNeutral,
				0 as allowdelete,
				(b.winlost-b.actual_stake)  winlost,
				b.playercomm as commission,
				(b.scomm - b.acomm),
				(b.acomm - b.comm),
				(b.comm - b.playercomm),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				'' as showtime,
				 b.winlostdate,
				 b.BetCheck,
				'' AS transdesc
					
			from	bettrans14 as b with (nolock)   
					inner join outright14 as odds with (nolock) on b.matchid=odds.orid   
					inner join league l with (nolock) on odds.leagueid=l.leagueid    
					INNER JOIN @SportBettype s ON s.Bettype = b.bettype
					left join (			
						SELECT	t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking, t.finalodds,
								f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2, f.finalodds finalodds2
						FROM	bettransm14 t WITH (NOLOCK)
								INNER JOIN bettransm14 f WITH (NOLOCK) ON t.refno = f.refno 
						WHERE	t.bettype in (31,41) AND f.bettype in (32,42)
					) bm on b.transid = bm.refno 
			where	b.winlostdate >= @FromDate 
					and b.winlostdate<= @ToDate 
					and b.custid = @Custid 
					--and s.ProductID = 2 --b.bettype in (31,32,33,41,42,43)
					AND	(
						s.ProductId 	= 2 	
						AND s.EventType = 2
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
		END
		
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 5 AND Bettype = @Bettype)
		)
		BEGIN		
			-- Virtual HR
			INSERT INTO #BetListData
			select 
				b.bettype,
				b.transid,
				'' betid,
				b.refno,
				o.RacerNum matchcode, --Horse Number
				b.oddsid as Race, --Outright ID
				'' eventdate,
				0,
				0,
				b.sdiscount,
				b.adiscount,
				b.discount,	
				o.RacerID as homeID, 
				0 as awayID,
				'' settleTime,
				b.hdp1,
				b.hdp2,
				b.odds,   
				0 finalodds,
				0 finalodds2,
				b.OddsType,  
				b.status,
				CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) 
						or statusID NOT IN(0, 1, 112, 113, 111) 
						or b.recommend IN (SELECT custid from #LASAgent)
						THEN 0 ELSE 1 END as allowdelete,
				(b.winlost-b.actual_stake)  winlost,
				b.playercomm as commission,
				(b.scomm - b.acomm),
				(b.acomm - b.comm),
				(b.comm - b.playercomm),
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				r.EventTime showtime, -- Race Name			
				b.winlostdate,
				b.BetCheck,
				'' AS transdesc
					
			from 
				bettrans14 as b with (nolock) 
				INNER JOIN VSOutright14 o WITH (NOLOCK) ON b.oddsid = o.Orid
				INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
				INNER JOIN @SportBettype s ON s.BetType = b.BetType 
				left join (     
					SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking,
					  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2
					FROM bettransm14 t WITH (NOLOCK)  
					  INNER JOIN bettransm14 f WITH (NOLOCK) ON t.refno = f.refno   
					WHERE t.bettype = 1231 AND f.bettype = 1232 
					) bm on b.refno = bm.refno  
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid 
					--and	s.ProductID=5 
					--AND s.EventType=3
					--b.bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())		
					AND	(
						s.ProductId 	= 5 	
						AND s.EventType = 3
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
		END
		
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 12 AND Bettype = @Bettype)
		)
		BEGIN		
			--Gold Deluxe
			INSERT INTO #BetListData
			SELECT 
				 b.bettype,   
				 b.transid, 
				 isnull(b.betid,0) betid,
				 b.refno,
				 '' as matchcode,   
				 '' as race,
				 '' as eventdate, 
				 0,
				 0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 as homeid,   
				 0 as awayid,  
				 '' settleTime, 
				 b.hdp1,
				 b.hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status,  
				 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				 0 as finalhomescore, 
				 0 as finalawayscore,  
				 0 as leagueid,  
				 255 as sporttype, 
				 b.ip,
				 b.betfrom,
				 b.matchid,
				 CONVERT(BIT,0) as IsNeutral,
				 0 as allowdelete,
				 (b.winlost-b.actual_stake)  winlost,
				 b.playercomm as commission,
				 (b.scomm - b.acomm),
				 (b.acomm - b.comm),
				 (b.comm - b.playercomm),
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' as showtime,
				 b.winlostdate,
				 b.BetCheck,
				'' AS transdesc
					
			from	dbo.bettrans14 b with (nolock)   
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid
					AND	(
						s.ProductId 	= 12
						AND s.EventType = 0
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
						
		END

		-- MicroGamming
		IF (@Bettype = 0
			OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 13 AND Bettype = @Bettype)
		)
		BEGIN		
			
			INSERT INTO #BetListData
			select 
				 b.bettype,   
				 b.transid transid, 
				 isnull(b.betid,0),
				 b.refno,
				 '' as matchcode,   
				 '' as race,
				 '' as eventdate, 
				 0,
				 0,
				 sdiscount,
				 adiscount,
				 discount,	 
				 0 as homeid,   
				 0 as awayid,  
				 '' settleTime, 
				 b.hdp1,
				 b.hdp2,
				 b.odds,   
				 0 finalodds,
				 0 finalodds2,
				 '' OddsType,  
				 b.status,  
				 CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus, 
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
				 0 as finalhomescore, 
				 0 as finalawayscore,  
				 0 as leagueid,  
				 203 as sporttype, 
				 b.ip,
				 b.betfrom,
				 0 AS matchid,
				 CONVERT(BIT,0) as IsNeutral,
				 0 as allowdelete,
				 (b.winlost-b.actual_stake)  winlost,
				 b.playercomm as commission,
				 (b.scomm - b.acomm),
				 (b.acomm - b.comm),
				 (b.comm - b.playercomm),
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' as showtime,
				b.winlostdate,
				b.BetCheck,
				'' AS transdesc
					
			from	bettrans14 b with (nolock)   
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid 
					AND	(
						s.ProductId 	= 13
						AND s.EventType = 0
						AND (@bettype 	= 0 OR s.bettype = @bettype)
					)
		END		
	END 
	   
	UPDATE betList
	SET betList.Odds	= originBetList.Odds
		,betList.Stake	= originBetList.Stake
		,betList.comm	= CASE WHEN betList.Bettype = 902 THEN commBetList.awinlost ELSE betList.comm END
		,betList.BetID	= originBetList.Bettype
	FROM #BetListData AS betList
		INNER JOIN #BetListData AS originBetList ON betList.RefNO = originBetList.TransID
		INNER JOIN #BetListData AS commBetList ON betList.RefNO = commBetList.RefNO
	WHERE betList.Sporttype = 1 AND betList.Bettype IN (901, 902)
		AND commBetList.Bettype = 903

	DELETE #BetListData WHERE Sporttype = 1 AND Bettype = 903

	SELECT * FROM #BetListData
	ORDER BY transid  

	IF EXISTS (SELECT TOP 1 1 
			FROM @SportBettype sp 
				INNER JOIN #BetListData d
					ON d.bettype = sp.bettype 
			WHERE ProductID in (4,12)) 
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
				FROM dbo.bettransg BG with (NOLOCK)
					INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (4)
					INNER JOIN #BetListData B1 ON (BG.refno = B1.refno AND BG.bettype = B1.bettype AND sp.Productid in (4))
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
				FROM dbo.bettransg BG with (NOLOCK)
					INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (12)
					INNER JOIN #BetListData B2 ON (BG.refno = B2.transid AND BG.bettype = B2.bettype AND sp.Productid in (12))
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
				FROM dbo.bettransg14 BG with (NOLOCK)
					INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (4)
					INNER JOIN #BetListData B1 ON (BG.refno = B1.refno AND BG.bettype = B1.bettype AND sp.Productid in (4))
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
				FROM dbo.bettransg14 BG with (NOLOCK)
					INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (12)
					INNER JOIN #BetListData B2 ON (BG.refno = B2.transid AND BG.bettype = B2.bettype AND sp.Productid in (12))	   
		END 
	END
			   
	 SELECT * FROM #BetListDetailData BG ORDER BY BG.refno

	 DROP TABLE #BetListData
	 DROP TABLE #BetListDetailData
	 DROP TABLE #LASAgent
END
GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetList] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetList] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetsSelBetList] TO [vnteam] AS [dbo]