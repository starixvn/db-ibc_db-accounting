USE bodb02
GO

ALTER PROCEDURE [dbo].[Acc_BetsSelBetList_ByTransID_Advance]  
	@TransID bigint
AS  
/*
	Created by: Elodie
	Date: 20121212
	Task: Ticket's information by TransID only
	DB: DBAGE/bodb02 
	Original:  Acc_BetsSelBetList_ByTransID 
	
	Revisions:
		- 20130121@Dan: change linked server DB06 to DBARC	
		- 20130227@Elodie: Add Virtual HR product
		- 20130724@Elodie: Get winlostdate field
		- 20130726@Elodie: Define data for bettrans, bettrans14 or bettrans_bk by winlostdate field
						   Enhance performance
		- 20140907@Dom:	[Redmine #22012] update VS Condition
		- 20141103@Dom: Apply sport bettype matrix
		- 20150415@Sophia: Support Betradar and revise code of Bettype matrix
*/ 

SET NOCOUNT ON  


----Get Sport Bettype Matrix------
DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT)
INSERT INTO @SportBettype
EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode=4


DECLARE @refno BIGINT		

Declare @Data TABLE (
	username		nvarchar(50),
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
	betteam			nvarchar(10),
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
	BetCheck		NVARCHAR(50)
)

DECLARE @DetailData TABLE (
	refno			nvarchar(50), 
	odds			smallmoney, 
	stake			money,
	status			nvarchar(50),
	apositiontaking smallmoney, 
	mpositiontaking smallmoney, 
	spositiontaking smallmoney,
	bettype			smallint,
	betteam			nvarchar(50)	
)

DECLARE @WinlostDate smalldatetime, @MoveBetsDay smalldatetime, @BalanceUpDay smalldatetime, @bettype int
DECLARE @tmp TABLE (BalanceUpDay smalldatetime, MoveBetsDay smalldatetime) 
INSERT INTO @tmp(BalanceUpDay, MoveBetsDay)
EXEC Age_SelBalanceUpDay

SELECT @MoveBetsDay = MoveBetsDay, @BalanceUpDay = BalanceUpDay FROM @tmp

IF exists (select top 1 1 from bettrans with (nolock) where transid = @TransID)
	SELECT @WinlostDate = winlostdate, @bettype = bettype ,@refno = refno from bettrans with (nolock) where transid = @TransID
ELSE IF exists(select top 1 1  from bettrans14 with (nolock) where transid = @TransID)
	SELECT @WinlostDate = winlostdate, @bettype = bettype ,@refno = refno from bettrans14 with (nolock) where transid = @TransID
ELSE IF exists(select top 1 1 from DBARC.bodb_archive.dbo.bettrans_bk with (nolock) where transid = @TransID)
	SELECT @WinlostDate = winlostdate, @bettype = bettype ,@refno = refno from DBARC.bodb_archive.dbo.bettrans_bk with (nolock) where transid = @TransID
ELSE IF exists(  
	select top 1 1 from bettrans bt with (nolock)
	INNER JOIN @SportBettype sp ON bt.bettype = sp.bettype 
	where (refno = @transid AND sp.productid IN (12))
) 
	SELECT @WinlostDate = winlostdate, @bettype = bt.bettype ,@refno = refno
		from bettrans bt with (nolock)
		INNER JOIN @SportBettype sp ON bt.bettype = sp.bettype
		where (refno = @transid AND sp.productid IN (12))
ELSE IF exists(  
	select top 1 1 from translog bt with (nolock)   
		INNER JOIN @SportBettype sp ON bt.gameID = sp.bettype
	where translogid = @TransID AND sp.productid IN (12) and statusID = 0
)
	SELECT @WinlostDate = winlostdate, @bettype = gameID ,@refno = translogid
		from translog bt with (nolock)   
		INNER JOIN @SportBettype sp ON bt.gameID = sp.bettype
		where translogid = @TransID  AND sp.productid IN (12) and statusID = 0
