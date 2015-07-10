ALTER PROCEDURE HR_Settle--by race
	@race varchar(20),--race
	@leagueid int,--meeting
	@Results varchar(2000) = ''
AS

--======================================================
--Settlement for Horseracing
--Developer:Vinh Truong
--Simulate only, the real settlement is from Phumelela
--======================================================

--results format: 
--Position:	 01   02   03   04  
--HorseNo:  '05','07','09','15',...
declare 
	@orid int, @HorseCount int, @c int,
	@First int, @Second int, @Third int, @ThirdNo int, @dividendWin smallmoney, @dividendPlace smallmoney,
	@TurnOver money, @WinBetCount int, @dividend float ,@tax smallmoney, @phum smallmoney 
--SELECT @tax = 0.2  --- suppose 20% for goverment tax and comm 
--SELECT @phum = 1 - @tax 


if not exists(select 1 from league with (nolock) where leagueid = @leagueid and sporttype = 151) return
select @HorseCount = count(1) from outright with (nolock) where groupmatch = @race and leagueid = @leagueid and matchcode <> 'HRDummy'

if @Results <> ''
BEGIN
	if (@HorseCount <> (select count(1) from dbo.StrSplit(@Results, ','))) return --invalid results
END
else--simulate result if not indicate
BEGIN
	select @Results = ''
	select @Results = @Results + matchcode + ',' 
	from  outright 
	where groupmatch = @race and leagueid = @leagueid and matchcode <> 'HRDummy'
	ORDER BY matchcode
END

--delete dummy trans to avoid settle on dummy trans
delete bettrans where matchid IN(select orid from outright with (nolock) where leagueid = @leagueid and groupmatch = @race and matchcode = 'HRDummy')


select @c = 1
WHILE(@c <= @HorseCount)
BEGIN
	select @orid = orid from outright 
	where groupmatch = @race and leagueid = @leagueid and matchcode = dbo.Acc_SplitIndex(@Results, ',', @c)
	
	if @c < 4 --record orid of 1,2,3 position and horseNo of 3rd
	BEGIN
		select @First = case when @c=1 then @orid else @First end
		select @Second = case when @c=2 then @orid else @Second end
		select @Third = case when @c=3 then @orid else @Third end		
		select @ThirdNo = case when @c=3 then matchcode else @ThirdNo end from outright with (nolock) where orid = @orid
		
		update outright set placing = @c where orid = @orid  ---update position 
	END
	--update horse position
	update outright set oddsstatus = 'completed', status = 'OFFICIAL'  
	where orid = @orid

	select @c = @c + 1
END


------------------
--calculate (win)
------------------

select @TurnOver = sum(stake) from bettrans with (nolock) 
where bettype = 31
	AND matchid IN (select orid from outright with (nolock) where groupmatch = @race and leagueid = @leagueid)

--select @WinBetCount = count(1) from bettrans with (nolock) where matchid = @First and bettype = 31
--select @dividend = case when @WinBetCount = 0 then 0 else (@TurnOver*@phum)/(@TurnOver *@WinBetCount) end

update	bettrans set odds = o.odds
from	bettrans 
		inner join outright o (nolock) on bettrans.matchid = o.orid 
where	o.groupmatch = @race 
		and o.leagueid = @leagueid
		and bettrans.bettype = 31 

UPDATE bettrans
SET 
	WinLost = case when matchid = @First then actual_stake + stake * odds else 0 end,
	aWinLost = 0,
	mWinLost = 0,
	sWinLost = 0,
	PlayerComm = playerdiscount * stake,
	Comm = discount * stake,
	aComm = adiscount * stake,
	sComm = sdiscount * stake,
--	Odds = @dividend,
	Status = case when matchid = @First then 'WON' else 'LOSE' end,
	ruben=1
WHERE 
	bettype = 31
	and	status NOT IN ('VOID', 'REJECT')
	and matchid IN (select orid from outright with (nolock) where groupmatch = @race and leagueid = @leagueid)


-------------------
--calculate (place)
-------------------
select @TurnOver = sum(stake) from bettrans with (nolock) 
where bettype = 32
	AND matchid IN (select orid from outright with (nolock) where groupmatch = @race and leagueid = @leagueid)

