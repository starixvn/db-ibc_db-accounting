----------------------------------------------------------
--Create data for Meetings, Races, Horses for Horseracing 
----------------------------------------------------------
declare @Meeting1 int, @Meeting2 int, @Meeting3 int, @Meeting4 int
declare @discountUKWin smallmoney, @discountUKPlace smallmoney,	@discountSA smallmoney
declare @raceNo1 tinyint, @raceNo2 tinyint,@raceNo3 tinyint, @raceNo4 tinyint 
declare @programid1 varchar(10), @programid2 varchar(10),@programid3 varchar(10),@programid4 varchar(10)

SELECT @discountSA = 0.09 , @discountUKWin = 0.06 , @discountUKPlace = 0.09  
SELECT @programid1='UK-EX', @programid2='UK-LF', @programid3='SA-AUS',@programid4='SA-SP'
SELECT @raceNo1 =1 ,@raceNo2=2 ,@raceNo3 = 3,@raceNo4 = 4 


--delete all ralated HR data
delete league where sporttype = 151
delete team where teamdesc = 'Horse'
delete outright where len(ProgramID) > 1
delete leaguedetail 
delete raceinfo


--Meetings (league):
INSERT INTO league VALUES(
    'LINKFIELD(UK-LF)',--leaguename
	@discountUKWin,--maxstake 
    1,--minstake
    @discountUKPlace, --maxstakeou place comm%
    (@discountUKWin + @discountUKPlace)/2, --maxstake e-way comm % 
	NULL,NULL,8,'#ff99ff',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,
	151,--sporttype
	GetDate(),NULL,0,0,0,null,@programid2
)
select @Meeting2 = @@IDENTITY

INSERT INTO league VALUES(
    'SINGAPORE(SA-SP)',--leaguename
	@discountSA,--maxstake 
    2,--minstake
    @discountSA, --maxstakeou place comm%
    @discountSA, --maxstake e-way comm % 
	NULL,NULL,8,'#ff99ff',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,
	151,--sporttype
	GetDate(),NULL,0,0,0,null,@programid4
)
select @Meeting4 = @@IDENTITY

-----------------leaguedetail --------------

 
INSERT INTO Leaguedetail 
VALUES (	@meeting2,	
			@programid2,
			getdate(),
			'running',
			100,
			50,
			getdate(),	
			''
       )       

INSERT INTO Leaguedetail 
VALUES (	@meeting4,	
			@programid4,
			getdate(),
			'running',
			100,
			50,
			getdate(),	
			''
       )
       
 ----------------------RACE INFO -------------------------

  INSERT INTO Raceinfo
 VALUES (	@programid2,
			@raceNo1,
			'Turf', -- Track type
			'1400m',--Distance
			'01:20',null,null,null,
			getdate()
  )
  
    INSERT INTO Raceinfo
 VALUES (	@programid2,
			@raceNo2,
			'Turf', -- Track type
			'1400m',--Distance
			'01:20',null,null,null,
			getdate()
  )
  
 
 
      INSERT INTO Raceinfo
 VALUES (	@programid4,
			@raceNo1,
			'Turf', -- Track type
			'1200m',--Distance
			'01:00',null,null,null,
			getdate()
  )
 
 
      INSERT INTO Raceinfo
 VALUES (	@programid4,
			@raceNo2,
			'Turf', -- Track type
			'1200m',--Distance
			'01:00',null,null,null,
			getdate()
  )
 
 
      INSERT INTO Raceinfo
 VALUES (	@programid4,
			@raceNo3,
			'Turf', -- Track type
			'1200m',--Distance
			'01:00',null,null,null,
			getdate()
  )
 
 

 ---------------------------------------------------------
--Horses (team)
INSERT INTO team(teamname,teamnamec,teamdesc,creator,teamnamesc,teamnamec_uni,teamnamej,teamnamecn)
SELECT 'Amorts',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Shantahliatrailblaza',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION
SELECT 'Merrywood Prince',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Just Pretend',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Misty Miller',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Gotashotaway',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Jarendan',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Butler On Duty',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Mighty Dane',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Regal Knight',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Bombardier',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Is Lucky',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Bay Of Island',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Val Algeo',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Cullenator',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Fifth Avenue',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Lucero De Gloria',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Astronomy',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Black List',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Fabiani',NULL,'Horse',8,NULL,NULL,NULL,NULL
UNION ALL
SELECT 'Fingal ',NULL,'Horse',8,NULL,NULL,NULL,NULL 
UNION ALL
SELECT 'Pink Dollar',NULL,'Horse',8,NULL,NULL,NULL,NULL 
UNION ALL
SELECT 'Fort Vogue',NULL,'Horse',8,NULL,NULL,NULL,NULL 
UNION ALL
SELECT 'The Rookie',NULL,'Horse',8,NULL,NULL,NULL,NULL 
UNION ALL
SELECT 'National Theme',NULL,'Horse',8,NULL,NULL,NULL,NULL 
UNION ALL
SELECT 'Ferchard',NULL,'Horse',8,NULL,NULL,NULL,NULL 
UNION ALL
SELECT 'Hospitality',NULL,'Horse',8,NULL,NULL,NULL,NULL 
UNION ALL
SELECT 'Astronast',NULL,'Horse',8,NULL,NULL,NULL,NULL 
UNION ALL
SELECT 'City OF Light',NULL,'Horse',8,NULL,NULL,NULL,NULL 
--Races (Outright)

