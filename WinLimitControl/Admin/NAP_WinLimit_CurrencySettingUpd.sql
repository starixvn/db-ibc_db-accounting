USE [bodb02]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CurrencySettingUpd]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingUpd]
GO

USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CurrencySettingUpd]    Script Date: 07/07/2015 16:10:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingUpd]
	@ExchangeID		INT				= 0,
	@ProductID		TINYINT			= 0,
	@MaxWinLimit	MONEY,
	@UserID			INT				= 0,
	@IP				VARCHAR(20)		= '',
	@ErrCode		INT				= 0		OUTPUT,
	@ErrMsg			NVARCHAR(500)	= ''	OUTPUT
AS
	/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608 - Implement function to control Player's Win Limit on specific Product
		
		DB: DBTXN/bodb02
		
		Revisions:
		
		Parameters Explanation:	
			@ExchangeID		: Currency ID.
			@ProductID		: Product ID.
			@MaxWinLimit	: Max Win Limit amount.
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
	SELECT  @StartRun = GETDATE()
	IF @MaxWinLimit <=0
	BEGIN
		SET @MaxWinLimit = 0
	END
	IF NOT EXISTS (SELECT 1 FROM dbo.WinLimit_GlobalSetting WITH(NOLOCK) WHERE ExchangeID = @ExchangeID AND ProductID = @ProductID)
	BEGIN
		SELECT	@ErrCode = 2
				,@ErrMsg = 'This setting does not exist.'
		RETURN;
	END
	
	SELECT	@MaxWinLimitOld = MaxWinLimit
	FROM	dbo.WinLimit_GlobalSetting WITH (NOLOCK) 
	WHERE	ExchangeID = @ExchangeID 
			AND ProductID = @ProductID
	
	BEGIN TRY
		UPDATE	dbo.WinLimit_GlobalSetting WITH (UPDLOCK, ROWLOCK)
		SET		MaxWinLimit = @MaxWinLimit
		WHERE	ProductID = @ProductID
				AND ExchangeID = @ExchangeID
	END TRY
	BEGIN CATCH
		SELECT	@ErrCode = 2
				,@ErrMsg = ERROR_MESSAGE()
		RETURN;
	END CATCH
	
	-- Remove nested called due to no DBCUST link DB on DBPRO.
	-- Web will call this SP manually.
	-- Update all related Customer MaxWinLimit If new Global MaxWinLimit less than Customer MaxWinLimit.
	--EXEC DBCUST.CustDB.dbo.NAP_WinLimit_CustSettingRelatedToCurrencySettingUpd
	--	@ExchangeID	= @ExchangeID,
	--	@ProductID = @ProductID,
	--	@MaxWinLimit = @MaxWinLimit,
	--	@UserID	=@UserID,
	--	@IP	= @IP,
	--	@ErrCode = @ErrCode,
	--	@ErrMsg	=@ErrMsg
		
	SELECT	@EndRun = GETDATE()
			,@Duration = DATEDIFF(millisecond, @StartRun, @EndRun)
	
	DECLARE @LogSPData VARCHAR(300)
			,@TrackingValue2 VARCHAR(300)

	SELECT @LogSPData = '<NAP_WinLimit_CurrencySettingUpd '
		+ '" ExchangeID ="' + CONVERT(VARCHAR(20), @ExchangeID) 
		+ '" ProductID="' + CONVERT(VARCHAR(20), @ProductID)
		+ '" MaxWinLimit="' + CONVERT(VARCHAR(20), @MaxWinLimit)
		+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
		+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
		+ '" />'
						
	SELECT @TrackingValue2 = '<NAP_WinLimit_CurrencySettingUpd '
		+ '" ExchangeID ="' + CONVERT(VARCHAR(20), @ExchangeID) 
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
			@ActionID		= 31202,
			@TrackingValue	= @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@Duration		= @Duration
	END TRY
	BEGIN CATCH
		SELECT	@LogSPData = '<NAP_WinLimit_CurrencySettingUpd '
			+ '" ExchangeID ="' + CONVERT(VARCHAR(20), @ExchangeID) 
			+ '" ProductID="' + CONVERT(VARCHAR(20), @ProductID)
			+ '" MaxWinLimit="' + CONVERT(VARCHAR(20), @MaxWinLimit)
			+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
			+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
			+ '" ErrMsg="'+ COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(400)),SPACE(1)) 
			+ '" />'
		SELECT	@TrackingValue2 = '<NAP_WinLimit_CurrencySettingUpd '
			+ '" ExchangeID ="' + CONVERT(VARCHAR(20), @ExchangeID) 
			+ '" ProductID="' + CONVERT(VARCHAR(20), @ProductID)
			+ '" MaxWinLimit="' + CONVERT(VARCHAR(20), @MaxWinLimitOld)
			+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
			+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
			+ '" ErrMsg="'+ COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(400)),SPACE(1)) 
			+ '" />'
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID			= @UserID,
			@ActionID		= 31202,
			@TrackingValue	= @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@Duration		= @Duration
	END CATCH
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySettingUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CurrencySettingUpd] TO [vnteam]
GO