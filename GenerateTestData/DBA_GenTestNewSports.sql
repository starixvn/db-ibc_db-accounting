CREATE PROCEDURE [dbo].[DBA_GenTestNewSports]
	@sportID int
AS
SET NOCOUNT ON

declare @LeagueID int,
	@LeagueName nvarchar(100),
	@ErrMsg nvarchar(400),
	@sporttype tinyint,
	@sportname varchar(50),
	@teamname varchar(50),
	@TeamSuffix varchar(20)

-----------------------------------------
--Add League
select @sportname = sportname from sports with (nolock) where sporttype = @sportID

select @LeagueName = '*..::¤ IT-SMS League for ' + @sportname,
		@sporttype = @sportID,
		@TeamSuffix = replace(convert(varchar(20), getdate(), 108), ':', '')
		

--Exec DBA_DelTest @LeagueName

if exists (select 1 from League with (nolock) where leagueName = @LeagueName)
BEGIN
	Select @leagueid = leagueID from league with (nolock) where leaguename = @leagueName
	Print 'Use old LeagueID = ' + cast(@LeagueID as varchar(20))
END
else
BEGIN
	exec LeagueIns @leagueid = @LeagueID output, @sporttype = @sporttype, @leaguename = @LeagueName, @leaguenamec = @LeagueName, @maxstake = 1.000000000000000e+003, @maxstakeou = 1.000000000000000e+003, @maxstakeoe = 1.000000000000000e+003, @creator = 12664, @language = default, @lcolor = N'violet'
	Print 'Created LeagueID = ' + cast(@LeagueID as varchar(20))
end

------------------------------------------
--Add Teams
declare @TeamID_1 int,
	@TeamID_2 int,
	@TeamID_3 int,
	@TeamID_4 int,
	@TeamID_5 int,
	@TeamID_6 int
select @teamname = @sportname + ' ' + 'Live Honda'

select @teamname = @sportname + ' ' + 'Live Honda'
exec TeamIns @teamid = @TeamID_1 output, @teamname = @teamname, @teamnamec = @teamname, @teamdesc = N'', @userid = 8
--exec TeamIns @teamid = @TeamID_1 output, @teamname = N'PGE Turów Zgorzelec', @teamnamec = N'PGE Turów Zgorzelec', @teamdesc = N'', @userid = 8

select @teamname = @sportname + ' ' + 'Live Suzuki'
exec TeamIns @teamid = @TeamID_2 output, @teamname = @teamname, @teamnamec = @teamname, @teamdesc = N'', @userid = 8
select @teamname = @sportname + ' ' + 'Live Honda'
exec TeamIns @teamid = @TeamID_3 output, @teamname = @teamname, @teamnamec = @teamname, @teamdesc = N'', @userid = 8

select @teamname = @sportname + ' ' + 'Live Yamaha'
exec TeamIns @teamid = @TeamID_4 output, @teamname = @teamname, @teamnamec = @teamname, @teamdesc = N'', @userid = 8
select @teamname = @sportname + ' ' + 'Live Piaggio'
exec TeamIns @teamid = @TeamID_5 output, @teamname = @teamname, @teamnamec = @teamname, @teamdesc = N'', @userid = 8
select @teamname = @sportname + ' ' + 'Live Yamaha'
exec TeamIns @teamid = @TeamID_6 output, @teamname = @teamname, @teamnamec = @teamname, @teamdesc = N'', @userid = 8


------------------------------------------
--Add Teams into League
Declare @TeamIDList varchar(50)
Select @TeamIDList = cast(@TeamID_1 as varchar(10)) + ',' + cast(@TeamID_2 as varchar(10)) + ',' + cast(@TeamID_3 as varchar(10)) 
					+ ',' + cast(@TeamID_4 as varchar(10)) + ',' + cast(@TeamID_5 as varchar(10)) + ',' + cast(@TeamID_6 as varchar(10)) 