INSERT INTO outright
           ([leagueid]
           ,[teamid]
           ,[eventdate]
           ,[kickofftime]
           ,[oddsstatus]
           ,[odds]
           ,[maxbet]
           ,[gapodds]
           ,[matchcode]
           ,[groupmatch]
           ,[status]
           ,[creator]
           ,[bal]
           ,[risk]
           ,[DisplayMode]
           ,[ProgramID]
           ,[HorseTrainer]
           ,[HorseJockey]
           ,[HorseDraw]
           ,[HorseWgt]
           ,[PlaceOdds]
           ,[Placing]
           ,[IsFavor]
           ,[IsSCR])

----meeting2------------------------------------
SELECT 
   @Meeting2,--leagueid
   teamid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '05',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,
   @programid2,
    'Hodgson',
   'Schlechter',
   '11',
   '56',
   round((5*rand() + 2),2),
   0,1,0
FROM team with (nolock) where teamname IN('City OF Light')
UNION ALL
SELECT 
   @Meeting2,--leagueid
   teamid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '01',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,
    @programid2,
    'G S Kannemeyer',
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0
FROM team with (nolock) where teamname IN('Just Pretend')
UNION ALL
SELECT 
   @Meeting2,--leagueid
   teamid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '02',--matchcode
   @raceNo1,--groupmatch
  'running',8,0,0,1,
	@programid2,
    'G S Kannemeyer',
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0
FROM team with (nolock) where teamname IN('Misty Miller')
UNION ALL
SELECT 
   @Meeting2,--leagueid
   teamid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '04',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,
    @programid2,
    'G S Kannemeyer',
   'D Behr',
   '18',
   '57',
  round((5*rand() + 2),2),
   0,0,0
FROM team with (nolock) where teamname IN('Gotashotaway' )

--meeting4------------------------------------
UNION ALL
SELECT 
   @Meeting4,--leagueid
   teamid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '01',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,
     @programid4,
    'G S Kannemeyer',
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0
FROM team with (nolock) where teamname IN('Regal Knight')
UNION ALL
SELECT 
   @Meeting4,--leagueid
   teamid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '02',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,
     @programid4,
    'G S Kannemeyer',
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0
FROM team with (nolock) where teamname IN( 'Bombardier')
UNION ALL
SELECT 
   @Meeting4,--leagueid
   teamid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '03',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,
     @programid4,
    'G S Kannemeyer',
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0
FROM team with (nolock) where teamname IN('Is Lucky')
UNION ALL
SELECT 
   @Meeting4,--leagueid
   teamid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '04',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,
     @programid4,
    'G S Kannemeyer',
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0
FROM team with (nolock) where teamname IN( 'Bay Of Island')
UNION ALL
SELECT 
   @Meeting4,--leagueid
   teamid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '05',--matchcode
  @raceNo1,--groupmatch
   'running',8,0,0,1,
     @programid4,
    'G S Kannemeyer',
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0
FROM team with (nolock) where teamname IN('Val Algeo')
UNION ALL
SELECT 
   @Meeting4,--leagueid
   teamid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '01',--matchcode
   @raceNo2,--groupmatch
   'running',8,0,0,1,
     @programid4,
    'G S Kannemeyer',
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0
FROM team with (nolock) where teamname IN('Is Lucky')
UNION ALL
SELECT 
   @Meeting4,--leagueid
   teamid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '02',--matchcode
   @raceNo2,--groupmatch
   'running',8,0,0,1,
    @programid4,
    'G S Kannemeyer',
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0
FROM team with (nolock) where teamname IN( 'Shantahliatrailblaza')
UNION ALL
SELECT 
   @Meeting4,--leagueid
   teamid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '03',--matchcode
   @raceNo2,--groupmatch
   'running',8,0,0,1,
     @programid4,
    'G S Kannemeyer',
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0
FROM team with (nolock) where teamname IN('Amorts')
UNION ALL
SELECT 
   @Meeting4,--leagueid
   teamid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '11',--matchcode
   @raceNo3,--groupmatch
   'running',8,0,0,1,
    @programid4,
    'G S Kannemeyer',
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0
FROM team with (nolock) where teamname IN('Bay Of Island')
UNION ALL
SELECT 
   @Meeting4,--leagueid
   teamid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '12',--matchcode
   @raceNo3,--groupmatch
   'running',8,0,0,1,
     @programid4,
    'G S Kannemeyer',
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,1
FROM team with (nolock) where teamname IN( 'Val Algeo')
------------------
--Delete Bets
delete bettrans where bettype IN(31, 32, 33)
---------------

