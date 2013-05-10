ALTER PROCEDURE [dbo].[Acc_Rpt_TraderPerformanceDetail_14]
	@fromdate datetime,
	@todate datetime,
	@isSoccer bit =1 
AS

SET NOCOUNT ON

/*
Created: 20090122@[creator]
Task : Trader performance of operators who are handling live games for members play bet (view detail on each match)
DB: DB06.bodb02
Original:

Revisions:    
    - 20081209@Khoa: Improve performance
    - 20081215@PhuongDao: Add Trader for Other Sports	
	- 20090104@Dung: Improve Performance 
	- 20090104@Khoa: add new betype Next Goal
	- 20090220@PhuongDao: Add leagueid column for report 
	- 20090226@PhuongDao: Change how to calculate Turnover as follows:
		+ Not including DRAW tickets 
		+ Turnover = Turnover /2 with HALF WIN or HALF LOSE tickets 
	- 20090702@Daniel: 
		+ Add bettype of Corners & 15 MINS OVER/UNDER, base on Leaguename
		+ Since using physical temptable without affective indexes is a waste, change to use temptable in memory (temp_daao) -> much faster
		+ List out orphan matches (matches which not assigned to any operator)
	- 20090729@Henry: Add Bettype 1st No.Of Corners
	- 20100504@Henry: Add Bettype 1st No.Of Yellow Card & No.of Yellow Card
			+ teamname LIKE '%No.of Corners%' then OU type = 1
			+ teamname LIKE '%No.of Yellow Cards%' then OU type = 3
			+ leaguename LIKE '%SPECIFIC 15 MINS OVER/UNDER%' OU type = 2
	- 20110228@Viet:	+ Change to use StatusID instead
						+ Remove bettype Next Goal and add new bettype Odd/Even  type = 4		
						+ Count live bet by bettype and match
	- 20110516@Lukas: re-arrange bettype
	- 20110823@Elly: - Correct Turnover of sports book since Sep 01, 2011
	- 20120412@Hurri: Exclude ticket of members under agent 'BARM' (change code: "<> 52466" -> "not in (52466, 5707545)")
	- 20120423@Hurri: Remove @NegativeBetEffectiveDate='2011-09-01'
	
Param's Explanation:
• @isSoccer
    = 1: Soccer
    = 0: Other Sports
*/

SET NOCOUNT ON
declare @temp_daao table
(
	custid int,
	username varchar(30), 
	leagueid int,
	matchid int,
	homeid int,
	awayid int,
	eventdate datetime,
	hthomescore int,
	htawayscore int,
	fthomescore int,
	ftawayscore int,
	bettype smallint,
	IsNeutral bit,
	OUtype tinyint
)


if @isSoccer = 1 
BEGIN	
	--DECLARE @NegativeBetEffectiveDate datetime
	--SET @NegativeBetEffectiveDate='2011-09-01'

	insert @temp_daao
	select c.custid, c.username, m.leagueid, m.matchid,
		m.homeid,
		m.awayid,
		m.eventdate,
		m.hthomescore,m.htawayscore,m.finalhomescore,m.finalawayscore,
		case	when operatortype = 1 and bettype = 1 then 1 
				when operatortype = 1 and bettype = 4 then 2
				when operatortype = 1 and bettype = 2 then 3 
				when operatortype = 1 and bettype = 3  then 5
				--when operatortype = 1 and bettype = 4  then 22 -- Next Goal
				when operatortype = 2 and bettype = 1 then 7
				when operatortype = 2 and bettype = 2 then 8
				when operatortype = 2 and bettype = 4 then 12
				when operatortype = 2 and bettype = 3  then 15		
		else 0 end bettype ,	
		m.isNeutral,	--phuong.nguyen
		case 
			when teamname LIKE '%No.of Corners%' then 1
			when teamname LIKE '%No.of Yellow Cards%' then 3
			when leaguename LIKE '%SPECIFIC 15 MINS OVER/UNDER%' then 2
			else 0
		end		
	from Dot_admin_Assignment_Operator a (nolock)  
		inner join match14 m with(nolock) on a.matchid=m.matchid
		inner join team t with(nolock) on m.homeid=t.teamid
		inner join customer c with(nolock) on a.operatorid=c.custid
		inner join league l with(nolock) on m.leagueid=l.leagueid		
	where
		m.eventdate >= @fromdate and m.eventdate <= @todate
		and m.eventstatus='completed'
		and m.sporttype= 1
		and a.operatortype < 3
		and m.matchcode not like '%hedge%'
	UNION ALL-- include orphan matches
	select NULL, NULL, m.leagueid, m.matchid,
		m.homeid,
		m.awayid,
		m.eventdate,
		m.hthomescore,m.htawayscore,m.finalhomescore,m.finalawayscore,0,
		m.isNeutral,	--phuong.nguyen
		case 
			when teamname LIKE '%No.of Corners%' then 1
			when teamname LIKE '%No.of Yellow Cards%' then 3
			when leaguename LIKE '%SPECIFIC 15 MINS OVER/UNDER%' then 2
			else 0
		end
	from 
		Dot_admin_Assignment_Operator a (nolock)
		right join match14 m with(nolock) on a.matchid = m.matchid
		inner join team t with(nolock) on m.homeid=t.teamid
		inner join league l with(nolock) on m.leagueid=l.leagueid
	where
		m.eventdate between @fromdate and @todate
		and m.eventstatus='completed'
		and m.sporttype=1
		and m.matchcode not like '%hedge%'
		and a.matchid is NULL			
