/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_GroupExtraPTSetting_Upd]
	@CustID			INT,
	@GroupName		VARCHAR(50),
	@EffectiveDate	DATETIME = NULL,
	@UserID			INT,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(1000) = '' OUTPUT
AS

/*
	Creator: Percy
	Date: 20160721
	Task: Change Primary, Remove CustID from Extra PT Group
	DB: DBCUST.CustDB

	Revisions:
		- 20170413@Percy: Get setting of group from new table [RedmineID: #74292]
		- 20170926@Percy: Migrate this SP from DBACC.bodb_ACC to DBCUST.CustDB [RedmineID: #83600]
		- 20180808@Helen: DB05.DBPOLICY migration - [Redmine:99462]
		- 20191211@Percy: Add UplineId (HeadlineId) [RedmineID: #118962]
		
	Param's Explanation:
		- @EffectiveDate
			+ IS NULL: remove @CustID from @GroupName
			+ NOT NULL: change @GroupName is Primary Extra PT Group of @CustID
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission for account site
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission
		@CustID = @UserID,
		@FuncName = '[Admin_ManageExAcc]',
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT,
		@System = 'ACCOUNTING'

	IF @ErrCode <> 0
		RETURN
	
	DECLARE @today DATETIME, @EndDate DATETIME
	SELECT  @today = CONVERT(DATE, GETDATE()), @EndDate = '9999-12-31'

	DECLARE @GroupId INT
	SELECT TOP 1 @GroupId = GroupId FROM dbo.Acc_GroupExtraPT_Product WITH(NOLOCK) WHERE GroupName = @GroupName

	DECLARE @Setting TABLE (GroupId INT, FromDate DATETIME)

	IF @EffectiveDate IS NOT NULL -- change @GroupName is Primary Extra PT Group of @CustID
	BEGIN
		IF @EffectiveDate < @today
			RETURN
		
		DECLARE @FromDate DATETIME

		IF @GroupName = 'No Extra PT'
		BEGIN
			IF NOT EXISTS (
				SELECT TOP 1 1 FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
				WHERE SuperId = @CustID AND GroupId <> 0
					AND (FromDate > @today OR @today BETWEEN FromDate AND ToDate)
			)
			BEGIN
				SELECT
					@ErrCode = 102,
					@ErrMsg = N'Please select a primary group.'
				RETURN
			END
		END
		ELSE
		BEGIN
			SELECT  @FromDate = MIN(FromDate) FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
			WHERE SuperId = @CustID AND GroupId = @GroupId AND @EffectiveDate BETWEEN FromDate AND ToDate AND FromDate <= @today
			
			IF @FromDate IS NOT NULL
			BEGIN
				IF NOT EXISTS (
					SELECT TOP 1 1 FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
					WHERE SuperId = @CustID AND GroupId <> @GroupId AND FromDate > @today
				)
				BEGIN
					SELECT
						@ErrCode = 101,
						@ErrMsg = N'The group ' + @GroupName + N' has already been the primary group since ' + CONVERT(NVARCHAR(10), @FromDate, 101)
					RETURN
				END
			END
		END

		DELETE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
		WHERE SuperId = @CustID AND FromDate >= @EffectiveDate
			AND ToDate >= @today

		UPDATE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
		SET ToDate = DATEADD(DAY, -1, @EffectiveDate)
		WHERE SuperId = @CustID AND FromDate < @EffectiveDate
			AND ToDate >= @today

		DECLARE @UplineId INT
		SELECT  TOP 1 @UplineId = UplineId
		FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
		WHERE SuperId = @CustID AND ToDate = DATEADD(DAY, -1, @EffectiveDate)

		IF @GroupName = 'No Extra PT'
		BEGIN
			INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate, UplineId)
			VALUES (@CustId, 0, '', 0, 0, '', 0, @EffectiveDate, '9999-12-31', @UplineId)
		END
		ELSE
		BEGIN
			INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate, UplineId)
			SELECT @CustId, @GroupId, @GroupName, ProductID, Sporttype, SubProduct, ExtraPT,
				CASE WHEN @EffectiveDate < FromDate THEN FromDate ELSE @EffectiveDate END AS FromDate,
				CASE WHEN @EndDate < ToDate THEN @EndDate ELSE ToDate END AS ToDate,
				@UplineId
			FROM dbo.Acc_GroupExtraPT_Product WITH(NOLOCK)
			WHERE GroupId = @GroupId
				AND @EffectiveDate <= ToDate
		
			IF @GroupName IN ('ACCTHAI2','ACCTHAI56','ACCTHAI99')
			BEGIN
				INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate, UplineId)
				SELECT @CustId, GroupId, GroupName, ProductID, Sporttype, SubProduct, ExtraPT,
					CASE WHEN @EffectiveDate < FromDate THEN FromDate ELSE @EffectiveDate END AS FromDate,
					CASE WHEN @EndDate < ToDate THEN @EndDate ELSE ToDate END AS ToDate,
					@UplineId
				FROM dbo.Acc_GroupExtraPT_Product WITH(NOLOCK)
				WHERE GroupName = 'BC'
					AND @EffectiveDate <= ToDate
			END
		END
	END
	ELSE -- remove @CustID from @GroupName
	BEGIN
		IF EXISTS (
			SELECT TOP 1 1 FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
			WHERE SuperId = @CustID AND GroupId = @GroupId AND @today BETWEEN FromDate AND ToDate
		) -- Is Primary Extra PT Group
		BEGIN
			SELECT
				@ErrMsg = 	N'Please change the Extra PT group of the customer before removing him from the group.',
				@ErrCode = 103
			RETURN
		END

		IF EXISTS (
			SELECT TOP 1 1 FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
			WHERE SuperId = @CustID AND GroupId = @GroupId AND FromDate > @today
		) -- To be Is Primary Extra PT Group
		BEGIN
			DELETE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
			WHERE SuperId = @CustID AND GroupId = @GroupId AND FromDate > @today

			IF @GroupName IN ('ACCTHAI2','ACCTHAI56','ACCTHAI99')
			BEGIN
				DELETE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
				WHERE SuperId = @CustID AND GroupName = 'BC' AND FromDate > @today
			END

			IF EXISTS (
				SELECT TOP 1 1 FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
				WHERE SuperId = @CustID AND @today BETWEEN FromDate AND ToDate
			)
			BEGIN
				DELETE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
				OUTPUT DELETED.GroupId, DELETED.FromDate
					INTO @Setting (GroupId, FromDate)
				WHERE SuperId = @CustID AND ToDate > @today

				INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate, UplineId)
				SELECT @CustId, g.GroupId, g.GroupName, g.ProductID, g.Sporttype, g.SubProduct, g.ExtraPT,
					CASE WHEN s.FromDate < @today THEN s.FromDate ELSE g.FromDate END AS FromDate, g.ToDate,
					@UplineId
				FROM dbo.Acc_GroupExtraPT_Product g WITH(NOLOCK)
					INNER JOIN @Setting s ON g.GroupId = s.GroupId
				WHERE @today >= g.ToDate
			END
		END
	END
END
GO