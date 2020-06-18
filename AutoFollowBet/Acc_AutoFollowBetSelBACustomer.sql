/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_AutoFollowBetSelBACustomer]
	@LicenseeID INT = 0
	,@status	INT = 0
	,@username	NVARCHAR(50) = ''
AS

/*
	Created: 20120706@Henry
	DB: DBCUST-CustDB
    Task: Get BA Customer
	
	Revisions:  
        - 20130123@Daniel: Change link server alias
        - 20140805@Logan: Separate live & non-live setting
        - 20150323@Kathy: Support 2 more bettype 1x2 & 1st 1x2 [Redmine:#30394]   
		- 20180926@Sophia: migrate bodb_Licensee from DB052 to DBCUST - remove linked server DBLIC [redmine: #99855]
	
	Param's Explanation:  
	  + @LicenseID: 0 - All 
	  +	@status: 0 - All; 1 - Is Followed; 2 - Is Not Followed
*/

BEGIN
	SET NOCOUNT ON

	CREATE TABLE #TempBACust (
		LicenseeID	INT
		,CustID		INT
		)

	INSERT INTO #TempBACust (
		LicenseeID
		,CustID
		)
	SELECT LicenseeID
		,CustID
	FROM bodb_licensee.dbo.LicenseeBAHistory WITH (NOLOCK)
	WHERE STATUS = 'running'
		AND (
			@LicenseeID = 0
			OR (
				@LicenseeID <> 0
				AND LicenseeID = @LicenseeID
				)
			)

	SELECT @username = RTRIM(LTRIM(@username))

	CREATE TABLE #TmpResult (
		custid			INT
		,username		NVARCHAR(50)
		,licenseename	VARCHAR(50)
		,FollowedAgent	INT
		,IsFollowed		BIT
		)

	INSERT INTO #TmpResult (
		custid
		,username
		,licenseename
		,FollowedAgent
		,IsFollowed
		)
	SELECT DISTINCT c.custid
		,c.username
		,l.licenseename
		,(
			SELECT TOP 1 ca.custid
			FROM Cust_FollowBet ca WITH (NOLOCK)
			WHERE ca.custid = c.recommend
			) AS FollowedAgent
		,COALESCE(cf.custid, 0, 1)
	FROM Customer c WITH (NOLOCK)
		INNER JOIN #TempBACust lba ON c.custid = lba.custid
		INNER JOIN bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON lba.LicenseeID = l.LicenseeID
		LEFT JOIN Cust_FollowBet cf WITH (NOLOCK) ON c.custid = cf.custid
	ORDER BY l.Licenseename
		,c.username

	SELECT custid
		,username
		,licenseename
		,CASE 
			WHEN IsFollowed = 1
				OR FollowedAgent IS NOT NULL THEN 1
			ELSE 0
			END IsFollowed
	FROM #TmpResult
	WHERE (
			username LIKE @username + '%'
			OR @username = ''
			)
		AND (
			@status = CASE 
			WHEN IsFollowed = 1
				OR FollowedAgent IS NOT NULL THEN 1
			ELSE 2 END
			OR @status = 0
			)

	DROP TABLE #TempBACust

	DROP TABLE #TmpResult
END
GO