END

ELSE if @isSoccer = 0 
BEGIN
	insert @temp_daao
	select c.custid, c.username, m.leagueid, m.matchid,
		m.homeid,
		m.awayid,
		m.eventdate,
		m.hthomescore,m.htawayscore,m.finalhomescore,m.finalawayscore,
		case	when operatortype = 1 and bettype = 1 then 1 
				when operatortype = 1 and bettype = 4 then 2
				when operatortype = 1 and bettype = 2 then 3 
				when operatortype = 1 and bettype = 3  then 5
				--when operatortype = 1 and bettype = 4  then 22 -- Next Goal
				when operatortype = 2 and bettype = 1 then 7
				when operatortype = 2 and bettype = 2 then 8
				when operatortype = 2 and bettype = 4 then 12
				when operatortype = 2 and bettype = 3  then 15		
		else 0 end bettype ,	
		m.isNeutral, 0
	from Dot_admin_Assignment_Operator a (nolock)  
		inner join match14 m with(nolock) on a.matchid=m.matchid
		inner join customer c with(nolock) on a.operatorid=c.custid
		inner join league l with(nolock) on m.leagueid=l.leagueid				
	where
		m.eventdate >= @fromdate and m.eventdate <= @todate
		and m.eventstatus='completed'
		and m.sporttype not in (1,161)-- exclude number game
		and a.operatortype < 3
		and m.matchcode not like '%hedge%'
	UNION ALL
	select NULL, NULL, m.leagueid, m.matchid,
		m.homeid,
		m.awayid,
		m.eventdate,
		m.hthomescore,m.htawayscore,m.finalhomescore,m.finalawayscore,0,
		m.isNeutral, 0
	from 
		Dot_admin_Assignment_Operator a (nolock)
		right join match14 m with(nolock) on a.matchid = m.matchid
		inner join league l with(nolock) on m.leagueid=l.leagueid
	where
		m.eventdate between @fromdate and @todate
		and m.eventstatus='completed'
		and m.sporttype not in (1,161)
		and m.matchcode not like '%hedge%'
		and a.matchid is NULL
END


