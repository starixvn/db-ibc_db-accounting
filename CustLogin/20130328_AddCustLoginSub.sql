DECLARE @MaxCustID INT
		,@PwdExpiry DATETIME 
SELECT	@MaxCustID = 517381 -- SELECT MAX(SubAccID) FROM CustSub WITH (NOLOCK)

SELECT	@PwdExpiry = '2013-03-29'
SELECT	@PwdExpiry

INSERT INTO dbo.CustLoginInfoSub (
SubAccID
,[CustID]
,[OldUserPwd]
,[LastChangedPwdDate]
,[PwdExpiry]
,[isFirstLogin]
)
SELECT 
SubAccID
,[CustID]
,NULL
,NULL
,@PwdExpiry
, 0 --
FROM CustSub WITH (NOLOCK)
WHERE subaccid <= @MaxCustID
