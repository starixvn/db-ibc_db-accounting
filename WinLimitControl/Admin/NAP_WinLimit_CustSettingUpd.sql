USE [CustDB]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustSettingUpd]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[NAP_WinLimit_CustSettingUpd]
GO

USE [CustDB]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustSettingUpd]    Script Date: 07/07/2015 16:09:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingUpd]
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
			@CustID			: Customer ID.
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
			,@MaxWinLimitOld MONEY
	SELECT	@StartRun = GETDATE()
	IF NOT EXISTS(SELECT 1 FROM dbo.WinLimit_CustSetting WITH (NOLOCK) WHERE CustID = @CustID AND ProductID = @ProductID)
	BEGIN
		SELECT	@ErrCode = 2
				,@ErrMsg = 'This setting does not exist.'
		RETURN;
	END
	
	SELECT	@MaxWinLimitOld = MaxWinLimit 
	FROM	dbo.WinLimit_CustSetting WITH (NOLOCK) 
	WHERE	CustID = @CustID AND ProductID = @ProductID
	
	UPDATE	dbo.WinLimit_CustSetting WITH (ROWLOCK, UPDLOCK)
	SET		MaxWinLimit = @MaxWinLimit
	WHERE	CustID = @CustID 
			AND ProductID = @ProductID
	
	IF @@ERROR <> 0
	BEGIN
		SELECT	@ErrCode = 2
				,@ErrMsg = 'This setting does not exist.'
		RETURN;
	END
	
	SELECT	@EndRun = GETDATE()
			,@Duration = DATEDIFF(millisecond, @StartRun, @EndRun)
	
	DECLARE @LogSPData VARCHAR(300)
			,@TrackingValue2 VARCHAR(300)

	SELECT @LogSPData = '<NAP_WinLimit_CustSettingUpd '
		+ '" CustID ="' + CONVERT(VARCHAR(20), @CustID) 
		+ '" ProductID="' + CONVERT(VARCHAR(20), @ProductID)
		+ '" MaxWinLimit="' + CONVERT(VARCHAR(20), @MaxWinLimit)
		+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
		+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
		+ '" />'
						
	SELECT @TrackingValue2 = '<NAP_WinLimit_CustSettingUpd '
		+ '" CustID ="' + CONVERT(VARCHAR(20), @CustID) 
		+ '" ProductID="' + CONVERT(VARCHAR(20), @ProductID)
		+ '" MaxWinLimit="' + CONVERT(VARCHAR(20), @MaxWinLimitOld)
		+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
		+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
		+ '" />'

	SELECT	@EndRun = GETDATE()
			,@Duration  = DATEDIFF(MILLISECOND,@StartRun,@EndRun)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID			= @UserID,
			@CustID			= @CustID,
			@ActionID		= 2907,
			@TrackingValue	= @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@Duration		= @Duration
	END TRY
	BEGIN CATCH
		SELECT @LogSPData = '<NAP_WinLimit_CurrencySettingUpd '
			+ '" CustID ="' + CONVERT(VARCHAR(20), @CustID) 
			+ '" ProductID="' + CONVERT(VARCHAR(20), @ProductID)
			+ '" MaxWinLimit="' + CONVERT(VARCHAR(20), @MaxWinLimit)
			+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
			+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
			+ '" ErrMsg="'+ COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(400)),SPACE(1)) 
			+ '" />'
		SELECT @TrackingValue2 = '<NAP_WinLimit_CurrencySettingUpd '
			+ '" CustID ="' + CONVERT(VARCHAR(20), @CustID) 
			+ '" ProductID="' + CONVERT(VARCHAR(20), @ProductID)
			+ '" MaxWinLimit="' + CONVERT(VARCHAR(20), @MaxWinLimitOld)
			+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
			+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
			+ '" ErrMsg="'+ COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(400)),SPACE(1)) 
			+ '" />'
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID			= @UserID,
			@CustID			= @CustID,
			@ActionID		= 2907,
			@TrackingValue	= @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@Duration		= @Duration
	END CATCH
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingUpd] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingUpd] TO [accteam]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustSettingUpd] TO [vnteam]
GO