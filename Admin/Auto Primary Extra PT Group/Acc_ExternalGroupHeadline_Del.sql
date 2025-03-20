/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Acc_ExternalGroupHeadline_Del]
	@UserId				INT
	,@GroupHeadlineId	INT
	,@SiteId			INT
	,@ExchangeId		INT
	,@ExternalGroups	VARCHAR(MAX)
	,@PrimaryExtraGroup	VARCHAR(100) = ''
	,@IP				VARCHAR(20)
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			VARCHAR(2000) = '' OUTPUT
	,@AffectedSupers	VARCHAR(MAX) = '' OUTPUT
AS

/*
	Created: 20210302@Percy
	DB: DBCUST-CustDB
	Task: Auto Set Primary Extra PT Group

	Revisions:
		- 20210302@Percy: Initialize SP [RemineID: #146710]
		- 20220509@Danny: Use String_split built-in function [RemineID: #171831]
		- 20241231@Hughie: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
		- 20250114@Lewis: Apply Rep-Inhouse [RedmineID: #215883]
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
	DECLARE @MaxDate DATETIME = '9999-12-31'
	DECLARE @AllPrimaryGroups VARCHAR(MAX)

	DECLARE @Site VARCHAR(50), @Currency VARCHAR(50)
	SELECT  @Site = Site FROM dbo.Site WITH (NOLOCK) WHERE SiteId = @SiteId
	SELECT  @Currency = Currency FROM dbo.Exchange WITH (NOLOCK) WHERE ExchangeId = @ExchangeId

	DECLARE @EaGroup TABLE (GroupId INT, GroupExtraPTId INT, GroupName VARCHAR(100), GroupTypeId TINYINT)
	INSERT INTO @EaGroup (GroupName, GroupTypeId)
	SELECT value, 0 FROM STRING_SPLIT(@ExternalGroups, ',')

	UPDATE t
	SET t.GroupId = e.GroupId
	FROM @EaGroup t
		INNER JOIN NAP_UserControl.dbo.EaGroup e WITH (NOLOCK) ON t.GroupName = e.GroupName

	IF EXISTS (SELECT 1 FROM @EaGroup WHERE GroupId IS NULL)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid External Group.'
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
			SELECT @ErrCode = 102, @ErrMsg = 'Invalid Primary Extra PT Group.'
			RETURN
		END
	END
	
	SELECT @AllPrimaryGroups = COALESCE(@AllPrimaryGroups + ', ', '') + CASE WHEN GroupName = '' THEN 'No Extra PT' ELSE GroupName END + ': ' + CONVERT(VARCHAR(10), EffectiveDate, 120)
	FROM dbo.EaGroupHeadline WITH (NOLOCK)
	WHERE GroupHeadlineId = @GroupHeadlineId AND SiteId = @SiteId AND ExchangeId = @ExchangeId
		AND GroupTypeId = 2 AND EndDate >= @currentDate

	IF NOT EXISTS (
		SELECT 1
		FROM dbo.EaGroupHeadline WITH (NOLOCK)
		WHERE GroupHeadlineId = @GroupHeadlineId AND SiteId = @SiteId AND ExchangeId = @ExchangeId
	)
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'The Headline/External Group Mapping does not exist.'
		RETURN
	END

	UPDATE e
	SET e.GroupTypeId = CASE WHEN egh.GroupTypeId = 2 AND egh.EndDate < @currentDate THEN 1 ELSE egh.GroupTypeId END
	FROM @EaGroup e
		INNER JOIN dbo.EaGroupHeadline egh WITH (NOLOCK) ON e.GroupName = egh.GroupName
	WHERE egh.GroupHeadlineId = @GroupHeadlineId AND egh.SiteId = @SiteId AND egh.ExchangeId = @ExchangeId

	-- List Super under Headline
	CREATE TABLE #Super (CustId INT NOT NULL, GroupExtraPTId INT, GroupName VARCHAR(100) NOT NULL, GroupTypeId TINYINT, EffectiveDate DATETIME, EndDate DATETIME, DataType TINYINT DEFAULT(1), PRIMARY KEY (CustId, GroupName))
	
	INSERT INTO #Super (CustId, GroupExtraPTId, GroupName, GroupTypeId, EndDate)
	SELECT s.CustId, e.GroupExtraPTId, e.GroupName, e.GroupTypeId, CASE WHEN e.GroupTypeId = 2 THEN DATEADD(DAY, -1, @currentDate) END
	FROM (
		SELECT s.CustId
		FROM dbo.CustAccount ca WITH (NOLOCK)
			INNER JOIN dbo.Customer s WITH (NOLOCK) ON ca.CustId = s.CustId
			INNER JOIN dbo.CustInfo c WITH (NOLOCK) ON s.CustId = c.CustId AND c.Enabled = 1
		WHERE ca.GroupId = @GroupHeadlineId AND s.Site = @Site AND s.Currency = @ExchangeId
			AND s.RoleId = 4
	) s
		CROSS JOIN @EaGroup e

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
		SELECT CustId, '<Acc_ExternalGroupHeadline_Del ExternalGroups="' + COALESCE(ExternalGroups, SPACE(1)) + '" ' + 'PrimaryGroup="' + COALESCE(PrimaryExtraGroup, SPACE(1)) + '" />'
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

	-- Delete mapping
	BEGIN TRY
		DELETE dbo.EaGroupHeadline WITH (ROWLOCK, UPDLOCK)
			OUTPUT DELETED.GroupHeadlineId, DELETED.GroupId, DELETED.GroupName, DELETED.SiteId, DELETED.ExchangeId, [dbo].[f_GetDateTime2]()
			INTO EaGroupHeadline_Del_Inhouse (GroupHeadlineId, GroupId, GroupName, SiteId, ExchangeId, RepUpdatetime)
		WHERE GroupHeadlineId = @GroupHeadlineId AND SiteId = @SiteId AND ExchangeId = @ExchangeId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = 'Remove Headline/External Group Mapping falied.'
		RETURN
	END CATCH

	-- Extra PT Setting
	IF EXISTS (SELECT 1 FROM #Super WHERE GroupTypeId = 2)
	BEGIN
		UPDATE s
		SET s.EndDate = DATEADD(DAY, 1, s.EndDate)
		FROM #Super s
		WHERE s.GroupTypeId = 2
			AND EXISTS (SELECT c.CustId FROM dbo.Customer c WITH (NOLOCK) WHERE s.CustId = c.srecommend AND c.RoleId = 1)

		UPDATE s
		SET s.EffectiveDate = e.EffectiveDate
		FROM #Super s
			CROSS APPLY (
				SELECT MIN(e.FromDate) AS EffectiveDate
				FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
				WHERE e.SuperId = s.CustId AND e.GroupName = s.GroupName
					AND e.ToDate >= @currentDate
			) e
		WHERE s.GroupTypeId = 2

		-- Remove future setting
		DELETE e WITH (ROWLOCK, UPDLOCK)
			OUTPUT deleted.ID, [dbo].[f_GetDateTime2]()
			INTO Acc_GroupExtraPTSetting_Del_InHouse (ID, RepUpdateTime)
		FROM dbo.Acc_GroupExtraPTSetting e
			INNER JOIN #Super s ON e.SuperId = s.CustId AND e.GroupName = s.GroupName
		WHERE s.GroupTypeId = 2
			AND e.FromDate >= @currentDate
			AND (
				e.FromDate > @currentDate
				OR e.FromDate > s.EndDate
			)

		DELETE e WITH (ROWLOCK, UPDLOCK)
			OUTPUT deleted.ID, [dbo].[f_GetDateTime2]()
			INTO Acc_GroupExtraPT2Setting_Del_InHouse (ID, RepUpdateTime)
		FROM dbo.Acc_GroupExtraPT2Setting e
			INNER JOIN #Super s ON e.SuperId = s.CustId AND e.GroupName = s.GroupName
		WHERE s.GroupTypeId = 2
			AND e.FromDate >= @currentDate
			AND (
				e.FromDate > @currentDate
				OR e.FromDate > s.EndDate
			)

		-- Close current setting
		UPDATE e WITH (ROWLOCK)
		SET e.ToDate = s.EndDate, e.RepUpdateTime = [dbo].[f_GetDateTime2]()
		FROM dbo.Acc_GroupExtraPTSetting e
			INNER JOIN #Super s ON e.SuperId = s.CustId AND e.GroupName = s.GroupName
		WHERE s.GroupTypeId = 2
			AND e.ToDate >= @currentDate

		UPDATE e WITH (ROWLOCK)
		SET e.ToDate = s.EndDate, e.RepUpdateTime = [dbo].[f_GetDateTime2]()
		FROM dbo.Acc_GroupExtraPT2Setting e
			INNER JOIN #Super s ON e.SuperId = s.CustId AND e.GroupName = s.GroupName
		WHERE s.GroupTypeId = 2
			AND e.ToDate >= @currentDate
	END

	-- Acc_CustGroup
	IF EXISTS (SELECT 1 FROM #Super)
	BEGIN
		-- DataType: 1: delete, 2: remove at the end of today
		UPDATE s
		SET s.EndDate = @currentDate, s.DataType = ISNULL(e.DataType, 1)
		FROM #Super s
			OUTER APPLY (
				SELECT TOP 1 CONVERT(TINYINT, 2) AS DataType
				FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
				WHERE e.SuperId = s.CustId AND e.GroupName = s.GroupName
					AND e.ToDate = @currentDate
				ORDER BY e.FromDate
			) e
		WHERE s.GroupName <> '' -- No Extra PT

		-- Remove supers from old normal groups
		DELETE c WITH (ROWLOCK, UPDLOCK)
		OUTPUT DELETED.custid, DELETED.GroupName, dbo.f_GetDateTime2()
		INTO Acc_CustGroup_Del_Inhouse(custid,GroupName,RepUpdateTime)
		FROM dbo.Acc_CustGroup c
			INNER JOIN #Super s ON c.CustId = s.CustId AND c.GroupName = s.GroupName
		WHERE s.DataType = 1

		-- Will remove supers from old extra pt groups at the end of today
		SET @AffectedSupers = NULL
		SELECT @AffectedSupers = COALESCE(@AffectedSupers + ',', '') + c.UserName
		FROM (SELECT DISTINCT CustId FROM #Super WHERE DataType = 2) s
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON s.CustId = c.CustId

		SELECT @AffectedSupers = ISNULL(@AffectedSupers, '')

		MERGE dbo.Acc_CustGroup_Queue AS t
		USING (SELECT DISTINCT CustId, GroupName, EndDate FROM #Super WHERE DataType = 2) AS s ON t.CustId = s.CustId AND t.GroupName = s.GroupName
		WHEN MATCHED THEN UPDATE
			SET t.EndDate = s.EndDate
		WHEN NOT MATCHED THEN INSERT
			(CustId, GroupName, EndDate)
			VALUES (s.CustId, s.GroupName, s.EndDate);

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
		SELECT CustId, '<Acc_ExternalGroupHeadline_Del ExternalGroups="' + COALESCE(ExternalGroups, SPACE(1)) + '" ' + 'PrimaryGroup="' + COALESCE(PrimaryExtraGroup, SPACE(1)) + '" />'
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
	DECLARE @TrackingValue NVARCHAR(1000), @TrackingValue2 NVARCHAR(1000)
	SET @Duration = DATEDIFF (MILLISECOND, @startRun, GETDATE())

	DECLARE @CustId INT

	-- Log for Headline
	SELECT @CustId = CustId FROM dbo.CustGroupHeadline WITH (NOLOCK) WHERE GroupId = @GroupHeadlineId
	SELECT @TrackingValue = '<Acc_ExternalGroupHeadline_Del Site="' + COALESCE(@Site, SPACE(1)) + '" ' +
															'Currency="' + COALESCE(@Currency, SPACE(1)) + '" ' +
															'PrimaryGroup="' + COALESCE(@AllPrimaryGroups, SPACE(1)) + '" ' +
															'HeadlineId="' + COALESCE(CONVERT(VARCHAR(20), @GroupHeadlineId), SPACE(1)) + '" ' +
															'ExternalGroups="' + COALESCE(@ExternalGroups, SPACE(1)) + '" />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId			= @UserId
		,@CustId		= @CustId
		,@ActionId		= 95043
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
				,@ActionId			= 95052
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