select 
	custid, username, eventdate, leagueid, matchid,
	stake_hdp, stake_ou, stake_1sthdp, stake_1stou, stake_1x2, stake_1st1x2, stake_oe, stake_1stoe, stake_1stNoOfCorners, stake_NoOfCorners, stake_15minOU,stake_1stNoOfYellowCards,stake_NoOfYellowCards,
	winlost_hdp - comm_hdp as winlost_hdp, winlost_ou - comm_ou as winlost_ou, winlost_1sthdp - comm_1sthdp as winlost_1sthdp , winlost_1stou - comm_1stou as winlost_1stou, winlost_1x2 - comm_1x2 as winlost_1x2, winlost_1st1x2 - comm_1st1x2 as winlost_1st1x2, winlost_oe - comm_oe as winlost_oe,winlost_1stoe - comm_1stoe as winlost_1stoe, winlost_1stNoOfCorners - comm_1stNoOfCorners as winlost_1stNoOfCorners, winlost_NoOfCorners - comm_NoOfCorners as winlost_NoOfCorners, winlost_15minOU - comm_15minOU as winlost_15minOU, winlost_1stNoOfYellowCards - comm_1stNoOfYellowCards as winlost_1stNoOfYellowCards,winlost_NoOfYellowCards - comm_NoOfYellowCards as winlost_NoOfYellowCards,
	comm_hdp, comm_ou, comm_1sthdp, comm_1stou, comm_1x2, comm_1st1x2, comm_oe, comm_1stoe, comm_1stNoOfCorners,comm_NoOfCorners, comm_15minOU,comm_1stNoOfYellowCards,comm_NoOfYellowCards,
	homeid,
	awayid,
	IsNeutral,
	hthomescore, htawayscore, fthomescore, ftawayscore,
	stake_1sthdp + stake_hdp + stake_1stou + stake_ou + stake_1x2 + stake_1st1x2 + stake_oe + stake_1stoe + stake_1stNoOfCorners + stake_NoOfCorners + stake_15minOU + stake_1stNoOfYellowCards + stake_NoOfYellowCards as overall_st,
	winlost_1sthdp + winlost_hdp + winlost_1stou + winlost_ou +  winlost_1x2 + winlost_1st1x2 + winlost_oe + winlost_1stoe + winlost_1stNoOfCorners +winlost_NoOfCorners + winlost_15minOU + winlost_1stNoOfYellowCards + winlost_NoOfYellowCards
		- (comm_1sthdp + comm_hdp + comm_1stou + comm_ou + comm_1x2 + comm_1st1x2 + comm_oe + comm_1stoe + comm_1stNoOfCorners +comm_NoOfCorners + comm_15minOU + comm_1stNoOfYellowCards + comm_NoOfYellowCards )as overall_wl,	
	comm_1sthdp + comm_hdp + comm_1stou + comm_ou + comm_1x2 + comm_1st1x2 + comm_oe + comm_1stoe + comm_1stNoOfCorners +comm_NoOfCorners + comm_15minOU + comm_1stNoOfYellowCards + comm_NoOfYellowCards as overall_com,
	(winlost_1sthdp - comm_1sthdp)/(case when isnull(stake_1sthdp,0) = 0 then 1 else stake_1sthdp end) as margin_1sthdp,
	(winlost_hdp - comm_hdp)/(case when isnull(stake_hdp,0) = 0 then 1 else stake_hdp end) as margin_hdp,
	(winlost_1stou - comm_1stou)/(case when isnull(stake_1stou,0) = 0 then 1 else stake_1stou end) as margin_1stou,
	(winlost_ou - comm_ou)/(case when isnull(stake_ou,0) = 0 then 1 else stake_ou end) as margin_ou,
	(winlost_1x2 - comm_1x2)/(case when isnull(stake_1x2,0) = 0 then 1 else stake_1x2 end) as margin_1x2,
	(winlost_1st1x2 - comm_1st1x2)/(case when isnull(stake_1st1x2,0) = 0 then 1 else stake_1st1x2 end) as margin_1st1x2,
	--(winlost_ng - comm_ng)/(case when isnull(stake_ng,0) = 0 then 1 else stake_ng end) as margin_ng,
	(winlost_oe - comm_oe)/(case when isnull(stake_oe,0) = 0 then 1 else stake_oe end) as margin_oe,
	(winlost_1stoe - comm_oe)/(case when isnull(stake_oe,0) = 0 then 1 else stake_oe end) as margin_1stoe,
	(winlost_1stNoOfCorners - comm_1stNoOfCorners)/(case when isnull(stake_1stNoOfCorners,0) = 0 then 1 else stake_1stNoOfCorners end) as margin_1stNoOfCorners,
	(winlost_NoOfCorners - comm_NoOfCorners)/(case when isnull(stake_NoOfCorners,0) = 0 then 1 else stake_NoOfCorners end) as margin_NoOfCorners,
	(winlost_15minOU - comm_15minOU)/(case when isnull(stake_15minOU,0) = 0 then 1 else stake_15minOU end) as margin_15minOU,
	(winlost_1stNoOfYellowCards - comm_1stNoOfYellowCards)/(case when isnull(stake_1stNoOfYellowCards,0) = 0 then 1 else stake_1stNoOfYellowCards end) as margin_1stNoOfYellowCards,
	(winlost_NoOfYellowCards - comm_NoOfYellowCards)/(case when isnull(stake_NoOfYellowCards,0) = 0 then 1 else stake_NoOfYellowCards end) as margin_NoOfYellowCards,
	((winlost_1sthdp + winlost_hdp + winlost_1stou + winlost_ou + winlost_1x2 + winlost_1st1x2 + winlost_oe + winlost_1stoe + winlost_1stNoOfCorners + winlost_NoOfCorners + winlost_15minOU + winlost_1stNoOfYellowCards + winlost_NoOfYellowCards ) - (comm_1sthdp + comm_hdp + comm_1stou + comm_ou + comm_1x2 + comm_1st1x2 + comm_oe + comm_1stoe + comm_1stNoOfCorners + comm_NoOfCorners + comm_15minOU + comm_1stNoOfYellowCards + comm_NoOfYellowCards))
		/(case when (isnull(stake_1sthdp,0) + isnull(stake_hdp,0) + isnull(stake_1stou,0) + isnull(stake_ou,0) + isnull(stake_1x2,0) + isnull(stake_1st1x2,0) + isnull(stake_oe,0) + isnull(stake_1stoe,0) + isnull(stake_1stNoOfCorners,0) + isnull(stake_NoOfCorners,0) + isnull(stake_15minOU,0) + isnull(stake_1stNoOfYellowCards,0) + isnull(stake_NoOfYellowCards,0) ) = 0 then 1 
			else (isnull(stake_1sthdp,0) + isnull(stake_hdp,0) + isnull(stake_1stou,0) +isnull(stake_ou,0) + isnull(stake_1x2,0) + isnull(stake_1st1x2,0) + isnull(stake_oe,0)+ isnull(stake_1stoe,0)+ isnull(stake_1stNoOfCorners,0) +isnull(stake_NoOfCorners,0)+ isnull(stake_15minOU,0)  + isnull(stake_1stNoOfYellowCards,0) + isnull(stake_NoOfYellowCards,0)  ) end ) as overall_margin ,
	bet_hdp, bet_ou, bet_1sthdp, bet_1stou, bet_1x2, bet_1st1x2, bet_oe, bet_1stoe, bet_1stNoOfCorners, bet_NoOfCorners, bet_15minOU, bet_1stNoOfYellowCards, bet_NoOfYellowCards,
	bet_hdp + bet_ou + bet_1x2 + bet_oe + bet_1sthdp + bet_1stou + bet_1st1x2 + bet_1stoe +  bet_NoOfCorners + bet_1stNoOfCorners + bet_15minOU + bet_1stNoOfYellowCards + bet_NoOfYellowCards as overall_livebet

