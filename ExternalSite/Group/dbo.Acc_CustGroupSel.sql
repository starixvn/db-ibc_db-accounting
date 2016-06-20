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

*/
	SET NOCOUNT ON 
	IF @Userid IS NULL
	BEGIN	
	if @GroupName = ''
	set @GroupName = null
	
	select 
		a.CustID, c.username,c.firstname, c.lastname, a.roleid, a.GroupName , c.iplogin
	from 
		Acc_CustGroup a (nolock) inner join bodb02.dbo.customer c (nolock) on a.CustID = c.CustID
	where GroupName = COALESCE(@GroupName,GroupName)
	order by GroupName, username	
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
	
	END

GO
GRANT EXECUTE ON [dbo].[Acc_CustGroupSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustGroupSel] TO [vnteam]