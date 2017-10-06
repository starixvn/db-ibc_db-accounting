/*<info serverAlias="DBACC-bodb_ACC" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

USE [bodb_ACC]
GO

ALTER PROCEDURE [dbo].[Acc_GroupExtraPT_GroupByProduct_Ins]
	@UserId			INT,
	@GroupId		TINYINT,
	@ProductId		TINYINT,
	@ExtraPT		DECIMAL(9,8),
	@EffectiveDate	DATETIME,
	@EndDate		DATETIME = NULL,

	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(200) = '' OUTPUT
AS

/*
	Created by: Percy
	Date: 2017-04-13
	DB: DBACC.bodb_ACC
	Task: Manage Extra PT Group - Insert [RedmineID: #74292]

	Revisions:

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission --
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission
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
	SELECT  @GroupName = GroupName FROM dbo.Acc_DWLList_ExtraPT WITH(NOLOCK) WHERE GroupId = @GroupId
	SELECT  @ProductName = ProductName FROM bodb02.dbo.Products WITH(NOLOCK) WHERE ProductID = @ProductID
	SELECT  @today = CONVERT(DATE, GETDATE())

	IF ISNULL(@GroupName, '') = ''
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Invalid Extra PT Group.'
		
		RETURN
	END

	IF ISNULL(@ProductName, '') = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Product.'
		
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.Acc_DWLList WITH(NOLOCK) WHERE ProductId = @ProductId)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This product is not offers'
		
		RETURN
	END

	SELECT  @EndDate = ISNULL(@EndDate, '9999-12-31')
	SELECT  @EffectiveDate = CONVERT(DATE, @EffectiveDate), @EndDate = CONVERT(DATE, @EndDate)

	-- Check valid --
	IF @EffectiveDate < @today
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Please select Effective Date from current date.'
		
		RETURN
	END

	IF @EndDate < @EffectiveDate
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Effective Date is greater than End Date.'
		
		RETURN
	END

	-- Check exists
	IF EXISTS (
		SELECT TOP 1 1
		FROM dbo.Acc_GroupExtraPT_Product WITH(NOLOCK)
		WHERE GroupId = @GroupId AND ProductID = @ProductID
			AND FromDate > @today
	)
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'You are not allowed to create more than one extra PT plan (Effective Date > Today).'
		
		RETURN
	END

	DECLARE @OldEffectiveDate DATETIME, @OldEndDate DATETIME, @OldExtraPT DECIMAL(9,8)
	DECLARE @isNew BIT = 0
	
	SELECT TOP 1 @OldEffectiveDate = FromDate, @OldEndDate = ToDate, @OldExtraPT = ExtraPT
	FROM dbo.Acc_GroupExtraPT_Product WITH(NOLOCK)
	WHERE GroupId = @GroupId AND ProductID = @ProductID
		AND ToDate >= @EffectiveDate
	ORDER BY ToDate DESC, FromDate ASC

	IF @OldEffectiveDate IS NOT NULL
	BEGIN
		IF @EffectiveDate <= @OldEndDate -- conflicts
		BEGIN
			IF @OldEndDate < '9999-12-31' OR DATEADD(DAY, -1, @EffectiveDate) < @OldEffectiveDate
			BEGIN
				SELECT @ErrCode = 104, @ErrMsg = 'The Effective Period of the new setting conflicts with a current setting.'
		
				RETURN
			END
		END
		ELSE IF @ExtraPT = @OldExtraPT AND @OldEndDate = '9999-12-31'
		BEGIN
			SELECT @ErrCode = 105, @ErrMsg = 'The Extra PT of the new setting the same as current setting.'
		
			RETURN
		END
	END
	ELSE
	BEGIN
		SELECT @isNew = 1
	END

	/* Group */
	-- update old group setting --
	IF @isNew = 0
	BEGIN
		BEGIN TRY
			UPDATE dbo.Acc_GroupExtraPT_Product WITH (ROWLOCK, UPDLOCK)
			SET ToDate = DATEADD(DAY, -1, @EffectiveDate)
			WHERE GroupId = @GroupId AND ProductID = @ProductID AND ToDate = @OldEndDate

			DELETE dbo.Acc_GroupExtraPT_Product WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @GroupId AND ProductID = @ProductID AND ToDate < FromDate
		END TRY
		BEGIN CATCH
			SELECT @ErrCode = 106, @ErrMsg = ERROR_MESSAGE()

			RETURN
		END CATCH
	END

	-- insert new group setting --
	BEGIN TRY
		INSERT INTO dbo.Acc_GroupExtraPT_Product (GroupId, GroupName, ProductID, Sporttype, SubProduct, FromDate, ToDate, ExtraPT)
		SELECT DISTINCT @GroupId, @GroupName, @ProductID, Sporttype, SubProduct, @EffectiveDate, @EndDate,
			CASE WHEN @ProductId = 1 AND SubProduct IN ('BT-Bought', 'BT-Comm', 'BT-Sold', 'BT-Winloss') THEN 0 ELSE @ExtraPT END
		FROM Acc_GroupExtraPT_Product WITH(NOLOCK)
		WHERE ProductID = @ProductId

		IF @@ROWCOUNT = 0 -- no data insert
		BEGIN
			INSERT INTO dbo.Acc_GroupExtraPT_Product (GroupId, GroupName, ProductID, Sporttype, SubProduct, FromDate, ToDate, ExtraPT)
			VALUES (@GroupId, @GroupName, @ProductID, 0, '', @EffectiveDate, @EndDate, @ExtraPT)

			IF @ProductId = 1
			BEGIN
				INSERT INTO dbo.Acc_GroupExtraPT_Product (GroupId, GroupName, ProductID, Sporttype, SubProduct, FromDate, ToDate, ExtraPT)
				SELECT @GroupId, @GroupName, @ProductID, Sporttype, SubProduct, @EffectiveDate, @EndDate, ExtraPT
				FROM (
					SELECT  0 AS Sporttype, 'BT-Bought'		AS SubProduct,		0	AS ExtraPT UNION ALL
					SELECT  0 AS Sporttype, 'BT-Comm'		AS SubProduct,		0	AS ExtraPT UNION ALL
					SELECT  0 AS Sporttype, 'BT-Sold'		AS SubProduct,		0	AS ExtraPT UNION ALL
					SELECT  0 AS Sporttype, 'BT-Winloss'	AS SubProduct,		0	AS ExtraPT UNION ALL
					SELECT  0 AS Sporttype, 'MG-SuperLive'	AS SubProduct, @ExtraPT AS ExtraPT UNION ALL
					SELECT 44 AS Sporttype, ''				AS SubProduct, @ExtraPT AS ExtraPT
				) AS A
			END
		END
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 107, @ErrMsg = ERROR_MESSAGE()

		RETURN
	END CATCH

	/* Super */
	-- affected super --
	DECLARE @Super TABLE (SuperId INT, Sporttype INT, SubProduct VARCHAR(50), FromDate DATETIME, ToDate DATETIME)

	DECLARE @FromDate DATETIME, @ToDate DATETIME

	SELECT  @FromDate = FromDate, @ToDate = ToDate FROM dbo.Acc_GroupExtraPT_Product WITH(NOLOCK)
	WHERE GroupId = @GroupId AND ProductID = @ProductID AND ToDate = DATEADD(DAY, -1, @EffectiveDate)

	IF @FromDate IS NOT NULL
	BEGIN
		DELETE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
		OUTPUT DELETED.SuperId, DELETED.Sporttype, DELETED.SubProduct, DELETED.FromDate, DELETED.ToDate
			INTO @Super (SuperId, Sporttype, SubProduct, FromDate, ToDate)
		WHERE GroupId = @GroupId AND ProductId = @ProductId
			AND @ToDate < FromDate
		
		UPDATE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
		SET ToDate = @ToDate
		OUTPUT DELETED.SuperId, DELETED.Sporttype, DELETED.SubProduct, DATEADD(DAY, 1, @ToDate), DELETED.ToDate
			INTO @Super (SuperId, Sporttype, SubProduct, FromDate, ToDate)
		WHERE GroupId = @GroupId AND ProductId = @ProductId
			AND @ToDate BETWEEN FromDate AND ToDate

		DELETE @Super
		WHERE ToDate < FromDate
	END

	SELECT  @FromDate = @EffectiveDate, @ToDate = @EndDate

	IF @isNew = 0
	BEGIN
		INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, FromDate, ToDate, ExtraPT)
		SELECT SuperId, @GroupId, @GroupName, @ProductId, Sporttype, SubProduct, FromDate, ToDate,
				CASE WHEN @ProductId = 1 AND SubProduct IN ('BT-Bought', 'BT-Comm', 'BT-Sold', 'BT-Winloss') THEN 0 ELSE @ExtraPT END
		FROM @Super
	END
	ELSE
	BEGIN
		;WITH Super AS (
			SELECT SuperId, MIN(FromDate) AS FromDate
			FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
			WHERE GroupId = @GroupId
				AND @FromDate <= ToDate
			GROUP BY SuperId
		)
		, CurrentSuper AS (
			SELECT SuperId, @FromDate AS FromDate
			FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
			WHERE GroupId = @GroupId
				AND ToDate BETWEEN @today AND @ToDate
				AND SuperId NOT IN (SELECT SuperId FROM Super)
			GROUP BY SuperId

			UNION ALL
			SELECT SuperId, FromDate
			FROM Super
		)
		, FeatureSuper AS (
			SELECT SuperId, MIN(FromDate) AS FromDate
			FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
			WHERE GroupId <> @GroupId
				AND SuperId IN (SELECT SuperId FROM CurrentSuper)
				AND FromDate >= @FromDate
			GROUP BY SuperId
		)
		INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
		SELECT cs.SuperId, @GroupId, @GroupName, @ProductId, B.Sporttype, B.SubProduct, B.ExtraPT,
				CASE WHEN @FromDate < cs.FromDate THEN cs.FromDate ELSE @FromDate END,
				CASE WHEN fs.FromDate IS NULL OR @ToDate < fs.FromDate THEN @ToDate ELSE DATEADD(DAY, -1, ISNULL(fs.FromDate, '9999-12-31')) END
		FROM CurrentSuper cs
			LEFT JOIN FeatureSuper fs ON cs.SuperId = fs.SuperId
			CROSS APPLY (
				SELECT 0 AS Sporttype, '' AS SubProduct, @ExtraPT AS ExtraPT
				
				UNION ALL
				SELECT Sporttype, SubProduct, ExtraPT
				FROM (
					SELECT  0 AS Sporttype, 'BT-Bought'		AS SubProduct,		0	AS ExtraPT UNION ALL
					SELECT  0 AS Sporttype, 'BT-Comm'		AS SubProduct,		0	AS ExtraPT UNION ALL
					SELECT  0 AS Sporttype, 'BT-Sold'		AS SubProduct,		0	AS ExtraPT UNION ALL
					SELECT  0 AS Sporttype, 'BT-Winloss'	AS SubProduct,		0	AS ExtraPT UNION ALL
					SELECT  0 AS Sporttype, 'MG-SuperLive'	AS SubProduct, @ExtraPT AS ExtraPT UNION ALL
					SELECT 44 AS Sporttype, ''				AS SubProduct, @ExtraPT AS ExtraPT
				) AS A
				WHERE @ProductId = 1
			) AS B
	END

	-- write log
	DECLARE @LogData NVARCHAR(MAX)
	SELECT  @LogData = '<Acc_GroupExtraPT_GroupByProduct_Ins UserID="' + CONVERT(VARCHAR(20), @UserID)
						+ '" Group="'			+ CONVERT(VARCHAR(50), @GroupName)
						+ '" Product="'			+ CONVERT(VARCHAR(50), @ProductName)
						+ '" ExtraPT="'			+ CONVERT(VARCHAR(50), @ExtraPT)
						+ '" EffectiveDate="'	+ CONVERT(VARCHAR(50), @EffectiveDate)
						+ '" EndDate="'			+ CONVERT(VARCHAR(50), @EndDate)
						+ '" />'

	SELECT	@duration = DATEDIFF(MILLISECOND, @startRun, GETDATE())

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @UserID,
		@ActionID = 673,
		@TrackingValue = @LogData,
		@duration = @duration
END