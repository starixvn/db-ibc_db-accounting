USE bodb_archive
GO

ALTER PROCEDURE [dbo].[Acc_BetsSelBetList_Old]
	@FromDate datetime,  
	@ToDate datetime,  
	@CustID int,
	@Bettype int = 0	 
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
*/	
BEGIN

	SET NOCOUNT ON	
	CREATE TABLE #BetListData (
		bettype smallint,
		transid bigint, 
		betid bigint,
		refno nvarchar(50), 
		matchcode nvarchar(50),
		race nvarchar(20),
		eventdate smalldatetime,
		virtualrate float,
		isShowOTExRate bit,
		sdiscount smallmoney,
		adiscount smallmoney,
		discount smallmoney,
		homeid int, 
		awayid int, 
		settleTime datetime,
		hdp1 smallmoney, 
		hdp2 smallmoney, 
		odds smallmoney,
		finalodds smallmoney,
		finalodds2 smallmoney,
		OddsType tinyint,
		status nvarchar(50),
		comstatus nvarchar(50), 
		stake money,
		actual_stake money,
		transdate datetime,
		betteam nvarchar(10),
		spositiontaking smallmoney,
		mpositiontaking smallmoney,
		apositiontaking smallmoney,
		spositiontaking2 smallmoney,
		mpositiontaking2 smallmoney,
		apositiontaking2 smallmoney,
		liveindicator bit,
		modds smallmoney,
		custid int,
		livehomescore smallint, 
		liveawayscore smallint, 
		finalhomescore smallint, 
		finalawayscore smallint, 
		leagueid int, 
		sporttype smallint, 
		ip nvarchar(15), 
		betfrom nvarchar (1),
		matchid int,
		isNeutral bit,
		allowdelete bit,
		winlost money,
		commission money,
		scomm money,	
		acomm money,
		comm money,
		awinlost money,
		mwinlost money,
		swinlost money,
		showtime nvarchar(50),
		winlostdate		smalldatetime,
		BetCheck	NVARCHAR(50),
		transdesc	NVARCHAR(300)
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

	----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT)
	INSERT INTO @SportBettype
	EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode=4

	IF @Bettype <> 0
	BEGIN
		DELETE @SportBettype 
		WHERE Bettype <> @Bettype
	END

	IF (@Bettype = 0
		OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 1 AND Bettype = @Bettype)
	)
	BEGIN
		--Sport Book
		INSERT INTO #BetListData
		select 
			b.bettype,
			b.transid,
			isnull(b.BetID,0),
			b.refno,
			m.matchcode,
			'' as race,
			m.eventdate as eventdate,
			0,0,
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
			(b.scomm - b.acomm) as scomm,
			(b.acomm - b.comm) as acomm,
			(b.comm - b.playercomm) as comm,
			b.awinlost,
			b.mwinlost,
			b.swinlost,
			m.showtime,
			b.winlostdate,
			b.BetCheck,
			CASE WHEN b.bettype BETWEEN 801 AND 899 THEN b.transdesc ELSE '' END AS transdesc 						
		from 
			dbo.bettrans_bk as b with (nolock,index=IX_custid) 
			inner join dbo.match_BK as m with (nolock) on b.matchid = m.matchid 
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		where	b.winlostdate>= @FromDate and    
				b.winlostdate<= @ToDate and   
				b.custid = @Custid 
				AND	(
					s.ProductId 	= 1 	
					AND s.EventType = 1
					AND (@bettype 	= 0 OR s.bettype = @bettype)
				)
				
				--b.bettype < 19001 and
				--b.bettype not in (10,31,32,33,41,42,43/*,1231,1232,1233,1237,1238*/) and 
				--b.bettype NOT BETWEEN 1501 and 1599 and --20120626@Elodie: exclude outright, HR from sportbook
				--b.bettype NOT IN (SELECT  bettype FROM bodb02.dbo.f_VSHorseRacingByBettype())
			
		--Mix Parlay
		IF (EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 1 AND Bettype = 9))
		BEGIN
			INSERT INTO #BetListData
			select 
				 9 bettype,   
				 b.transid,   
				 isnull(b.BetID,0),
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
				 (b.scomm - b.acomm) as scomm,
				 (b.acomm - b.comm) as acomm,
				 (b.comm - b.playercomm) as comm,
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' as showtime,
				b.winlostdate,
				b.BetCheck,
				'' AS transdesc 				
			from	dbo.bettrans_bk AS b with (nolock, index=IX_custid)
			where	b.winlostdate>= @FromDate and    
					b.winlostdate<= @ToDate and   
					b.custid = @Custid  
					--and matchid=0  
					and matchid IN (0,9)
					and bettype = 9  
		END	 
		 --Combination Mix Parlay
		IF (EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 1 AND Bettype = 29))
		BEGIN
			INSERT INTO #BetListData
			select 
				 29 bettype,   
				 CASE WHEN ISNULL(b.betID,0) = 0 THEN b.transid ELSE b.betID END AS transid,
				 isnull(b.BetID,0),
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
				 (b.scomm - b.acomm) as scomm,
				 (b.acomm - b.comm) as acomm,
				 (b.comm - b.playercomm) as comm,
				 b.awinlost,
				 b.mwinlost,
				 b.swinlost,
				 '' as showtime,
				b.winlostdate,
				b.BetCheck,
				'' AS transdesc								 
			from	dbo.bettrans_bk AS b with (nolock, index=IX_custid)
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
				isnull(b.BetID,0),
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
				(b.scomm - b.acomm) as scomm,
				(b.acomm - b.comm) as acomm,
				(b.comm - b.playercomm) as comm,
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				'' as showtime,
				b.winlostdate,
				b.BetCheck,
				'' AS transdesc									
			from	dbo.bettrans_bk AS b with (nolock, index=IX_custid)   
					inner join dbo.Outright_bk as odds with (nolock) on b.matchid=odds.orid   
					inner join bodb02.dbo.league l with (nolock) on odds.leagueid=l.leagueid     
			where b.bettype = 10
			and b.winlostdate >= @FromDate and   
			b.winlostdate<= @ToDate  and
			b.custid = @Custid  
		END
	END
	IF (@Bettype = 0
		OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 6 AND Bettype = @Bettype)
	)
	BEGIN
		--- Casino
		INSERT INTO #BetListData
		select 
			 b.bettype,   
			 b.betid transid,   
			 isnull(b.BetID,0),
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
			 (b.scomm - b.acomm) as scomm,
			 (b.acomm - b.comm) as acomm,
			 (b.comm - b.playercomm) as comm,
			 b.awinlost,
			 b.mwinlost,
			 b.swinlost,
			 '' as showtime,
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc								 
		from	dbo.bettrans_bk AS b with (nolock, index=IX_custid)	
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		where	b.winlostdate>= @FromDate and    
				b.winlostdate<= @ToDate and   
				b.custid = @Custid  
				AND	(
					s.ProductId 	= 6 	
					AND s.EventType = 0
					AND (@bettype 	= 0 OR s.bettype = @bettype)
				)
	END
	IF (@Bettype = 0
		OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 7 AND Bettype = @Bettype)
	)
	BEGIN
		--IBC BIngo
		INSERT INTO #BetListData
		select 
			 b.bettype,   
			 b.betid transid,   
			 isnull(b.BetID,0),
			 b.refno,
			 CONVERT(varchar(50), b.refno) as matchcode,   
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
			 252 as sporttype, 
			 b.ip,
			 b.betfrom,
			 b.matchid,
			 CONVERT(BIT,0) as IsNeutral,
			 0 as allowdelete,
			 (b.winlost-b.actual_stake)  winlost,
			 b.playercomm as commission,
			 (b.scomm - b.acomm) as scomm,
			 (b.acomm - b.comm) as acomm,
			 (b.comm - b.playercomm) as comm,
			 b.awinlost,
			 b.mwinlost,
			 b.swinlost,
			 '' as showtime,
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc								 
		from	dbo.bettrans_bk AS b with (nolock, index=IX_custid)	
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		where	b.winlostdate>= @FromDate and    
				b.winlostdate<= @ToDate and   
				b.custid = @Custid 
				AND	(
					s.ProductId 	= 7 	
					AND s.EventType = 0
					AND (@bettype 	= 0 OR s.bettype = @bettype)
				)
	END
	IF (@Bettype = 0
		OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 8 AND Bettype = @Bettype)
	)
	BEGIN
		--keno
		INSERT INTO #BetListData
		select 
			 b.bettype,   
			 b.betid transid,   
			 isnull(b.BetID,0),
			 b.refno,
			 CONVERT(varchar(50), b.refno) as matchcode,   
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
			 (b.scomm - b.acomm) as scomm,
			 (b.acomm - b.comm) as acomm,
			 (b.comm - b.playercomm) as comm,
			 b.awinlost,
			 b.mwinlost,
			 b.swinlost,
			 '' as showtime,
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc								 
		from	dbo.bettrans_bk AS b with (nolock, index=IX_custid)	
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		outer apply dbo.[f_ParseTransDesc](b.TransDesc, b.bettype) d
		where	b.winlostdate>= @FromDate and    
				b.winlostdate<= @ToDate and   
				b.custid = @Custid  
				AND	(
					s.ProductId 	= 8 	
					AND s.EventType = 0
					AND (@bettype 	= 0 OR s.bettype = @bettype)
				)				
	END
	IF (@Bettype = 0
		OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 9 AND Bettype = @Bettype)
	)
	BEGIN				
		--- P2P
		INSERT INTO #BetListData
		select 
			 b.bettype,   
			 b.transid,   
			 isnull(b.BetID,0),
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
			 (b.scomm - b.acomm) as scomm,
			 (b.acomm - b.comm) as acomm,
			 (b.comm - b.playercomm) as comm,
			 b.awinlost,
			 b.mwinlost,
			 b.swinlost,
			 '' as showtime,
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc									 
		from	dbo.bettrans_bk AS b with (nolock, index=IX_custid)	
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
	IF (@Bettype = 0
		OR EXISTS(SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 2 AND Bettype = @Bettype)
	)
	BEGIN		
		-- HR		
		INSERT INTO #BetListData 
		select 
			b.bettype,
			b.transid,   
			isnull(b.BetID,0),
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
			(b.scomm - b.acomm) as scomm,
			(b.acomm - b.comm) as acomm,
			(b.comm - b.playercomm) as comm,
			b.awinlost,
			b.mwinlost,
			b.swinlost,
			'' as showtime,
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc									
		from	dbo.bettrans_bk AS b with (nolock, index=IX_custid)   
				inner join dbo.Outright_bk as odds with (nolock) on b.matchid=odds.orid   
				inner join bodb02.dbo.league l with (nolock) on odds.leagueid=l.leagueid    
				INNER JOIN @SportBettype s ON s.Bettype = b.bettype
				left join (			
					SELECT	t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking, t.finalodds,
							f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2, f.finalodds finalodds2
					FROM	dbo.bettransm t WITH (NOLOCK)
							INNER JOIN dbo.bettransm f WITH (NOLOCK) ON t.refno = f.refno 
					WHERE	t.bettype in (31,41) AND f.bettype in (32,42)
				) bm on b.transid = bm.refno 
		where	b.winlostdate >= @FromDate 
				and b.winlostdate<= @ToDate 
				and b.custid = @Custid   
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
			0 as allowdelete,
			(b.winlost-b.actual_stake)  winlost,
			b.playercomm as commission,
			(b.scomm - b.acomm),
			(b.acomm - b.comm),
			(b.comm - b.playercomm),
			b.awinlost,
			b.mwinlost,
			b.swinlost,
			r.EventTime showtime, -- race name
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc
		from 
			bettrans_bk as b with (nolock, index=IX_custid)    
			INNER JOIN VSOutright_bk o WITH (NOLOCK) ON b.oddsid = o.Orid
			INNER JOIN bodb02.dbo.VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
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
		from	dbo.bettrans_bk b with (nolock)   
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

	 SELECT * 
	 FROM #BetListData ORDER BY transid 	

	 IF EXISTS (SELECT TOP 1 1 
			FROM @SportBettype sp 
				INNER JOIN #BetListData d
					ON d.bettype = sp.bettype 
			WHERE ProductID in (4,12)) 
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
			FROM dbo.bettransg BG with (NOLOCK)
				INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (4)
				INNER JOIN #BetListData B ON (BG.refno = B.refno AND BG.CustID = B.CustID AND sp.Productid in (4))
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
				BG.betteam  ,
				BG.TransDesc 
			FROM dbo.bettransg BG with (NOLOCK)
				INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (12)
				INNER JOIN #BetListData B ON (BG.refno = B.transid AND BG.CustID = B.CustID AND sp.Productid in (12))
					
	END 
			   
	 SELECT * FROM #BetListDetailData BG ORDER BY refno
		
	 DROP TABLE #BetListData;
	 DROP TABLE #BetListDetailData;
END
GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetList_Old] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetList_Old] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetsSelBetList_Old] TO [vnteam]
