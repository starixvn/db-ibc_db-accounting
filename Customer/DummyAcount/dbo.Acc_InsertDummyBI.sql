ALTER PROCEDURE [dbo].[Acc_InsertDummyBI]
	@CurrencyName varchar(10),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg varchar(200) = '' OUTPUT	
AS
/*
Created: Henry
Date: 2010-09-30
Task : Insert dummy accounts for Bingo based on new-added currencty
DB: DBTRANS.bodb02
Original:

Revisions:
	- 20101103@Henry: Add MaxPerBall
Param's Explanation:
• @CurrencyName: input currency to create related dummies, this currency must be added to table exchange before

--=====================================================
Settings:	Credit = 0, MinBet = 0, MaxBet = 0, MaxPerMatch = 0
			All PT = 0, Commission = 0 
--------------------------------------------------------

Super:	     3rdSuperUS$ 				
			
Master:	     BIUS$			
			
Agent:       BIUS$01	           
			
Member:	     BIBetUS$			

--=====================================================
*/

SET NOCOUNT ON
DECLARE @SuperID	INT, 
		@MasterID	INT,
		@AgentID	INT,
		@memberID	INT,
		@username	VARCHAR(20),
		@CurrencyID INT

SELECT	@CurrencyID = exchangeid FROM exchange WITH (NOLOCK) WHERE currency = rtrim(@CurrencyName)
IF @CurrencyID is NULL
BEGIN
	SELECT	@errcode = 101	
	SELECT	@ErrMsg =  'Invalid currency!'
	RETURN
END	

--Insert Super
SELECT	@username = '3rdSuper'+rtrim(@CurrencyName)
SELECT  @SuperID = custid FROM custinfo WITH (NOLOCK) WHERE username = @username
IF (@SuperID is not null)
BEGIN
	PRINT 'Super ' + @username + ' already exists. Skip creating and use existing Super to create dummy master'
