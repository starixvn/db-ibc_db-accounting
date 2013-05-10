ALTER PROCEDURE [dbo].[Acc_AutoFollowBetSelCustomer]	
	@status	INT=0
AS
/*
Created: Viet @ 4-Jul-2012
DB: DBTXN/bodb02
Revisions:  
	- 20130201@Daniel: Change link server alias
  
		
	Param's Explanation:  
	  +	@status: 0 - All; 1 - BA Enabled; 2 - BA Disabled
*/
SET NOCOUNT ON

CREATE TABLE #TempBACust (CustID INT)
INSERT INTO #TempBACust (CustID)
SELECT CustID 
FROM DBLIC.bodb_licensee.dbo.LicenseeBAHistory WITH(NOLOCK) 
WHERE 
	status = 'running'

IF @status = 0
BEGIN
	SELECT 
		c.custid, ci.username, c.rate ,
		CASE WHEN ba.CustID IS NULL THEN 0 ELSE 1 END AS IsBA
	FROM Cust_FollowBet c WITH(NOLOCK)
		INNER JOIN custinfo ci WITH(NOLOCK) ON c.custid = ci.custid
		LEFT JOIN #TempBACust ba ON c.custid = ba.custid
	ORDER BY ci.username	
END
ELSE IF @status = 1
BEGIN
	SELECT 
		c.custid, ci.username, c.rate ,
		1 AS IsBA
	FROM Cust_FollowBet c WITH(NOLOCK)
		INNER JOIN custinfo ci WITH(NOLOCK) ON c.custid = ci.custid
		INNER JOIN #TempBACust ba ON c.custid = ba.custid
	ORDER BY ci.username
END
ELSE IF @status = 2
BEGIN
	SELECT 
		c.custid, ci.username, c.rate ,
		0 AS IsBA
	FROM Cust_FollowBet c WITH(NOLOCK)
		INNER JOIN custinfo ci WITH(NOLOCK) ON c.custid = ci.custid
		LEFT JOIN #TempBACust ba ON c.custid = ba.custid
	WHERE ba.CustID IS NULL
	ORDER BY ci.username
END

DROP TABLE #TempBACust

GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetSelCustomer] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetSelCustomer] TO [VNTeam]
GO