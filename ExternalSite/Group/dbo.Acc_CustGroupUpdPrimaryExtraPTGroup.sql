USE [bodb_Age]
GO

ALTER PROCEDURE [dbo].[Acc_CustGroupUpdPrimaryExtraPTGroup]
	@CustID			INT,
	@GroupName		VARCHAR(50),
	@EffectiveDate	DATETIME,
	@UserID			INT,
	@IP				VARCHAR(20),
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(1000) = '' OUTPUT
AS
/*
	Creator: Percy
	Date: 20160721
	Task: Change Primary ExtraPTGroup
	DB: DBAGE.bodb_Age

	Revisions:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT
	SELECT  @StartRun = GETDATE()

	IF @EffectiveDate IS NULL OR @EffectiveDate < CONVERT(DATE, GETDATE())
		RETURN

	-- Check permission for account site
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission
		@CustID = @UserID,
		@FuncName = '[Admin_ManageExAcc]',
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT,
		@System = 'ACCOUNTING'
	
	IF @ErrCode <> 0
		RETURN

	IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.Acc_CustGroup WITH(NOLOCK) WHERE CustID = @CustID)
	BEGIN
		SELECT
			@ErrCode = 101,
			@ErrMsg = N'This Customer does not exist'
		RETURN
	END

	IF @GroupName <> 'No Extra PT'
	BEGIN
		IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.Acc_CustGroup WITH(NOLOCK) WHERE CustID = @CustID AND GroupName = @GroupName)
		BEGIN
			SELECT
				@ErrCode = 102,
				@ErrMsg = N'This Customer does not belong to this group!'
			RETURN
		END
	END

	-- Update table Acc_GroupExtraPTSetting
	EXEC DBACC.bodb_ACC.dbo.Acc_GroupExtraPTSetting_Upd
		@CustID = @CustID,
		@GroupName = @GroupName,
		@EffectiveDate = @EffectiveDate,
		@UserID = @UserID,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- Write log
	DECLARE @LogData NVARCHAR(MAX)
	SELECT  @LogData = '<Acc_CustGroupUpdPrimaryExtraPTGroup CustID="' + CONVERT(NVARCHAR(20), @CustID)
						+ '" PrimaryGroup="' + @GroupName
						+ '" EffectiveDate="' + CONVERT(NVARCHAR(10), @EffectiveDate, 120)
						+ '" IP="' + @IP
						+ '" ErrCode="' + CONVERT(NVARCHAR(4), @ErrCode)
						+ '" ErrMsg="' + @ErrMsg + '" />'
	SELECT @EndRun = GETDATE()
	SELECT @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 662,
		@TrackingValue = @LogData,
		@Duration = @Duration
END
GO

GRANT EXECUTE ON [dbo].[Acc_CustGroupUpdPrimaryExtraPTGroup] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustGroupUpdPrimaryExtraPTGroup] TO [vnteam]
GO