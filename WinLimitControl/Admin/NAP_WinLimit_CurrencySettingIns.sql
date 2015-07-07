USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CurrencySettingIns]    Script Date: 07/07/2015 16:10:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingIns]
	@ExchangeID		INT = 0,
	@ProductID		INT = 0,
	@MaxWinLimit	MONEY,
	@UserID			INT = 0,
	@IP				VARCHAR(20) = '',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608
		DB: DBCust/CustDB
		
		Revisions:
		
		Parameters Explanation:	
			@ExchangeID: Currency ID.
			@ProductID: Product ID.
			@MaxWinLimit: Max Win Limit amount.
			@UserID: User making this action.
			@IP: IP of the machine making this action.
			@ErrCode: Error Code.
			@ErrMsg: Error Message.
	*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @StartRun DATETIME
	DECLARE @EndRun DATETIME
	DECLARE @Duration INT
	SET @StartRun = GETDATE()
	IF @MaxWinLimit <=0
	BEGIN
		SET @MaxWinLimit = 1000
	END
	
	IF @ExchangeID = 0 OR @ProductID = 0
	BEGIN
		SELECT @ErrCode = 5
		SELECT @ErrMsg = 'Invalid input. ExchangeID = 0 or ProductID = 0.'
		RETURN;
	END
	
	BEGIN TRY
	INSERT INTO dbo.WinLimit_GlobalSetting 
	(
		ProductID,
		ExchangeID,
		MaxWinLimit
	)
	VALUES
	(
		@ProductID,
		@ExchangeID,
		@MaxWinLimit
	)
	END TRY
	BEGIN CATCH
	IF @@ERROR <> 0 
	BEGIN
		SELECT @ErrCode = 1
		SELECT @ErrMsg = 'This setting is already set.'
	END
	END CATCH;
	
	SET @EndRun = GETDATE()
	SET @Duration = DATEDIFF(millisecond, @StartRun, @EndRun)
	
	DECLARE @LogSPData VARCHAR(300)

	SELECT @LogSPData = '<NAP_WinLimit_CurrencySettingIns '
		+ '" ExchangeID ="' + CONVERT(VARCHAR(20), @ExchangeID) 
		+ '" ProductID="' + CONVERT(VARCHAR(20), @ProductID)
		+ '" MaxWinLimit="' + CONVERT(VARCHAR(20), @MaxWinLimit)
		+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
		+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
		+ '" />'
		
	BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@ActionID = 2904,
		@TrackingValue = @LogSPData	,
		@Duration = @Duration
	END TRY
	BEGIN CATCH
	SELECT @LogSPData = '<NAP_WinLimit_CurrencySettingIns '
		+ '" ExchangeID ="' + CONVERT(VARCHAR(20), @ExchangeID) 
		+ '" ProductID="' + CONVERT(VARCHAR(20), @ProductID)
		+ '" MaxWinLimit="' + CONVERT(VARCHAR(20), @MaxWinLimit)
		+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
		+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
		+ '" ErrMsg="'+ COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(400)),SPACE(1)) 
		+ '" />'
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@ActionID = 2904,
		@TrackingValue = @LogSPData	,
		@Duration = @Duration
	END CATCH

END
GO

