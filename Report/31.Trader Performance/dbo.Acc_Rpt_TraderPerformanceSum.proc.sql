USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_Rpt_TraderPerformanceSum]    Script Date: 09/18/2015 09:38:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Acc_Rpt_TraderPerformanceSum]  
 @fromdate datetime,  
 @todate datetime,  
 @isSoccer bit =1  
AS  
  
/*  
 Created: 20090122@[creator]  
 Task : Trader performance of operators who are handling live games for members play bet(handle on each match)  
 DB: DBACC/bodb02  
 Original:  
  
 Revisions:      
  - 20081209@Khoa: Improve performance   
  - 20090104@Dung: Improve Performance   
  - 20090104@Khoa: add new betype Next Goal  
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
  -- 20100525@Henry: Change to use StatusID instead of Status in WHERE statement  
  - 20101125@Johnson: + Remove bettype Next Goal and add new bettype Odd/Even  type = 4  
       + Count live bet by bettype and match  
  - 20110224@Amy: Adding new Next Corner column  
  - 20110506@Amy: Change way to get Next Corner (by bettype=5 and operatortype=1)
  - 20110608@Amy: Change to temporary get Next Corner by teamname 
  - 20110822@Elly: - Correct Turnover of sports book since Sep 01, 2011
  - 20120412@Hurri: Exclude ticket of members under agent 'BARM' (change code: "<> 52466" -> "not in (52466, 5707545)")
  - 20120423@Hurri: Remove @NegativeBetEffectiveDate='2011-09-01'
  - 20130628@Johnson: Remove column "No. of Yellow Card" and add more column for report
						• 1st Total Bookings, Next Booking, Total Bookings
						• Total Bookings 15mins O /U,Corners 15mins O/U 
						• 10 mins O/U, Single Team O/U
  - 20140121@Johnson: category leagues by major or minor 
  - 20140519@Johnson: Remove bettype from league name [RedmineID:#16022]						
  - 20140617@Johnson: Add more columns 10mins hdp, 10mins 1x2 [RedmineID: #17685]
  - 20150122@Johnson: optimize sp
  - 20150909@Jim: Remove leagueName SPECIALS (HotFix #41712)
  - 20160317@Robert - Incorporate 1X2 HDP and 1H 1X2 HDP bet types into Trader Performance Report[#54184]
  - 20160414@Robert - Trader Performance Report - Mismatch Turnover data with TGR/Performance Detail report[RedmineId: #55948]
 Param's Explanation:  
 • @isSoccer  
  = 1: Soccer  
  = 0: Other Sport  
*/  
/* 
select * from _tmp_traderOld
return
*/

SET NOCOUNT ON  
  
Declare @o_x smalldatetime SELECT @o_x = max(winlostdate) FROM bettrans14 with (nolock)  
Declare @countOrphan int  
--DECLARE @NegativeBetEffectiveDate datetime
--SET @NegativeBetEffectiveDate='2011-09-01'

--temp table for operator username and number of matches control by an operator  
DECLARE @temp_daao TABLE  
(  
 custid int,  
 username varchar(30),   
 matchID int,  
 bettype smallint ,  
 OUtype tinyint,
 category varchar(10)  
)  
  
  
IF @isSoccer = 1 AND (@fromdate > @o_x or @todate > @o_x )   
BEGIN  
 insert @temp_daao (custid,username,matchID, bettype,OUtype,category)  
 select a.operatorid, username,  m.matchID,  
   case when (a.bettype = 1 or a.bettype=5) and (a.operatortype = 1) then 1   
     when (a.bettype = 1 and a.operatortype = 2) then 7   
     when (a.bettype = 2 and a.operatortype = 1) then 3  
     when (a.bettype = 2 and a.operatortype = 2) then 8  
     when (a.bettype = 3 and a.operatortype = 1) then 5  
     when (a.bettype = 3 and a.operatortype = 2) then 15  
     --when (a.bettype = 4 and a.operatortype = 1) then 22 -- Next Goal  
     when (a.bettype = 4 and a.operatortype = 1) then 2  
     when (a.bettype = 4 and a.operatortype = 2) then 12            
   else 0  end,  
  case
   when leaguename LIKE '%SPECIFIC 15 MINS%' AND t.teamname LIKE '%No.of Corners%' THEN 6   
   when t.teamname LIKE '%No.of Corners%' then 1  
   when t.teamname LIKE '%Total Bookings' then 3   
   when t.teamname LIKE '%Booking' then 5     
   --when a.bettype=5 then 4   
   when t.teamname LIKE '%Corner%' then 4       
   when leaguename LIKE '%SPECIFIC 15 MINS TOTAL BOOKINGS%' then 7 
   when leaguename LIKE '%SPECIFIC 15 MINS%' then 2 
   when leaguename LIKE '%SPECIFIC 10 MINS%' then 8
   when leaguename LIKE '%SINGLE TEAM OVER/UNDER%' and (t.teamname LIKE '%Over' or t.teamname LIKE '%Under') THEN 9    
   
   else 0  
  end ,
  l.category 
 from Dot_admin_Assignment_Operator a (nolock)  
  inner join customer c with(nolock) on a.operatorid=c.custid  
  inner join match m with(nolock) on a.matchid=m.matchid  
  inner join team t with(nolock) on m.homeid=t.teamid        
  inner join team ta with(nolock) on m.awayid=ta.teamid     
  inner join league l with(nolock) on m.leagueid=l.leagueid  
 where  
  m.eventdate between @fromdate and @todate  
  and m.eventstatus='completed'  
  and m.sporttype=1  
  and m.matchcode not like '%hedge%'  
  and a.operatortype < 3  
 UNION ALL-- include orphan matches  
 select NULL, NULL,  m.matchID,0,  
  case   
   when leaguename LIKE '%SPECIFIC 15 MINS%' AND t.teamname LIKE '%No.of Corners%' THEN 6   
   when t.teamname LIKE '%No.of Corners%' then 1  
   when t.teamname LIKE '%Total Bookings' then 3   
   when t.teamname LIKE '%Booking' then 5     
   --when a.bettype=5 then 4   
   when t.teamname LIKE '%Corner%' then 4       
   when leaguename LIKE '%SPECIFIC 15 MINS TOTAL BOOKINGS%' then 7 
   when leaguename LIKE '%SPECIFIC 15 MINS%' then 2 
   when leaguename LIKE '%SPECIFIC 10 MINS%' then 8
   when leaguename LIKE '%SINGLE TEAM OVER/UNDER%' and (t.teamname LIKE '%Over' or t.teamname LIKE '%Under') THEN 9    
   else 0  
  end ,
  l.category   
 from   
  Dot_admin_Assignment_Operator a (nolock)  
  right join match m with(nolock) on a.matchid = m.matchid  
  inner join team t with(nolock) on m.homeid=t.teamid   
  inner join team ta with(nolock) on m.awayid=ta.teamid         
  inner join league l with(nolock) on m.leagueid=l.leagueid  
 where  
  m.eventdate between @fromdate and @todate  
  and m.eventstatus='completed'  
  and m.sporttype=1  
  and m.matchcode not like '%hedge%'  
  and a.matchid is NULL  
  
