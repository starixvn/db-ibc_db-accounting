DECLARE @UserName varchar(50)
SELECT @UserName = 

-------------------
DECLARE @BalanceUpDay SMALLDATETIME, @MoveBetsDay SMALLDATETIME  
SELECT @BalanceUpDay = winlostdate FROM Bettrans WITH(NOLOCK) WHERE bettype = 100 and matchid = 0  
SELECT @MoveBetsDay = max(winlostdate) FROM Bettrans14 WITH(NOLOCK)  

-- General information
declare @CustID int,
	@Creatdate datetime,
	@BetCount int,
	@BetCnt_Live int,
	@betCnt_Dead int,
	@BetWon int,	
	@PercentageWon money,
	@BetsPerDay money,
	@TurnOver money,
	@AvgBetAmt money,
	@TotalDays int
select @CustID = CustID, @Creatdate = creatdate
from Customer with(nolock)
where UserName = @UserName

SELECT @TotalDays = datediff(d, @Creatdate, CURRENT_TIMESTAMP)
------------------- @TurnOver
select @turnover = isnull(sum(stake),0) 
from bettrans with(nolock)
where custid=@CustID and ruben=1 and status not in ('running','waiting','VOID', 'REJECT') and bettype < 99

select @turnover = @turnover + isnull(sum(stake),0)
from bettrans14 with(nolock)
where custid=@CustID and status not in ('VOID', 'REJECT') and bettype < 99 AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay

select @turnover = @turnover +  isnull(sum(stake),0)
from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
where custid=@CustID and status not in ('VOID', 'REJECT') and bettype < 99

------------------- BET COUNT
CREATE TABLE #Temp(betCount int, W int, L int, D int, isLive bit)
INSERT INTO #Temp
select count(b.transid), 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	b.liveindicator
from bettrans b with(nolock)  
where custid=@CustID and bettype < 99
	AND winlostdate > @MoveBetsDay
group by liveindicator

INSERT INTO #Temp
select count(b.transid), 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),
	b.liveindicator
from bettrans14 b with(nolock)  
where custid=@CustID and bettype < 99
	 AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
group by liveindicator

INSERT INTO #Temp
select count(b.transid), 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),
	b.liveindicator
from DB06.bodb_archive.dbo.bettrans_bk b with(nolock)  
where custid=@CustID and bettype < 99
group by liveindicator

select @BetCount = sum(betcount) from #Temp
------------------- Win (%)
select @BetCount = sum(betCount), @BetWon = sum(W) from #Temp

DECLARE @W_live int, @L_live int, @D_live int, @W_dead int, @L_dead int, @D_dead int

select @BetCnt_Live = sum(betCount),
	@W_live = sum(w),
	@L_live = sum(l),
	@D_live = sum(d)
from #Temp 
where isLive = 1

select @BetCnt_Dead = sum(betCount) ,
	@W_Dead = sum(w),
	@L_Dead = sum(l),
	@D_Dead = sum(d)
from #Temp 
where isLive = 0 

SELECT @PercentageWon = CASE WHEN @BetCount>0 THEN cast(@BetWon as float)*100 / @BetCount ELSE 0 END
------------------- Bets Per day,  AVG bet Amt
SELECT @BetsPerDay = CASE WHEN @TotalDays>0 THEN @BetCount / @TotalDays ELSE 0 END
SELECT @AvgBetAmt = CASE WHEN @BetCount>0 THEN cast(@TurnOver as float) / @BetCount ELSE 0 END
--select * from #Temp
------------------- 
SELECT @BetsPerDay BetsPerDay,
	isnull(@BetCnt_Live,0) BetCnt_live,
	ROUND(CASE WHEN @BetCnt_Live>0 THEN cast(@W_live as float)*100 / @BetCnt_Live ELSE 0 END,0) 'Won (%)' ,
	ROUND(CASE WHEN @BetCnt_Live>0 THEN cast(@L_live as float)*100 / @BetCnt_Live ELSE 0 END,0) 'Lose (%)',
	ROUND(CASE WHEN @BetCnt_Live>0 THEN cast(@D_live as float)*100 / @BetCnt_Live ELSE 0 END,0) 'Draw (%)',
	isnull(@BetCnt_dead,0) BetCnt_dead,																   
	ROUND(CASE WHEN @BetCnt_Dead>0 THEN cast(@W_Dead as float)*100 / @BetCnt_Dead ELSE 0 END,0) 'Won (%)' ,
	ROUND(CASE WHEN @BetCnt_Dead>0 THEN cast(@L_Dead as float)*100 / @BetCnt_Dead ELSE 0 END,0) 'Lose (%)',
	ROUND(CASE WHEN @BetCnt_Dead>0 THEN cast(@D_Dead as float)*100 / @BetCnt_Dead ELSE 0 END,0) 'Draw (%)',
	@Creatdate Creatdate, 
	isnull(@TurnOver,0) TurnOver,	
	isnull(@BetCount,0) BetCount,
	isnull(@AvgBetAmt,0) AvgBetAmt,		
	isnull(@PercentageWon,0) PercentageWon
	
DROP TABLE #Temp


------------------- 
------------------- 
--LEAGUEs
CREATE TABLE #TempLeagues (LeagueID int, betCount int, LeagueName nvarchar(100), W int, L int, D int, isLive bit, rTurnOver money, Winloss money)
INSERT INTO #TempLeagues (LeagueID, BetCount, LeagueName, W, L, D, rTurnOver, Winloss, IsLive)
select l.leagueID, 
	count(b.matchid), 
	l.leaguename, 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	sum(case when b.status not in ('running', 'waiting', 'VOID', 'REJECT', 'DRAW') and b.ruben = 1 and b.bettype<99 then isnull(b.stake,0) else 0 end),
	sum(case when b.status not in ('VOID', 'REJECT') and b.ruben=1 and b.bettype<99 then isnull(b.winlost-b.actual_stake,0) else 0 end),
	b.liveindicator as IsLive