END
ELSE
BEGIN
	EXEC dbo.Acc_CustomerInsMember_Com 
		@custid = @SuperID OUTPUT,
		@firstname = N'-',
		@lastname = N'-',
		@address = N'-',
		@postal = N'-',
		@city = N'-',
		@state = N'-',
		@country = N'-',
		@phone = N'-',
		@mobilephone = N'-',
		@email = N'-',
		@fax = N'-',
		@refcode1 = N'-',
		@creator = 8,
		@username = @username,
		@userpwd = N'',
		@site = 'BEST-ODDS',
		@currency = @CurrencyID,
		@credit = $0.0000,
		@groupa = 0,
		@groupb = 0,
		@groupc = 0,
		@groupd = 0,
		@discountcs = 0,
		@discount1x2 =0, 
		@discountnumber = 0,
		@MinBet = 0,
		@MaxBet = 0,
		@MaxPerMatch = 0,
		@MinBetv2 = 0,
		@MaxBetv2 = 0,
		@MaxPerMatchv2 = 0,
		@MinBetv3 = 0,
		@MaxBetv3 = 0,
		@MaxPerMatchv3 = 0,
		@MinBetv5 = 0,
		@MaxBetv5 = 0,
		@MaxPerMatchv5 = 0,
		@MinBetv8 = 0,
		@MaxBetv8 = 0,
		@MaxPerMatchv8 = 0,
		@MinBetv10 = 0,
		@MaxBetv10 = 0,
		@MaxPerMatchv10 = 0,
		@MinBetv11 = 0,
		@MaxBetv11 = 0,
		@MaxPerMatchv11 = 0,
		@MinBetv99 = 0,
		@MaxBetv99 = 0,
		@MaxPerMatchv99 = 0,
		@MinBetv99MP = 0,
		@MaxBetv99MP = 0,
		@MaxPerMatchv99MP = 0,
		@MinBetv161 = 0,
		@MaxBetv161 = 0,
		@MaxPerBallv161 = 0,
		@MaxPerMatchv161 = 0,
		@spositiontaking_1 = 0,
		@spositiontaking_2 = 0,
		@spositiontaking_3 = 0,
		@spositiontaking_4 = 0,
		@spositiontaking_5 = 0,
		@spositiontaking_6 = 0,
		@spositiontaking_7 = 0,
		@spositiontaking_8 = 0,
		@spositiontaking_9 = 0,
		@spositiontaking_10 = 0,
		@slivepositiontaking_1 = 0,
		@slivepositiontaking_3 = 0,
		@slivepositiontaking_7 = 0,
		@slivepositiontaking_8 = 0,
		@v2spositiontaking_1 = 0,
		@v2spositiontaking_2 = 0,
		@v2spositiontaking_3 = 0,
		@v2spositiontaking_7 = 0,
		@v2spositiontaking_8 = 0,
		--@v2spositiontaking_9 = 0,
		@v2spositiontaking_20 = 0,
		@v3spositiontaking_1 = 0,
		@v3spositiontaking_2 = 0,
		@v3spositiontaking_3 = 0,
		@v3spositiontaking_20 = 0,
		@v5spositiontaking_1 = 0,
		@v5spositiontaking_2 = 0,
		@v5spositiontaking_3 = 0,
		@v5spositiontaking_20 = 0,
		@v8spositiontaking_1 = 0,
		@v8spositiontaking_3 = 0,
		@v8spositiontaking_20 = 0,
		@v10spositiontaking_1 = 0,
		@v10spositiontaking_2 = 0,
		@v10spositiontaking_3 = 0,
		@v10spositiontaking_20 = 0,
		@v11spositiontaking_1 = 0,
		@v11spositiontaking_20 = 0,
		@v99spositiontaking_1 = 0,
		@v99spositiontaking_2 = 0,
		@v99spositiontaking_3 = 0,
		@v99spositiontaking_9 = 0,
		@v99spositiontaking_20 = 0,
		
		--v161
		@v161spositiontaking_81  = 0,
		@v161spositiontaking_83  = 0,
		--@v161spositiontaking_85 smallmoney,
		@v161spositiontaking_86  = 0,
		@v161spositiontaking_88 = 0,
		@v161slivepositiontaking_85  = 0,
		@v161slivepositiontaking_86  = 0,
		@v161slivepositiontaking_87  = 0,	
		@v161slivepositiontaking_89  = 0,
		@v161slivepositiontaking_90  = 0,
		
		@mpositiontaking_1 = 0,
		@mpositiontaking_2 = 0,
		@mpositiontaking_3 = 0,
		@mpositiontaking_4 = 0,
		@mpositiontaking_5 = 0,
		@mpositiontaking_6 = 0,
		@mpositiontaking_7 = 0,
		@mpositiontaking_8 = 0,
		@mpositiontaking_9 = 0,
		@mpositiontaking_10 = 0,
		@mlivepositiontaking_1 = 0,
		@mlivepositiontaking_3 = 0,
		@mlivepositiontaking_7 = 0,
		@mlivepositiontaking_8 = 0,
		@v2mpositiontaking_1 = 0,
		@v2mpositiontaking_2 = 0,
		@v2mpositiontaking_3 = 0,
		@v2mpositiontaking_7 = 0,
		@v2mpositiontaking_8 = 0,
		--@v2mpositiontaking_9 = 0,
		@v2mpositiontaking_20 = 0,
		@v3mpositiontaking_1 = 0,
		@v3mpositiontaking_2 = 0,
		@v3mpositiontaking_3 = 0,
		@v3mpositiontaking_20 = 0,
		@v5mpositiontaking_1 = 0,
		@v5mpositiontaking_2 = 0,
		@v5mpositiontaking_3 = 0,
		@v5mpositiontaking_20 = 0,
		@v8mpositiontaking_1 = 0,
		@v8mpositiontaking_3 = 0,
		@v8mpositiontaking_20 = 0,
		@v10mpositiontaking_1 = 0,
		@v10mpositiontaking_2 = 0,
		@v10mpositiontaking_3 = 0,
		@v10mpositiontaking_20 = 0,
		@v11mpositiontaking_1 = 0,
		@v11mpositiontaking_20 = 0,
		@v99mpositiontaking_1 = 0,
		@v99mpositiontaking_2 = 0,
		@v99mpositiontaking_3 = 0,
		@v99mpositiontaking_9 = 0,
		@v99mpositiontaking_20 = 0,
		
	--v161
		@v161mpositiontaking_81  = 0,
		@v161mpositiontaking_83  = 0,
		--@v161mpositiontaking_85 smallmoney,
		@v161mpositiontaking_86  = 0,
		@v161mpositiontaking_88  = 0,
		@v161mlivepositiontaking_85  = 0,
		@v161mlivepositiontaking_86  = 0,
		@v161mlivepositiontaking_87  = 0,
		@v161mlivepositiontaking_89  = 0,
		@v161mlivepositiontaking_90 =0,
	
		
		@apositiontaking_1 = 0,
		@apositiontaking_2 = 0,
		@apositiontaking_3 = 0,
		@apositiontaking_4 = 0,
		@apositiontaking_5 = 0,
		@apositiontaking_6 = 0,
		@apositiontaking_7 = 0,
		@apositiontaking_8 = 0,
		@apositiontaking_9 = 0,
		@apositiontaking_10 = 0,
		@alivepositiontaking_1 = 0,
		@alivepositiontaking_3 = 0,
		@alivepositiontaking_7 = 0,
		@alivepositiontaking_8 = 0,
		@v2apositiontaking_1 = 0,
		@v2apositiontaking_2 = 0,
		@v2apositiontaking_3 = 0,
		@v2apositiontaking_7 = 0,
		@v2apositiontaking_8 = 0,
		--@v2apositiontaking_9 = 0,
		@v2apositiontaking_20 = 0,
		@v3apositiontaking_1 = 0,
		@v3apositiontaking_2 = 0,
		@v3apositiontaking_3 = 0,
		@v3apositiontaking_20 = 0,
		@v5apositiontaking_1 = 0,
		@v5apositiontaking_2 = 0,
		@v5apositiontaking_3 = 0,
		@v5apositiontaking_20 = 0,
		@v8apositiontaking_1 = 0,
		@v8apositiontaking_3 = 0,
		@v8apositiontaking_20 = 0,
		@v10apositiontaking_1 = 0,
		@v10apositiontaking_2 = 0,
		@v10apositiontaking_3 = 0,
		@v10apositiontaking_20 = 0,
		@v11apositiontaking_1 = 0,
		@v11apositiontaking_20 = 0,
		@v99apositiontaking_1 = 0,
		@v99apositiontaking_2 = 0,
		@v99apositiontaking_3 = 0,
		@v99apositiontaking_9 = 0,
		@v99apositiontaking_20 = 0,
		
	
		--v161
		@v161apositiontaking_81  = 0,
		@v161apositiontaking_83  = 0,
		@v161apositiontaking_86  = 0,
		@v161apositiontaking_88  = 0,
		@v161alivepositiontaking_85  = 0,
		@v161alivepositiontaking_86  = 0,
		@v161alivepositiontaking_87  = 0,
		@v161alivepositiontaking_89  = 0,
		@v161alivepositiontaking_90 = 0,
	
		@Disable151_31 = 0,-- @DisableHorseRacing -> @Disable151_31
		@Disable151_41 = 0,-- @DisableOpenTote -> @Disable151_41
		@Disable151_51 = 0,-- @Disable151_AU -> @Disable151_51
		@Disable152_41 = 0,-- @Disable152_UK -> @Disable152_41
		@Disable152_51 = 0,-- @Disable152_AU -> @Disable152_51
		@Disable153_51 = 0,-- @Disable153_AU -> @Disable153_51
		@DisableFinancial = 0,
		@DisableCasino = 0, 
		@DisableBingo = 0,
		@DisableNumber = 0,
		
		@Language = 'E',
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0 
	BEGIN
		SELECT @errcode = 102
		SELECT @ErrMsg =  'Create dummy super for Bingo failed: ' + @username
		RETURN
	END	
	print 'Create dummy super for Bingo successfully: ' + @username			
