 
/******Use to run sp below
Declare @ErrCode int
Declare @ErrMsg nvarchar(4000)
---------------------------------
EXEC dbo.DBA_CustomerIns_SMA 
@site = 'Bet8',
@currency = 9,
@ErrCode = @ErrCode OUTPUT,
@ErrMsg = @ErrMsg OUTPUT
---------------------------------
select 
@ErrCode as ErrCode,
@ErrMsg as ErrMsg
*/



ALTER PROCEDURE [dbo].[DBA_CustomerIns_SMA]  
 @site nvarchar(10),  
 @currency int,  
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT  
   
AS  

/**********************************************************************************
***************************Create new licensee line *******************************
***********************************************************************************/
-- Admin info and IP
DECLARE @creator int , @pwd nvarchar(40) 
DECLARE @IP nvarchar(15)

-- Account info
DECLARE @SuperID INT, @MasterID INT, @MasterDummyID INT, @AgentID INT, @AgentDummyID INT, @MemberID INT

DECLARE @Super_Username nvarchar(50)
, @Master_Username nvarchar(50)
, @MasterDummy_Username nvarchar(50)
, @Agent_Username nvarchar(50)
, @AgentDummy_Username nvarchar(50)
, @Member_Username nvarchar(50)

-- Site, currency  info 
--DECLARE @site nvarchar(10)
--DECLARE @currency int
DECLARE @currency_name nvarchar(5)

-- Error info
-- Error info
-- DECLARE @ErrCode int, @ErrMsg nvarchar(4000)


DECLARE @minbet MONEY,@maxbet MONEY, @maxpermatch MONEY
DECLARE @NG_minbet MONEY,@NG_maxbet MONEY, @NG_maxpermatch MONEY, @NG_maxperball MONEY

DECLARE @PT SMALLMONEY, @NG_PT SMALLMONEY 

DECLARE @tmpMember table (id SMALLINT,username nvarchar(50),isCreated bit)
DECLARE @tmpBetlimit table (currency int primary key,minbet MONEY,maxbet MONEY, maxpermatch MONEY)

-------------------------------------------------------------------------------------------------------------------
-- SET values----------- ------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
SELECT @creator = 8218004,@pwd='82D858C18360880664810DB8457F8D'

--SELECT @site = 'Bet8', @currency = 2

SELECT @PT = 0.85, @NG_PT = 0.85

SELECT @currency_name = currency FROM exchange with (nolock) WHERE exchangeid = @currency
SELECT @Super_Username = @site + 'Super' + @currency_name
SELECT @Master_Username = @site + @currency_name
SELECT @Agent_Username = @Master_Username + '01'
SELECT @MasterDummy_Username =  @site + 'ACC'+ @currency_name
SELECT @AgentDummy_Username = @MasterDummy_Username + '01'

-- Member Dummy list 
INSERT INTO @tmpMember 
SELECT 1,Convert (nvarchar(50),@site + 'Transfer' + @currency_name), 0
UNION ALL SELECT 2,Convert (nvarchar(50),@site + 'Charges' + @currency_name), 0
UNION ALL SELECT 3,Convert (nvarchar(50),@site + 'Bonus' + @currency_name), 0
UNION ALL SELECT 4,Convert (nvarchar(50),@site + 'Withdrawal' + @currency_name), 0

-- Currency - Bet limit values 
INSERT INTO @tmpBetlimit  
SELECT 13,1,500000,2000000 --RMB(CNY)
UNION ALL SELECT 4,1,2500000,10000000-- TB(THB)
UNION ALL SELECT 34,1,750000,3000000 -- IDR
UNION ALL SELECT 51,1,1500000,6000000 --INH(VND)
UNION ALL SELECT 2,1,250000,1000000 -- MYR
UNION ALL SELECT 3,1,75000,500000-- USD
UNION ALL SELECT 9,1,75000,500000 -- AUD
UNION ALL SELECT 6,1,10000,100000 -- EUR
UNION ALL SELECT 12,1,10000,100000 --GBP
UNION ALL SELECT 32,1,7000000,28000000 --JPY
UNION ALL SELECT 61,1,4000000,16000000 --INR

-- Get bet limit based on currency 
SELECT @minbet = minbet ,@maxbet = maxbet , @maxpermatch = maxpermatch
       FROM @tmpBetlimit 
WHERE currency = @currency

-------------------------------------------------------------------------------------------------------------------
-- Check currency --------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

IF (isnull(@minbet,0) = 0 ) RETURN

-------------------------------------------------------------------------------------------------------------------
-- Check line exists--------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
IF Exists (select 1  FROM Customer WITH (NOLOCK) WHERE site = @site and currency = @currency and roleid = 4) RETURN

-------------------------------------------------------------------------------------------------------------------
-- 1. Create new super --------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

EXEC Acc_Dep_CustomerInsMember_Com 
 @custid=@SuperID output,@creator=@creator,@username=@Super_Username,@userpwd=@pwd,@site=@site ,@currency=@currency

-- Sportbook bet limit 
,@MinBetv1=@minbet,@MaxBetv1=@maxbet,@MaxPerMatchv1=@maxpermatch
,@MinBetv2=@minbet,@MaxBetv2=@maxbet,@MaxPerMatchv2=@maxpermatch
,@MinBetv3=@minbet,@MaxBetv3=@maxbet,@MaxPerMatchv3=@maxpermatch
,@MinBetv5=@minbet,@MaxBetv5=@maxbet,@MaxPerMatchv5=@maxpermatch
,@MinBetv8=@minbet,@MaxBetv8=@maxbet,@MaxPerMatchv8=@maxpermatch
,@MinBetv10=@minbet,@MaxBetv10=@maxbet,@MaxPerMatchv10=@maxpermatch
,@MinBetv11=@minbet,@MaxBetv11=@maxbet,@MaxPerMatchv11=@maxpermatch
,@MinBetv99=@minbet,@MaxBetv99=@maxbet,@MaxPerMatchv99=@maxpermatch
,@MinBetv99MP=@minbet,@MaxBetv99MP=@maxbet,@MaxPerMatchv99MP=@maxpermatch

-- Number Game bet limit
,@MinBetv161=0.0000,@MaxBetv161=0.0000,@MaxPerMatchv161=0.0000,@MaxPerBallv161=0.0000

-- Racing bet limit

,@v151minbet_31=0.0000,@v151maxbet_31=0.0000,@v151maxpermatch_31=0.0000,@v151minbet_41=0.0000,@v151maxbet_41=0.0000,@v151maxpermatch_41=0.0000,@v151minbet_51=0.0000,@v151maxbet_51=0.0000,@v151maxpermatch_51=0.0000
,@v152minbet_41=0.0000,@v152maxbet_41=0.0000,@v152maxpermatch_41=0.0000,@v152minbet_51=0.0000,@v152maxbet_51=0.0000,@v152maxpermatch_51=0.0000
,@v153minbet_51=0.0000,@v153maxbet_51=0.0000,@v153maxpermatch_51=0.0000

-- Sportbook  sPT
,@v1spositiontaking_1=@PT,@v1spositiontaking_2=@PT,@v1spositiontaking_3=@PT,@v1spositiontaking_4=@PT,@v1spositiontaking_5=@PT
,@v1spositiontaking_6=@PT,@v1spositiontaking_7=@PT,@v1spositiontaking_8=@PT,@v1spositiontaking_9=@PT,@v1spositiontaking_10=@PT
,@v1slivepositiontaking_1=@PT,@v1slivepositiontaking_3=@PT,@v1slivepositiontaking_7=@PT,@v1slivepositiontaking_8=@PT

