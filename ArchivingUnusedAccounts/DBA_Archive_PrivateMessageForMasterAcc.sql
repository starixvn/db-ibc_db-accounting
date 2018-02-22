USE bodb_Message
GO

ALTER PROCEDURE DBA_Archive_PrivateMessageForMasterAcc
	@MasterList			VARCHAR(MAX) = NULL,	
	@Stage				TINYINT = 1
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
	EXEC DBA_Archive_PrivateMessageForMasterAcc @MasterList = N'<ROOT><Master MasterID="791088" UserName="AA"/><Master MasterID="860379" UserName="BB"/></ROOT>', @Stage = 2
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MessageID INT

	--SELECT @MessageID = CASE WHEN @Stage = 1 THEN 1074255111 ELSE 1074255112 END -- hard code

	DECLARE @Creator INT, @CreatorName NVARCHAR(50), @CustID INT, @UserName VARCHAR(30), @i INT, @Max INT
	DECLARE @Content_en1 NVARCHAR(4000), @Content_en2 NVARCHAR(4000), @Content_en NVARCHAR(4000)
			, @Content_vn1 NVARCHAR(4000), @Content_vn2 NVARCHAR(4000), @Content_vn NVARCHAR(4000)
			, @Content_ch1 NVARCHAR(4000), @Content_ch2 NVARCHAR(4000), @Content_ch NVARCHAR(4000) -- Traditional
			, @Content_cs1 NVARCHAR(4000), @Content_cs2 NVARCHAR(4000), @Content_cs NVARCHAR(4000) -- Simplified
			, @Content_th1 NVARCHAR(4000), @Content_th2 NVARCHAR(4000), @Content_th NVARCHAR(4000) -- Thai

	DECLARE @PostTime DATETIME
	SELECT @PostTime = GETDATE()

	SELECT @Creator = 10278938, @CreatorName = 'starixIT'	

	-- English
	SET @Content_en1 = 'Dear valued agents, '
						+ '<br />' + 'Some of your agents were closed because their members have had No Activity in the last 3 months. You can re-open them if you wish to keep their businesses. '
						+ '<br />' + 'Please be informed that the account will be disabled after being closed for 1 month, and you cannot recover a disabled account. '
						+ '<br />' + 'Thank you. '

	SET @Content_en2 = 'Dear valued agents, ' 
						+ '<br />' + 'Please be informed that some of your agents were disabled because their members have had No Activity in the last 4 months, and you cannot recover a disabled account. '
						+ '<br />' + 'Thank you. '

	-- VietNamese
	SET @Content_vn1 = N'Kính gửi quý khách hàng, '
						+ N'<br />' + N'Một số đại lý của bạn đã bị đóng vì các thành viên của họ đã Không Có Hoạt Động Nào trong 3 tháng qua. Bạn có thể mở lại nếu bạn muốn giữ những đại lý này. '
						+ N'<br />' + N'Xin lưu ý rằng tài khoản sẽ bị vô hiệu sau khi đóng trong 1 tháng và bạn không thể khôi phục tài khoản bị vô hiệu. '
						+ N'<br />' + N'Trân Trọng. '

	SET @Content_vn2 = N'Kính gửi quý khách hàng, ' 
						+ N'<br />' + N'Một số đại lý của bạn đã bị vô hiệu vì các thành viên của họ đã Không Có Hoạt Động Nào trong 4 tháng qua, và bạn không thể khôi phục tài khoản bị vô hiệu. '
						+ N'<br />' + N'Trân Trọng. '

	-- Chinese Traditional
	SET @Content_ch1 = N'尊敬的代理們，'
						+ N'<br />' + N'由於您代理及其會員賬號已長達近 3 個月無活躍操作因此已關閉。倘若關閉賬號持有者有意繼續進行生意仍可重啟賬號。 '
						+ N'<br />' + N'請知悉，賬號將在關閉後的一個月被禁用。禁用後的賬號將無法重啟。 '
						+ N'<br />' + N'謝謝。'

	SET @Content_ch2 = N'尊敬的代理們，' 
						+ N'<br />' + N'請知悉，由於您代理及其會員賬號在近 4 個月內無任何活躍操作因此現已被禁用。已禁用之賬號無法重啟。 '
						+ N'<br />' + N'謝謝。 '

	-- Chinese Simplified
	SET @Content_cs1 = N'尊敬的代理们，'
						+ N'<br />' + N'由于您代理及其会员账号已长达近 3 个月无活跃操作因此已关闭。倘若关闭账号持有者有意继续进行生意仍可重启账号。 '
						+ N'<br />' + N'请知悉，账号将在关闭后的一个月被禁用。禁用后的账号将无法重启。 '
						+ N'<br />' + N'谢谢。 '

	SET @Content_cs2 = N'尊敬的代理们， ' 
						+ N'<br />' + N'请知悉，由于您代理及其会员账号在近 4 个月内无任何活跃操作因此现已被禁用。已禁用之账号无法重启。 '
						+ N'<br />' + N'谢谢。 '
	
	-- Thai
	SET @Content_th1 = N'เรียนเอเจนต์ทุกท่าน '
						+ N'<br />' + N'เอเจนต์ของคุณบางบัญชีถูกปิดเนื่องจากบัญชีสมาชิกไม่มีการใช้งานใดๆ ในช่วง 3เดือนที่ผ่านมา คุณสามารถเปิดกลับอีกครั้งหากต้องการทำธุรกิจต่อและรักษาบัญชีดังกล่าวไว้ '
						+ N'<br />' + N'โปรดทราบว่าบัญชีจะถูกปิดใช้งานหลังจากปิดให้บริการเป็นเวลา 1 เดือนและคุณจะไม่สามารถกู้คืนบัญชีที่ถูกปิดใช้งานได้ '
						+ N'<br />' + N'ขอบคุณค่ะ '

	SET @Content_th2 = N'เรียนเอเจนต์ทุกท่าน ' 
						+ N'<br />' + N'โปรดทราบว่าบัญชีเอเจนต์ของคุณถูกปิดใช้งานเนื่องจากสมาชิกไม่มีการใช้งานใดๆ ในช่วง 4 เดือนที่ผ่านมาและคุณไม่สามารถกู้คืนบัญชีที่ถูกปิดใช้งานได้ '
						+ N'<br />' + N'ขอบคุณค่ะ '

	IF @Stage = 1
	BEGIN
		SELECT @Content_en = @Content_en1,
				@Content_ch = @Content_ch1,
				@Content_cs = @Content_cs1,
				@Content_vn = @Content_vn1,
				@Content_th = @Content_th1
	END
	ELSE
	BEGIN
	    SELECT @Content_en = @Content_en2,
				@Content_ch = @Content_ch2,
				@Content_cs = @Content_cs2,
				@Content_vn = @Content_vn2,
				@Content_th = @Content_th2
	END
		
	
	-- Insert message
	EXEC dbo.Dot_Msg_SetMessage2 
		@MessageId	= @MessageId OUTPUT,
		@Content_en = @Content_en,
		@Content_ch = @Content_ch,
		@Content_cs = @Content_cs,
		@Content_th = @Content_th,
		@Content_vn = @Content_vn,
		@MsgType	= 1,			 -- message to customer (personal)
		@IsSticky	= 0,			 -- Is special Message or not 
		@Creator	= @Creator,
		@CreatorName = @CreatorName,
		@IsTest		= 0,			 -- Is test or not 
		@IsBatch	= 0			 -- normal message (no need to replace the symbol @@ by transid when display)
	
	-- Handle Master information
	DECLARE @TempMember AS TABLE (ID INT IDENTITY(1,1), Custid int, Username varchar(30))
	DECLARE @DocHandler	INT

	BEGIN TRY
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @MasterList

		INSERT INTO @TempMember ( Custid, Username )
		SELECT MasterID, UserName
		FROM OPENXML(@DocHandler, '/ROOT/Master', 1) WITH (MasterID INT, UserName VARCHAR(30)) AS Data

		EXEC sp_xml_removedocument @DocHandler
	END TRY

	BEGIN CATCH
		SELECT ErrCode = 100
			,ErrMsg = N'Paramter invalid.'

		RETURN
	END CATCH;	
	
	-- Insert Message Target	
	SET @i = 1
	SELECT @Max = Max(ID) FROM @TempMember

	WHILE @i <= @Max
	BEGIN
		SELECT @CustID = custid, @UserName = username FROM @TempMember WHERE ID = @i

		EXEC dbo.Dot_Msg_SetUsrMessage
		@MessageId	= @MessageId,
		@TargetId	= @CustID,
		@TargetName = @UserName,
		@PostTime	= @PostTime,
		@isRead		= 0		
		
		SELECT @i = @i + 1
	END
	
END