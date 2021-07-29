/*<info serverAlias="DBCUST-CustDB"></info>*/
/*
	Created: 20210301@Percy
	DB: DBCUST-CustDB
	Task: Initialize data for new table
*/
USE CustDB
GO

DECLARE @currentDate DATETIME = CONVERT(DATE, GETDATE())

-- Get Headline - Super
CREATE TABLE #GroupHeadline (GroupHeadlineId INT, SiteId INT, ExchangeId INT, ExternalGroup VARCHAR(50), PrimaryExtraPTGroup VARCHAR(50), FromDate DATETIME, ToDate DATETIME)
INSERT INTO #GroupHeadline (GroupHeadlineId, SiteId, ExchangeId, ExternalGroup, PrimaryExtraPTGroup, FromDate, ToDate)
SELECT cgh.GroupId AS GroupHeadlineId, ss.SiteId, s.Currency, cg.GroupName, e.GroupName, MIN(e.FromDate) AS FromDate, MAX(e.ToDate) AS ToDate
FROM dbo.CustGroupHeadline cgh WITH (NOLOCK)
	INNER JOIN dbo.Customer ch WITH (NOLOCK) ON cgh.CustId = ch.CustId --AND ch.Currency <> 20 -- Headline
	INNER JOIN dbo.CustAccount ca WITH (NOLOCK) ON cgh.GroupId = ca.GroupId AND cgh.GroupId <> 0
	INNER JOIN dbo.Customer s WITH (NOLOCK) ON ca.CustId = s.CustId AND s.RoleId = 4 --AND s.Currency <> 20 -- Super
	INNER JOIN dbo.CustInfo ci WITH (NOLOCK) ON s.CustId = ci.CustId AND ci.Enabled = 1
	INNER JOIN dbo.Site ss WITH (NOLOCK) ON s.site = ss.site
	INNER JOIN dbo.Acc_CustGroup cg WITH (NOLOCK) ON s.CustId = cg.CustId
	INNER JOIN NAP_UserControl.dbo.EaGroup eg WITH (NOLOCK) ON cg.GroupName = eg.GroupName AND ISNULL(eg.ParentId, 0) = 0
	INNER JOIN (
		SELECT SuperId, GroupName, MIN(FromDate) AS FromDate, MAX(ToDate) AS ToDate
		FROM dbo.Acc_GroupExtraPTSetting WITH (NOLOCK)
		WHERE @currentDate < ToDate
		GROUP BY SuperId, GroupName
	) e ON s.CustId = e.SuperId
WHERE s.site <> 'CN88'
	AND (s.site <> 'EU88' OR s.Currency <> 78)
GROUP BY cgh.GroupId, ss.SiteId, s.Currency, cg.GroupName, e.GroupName

CREATE TABLE #EaGroupHeadline (GroupHeadlineId INT, GroupId INT, GroupName VARCHAR(50), SiteId INT, ExchangeId INT, GroupTypeId TINYINT, EffectiveDate DATETIME, EndDate DATETIME)
INSERT INTO #EaGroupHeadline (GroupHeadlineId, GroupId, GroupName, SiteId, ExchangeId, GroupTypeId, EffectiveDate, EndDate)
SELECT t.GroupHeadlineId, g.GroupId, t.GroupName, t.SiteId, t.ExchangeId
	,CASE WHEN t.GroupTypeId = 0 AND e.GroupName IS NOT NULL THEN 1 ELSE t.GroupTypeId END AS GroupTypeId
	,MIN(t.FromDate) AS EffectiveDate
	,MAX(t.ToDate) AS EndDate
FROM (
	SELECT cg.GroupHeadlineId, cg.SiteId, cg.ExchangeId, g.GroupName, g.GroupTypeId, g.FromDate, g.ToDate
	FROM #GroupHeadline cg
		CROSS APPLY (
			SELECT PrimaryExtraPTGroup AS GroupName, FromDate, ToDate, CONVERT(TINYINT, 2) AS GroupTypeId
			UNION
			SELECT ExternalGroup, NULL, NULL, 0 WHERE ExternalGroup <> PrimaryExtraPTGroup
		) g
) t
	INNER JOIN NAP_UserControl.dbo.EaGroup g WITH (NOLOCK) ON t.GroupName = g.GroupName AND ISNULL(g.ParentId, 0) = 0
	LEFT JOIN dbo.Acc_DWLList_ExtraPT e WITH (NOLOCK) ON t.GroupName = e.GroupName
GROUP BY t.GroupHeadlineId, g.GroupId, t.GroupName, t.SiteId, t.ExchangeId
	,CASE WHEN t.GroupTypeId = 0 AND e.GroupName IS NOT NULL THEN 1 ELSE t.GroupTypeId END

DELETE e1
FROM #EaGroupHeadline e1
	INNER JOIN #EaGroupHeadline e2 ON e1.GroupHeadlineId = e2.GroupHeadlineId AND e1.SiteId = e2.SiteId AND e1.ExchangeId = e2.ExchangeId
WHERE e1.GroupTypeId = 1 AND e2.GroupTypeId = 2 AND e1.GroupName = e2.GroupName

DELETE e
FROM (
	SELECT *,ROW_NUMBER() OVER(PARTITION BY GroupHeadlineId, GroupName, SiteId, ExchangeId ORDER BY EffectiveDate) AS RN
	FROM #EaGroupHeadline
	WHERE GroupTypeId = 2
) e
WHERE RN > 1

MERGE dbo.EaGroupHeadline AS t
USING #EaGroupHeadline AS s
	ON t.GroupHeadlineId = s.GroupHeadlineId AND t.GroupName = s.GroupName AND t.SiteId = s.SiteId AND t.ExchangeId = s.ExchangeId
WHEN MATCHED THEN UPDATE
	SET t.GroupTypeId = s.GroupTypeId, t.EffectiveDate = s.EffectiveDate, t.EndDate = s.EndDate
WHEN NOT MATCHED BY TARGET THEN INSERT
	(GroupHeadlineId, GroupId, GroupName, SiteId, ExchangeId, GroupTypeId, EffectiveDate, EndDate)
	VALUES (GroupHeadlineId, GroupId, GroupName, SiteId, ExchangeId, GroupTypeId, EffectiveDate, EndDate)
WHEN NOT MATCHED BY SOURCE THEN DELETE;

DROP TABLE #EaGroupHeadline
DROP TABLE #GroupHeadline