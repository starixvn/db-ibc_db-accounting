USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_AutoFollowBetSelCustomer]    Script Date: 03/23/2015 09:31:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_AutoFollowBetSelCustomer]
	@Username	VARCHAR(50) = '%',
	@Source		VARCHAR(1)	= '%',
	@BAStatus	VARCHAR(1)	= '%',
	@FollowLive	VARCHAR(1) 	= '%',
	@HDP    	VARCHAR(1) 	= '%',
	@1stHDP     VARCHAR(1) 	= '%',
	@OU     	VARCHAR(1) 	= '%',
	@1stOU  	VARCHAR(1) 	= '%',
	@1x2		VARCHAR(1) 	= '%',
	@1st1x2		VARCHAR(1) 	= '%',
	@Follower	VARCHAR(30) = '%',
	@IsAgent    VARCHAR(1)	= '%'
AS
/*
Created: Viet @ 4-Jul-2012
DB: DBTXN/CustDB
Revisions:  
	- 20130201@Daniel: Change link server alias
	- 20131212@Kathy: - Remove @status, add new @param
					  - Separate Auto follow bet account for Live or Non-Live or All [Redmine:#9144]
	- 20140106@Kathy: Add param: @Follower [Redmine:#10329]
	- 20140227@Kathy: Get more column: Odds [Redmine:#12546]
	- 20140805@Logan:   1. Separate live and nonlive setting [Redmine: #16578]
	                    2. Allow following an agent (all members under) [Redmine: #19650]
	                    3. Code aligning
	- 20150323@Kathy: Support 2 more bettype 1x2 & 1st 1x2 [Redmine:#30394]


	Param's Explanation:  
	  + @Source:	0 - Manual		 1 - Auto			% - All
	  +	@BAStatus:	0 - BA Disabled  1 - BA Enabled 	% - All
	  + @FollowLive:0 - Non live 	 1 - Live			% - All
	  + @HDP:		0 - Not follow   1 - Follow		    % - All
	  + @1stHDP:	0 - Not follow	 1 - Follow		    % - All
	  + @OU:		0 - Not follow	 1 - Follow	    	% - All
	  + @1stOU:	    0 - Not follow	 1 - Follow 		% - All
	  + @1x2:		0 - Not follow	 1 - Follow	    	% - All
	  + @1st1x2	    0 - Not follow	 1 - Follow 		% - All

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @tblBACust TABLE (custId INT PRIMARY KEY)
	--INSERT INTO @tblBACust(custId)
	--SELECT l.custid
	--  FROM DBLIC.bodb_licensee.dbo.LicenseeBAHistory l WITH(NOLOCK)
	-- WHERE l.status = 'running'
	
	INSERT INTO @tblBACust(custid)
	SELECT CustId
	FROM dbo.Dep_CustBAActive WITH(NOLOCK)

	SELECT c.username
	     , f.src
	     , f.Rate
	     , f.Rate2
	     , f.FollowLive
	     , f.Follow1
	     , f.Follow3
	     , f.Follow5
	     , f.Follow7
	     , f.Follow8
	     , f.Follow15
	     , CASE
	         WHEN f.custid IN (SELECT CustId
	                             FROM @tblBACust
	                          ) THEN 1
	         ELSE 0
	       END as IsBA
	     , ISNULL(ci.username, '') as Follower
	     , f.Odds
	     , f.Odds2
	     , CASE
	         WHEN c.roleid = 2 THEN 1
	         ELSE 0
	       END as IsAgent
	  FROM dbo.Cust_FollowBet f WITH(NOLOCK)
INNER JOIN dbo.Customer c WITH(NOLOCK) ON c.custid = f.custid
                                  AND c.roleid IN (1, 2)
 LEFT JOIN dbo.custInfo ci WITH(NOLOCK) ON ci.custid = f.Follower
                                   AND ci.roleid = 1
	 WHERE c.username LIKE ISNULL(@Username, '%')
	   AND f.src LIKE @Source
	   AND f.FollowLive LIKE @FollowLive
       AND f.Follow1 LIKE @HDP
	   AND f.Follow3 LIKE @OU
	   AND f.Follow5 LIKE @1x2
	   AND f.Follow7 LIKE @1stHDP
	   AND f.Follow8 LIKE @1stOU	   
	   AND f.Follow15 LIKE @1st1x2
	   AND ISNULL(ci.username, '%') LIKE ISNULL(@Follower, '%')
	   AND f.IsAgent LIKE @IsAgent
	   AND (@BAStatus = CASE
	                      WHEN f.custid IN (SELECT CustId
	                                          FROM @tblBACust
	                                       ) THEN '1'
	                      ELSE '0'
	                    END
	        OR @BAStatus = '%'
	       )
  ORDER BY c.username, f.FollowLive

END


GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetSelCustomer] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetSelCustomer] TO [vnteam] AS [dbo]