--select @WinBetCount = count(1) from bettrans with (nolock) 
--where 
	--matchid IN(@First, @Second) OR (matchid=@Third AND @ThirdNo>=7)
	--and bettype = 32
	
--select @dividend = case when @WinBetCount = 0 then 0 else (@TurnOver*@phum)/(@TurnOver *@WinBetCount) end

update	bettrans set odds = o.placeodds
from	bettrans 
		inner join outright o (nolock) on bettrans.matchid = o.orid 
where	o.groupmatch = @race 
		and o.leagueid = @leagueid
		and bettrans.bettype = 32 


UPDATE bettrans
SET 
	WinLost = case when matchid IN(@First, @Second) OR (matchid=@Third AND @ThirdNo>=7) then actual_stake + stake * odds else 0 end,
	aWinLost = 0,
	mWinLost = 0,
	sWinLost = 0,
	PlayerComm = playerdiscount * stake,
	Comm = discount * stake,
	aComm = adiscount * stake,
	sComm = sdiscount * stake,
--	Odds = @dividend,
	Status = case when matchid IN(@First, @Second) OR (matchid=@Third AND @ThirdNo>=7) then 'WON' else 'LOSE' end,
	ruben=1
WHERE 
	bettype = 32
	and	status NOT IN ('VOID', 'REJECT')
	and matchid IN (select orid from outright with (nolock) where groupmatch = @race and leagueid = @leagueid)

----------------------
--calculate (each way)
----------------------


select @TurnOver = sum(stake) from bettrans with (nolock) 
where bettype = 33
	AND matchid IN (select orid from outright with (nolock) where groupmatch = @race and leagueid = @leagueid)

--select @WinBetCount = count(1) from bettrans with (nolock) 
--where 
	--(
		--(matchid = @First)OR 
		--(matchid IN(@First, @Second) OR (matchid=@Third AND @ThirdNo>=7))
	--)
	--and bettype = 33

--select @dividend = case when @WinBetCount = 0 then 0 else (@TurnOver*@phum)/(@TurnOver *@WinBetCount) end

update	bettrans set odds = (o.odds + o.placeodds)/2
from	bettrans 
		inner join outright o (nolock) on bettrans.matchid = o.orid 
where	o.groupmatch = @race 
		and o.leagueid = @leagueid
		and bettrans.bettype = 33 


UPDATE bettrans
SET 
	WinLost = 
		case when matchid = @First then actual_stake + stake * odds else 0 end + 
		case when matchid IN(@First, @Second) OR (matchid=@Third AND @ThirdNo>=7) then actual_stake + stake * odds else 0 end,
	aWinLost = 0,
	mWinLost = 0,
	sWinLost = 0,
	PlayerComm = playerdiscount * stake,
	Comm = discount * stake,
	aComm = adiscount * stake,
	sComm = sdiscount * stake,
--	Odds = @dividend,
	Status = 
		case 
			when 
				(matchid = @First)OR  
				(matchid IN(@First, @Second) OR (matchid=@Third AND @ThirdNo>=7)) then 'WON' 
			else 'LOSE' 
		end,
	ruben=1
WHERE 
	bettype = 33
	and	status NOT IN ('VOID', 'REJECT')
	and matchid IN (select orid from outright with (nolock) where groupmatch = @race and leagueid = @leagueid)

--------------------------
--Create dummy horse, odds
--------------------------

--Create dummy horse - create once only (static and reused)!
declare @HorseID int

delete team where teamname = 'Dummy Horse'

INSERT INTO team(teamname,teamnamec,teamdesc,creator,teamnamesc,teamnamec_uni,teamnamej,teamnamecn)
SELECT 'Dummy Horse',NULL,'Dummy Horse',8,NULL,NULL,NULL,NULL
select @HorseID = @@IDENTITY

--Create dummy odds (by race)
delete outright where leagueid = @leagueid and groupmatch = @race and matchcode = 'HRDummy'

DECLARE @eventdate datetime, @kickofftime datetime 
SELECT @eventdate = eventdate , @kickofftime = kickofftime FROM outright (nolock) 
WHERE leagueid = @leagueid and groupmatch =@race 

