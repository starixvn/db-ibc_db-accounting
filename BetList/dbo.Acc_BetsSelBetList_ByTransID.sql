ALTER PROCEDURE [dbo].[Acc_BetsSelBetList_ByTransID]    
	@CustID int,  
	@TransID bigint  
AS    
	/*  
	Created by: Henry  
	Date: 2008  
	Task: Bet List By TransID  
	DB: DBAGE/bodb02   
	Original:  Acc_BetsSelBetList   

	Revisions:  
	- 20091229@[Henry]: newly created  
	- 20100409@Daniel:   
	+ Support Mini game   
			+ Fix search Casino & Mini game by bettrans.refno instead  
	 - 20100501@Daniel: Remove support Mini game, add agent W/L amount, agent's commission amount columns  
	- 20100524@Jamie: Show currency2's exchange rate for OpenTote   
	-- 20100525@Henry: Change to use StatusID instead of Status in WHERE statement  
	- 20100611@Henry: Change mix-parlay match from 0 to 9  
	- 20100907@Henry: Add IBC Bingo bettype  
	- 20101130@Henry: Add column betid for number game  
	- 20101201@Henry: Return winlost-actual_stake for column winlost  
	- 20110408@Amy: Change function to get Odds value and odds type  
	- 20110516@Lukas: re-arrange bettype  
	- 20110711@Johnson: show exchange rate for SA Tote(Pool Currency)  
	- 20110802@Johnson: - Add column actual_stake into betlist  
	   - Add new bettype combination mix parlay  
	- 20111122@Sophia: Add Checktime and SecAcceptFlag to show status waiting or running  
	- 20111207@Sophia: Add P2P  
	- 20120120@Sophia: Add Showtime for Table-hand-shoe of Live Casino  
	   Add sub detail for Live Casino  
	- 20120217@Daniel: Allow to delete mix palay bet (whole ticket)  
	- 20120405@Hurri: Exclude bettype 72 (P2P bet ticket) in the calculation of Casino  
	- 20120410@Hurri: change matchid 0 -> 1000 for bettype 1000  
	- 20120417@Johnson: Correct column transid for p2p    
	- 20120424@Lukas: show transid of main-ticket for sub-tickets of system parlay   
	- 20120507@Jamie: Fix p2p to get transID   
	- 20120606@Sophia: Change datatype of stake to money   
	- 20120626@Lukas: exclude outright from sportbook ( in case of matchid = orid)  
	- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype,f_GetChoice for odds, Oddstype, betteam  
	- 20120927@Johnson: get commstatus column to check double comm losing  
	- 20130121@Dan: change linked server DB06 to DBARC   
	- 20130227@Elodie: Add Virtual HR product  
	- 20130705@Kathy: Update matchid for RnG Casino (71) and Bingo (73)
	*/   

SET NOCOUNT ON    
--list of bettype not allowed to delete  
DECLARE @tableBettypeNotAllowDelete  TABLE(typeid int not null)  
INSERT INTO @tableBettypeNotAllowDelete (typeid)   
SELECT 31 UNION SELECT 32 UNION SELECT 33 UNION SELECT 41 UNION SELECT 42 UNION SELECT 43 UNION   
SELECT 51 UNION SELECT 52 UNION SELECT 53 UNION SELECT 54 UNION SELECT 55 UNION SELECT 56 UNION  
SELECT 61 UNION SELECT 62 UNION SELECT 63 UNION SELECT 64 UNION SELECT 65 UNION SELECT 66  

--End  

