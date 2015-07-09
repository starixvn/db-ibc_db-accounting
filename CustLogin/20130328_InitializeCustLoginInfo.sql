 /*
	Initialize CustLoginInfo

*/

DECLARE @MaxCustID INT
		,@PwdExpiry DATETIME 
SELECT	@MaxCustID =10579518 -- SELECT MAX(CustID) FROM Custinfo WITH (NOLOCK)

SELECT	@PwdExpiry = '2013-03-29'
SELECT	@PwdExpiry

INSERT INTO dbo.CustLoginInfo (
[CustID]
,[OldUserPwd]
,[LastChangedPwdDate]
,[isFirstLogin]
)
SELECT 
 [CustID]
,NULL
,NULL
, CASE WHEN iplogin IS NULL THEN 1 ELSE 0 END 
FROM Customer WITH (NOLOCK)
WHERE custid <= @MaxCustID
AND roleid BETWEEN 2 AND 4 

