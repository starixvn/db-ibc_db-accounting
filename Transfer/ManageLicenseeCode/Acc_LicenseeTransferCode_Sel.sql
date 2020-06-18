/*<info serverAlias="DBLIC-bodb_Licensee" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_LicenseeTransferCode_Sel
(
	@MoveBetsDay SMALLDATETIME,
	@LicenseeIds VARCHAR(MAX) = '',
	@StatusIds VARCHAR(MAX) = '',
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

	Param Info:
		- @MoveBetsDay: movebet get from sp [age_SelBalanceUpDay]
		- @LicenseeIds: List licensee id in integer
		- @StatusIds: List status id in integer
	
*/
BEGIN

	SET NOCOUNT ON;

	DECLARE 
		@currentDate DATETIME
		,@startDate DATE
		,@endDate DATE
		,@RowStart INT
		,@RowEnd INT

	DECLARE @tblLicenseeList TABLE (LicenseeId INT, LicenseeName VARCHAR(50), CustSuperId INT, CurrId TINYINT)
	DECLARE @tblLicenseeWithStatus TABLE(LicenseeId INT, LicenseeName VARCHAR(50), LicenseeStatus TINYINT)

	SELECT @PageIndex = @PageIndex - 1, @RowStart =  @PageIndex * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1

	SELECT 
		@currentDate = GETDATE()
		,@startDate	= CAST(CONVERT(VARCHAR(7), DATEADD(MONTH, -1, @currentDate), 111) + '/01' AS DATE)
		,@endDate = CAST(@currentDate AS DATE)
		,@MoveBetsDay = CAST(@MoveBetsDay AS DATE)

	---- run only when the filter include "code needed", "n/a"
	IF EXISTS (SELECT TOP 1 1 FROM dbo.strSplit(@StatusIds,',') t WHERE t.val IN (3, 4))
	BEGIN
		INSERT INTO @tblLicenseeList
		SELECT l.LicenseeID, l.LicenseeName, cs.custid, cs.currency
		FROM dbo.Licensees l WITH(NOLOCK)
				LEFT JOIN DBCUST.bodb_licensee.dbo.LicenseeTransferCode lc WITH(NOLOCK)
					on l.LicenseeName = lc.LicenseeName
				LEFT JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK)
					on cs.[site] = l.LicenseeName
		WHERE 
			l.IsActive = 1
			AND lc.LicenseeName IS NULL
			AND cs.currency <> 20
			AND (
					l.LicenseeID IN (SELECT val FROM dbo.strSplit(@LicenseeIds,',') t) 
					OR @LicenseeIds = 'ALL'
				)
		--OPTION (MAXRECURSION 0)

		-- get the status
		INSERT INTO @tblLicenseeWithStatus
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
		FROM @tblLicenseeList l
		WHERE EXISTS 
			(
				SELECT TOP 1 1
				FROM bodb_licenseereport.dbo.rptLicWinloss2 AS b WITH (NOLOCK)
				WHERE b.winlostdate BETWEEN @startDate AND @MoveBetsDay
					AND b.RoleId = 4
					AND b.statusid IN (111, 112, 113, 114, 115)
					AND b.srecommend = l.CustSuperId
			) 

		INSERT INTO @tblLicenseeWithStatus
		SELECT DISTINCT l.LicenseeId, l.LicenseeName, 4 AS LicenseeStatus -- n/a status
		FROM @tblLicenseeList l
			LEFT JOIN @tblLicenseeWithStatus t
				ON l.LicenseeId = t.LicenseeId
		WHERE t.LicenseeId IS NULL

	END
	---- final result
	CREATE TABLE #LicenseeCode (LicenseeId INT, LicenseeName VARCHAR(50), LicenseeCode NVARCHAR(50), LicenseeStatusId TINYINT)
	CREATE TABLE #LicenseeCodeFinal (RowNumber INT, LicenseeName VARCHAR(50), LicenseeCode NVARCHAR(50), LicenseeStatus VARCHAR(50))

	INSERT INTO #LicenseeCode
	SELECT l.LicenseeID, l.LicenseeName, ci.username AS LicenseeCode, 
		CASE 
			WHEN lt.CustID IS NOT NULL AND lt.StatusID = 1 THEN 1  
			WHEN lt.CustID IS NOT NULL AND lt.StatusID = 0 THEN 2
			ELSE t.LicenseeStatus
		END AS LicenseeStatusId
	FROM Licensees l WITH(NOLOCK)
		LEFT JOIN DBCUST.bodb_licensee.dbo.LicenseeTransferCode lt WITH(NOLOCK)
			ON l.LicenseeName = lt.LicenseeName
		LEFT JOIN bodb02.dbo.custInfo ci WITH(NOLOCK)
			ON lt.CustID = ci.custid AND ci.roleid = 1
		LEFT JOIN @tblLicenseeWithStatus t
			ON l.LicenseeName = t.LicenseeName
	WHERE l.IsActive = 1

	---- final result with filter 
	INSERT INTO #LicenseeCodeFinal
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
	--OPTION (MAXRECURSION 0)

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