--------------------------------------------------------------
--Create data for Markets, Indexes, Index events for Financial 
--------------------------------------------------------------
declare @Market1 int, @Market2 int, @Market3 int

if exists(select 1 from match where sporttype = 201)
begin
	print 'Event is existed. Cannot create new events'
	return 
end
--delete all ralated FA data
--delete league where sporttype = 201
--delete team where teamdesc = 'Index'
--delete match where sporttype = 201
--
--Markets (league):
INSERT INTO [bodb02].[dbo].[league]
           ([leaguename]
           ,[maxstake]
           ,[minstake]
           ,[maxstakeou]
           ,[maxstakeoe]
           ,[leaguenamec]
           ,[leaguenametc]
           ,[creator]
           ,[lcolor]
           ,[hdp_min]
           ,[hdp_max]
           ,[hdp_risk]
           ,[hdp_range]
           ,[hdp_allowance]
           ,[hdp_gapodds]
           ,[hdp_gapoddsr]
           ,[ou_min]
           ,[ou_max]
           ,[ou_risk]
           ,[ou_range]
           ,[ou_allowance]
           ,[ou_gapodds]
           ,[ou_gapoddsr]
           ,[oe_min]
           ,[oe_max]
           ,[oe_risk]
           ,[oe_range]
           ,[oe_gapodds]
           ,[cs_min]
           ,[cs_max]
           ,[cs_risk]
           ,[cs_range]
           ,[cs_gapodds]
           ,[b1x2_min]
           ,[b1x2_max]
           ,[b1x2_risk]
           ,[b1x2_range]
           ,[b1x2_gapodds]
           ,[tg_min]
           ,[tg_max]
           ,[tg_risk]
           ,[tg_range]
           ,[tg_gapodds]
           ,[ht_min]
           ,[ht_max]
           ,[ht_risk]
           ,[ht_range]
           ,[ht_allowance]
           ,[ht_gapodds]
           ,[ht_gapoddsr]
           ,[ht1x2_min]
           ,[ht1x2_max]
           ,[ht1x2_risk]
           ,[ht1x2_range]
           ,[ht1x2_gapodds]
           ,[leaguenamec_uni]
           ,[leaguenamej]
           ,[sporttype]
           ,[createdate]
           ,[leaguenamecn]
           ,[oe_gapoddsr]
           ,[DisplayMode]
           ,[isTest]
           ,[leaguenameth]
           ,[ProgramID]
           ) VALUES(
    'Vietnam',--leaguename
	0,--maxstake 
    0,--minstake
	0,0,NULL,NULL,8,'#ff99ff',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,
	201,--sporttype
	GetDate(),NULL,0,0,0,null,null
	--maxstakeou, maxstakeoe, leaguenamec, leaguenametc, creator, lcolor, hdp_min, hdp_max, hdp_risk, hdp_range, hdp_allowance, hdp_gapodds, hdp_gapoddsr, ou_min, ou_max, ou_risk, ou_range, ou_allowance, ou_gapodds, ou_gapoddsr, oe_min, oe_max, oe_risk, oe_range, oe_gapodds, cs_min, cs_max, cs_risk, cs_range, cs_gapodds, b1x2_min, b1x2_max, b1x2_risk, b1x2_range, b1x2_gapodds, tg_min, tg_max, tg_risk, tg_range, tg_gapodds, ht_min, ht_max, ht_risk, ht_range, ht_allowance, ht_gapodds, ht_gapoddsr, ht1x2_min, ht1x2_max, ht1x2_risk, ht1x2_range, ht1x2_gapodds, leaguenamec_uni, sporttype, createdate, leaguenamecn, oe_gapoddsr, DisplayMode, isTest
)
select @Market1 = @@IDENTITY
INSERT INTO [bodb02].[dbo].[league]
           ([leaguename]
           ,[maxstake]
           ,[minstake]
           ,[maxstakeou]
           ,[maxstakeoe]
           ,[leaguenamec]
           ,[leaguenametc]
           ,[creator]
           ,[lcolor]
           ,[hdp_min]
           ,[hdp_max]
           ,[hdp_risk]
           ,[hdp_range]
           ,[hdp_allowance]
           ,[hdp_gapodds]
           ,[hdp_gapoddsr]
           ,[ou_min]
           ,[ou_max]
           ,[ou_risk]
           ,[ou_range]
           ,[ou_allowance]
           ,[ou_gapodds]
           ,[ou_gapoddsr]
           ,[oe_min]
           ,[oe_max]
           ,[oe_risk]
           ,[oe_range]
           ,[oe_gapodds]
           ,[cs_min]
           ,[cs_max]
           ,[cs_risk]
           ,[cs_range]
           ,[cs_gapodds]
           ,[b1x2_min]
           ,[b1x2_max]
           ,[b1x2_risk]
           ,[b1x2_range]
           ,[b1x2_gapodds]
           ,[tg_min]
           ,[tg_max]
           ,[tg_risk]
           ,[tg_range]
           ,[tg_gapodds]
           ,[ht_min]
           ,[ht_max]
           ,[ht_risk]
           ,[ht_range]
           ,[ht_allowance]
           ,[ht_gapodds]
           ,[ht_gapoddsr]
           ,[ht1x2_min]
           ,[ht1x2_max]
           ,[ht1x2_risk]
           ,[ht1x2_range]
           ,[ht1x2_gapodds]
           ,[leaguenamec_uni]
           ,[leaguenamej]
           ,[sporttype]
           ,[createdate]
           ,[leaguenamecn]
           ,[oe_gapoddsr]
           ,[DisplayMode]
           ,[isTest]
           ,[leaguenameth]
           ,[ProgramID]
           ) VALUES(
    'United States',--leaguename
	0,--maxstake 
    0,--minstake
	0,0,NULL,NULL,8,'#ff99ff',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,
	201,--sporttype
	GetDate(),NULL,0,0,0,null,null
)
select @Market2 = @@IDENTITY
INSERT INTO [bodb02].[dbo].[league]
           ([leaguename]
           ,[maxstake]
           ,[minstake]
           ,[maxstakeou]
           ,[maxstakeoe]
           ,[leaguenamec]
           ,[leaguenametc]
           ,[creator]
           ,[lcolor]
           ,[hdp_min]
           ,[hdp_max]
           ,[hdp_risk]
           ,[hdp_range]
           ,[hdp_allowance]
           ,[hdp_gapodds]
           ,[hdp_gapoddsr]
           ,[ou_min]
           ,[ou_max]
           ,[ou_risk]
           ,[ou_range]
           ,[ou_allowance]
           ,[ou_gapodds]
           ,[ou_gapoddsr]
           ,[oe_min]
           ,[oe_max]
           ,[oe_risk]
           ,[oe_range]
           ,[oe_gapodds]
           ,[cs_min]
           ,[cs_max]
           ,[cs_risk]
           ,[cs_range]
           ,[cs_gapodds]
           ,[b1x2_min]
           ,[b1x2_max]
           ,[b1x2_risk]
           ,[b1x2_range]
           ,[b1x2_gapodds]
           ,[tg_min]
           ,[tg_max]
           ,[tg_risk]
           ,[tg_range]
           ,[tg_gapodds]
           ,[ht_min]
           ,[ht_max]
           ,[ht_risk]
           ,[ht_range]
           ,[ht_allowance]
           ,[ht_gapodds]
           ,[ht_gapoddsr]
           ,[ht1x2_min]
           ,[ht1x2_max]
           ,[ht1x2_risk]
           ,[ht1x2_range]
           ,[ht1x2_gapodds]
           ,[leaguenamec_uni]
           ,[leaguenamej]
           ,[sporttype]
           ,[createdate]
           ,[leaguenamecn]
           ,[oe_gapoddsr]
           ,[DisplayMode]
           ,[isTest]
           ,[leaguenameth]
           ,[ProgramID]
           ) VALUES(
    'United Kingdom',--leaguename
	0,--maxstake 
    0,--minstake
	0,0,NULL,NULL,8,'#ff99ff',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,
	201,--sporttype
	GetDate(),NULL,0,0,0,null,null
)
select @Market3 = @@IDENTITY