from bettrans b with(nolock)
 inner join match m with(nolock) on b.matchid = m.matchid
 inner join league l with(nolock) on m.leagueID = l.leagueID
where custid=@CustID
group by l.leagueID, l.leaguename, liveindicator
order by 1
----

INSERT INTO #TempLeagues (LeagueID, BetCount, LeagueName, W, L, D, rTurnOver, Winloss, IsLive)
select l.leagueID, 
	count(b.matchid), 
	l.leaguename, 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	sum(case when b.status not in ('VOID', 'REJECT', 'DRAW') and b.ruben = 1 and b.bettype<99 then isnull(b.stake,0) else 0 end),
	sum(case when b.status not in ('VOID', 'REJECT') and b.ruben=1 and b.bettype<99 then isnull(b.winlost-b.actual_stake,0) else 0 end),
	b.liveindicator as IsLive
from bettrans b with(nolock)
 inner join bettransM bM with(nolock) on b.refno=bm.refno
 inner join match m with(nolock) on bm.matchid = m.matchid
 inner join league l with(nolock) on m.leagueID = l.leagueID
where b.custid = @CustID
 and b.matchid = 0
group by l.leagueID, l.leaguename, b.liveindicator
order by 1
-------------------

INSERT INTO #TempLeagues (LeagueID, BetCount, LeagueName, W, L, D, rTurnOver, Winloss, IsLive)
select l.leagueID, 
	count(b.matchid), 
	l.leaguename, 	
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),
	sum(case when b.status not in ('VOID', 'REJECT', 'DRAW') and b.ruben = 1 and b.bettype<99 then isnull(b.stake,0) else 0 end),
	sum(case when b.status not in ('VOID', 'REJECT') and b.ruben=1 and b.bettype<99 then isnull(b.winlost-b.actual_stake,0) else 0 end),
	b.liveindicator as IsLive
from bettrans14 b with(nolock)
 inner join match14 m with(nolock) on b.matchid = m.matchid
 inner join league l with(nolock) on m.leagueID = l.leagueID
where custid=@CustID
	 AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
group by l.leagueID, l.leaguename, b.liveindicator
order by 1
-------------------

INSERT INTO #TempLeagues (LeagueID, BetCount, LeagueName, W, L, D, rTurnOver, Winloss, IsLive)
select l.leagueID, 
	count(b.matchid), 
	l.leaguename, 	
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	sum(case when b.status not in ('VOID', 'REJECT', 'DRAW') and b.ruben = 1 and b.bettype<99 then isnull(b.stake,0) else 0 end),
	sum(case when b.status not in ('VOID', 'REJECT') and b.ruben=1 and b.bettype<99 then isnull(b.winlost-b.actual_stake,0) else 0 end),
	b.liveindicator as IsLive
from bettrans14 b with(nolock)
 inner join bettransM14 bm with(nolock) on b.refno=bm.refno
 inner join match14 m with(nolock) on bm.matchid = m.matchid
 inner join league l with(nolock) on m.leagueID = l.leagueID
where b.custid = @CustID
	and b.matchid = 0
	AND b.Winlostdate Between @BalanceUpDay AND @MoveBetsDay
group by l.leagueID, l.leaguename, b.liveindicator
order by 1
-------------------

INSERT INTO #TempLeagues (LeagueID, BetCount, LeagueName, W, L, D, rTurnOver, Winloss, IsLive)
select l.leagueID, 
	count(b.matchid), 
	l.leaguename, 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	sum(case when b.status not in ('VOID', 'REJECT', 'DRAW') and b.ruben = 1 and b.bettype<99 then isnull(b.stake,0) else 0 end),
	sum(case when b.status not in ('VOID', 'REJECT') and b.ruben=1 and b.bettype<99 then isnull(b.winlost-b.actual_stake,0) else 0 end),
	b.liveindicator as IsLive
from DB06.bodb_archive.dbo.bettrans_bk b with(nolock)
 inner join DB06.bodb_archive.dbo.match_bk m with(nolock) on b.matchid = m.matchid
 inner join league l with(nolock) on m.leagueID = l.leagueID
where custid=@CustID
group by l.leagueID, l.leaguename, b.liveindicator
order by 1
-------------------

INSERT INTO #TempLeagues (LeagueID, BetCount, LeagueName, W, L, D, rTurnOver, Winloss, IsLive)
select l.leagueID, 
	count(b.matchid), 
	l.leaguename, 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	sum(case when b.status not in ('VOID', 'REJECT', 'DRAW') and b.ruben = 1 and b.bettype<99 then isnull(b.stake,0) else 0 end),
	sum(case when b.status not in ('VOID', 'REJECT') and b.ruben=1 and b.bettype<99 then isnull(b.winlost-b.actual_stake,0) else 0 end),
	b.liveindicator as IsLive
from DB06.bodb_archive.dbo.bettrans_bk b with(nolock)
 inner join DB06.bodb_archive.dbo.bettransM bm with(nolock) on b.refno=bm.refno
 inner join DB06.bodb_archive.dbo.match_bk m with(nolock) on bm.matchid = m.matchid
 inner join league l with(nolock) on m.leagueID = l.leagueID
where b.custid = @CustID
 and b.matchid = 0
group by l.leagueID, l.leaguename, b.liveindicator
order by 1

-------------------