END  
 -- OTHER SPORTS   
ELSE IF @isSoccer = 0 AND (@fromdate > @o_x or @todate > @o_x )   
 BEGIN  
  insert @temp_daao (custid,username,matchID, bettype, OUtype, category)  
  select a.operatorid, username,  m.matchID,  
    case when (a.bettype = 1 or a.bettype =5)  and (a.operatortype = 1) then 1   
      when (a.bettype = 1 and a.operatortype = 2) then 7   
      when (a.bettype = 2 and a.operatortype = 1) then 3  
      when (a.bettype = 2 and a.operatortype = 2) then 8  
      when (a.bettype = 3 and a.operatortype = 1) then 5  
      when (a.bettype = 3 and a.operatortype = 2) then 15  
      --when (a.bettype = 4 and a.operatortype = 1) then 22 -- Next Goal  
      when (a.bettype = 4 and a.operatortype = 1) then 2  
      when (a.bettype = 4 and a.operatortype = 2) then 12               
    else 0  end, 0 ,
	l.category   
  from Dot_admin_Assignment_Operator a (nolock)  
   inner join customer c with(nolock) on a.operatorid=c.custid  
   inner join match m with(nolock) on a.matchid=m.matchid  
   inner join league l with(nolock) on m.leagueid=l.leagueid  
  where  
   m.eventdate between @fromdate and @todate  
   and m.eventstatus='completed'  
   and m.sporttype not in (1,161)--exclude number game  
   and m.matchcode not like '%hedge%'  
   and a.operatortype < 3  
  UNION ALL-- include orphan matches  
  select NULL, NULL,  m.matchID,0,0 ,l.category   
  from   
   Dot_admin_Assignment_Operator a (nolock)  
   right join match m with(nolock) on a.matchid = m.matchid  
   inner join league l with(nolock) on m.leagueid=l.leagueid  
  where  
   m.eventdate between @fromdate and @todate  
   and m.eventstatus='completed'  
   and m.sporttype not in (1,161) -- exclude number game  
   and m.matchcode not like '%hedge%'  
   and a.matchid is NULL  
 END  
  
if @fromdate > @o_x or @todate > @o_x   
BEGIN  
    create table #userMatch  
 (  
  custid int primary key,  
  nMatch int,  
  Major int,
  Minor1 int,
  Minor2 int,
  Minor3 int,
  Others int
 )  
 
 DECLARE @countMajorOrphan int, @countMinor1Orphan int, @countMinor2Orphan int, @countMinor3Orphan int , @countOthersOrphan int
 
 insert #userMatch (custid,nMatch, Major,Minor1,Minor2,Minor3,Others) 
 SELECT custid, isnull(Major,0) + isnull(Minor1,0) + isnull(Minor2,0) + isnull(Minor3,0) + isnull(Others,0) as nMatch,isnull(Major,0), isnull(Minor1,0), isnull(Minor2,0), isnull(Minor3,0) ,isnull(Others,0)
 FROM( 
	 select t.custid, ISNULL(t.category,'Others') as category, count(distinct t.matchID) as cntMatch
	 from @temp_daao t  
	  inner join bettrans b with (nolock) on b.matchid=t.matchid and (b.bettype = t.bettype  or (b.bettype = 124 AND t.BetType = 5) OR (b.bettype = 125 AND t.BetType = 15))
	 where LiveIndicator = 1 and   
	 --b.status not in ('VOID','REJECT','DRAW','DONE','REFUND')  
	 b.statusID not in (101,102,103,121,111)   
	 and b.currency <> 20 
	 group by t.custid ,ISNULL(t.category,'Others')  ) as s
 PIVOT(
	SUM(s.cntMatch)
	FOR category in (Major, Minor1, Minor2, Minor3, Others)
 ) p

 ; WITH T AS(  
 select ISNULL(t.category,'Others') category, count(distinct t.matchID) countOrphan
 from @temp_daao t  
  inner join bettrans b with (nolock) on b.matchid=t.matchid and t.bettype = 0  
 where LiveIndicator = 1 and   
 --b.status not in ('VOID','REJECT','DRAW','DONE','REFUND')  
 b.statusID not in (101,102,103,121,111)   
 and b.currency <> 20
 GROUP by ISNULL(t.category,'Others')
 )
 
 SELECT @countMajorOrphan = SUM(CASE when category = 'Major' THEN countOrphan ELSE 0 end),
		@countMinor1Orphan = SUM(CASE when category = 'Minor1' THEN countOrphan ELSE 0 end),
		@countMinor2Orphan = SUM(CASE when category = 'Minor2' THEN countOrphan ELSE 0 end),
		@countMinor3Orphan = SUM(CASE when category = 'Minor3' THEN countOrphan ELSE 0 end),
		@countOthersOrphan = SUM(CASE when category = 'Others' THEN countOrphan ELSE 0 end)
 FROM T 
 
 