DECLARE @refno BIGINT  
Declare @Data TABLE (  
	bettype   int,  
	transid   bigint,   
	betid   bigint,  
	refno   nvarchar(50),   
	matchcode  nvarchar(50),  
	race   nvarchar(20),  
	eventdate  smalldatetime,  
	virtualrate  float,  
	isShowOTExRate bit,  
	sdiscount  smallmoney,  
	adiscount  smallmoney,  
	discount  smallmoney,  
	homeid   int,   
	awayid   int,   
	settleTime  datetime,  
	hdp1   smallmoney,   
	hdp2   smallmoney,   
	odds   smallmoney,  
	finalodds  smallmoney,  
	finalodds2  smallmoney,  
	OddsType  tinyint,  
	status   nvarchar(50),   
	comstatus  nvarchar(50),  
	stake   money,  
	actual_stake money,  
	transdate  datetime,  
	betteam   nvarchar(10),  
	spositiontaking smallmoney,  
	mpositiontaking smallmoney,  
	apositiontaking smallmoney,  
	spositiontaking2 smallmoney,  
	mpositiontaking2 smallmoney,  
	apositiontaking2 smallmoney,  
	liveindicator  bit,  
	modds   smallmoney,  
	custid   int,  
	livehomescore int,   
	liveawayscore int,   
	finalhomescore int,   
	finalawayscore int,   
	leagueid  int,   
	sporttype  smallint,   
	ip    nvarchar(15),   
	betfrom   nvarchar (1),  
	matchid   int,  
	isNeutral  bit,  
	allowdelete  bit,  
	winlost   money,  
	commission  money,  
	scomm   money,   
	acomm   money,  
	comm   money,  
	awinlost  money,  
	mwinlost  money,  
	swinlost  money,  
	showtime  nvarchar(50)  )  

DECLARE @DetailData TABLE (  
		refno   nvarchar(50),   
		odds   smallmoney,   
		stake   money,  
		status   nvarchar(50),  
		apositiontaking smallmoney,   
		mpositiontaking smallmoney,   
		spositiontaking smallmoney,  
		bettype   smallint,  
		betteam   nvarchar(50)  
		)  


--Bettrans  

IF exists(  
select 1 from bettrans with (nolock)   
where transid = @TransID OR (refno = @transid AND bettype IN (71, 73, 1000) and matchid IN (0, 71, 73, 1000)) --20120405@Hurri  
AND custid = @Custid  
)  
BEGIN  
--Sportbooks  
INSERT INTO @Data  
	select   
	b.bettype,  
	b.transid,  
	isnull(b.BetID,0) as BetID,  
	b.refno,  
	m.matchcode,  
	'' as race,  
	'' as eventdate,  
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
	--CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or status NOT IN('running', 'waiting', 'WON', 'LOSE', 'DRAW') THEN 0 ELSE 1 END as allowdelete,  
	CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or statusID NOT IN(0, 1, 112, 113, 111) THEN 0 ELSE 1 END as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	m.showtime   
from   
	bettrans as b with (nolock)   
	inner join match as m with (nolock) on b.matchid = m.matchid --phuong.nguyen, remove left join match_remark  
where    
	b.custid = @Custid and  
	b.bettype < 19001 and b.bettype NOT IN (31,32,33,10, 1231,1232,1233,1237,1238) and   
	b.transid = @TransID  
 
--Mix Parlay  
INSERT INTO @Data  
	select   
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
	CASE WHEN statusID = 0 THEN 1 ELSE 0 END as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	'' as showtime        
from bettrans as b with (nolock)     
where    
	b.custid = @Custid    
	--and matchid=0    
	and matchid = 9  
	and bettype = 9    
	and b.transid = @TransID  

--Combination Mix Parlay  
SELECT @refno = refno  
FROM bettrans b WITH(NOLOCK)  
WHERE b.custid = @Custid    
	--and matchid=0    
	and matchid = 29  
	and bettype = 29    
	and b.transid = @TransID  
  
--- Casino  
INSERT INTO @Data  
select   
	bettype,     
	b.betid transid,     
	isnull(b.BetID,0) as BetID,  
	b.refno,  
	CONVERT(varchar(50), b.refno) matchcode,     
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
	'' as showtime      
from bettrans b with (nolock)     
where     
	b.custid = @Custid    
	AND matchid in (0, 71)  
	AND bettype = 71        --20120405@Hurri  
	AND b.refno = @TransID  

--IBC Bingo  
INSERT INTO @Data  
select   
	bettype,     
	b.betid transid,   
	isnull(b.BetID,0) as BetID,    
	b.refno,  
	CONVERT(varchar(50), b.refno) as matchcode,     
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
	'' as showtime       