select 
	case when a.leagueID is null then b.leagueID else a.leagueID end,
	isnull(betCount,0)+isnull(betCount_L,0) as BetCount_ALL, 
	case when a.leaguename is null then b.leaguename else a.leaguename end LeagueName,	
	isnull(betCount_L,0) BetCnt_Live,
	round(cast(isnull(PercentageW_L,0) as float)*100 / case when isnull(betCount_L,0) = 0 then 1 else isnull(betCount_L,0) end, 0) 'Won (%)' ,
	round(cast(isnull(PercentageL_L,0) as float)*100 / case when isnull(betCount_L,0) = 0 then 1 else isnull(betCount_L,0) end, 0) 'Lose (%)',
	round(cast(isnull(PercentageD_L,0) as float)*100 / case when isnull(betCount_L,0) = 0 then 1 else isnull(betCount_L,0) end, 0) 'Draw (%)',
	isnull(betCount,0) BetCnt, 
	round(cast(isnull(PercentageW,0) as float)*100 / case when isnull(betCount,0) = 0 then 1 else isnull(betCount,0) end, 0) 'Won (%)' ,
	round(cast(isnull(PercentageL*100,0) as float) / case when isnull(betCount,0) = 0 then 1 else isnull(betCount,0) end, 0) 'Lose (%)',
	round(cast(isnull(PercentageD*100,0) as float) / case when isnull(betCount,0) = 0 then 1 else isnull(betCount,0) end, 0) 'Draw (%)',
	isnull(rTurnOver,0)+isnull(rTurnOver_live,0) as rTurnOver,
	isnull(winloss,0)+isnull(winloss_live,0) as winloss,
	Round((isnull(winloss,0)+isnull(winloss_live,0))*100/case when (isnull(rTurnOver,0)+isnull(rTurnOver_live,0)) = 0 then 1 else (isnull(rTurnOver,0)+isnull(rTurnOver_live,0)) end, 0) as WinPercentage
from
(select leagueID,
	leaguename,
	sum(isnull(betCount, 0)) as betCount,	
	SUM(W) PercentageW,
	SUM(L) PercentageL,
	SUM(D) PercentageD,
	sum(isnull(rTurnOver, 0)) as rTurnOver,
	sum(isnull(winloss, 0)) as winloss
FROM #TempLeagues
WHERE isLIVE=0
GROUP BY leagueID, leaguename
) a
FULL OUTER JOIN
(
select leagueID,
	leaguename,	
	sum(isnull(betCount, 0)) as betCount_L,	
	SUM(W) PercentageW_L,
	SUM(L) PercentageL_L,
	SUM(D) PercentageD_L,
	sum(isnull(rTurnOver, 0)) as rTurnOver_live,
	sum(isnull(winloss, 0)) as winloss_live
FROM #TempLeagues
WHERE isLIVE=1
GROUP BY leagueID, leaguename
)b on a.leagueID = b.LeagueID

drop table #TempLeagues

------------------- 
------------------- 
--SPORTs
CREATE TABLE #TempSports (SportID int, betCount int, SportName varchar(50), W int, L int, D int, isLive bit)
INSERT INTO #TempSports
select m.sporttype, count(b.matchid), s.sportname, 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	b.liveindicator as IsLive
from bettrans b with(nolock)
	inner join match m with(nolock) on b.matchid = m.matchid 
	inner join sports s with(nolock) on m.sporttype = s.sporttype
where custid=@CustID
group by m.sporttype, s.sportname, b.liveindicator
order by 1


INSERT INTO #TempSports
select m.sporttype, count(b.matchid), s.sportname, 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	b.liveindicator as IsLive
from bettrans b with(nolock)
	inner join bettransM bm with(nolock) on b.refno=bm.refno
	inner join match m with(nolock) on bm.matchid = m.matchid 
	inner join sports s with(nolock) on m.sporttype = s.sporttype
where b.custid=@CustID
group by m.sporttype, s.sportname, b.liveindicator
order by 1
-------------------
INSERT INTO #TempSports
select m.sporttype, count(b.matchid), s.sportname, 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	b.liveindicator as IsLive
from bettrans14 b with(nolock)
	inner join match14 m with(nolock) on b.matchid = m.matchid 
	inner join sports s with(nolock) on m.sporttype = s.sporttype
where custid=@CustID
	AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
group by m.sporttype, s.sportname, b.liveindicator
order by 1

INSERT INTO #TempSports
select m.sporttype, count(b.matchid), s.sportname, 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	b.liveindicator as IsLive
from bettrans14 b with(nolock)
	inner join bettransM14 bm with(nolock) on b.refno=bm.refno
	inner join match14 m with(nolock) on bm.matchid = m.matchid 
	inner join sports s with(nolock) on m.sporttype = s.sporttype
where b.custid=@CustID
	AND b.Winlostdate Between @BalanceUpDay AND @MoveBetsDay
group by m.sporttype, s.sportname, b.liveindicator
-------------------
INSERT INTO #TempSports
select m.sporttype, count(b.matchid), s.sportname, 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	b.liveindicator as IsLive
from DB06.bodb_archive.dbo.bettrans_bk b with(nolock)
	inner join DB06.bodb_archive.dbo.match_bk m with(nolock) on b.matchid = m.matchid 
	inner join sports s with(nolock) on m.sporttype = s.sporttype
where custid=@CustID
group by m.sporttype, s.sportname, b.liveindicator
order by 1

INSERT INTO #TempSports
select m.sporttype, count(b.matchid), s.sportname, 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	b.liveindicator as IsLive
from DB06.bodb_archive.dbo.bettrans_bk b with(nolock)
	inner join DB06.bodb_archive.dbo.bettransM bm with(nolock) on b.refno=bm.refno
	inner join DB06.bodb_archive.dbo.match_bk m with(nolock) on bm.matchid = m.matchid 
	inner join sports s with(nolock) on m.sporttype = s.sporttype
where b.custid=@CustID
group by m.sporttype, s.sportname, b.liveindicator
order by 1

