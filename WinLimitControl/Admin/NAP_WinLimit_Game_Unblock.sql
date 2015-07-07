USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_Game_Unblock]    Script Date: 07/07/2015 16:11:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_Game_Unblock]
	@CustID		INT,
	@ProductID	INT,
	@UserID		INT = 0,
	@IP			VARCHAR(20) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Phillip	
		Date: 2015-06-30
		Task: #38608
		DB: DBCust/CustDB
		
		Revisions:
		
		Parameters Explanation:	
			@UserName : User Name.
			@ProductID: Game ID.
	*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @StartRun DATETIME
			,@EndRun DATETIME
			,@Duration INT
			,@IsBlockedOld BIT
			,@IsNotifiedOld BIT
			,@UnblockDateOld DATETIME
			,@UnblockDateNew DATETIME
	
	SET @StartRun = GETDATE()
	SELECT @IsBlockedOld = IsBlocked
			,@IsNotifiedOld = IsNotified
			,@UnblockDateOld = UnBlockDate
	FROM dbo.WinLimit_Game
	WHERE CustID = @CustID AND ProductID = @ProductID
	
	IF @IsBlockedOld = 1
	BEGIN
		SET @UnblockDateNew = CURRENT_TIMESTAMP
		UPDATE dbo.WinLimit_Game WITH (ROWLOCK)
		SET IsBlocked = 0, IsNotified = 0, UnBlockDate = @UnblockDateNew
		WHERE CustID = @CustID AND ProductID = @ProductID
		
		IF @@ERROR <> 0
		BEGIN
			SET @ErrCode = 5
			SET @ErrMsg = 'The Player does not exist.'
		END
		
		SET @EndRun = GETDATE()
		SET @Duration = DATEDIFF(millisecond, @StartRun, @EndRun)
		
		DECLARE @LogSPData VARCHAR(300)
		DECLARE @TrackingValue2 VARCHAR(300)

		SELECT @LogSPData = '<NAP_WinLimit_Game_Unblock '
			+ '" IsBlocked="' + CONVERT(VARCHAR(20), @IsBlockedOld) 
			+ '" IsNotified="' + CONVERT(VARCHAR(20), @IsNotifiedOld)
			+ '" UnblockDate="' + CONVERT(VARCHAR(20), @UnblockDateOld)
			+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
			+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))+'" />'
							
		SELECT @TrackingValue2 = '<NAP_WinLimit_Game_Unblock '
			+ '" IsBlocked="0'
			+ '" IsNotified="0'
			+ '" UnblockDate="' + CONVERT(VARCHAR(20), @UnblockDateNew)
			+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
			+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))+'" />'

		SET @EndRun = GETDATE()
		SET @Duration  = DATEDIFF(MILLISECOND,@StartRun,@EndRun)

		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@ActionID = 2909,
				@TrackingValue = @LogSPData	,
				@TrackingValue2 = @TrackingValue2,
				@Duration = @Duration
		END TRY
		BEGIN CATCH
			SELECT @LogSPData = '<NAP_WinLimit_Game_Unblock '
			+ '" IsBlocked="' + CONVERT(VARCHAR(20), @IsBlockedOld) 
			+ '" IsNotified="' + CONVERT(VARCHAR(20), @IsNotifiedOld)
			+ '" UnblockDate="' + CONVERT(VARCHAR(20), @UnblockDateOld)
			+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
			+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
				+ '" ErrMsg="'+ COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(400)),SPACE(1)) +'" />'
				
			SELECT @TrackingValue2 = '<NAP_WinLimit_Game_Unblock '
				+ '" IsBlocked="0'
				+ '" IsNotified="0'
				+ '" UnblockDate="' + CONVERT(VARCHAR(20), @UnblockDateNew)
				+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
				+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
				+ '" ErrMsg="'+ COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(400)),SPACE(1)) +'" />'
				
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@ActionID = 2909,
				@TrackingValue = @LogSPData	,
				@TrackingValue2 = @TrackingValue2,
				@Duration = @Duration
		END CATCH
	END
	
END
GO