END

--Insert master Bingo 
SELECT @username ='BI'+ rtrim(@CurrencyName)
SELECT @MasterID = custid FROM custinfo WITH (NOLOCK) WHERE username = @username
IF (@MasterID is not null)
BEGIN
	PRINT 'Master ' + @username + ' already exists. Skip creating and use existing Master to create dummy agents'
END
ELSE
BEGIN
	EXEC dbo.Acc_CustomerInsMember_SAg 
		@custid = @MasterID OUTPUT,
		@firstname = N'-',
		@lastname = N'-',
		@creator = 8,
		@username = @username,
		@userpwd = '',
		@phone = N'-',
		@mobilephone = N'-',
		@email = N'-',
		@fax = N'-',
		@address = N'-',
		@city = N'-',
		@state = N'-',
		@country = N'-',
		@postal = N'-',
		@TransferOption = 0,
		@suspended = 0,
		@Disable151_31 = 0,--@DisableHorseRacing -> @Disable151_31
		@Disable151_41 = 0,-- @DisableOpenTote -> @Disable151_41
		@Disable151_51 = 0, -- @Disable151_AU -> @Disable151_51
		@Disable152_41 = 0, -- @Disable152_UK -> @Disable152_41
		@Disable152_51 = 0, -- @Disable152_AU -> @Disable152_51
		@Disable153_51 = 0, -- @Disable153_AU -> @Disable153_51
		@DisableFinancial = 0,
		@DisableCasino =0,
		@DisableAutoMPT = 1,--Super allow master using auto master PT or not.
		@DisableBingo = 0, 
		@DisableNumber = 0,

		@suspendedFlag = 0,
		@IsInternal = 0,
		@minbet = 0,
		@maxbet = 0,
		@maxpermatch = 0,
		@minbetv2 = 0,
		@maxbetv2 = 0,
		@maxpermatchv2 = 0,
		@minbetv3 = 0,
		@maxbetv3 = 0,
		@maxpermatchv3 = 0,
		@minbetv5 = 0,
		@maxbetv5 = 0,
		@maxpermatchv5 = 0,
		@minbetv8 = 0,
		@maxbetv8 = 0,
		@maxpermatchv8 = 0,
		@minbetv10 = 0,
		@maxbetv10 = 0,
		@maxpermatchv10 = 0,
		@minbetv11 = 0,
		@maxbetv11 = 0,
		@maxpermatchv11 = 0,
		@minbetv99 = 0,
		@maxbetv99 = 0,
		@maxpermatchv99 = 0,
		@minbetv99MP = 0,
		@maxbetv99MP = 0,
		@maxpermatchv99MP = 0,
		@minbetv161 = 0,
		@maxbetv161 = 0,
		@MaxPerBallv161 = 0,
		@maxpermatchv161 = 0,
		
		@credit = 0,
		@srecommend = @superid,
		@spositiontaking_1 = 0,
		@spositiontaking_2 = 0,
		@spositiontaking_3 = 0,
		@spositiontaking_4 = 0,
		@spositiontaking_5 = 0,
		@spositiontaking_6 = 0,
		@spositiontaking_7 = 0,
		@spositiontaking_8 = 0,
		@spositiontaking_9 = 0,
		@spositiontaking_10 = 0,
		@slivepositiontaking_1 = 0,
		@slivepositiontaking_3 = 0,
		@slivepositiontaking_7 = 0,
		@slivepositiontaking_8 = 0,
		@v2spositiontaking_1 = 0,
		@v2spositiontaking_2 = 0,
		@v2spositiontaking_3 = 0,
		@v2spositiontaking_7 = 0,
		@v2spositiontaking_8 = 0,
		--@v2spositiontaking_9 = 0,
		@v2spositiontaking_20 = 0,
		@v3spositiontaking_1 = 0,
		@v3spositiontaking_2 = 0,
		@v3spositiontaking_3 = 0,
		@v3spositiontaking_20 = 0,
		@v5spositiontaking_1 = 0,
		@v5spositiontaking_2 = 0,
		@v5spositiontaking_3 = 0,
		@v5spositiontaking_20 = 0,
		@v8spositiontaking_1 = 0,
		@v8spositiontaking_3 = 0,
		@v8spositiontaking_20 = 0,
		@v10spositiontaking_1 = 0,
		@v10spositiontaking_2 = 0,
		@v10spositiontaking_3 = 0,
		@v10spositiontaking_20 = 0,
		@v11spositiontaking_1 = 0,
		@v11spositiontaking_20 = 0,
		@v99spositiontaking_1 = 0,
		@v99spositiontaking_2 = 0,
		@v99spositiontaking_3 = 0,
		@v99spositiontaking_9 = 0,
		@v99spositiontaking_20 = 0,
		
		@v161spositiontaking_81 = 0, 				
		@v161spositiontaking_83 = 0,
		@v161spositiontaking_86 = 0,
		@v161spositiontaking_88 = 0,
		
		@v161slivepositiontaking_85 = 0,
		@v161slivepositiontaking_86 = 0,
		@v161slivepositiontaking_87	= 0,
		@v161slivepositiontaking_89	= 0,
		@v161slivepositiontaking_90	= 0,
		
		@groupa = 0,
		@groupb = 0,
		@groupc = 0,
		@groupd = 0,
		@discountcs = 0,
		@discount1x2 = 0,
		@discountnumber = 0,
		@auto_spositiontaking_1 = 0,
		@auto_spositiontaking_2 = 0,
		@auto_spositiontaking_3 = 0,
		@auto_spositiontaking_4 = 0,
		@auto_spositiontaking_5 = 0,
		@auto_spositiontaking_6 = 0,
		@auto_spositiontaking_7 = 0,
		@auto_spositiontaking_8 = 0,
		@auto_spositiontaking_9 = 0,
		@auto_spositiontaking_10 = 0,
		@auto_slivepositiontaking_1 = 0,
		@auto_slivepositiontaking_3 = 0,
		@auto_slivepositiontaking_7 = 0,
		@auto_slivepositiontaking_8 = 0,
		@auto_v2spositiontaking_1 = 0,
		@auto_v2spositiontaking_2 = 0,
		@auto_v2spositiontaking_3 = 0,
		@auto_v2spositiontaking_7 = 0,
		@auto_v2spositiontaking_8 = 0,
		--@auto_v2spositiontaking_9 = 0,
		@auto_v2spositiontaking_20 = 0,
		@auto_v3spositiontaking_1 = 0,
		@auto_v3spositiontaking_2 = 0,
		@auto_v3spositiontaking_3 = 0,
		@auto_v3spositiontaking_20 = 0,
		@auto_v5spositiontaking_1 = 0,
		@auto_v5spositiontaking_2 = 0,
		@auto_v5spositiontaking_3 = 0,
		@auto_v5spositiontaking_20 = 0,
		@auto_v8spositiontaking_1 = 0,
		@auto_v8spositiontaking_3 = 0,
		@auto_v8spositiontaking_20 = 0,
		@auto_v10spositiontaking_1 = 0,
		@auto_v10spositiontaking_2 = 0,
		@auto_v10spositiontaking_3 = 0,
		@auto_v10spositiontaking_20 = 0,
		@auto_v11spositiontaking_1 = 0,
		@auto_v11spositiontaking_20 = 0,
		@auto_v99spositiontaking_1 = 0,
		@auto_v99spositiontaking_2 = 0,
		@auto_v99spositiontaking_3 = 0,
		@auto_v99spositiontaking_9 = 0,
		@auto_v99spositiontaking_20 = 0,
		
		@auto_v161spositiontaking_81 = 0,            
		@auto_v161spositiontaking_83 = 0,
		@auto_v161spositiontaking_86 = 0,
		@auto_v161spositiontaking_88 = 0,
		
		@auto_v161slivepositiontaking_85 = 0,
		@auto_v161slivepositiontaking_86 = 0,
		@auto_v161slivepositiontaking_87 = 0,
		@auto_v161slivepositiontaking_89 = 0,
		@auto_v161slivepositiontaking_90 = 0,
		
		@Language = 'E',
		@SubAccID = 0,
		@mpositiontaking_1 = 0,
		@mpositiontaking_2 = 0,
		@mpositiontaking_3 = 0,
		@mpositiontaking_4 = 0,
		@mpositiontaking_5 = 0,
		@mpositiontaking_6 = 0,
		@mpositiontaking_7 = 0,
		@mpositiontaking_8 = 0,
		@mpositiontaking_9 = 0,
		@mpositiontaking_10 = 0,
		@mlivepositiontaking_1 = 0,
		@mlivepositiontaking_3 = 0,
		@mlivepositiontaking_7 = 0,
		@mlivepositiontaking_8 = 0,
		@v2mpositiontaking_1 = 0,
		@v2mpositiontaking_2 = 0,
		@v2mpositiontaking_3 = 0,
		@v2mpositiontaking_7 = 0,
		@v2mpositiontaking_8 = 0,
		--@v2mpositiontaking_9 = 0,
		@v2mpositiontaking_20 = 0,
		@v3mpositiontaking_1 = 0,
		@v3mpositiontaking_2 = 0,
		@v3mpositiontaking_3 = 0,
		@v3mpositiontaking_20 = 0,
		@v5mpositiontaking_1 = 0,
		@v5mpositiontaking_2 = 0,
		@v5mpositiontaking_3 = 0,
		@v5mpositiontaking_20 = 0,
		@v8mpositiontaking_1 = 0,
		@v8mpositiontaking_3 = 0,
		@v8mpositiontaking_20 = 0,
		@v10mpositiontaking_1 = 0,
		@v10mpositiontaking_2 = 0,
		@v10mpositiontaking_3 = 0,
		@v10mpositiontaking_20 = 0,
		@v11mpositiontaking_1 = 0,
		@v11mpositiontaking_20 = 0,
		@v99mpositiontaking_1 = 0,
		@v99mpositiontaking_2 = 0,
		@v99mpositiontaking_3 = 0,
		@v99mpositiontaking_9 = 0,
		@v99mpositiontaking_20 = 0,
		
		@v161mpositiontaking_81 = 0,        
		@v161mpositiontaking_83  = 0,
		@v161mpositiontaking_86  = 0,
		@v161mpositiontaking_88  = 0,
		
		@v161mlivepositiontaking_85  = 0,
		@v161mlivepositiontaking_86  = 0,
		@v161mlivepositiontaking_87  = 0,
		@v161mlivepositiontaking_89  = 0,
		@v161mlivepositiontaking_90  = 0,
		
		@IP = N'-',
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT,
		@site = N'-'

	IF @ErrCode <> 0 
	BEGIN
		SELECT @errcode = 103
		SELECT @ErrMsg =  'Create dummy master for Bingo failed: ' + @username
		RETURN
	END	
	print 'Create dummy master for Bingo successfully: ' + @username				