INSERT INTO outright
SELECT
   @leagueid,--leagueid
   @HorseID,--teamid
   @eventdate, @kickofftime, 'completed',0,0,0,
   'HRDummy',--matchcode
   @race,--groupmatch
   'OFFICIAL',8,0,0,1,
   '',
   '','','','',0,0,0,0,''

select @orid = @@IDENTITY



--INSERT DUMMY TRANS
Declare @transcode bigint, @grefno int
UPDATE ref with (rowlock, UPDLOCK)  SET   @grefno=transcode=transcode+1
WHERE  refid='acc'
SELECT @transcode=300000000000+@grefno

--Phume TurnOver
INSERT INTO bettrans
(
	creator, 
	custid, 
	username, 
	refno, 
	transdate, 
	bettype, 
	transdesc, 
	winlost, 
	actual_stake, 
	comstatus, 
	status, 
	ruben, 
	winlostdate, 
	currency,
	actualrate, 
	matchid,
	currencyName,
	recommend, 
	mrecommend, 
	srecommend, 
	scomm, 
	swinlost,
	ip
)
select
	8,
	c.custid, 
	c.username,
	@transcode, 
	CURRENT_TIMESTAMP,
	bettype, 	
	'Meeting ' 
	+ convert(varchar(10),LeagueID) 
	+ ' - ' + groupmatch 
	+ ' : TurnOver Sum [' +  convert(varchar(10),bettype) + '] [' + e.Currency + '] Phume' transdesc, 
	sum(stake) TurnOver,
	0,
	NULL, 
	'', 
	1, 
	eventdate,--convert(varchar(10), CURRENT_TIMESTAMP, 120), 
	b.currency,
	e.actualrate,
	@orid,
	e.Currency currName,
	a.custid recommend, 
	ma.custid mrecommend, 
	s.custid srecommend, 
	0, 
	0, 
	NULL
from bettrans b with (nolock)
	inner join exchange e with (nolock) on b.currency = e.exchangeid
	inner join outright m with (nolock) on b.matchid = m.orid
	inner join customer c with (nolock) on e.exchangeid = c.currency and left(c.username, 5) = 'TO4HR'
	inner join customer a with (nolock) on c.recommend = a.custid
	inner join customer ma with (nolock) on c.mrecommend = ma.custid
	inner join customer s with (nolock) on c.srecommend = s.custid
where 
	bettype IN(31,32,33)
	and b.matchid <> @orid
	and ruben = 1	
	and leagueid = @leagueid
	and GroupMatch = @Race
group by 
	c.custid, 
	c.username,
	a.custid , 
	ma.custid, 
	s.custid, 
	LeagueID, GroupMatch, EventDate, bettype, 
	b.currency,
	e.actualrate,
	e.Currency



--Phume win/lost
INSERT INTO bettrans
(
	creator, 
	custid, 
	username, 
	refno, 
	transdate, 
	bettype, 
	transdesc, 
	winlost, 
	actual_stake, 
	comstatus, 
	status, 
	ruben, 
	winlostdate, 
	currency,
	actualrate, 
	matchid,	
	currencyName,
	recommend, 
	mrecommend, 
	srecommend, 
	scomm, 
	swinlost,
	ip
)
select
	8,
	c.custid, 
	c.username,
	@transcode, 
	CURRENT_TIMESTAMP,
	bettype, 	
	'Meeting ' 
	+ convert(varchar(10),LeagueID) 
	+ ' - ' + groupmatch 
	+ ' : Winlost Sum [' +  convert(varchar(10),bettype) + '] [' + e.Currency + '] Phume' transdesc, 
	0,--winlost
	sum(winlost),--actual_stake
	NULL, 
	'', 
	1, 
	eventdate,--convert(varchar(10), CURRENT_TIMESTAMP, 120), 
	b.currency,
	e.actualrate,
	@orid,	
	e.Currency currName,
	a.custid recommend, 
	ma.custid mrecommend, 
	s.custid srecommend, 
	0, 
	0, 
	NULL
