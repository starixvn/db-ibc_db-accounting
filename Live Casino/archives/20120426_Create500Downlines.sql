


/*
script create 500 masters
*/
DECLARE @username NVARCHAR(50),		
		@custid INT

SELECT  @username = 'SuperTestPT',
		@custid = 6485936

DECLARE @tmp TABLE (id INT)
DECLARE @i INT
SET @i = 500

WHILE @i > 0
BEGIN
	INSERT INTO @tmp
		SELECT @i 
	SET @i = @i - 1
END

DECLARE @customers TABLE (id INT IDENTITY, username VARCHAR(50))
INSERT INTO @customers(username)
	SELECT @username + RIGHT('000'+CONVERT(NVARCHAR(5),id),3)
	FROM @tmp 
	ORDER BY id 


SET @i = 1
WHILE @i <= 500
BEGIN	
	SELECT @UserName = username 
	FROM @customers 
	WHERE id = @i

	SET @i = @i + 1
	-- Call to insert data for Master
	DECLARE @p1 INT
	DECLARE @p229 INT
	DECLARE @p230 NVARCHAR(4000)

	EXEC Acc_CustomerInsMember_SAg @custid=@p1 OUTPUT,
	@firstname=N'',@lastname=N'',@creator=8,@username=@UserName,@userpwd='56E8A2D78170E87C928E480797CC73',@phone=N'',@mobilephone=N'',@email=N'',@fax=N'',@address=N'',@city=N'',@STATE=N'',@country=N'',@postal=N'',@TransferOption='00000000',@suspended=0,@Disable151_31=DEFAULT,@Disable151_41=DEFAULT,@Disable151_51=DEFAULT,@Disable152_41=DEFAULT,@Disable152_51=DEFAULT,@Disable153_51=DEFAULT,@DisableFinancial=DEFAULT,@DisableCasino=DEFAULT,@DisableAutoMPT=0,@DisableBingo=DEFAULT,@DisableNumber=DEFAULT,@suspendedFlag='Acc',@IsInternal=0,@minbet=$0.0000,@maxbet=$0.0000,@maxpermatch=$0.0000,@minbetv2=$0.0000,@maxbetv2=$0.0000,@maxpermatchv2=$0.0000,@minbetv3=$0.0000,@maxbetv3=$0.0000,@maxpermatchv3=$0.0000,@minbetv5=$0.0000,@maxbetv5=$0.0000,@maxpermatchv5=$0.0000,@minbetv8=$0.0000,@maxbetv8=$0.0000,@maxpermatchv8=$0.0000,@minbetv10=$0.0000,@maxbetv10=$0.0000,@maxpermatchv10=$0.0000,@minbetv11=$0.0000,@maxbetv11=$0.0000,@maxpermatchv11=$0.0000,@minbetv99=$0.0000,@maxbetv99=$0.0000,@maxpermatchv99=$0.0000,@minbetv99mp=$0.0000,@maxbetv99mp=$0.0000,@maxpermatchv99mp=$0.0000,@minbetv161=$0.0000,@maxbetv161=$0.0000,@maxpermatchv161=$0.0000,@maxperballv161=$0.0000,@credit=0.0000,@srecommend=@custid,@spositiontaking_1=$0.0000,@spositiontaking_2=$0.0000,@spositiontaking_3=$0.0000,@spositiontaking_4=$0.0000,@spositiontaking_5=$0.0000,@spositiontaking_6=$0.0000,@spositiontaking_7=$0.0000,@spositiontaking_8=$0.0000,@spositiontaking_9=$0.0000,@spositiontaking_10=$0.0000,@slivepositiontaking_1=$0.0000,@slivepositiontaking_3=$0.0000,@slivepositiontaking_7=$0.0000,@slivepositiontaking_8=$0.0000,@v2spositiontaking_1=$0.0000,@v2spositiontaking_2=$0.0000,@v2spositiontaking_3=$0.0000,@v2spositiontaking_7=$0.0000,@v2spositiontaking_8=$0.0000,@v2spositiontaking_20=$0.0000,@v3spositiontaking_1=$0.0000,@v3spositiontaking_2=$0.0000,@v3spositiontaking_3=$0.0000,@v3spositiontaking_20=$0.0000,@v5spositiontaking_1=$0.0000,@v5spositiontaking_2=$0.0000,@v5spositiontaking_3=$0.0000,@v5spositiontaking_20=$0.0000,@v8spositiontaking_1=$0.0000,@v8spositiontaking_3=$0.0000,@v8spositiontaking_20=$0.0000,@v10spositiontaking_1=$0.0000,@v10spositiontaking_2=$0.0000,@v10spositiontaking_3=$0.0000,@v10spositiontaking_20=$0.0000,@v11spositiontaking_1=$0.0000,@v11spositiontaking_20=$0.0000,@v99spositiontaking_1=$0.0000,@v99spositiontaking_2=$0.0000,@v99spositiontaking_3=$0.0000,@v99spositiontaking_20=$0.0000,@v99spositiontaking_9=$0.0000,@v161spositiontaking_81=$0.0000,@v161spositiontaking_83=$0.0000,@v161spositiontaking_86=$0.0000,@v161spositiontaking_88=$0.0000,@v161slivepositiontaking_85=$0.0000,@v161slivepositiontaking_86=$0.0000,@v161slivepositiontaking_87=$0.0000,@v161slivepositiontaking_89=$0.0000,@v161slivepositiontaking_90=$0.0000,@groupa=0,@groupb=0,@groupc=0,@groupd=0,@discountcs=0,@discount1x2=0,@discountnumber=0,@auto_spositiontaking_1=0.0000,@auto_spositiontaking_2=0.0000,@auto_spositiontaking_3=0.0000,@auto_spositiontaking_4=0.0000,@auto_spositiontaking_5=0.0000,@auto_spositiontaking_6=0.0000,@auto_spositiontaking_7=0.0000,@auto_spositiontaking_8=0.0000,@auto_spositiontaking_9=0.0000,@auto_spositiontaking_10=0.0000,@auto_slivepositiontaking_1=0.0000,@auto_slivepositiontaking_3=0.0000,@auto_slivepositiontaking_7=0.0000,@auto_slivepositiontaking_8=0.0000,@auto_v2spositiontaking_1=0.0000,@auto_v2spositiontaking_2=0.0000,@auto_v2spositiontaking_3=0.0000,@auto_v2spositiontaking_7=0.0000,@auto_v2spositiontaking_8=0.0000,@auto_v2spositiontaking_20=0.0000,@auto_v3spositiontaking_1=0.0000,@auto_v3spositiontaking_2=0.0000,@auto_v3spositiontaking_3=0.0000,@auto_v3spositiontaking_20=0.0000,@auto_v5spositiontaking_1=0.0000,@auto_v5spositiontaking_2=0.0000,@auto_v5spositiontaking_3=0.0000,@auto_v5spositiontaking_20=0.0000,@auto_v8spositiontaking_1=0.0000,@auto_v8spositiontaking_3=0.0000,@auto_v8spositiontaking_20=0.0000,@auto_v10spositiontaking_1=0.0000,@auto_v10spositiontaking_2=0.0000,@auto_v10spositiontaking_3=0.0000,@auto_v10spositiontaking_20=0.0000,@auto_v11spositiontaking_1=0.0000,@auto_v11spositiontaking_20=0.0000,@auto_v99spositiontaking_1=0.0000,@auto_v99spositiontaking_2=0.0000,@auto_v99spositiontaking_3=0.0000,@auto_v99spositiontaking_20=0.0000,@auto_v99spositiontaking_9=0.0000,@auto_v161spositiontaking_81=0.0000,@auto_v161spositiontaking_83=0.0000,@auto_v161spositiontaking_86=0.0000,@auto_v161spositiontaking_88=0.0000,@auto_v161slivepositiontaking_85=0.0000,@auto_v161slivepositiontaking_86=0.0000,@auto_v161slivepositiontaking_87=0.0000,@auto_v161slivepositiontaking_89=0.0000,@auto_v161slivepositiontaking_90=0.0000,@LANGUAGE=DEFAULT,@SubAccID=0,@mpositiontaking_1=0.0000,@mpositiontaking_2=0.0000,@mpositiontaking_3=0.0000,@mpositiontaking_4=0.0000,@mpositiontaking_5=0.0000,@mpositiontaking_6=0.0000,@mpositiontaking_7=0.0000,@mpositiontaking_8=0.0000,@mpositiontaking_9=0.0000,@mpositiontaking_10=0.0000,@mlivepositiontaking_1=0.0000,@mlivepositiontaking_3=0.0000,@mlivepositiontaking_7=0.0000,@mlivepositiontaking_8=0.0000,@v2mpositiontaking_1=0.0000,@v2mpositiontaking_2=0.0000,@v2mpositiontaking_3=0.0000,@v2mpositiontaking_7=0.0000,@v2mpositiontaking_8=0.0000,@v2mpositiontaking_20=0.0000,@v3mpositiontaking_1=0.0000,@v3mpositiontaking_2=0.0000,@v3mpositiontaking_3=0.0000,@v3mpositiontaking_20=0.0000,@v5mpositiontaking_1=0.0000,@v5mpositiontaking_2=0.0000,@v5mpositiontaking_3=0.0000,@v5mpositiontaking_20=0.0000,@v8mpositiontaking_1=0.0000,@v8mpositiontaking_3=0.0000,@v8mpositiontaking_20=0.0000,@v10mpositiontaking_1=0.0000,@v10mpositiontaking_2=0.0000,@v10mpositiontaking_3=0.0000,@v10mpositiontaking_20=0.0000,@v11mpositiontaking_1=0.0000,@v11mpositiontaking_20=0.0000,@v99mpositiontaking_1=0.0000,@v99mpositiontaking_2=0.0000,@v99mpositiontaking_3=0.0000,@v99mpositiontaking_20=0.0000,@v99mpositiontaking_9=0.0000,@v161mpositiontaking_81=0.0000,@v161mpositiontaking_83=0.0000,@v161mpositiontaking_86=0.0000,@v161mpositiontaking_88=0.0000,@v161mlivepositiontaking_85=0.0000,@v161mlivepositiontaking_86=0.0000,@v161mlivepositiontaking_87=0.0000,@v161mlivepositiontaking_89=0.0000,@v161mlivepositiontaking_90=0.0000,@DisableP2P=DEFAULT,@DisableFUNP2P=DEFAULT,@IP='202.78.228.8',
	@ErrCode=@p229 OUTPUT,@ErrMsg=@p230 OUTPUT,@site=''
	SELECT @p1, @p229, @p230	
	
