SELECT	refno,
			b.transid,
			b.transdate,
			--o.matchcode HorseNo, 
		    --o.groupmatch as raceNo,
			case b.bettype when 31 then 'WIN' when 32 then 'PLACE' else 'W/P' end bettype,
			o.odds winOdds,
			o.PlaceOdds placeOdds,
			b.odds,
			case when bettype = 33 and liveawayscore = 0 then b.stake/2 else stake end as stake,
			(b.winlost - b.actual_stake)  as winlost,			
			b.status
			
	FROM	bettrans14 b (nolock)			
			INNER JOIN outright14 o (nolock) on b.matchid = o.orid 

	WHERE	b.bettype in (31,32,33) 
			AND b.ruben = 1 
			AND b.status NOT in ('VOID','REJECT','DONE', 'REFUND')
			AND b.currency =5
			AND b.winlostdate = '20090313'
			--AND o.leagueid = @leagueid 
			--AND o.groupmatch = @raceNo
	order by transid

SELECT	refno,
			b.transid,
			b.transdate,
			--o.matchcode HorseNo, 
		    --o.groupmatch as raceNo,
			case b.bettype when 31 then 'WIN' when 32 then 'PLACE' else 'W/P' end bettype,
			o.odds winOdds,
			o.PlaceOdds placeOdds,
			b.odds,
			case when bettype = 33 and liveawayscore = 0 then b.stake/2 else stake end as stake,
			(b.winlost - b.actual_stake)  as winlost,			
			b.status
			
	FROM	bettrans b (nolock)			
			INNER JOIN outright o (nolock) on b.matchid = o.orid 

	WHERE	b.bettype in (31,32,33) 
			AND b.ruben = 1 
			AND b.status NOT in ('VOID','REJECT','DONE', 'REFUND')
			AND b.currency =5
			AND b.winlostdate = '20090314'
			--AND o.leagueid = @leagueid 
			--AND o.groupmatch = @raceNo
	order by transid
	
	--------------
select * from _HR_Dis
where PG NOT IN (
select PG from _HR_Dis where PG in (select IBC from _HR_Dis))

--

SELECT	refno,
			b.transid,
			b.transdate,
			o.matchcode HorseNo, 
		    o.groupmatch as raceNo,
			case b.bettype when 31 then 'WIN' when 32 then 'PLACE' else 'W/P' end,
			o.odds winOdds,
			o.PlaceOdds placeOdds,
			b.odds,
			b.stake as stake,
			(b.winlost - b.actual_stake)  as winlost,	
			b.status,
			l.leaguename		
			
	FROM	bettrans14 b (nolock)			
			INNER JOIN outright14 o (nolock) on b.matchid = o.orid 
			INNER JOIN League l with (nolock) on o.leagueid = l.leagueid

	WHERE	transid = 
	order by transid
------------------
SELECT	refno,
			b.transid,
			b.transdate,
			--o.matchcode HorseNo, 
		    --o.groupmatch as raceNo,
			case b.bettype when 31 then 'WIN' when 32 then 'PLACE' else 'W/P' end bettype,
			o.odds winOdds,
			o.PlaceOdds placeOdds,
			b.odds,
			case when bettype = 33 and liveawayscore = 0 then b.stake/2 else stake end as stake,
			(b.winlost - b.actual_stake)  as winlost,			
			b.status
			
	FROM	bettrans14 b (nolock)			
			INNER JOIN outright14 o (nolock) on b.matchid = o.orid 

	WHERE	b.bettype in (31,32,33) 
			AND b.ruben = 1 
			AND b.status NOT in ('REJECT', 'DONE')
			AND b.currency =1
			AND b.winlostdate = '20090304'
			--AND o.leagueid = @leagueid 
			--AND o.groupmatch = @raceNo
	order by refno
	---------
