/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Acc_ExternalGroupHeadline_UpdSuper]
	@UserId					INT
	,@CustId				INT
	,@GroupHeadlineId		INT
	,@Old_GroupHeadlineId	INT = 0
	,@HeadlineId			INT
	,@AffectedSupers		VARCHAR(MAX) = '' OUTPUT
	,@SPName				VARCHAR(128) = '' -- for log
AS

/*
	Created: 20210301@Percy
	DB: DBCUST-CustDB
	Task: Add super into Headline - Auto add extra PT Setting

	Revisions:
		- 20210301@Percy: Initialize SP [RedmineID: #146710]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @StartRun DATETIME, @Duration INT, @ActionId INT, @LogHeadline NVARCHAR(1000)
	SET @StartRun = GETDATE()

	SELECT @SPName = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@SPName, '_xtest', ''), '_xpre', ''), '_UAT1', ''), '_UAT2', ''), '_UAT3', ''), '_UAT4', '')

	SELECT @GroupHeadlineId = ISNULL(@GroupHeadlineId, 0), @Old_GroupHeadlineId = ISNULL(@Old_GroupHeadlineId, 0)
	
	IF @GroupHeadlineId = @Old_GroupHeadlineId
		RETURN

	DECLARE @CurrentDate DATETIME = CONVERT(DATE, GETDATE())
	DECLARE @EndDate DATETIME = DATEADD(DAY, -1, @CurrentDate)

	DECLARE @RoleId TINYINT, @SiteId INT, @ExchangeId INT, @UserName VARCHAR(50)

	SELECT @RoleId		= c.RoleId
		,@SiteId		= s.SiteId
		,@ExchangeId	= c.Currency
		,@UserName		= c.UserName
	FROM dbo.Customer c WITH (NOLOCK)
		INNER JOIN dbo.Site s WITH (NOLOCK) ON c.Site = s.Site
	WHERE c.CustId = @CustId

	IF NOT EXISTS (SELECT 1 FROM dbo.EaGroupHeadline WITH (NOLOCK) WHERE GroupHeadlineId IN (@GroupHeadlineId, @Old_GroupHeadlineId))
		RETURN

	DECLARE @ExternalGroup TABLE (GroupName VARCHAR(100), GroupTypeId TINYINT, EffectiveDate DATETIME, EndDate DATETIME, DataType TINYINT)
	-- DataType: 1 = insert, 2 = delete, 3 = add into queue

	-- Log for remove mapping
	DECLARE @EaGroupHeadline TABLE (GroupName VARCHAR(100), SiteId INT, Site VARCHAR(50), ExchangeId INT, Currency VARCHAR(50), GroupTypeId TINYINT, EffectiveDate DATETIME, EndDate DATETIME)
	
	-- EaGroupHeadline
	IF @GroupHeadlineId = 0 -- remove from group HL
	BEGIN
		INSERT INTO @ExternalGroup (GroupName, GroupTypeId, EffectiveDate, EndDate, DataType)
		SELECT GroupName, GroupTypeId, EffectiveDate, EndDate, 2 AS DataType -- remove super from External Group
		FROM dbo.EaGroupHeadline WITH (NOLOCK)
		WHERE GroupHeadlineId = @Old_GroupHeadlineId AND SiteId = @SiteId AND ExchangeId = @ExchangeId

		UPDATE @ExternalGroup
		SET GroupTypeId = 1, EffectiveDate = NULL, EndDate = NULL
		WHERE GroupTypeId = 2 AND EndDate < @CurrentDate

		DELETE @ExternalGroup WHERE GroupName = '' -- No Extra PT

		IF NOT EXISTS (SELECT 1 FROM dbo.CustAccount WITH (NOLOCK) WHERE GroupId = @Old_GroupHeadlineId)
			OR EXISTS (SELECT 1 FROM dbo.CustGroupHeadline WITH (NOLOCK) WHERE CustId = @CustId AND GroupId = @Old_GroupHeadlineId)
		BEGIN
			INSERT INTO @EaGroupHeadline (GroupName, SiteId, ExchangeId, GroupTypeId, EffectiveDate, EndDate)
			SELECT GroupName, SiteId, ExchangeId, GroupTypeId, EffectiveDate, EndDate
			FROM dbo.EaGroupHeadline WITH (NOLOCK)
			WHERE GroupHeadlineId = @Old_GroupHeadlineId

			DELETE dbo.EaGroupHeadline WITH (ROWLOCK, UPDLOCK)
			WHERE GroupHeadlineId = @Old_GroupHeadlineId
		END
	END
	ELSE -- add new or change group HL
	BEGIN
		INSERT INTO @ExternalGroup (GroupName, GroupTypeId, EffectiveDate, EndDate, DataType)
		SELECT GroupName, GroupTypeId, EffectiveDate, EndDate, 1 AS DataType -- add super into External Group
		FROM dbo.EaGroupHeadline WITH (NOLOCK)
		WHERE GroupHeadlineId = @GroupHeadlineId AND SiteId = @SiteId AND ExchangeId = @ExchangeId

		UPDATE @ExternalGroup
		SET GroupTypeId = 1, EffectiveDate = NULL, EndDate = NULL
		WHERE GroupTypeId = 2 AND EndDate < @CurrentDate

		UPDATE @ExternalGroup SET EffectiveDate = @CurrentDate WHERE GroupTypeId = 2 AND EffectiveDate <= @CurrentDate

		DELETE @ExternalGroup WHERE GroupName = '' -- No Extra PT
	END
	
	DECLARE @TrackingValue NVARCHAR(1000), @TrackingValue2 NVARCHAR(1000)
	
	-- Log Extra PT
	IF @RoleId = 4
	BEGIN
		DECLARE @ExtraPTGroup TABLE (GroupId INT, GroupName VARCHAR(100), FromDate DATETIME, ToDate DATETIME)
		INSERT INTO @ExtraPTGroup (GroupId, GroupName, FromDate, ToDate)
		SELECT GroupId, GroupName, MIN(FromDate), MAX(ToDate)
		FROM dbo.Acc_GroupExtraPTSetting WITH (NOLOCK)
		WHERE SuperId = @CustId
			AND ToDate >= @CurrentDate
		GROUP BY GroupId, GroupName

		WHILE 1 = 1
		BEGIN
			UPDATE eg
			SET eg.FromDate = e.FromDate
			FROM @ExtraPTGroup eg
				CROSS APPLY (
					SELECT MIN(e.FromDate) AS FromDate
					FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
					WHERE e.SuperId = @CustId AND eg.GroupId = e.GroupId
						AND e.ToDate = DATEADD(DAY, -1, eg.FromDate)
				) e
			WHERE e.FromDate IS NOT NULL

			IF @@ROWCOUNT = 0
				BREAK
		END

		SELECT @TrackingValue2 = '<' + @SPName + ' ExternalGroups="' + COALESCE(ExternalGroups, SPACE(1)) + '" ' +
																'PrimaryGroup="' + COALESCE(PrimaryExtraGroup, SPACE(1)) + '" />'
		FROM (
			SELECT
				STUFF((
					SELECT ', ' + cg.GroupName
					FROM dbo.Acc_CustGroup cg WITH (NOLOCK)
						INNER JOIN NAP_UserControl.dbo.EaGroup eg WITH (NOLOCK) ON cg.GroupName = eg.GroupName AND eg.ParentId = 0
						LEFT JOIN dbo.Acc_CustGroup_Queue q WITH (NOLOCK) ON cg.CustId = q.CustId AND cg.GroupName = q.GroupName
					WHERE cg.CustId = c.CustId AND q.CustId IS NULL
					FOR XML PATH ('')), 1, 2, '') AS ExternalGroups
				,STUFF((
					SELECT ', ' + e.GroupName + ': ' + CONVERT(VARCHAR(10), e.FromDate, 120) + ' - ' + CONVERT(VARCHAR(10), e.ToDate, 120)
					FROM @ExtraPTGroup e
					FOR XML PATH ('')), 1, 2, '') AS PrimaryExtraGroup
			FROM (VALUES(@CustId)) c (CustId)
		) t
	END

	-- Acc_GroupExtraPTSetting
	IF @RoleId = 4
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.Customer WHERE srecommend = @CustId AND RoleId = 1)
		BEGIN
			SELECT @EndDate = DATEADD(DAY, 1, @EndDate)

			UPDATE @ExternalGroup SET EffectiveDate = DATEADD(DAY, 1, EffectiveDate)
			WHERE EffectiveDate = @CurrentDate
				AND GroupTypeId = 2 AND DataType = 1
		END

		-- Remove future setting
		DELETE dbo.Acc_GroupExtraPTSetting WITH (ROWLOCK, UPDLOCK)
		WHERE SuperId = @CustId
			AND FromDate >= @currentDate
			AND (
				FromDate > @currentDate
				OR FromDate > @EndDate
			)

		DELETE dbo.Acc_GroupExtraPT2Setting WITH (ROWLOCK, UPDLOCK)
		WHERE SuperId = @CustId
			AND FromDate >= @currentDate
			AND (
				FromDate > @currentDate
				OR FromDate > @EndDate
			)

		-- Update current setting
		UPDATE e WITH (ROWLOCK)
		SET e.ToDate = CASE WHEN @EndDate < p.ToDate THEN @EndDate ELSE p.ToDate END
		FROM dbo.Acc_GroupExtraPTSetting e
			INNER JOIN dbo.Acc_GroupExtraPT_Product p WITH (NOLOCK)
				ON		e.GroupId		= p.GroupId
					AND e.ProductId		= p.ProductId
					AND e.Sporttype		= p.Sporttype
					AND e.SubProduct	= p.SubProduct
		WHERE e.SuperId = @CustId
			AND @EndDate BETWEEN p.FromDate AND p.ToDate
			AND @EndDate BETWEEN e.FromDate AND e.ToDate

		UPDATE e WITH (ROWLOCK)
		SET e.ToDate = CASE WHEN @EndDate < p.ToDate THEN @EndDate ELSE p.ToDate END
		FROM dbo.Acc_GroupExtraPT2Setting e
			INNER JOIN dbo.Acc_GroupExtraPT2_Product p WITH (NOLOCK)
				ON		e.GroupId		= p.GroupId
					AND e.ProductId		= p.ProductId
					AND e.Sporttype		= p.Sporttype
					AND e.SubProduct	= p.SubProduct
		WHERE e.SuperId = @CustId
			AND @EndDate BETWEEN p.FromDate AND p.ToDate
			AND @EndDate BETWEEN e.FromDate AND e.ToDate

		-- Add new setting
		IF EXISTS (SELECT 1 FROM @ExternalGroup WHERE GroupTypeId = 2 AND DataType = 1)
		BEGIN
			INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
			SELECT @CustId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate
			FROM (
				SELECT ep.GroupId, ep.GroupName, ep.ProductId, ep.Sporttype, ep.SubProduct, ep.ExtraPT
					,CASE WHEN eg.EffectiveDate < ep.FromDate THEN ep.FromDate ELSE eg.EffectiveDate END AS FromDate
					,CASE WHEN eg.EndDate < ep.ToDate THEN eg.EndDate ELSE ep.ToDate END AS ToDate
				FROM dbo.Acc_GroupExtraPT_Product ep WITH (NOLOCK)
					INNER JOIN @ExternalGroup eg ON ep.GroupName = eg.GroupName AND eg.DataType = 1
				WHERE eg.EffectiveDate <= ep.ToDate
			) t
			WHERE FromDate <= ToDate

			INSERT INTO dbo.Acc_GroupExtraPT2Setting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
			SELECT @CustId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate
			FROM (
				SELECT ep.GroupId, ep.GroupName, ep.ProductId, ep.Sporttype, ep.SubProduct, ep.ExtraPT
					,CASE WHEN eg.EffectiveDate < ep.FromDate THEN ep.FromDate ELSE eg.EffectiveDate END AS FromDate
					,CASE WHEN eg.EndDate < ep.ToDate THEN eg.EndDate ELSE ep.ToDate END AS ToDate
				FROM dbo.Acc_GroupExtraPT2_Product ep WITH (NOLOCK)
					INNER JOIN @ExternalGroup eg ON ep.GroupName = eg.GroupName AND eg.DataType = 1
				WHERE eg.EffectiveDate <= ep.ToDate
			) t
			WHERE FromDate <= ToDate
		END
	END

	-- Acc_CustGroup
	IF @RoleId = 4
	BEGIN
		IF @Old_GroupHeadlineId <> 0 AND @GroupHeadlineId <> 0 -- Move Group 
			INSERT INTO @ExternalGroup (GroupName, DataType)
			SELECT e.GroupName, 2 -- remove super from External Group
			FROM dbo.EaGroupHeadline e WITH (NOLOCK)
				LEFT JOIN @ExternalGroup eg ON e.GroupName = eg.GroupName
			WHERE e.GroupHeadlineId = @Old_GroupHeadlineId AND e.SiteId = @SiteId AND e.ExchangeId = @ExchangeId AND e.GroupName <> ''
				AND eg.GroupName IS NULL
			
		UPDATE e
		SET e.DataType = 3 -- add into queue to remove later
		FROM @ExternalGroup e
			INNER JOIN (
				SELECT DISTINCT GroupName
				FROM dbo.Acc_GroupExtraPTSetting WITH (NOLOCK)
				WHERE SuperId = @CustId AND ToDate = @CurrentDate
			) eg ON e.GroupName = eg.GroupName
		WHERE e.DataType = 2

		DELETE c WITH (ROWLOCK)
		FROM dbo.Acc_CustGroup c
			INNER JOIN @ExternalGroup e ON c.GroupName = e.GroupName
		WHERE c.CustId = @CustId AND e.DataType = 2

		INSERT INTO dbo.Acc_CustGroup (CustId, RoleId, GroupName)
		SELECT @CustId, 4, e.GroupName
		FROM @ExternalGroup e
			LEFT JOIN dbo.Acc_CustGroup c WITH (NOLOCK) ON c.CustId = @CustId AND e.GroupName = c.GroupName
		WHERE e.DataType = 1 AND c.CustId IS NULL

		DELETE q WITH (ROWLOCK)
		FROM dbo.Acc_CustGroup_Queue q
			INNER JOIN @ExternalGroup e ON q.GroupName = e.GroupName
		WHERE q.CustId = @CustId AND e.DataType = 1

		DELETE @ExternalGroup WHERE ISNULL(DataType, 0) <> 3

		MERGE dbo.Acc_CustGroup_Queue AS s
		USING @ExternalGroup AS t ON s.GroupName = t.GroupName AND s.CustId = @CustId
		WHEN MATCHED THEN UPDATE
			SET s.EndDate = @EndDate
		WHEN NOT MATCHED THEN INSERT
			(CustId, GroupName, EndDate)
			VALUES (@CustId, t.GroupName, @EndDate);

		IF EXISTS (SELECT 1 FROM @ExternalGroup)
			SET @AffectedSupers = @UserName
	END

	-- CustSuperProfile
	IF EXISTS (
		SELECT 1
		FROM dbo.EaGroupHeadline WITH (NOLOCK)
		WHERE GroupHeadlineId = @GroupHeadlineId AND SiteId = @SiteId AND ExchangeId = @ExchangeId AND GroupName <> '' AND @RoleId = 4
	)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.CustSuperProfile WITH (NOLOCK) WHERE CustId = @CustId)
			INSERT INTO dbo.CustSuperProfile (CustId)
			VALUES (@CustId)
	END

	-- Log for Extra PT
	IF @RoleId = 4
	BEGIN
		UPDATE eg
		SET eg.FromDate = e.FromDate, eg.ToDate = DATEADD(DAY, -1, @CurrentDate)
		FROM @ExtraPTGroup eg
			INNER JOIN (
				SELECT GroupName, MIN(FromDate) AS FromDate
				FROM dbo.Acc_GroupExtraPTSetting WITH (NOLOCK)
				WHERE SuperId = @CustId
					AND ToDate = DATEADD(DAY, -1, @CurrentDate) -- end yesterday
				GROUP BY GroupName
			) e ON eg.GroupName = e.GroupName

		DELETE @ExtraPTGroup WHERE ToDate >= @CurrentDate

		INSERT INTO @ExtraPTGroup (GroupId, GroupName, FromDate, ToDate)
		SELECT GroupId, GroupName, MIN(FromDate) AS FromDate, MAX(ToDate) AS ToDate
		FROM dbo.Acc_GroupExtraPTSetting WITH (NOLOCK)
		WHERE SuperId = @CustId
			AND ToDate >= @CurrentDate
		GROUP BY GroupId, GroupName

		DELETE e
		FROM (
			SELECT GroupName, ROW_NUMBER() OVER(PARTITION BY GroupName ORDER BY FromDate DESC) AS RN
			FROM @ExtraPTGroup e
		) e
		WHERE RN > 1

		WHILE 1 = 1
		BEGIN
			UPDATE eg
			SET eg.FromDate = e.FromDate
			FROM @ExtraPTGroup eg
				CROSS APPLY (
					SELECT MIN(e.FromDate) AS FromDate
					FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
					WHERE e.SuperId = @CustId AND eg.GroupId = e.GroupId
						AND e.ToDate = DATEADD(DAY, -1, eg.FromDate)
				) e
			WHERE e.FromDate IS NOT NULL

			IF @@ROWCOUNT = 0
				BREAK
		END

		SELECT @TrackingValue = '<' + @SPName + ' ExternalGroups="' + COALESCE(ExternalGroups, SPACE(1)) + '" ' +
																'PrimaryGroup="' + COALESCE(PrimaryExtraGroup, SPACE(1)) + '" />'
		FROM (
				SELECT
					STUFF((
						SELECT ', ' + cg.GroupName
						FROM dbo.Acc_CustGroup cg WITH (NOLOCK)
							INNER JOIN NAP_UserControl.dbo.EaGroup eg WITH (NOLOCK) ON cg.GroupName = eg.GroupName AND eg.ParentId = 0
							LEFT JOIN dbo.Acc_CustGroup_Queue q WITH (NOLOCK) ON cg.CustId = q.CustId AND cg.GroupName = q.GroupName
						WHERE cg.CustId = c.CustId AND q.CustId IS NULL
						FOR XML PATH ('')), 1, 2, '') AS ExternalGroups
					,STUFF((
						SELECT ', ' + e.GroupName + ': ' + CONVERT(VARCHAR(10), e.FromDate, 120) + ' - ' + CONVERT(VARCHAR(10), e.ToDate, 120)
						FROM @ExtraPTGroup e
						FOR XML PATH ('')), 1, 2, '') AS PrimaryExtraGroup
				FROM (VALUES(@CustId)) c (CustId)
			) t
	END

	IF @RoleId = 4
	BEGIN
		SET @Duration = DATEDIFF (MILLISECOND, @startRun, GETDATE())
		SELECT @ActionId = CASE
							WHEN 'Acc_CreditTermUpdAddToGroup' LIKE @SPName + '%' THEN 95053
							WHEN 'Acc_CreditTermUpdCustomer' LIKE @SPName + '%' THEN 95054
							ELSE 0 END

		IF ISNULL(@TrackingValue, '') = ''
			SELECT @TrackingValue = @TrackingValue2, @TrackingValue2 = ''

		IF ISNULL(@TrackingValue, '') <> ''
			EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId
				,@CustId			= @CustId
				,@ActionId			= @ActionId
				,@TrackingValue		= @TrackingValue
				,@TrackingValue2	= @TrackingValue2
				,@Duration			= @Duration
	END

	-- Log remove mapping
	IF EXISTS (SELECT 1 FROM @EaGroupHeadline)
	BEGIN
		SET @Duration = DATEDIFF (MILLISECOND, @startRun, GETDATE())

		UPDATE eg
		SET eg.Site = s.Site, eg.Currency = e.Currency
		FROM @EaGroupHeadline eg
			INNER JOIN dbo.Site s WITH (NOLOCK) ON eg.SiteId = s.SiteId
			INNER JOIN dbo.Exchange e WITH (NOLOCK) ON eg.ExchangeId = e.ExchangeId

		UPDATE @EaGroupHeadline SET GroupTypeId = 1 WHERE GroupTypeId = 2 AND EndDate < @CurrentDate

		DECLARE @Site VARCHAR(50), @Currency VARCHAR(50)

		WHILE EXISTS (SELECT 1 FROM @EaGroupHeadline)
		BEGIN
			SELECT TOP 1 @SiteId = SiteId, @Site = Site, @ExchangeId = ExchangeId, @Currency = Currency FROM @EaGroupHeadline
			
			SELECT @TrackingValue = '<' + @SPName + ' Site="' + COALESCE(@Site, SPACE(1)) + '" ' +
													'Currency="' + COALESCE(@Currency, SPACE(1)) + '" ' +
													'PrimaryGroup="' + COALESCE(PrimaryExtraGroup, SPACE(1)) + '" ' +
													'HeadlineId="' + COALESCE(CONVERT(VARCHAR(20), @Old_GroupHeadlineId), SPACE(1)) + '" ' +
													'ExternalGroups="' + COALESCE(ExternalGroups, SPACE(1)) + '" />'
			FROM (
				SELECT STUFF((SELECT ', ' + GroupName FROM @EaGroupHeadline WHERE SiteId = @SiteId AND ExchangeId = @ExchangeId AND GroupName <> '' FOR XML PATH('')), 1, 2, '') AS ExternalGroups
				,STUFF((SELECT ', ' + ISNULL(NULLIF(GroupName, ''), 'No Extra PT') + ': ' + CONVERT(VARCHAR(10), EffectiveDate, 120) + ' - ' + + CONVERT(VARCHAR(10), EndDate, 120) FROM @EaGroupHeadline WHERE SiteId = @SiteId AND ExchangeId = @ExchangeId AND GroupTypeId = 2 FOR XML PATH('')), 1, 2, '') AS PrimaryExtraGroup
			) e

			EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId			= @UserId
				,@CustId		= @HeadlineId
				,@ActionId		= 95056
				,@TrackingValue = @TrackingValue
				,@Duration		= @Duration

			DELETE @EaGroupHeadline WHERE SiteId = @SiteId AND ExchangeId = @ExchangeId
		END
	END
END
GO