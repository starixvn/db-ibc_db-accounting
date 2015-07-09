----------------------------------------------------------
--Create data for Meetings, Races, Horses for Horseracing 
----------------------------------------------------------
declare @Meeting1 int, @Meeting2 int, @Meeting3 int, @Meeting4 int
declare @discountUKWin smallmoney, @discountUKPlace smallmoney,	@discountSA smallmoney
declare @raceNo1 tinyint, @raceNo2 tinyint,@raceNo3 tinyint, @raceNo4 tinyint 
declare @programid1 varchar(10), @programid2 varchar(10),@programid3 varchar(10),@programid4 varchar(10)

SELECT @discountSA = 0.10 , @discountUKWin = 0.06 , @discountUKPlace = 0.09  
--SELECT @programid1='UK-EX', @programid2='UK-LF', @programid3='SA-AUS',@programid4='SA-SP'
SELECT @raceNo1 =1 ,@raceNo2=2 ,@raceNo3 = 3,@raceNo4 = 4 

SELECT @meeting1 = leagueid, @programid1 = programid FROM league (Nolock) WHERE leaguename ='Musselburgh(UK)' and sporttype = 151 
SELECT @meeting2 = leagueid, @programid2 = programid FROM league (Nolock) WHERE leaguename ='Fairview (SA)' and sporttype = 151 
SELECT @meeting3 = leagueid, @programid3 = programid FROM league (Nolock) WHERE leaguename ='Kenilworth (SA)' and sporttype = 151 
SELECT @meeting4 = leagueid, @programid4 = programid FROM league (Nolock) WHERE leaguename ='Catterick(UK)' and sporttype = 151 


--delete all ralated HR data
--delete league where sporttype = 151
--delete team where teamdesc = 'Horse'
--delete outright where len(matchcode) = 2
--delete leaguedetail 
--delete raceinfo 

