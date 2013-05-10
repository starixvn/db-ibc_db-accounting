ALTER PROCEDURE [dbo].[Acc_AutoFollowBetSelBACustomer]	
	@LicenseeID	INT = 0,
	@status	INT=0,
	@username NVARCHAR(50)=''
AS
/*  Created: Henry  
	Date: 2012-07-06
    Task : Get BA Customer
    DB: DBTrans.bodb02  
   
    Revisions:  
       20130123@Daniel: Change link server alias
  
		
	Param's Explanation:  
	  + @LicenseID: 0 - All 
	  +	@status: 0 - All; 1 - Is Followed; 2 - Is Not Followed
	  
*/  
SET NOCOUNT ON

CREATE TABLE #TempBACust (LicenseeID INT, CustID INT)
INSERT INTO #TempBACust (LicenseeID, CustID)
SELECT 
	LicenseeID,CustID 
FROM DBLIC.bodb_licensee.dbo.LicenseeBAHistory WITH(NOLOCK) 
WHERE 
	status = 'running'
	AND ((@LicenseeID=0) OR (@LicenseeID<>0 AND LicenseeID = @LicenseeID))

CREATE TABLE #TmpResult (custid INT,username NVARCHAR(50),licenseename VARCHAR(50),IsFollowed BIT)

IF @status = 0
BEGIN
	INSERT INTO #TmpResult(custid,username,licenseename,IsFollowed)
	SELECT 
		c.custid,
		c.username,
		l.licenseename,
		CASE WHEN cf.CustID IS NULL THEN 0 ELSE 1 END AS IsFollowed
	FROM Customer c WITH (NOLOCK)
		INNER JOIN #TempBACust lba ON c.custid = lba.custid 
		INNER JOIN DBLIC.bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON lba.LicenseeID = l.LicenseeID
		LEFT JOIN Cust_FollowBet cf WITH (NOLOCK) ON c.custid = cf.custid
	ORDER BY l.Licenseename,c.username	
	
END
ELSE IF @status=1
BEGIN
	INSERT INTO #TmpResult(custid,username,licenseename,IsFollowed)
	SELECT 
		c.custid,
		c.username,
		l.licenseename,
		1 AS IsFollowed
	FROM Customer c WITH (NOLOCK)
		INNER JOIN #TempBACust lba ON c.custid = lba.custid 
		INNER JOIN DBLIC.bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON lba.LicenseeID = l.LicenseeID
		INNER JOIN Cust_FollowBet cf WITH (NOLOCK) ON c.custid = cf.custid
	ORDER BY l.Licenseename,c.username	
END
ELSE IF @status=2
BEGIN
	INSERT INTO #TmpResult(custid,username,licenseename,IsFollowed)
	SELECT 
		c.custid,
		c.username,
		l.licenseename,
		0 AS IsFollowed
	FROM Customer c WITH (NOLOCK)
		INNER JOIN #TempBACust lba ON c.custid = lba.custid 
		INNER JOIN DBLIC.bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON lba.LicenseeID = l.LicenseeID
		LEFT JOIN Cust_FollowBet cf WITH (NOLOCK) ON c.custid = cf.custid
	WHERE 
		cf.CustID IS NULL
	ORDER BY l.Licenseename,c.username	
END	

SELECT @username = RTRIM(LTRIM(@username))

IF @username<>''
BEGIN
	SELECT * FROM #TmpResult
	WHERE username LIKE @username + '%'
END
ELSE
BEGIN
	SELECT * FROM #TmpResult
END
	
	
DROP TABLE #TempBACust
DROP TABLE #TmpResult

GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetSelBACustomer] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetSelBACustomer] TO [VNTeam]
GO