from bettrans b with (nolock)
	inner join exchange e with (nolock) on b.currency = e.exchangeid
	inner join outright m with (nolock) on b.matchid = m.orid
	inner join customer c with (nolock) on e.exchangeid = c.currency and left(c.username, 9) = 'DivRec4HR'
	inner join customer a with (nolock) on c.recommend = a.custid
	inner join customer ma with (nolock) on c.mrecommend = ma.custid
	inner join customer s with (nolock) on c.srecommend = s.custid
where 
	bettype IN(31,32,33)
	and b.matchid <> @orid	
	and ruben = 1
	and leagueid = @leagueid
	and GroupMatch = @Race
group by 
	c.custid, 
	c.username,
	a.custid , 
	ma.custid, 
	s.custid, 
	LeagueID, GroupMatch, EventDate, bettype, 
	b.currency,
	e.actualrate,
	e.Currency



--Phume comm exp
INSERT INTO bettrans
(
	creator, 
	custid, 
	username, 
	refno, 
	transdate, 
	bettype, 
	transdesc, 
	winlost, 
	actual_stake, 
	comstatus, 
	status, 
	ruben, 
	winlostdate, 
	currency,
	actualrate, 
	matchid,	
	currencyName,
	recommend, 
	mrecommend, 
	srecommend, 
	scomm, 
	swinlost,
	ip
)
select
	8,
	c.custid, 
	c.username,
	@transcode, 
	CURRENT_TIMESTAMP,
	bettype, 	
	'Meeting ' 
	+ convert(varchar(10),m.LeagueID) 
	+ ' - ' + groupmatch 
	+ ' : CommExp Sum [' +  convert(varchar(10),bettype) + '] [' + e.Currency + '] Phume' transdesc, 
	0,--winlost
	sum(case bettype when 31 then stake * l.MaxStake
					 when 32 then stake * l.maxstakeou 
					 when 33 then stake * (l.maxstake + l.maxstakeou)/2
					 else 0 end 
					),--actual_stake
	NULL, 
	'', 
	1, 
	eventdate,--convert(varchar(10), CURRENT_TIMESTAMP, 120), 
	b.currency,
	e.actualrate,
	@orid,	
	e.Currency currName,
	a.custid recommend, 
	ma.custid mrecommend, 
	s.custid srecommend, 
	0, 
	0, 
	NULL
from bettrans b with (nolock)
	inner join exchange e with (nolock) on b.currency = e.exchangeid
	inner join outright m with (nolock) on b.matchid = m.orid
	inner join customer c with (nolock) on e.exchangeid = c.currency and left(c.username, 12) = 'CommRecFrPhu'
	inner join customer a with (nolock) on c.recommend = a.custid
	inner join customer ma with (nolock) on c.mrecommend = ma.custid
	inner join customer s with (nolock) on c.srecommend = s.custid
	inner join league l with (nolock) on m.leagueid = l.leagueid
where 
	bettype IN(31,32,33)
	and b.matchid <> @orid	
	and ruben = 1	
	and m.leagueid = @leagueid
	and GroupMatch = @Race
group by 
	c.custid, 
	c.username,
	a.custid , 
	ma.custid, 
	s.custid, 
	m.LeagueID, GroupMatch, EventDate, bettype, 
	b.currency,
	e.actualrate,
	e.Currency


--IBC Comm Income
INSERT INTO bettrans
(
	creator, 
	custid, 
	username, 
	refno, 
	transdate, 
	bettype, 
	transdesc, 
	winlost, 
	actual_stake, 
	comstatus, 
	status, 
	ruben, 
	winlostdate, 
	currency,
	actualrate, 
	matchid,	
	currencyName,
	recommend, 
	mrecommend, 
	srecommend, 
	scomm, 
	swinlost,
	ip
)
select
	8,
	c.custid, 
	c.username,
	@transcode, 
	CURRENT_TIMESTAMP,
	bettype, 	
	'Meeting ' 
	+ convert(varchar(10),m.LeagueID) 
	+ ' - ' + groupmatch 
	+ ' : CommInc Sum [' +  convert(varchar(10),bettype) + '] [' + e.Currency + '] IBC' transdesc, 
	sum(case bettype when 31 then stake * l.MaxStake
					 when 32 then stake * l.maxStakeou
					 when 33 then stake * (l.maxstake + maxstakeou)/2 
					 else 0 end),--winlost
	0,--actual_stake
	NULL, 
	'', 
	1, 
	eventdate,--convert(varchar(10), CURRENT_TIMESTAMP, 120), 
	b.currency,
	e.actualrate,
	@orid,	
	e.Currency currName,
	a.custid recommend, 
	ma.custid mrecommend, 
	s.custid srecommend, 
	0, 
	0, 
	NULL