--Meetings (league):
--INSERT INTO league VALUES(
--    'EXETER(UK-EX)',--leaguename
--	@discountUKWin,--maxstake win comm%
--    1,--minstake
--    @discountUKPlace, --maxstakeou place comm%
--    (@discountUKWin + @discountUKPlace)/2, --maxstake e-way comm % 
--	NULL,NULL,8,'#ff99ff',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,
--	151,--sporttype
--	GetDate(),NULL,0,0,0,null,@programid1,null,null,null,null,1
--	--maxstakeou, maxstakeoe, leaguenamec, leaguenametc, creator, lcolor, hdp_min, hdp_max, hdp_risk, hdp_range, hdp_allowance, hdp_gapodds, hdp_gapoddsr, ou_min, ou_max, ou_risk, ou_range, ou_allowance, ou_gapodds, ou_gapoddsr, oe_min, oe_max, oe_risk, oe_range, oe_gapodds, cs_min, cs_max, cs_risk, cs_range, cs_gapodds, b1x2_min, b1x2_max, b1x2_risk, b1x2_range, b1x2_gapodds, tg_min, tg_max, tg_risk, tg_range, tg_gapodds, ht_min, ht_max, ht_risk, ht_range, ht_allowance, ht_gapodds, ht_gapoddsr, ht1x2_min, ht1x2_max, ht1x2_risk, ht1x2_range, ht1x2_gapodds, leaguenamec_uni, sporttype, createdate, leaguenamecn, oe_gapoddsr, DisplayMode, isTest
--)
--select @Meeting1 = @@IDENTITY
--INSERT INTO league VALUES(
--    'LINKFIELD(UK-LF)',--leaguename
--	@discountUKWin,--maxstake 
--    1,--minstake
--    @discountUKPlace, --maxstakeou place comm%
--    (@discountUKWin + @discountUKPlace)/2, --maxstake e-way comm % 
--	NULL,NULL,8,'#ff99ff',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,
--	151,--sporttype
--	GetDate(),NULL,0,0,0,null,@programid2,null,null,null,null,1
--)
--select @Meeting2 = @@IDENTITY
--INSERT INTO league VALUES(
--    'HARORLD PARK(SA-AUS)',--leaguename
--	@discountSA,--maxstake 
--    2,--minstake
--    @discountSA, --maxstakeou place comm%
--    @discountSA, --maxstake e-way comm % 
--	NULL,NULL,8,'#ff99ff',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,
--	151,--sporttype
--	GetDate(),NULL,0,0,0,null,@programid3,null,null,null,null,1
--)
--select @Meeting3 = @@IDENTITY
--INSERT INTO league VALUES(
--    'SINGAPORE(SA-SP)',--leaguename
--	@discountSA,--maxstake 
--    2,--minstake
--    @discountSA, --maxstakeou place comm%
--    @discountSA, --maxstake e-way comm % 
--	NULL,NULL,8,'#ff99ff',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,
--	151,--sporttype
--	GetDate(),NULL,0,0,0,null,@programid4,null,null,null,null,1
--)
--select @Meeting4 = @@IDENTITY
--
-------------------leaguedetail --------------
--INSERT INTO Leaguedetail 
--VALUES (	@meeting1,	
--			@programid1,
--			getdate(),
--			'running',
--			100,
--			50,
--			getdate(),	
--			''
--       )
-- 
--INSERT INTO Leaguedetail 
--VALUES (	@meeting2,	
--			@programid2,
--			getdate(),
--			'running',
--			100,
--			50,
--			getdate(),	
--			''
--       )
--       
--INSERT INTO Leaguedetail 
--VALUES (	@meeting3,	
--			@programid3,
--			getdate(),
--			'running',
--			100,
--			50,
--			getdate(),	
--			''
--       )
--INSERT INTO Leaguedetail 
--VALUES (	@meeting4,	
--			@programid4,
--			getdate(),
--			'running',
--			100,
--			50,
--			getdate(),	
--			''
--       )
--       
-- ----------------------RACE INFO -------------------------
-- INSERT INTO Raceinfo
-- VALUES (	@programid1,
--			@raceNo1,
--			'Turf', -- Track type
--			'1000m',--Distance
--			'01:20',null,null,null,
--			getdate()
--  )
-- 
--  INSERT INTO Raceinfo
-- VALUES (	@programid1,
--			@raceNo2,
--			'Turf', -- Track type
--			'1000m',--Distance
--			'01:20',null,null,null,
--			getdate()
--  )
-- 
-- 
--   INSERT INTO Raceinfo
-- VALUES (	@programid1,
--			@raceNo3,
--			'Turf', -- Track type
--			'1000m',--Distance
--			'01:20',null,null,null,
--			getdate()
--  )
--  INSERT INTO Raceinfo
-- VALUES (	@programid2,
--			@raceNo1,
--			'Turf', -- Track type
--			'1400m',--Distance
--			'01:20',null,null,null,
--			getdate()
--  )
--  
--    INSERT INTO Raceinfo
-- VALUES (	@programid2,
--			@raceNo2,
--			'Turf', -- Track type
--			'1400m',--Distance
--			'01:20',null,null,null,
--			getdate()
--  )
--  
-- 
--     INSERT INTO Raceinfo
-- VALUES (	@programid3,
--			@raceNo1,
--			'Turf', -- Track type
--			'1800m',--Distance
--			'01:20',null,null,null,
--			getdate()
--  )
-- 
--     INSERT INTO Raceinfo
-- VALUES (	@programid3,
--			@raceNo2,
--			'Turf', -- Track type
--			'1800m',--Distance
--			'01:20',null,null,null,
--			getdate()
--  )
-- 
--     INSERT INTO Raceinfo
-- VALUES (	@programid3,
--			@raceNo3,
--			'Turf', -- Track type
--			'1800m',--Distance
--			'01:20',null,null,null,
--			getdate()
--  )
-- 
-- 
--      INSERT INTO Raceinfo
-- VALUES (	@programid4,
--			@raceNo1,
--			'Turf', -- Track type
--			'1200m',--Distance
--			'01:00',null,null,null,
--			getdate()
--  )
-- 
-- 
--      INSERT INTO Raceinfo
-- VALUES (	@programid4,
--			@raceNo2,
--			'Turf', -- Track type
--			'1200m',--Distance
--			'01:00',null,null,null,
--			getdate()
--  )
-- 
-- 
--      INSERT INTO Raceinfo
-- VALUES (	@programid4,
--			@raceNo3,
--			'Turf', -- Track type
--			'1200m',--Distance
--			'01:00',null,null,null,
--			getdate()
--  )
-- 
 
