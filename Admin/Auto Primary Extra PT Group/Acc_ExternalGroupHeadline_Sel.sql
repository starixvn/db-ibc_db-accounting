/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Acc_ExternalGroupHeadline_Sel]
	@GroupHeadlineId		INT = 0
	,@HeadlineName			VARCHAR(50) = ''
	,@SiteIds				VARCHAR(MAX)
	,@ExchangeIds			VARCHAR(MAX)
	,@ExternalGroups		VARCHAR(MAX) = ''
	,@PrimaryExtraGroups	VARCHAR(MAX) = ''
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

	DECLARE @CurrentDate DATETIME = CONVERT(DATE, GETDATE())

	DECLARE @EaGroupHeadline TABLE
	(
		GroupHeadlineId INT
		,HeadlineName VARCHAR(50)
		,SiteId INT
		,Site VARCHAR(100)
		,ExchangeId INT
		,Currency VARCHAR(50)
		,IsPrimary BIT
	)

	IF ISNULL(@GroupHeadlineId, 0) = 0 AND ISNULL(@HeadlineName, '') = ''
	BEGIN
		INSERT INTO @EaGroupHeadline (GroupHeadlineId, HeadlineName, SiteId, Site, ExchangeId, Currency)
		SELECT GroupHeadlineId, UserName, SiteId, Site, ExchangeId, Currency
		FROM (
			SELECT GroupHeadlineId, UserName, SiteId, Site, ExchangeId, Currency
				,MAX(CASE WHEN @PrimaryExtraGroups = 'all' OR (GroupTypeId = 2 AND ',' + @PrimaryExtraGroups + ',' LIKE '%,' + GroupName + ',%') THEN 1 ELSE 0 END) AS IsPrimary
				,MAX(CASE WHEN ',' + @ExternalGroups + ',' LIKE '%,' + GroupName + ',%' THEN 1 ELSE 0 END) AS IsExternal
			FROM (
				SELECT egh.GroupHeadlineId, c.UserName, egh.SiteId, s.Site, egh.ExchangeId, e.Currency
					,ISNULL(NULLIF(egh.GroupName, ''), 'No Extra PT') AS GroupName
					,CASE WHEN egh.GroupTypeId = 2 AND egh.EndDate < @CurrentDate THEN 1 ELSE egh.GroupTypeId END AS GroupTypeId
				FROM dbo.EaGroupHeadline egh WITH (NOLOCK)
					INNER JOIN dbo.CustGroupHeadline cda WITH (NOLOCK) ON egh.GroupHeadlineId = cda.GroupId
					INNER JOIN dbo.Customer c WITH (NOLOCK) ON cda.CustId = c.CustId
					INNER JOIN dbo.Exchange e WITH (NOLOCK) ON egh.ExchangeId = e.ExchangeId
					INNER JOIN dbo.Site s WITH (NOLOCK) ON egh.SiteId = s.SiteId
				WHERE ',' + @SiteIds + ',' LIKE '%,' + CONVERT(VARCHAR(15), egh.SiteId) + ',%'
					AND ',' + @ExchangeIds + ',' LIKE '%,' + CONVERT(VARCHAR(15), egh.ExchangeId) + ',%'
					AND 1 = CASE
								WHEN egh.GroupName <> '' THEN 1
								WHEN egh.GroupTypeId = 1 THEN 0
								WHEN egh.EndDate < @CurrentDate THEN 0
								ELSE 1 END
			) t
			WHERE (
					(@PrimaryExtraGroups = 'all' OR (GroupTypeId = 2 AND ',' + @PrimaryExtraGroups + ',' LIKE '%,' + GroupName + ',%'))
					OR (',' + @ExternalGroups + ',' LIKE '%,' + GroupName + ',%')
				)
			GROUP BY GroupHeadlineId, UserName, SiteId, Site, ExchangeId, Currency
		) e
		WHERE IsPrimary = 1 AND IsExternal = 1
	END
	ELSE
	BEGIN
		IF ISNULL(@HeadlineName, '') <> ''
			SELECT @GroupHeadlineId = cda.GroupId
			FROM dbo.Customer c WITH (NOLOCK)
				INNER JOIN dbo.CustGroupHeadline cda WITH (NOLOCK) ON c.CustId = cda.CustId
			WHERE c.UserName = @HeadlineName

		INSERT INTO @EaGroupHeadline (GroupHeadlineId, HeadlineName, SiteId, Site, ExchangeId, Currency)
		SELECT GroupHeadlineId, UserName, SiteId, Site, ExchangeId, Currency
		FROM (
			SELECT GroupHeadlineId, UserName, SiteId, Site, ExchangeId, Currency
				,MAX(CASE WHEN @PrimaryExtraGroups = 'all' OR (GroupTypeId = 2 AND ',' + @PrimaryExtraGroups + ',' LIKE '%,' + GroupName + ',%') THEN 1 ELSE 0 END) AS IsPrimary
				,MAX(CASE WHEN ',' + @ExternalGroups + ',' LIKE '%,' + GroupName + ',%' THEN 1 ELSE 0 END) AS IsExternal
			FROM (
				SELECT egh.GroupHeadlineId, c.UserName, egh.SiteId, s.Site, egh.ExchangeId, e.Currency
					,ISNULL(NULLIF(egh.GroupName, ''), 'No Extra PT') AS GroupName
					,CASE WHEN egh.GroupTypeId = 2 AND egh.EndDate < @CurrentDate THEN 1 ELSE egh.GroupTypeId END AS GroupTypeId
				FROM dbo.EaGroupHeadline egh WITH (NOLOCK)
					INNER JOIN dbo.CustGroupHeadline cda WITH (NOLOCK) ON egh.GroupHeadlineId = cda.GroupId
					INNER JOIN dbo.Customer c WITH (NOLOCK) ON cda.CustId = c.CustId
					INNER JOIN dbo.Exchange e WITH (NOLOCK) ON egh.ExchangeId = e.ExchangeId
					INNER JOIN dbo.Site s WITH (NOLOCK) ON egh.SiteId = s.SiteId
				WHERE egh.GroupHeadlineId = @GroupHeadlineId
					AND ',' + @SiteIds + ',' LIKE '%,' + CONVERT(VARCHAR(15), egh.SiteId) + ',%'
					AND ',' + @ExchangeIds + ',' LIKE '%,' + CONVERT(VARCHAR(15), egh.ExchangeId) + ',%'
					AND 1 = CASE
								WHEN egh.GroupName <> '' THEN 1
								WHEN egh.GroupTypeId = 1 THEN 0
								WHEN egh.EndDate < @CurrentDate THEN 0
								ELSE 1 END
			) t
			WHERE (
					(@PrimaryExtraGroups = 'all' OR (GroupTypeId = 2 AND ',' + @PrimaryExtraGroups + ',' LIKE '%,' + GroupName + ',%'))
					OR (',' + @ExternalGroups + ',' LIKE '%,' + GroupName + ',%')
				)
			GROUP BY GroupHeadlineId, UserName, SiteId, Site, ExchangeId, Currency
		) e
		WHERE IsPrimary = 1 AND IsExternal = 1
	END

	;WITH CTE_Data AS
	(
		SELECT GroupHeadlineId, HeadlineName, SiteId, Site, ExchangeId, Currency, GroupName, GroupTypeId, EffectiveDate, EndDate
			,ROW_NUMBER() OVER(PARTITION BY GroupHeadlineId, SiteId, ExchangeId
								ORDER BY CASE WHEN EffectiveDate > @CurrentDate OR GroupTypeId <> 2 THEN 1 ELSE 0 END, EffectiveDate DESC) AS RN
		FROM (
			SELECT t.GroupHeadlineId, t.HeadlineName, t.SiteId, t.Site, t.ExchangeId, t.Currency, egh.GroupName
				,CASE WHEN egh.GroupTypeId = 2 AND egh.EndDate < @CurrentDate THEN 1 ELSE egh.GroupTypeId END AS GroupTypeId
				,CASE WHEN egh.GroupTypeId = 2 AND egh.EndDate >= @CurrentDate THEN egh.EffectiveDate ELSE NULL END AS EffectiveDate
				,CASE WHEN egh.GroupTypeId = 2 AND egh.EndDate >= @CurrentDate THEN egh.EndDate ELSE NULL END AS EndDate
			FROM @EaGroupHeadline t
				INNER JOIN dbo.EaGroupHeadline egh WITH (NOLOCK) ON t.GroupHeadlineId = egh.GroupHeadlineId AND t.SiteId = egh.SiteId AND t.ExchangeId = egh.ExchangeId
			WHERE 1 = CASE
						WHEN egh.GroupName <> '' THEN 1
						WHEN egh.GroupTypeId = 1 THEN 0
						WHEN egh.EndDate < @CurrentDate THEN 0
						ELSE 1 END
		) t
	)
	SELECT GroupHeadlineId, HeadlineName, SiteId, Site, ExchangeId, Currency
		,STUFF((SELECT ', ' + d2.GroupName
				FROM CTE_Data d2
				WHERE d2.GroupHeadlineId = d1.GroupHeadlineId AND d2.SiteId = d1.SiteId AND d2.ExchangeId = d1.ExchangeId
					AND d2.GroupTypeId = 0
				FOR XML PATH('')), 1, 1, '') AS NormalGroup
		,STUFF((SELECT ', ' + d2.GroupName
				FROM CTE_Data d2
				WHERE d2.GroupHeadlineId = d1.GroupHeadlineId AND d2.SiteId = d1.SiteId AND d2.ExchangeId = d1.ExchangeId
					AND d2.GroupTypeId IN (1, 2) AND d2.GroupName <> ''
				FOR XML PATH('')), 1, 2, '') AS ExtraPTGroup
		,STUFF((SELECT ', ' + ISNULL(NULLIF(d2.GroupName, ''), 'No Extra PT') + ISNULL('(' + CONVERT(VARCHAR(10), d2.EffectiveDate, 101) + ' - ' + CONVERT(VARCHAR(10), d2.EndDate, 101) + ')', '')
				FROM CTE_Data d2
				WHERE d2.GroupHeadlineId = d1.GroupHeadlineId AND d2.SiteId = d1.SiteId AND d2.ExchangeId = d1.ExchangeId
					AND d2.GroupTypeId = 2
				FOR XML PATH('')), 1, 2, '') AS PrimaryExtraPTGroup
		,STUFF((SELECT ', ' + ISNULL(NULLIF(d2.GroupName, ''), 'No Extra PT')
				FROM CTE_Data d2
				WHERE d2.GroupHeadlineId = d1.GroupHeadlineId AND d2.SiteId = d1.SiteId AND d2.ExchangeId = d1.ExchangeId
					AND d2.GroupTypeId = 2 AND d2.RN = 1
				FOR XML PATH('')), 1, 2, '') AS CurrentPrimaryExtraPTGroup
		,STUFF((SELECT ', ' + CONVERT(VARCHAR(10), d2.EffectiveDate, 101)
				FROM CTE_Data d2
				WHERE d2.GroupHeadlineId = d1.GroupHeadlineId AND d2.SiteId = d1.SiteId AND d2.ExchangeId = d1.ExchangeId
					AND d2.GroupTypeId = 2 AND d2.RN = 1
				FOR XML PATH('')), 1, 2, '') AS CurrentEffectiveDate
	FROM CTE_Data d1
	GROUP BY GroupHeadlineId, HeadlineName, SiteId, Site, ExchangeId, Currency
END
GO