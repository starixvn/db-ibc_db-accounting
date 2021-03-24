/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_LicenseeTransfer_Update
	@LicenseeInfo		VARCHAR(MAX)
	,@LastMonthDate		SMALLDATETIME
	,@LastTransferDate	DATETIME
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			VARCHAR(4000) = '' OUTPUT
AS
/*
	Create: 20190806@Bobby
	Task: 112454 - NAP - Automate the Finance Transfer process for Licensee 
	DB: DBCUST/bodb_Licensee

	Revisions:
		- 20190806@Bobby: Update Licensee last month transfer information [redmine: #118247]
		- 20210315@Sol: NAP - Enhance Manage Licensee Code to support change base currency of licensees - [Redmine: #151607]
		 
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @xmlLicenseeInfo	XML
	DECLARE @tempLicenseeInfo	TABLE (LicenseeName VARCHAR(50), CustId INT, FromDate DATE)
	
	SELECT @ErrCode		= 0
		,@ErrMsg		= ''

	BEGIN TRY
		SELECT @xmlLicenseeInfo	= CONVERT(XML, @LicenseeInfo)	
	
		INSERT INTO @tempLicenseeInfo (LicenseeName, CustId, FromDate)
		SELECT LicenseeName, CustId, FromDate
		FROM (
			SELECT 
				T.C.value('./@l', 'VARCHAR(50)') AS LicenseeName,
				T.C.value('./@c', 'VARCHAR(50)') AS CustId,
				T.C.value('./@fd', 'VARCHAR(50)') AS FromDate
			FROM @xmlLicenseeInfo.nodes('/root/r') AS T(C)
		) AS lic

		UPDATE code
		SET LastMonthDate = @LastMonthDate
			,LastTransferDate = @LastTransferDate
		FROM bodb_licensee.dbo.LicenseeTransferCode code WITH(ROWLOCK, UPDLOCK)
		INNER JOIN @tempLicenseeInfo AS pol
			ON code.LicenseeName = pol.LicenseeName AND pol.CustId = code.CustID AND pol.FromDate = code.FromDate
	END TRY
	BEGIN CATCH 
		SELECT @ErrCode	= 999
			,@ErrMsg	= 'Source: ' + ERROR_PROCEDURE() + '. Line:' + CAST(ERROR_LINE() AS VARCHAR(10)) + '. Message: ' + ERROR_MESSAGE()
	END CATCH

END
GO