--HRCode Table 
 ---------------------------------------------------------
--Horses (team)
--INSERT INTO team(teamname,teamnamec,teamdesc,creator,teamnamesc,teamnamec_uni,teamnamej,teamnamecn)
--SELECT 'Amorts',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'White Amorts',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Shantahliatrailblaza Lanta',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Shantahliatrailblaza',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION
--SELECT 'Merrywood Prince',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Just Pretend',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Blue Oceans',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Misty Miller',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Gotashotaway',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Jarendan',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Jarendan Most',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Butler On Duty',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Mighty Dane',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Regal Knight',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Bombardier',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Is Lucky',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Is Lucky Deja',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Bay Of Island',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Bay Of African Island',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Val Algeo',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Val Deja Vu',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Cullenator',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Fifth Avenue',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Lucero De Gloria',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Astronomy',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Black List',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Fabiani Raja',NULL,'Horse',8,NULL,NULL,NULL,NULL
--UNION ALL
--SELECT 'Fingal ',NULL,'Horse',8,NULL,NULL,NULL,NULL 
--UNION ALL
--SELECT 'Pink Dollar',NULL,'Horse',8,NULL,NULL,NULL,NULL 
--UNION ALL
--SELECT 'Fort Vogue',NULL,'Horse',8,NULL,NULL,NULL,NULL 
--UNION ALL
--SELECT 'The Rookie Deja ',NULL,'Horse',8,NULL,NULL,NULL,NULL 
--UNION ALL
--SELECT 'National Theme',NULL,'Horse',8,NULL,NULL,NULL,NULL 
--UNION ALL
--SELECT 'Ferchard',NULL,'Horse',8,NULL,NULL,NULL,NULL 
--UNION ALL
--SELECT 'Ferchard Hilton',NULL,'Horse',8,NULL,NULL,NULL,NULL 
--UNION ALL
--SELECT 'Hospitality',NULL,'Horse',8,NULL,NULL,NULL,NULL 
--UNION ALL
--SELECT 'Astronast',NULL,'Horse',8,NULL,NULL,NULL,NULL 
--UNION ALL
--SELECT 'City of Royal Light ',NULL,'Horse',8,NULL,NULL,NULL,NULL 
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
           ,[HorseJockey]
           ,[HorseDraw]
           ,[HorseWgt]
           ,[PlaceOdds]
           ,[Placing]
           ,[IsFavor]
           ,[IsSCR]
           ,[HorseTrainer]
           ,[Colours])
--meeting1------------------------------
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), 
   DATEADD(day, 1, GetDate()), 
   'running',
   round((10*rand() + 2),2), --win odds 
   1000000,0,
   '01',--matchcode
   @raceNo1,--groupmatch
   'running',
    8,
    0,
    0,
    1,
    @programid1, 
   'M Khan',
   '10',--Horse Draw 
   '58', -- Horse Wgt
   round((5*rand() + 2),2), --Place Odds 
   0, --placing 
   1, --TF
   0, --SCR 
   'B Marcus',--Horse Trainer 
   null