,@v2spositiontaking_1=@PT,@v2spositiontaking_2=@PT,@v2spositiontaking_3=@PT,@v2spositiontaking_7=@PT,@v2spositiontaking_8=@PT,@v2spositiontaking_20=@PT

,@v3spositiontaking_1=@PT,@v3spositiontaking_2=@PT,@v3spositiontaking_3=@PT,@v3spositiontaking_20=@PT

,@v5spositiontaking_1=@PT,@v5spositiontaking_2=@PT,@v5spositiontaking_3=@PT,@v5spositiontaking_20=@PT

,@v8spositiontaking_1=@PT,@v8spositiontaking_3=@PT,@v8spositiontaking_20=@PT

,@v10spositiontaking_1=@PT,@v10spositiontaking_2=@PT,@v10spositiontaking_3=@PT,@v10spositiontaking_20=@PT

,@v11spositiontaking_1=@PT,@v11spositiontaking_20=@PT

,@v99spositiontaking_1=@PT,@v99spositiontaking_2=@PT,@v99spositiontaking_3=@PT,@v99spositiontaking_9=@PT,@v99spositiontaking_20=@NG_PT

-- NumberGame PT
,@v161spositiontaking_81=@NG_PT,@v161spositiontaking_83=@NG_PT,@v161spositiontaking_86=@NG_PT,@v161spositiontaking_88=@NG_PT,@v161slivepositiontaking_85=@NG_PT,@v161slivepositiontaking_86=@NG_PT
,@v161slivepositiontaking_87=@NG_PT,@v161slivepositiontaking_89=@NG_PT,@v161slivepositiontaking_90=@NG_PT

-- Racing PT 
,@v151spositiontaking_31=0.0000,@v151spositiontaking_32=0.0000,@v151spositiontaking_41=0.0000,@v151spositiontaking_42=0.0000,@v151spositiontaking_51=0.0000,@v151spositiontaking_52=0.0000
,@v152spositiontaking_41=0.0000,@v152spositiontaking_42=0.0000,@v152spositiontaking_51=0.0000,@v152spositiontaking_52=0.0000
,@v153spositiontaking_51=0.0000,@v153spositiontaking_52=0.0000


-- Sportbook mPT
,@v1mpositiontaking_1=@PT,@v1mpositiontaking_2=@PT,@v1mpositiontaking_3=@PT,@v1mpositiontaking_4=@PT,@v1mpositiontaking_5=@PT,@v1mpositiontaking_6=@PT
,@v1mpositiontaking_7=@PT,@v1mpositiontaking_8=@PT,@v1mpositiontaking_9=@PT,@v1mpositiontaking_10=@PT,@v1mlivepositiontaking_1=@PT
,@v1mlivepositiontaking_3=@PT,@v1mlivepositiontaking_7=@PT,@v1mlivepositiontaking_8=@PT

,@v2mpositiontaking_1=@PT,@v2mpositiontaking_2=@PT,@v2mpositiontaking_3=@PT,@v2mpositiontaking_7=@PT,@v2mpositiontaking_8=@PT,@v2mpositiontaking_20=@PT

,@v3mpositiontaking_1=@PT,@v3mpositiontaking_2=@PT,@v3mpositiontaking_3=@PT,@v3mpositiontaking_20=@PT

,@v5mpositiontaking_1=@PT,@v5mpositiontaking_2=@PT,@v5mpositiontaking_3=@PT,@v5mpositiontaking_20=@PT

,@v8mpositiontaking_1=@PT,@v8mpositiontaking_3=@PT,@v8mpositiontaking_20=@PT

,@v10mpositiontaking_1=@PT,@v10mpositiontaking_2=@PT,@v10mpositiontaking_3=@PT,@v10mpositiontaking_20=@PT

,@v11mpositiontaking_1=@PT,@v11mpositiontaking_20=@PT

,@v99mpositiontaking_1=@PT,@v99mpositiontaking_2=@PT,@v99mpositiontaking_3=@PT,@v99mpositiontaking_9=@PT,@v99mpositiontaking_20=@PT

-- NumberGame mPT
,@v161mpositiontaking_81=@NG_PT,@v161mpositiontaking_83=@NG_PT,@v161mpositiontaking_86=@NG_PT,@v161mpositiontaking_88=@NG_PT,@v161mlivepositiontaking_85=@NG_PT,@v161mlivepositiontaking_86=@NG_PT,@v161mlivepositiontaking_87=@NG_PT
,@v161mlivepositiontaking_89=@NG_PT,@v161mlivepositiontaking_90=@NG_PT

-- Racing mPT
,@v151mpositiontaking_31=0.0000,@v151mpositiontaking_32=0.0000,@v151mpositiontaking_41=0.0000,@v151mpositiontaking_42=0.0000,@v151mpositiontaking_51=0.0000,@v151mpositiontaking_52=0.0000

,@v152mpositiontaking_41=0.0000,@v152mpositiontaking_42=0.0000,@v152mpositiontaking_51=0.0000,@v152mpositiontaking_52=0.0000
,@v153mpositiontaking_51=0.0000,@v153mpositiontaking_52=0.0000

-- Sportbook aPT
,@v1apositiontaking_1=@PT,@v1apositiontaking_2=@PT,@v1apositiontaking_3=@PT,@v1apositiontaking_4=@PT,@v1apositiontaking_5=@PT,@v1apositiontaking_6=@PT
,@v1apositiontaking_7=@PT,@v1apositiontaking_8=@PT,@v1apositiontaking_9=@PT,@v1apositiontaking_10=@PT,@v1alivepositiontaking_1=@PT,@v1alivepositiontaking_3=@PT
,@v1alivepositiontaking_7=@PT,@v1alivepositiontaking_8=@PT

,@v2apositiontaking_1=@PT,@v2apositiontaking_2=@PT,@v2apositiontaking_3=@PT,@v2apositiontaking_7=@PT,@v2apositiontaking_8=@PT,@v2apositiontaking_20=@PT

,@v3apositiontaking_1=@PT,@v3apositiontaking_2=@PT,@v3apositiontaking_3=@PT,@v3apositiontaking_20=@PT

,@v5apositiontaking_1=@PT,@v5apositiontaking_2=@PT,@v5apositiontaking_3=@PT,@v5apositiontaking_20=@PT

,@v8apositiontaking_1=@PT,@v8apositiontaking_3=@PT,@v8apositiontaking_20=@PT

,@v10apositiontaking_1=@PT,@v10apositiontaking_2=@PT,@v10apositiontaking_3=@PT,@v10apositiontaking_20=@PT

,@v11apositiontaking_1=@PT,@v11apositiontaking_20=@PT

,@v99apositiontaking_1=@PT,@v99apositiontaking_2=@PT,@v99apositiontaking_3=@PT,@v99apositiontaking_9=@PT,@v99apositiontaking_20=@PT

-- Number Gaem aPT
,@v161apositiontaking_81=@NG_PT,@v161apositiontaking_83=@NG_PT,@v161apositiontaking_86=@NG_PT,@v161apositiontaking_88=@NG_PT,@v161alivepositiontaking_85=@NG_PT
,@v161alivepositiontaking_86=@NG_PT,@v161alivepositiontaking_87=@NG_PT,@v161alivepositiontaking_89=@NG_PT,@v161alivepositiontaking_90=@NG_PT