exec TeamLeague_Add @leagueid = @LeagueID, @titeamid = @TeamIDList, @creator = 8

-----------------------
Update league set LeagueName = LeagueName --+ ' - ' + cast(@LeagueID as varchar(20))
where leagueID = @LeagueID

/*
Update team set TeamName = TeamName + ' - ' + cast(teamid as varchar(20))
where teamid = @TeamID_1
	or teamid = @TeamID_2
	or teamid = @TeamID_3
	or teamid = @TeamID_4
	or teamid = @TeamID_5
	or teamid = @TeamID_6
*/
/*
---------------------------
--Prevent Replication problem
select @TeamID_1 = 1200,
	@TeamID_2 = 1201,
	@TeamID_3 = 6349,
	@TeamID_4 = 6350,
	@TeamID_5 = 8951,
	@TeamID_6 = 8952
------------------------------------------
*/
--Add Matches (Events)

declare @MatchID_1 int,
	@MatchID_2 int,
	@MatchID_3 int,
	@EventDate datetime,
	@KickOffTime datetime,
	@ShowTime varchar(100)
----------------------------------------
--Live Event
Select @EventDate = convert(varchar, getdate(), 101), @KickOffTime = Current_TimeStamp,
	@ShowTime = convert(varchar(20), dateadd(hh, 12, @KickOffTime), 108)

exec MatchIns @matchid = @MatchID_1 output, @leagueid = @LeagueID, @homeid = @TeamID_1, @awayid = @TeamID_2, @homeid2 = default, @awayid2 = default, @eventdate = @EventDate, @eventstatus = N'running', @betstatus = N'', @matchcode = '_Test_', @kickofftime = @KickOffTime, @showtime = @ShowTime, @multiple = 1, @ex = 0.4, @creator = 8, @live = 1

----------------------------------------
--Today Dead Event (Parlay enabled)
select @KickOffTime = dateadd(hh, 3, getdate())

Select @EventDate = convert(varchar, @KickOffTime, 101)
Select @ShowTime ='<font color=red>LIVE</font>  ' + convert(varchar(20), dateadd(hh, 12, @KickOffTime), 108)

exec MatchIns @matchid = @MatchID_2 output, @leagueid = @LeagueID, @homeid = @TeamID_3, @awayid = @TeamID_4, @homeid2 = default, @awayid2 = default, @eventdate = @EventDate, @eventstatus = N'running', @betstatus = N'', @matchcode = '_Test_', @kickofftime = @KickOffTime, @showtime = @ShowTime, @multiple = 1, @ex = 0, @creator = 8, @live = 0

----------------------------------------
--Early Dead Event

select @KickOffTime = dateadd(hh, 3, dateadd(day, 1, getdate()))
Select @EventDate = convert(varchar, @KickOffTime, 101)
Select @ShowTime = convert(varchar, dateadd(hh, 12, @KickOffTime), 113)

exec MatchIns @matchid = @MatchID_3 output, @leagueid = @LeagueID, @homeid = @TeamID_5, @awayid = @TeamID_6, @homeid2 = default, @awayid2 = default, @eventdate = @EventDate, @eventstatus = N'running', @betstatus = N'', @matchcode = '_Test_', @kickofftime = @KickOffTime, @showtime = @ShowTime, @multiple = 1, @ex = 0, @creator = 8, @live = 0
------------------------------------

Update team set TeamName = TeamName + ' - ' + cast(matchid as varchar(20))
from match
where (match.homeid = team.teamid or match.awayid = team.teamid)
	and (match.matchid = @MatchID_1 or match.matchid = @MatchID_2 or match.matchid = @MatchID_3)
--------------------------------------
Delete from Odds where matchid = @MatchID_1
Delete from Odds where matchid = @MatchID_2
Delete from Odds where matchid = @MatchID_3
------------------------------------
--Match_1