from bettrans b with (nolock)     
where     
	b.custid = @Custid    
	AND matchid in (0, 73) 
	AND bettype = 73  
	AND b.refno = @TransID  

--- P2P  
INSERT INTO @Data  
select   
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
	0 as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	'' as showtime       
from bettrans b with (nolock)     
where     
	b.custid = @Custid    
	AND matchid = 1000  
	AND bettype = 1000  
	AND b.transid = @TransID  
 
--Outright  
INSERT INTO @Data  
select   
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
	--CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or b.status NOT IN('running', 'waiting', 'WON', 'LOSE', 'DRAW') THEN 0 ELSE 1 END as allowdelete,  
	CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or b.statusID NOT IN(0, 1, 112, 113, 111) THEN 0 ELSE 1 END as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	'' as showtime     
from bettrans as b with (nolock)     
	inner join outright as odds with (nolock) on b.matchid=odds.orid     
	inner join league l with (nolock) on odds.leagueid=l.leagueid       
where b.bettype = 10  
	and b.custid = @Custid      
	and b.transid = @TransID  
 
--HR  
INSERT INTO @Data  
select   
	b.bettype,  
	b.transid,     
	isnull(b.BetID,0) as BetID,  
	b.refno,  
	odds.matchcode,   
	odds.groupmatch as race,  
	odds.eventdate as eventdate,  
	b.virtualrate,  
	--isnumeric(odds.programID) as isShowOTExRate,  
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
	--CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or b.status NOT IN('running', 'waiting', 'WON', 'LOSE', 'DRAW') THEN 0 ELSE 1 END as allowdelete,  
	CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or b.statusID NOT IN(0, 1, 112, 113, 111) THEN 0 ELSE 1 END as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	'' as showtime      
from bettrans as b with (nolock)     
	inner join outright as odds with (nolock) on b.matchid=odds.orid     
	inner join league l with (nolock) on odds.leagueid=l.leagueid      
	left join (     
		SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking, t.finalodds,  
		  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2, f.finalodds finalodds2  
		FROM bettransm t WITH (NOLOCK)  
		  INNER JOIN bettransm f WITH (NOLOCK) ON t.refno = f.refno   
		WHERE t.bettype in (31,41) AND f.bettype in (32,42)  
		) bm on b.transid = bm.refno   
where b.bettype in (31,32,33,41,42,43)  
	and b.custid = @Custid        
	and b.transid = @TransID  
order by b.transid    

-- Virtual HR  
INSERT INTO @Data  
select   
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
	CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or statusID NOT IN(0, 1, 112, 113, 111) THEN 0 ELSE 1 END as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	r.EventTime showtime -- Race Name  
from   
	bettrans as b with (nolock)   
	INNER JOIN VSOutright o WITH (NOLOCK) ON b.oddsid = o.Orid  
	INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID  
	left join (     
		SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking,
		  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2
		FROM bettransm t WITH (NOLOCK)  
		  INNER JOIN bettransm f WITH (NOLOCK) ON t.refno = f.refno   
		WHERE t.bettype = 1231 AND f.bettype = 1232 
		) bm on b.refno = bm.refno   
where    
	b.custid = @Custid and  
	b.bettype in (1231, 1232, 1233, 1237, 1238) and   
	b.transid = @TransID  
END  

--Bettrans14  
ELSE IF exists(  
select 1 from bettrans14 with (nolock)   
where transid = @TransID OR (refno = @transid AND bettype IN (71,73, 1000) and matchid IN (0,71, 73, 1000)) --20120405@Hurri  
AND custid = @Custid  
)  
BEGIN  
--Sportbooks  
INSERT INTO @Data  
select   
	b.bettype,  
	b.transid,  
	isnull(b.BetID,0) as BetID,  
	b.refno,  
	m.matchcode,  
	'' as race,  
	'' as eventdate,  
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
	0 as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	m.showtime      
from   
	bettrans14 as b with (nolock)   
	inner join match14 as m with (nolock) on b.matchid = m.matchid  
where    
	b.custid = @Custid and  
	b.bettype < 19001 and b.bettype NOT IN (31,32,33,10, 1231,1232,1233,1237,1238) and   
	b.transid = @TransID  
 