-- Racing aPT
,@v151apositiontaking_31=0.0000,@v151apositiontaking_32=0.0000,@v151apositiontaking_41=0.0000,@v151apositiontaking_42=0.0000,@v151apositiontaking_51=0.0000,@v151apositiontaking_52=0.0000

,@v152apositiontaking_41=0.0000,@v152apositiontaking_42=0.0000,@v152apositiontaking_51=0.0000,@v152apositiontaking_52=0.0000

,@v153apositiontaking_51=0.0000,@v153apositiontaking_52=0.0000

-- Racing IBC PT
,@v151IBCPositiontaking_31=0.0000,@v151IBCPositiontaking_41=0.0000,@v151IBCPositiontaking_51=0.0000

,@v152IBCPositiontaking_41=0.0000,@v152IBCPositiontaking_51=0.0000,@v153IBCPositiontaking_51=0.0000

-- Racing discount 
,@v151discount_31=0.00000000,@v151discount_41=0.00000000,@v151discount_51=0.00000000

,@v152discount_41=0.00000000,@v152discount_51=0.00000000,@v153discount_51=0.00000000

-- Racing enable/disable
,@Disable151_31=1,@Disable151_41=1,@Disable151_51=1
,@Disable152_41=1,@Disable152_51=1,@Disable153_51=1

-- Number Game enable/disable
,@DisableNumber=0

-- Virtual Sport bet limit
,@v180MinBet=0.0000,@v180MaxBet=0.0000,@v180MaxPerMatch=0.0000

-- Virtual Sport PT
,@v180sPositionTaking=0.0000,@v180mPositionTaking=0.0000,@v180aPositionTaking=0.0000

-- Virtual Sport enable/disable
,@DisableVirtualSports=1

-- IP , Langue and error info 
,@IP=@IP,@Language=default,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output

-------------------------------------------------------------------------------------------------------------------
-- 2. Create new master --------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

IF (@ErrCode > 0 or @SuperID < 0) RETURN

SELECT @ErrCode = 0, @ErrMsg = ''


EXEC Acc_Dep_CustomerInsMember_SAg
@custid=@MasterID output,@creator=@creator,@username=@Master_Username,@userpwd=@pwd,@srecommend=@SuperID

-- Racing enable/disable
,@Disable151_31=1,@Disable151_41=1,@Disable151_51=1,@Disable152_41=1,@Disable152_51=1,@Disable153_51=1

-- Number Game enable/disabel
,@DisableNumber=0

-- Sportbook bet limit
,@minbetv1=@minbet,@maxbetv1=@maxbet,@maxpermatchv1=@maxpermatch
,@minbetv2=@minbet,@maxbetv2=@maxbet,@maxpermatchv2=@maxpermatch
,@minbetv3=@minbet,@maxbetv3=@maxbet,@maxpermatchv3=@maxpermatch
,@minbetv5=@minbet,@maxbetv5=@maxbet,@maxpermatchv5=@maxpermatch
,@minbetv8=@minbet,@maxbetv8=@maxbet,@maxpermatchv8=@maxpermatch
,@minbetv10=@minbet,@maxbetv10=@maxbet,@maxpermatchv10=@maxpermatch
,@minbetv11=@minbet,@maxbetv11=@maxbet,@maxpermatchv11=@maxpermatch
,@minbetv99=@minbet,@maxbetv99=@maxbet,@maxpermatchv99=@maxpermatch
,@minbetv99mp=@minbet,@maxbetv99mp=@maxbet,@maxpermatchv99mp=@maxpermatch

-- Number Game bet limit
,@minbetv161=0.0000,@maxbetv161=0.0000,@maxpermatchv161=0.0000,@maxperballv161=0.0000

-- Racing bet limit
,@v151minbet_31=0.0000,@v151maxbet_31=0.0000,@v151maxpermatch_31=0.0000,@v151minbet_41=0.0000,@v151maxbet_41=0.0000,@v151maxpermatch_41=0.0000,@v151minbet_51=0.0000,@v151maxbet_51=0.0000,@v151maxpermatch_51=0.0000
,@v152minbet_41=0.0000,@v152maxbet_41=0.0000,@v152maxpermatch_41=0.0000,@v152minbet_51=0.0000,@v152maxbet_51=0.0000,@v152maxpermatch_51=0.0000
,@v153minbet_51=0.0000,@v153maxbet_51=0.0000,@v153maxpermatch_51=0.0000

-- Sportbook sPT
,@v1spositiontaking_1=@PT,@v1spositiontaking_2=@PT,@v1spositiontaking_3=@PT,@v1spositiontaking_4=@PT,@v1spositiontaking_5=@PT,@v1spositiontaking_6=@PT
,@v1spositiontaking_7=@PT,@v1spositiontaking_8=@PT,@v1spositiontaking_9=@PT,@v1spositiontaking_10=@PT,@v1slivepositiontaking_1=@PT
,@v1slivepositiontaking_3=@PT,@v1slivepositiontaking_7=@PT,@v1slivepositiontaking_8=@PT

,@v2spositiontaking_1=@PT,@v2spositiontaking_2=@PT,@v2spositiontaking_3=@PT,@v2spositiontaking_7=@PT,@v2spositiontaking_8=@PT,@v2spositiontaking_20=@PT

,@v3spositiontaking_1=@PT,@v3spositiontaking_2=@PT,@v3spositiontaking_3=@PT,@v3spositiontaking_20=@PT

,@v5spositiontaking_1=@PT,@v5spositiontaking_2=@PT,@v5spositiontaking_3=@PT,@v5spositiontaking_20=@PT

,@v8spositiontaking_1=@PT,@v8spositiontaking_3=@PT,@v8spositiontaking_20=@PT

,@v10spositiontaking_1=@PT,@v10spositiontaking_2=@PT,@v10spositiontaking_3=@PT,@v10spositiontaking_20=@PT

,@v11spositiontaking_1=@PT,@v11spositiontaking_20=@PT

,@v99spositiontaking_1=@PT,@v99spositiontaking_2=@PT,@v99spositiontaking_3=@PT,@v99spositiontaking_20=@PT,@v99spositiontaking_9=@PT

-- NumberGame sPT
,@v161spositiontaking_81=@NG_PT,@v161spositiontaking_83=@NG_PT,@v161spositiontaking_86=@NG_PT,@v161spositiontaking_88=@NG_PT,@v161slivepositiontaking_85=@NG_PT
,@v161slivepositiontaking_86=@NG_PT,@v161slivepositiontaking_87=@NG_PT,@v161slivepositiontaking_89=@NG_PT,@v161slivepositiontaking_90=@NG_PT

-- Racing sPT
,@v151spositiontaking_31=0.0000,@v151spositiontaking_32=0.0000,@v151spositiontaking_41=0.0000,@v151spositiontaking_42=0.0000,@v151spositiontaking_51=0.0000,@v151spositiontaking_52=0.0000

,@v152spositiontaking_41=0.0000,@v152spositiontaking_42=0.0000,@v152spositiontaking_51=0.0000,@v152spositiontaking_52=0.0000

,@v153spositiontaking_51=0.0000,@v153spositiontaking_52=0.0000


-- Sportbook mPT
,@v1mpositiontaking_1=@PT,@v1mpositiontaking_2=@PT,@v1mpositiontaking_3=@PT,@v1mpositiontaking_4=@PT,@v1mpositiontaking_5=@PT,@v1mpositiontaking_6=@PT
,@v1mpositiontaking_7=@PT,@v1mpositiontaking_8=@PT,@v1mpositiontaking_9=@PT,@v1mpositiontaking_10=@PT,@v1mlivepositiontaking_1=@PT
,@v1mlivepositiontaking_3=@PT,@v1mlivepositiontaking_7=@PT,@v1mlivepositiontaking_8=@PT