FROM HRCode with (nolock) where CodeNameEn IN('HAPTHOR')AND creator=151
UNION ALL
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), 
   DATEADD(day, 1, GetDate()), 
  'running',
  round((10*rand() + 2),2),
   1000000,0,
   '02',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,@programid1,
   'R Khathi',
   '12',
   '56',
   round((5*rand() + 2),2),
   0,
   0,
   0,
      'W G Prestage',null
FROM HRCode with (nolock) where CodeNameEn IN('STORMY BEECH')AND creator=151
UNION ALL
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), 
   DATEADD(day, 1, GetDate()), 
   'running',
   round((10*rand() + 2),2),
   1000000,0,
   '03',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,@programid1,
   'N Roebuck',
   '9',
   '56',
  round((5*rand() + 2),2),
   0,0,1,
   'G S Kotzen',null
FROM HRCode with (nolock) where CodeNameEn IN('SNOWY (IRE)')AND creator=151
UNION ALL 
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '04',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,@programid1,
   'G Cheyne',
   '15',
   '56',
   round((5*rand() + 2),2),
   0,0,0,
    'G S Steyn',null  

FROM HRCode with (nolock) where CodeNameEn IN('BALAKAR (IRE)')AND creator=151
UNION ALL 
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '05',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,@programid1,
   'D Behr',
   '18',
   '56',
   round((5*rand() + 2),2),
   0,0,1,
      'G S Kannemeyer',null

FROM HRCode with (nolock) where CodeNameEn IN('DIVEX (IRE)')AND creator=151
UNION ALL
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '12',--matchcode
   @raceNo2,--groupmatch
   'running',8,0,0,1,@programid1,
   'D Behr',
   '18',
   '56',
   round((5*rand() + 2),2),
   0,0,1,
   'G S Kannemeyer', null
FROM HRCode with (nolock) where CodeNameEn IN('YANKEE HOLIDAY (IRE)')AND creator=151
UNION ALL
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '22',--matchcode
    @raceNo2,--groupmatch
   'running',8,0,0,1,@programid1,
   'Domeyer',
   '2',
   '56',
   round((5*rand() + 2),2),
   0,0,0,
      'Elley', null
FROM HRCode with (nolock) where CodeNameEn IN('OCEAN DANCER')AND creator=151
UNION ALL


SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '01',--matchcode
    @raceNo2,--groupmatch
   'running',8,0,0,1,@programid1,
   'Orffer',
   '5',
   '56',
   round((5*rand() + 2),2),
   0,1,0,
   'Kotzen',null
FROM HRCode with (nolock) where CodeNameEn IN('MR TWINS (ARG)')AND creator=151

UNION ALL
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '05',--matchcode
    @raceNo2,--groupmatch
   'running',8,0,0,1,@programid1,
   'Winnaarr',
   '14',
   '56',
   round((5*rand() + 2),2),
   0,0,0,
   'Snaith',null
FROM HRCode with (nolock) where CodeNameEn IN('KINGS ENVOY (USA)')AND creator=151

UNION ALL
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '06',--matchcode
    @raceNo2,--groupmatch
   'running',8,0,0,1,@programid1,
   'Fourei',
   '8',
   '56',
   round((5*rand() + 2),2),
   0,0,0,
   'TF Kannemeyer', null
FROM HRCode with (nolock) where CodeNameEn IN('CHORD')AND creator=151

UNION ALL
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '15',--matchcode
    @raceNo2,--groupmatch
   'running',8,0,0,1,@programid1,
   'D Behr',
   '18',
   '56',
   round((5*rand() + 2),2),
   0,0,0,
   'Bass', null
FROM HRCode with (nolock) where CodeNameEn IN('DIVERS (FR)')AND creator=151

UNION ALL
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '14',--matchcode
    @raceNo2,--groupmatch
   'running',8,0,0,1,@programid1,
   'Fayd Herbe',
   '13',
   '56',
   round((5*rand() + 2),2),
   0,0,0,
   'Style',null
