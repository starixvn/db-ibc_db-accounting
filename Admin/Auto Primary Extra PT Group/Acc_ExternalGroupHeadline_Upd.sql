/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Acc_ExternalGroupHeadline_Upd]
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
	DECLARE @Old_AllPrimaryGroups VARCHAR(MAX), @New_AllPrimaryGroups VARCHAR(MAX)
	DECLARE @Old_ExternalGroups VARCHAR(MAX), @New_ExternalGroups VARCHAR(MAX)

	DECLARE @Site VARCHAR(50), @Currency VARCHAR(50)
	SELECT  @Site = Site FROM dbo.Site WITH (NOLOCK) WHERE SiteId = @SiteId
	SELECT  @Currency = Currency FROM dbo.Exchange WITH (NOLOCK) WHERE ExchangeId = @ExchangeId

	CREATE TABLE #Super (CustId INT NOT NULL, GroupExtraPTId INT, GroupName VARCHAR(100) NOT NULL, GroupTypeId TINYINT, EffectiveDate DATETIME, EndDate DATETIME, DataType TINYINT, PRIMARY KEY (CustId, GroupName))
	CREATE TABLE #OldSuper (CustId INT NOT NULL, GroupName VARCHAR(100) NOT NULL, EffectiveDate DATETIME, EndDate DATETIME, PRIMARY KEY (CustId, GroupName))

	DECLARE @OldEaGroup TABLE (GroupId INT, GroupName VARCHAR(100), GroupTypeId TINYINT, EffectiveDate DATETIME, EndDate DATETIME)
	INSERT INTO @OldEaGroup (GroupId, GroupName, GroupTypeId, EffectiveDate, EndDate)
	SELECT GroupId, GroupName, GroupTypeId, EffectiveDate, EndDate
	FROM dbo.EaGroupHeadline WITH (NOLOCK)
	WHERE GroupHeadlineId = @GroupHeadlineId AND SiteId = @SiteId AND ExchangeId = @ExchangeId
	
	-- Check existing mapping
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'This Headline/Site/Currency combination doesn''t exist.'
		RETURN
	END

	UPDATE @OldEaGroup
	SET GroupTypeId = 1, EffectiveDate = NULL, EndDate = NULL
	WHERE GroupTypeId = 2 AND EndDate < @currentDate

	DECLARE @EaGroup TABLE (GroupId INT, GroupExtraPTId INT, GroupName VARCHAR(100), GroupTypeId TINYINT, EffectiveDate DATETIME, EndDate DATETIME)
	INSERT INTO @EaGroup (GroupName, GroupTypeId)
	SELECT val, 0 FROM dbo.strSplit(@ExternalGroups, ',')

	UPDATE t
	SET t.GroupId = e.GroupId
	FROM @EaGroup t
		INNER JOIN NAP_UserControl.dbo.EaGroup e WITH (NOLOCK) ON t.GroupName = e.GroupName AND e.ParentId = 0

	IF EXISTS (SELECT 1 FROM @EaGroup WHERE GroupId IS NULL)
	BEGIN
		SELECT @ErrCode = 110, @ErrMsg = 'Invalid External Group.'
		RETURN
	END

	UPDATE t
	SET t.GroupTypeId = 1, t.GroupExtraPTId = e.GroupId
	FROM @EaGroup t
		INNER JOIN dbo.Acc_DWLList_ExtraPT e WITH (NOLOCK) ON t.GroupName = e.GroupName
	WHERE t.GroupTypeId = 0

	IF @PrimaryExtraGroup = 'No Extra PT'
		INSERT INTO @EaGroup (GroupId, GroupName, GroupTypeId, EffectiveDate, EndDate)
		VALUES (0, '', 2, @EffectiveDate, @maxDate)
	ELSE IF ISNULL(@PrimaryExtraGroup, '') <> ''
	BEGIN
		UPDATE @EaGroup SET GroupTypeId = 2, EffectiveDate = @EffectiveDate, EndDate = @maxDate
		WHERE GroupName = @PrimaryExtraGroup AND GroupTypeId = 1

		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @ErrCode = 112, @ErrMsg = 'Invalid Primary Extra PT Group.'
			RETURN
		END
	END
	ELSE
		SET @EffectiveDate = @currentDate

	IF NOT EXISTS (SELECT 1 FROM @EaGroup WHERE GroupName = '')
		INSERT INTO @EaGroup (GroupId, GroupName, GroupTypeId)
		SELECT GroupId, GroupName, 1 FROM @OldEaGroup WHERE GroupName = ''

	-- Check site, currency
	SET @ErrMsg = NULL
	SELECT @ErrMsg = COALESCE(@ErrMsg + ', ', '') + e.GroupName
	FROM @EaGroup e
	WHERE e.GroupId <> 0
		AND NOT EXISTS (SELECT 1 FROM dbo.f_SiteBySystem(e.GroupName) s WHERE ISNULL(s.SiteId, 0) = @SiteId)

	IF ISNULL(@ErrMsg, '') <> ''
	BEGIN
		SELECT @ErrCode = 120, @ErrMsg = 'These groups don''t belong to the selected site: ' + @ErrMsg
		RETURN
	END

	SET @ErrMsg = NULL
	SELECT @ErrMsg = COALESCE(@ErrMsg + ', ', '') + e.GroupName
	FROM @EaGroup e
	WHERE e.GroupId <> 0
		AND NOT EXISTS (SELECT 1 FROM dbo.f_CurrencyBySystem(e.GroupName) c WHERE ISNULL(c.ExchangeId, 0) = @ExchangeId)

	IF ISNULL(@ErrMsg, '') <> ''
	BEGIN
		SELECT @ErrCode = 121, @ErrMsg = 'These groups don''t belong to the selected currency: ' + @ErrMsg
		RETURN
	END

	-- Check data
	IF EXISTS (SELECT 1 FROM @EaGroup WHERE GroupTypeId = 2)
	BEGIN
		DECLARE @NoOfGroup INT
		-- Check Effective Date
		IF (NOT EXISTS (SELECT 1 FROM @OldEaGroup WHERE GroupTypeId = 2) AND @EffectiveDate < @currentDate)
			OR @EffectiveDate IS NULL
		BEGIN
			SELECT @ErrCode = 130, @ErrMsg = 'Invalid Effective Date.'
			RETURN
		END

		-- Check existing future mapping
		SELECT @NoOfGroup = COUNT(1) FROM @OldEaGroup WHERE GroupTypeId = 2
		
		IF @NoOfGroup = 1
		BEGIN
			IF EXISTS (SELECT 1 FROM @OldEaGroup WHERE GroupTypeId = 2 AND GroupName = ISNULL(NULLIF(@PrimaryExtraGroup, 'No Extra PT'), '') AND EffectiveDate <= @currentDate AND EffectiveDate < @EffectiveDate)
			BEGIN
				SELECT @ErrCode = 131, @ErrMsg = 'The selected primary group has is the currently effective group. You cannot set it as the primary group again.'
				RETURN
			END

			IF EXISTS (SELECT 1 FROM @OldEaGroup WHERE GroupTypeId = 2 AND GroupName <> ISNULL(NULLIF(@PrimaryExtraGroup, 'No Extra PT'), '') AND EffectiveDate > @currentDate AND EffectiveDate < @EffectiveDate)
			BEGIN
				SELECT @ErrCode = 132, @ErrMsg = 'You can only add one future extra pt setting plan for a mapping. Please replace the existing group by the group ' + @PrimaryExtraGroup + ' effective from ' + CONVERT(VARCHAR(10), EffectiveDate, 101) + ', then submit. After that, you can choose ' + CONVERT(VARCHAR(10), @EffectiveDate, 101) + '.'
				FROM @OldEaGroup WHERE GroupTypeId = 2 AND EffectiveDate > @currentDate AND EffectiveDate < @EffectiveDate
				RETURN
			END
		END
		ELSE IF @NoOfGroup = 2
		BEGIN
			IF EXISTS (SELECT 1 FROM @OldEaGroup WHERE GroupTypeId = 2 AND GroupName <> ISNULL(NULLIF(@PrimaryExtraGroup, 'No Extra PT'), '') AND EffectiveDate > @currentDate AND EffectiveDate < @EffectiveDate)
			BEGIN
				SELECT @ErrCode = 132, @ErrMsg = 'You can only add one future extra pt setting plan for a mapping. Please replace the existing group by the group ' + @PrimaryExtraGroup + ' effective from ' + CONVERT(VARCHAR(10), EffectiveDate, 101) + ', then submit. After that, you can choose ' + CONVERT(VARCHAR(10), @EffectiveDate, 101) + '.'
				FROM @OldEaGroup WHERE GroupTypeId = 2 AND EffectiveDate > @currentDate AND EffectiveDate < @EffectiveDate
				RETURN
			END
		END

		-- Update new mapping
		IF @NoOfGroup = 1
		BEGIN
			-- comment
			IF EXISTS (SELECT 1 FROM @OldEaGroup WHERE GroupTypeId = 2 AND EffectiveDate <= @currentDate)
				UPDATE e
				SET e.GroupTypeId = 2, e.EffectiveDate = o.EffectiveDate
				FROM @EaGroup e
					INNER JOIN @OldEaGroup o ON e.GroupName = o.GroupName AND o.GroupTypeId = 2 AND o.EffectiveDate < @EffectiveDate
				WHERE e.GroupTypeId = 1
		END
		ELSE IF @NoOfGroup = 2
		BEGIN
			-- Update same group with old setting
			IF EXISTS (SELECT 1 FROM @OldEaGroup WHERE GroupTypeId = 2 AND GroupName = ISNULL(NULLIF(@PrimaryExtraGroup, 'No Extra PT'), ''))
			BEGIN
				-- Update future setting
				IF EXISTS (SELECT 1 FROM @OldEaGroup WHERE GroupTypeId = 2 AND GroupName = ISNULL(NULLIF(@PrimaryExtraGroup, 'No Extra PT'), '') AND EffectiveDate > @currentDate)
					UPDATE e
					SET e.GroupTypeId = 2, e.EffectiveDate = o.EffectiveDate
					FROM @EaGroup e
						INNER JOIN @OldEaGroup o ON e.GroupName = o.GroupName AND o.GroupTypeId = 2 AND o.EffectiveDate < @EffectiveDate
					WHERE e.GroupTypeId = 1
				-- Update current setting
				ELSE IF EXISTS (SELECT 1 FROM @OldEaGroup WHERE GroupTypeId = 2 AND GroupName = ISNULL(NULLIF(@PrimaryExtraGroup, 'No Extra PT'), '') AND EffectiveDate <= @currentDate AND EffectiveDate < @EffectiveDate)
					UPDATE e
					SET e.EffectiveDate = o.EffectiveDate
					FROM @EaGroup e
						INNER JOIN @OldEaGroup o ON e.GroupName = o.GroupName AND o.GroupTypeId = 2
					WHERE e.GroupTypeId = 2
				ELSE IF EXISTS (SELECT 1 FROM @OldEaGroup WHERE GroupTypeId = 2 AND GroupName = ISNULL(NULLIF(@PrimaryExtraGroup, 'No Extra PT'), '') AND EffectiveDate <= @currentDate AND EffectiveDate = @EffectiveDate)
					UPDATE e
					SET e.GroupTypeId = 2, e.EffectiveDate = o.EffectiveDate
					FROM @EaGroup e
						INNER JOIN @OldEaGroup o ON e.GroupName = o.GroupName AND o.GroupTypeId = 2
					WHERE e.GroupTypeId = 1 AND o.EffectiveDate > @EffectiveDate
			END
			ELSE -- update different group with old setting
			BEGIN
				UPDATE e
				SET e.GroupTypeId = 2, e.EffectiveDate = o.EffectiveDate
				FROM @EaGroup e
					INNER JOIN @OldEaGroup o ON e.GroupName = o.GroupName AND o.GroupTypeId = 2
				WHERE e.GroupTypeId = 1 AND o.EffectiveDate < @EffectiveDate
			END
		END

		UPDATE e1
		SET e1.EndDate = ISNULL(DATEADD(DAY, -1, e2.EffectiveDate), @maxDate)
		FROM @EaGroup e1
			LEFT JOIN @EaGroup e2 ON e1.GroupTypeId = e2.GroupTypeId AND e1.EffectiveDate < e2.EffectiveDate
		WHERE e1.GroupTypeId = 2

		UPDATE @EaGroup SET GroupTypeId = 1, EffectiveDate = NULL, EndDate = NULL WHERE GroupTypeId = 2 AND EndDate < @currentDate

		DELETE @EaGroup WHERE GroupName = '' AND GroupTypeId = 1
	END

	SELECT @Old_AllPrimaryGroups = COALESCE(@Old_AllPrimaryGroups + ', ', '') + CASE WHEN GroupName = '' THEN 'No Extra PT' ELSE GroupName END + ': ' + CONVERT(VARCHAR(10), EffectiveDate, 120)
	FROM @OldEaGroup WHERE GroupTypeId = 2

	SELECT @Old_ExternalGroups = COALESCE(@Old_ExternalGroups + ', ', '') + GroupName
	FROM @OldEaGroup WHERE GroupName <> ''

	SELECT @New_AllPrimaryGroups = COALESCE(@New_AllPrimaryGroups + ', ', '') + CASE WHEN GroupName = '' THEN 'No Extra PT' ELSE GroupName END + ': ' + CONVERT(VARCHAR(10), EffectiveDate, 120)
	FROM @EaGroup WHERE GroupTypeId = 2

	SELECT @New_ExternalGroups = COALESCE(@New_ExternalGroups + ', ', '') + GroupName
	FROM @EaGroup WHERE GroupName <> ''

	-- List Super under Headline
	INSERT INTO #Super (CustId, GroupExtraPTId, GroupName, GroupTypeId, EffectiveDate, EndDate, DataType)
	SELECT s.CustId, e.GroupExtraPTId, e.GroupName, e.GroupTypeId
		,CASE WHEN e.EffectiveDate < @currentDate THEN @currentDate ELSE e.EffectiveDate END, e.EndDate
		,CASE WHEN e.GroupTypeId = 2 THEN CASE WHEN e.EndDate = @maxDate THEN 1 ELSE 2 END END -- 1 = insert, 2 = update
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

	UPDATE s
	SET EffectiveDate = DATEADD(DAY, 1, EffectiveDate)
	FROM #Super s
	WHERE s.GroupTypeId = 2 AND EXISTS (SELECT 1 FROM dbo.Customer c WITH (NOLOCK) WHERE s.CustId = c.srecommend AND c.roleid = 1)
		AND s.EffectiveDate = @currentDate

	IF @@ROWCOUNT <> 0
		UPDATE s1
		SET s1.EndDate = DATEADD(DAY, -1, s2.EffectiveDate)
		FROM #Super s1
			INNER JOIN #Super s2 ON s1.CustId = s2.CustId AND s1.GroupName = s2.GroupName AND s1.EffectiveDate < s2.EffectiveDate
		WHERE s1.GroupTypeId = 2

	-- Old Setting
	INSERT INTO #OldSuper (CustId, GroupName, EffectiveDate, EndDate)
	SELECT e.SuperId, e.GroupName, MIN(e.FromDate), MAX(e.ToDate)
	FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
		INNER JOIN (SELECT DISTINCT CustId FROM #Super) s ON e.SuperId = s.CustId
	WHERE @currentDate BETWEEN e.FromDate AND e.ToDate
	GROUP BY e.SuperId, e.GroupId, e.GroupName

	UPDATE o
	SET o.EndDate = ISNULL(s.EndDate, DATEADD(DAY, -1, @currentDate))
	FROM #OldSuper o
		LEFT JOIN #Super s ON o.CustId = s.CustId AND o.GroupName = s.GroupName
			AND s.GroupTypeId = 2
			AND (
				DATEADD(DAY, -1, s.EffectiveDate) = o.EndDate
				OR s.EffectiveDate BETWEEN o.EffectiveDate AND o.EndDate
			)
	
	UPDATE o
	SET EndDate = CASE WHEN EndDate = DATEADD(DAY, -1, @currentDate) THEN DATEADD(DAY, 1, EndDate) ELSE EndDate END
	FROM #OldSuper o
	WHERE EXISTS (SELECT 1 FROM dbo.Customer c WITH (NOLOCK) WHERE o.CustId = c.srecommend AND c.roleid = 1)

	UPDATE s
	SET s.DataType = 1
	FROM (
		SELECT DataType, EffectiveDate, ROW_NUMBER() OVER(PARTITION BY CustId ORDER BY EffectiveDate DESC) AS RN
		FROM #Super
	) s
	WHERE RN = 2 AND EffectiveDate > @currentDate
	
	UPDATE s
	SET s.DataType = 2
	FROM #Super s
		INNER JOIN #OldSuper o ON s.CustId = o.CustId AND s.GroupName = o.GroupName AND s.EffectiveDate BETWEEN o.EffectiveDate AND o.EndDate
	WHERE s.DataType = 1

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
		SELECT CustId, '<Acc_ExternalGroupHeadline_Upd ExternalGroups="' + COALESCE(ExternalGroups, SPACE(1)) + '" ' + 'PrimaryGroup="' + COALESCE(PrimaryExtraGroup, SPACE(1)) + '" />'
		FROM (
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

	-- Update mapping
	BEGIN TRY
		MERGE dbo.EaGroupHeadline AS t
		USING @EaGroup AS s
			ON		t.GroupId			= s.GroupId
				AND t.GroupName			= s.GroupName
				AND t.GroupHeadlineId	= @GroupHeadlineId
				AND t.SiteId			= @SiteId
				AND t.ExchangeId		= @ExchangeId
		WHEN MATCHED THEN UPDATE
			SET t.GroupTypeId = s.GroupTypeId, t.EffectiveDate = s.EffectiveDate, t.EndDate = s.EndDate
		WHEN NOT MATCHED BY TARGET THEN INSERT
			(GroupHeadlineId, GroupId, GroupName, SiteId, ExchangeId, GroupTypeId, EffectiveDate, EndDate)
			VALUES
			(@GroupHeadlineId, GroupId, GroupName, @SiteId, @ExchangeId, GroupTypeId, EffectiveDate, EndDate)
		WHEN NOT MATCHED BY SOURCE AND t.GroupHeadlineId = @GroupHeadlineId AND t.SiteId = @SiteId AND t.ExchangeId = @ExchangeId THEN DELETE;
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = 'Update Headline/External Group Mapping falied.'
		RETURN
	END CATCH

	-- Extra PT Setting
	IF EXISTS (
		SELECT 1
		FROM (SELECT GroupName, EffectiveDate, EndDate FROM @EaGroup WHERE GroupTypeId = 2) e
			FULL OUTER JOIN (SELECT GroupName, EffectiveDate, EndDate FROM @OldEaGroup WHERE GroupTypeId = 2) o ON e.GroupName = o.GroupName
		WHERE e.GroupName IS NULL OR o.GroupName IS NULL
			OR e.EffectiveDate <> o.EffectiveDate OR e.EndDate <> o.EndDate
	)
	BEGIN
		-- Remove future setting
		DELETE e WITH (ROWLOCK, UPDLOCK)
		FROM dbo.Acc_GroupExtraPTSetting e
			INNER JOIN (SELECT DISTINCT CustId FROM #Super) s ON e.SuperId = s.CustId
			LEFT JOIN #OldSuper o ON e.SuperId = o.CustId AND e.GroupName = o.GroupName
		WHERE e.FromDate >= @currentDate
			AND (
				e.FromDate > @currentDate
				OR e.FromDate > o.EndDate
			)

		DELETE e WITH (ROWLOCK, UPDLOCK)
		FROM dbo.Acc_GroupExtraPT2Setting e
			INNER JOIN (SELECT DISTINCT CustId FROM #Super) s ON e.SuperId = s.CustId
			LEFT JOIN #OldSuper o ON e.SuperId = o.CustId AND e.GroupName = o.GroupName
		WHERE e.FromDate >= @currentDate
			AND (
				e.FromDate > @currentDate
				OR e.FromDate > o.EndDate
			)

		-- Update current setting
		UPDATE e WITH (ROWLOCK)
		SET e.ToDate = CASE WHEN o.EndDate < p.ToDate THEN o.EndDate ELSE p.ToDate END
		FROM dbo.Acc_GroupExtraPTSetting e
			INNER JOIN dbo.Acc_GroupExtraPT_Product p WITH (NOLOCK)
				ON		e.GroupId		= p.GroupId
					AND e.ProductId		= p.ProductId
					AND e.Sporttype		= p.Sporttype
					AND e.SubProduct	= p.SubProduct
			INNER JOIN #OldSuper o ON e.SuperId = o.CustId AND e.GroupName = o.GroupName
		WHERE @currentDate BETWEEN e.FromDate AND e.ToDate
			AND @currentDate BETWEEN p.FromDate AND p.ToDate

		UPDATE e WITH (ROWLOCK)
		SET e.ToDate = CASE WHEN o.EndDate < p.ToDate THEN o.EndDate ELSE p.ToDate END
		FROM dbo.Acc_GroupExtraPT2Setting e
			INNER JOIN dbo.Acc_GroupExtraPT2_Product p WITH (NOLOCK)
				ON		e.GroupId		= p.GroupId
					AND e.ProductId		= p.ProductId
					AND e.Sporttype		= p.Sporttype
					AND e.SubProduct	= p.SubProduct
			INNER JOIN #OldSuper o ON e.SuperId = o.CustId AND e.GroupName = o.GroupName
		WHERE @currentDate BETWEEN e.FromDate AND e.ToDate
			AND @currentDate BETWEEN p.FromDate AND p.ToDate

		-- Add new setting
		IF EXISTS (SELECT 1 FROM #Super WHERE GroupTypeId = 2 AND GroupName <> '')
		BEGIN
			INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
			SELECT t.CustId, t.GroupId, t.GroupName, t.ProductId, t.Sporttype, t.SubProduct, t.ExtraPT, t.FromDate, t.ToDate
			FROM (
				SELECT s.CustId, p.GroupId, p.GroupName, p.ProductId, p.Sporttype, p.SubProduct, p.ExtraPT
					,CASE WHEN s.EffectiveDate > p.FromDate THEN s.EffectiveDate ELSE p.FromDate END AS FromDate
					,CASE WHEN s.EndDate < p.ToDate THEN s.EndDate ELSE p.ToDate END AS ToDate
				FROM dbo.Acc_GroupExtraPT_Product p WITH (NOLOCK)
					INNER JOIN #Super s ON p.GroupName = s.GroupName AND s.GroupTypeId = 2 AND s.EffectiveDate <= s.EndDate AND s.GroupName <> ''
				WHERE s.EffectiveDate <= p.ToDate
			) t
				LEFT JOIN dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
					ON	t.CustId		= e.SuperId
					AND t.GroupId		= e.GroupId
					AND t.ProductId		= e.ProductId
					AND t.Sporttype		= e.Sporttype
					AND t.SubProduct	= e.SubProduct
					AND t.FromDate BETWEEN e.FromDate AND e.ToDate
			WHERE t.FromDate <= t.ToDate
				AND e.SuperId IS NULL

			INSERT INTO dbo.Acc_GroupExtraPT2Setting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
			SELECT t.CustId, t.GroupId, t.GroupName, t.ProductId, t.Sporttype, t.SubProduct, t.ExtraPT, t.FromDate, t.ToDate
			FROM (
				SELECT s.CustId, p.GroupId, p.GroupName, p.ProductId, p.Sporttype, p.SubProduct, p.ExtraPT
					,CASE WHEN s.EffectiveDate > p.FromDate THEN s.EffectiveDate ELSE p.FromDate END AS FromDate
					,CASE WHEN s.EndDate < p.ToDate THEN s.EndDate ELSE p.ToDate END AS ToDate
				FROM dbo.Acc_GroupExtraPT2_Product p WITH (NOLOCK)
					INNER JOIN #Super s ON p.GroupName = s.GroupName AND s.GroupTypeId = 2 AND s.EffectiveDate <= s.EndDate AND s.GroupName <> ''
				WHERE s.EffectiveDate <= p.ToDate
			) t
				LEFT JOIN dbo.Acc_GroupExtraPT2Setting e WITH (NOLOCK)
					ON	t.CustId		= e.SuperId
					AND t.GroupId		= e.GroupId
					AND t.ProductId		= e.ProductId
					AND t.Sporttype		= e.Sporttype
					AND t.SubProduct	= e.SubProduct
					AND t.FromDate BETWEEN e.FromDate AND e.ToDate
			WHERE t.FromDate <= t.ToDate
				AND e.SuperId IS NULL
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

	-- Log for Extra PT
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
		SELECT CustId, '<Acc_ExternalGroupHeadline_Upd ExternalGroups="' + COALESCE(ExternalGroups, SPACE(1)) + '" ' + 'PrimaryGroup="' + COALESCE(PrimaryExtraGroup, SPACE(1)) + '" />'
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
		WHERE e1.TrackingValue2 IS NOT NULL AND e2.TrackingValue IS NOT NULL

		DELETE e
		FROM (
			SELECT CustId, ROW_NUMBER() OVER(PARTITION BY CustId ORDER BY CASE WHEN TrackingValue IS NOT NULL AND TrackingValue2 IS NOT NULL THEN 0 ELSE 1 END) AS RN
			FROM #ExtraPTLog
		) e
		WHERE RN > 1
	END

	-- Write log
	DECLARE @CustId INT, @TrackingValue NVARCHAR(1000), @TrackingValue2 NVARCHAR(1000)
	SET @Duration = DATEDIFF (MILLISECOND, @startRun, GETDATE())

	-- Mapping for Headline
	SELECT @CustId = CustId FROM dbo.CustGroupHeadline WITH (NOLOCK) WHERE GroupId = @GroupHeadlineId
	SELECT @TrackingValue = '<Acc_ExternalGroupHeadline_Upd Site="' + COALESCE(@Site, SPACE(1)) + '" ' +
															'Currency="' + COALESCE(@Currency, SPACE(1)) + '" ' +
															'PrimaryGroup="' + COALESCE(PrimaryExtraGroup, SPACE(1)) + '" ' +
															'HeadlineId="' + COALESCE(CONVERT(VARCHAR(20), @GroupHeadlineId), SPACE(1)) + '" ' +
															'ExternalGroups="' + COALESCE(ExternalGroups, SPACE(1)) + '" />'
	FROM (
		SELECT STUFF((SELECT ', ' + GroupName FROM @EaGroup WHERE GroupName <> '' FOR XML PATH('')), 1, 2, '') AS ExternalGroups
			,STUFF((SELECT ', ' + ISNULL(NULLIF(GroupName, ''), 'No Extra PT') + ': ' + CONVERT(VARCHAR(10), EffectiveDate, 120) + ' - ' + + CONVERT(VARCHAR(10), EndDate, 120) FROM @EaGroup WHERE GroupTypeId = 2 FOR XML PATH('')), 1, 2, '') AS PrimaryExtraGroup
	) e

	SELECT @TrackingValue2 = '<Acc_ExternalGroupHeadline_Upd Site="' + COALESCE(@Site, SPACE(1)) + '" ' +
															'Currency="' + COALESCE(@Currency, SPACE(1)) + '" ' +
															'PrimaryGroup="' + COALESCE(PrimaryExtraGroup, SPACE(1)) + '" ' +
															'HeadlineId="' + COALESCE(CONVERT(VARCHAR(20), @GroupHeadlineId), SPACE(1)) + '" ' +
															'ExternalGroups="' + COALESCE(ExternalGroups, SPACE(1)) + '" />'
	FROM (
		SELECT STUFF((SELECT ', ' + GroupName FROM @OldEaGroup WHERE GroupName <> '' FOR XML PATH('')), 1, 2, '') AS ExternalGroups
			,STUFF((SELECT ', ' + ISNULL(NULLIF(GroupName, ''), 'No Extra PT') + ': ' + CONVERT(VARCHAR(10), EffectiveDate, 120) + ' - ' + + CONVERT(VARCHAR(10), EndDate, 120) FROM @OldEaGroup WHERE GroupTypeId = 2 FOR XML PATH('')), 1, 2, '') AS PrimaryExtraGroup
	) e

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= @UserId
		,@CustId			= @CustId
		,@ActionId			= 95042
		,@TrackingValue		= @TrackingValue
		,@TrackingValue2	= @TrackingValue2
		,@Duration			= @Duration

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
				,@ActionId			= 95051
				,@TrackingValue		= @TrackingValue
				,@TrackingValue2	= @TrackingValue2
				,@Duration			= @Duration
		
		DELETE #ExtraPTLog WHERE CustId = @CustId
	END

	DROP TABLE #ExtraPTGroup
	DROP TABLE #ExtraPTLog
	DROP TABLE #Super
	DROP TABLE #OldSuper
END
GO