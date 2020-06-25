/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_LicenseeTransferCode_Verify
(
	@LicenseeName VARCHAR(50),
	@LicenseeCode NVARCHAR(50)
)
AS
/*
	Created: 20200615@Sol
	Task : Verify licensee before update licensee code
	DB: DBCUST-bodb_Licensee
	
	Revisions:
		- 20200615@Sol: NAP - Auto Assign Licensee code to the Licensee accordingly [Redmine: #120670]

	Param Info:
		- @LicenseeName: Name of the Licensee 
		- @LicenseeCode: code need to mapping (username of member)
		- @CodeStatus: status of the mapping (active/inactive)
	
*/
BEGIN

	SET NOCOUNT ON;

	DECLARE @tblVerifiedResult TABLE (ErrorId INT, ErrorMessage VARCHAR(200))

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
	IF EXISTS 
		(
			SELECT TOP 1 1 
			FROM LicenseeTransferCode lc WITH(NOLOCK)
				INNER JOIN CustDB.dbo.custInfo c WITH(NOLOCK)
					ON c.custid = lc.CustID AND c.roleid = 1
			WHERE 
				lc.LicenseeName = @LicenseeName
				AND lc.StatusID = 1
		)
	BEGIN
		INSERT INTO @tblVerifiedResult
		SELECT '202' AS ErrorCode, 'The Licensee already has another ON licensee code' AS ErrorMessage
	END
	
	SELECT t.ErrorId, t.ErrorMessage
	FROM @tblVerifiedResult t

END