ELSE IF exists(  
	select top 1 1 from bettrans14 bt with (nolock)   
	INNER JOIN @SportBettype sp ON bt.bettype = sp.bettype 
	where ((refno = @transid AND sp.productid IN (12)))
)
	SELECT @WinlostDate = winlostdate, @bettype = bt.bettype ,@refno = refno
	from bettrans14 bt with (nolock)   
	INNER JOIN @SportBettype sp ON bt.bettype = sp.bettype 
	where ((refno = @transid AND sp.productid IN (12)))
ELSE IF exists(  
select top 1 1 from DBARC.bodb_archive.dbo.bettrans_bk bt with (nolock)    
	INNER JOIN @SportBettype sp ON bt.bettype = sp.bettype 
where refno = @transid AND sp.productid IN (12)
)
	SELECT @WinlostDate = winlostdate, @bettype = bt.bettype ,@refno = refno
	from DBARC.bodb_archive.dbo.bettrans_bk bt with (nolock)   
	INNER JOIN @SportBettype sp ON bt.bettype = sp.bettype 
	where refno = @transid AND sp.productid IN (12)

--Bettrans
IF @WinlostDate > @MoveBetsDay
BEGIN
	IF @bettype < 19001 and @bettype NOT IN (31,32,33,10/*, 1231,1232,1233,1237,1238*/) and @bettype not in (SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
	--Sportbooks
	INSERT INTO @Data
	select 
		b.username,
		b.bettype,
		b.transid,
		isnull(b.BetID,0) as BetID,
		b.refno,
		m.matchcode,
		'' as race,
		m.eventdate as eventdate,
		0 as virtualrate,
		0 as isShowOTExRate,
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
		b.BetCheck	
	from 
		bettrans as b with (nolock) 
		INNER JOIN match as m with (nolock) on b.matchid = m.matchid --phuong.nguyen, remove left join match_remark
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where	s.EventType=1 
			--b.bettype < 19001 and b.bettype NOT IN (31,32,33,10/*, 1231,1232,1233,1237,1238*/) and
			--b.bettype not in (SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) and
			AND b.transid = @TransID
			
	--Mix Parlay
	IF @bettype = 9
	INSERT INTO @Data
	select 
		 b.username,
		 9 bettype,   
		 b.transid,   
		 isnull(b.BetID,0) as BetID,
		 b.refno,
		 '' matchcode,  
		 '' as race,
		 '' as eventdate,
		 0 as virtualrate,
		 0 as isShowOTExRate,
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
		 0, 0,  
		 0 as leagueid,  
		 0 as sporttype, 
		 b.ip,
		 b.betfrom,
		 0 matchid,	
		 CONVERT(BIT,0) as IsNeutral,
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
		 b.BetCheck			 	 
	from	bettrans as b with (nolock)   
	where	matchid = 9
			and bettype = 9  
			and b.transid = @TransID
	 
	--Combination Mix Parlay
	IF @bettype = 29
	INSERT INTO @Data
	select 
		 b.username,
		 29 bettype,   
		 CASE WHEN ISNULL(b.betid,0) = 0 THEN b.transid ELSE b.betID END as transid,   
		 isnull(b.BetID,0) as BetID,
		 b.refno,
		 '' matchcode,  
		 '' as race,
		 '' as eventdate,
		 0 as virtualrate,
		 0 as isShowOTExRate,
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
		 0, 0,  
		 0 as leagueid,  
		 0 as sporttype, 
		 b.ip,
		 b.betfrom,
		 0 matchid,	
		 CONVERT(BIT,0) as IsNeutral,
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
		 b.BetCheck
	FROM bettrans b WITH(NOLOCK)
	WHERE	matchid = 29
			and bettype = 29  
			and b.transid = @TransID		

	--- P2P
	IF @bettype = 1000
	INSERT INTO @Data
	select 
		 b.username,
		 bettype,   
		 b.transid,   
		 isnull(b.BetID,0) as BetID,
		 b.refno,
		 '' matchcode,   
		 '' as race,
		 '' as eventdate, 
		 0 as virtualrate,
		 0 as isShowOTExRate,
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
		 0, 0,  
		 0 as leagueid,  
		 253 as sporttype, 
		 b.ip,
		 b.betfrom,
		 b.matchid,
		 CONVERT(BIT,0) as IsNeutral,
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
		 b.BetCheck				 
	from	bettrans b with (nolock)   
	where	matchid = 1000
			AND bettype = 1000
			AND b.transid = @TransID
			
	--Outright
	IF @bettype = 10
	INSERT INTO @Data
	select 
		b.username,
		b.bettype,
		b.transid,
		isnull(b.BetID,0) as BetID,   
		b.refno,
		odds.matchcode, 
		odds.groupmatch as race,
		odds.eventdate as eventdate,
	    0 as virtualrate,
		0 as isShowOTExRate,
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
		0, 0,  
		odds.leagueid,
		l.sporttype,
		b.ip ,
		b.betfrom,
		b.matchid,
		CONVERT(BIT,0) as IsNeutral,
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
		b.BetCheck			
	from	bettrans as b with (nolock)   
			inner join outright as odds with (nolock) on b.matchid=odds.orid   
			inner join league l with (nolock) on odds.leagueid=l.leagueid     
	where b.bettype = 10
		  and b.transid = @TransID
			
	--HR
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 2 AND Bettype = @Bettype)
	INSERT INTO @Data
	select 
		b.username,
		b.bettype,
		b.transid,   
		isnull(b.BetID,0) as BetID,
		b.refno,
		odds.matchcode, 
		odds.groupmatch as race,
		odds.eventdate as eventdate,
		b.virtualrate,
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
		0, 0,  
		odds.leagueid,
		l.sporttype,
		b.ip ,
		b.betfrom,
		b.matchid,
		CONVERT(BIT,0) as IsNeutral,
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
		b.BetCheck				
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
	where	s.ProductID = 2 --b.bettype in (31,32,33,41,42,43)
			and b.transid = @TransID
	order by b.transid  
	
	-- Virtual HR
	IF @bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
	INSERT INTO @Data
	select 
		b.username,
		b.bettype,
		b.transid,
		'' as BetID,
		b.refno,
		o.RacerNum matchcode, --Horse Number
		b.oddsid as Race, --Outright ID
		'' eventdate,
		0 as virtualrate,
		0 as isShowOTExRate,
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
		b.actual_stake,
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
		(b.winlost-b.actual_stake)  winlost,
		b.playercomm as commission,
		(b.scomm - b.acomm) as scomm,
		(b.acomm - b.comm) as acomm,
		(b.comm - b.playercomm) as comm,
		b.awinlost,
		b.mwinlost,
		b.swinlost,
		r.EventTime showtime, -- Race Name			
		b.winlostdate,
		b.BetCheck
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
	where	s.ProductID = 5 AND
			s.EventType = 3 AND 
			--b.bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) and 
			b.transid = @TransID
	
	IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 12 AND Bettype = @Bettype)
	BEGIN
		INSERT INTO @Data  
		select
			b.username, 
			b.bettype,     
			b.transid,   
			isnull(b.BetID,0) as BetID,    
			b.refno,  
			'' as matchcode,     
			'' as race,  
			'' as eventdate,   
			0 as virtualrate,  
			0 as isShowOTExRate,  
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
			0, 
			0,    
			0 as leagueid,    
			255 as sporttype,   
			b.ip,  
			b.betfrom,  
			b.matchid,
			CONVERT(BIT,0) as IsNeutral,  
			(b.winlost-b.actual_stake)  winlost,  
			b.playercomm as commission,  
			(b.scomm - b.acomm) as scomm,  
			(b.acomm - b.comm) as acomm,  
			(b.comm - b.playercomm) as comm,  
			b.awinlost,  
			b.mwinlost,  
			b.swinlost,  
			'' as showtime,
			b.winlostdate ,
			b.BetCheck        
		from dbo.bettrans b with (nolock)     
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		where     
			s.ProductID = 12
			AND b.refno = @refno
		UNION ALL	-- translog
		select 
			cu.username,
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
			b.GameID3rd betteam,   
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
			b.GameID3rd as BetCheck  	 
		from dbo.translog b with (nolock)
			LEFT JOIN dbo.CustInfo cu with (nolock) ON b.CustID = cu.CustID
		INNER JOIN @SportBettype s ON s.Bettype = b.gameID
		where	s.ProductID = 12
			AND b.statusID = 0
			AND b.translogid = @refno
	END		