SELECT	refno,
			b.transid,
			b.transdate,
			o.matchcode HorseNo, 
		    o.groupmatch as raceNo,
			case b.bettype when 31 then 'WIN' when 32 then 'PLACE' else 'W/P' end,
			--o.odds winOdds,
			--o.PlaceOdds placeOdds,
			b.odds,
			b.stake as stake,
			(b.winlost - b.actual_stake)  as winlost,	
			b.status,
			l.leaguename,
			username, currencyname	
			
	FROM	bettrans b (nolock)			
			INNER JOIN outright o (nolock) on b.matchid = o.orid 
			INNER JOIN League l with (nolock) on o.leagueid = l.leagueid

	WHERE	winlostdate = '2009-03-15'
		and b.status not in ('DONE') and bettype in (31,32,33)

	order by o.leagueid,transid
	--------------
SELECT	refno,
			b.transid,
			b.transdate,
			o.matchcode HorseNo, 
		    o.groupmatch as raceNo,
			case b.bettype when 31 then 'WIN' when 32 then 'PLACE' else 'W/P' end,
			--o.odds winOdds,
			--o.PlaceOdds placeOdds,
			b.odds,
			b.stake as stake,
			(b.winlost - b.actual_stake)  as winlost,	
			b.status,
			l.leaguename,
			username, currencyname	
			
	FROM	bettrans b (nolock)			
			INNER JOIN outright o (nolock) on b.matchid = o.orid 
			INNER JOIN League l with (nolock) on o.leagueid = l.leagueid

	WHERE	winlostdate = '2009-03-17'
		and b.status not in ('DONE') and bettype in (31,32,33)
	and transid between 831852885 and 831889999

	order by o.leagueid,transid

--------------------
SELECT	refno,
			b.stake as stake,
			0 as dividendRec,
			0 as PhuTransdate,
			b.transid,
			b.transdate,
			o.matchcode HorseNo, 
		    o.groupmatch as raceNo,
			case b.bettype when 31 then 'WIN' when 32 then 'PLACE' else 'W/P' end,
			o.odds winOdds,
			o.PlaceOdds placeOdds,
			b.odds,			
			b.status,
			o.Placing,
			l.leaguename		
			
	FROM	bettrans14 b (nolock)			
			INNER JOIN outright14 o (nolock) on b.matchid = o.orid 
			INNER JOIN League l with (nolock) on o.leagueid = l.leagueid

	WHERE	transdate between  '3/2/09 5:20' and '3/2/09 5:50'
			--and b.status = 'reject' 
			and bettype in (31,32,33)
			and currency = 3
	order by transid
	-------------------
	SELECT	refno,
			b.stake as stake,
			0 as dividendRec,
			0 as PhuTransdate,
			b.transid,
			b.transdate,
			o.matchcode HorseNo, 
		    o.groupmatch as raceNo,
			case b.bettype when 31 then 'WIN' when 32 then 'PLACE' else 'W/P' end,
			o.odds winOdds,
			o.PlaceOdds placeOdds,
					
			b.status,
			o.Placing,
			l.leaguename		
			
	FROM	bettrans14 b (nolock)			
			INNER JOIN outright14 o (nolock) on b.matchid = o.orid 
			INNER JOIN League l with (nolock) on o.leagueid = l.leagueid

	WHERE	transdate between  '3/14/09 9:24' and '3/14/09 9:26'
			--and b.status = 'reject' 
			and bettype in (31,32,33)
			and currency =5
	order by transid
	--------------
	SELECT	refno,
			b.transid,
			b.transdate,
			--o.matchcode HorseNo, 
		    --o.groupmatch as raceNo,
			case b.bettype when 31 then 'WIN' when 32 then 'PLACE' else 'W/P' end bettype,
			o.odds winOdds,
			o.PlaceOdds placeOdds,
			b.odds,
			case when bettype = 33 and liveawayscore = 0 then b.stake/2 else stake end as stake,
			(b.winlost - b.actual_stake)  as winlost,			
			b.status
			
	FROM	bettrans14 b (nolock)			
			INNER JOIN outright14 o (nolock) on b.matchid = o.orid 

	WHERE	b.bettype in (31,32,33) 
			AND b.ruben = 1 
			AND b.status NOT in ('REJECT', 'DONE')
			AND b.currency =5
			AND b.winlostdate = '20090314'
			--AND o.leagueid = @leagueid 
			--AND o.groupmatch = @raceNo
	order by refno