END
/*
End of script create 500 masters
*/



/*
==========================================================================================================
script create 500 agents
==========================================================================================================
*/
DECLARE @username NVARCHAR(50),		
		@custid INT

SELECT  @username = 'SuperTestPT0001',
		@custid = 0

SELECT @custid = custid
FROM custinfo WITH(NOLOCK)
WHERE username = @username

DECLARE @tmp TABLE (id INT)
DECLARE @i INT
SET @i = 500

WHILE @i > 0
BEGIN
	INSERT INTO @tmp
		SELECT @i 
	SET @i = @i - 1
END

DECLARE @customers TABLE (id INT IDENTITY, username VARCHAR(50))
INSERT INTO @customers(username)
	SELECT @username + RIGHT('000'+CONVERT(NVARCHAR(5),id),3)
	FROM @tmp 
	ORDER BY id 


SET @i = 1
WHILE @i <= 500
BEGIN	
	SELECT @UserName = username 
	FROM @customers 
	WHERE id = @i

	SET @i = @i + 1
	-- Call to insert data for Master
	DECLARE @p1 INT
    DECLARE @p230 INT
    DECLARE @p231 NVARCHAR(4000)

    EXEC Acc_CustomerInsMember_MAg @custid=@p1 OUTPUT,@firstname=N'',@lastname=N'',@creator=8,@username=@username,@userpwd='56E8A2D78170E87C928E480797CC73',@discountcs=0,@discount1x2=0,@discountnumber=0,@phone=N'',@mobilephone=N'',@email=N'',@fax=N'',@address=N'',@city=N'',@STATE=N'',@country=N'',@postal=N'',@groupa=0,@groupb=0,@groupc=0,@groupd=0,@TransferOption='00000000',@suspended=0,@Disable151_31=DEFAULT,@Disable151_41=DEFAULT,@Disable151_51=DEFAULT,@Disable152_41=DEFAULT,@Disable152_51=DEFAULT,@Disable153_51=DEFAULT,@DisableFinancial=DEFAULT,@DisableCasino=DEFAULT,@suspendedFlag=DEFAULT,@IsInternal=0,@DisableBingo=DEFAULT,@DisableNumber=DEFAULT,@MinBet=$0.0000,@MaxBet=$0.0000,@MaxPerMatch=$0.0000,@MinBetv2=$0.0000,@MaxBetv2=$0.0000,@MaxPerMatchv2=$0.0000,@MinBetv3=$0.0000,@MaxBetv3=$0.0000,@MaxPerMatchv3=$0.0000,@MinBetv5=$0.0000,@MaxBetv5=$0.0000,@MaxPerMatchv5=$0.0000,@MinBetv8=$0.0000,@MaxBetv8=$0.0000,@MaxPerMatchv8=$0.0000,@MinBetv10=$0.0000,@MaxBetv10=$0.0000,@MaxPerMatchv10=$0.0000,@MinBetv11=$0.0000,@MaxBetv11=$0.0000,@MaxPerMatchv11=$0.0000,@MinBetv99=$0.0000,@MaxBetv99=$0.0000,@MaxPerMatchv99=$0.0000,@MinBetv99mp=$0.0000,@MaxBetv99mp=$0.0000,@MaxPerMatchv99mp=$0.0000,@MinBetv161=0.0000,@MaxBetv161=0.0000,@MaxPerMatchv161=0.0000,@MaxPerBallv161=0.0000,@credit=0.0000,@maxcredit=0.0000,@mrecommend=@custid,@apositiontaking_1=0.0000,@apositiontaking_2=0.0000,@apositiontaking_3=0.0000,@apositiontaking_4=0.0000,@apositiontaking_5=0.0000,@apositiontaking_6=0.0000,@apositiontaking_7=0.0000,@apositiontaking_8=0.0000,@apositiontaking_9=0.0000,@apositiontaking_10=0.0000,@mpositiontaking_1=0.0000,@mpositiontaking_2=0.0000,@mpositiontaking_3=0.0000,@mpositiontaking_4=0.0000,@mpositiontaking_5=0.0000,@mpositiontaking_6=0.0000,@mpositiontaking_7=0.0000,@mpositiontaking_8=0.0000,@mpositiontaking_9=0.0000,@mpositiontaking_10=0.0000,@alivepositiontaking_1=0.0000,@alivepositiontaking_3=0.0000,@alivepositiontaking_7=0.0000,@alivepositiontaking_8=0.0000,@mlivepositiontaking_1=0.0000,@mlivepositiontaking_3=0.0000,@mlivepositiontaking_7=0.0000,@mlivepositiontaking_8=0.0000,@v2apositiontaking_1=0.0000,@v2apositiontaking_2=0.0000,@v2apositiontaking_3=0.0000,@v2apositiontaking_7=0.0000,@v2apositiontaking_8=0.0000,@v2apositiontaking_20=0.0000,@v3apositiontaking_1=0.0000,@v3apositiontaking_2=0.0000,@v3apositiontaking_3=0.0000,@v3apositiontaking_20=0.0000,@v5apositiontaking_1=0.0000,@v5apositiontaking_2=0.0000,@v5apositiontaking_3=0.0000,@v5apositiontaking_20=0.0000,@v8apositiontaking_1=0.0000,@v8apositiontaking_3=0.0000,@v8apositiontaking_20=0.0000,@v10apositiontaking_1=0.0000,@v10apositiontaking_2=0.0000,@v10apositiontaking_3=0.0000,@v10apositiontaking_20=0.0000,@v11apositiontaking_1=0.0000,@v11apositiontaking_20=0.0000,@v99apositiontaking_1=0.0000,@v99apositiontaking_2=0.0000,@v99apositiontaking_3=0.0000,@v99apositiontaking_20=0.0000,@v99apositiontaking_9=0.0000,@v161apositiontaking_81=0.0000,@v161apositiontaking_83=0.0000,@v161apositiontaking_86=0.0000,@v161apositiontaking_88=0.0000,@v161alivepositiontaking_85=0.0000,@v161alivepositiontaking_86=0.0000,@v161alivepositiontaking_87=0.0000,@v161alivepositiontaking_89=0.0000,@v161alivepositiontaking_90=0.0000,@v2mpositiontaking_1=0.0000,@v2mpositiontaking_2=0.0000,@v2mpositiontaking_3=0.0000,@v2mpositiontaking_7=0.0000,@v2mpositiontaking_8=0.0000,@v2mpositiontaking_20=0.0000,@v3mpositiontaking_1=0.0000,@v3mpositiontaking_2=0.0000,@v3mpositiontaking_3=0.0000,@v3mpositiontaking_20=0.0000,@v5mpositiontaking_1=0.0000,@v5mpositiontaking_2=0.0000,@v5mpositiontaking_3=0.0000,@v5mpositiontaking_20=0.0000,@v8mpositiontaking_1=0.0000,@v8mpositiontaking_3=0.0000,@v8mpositiontaking_20=0.0000,@v10mpositiontaking_1=0.0000,@v10mpositiontaking_2=0.0000,@v10mpositiontaking_3=0.0000,@v10mpositiontaking_20=0.0000,@v11mpositiontaking_1=0.0000,@v11mpositiontaking_20=0.0000,@v99mpositiontaking_1=0.0000,@v99mpositiontaking_2=0.0000,@v99mpositiontaking_3=0.0000,@v99mpositiontaking_20=0.0000,@v99mpositiontaking_9=0.0000,@v161mpositiontaking_81=0.0000,@v161mpositiontaking_83=0.0000,@v161mpositiontaking_86=0.0000,@v161mpositiontaking_88=0.0000,@v161mlivepositiontaking_85=0.0000,@v161mlivepositiontaking_86=0.0000,@v161mlivepositiontaking_87=0.0000,@v161mlivepositiontaking_89=0.0000,@v161mlivepositiontaking_90=0.0000,@auto_mpositiontaking_1=0.0000,@auto_mpositiontaking_2=0.0000,@auto_mpositiontaking_3=0.0000,@auto_mpositiontaking_4=0.0000,@auto_mpositiontaking_5=0.0000,@auto_mpositiontaking_6=0.0000,@auto_mpositiontaking_7=0.0000,@auto_mpositiontaking_8=0.0000,@auto_mpositiontaking_9=0.0000,@auto_mpositiontaking_10=0.0000,@auto_mlivepositiontaking_1=0.0000,@auto_mlivepositiontaking_3=0.0000,@auto_mlivepositiontaking_7=0.0000,@auto_mlivepositiontaking_8=0.0000,@auto_v2mpositiontaking_1=0.0000,@auto_v2mpositiontaking_2=0.0000,@auto_v2mpositiontaking_3=0.0000,@auto_v2mpositiontaking_7=0.0000,@auto_v2mpositiontaking_8=0.0000,@auto_v2mpositiontaking_20=0.0000,@auto_v3mpositiontaking_1=0.0000,@auto_v3mpositiontaking_2=0.0000,@auto_v3mpositiontaking_3=0.0000,@auto_v3mpositiontaking_20=0.0000,@auto_v5mpositiontaking_1=0.0000,@auto_v5mpositiontaking_2=0.0000,@auto_v5mpositiontaking_3=0.0000,@auto_v5mpositiontaking_20=0.0000,@auto_v8mpositiontaking_1=0.0000,@auto_v8mpositiontaking_3=0.0000,@auto_v8mpositiontaking_20=0.0000,@auto_v10mpositiontaking_1=0.0000,@auto_v10mpositiontaking_2=0.0000,@auto_v10mpositiontaking_3=0.0000,@auto_v10mpositiontaking_20=0.0000,@auto_v11mpositiontaking_1=0.0000,@auto_v11mpositiontaking_20=0.0000,@auto_v99mpositiontaking_1=0.0000,@auto_v99mpositiontaking_2=0.0000,@auto_v99mpositiontaking_3=0.0000,@auto_v99mpositiontaking_20=0.0000,@auto_v99mpositiontaking_9=0.0000,@auto_v161mpositiontaking_81=0.0000,@auto_v161mpositiontaking_83=0.0000,@auto_v161mpositiontaking_86=0.0000,@auto_v161mpositiontaking_88=0.0000,@auto_v161mlivepositiontaking_85=0.0000,@auto_v161mlivepositiontaking_86=0.0000,@auto_v161mlivepositiontaking_87=0.0000,@auto_v161mlivepositiontaking_89=0.0000,@auto_v161mlivepositiontaking_90=0.0000,@DisableP2P=DEFAULT,@DisableFUNP2P=DEFAULT,@sitename=DEFAULT,@IP='202.78.228.8',@LANGUAGE='E',@SubAccID=0,@ErrCode=@p230 OUTPUT,@ErrMsg=@p231 OUTPUT
    SELECT @p1, @p230, @p231
	
