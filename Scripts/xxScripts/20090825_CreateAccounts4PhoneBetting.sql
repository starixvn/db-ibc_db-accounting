SET ansi_warnings OFF
DECLARE	@AgentID	INT,
		@Agent1ID	INT,
		@Agent2ID	INT,
		@Agent3ID	INT,
		@Agent4ID	INT,
		@memberID	INT,
		@username	VARCHAR(25),
		@MemName	VARCHAR(20),
		@i			INT,
		@j			INT,
		@n			INT,
		@s			VARCHAR(5),
		@ErrCode	INT,
		@ErrMsg		VARCHAR(200)  

SELECT	@Agent1ID = custid FROM custinfo (NOLOCK) WHERE username = 'LG999' 
SELECT	@Agent2ID = custid FROM custinfo (NOLOCK) WHERE username = 'NLG999'
SELECT	@Agent3ID = custid FROM custinfo (NOLOCK) WHERE username = 'th8aaLG'
SELECT	@Agent4ID = custid FROM custinfo (NOLOCK) WHERE username = 'th8aaNLG' 

SELECT	@s = '00000'

DECLARE	Customer_Cursor CURSOR FOR

SELECT	@Agent1ID, 9, 400, '999sd'
UNION ALL
SELECT	@Agent2ID, 1028, 1070, '999sd'
UNION ALL 
SELECT	@Agent3ID, 1001, 1375, 'THAA'
UNION ALL 
SELECT	@Agent4ID, 2001, 2040, 'THAA' 	

OPEN Customer_Cursor 
FETCH NEXT FROM Customer_Cursor INTO @AgentID, @i , @n, @MemName  
WHILE @@FETCH_STATUS = 0 
BEGIN
	PRINT 'Create member under agent' 
	PRINT @AgentID 
	SET @j = @i 
	WHILE (@j <= @n)
	BEGIN
		--Insert Member  
		SELECT @memberID = NULL
		SELECT @username = @MemName + RIGHT(@s + CAST(@j AS VARCHAR),5)
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
				@credit = 0,
				@suspended = 0,
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
				@v2apositiontaking_9 = 0,
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
				@v99apositiontaking_20 = 0,
				@answer = N'-',
				@IP = N'-',
				@success = 0 ,
				@Language = 'E',
				@SubAccID = 0,
				@ErrCode = @ErrCode OUTPUT,
				@ErrMsg = @ErrMsg OUTPUT

			IF @ErrCode <> 0 
			BEGIN
				SELECT @errcode = 105
				SELECT @ErrMsg =  'Create member failed: ' + @username
				RETURN
			END
			PRINT 'Create member successfully: ' + @username				
		END
		SET @j = @j + 1 
	END
	FETCH NEXT FROM Customer_Cursor INTO @AgentID, @i, @n, @MemName
END
CLOSE Customer_Cursor
DEALLOCATE Customer_Cursor 
 