from
(
		select om.custid,om.username,om.eventdate, om.leagueid,om.matchid,
		--turn over
			--hdp, ou, ht hdp, ht ou, 1x2, 1st1x2, next goal  
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=1 
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_hdp,
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=2 
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_oe,												
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=3 and OUtype = 0
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_ou,
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=5 then ABS(b.stake)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_1x2,
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=7 
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_1sthdp,
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=8 and OUtype = 0 
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_1stou,	
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=12 
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_1stoe,								
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=15 then ABS(b.stake)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_1st1x2,					
			--sum(case when b.recommend not in (52466, 5707545) and b.bettype=22 
			--				then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end) *(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_ng,	--NEXT GOAL 
			sum((case when b.recommend not in (52466, 5707545) and b.bettype = 8 and OUtype = 1
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end)) as stake_1stNoOfCorners,
			sum((case when b.recommend not in (52466, 5707545) and b.bettype = 3 and OUtype = 1
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end)) as stake_NoOfCorners,
			sum((case when b.recommend not in (52466, 5707545) and b.bettype = 3 and OUtype = 2
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end)) as stake_15minOU,
			--1st No.of Yellow Cards + No.of Yellow Cards
			sum((case when b.recommend not in (52466, 5707545) and b.bettype = 8 and OUtype = 3
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end) *(1-b.tpositiontaking)*b.virtualrate else 0 end)) as stake_1stNoOfYellowCards,						
			sum((case when b.recommend not in (52466, 5707545) and b.bettype = 3 and OUtype = 3
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end)) as stake_NoOfYellowCards,

		--Winlost
			-sum(case when b.bettype=1 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_hdp,
			-sum(case when b.bettype=2 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_oe,
			-sum(case when b.bettype=3  and OUtype = 0 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_ou,
			-sum(case when b.bettype=5 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_1x2,
			-sum(case when b.bettype=7 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_1sthdp,
			-sum(case when b.bettype=8 and OUtype = 0 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_1stou,
			-sum(case when b.bettype=12 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_1stoe,
			-sum(case when b.bettype=15 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_1st1x2,
		--	-sum(case when b.bettype=22 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_ng,
			-sum(case when b.bettype=8 and OUtype = 1 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_1stNoOfCorners,
			-sum(case when b.bettype=3 and OUtype = 1 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_NoOfCorners,
			-sum(case when b.bettype=3 and OUtype = 2 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_15minOU,
			--1st No.of Yellow Cards + No.of Yellow Cards
			-sum(case when b.bettype=8 and OUtype = 3 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_1stNoOfYellowCards,
			-sum(case when b.bettype=3 and OUtype = 3 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_NoOfYellowCards,

		--Commission
			sum(case when b.bettype=1 then scomm*b.virtualrate else 0 end) as comm_hdp,
			sum(case when b.bettype=2 then scomm*b.virtualrate else 0 end) as comm_oe,
			sum(case when b.bettype=3  and OUtype = 0 then scomm*b.virtualrate else 0 end) as comm_ou,
			sum(case when b.bettype=5 then scomm*b.virtualrate else 0 end) as comm_1x2,
			sum(case when b.bettype=7 then scomm*b.virtualrate else 0 end) as comm_1sthdp,
			sum(case when b.bettype=8 and OUtype = 0 then scomm*b.virtualrate else 0 end) as comm_1stou,
			sum(case when b.bettype=12 then scomm*b.virtualrate else 0 end) as comm_1stoe,
			sum(case when b.bettype=15 then scomm*b.virtualrate else 0 end) as comm_1st1x2,
			--sum(case when b.bettype=22 then scomm*b.virtualrate else 0 end) as comm_ng,
			sum(case when b.bettype=8 and OUtype = 1  then scomm*b.virtualrate else 0 end) as comm_1stNoOfCorners,
			sum(case when b.bettype=3 and OUtype = 1  then scomm*b.virtualrate else 0 end) as comm_NoOfCorners,
			sum(case when b.bettype=3 and OUtype = 2 then scomm*b.virtualrate else 0 end) as comm_15minOU,
			--1st No.of Yellow Cards + No.of Yellow Cards
			sum(case when b.bettype=8 and OUtype = 3 then scomm*b.virtualrate else 0 end) as comm_1stNoOfYellowCards,
			sum(case when b.bettype=3 and OUtype = 3  then scomm*b.virtualrate else 0 end) as comm_NoOfYellowCards,
			
		--Live BetCount				
			sum(case when b.bettype = 1 then 1 else 0 end) as bet_hdp,
			sum(case when b.bettype = 2 then 1 else 0 end) as bet_oe,
			sum(case when b.bettype = 3 and OUtype = 0 then 1 else 0 end) as bet_ou,
			sum(case when b.bettype = 7 then 1 else 0 end) as bet_1sthdp,
			sum(case when b.bettype = 8 and OUtype = 0 then 1 else 0 end) as bet_1stou,
			sum(case when b.bettype = 5 then 1 else 0 end) as bet_1x2,
			sum(case when b.bettype =12 then 1 else 0 end) as bet_1stoe,
			sum(case when b.bettype = 15 then 1 else 0 end) as bet_1st1x2,
			sum(case when b.bettype = 8 and OUtype =1 then 1 else 0 end) as bet_1stNoOfCorners,
			sum(case when b.bettype = 3 and OUType =1 then 1 else 0 end) as bet_NoOfCorners,
			sum(case when b.bettype = 3 and OUType =2 then 1 else 0 end) as bet_15minOU,
			sum(case when b.bettype = 8 and OUType = 3 then 1 else 0 end) as bet_1stNoOfYellowCards,
			sum(case when b.bettype = 3 and OUType = 3 then 1 else 0 end) as bet_NoOfYellowCards,
			
		 --om.hometeam,om.awayteam,
			om.homeid,
			om.awayid,
			om.hthomescore,om.htawayscore,om.fthomescore,om.ftawayscore,
			om.IsNeutral
		from bettrans14 b with(nolock) 		
			inner join @temp_daao om  on b.matchid=om.matchid and b.bettype = om.bettype and LiveIndicator = 1
		where 
		--b.status not in ('VOID','REJECT','DRAW','DONE', 'REFUND') 
		b.statusID not in (101,102,103,121,111) 
		AND b.ruben =1 
		group by om.custid,om.username,om.eventdate, om.leagueid, om.matchid,om.homeid,om.awayid,om.hthomescore,om.htawayscore,om.fthomescore,om.ftawayscore,om.IsNeutral
		UNION ALL
		select 0,'(unassigned)',om.eventdate, om.leagueid,om.matchid,
		--turn over
			--hdp, ou, ht hdp, ht ou, 1x2, 1st1x2, next goal  
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=1 
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_hdp,
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=3 and OUtype = 0
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_ou,
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=5 then ABS(b.stake)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_1x2,
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=7 
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_1sthdp,
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=8 and OUtype = 0 
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_1stou,		
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=15 then ABS(b.stake)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_1st1x2,	
			--sum(case when b.recommend not in (52466, 5707545) and b.bettype=22 
			--				then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end) *(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_ng,	--NEXT GOAL 
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=2 
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_oe,
			sum(case when b.recommend not in (52466, 5707545) and b.bettype=12 
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end) as stake_1stoe,								
			sum((case when b.recommend not in (52466, 5707545) and b.bettype = 8 and OUtype = 1
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end)) as stake_1stNoOfCorners,
			sum((case when b.recommend not in (52466, 5707545) and b.bettype = 3 and OUtype = 1
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end)) as stake_NoOfCorners,
			sum((case when b.recommend not in (52466, 5707545) and b.bettype = 3 and OUtype = 2
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end)) as stake_15minOU,
			--1st No.of Yellow Cards + No.of Yellow Cards
			sum((case when b.recommend not in (52466, 5707545) and b.bettype = 8 and OUtype = 3
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end) *(1-b.tpositiontaking)*b.virtualrate else 0 end)) as stake_1stNoOfYellowCards,						
			sum((case when b.recommend not in (52466, 5707545) and b.bettype = 3 and OUtype = 3
							then (case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate else 0 end)) as stake_NoOfYellowCards,				

		--Winlost
			-sum(case when b.bettype=1 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_hdp,
			-sum(case when b.bettype=2 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_oe,
			-sum(case when b.bettype=3 and OUtype = 0 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_ou,
			-sum(case when b.bettype=5 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_1x2,
			-sum(case when b.bettype=7 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_1sthdp,
			-sum(case when b.bettype=8 and OUtype = 0 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_1stou,
			-sum(case when b.bettype=12 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_1stoe,
			-sum(case when b.bettype=15 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_1st1x2,
		--	-sum(case when b.bettype=22 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_ng,
			-sum(case when b.bettype=8 and OUtype = 1 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_1stNoOfCorners,
			-sum(case when b.bettype=3 and OUtype = 1 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_NoOfCorners,
			-sum(case when b.bettype=3 and OUtype = 2 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_15minOU,
			--1st No.of Yellow Cards + No.of Yellow Cards
			-sum(case when b.bettype=8 and OUtype = 3 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_1stNoOfYellowCards,
			-sum(case when b.bettype=3 and OUtype = 3 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_NoOfYellowCards,

		--Commission
			sum(case when b.bettype=1 then scomm*b.virtualrate else 0 end) as comm_hdp,
			sum(case when b.bettype=2 then scomm*b.virtualrate else 0 end) as comm_oe,
			sum(case when b.bettype=3 and OUtype = 0 then scomm*b.virtualrate else 0 end) as comm_ou,
			sum(case when b.bettype=5 then scomm*b.virtualrate else 0 end) as comm_1x2,
			sum(case when b.bettype=7 then scomm*b.virtualrate else 0 end) as comm_1sthdp,
			sum(case when b.bettype=8 and OUtype = 0 then scomm*b.virtualrate else 0 end) as comm_1stou,
			sum(case when b.bettype=12 then scomm*b.virtualrate else 0 end) as comm_1stoe,
			sum(case when b.bettype=15 then scomm*b.virtualrate else 0 end) as comm_1st1x2,
			--sum(case when b.bettype=22 then scomm*b.virtualrate else 0 end) as comm_ng,
			sum(case when b.bettype=8 and OUtype = 1  then scomm*b.virtualrate else 0 end) as comm_1stNoOfCorners,
			sum(case when b.bettype=3 and OUtype = 1  then scomm*b.virtualrate else 0 end) as comm_NoOfCorners,
			sum(case when b.bettype=3 and OUtype = 2 then scomm*b.virtualrate else 0 end) as comm_15minOU,
			--1st No.of Yellow Cards + No.of Yellow Cards
			sum(case when b.bettype=8 and OUtype = 3 then scomm*b.virtualrate else 0 end) as comm_1stNoOfYellowCards,
			sum(case when b.bettype=3 and OUtype = 3  then scomm*b.virtualrate else 0 end) as comm_NoOfYellowCards,
		
			
		--Live BetCount				
			sum(case when b.bettype = 1 then 1 else 0 end) as bet_hdp,
			sum(case when b.bettype = 2 then 1 else 0 end) as bet_oe,
			sum(case when b.bettype = 3 and OUtype = 0 then 1 else 0 end) as bet_ou,
			sum(case when b.bettype = 7 then 1 else 0 end) as bet_1sthdp,
			sum(case when b.bettype = 8 and OUtype = 0 then 1 else 0 end) as bet_1stou,
			sum(case when b.bettype = 5 then 1 else 0 end) as bet_1x2,
			sum(case when b.bettype =12 then 1 else 0 end) as bet_1stoe,
			sum(case when b.bettype = 15 then 1 else 0 end) as bet_1st1x2,
			sum(case when b.bettype = 8 and OUtype =1 then 1 else 0 end) as bet_1stNoOfCorners,
			sum(case when b.bettype = 3 and OUType =1 then 1 else 0 end) as bet_NoOfCorners,
			sum(case when b.bettype = 3 and OUType =2 then 1 else 0 end) as bet_15minOU,
			sum(case when b.bettype = 8 and OUType = 3 then 1 else 0 end) as bet_1stNoOfYellowCards,
			sum(case when b.bettype = 3 and OUType = 3 then 1 else 0 end) as bet_NoOfYellowCards,
			
		 --om.hometeam,om.awayteam,
			om.homeid,
			om.awayid,
			om.hthomescore,om.htawayscore,om.fthomescore,om.ftawayscore,
			om.IsNeutral
		from bettrans14 b with(nolock) 		
			inner join @temp_daao om  on b.matchid=om.matchid and om.bettype = 0 and LiveIndicator = 1
		where 
		--b.status not in ('VOID','REJECT','DRAW','DONE', 'REFUND') 
		b.statusID not in (101,102,103,121,111) 
		AND b.ruben =1 
		group by om.eventdate, om.leagueid, om.matchid,om.homeid,om.awayid,om.hthomescore,om.htawayscore,om.fthomescore,om.ftawayscore,om.IsNeutral

) as a
order by username,eventdate, leagueid, matchid


GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_TraderPerformanceDetail_14] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_TraderPerformanceDetail_14] TO [vnteam]