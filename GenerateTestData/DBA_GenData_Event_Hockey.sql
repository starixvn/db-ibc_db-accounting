--------------------------------------------------------------
--Create data for Markets, Indexes, Index events for Financial 
--------------------------------------------------------------
DECLARE @leaguename1 NVARCHAR(50), @leaguename2 NVARCHAR(50), @leaguename3 NVARCHAR(50)
DECLARE @teamname1 NVARCHAR(50), @teamname2 NVARCHAR(50), @teamname3 NVARCHAR(50),
		@teamname4 NVARCHAR(50),@teamname5 NVARCHAR(50),@teamname6 NVARCHAR(50)
declare @leagueid1 int, @leagueid2 int, @leagueid3 INT
DECLARE @teamid1 INT, @teamid2 INT,@teamid3 INT,@teamid4 INT,@teamid5 INT,@teamid6 INT

SELECT	@leaguename1 ='RABO HOOFDKLASSE FIELD HOCKEY',
		@leaguename2='FIELD Hockey - IIHF Ice Hockey World U20 Championship' ,
		@leaguename3='FIEL HOCKEY NHL - ALL STAR GAME'
		
SELECT	@teamname1 ='New York Rangers', 
		@teamname2 ='Carolina Hurricanes',
		@teamname3 ='Calgary Flames',
		@teamname4 ='Vancouver(1st Period)',
		@teamname5 ='Carolina(1st Period)',
		@teamname6 ='Los Angeles Kings'

if exists(select 1 from match where sporttype = 28)
begin
	print 'Event is existed. Cannot create new events'
	return 
END

--delete all ralated FA data
--delete league where sporttype = 28
--delete team where teamdesc = 'Field Hockey'
--delete match where sporttype = 28

--Markets (league):
INSERT INTO league VALUES(
    @leaguename1,--leaguename
	0,--maxstake 
    0,--minstake
	0,0,NULL,NULL,8,'#ff99ff',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,
	28,--sporttype
	GetDate(),NULL,0,0,0,null,null
	--maxstakeou, maxstakeoe, leaguenamec, leaguenametc, creator, lcolor, hdp_min, hdp_max, hdp_risk, hdp_range, hdp_allowance, hdp_gapodds, hdp_gapoddsr, ou_min, ou_max, ou_risk, ou_range, ou_allowance, ou_gapodds, ou_gapoddsr, oe_min, oe_max, oe_risk, oe_range, oe_gapodds, cs_min, cs_max, cs_risk, cs_range, cs_gapodds, b1x2_min, b1x2_max, b1x2_risk, b1x2_range, b1x2_gapodds, tg_min, tg_max, tg_risk, tg_range, tg_gapodds, ht_min, ht_max, ht_risk, ht_range, ht_allowance, ht_gapodds, ht_gapoddsr, ht1x2_min, ht1x2_max, ht1x2_risk, ht1x2_range, ht1x2_gapodds, leaguenamec_uni, sporttype, createdate, leaguenamecn, oe_gapoddsr, DisplayMode, isTest
)
select @leagueid1 = @@IDENTITY
INSERT INTO league VALUES(
    @leaguename2,--leaguename
	0,--maxstake 
    0,--minstake
	0,0,NULL,NULL,8,'#ff99ff',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,
	28,--sporttype
	GetDate(),NULL,0,0,0,null,null
)
select @leagueid2 = @@IDENTITY
INSERT INTO league VALUES(
    @leaguename3,--leaguename
	0,--maxstake 
    0,--minstake
	0,0,NULL,NULL,8,'#ff99ff',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,
	28,--sporttype
	GetDate(),NULL,0,0,0,null,null
)
select @leagueid3 = @@IDENTITY


--Indexes (team)
INSERT INTO team(teamname,teamnamec,teamdesc,creator,teamnamesc,teamnamec_uni,teamnamej,teamnamecn)
VALUES( @teamname1,NULL,'Field Hockey',8,NULL,NULL,NULL,NULL)
SELECT @teamid1 =@@IDENTITY

INSERT INTO team(teamname,teamnamec,teamdesc,creator,teamnamesc,teamnamec_uni,teamnamej,teamnamecn)
VALUES(@teamname2,NULL,'Field Hockey',8,NULL,NULL,NULL,NULL)
SELECT @teamid2=@@IDENTITY


INSERT INTO team(teamname,teamnamec,teamdesc,creator,teamnamesc,teamnamec_uni,teamnamej,teamnamecn)
VALUES(@teamname3,NULL,'Field Hockey',8,NULL,NULL,NULL,NULL)
SELECT @teamid3=@@IDENTITY

INSERT INTO team(teamname,teamnamec,teamdesc,creator,teamnamesc,teamnamec_uni,teamnamej,teamnamecn)
VALUES(@teamname4,NULL,'Field Hockey',8,NULL,NULL,NULL,NULL)
SELECT @teamid4=@@IDENTITY


INSERT INTO team(teamname,teamnamec,teamdesc,creator,teamnamesc,teamnamec_uni,teamnamej,teamnamecn)
VALUES( @teamname5 ,NULL,'Field Hockey',8,NULL,NULL,NULL,NULL)
SELECT @teamid5=@@IDENTITY


INSERT INTO team(teamname,teamnamec,teamdesc,creator,teamnamesc,teamnamec_uni,teamnamej,teamnamecn)
VALUES( @teamname6 ,NULL,'Field Hockey',8,NULL,NULL,NULL,NULL )
SELECT @teamid6=@@IDENTITY

--Match events (match)
declare 
	@EventDate datetime,
	@KickOffTime datetime,
	@ShowTime varchar(100)
select @KickOffTime = getdate()--dateadd(hh, 3, dateadd(day, 1, getdate()))
Select @EventDate = convert(varchar, @KickOffTime, 101)
Select @ShowTime = convert(varchar, dateadd(hh, 12, @KickOffTime), 113)

DECLARE @i INT, @t1 NVARCHAR(10), @t2 NVARCHAR(10), @strteam NVARCHAR(10) ,@strmatch NVARCHAR(10)
SELECT @i=1, @strteam='@team', @strmatch='' 
WHILE(@i<6)
BEGIN
	SELECT @t1 = @strteam + CONVERT(VARCHAR(10),@i)
	SELECT @t2 = @strteam + CONVERT(VARCHAR(10),@i+1)
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
	--match------------------------------
	VALUES(
		@leagueid1,--leagueid
		@t1,--teamid
		@t2,--awayid
		@EventDate,--eventdate
		'running', --eventstatus
		NULL,0,0,0,0,8,
		'Field Hockey',--matchcode
		@KickOffTime,--KickOffTime
		NULL,--closetime
		@ShowTime,--Showtime
		NULL,--hthomescore
		NULL,--htawayscore
		0,--ruben
		0,--multiple
		0,--yenbet
		0,--exrisk
		28,--sportype
		0,--homeid2
		0,--awayid2
		0--DisplayMode
		)
END