END
/*
==========================================================================================================
End of script create 500 agents
==========================================================================================================
*/



/*
==========================================================================================================
script create 500 members
==========================================================================================================
*/
DECLARE @username NVARCHAR(50),		
		@custid INT

SELECT  @username = 'SuperTestPT00010001',
		@custid = 0

SELECT @custid = custid
FROM custinfo WITH(NOLOCK)
WHERE username = @username


DECLARE @tmp TABLE (id INT)
DECLARE @i INT
SET @i = 500

WHILE @i > 0
BEGIN
	INSERT INTO @tmp
		SELECT @i 
	SET @i = @i - 1
END

DECLARE @customers TABLE (id INT IDENTITY, username VARCHAR(50))
INSERT INTO @customers(username)
	SELECT @username + RIGHT('000'+CONVERT(NVARCHAR(5),id),3)
	FROM @tmp 
	ORDER BY id 


SET @i = 1
WHILE @i <= 500
BEGIN	
	SELECT @UserName = username 
	FROM @customers 
	WHERE id = @i

	SET @i = @i + 1
	
	DECLARE @ugroup VARCHAR(5),
			@currency INT	    
		 
	SELECT @currency  = currency FROM custinfo WITH(NOLOCK) WHERE custid = @custid
	IF @currency IN (45,36,16)
		SET @ugroup = CASE @currency WHEN 45 THEN 'dea'
									 WHEN 36 THEN 'hka'
									 WHEN 16 THEN 'hka'    ELSE 'a'
						END          
		-- Call to insert data for Member  
		DECLARE @p1 INT
		DECLARE @p115 BIT
		DECLARE @p118 INT
		DECLARE @p119 NVARCHAR(4000)

		EXEC Acc_CustomerInsMember_Ag @custid=@p1 OUTPUT,@firstname=N'',@lastname=N'',@creator=8,@username=@username,@userpwd='56E8A2D78170E87C928E480797CC73',@phone=N'',@fax=N'',@mobilephone=N'',@playerdiscount=0,@playerdiscountcs=0,@playerdiscount1x2=0,@playerdiscountnumber=0,@MinBet=$0.0000,@MaxBet=$0.0000,@MaxPerMatch=$0.0000,@MinBetv2=$0.0000,@MaxBetv2=$0.0000,@MaxPerMatchv2=$0.0000,@MinBetv3=$0.0000,@MaxBetv3=$0.0000,@MaxPerMatchv3=$0.0000,@MinBetv5=$0.0000,@MaxBetv5=$0.0000,@MaxPerMatchv5=$0.0000,@MinBetv8=$0.0000,@MaxBetv8=$0.0000,@MaxPerMatchv8=$0.0000,@MinBetv10=$0.0000,@MaxBetv10=$0.0000,@MaxPerMatchv10=$0.0000,@MinBetv11=$0.0000,@MaxBetv11=$0.0000,@MaxPerMatchv11=$0.0000,@MinBetv99=$0.0000,@MaxBetv99=$0.0000,@MaxPerMatchv99=$0.0000,@MinBetv99MP=$0.0000,@MaxBetv99MP=$0.0000,@MaxPerMatchv99MP=$0.0000,@MinBetv161=0.0000,@MaxBetv161=0.0000,@MaxPerBallv161=0.0000,@MaxPerMatchv161=0.0000,@credit=0.0000,@suspended=0,@Disable151_31=DEFAULT,@Disable151_41=DEFAULT,@Disable151_51=DEFAULT,@Disable152_41=DEFAULT,@Disable152_51=DEFAULT,@Disable153_51=DEFAULT,@DisableFinancial=DEFAULT,@DisableCasino=DEFAULT,@DisableBingo=DEFAULT,@DisableNumber=DEFAULT,@recommend=@custid,@ugroup=@ugroup,@closed=0,@suspendedFlag=DEFAULT,@apositiontaking_1=0.0000,@apositiontaking_2=0.0000,@apositiontaking_3=0.0000,@apositiontaking_4=0.0000,@apositiontaking_5=0.0000,@apositiontaking_6=0.0000,@apositiontaking_7=0.0000,@apositiontaking_8=0.0000,@apositiontaking_9=0.0000,@apositiontaking_10=0.0000,@alivepositiontaking_1=0.0000,@alivepositiontaking_3=0.0000,@alivepositiontaking_7=0.0000,@alivepositiontaking_8=0.0000,@v2apositiontaking_1=0.0000,@v2apositiontaking_2=0.0000,@v2apositiontaking_3=0.0000,@v2apositiontaking_7=0.0000,@v2apositiontaking_8=0.0000,@v2apositiontaking_20=0.0000,@v3apositiontaking_1=0.0000,@v3apositiontaking_2=0.0000,@v3apositiontaking_3=0.0000,@v3apositiontaking_20=0.0000,@v5apositiontaking_1=0.0000,@v5apositiontaking_2=0.0000,@v5apositiontaking_3=0.0000,@v5apositiontaking_20=0.0000,@v8apositiontaking_1=0.0000,@v8apositiontaking_3=0.0000,@v8apositiontaking_20=0.0000,@v10apositiontaking_1=0.0000,@v10apositiontaking_2=0.0000,@v10apositiontaking_3=0.0000,@v10apositiontaking_20=0.0000,@v11apositiontaking_1=0.0000,@v11apositiontaking_20=0.0000,@v99apositiontaking_1=0.0000,@v99apositiontaking_2=0.0000,@v99apositiontaking_3=0.0000,@v99apositiontaking_9=0.0000,@v99apositiontaking_20=0.0000,@v161apositiontaking_81=0.0000,@v161apositiontaking_83=0.0000,@v161apositiontaking_86=0.0000,@v161apositiontaking_88=0.0000,@v161alivepositiontaking_85=0.0000,@v161alivepositiontaking_86=0.0000,@v161alivepositiontaking_87=0.0000,@v161alivepositiontaking_89=0.0000,@v161alivepositiontaking_90=0.0000,@DisableP2P=DEFAULT,@DisableFUNP2P=DEFAULT,@IP='202.78.228.91',@success=@p115 OUTPUT,@LANGUAGE='E',@SubAccID=0,@ErrCode=@p118 OUTPUT,@ErrMsg=@p119 OUTPUT
		SELECT @p1, @p115, @p118, @p119	 
END
/*
==========================================================================================================
End of script create 500 members
==========================================================================================================
*/