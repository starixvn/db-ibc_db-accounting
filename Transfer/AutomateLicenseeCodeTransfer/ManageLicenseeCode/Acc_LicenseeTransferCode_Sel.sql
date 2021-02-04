/*<info serverAlias="DBLIC-bodb_Licensee" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_LicenseeTransferCode_Sel
(
	@MoveBetsDay SMALLDATETIME,
	@LicenseeIds VARCHAR(MAX) = '',
	@StatusIds VARCHAR(MAX) = '',
	@ForEmail BIT = 0,
	@PageIndex INT = 0,
	@PageSize INT = 0,
	@TotalRows INT = 0 OUTPUT
)
AS
/*
	Created: 20200615@Sol
	Task : Get list licensee detail
	DB: DBLIC-bodb_Licensee
	
	Revisions:
		- 20200615@Sol: NAP - Auto Assign Licensee code to the Licensee accordingly [Redmine: #120670]
		- 20210204@Sol: NAP - email notification for last month only - [Redmine: #150060]

	Param Info:
		- @MoveBetsDay: movebet get from sp [age_SelBalanceUpDay]
		- @LicenseeIds: List licensee id in integer
		- @StatusIds: List status id in integer
		- @ForEmail: get data only from last month to send email notification
	
*/
BEGIN

	SET NOCOUNT ON;

	DECLARE 
		@currentDate SMALLDATETIME
		,@startDate SMALLDATETIME
		,@endDate SMALLDATETIME
		,@RowStart INT
		,@RowEnd INT

	DECLARE @tblLicenseeList TABLE (LicenseeId INT, LicenseeName VARCHAR(50), CustSuperId INT)
	DECLARE @tblLicenseeListAgent TABLE (LicenseeId INT, LicenseeName VARCHAR(50), CustAgentId INT)
	DECLARE @tblLicenseeWithStatus TABLE(LicenseeId INT, LicenseeName VARCHAR(50), LicenseeStatus TINYINT)
	DECLARE @tblLicenseeTransferCode TABLE(CustId INT, LicenseeName VARCHAR(50), StatusID TINYINT)

	SELECT @PageIndex = @PageIndex - 1, @RowStart =  @PageIndex * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1

	SELECT 
		@currentDate = GETDATE()
		,@startDate	= CAST(CONVERT(VARCHAR(7), DATEADD(MONTH, -1, @currentDate), 111) + '/01' AS DATE)
		,@endDate = CASE WHEN @ForEmail = 1 THEN DATEADD(DAY, -1, DATEADD(MONTH, 1, @startDate)) ELSE CAST(@currentDate AS DATE) END
		,@MoveBetsDay = CAST(@MoveBetsDay AS DATE)

	---- get list licensee code
	INSERT INTO @tblLicenseeTransferCode(CustId , LicenseeName , StatusID )
	SELECT CustId , LicenseeName , StatusID
	FROM DBCUST.bodb_licensee.dbo.LicenseeTransferCode WITH(NOLOCK)

	---- run only when the filter include "code needed", "n/a"
	IF EXISTS (SELECT TOP 1 1 FROM dbo.strSplit(@StatusIds,',') t WHERE t.val IN (3, 4))
	BEGIN

		INSERT INTO @tblLicenseeList(LicenseeId, LicenseeName, CustSuperId)
		SELECT l.LicenseeID, l.LicenseeName, cs.custid
		FROM dbo.Licensees l WITH(NOLOCK)
				INNER JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK)
					on cs.[site] = l.LicenseeName
				LEFT JOIN @tblLicenseeTransferCode lc
					on l.LicenseeName = lc.LicenseeName
		WHERE 
			l.IsActive = 1
			AND lc.LicenseeName IS NULL
			AND cs.currency <> 20
			AND (
					l.LicenseeID IN (SELECT val FROM dbo.strSplit(@LicenseeIds,',') t) 
					OR @LicenseeIds = 'ALL'
				)

		---- get agent of licensee
		INSERT INTO @tblLicenseeListAgent(LicenseeId, LicenseeName, CustAgentId)
		SELECT t.LicenseeId, t.LicenseeName AS LicenseeName, la.CustID
		FROM LicenseeCust la WITH(NOLOCK)
			INNER JOIN bodb02.dbo.custInfo i WITH(NOLOCK)
				ON i.custid = la.CustID AND la.RoleID = i.roleid
			INNER JOIN @tblLicenseeList t
				ON i.srecommend = t.CustSuperId
		WHERE
			la.Currency <> 20 
			AND (
					la.LicenseeID IN (SELECT val FROM dbo.strSplit(@LicenseeIds,',') t) 
					OR @LicenseeIds = 'ALL'
				)

		-- get the status
		INSERT INTO @tblLicenseeWithStatus(LicenseeId, LicenseeName, LicenseeStatus)
		SELECT DISTINCT l.LicenseeId, l.LicenseeName, 3 LicenseeStatus -- code needed
		FROM @tblLicenseeList l
		WHERE EXISTS 
			(
				SELECT TOP 1 1
				FROM bodb02.dbo.bettrans AS b WITH(NOLOCK)
				WHERE b.winlostdate BETWEEN @MoveBetsDay AND @endDate
					AND b.bettype < 19001
					AND b.statusid IN (111, 112, 113)
					AND b.srecommend = l.CustSuperId
			) 
		UNION 
		SELECT DISTINCT l.LicenseeId, l.LicenseeName, 3 LicenseeStatus -- code needed
		FROM @tblLicenseeListAgent l
		WHERE EXISTS 
			(
				SELECT TOP 1 1
				FROM bodb_licenseereport.dbo.rptLicWinloss2 AS b WITH (NOLOCK)
				WHERE b.winlostdate BETWEEN @startDate AND @MoveBetsDay
					AND b.RoleId = 2
					AND b.statusid IN (111, 112, 113, 114, 115)
					AND b.recommend = l.CustAgentId
			) 

		INSERT INTO @tblLicenseeWithStatus(LicenseeId, LicenseeName, LicenseeStatus)
		SELECT DISTINCT l.LicenseeId, l.LicenseeName, 4 AS LicenseeStatus -- n/a status
		FROM @tblLicenseeList l
			LEFT JOIN @tblLicenseeWithStatus t
				ON l.LicenseeId = t.LicenseeId
		WHERE t.LicenseeId IS NULL

	END
	---- final result
	CREATE TABLE #LicenseeCode (LicenseeId INT, LicenseeName VARCHAR(50), LicenseeCode NVARCHAR(50), LicenseeStatusId TINYINT)
	CREATE TABLE #LicenseeCodeFinal (RowNumber INT, LicenseeName VARCHAR(50), LicenseeCode NVARCHAR(50), LicenseeStatus VARCHAR(50))

	INSERT INTO #LicenseeCode(LicenseeId, LicenseeName, LicenseeCode, LicenseeStatusId)
	SELECT l.LicenseeID, l.LicenseeName, ci.username AS LicenseeCode, 
		CASE 
			WHEN lt.StatusID = 1 THEN 1  
			WHEN lt.StatusID = 0 THEN 2
		END AS LicenseeStatusId
	FROM Licensees l WITH(NOLOCK)
		INNER JOIN @tblLicenseeTransferCode lt
			ON l.LicenseeName = lt.LicenseeName
		INNER JOIN bodb02.dbo.custInfo ci WITH(NOLOCK)
			ON lt.CustID = ci.custid AND ci.roleid = 1
	WHERE l.IsActive = 1
	UNION ALL
	SELECT lt.LicenseeId, lt.LicenseeName, NULL, lt.LicenseeStatus 
	FROM @tblLicenseeWithStatus lt

	---- final result with filter 
	INSERT INTO #LicenseeCodeFinal(RowNumber, LicenseeName, LicenseeCode, LicenseeStatus)
	SELECT 
		ROW_NUMBER() OVER(ORDER BY lc.LicenseeName) AS RowNumber,
		lc.LicenseeName, lc.LicenseeCode, 
		CASE 
			WHEN lc.LicenseeStatusId = 1 THEN 'ON'
			WHEN lc.LicenseeStatusId = 2 THEN 'OFF'
			WHEN lc.LicenseeStatusId = 3 THEN 'Code Needed'
			WHEN lc.LicenseeStatusId = 4 THEN 'N/A'
		END AS LicenseeStatus
	FROM #LicenseeCode lc
	WHERE 
		lc.LicenseeStatusId IN (SELECT val FROM dbo.strSplit(@StatusIds,',') t)
		AND 
		(
			lc.LicenseeID IN (SELECT val FROM dbo.strSplit(@LicenseeIds,',') t)
			OR @LicenseeIds = 'ALL'
		)

	--return data
	SELECT @TotalRows = MAX(RowNumber) FROM #LicenseeCodeFinal

	SELECT lf.RowNumber, lf.LicenseeName, lf.LicenseeCode, lf.LicenseeStatus
	FROM #LicenseeCodeFinal lf
	WHERE @PageIndex < 0 OR @PageSize <= 0 OR (RowNumber BETWEEN @RowStart AND @RowEnd) 

	---- drop temp table
	DROP TABLE #LicenseeCode
	DROP TABLE #LicenseeCodeFinal

END
GO