declare @oddsid1 int, @transid int
   
select @oddsid1 = orid from outright with (nolock) where leagueid = @Meeting2 and matchcode = '01'

EXEC dbo.Dot_Member_PlaceBet3rd 
@custid = 1168313,
@SportType = 151,
@BetType = 31,
@oddsid = @oddsid1,
@betteam = 'WIN',
@hdp1 = 0,
@hdp2 = 0,
@odds = 5,
@livehomescore = 0,
@liveawayscore = 0,
@stake = 100,
@HTTP_REF = 'Thien_Test',
@BET_IP = '10.20.20.201',
@site = 'Best-Odds',
@betfrom = 'i',
@creator = 1168313,
@CommID = 1
---------
select top 1 @transid = transid from bettrans where bettype in (31,32,33) order by transid desc
--------------
EXEC dbo.Dot_Member_Confirm3rd 
@transid = @transid,
@IsSuccess = 1,
@refno = '1111'
-----------------------
select @oddsid1 = orid from outright with (nolock) where leagueid = @Meeting2 and matchcode = '05'

EXEC dbo.Dot_Member_PlaceBet3rd 
@custid = 1168393,
@SportType = 151,
@BetType = 32,
@oddsid = @oddsid1,
@betteam = 'Place',
@hdp1 = 0,
@hdp2 = 0,
@odds = 3,
@livehomescore = 0,
@liveawayscore = 0,
@stake = 100,
@HTTP_REF = 'Thien_Test',
@BET_IP = '10.20.20.201',
@site = 'Best-Odds',
@betfrom = 'i',
@creator = 1168393,
@CommID = 1
---------
select top 1 @transid = transid from bettrans where bettype in (31,32,33) order by transid desc
--------------
EXEC dbo.Dot_Member_Confirm3rd 
@transid = @transid,
@IsSuccess = 1,
@refno = '1111'
--------------












-----------------------------------------------------------------
   
select @oddsid1 = orid from outright with (nolock) where leagueid = @Meeting4 and matchcode = '01'

EXEC dbo.Dot_Member_PlaceBet3rd 
@custid = 1168313,
@SportType = 151,
@BetType = 32,
@oddsid = @oddsid1,
@betteam = 'PLACE',
@hdp1 = 0,
@hdp2 = 0,
@odds = 3.5,
@livehomescore = 0,
@liveawayscore = 0,
@stake = 200,
@HTTP_REF = 'Thien_Test',
@BET_IP = '10.20.20.201',
@site = 'Best-Odds',
@betfrom = 'i',
@creator = 1168313,
@CommID = 2
---------
select top 1 @transid = transid from bettrans where bettype in (31,32,33) order by transid desc
--------------
EXEC dbo.Dot_Member_Confirm3rd 
@transid = @transid,
@IsSuccess = 1,
@refno = '1111'
-----------------------
select @oddsid1 = orid from outright with (nolock) where leagueid = @Meeting4 and matchcode = '02'

EXEC dbo.Dot_Member_PlaceBet3rd 
@custid = 1168393,
@SportType = 151,
@BetType = 31,
@oddsid = @oddsid1,
@betteam = 'WIN',
@hdp1 = 0,
@hdp2 = 0,
@odds = 6,
@livehomescore = 0,
@liveawayscore = 0,
@stake = 50,
@HTTP_REF = 'Thien_Test',
@BET_IP = '10.20.20.201',
@site = 'Best-Odds',
@betfrom = 'i',
@creator = 1168393,
@CommID = 2
---------
select top 1 @transid = transid from bettrans where bettype in (31,32,33) order by transid desc
--------------
EXEC dbo.Dot_Member_Confirm3rd 
@transid = @transid,
@IsSuccess = 1,
@refno = '1111'