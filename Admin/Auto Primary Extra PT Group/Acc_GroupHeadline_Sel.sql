/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_GroupHeadline_Sel]
	@DeniedList NVARCHAR(MAX)=NULL
AS

/*
	Created: 20210302@Percy
	DB: DBCUST-CustDB
	Task: Select all group headlines

	Revisions:
		- 20210302@Percy: Initialize SP [RemineID: #146710]
		- 20231207@Johnson: Arrange Permission on NAP for new site 777 [Redmine: #197160]
		- 20240419@Tacy: NAP - Permission controls on real currency [redmineID: #202523]
		- 20240729@Lewis: Scale Out DBCust - Remove Linked Server [Redmine : #206895]

*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpExchange TABLE (exchangeID INT, Currency NVARCHAR(50), OfferSite TINYINT)

	IF ISNULL(@DeniedList,'')<>''
	BEGIN
		--get deny site
		INSERT INTO @tmp (siteid, site, SpecialGroup)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Site'
	
		--get deny currency
		INSERT INTO  @tmpExchange (exchangeID, Currency, OfferSite)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Exchange'
	END
	
	SELECT cgh.GroupId AS GroupHeadlineId, c.UserName AS HeadlineName
	FROM dbo.CustGroupHeadline cgh WITH (NOLOCK)
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON cgh.CustId = c.CustId
		INNER JOIN dbo.CustInfo ci WITH (NOLOCK) ON c.CustId = ci.CustId AND ci.Enabled = 1
		LEFT JOIN dbo.CustSuper s WITH (NOLOCK) ON c.srecommend = s.CustId
	WHERE c.Site <> 'CN88'
		AND c.Site NOT IN (SELECT Site FROM @tmp)
		AND c.currency NOT IN (SELECT exchangeID FROM @tmpExchange)
		AND ISNULL(s.IsInternal, 0) = 0 -- Exclude finance account
	ORDER BY HeadlineName
END
GO