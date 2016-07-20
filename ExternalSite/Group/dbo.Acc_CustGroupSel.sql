USE [bodb_Age]
GO

ALTER PROCEDURE  [dbo].[Acc_CustGroupSel]
	@GroupName varchar(50) = null,
	@Userid		INT=NULL
AS
/*
	Created by: [Henry]
	Date: 2011-04-01
	Task: Select the list super/master of Acc_CustGroup
	DB: DBAGE/bodb_AGE
	
	Revisions:
		- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE
		- 20160620@Winnie: #48948 Hide_special_sites_from_unautorized_users
		- 20160721@Percy: Return NormalGroup and ExtraPTGroup columns [RedmineID: #60883]

*/
	SET NOCOUNT ON
	IF @Userid IS NULL
	BEGIN	
	DECLARE @today DATETIME
	SELECT  @today = CONVERT(DATE, GETDATE())
	
	IF @GroupName = ''
		SET @GroupName = null

	DECLARE @GroupExtraPT TABLE (GroupName NVARCHAR(100))
	END
	ELSE
	BEGIN
	DECLARE @SearchQuery varchar(1024)
	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpUserid VARCHAR(50)
	CREATE TABLE #TempCustGroup(CustID INT,Username VARCHAR(50),Firstname NVARCHAR(50),Lastname NVARCHAR(50),RoleId TINYINT,Groupname VARCHAR(50),iplogin NVARCHAR(20),recommendId INT,site VARCHAR(10))

	SELECT @tmpUserid=CAST(@Userid AS VARCHAR(50))
	SELECT @SearchQuery = 'SELECT * 
	FROM OPENQUERY(DBPOLICY, 
	''SELECT siteid , site,SpecialGroup FROM bodb02.dbo.f_GetDeniedSiteByUser( ''''' + @tmpUserid + ''''')'')'

	INSERT INTO  @tmp (siteid , site,SpecialGroup)
	EXECUTE(@SearchQuery)	
	
	if @GroupName = ''
	set @GroupName = null
	
	INSERT INTO #TempCustGroup(CustID ,Username ,Firstname,Lastname ,RoleId ,Groupname ,iplogin,recommendId,site)
	select 
		a.CustID, c.username,c.firstname, c.lastname, a.roleid, a.GroupName , c.iplogin,c.recommend,site
	from 
		Acc_CustGroup a (nolock) 
	inner join bodb02.dbo.customer c (nolock) on a.CustID = c.CustID
	where GroupName = COALESCE(@GroupName,GroupName)
	order by GroupName, username	
	
	UPDATE a SET a.site=b.site
	FROM #TempCustGroup a
	INNER JOIN bodb02.dbo.Customer b (NOLOCK) ON a.recommendId=b.custid
	WHERE a.RoleId=1
	DELETE FROM #TempCustGroup WHERE site IN(SELECT site FROM @tmp)
	
	select 
		CustID, username,firstname, lastname, roleid, GroupName , iplogin
	FROM #TempCustGroup
	INSERT INTO @GroupExtraPT (GroupName)
	SELECT GroupName FROM OPENQUERY(DBACC, 'SELECT GroupName FROM bodb_Acc.dbo.Acc_DWLList_ExtraPT WITH(NOLOCK)')

	;WITH CTE AS
	(
		SELECT
			c.CustID,
			c.roleid,
			c.GroupName,
			CASE WHEN e.GroupName IS NULL THEN c.GroupName ELSE NULL END AS Normal,
			CASE WHEN e.GroupName IS NULL THEN NULL ELSE
				CASE WHEN c.EffectiveDate = (SELECT MAX(EffectiveDate) FROM dbo.Acc_CustGroup WITH(NOLOCK) WHERE EffectiveDate <= @today AND CustID = c.CustID) THEN c.GroupName +','+CONVERT(VARCHAR(10), c.EffectiveDate, 101)+',1'
					 WHEN c.EffectiveDate > @today THEN c.GroupName +','+CONVERT(VARCHAR(10), c.EffectiveDate, 101)+',0'
					 ELSE c.GroupName +',,0' END
			END AS Extra
		FROM
			dbo.Acc_CustGroup c WITH(NOLOCK)
			LEFT JOIN @GroupExtraPT e ON c.GroupName = e.GroupName
	)
	SELECT 
		a.CustID, c.username,c.firstname, c.lastname, a.roleid, a.GroupName , c.iplogin,
		(SELECT CASE WHEN Normal IS NULL THEN '' ELSE STUFF((SELECT ';' + Normal FROM CTE WHERE custid = a.CustID FOR XML PATH('')), 1, 1, '') END) AS NormalGroup,
		(SELECT CASE WHEN Extra  IS NULL THEN '' ELSE STUFF((SELECT ';' + Extra  FROM CTE WHERE custid = a.CustID FOR XML PATH('')), 1, 1, '') END) AS ExtraPTGroup
	FROM 
		CTE a
		INNER JOIN bodb02.dbo.customer c WITH(NOLOCK) ON a.CustID = c.CustID
	WHERE a.GroupName = COALESCE(@GroupName,a.GroupName)
	GROUP BY a.CustID, c.username,c.firstname, c.lastname, a.roleid, a.GroupName, c.iplogin, Normal, Extra
	ORDER BY GroupName, username	
	
	END

GO
GRANT EXECUTE ON [dbo].[Acc_CustGroupSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustGroupSel] TO [vnteam]