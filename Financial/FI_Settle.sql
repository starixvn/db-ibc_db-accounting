ALTER PROCEDURE FI_Settle--by index
	@matchid varchar(20),--indexID
	@Bettype int = 0
AS

--======================================================
--Settlement for Financial
--Developer:Vinh Truong
--No need to input result, the result will be simulated
--======================================================
declare @IBCShare float, @3rdShare float
select @IBCShare = 0.4, @3rdShare = 0.6

--delete dummy trans to avoid settle on dummy trans
delete bettrans 
where matchid = @matchid 
and 1 = case when @bettype = 0 then case when bettype between 51 and 56 or bettype between 61 and 66 then 1 else 0 end 
			 else case when bettype = @bettype then 1 else 0 end 
		end
and left(username, 10) IN('FI3rdShare', 'FIIBCShare')

if 	not exists(
			select 1 from bettrans (nolock) where transid not in 
			(
				select transid 
				from bettrans (nolock) where 
					1 = case when @bettype = 0 then case when bettype between 51 and 56 or bettype between 61 and 66 then 1 else 0 end 
						 else case when bettype = @bettype then 1 else 0 end 
					end
					and ruben = 0 
					and matchid = @matchid
			)
			and matchid = @matchid and ruben = 0
)	
	update match set eventstatus = 'completed' where matchid = @matchid

UPDATE bettrans
SET 
	WinLost = case when hdp2 > hdp1 then actual_stake + stake * odds else 0 end,
	aWinLost = case when hdp2 > hdp1 then -stake * odds * apositiontaking else actual_stake * apositiontaking end,
	mWinLost = case when hdp2 > hdp1 then -stake * odds * mpositiontaking else actual_stake * mpositiontaking end,
	sWinLost = case when hdp2 > hdp1 then -stake * odds * spositiontaking else actual_stake * spositiontaking end,
	PlayerComm = playerdiscount * stake,
	Comm = discount * stake * (1-apositiontaking),
	aComm = adiscount * stake * (1-(mpositiontaking+apositiontaking)),
	sComm = sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)),
	Status = case when hdp2 > hdp1 then 'WON' else 'LOSE' end,
	ruben=1
WHERE 
	1 = case when @bettype = 0 then case when bettype between 51 and 56 or bettype between 61 and 66 then 1 else 0 end 
			 else case when bettype = @bettype then 1 else 0 end 
		end
	and betteam = 'h'
	and	status NOT IN ('VOID', 'REJECT')
	and matchid = @matchid



UPDATE bettrans
SET 
	WinLost = case when hdp2 < hdp1 then actual_stake +  stake * odds else 0 end,
	aWinLost = case when hdp2 < hdp1 then -stake * odds * apositiontaking else actual_stake * apositiontaking end,
	mWinLost = case when hdp2 < hdp1 then -stake * odds * mpositiontaking else actual_stake * mpositiontaking end,
	sWinLost = case when hdp2 < hdp1 then -stake * odds * spositiontaking else actual_stake * spositiontaking end,
	PlayerComm = playerdiscount * stake,
	Comm = discount * stake * (1-apositiontaking),
	aComm = adiscount * stake * (1-(mpositiontaking+apositiontaking)),
	sComm = sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)),
	Status = case when hdp2 < hdp1 then 'WON' else 'LOSE' end,
	ruben=1
WHERE 
	1 = case when @bettype = 0 then case when bettype between 51 and 56 or bettype between 61 and 66 then 1 else 0 end 
			 else case when bettype = @bettype then 1 else 0 end 
		end
	and betteam = 'a'
	and	status NOT IN ('VOID', 'REJECT')
	and matchid = @matchid


--INSERT DUMMY TRANS
Declare @transcode bigint, @grefno int
UPDATE ref with (rowlock, UPDLOCK)  SET   @grefno=transcode=transcode+1
WHERE  refid='acc'
SELECT @transcode=300000000000+@grefno