,@v2mpositiontaking_1=@PT,@v2mpositiontaking_2=@PT,@v2mpositiontaking_3=@PT,@v2mpositiontaking_7=@PT,@v2mpositiontaking_8=@PT,@v2mpositiontaking_20=@PT

,@v3mpositiontaking_1=@PT,@v3mpositiontaking_2=@PT,@v3mpositiontaking_3=@PT,@v3mpositiontaking_20=@PT

,@v5mpositiontaking_1=@PT,@v5mpositiontaking_2=@PT,@v5mpositiontaking_3=@PT,@v5mpositiontaking_20=@PT

,@v8mpositiontaking_1=@PT,@v8mpositiontaking_3=@PT,@v8mpositiontaking_20=@PT

,@v10mpositiontaking_1=@PT,@v10mpositiontaking_2=@PT,@v10mpositiontaking_3=@PT,@v10mpositiontaking_20=@PT

,@v11mpositiontaking_1=@PT,@v11mpositiontaking_20=@PT

,@v99mpositiontaking_1=@PT,@v99mpositiontaking_2=@PT,@v99mpositiontaking_3=@PT,@v99mpositiontaking_20=@PT,@v99mpositiontaking_9=@PT

-- Number Game mPT
,@v161mpositiontaking_81=@NG_PT,@v161mpositiontaking_83=@NG_PT,@v161mpositiontaking_86=@NG_PT,@v161mpositiontaking_88=@NG_PT,@v161mlivepositiontaking_85=@NG_PT
,@v161mlivepositiontaking_86=@NG_PT,@v161mlivepositiontaking_87=@NG_PT,@v161mlivepositiontaking_89=@NG_PT,@v161mlivepositiontaking_90=@NG_PT

-- Racing mPT
,@v151mpositiontaking_31=0.0000,@v151mpositiontaking_32=0.0000,@v151mpositiontaking_41=0.0000,@v151mpositiontaking_42=0.0000,@v151mpositiontaking_51=0.0000,@v151mpositiontaking_52=0.0000

,@v152mpositiontaking_41=0.0000,@v152mpositiontaking_42=0.0000,@v152mpositiontaking_51=0.0000,@v152mpositiontaking_52=0.0000

,@v153mpositiontaking_51=0.0000,@v153mpositiontaking_52=0.0000

-- Racing discount
,@v151discount_31=0.00000000,@v151discount_41=0.00000000,@v151discount_51=0.00000000
,@v152discount_41=0.00000000,@v152discount_51=0.00000000
,@v153discount_51=0.00000000


-- Virtual sport PT
,@v180sPositionTaking=0.0000,@v180mPositionTaking=0.0000

-- Virtual sport bet limit
,@v180MinBet=0.0000,@v180MaxBet=0.0000,@v180MaxPerMatch=0.0000

-- IP, Languague and error info 
,@IP=@IP, @Language=default, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output


-------------------------------------------------------------------------------------------------------------------
-- 3. Create new Agent --------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

IF (@ErrCode > 0 or @MasterID < 0) RETURN

SELECT @ErrCode = 0, @ErrMsg = ''



EXEC Acc_Dep_CustomerInsMember_MAg 
@custid=@AgentID output,@creator=@creator,@username=@Agent_Username,@userpwd=@pwd,@mrecommend=@MasterID

-- Racing enable/disble
,@Disable151_31=1,@Disable151_41=1,@Disable151_51=1,@Disable152_41=1,@Disable152_51=1,@Disable153_51=1

-- NumberGane enable/disable
,@DisableNumber=0

-- Sportbook bet limit
,@MinBetv1=@minbet,@MaxBetv1=@maxbet,@MaxPerMatchv1=@maxpermatch
,@MinBetv2=@minbet,@MaxBetv2=@maxbet,@MaxPerMatchv2=@maxpermatch
,@MinBetv3=@minbet,@MaxBetv3=@maxbet,@MaxPerMatchv3=@maxpermatch
,@MinBetv5=@minbet,@MaxBetv5=@maxbet,@MaxPerMatchv5=@maxpermatch
,@MinBetv8=@minbet,@MaxBetv8=@maxbet,@MaxPerMatchv8=@maxpermatch
,@MinBetv10=@minbet,@MaxBetv10=@maxbet,@MaxPerMatchv10=@maxpermatch
,@MinBetv11=@minbet,@MaxBetv11=@maxbet,@MaxPerMatchv11=@maxpermatch
,@MinBetv99=@minbet,@MaxBetv99=@maxbet,@MaxPerMatchv99=@maxpermatch
,@MinBetv99mp=@minbet,@MaxBetv99mp=@maxbet,@MaxPerMatchv99mp=@maxpermatch

-- NumberGame bet limit
,@MinBetv161=0.0000,@MaxBetv161=0.0000,@MaxPerMatchv161=0.0000,@MaxPerBallv161=0.0000

-- Racing bet limit
,@v151minbet_31=0.0000,@v151maxbet_31=0.0000,@v151maxpermatch_31=0.0000,@v151minbet_41=0.0000,@v151maxbet_41=0.0000,@v151maxpermatch_41=0.0000,@v151minbet_51=0.0000,@v151maxbet_51=0.0000,@v151maxpermatch_51=0.0000
,@v152minbet_41=0.0000,@v152maxbet_41=0.0000,@v152maxpermatch_41=0.0000,@v152minbet_51=0.0000,@v152maxbet_51=0.0000,@v152maxpermatch_51=0.0000
,@v153minbet_51=0.0000,@v153maxbet_51=0.0000,@v153maxpermatch_51=0.0000

-- Sportbook aPT
,@v1apositiontaking_1=@PT,@v1apositiontaking_2=@PT,@v1apositiontaking_3=@PT,@v1apositiontaking_4=@PT,@v1apositiontaking_5=@PT,@v1apositiontaking_6=@PT
,@v1apositiontaking_7=@PT,@v1apositiontaking_8=@PT,@v1apositiontaking_9=@PT,@v1apositiontaking_10=@PT
,@v1alivepositiontaking_1=@PT,@v1alivepositiontaking_3=@PT,@v1alivepositiontaking_7=@PT,@v1alivepositiontaking_8=@PT

,@v2apositiontaking_1=@PT,@v2apositiontaking_2=@PT,@v2apositiontaking_3=@PT,@v2apositiontaking_7=@PT,@v2apositiontaking_8=@PT,@v2apositiontaking_20=@PT
,@v3apositiontaking_1=@PT,@v3apositiontaking_2=@PT,@v3apositiontaking_3=@PT,@v3apositiontaking_20=@PT
,@v5apositiontaking_1=@PT,@v5apositiontaking_2=@PT,@v5apositiontaking_3=@PT,@v5apositiontaking_20=@PT
,@v8apositiontaking_1=@PT,@v8apositiontaking_3=@PT,@v8apositiontaking_20=@PT
,@v10apositiontaking_1=@PT,@v10apositiontaking_2=@PT,@v10apositiontaking_3=@PT,@v10apositiontaking_20=@PT
,@v11apositiontaking_1=@PT,@v11apositiontaking_20=@PT
,@v99apositiontaking_1=@PT,@v99apositiontaking_2=@PT,@v99apositiontaking_3=@PT,@v99apositiontaking_20=@PT,@v99apositiontaking_9=@PT