---------------------------------------------------------------------------
SELECT	 b.status, sum(stake*actualrate) as Turnover,
			
		    o.groupmatch as raceNo,
			
			l.leaguename, l.leagueid

	--select sum(stake)
			
	FROM	bettrans14 b (nolock)			
			INNER JOIN outright14 o (nolock) on b.matchid = o.orid
			INNER JOIN League l with (nolock) on o.leagueid = l.leagueid

	WHERE	b.bettype in (31,32,33) 
			AND b.ruben = 1 
			AND b.status  NOT in ('VOID','REJECT', 'DONE', 'REFUND')
			AND b.currency =5
			AND b.winlostdate = '20090401'
			AND o.leagueid = 6741 
			AND o.groupmatch = 7
group by  o.groupmatch, l.leaguename, l.leagueid, b.status
order by 	l.leaguename,o.groupmatch
-------------------

SELECT	transid, c.username, b.bettype, b.status, actual_stake, winlost ,
			
		    o.groupmatch as raceNo,
			
			l.leaguename, l.leagueid,b.*
			
	FROM	bettrans14 b (nolock)			
			INNER JOIN outright14 o (nolock) on b.matchid = o.orid
			INNER JOIN League l with (nolock) on o.leagueid = l.leagueid
inner join custinfo c (nolock) on b.custid = c.custid

	WHERE	b.bettype in (31,32,33) 
			AND b.ruben = 1 
			AND b.status in ('done')
			AND b.currency =5
			AND b.winlostdate = '20090401'
			AND o.leagueid = 6741 
			AND o.groupmatch = 7
order by 	c.username, b.bettype, b.transid,l.leaguename,o.groupmatch


update bettrans14 set custid = custid + 1000000000
where transid in (850031974,850031959,850031939,850031975,850031960,850031940,850031976,850031961,850031941,850031973,850031958,850031938,850031972,850031957,850031937)

update bettrans14 set custid = custid + 1000000000
where transid in (850031979,850031969,850031964,850031944,850031954,850031949,850031980,850031970,850031965,850031945,850031955,850031950,850031981,850031971,850031966,850031946,850031956,850031951,850031978,850031968,850031963,850031943,850031953,850031948,850031977,850031967,850031962,850031942,850031952,850031947)

Super:
1150890, 1150941, 1151009, 1151025


SELECT	transdesc, refno,username,
			b.transid,
			b.transdate,
			--o.matchcode HorseNo, 
		    --o.groupmatch as raceNo,
			case b.bettype when 31 then 'WIN' when 32 then 'PLACE' else 'W/P' end bettype,
			o.odds winOdds,
			o.PlaceOdds placeOdds,
			b.odds,
			 stake,
			(b.winlost - b.actual_stake)  as winlost,			
			b.status
			
	FROM	bettrans b (nolock)			
			INNER JOIN outright o (nolock) on b.matchid = o.orid 

	WHERE	b.bettype in (31,32,33) 
			AND b.ruben = 1 
			AND b.status  in ('REJECT')
			--AND b.currency =2
			AND b.winlostdate = '20090410'
			--AND o.leagueid = @leagueid 
			--AND o.groupmatch = @raceNo
	order by refno
	----------------------

truncate table _HR_Dis

select * from _HR_Dis
where IBC NOT IN (
select IBC from _HR_Dis where IBC in (select PG from _HR_Dis))
---------------
SELECT	refno, username,
			b.transid, stake,
			b.transdate,
			--o.matchcode HorseNo, 
		    --o.groupmatch as raceNo,
			case b.bettype when 31 then 'WIN' when 32 then 'PLACE' else 'W/P' end bettype,
			o.odds winOdds,
			o.PlaceOdds placeOdds,			
			(b.winlost )  as winlost,			
			b.status
			
	FROM	bettrans14 b (nolock)			
			INNER JOIN outright14 o (nolock) on b.matchid = o.orid
			inner join customer c (nolock) on b.custid = c.custid 

	WHERE	b.bettype in (31,32,33) 
			AND b.ruben = 1 
			AND b.status NOT in ('VOID','REJECT','DONE', 'REFUND')
			AND b.currency =1
			AND b.winlostdate = '20090419'
			--AND o.leagueid = @leagueid 
			--AND o.groupmatch = @raceNo
			--and transid in (874452560, 874459950,874903771)
			--and refno = 0

	order by transid