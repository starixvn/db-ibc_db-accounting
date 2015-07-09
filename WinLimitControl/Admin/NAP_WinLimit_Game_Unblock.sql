USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_Game_Unblock]    Script Date: 07/07/2015 16:11:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_WinLimit_Game_Unblock]
	@CustID		INT,
	@ProductID	TINYINT,
	@UserID		INT				= 0,
	@IP			VARCHAR(20)		= '',
	@ErrCode	INT				= 0		OUTPUT,
	@ErrMsg		VARCHAR(500)	= ''	OUTPUT
AS
	/*
		Created: Phillip	
		Date: 2015-06-30
		Task: #38608
		DB: DBTXN/bodb02
		
		Revisions:
		
		Parameters Explanation:	
			@@CustID		: Customer ID.
			@ProductID		: Game ID.
			@UserID			: User making this action.
			@IP				: IP of the machine making this action.
			@ErrCode		: Error Code.
			@ErrMsg			: Error Message.
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
	
	SELECT	@StartRun = GETDATE()
	SELECT	@IsBlockedOld = IsBlocked
			,@IsNotifiedOld = IsNotified
			,@UnblockDateOld = UnBlockDate
	FROM	dbo.WinLimit_Game WITH (NOLOCK)
	WHERE	CustID = @CustID 
			AND ProductID = @ProductID
	
	IF @IsBlockedOld = 1
	BEGIN
		SELECT	@UnblockDateNew = CURRENT_TIMESTAMP
		UPDATE	dbo.WinLimit_Game WITH (ROWLOCK, UPDLOCK)
		SET		IsBlocked = 0, IsNotified = 0, UnBlockDate = @UnblockDateNew
		WHERE	CustID = @CustID 
				AND ProductID = @ProductID
		
		IF @@ERROR <> 0
		BEGIN
			SELECT	@ErrCode = 5
					,@ErrMsg = 'The Player does not exist.'
		END
		
		SELECT	@EndRun = GETDATE()
				,@Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
		
		DECLARE @LogSPData VARCHAR(300)
				,@TrackingValue2 VARCHAR(300)

		SELECT	@LogSPData = '<NAP_WinLimit_Game_Unblock '
			+ '" IsBlocked="' + CONVERT(VARCHAR(20), @IsBlockedOld) 
			+ '" IsNotified="' + CONVERT(VARCHAR(20), @IsNotifiedOld)
			+ '" UnblockDate="' + CONVERT(VARCHAR(20), @UnblockDateOld)
			+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
			+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))+'" />'
							
		SELECT	@TrackingValue2 = '<NAP_WinLimit_Game_Unblock '
			+ '" IsBlocked="0'
			+ '" IsNotified="0'
			+ '" UnblockDate="' + CONVERT(VARCHAR(20), @UnblockDateNew)
			+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
			+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))+'" />'

		SELECT @EndRun = GETDATE()
				,@Duration  = DATEDIFF(MILLISECOND,@StartRun,@EndRun)
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID			= @UserID,
				@ActionID		= 2909,
				@TrackingValue	= @LogSPData,
				@TrackingValue2 = @TrackingValue2,
				@Duration		= @Duration
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
				@UserID			= @UserID,
				@ActionID		= 2909,
				@TrackingValue	= @LogSPData,
				@TrackingValue2 = @TrackingValue2,
				@Duration		= @Duration
		END CATCH
	END
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_Game_Unblock] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_Game_Unblock] TO [accteam]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_Game_Unblock] TO [vnteam]
GO