--Indexes (team)
INSERT INTO team(teamname,teamnamec,teamdesc,creator,teamnamesc,teamnamec_uni,teamnamej,teamnamecn)
SELECT 'Vn-Index',NULL,'Index',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'HASTC-Index',NULL,'Index',8,NULL,NULL,NULL,NULL
UNION
SELECT 'NASDAQ-100',NULL,'Index',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Russell 3000',NULL,'Index',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'FT30 Index',NULL,'Index',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'FTSE techMark Index',NULL,'Index',8,NULL,NULL,NULL,NULL 

--Index events (match)
declare 
	@EventDate datetime,
	@KickOffTime datetime,
	@ShowTime varchar(100)
select @KickOffTime = getdate()--dateadd(hh, 3, dateadd(day, 1, getdate()))
Select @EventDate = convert(varchar, @KickOffTime, 101)
Select @ShowTime = convert(varchar, dateadd(hh, 12, @KickOffTime), 113)

INSERT INTO match
           ([leagueid]
           ,[homeid]
           ,[awayid]
           ,[eventdate]
           ,[eventstatus]
           ,[betstatus]
           ,[livehomescore]
           ,[liveawayscore]
           ,[finalhomescore]
           ,[finalawayscore]
           ,[creator]
           ,[matchcode]
           ,[kickofftime]
           ,[closedtime]
           ,[showtime]
           ,[hthomescore]
           ,[htawayscore]
           ,[ruben]
           ,[multiple]
           ,[yenbet]
           ,[exrisk]
           ,[sporttype]
           ,[homeid2]
           ,[awayid2]
           ,[DisplayMode])