END

--Bettrans14
ELSE IF @WinlostDate <= @MoveBetsDay and @WinlostDate >= @BalanceUpDay
BEGIN
	--Sportbooks
	IF @bettype < 19001 and @bettype NOT IN (31,32,33,10/*, 1231,1232,1233,1237,1238*/) and @bettype NOT IN(SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
	INSERT INTO @Data
	select 
		b.username,
		b.bettype,
		b.transid,
		isnull(b.BetID,0) as BetID,
		b.refno,
		m.matchcode,
		'' as race,
		m.eventdate as eventdate,
		0 as virtualrate,
		0 as isShowOTExRate,
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
		b.BetCheck				
	from 
		bettrans14 as b with (nolock) 
		INNER JOIN match14 as m with (nolock) on b.matchid = m.matchid
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where	s.EventType = 1 
			--b.bettype < 19001 and b.bettype NOT IN (31,32,33,10/*, 1231,1232,1233,1237,1238*/) and 
			--b.bettype NOT IN(SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) and
			AND b.transid = @TransID
			
	--Mix Parlay
	IF @bettype = 9
	INSERT INTO @Data
	select 
		 b.username,
		 9 bettype,   
		 b.transid,   
		 isnull(b.BetID,0) as BetID,
		 b.refno,
		 '' matchcode,  
		 '' as race,
		 '' as eventdate,
		 0 as virtualrate,
		 0 as isShowOTExRate,
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
		 0, 0,  
		 0 as leagueid,  
		 0 as sporttype, 
		 b.ip,
		 b.betfrom,
		 0 matchid,	
		 CONVERT(BIT,0) as IsNeutral,
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
		 b.BetCheck				 
	from	bettrans14 as b with (nolock)   
	where	matchid = 9
			and bettype = 9  
			and b.transid = @TransID
	 
	--Combination Mix Parlay
	IF @bettype = 29
	INSERT INTO @Data
	select 
		 b.username,
		 29 bettype,   
		 CASE WHEN ISNULL(b.betid,0) = 0 THEN b.transid ELSE b.betID END as transid,
		 isnull(b.BetID,0) as BetID,
		 b.refno,
		 '' matchcode,  
		 '' as race,
		 '' as eventdate,
		 0 as virtualrate,
		 0 as isShowOTExRate,
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
		 0, 0,  
		 0 as leagueid,  
		 0 as sporttype, 
		 b.ip,
		 b.betfrom,
		 0 matchid,	
		 CONVERT(BIT,0) as IsNeutral,
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
		 b.BetCheck
	FROM bettrans14 b WITH(NOLOCK)
	WHERE  
			matchid = 29
			and bettype = 29  
			and b.transid = @TransID				

	--- P2P
	IF @bettype = 1000
	INSERT INTO @Data
	select 
		 b.username,
		 bettype,   
		 b.transid,   
		 isnull(b.BetID,0) as BetID,
		 b.refno,
		 '' matchcode,   
		 '' as race,
		 '' as eventdate, 
		 0 as virtualrate,
		 0 as isShowOTExRate,
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
		 0, 0,  
		 0 as leagueid,  
		 253 as sporttype, 
		 b.ip,
		 b.betfrom,
		 b.matchid,
		 CONVERT(BIT,0) as IsNeutral,
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
		 b.BetCheck				 
	from	bettrans14 b with (nolock)   
	where	matchid = 1000
			AND bettype = 1000
			AND b.transid = @TransID

	--Outright
	IF @bettype = 10
	INSERT INTO @Data
	select 
		b.username,
		b.bettype,
		b.transid,
		isnull(b.BetID,0) as BetID,    
		b.refno,
		odds.matchcode, 
		odds.groupmatch as race,
		odds.eventdate as eventdate,
		0 as virtualrate,
		0 as isShowOTExRate,
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
		0, 0,  
		odds.leagueid,
		l.sporttype,
		b.ip ,
		b.betfrom,
		b.matchid,
		CONVERT(BIT,0) as IsNeutral,
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
		b.BetCheck				
	from	bettrans14 as b with (nolock)   
			inner join outright14 as odds with (nolock) on b.matchid=odds.orid   
			inner join league l with (nolock) on odds.leagueid=l.leagueid     
	where b.bettype = 10		  
		  and b.transid = @TransID			
			
	--HR
	IF @bettype in (31,32,33,41,42,43)
	INSERT INTO @Data
	select 
		b.username,
		b.bettype,
		b.transid,   
		isnull(b.BetID,0) as BetID,
		b.refno,
		odds.matchcode, 
		odds.groupmatch as race,
		odds.eventdate as eventdate,
		b.virtualrate,
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
		0, 0,  
		odds.leagueid,
		l.sporttype,
		b.ip ,
		b.betfrom,
		b.matchid,
		CONVERT(BIT,0) as IsNeutral,
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
		b.BetCheck				
	from	bettrans14 as b with (nolock)   
			inner join outright14 as odds with (nolock) on b.matchid=odds.orid   
			inner join league l with (nolock) on odds.leagueid=l.leagueid    
			INNER JOIN @SportBettype s ON s.BetType = b.BetType 
			left join (			
				SELECT	t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking, t.finalodds,
						f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2, f.finalodds finalodds2
				FROM	bettransm14 t WITH (NOLOCK)
						INNER JOIN bettransm14 f WITH (NOLOCK) ON t.refno = f.refno 
				WHERE	t.bettype in (31,41) AND f.bettype in (32,42)
			) bm on b.transid = bm.refno 
	where	s.ProductID = 2 --b.bettype in (31,32,33,41,42,43)			
			and b.transid = @TransID
	order by b.transid  
	
	-- Virtual HR
	IF @bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
	INSERT INTO @Data
	select 
		b.username,
		b.bettype,
		b.transid,
		'' as BetID,
		b.refno,
		o.RacerNum matchcode, --Horse Number
		b.oddsid as Race, --Outright ID
		'' eventdate,
		0 as virtualrate,
		0 as isShowOTExRate,
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
		b.actual_stake,
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
		(b.winlost-b.actual_stake)  winlost,
		b.playercomm as commission,
		(b.scomm - b.acomm) as scomm,
		(b.acomm - b.comm) as acomm,
		(b.comm - b.playercomm) as comm,
		b.awinlost,
		b.mwinlost,
		b.swinlost,
		r.EventTime showtime, -- Race Name			
		b.winlostdate,
		b.BetCheck
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
	where	s.ProductID=5 AND
			s.EventType=3 AND 
			--b.bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) and 
			b.transid = @TransID
			
	IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 12 AND Bettype = @Bettype)
	BEGIN
		INSERT INTO @Data  
		select
			b.username, 
			b.bettype,     
			b.transid,   
			isnull(b.BetID,0) as BetID,    
			b.refno,  
			'' as matchcode,     
			'' as race,  
			'' as eventdate,   
			0 as virtualrate,  
			0 as isShowOTExRate,  
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
			0, 
			0,    
			0 as leagueid,    
			255 as sporttype,   
			b.ip,  
			b.betfrom,  
			b.matchid,
			CONVERT(BIT,0) as IsNeutral,  
			(b.winlost-b.actual_stake)  winlost,  
			b.playercomm as commission,  
			(b.scomm - b.acomm) as scomm,  
			(b.acomm - b.comm) as acomm,  
			(b.comm - b.playercomm) as comm,  
			b.awinlost,  
			b.mwinlost,  
			b.swinlost,  
			'' as showtime,
			b.winlostdate ,
			b.BetCheck        
		from dbo.bettrans14 b with (nolock)     
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		where     
			s.ProductID = 12
			AND b.refno = @refno
	END
