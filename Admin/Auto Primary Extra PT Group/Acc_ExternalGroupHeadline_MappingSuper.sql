/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Acc_ExternalGroupHeadline_MappingSuper]
	@UserNames	VARCHAR(MAX) = '' -- list of super name
	,@GroupId	INT
AS

/*
	Created: 20210302@Percy
	DB: DBCUST-CustDB
	Task: Auto Set Primary Extra PT Group - Check Mapping Super

	Revisions:
		- 20210302@Percy: Initialize SP [RemineID: #146710]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @currentDate DATETIME = CONVERT(DATE, GETDATE())
	DECLARE @newExtraPTGroup VARCHAR(50)

	DECLARE @Supers TABLE (CustId INT, ExchangeId INT, Currency VARCHAR(50), SiteId INT, Site VARCHAR(100), UserName VARCHAR(30))
	INSERT INTO @Supers (UserName)
	SELECT DISTINCT LTRIM(RTRIM(val)) FROM dbo.strSplit(@UserNames, ',')

	UPDATE s
	SET s.CustId = c.CustId
		,s.ExchangeId = e.ExchangeId
		,s.Currency = e.Currency
		,s.SiteId = ss.SiteId
		,s.Site = ss.Site
	FROM @Supers s
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON s.UserName = c.UserName
		INNER JOIN dbo.CustInfo i WITH (NOLOCK) ON c.CustId = i.CustId AND i.Enabled = 1
		INNER JOIN dbo.Exchange e WITH (NOLOCK) ON c.Currency = e.ExchangeId
		INNER JOIN dbo.Site ss WITH (NOLOCK) ON c.Site = ss.Site
	WHERE c.RoleId = 4

	DELETE @Supers WHERE CustId IS NULL

	;WITH CTE_Data AS
	(
		SELECT UserName, SiteId, Site, ExchangeId, Currency, GroupName, GroupTypeId, EffectiveDate
		FROM (
			SELECT s.UserName, s.SiteId, s.Site, s.ExchangeId, s.Currency, egh.GroupName
				,CASE WHEN egh.GroupTypeId = 2 AND egh.EndDate < @CurrentDate THEN 1 ELSE egh.GroupTypeId END AS GroupTypeId
				,CASE WHEN egh.GroupTypeId = 2 AND egh.EndDate >= @CurrentDate THEN egh.EffectiveDate ELSE NULL END AS EffectiveDate
			FROM @Supers s
				INNER JOIN dbo.EaGroupHeadline egh WITH (NOLOCK) ON egh.GroupHeadlineId = @GroupId AND s.SiteId = egh.SiteId AND s.ExchangeId = egh.ExchangeId
			WHERE 1 = CASE
						WHEN egh.GroupName <> '' THEN 1
						WHEN egh.GroupTypeId = 1 THEN 0
						WHEN egh.EndDate < @CurrentDate THEN 0
						ELSE 1 END
		) t
	)
	SELECT UserName, SiteId, Site, ExchangeId, Currency
		,STUFF((SELECT ', ' + d2.GroupName
				FROM CTE_Data d2
				WHERE d2.UserName = d1.UserName
					AND d2.GroupTypeId = 0
				FOR XML PATH('')), 1, 2, '') AS NormalGroup
		,STUFF((SELECT ', ' + d2.GroupName
				FROM CTE_Data d2
				WHERE d2.UserName = d1.UserName
					AND d2.GroupTypeId IN (1, 2) AND d2.GroupName <> ''
				FOR XML PATH('')), 1, 2, '') AS ExtraPTGroup
		,STUFF((SELECT ', ' + ISNULL(NULLIF(d2.GroupName, ''), 'No Extra PT') + '(' + CONVERT(VARCHAR(10), d2.EffectiveDate, 120) + ')'
				FROM CTE_Data d2
				WHERE d2.UserName = d1.UserName
					AND d2.GroupTypeId = 2
				FOR XML PATH('')), 1, 2, '') AS PrimaryExtraPTGroup
	FROM CTE_Data d1
	GROUP BY UserName, SiteId, Site, ExchangeId, Currency
END
GO