--Mix Parlay  
INSERT INTO @Data  
select   
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
	CASE WHEN statusID = 0 THEN 1 ELSE 0 END as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	'' as showtime       
from bettrans14 as b with (nolock)     
where    
	b.custid = @Custid    
	--and matchid=0    
	and matchid = 9  
	and bettype = 9    
	and b.transid = @TransID  

--Combination Mix Parlay  
SELECT @refno = refno  
FROM bettrans14 b WITH(NOLOCK)  
WHERE b.custid = @Custid    
	--and matchid=0    
	and matchid = 29  
	and bettype = 29    
	and b.transid = @TransID   
 
--- Casino  
INSERT INTO @Data  
select   
	bettype,     
	b.betid transid,     
	isnull(b.BetID,0) as BetID,  
	b.refno,  
	CONVERT(varchar(50), b.refno) matchcode,     
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
	'' as showtime       
from bettrans14 b with (nolock)     
where     
	b.custid = @Custid   
	AND matchid in (0, 71) 
	AND bettype = 71        --20120405@Hurri  
	AND b.refno = @TransID  

--IBC Bingo  
INSERT INTO @Data  
select   
	bettype,     
	b.betid transid,     
	isnull(b.BetID,0) as BetID,  
	b.refno,  
	CONVERT(varchar(50), b.refno) as matchcode,     
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
	'' as showtime       
from bettrans14 b with (nolock)     
where     
	b.custid = @Custid   
	AND matchid in (0, 73)  
	AND bettype = 73  
	AND b.refno = @TransID  

--- P2P  
INSERT INTO @Data  
select   
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
	0 as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	'' as showtime       
from bettrans14 b with (nolock)     
where     
	b.custid = @Custid   
	AND matchid = 1000  
	AND bettype = 1000  
	AND b.transid = @TransID  

--Outright  
INSERT INTO @Data  
select   
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
	0 as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	'' as showtime      
from bettrans14 as b with (nolock)     
	inner join outright14 as odds with (nolock) on b.matchid=odds.orid     
	inner join league l with (nolock) on odds.leagueid=l.leagueid       
where b.bettype = 10  
	and b.custid = @Custid      
	and b.transid = @TransID  
 
--HR  
INSERT INTO @Data  
select   
	b.bettype,  
	b.transid,     
	isnull(b.BetID,0) as BetID,  
	b.refno,  
	odds.matchcode,   
	odds.groupmatch as race,  
	odds.eventdate as eventdate,  
	b.virtualrate,  
	--isnumeric(odds.programID) as isShowOTExRate,  
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
	0 as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	'' as showtime      
from bettrans14 as b with (nolock)     
	inner join outright14 as odds with (nolock) on b.matchid=odds.orid     
	inner join league l with (nolock) on odds.leagueid=l.leagueid      
	left join (     
		SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking, t.finalodds,  
		  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2, f.finalodds finalodds2  
		FROM bettransm14 t WITH (NOLOCK)  
		  INNER JOIN bettransm14 f WITH (NOLOCK) ON t.refno = f.refno   
		WHERE t.bettype in (31,41) AND f.bettype in (32,42)  
		) bm on b.transid = bm.refno   
where b.bettype in (31,32,33,41,42,43)  
	and b.custid = @Custid        
	and b.transid = @TransID  
order by b.transid    

-- Virtual HR  
INSERT INTO @Data  
select   
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
	CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or statusID NOT IN(0, 1, 112, 113, 111) THEN 0 ELSE 1 END as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	r.EventTime showtime -- Race Name   
from   
	bettrans14 as b with (nolock)   
	INNER JOIN VSOutright14 o WITH (NOLOCK) ON b.oddsid = o.Orid  
	INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID  
	left join (     
		SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking,
		  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2
		FROM bettransm14 t WITH (NOLOCK)  
		  INNER JOIN bettransm14 f WITH (NOLOCK) ON t.refno = f.refno   
		WHERE t.bettype = 1231 AND f.bettype = 1232 
		) bm on b.refno = bm.refno  
where    
	b.custid = @Custid and  
	b.bettype in (1231, 1232, 1233, 1237, 1238) and   
	b.transid = @TransID  
 