FROM HRCode with (nolock) where CodeNameEn IN('EVEN SMARTER')AND creator=151

UNION ALL
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '08',--matchcode
    @raceNo2,--groupmatch
   'running',8,0,0,1,@programid1,
   'D Behr',
   '18',
   '56',
   round((5*rand() + 2),2),
   0,0,0,
   'G S Kannemeyer', null
FROM HRCode with (nolock) where CodeNameEn IN('KING OF THE TITANS (IRE)')AND creator=151

UNION ALL
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '06',--matchcode
   @raceNo3,--groupmatch
   'running',8,0,0,1,@programid1,
   'D Behr',
   '18',
   '56',
   round((5*rand() + 2),2),
   0,0,0,
   'G S Kannemeyer',null
FROM HRCode with (nolock) where CodeNameEn IN('MASTERS HOUSE (IRE)')AND creator=151

UNION ALL
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((5*rand() + 2),2),
   1000000,0,
   '09',--matchcode
   @raceNo3,--groupmatch
   'running',8,0,0,1,@programid1,
   'D Behr',
   '18',
   '56',
   round((5*rand() + 2),2),
   0,0,0,
      'G S Kannemeyer',null
FROM HRCode with (nolock) where CodeNameEn IN('PERCUTANT (FR)')AND creator=151

UNION ALL
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '19',--matchcode
   @raceNo3,--groupmatch
   'running',8,0,0,1,@programid1,
   'D Behr',
   '18',
   '56',
   round((5*rand() + 2),2),
   0,0,0,  'G S Kannemeyer',null
FROM HRCode with (nolock) where CodeNameEn IN('ALMOND COURT (IRE)')AND creator=151

UNION ALL
SELECT 
   @Meeting1,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '21',--matchcode
   @raceNo3,--groupmatch
   'running',8,0,0,1,@programid1,
   'D Behr',
   '18',
   '56',
   round((5*rand() + 2),2),
   0,1,0,   'G S Kannemeyer',null
FROM HRCode with (nolock) where CodeNameEn IN('SPELLCHECKER (IRE)')AND creator=151

----meeting2------------------------------------
UNION ALL
SELECT 
   @Meeting2,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '01',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,
   @programid2,
   'Schlechter',
   '11',
   '56',
   round((5*rand() + 2),2),
   0,1,0,    'Hodgson',null
FROM HRCode with (nolock) where CodeNameEn IN('ALMOND COURT (IRE)')AND creator=151

UNION ALL
SELECT 
   @Meeting2,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '01',--matchcode
   @raceNo2,--groupmatch
   'running',8,0,0,1,
    @programid2,
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0,    'Hodgson',null
FROM HRCode with (nolock) where CodeNameEn IN('BALLYMURPHY LADY (IRE)')AND creator=151
UNION ALL
SELECT 
   @Meeting2,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '22',--matchcode
   @raceNo1,--groupmatch
  'running',8,0,0,1,
	@programid2,
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0,
       'G S Kannemeyer',null
FROM HRCode with (nolock) where CodeNameEn IN('AND WHATEVER ELSE (IRE)')AND creator=151
UNION ALL
SELECT 
   @Meeting2,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '04',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,
    @programid2,
   'D Behr',
   '18',
   '57',
  round((5*rand() + 2),2),
   0,0,0,'G S Kannemeyer',null
   
FROM HRCode with (nolock) where CodeNameEn IN('ELLA MACCADELLA')AND creator=151
----meeting3------------------------------------
UNION ALL
SELECT 
   @Meeting3,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '01',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,
    @programid3,
   'Reserve 1',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0,'Stewart',null
FROM HRCode with (nolock) where CodeNameEn IN('ROMANCE DANCE')AND creator=151
UNION ALL
SELECT 
   @Meeting3,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '02',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,
    @programid3,
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0,'Stewart',null
FROM HRCode with (nolock) where CodeNameEn IN('STARBOUGG')AND creator=151