END

--bettrans_bk
ELSE IF @WinlostDate < @BalanceUpDay
BEGIN
	--Sportbooks
	IF @bettype < 19001 and @bettype NOT IN (31,32,33,10/*, 1231,1232,1233,1237,1238*/) and @bettype NOT IN (SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
	INSERT INTO @Data
	select 
		c.username,
		b.bettype,
		b.transid,
		isnull(b.BetID,0) as BetID,
		b.refno,
		m.matchcode,
		'' as race,
		m.eventdate as eventdate,
		0 as virtualrate,
		0 as isShowOTExRate,
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
		b.BetCheck				
	from 
		DBARC.bodb_archive.dbo.bettrans_bk b with (nolock) 
		inner join DBARC.bodb_archive.dbo.match_BK m with (nolock) on b.matchid = m.matchid
		inner JOIN custInfo c with (NOLOCK) on c.custid = b.custid
		INNER JOIN @SportBettype s ON s.BetType = b.BetType 
	where	s.EventType = 1 AND 
			--b.bettype < 19001 and b.bettype NOT IN (31,32,33,10/*, 1231,1232,1233,1237,1238*/) and 
			--b.bettype NOT IN(SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) and
			b.transid = @TransID
			
	--Mix Parlay
	IF @bettype = 9
	INSERT INTO @Data
	select 
		 c.username,
		 9 bettype,   
		 b.transid,   
		 isnull(b.BetID,0) as BetID,
		 b.refno,
		 '' matchcode,  
		 '' as race,
		 '' as eventdate,
		 0 as virtualrate,
		 0 as isShowOTExRate,
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
		 0, 0,  
		 0 as leagueid,  
		 0 as sporttype, 
		 b.ip,
		 b.betfrom,
		 0 matchid,	
		 CONVERT(BIT,0) as IsNeutral,
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
		 b.BetCheck				 
	from	DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)  
			inner JOIN custInfo c with (NOLOCK) ON c.custid = b.custid
	where	 			
			matchid = 9
			and bettype = 9  
			and b.transid = @TransID
	 
	--Combination Mix Parlay
	IF @bettype = 29
	INSERT INTO @Data
	select 
		 c.username,
		 29 bettype,   
		 CASE WHEN ISNULL(b.betid,0) = 0 THEN b.transid ELSE b.betID END AS transid,   			 
		 isnull(b.BetID,0) as BetID,
		 b.refno,
		 '' matchcode,  
		 '' as race,
		 '' as eventdate,
		 0 as virtualrate,
		 0 as isShowOTExRate,
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
		 0, 0,  
		 0 as leagueid,  
		 0 as sporttype, 
		 b.ip,
		 b.betfrom,
		 0 matchid,	
		 CONVERT(BIT,0) as IsNeutral,
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
		 b.BetCheck
	FROM DBARC.bodb_archive.dbo.bettrans_bk b WITH(NOLOCK)
		inner JOIN custInfo c WITH (NOLOCK) ON c.custid = b.custid
	WHERE 
			matchid = 29
			and bettype = 29  
			and b.transid = @TransID
	
	--- P2P
	IF @bettype = 1000
	INSERT INTO @Data
	select 
		 c.username,
		 bettype,   
		 b.transid,   
		 isnull(b.BetID,0) as BetID,
		 b.refno,
		 '' matchcode,   
		 '' as race,
		 '' as eventdate, 
		 0 as virtualrate,
		 0 as isShowOTExRate,
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
		 0, 0,  
		 0 as leagueid,  
		 253 as sporttype, 
		 b.ip,
		 b.betfrom,
		 b.matchid,
		 CONVERT(BIT,0) as IsNeutral,
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
		 b.BetCheck				 
	from	DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)   
			inner JOIN custInfo c with (NOLOCK) ON c.custid = b.custid
	where	  		
			matchid = 1000
			AND bettype = 1000
			AND b.transid = @TransID			
	
	--Outright
	IF @bettype = 10
	INSERT INTO @Data
	select 
		c.username,
		b.bettype,
		b.transid,   
		isnull(b.BetID,0) as BetID,
		b.refno,
		odds.matchcode, 
		odds.groupmatch as race,
		odds.eventdate as eventdate,
		0 as virtualrate,
		0 as isShowOTExRate,
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
		0, 0,  
		odds.leagueid,
		l.sporttype,
		b.ip ,
		b.betfrom,
		b.matchid,
		CONVERT(BIT,0) as IsNeutral,
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
		b.BetCheck				
	from	DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)   
			inner join DBARC.bodb_archive.dbo.Outright_bk as odds with (nolock) on b.matchid=odds.orid   
			inner join league l with (nolock) on odds.leagueid=l.leagueid   
			inner JOIN custInfo c with (NOLOCK) ON c.custid = b.custid
	where b.bettype = 10
		  and b.transid = @TransID
			
	--HR
	IF @bettype in (31,32,33,41,42,43)
	INSERT INTO @Data
	select 		 
		c.username,
		b.bettype,
		b.transid,   
		isnull(b.BetID,0) as BetID,
		b.refno,
		odds.matchcode, 
		odds.groupmatch as race,
		odds.eventdate as eventdate,
		b.virtualrate,
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
		0, 0,  
		odds.leagueid,
		l.sporttype,
		b.ip ,
		b.betfrom,
		b.matchid,
		CONVERT(BIT,0) as IsNeutral,
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
		b.BetCheck				
	from	DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock) 
			inner join DBARC.bodb_archive.dbo.Outright_bk as odds with (nolock) on b.matchid=odds.orid   
			inner join league l with (nolock) on odds.leagueid=l.leagueid    
			inner JOIN custInfo c with (NOLOCK) ON c.custid = b.custid
			INNER JOIN @SportBettype s ON s.BetType = b.BetType 
			left join (			
				SELECT	t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking, t.finalodds,
						f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2, f.finalodds finalodds2
				FROM	DBARC.bodb_archive.dbo.bettransm t WITH (NOLOCK)
						INNER JOIN DBARC.bodb_archive.dbo.bettransm f WITH (NOLOCK) ON t.refno = f.refno 
				WHERE	t.bettype in (31,41) AND f.bettype in (32,42)
			) bm on b.transid = bm.refno 
	where	s.ProductID=2 --b.bettype in (31,32,33,41,42,43)			
			and b.transid = @TransID
	order by b.transid 
	
	-- Virtual HR
	IF @bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
	INSERT INTO @Data
	select 
		c.username,
		b.bettype,
		b.transid,
		'' as BetID,
		b.refno,
		o.RacerNum matchcode, --Horse Number
		b.oddsid as Race, --Outright ID
		'' eventdate,
		0 as virtualrate,
		0 as isShowOTExRate,
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
		b.actual_stake,
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
		(b.winlost-b.actual_stake)  winlost,
		b.playercomm as commission,
		(b.scomm - b.acomm) as scomm,
		(b.acomm - b.comm) as acomm,
		(b.comm - b.playercomm) as comm,
		b.awinlost,
		b.mwinlost,
		b.swinlost,
		r.EventTime showtime, -- Race Name			
		b.winlostdate,
		b.BetCheck
	from 
		DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock) 
		INNER JOIN DBARC.bodb_archive.dbo.VSOutright_bk o WITH (NOLOCK) ON b.oddsid = o.Orid
        INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
        inner JOIN custInfo c with (NOLOCK) ON c.custid = b.custid
		INNER JOIN @SportBettype s ON s.BetType = b.BetType 
        left join (     
			SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking,
			  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2
			FROM DBARC.bodb_archive.dbo.bettransm t WITH (NOLOCK)  
			  INNER JOIN DBARC.bodb_archive.dbo.bettransm f WITH (NOLOCK) ON t.refno = f.refno   
			WHERE t.bettype = 1231 AND f.bettype = 1232 
			) bm on b.refno = bm.refno  
	where	s.ProductID = 5 AND
			s.EventType = 3 AND 
			b.bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) and 
			b.transid = @TransID

IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 12 AND Bettype = @Bettype)
	BEGIN
		INSERT INTO @Data  
		select
			cu.username, 
			b.bettype,     
			b.transid,   
			isnull(b.BetID,0) as BetID,    
			b.refno,  
			'' as matchcode,     
			'' as race,  
			'' as eventdate,   
			0 as virtualrate,  
			0 as isShowOTExRate,  
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
			0, 
			0,    
			0 as leagueid,    
			255 as sporttype,   
			b.ip,  
			b.betfrom,  
			b.matchid,
			CONVERT(BIT,0) as IsNeutral,  
			(b.winlost-b.actual_stake)  winlost,  
			b.playercomm as commission,  
			(b.scomm - b.acomm) as scomm,  
			(b.acomm - b.comm) as acomm,  
			(b.comm - b.playercomm) as comm,  
			b.awinlost,  
			b.mwinlost,  
			b.swinlost,  
			'' as showtime,
			b.winlostdate ,
			b.BetCheck        
		from DBARC.bodb_archive.dbo.bettrans_bk b with (nolock)     
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		INNER JOIN dbo.custInfo cu with (NOLOCK) ON cu.custid = b.custid
		where     
			s.ProductID = 12
			AND b.refno = @refno
	END

END

SELECT * FROM @Data
ORDER BY transid  

