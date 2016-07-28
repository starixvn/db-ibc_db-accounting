USE [bodb_ACC]
GO

ALTER PROCEDURE dbo.Acc_GroupExtraPTSetting_Upd
	@CustID			INT,
	@GroupName		VARCHAR(50),
	@EffectiveDate	DATETIME = NULL,
	@UserID			INT,
	@ErrCode		TINYINT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(1000) = '' OUTPUT
AS
/*
	Creator: Percy
	Date: 20160721
	Task: Change Primary, Remove CustID from Extra PT Group
	DB: DBACC.bodb_ACC

	Revisions:

	Param's Explanation:
		- @EffectiveDate
			+ IS NULL: remove @CustID from @GroupName
			+ NOT NULL: change @GroupName is Primary Extra PT Group of @CustID
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
	
	DECLARE @today DATETIME
	SELECT  @today = CONVERT(DATE, GETDATE())

	IF @EffectiveDate IS NOT NULL -- change @GroupName is Primary Extra PT Group of @CustID
	BEGIN
		IF @EffectiveDate < @today
			RETURN
		
		DECLARE @FromDate DATETIME
		SELECT  @FromDate = MIN(FromDate) FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE SuperId = @CustID AND GroupName = @GroupName AND @EffectiveDate BETWEEN FromDate AND ToDate AND FromDate <= CONVERT(DATE, GETDATE())

		IF @FromDate IS NOT NULL
		BEGIN
			IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE SuperId = @CustID AND FromDate > @today)
			BEGIN
				SELECT
					@ErrCode = 101,
					@ErrMsg = N'The group ' + @GroupName + N' has already been the primary group since ' + CONVERT(NVARCHAR(10), @FromDate, 101)
				RETURN
			END
		END
	
		-- Update old setting
		DECLARE @Curr_Primary TABLE (GroupName VARCHAR(50), IsDeleted BIT)
		INSERT INTO @Curr_Primary (GroupName, IsDeleted)
		SELECT DISTINCT
			GroupName,
			CASE WHEN FromDate > @today THEN 1 ELSE 0 END
		FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE SuperId = @CustID AND (@EffectiveDate BETWEEN FromDate AND ToDate OR FromDate > @EffectiveDate)

		IF NOT EXISTS (SELECT TOP 1 1 FROM @Curr_Primary WHERE IsDeleted = 0)
		BEGIN
			INSERT INTO @Curr_Primary (GroupName, IsDeleted)
			SELECT TOP 1 GroupName, 0
			FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
			WHERE ToDate < @EffectiveDate AND GroupName <> 'BC'
			ORDER BY ToDate DESC
		END
		
		IF @GroupName IN ('ACCTHAI2','ACCTHAI56','ACCTHAI99')
		BEGIN
			INSERT INTO @Curr_Primary (GroupName, IsDeleted)
			SELECT 'BC', IsDeleted FROM @Curr_Primary WHERE GroupName = @GroupName
		END
		
		IF EXISTS (SELECT TOP 1 1 FROM @Curr_Primary WHERE IsDeleted = 1)
		BEGIN
			DELETE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
			WHERE SuperId = @CustID AND GroupName IN (SELECT GroupName FROM @Curr_Primary WHERE IsDeleted = 1)
				AND FromDate > @today
		END

		IF NOT EXISTS (SELECT TOP 1 1 FROM @Curr_Primary WHERE IsDeleted = 0 AND GroupName = @GroupName)
		BEGIN
			UPDATE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
			SET ToDate = DATEADD(DAY, -1, @EffectiveDate)
			WHERE SuperId = @CustID AND GroupName IN (SELECT GroupName FROM @Curr_Primary WHERE IsDeleted = 0)
				AND @today BETWEEN FromDate AND ToDate

			IF @GroupName <> 'No Extra PT'
			BEGIN
				-- Insert new setting
				DECLARE @GroupID INT
				SELECT  @GroupID = GroupID FROM dbo.Acc_DWLList_ExtraPT WITH(NOLOCK) WHERE GroupName = @GroupName

				INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
				SELECT DISTINCT @CustID, @GroupID, @GroupName, ProductId, Sporttype, SubProduct, ExtraPT, @EffectiveDate, '99991231'
				FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE GroupName = @GroupName

				IF @GroupName IN ('ACCTHAI2','ACCTHAI56','ACCTHAI99')
				BEGIN
					INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
					SELECT DISTINCT @CustID, 18, 'BC', ProductId, Sporttype, SubProduct, ExtraPT, @EffectiveDate, '99991231'
					FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE GroupName = 'BC'
				END
			END
		END
		ELSE
		BEGIN
			UPDATE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
			SET ToDate = '99991231'
			WHERE SuperId = @CustID AND GroupName IN (SELECT GroupName FROM @Curr_Primary WHERE IsDeleted = 0)
				AND @today BETWEEN FromDate AND ToDate
		END
	END
	ELSE -- remove @CustID from @GroupName
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE SuperId = @CustID AND GroupName = @GroupName AND FromDate <= @today AND ToDate >= @today) -- Is Primary Extra PT Group
		BEGIN
			SELECT
				@ErrMsg = 	N'Please change the Extra PT group of the customer before removing him from the group.',
				@ErrCode = 103
			RETURN
		END

		IF EXISTS (SELECT TOP 1 1 FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE SuperId = @CustID AND GroupName = @GroupName AND FromDate > @today) -- To be Is Primary Extra PT Group
		BEGIN
			DELETE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
			WHERE SuperId = @CustID AND GroupName = @GroupName AND FromDate > @today

			IF @GroupName IN ('ACCTHAI2','ACCTHAI56','ACCTHAI99')
			BEGIN
				DELETE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
				WHERE SuperId = @CustID AND GroupName = 'BC' AND FromDate > @today
			END

			UPDATE dbo.Acc_GroupExtraPTSetting
			SET ToDate = '99991231'
			WHERE SuperId = @CustID AND @today BETWEEN FromDate AND ToDate

			IF EXISTS (SELECT TOP 1 1 FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE SuperId = @CustID AND @today BETWEEN FromDate AND ToDate AND GroupName IN ('ACCTHAI2','ACCTHAI56','ACCTHAI99'))
			BEGIN
				UPDATE dbo.Acc_GroupExtraPTSetting
				SET ToDate = '99991231'
				WHERE SuperId = @CustID AND GroupName = 'BC' AND @today BETWEEN FromDate AND ToDate
			END
		END
	END
END
GO

GRANT EXECUTE ON [dbo].[Acc_GroupExtraPTSetting_Upd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_GroupExtraPTSetting_Upd] TO [vnteam]
GO