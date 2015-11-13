USE [CustDB]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustSettingIns]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[NAP_WinLimit_CustSettingIns]
GO

USE [CustDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingIns]
	@CustSettingXML XML,
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
			@CustSettingXML	: Insert XML string.
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
			,@LogSPData VARCHAR(300)
			
	SELECT	@StartRun = GETDATE()
	DECLARE @TempCustSetting TABLE
	(
		CustID			INT
		,ProductID		TINYINT
		,MaxWinLimit	MONEY
	)
	
	INSERT INTO @TempCustSetting
	SELECT  
       Tbl.Col.value('@CustID', 'INT'),  
       Tbl.Col.value('@ProductID', 'TINYINT'),
       Tbl.Col.value('@MaxWinLimit', 'MONEY')
	FROM @CustSettingXML.nodes('//custsetting/row') Tbl(Col)
	
	IF ( @@ROWCOUNT = 0 )
	BEGIN
		SELECT 	@ErrCode	= 1
				,@ErrMsg 	= 'There is no information.'
		RETURN;
	END
	
	-- Validate Data
	DECLARE @TempSearchCurrencySetting TABLE
	(
		CustID				INT,
		ExchangeID			INT,
		ProductID			TINYINT,
		PlayerWinLimit		MONEY,
		CurrencyWinLimit	MONEY,
		IsValid				BIT
	)
	
	INSERT INTO @TempSearchCurrencySetting
	SELECT	tcs.CustID, wg.ExchangeID, wg.ProductID, tcs.MaxWinLimit PlayerWinLimit, wg.MaxWinLimit CurrencyWinLimit, CASE WHEN tcs.MaxWinLimit <= wg.MaxWinLimit THEN 1 ELSE 0 END IsValid
	FROM	@TempCustSetting tcs
			INNER JOIN dbo.Customer c WITH (NOLOCK)
			ON tcs.CustID = c.CustID
			INNER JOIN DBPRO.bodb02.dbo.WinLimit_GlobalSetting wg WITH (NOLOCK)
			ON c.currency = wg.ExchangeID AND tcs.ProductID = wg.ProductID
			
	IF EXISTS (SELECT 1 FROM @TempSearchCurrencySetting WHERE IsValid = 0)
	BEGIN
		DECLARE @ValidPlayers	VARCHAR(1000),
				@InvalidPlayers	VARCHAR(1000)
				  
		SELECT	@ValidPlayers = COALESCE(@ValidPlayers + ',', '') + CONVERT(VARCHAR(100), ProductID) FROM @TempSearchCurrencySetting
		WHERE	IsValid = 1
		
		SELECT	@InvalidPlayers = COALESCE(@InvalidPlayers + ',', '') + CONVERT(VARCHAR(100), ProductID) FROM @TempSearchCurrencySetting
		WHERE	IsValid = 0
		
		SELECT	@ErrCode	= 2,
				@ErrMsg		= 'Invalid data because it has changed by some other people. Please refresh the page.'--ISNULL(@ValidPlayers, '') + ';' + ISNULL(@InvalidPlayers, '')
				
	END
	
	INSERT INTO dbo.WinLimit_CustSetting
	SELECT	CustID,
			ProductID,
			PlayerWinLimit
	FROM	@TempSearchCurrencySetting
	WHERE	IsValid = 1
	
	SELECT	@EndRun = GETDATE()
			,@Duration = DATEDIFF(millisecond, @StartRun, @EndRun)
			
	SELECT	@LogSPData = '<NAP_WinLimit_CustSettingIns '
		+ '" CustSettingXML ="' + CONVERT(VARCHAR(MAX), @CustSettingXML) 
		+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
		+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
		+ '" />'
		
	BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID			= @UserID,
		@CustID			= @UserID,
		@ActionID		= 2906,
		@TrackingValue	= @LogSPData,
		@Duration		= @Duration
	END TRY
	BEGIN CATCH
	SELECT @LogSPData = '<NAP_WinLimit_CustSettingIns '
		+ '" CustSettingXML ="' + CONVERT(VARCHAR(MAX), @CustSettingXML) 
		+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
		+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
		+ '" ErrMsg="'+ COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(400)),SPACE(1)) 
		+ '" />'
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID			= @UserID,
		@CustID			= @UserID,
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
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustSettingIns] TO [vnteam]
GO