-- NumberGame aPT
,@v161apositiontaking_81=@NG_PT,@v161apositiontaking_83=@NG_PT,@v161apositiontaking_86=@NG_PT,@v161apositiontaking_88=@NG_PT,@v161alivepositiontaking_85=@NG_PT
,@v161alivepositiontaking_86=@NG_PT,@v161alivepositiontaking_87=@NG_PT,@v161alivepositiontaking_89=@NG_PT,@v161alivepositiontaking_90=@NG_PT

-- Racing aPT
,@v151apositiontaking_31=0.0000,@v151apositiontaking_32=0.0000,@v151apositiontaking_41=0.0000,@v151apositiontaking_42=0.0000,@v151apositiontaking_51=0.0000,@v151apositiontaking_52=0.0000
,@v152apositiontaking_41=0.0000,@v152apositiontaking_42=0.0000,@v152apositiontaking_51=0.0000,@v152apositiontaking_52=0.0000
,@v153apositiontaking_51=0.0000,@v153apositiontaking_52=0.0000


-- Sportbook mPT
,@v1mpositiontaking_1=@PT,@v1mpositiontaking_2=@PT,@v1mpositiontaking_3=@PT,@v1mpositiontaking_4=@PT,@v1mpositiontaking_5=@PT,@v1mpositiontaking_6=@PT
,@v1mpositiontaking_7=@PT,@v1mpositiontaking_8=@PT,@v1mpositiontaking_9=@PT,@v1mpositiontaking_10=@PT,@v1mlivepositiontaking_1=@PT
,@v1mlivepositiontaking_3=@PT,@v1mlivepositiontaking_7=@PT,@v1mlivepositiontaking_8=@PT

,@v2mpositiontaking_1=@PT,@v2mpositiontaking_2=@PT,@v2mpositiontaking_3=@PT,@v2mpositiontaking_7=@PT,@v2mpositiontaking_8=@PT,@v2mpositiontaking_20=@PT
,@v3mpositiontaking_1=@PT,@v3mpositiontaking_2=@PT,@v3mpositiontaking_3=@PT,@v3mpositiontaking_20=@PT
,@v5mpositiontaking_1=@PT,@v5mpositiontaking_2=@PT,@v5mpositiontaking_3=@PT,@v5mpositiontaking_20=@PT
,@v8mpositiontaking_1=@PT,@v8mpositiontaking_3=@PT,@v8mpositiontaking_20=@PT
,@v10mpositiontaking_1=@PT,@v10mpositiontaking_2=@PT,@v10mpositiontaking_3=@PT,@v10mpositiontaking_20=@PT
,@v11mpositiontaking_1=@PT,@v11mpositiontaking_20=@PT
,@v99mpositiontaking_1=@PT,@v99mpositiontaking_2=@PT,@v99mpositiontaking_3=@PT,@v99mpositiontaking_20=@PT,@v99mpositiontaking_9=@PT

-- NumberGame mPT
,@v161mpositiontaking_81=@NG_PT,@v161mpositiontaking_83=@NG_PT,@v161mpositiontaking_86=@NG_PT,@v161mpositiontaking_88=@NG_PT,@v161mlivepositiontaking_85=@NG_PT
,@v161mlivepositiontaking_86=@NG_PT,@v161mlivepositiontaking_87=@NG_PT,@v161mlivepositiontaking_89=@NG_PT,@v161mlivepositiontaking_90=@NG_PT

-- Racing mPT
,@v151mpositiontaking_31=0.0000,@v151mpositiontaking_32=0.0000,@v151mpositiontaking_41=0.0000,@v151mpositiontaking_42=0.0000,@v151mpositiontaking_51=0.0000,@v151mpositiontaking_52=0.0000
,@v152mpositiontaking_41=0.0000,@v152mpositiontaking_42=0.0000,@v152mpositiontaking_51=0.0000,@v152mpositiontaking_52=0.0000
,@v153mpositiontaking_51=0.0000,@v153mpositiontaking_52=0.0000

-- Racing discount
,@v151discount_31=0.00000000,@v151discount_41=0.00000000,@v151discount_51=0.00000000,@v152discount_41=0.00000000,@v152discount_51=0.00000000,@v153discount_51=0.00000000

-- Virtual sport PT
,@v180aPositionTaking=0.0000,@v180mPositionTaking=0.0000

-- Virtual Sport bet limit

,@v180MinBet=0.0000,@v180MaxBet=0.0000,@v180MaxPerMatch=0.0000

-- IP, Language and error info 
,@IP=@IP,@Language=default,@SubAccID=default,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output


-------------------------------------------------------------------------------------------------------------------
-- 4. Reset bet limit and PT for Dummy accounts -------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
SELECT @minbet = 0,@maxbet = 0, @maxpermatch = 0
SELECT @NG_minbet = 0,@NG_maxbet = 0, @NG_maxpermatch = 0, @NG_maxperball = 0
SELECT @PT = 0 , @NG_PT = 0



-------------------------------------------------------------------------------------------------------------------
-- 5. Create new MasterDummy --------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

IF (@ErrCode > 0 or @SuperID < 0) RETURN

SELECT @ErrCode = 0, @ErrMsg = ''

EXEC Acc_Dep_CustomerInsMember_SAg
@custid=@MasterDummyID output,@creator=@creator,@username=@MasterDummy_Username,@userpwd=@pwd,@srecommend=@SuperID

-- Racing enable/disable
,@Disable151_31=1,@Disable151_41=1,@Disable151_51=1,@Disable152_41=1,@Disable152_51=1,@Disable153_51=1

-- Number Game enable/disabel
,@DisableNumber=0

-- Sportbook bet limit
,@minbetv1=@minbet,@maxbetv1=@maxbet,@maxpermatchv1=@maxpermatch
,@minbetv2=@minbet,@maxbetv2=@maxbet,@maxpermatchv2=@maxpermatch
,@minbetv3=@minbet,@maxbetv3=@maxbet,@maxpermatchv3=@maxpermatch
,@minbetv5=@minbet,@maxbetv5=@maxbet,@maxpermatchv5=@maxpermatch
,@minbetv8=@minbet,@maxbetv8=@maxbet,@maxpermatchv8=@maxpermatch
,@minbetv10=@minbet,@maxbetv10=@maxbet,@maxpermatchv10=@maxpermatch
,@minbetv11=@minbet,@maxbetv11=@maxbet,@maxpermatchv11=@maxpermatch
,@minbetv99=@minbet,@maxbetv99=@maxbet,@maxpermatchv99=@maxpermatch
,@minbetv99mp=@minbet,@maxbetv99mp=@maxbet,@maxpermatchv99mp=@maxpermatch

-- Number Game bet limit
,@minbetv161=0.0000,@maxbetv161=0.0000,@maxpermatchv161=0.0000,@maxperballv161=0.0000

-- Racing bet limit
,@v151minbet_31=0.0000,@v151maxbet_31=0.0000,@v151maxpermatch_31=0.0000,@v151minbet_41=0.0000,@v151maxbet_41=0.0000,@v151maxpermatch_41=0.0000,@v151minbet_51=0.0000,@v151maxbet_51=0.0000,@v151maxpermatch_51=0.0000
,@v152minbet_41=0.0000,@v152maxbet_41=0.0000,@v152maxpermatch_41=0.0000,@v152minbet_51=0.0000,@v152maxbet_51=0.0000,@v152maxpermatch_51=0.0000
,@v153minbet_51=0.0000,@v153maxbet_51=0.0000,@v153maxpermatch_51=0.0000