UNION ALL
SELECT 
   @Meeting3,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '01',--matchcode
   @raceNo2,--groupmatch
   'running',8,0,0,1,
    @programid3,
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0,'G S Kannemeyer',null
FROM HRCode with (nolock) where CodeNameEn IN('ANDIJAN (IRE)')AND creator=151

UNION ALL
SELECT 
   @Meeting3,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '02',--matchcode
   @raceNo2,--groupmatch
  'running',8,0,0,1,
    @programid3,
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0,'G S Kannemeyer', null
FROM HRCode with (nolock) where CodeNameEn IN('ANGLICISME (FR)')AND creator=151

--meeting4------------------------------------
UNION ALL
SELECT 
   @Meeting4,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '01',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,
     @programid4,
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0,'G S Kannemeyer',null
FROM HRCode with (nolock) where CodeNameEn IN('ASTON LAD')AND creator=151

UNION ALL
SELECT 
   @Meeting4,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '02',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,
     @programid4,
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0,'G S Kannemeyer',null
FROM HRCode with (nolock) where CodeNameEn IN('BEN TIRRAN')AND creator=151

UNION ALL
SELECT 
   @Meeting4,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '03',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,
     @programid4,
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0,'G S Kannemeyer',null
FROM HRCode with (nolock) where CodeNameEn IN('GUNS AND BUTTER (IRE)')AND creator=151
UNION ALL
SELECT 
   @Meeting4,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '04',--matchcode
   @raceNo1,--groupmatch
   'running',8,0,0,1,
     @programid4,
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,1,'G S Kannemeyer',null
FROM HRCode with (nolock) where CodeNameEn IN('HERNANDO S BOY')AND creator=151
UNION ALL
SELECT 
   @Meeting4,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '05',--matchcode
  @raceNo1,--groupmatch
   'running',8,0,0,1,
     @programid4,
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0,'G S Kannemeyer', null
FROM HRCode with (nolock) where CodeNameEn IN('HIGH BIRD HUMPHREY')AND creator=151
UNION ALL
SELECT 
   @Meeting4,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '01',--matchcode
   @raceNo2,--groupmatch
   'running',8,0,0,1,
     @programid4,
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0,'G S Kannemeyer', null
FROM HRCode with (nolock) where CodeNameEn IN('LABOREC (IRE)')AND creator=151
UNION ALL
SELECT 
   @Meeting4,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '02',--matchcode
   @raceNo2,--groupmatch
   'running',8,0,0,1,
    @programid4,
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0,'G S Kannemeyer',null
FROM HRCode with (nolock) where CodeNameEn IN('MAT HILL (IRE)')AND creator=151
UNION ALL
SELECT 
   @Meeting4,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '03',--matchcode
   @raceNo2,--groupmatch
   'running',8,0,0,1,
     @programid4,
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0,'G S Kannemeyer',null
FROM HRCode with (nolock) where CodeNameEn IN('PAMAK DAIRY (FR)')AND creator=151
UNION ALL
SELECT 
   @Meeting4,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '11',--matchcode
   @raceNo3,--groupmatch
   'running',8,0,0,1,
    @programid4,
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,0,'G S Kannemeyer',null
FROM HRCode with (nolock) where CodeNameEn IN('ROOKERY REBEL (IRE)')AND creator=151
UNION ALL
SELECT 
   @Meeting4,--leagueid
   codeid,--teamid
   convert(varchar(10), getdate(), 120), DATEADD(day, 1, GetDate()), 'running',
   round((10*rand() + 2),2),
   1000000,0,
   '12',--matchcode
   @raceNo3,--groupmatch
   'running',8,0,0,1,
     @programid4,
   'D Behr',
   '18',
   '57',
   round((5*rand() + 2),2),
   0,0,1,'G S Kannemeyer',null
FROM HRCode with (nolock) where CodeNameEn IN('SADLERS COVE (FR)')AND creator=151 