from bettrans b with (nolock)
	inner join exchange e with (nolock) on b.currency = e.exchangeid
	inner join outright m with (nolock) on b.matchid = m.orid
	inner join customer c with (nolock) on e.exchangeid = c.currency and left(c.username, 11) = 'CommIncFrHR'
	inner join customer a with (nolock) on c.recommend = a.custid
	inner join customer ma with (nolock) on c.mrecommend = ma.custid
	inner join customer s with (nolock) on c.srecommend = s.custid
	inner join league l with (nolock) on m.leagueid = l.leagueid
where 
	bettype IN(31,32,33)
	and b.matchid <> @orid
	and ruben = 1	
	and m.leagueid = @leagueid
	and GroupMatch = @Race
group by 
	c.custid, 
	c.username,
	a.custid , 
	ma.custid, 
	s.custid, 
	m.LeagueID, GroupMatch, EventDate, bettype, 
	b.currency,
	e.actualrate,
	e.Currency
	
	
--IBC comm exp
INSERT INTO bettrans
(
	creator, 
	custid, 
	username, 
	refno, 
	transdate, 
	bettype, 
	transdesc, 
	winlost, 
	actual_stake, 
	comstatus, 
	status, 
	ruben, 
	winlostdate, 
	currency,
	actualrate, 
	matchid,	
	currencyName,
	recommend, 
	mrecommend, 
	srecommend, 
	scomm, 
	swinlost,
	ip
)
select
	8,
	c.custid, 
	c.username,
	@transcode, 
	CURRENT_TIMESTAMP,
	bettype, 	
	'Meeting ' 
	+ convert(varchar(10),m.LeagueID) 
	+ ' - ' + groupmatch 
	+ ' : CommExp Sum [' +  convert(varchar(10),bettype) + '] [' + e.Currency + '] IBC' transdesc, 
	0,--winlost
	sum(scomm),--actual_stake
	NULL, 
	'', 
	1, 
	eventdate,--convert(varchar(10), CURRENT_TIMESTAMP, 120), 
	b.currency,
	e.actualrate,
	@orid,	
	e.Currency currName,
	a.custid recommend, 
	ma.custid mrecommend, 
	s.custid srecommend, 
	0, 
	0, 
	NULL
from bettrans b with (nolock)
	inner join exchange e with (nolock) on b.currency = e.exchangeid
	inner join outright m with (nolock) on b.matchid = m.orid
	inner join customer c with (nolock) on e.exchangeid = c.currency and left(c.username, 10) = 'CommExp4HR'
	inner join customer a with (nolock) on c.recommend = a.custid
	inner join customer ma with (nolock) on c.mrecommend = ma.custid
	inner join customer s with (nolock) on c.srecommend = s.custid
where 
	bettype IN(31,32,33)
	and b.matchid <> @orid
	and ruben = 1
	and m.leagueid = @leagueid
	and GroupMatch = @Race
group by 
	c.custid, 
	c.username,
	a.custid , 
	ma.custid, 
	s.custid, 
	m.LeagueID, GroupMatch, EventDate, bettype, 
	b.currency,
	e.actualrate,
	e.Currency	
----------------
--Update outright set oddsstatus = 'closed' where programID = 'UK-EX'

--EXEC dbo.Admin_3rdAutoSettlement_s151 
--@ProgramID = 'UK-EX',
--@raceNumber = 3,
--@eventdate = '2008-12-20'
-------------
--select * from outright with (nolock) where orid = (select matchid from bettrans with (nolock) where transid = 736103293)
--select * from bettrans with (nolock) where transid = 736103293
--select minstake from league with (nolock)
	--where leagueid = (select leagueid from outright with (nolock) where orid = (select matchid from bettrans with (nolock) where transid = 736103293))
