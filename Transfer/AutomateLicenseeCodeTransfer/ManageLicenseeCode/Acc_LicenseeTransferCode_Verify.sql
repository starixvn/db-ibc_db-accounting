/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_LicenseeTransferCode_Verify
(
	@LicenseeName VARCHAR(50),
	@LicenseeCode NVARCHAR(50),
	@FromDateOld DATE = NULL,
	@ToDateOld DATE = NULL,
	@FromDate DATE,
	@ToDate DATE
)
AS
/*
	Created: 20200615@Sol
	Task : Verify licensee before update licensee code
	DB: DBCUST-bodb_Licensee
	
	Revisions:
		- 20200615@Sol: NAP - Auto Assign Licensee code to the Licensee accordingly [Redmine: #120670]
		- 20210315@Sol: NAP - Enhance Manage Licensee Code to support change base currency of licensees - [Redmine: #151607]
		- 20210330@Sol: NAP - Enhance Manage Licensee Code to support change base currency of licensees - Phase 2 - [Redmine: #152056]

	Param Info:
		- @LicenseeName: Name of the Licensee 
		- @LicenseeCode: code need to mapping (username of member)
		- @CodeStatus: status of the mapping (active/inactive)
	
*/
BEGIN

	SET NOCOUNT ON;

	DECLARE @tblVerifiedResult TABLE (ErrorId INT, ErrorMessage VARCHAR(200))
	DECLARE @tblLicensee TABLE (LicenseeName VARCHAR(50), CustID INT, FromDate DATE,ToDate DATE, MinFromDate DATE, MaxToDate DATE)

	INSERT INTO @tblLicensee(LicenseeName, CustID, FromDate, ToDate, MinFromDate, MaxToDate)
	SELECT lc.LicenseeName, lc.CustID, lc.FromDate, lc.ToDate, t.MinFromDate, t.MaxToDate
	FROM dbo.LicenseeTransferCode lc WITH(NOLOCK)
		CROSS APPLY
		(
			SELECT MIN(lc.FromDate) AS MinFromDate, MAX(lc.ToDate) AS MaxToDate 
			FROM dbo.LicenseeTransferCode lc WITH(NOLOCK)
			WHERE lc.LicenseeName = @LicenseeName	
		) t
	WHERE lc.LicenseeName = @LicenseeName

	---- check code used
	INSERT INTO @tblVerifiedResult
	SELECT DISTINCT
		'101' AS ErrorCode, 
		'This code is already used by [' + 
			STUFF((
					SELECT ', ' + inLc.LicenseeName
					FROM LicenseeTransferCode inLc WITH(NOLOCK)
					WHERE lc.CustID = inLc.CustID
						and inLc.LicenseeName is not null
					FOR XML PATH('')
				), 1, 2, '') 
			+ ']' AS ErrorMessage
	FROM LicenseeTransferCode lc WITH(NOLOCK)
		INNER JOIN CustDB.dbo.custInfo c WITH(NOLOCK)
			ON c.custid = lc.CustID AND c.roleid = 1
	WHERE 
		c.username = @LicenseeCode
		AND lc.LicenseeName <> @LicenseeName

	---- check not contain licensee name
	INSERT INTO @tblVerifiedResult
	SELECT
		'102' AS ErrorCode, 
		'This code does not contain licensee name' AS ErrorMessage
	FROM 
	(
		VALUES(@LicenseeCode)
	) t (LicenseeCode)
	WHERE CHARINDEX(@LicenseeName, t.LicenseeCode) = 0

	---- check licensee code is not existed
	IF NOT EXISTS (SELECT TOP 1 1 FROM CustDB.dbo.custInfo c WITH(NOLOCK) WHERE c.username = @LicenseeCode AND c.roleid = 1)
	BEGIN
		INSERT INTO @tblVerifiedResult
		SELECT '201' AS ErrorCode, 'This code does not exist' AS ErrorMessage
	END

	---- check licensee already has another active code
	IF EXISTS (SELECT TOP 1 1 FROM @tblLicensee lc WHERE lc.LicenseeName = @LicenseeName)
	BEGIN
		IF @FromDateOld IS NOT NULL --- case update
		BEGIN
			IF EXISTS 
			(
				SELECT TOP 1 1 
				FROM @tblLicensee lc
				WHERE 
					lc.LicenseeName = @LicenseeName
					AND 
					(
						@FromDateOld > lc.ToDate 
						OR @ToDateOld < lc.FromDate 
						OR (@FromDate > @FromDateOld AND @ToDate < @ToDateOld)
						OR (@FromDate = @FromDateOld AND @ToDate < @ToDateOld)
						OR (@FromDate > @FromDateOld AND @ToDate = @ToDateOld)
					)
					AND 
					(
						@FromDate BETWEEN lc.FromDate AND lc.ToDate
						OR @ToDate BETWEEN lc.FromDate AND lc.ToDate
						OR lc.FromDate BETWEEN @FromDate AND @ToDate
						OR lc.ToDate BETWEEN @FromDate AND @ToDate
					)
			)
			OR EXISTS
			(
				SELECT TOP 1 1 
				FROM @tblLicensee lc
				WHERE 
					lc.LicenseeName = @LicenseeName
					AND 
					(
						(@FromDateOld > lc.ToDate AND @ToDateOld = lc.MaxToDate) 
						OR (@ToDateOld < lc.FromDate AND @FromDateOld = lc.MinFromDate) 
					)
					AND 
					(
						@FromDate BETWEEN lc.FromDate AND lc.ToDate
						OR @ToDate BETWEEN lc.FromDate AND lc.ToDate
						OR @FromDate > @FromDateOld AND @ToDateOld = lc.MaxToDate
						OR @ToDate < @ToDateOld AND @FromDateOld = lc.MinFromDate
					)
			)
			BEGIN
				INSERT INTO @tblVerifiedResult
				SELECT '202' AS ErrorCode, 'Cannot save the setting, please check From date/To date!' AS ErrorMessage
			END
		END
		ELSE 
		BEGIN
			IF 
			EXISTS --overlapped
			(
				SELECT TOP 1 1 
				FROM @tblLicensee lc
				WHERE 
					lc.LicenseeName = @LicenseeName
					AND 
					(
						@FromDate BETWEEN lc.FromDate AND lc.ToDate
						OR @ToDate BETWEEN lc.FromDate AND lc.ToDate
						OR lc.FromDate BETWEEN @FromDate AND @ToDate
						OR lc.ToDate BETWEEN @FromDate AND @ToDate
					)
			)
			OR 
			NOT EXISTS --time range must be continued
			(
				SELECT TOP 1 1 
				FROM @tblLicensee lc
				WHERE 
					lc.LicenseeName = @LicenseeName
					AND 
					(
						@ToDate < lc.MinFromDate
						OR @FromDate > lc.MaxToDate
					)
			)
			BEGIN
				INSERT INTO @tblVerifiedResult
				SELECT '202' AS ErrorCode, 'Cannot save the setting, please check From date/To date! ' AS ErrorMessage
			END
		END
	END

	IF (@FromDate >= @ToDate) OR (@FromDateOld IS NOT NULL AND @ToDateOld IS NOT NULL AND @FromDateOld >= @ToDateOld)
	BEGIN
		INSERT INTO @tblVerifiedResult
		SELECT '203' AS ErrorCode, 'From Date could not be later than To Date' AS ErrorMessage
	END
		
	
	SELECT t.ErrorId, t.ErrorMessage
	FROM @tblVerifiedResult t

END