-------------------
select 
	case when a.sportID is null then b.sportID else a.sportID end SportID,
	isnull(betCount,0)+isnull(betCount_L,0) as BetCount_ALL, 
	case when a.sportname is null then b.sportname else a.sportname end SportName,	
	isnull(betCount_L,0) BetCnt_LIVE,
	round(cast(isnull(PercentageW_L,0) as float)*100 / case when isnull(betCount_L,0) = 0 then 1 else isnull(betCount_L,0) end, 0) 'Won (%)' ,
	round(cast(isnull(PercentageL_L,0) as float)*100 / case when isnull(betCount_L,0) = 0 then 1 else isnull(betCount_L,0) end, 0) 'Lose (%)',
	round(cast(isnull(PercentageD_L,0) as float)*100 / case when isnull(betCount_L,0) = 0 then 1 else isnull(betCount_L,0) end, 0) 'Draw (%)',
	isnull(betCount,0) BetCnt, 
	round(cast(isnull(PercentageW,0) as float)*100 / case when isnull(betCount,0) = 0 then 1 else isnull(betCount,0) end, 0) 'Won (%)' ,
	round(cast(isnull(PercentageL*100,0) as float) / case when isnull(betCount,0) = 0 then 1 else isnull(betCount,0) end, 0) 'Lose (%)',
	round(cast(isnull(PercentageD*100,0) as float) / case when isnull(betCount,0) = 0 then 1 else isnull(betCount,0) end, 0) 'Draw (%)'	
from
(select sportID,
	sportname,
	sum(isnull(betCount, 0)) as betCount,	
	SUM(W) PercentageW,
	SUM(L) PercentageL,
	SUM(D) PercentageD	
FROM #TempSports
WHERE isLIVE=0
GROUP BY sportID, sportname
) a
FULL OUTER JOIN
(
select sportID,
	sportname,	
	sum(isnull(betCount, 0)) as betCount_L,	
	SUM(W) PercentageW_L,
	SUM(L) PercentageL_L,
	SUM(D) PercentageD_L
FROM #TempSports
WHERE isLIVE=1
GROUP BY sportID, sportname
)b on a.sportID = b.sportID

drop table #TempSports



------------------- 
------------------- 
--BETTYPEs
CREATE TABLE #TempBTYPEs (bettype int, betCount int, typename varchar(50), W int, L int, D int, isLive bit)

INSERT INTO #TempBTYPEs
select b.bettype, count(b.custid) b, bt.typenamee,	
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	b.liveindicator as IsLive
from bettrans b with(nolock)
 inner join bettype bt with(nolock) on b.bettype = bt.typeid 
where custid=@CustID
	and bettype < 99
group by b.bettype, bt.typenamee, b.liveindicator
order by 1
-------------------

INSERT INTO #TempBTYPEs
select b.bettype, count(b.custid) b, bt.typenamee,
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	b.liveindicator as IsLive
from bettrans14 b with(nolock)
 inner join bettype bt with(nolock) on b.bettype = bt.typeid 
where custid=@CustID
	and bettype < 99
	AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
group by b.bettype, bt.typenamee, b.liveindicator
order by 1
-------------------

INSERT INTO #TempBTYPEs
select b.bettype, count(b.custid) b, bt.typenamee,
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	b.liveindicator as IsLive
from DB06.bodb_archive.dbo.bettrans_bk b with(nolock)
 inner join bettype bt with(nolock) on b.bettype = bt.typeid 
where custid=@CustID
	and bettype < 99
group by b.bettype, bt.typenamee, b.liveindicator
order by 1
-------------------

select 
	case when a.bettype is null then b.bettype else a.bettype end Bettype,
	isnull(betCount,0)+isnull(betCount_L,0) as BetCount_ALL, 
	case when a.typename is null then b.typename else a.typename end TypeName,	
	isnull(betCount_L,0) BetCnt_LIVE,
	round(cast(isnull(PercentageW_L,0) as float)*100 / case when isnull(betCount_L,0) = 0 then 1 else isnull(betCount_L,0) end, 0) 'Won (%)' ,
	round(cast(isnull(PercentageL_L,0) as float)*100 / case when isnull(betCount_L,0) = 0 then 1 else isnull(betCount_L,0) end, 0) 'Lose (%)',
	round(cast(isnull(PercentageD_L,0) as float)*100 / case when isnull(betCount_L,0) = 0 then 1 else isnull(betCount_L,0) end, 0) 'Draw (%)',
	isnull(betCount,0) BetCnt, 
	round(cast(isnull(PercentageW,0) as float)*100 / case when isnull(betCount,0) = 0 then 1 else isnull(betCount,0) end, 0) 'Won (%)' ,
	round(cast(isnull(PercentageL*100,0) as float) / case when isnull(betCount,0) = 0 then 1 else isnull(betCount,0) end, 0) 'Lose (%)',
	round(cast(isnull(PercentageD*100,0) as float) / case when isnull(betCount,0) = 0 then 1 else isnull(betCount,0) end, 0) 'Draw (%)'		
from
(select bettype,
	typename,
	sum(isnull(betCount, 0)) as betCount,	
	SUM(W) PercentageW,
	SUM(L) PercentageL,
	SUM(D) PercentageD	
FROM #TempBTYPEs
WHERE isLIVE=0
GROUP BY bettype, typename
) a
FULL OUTER JOIN
(
select bettype,
	typename,	
	sum(isnull(betCount, 0)) as betCount_L,	
	SUM(W) PercentageW_L,
	SUM(L) PercentageL_L,
	SUM(D) PercentageD_L
FROM #TempBTYPEs
WHERE isLIVE=1
GROUP BY bettype, typename
)b on a.bettype = b.bettype

drop table #TempBTYPEs

--------------------
--------------------
--Weekly statistics
CREATE TABLE #TempWeeklyWL_LIVE (fdate smalldatetime, tdate smalldatetime, W int, L int, D int, BetCount int, rTurnOver money, Winloss money)
CREATE TABLE #TempWeeklyWL (fdate smalldatetime, tdate smalldatetime, W int, L int, D int, BetCount int)

