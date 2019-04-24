/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UserLog_ExternalAPI_SelSyncedCustomer]
	@isTestOnly		BIT	= 0 
	,@FromDate		DATETIME = NULL
	,@ToDate		DATETIME = NULL  
AS
/*
Created: 20160823@Jamie
Task : List of customers called via API
DB: DBLOG.bodb_CustomerLog 
Original:

Revisions:
	- 20190405@Patrick: Support archive date range [Redmine: #111476]

Param's Explanation:
	@isTestOnly: 1: UUS; 0: Real Currency 

*/
BEGIN
	SET NOCOUNT ON 

	IF @FromDate IS NULL AND @ToDate IS NULL 
	BEGIN 
		SELECT	@ToDate= DATEADD(MINUTE,-15, CURRENT_TIMESTAMP)  ---DATEADD(DAY,-7,CONVERT(VARCHAR,CURRENT_TIMESTAMP,110))
				,@FromDate = DATEADD(HOUR,-12, CURRENT_TIMESTAMP)	-- 12 hours ago 
	END

	CREATE TABLE #__tmpCustLog(LogId BIGINT, CustId INT)

	DECLARE @__archiveDate DATETIME
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

	IF @FromDate >= @__archiveDate
	BEGIN
		INSERT INTO #__tmpCustLog(LogId, CustId)
		SELECT	LogID, CustID 
		FROM	UserLog_ExternalAPI WITH (NOLOCK)
		WHERE	CustID <>0 
				AND LogDate <= @ToDate
				AND LogDate >= @FromDate
				AND ActionID = 1404
				AND isNotified = 0 
	END
	ELSE IF @ToDate < @__archiveDate
	BEGIN
		INSERT INTO #__tmpCustLog(LogId, CustId)
		SELECT	LogID, CustID 
		FROM bodb_CustomerLog_Archive.dbo.UserLog_ExternalAPI WITH (NOLOCK)
		WHERE	CustID <>0 
				AND LogDate <= @ToDate
				AND LogDate >= @FromDate
				AND ActionID = 1404
				AND isNotified = 0 
	END
	ELSE
	BEGIN
		INSERT INTO #__tmpCustLog(LogId, CustId)
		SELECT	LogID, CustID 
		FROM	UserLog_ExternalAPI WITH (NOLOCK)
		WHERE	CustID <>0 
				AND LogDate <= @ToDate
				AND LogDate >= @__archiveDate
				AND ActionID = 1404
				AND isNotified = 0 

		UNION ALL
		SELECT	LogID, CustID 
		FROM bodb_CustomerLog_Archive.dbo.UserLog_ExternalAPI WITH (NOLOCK)
		WHERE	CustID <>0 
				AND LogDate < @__archiveDate
				AND LogDate >= @FromDate
				AND ActionID = 1404
				AND isNotified = 0 
	END
	
	IF @isTestOnly = 1 
	BEGIN
		SELECT	l.LogID, l.CustID
		FROM	#__tmpCustLog l WITH (NOLOCK)
				INNER JOIN bodb02.dbo.Custinfo ci WITH (NOLOCK) ON l.CustID = ci.CustID 
		WHERE	currency =20 
	END 

	IF @isTestOnly = 0 
	BEGIN
		SELECT	l.LogID, l.CustID
		FROM	#__tmpCustLog l WITH (NOLOCK)
				INNER JOIN bodb02.dbo.Custinfo ci WITH (NOLOCK) ON l.CustID = ci.CustID 
		WHERE	currency <>20 
	END 

	DROP TABLE #__tmpCustLog
END
GO