-- Sportbook sPT
,@v1spositiontaking_1=@PT,@v1spositiontaking_2=@PT,@v1spositiontaking_3=@PT,@v1spositiontaking_4=@PT,@v1spositiontaking_5=@PT,@v1spositiontaking_6=@PT
,@v1spositiontaking_7=@PT,@v1spositiontaking_8=@PT,@v1spositiontaking_9=@PT,@v1spositiontaking_10=@PT,@v1slivepositiontaking_1=@PT
,@v1slivepositiontaking_3=@PT,@v1slivepositiontaking_7=@PT,@v1slivepositiontaking_8=@PT

,@v2spositiontaking_1=@PT,@v2spositiontaking_2=@PT,@v2spositiontaking_3=@PT,@v2spositiontaking_7=@PT,@v2spositiontaking_8=@PT,@v2spositiontaking_20=@PT

,@v3spositiontaking_1=@PT,@v3spositiontaking_2=@PT,@v3spositiontaking_3=@PT,@v3spositiontaking_20=@PT

,@v5spositiontaking_1=@PT,@v5spositiontaking_2=@PT,@v5spositiontaking_3=@PT,@v5spositiontaking_20=@PT

,@v8spositiontaking_1=@PT,@v8spositiontaking_3=@PT,@v8spositiontaking_20=@PT

,@v10spositiontaking_1=@PT,@v10spositiontaking_2=@PT,@v10spositiontaking_3=@PT,@v10spositiontaking_20=@PT

,@v11spositiontaking_1=@PT,@v11spositiontaking_20=@PT

,@v99spositiontaking_1=@PT,@v99spositiontaking_2=@PT,@v99spositiontaking_3=@PT,@v99spositiontaking_20=@PT,@v99spositiontaking_9=@PT

-- NumberGame sPT
,@v161spositiontaking_81=@NG_PT,@v161spositiontaking_83=@NG_PT,@v161spositiontaking_86=@NG_PT,@v161spositiontaking_88=@NG_PT,@v161slivepositiontaking_85=@NG_PT
,@v161slivepositiontaking_86=@NG_PT,@v161slivepositiontaking_87=@NG_PT,@v161slivepositiontaking_89=@NG_PT,@v161slivepositiontaking_90=@NG_PT

-- Racing sPT
,@v151spositiontaking_31=0.0000,@v151spositiontaking_32=0.0000,@v151spositiontaking_41=0.0000,@v151spositiontaking_42=0.0000,@v151spositiontaking_51=0.0000,@v151spositiontaking_52=0.0000

,@v152spositiontaking_41=0.0000,@v152spositiontaking_42=0.0000,@v152spositiontaking_51=0.0000,@v152spositiontaking_52=0.0000

,@v153spositiontaking_51=0.0000,@v153spositiontaking_52=0.0000


-- Sportbook mPT
,@v1mpositiontaking_1=@PT,@v1mpositiontaking_2=@PT,@v1mpositiontaking_3=@PT,@v1mpositiontaking_4=@PT,@v1mpositiontaking_5=@PT,@v1mpositiontaking_6=@PT
,@v1mpositiontaking_7=@PT,@v1mpositiontaking_8=@PT,@v1mpositiontaking_9=@PT,@v1mpositiontaking_10=@PT,@v1mlivepositiontaking_1=@PT
,@v1mlivepositiontaking_3=@PT,@v1mlivepositiontaking_7=@PT,@v1mlivepositiontaking_8=@PT

,@v2mpositiontaking_1=@PT,@v2mpositiontaking_2=@PT,@v2mpositiontaking_3=@PT,@v2mpositiontaking_7=@PT,@v2mpositiontaking_8=@PT,@v2mpositiontaking_20=@PT

,@v3mpositiontaking_1=@PT,@v3mpositiontaking_2=@PT,@v3mpositiontaking_3=@PT,@v3mpositiontaking_20=@PT

,@v5mpositiontaking_1=@PT,@v5mpositiontaking_2=@PT,@v5mpositiontaking_3=@PT,@v5mpositiontaking_20=@PT

,@v8mpositiontaking_1=@PT,@v8mpositiontaking_3=@PT,@v8mpositiontaking_20=@PT

,@v10mpositiontaking_1=@PT,@v10mpositiontaking_2=@PT,@v10mpositiontaking_3=@PT,@v10mpositiontaking_20=@PT

,@v11mpositiontaking_1=@PT,@v11mpositiontaking_20=@PT

,@v99mpositiontaking_1=@PT,@v99mpositiontaking_2=@PT,@v99mpositiontaking_3=@PT,@v99mpositiontaking_20=@PT,@v99mpositiontaking_9=@PT

-- Number Game mPT
,@v161mpositiontaking_81=@NG_PT,@v161mpositiontaking_83=@NG_PT,@v161mpositiontaking_86=@NG_PT,@v161mpositiontaking_88=@NG_PT,@v161mlivepositiontaking_85=@NG_PT
,@v161mlivepositiontaking_86=@NG_PT,@v161mlivepositiontaking_87=@NG_PT,@v161mlivepositiontaking_89=@NG_PT,@v161mlivepositiontaking_90=@NG_PT

-- Racing mPT
,@v151mpositiontaking_31=0.0000,@v151mpositiontaking_32=0.0000,@v151mpositiontaking_41=0.0000,@v151mpositiontaking_42=0.0000,@v151mpositiontaking_51=0.0000,@v151mpositiontaking_52=0.0000

,@v152mpositiontaking_41=0.0000,@v152mpositiontaking_42=0.0000,@v152mpositiontaking_51=0.0000,@v152mpositiontaking_52=0.0000

,@v153mpositiontaking_51=0.0000,@v153mpositiontaking_52=0.0000

-- Racing discount
,@v151discount_31=0.00000000,@v151discount_41=0.00000000,@v151discount_51=0.00000000
,@v152discount_41=0.00000000,@v152discount_51=0.00000000
,@v153discount_51=0.00000000


-- Virtual sport PT
,@v180sPositionTaking=0.0000,@v180mPositionTaking=0.0000

-- Virtual sport bet limit
,@v180MinBet=0.0000,@v180MaxBet=0.0000,@v180MaxPerMatch=0.0000

-- IP, Languague and error info 
,@IP=@IP, @Language=default, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output

-------------------------------------------------------------------------------------------------------------------
-- 6. Create new AgentDummy --------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

IF (@ErrCode > 0 or @MasterDummyID < 0) RETURN

SELECT @ErrCode = 0, @ErrMsg = ''



EXEC Acc_Dep_CustomerInsMember_MAg 
@custid=@AgentDummyID output,@creator=@creator,@username=@AgentDummy_Username,@userpwd=@pwd,@mrecommend=@MasterDummyID

-- Racing enable/disble
,@Disable151_31=1,@Disable151_41=1,@Disable151_51=1,@Disable152_41=1,@Disable152_51=1,@Disable153_51=1

-- NumberGane enable/disable
,@DisableNumber=0