declare @d1 smalldatetime, @d2 smalldatetime
select @d1 = convert(varchar(10),@Creatdate,120)
select @d2 = convert(varchar(10),CURRENT_TIMESTAMP,120)

WHILE @d1 < @d2
BEGIN	
	INSERT INTO #TempWeeklyWL_LIVE values(@d1,dateadd(dd,6,@d1),0,0,0,0,0,0)
	SELECT @d1 = dateadd(dd, 7, @d1)
END
Update #TempWeeklyWL_LIVE set tdate = @d2 where tdate > @d2
INSERT INTO #TempWeeklyWL SELECT fdate,tdate,0,0,0,0 FROM #TempWeeklyWL_LIVE

update #TempWeeklyWL_LIVE 
set rTurnOver = rTurnOver + (select isnull(sum(stake),0)
				from bettrans with(nolock)
				where custid= @CustID
					and ruben=1
					and status not in ('running', 'waiting', 'VOID', 'REJECT', 'DRAW')
					and bettype < 99
					and winlostdate between fdate and tdate					
				),
	BetCount = BetCount + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
				and bettype < 99
				and ruben = 1
				and winlostdate between fdate and tdate
				and liveindicator = 1
				),
	W = W + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'WON'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 1
				),
	L = L + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'LOSE'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 1
				),
	D = D + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'DRAW'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 1
				),
	Winloss = Winloss + (select isnull(sum(winlost-actual_stake),0)
						FROM bettrans with(nolock)
						where custid=@CustID
							and winlostdate between fdate and tdate
							and ruben=1
							and status not in ('VOID', 'REJECT')
							and bettype < 99
				)
-- 14
update #TempWeeklyWL_LIVE 
SET	rturnover =  rturnover + (select isnull(sum(stake),0)
				from bettrans14 with(nolock)
				where custid= @CustID
					and ruben=1
					and status not in ('VOID', 'REJECT', 'DRAW')
					and bettype < 99
					and winlostdate between fdate and tdate
					AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay					
				),
	BetCount = BetCount + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
				and bettype < 99
				and ruben = 1
				and winlostdate between fdate and tdate
				AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
				and liveindicator = 1
				),
	W = W + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'WON'
					and bettype < 99
					and winlostdate between fdate and tdate
					AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
					and liveindicator = 1
				),
	L = L + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'LOSE'
					and bettype < 99
					and winlostdate between fdate and tdate
					AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
					and liveindicator = 1
				),
	D = D + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'DRAW'
					and bettype < 99
					and winlostdate between fdate and tdate
					AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
					and liveindicator = 1
				),
	Winloss = Winloss + (select isnull(sum(winlost-actual_stake),0)
						FROM bettrans14 with(nolock)
						where custid=@CustID
							and winlostdate between fdate and tdate
							and ruben=1
							and status not in ('VOID', 'REJECT')
							and bettype < 99
				)
-- archive
update #TempWeeklyWL_LIVE 
set rturnover = rturnover + (select isnull(sum(stake),0)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid= @CustID
					and ruben=1
					and status not in ('VOID', 'REJECT', 'DRAW')
					and bettype < 99
					and winlostdate between fdate and tdate					
				),
	BetCount = BetCount + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
				and bettype < 99
				and ruben = 1
				and winlostdate between fdate and tdate
				and liveindicator = 1
				),
	W = W + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'WON'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 1
				),
	L = L + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'LOSE'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 1
				),
	D = D + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'DRAW'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 1
				),
	Winloss = Winloss + (select isnull(sum(winlost-actual_stake),0)
						FROM DB06.bodb_archive.dbo.bettrans_bk with(nolock)
						where custid=@CustID
							and winlostdate between fdate and tdate
							and ruben=1
							and status not in ('VOID', 'REJECT')
							and bettype < 99
				)

update #TempWeeklyWL 
set BetCount = BetCount + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
				and bettype < 99
				and ruben = 1
				and winlostdate between fdate and tdate
				and liveindicator = 0
				),
	W = W + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'WON'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 0
				),
	L = L + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'LOSE'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 0
				),
	D = D + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'DRAW'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 0
				)
-- 14
update #TempWeeklyWL 
set BetCount = BetCount + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
				and bettype < 99
				and ruben = 1
				and winlostdate between fdate and tdate
				AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
				and liveindicator = 0
				),
	W = W + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'WON'
					and bettype < 99
					and winlostdate between fdate and tdate
					AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
					and liveindicator = 0
				),
	L = L + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'LOSE'
					and bettype < 99
					and winlostdate between fdate and tdate
					AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
					and liveindicator = 0
				),
	D = D + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'DRAW'
					and bettype < 99
					and winlostdate between fdate and tdate
					AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
					and liveindicator = 0
				)
-- archive
update #TempWeeklyWL 
set BetCount = BetCount + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
				and bettype < 99
				and ruben = 1
				and winlostdate between fdate and tdate
				and liveindicator = 0
				),
	W = W + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'WON'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 0
				),
	L = L + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'LOSE'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 0
				),
	D = D + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'DRAW'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 0
				)