END

--Insert Agent BI__01
SELECT @username = 'BI'+ rtrim(@CurrencyName) + '01'
SELECT @AgentID = custid FROM custinfo WITH (NOLOCK) WHERE username = @username
IF (@AgentID is not null)
BEGIN
	PRINT 'Agent ' + @username + ' already exists. Skip creating and use existing Agent to create dummy members'
END
ELSE
BEGIN
	EXEC dbo.Acc_CustomerInsMember_MAg 
		@custid = @agentid OUTPUT,
		@firstname = N'-',
		@lastname = N'-',
		@creator = 8,
		@username = @username,
		@userpwd = '',
		@discountcs = 0,
		@discount1x2 = 0,
		@discountnumber = 0,
		@phone = N'-',
		@mobilephone = N'-',
		@email = N'-',
		@fax = N'-',
		@address = N'-',
		@city = N'-',
		@state = N'-',
		@country = N'-',
		@postal = N'-',
		@groupa = 0,
		@groupb = 0,
		@groupc = 0,
		@groupd = 0,
		@TransferOption =0, --pass value (not NULL) in case direct master add new agent
		@suspended = 0,
		@Disable151_31 = 0,-- @DisableHorseRacing -> @Disable151_31
		@Disable151_41 = 0,-- @DisableOpenTote -> @Disable151_41
		@Disable151_51 = 0, -- @Disable151_AU -> @Disable151_51
		@Disable152_41 = 0, -- @Disable152_UK -> @Disable152_41
		@Disable152_51 = 0, -- @Disable152_AU -> @Disable152_51
		@Disable153_51 = 0,-- @Disable153_AU -> @Disable153_51
		@DisableFinancial = 0,
		@DisableCasino = 0, 
		@suspendedFlag =0,
		@IsInternal = 0,
		
		-- bingo & number game status
		@DisableBingo  = 0,
		@DisableNumber = 0,	
		@MinBet = 0,
		@MaxBet = 0,
		@MaxPerMatch = 0,
		@MinBetv2 = 0,
		@MaxBetv2 = 0,
		@MaxPerMatchv2 = 0,
		@MinBetv3 = 0,
		@MaxBetv3 = 0,
		@MaxPerMatchv3 = 0,
		@MinBetv5 = 0,
		@MaxBetv5 = 0,
		@MaxPerMatchv5 = 0,
		@MinBetv8 = 0,
		@MaxBetv8 = 0,
		@MaxPerMatchv8 = 0,
		@MinBetv10 = 0,
		@MaxBetv10 = 0,
		@MaxPerMatchv10 = 0,
		@MinBetv11 = 0,
		@MaxBetv11 = 0,
		@MaxPerMatchv11 = 0,
		@MinBetv99 = 0,
		@MaxBetv99 = 0,
		@MaxPerMatchv99 = 0,
		@MinBetv99MP = 0,
		@MaxBetv99MP = 0,
		@MaxPerMatchv99MP = 0,
		@MinBetv161 = 0,
		@MaxBetv161 = 0,
		@MaxPerBallv161 = 0,
		@MaxPerMatchv161 = 0,
		
		@credit = 0,
		@maxcredit = 0,
		@mrecommend = @masterid,
		@apositiontaking_1 = 0,
		@apositiontaking_2 = 0,
		@apositiontaking_3 = 0,
		@apositiontaking_4 = 0,
		@apositiontaking_5 = 0,
		@apositiontaking_6 = 0,
		@apositiontaking_7 = 0,
		@apositiontaking_8 = 0,
		@apositiontaking_9 = 0,
		@apositiontaking_10 = 0,
		@mpositiontaking_1 = 0,
		@mpositiontaking_2 = 0,
		@mpositiontaking_3 = 0,
		@mpositiontaking_4 = 0,
		@mpositiontaking_5 = 0,
		@mpositiontaking_6 = 0,
		@mpositiontaking_7 = 0,
		@mpositiontaking_8 = 0,
		@mpositiontaking_9 = 0,
		@mpositiontaking_10 = 0,
		@alivepositiontaking_1 = 0,
		@alivepositiontaking_3 = 0,
		@alivepositiontaking_7 = 0,
		@alivepositiontaking_8 = 0,
		@mlivepositiontaking_1 = 0,
		@mlivepositiontaking_3 = 0,
		@mlivepositiontaking_7 = 0,
		@mlivepositiontaking_8 = 0,
		@v2apositiontaking_1 = 0,
		@v2apositiontaking_2 = 0,
		@v2apositiontaking_3 = 0,
		@v2apositiontaking_7 = 0,
		@v2apositiontaking_8 = 0,
		--@v2apositiontaking_9 = 0,
		@v2apositiontaking_20 = 0,
		@v3apositiontaking_1 = 0,
		@v3apositiontaking_2 = 0,
		@v3apositiontaking_3 = 0,
		@v3apositiontaking_20 = 0,
		@v5apositiontaking_1 = 0,
		@v5apositiontaking_2 = 0,
		@v5apositiontaking_3 = 0,
		@v5apositiontaking_20 = 0,
		@v8apositiontaking_1 = 0,
		@v8apositiontaking_3 = 0,
		@v8apositiontaking_20 = 0,
		@v10apositiontaking_1 = 0,
		@v10apositiontaking_2 = 0,
		@v10apositiontaking_3 = 0,
		@v10apositiontaking_20 = 0,
		@v11apositiontaking_1 = 0,
		@v11apositiontaking_20 = 0,
		@v99apositiontaking_1 = 0,
		@v99apositiontaking_2 = 0,
		@v99apositiontaking_3 = 0,
		@v99apositiontaking_9 = 0,
		@v99apositiontaking_20 = 0,
		
		@v161apositiontaking_81  = 0,
		@v161apositiontaking_83  = 0,
		@v161apositiontaking_86  = 0,
		@v161apositiontaking_88  = 0,
		
		@v161alivepositiontaking_85  = 0,
		@v161alivepositiontaking_86  = 0,	
		@v161alivepositiontaking_87  = 0,
		@v161alivepositiontaking_89 = 0,	
		@v161alivepositiontaking_90 = 0,
		
		@v2mpositiontaking_1 = 0,
		@v2mpositiontaking_2 = 0,
		@v2mpositiontaking_3 = 0,
		@v2mpositiontaking_7 = 0,
		@v2mpositiontaking_8 = 0,
		--@v2mpositiontaking_9 = 0,
		@v2mpositiontaking_20 = 0,
		@v3mpositiontaking_1 = 0,
		@v3mpositiontaking_2 = 0,
		@v3mpositiontaking_3 = 0,
		@v3mpositiontaking_20 = 0,
		@v5mpositiontaking_1 = 0,
		@v5mpositiontaking_2 = 0,
		@v5mpositiontaking_3 = 0,
		@v5mpositiontaking_20 = 0,
		@v8mpositiontaking_1 = 0,
		@v8mpositiontaking_3 = 0,
		@v8mpositiontaking_20 = 0,
		@v10mpositiontaking_1 = 0,
		@v10mpositiontaking_2 = 0,
		@v10mpositiontaking_3 = 0,
		@v10mpositiontaking_20 = 0,
		@v11mpositiontaking_1 = 0,
		@v11mpositiontaking_20 = 0,
		@v99mpositiontaking_1 = 0,
		@v99mpositiontaking_2 = 0,
		@v99mpositiontaking_3 = 0,
		@v99mpositiontaking_9 = 0,
		@v99mpositiontaking_20 = 0,
		
		-- number game
		@v161mpositiontaking_81  = 0,
		@v161mpositiontaking_83  = 0,
		@v161mpositiontaking_86  = 0,
		@v161mpositiontaking_88  = 0,
			
		@v161mlivepositiontaking_85  = 0,
		@v161mlivepositiontaking_86  = 0,
		@v161mlivepositiontaking_87  = 0,
		@v161mlivepositiontaking_89 = 0,
		@v161mlivepositiontaking_90 = 0,
		
		@auto_mpositiontaking_1 = 0,
		@auto_mpositiontaking_2 = 0,
		@auto_mpositiontaking_3 = 0,
		@auto_mpositiontaking_4 = 0,
		@auto_mpositiontaking_5 = 0,
		@auto_mpositiontaking_6 = 0,
		@auto_mpositiontaking_7 = 0,
		@auto_mpositiontaking_8 = 0,
		@auto_mpositiontaking_9 = 0,
		@auto_mpositiontaking_10 = 0,
		@auto_mlivepositiontaking_1 = 0,
		@auto_mlivepositiontaking_3 = 0,
		@auto_mlivepositiontaking_7 = 0,
		@auto_mlivepositiontaking_8 = 0,
		@auto_v2mpositiontaking_1 = 0,
		@auto_v2mpositiontaking_2 = 0,
		@auto_v2mpositiontaking_3 = 0,
		@auto_v2mpositiontaking_7 = 0,
		@auto_v2mpositiontaking_8 = 0,
		--@auto_v2mpositiontaking_9 = 0,
		@auto_v2mpositiontaking_20 = 0,
		@auto_v3mpositiontaking_1 = 0,
		@auto_v3mpositiontaking_2 = 0,
		@auto_v3mpositiontaking_3 = 0,
		@auto_v3mpositiontaking_20 = 0,
		@auto_v5mpositiontaking_1 = 0,
		@auto_v5mpositiontaking_2 = 0,
		@auto_v5mpositiontaking_3 = 0,
		@auto_v5mpositiontaking_20 = 0,
		@auto_v8mpositiontaking_1 = 0,
		@auto_v8mpositiontaking_3 = 0,
		@auto_v8mpositiontaking_20 = 0,
		@auto_v10mpositiontaking_1 = 0,
		@auto_v10mpositiontaking_2 = 0,
		@auto_v10mpositiontaking_3 = 0,
		@auto_v10mpositiontaking_20 = 0,
		@auto_v11mpositiontaking_1 = 0,
		@auto_v11mpositiontaking_20 = 0,
		@auto_v99mpositiontaking_1 = 0,
		@auto_v99mpositiontaking_2 = 0,
		@auto_v99mpositiontaking_3 = 0,
		@auto_v99mpositiontaking_9 = 0,
		@auto_v99mpositiontaking_20 = 0,
		

		-- number game
		@auto_v161mpositiontaking_81 = 0,
		@auto_v161mpositiontaking_83 = 0,
		@auto_v161mpositiontaking_86 = 0,
		@auto_v161mpositiontaking_88 = 0,
		
		@auto_v161mlivepositiontaking_85 = 0,
		@auto_v161mlivepositiontaking_86 = 0,
		@auto_v161mlivepositiontaking_87 = 0,
		@auto_v161mlivepositiontaking_89 = 0,
		@auto_v161mlivepositiontaking_90 = 0,
		
		@sitename = N'-',
		@IP = N'-',
		@Language = 'E',
		@SubAccID = 0,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0 
	BEGIN
		SELECT @errcode = 104
		SELECT @ErrMsg =  'Create dummy agent01 for Bingo failed: ' + @username
		RETURN
	END
	print 'Create dummy agent01 for Bingo successfully: ' + @username			
