/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Acc_ExternalGroupHeadline_Ins]
	@UserId				INT
	,@GroupHeadlineId	INT
	,@SiteId			INT
	,@ExchangeId		INT
	,@ExternalGroups	VARCHAR(MAX)
	,@PrimaryExtraGroup	VARCHAR(100) = ''
	,@EffectiveDate		DATETIME = NULL
	,@IP				VARCHAR(20)
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			VARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20210302@Percy
	DB: DBCUST-CustDB
	Task: Auto Set Primary Extra PT Group

	Revisions:
		- 20210302@Percy: Initialize SP [RemineID: #146710]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @StartRun DATETIME, @Duration INT
	SET @StartRun = GETDATE()

	-- Check permission
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[HeadlineExternalGroupMapping]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN

	DECLARE @currentDate DATETIME = CONVERT(DATE, GETDATE())
	DECLARE @maxDate DATETIME = '9999-12-31'

	DECLARE @Site VARCHAR(50), @Currency VARCHAR(50)
	SELECT  @Site = Site FROM dbo.Site WITH (NOLOCK) WHERE SiteId = @SiteId
	SELECT  @Currency = Currency FROM dbo.Exchange WITH (NOLOCK) WHERE ExchangeId = @ExchangeId

	-- Check Effective Date
	IF (ISNULL(@PrimaryExtraGroup, '') <> '' AND @EffectiveDate IS NULL) OR @EffectiveDate < @currentDate
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Invalid Effective Date.'
		RETURN
	END

	-- Check existing mapping
	IF EXISTS (
		SELECT 1
		FROM dbo.EaGroupHeadline WITH (NOLOCK)
		WHERE GroupHeadlineId = @GroupHeadlineId AND SiteId = @SiteId AND ExchangeId = @ExchangeId
	)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This Headline/Site/Currency combination is existing.'
		RETURN
	END

	-- Check Group Headline
	IF NOT EXISTS (SELECT 1 FROM dbo.CustGroupHeadline WITH (NOLOCK) WHERE GroupId = @GroupHeadlineId)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This Group Headline does not exist.'
		RETURN
	END

	-- Check valid Group
	DECLARE @EaGroup TABLE (GroupId INT, GroupExtraPTId INT, GroupName VARCHAR(100), GroupTypeId TINYINT)
	INSERT INTO @EaGroup (GroupName, GroupTypeId)
	SELECT DISTINCT val, 0 FROM dbo.strSplit(@ExternalGroups, ',')

	UPDATE t
	SET t.GroupId = e.GroupId
	FROM @EaGroup t
		INNER JOIN NAP_UserControl.dbo.EaGroup e WITH (NOLOCK) ON t.GroupName = e.GroupName

	IF EXISTS (SELECT 1 FROM @EaGroup WHERE GroupId IS NULL)
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'Invalid External Group.'
		RETURN
	END

	UPDATE t
	SET t.GroupTypeId = 1, t.GroupExtraPTId = e.GroupId
	FROM @EaGroup t
		INNER JOIN dbo.Acc_DWLList_ExtraPT e WITH (NOLOCK) ON t.GroupName = e.GroupName
	WHERE t.GroupTypeId = 0

	IF @PrimaryExtraGroup = 'No Extra PT'
		INSERT INTO @EaGroup (GroupId, GroupName, GroupTypeId)
		VALUES (0, '', 2)
	ELSE IF ISNULL(@PrimaryExtraGroup, '') <> ''
	BEGIN
		UPDATE @EaGroup SET GroupTypeId = 2
		WHERE GroupName = @PrimaryExtraGroup AND GroupTypeId = 1

		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @ErrCode = 104, @ErrMsg = 'Invalid Primary Extra PT Group.'
			RETURN
		END
	END

	-- Check site, currency
	SET @ErrMsg = NULL
	SELECT @ErrMsg = COALESCE(@ErrMsg + ', ', '') + e.GroupName
	FROM @EaGroup e
	WHERE e.GroupId <> 0
		AND NOT EXISTS (SELECT 1 FROM dbo.f_SiteBySystem(e.GroupName) s WHERE ISNULL(s.SiteId, 0) = @SiteId)

	IF ISNULL(@ErrMsg, '') <> ''
	BEGIN
		SELECT @ErrCode = 105, @ErrMsg = 'These groups don''t belong to the selected site: ' + @ErrMsg
		RETURN
	END

	SET @ErrMsg = NULL
	SELECT @ErrMsg = COALESCE(@ErrMsg + ', ', '') + e.GroupName
	FROM @EaGroup e
	WHERE e.GroupId <> 0
		AND NOT EXISTS (SELECT 1 FROM dbo.f_CurrencyBySystem(e.GroupName) c WHERE ISNULL(c.ExchangeId, 0) = @ExchangeId)

	IF ISNULL(@ErrMsg, '') <> ''
	BEGIN
		SELECT @ErrCode = 106, @ErrMsg = 'These groups don''t belong to the selected currency: ' + @ErrMsg
		RETURN
	END

	-- List Super under Headline
	CREATE TABLE #Super (CustId INT NOT NULL, GroupExtraPTId INT, GroupName VARCHAR(100) NOT NULL, GroupTypeId TINYINT, EffectiveDate DATETIME, EndDate DATETIME, DataType TINYINT, PRIMARY KEY (CustId, GroupName))

	INSERT INTO #Super (CustId, GroupExtraPTId, GroupName, GroupTypeId, EffectiveDate, EndDate)
	SELECT s.CustId, e.GroupExtraPTId, e.GroupName, e.GroupTypeId, @EffectiveDate, DATEADD(DAY, -1, @currentDate)
	FROM (
		SELECT s.CustId
		FROM dbo.CustAccount ca WITH (NOLOCK)
			INNER JOIN dbo.Customer s WITH (NOLOCK) ON ca.CustId = s.CustId
			INNER JOIN dbo.CustInfo c WITH (NOLOCK) ON s.CustId = c.CustId AND c.Enabled = 1
		WHERE ca.GroupId = @GroupHeadlineId AND s.Site = @Site AND s.Currency = @ExchangeId
			AND s.RoleId = 4
	) s
		CROSS JOIN @EaGroup e

	-- Check super prefix
	DECLARE @tblPrefix TABLE (GroupName VARCHAR(50), Prefix VARCHAR(10), AllowNewSuper BIT)
	INSERT INTO @tblPrefix (GroupName, Prefix, AllowNewSuper)
	SELECT GroupName, Prefix, AllowNewSuper
	FROM dbo.Acc_SuperPrefix WITH (NOLOCK)
	WHERE ',' + @ExternalGroups + ',' LIKE '%,' + GroupName + ',%'
		
	IF @@ROWCOUNT <> 0
	BEGIN
		SET @ErrMsg = NULL

		;WITH CTE_Group AS (
			SELECT DISTINCT c.UserName, a.GroupName
			FROM #Super s
				INNER JOIN dbo.Customer c WITH (NOLOCK) ON s.CustId = c.CustId
				CROSS APPLY (SELECT DISTINCT t.GroupName FROM @tblPrefix t WHERE t.GroupName NOT IN (SELECT p.GroupName FROM @tblPrefix p WHERE c.UserName LIKE p.Prefix + '%' AND AllowNewSuper = 1)) a
			WHERE a.GroupName IS NOT NULL
		), CTE_UserName AS (
			SELECT g1.UserName
				,STUFF((SELECT ', ' + g2.GroupName FROM CTE_Group g2 WHERE g2.UserName = g1.UserName
						FOR XML PATH('')), 1, 2, '') AS GroupNames
			FROM CTE_Group g1
			GROUP BY g1.UserName
		)
		SELECT @ErrMsg = COALESCE(@ErrMsg + '<br/>', '') + UserName + ': Wrong username prefix for the group(s) ' + GroupNames
		FROM CTE_UserName
			
		SELECT @ErrMsg = ISNULL(@ErrMsg, '')
			
		IF @ErrMsg <> ''
		BEGIN
			SELECT @ErrCode = 106
			RETURN
		END
	END

	-- Log Extra PT
	BEGIN
		CREATE TABLE #ExtraPTLog (CustId INT, TrackingValue NVARCHAR(1000), TrackingValue2 NVARCHAR(1000))
		CREATE CLUSTERED INDEX CIX_ExtraPTLog ON #ExtraPTLog (CustId)

		CREATE TABLE #ExtraPTGroup (CustId INT, GroupId INT, GroupName VARCHAR(100), FromDate DATETIME, ToDate DATETIME, PRIMARY KEY (CustId, GroupId, GroupName, FromDate))
		INSERT INTO #ExtraPTGroup (CustId, GroupId, GroupName, FromDate, ToDate)
		SELECT e.SuperId, e.GroupId, e.GroupName, MIN(e.FromDate), MAX(e.ToDate)
		FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
			INNER JOIN (SELECT DISTINCT CustId FROM #Super) s ON e.SuperId = s.CustId
		WHERE e.ToDate >= @CurrentDate
		GROUP BY e.SuperId, e.GroupId, e.GroupName

		WHILE 1 = 1
		BEGIN
			UPDATE eg
			SET eg.FromDate = e.FromDate
			FROM #ExtraPTGroup eg
				CROSS APPLY (
					SELECT MIN(e.FromDate) AS FromDate
					FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
					WHERE e.SuperId = eg.CustId AND eg.GroupId = e.GroupId
						AND e.ToDate = DATEADD(DAY, -1, eg.FromDate)
				) e
			WHERE e.FromDate IS NOT NULL

			IF @@ROWCOUNT = 0
				BREAK
		END

		INSERT INTO #ExtraPTLog (CustId, TrackingValue2)
		SELECT CustId, '<Acc_ExternalGroupHeadline_Ins ExternalGroups="' + COALESCE(ExternalGroups, SPACE(1)) + '" ' + 'PrimaryGroup="' + COALESCE(PrimaryExtraGroup, SPACE(1)) + '" />'
		FROM
		(
			SELECT c.CustId
				,STUFF((
					SELECT ', ' + cg.GroupName
					FROM dbo.Acc_CustGroup cg WITH (NOLOCK)
						INNER JOIN NAP_UserControl.dbo.EaGroup eg WITH (NOLOCK) ON cg.GroupName = eg.GroupName AND eg.ParentId = 0
						LEFT JOIN dbo.Acc_CustGroup_Queue q WITH (NOLOCK) ON cg.CustId = q.CustId AND cg.GroupName = q.GroupName
					WHERE cg.CustId = c.CustId AND q.CustId IS NULL
					FOR XML PATH ('')), 1, 2, '') AS ExternalGroups
				,STUFF((
					SELECT ', ' + e.GroupName + ': ' + CONVERT(VARCHAR(10), e.FromDate, 120) + ' - ' + CONVERT(VARCHAR(10), e.ToDate, 120)
					FROM #ExtraPTGroup e
					WHERE e.CustId = c.CustId
					FOR XML PATH ('')), 1, 2, '') AS PrimaryExtraGroup
			FROM (SELECT DISTINCT CustId FROM #Super) c
			GROUP BY c.CustId
		) t
	END

	-- Insert mapping
	BEGIN TRY
		INSERT INTO dbo.EaGroupHeadline (GroupHeadlineId, GroupId, GroupName, SiteId, ExchangeId, GroupTypeId, EffectiveDate, EndDate)
		SELECT @GroupHeadlineId, GroupId, GroupName, @SiteId, @ExchangeId, GroupTypeId, CASE WHEN GroupTypeId = 2 THEN @EffectiveDate END, CASE WHEN GroupTypeId = 2 THEN @maxDate END
		FROM @EaGroup
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = 'Insert Headline/External Group Mapping failed.'
		RETURN
	END CATCH

	-- Extra PT Setting
	IF EXISTS (SELECT 1 FROM #Super)
	BEGIN
		UPDATE s
		SET s.EffectiveDate = CASE WHEN @EffectiveDate = @currentDate AND s.GroupTypeId = 2 THEN DATEADD(DAY, 1, s.EffectiveDate) ELSE s.EffectiveDate END
			,s.EndDate = @currentDate
		FROM #Super s
		WHERE EXISTS (SELECT c.CustId FROM dbo.Customer c WITH (NOLOCK) WHERE s.CustId = c.srecommend AND c.RoleId = 1)

		-- Remove future setting
		DELETE e WITH (ROWLOCK, UPDLOCK)
		FROM dbo.Acc_GroupExtraPTSetting e
			INNER JOIN (SELECT DISTINCT CustId, EndDate FROM #Super) s ON e.SuperId = s.CustId
		WHERE e.FromDate >= @currentDate
			AND (
				e.FromDate > @currentDate
				OR e.FromDate > s.EndDate
			)

		DELETE e WITH (ROWLOCK, UPDLOCK)
		FROM dbo.Acc_GroupExtraPT2Setting e
			INNER JOIN (SELECT DISTINCT CustId, EndDate FROM #Super) s ON e.SuperId = s.CustId
		WHERE e.FromDate >= @currentDate
			AND (
				e.FromDate > @currentDate
				OR e.FromDate > s.EndDate
			)
		
		-- Update current setting
		UPDATE e WITH (ROWLOCK)
		SET e.ToDate = CASE WHEN s.EndDate < p.ToDate THEN s.EndDate ELSE p.ToDate END
		FROM dbo.Acc_GroupExtraPTSetting e
			INNER JOIN dbo.Acc_GroupExtraPT_Product p WITH (NOLOCK)
				ON		e.GroupId		= p.GroupId
					AND e.ProductId		= p.ProductId
					AND e.Sporttype		= p.Sporttype
					AND e.SubProduct	= p.SubProduct
			INNER JOIN (SELECT DISTINCT CustId, EndDate FROM #Super) s ON e.SuperId = s.CustId
		WHERE s.EndDate BETWEEN p.FromDate AND p.ToDate
			AND s.EndDate BETWEEN e.FromDate AND e.ToDate

		UPDATE e WITH (ROWLOCK)
		SET e.ToDate = CASE WHEN s.EndDate < p.ToDate THEN s.EndDate ELSE p.ToDate END
		FROM dbo.Acc_GroupExtraPT2Setting e
			INNER JOIN dbo.Acc_GroupExtraPT_Product p WITH (NOLOCK)
				ON		e.GroupId		= p.GroupId
					AND e.ProductId		= p.ProductId
					AND e.Sporttype		= p.Sporttype
					AND e.SubProduct	= p.SubProduct
			INNER JOIN (SELECT DISTINCT CustId, EndDate FROM #Super) s ON e.SuperId = s.CustId
		WHERE s.EndDate BETWEEN p.FromDate AND p.ToDate
			AND s.EndDate BETWEEN e.FromDate AND e.ToDate

		-- Add new setting
		IF @PrimaryExtraGroup NOT IN ('', 'No Extra PT')
		BEGIN
			DECLARE @New_ExtraPTGroupId INT
			SELECT TOP 1 @New_ExtraPTGroupId = GroupId FROM dbo.Acc_GroupExtraPT_Product WITH (NOLOCK) WHERE GroupName = @PrimaryExtraGroup
			
			INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
			SELECT CustId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate
			FROM (
				SELECT s.CustId, p.GroupId, p.GroupName, p.ProductId, p.Sporttype, p.SubProduct, p.ExtraPT
					,CASE WHEN s.EffectiveDate > p.FromDate THEN s.EffectiveDate ELSE p.FromDate END AS FromDate
					,CASE WHEN p.ToDate < @maxDate THEN p.ToDate ELSE @maxDate END AS ToDate
				FROM dbo.Acc_GroupExtraPT_Product p WITH (NOLOCK)
					CROSS JOIN #Super s
				WHERE s.GroupTypeId = 2
					AND p.GroupId = @New_ExtraPTGroupId
					AND s.EffectiveDate <= p.ToDate
			) t
			WHERE FromDate <= ToDate

			INSERT INTO dbo.Acc_GroupExtraPT2Setting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
			SELECT CustId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate
			FROM (
				SELECT s.CustId, p.GroupId, p.GroupName, p.ProductId, p.Sporttype, p.SubProduct, p.ExtraPT
					,CASE WHEN s.EffectiveDate > p.FromDate THEN s.EffectiveDate ELSE p.FromDate END AS FromDate
					,CASE WHEN p.ToDate < @maxDate THEN p.ToDate ELSE @maxDate END AS ToDate
				FROM dbo.Acc_GroupExtraPT2_Product p WITH (NOLOCK)
					CROSS JOIN #Super s
				WHERE s.GroupTypeId = 2
					AND p.GroupId = @New_ExtraPTGroupId
					AND s.EffectiveDate <= p.ToDate
			) t
			WHERE FromDate <= ToDate
		END
	END

	-- Acc_CustGroup
	IF EXISTS (SELECT 1 FROM #Super)
	BEGIN
		INSERT INTO dbo.Acc_CustGroup (CustId, GroupName, RoleId)
		SELECT s.CustId, s.GroupName, 4
		FROM #Super s
			LEFT JOIN dbo.Acc_CustGroup cg WITH (NOLOCK) ON s.CustId = cg.CustId AND s.GroupName = cg.GroupName
		WHERE cg.CustId IS NULL AND s.GroupName <> '' -- No Extra PT

		DELETE q WITH (ROWLOCK, UPDLOCK)
		FROM dbo.Acc_CustGroup_Queue q
			INNER JOIN #Super s ON q.CustId = s.CustId AND q.GroupName = s.GroupName

		INSERT INTO #Super (CustId, GroupName, GroupTypeId)
		SELECT cg.CustId, cg.GroupName, CASE WHEN e.GroupName IS NOT NULL THEN 1 ELSE 0 END
		FROM dbo.Acc_CustGroup cg WITH (NOLOCK)
			INNER JOIN (SELECT DISTINCT CustId FROM #Super) c ON cg.CustId = c.CustId
			INNER JOIN NAP_UserControl.dbo.EaGroup eg WITH (NOLOCK) ON cg.GroupName = eg.GroupName AND eg.ParentId = 0
			LEFT JOIN dbo.Acc_DWLList_ExtraPT e WITH (NOLOCK) ON cg.GroupName = e.GroupName
			LEFT JOIN dbo.Acc_CustGroup_Queue q WITH (NOLOCK) ON cg.CustId = q.CustId AND cg.GroupName = q.GroupName
		WHERE NOT EXISTS (SELECT 1 FROM #Super s WHERE cg.CustId = s.CustId AND cg.GroupName = s.GroupName)
			AND q.CustId IS NULL
	END

	-- Log Extra PT
	BEGIN
		UPDATE eg
		SET eg.FromDate = e.FromDate, eg.ToDate = DATEADD(DAY, -1, @CurrentDate)
		FROM #ExtraPTGroup eg
			INNER JOIN (
				SELECT e.SuperId, e.GroupName, MIN(e.FromDate) AS FromDate
				FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
					INNER JOIN (SELECT DISTINCT CustId FROM #Super) s ON e.SuperId = s.CustId
				WHERE e.ToDate = DATEADD(DAY, -1, @CurrentDate) -- end yesterday
				GROUP BY e.SuperId, e.GroupName
			) e ON eg.CustId = e.SuperId AND eg.GroupName = e.GroupName

		DELETE #ExtraPTGroup WHERE ToDate >= @CurrentDate

		INSERT INTO #ExtraPTGroup (CustId, GroupId, GroupName, FromDate, ToDate)
		SELECT e.SuperId, e.GroupId, e.GroupName, MIN(e.FromDate), MAX(e.ToDate)
		FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
			INNER JOIN (SELECT DISTINCT CustId FROM #Super) s ON e.SuperId = s.CustId
		WHERE e.ToDate >= @CurrentDate
		GROUP BY e.SuperId, e.GroupId, e.GroupName

		DELETE e
		FROM (
			SELECT CustId, GroupName, ROW_NUMBER() OVER(PARTITION BY CustId, GroupName ORDER BY FromDate DESC) AS RN
			FROM #ExtraPTGroup e
		) e
		WHERE RN > 1

		WHILE 1 = 1
		BEGIN
			UPDATE eg
			SET eg.FromDate = e.FromDate
			FROM #ExtraPTGroup eg
				CROSS APPLY (
					SELECT MIN(e.FromDate) AS FromDate
					FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
					WHERE e.SuperId = eg.CustId AND eg.GroupId = e.GroupId
						AND e.ToDate = DATEADD(DAY, -1, eg.FromDate)
				) e
			WHERE e.FromDate IS NOT NULL

			IF @@ROWCOUNT = 0
				BREAK
		END

		INSERT INTO #ExtraPTLog (CustId, TrackingValue)
		SELECT CustId, '<Acc_ExternalGroupHeadline_Ins ExternalGroups="' + COALESCE(ExternalGroups, SPACE(1)) + '" ' + 'PrimaryGroup="' + COALESCE(PrimaryExtraGroup, SPACE(1)) + '" />'
		FROM
		(
			SELECT c.CustId
				,STUFF((
					SELECT ', ' + cg.GroupName
					FROM dbo.Acc_CustGroup cg WITH (NOLOCK)
						INNER JOIN NAP_UserControl.dbo.EaGroup eg WITH (NOLOCK) ON cg.GroupName = eg.GroupName AND eg.ParentId = 0
						LEFT JOIN dbo.Acc_CustGroup_Queue q WITH (NOLOCK) ON cg.CustId = q.CustId AND cg.GroupName = q.GroupName
					WHERE cg.CustId = c.CustId AND q.CustId IS NULL
					FOR XML PATH ('')), 1, 2, '') AS ExternalGroups
				,STUFF((
					SELECT ', ' + e.GroupName + ': ' + CONVERT(VARCHAR(10), e.FromDate, 120) + ' - ' + CONVERT(VARCHAR(10), e.ToDate, 120)
					FROM #ExtraPTGroup e
					WHERE e.CustId = c.CustId
					FOR XML PATH ('')), 1, 2, '') AS PrimaryExtraGroup
			FROM (SELECT DISTINCT CustId FROM #Super) c
			GROUP BY c.CustId
		) t

		UPDATE e1
		SET e1.TrackingValue = e2.TrackingValue
		FROM #ExtraPTLog e1
			INNER JOIN #ExtraPTLog e2 ON e1.CustId = e2.CustId

		DELETE e
		FROM (
			SELECT CustId, ROW_NUMBER() OVER(PARTITION BY CustId ORDER BY CASE WHEN TrackingValue IS NOT NULL AND TrackingValue2 IS NOT NULL THEN 0 ELSE 1 END) AS RN
			FROM #ExtraPTLog
		) e
		WHERE RN > 1
	END

	-- Write log
	DECLARE @TrackingValue NVARCHAR(1000), @TrackingValue2 NVARCHAR(1000)
	SET @Duration = DATEDIFF (MILLISECOND, @startRun, GETDATE())

	DECLARE @CustId INT

	-- Log for Headline
	SELECT @CustId = CustId FROM dbo.CustGroupHeadline WITH (NOLOCK) WHERE GroupId = @GroupHeadlineId
	SELECT @TrackingValue = '<Acc_ExternalGroupHeadline_Ins Site="' + COALESCE(@Site, SPACE(1)) + '" ' +
															'Currency="' + COALESCE(@Currency, SPACE(1)) + '" ' +
															'PrimaryGroup="' + COALESCE(@PrimaryExtraGroup + ': ' + CONVERT(VARCHAR(10), @EffectiveDate, 120), SPACE(1)) + '" ' +
															'HeadlineId="' + COALESCE(CONVERT(VARCHAR(20), @GroupHeadlineId), SPACE(1)) + '" ' +
															'ExternalGroups="' + COALESCE(REPLACE(@ExternalGroups, ',', ', '), SPACE(1)) + '" />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId			= @UserId
		,@CustId		= @CustId
		,@ActionId		= 95041
		,@TrackingValue = @TrackingValue
		,@Duration		= @Duration

	-- Extra PT for Super
	WHILE EXISTS (SELECT 1 FROM #ExtraPTLog)
	BEGIN
		SELECT TOP 1 @CustId = CustId, @TrackingValue = ISNULL(TrackingValue, ''), @TrackingValue2 = ISNULL(TrackingValue2, '') FROM #ExtraPTLog

		IF ISNULL(@TrackingValue, '') = ''
			SELECT @TrackingValue = @TrackingValue2, @TrackingValue2 = ''

		IF ISNULL(@TrackingValue, '') <> ''
			EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId
				,@CustId			= @CustId
				,@ActionId			= 95050
				,@TrackingValue		= @TrackingValue
				,@TrackingValue2	= @TrackingValue2
				,@Duration			= @Duration
		
		DELETE #ExtraPTLog WHERE CustId = @CustId
	END

	DROP TABLE #ExtraPTGroup
	DROP TABLE #ExtraPTLog
	DROP TABLE #Super
END
GO