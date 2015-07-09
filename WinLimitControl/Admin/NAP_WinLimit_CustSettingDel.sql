USE [CustDB]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustSettingDel]    Script Date: 07/07/2015 16:09:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_WinLimit_CustSettingDel]
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
		Task: #38608 - Implement function to control Player's Win Limit on specific Product
		
		DB: DBCust/CustDB
		
		Revisions:
		
		Parameters Explanation:	
			@UserName		: User Name.
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
			,@MaxWinLimitOld MONEY
	SELECT	@StartRun = GETDATE()
	
	SELECT	@MaxWinLimitOld = MaxWinLimit
	FROM	dbo.WinLimit_CustSetting WITH (NOLOCK) 
	WHERE	CustID = @CustID 
			AND ProductID = @ProductID
	
	DELETE dbo.WinLimit_CustSetting
	WHERE CustID = @CustID AND ProductID = @ProductID
	
	IF @@ERROR <> 0
	BEGIN
		SET @ErrCode = 2
		SET @ErrMsg = 'This setting does not exist.'
	END
	
	SELECT	@EndRun = GETDATE()
			,@Duration = DATEDIFF(millisecond, @StartRun, @EndRun)
	
	DECLARE @LogSPData VARCHAR(300)

	SELECT @LogSPData = '<NAP_WinLimit_CustSettingDel '
		+ '" CustID ="' + CONVERT(VARCHAR(20), @CustID) 
		+ '" ProductID="' + CONVERT(VARCHAR(20), @ProductID)
		+ '" MaxWinLimit="' + CONVERT(VARCHAR(20), @MaxWinLimitOld)
		+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
		+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) 
		+ '" />'
		
	BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID			= @UserID,
		@CustID			= @CustID,
		@ActionID		= 2908,
		@TrackingValue	= @LogSPData,
		@Duration		= @Duration
	END TRY
	BEGIN CATCH
	SELECT @LogSPData = '<NAP_WinLimit_CustSettingDel '
		+ '" CustID ="' + CONVERT(VARCHAR(20), @CustID) 
		+ '" ProductID="' + CONVERT(VARCHAR(20), @ProductID)
		+ '" MaxWinLimit="' + CONVERT(VARCHAR(20), @MaxWinLimitOld)
		+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
		+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
		+ '" ErrMsg="'+ COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(400)),SPACE(1)) 
		+ '" />'
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID			= @UserID,
		@CustID			= @CustID,
		@ActionID		= 2908,
		@TrackingValue	= @LogSPData,
		@Duration		= @Duration
	END CATCH
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingDel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingDel] TO [accteam]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustSettingDel] TO [vnteam]
GO