END

--Insert Member Bingo 
SELECT @username = 'BIBet'+rtrim(@CurrencyName)
SELECT @memberID = custid FROM custinfo WITH (NOLOCK) WHERE username = @username
IF (@memberID is not null)
BEGIN
	PRINT 'Member ' + @username + ' already exists. Skip creating.'
END
ELSE
BEGIN
	EXEC dbo.Acc_CustomerInsMember_Ag 
		@custid = @memberid OUTPUT,
		@firstname = N'-',
		@lastname = N'-',
		@creator = 8,
		@username = @username,
		@userpwd = '',
		@phone = N'-',
		@fax = N'-',
		@mobilephone = N'-',
		@playerdiscount = 0,
		@playerdiscountcs = 0,
		@playerdiscount1x2 = 0,
		@playerdiscountnumber = 0,
		@MinBet = 0,
		@MaxBet = 0,
		@MaxPerMatch = 0,
		@MinBetv2 = 0,
		@MaxBetv2 = 0,
		@MaxPerMatchv2 = 0,
		@MinBetv3 = 0,
		@MaxBetv3 = 0,
		@MaxPerMatchv3 = 0,
		@MinBetv5 = 0,
		@MaxBetv5 = 0,
		@MaxPerMatchv5 = 0,
		@MinBetv8 = 0,
		@MaxBetv8 = 0,
		@MaxPerMatchv8 = 0,
		@MinBetv10 = 0,
		@MaxBetv10 = 0,
		@MaxPerMatchv10 = 0,
		@MinBetv11 = 0,
		@MaxBetv11 = 0,
		@MaxPerMatchv11 = 0,
		@MinBetv99 = 0,
		@MaxBetv99 = 0,
		@MaxPerMatchv99 = 0,
		@MinBetv99MP = 0,
		@MaxBetv99MP = 0,
		@MaxPerMatchv99MP = 0,
		
		@MinBetv161 = 0,
		@MaxBetv161 = 0,
		@MaxPerBallv161 = 0,
		@MaxPerMatchv161 = 0,
		
		@credit = 0,
		@suspended = 0,
			
		@Disable151_31 = 0,-- @DisableHorseRacing -> @Disable151_31
		@Disable151_41 = 0,-- @DisableOpenTote -> @Disable151_41
		@Disable151_51 = 0,-- @Disable151_AU -> @Disable151_51    
		@Disable152_41 = 0,-- @Disable152_UK -> @Disable152_41    
		@Disable152_51 = 0,-- @Disable152_AU -> @Disable152_51    
		@Disable153_51 = 0,--@Disable153_AU  -> @Disable153_51 
		@DisableFinancial = 0,
		@DisableCasino = 0, 
		@DisableBingo = 0,
		@DisableNumber = 0,
		
		@recommend = @agentID,
		@ugroup = 'a',
		@closed = 0,
		@apositiontaking_1 = 0,
		@apositiontaking_2 = 0,
		@apositiontaking_3 = 0,
		@apositiontaking_4 = 0,
		@apositiontaking_5 = 0,
		@apositiontaking_6 = 0,
		@apositiontaking_7 = 0,
		@apositiontaking_8 = 0,
		@apositiontaking_9 = 0,
		@apositiontaking_10 = 0,
		@alivepositiontaking_1 = 0,
		@alivepositiontaking_3 = 0,
		@alivepositiontaking_7 = 0,
		@alivepositiontaking_8 = 0,
		@v2apositiontaking_1 = 0,
		@v2apositiontaking_2 = 0,
		@v2apositiontaking_3 = 0,
		@v2apositiontaking_7 = 0,
		@v2apositiontaking_8 = 0,
		--@v2apositiontaking_9 = 0,
		@v2apositiontaking_20 = 0,
		@v3apositiontaking_1 = 0,
		@v3apositiontaking_2 = 0,
		@v3apositiontaking_3 = 0,
		@v3apositiontaking_20 = 0,
		@v5apositiontaking_1 = 0,
		@v5apositiontaking_2 = 0,
		@v5apositiontaking_3 = 0,
		@v5apositiontaking_20 = 0,
		@v8apositiontaking_1 = 0,
		@v8apositiontaking_3 = 0,
		@v8apositiontaking_20 = 0,
		@v10apositiontaking_1 = 0,
		@v10apositiontaking_2 = 0,
		@v10apositiontaking_3 = 0,
		@v10apositiontaking_20 = 0,
		@v11apositiontaking_1 = 0,
		@v11apositiontaking_20 = 0,
		@v99apositiontaking_1 = 0,
		@v99apositiontaking_2 = 0,
		@v99apositiontaking_3 = 0,
		@v99apositiontaking_9 = 0,
		@v99apositiontaking_20 = 0,
		
		@v161apositiontaking_81  = 0, 
		@v161apositiontaking_83  = 0, 
		@v161apositiontaking_86  = 0, 
		@v161apositiontaking_88  = 0, 
		@v161alivepositiontaking_85  = 0,
		@v161alivepositiontaking_86  = 0,
		@v161alivepositiontaking_87  = 0,
		@v161alivepositiontaking_89 = 0,
		@v161alivepositiontaking_90 = 0,
		
		@IP = N'-',
		@success = 0 ,
		@Language = 'E',
		@SubAccID = 0,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0 
	BEGIN
		SELECT @errcode = 105
		SELECT @ErrMsg =  'Create dummy member failed: ' + @username
		RETURN
	END
	print 'Create dummy member for Bingo successfully: ' + @username				
END
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_InsertDummyBI] TO [vnteam]