exec OddsIns @oddsid = 1, @typeid = 1, @hdp1 = 1, @hdp2 = $0.0000, @odds1a = default, @odds2a = $0.8900, @odds1b = default, @odds2b = default, @odds1c = default, @odds2c = default, @odds1e = default, @odds2e = default, @odds1f = default, @odds2f = default, @odds1d = default, @odds2d = default, @odds1hka = default, @odds2hka = default, @odds1hkb = default, @odds2hkb = default, @odds1hkc = default, @odds2hkc = default, @odds1hke = default, @odds2hke = default, @odds1hkf = default, @odds2hkf = default, @odds1hkd = default, @odds2hkd = default, @oddsspreada = $0.1200, @oddsspreadb = $0.1300, @oddsspreadc = $0.1400, @oddsspreadd = $0.1500, @oddsspreade = $0.1600, @oddsspreadf = $0.1700, @autobookie = 1, @gapodds1 = $0.0250, @maxodds = -$0.6500, @minodds = $0.6500, @oddsstatus = N'running', @liveindicator = 1, @risk = $2000.0000, @stakerange = $2000.0000, @livehomescore = 0, @liveawayscore = 0, @cs00 = default, @cs01 = default, @cs10 = default, @cs11 = default, @cs02 = default, @cs12 = default, @cs22 = default, @cs21 = default, @cs20 = default, @cs30 = default, @cs31 = default, @cs32 = default, @cs33 = default, @cs23 = default, @cs13 = default, @cs03 = default, @cs43 = default, @cs42 = default, @cs41 = default, @cs40 = default, @cs44 = default, @cs14 = default, @cs24 = default, @cs04 = default, @cs34 = default, @cs50 = default, @cs05 = default, @comstatus = default, @csstatus = default, @commaxbet = default, @csmaxbet = default, @switch = default, @com1 = default, @comx = default, @com2 = default, @matchid = @MatchID_1, @custid = 8, @sporttype = @sporttype

exec OddsIns @oddsid = 1, @typeid = 1, @hdp1 = .75, @hdp2 = $0.0000, @odds1a = default, @odds2a = $0.9200, @odds1b = default, @odds2b = default, @odds1c = default, @odds2c = default, @odds1e = default, @odds2e = default, @odds1f = default, @odds2f = default, @odds1d = default, @odds2d = default, @odds1hka = default, @odds2hka = default, @odds1hkb = default, @odds2hkb = default, @odds1hkc = default, @odds2hkc = default, @odds1hke = default, @odds2hke = default, @odds1hkf = default, @odds2hkf = default, @odds1hkd = default, @odds2hkd = default, @oddsspreada = $0.1200, @oddsspreadb = $0.1300, @oddsspreadc = $0.1400, @oddsspreadd = $0.1500, @oddsspreade = $0.1600, @oddsspreadf = $0.1700, @autobookie = 1, @gapodds1 = $0.0250, @maxodds = -$0.6500, @minodds = $0.6500, @oddsstatus = N'running', @liveindicator = 1, @risk = $2000.0000, @stakerange = $2000.0000, @livehomescore = 0, @liveawayscore = 0, @cs00 = default, @cs01 = default, @cs10 = default, @cs11 = default, @cs02 = default, @cs12 = default, @cs22 = default, @cs21 = default, @cs20 = default, @cs30 = default, @cs31 = default, @cs32 = default, @cs33 = default, @cs23 = default, @cs13 = default, @cs03 = default, @cs43 = default, @cs42 = default, @cs41 = default, @cs40 = default, @cs44 = default, @cs14 = default, @cs24 = default, @cs04 = default, @cs34 = default, @cs50 = default, @cs05 = default, @comstatus = default, @csstatus = default, @commaxbet = default, @csmaxbet = default, @switch = default, @com1 = default, @comx = default, @com2 = default, @matchid = @MatchID_1, @custid = 8, @sporttype = @sporttype

