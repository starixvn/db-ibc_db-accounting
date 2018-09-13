/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_GroupExtraPT_GroupByProduct_Del]
	@UserId				INT,
	@GroupId			TINYINT,
	@ProductId			TINYINT,
	@ExtraPT			DECIMAL(9,8),
	@EffectiveDate		DATETIME,
	@EndDate			DATETIME = NULL,

	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				NVARCHAR(200) = '' OUTPUT
AS

/*
	Created by: Percy
	Date: 2017-04-13
	DB: DBCUST.CustDB
	Task: Manage Extra PT Group - Delete setting [RedmineID: #74292]

	Revisions:
		- 20170926@Percy: Move this SP from DBACC.bodb_ACC to DBCUST.CustDB [RedmineID: #83600]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @LogData NVARCHAR(MAX)

	-- Check valid --
	IF @EffectiveDate <= CONVERT(DATE, GETDATE())
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Can not remove this setting.'
		
		RETURN
	END

	-- Check permission --
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission
		@CustID = @UserID,
		@FuncName = '[ManageExtraPTGroup]',
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT,
		@System = 'ACCOUNTING'
	
	IF @ErrCode <> 0
		RETURN

	DECLARE @startRun DATETIME, @duration INT
	SELECT  @startRun = GETDATE()

	DECLARE @GroupName VARCHAR(30), @ProductName VARCHAR(30)
	SELECT  @GroupName = GroupName FROM DBACC.bodb_ACC.dbo.Acc_DWLList_ExtraPT WITH(NOLOCK) WHERE GroupId = @GroupId
	SELECT  @ProductName = ProductName FROM DBTXN.bodb02.dbo.Products WITH(NOLOCK) WHERE ProductID = @ProductID

	IF ISNULL(@GroupName, '') = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Extra PT Group.'
		
		RETURN
	END

	IF ISNULL(@ProductName, '') = ''
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Invalid Product.'
		
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM DBACC.bodb_ACC.dbo.Acc_DWLList WITH(NOLOCK) WHERE ProductId = @ProductId)
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'This product is not offers.'
		
		RETURN
	END

	SELECT  @EndDate = ISNULL(@EndDate, '9999-12-31')
	SELECT  @EffectiveDate = CONVERT(DATE, @EffectiveDate), @EndDate = CONVERT(DATE, @EndDate)

	-- Check exists
	IF NOT EXISTS (
		SELECT TOP 1 1 FROM dbo.Acc_GroupExtraPT_Product WITH(NOLOCK)
		WHERE GroupId = @GroupId
			AND ProductID = @ProductID
			AND ExtraPT = @ExtraPT
			AND FromDate = @EffectiveDate
			AND ToDate = @EndDate
	)
	BEGIN
		SELECT @ErrCode = 104, @ErrMsg = 'This setting is not exists.'
		
		RETURN
	END
	ELSE
	BEGIN
		/* Group */
		BEGIN TRY
		DELETE dbo.Acc_GroupExtraPT_Product WITH(ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId
			AND ProductID = @ProductID
			AND FromDate = @EffectiveDate
			AND ToDate = @EndDate
		END TRY
		BEGIN CATCH
			SELECT @ErrCode = 105, @ErrMsg = 'Remove setting failed.'
		
			RETURN
		END CATCH

		/* Super */
		DELETE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND ProductID = @ProductID
			AND FromDate >= @EffectiveDate
			AND ToDate <= @EndDate
	END

	
	SELECT  @LogData = '<Acc_GroupExtraPT_GroupByProduct_Del UserID="' + CONVERT(VARCHAR(20), @UserID)
						+ '" Group="'   + CONVERT(VARCHAR(50), @GroupName)
						+ '" Product="' + CONVERT(VARCHAR(50), @ProductName)
						+ '" ExtraPT="' + CONVERT(VARCHAR(50), @ExtraPT)
						+ '" FromDate="' + CONVERT(VARCHAR(50), @EffectiveDate)
						+ '" ToDate="' + CONVERT(VARCHAR(50), @EndDate)
						+ '" />'

	SELECT	@duration = DATEDIFF(MILLISECOND, @startRun, GETDATE())

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @UserID,
		@ActionID = 675,
		@TrackingValue = @LogData,
		@duration = @duration
END
GO