--3rd Party Share
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
	'Market ' + convert(varchar(10), leagueid) 
	+ ' - IndexEvent ' + convert(varchar(10), @matchid) 
	+ ' : CommShare Sum [' +  convert(varchar(10),bettype) + '] [' + e.Currency + '] 3rd' transdesc, 
	--sum(-(winlost-actual_stake)*(1-tpositiontaking)-scomm )*@3rdShare,--winlost
	case when -isnull(sum(winlost-actual_stake + awinlost+mwinlost+swinlost + scomm),0)*@3rdShare > 0 then -isnull(sum(winlost-actual_stake + awinlost+mwinlost+swinlost + scomm),0)*@3rdShare else 0 end, 
	case when -isnull(sum(winlost-actual_stake + awinlost+mwinlost+swinlost + scomm),0)*@3rdShare < 0 then -isnull(sum(winlost-actual_stake + awinlost+mwinlost+swinlost + scomm),0)*@3rdShare else 0 end,--actual_stake
	NULL, 
	'done', 
	1, 
	m.eventdate, --convert(varchar(10), CURRENT_TIMESTAMP, 120), 
	b.currency,
	e.actualrate,
	@matchid,
	e.Currency currName,
	c.custid, 
	c.mrecommend, 
	c.srecommend, 
	0, 
	0, 
	NULL
from bettrans b with (nolock)
	inner join match m with (nolock) on b.matchid = m.matchid
	inner join exchange e with (nolock) on b.currency = e.exchangeid
	inner join customer c with (nolock) on e.exchangeid = c.currency and left(c.username, 10) = 'FI3rdShare'
where 
	1 = case when @bettype = 0 then case when bettype between 51 and 56 or bettype between 61 and 66 then 1 else 0 end 
			 else case when bettype = @bettype then 1 else 0 end 
	end
	and b.matchid = @matchid
	and b.ruben = 1	
	and isnull(left(b.username, 10), '') NOT IN('FI3rdShare', 'FIIBCShare')
group by 
	c.custid, 
	c.username,
	c.recommend , 
	c.mrecommend, 
	c.srecommend, 
	leagueid,
	bettype,
	b.currency,
	e.actualrate,
	e.Currency,
	m.eventdate



--IBC Share
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
	'Market ' + convert(varchar(10), leagueid) 
	+ ' - IndexEvent ' + convert(varchar(10), @matchid) 
	+ ' : CommShare Sum [' +  convert(varchar(10),bettype) + '] [' + e.Currency + '] IBC' transdesc, 
	--sum(-(winlost-actual_stake)*(1-tpositiontaking)-scomm )*@IBCShare,--winlost
	-isnull(sum(winlost-actual_stake + awinlost+mwinlost+swinlost + scomm),0)*@IBCShare ,--winlost
	0,--actual_stake
	NULL, 
	'done', 
	1, 
	m.eventdate, --convert(varchar(10), CURRENT_TIMESTAMP, 120), 
	b.currency,
	e.actualrate,
	@matchid,	
	e.Currency currName,
	c.custid, 
	c.mrecommend, 
	c.srecommend, 
	0, 
	0, 
	NULL
from bettrans b with (nolock)
	inner join match m with (nolock) on b.matchid = m.matchid
	inner join exchange e with (nolock) on b.currency = e.exchangeid
	inner join customer c with (nolock) on e.exchangeid = c.currency and left(c.username, 10) = 'FIIBCShare'
where 
	1 = case when @bettype = 0 then case when bettype between 51 and 56 or bettype between 61 and 66 then 1 else 0 end 
			 else case when bettype = @bettype then 1 else 0 end 
	end
	and b.matchid = @matchid	
	and b.ruben = 1
	and isnull(left(b.username, 10), '') NOT IN('FI3rdShare', 'FIIBCShare')
group by 
	c.custid, 
	c.username,
	c.recommend , 
	c.mrecommend, 
	c.srecommend, 
	leagueid,
	bettype, 
	b.currency,
	e.actualrate,
	e.Currency,
	m.eventdate