select 
	convert(varchar(10),a.fdate,120), convert(varchar(10),a.tdate,120),
	isnull(a.betCount,0)+isnull(b.betCount,0) as BetCount_ALL,	
	isnull(b.betCount,0) BetCnt_LIVE,
	round(cast(isnull(b.W,0) as float)*100 / case when isnull(b.betCount,0) = 0 then 1 else isnull(b.betCount,0) end, 0) 'Won (%)' ,
	round(cast(isnull(b.L*100,0) as float) / case when isnull(b.betCount,0) = 0 then 1 else isnull(b.betCount,0) end, 0) 'Lose (%)',
	round(cast(isnull(b.D*100,0) as float) / case when isnull(b.betCount,0) = 0 then 1 else isnull(b.betCount,0) end, 0) 'Draw (%)',
	isnull(a.betCount,0) BetCnt, 
	round(cast(isnull(a.W,0) as float)*100 / case when isnull(a.betCount,0) = 0 then 1 else isnull(a.betCount,0) end, 0) 'Won (%)' ,
	round(cast(isnull(a.L*100,0) as float) / case when isnull(a.betCount,0) = 0 then 1 else isnull(a.betCount,0) end, 0) 'Lose (%)',
	round(cast(isnull(a.D*100,0) as float) / case when isnull(a.betCount,0) = 0 then 1 else isnull(a.betCount,0) end, 0) 'Draw (%)',	
	isnull(b.rturnover,0) as rTurnOver,
	isnull(b.winloss,0) as winloss,
	Round(isnull(b.winloss,0)*100/case when isnull(b.rturnover,0) = 0 then 1 else isnull(b.rturnover,0) end, 0) as WinPercentage	
from #TempWeeklyWL a
	FULL OUTER JOIN #TempWeeklyWL_live b on a.fdate=b.fdate

drop table #TempWeeklyWL
drop table #TempWeeklyWL_live

/*
--------------------
--------------------
--Daily statistics

CREATE TABLE #TempDaily (date smalldatetime, turnover money, betcount int, w int, l int, d int, islive bit, winamt money, stake money, winloss money)

INSERT INTO #TempDaily
select b.winlostdate, 0, count(b.custid), 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	b.liveindicator as IsLive,
	0, 0, 0
from bettrans b with(nolock) 
where custid=@CustID
	and bettype < 99
group by b.winlostdate, b.liveindicator
order by 1

INSERT INTO #TempDaily
select b.winlostdate, 0, count(b.custid), 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	b.liveindicator as IsLive,
	0, 0, 0
from bettrans14 b with(nolock) 
where custid=@CustID
	and bettype < 99
	and winlostdate between @BalanceUpDay and @MoveBetsDay
group by b.winlostdate, b.liveindicator
order by 1

INSERT INTO #TempDaily
select b.winlostdate, 0, count(b.custid), 
	sum(case when b.status='WON' then 1 else 0 end),
	sum(case when b.status='LOSE' then 1 else 0 end),
	sum(case when b.status='DRAW' then 1 else 0 end),	
	b.liveindicator as IsLive,
	0, 0, 0
from db06.bodb_archive.dbo.bettrans_bk b with(nolock) 
where custid=@CustID
	and bettype < 99
group by b.winlostdate, b.liveindicator
order by 1

UPDATE #TempDaily
set turnover = turnover + (	select isnull(sum(b.stake),0)
							FROM bettrans b with(nolock)
							where custid=@CustID
								and status not in ('VOID', 'REJECT', 'DRAW')
								and b.winlostdate = date 
								and ruben=1
								and bettype < 99),
	winamt = winamt + (	select isnull(sum(winlost-actual_stake),0)
						FROM bettrans b with(nolock)
						where custid=@CustID
							and b.winlostdate = date 
							and ruben=1
							and status='WON'
							and bettype < 99),
	stake = stake + (select isnull(sum(b.stake),0)
							FROM bettrans b with(nolock)
							where custid=@CustID
								and status not in ('VOID', 'REJECT')
								and b.winlostdate = date 
								and ruben=1
								and bettype < 99),
	winloss = winloss + (	select isnull(sum(winlost-actual_stake),0)
						FROM bettrans b with(nolock)
						where custid=@CustID
							and b.winlostdate = date 
							and ruben=1
							and status not in ('VOID', 'REJECT')
							and bettype < 99) 

UPDATE #TempDaily
set turnover = turnover + (	select isnull(sum(b.stake),0)
							FROM bettrans14 b with(nolock)
							where custid=@CustID
								and status not in ('VOID', 'REJECT', 'DRAW')
								and b.winlostdate = date 
								and ruben=1
								and winlostdate between @BalanceUpDay and @MoveBetsDay 
								and bettype < 99),
	winamt = winamt + (	select isnull(sum(winlost-actual_stake),0)
						FROM bettrans14 b with(nolock)
						where custid=@CustID
							and b.winlostdate = date 
							and ruben=1
							and status='WON'
							and winlostdate between @BalanceUpDay and @MoveBetsDay 
							and bettype < 99),
	stake = stake + (select isnull(sum(b.stake),0)
							FROM bettrans14 b with(nolock)
							where custid=@CustID
								and status not in ('VOID', 'REJECT')
								and b.winlostdate = date 
								and winlostdate between @BalanceUpDay and @MoveBetsDay 
								and ruben=1
								and bettype < 99),
	winloss = winloss + (	select isnull(sum(winlost-actual_stake),0)
						FROM bettrans14 b with(nolock)
						where custid=@CustID
							and b.winlostdate = date 
							and winlostdate between @BalanceUpDay and @MoveBetsDay 
							and ruben=1
							and status not in ('VOID', 'REJECT')
							and bettype < 99) 

UPDATE #TempDaily
set turnover = turnover + (	select isnull(sum(b.stake),0)
							FROM db06.bodb_archive.dbo.bettrans_bk b with(nolock)
							where custid=@CustID
								and status not in ('VOID', 'REJECT', 'DRAW')
								and b.winlostdate = date 
								and ruben=1
								and bettype < 99),
	winamt = winamt + (	select isnull(sum(winlost-actual_stake),0)
						FROM db06.bodb_archive.dbo.bettrans_bk b with(nolock)
						where custid=@CustID
							and b.winlostdate = date 
							and ruben=1
							and status='WON'
							and bettype < 99),
	stake = stake + (select isnull(sum(b.stake),0)
							FROM db06.bodb_archive.dbo.bettrans_bk b with(nolock)
							where custid=@CustID
								and status not in ('VOID', 'REJECT')
								and b.winlostdate = date 
								and ruben=1
								and bettype < 99),
	winloss = winloss + (	select isnull(sum(winlost-actual_stake),0)
						FROM db06.bodb_archive.dbo.bettrans_bk b with(nolock)
						where custid=@CustID
							and b.winlostdate = date 
							and ruben=1
							and status not in ('VOID', 'REJECT')
							and bettype < 99)  

select 
	convert(varchar(10),case when a.date is null then b.date else a.date end, 120) as date,	
	Round(isnull(a.stake,0)+isnull(b.stake,0),2) as stake,
	isnull(betCount_L,0) + isnull(betCount,0) as BetCount,
	isnull(betCount_L,0) BetCnt_LIVE,
	round(cast(isnull(PercentageW_L,0) as float)*100 / case when isnull(betCount_L,0) = 0 then 1 else isnull(betCount_L,0) end, 0) 'Won (%)' ,
	round(cast(isnull(PercentageL_L,0) as float)*100 / case when isnull(betCount_L,0) = 0 then 1 else isnull(betCount_L,0) end, 0) 'Lose (%)',
	round(cast(isnull(PercentageD_L,0) as float)*100 / case when isnull(betCount_L,0) = 0 then 1 else isnull(betCount_L,0) end, 0) 'Draw (%)',
	isnull(betCount,0) BetCnt, 
	round(cast(isnull(PercentageW,0) as float)*100 / case when isnull(betCount,0) = 0 then 1 else isnull(betCount,0) end, 0) 'Won (%)' ,
	round(cast(isnull(PercentageL*100,0) as float) / case when isnull(betCount,0) = 0 then 1 else isnull(betCount,0) end, 0) 'Lose (%)',
	round(cast(isnull(PercentageD*100,0) as float) / case when isnull(betCount,0) = 0 then 1 else isnull(betCount,0) end, 0) 'Draw (%)',
	--Round(isnull(a.WinAmt,0)+isnull(b.WinAmt,0),2) as WinAmt,
	--Round((isnull(a.WinAmt,0)+isnull(b.WinAmt,0))*100/case when (isnull(a.turnover,0)+isnull(b.turnover,0)) = 0 then 1 else (isnull(a.turnover,0)+isnull(b.turnover,0)) end, 0) as WinMargin,
	isnull(a.turnover,0)+isnull(b.turnover,0) as rTurnOver,	
	Round(isnull(a.winloss,0)+isnull(b.winloss,0),2) as winloss,
	Round((isnull(a.winloss,0)+isnull(b.winloss,0))*100/case when (isnull(a.turnover,0)+isnull(b.turnover,0)) = 0 then 1 else (isnull(a.turnover,0)+isnull(b.turnover,0)) end, 0) as WinPercentage
from
(select date,
	sum(isnull(turnover,0)) as turnover,
	sum(isnull(betCount, 0)) as betCount_L,	
	SUM(W) PercentageW_L,
	SUM(L) PercentageL_L,
	SUM(D) PercentageD_L,
	sum(isnull(winamt,0)) as winamt,	
	sum(isnull(stake,0)) as stake,	
	sum(isnull(winloss,0)) as winloss
FROM #TempDaily
WHERE isLIVE=1
GROUP BY date
) a
FULL OUTER JOIN
(
select date,
	sum(isnull(turnover,0)) as turnover,
	sum(isnull(betCount, 0)) as betCount,	
	SUM(W) PercentageW,
	SUM(L) PercentageL,
	SUM(D) PercentageD,
	sum(isnull(winamt,0)) as winamt,
	sum(isnull(stake,0)) as stake,	
	sum(isnull(winloss,0)) as winloss
FROM #TempDaily
WHERE isLIVE=0
GROUP BY date
)b on a.date = b.date

drop table #TempDaily
*/