IF EXISTS (SELECT TOP 1 1 
		FROM @SportBettype sp 
			INNER JOIN @Data d
				ON d.bettype = sp.bettype 
		WHERE ProductID in (4,12) AND sp.bettype = @bettype )
BEGIN
	IF @WinlostDate > @MoveBetsDay
		INSERT INTO @DetailData
		SELECT 
			CASE WHEN sp.Productid in (4) THEN BG.refno
						ELSE B2.refno END refno,
			BG.odds, 
			BG.stake,
			BG.status,
			BG.apositiontaking, 
			BG.mpositiontaking, 
			BG.spositiontaking,
			BG.bettype,
			BG.betteam  
		FROM bettransg BG with (NOLOCK)
				INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (4,12)
				LEFT JOIN @Data B1 ON (BG.refno = B1.refno AND BG.bettype = B1.bettype AND sp.Productid in (4))
				LEFT JOIN @Data B2 ON (BG.refno = B2.transid AND BG.bettype = B2.bettype AND sp.Productid in (12))
		WHERE B1.bettype IS NOT NULL OR B2.bettype IS NOT NULL
	
	ELSE IF @WinlostDate <= @MoveBetsDay and @WinlostDate >= @BalanceUpDay	   
		INSERT INTO @DetailData
		SELECT 
			CASE WHEN sp.Productid in (4) THEN BG.refno
						ELSE B2.refno END refno,
			BG.odds, 
			BG.stake,
			BG.status,
			BG.apositiontaking, 
			BG.mpositiontaking, 
			BG.spositiontaking,
			BG.bettype,
			BG.betteam  
		FROM bettransg14 BG with (NOLOCK)
				INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (4,12)
				LEFT JOIN @Data B1 ON (BG.refno = B1.refno AND BG.bettype = B1.bettype AND sp.Productid in (4))
				LEFT JOIN @Data B2 ON (BG.refno = B2.transid AND BG.bettype = B2.bettype AND sp.Productid in (12))
		WHERE B1.bettype IS NOT NULL OR B2.bettype IS NOT NULL
	ELSE	
		INSERT INTO @DetailData
		SELECT 
			CASE WHEN sp.Productid in (4) THEN BG.refno
						ELSE B2.refno END refno,
			BG.odds, 
			BG.stake,
			BG.status,
			BG.apositiontaking, 
			BG.mpositiontaking, 
			BG.spositiontaking,
			BG.bettype,
			BG.betteam  
		FROM DBARC.bodb_archive.dbo.bettransg BG with (NOLOCK)
					INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (4,12)
				LEFT JOIN @Data B1 ON (BG.refno = B1.refno AND BG.bettype = B1.bettype AND sp.Productid in (4))
				LEFT JOIN @Data B2 ON (BG.refno = B2.transid AND BG.bettype = B2.bettype AND sp.Productid in (12))
		WHERE B1.bettype IS NOT NULL OR B2.bettype IS NOT NULL	 
END
		   
SELECT * FROM @DetailData

GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetList_ByTransID_Advance] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetList_ByTransID_Advance] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetsSelBetList_ByTransID_Advance] TO [vnteam]