--Market1------------------------------
SELECT
	@Market1,--leagueid
	teamid,--teamid
	0,--awayid
	@EventDate,--eventdate
	'running', --eventstatus
	NULL,0,0,0,0,8,
	'Vn-Index',--matchcode
	@KickOffTime,--KickOffTime
	NULL,--closetime
	@ShowTime,--Showtime
	NULL,--hthomescore
	NULL,--htawayscore
	0,--ruben
	0,--multiple
	0,--yenbet
	0,--exrisk
	201,--sportype
	0,--homeid2
	0,--awayid2
	0--DisplayMode
FROM team with (nolock) where teamname = 'Vn-Index'
UNION ALL
SELECT
	@Market1,--leagueid
	teamid,--teamid
	0,--awayid
	@EventDate,--eventdate
	'running', --eventstatus
	NULL,0,0,0,0,8,
	'HASTC-Index',--matchcode
	@KickOffTime,--KickOffTime
	NULL,--closetime
	@ShowTime,--Showtime
	NULL,--hthomescore
	NULL,--htawayscore
	0,--ruben
	0,--multiple
	0,--yenbet
	0,--exrisk
	201,--sportype
	0,--homeid2
	0,--awayid2
	0--DisplayMode
FROM team with (nolock) where teamname = 'HASTC-Index'
--Market2------------------------------
UNION ALL
SELECT
	@Market2,--leagueid
	teamid,--teamid
	0,--awayid
	@EventDate,--eventdate
	'running', --eventstatus
	NULL,0,0,0,0,8,
	'NASDAQ-100',--matchcode
	@KickOffTime,--KickOffTime
	NULL,--closetime
	@ShowTime,--Showtime
	NULL,--hthomescore
	NULL,--htawayscore
	0,--ruben
	0,--multiple
	0,--yenbet
	0,--exrisk
	201,--sportype
	0,--homeid2
	0,--awayid2
	0--DisplayMode
FROM team with (nolock) where teamname = 'NASDAQ-100'
UNION ALL
SELECT
	@Market2,--leagueid
	teamid,--teamid
	0,--awayid
	@EventDate,--eventdate
	'running', --eventstatus
	NULL,0,0,0,0,8,
	'Russell 3000',--matchcode
	@KickOffTime,--KickOffTime
	NULL,--closetime
	@ShowTime,--Showtime
	NULL,--hthomescore
	NULL,--htawayscore
	0,--ruben
	0,--multiple
	0,--yenbet
	0,--exrisk
	201,--sportype
	0,--homeid2
	0,--awayid2
	0--DisplayMode
FROM team with (nolock) where teamname = 'Russell 3000'
--Market3------------------------------
UNION ALL
SELECT
	@Market3,--leagueid
	teamid,--teamid
	0,--awayid
	@EventDate,--eventdate
	'running', --eventstatus
	NULL,0,0,0,0,8,
	'FT30 Index',--matchcode
	@KickOffTime,--KickOffTime
	NULL,--closetime
	@ShowTime,--Showtime
	NULL,--hthomescore
	NULL,--htawayscore
	0,--ruben
	0,--multiple
	0,--yenbet
	0,--exrisk
	201,--sportype
	0,--homeid2
	0,--awayid2
	0--DisplayMode
FROM team with (nolock) where teamname = 'FT30 Index'
UNION ALL
SELECT
	@Market3,--leagueid
	teamid,--teamid
	0,--awayid
	@EventDate,--eventdate
	'running', --eventstatus
	NULL,0,0,0,0,8,
	'FTSE techMark Index',--matchcode
	@KickOffTime,--KickOffTime
	NULL,--closetime
	@ShowTime,--Showtime
	NULL,--hthomescore
	NULL,--htawayscore
	0,--ruben
	0,--multiple
	0,--yenbet
	0,--exrisk
	201,--sportype
	0,--homeid2
	0,--awayid2
	0--DisplayMode
FROM team with (nolock) where teamname = 'FTSE techMark Index'