END  
--bettrans_bk  
ELSE IF exists(  
select 1 from DBARC.bodb_archive.dbo.bettrans_bk with (nolock)   
where transid = @TransID OR (refno = @transid AND bettype IN (71,73,1000) and matchid IN (0, 71, 73, 1000)) --20120405@Hurri  
AND custid = @Custid  
)  
BEGIN  
--Sportbooks  
INSERT INTO @Data  
select   
	b.bettype,  
	b.transid,  
	isnull(b.BetID,0) as BetID,  
	b.refno,  
	m.matchcode,  
	'' as race,  
	'' as eventdate,  
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
	0 as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	m.showtime      
from   
	DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)   
	inner join DBARC.bodb_archive.dbo.match_BK as m with (nolock) on b.matchid = m.matchid  
where    
	b.custid = @Custid and  
	b.bettype < 19001 and b.bettype NOT IN (31,32,33,10, 1231, 1232, 1233, 1237, 1238) and   
	b.transid = @TransID  
 
--Mix Parlay  
INSERT INTO @Data  
select   
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
	0 as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	'' as showtime       
from DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)     
where    
	b.custid = @Custid    
	--and matchid=0    
	and matchid = 9  
	and bettype = 9    
	and b.transid = @TransID  

--Combination Mix Parlay  
SELECT @refno = refno  
FROM DBARC.bodb_archive.dbo.bettrans_bk b WITH(NOLOCK)  
WHERE b.custid = @Custid    
	--and matchid=0    
	and matchid = 29  
	and bettype = 29    
	and b.transid = @TransID  

--- Casino  
INSERT INTO @Data  
select   
	bettype,     
	b.betid transid,     
	isnull(b.BetID,0) as BetID,  
	b.refno,  
	CONVERT(varchar(50), b.refno) matchcode,     
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
	'' as showtime       
from DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)     
where     
	b.custid = @Custid    
	AND matchid in (0, 71)  
	AND bettype = 71        --20120405@Hurri  
	AND b.refno = @TransID  

--- IBC Bingo  
INSERT INTO @Data  
select   
	bettype,     
	b.betid transid,     
	isnull(b.BetID,0) as BetID,  
	b.refno,  
	CONVERT(varchar(50), b.refno) as matchcode,     
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
	'' as showtime      
from DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)     
where     
	b.custid = @Custid    
	AND matchid in (0, 73)  
	AND bettype = 73  
	AND b.refno = @TransID  

--- P2P  
INSERT INTO @Data  
select   
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
	0 as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	'' as showtime       
from DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)     
where     
	b.custid = @Custid    
	AND matchid = 1000  
	AND bettype = 1000  
	AND b.transid = @TransID  
 

--Outright  
INSERT INTO @Data  
select   
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
	0 as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	'' as showtime      
from DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)     
	inner join DBARC.bodb_archive.dbo.Outright_bk as odds with (nolock) on b.matchid=odds.orid     
	inner join league l with (nolock) on odds.leagueid=l.leagueid       
where b.bettype = 10  
	and b.custid = @Custid      
	and b.transid = @TransID     

--HR  
INSERT INTO @Data  
select   
	b.bettype,  
	b.transid,     
	isnull(b.BetID,0) as BetID,  
	b.refno,  
	odds.matchcode,   
	odds.groupmatch as race,  
	odds.eventdate as eventdate,  
	b.virtualrate,  
	--isnumeric(odds.programID) as isShowOTExRate,  
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
	0 as allowdelete,   
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	'' as showtime      
from DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)   
	inner join DBARC.bodb_archive.dbo.Outright_bk as odds with (nolock) on b.matchid=odds.orid     
	inner join league l with (nolock) on odds.leagueid=l.leagueid      
	left join (     
		SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking, t.finalodds,  
		  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2, f.finalodds finalodds2  
		FROM DBARC.bodb_archive.dbo.bettransm t WITH (NOLOCK)  
		  INNER JOIN DBARC.bodb_archive.dbo.bettransm f WITH (NOLOCK) ON t.refno = f.refno   
		WHERE t.bettype in (31,41) AND f.bettype in (32,42)  
		) bm on b.transid = bm.refno   