------------------------------------
--Match_2
exec OddsIns @oddsid = 1, @typeid = 1, @hdp1 = .25, @hdp2 = $0.0000, @odds1a = default, @odds2a = $0.8500, @odds1b = default, @odds2b = default, @odds1c = default, @odds2c = default, @odds1e = default, @odds2e = default, @odds1f = default, @odds2f = default, @odds1d = default, @odds2d = default, @odds1hka = default, @odds2hka = default, @odds1hkb = default, @odds2hkb = default, @odds1hkc = default, @odds2hkc = default, @odds1hke = default, @odds2hke = default, @odds1hkf = default, @odds2hkf = default, @odds1hkd = default, @odds2hkd = default, @oddsspreada = $0.1200, @oddsspreadb = $0.1300, @oddsspreadc = $0.1400, @oddsspreadd = $0.1500, @oddsspreade = $0.1600, @oddsspreadf = $0.1700, @autobookie = 1, @gapodds1 = $0.0250, @maxodds = -$0.6500, @minodds = $0.6500, @oddsstatus = N'running', @liveindicator = 0, @risk = $2000.0000, @stakerange = $2000.0000, @livehomescore = 0, @liveawayscore = 0, @cs00 = default, @cs01 = default, @cs10 = default, @cs11 = default, @cs02 = default, @cs12 = default, @cs22 = default, @cs21 = default, @cs20 = default, @cs30 = default, @cs31 = default, @cs32 = default, @cs33 = default, @cs23 = default, @cs13 = default, @cs03 = default, @cs43 = default, @cs42 = default, @cs41 = default, @cs40 = default, @cs44 = default, @cs14 = default, @cs24 = default, @cs04 = default, @cs34 = default, @cs50 = default, @cs05 = default, @comstatus = default, @csstatus = default, @commaxbet = default, @csmaxbet = default, @switch = default, @com1 = default, @comx = default, @com2 = default, @matchid = @MatchID_2, @custid = 8, @sporttype = @sporttype


------------------------------------
--Match_3
exec OddsIns @oddsid = 1, @typeid = 1, @hdp1 = .25, @hdp2 = $0.0000, @odds1a = default, @odds2a = $0.7500, @odds1b = default, @odds2b = default, @odds1c = default, @odds2c = default, @odds1e = default, @odds2e = default, @odds1f = default, @odds2f = default, @odds1d = default, @odds2d = default, @odds1hka = default, @odds2hka = default, @odds1hkb = default, @odds2hkb = default, @odds1hkc = default, @odds2hkc = default, @odds1hke = default, @odds2hke = default, @odds1hkf = default, @odds2hkf = default, @odds1hkd = default, @odds2hkd = default, @oddsspreada = $0.1200, @oddsspreadb = $0.1100, @oddsspreadc = $0.1300, @oddsspreadd = $0.1500, @oddsspreade = $0.1600, @oddsspreadf = $0.1700, @autobookie = 1, @gapodds1 = $0.0250, @maxodds = -$0.6500, @minodds = $0.6500, @oddsstatus = N'running', @liveindicator = 0, @risk = $2000.0000, @stakerange = $2000.0000, @livehomescore = 0, @liveawayscore = 0, @cs00 = default, @cs01 = default, @cs10 = default, @cs11 = default, @cs02 = default, @cs12 = default, @cs22 = default, @cs21 = default, @cs20 = default, @cs30 = default, @cs31 = default, @cs32 = default, @cs33 = default, @cs23 = default, @cs13 = default, @cs03 = default, @cs43 = default, @cs42 = default, @cs41 = default, @cs40 = default, @cs44 = default, @cs14 = default, @cs24 = default, @cs04 = default, @cs34 = default, @cs50 = default, @cs05 = default, @comstatus = default, @csstatus = default, @commaxbet = default, @csmaxbet = default, @switch = default, @com1 = default, @comx = default, @com2 = default, @matchid = @MatchID_3, @custid = 8, @sporttype = @sporttype

----------------------------------
Update Odds
set MaxBet = 10000
where matchid in (select matchid from match where leagueid = @LeagueID)
