USE [bodb_ACC]
GO

ALTER PROCEDURE dbo.Acc_GroupExtraPTSetting_Ins
	@CustID		INT,
	@GroupName	VARCHAR(50),
	@ErrCode	TINYINT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(1000) = '' OUTPUT,
	@UserID		INT
AS
/*
	Creator: Percy
	Date: 20160721
	Task: Insert new custid into table GroupExtraPTSetting
	DB: DBACC.bodb_ACC

	Revisions:

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	-- Check permission for account site
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission
		@CustID = @UserID,
		@FuncName = '[Admin_ManageExAcc]',
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT,
		@System = 'ACCOUNTING'
	
	IF @ErrCode <> 0
		RETURN

	DECLARE @Username VARCHAR(30), @RoleID INT
	SELECT  @Username = username FROM bodb02.dbo.Customer WITH(NOLOCK) WHERE custid = @CustID

	IF ISNULL(@Username, '') = ''
	BEGIN
		SELECT
			@ErrCode = 101,
			@ErrMsg = N'This username is invalid!'	
		RETURN
	END
	
	IF ISNULL(@RoleID, 0) <> 4
	BEGIN
		SELECT
			@ErrCode = 102,
			@ErrMsg = N'The role of this username is not super, please check again !'	
		RETURN
	END

	DECLARE @MaxToDate DATETIME
	SELECT  @MaxToDate = MAX(ToDate) FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE GroupName = @GroupName

	IF @MaxToDate IS NULL OR @MaxToDate < CONVERT(DATE, GETDATE())
	BEGIN
		SELECT
			@ErrCode = 106,
			@ErrMsg = 'Please select the Extra PT effective date for the customer ' + @Username + '.'
		RETURN
	END
	
	INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
	SELECT DISTINCT @CustID, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate
	FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE GroupName = @GroupName AND ToDate = @MaxToDate

	-- BC group
	IF (@GroupName IN ('ACCTHAI2','ACCTHAI56','ACCTHAI99'))
	BEGIN
		INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
		SELECT DISTINCT @CustID, 18, 'BC', ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate
		FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE GroupName = 'BC' AND ToDate = @MaxToDate
	END
END
GO

GRANT EXECUTE ON [dbo].[Acc_GroupExtraPTSetting_Ins] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_GroupExtraPTSetting_Ins] TO [vnteam]
GO