/*
--------------------
--------------------
--MONTHLY(*) statistics

CREATE TABLE #TempDaily2_LIVE (fdate smalldatetime, tdate smalldatetime, betcount int, w int, l int, d int, rTurnOver money, Winloss money)
CREATE TABLE #TempDaily2 (fdate smalldatetime, tdate smalldatetime, betcount int, w int, l int, d int)
declare @date1 smalldatetime, @date2 smalldatetime
select @date1 = convert(varchar(10),@Creatdate,120)
select @date2 = dateadd(mm,-1,convert(varchar(10),CURRENT_TIMESTAMP,120))

WHILE @date1 < @date2
BEGIN	
	INSERT INTO #TempDaily2_LIVE values(@date1,dateadd(mm,1,dateadd(dd,-1,@date1)),0,0,0,0,0,0)
	SELECT @date1 = dateadd(dd, 1, @date1)
END
INSERT INTO #TempDaily2 SELECT fdate,tdate,0,0,0,0 FROM #TempDaily2_LIVE


update #TempDaily2_LIVE 
set rTurnOver = rTurnOver + (select isnull(sum(stake),0)
				from bettrans with(nolock)
				where custid= @CustID
					and ruben=1
					and status not in ('running', 'waiting', 'VOID', 'REJECT', 'DRAW')
					and bettype < 99
					and winlostdate between fdate and tdate					
				),
	BetCount = BetCount + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
				and bettype < 99
				and ruben = 1
				and winlostdate between fdate and tdate
				and liveindicator = 1
				),
	W = W + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'WON'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 1
				),
	L = L + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'LOSE'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 1
				),
	D = D + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'DRAW'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 1
				),
	Winloss = Winloss + (select isnull(sum(winlost-actual_stake),0)
						FROM bettrans with(nolock)
						where custid=@CustID
							and winlostdate between fdate and tdate
							and ruben=1
							and status not in ('VOID', 'REJECT')
							and bettype < 99
				)
-- 14
update #TempDaily2_LIVE 
SET	rturnover =  rturnover + (select isnull(sum(stake),0)
				from bettrans14 with(nolock)
				where custid= @CustID
					and ruben=1
					and status not in ('VOID', 'REJECT', 'DRAW')
					and bettype < 99
					and winlostdate between fdate and tdate
					AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay					
				),
	BetCount = BetCount + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
				and bettype < 99
				and ruben = 1
				and winlostdate between fdate and tdate
				AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
				and liveindicator = 1
				),
	W = W + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'WON'
					and bettype < 99
					and winlostdate between fdate and tdate
					AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
					and liveindicator = 1
				),
	L = L + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'LOSE'
					and bettype < 99
					and winlostdate between fdate and tdate
					AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
					and liveindicator = 1
				),
	D = D + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'DRAW'
					and bettype < 99
					and winlostdate between fdate and tdate
					AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
					and liveindicator = 1
				),
	Winloss = Winloss + (select isnull(sum(winlost-actual_stake),0)
						FROM bettrans14 with(nolock)
						where custid=@CustID
							and winlostdate between fdate and tdate
							and ruben=1
							and status not in ('VOID', 'REJECT')
							and bettype < 99
				)
-- archive
update #TempDaily2_LIVE 
set rturnover = rturnover + (select isnull(sum(stake),0)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid= @CustID
					and ruben=1
					and status not in ('VOID', 'REJECT', 'DRAW')
					and bettype < 99
					and winlostdate between fdate and tdate					
				),
	BetCount = BetCount + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
				and bettype < 99
				and ruben = 1
				and winlostdate between fdate and tdate
				and liveindicator = 1
				),
	W = W + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'WON'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 1
				),
	L = L + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'LOSE'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 1
				),
	D = D + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'DRAW'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 1
				),
	Winloss = Winloss + (select isnull(sum(winlost-actual_stake),0)
						FROM DB06.bodb_archive.dbo.bettrans_bk with(nolock)
						where custid=@CustID
							and winlostdate between fdate and tdate
							and ruben=1
							and status not in ('VOID', 'REJECT')
							and bettype < 99
				)

update #TempDaily2 
set BetCount = BetCount + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
				and bettype < 99
				and ruben = 1
				and winlostdate between fdate and tdate
				and liveindicator = 0
				),
	W = W + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'WON'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 0
				),
	L = L + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'LOSE'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 0
				),
	D = D + (select count(matchid)
				from bettrans with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'DRAW'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 0
				)
-- 14
update #TempDaily2 
set BetCount = BetCount + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
				and bettype < 99
				and ruben = 1
				and winlostdate between fdate and tdate
				AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
				and liveindicator = 0
				),
	W = W + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'WON'
					and bettype < 99
					and winlostdate between fdate and tdate
					AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
					and liveindicator = 0
				),
	L = L + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'LOSE'
					and bettype < 99
					and winlostdate between fdate and tdate
					AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
					and liveindicator = 0
				),
	D = D + (select count(matchid)
				from bettrans14 with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'DRAW'
					and bettype < 99
					and winlostdate between fdate and tdate
					AND Winlostdate Between @BalanceUpDay AND @MoveBetsDay
					and liveindicator = 0
				)
-- archive
update #TempDaily2 
set BetCount = BetCount + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
				and bettype < 99
				and ruben = 1
				and winlostdate between fdate and tdate
				and liveindicator = 0
				),
	W = W + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'WON'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 0
				),
	L = L + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'LOSE'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 0
				),
	D = D + (select count(matchid)
				from DB06.bodb_archive.dbo.bettrans_bk with(nolock)
				where custid = @CustID
					and ruben=1
					and status = 'DRAW'
					and bettype < 99
					and winlostdate between fdate and tdate
					and liveindicator = 0
				)

select 
	convert(varchar(10),a.fdate,120), convert(varchar(10),a.tdate,120),	
	isnull(a.betCount,0)+isnull(b.betCount,0) as BetCount_ALL,	
	isnull(b.betCount,0) BetCnt_LIVE,
	round(cast(isnull(b.W,0) as float)*100 / case when isnull(b.betCount,0) = 0 then 1 else isnull(b.betCount,0) end, 0) 'Won (%)' ,
	round(cast(isnull(b.L*100,0) as float) / case when isnull(b.betCount,0) = 0 then 1 else isnull(b.betCount,0) end, 0) 'Lose (%)',
	round(cast(isnull(b.D*100,0) as float) / case when isnull(b.betCount,0) = 0 then 1 else isnull(b.betCount,0) end, 0) 'Draw (%)',
	isnull(a.betCount,0) BetCnt, 
	round(cast(isnull(a.W,0) as float)*100 / case when isnull(a.betCount,0) = 0 then 1 else isnull(a.betCount,0) end, 0) 'Won (%)' ,
	round(cast(isnull(a.L*100,0) as float) / case when isnull(a.betCount,0) = 0 then 1 else isnull(a.betCount,0) end, 0) 'Lose (%)',
	round(cast(isnull(a.D*100,0) as float) / case when isnull(a.betCount,0) = 0 then 1 else isnull(a.betCount,0) end, 0) 'Draw (%)',	
	isnull(b.rturnover,0) as rTurnOver,
	isnull(b.winloss,0) as winloss,
	Round(isnull(b.winloss,0)*100/case when isnull(b.rturnover,0) = 0 then 1 else isnull(b.rturnover,0) end, 0) as WinPercentage	
from #TempDaily2 a
	FULL OUTER JOIN #TempDaily2_live b on a.fdate=b.fdate

drop table #TempDaily2
drop table #TempDaily2_LIVE
*/