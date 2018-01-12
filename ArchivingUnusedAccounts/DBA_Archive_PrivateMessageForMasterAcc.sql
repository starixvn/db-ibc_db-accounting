USE bodb_Message
GO

ALTER PROCEDURE DBA_Archive_PrivateMessageForMasterAcc
	@MasterIDs	VARCHAR(2000) = NULL,
	@Stage		TINYINT = 1
AS
/*
	Created: 20180109@Harper
	Description: Archiving unused Credit accounts - Send private message to direct master
	DB: DBMSG.bodb_message

	Revisions:
		- 20180109@Harper: Initialize SP[RedmineID: #88794]
	Param's Explanation:
		@MasterIDs: list master ID
		@Stage: kind of message when sending
			= 1: stage 1
			= 2: stage 2
	EXEC DBA_Archive_PrivateMessageForMasterAcc @MasterIDs = 1176083, @Stage = 2
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MessageID INT

	--SELECT @MessageID = CASE WHEN @Stage = 1 THEN 1074255111 ELSE 1074255112 END -- hard code

	DECLARE @Creator INT, @CreatorName NVARCHAR(50), @CustID INT, @UserName VARCHAR(30), @i INT, @Max INT
	DECLARE @Content_en1 NVARCHAR(4000), @Content_en2 NVARCHAR(4000), @Content_en NVARCHAR(4000)

	SELECT @Creator = custid, @CreatorName = username
	FROM bodb02.dbo.custInfo WITH (NOLOCK)
	WHERE username = 'starixIT'

	SET @Content_en1 = 'Dear valued agents, '
						+ '<br />' + 'Some of your agents were closed because they have had no new member and their members have had no new bet in the last 3 months. You can re-open them if you wish to keep their business. '
						+ '<br />' + 'Please be informed that the account will be disabled after being closed for 1 month, and you cannot recover a disabled account. '
						+ '<br />' + 'Thank you. '

	SET @Content_en2 = 'Dear valued agents, ' 
						+ '<br />' + 'Please be informed that some of your agents were disabled because they have had no new member and their members have had no new bet in the last 4 months, and you cannot recover a disabled account. '
						+ '<br />' + 'Thank you. '
	
	SELECT @Content_en = CASE WHEN @Stage = 1 THEN @Content_en1 ELSE @Content_en2 END	

	-- Insert message
	EXEC DBMSG.bodb_message.dbo.Dot_Msg_SetMessage2 
		@MessageId	= @MessageId OUTPUT,
		@Content_en = @Content_en,
		@Content_ch = @Content_en,
		@Content_cs = @Content_en,
		@Content_jp = @Content_en,
		@Content_it = @Content_en,
		@Content_th = @Content_en,
		@Content_ko = @Content_en,
		@Content_es = @Content_en,
		@Content_vn = @Content_en,
		@Content_id = @Content_en,
		@MsgType = 1,			 -- message to customer (personal)
		@IsSticky = 0,			 -- Is special Message or not 
		@Creator = @Creator,
		@CreatorName = @CreatorName,
		@IsTest = 0,			 -- Is test or not 
		@IsBatch = 0			 -- normal message (no need to replace the symbol @@ by transid when display)
	
	-- Insert Message Target
	DECLARE @TempMember as table(ID INT IDENTITY(1,1), custid int, username varchar(30))
	
	INSERT INTO @TempMember ( custid, username )
	SELECT ci.custid, ci.username
	FROM bodb02.dbo.custInfo ci WITH (NOLOCK)
		INNER JOIN (
					SELECT VAL AS CustID
					FROM strSplit(@MasterIDs, ',')
					) c ON c.CustID = ci.custid
	SET @i = 1
	SELECT @Max = Max(ID) FROM @TempMember

	WHILE @i <= @Max
	BEGIN
		SELECT @CustID = custid, @UserName = username FROM @TempMember WHERE ID = @i

		EXEC DBMSG.bodb_message.dbo.Dot_Msg_SetUsrMessage
		@MessageId = @MessageId,
		@TargetId = @custID,
		@TargetName = @username,
		@isRead = 0
		
		SELECT @i = @i + 1
	END
	
END