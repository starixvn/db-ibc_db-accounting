/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_GroupExtraPT_GroupByProduct_Upd]
	@UserId				INT,
	@GroupId			TINYINT,
	@ProductId			TINYINT,
	@OldExtraPT			DECIMAL(9,8),
	@NewExtraPT			DECIMAL(9,8),
	@OldEffectiveDate	DATETIME,
	@NewEffectiveDate	DATETIME,
	@OldEndDate			DATETIME = NULL,
	@NewEndDate			DATETIME = NULL,

	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				NVARCHAR(200) = '' OUTPUT
AS

/*
	Created by: Percy
	Date: 2017-04-13
	DB: DBCUST.CustDB
	Task: Manage Extra PT Group - Update [RedmineID: #74292]

	Revisions:
		- 20170926@Percy: Move this SP from DBACC.bodb_ACC to DBCUST.CustDB [RedmineID: #83600]
		- 20180808@Helen: DB05.DBPOLICY migration - [Redmine:99462]
		- 20190214@Percy: Fix issue setting of supers is not updated when change extra PT amount [RedmineID: #108875]
		- 20191211@Percy: Remove Bettrade [RedmineID: #118962]
		
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	SELECT  @NewEndDate = ISNULL(@NewEndDate, '9999-12-31'), @OldEndDate = ISNULL(@OldEndDate, '9999-12-31')
	SELECT  @NewEffectiveDate = CONVERT(DATE, @NewEffectiveDate), @NewEndDate = CONVERT(DATE, @NewEndDate)
	SELECT  @OldEffectiveDate = CONVERT(DATE, @OldEffectiveDate), @OldEndDate = CONVERT(DATE, @OldEndDate)

	-- Check valid --
	IF @OldExtraPT = @NewExtraPT AND @OldEffectiveDate = @NewEffectiveDate AND @OldEndDate = @NewEndDate
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Nothing change.'
		
		RETURN
	END

	IF (@OldEffectiveDate <> @NewEffectiveDate OR @OldExtraPT <> @NewExtraPT) AND @NewEffectiveDate < CONVERT(DATE, GETDATE())
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Please select Effective Date from current date.'
		
		RETURN
	END

	IF @NewEndDate < @NewEffectiveDate
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Effective Date is greater than End Date.'
		
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

	DECLARE @GroupName VARCHAR(30), @ProductName VARCHAR(30), @today DATETIME
	SELECT  @GroupName = GroupName FROM DBACC.bodb_ACC.dbo.Acc_DWLList_ExtraPT WITH(NOLOCK) WHERE GroupId = @GroupId
	SELECT  @ProductName = ProductName FROM DBTXN.bodb02.dbo.Products WITH(NOLOCK) WHERE ProductID = @ProductID
	SELECT  @today = CONVERT(DATE, GETDATE())

	IF ISNULL(@GroupName, '') = ''
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'Invalid Extra PT Group.'
		
		RETURN
	END

	IF ISNULL(@ProductName, '') = ''
	BEGIN
		SELECT @ErrCode = 104, @ErrMsg = 'Invalid Product.'
		
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM DBACC.bodb_ACC.dbo.Acc_DWLList WITH(NOLOCK) WHERE ProductId = @ProductId)
	BEGIN
		SELECT @ErrCode = 105, @ErrMsg = 'This product is not offers'
		
		RETURN
	END

	-- Check exists
	IF NOT EXISTS (
		SELECT TOP 1 1
		FROM dbo.Acc_GroupExtraPT_Product WITH(NOLOCK)
		WHERE GroupId = @GroupId AND ProductID = @ProductID
			AND FromDate = @OldEffectiveDate AND ToDate = @OldEndDate AND ExtraPT = @OldExtraPT
	)
	BEGIN
		SELECT @ErrCode = 106, @ErrMsg = 'The current setting is not exists.'
		
		RETURN
	END
	ELSE
	BEGIN
		-- Check conflicts
		IF EXISTS (
			SELECT TOP 1 1
			FROM dbo.Acc_GroupExtraPT_Product WITH(NOLOCK)
			WHERE GroupId = @GroupId AND ProductID = @ProductID AND (FromDate <> @OldEffectiveDate OR ToDate <> @OldEndDate)
				AND (
					(ToDate < @OldEffectiveDate AND ToDate >= @NewEffectiveDate)
					OR (FromDate > @OldEndDate AND FromDate <= @NewEndDate)
				)
		)
		BEGIN
			SELECT @ErrCode = 107, @ErrMsg = 'The Effective Period of the new setting conflicts with a current setting.'
		
			RETURN
		END
		ELSE
		BEGIN
			/* Group */
			BEGIN TRY
				UPDATE dbo.Acc_GroupExtraPT_Product WITH (ROWLOCK, UPDLOCK)
				SET FromDate = @NewEffectiveDate, ToDate = @NewEndDate,
					ExtraPT = @NewExtraPT
				WHERE GroupId = @GroupId AND ProductID = @ProductID
					AND ToDate = @OldEndDate
			END TRY
			BEGIN CATCH
				SELECT @ErrCode = 108, @ErrMsg = ERROR_MESSAGE()

				RETURN
			END CATCH

			/* Super */
			IF @NewEffectiveDate = @OldEffectiveDate AND @NewExtraPT = @OldExtraPT -- update ToDate only
			BEGIN
				IF @NewEndDate < @OldEndDate
				BEGIN
					;WITH Super AS (
						SELECT SuperId, GroupId, ProductId, Sporttype, SubProduct, FromDate
						FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
						WHERE GroupId = @GroupId AND ProductID = @ProductID
							AND ToDate BETWEEN @NewEndDate AND @OldEndDate
					)
					MERGE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK) AS g
					USING Super AS s
						ON g.SuperId = s.SuperId AND g.GroupId = s.GroupId
							AND g.ProductId = s.ProductId AND g.Sporttype = s.Sporttype AND g.SubProduct = s.SubProduct
							AND g.FromDate = s.FromDate
					WHEN MATCHED AND g.FromDate <= @NewEndDate THEN UPDATE SET g.ToDate = @NewEndDate
					WHEN MATCHED THEN DELETE;
				END
				ELSE
				BEGIN
					;WITH Super AS (
						SELECT SuperId, MIN(FromDate) AS FromDate
						FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
						WHERE GroupId <> @GroupId
							AND FromDate BETWEEN @OldEndDate AND @NewEndDate
						GROUP BY SuperId
					)
					UPDATE g WITH(ROWLOCK, UPDLOCK)
					SET g.ToDate = CASE WHEN s.FromDate IS NULL OR @NewEndDate < ISNULL(s.FromDate, '9999-12-31') THEN @NewEndDate ELSE DATEADD(DAY, -1, ISNULL(s.FromDate, '9999-12-31')) END
					FROM dbo.Acc_GroupExtraPTSetting AS g
						LEFT JOIN Super s ON g.SuperId = s.SuperId
					WHERE GroupId = @GroupId AND ProductId = @ProductId
						AND g.ToDate = @OldEndDate
				END
			END
			ELSE
			BEGIN
				IF @OldExtraPT <> @NewExtraPT
				BEGIN
					UPDATE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
					SET ExtraPT = @NewExtraPT
					WHERE GroupId = @GroupId AND ProductId = @ProductId
						AND FromDate >= @OldEffectiveDate AND ToDate <= @OldEndDate
				END

				IF @OldEffectiveDate > @NewEffectiveDate
				BEGIN
					;WITH Super AS (
						SELECT SuperId, MAX(ToDate) AS ToDate
						FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
						WHERE GroupId <> @GroupId
							AND ToDate BETWEEN @NewEffectiveDate AND @OldEffectiveDate
						GROUP BY SuperId
					)
					UPDATE g WITH(ROWLOCK, UPDLOCK)
					SET g.FromDate = CASE WHEN @NewEffectiveDate > ISNULL(s.ToDate, '1970-01-01') THEN @NewEffectiveDate ELSE DATEADD(DAY, 1, ISNULL(s.ToDate, '1970-01-01')) END
					FROM dbo.Acc_GroupExtraPTSetting AS g
						LEFT JOIN Super s ON g.SuperId = s.SuperId
					WHERE GroupId = @GroupId AND ProductId = @ProductId
						AND g.FromDate = @OldEffectiveDate  
				END

				IF @OldEffectiveDate < @NewEffectiveDate
				BEGIN
					DELETE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
					WHERE GroupId = @GroupId AND ProductId = @ProductId
						AND FromDate >= @OldEffectiveDate AND ToDate < @NewEffectiveDate  
					
					UPDATE Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
					SET FromDate = @NewEffectiveDate
					WHERE GroupId = @GroupId AND ProductId = @ProductId
						AND FromDate BETWEEN @OldEffectiveDate AND @NewEffectiveDate
				END

				IF @OldEndDate < @NewEndDate
				BEGIN
					;WITH Super AS (
						SELECT SuperId, MIN(FromDate) AS FromDate
						FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
						WHERE GroupId <> @GroupId
							AND FromDate BETWEEN @OldEndDate AND @NewEndDate
						GROUP BY SuperId
					)
					UPDATE g WITH(ROWLOCK, UPDLOCK)
					SET g.ToDate = CASE WHEN @NewEndDate < ISNULL(s.FromDate, '9999-12-31') THEN @NewEndDate ELSE DATEADD(DAY, -1, ISNULL(s.FromDate, '9999-12-31')) END
					FROM dbo.Acc_GroupExtraPTSetting AS g
						LEFT JOIN Super s ON g.SuperId = s.SuperId
					WHERE GroupId = @GroupId AND ProductId = @ProductId
						AND g.ToDate = @OldEndDate  
				END

				IF @OldEndDate > @NewEndDate
				BEGIN
					DELETE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
					WHERE GroupId = @GroupId AND ProductId = @ProductId
						AND FromDate > @NewEndDate AND ToDate <= @OldEndDate  
					
					UPDATE Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
					SET ToDate = @NewEndDate
					WHERE GroupId = @GroupId AND ProductId = @ProductId
						AND ToDate BETWEEN @NewEndDate AND @OldEndDate
				END
			END
		END
	END

	-- write log
	DECLARE @LogData NVARCHAR(MAX)
	SELECT  @LogData = '<Acc_GroupExtraPT_GroupByProduct_Upd UserID="' + CONVERT(VARCHAR(20), @UserID)
						+ '" Group="'			+ CONVERT(VARCHAR(50), @GroupName)
						+ '" Product="'			+ CONVERT(VARCHAR(50), @ProductName)
						+ '" OldExtraPT="'		+ CONVERT(VARCHAR(50), @OldExtraPT)
						+ '" OldEffectiveDate="'+ CONVERT(VARCHAR(50), @OldEffectiveDate)
						+ '" OldEndDate="'		+ CONVERT(VARCHAR(50), @OldEndDate)
						+ '" NewExtraPT="'		+ CONVERT(VARCHAR(50), @NewExtraPT)
						+ '" NewEffectiveDate="'+ CONVERT(VARCHAR(50), @NewEffectiveDate)
						+ '" NewEndDate="'		+ CONVERT(VARCHAR(50), @NewEndDate)
						+ '" />'

	SELECT	@duration = DATEDIFF(MILLISECOND, @startRun, GETDATE())

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @UserID,
		@ActionID = 674,
		@TrackingValue = @LogData,
		@duration = @duration
END
GO