ALTER PROCEDURE [dbo].[Acc_CustomerSelByGroupHeadline]     
    @siteid VARCHAR(200) = ''
  , @currency INT = 0
  , @open BIT
  , @suspended BIT
  , @closed BIT
  , @disabled BIT
  , @roleid INT=0
  , @username VARCHAR(30) = ''
  , @groupheadline VARCHAR(30) = ''    
  , @Owner VARCHAR(50) = ''
  , @HeadlineType VARCHAR(20) = ''
  , @IsTest BIT = 0
AS    
    
/*    
    Created by: Scott    
    Date: 2012-11-20    
    Task : GET customer by group headline    
    DB: DB052.bodb02    
    Original SP:
    Revisions:
        - 20141001@Logan: Use f_DirectAgencyList instead of using Acc_CustDirect
		- 20160607@Elodie: Add headline type and their owner [Redmine:#51923]
						   Modify code to enhance performance 

	Example: exec Acc_CustomerSelByGroupHeadline @siteid=default,@currency=0,@open=1,@suspended=0,@closed=1,@disabled=1,@roleid=0,@username=default,@groupheadline=default,@Owner='',@HeadlineType='1'

*/    
BEGIN    
    SET NOCOUNT ON    
    
    CREATE TABLE #tmpDirectCust 
    (
        CustID INT PRIMARY KEY
      , Site VARCHAR(50)
      , Currency INT
      , RoleID INT
    )

	 CREATE TABLE #tmpGroupHeadline 
    (
        HeadlineID INT PRIMARY KEY
	  , GroupName NVARCHAR(100)
	  , GroupID SMALLINT 
	  , HeadlineType TINYINT NULL
	  , OwnerName VARCHAR(30) NULL
	  , OwnerID INT NULL
    )

    CREATE TABLE #tmpResult
    (
        CustHeadlineID INT
      , GroupName NVARCHAR(100)
      , CustID INT
      , UserName NVARCHAR(100)
      , IsSuspend BIT
      , IsClosed BIT
      , IsEnable BIT
      , Site VARCHAR(50)
      , Currency INT
      , RoleID INT
	  , HeadlineType TINYINT
	  , OwnerName VARCHAR(30)
    )

    CREATE TABLE #tmpResultAll
    (
        CustHeadlineID INT
      , GroupName NVARCHAR(100)
      , CustID INT
      , UserName NVARCHAR(100)
      , IsSuspend BIT
      , IsClosed BIT
      , IsEnable BIT
      , Site VARCHAR(50)
      , Currency INT
      , RoleID INT
	  , HeadlineType TINYINT
	  , OwnerName VARCHAR(30)
    )    
    
    --get super account     
    IF (@roleid = 0 OR @roleid = 4)    
    BEGIN     
        INSERT INTO #tmpDirectCust (custid, site, currency, roleid)
        SELECT c.custid, c.site, c.currency, c.roleid    
        FROM dbo.custAccount ca WITH(NOLOCK)    
			INNER JOIN dbo.Customer c WITH(NOLOCK) ON ca.custid = c.custid AND c.roleid = 4
			INNER JOIN dbo.CustSuper cs WITH(NOLOCK) ON ca.custid = cs.custid AND cs.IsInternal = 0    
        WHERE (@currency = 0 OR c.currency = @currency)
			AND ((@IsTest = 0 AND c.currency NOT IN (20, 27, 28)) OR @IsTest = 1)
    END

    --get direct master    
    IF (@roleid = 0 OR @roleid = 3)    
    BEGIN     
        INSERT INTO #tmpDirectCust (custid, site, currency, roleid)
        SELECT c.custid, c.site, c.currency, c.roleid      
        FROM dbo.f_GetDirectAgency(4) a
			INNER JOIN dbo.Customer c WITH(NOLOCK) ON a.custid = c.custid
			INNER JOIN dbo.CustMaster cm WITH(NOLOCK) ON cm.custid = c.custid AND cm.isInternal = 0
         WHERE (@currency = 0 OR c.currency = @currency)
			AND ((@IsTest = 0 AND c.currency NOT IN (20, 27, 28)) OR @IsTest = 1)
    END     
    
    --get direct agent    
    IF (@roleid = 0 OR @roleid = 2 )    
    BEGIN     
        INSERT INTO #tmpDirectCust (custid, site, currency, roleid)
        SELECT c.custid, c.site, c.currency, c.roleid    
        FROM dbo.f_GetDirectAgency(3) a
			INNER JOIN dbo.Customer c WITH(NOLOCK) ON a.custid = c.custid
			INNER JOIN dbo.CustAgent ca WITH(NOLOCK) ON ca.custid = c.custid AND ca.IsInternal = 0    
        WHERE (@currency = 0 OR c.currency = @currency)
			AND ((@IsTest = 0 AND c.currency NOT IN (20, 27, 28)) OR @IsTest = 1)
    END
    
    --get direct memeber    
    IF (@roleid = 0 OR @roleid = 1)    
    BEGIN     
        INSERT INTO #tmpDirectCust (custid, site, currency, roleid)
        SELECT c.custid, cc.site, c.currency, c.roleid    
        FROM dbo.f_GetDirectAgency(2) a
			INNER JOIN dbo.Customer c WITH(NOLOCK) ON a.custid = c.custid
			INNER JOIN dbo.Customer cc WITH(NOLOCK) ON c.recommend = cc.custid    
        WHERE c.recommend NOT IN (	SELECT custid
									FROM dbo.CustAgent WITH(NOLOCK)
                                    WHERE IsInternal = 1)
           AND (@currency = 0 OR c.currency = @currency)
           AND ((@IsTest = 0 AND c.currency NOT IN (20, 27, 28)) OR @IsTest = 1)
    END
    
    --apply filter by site    
    DELETE #tmpDirectCust    
    WHERE (@siteid <> ''  AND     
      (site NOT IN (SELECT [site] FROM [site] WHERE siteid IN (SELECT  val FROM dbo.strSplit(@siteid,','))) OR site IS NULL)) 
	   OR [site] NOT IN (SELECT [SITE] FROM [SITE] WHERE islicensee = 0 AND isactive=1)    
      
	--apply filter by Owner and Headline Type    
    INSERT INTO #tmpGroupHeadline(HeadlineID, GroupName, GroupID, HeadlineType, OwnerID, OwnerName)    
	SELECT hl.CustID, cu.username, hl.GroupID, hl.HeadlineType, hl.OwnerID, ci. username
	FROM dbo.CustGroupHeadline hl WITH (NOLOCK)
		INNER JOIN dbo.custInfo cu WITH (NOLOCK) ON hl.CustID = cu.custid
		LEFT JOIN dbo.custInfo ci WITH (NOLOCK) ON hl.OwnerID = ci.custid
	WHERE (@Owner = '' OR ci.username = @Owner) AND (@HeadlineType = '' OR hl.HeadlineType IN (SELECT val FROM dbo.strSplit(@HeadlineType, ',')))		

	INSERT INTO #tmpResultAll 
	SELECT  hl.HeadlineID Custheadlineid ,hl.GroupName groupname, ca.custid ,ci.username,isnull(ci.reject,0) issuspend,    
			ISNULL(ci.closed,0) isclosed, ci.[enabled] isEnable,d.site, d.currency, ci.roleid, hl.HeadlineType, ISNULL(hl.OwnerName,'') AS OwnerName
	FROM custaccount ca WITH(NOLOCK)    
		INNER JOIN #tmpGroupHeadline hl WITH(NOLOCK) ON  hl.groupid = ca.groupid
		INNER JOIN custinfo ci WITH(NOLOCK) ON  ci.custid = ca.custid     
		INNER JOIN #tmpDirectCust d ON  d.custid = ca.custid      
	WHERE (@username = '' OR ci.username=@username) 
		AND (@groupheadline = '' OR hl.GroupName=@groupheadline)    
		AND hl.GroupID <> 0
    
	UNION ALL    
	SELECT  0 custheadlineid,'Not assigned to group' , c.custid ,ci.username,isnull(ci.reject,0) issuspend,    
			ISNULL(ci.closed,0) isclosed, ci.[enabled] isEnable, c.site, c.currency, ci.roleid, hl.HeadlineType, ISNULL(hl.OwnerName, '') AS OwnerName
	FROM #tmpDirectCust c    
		INNER JOIN custinfo ci WITH(NOLOCK) ON  ci.custid = c.custid     
		LEFT JOIN #tmpGroupHeadline hl WITH(NOLOCK) ON  ci.custid = hl.HeadlineID
	WHERE c.custid NOT IN (SELECT  custid FROM custaccount WITH(NOLOCK)) 
		AND (@username = '' OR ci.username=@username) 
		AND @groupheadline='' AND @HeadlineType = '' 
		AND (@Owner = '' OR (@Owner <> '' AND hl.OwnerName = @Owner))
    
	--get resulset fOR SELECT all status    
    IF (@open = 1 AND @suspended  = 1 AND @closed = 1 AND @disabled = 1)    
    BEGIN     
		SELECT r.*, e.currency AS CurrencyName
		FROM  #tmpResultAll r
			INNER JOIN dbo.Exchange e WITH (NOLOCK) ON r.Currency = e.exchangeid
		ORDER BY custheadlineid,custid    
    
     RETURN   
    END     
    
    IF (@open = 1)    
    BEGIN     
		INSERT INTO #tmpResult    
		SELECT *     
		FROM #tmpResultAll    
		WHERE issuspend  = 0  AND isclosed = 0    
    END     
    
    IF (@suspended = 1)    
    BEGIN     
		INSERT INTO #tmpResult    
		SELECT *     
		FROM #tmpResultAll    
		WHERE issuspend  = 1  AND isclosed =0      
    END     
    
    IF (@closed = 1)    
    BEGIN     
		 INSERT INTO #tmpResult    
		 SELECT  *     
		 FROM #tmpResultAll    
		 WHERE isenable = 1  AND isclosed =1    
    END     
    
    IF (@disabled = 1)    
    BEGIN     
		INSERT INTO #tmpResult    
		SELECT  *     
		FROM #tmpResultAll    
		WHERE  isenable = 0     
    END     
    
    --resulset            
	SELECT r.*, e.currency AS CurrencyName
	FROM  #tmpResult r
		INNER JOIN dbo.Exchange e WITH (NOLOCK) ON r.Currency = e.exchangeid
	ORDER BY custheadlineid,custid   

END

GO 
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelByGroupHeadline] TO [vnteam]
GO 
GRANT EXECUTE ON [dbo].[Acc_CustomerSelByGroupHeadline] TO [bodbAdminNet]
GO 
