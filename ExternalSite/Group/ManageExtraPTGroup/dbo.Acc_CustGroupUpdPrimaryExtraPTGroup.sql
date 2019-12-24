/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
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
	DB: DBCUST-CUSTDB

	Revisions:
		- 20170926@Percy: Move the nested SP: Acc_GroupExtraPTSetting_Upd from DBACC.bodb_ACC to DBCUST.CustDB [RedmineID: #83600]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20181123@Helen: DB053.bodb_AGE/BODB02 & DB052.bodb_Summary Migration [Redmine: 104770]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT
	SELECT  @StartRun = GETDATE()

	IF @EffectiveDate IS NULL OR @EffectiveDate < CONVERT(DATE, GETDATE())
		RETURN

	-- Check permission for account site
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission
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
	EXEC dbo.Acc_GroupExtraPTSetting_Upd
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

	EXEC Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 662,
		@TrackingValue = @LogData,
		@Duration = @Duration
END
GO