select b.matchid,bettype,
    sum(case when b.bettype IN (5,15)
									 then ABS(b.stake)*(1-b.tpositiontaking)*b.virtualrate
							WHEN b.bettype IN (1,2,3,7,8,12,124,125) 
									then(case when b.modds = 0.25 OR b.modds = -0.25 then b.stake/2 else b.stake end)*(1-b.tpositiontaking)*b.virtualrate 
							else 0 end) as stake,              
   --Winlost  
   -sum((winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate) as winlost,
   --Commission  
   sum(scomm*b.virtualrate) as comm,  
   --Live BetCount      
    count(1) as bet    
INTO #bettrans
from bettrans b with(nolock) 
WHERE  b.statusID not in (101,102,103,121,111)   
   AND b.ruben =1  
   AND b.bettype in (1,3,7,8,5,15,2,12,124,125)   
   AND b.winlostdate between @fromdate AND @todate
   AND LiveIndicator = 1  
   AND b.currency <> 20
GROUP by matchid, bettype	
  
 select   
 custid, username, matchno,   
 a.Major, a.Minor1, a.Minor2, a.Minor3, a.Others,  
 stake_hdp, stake_ou, stake_1sthdp, stake_1stou,stake_1x2, stake_1st1x2, stake_oe,stake_1stoe,stake_1stNoOfCorners, stake_NoOfCorners, stake_15minhdp, stake_15minOU, stake_15min1x2, stake_1stTotalBookings,stake_TotalBookings,stake_NextCorner,  
 stake_NextBooking, stake_15minCorners, stake_15minTotalBookings, stake_10minHdp, stake_10minOU, stake_10min1x2, stake_SingleTeamOU,
  
 winlost_hdp - comm_hdp as winlost_hdp,   
 winlost_ou - comm_ou as winlost_ou,   
 winlost_oe - comm_oe as winlost_oe,  
 winlost_1sthdp - comm_1sthdp as winlost_1sthdp,   
 winlost_1stou - comm_1stou as winlost_1stou,   
 winlost_1x2 - comm_1x2 as winlost_1x2,   
 winlost_1st1x2 - comm_1st1x2 as winlost_1st1x2,   
 --winlost_ng - comm_ng as winlost_ng,  
 winlost_1stoe - comm_1stoe as winlost_1stoe,  
 winlost_1stNoOfCorners - comm_1stNoOfCorners as winlost_1stNoOfCorners,   
 winlost_NoOfCorners - comm_NoOfCorners as winlost_NoOfCorners,   
 winlost_15minhdp - comm_15minhdp as winlost_15minhdp,
 winlost_15minOU - comm_15minOU as winlost_15minOU,
 winlost_15min1x2 - comm_15min1x2 as winlost_15min1x2,   
 winlost_1stTotalBookings - comm_1stTotalBookings as winlost_1stTotalBookings,  
 winlost_TotalBookings - comm_TotalBookings as winlost_TotalBookings,  
 winlost_NextCorner - comm_NextCorner as winlost_NextCorner,  
 winlost_NextBooking - comm_NextBooking as winlost_NextBooking,  
 winlost_15minCorners - comm_15minCorners as winlost_15minCorners,  
 winlost_15minTotalBookings - comm_15minTotalBookings as winlost_15minTotalBookings,
 winlost_10minHdp - comm_10minHdp as winlost_10minHdp,
 winlost_10minOU - comm_10minOU as winlost_10minOU,
 winlost_10min1x2 - comm_10min1x2 as winlost_10min1x2,
 winlost_SingleTeamOU - comm_SingleTeamOU as winlost_SingleTeamOU,    
 
 comm_hdp, comm_ou, comm_1sthdp, comm_1stou,  comm_1x2, comm_1st1x2, comm_oe, comm_1stoe, comm_1stNoOfCorners, comm_NoOfCorners, comm_15minhdp, comm_15minOU, comm_15min1x2, comm_1stTotalBookings,comm_TotalBookings,comm_NextCorner,  
 comm_NextBooking, comm_15minCorners, comm_15minTotalBookings, comm_10minHdp, comm_10minOU, comm_10min1x2, comm_SingleTeamOU,
   
 stake_1sthdp + stake_hdp + stake_1stou+stake_ou + stake_1x2 + stake_1st1x2 + stake_oe + stake_1stoe + stake_1stNoOfCorners + stake_NoOfCorners + stake_15minhdp + stake_15minOU + stake_15min1x2 +stake_1stTotalBookings +stake_TotalBookings+stake_NextCorner
			+ stake_NextBooking + stake_15minCorners + stake_15minTotalBookings + stake_10minHdp + stake_10minOU + stake_10min1x2 + stake_SingleTeamOU as overall_st,  
   
 winlost_1sthdp + winlost_hdp + winlost_1stou + winlost_ou +  winlost_1x2 + winlost_1st1x2 + winlost_oe + winlost_1stoe + winlost_1stNoOfCorners +  winlost_NoOfCorners + winlost_15minhdp + winlost_15minOU + winlost_15min1x2 + winlost_1stTotalBookings + winlost_TotalBookings + winlost_NextCorner 
			+ winlost_NextBooking + winlost_15minCorners + winlost_15minTotalBookings + winlost_10minHdp + winlost_10minOU + winlost_10min1x2 + winlost_SingleTeamOU 
   - (comm_1sthdp + comm_hdp + comm_1stou + comm_ou + comm_1x2 + comm_1st1x2 + comm_oe + comm_1stoe + comm_1stNoOfCorners + comm_NoOfCorners + comm_15minhdp + comm_15minOU + comm_15min1x2 + comm_1stTotalBookings + comm_TotalBookings + comm_NextCorner
			+ comm_NextBooking + comm_15minCorners + comm_15minTotalBookings + comm_10minHdp + comm_10minOU + comm_10min1x2 + comm_SingleTeamOU ) as overall_wl,   
   
 comm_1sthdp + comm_hdp + comm_1stou + comm_ou + comm_1x2 + comm_1st1x2 + comm_oe + comm_1stoe + comm_1stNoOfCorners + comm_NoOfCorners + comm_15minhdp + comm_15minOU + comm_15min1x2 + comm_1stTotalBookings + comm_TotalBookings +comm_NextCorner
			+ comm_NextBooking + comm_15minCorners + comm_15minTotalBookings + comm_10minHdp + comm_10minOU + comm_10min1x2 + comm_SingleTeamOU as overall_com,  
  
 (winlost_1sthdp - comm_1sthdp)/(case when isnull(stake_1sthdp,0) = 0 then 1 else stake_1sthdp end) as margin_1sthdp,  
 (winlost_hdp - comm_hdp)/(case when isnull(stake_hdp,0) = 0 then 1 else stake_hdp end) as margin_hdp,  
 (winlost_1stou - comm_1stou)/(case when isnull(stake_1stou,0) = 0 then 1 else stake_1stou end) as margin_1stou,  
 (winlost_ou - comm_ou)/(case when isnull(stake_ou,0) = 0 then 1 else stake_ou end) as margin_ou,  
 (winlost_1x2 - comm_1x2)/(case when isnull(stake_1x2,0) = 0 then 1 else stake_1x2 end) as margin_1x2,  
 (winlost_1st1x2 - comm_1st1x2)/(case when isnull(stake_1st1x2,0) = 0 then 1 else stake_1st1x2 end) as margin_1st1x2,  
 --(winlost_ng - comm_ng)/(case when isnull(stake_ng,0) = 0 then 1 else stake_ng end) as margin_ng,  
 (winlost_oe -comm_oe)/(case when isnull(stake_oe,0) = 0 then 1 else stake_oe end) as margin_oe,  
 (winlost_1stoe - comm_1stoe)/(case when isnull(stake_1stoe,0) = 0 then 1 else stake_1stoe end) as margin_1stoe,  
 (winlost_1stNoOfCorners - comm_1stNoOfCorners)/(case when isnull(stake_1stNoOfCorners,0) = 0 then 1 else stake_1stNoOfCorners end) as margin_1stNoOfCorners,  
 (winlost_NoOfCorners - comm_NoOfCorners)/(case when isnull(stake_NoOfCorners,0) = 0 then 1 else stake_NoOfCorners end) as margin_NoOfCorners,  
 (winlost_15minhdp - comm_15minhdp)/(case when isnull(stake_15minhdp,0) = 0 then 1 else stake_15minhdp end) as margin_15minhdp,  
 (winlost_15minOU - comm_15minOU)/(case when isnull(stake_15minOU,0) = 0 then 1 else stake_15minOU end) as margin_15minOU,  
 (winlost_15min1x2 - comm_15min1x2)/(case when isnull(stake_15min1x2,0) = 0 then 1 else stake_15min1x2 end) as margin_15min1x2,  
 (winlost_1stTotalBookings - comm_1stTotalBookings)/(case when isnull(stake_1stTotalBookings,0) = 0 then 1 else stake_1stTotalBookings end) as margin_1stTotalBookings,  
 (winlost_TotalBookings - comm_TotalBookings)/(case when isnull(stake_TotalBookings,0) = 0 then 1 else stake_TotalBookings end) as margin_TotalBookings,  
 (winlost_NextCorner - comm_NextCorner)/(case when isnull(stake_NextCorner,0) = 0 then 1 else stake_NextCorner end) as margin_NextCorner,  
 (winlost_NextBooking - comm_NextBooking)/(case when isnull(stake_NextBooking,0) = 0 then 1 else stake_NextBooking end) as margin_NextBooking,  
 (winlost_15minCorners - comm_15minCorners)/(case when isnull(stake_15minCorners,0) = 0 then 1 else stake_15minCorners end) as margin_15minCorners,  
 (winlost_15minTotalBookings - comm_15minTotalBookings)/(case when isnull(stake_15minTotalBookings,0) = 0 then 1 else stake_15minTotalBookings end) as margin_15minTotalBookings,  
 (winlost_10minHdp - comm_10minHdp)/(case when isnull(stake_10minHdp,0) = 0 then 1 else stake_10minHdp end) as margin_10minhdp,  
 (winlost_10minOU - comm_10minOU)/(case when isnull(stake_10minOU,0) = 0 then 1 else stake_10minOU end) as margin_10minOU,  
 (winlost_10min1x2 - comm_10min1x2)/(case when isnull(stake_10min1x2,0) = 0 then 1 else stake_10min1x2 end) as margin_10min1x2,  
 (winlost_SingleTeamOU - comm_SingleTeamOU)/(case when isnull(stake_SingleTeamOU,0) = 0 then 1 else stake_SingleTeamOU end) as margin_SingleTeamOU,  
 
   
 ((winlost_1sthdp + winlost_hdp + winlost_1stou + winlost_ou + winlost_1x2 + winlost_1st1x2 + winlost_oe + winlost_1stoe  + winlost_1stNoOfCorners +winlost_NoOfCorners + winlost_15minhdp + winlost_15minOU + winlost_15min1x2 + winlost_1stTotalBookings + winlost_TotalBookings +  winlost_NextCorner
	+  winlost_NextBooking + winlost_15minCorners + winlost_15minTotalBookings + winlost_10minHdp + winlost_10minOU + winlost_10min1x2 + winlost_SingleTeamOU)   
  - (comm_1sthdp + comm_hdp + comm_1stou + comm_ou + comm_1x2 + comm_1st1x2 + comm_oe + comm_1stoe + comm_1stNoOfCorners + comm_NoOfCorners + comm_15minhdp + comm_15minOU + comm_15min1x2 + comm_1stTotalBookings + comm_TotalBookings+comm_NextCorner
		+  comm_NextBooking + comm_15minCorners + comm_15minTotalBookings + comm_10minHdp + comm_10minOU + comm_10min1x2 + comm_SingleTeamOU))  
  /(case when (isnull(stake_1sthdp,0) + isnull(stake_hdp,0) + isnull(stake_1stou,0) + isnull(stake_ou,0) + isnull(stake_1x2,0) + isnull(stake_1st1x2,0) + isnull(stake_oe,0) + isnull(stake_1stoe,0) + isnull(stake_1stNoOfCorners,0) + isnull(stake_NoOfCorners,0) + isnull(stake_15minhdp,0) + isnull(stake_15minOU,0) + isnull(stake_15min1x2,0)  + isnull(stake_1stTotalBookings,0) + isnull(stake_TotalBookings,0) +isnull(stake_NextCorner,0)
		+  isnull(stake_NextBooking,0) + isnull(stake_15minCorners,0) + isnull(stake_15minTotalBookings,0) + isnull(stake_10minHdp,0) + isnull(stake_10minOU,0) + isnull(stake_10min1x2,0) + isnull(stake_SingleTeamOU,0)) = 0   
   then 1 else (isnull(stake_1sthdp,0) + isnull(stake_hdp,0) + isnull(stake_1stou,0) +isnull(stake_ou,0) +  +isnull(stake_1x2,0) +  +isnull(stake_1st1x2,0) + isnull(stake_oe,0) + isnull(stake_1stoe,0) + isnull(stake_1stNoOfCorners,0) + isnull(stake_NoOfCorners,0) + isnull(stake_15minhdp,0) + isnull(stake_15minOU,0) + isnull(stake_15min1x2,0)  + isnull(stake_1stTotalBookings,0) + isnull(stake_TotalBookings,0) + isnull(stake_NextCorner,0)
		+  isnull(stake_NextBooking,0) + isnull(stake_15minCorners,0) + isnull(stake_15minTotalBookings,0) + isnull(stake_10minHdp,0) + isnull(stake_10minOU,0) + isnull(stake_10min1x2,0) + isnull(stake_SingleTeamOU,0)) end ) as overall_margin ,  
   
 bet_hdp, bet_ou, bet_1sthdp, bet_1stou, bet_1x2, bet_1st1x2, bet_oe, bet_1stoe, bet_1stNoOfCorners, bet_NoOfCorners, bet_15minhdp, bet_15minOU, bet_15min1x2, bet_1stTotalBookings, bet_TotalBookings,bet_NextCorner,bet_NextBooking,
		bet_NextBooking, bet_15minCorners, bet_15minTotalBookings, bet_10minHdp, bet_10minOU, bet_10min1x2, bet_SingleTeamOU,
 bet_hdp + bet_ou + bet_1x2 + bet_oe + bet_1sthdp + bet_1stou + bet_1st1x2 + bet_1stoe +  bet_NoOfCorners + bet_1stNoOfCorners + bet_15minhdp + bet_15minOU + bet_15min1x2 + bet_1stTotalBookings + bet_TotalBookings +bet_NextCorner 
		+ bet_NextBooking + bet_15minCorners + bet_15minTotalBookings + bet_10minHdp + bet_10minOU + bet_10min1x2 + bet_SingleTeamOU as overall_livebet  
   
 from   
 (  
  
   select cm.custid,cm.username,um.nMatch as matchno, Major, Minor1, Minor2, Minor3, Others,
   
   --turn over: hdp, ou, ht hdp, ht ou, 1x2, 1st1x2, ng    
        
     sum(case when b.bettype=1 and OUtype = 0 then stake else 0 end) as stake_hdp,  
    sum(case when b.bettype=2 then stake else 0 end) as stake_oe,              
    sum(case when b.bettype=3 and OUtype = 0 then stake else 0 end) as stake_ou,  
    sum(case when (b.bettype=5 or b.bettype=124) and OUtype = 0 then stake else 0 end) as stake_1x2, 
    sum(case when b.bettype=7 THEN stake else 0 end) as stake_1sthdp,  
    sum(case when b.bettype=12  then stake else 0 end) as stake_1stoe, 
    sum(case when b.bettype=8 and OUtype = 0 then stake else 0 end) as stake_1stou,
    sum(case when (b.bettype=15 or b.bettype=125) and OUtype = 0 then stake else 0 end) as stake_1st1x2,    
    sum((case when b.bettype = 8 and OUtype = 1 then stake else 0 end)) as stake_1stNoOfCorners,  
    sum((case when b.bettype = 3 and OUtype = 1 then stake else 0 end)) as stake_NoOfCorners,  
    sum((case when b.bettype = 1 and OUtype = 2 then stake else 0 end)) as stake_15minhdp,  
    sum((case when b.bettype = 3 and OUtype = 2 then stake else 0 end)) as stake_15minOU,  
	sum((case when b.bettype = 5 and OUtype = 2 then stake else 0 end)) as stake_15min1x2,          
    --1st Total Bookings + Total Bookings
    sum((case when b.bettype = 8 and OUtype = 3 then stake else 0 end)) as stake_1stTotalBookings,        
    sum((case when b.bettype = 3 and OUtype = 3 then stake else 0 end)) as stake_TotalBookings,  
    sum((case when b.bettype =1 and OUtype = 4 then stake else 0 end)) as stake_NextCorner,
    sum((case when b.bettype =1 and OUtype = 5 then stake else 0 end)) as stake_NextBooking,  
    sum((case when b.bettype =3 and OUtype = 6 then stake else 0 end)) as stake_15minCorners,
    sum((case when b.bettype =3 and OUtype = 7 then stake else 0 end)) as stake_15minTotalBookings,
    sum((case when b.bettype =1 and OUtype = 8 then stake else 0 end)) as stake_10minHdp,
    sum((case when b.bettype =3 and OUtype = 8 then stake else 0 end)) as stake_10minOU,
    sum((case when b.bettype =5 and OUtype = 8 then stake else 0 end)) as stake_10min1x2,
    sum((case when  OUtype = 9 and b.bettype IN (3,8) then stake else 0 end)) as stake_SingleTeamOU,
  
   --Winlost  
    sum(case when b.bettype=1 and OUtype = 0 then winlost else 0 end) as winlost_hdp,  
    sum(case when b.bettype=2 then winlost else 0 end) as winlost_oe,  
    sum(case when b.bettype=3  and OUtype = 0 then winlost else 0 end) as winlost_ou,  
    sum(case when (b.bettype=5 or b.bettype=124) AND OUtype = 0 then winlost else 0 end) as winlost_1x2,  
    sum(case when b.bettype=7 then winlost else 0 end) as winlost_1sthdp,  
    sum(case when b.bettype=8 and OUtype = 0 then winlost else 0 end) as winlost_1stou,  
    sum(case when b.bettype=12 then winlost else 0 end) as winlost_1stoe,  
    sum(case when (b.bettype=15 or b.bettype=125) AND OUtype = 0 then winlost else 0 end) as winlost_1st1x2,  
   -- -sum(case when b.bettype=22 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_ng,  
    sum(case when b.bettype=8 and OUtype = 1 then winlost else 0 end) as winlost_1stNoOfCorners,  
    sum(case when b.bettype=3 and OUtype = 1 then winlost else 0 end) as winlost_NoOfCorners,  
    sum(case when b.bettype=1 and OUtype = 2 then winlost else 0 end) as winlost_15minhdp,  
    sum(case when b.bettype=3 and OUtype = 2 then winlost else 0 end) as winlost_15minOU,  
    sum(case when b.bettype=5 and OUtype = 2 then winlost else 0 end) as winlost_15min1x2,  
    --1st No.of Yellow Cards + No.of Yellow Cards  
    sum(case when b.bettype=8 and OUtype = 3 then winlost else 0 end) as winlost_1stTotalBookings,  
    sum(case when b.bettype=3 and OUtype = 3 then winlost else 0 end) as winlost_TotalBookings,  
    sum(case when b.bettype =1 and OUtype = 4 then winlost else 0 end) as winlost_NextCorner,  
    sum(case when b.bettype =1 and OUtype = 5 then winlost else 0 end) as winlost_NextBooking,  
    sum(case when b.bettype =3 and OUtype = 6 then winlost else 0 end) as winlost_15minCorners,  
    sum(case when b.bettype =3 and OUtype = 7 then winlost else 0 end) as winlost_15minTotalBookings,  
    sum(case when b.bettype =1 and OUtype = 8 then winlost else 0 end) as winlost_10minHdp,  
    sum(case when b.bettype =3 and OUtype = 8 then winlost else 0 end) as winlost_10minOU,  
    sum(case when b.bettype =5 and OUtype = 8 then winlost else 0 end) as winlost_10min1x2,  
    sum(case when OUtype = 9 and b.bettype IN (3,8) then winlost else 0 end) as winlost_SingleTeamOU,  
   
   --Commission  
    sum(case when b.bettype=1 and OUtype = 0 then comm else 0 end) as comm_hdp,  
    sum(case when b.bettype=2 then comm else 0 end) as comm_oe,  
    sum(case when b.bettype=3  and OUtype = 0 then comm else 0 end) as comm_ou,  
    sum(case when (b.bettype=5 or b.bettype=124) and OUtype = 0 then comm else 0 end) as comm_1x2,  
    sum(case when b.bettype=7 then comm else 0 end) as comm_1sthdp,  
    sum(case when b.bettype=8 and OUtype = 0 then comm else 0 end) as comm_1stou,  
    sum(case when b.bettype=12 then comm else 0 end) as comm_1stoe,  
    sum(case when (b.bettype=15 or b.bettype=125) and OUtype = 0 then comm else 0 end) as comm_1st1x2,  
    --sum(case when b.bettype=22 then scomm*b.virtualrate else 0 end) as comm_ng,  
    sum(case when b.bettype=8 and OUtype = 1  then comm else 0 end) as comm_1stNoOfCorners,  
    sum(case when b.bettype=3 and OUtype = 1  then comm else 0 end) as comm_NoOfCorners,  
    sum(case when b.bettype=1 and OUtype = 2 then comm else 0 end) as comm_15minhdp,  
    sum(case when b.bettype=3 and OUtype = 2 then comm else 0 end) as comm_15minOU,  
    sum(case when b.bettype=5 and OUtype = 2 then comm else 0 end) as comm_15min1x2,  
    --1st No.of Yellow Cards + No.of Yellow Cards  
    sum(case when b.bettype=8 and OUtype = 3 then comm else 0 end) as comm_1stTotalBookings,  
    sum(case when b.bettype=3 and OUtype = 3  then comm else 0 end) as comm_TotalBookings,  
    sum(case when b.bettype =1 and OUtype = 4  then comm else 0 end) as comm_NextCorner,
    sum(case when b.bettype =1 and OUtype = 5  then comm else 0 end) as comm_NextBooking,
    sum(case when b.bettype =3 and OUtype = 6  then comm else 0 end) as comm_15minCorners,
    sum(case when b.bettype =3 and OUtype = 7  then comm else 0 end) as comm_15minTotalBookings,
    sum(case when b.bettype =1 and OUtype = 8  then comm else 0 end) as comm_10minHdp,
    sum(case when b.bettype =3 and OUtype = 8  then comm else 0 end) as comm_10minOU,
    sum(case when b.bettype =5 and OUtype = 8  then comm else 0 end) as comm_10min1x2,
    sum(case when OUtype = 9 and b.bettype IN (3,8) then comm else 0 end) as comm_SingleTeamOU,  
      
   --Live BetCount      
    sum(case when b.bettype = 1 and OUtype = 0 then bet else 0 end) as bet_hdp,  
    sum(case when b.bettype = 2 then bet else 0 end) as bet_oe,  
    sum(case when b.bettype = 3 and OUtype = 0 then bet else 0 end) as bet_ou,  
    sum(case when b.bettype = 7 then bet else 0 end) as bet_1sthdp,  
    sum(case when b.bettype = 8 and OUtype = 0 then bet else 0 end) as bet_1stou,  
    sum(case when (b.bettype=5 or b.bettype=124) and OUtype = 0 then bet else 0 end) as bet_1x2,  
    sum(case when b.bettype =12 then bet else 0 end) as bet_1stoe,  
    sum(case when (b.bettype=15 or b.bettype=125) and OUtype = 0 then bet else 0 end) as bet_1st1x2,  
    sum(case when b.bettype = 8 and OUtype =1 then bet else 0 end) as bet_1stNoOfCorners,  
    sum(case when b.bettype = 3 and OUType =1 then bet else 0 end) as bet_NoOfCorners,  
    sum(case when b.bettype = 1 and OUType =2 then bet else 0 end) as bet_15minhdp,  
    sum(case when b.bettype = 3 and OUType =2 then bet else 0 end) as bet_15minOU,  
    sum(case when b.bettype = 5 and OUType =2 then bet else 0 end) as bet_15min1x2,  
    sum(case when b.bettype = 8 and OUType = 3 then bet else 0 end) as bet_1stTotalBookings,  
    sum(case when b.bettype = 3 and OUType = 3 then bet else 0 end) as bet_TotalBookings,  
    sum(case when b.bettype =1 and OUtype = 4 then bet else 0 end) as bet_NextCorner,
    sum(case when b.bettype =1 and OUtype = 5 then bet else 0 end) as bet_NextBooking,
    sum(case when b.bettype =3 and OUtype = 6 then bet else 0 end) as bet_15minCorners,
    sum(case when b.bettype =3 and OUtype = 7 then bet else 0 end) as bet_15minTotalBookings,
    sum(case when b.bettype =1 and OUtype = 8 then bet else 0 end) as bet_10minHdp,
    sum(case when b.bettype =3 and OUtype = 8 then bet else 0 end) as bet_10minOU,
    sum(case when b.bettype =5 and OUtype = 8 then bet else 0 end) as bet_10min1x2,
    sum(case when OUtype = 9 and b.bettype IN (3,8) then bet else 0 end) as bet_SingleTeamOU
   from #bettrans b 
    inner join @temp_daao cm on b.matchid=cm.matchid and (b.bettype = cm.bettype  or (b.bettype = 124 AND cm.BetType = 5) OR (b.bettype = 125 AND cm.BetType = 15))
                inner join #userMatch um on um.custid=cm.custid     
   group by cm.username,cm.custid,um.nMatch , Major, Minor1, Minor2, Minor3, Others 
   UNION ALL  
   select 0, '(Unassigned)',ISNULL(@countMajorOrphan,0) + ISNULL(@countMinor1Orphan,0) + ISNULL(@countMinor2Orphan,0) + ISNULL(@countMinor3Orphan,0) + ISNULL(@countOthersOrphan ,0) as matchno, ISNULL(@countMajorOrphan,0) Major, ISNULL(@countMinor1Orphan,0), ISNULL(@countMinor2Orphan,0), ISNULL(@countMinor3Orphan,0), ISNULL(@countOthersOrphan ,0),
     
   --turn over: hdp, ou, ht hdp, ht ou, 1x2, 1st1x2, ng    
        
    sum(case when b.bettype=1 and OUtype = 0 then stake else 0 end) as stake_hdp,  
    sum(case when b.bettype=2 then stake else 0 end) as stake_oe,              
    sum(case when b.bettype=3 and OUtype = 0 then stake else 0 end) as stake_ou,  
    sum(case when (b.bettype=5 or b.bettype=124) and OUtype = 0 then stake else 0 end) as stake_1x2, 
    sum(case when b.bettype=7 THEN stake else 0 end) as stake_1sthdp,  
    sum(case when b.bettype=12  then stake else 0 end) as stake_1stoe, 
    sum(case when b.bettype=8 and OUtype = 0 then stake else 0 end) as stake_1stou,
    sum(case when (b.bettype=15 or b.bettype=125) and OUtype = 0 then stake else 0 end) as stake_1st1x2,    
    sum((case when b.bettype = 8 and OUtype = 1 then stake else 0 end)) as stake_1stNoOfCorners,  
    sum((case when b.bettype = 3 and OUtype = 1 then stake else 0 end)) as stake_NoOfCorners,  
    sum((case when b.bettype = 1 and OUtype = 2 then stake else 0 end)) as stake_15minhdp,  
    sum((case when b.bettype = 3 and OUtype = 2 then stake else 0 end)) as stake_15minOU,  
	sum((case when b.bettype = 5 and OUtype = 2 then stake else 0 end)) as stake_15min1x2,          
    --1st Total Bookings + Total Bookings
    sum((case when b.bettype = 8 and OUtype = 3 then stake else 0 end)) as stake_1stTotalBookings,        
    sum((case when b.bettype = 3 and OUtype = 3 then stake else 0 end)) as stake_TotalBookings,  
    sum((case when b.bettype =1 and OUtype = 4 then stake else 0 end)) as stake_NextCorner,
    sum((case when b.bettype =1 and OUtype = 5 then stake else 0 end)) as stake_NextBooking,  
    sum((case when b.bettype =3 and OUtype = 6 then stake else 0 end)) as stake_15minCorners,
    sum((case when b.bettype =3 and OUtype = 7 then stake else 0 end)) as stake_15minTotalBookings,
    sum((case when b.bettype =1 and OUtype = 8 then stake else 0 end)) as stake_10minHdp,
    sum((case when b.bettype =3 and OUtype = 8 then stake else 0 end)) as stake_10minOU,
    sum((case when b.bettype =5 and OUtype = 8 then stake else 0 end)) as stake_10min1x2,
    sum((case when  OUtype = 9 and b.bettype IN (3,8) then stake else 0 end)) as stake_SingleTeamOU,
  
   --Winlost  
    sum(case when b.bettype=1 and OUtype = 0 then winlost else 0 end) as winlost_hdp,  
    sum(case when b.bettype=2 then winlost else 0 end) as winlost_oe,  
    sum(case when b.bettype=3  and OUtype = 0 then winlost else 0 end) as winlost_ou,  
    sum(case when (b.bettype=5 or b.bettype=124) AND OUtype = 0 then winlost else 0 end) as winlost_1x2,  
    sum(case when b.bettype=7 then winlost else 0 end) as winlost_1sthdp,  
    sum(case when b.bettype=8 and OUtype = 0 then winlost else 0 end) as winlost_1stou,  
    sum(case when b.bettype=12 then winlost else 0 end) as winlost_1stoe,  
    sum(case when (b.bettype=15 or b.bettype=125) AND OUtype = 0 then winlost else 0 end) as winlost_1st1x2,  
   -- -sum(case when b.bettype=22 then (winlost-actual_stake + awinlost+mwinlost+swinlost)*b.virtualrate else 0 end) as winlost_ng,  
    sum(case when b.bettype=8 and OUtype = 1 then winlost else 0 end) as winlost_1stNoOfCorners,  
    sum(case when b.bettype=3 and OUtype = 1 then winlost else 0 end) as winlost_NoOfCorners,  
    sum(case when b.bettype=1 and OUtype = 2 then winlost else 0 end) as winlost_15minhdp,  
    sum(case when b.bettype=3 and OUtype = 2 then winlost else 0 end) as winlost_15minOU,  
    sum(case when b.bettype=5 and OUtype = 2 then winlost else 0 end) as winlost_15min1x2,  
    --1st No.of Yellow Cards + No.of Yellow Cards  
    sum(case when b.bettype=8 and OUtype = 3 then winlost else 0 end) as winlost_1stTotalBookings,  
    sum(case when b.bettype=3 and OUtype = 3 then winlost else 0 end) as winlost_TotalBookings,  
    sum(case when b.bettype =1 and OUtype = 4 then winlost else 0 end) as winlost_NextCorner,  
    sum(case when b.bettype =1 and OUtype = 5 then winlost else 0 end) as winlost_NextBooking,  
    sum(case when b.bettype =3 and OUtype = 6 then winlost else 0 end) as winlost_15minCorners,  
    sum(case when b.bettype =3 and OUtype = 7 then winlost else 0 end) as winlost_15minTotalBookings,  
    sum(case when b.bettype =1 and OUtype = 8 then winlost else 0 end) as winlost_10minHdp,  
    sum(case when b.bettype =3 and OUtype = 8 then winlost else 0 end) as winlost_10minOU,  
    sum(case when b.bettype =5 and OUtype = 8 then winlost else 0 end) as winlost_10min1x2,  
    sum(case when OUtype = 9 and b.bettype IN (3,8) then winlost else 0 end) as winlost_SingleTeamOU,  
   
   --Commission  
    sum(case when b.bettype=1 and OUtype = 0 then comm else 0 end) as comm_hdp,  
    sum(case when b.bettype=2 then comm else 0 end) as comm_oe,  
    sum(case when b.bettype=3  and OUtype = 0 then comm else 0 end) as comm_ou,  
    sum(case when (b.bettype=5 or b.bettype=124) and OUtype = 0 then comm else 0 end) as comm_1x2,  
    sum(case when b.bettype=7 then comm else 0 end) as comm_1sthdp,  
    sum(case when b.bettype=8 and OUtype = 0 then comm else 0 end) as comm_1stou,  
    sum(case when b.bettype=12 then comm else 0 end) as comm_1stoe,  
    sum(case when (b.bettype=15 or b.bettype=125) and OUtype = 0 then comm else 0 end) as comm_1st1x2,  
    --sum(case when b.bettype=22 then scomm*b.virtualrate else 0 end) as comm_ng,  
    sum(case when b.bettype=8 and OUtype = 1  then comm else 0 end) as comm_1stNoOfCorners,  
    sum(case when b.bettype=3 and OUtype = 1  then comm else 0 end) as comm_NoOfCorners,  
    sum(case when b.bettype=1 and OUtype = 2 then comm else 0 end) as comm_15minhdp,  
    sum(case when b.bettype=3 and OUtype = 2 then comm else 0 end) as comm_15minOU,  
    sum(case when b.bettype=5 and OUtype = 2 then comm else 0 end) as comm_15min1x2,  
    --1st No.of Yellow Cards + No.of Yellow Cards  
    sum(case when b.bettype=8 and OUtype = 3 then comm else 0 end) as comm_1stTotalBookings,  
    sum(case when b.bettype=3 and OUtype = 3  then comm else 0 end) as comm_TotalBookings,  
    sum(case when b.bettype =1 and OUtype = 4  then comm else 0 end) as comm_NextCorner,
    sum(case when b.bettype =1 and OUtype = 5  then comm else 0 end) as comm_NextBooking,
    sum(case when b.bettype =3 and OUtype = 6  then comm else 0 end) as comm_15minCorners,
    sum(case when b.bettype =3 and OUtype = 7  then comm else 0 end) as comm_15minTotalBookings,
    sum(case when b.bettype =1 and OUtype = 8  then comm else 0 end) as comm_10minHdp,
    sum(case when b.bettype =3 and OUtype = 8  then comm else 0 end) as comm_10minOU,
    sum(case when b.bettype =5 and OUtype = 8  then comm else 0 end) as comm_10min1x2,
    sum(case when OUtype = 9 and b.bettype IN (3,8) then comm else 0 end) as comm_SingleTeamOU,  
      
   --Live BetCount      
    sum(case when b.bettype = 1 and OUtype = 0 then bet else 0 end) as bet_hdp,  
    sum(case when b.bettype = 2 then bet else 0 end) as bet_oe,  
    sum(case when b.bettype = 3 and OUtype = 0 then bet else 0 end) as bet_ou,  
    sum(case when b.bettype = 7 then bet else 0 end) as bet_1sthdp,  
    sum(case when b.bettype = 8 and OUtype = 0 then bet else 0 end) as bet_1stou,  
    sum(case when (b.bettype=5 or b.bettype=124) and OUtype = 0 then bet else 0 end) as bet_1x2,  
    sum(case when b.bettype =12 then bet else 0 end) as bet_1stoe,  
    sum(case when (b.bettype=15 or b.bettype=125) and OUtype = 0 then bet else 0 end) as bet_1st1x2,  
    sum(case when b.bettype = 8 and OUtype =1 then bet else 0 end) as bet_1stNoOfCorners,  
    sum(case when b.bettype = 3 and OUType =1 then bet else 0 end) as bet_NoOfCorners,  
    sum(case when b.bettype = 1 and OUType =2 then bet else 0 end) as bet_15minhdp,  
    sum(case when b.bettype = 3 and OUType =2 then bet else 0 end) as bet_15minOU,  
    sum(case when b.bettype = 5 and OUType =2 then bet else 0 end) as bet_15min1x2,  
    sum(case when b.bettype = 8 and OUType = 3 then bet else 0 end) as bet_1stTotalBookings,  
    sum(case when b.bettype = 3 and OUType = 3 then bet else 0 end) as bet_TotalBookings,  
    sum(case when b.bettype =1 and OUtype = 4 then bet else 0 end) as bet_NextCorner,
    sum(case when b.bettype =1 and OUtype = 5 then bet else 0 end) as bet_NextBooking,
    sum(case when b.bettype =3 and OUtype = 6 then bet else 0 end) as bet_15minCorners,
    sum(case when b.bettype =3 and OUtype = 7 then bet else 0 end) as bet_15minTotalBookings,
    sum(case when b.bettype =1 and OUtype = 8 then bet else 0 end) as bet_10minHdp,
    sum(case when b.bettype =3 and OUtype = 8 then bet else 0 end) as bet_10minOU,
    sum(case when b.bettype =5 and OUtype = 8 then bet else 0 end) as bet_10min1x2,
    sum(case when OUtype = 9 and b.bettype IN (3,8) then bet else 0 end) as bet_SingleTeamOU
      
   from #bettrans b    
    inner join @temp_daao cm on b.matchid=cm.matchid and cm.bettype = 0     
 ) as a  
 order by username  
    drop table #userMatch  
END  

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_TraderPerformanceSum] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_TraderPerformanceSum] TO [vnteam]