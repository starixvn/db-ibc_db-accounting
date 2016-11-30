ALTER PROCEDURE [dbo].[Acc_UserLog_ExternalAPI_SelSyncedCustomer]
@isTestOnly		BIT	= 0 
,@FromDate		DATETIME = NULL
,@ToDate		DATETIME = NULL  
AS
/*
Created: 20160823@Jamie
Task : List of customers called via API [RedmineID: #65873]
DB: DBLOG.bodb_CustomerLog 
Original:

Revisions:

Param's Explanation:
	@isTestOnly: 1: UUS; 0: Real Currency 

*/
BEGIN
	SET NOCOUNT ON 

	IF @FromDate IS NULL AND @ToDate IS NULL 
	BEGIN 
		SELECT	@ToDate= DATEADD(MINUTE,-15,CURRENT_TIMESTAMP)  ---DATEADD(DAY,-7,CONVERT(VARCHAR,CURRENT_TIMESTAMP,110))
				,@FromDate = DATEADD(HOUR,-12,CURRENT_TIMESTAMP)	-- 12 hours ago 
	END

	SELECT	LogID, CustID 
	INTO #tmpCustLog
	FROM	UserLog_ExternalAPI WITH (NOLOCK)
	WHERE	CustID <>0 
			AND LogDate <=@ToDate
			AND LogDate >=@FromDate
			AND ActionID = 1404
			AND isNotified = 0 
	
	IF @isTestOnly = 1 
	BEGIN
		SELECT	l.LogID, l.CustID
		FROM	#tmpCustLog l WITH (NOLOCK)
				INNER JOIN bodb02.dbo.Custinfo ci WITH (NOLOCK) ON l.CustID = ci.CustID 
		WHERE	currency =20 
	END 

	IF @isTestOnly = 0 
	BEGIN
		SELECT	l.LogID, l.CustID
		FROM	#tmpCustLog l WITH (NOLOCK)
				INNER JOIN bodb02.dbo.Custinfo ci WITH (NOLOCK) ON l.CustID = ci.CustID 
		WHERE	currency <>20 
	END 

END
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_ExternalAPI_SelSyncedCustomer] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UserLog_ExternalAPI_SelSyncedCustomer] TO [vnteam] AS [dbo]
GO 