-- Sportbook bet limit
,@MinBetv1=@minbet,@MaxBetv1=@maxbet,@MaxPerMatchv1=@maxpermatch
,@MinBetv2=@minbet,@MaxBetv2=@maxbet,@MaxPerMatchv2=@maxpermatch
,@MinBetv3=@minbet,@MaxBetv3=@maxbet,@MaxPerMatchv3=@maxpermatch
,@MinBetv5=@minbet,@MaxBetv5=@maxbet,@MaxPerMatchv5=@maxpermatch
,@MinBetv8=@minbet,@MaxBetv8=@maxbet,@MaxPerMatchv8=@maxpermatch
,@MinBetv10=@minbet,@MaxBetv10=@maxbet,@MaxPerMatchv10=@maxpermatch
,@MinBetv11=@minbet,@MaxBetv11=@maxbet,@MaxPerMatchv11=@maxpermatch
,@MinBetv99=@minbet,@MaxBetv99=@maxbet,@MaxPerMatchv99=@maxpermatch
,@MinBetv99mp=@minbet,@MaxBetv99mp=@maxbet,@MaxPerMatchv99mp=@maxpermatch

-- NumberGame bet limit
,@MinBetv161=0.0000,@MaxBetv161=0.0000,@MaxPerMatchv161=0.0000,@MaxPerBallv161=0.0000

-- Racing bet limit
,@v151minbet_31=0.0000,@v151maxbet_31=0.0000,@v151maxpermatch_31=0.0000,@v151minbet_41=0.0000,@v151maxbet_41=0.0000,@v151maxpermatch_41=0.0000,@v151minbet_51=0.0000,@v151maxbet_51=0.0000,@v151maxpermatch_51=0.0000
,@v152minbet_41=0.0000,@v152maxbet_41=0.0000,@v152maxpermatch_41=0.0000,@v152minbet_51=0.0000,@v152maxbet_51=0.0000,@v152maxpermatch_51=0.0000
,@v153minbet_51=0.0000,@v153maxbet_51=0.0000,@v153maxpermatch_51=0.0000

-- Sportbook aPT
,@v1apositiontaking_1=@PT,@v1apositiontaking_2=@PT,@v1apositiontaking_3=@PT,@v1apositiontaking_4=@PT,@v1apositiontaking_5=@PT,@v1apositiontaking_6=@PT
,@v1apositiontaking_7=@PT,@v1apositiontaking_8=@PT,@v1apositiontaking_9=@PT,@v1apositiontaking_10=@PT
,@v1alivepositiontaking_1=@PT,@v1alivepositiontaking_3=@PT,@v1alivepositiontaking_7=@PT,@v1alivepositiontaking_8=@PT

,@v2apositiontaking_1=@PT,@v2apositiontaking_2=@PT,@v2apositiontaking_3=@PT,@v2apositiontaking_7=@PT,@v2apositiontaking_8=@PT,@v2apositiontaking_20=@PT
,@v3apositiontaking_1=@PT,@v3apositiontaking_2=@PT,@v3apositiontaking_3=@PT,@v3apositiontaking_20=@PT
,@v5apositiontaking_1=@PT,@v5apositiontaking_2=@PT,@v5apositiontaking_3=@PT,@v5apositiontaking_20=@PT
,@v8apositiontaking_1=@PT,@v8apositiontaking_3=@PT,@v8apositiontaking_20=@PT
,@v10apositiontaking_1=@PT,@v10apositiontaking_2=@PT,@v10apositiontaking_3=@PT,@v10apositiontaking_20=@PT
,@v11apositiontaking_1=@PT,@v11apositiontaking_20=@PT
,@v99apositiontaking_1=@PT,@v99apositiontaking_2=@PT,@v99apositiontaking_3=@PT,@v99apositiontaking_20=@PT,@v99apositiontaking_9=@PT

-- NumberGame aPT
,@v161apositiontaking_81=@NG_PT,@v161apositiontaking_83=@NG_PT,@v161apositiontaking_86=@NG_PT,@v161apositiontaking_88=@NG_PT,@v161alivepositiontaking_85=@NG_PT
,@v161alivepositiontaking_86=@NG_PT,@v161alivepositiontaking_87=@NG_PT,@v161alivepositiontaking_89=@NG_PT,@v161alivepositiontaking_90=@NG_PT

-- Racing aPT
,@v151apositiontaking_31=0.0000,@v151apositiontaking_32=0.0000,@v151apositiontaking_41=0.0000,@v151apositiontaking_42=0.0000,@v151apositiontaking_51=0.0000,@v151apositiontaking_52=0.0000
,@v152apositiontaking_41=0.0000,@v152apositiontaking_42=0.0000,@v152apositiontaking_51=0.0000,@v152apositiontaking_52=0.0000
,@v153apositiontaking_51=0.0000,@v153apositiontaking_52=0.0000


-- Sportbook mPT
,@v1mpositiontaking_1=@PT,@v1mpositiontaking_2=@PT,@v1mpositiontaking_3=@PT,@v1mpositiontaking_4=@PT,@v1mpositiontaking_5=@PT,@v1mpositiontaking_6=@PT
,@v1mpositiontaking_7=@PT,@v1mpositiontaking_8=@PT,@v1mpositiontaking_9=@PT,@v1mpositiontaking_10=@PT,@v1mlivepositiontaking_1=@PT
,@v1mlivepositiontaking_3=@PT,@v1mlivepositiontaking_7=@PT,@v1mlivepositiontaking_8=@PT

,@v2mpositiontaking_1=@PT,@v2mpositiontaking_2=@PT,@v2mpositiontaking_3=@PT,@v2mpositiontaking_7=@PT,@v2mpositiontaking_8=@PT,@v2mpositiontaking_20=@PT
,@v3mpositiontaking_1=@PT,@v3mpositiontaking_2=@PT,@v3mpositiontaking_3=@PT,@v3mpositiontaking_20=@PT
,@v5mpositiontaking_1=@PT,@v5mpositiontaking_2=@PT,@v5mpositiontaking_3=@PT,@v5mpositiontaking_20=@PT
,@v8mpositiontaking_1=@PT,@v8mpositiontaking_3=@PT,@v8mpositiontaking_20=@PT
,@v10mpositiontaking_1=@PT,@v10mpositiontaking_2=@PT,@v10mpositiontaking_3=@PT,@v10mpositiontaking_20=@PT
,@v11mpositiontaking_1=@PT,@v11mpositiontaking_20=@PT
,@v99mpositiontaking_1=@PT,@v99mpositiontaking_2=@PT,@v99mpositiontaking_3=@PT,@v99mpositiontaking_20=@PT,@v99mpositiontaking_9=@PT

-- NumberGame mPT
,@v161mpositiontaking_81=@NG_PT,@v161mpositiontaking_83=@NG_PT,@v161mpositiontaking_86=@NG_PT,@v161mpositiontaking_88=@NG_PT,@v161mlivepositiontaking_85=@NG_PT
,@v161mlivepositiontaking_86=@NG_PT,@v161mlivepositiontaking_87=@NG_PT,@v161mlivepositiontaking_89=@NG_PT,@v161mlivepositiontaking_90=@NG_PT

-- Racing mPT
,@v151mpositiontaking_31=0.0000,@v151mpositiontaking_32=0.0000,@v151mpositiontaking_41=0.0000,@v151mpositiontaking_42=0.0000,@v151mpositiontaking_51=0.0000,@v151mpositiontaking_52=0.0000
,@v152mpositiontaking_41=0.0000,@v152mpositiontaking_42=0.0000,@v152mpositiontaking_51=0.0000,@v152mpositiontaking_52=0.0000
,@v153mpositiontaking_51=0.0000,@v153mpositiontaking_52=0.0000

-- Racing discount
,@v151discount_31=0.00000000,@v151discount_41=0.00000000,@v151discount_51=0.00000000,@v152discount_41=0.00000000,@v152discount_51=0.00000000,@v153discount_51=0.00000000

