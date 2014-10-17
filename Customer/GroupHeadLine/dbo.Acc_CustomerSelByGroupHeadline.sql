SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Acc_CustomerSelByGroupHeadline    Script Date: 10/1/2014 5:21:20 PM ******/
CREATE PROCEDURE Acc_CustomerSelByGroupHeadline     
    @siteid VARCHAR(200) = ''
  , @currency INT=0
  , @open BIT
  , @suspended  BIT
  , @closed BIT
  , @disabled BIT
  , @roleid INT=0
  , @username VARCHAR(30) = ''
  , @groupheadline VARCHAR(30) = ''    
AS    
    
/*    
    Created by: Scott    
    Date: 2012-11-20    
    Task : GET customer by group headline    
    DB: DB052.bodb02    
    Original SP:
    Revisions:
        - 20141001@Logan:   Use f_DirectAgencyList instead of using Acc_CustDirect
  
*/    
BEGIN    
    
    SET NOCOUNT ON    
    
    DECLARE @tmpdirectcust TABLE
    (
        custid INT
      , site VARCHAR(50)
      , currency INT
      , roleid INT
    )

    DECLARE @tmpresult TABLE
    (
        custheadlineid INT
      , groupname NVARCHAR(100)
      , custid INT
      , username NVARCHAR(100)
      , issuspend BIT
      , isclosed BIT
      , isenable BIT
      , site VARCHAR(50)
      , currency INT
      , roleid INT
    )

    DECLARE @tmpresultall TABLE
    (
        custheadlineid INT
      , groupname NVARCHAR(100)
      , custid INT
      , username NVARCHAR(100)
      , issuspend  BIT
      , isclosed BIT
      , isenable BIT
      , site VARCHAR(50)
      , currency INT
      , roleid INT
    )    
    
    --get super account     
    IF (@roleid = 0
        OR @roleid = 4)    
    BEGIN     
        INSERT INTO @tmpdirectcust
        SELECT c.custid
             , c.site
             , c.currency
             , c.roleid    
          FROM custaccount ca WITH(NOLOCK)    
    INNER JOIN customer c WITH(NOLOCK) ON ca.custid = c.custid
                                      AND c.roleid = 4
    INNER JOIN custsuper cs WITH(NOLOCK) ON ca.custid = cs.custid
                                        AND cs.IsInternal = 0    
         WHERE (@currency = 0 OR c.currency = @currency)
           AND c.currency NOT IN (20, 27, 28)
    END

    --get direct master    
    IF (@roleid = 0
        OR @roleid = 3)    
    BEGIN     
        INSERT INTO @tmpdirectcust    
        SELECT c.custid
             , c.site
             , c.currency
             , c.roleid    
          FROM f_DirectAgencyList(3) a
    INNER JOIN customer c WITH(NOLOCK) ON a.custid = c.custid
    INNER JOIN custmaster cm WITH(NOLOCK) ON cm.custid = c.custid
                                         AND cm.isInternal = 0
         WHERE (@currency = 0 OR c.currency = @currency)
           AND c.currency NOT IN (20, 27, 28)    
    END     
    
    --get direct agent    
    IF (@roleid = 0 OR @roleid = 2 )    
    BEGIN     
        INSERT INTO @tmpdirectcust    
        SELECT c.custid
             , c.site
             , c.currency
             , c.roleid    
          FROM f_DirectAgencyList(2) a
    INNER JOIN customer c WITH(NOLOCK) ON a.custid = c.custid
    INNER JOIN custagent ca WITH(NOLOCK) ON ca.custid = c.custid
                                        AND ca.IsInternal = 0    
         WHERE (@currency = 0 OR c.currency = @currency)
           AND c.currency NOT IN (20, 27, 28)    
    END
    
    --get direct memeber    
    IF (@roleid = 0 OR @roleid = 1)    
    BEGIN     
        INSERT INTO @tmpdirectcust    
        SELECT c.custid
             , cc.site
             , c.currency
             , c.roleid    
          FROM f_DirectAgencyList(1) a
    INNER JOIN customer c WITH(NOLOCK) ON a.custid = c.custid
    INNER JOIN customer cc WITH(NOLOCK) ON c.recommend = cc.custid    
         WHERE c.recommend NOT IN (SELECT custid
                                     FROM custagent WITH(NOLOCK)
                                    WHERE IsInternal = 1
                                  )
           AND (@currency = 0 OR c.currency = @currency)
           AND c.currency NOT IN (20, 27, 28)    
    END
    
    --apply filter by site    
    delete @tmpdirectcust    
    WHERE (@siteid <> ''  AND     
      (    
       [site] NOT IN ( SELECT  [site]     
           FROM [site]     
           WHERE siteid IN (SELECT  val FROM dbo.strSplit(@siteid,','))) OR    
       [site] IS NULL       
      )  ) OR [site] NOT IN (SELECT [SITE] FROM [SITE] WHERE islicensee = 0  AND  isactive=1)    
    
      
    --get resulset fOR SELECT  all status    
    IF (@open = 1 AND @suspended  = 1 AND @closed = 1 AND @disabled = 1)    
    BEGIN     
    
     SELECT  c.custid custheadlineid ,cu.username groupname, ca.custid ,ci.username,isnull(ci.reject,0) issuspend  ,    
       isnull(ci.closed,0) isclosed, ci.[enabled] isEnable,d.site, d.currency, ci.roleid     
     FROM custaccount ca WITH(NOLOCK)    
      INNER JOIN custaccount c WITH(NOLOCK) ON  c.groupid = ca.groupid  AND c.isgroupheadline = 1     
      INNER JOIN custinfo ci WITH(NOLOCK) ON  ci.custid = ca.custid     
      INNER JOIN custinfo cu WITH(NOLOCK) ON  cu.custid = c.custid     
      INNER JOIN @tmpdirectcust  d    ON  d.custid = ca.custid      
     WHERE (@username = '' OR ci.username=@username) AND     
       (@groupheadline = '' OR cu.username=@groupheadline)    
    
     UNION ALL    
     
     SELECT  0 custheadlineid,'Not assigned to group' , c.custid ,ci.username,isnull(ci.reject,0) issuspend  ,    
       isnull(ci.closed,0) isclosed, ci.[enabled] isEnable, c.site, c.currency, ci.roleid     
     FROM @tmpdirectcust c    
      INNER JOIN custinfo ci WITH(NOLOCK) ON  ci.custid = c.custid     
     WHERE c.custid NOT IN (SELECT  custid FROM custaccount WITH(NOLOCK)) AND     
       (@username = '' OR ci.username=@username) AND    
       @groupheadline=''    
     ORDER BY custheadlineid,custid    
    
     RETURN;    
    END     
    
    --    
    INSERT INTO @tmpresultall    
    SELECT  c.custid custheadlineid ,cu.username groupname, ca.custid ,ci.username,isnull(ci.reject,0) issuspend ,    
      isnull(ci.closed,0) isclosed, ci.[enabled] isEnable, d.site, d.currency, ci.roleid     
    FROM custaccount ca WITH(NOLOCK)    
     INNER JOIN custaccount c WITH(NOLOCK) ON  c.groupid = ca.groupid  AND c.isgroupheadline = 1     
     INNER JOIN custinfo ci WITH(NOLOCK) ON  ci.custid = ca.custid     
     INNER JOIN custinfo cu WITH(NOLOCK) ON  cu.custid = c.custid     
     INNER JOIN @tmpdirectcust  d    ON  d.custid = ca.custid      
    WHERE (@username = '' OR ci.username=@username) AND     
      (@groupheadline = '' OR cu.username=@groupheadline)    
        
    UNION ALL    
    
    SELECT  0 custheadlineid,'Not assigned to group' , c.custid ,ci.username,isnull(ci.reject,0) issuspend  ,isnull(ci.closed,0) isclosed, ci.[enabled] isEnable,     
      c.site, c.currency, ci.roleid     
    FROM @tmpdirectcust c    
     INNER JOIN custinfo ci WITH(NOLOCK) ON  ci.custid = c.custid     
    WHERE c.custid NOT IN (SELECT  custid FROM custaccount WITH(NOLOCK)) AND     
      (@username = '' OR ci.username=@username) AND    
      @groupheadline=''    
    
    
    IF (@open = 1)    
    BEGIN     
     INSERT INTO @tmpresult    
     SELECT  *     
     FROM @tmpresultall    
     WHERE issuspend  = 0  AND isclosed = 0    
    END     
    
    IF (@suspended = 1)    
    BEGIN     
     INSERT INTO @tmpresult    
     SELECT  *     
     FROM @tmpresultall    
     WHERE  issuspend  = 1  AND isclosed =0      
    END     
    
    IF (@closed = 1)    
    BEGIN     
     INSERT INTO @tmpresult    
     SELECT  *     
     FROM @tmpresultall    
     WHERE isenable = 1  AND isclosed =1    
    END     
    
    IF (@disabled = 1)    
    BEGIN     
     INSERT INTO @tmpresult    
     SELECT  *     
     FROM @tmpresultall    
     WHERE  isenable = 0     
    END     
    
    --resulset    
    SELECT  *     
    FROM @tmpresult     
    ORDER BY custheadlineid,custid    
    
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelByGroupHeadline] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[Acc_CustomerSelByGroupHeadline] TO [bodbAdminNet]
GO 