where b.bettype in (31,32,33,41,42,43)  
	and b.custid = @Custid        
	and b.transid = @TransID  
order by b.transid   

-- Virtual HR  
INSERT INTO @Data  
select   
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
	CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or statusID NOT IN(0, 1, 112, 113, 111) THEN 0 ELSE 1 END as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	r.EventTime showtime -- Race Name   
from   
	DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)   
	INNER JOIN DBARC.bodb_archive.dbo.VSOutright_bk o WITH (NOLOCK) ON b.oddsid = o.Orid  
	INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID  
	left join (     
		SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking,
		  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2
		FROM DBARC.bodb_archive.dbo.bettransm t WITH (NOLOCK)  
		  INNER JOIN DBARC.bodb_archive.dbo.bettransm f WITH (NOLOCK) ON t.refno = f.refno   
		WHERE t.bettype = 1231 AND f.bettype = 1232 
		) bm on b.refno = bm.refno  
where    
	b.custid = @Custid and  
	b.bettype in (1231, 1232, 1233, 1237, 1238) and   
	b.transid = @TransID  
END  

---- get data of systemp parlay  
IF @refno IS NOT NULL  
BEGIN  
-- tickets in bettrans   
INSERT INTO @Data  
select   
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
	0 as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	'' as showtime        
FROM bettrans as b with (nolock)     
WHERE    
	b.custid = @Custid    
	--and matchid=0    
	and matchid = 29  
	and bettype = 29    
	and b.refno = @refno   

--- 'At' check if subtickets in bettrans14    
INSERT INTO @Data  
select   
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
	0 as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	'' as showtime       
from bettrans14 as b with (nolock)     
where    
	b.custid = @Custid    
	--and matchid=0    
	and matchid = 29  
	and bettype = 29    
	and b.refno = @refno   

--- '14' check if subtickets in bettrans_bk   
INSERT INTO @Data  
select   
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
	0 as allowdelete,  
	(b.winlost-b.actual_stake)  winlost,  
	b.playercomm as commission,  
	(b.scomm - b.acomm) as scomm,  
	(b.acomm - b.comm) as acomm,  
	(b.comm - b.playercomm) as comm,  
	b.awinlost,  
	b.mwinlost,  
	b.swinlost,  
	'' as showtime       
FROM DBARC.bodb_archive.dbo.bettrans_bk b WITH(NOLOCK)  
WHERE  b.custid = @Custid    
	--and matchid=0    
	and matchid = 29  
	and bettype = 29    
	and b.refno = @refno   
END  

SELECT * FROM @Data  
ORDER BY transid    


INSERT INTO @DetailData  
SELECT   
	BG.refno,   
	BG.odds,   
	BG.stake,  
	BG.status,  
	BG.apositiontaking,   
	BG.mpositiontaking,   
	BG.spositiontaking,  
	BG.bettype,  
	BG.betteam    
FROM bettransg BG with (NOLOCK)  
	INNER JOIN @Data B ON BG.refno = B.refno  
WHERE B.Bettype between 1101 and 1199  
   

INSERT INTO @DetailData  
SELECT   
	BG.refno,   
	BG.odds,   
	BG.stake,  
	BG.status,  
	BG.apositiontaking,   
	BG.mpositiontaking,   
	BG.spositiontaking,  
	BG.bettype,  
	BG.betteam    
FROM bettransg14 BG with (NOLOCK)  
	INNER JOIN @Data B ON BG.refno = B.refno  
WHERE B.Bettype between 1101 and 1199  

INSERT INTO @DetailData  
SELECT   
	BG.refno,   
	BG.odds,   
	BG.stake,  
	BG.status,  
	BG.apositiontaking,   
	BG.mpositiontaking,   
	BG.spositiontaking,  
	BG.bettype,  
	BG.betteam    
FROM DBARC.bodb_archive.dbo.bettransg BG with (NOLOCK)  
	INNER JOIN @Data B ON BG.refno = B.refno  
WHERE B.Bettype between 1101 and 1199  
   
SELECT * FROM @DetailData  