-- Virtual sport PT
,@v180aPositionTaking=0.0000,@v180mPositionTaking=0.0000

-- Virtual Sport bet limit

,@v180MinBet=0.0000,@v180MaxBet=0.0000,@v180MaxPerMatch=0.0000

-- IP, Language and error info 
,@IP=@IP,@Language=default,@SubAccID=default,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output


-------------------------------------------------------------------------------------------------------------------
-- 7. Create new MemberDummy --------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

IF (@ErrCode > 0 or @AgentDummyID < 0) RETURN

SELECT @ErrCode = 0, @ErrMsg = ''

DECLARE @rowcnt INT

WHILE (1=1)
BEGIN
	UPDATE TOP (1) @tmpMember
	SET @Member_Username = username
		,isCreated = 1
	FROM @tmpMember
	WHERE isCreated = 0
	
	SELECT @rowcnt = @@rowcount	

	IF @rowcnt < 1 BREAK

	EXEC Acc_Dep_CustomerInsMember_Ag 
		@custid=@MemberID output,@creator=@creator,@username=@Member_Username,@userpwd=@pwd,@recommend=@AgentDummyID
 
		-- Racing enable/disable
		,@Disable151_31=1,@Disable151_41=1,@Disable151_51=1,@Disable152_41=1,@Disable152_51=1,@Disable153_51=1
  
		 -- Number Game enable/disable
		 ,@DisableNumber=0
 
		 -- Sportbook bet limit
		 ,@MinBetv1=@minbet,@MaxBetv1=@maxbet,@MaxPerMatchv1=@maxpermatch
		 ,@MinBetv2=@minbet,@MaxBetv2=@maxbet,@MaxPerMatchv2=@maxpermatch
		 ,@MinBetv3=@minbet,@MaxBetv3=@maxbet,@MaxPerMatchv3=@maxpermatch
		 ,@MinBetv5=@minbet,@MaxBetv5=@maxbet,@MaxPerMatchv5=@maxpermatch
		 ,@MinBetv8=@minbet,@MaxBetv8=@maxbet,@MaxPerMatchv8=@maxpermatch
		 ,@MinBetv10=@minbet,@MaxBetv10=@maxbet,@MaxPerMatchv10=@maxpermatch
		 ,@MinBetv11=@minbet,@MaxBetv11=@maxbet,@MaxPerMatchv11=@maxpermatch
		 ,@MinBetv99=@minbet,@MaxBetv99=@maxbet,@MaxPerMatchv99=@maxpermatch
		 ,@MinBetv99mp=@minbet,@MaxBetv99mp=@maxbet,@MaxPerMatchv99mp=@maxpermatch
 
		 -- NumberGame bet limit
		  ,@MinBetv161=0.0000,@MaxBetv161=0.0000,@MaxPerMatchv161=0.0000,@MaxPerBallv161=0.0000
  
		  -- Racing bet limit
		  ,@v151minbet_31=0.0000,@v151maxbet_31=0.0000,@v151maxpermatch_31=0.0000,@v151minbet_41=0.0000,@v151maxbet_41=0.0000,@v151maxpermatch_41=0.0000,@v151minbet_51=0.0000
		  ,@v151maxbet_51=0.0000,@v151maxpermatch_51=0.0000,@v152minbet_41=0.0000,@v152maxbet_41=0.0000
		  ,@v152maxpermatch_41=0.0000,@v152minbet_51=0.0000,@v152maxbet_51=0.0000,@v152maxpermatch_51=0.0000
		  ,@v153minbet_51=0.0000,@v153maxbet_51=0.0000,@v153maxpermatch_51=0.0000
  
		  -- Sportbook aPT
		  ,@v1apositiontaking_1=@PT,@v1apositiontaking_2=@PT,@v1apositiontaking_3=@PT,@v1apositiontaking_4=@PT,@v1apositiontaking_5=@PT,@v1apositiontaking_6=@PT
		  ,@v1apositiontaking_7=@PT,@v1apositiontaking_8=@PT,@v1apositiontaking_9=@PT,@v1apositiontaking_10=@PT,@v1alivepositiontaking_1=@PT
		  ,@v1alivepositiontaking_3=@PT,@v1alivepositiontaking_7=@PT,@v1alivepositiontaking_8=@PT
		  ,@v2apositiontaking_1=@PT,@v2apositiontaking_2=@PT,@v2apositiontaking_3=@PT,@v2apositiontaking_7=@PT,@v2apositiontaking_8=@PT,@v2apositiontaking_20=@PT
		  ,@v3apositiontaking_1=@PT,@v3apositiontaking_2=@PT,@v3apositiontaking_3=@PT,@v3apositiontaking_20=@PT
		  ,@v5apositiontaking_1=@PT,@v5apositiontaking_2=@PT,@v5apositiontaking_3=@PT,@v5apositiontaking_20=@PT
		  ,@v8apositiontaking_1=@PT,@v8apositiontaking_3=@PT,@v8apositiontaking_20=@PT
		  ,@v10apositiontaking_1=@PT,@v10apositiontaking_2=@PT,@v10apositiontaking_3=@PT,@v10apositiontaking_20=@PT
		  ,@v11apositiontaking_1=@PT,@v11apositiontaking_20=@PT
		  ,@v99apositiontaking_1=@PT,@v99apositiontaking_2=@PT,@v99apositiontaking_3=@PT,@v99apositiontaking_20=@PT,@v99apositiontaking_9=@PT
  
		  -- Racing aPT  
		  ,@v151apositiontaking_31=0.0000,@v151apositiontaking_32=0.0000,@v151apositiontaking_41=0.0000,@v151apositiontaking_42=0.0000,@v151apositiontaking_51=0.0000  ,@v151apositiontaking_52=0.0000
		  ,@v152apositiontaking_41=0.0000,@v152apositiontaking_42=0.0000,@v152apositiontaking_51=0.0000,@v152apositiontaking_52=0.0000
		  ,@v153apositiontaking_51=0.0000,@v153apositiontaking_52=0.0000
  
		  -- Number game aPT
		  ,@v161apositiontaking_81=@NG_PT,@v161apositiontaking_83=@NG_PT,@v161apositiontaking_86=@NG_PT,@v161apositiontaking_88=@NG_PT,@v161alivepositiontaking_85=@NG_PT
		  ,@v161alivepositiontaking_86=@NG_PT,@v161alivepositiontaking_87=@NG_PT,@v161alivepositiontaking_89=@NG_PT,@v161alivepositiontaking_90=@NG_PT
  
		  -- Racing discount  
		  ,@v151playerdiscount_31=0.00000000,@v151playerdiscount_41=0.00000000,@v151playerdiscount_51=0.00000000
		  ,@v152playerdiscount_41=0.00000000,@v152playerdiscount_51=0.00000000
		  ,@v153playerdiscount_51=0.00000000
  
  
		  -- Virtual Racing PT
		  ,@v180aPositionTaking=0.0000
  
		  -- Virtual Racing bet limit
		  ,@v180MinBet=0.0000,@v180MaxBet=0.0000,@v180MaxPerMatch=0.0000
  
		  -- IP, Language and error info  
		  ,@IP=@IP, @Language=default, @SubAccID=default, @ErrCode=@ErrCode output, @ErrMsg=@ErrMsg output

END

----------------------------------------------------------------------------------------------------

SElECT site,username,custid,roleid FROM CUSTOMER WITH (NOLOCK) WHERE srecommend = @SuperID ORDER BY Custid
