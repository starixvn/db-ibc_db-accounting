USE [CustDB]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustSettingIns]    Script Date: 07/07/2015 16:09:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_WinLimit_CustSettingIns]
	@CustID			INT,
	@ProductID		TINYINT,
	@MaxWinLimit	MONEY,
	@UserID			INT				= 0,
	@IP				VARCHAR(20)		= '',
	@ErrCode		INT				= 0		OUTPUT,
	@ErrMsg			VARCHAR(500)	= ''	OUTPUT
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
			@MaxWinLimit	: Player Win Limit.
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
	SELECT @StartRun = GETDATE()
	IF EXISTS(SELECT 1 FROM dbo.WinLimit_CustSetting WITH (NOLOCK) WHERE CustID = @CustID AND ProductID = @ProductID)
	BEGIN
		SELECT	@ErrCode = 1
				,@ErrMsg = 'This setting is already set.'
		RETURN;
	END
	
	BEGIN TRY
		INSERT INTO dbo.WinLimit_CustSetting 
		(
			CustID,
			ProductID,
			MaxWinLimit
		)
		VALUES
		(
			@CustID,
			@ProductID,
			@MaxWinLimit
		)
	END TRY
	BEGIN CATCH
		SELECT	@ErrCode = 1
				,@ErrMsg = 'This setting is already set.'
	END CATCH;
	
	SELECT	@EndRun = GETDATE()
			,@Duration = DATEDIFF(millisecond, @StartRun, @EndRun)
	
	DECLARE @LogSPData VARCHAR(300)

	SELECT	@LogSPData = '<NAP_WinLimit_CustSettingIns '
		+ '" CustID ="' + CONVERT(VARCHAR(20), @CustID) 
		+ '" ProductID="' + CONVERT(VARCHAR(20), @ProductID)
		+ '" MaxWinLimit="' + CONVERT(VARCHAR(20), @MaxWinLimit)
		+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
		+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
		+ '" />'
		
	BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID			= @UserID,
		@CustID			= @CustID,
		@ActionID		= 2906,
		@TrackingValue	= @LogSPData,
		@Duration		= @Duration
	END TRY
	BEGIN CATCH
	SELECT @LogSPData = '<NAP_WinLimit_CustSettingIns '
		+ '" CustID ="' + CONVERT(VARCHAR(20), @CustID) 
		+ '" ProductID="' + CONVERT(VARCHAR(20), @ProductID)
		+ '" MaxWinLimit="' + CONVERT(VARCHAR(20), @MaxWinLimit)
		+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
		+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
		+ '" ErrMsg="'+ COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(400)),SPACE(1)) 
		+ '" />'
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID			= @UserID,
		@CustID			= @CustID,
		@ActionID		= 2906,
		@TrackingValue	= @LogSPData,
		@Duration		= @Duration
	END CATCH
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingIns] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingIns] TO [accteam]
GO