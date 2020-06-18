/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_LicenseeTransferCode_Ins
(
	@LicenseeName VARCHAR(50),
	@LicenseeCode NVARCHAR(50),
	@CodeStatus TINYINT,
	@UserId INT = 0,
	@IP VARCHAR(50) = '',
	@Language VARCHAR(20) = 'E',
	@ErrorCode INT = 0 OUTPUT,
	@ErrorMessage VARCHAR(1000) = '' OUTPUT
)
AS
/*
	Created: 20200615@Sol
	Task : update licensee code
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

	DECLARE @startRun	DATETIME
	DECLARE @endRun		DATETIME
	DECLARE @duration	INT
	DECLARE @ActionID	INT = 95026
	DECLARE @CodeStatus_Old TINYINT = NULL

	DECLARE @tblVerifiedResult TABLE (ErrorId INT, ErrorMessage VARCHAR(200))
	DECLARE @custId INT

	SELECT @startRun = GETDATE(), @ErrorCode = 0, @ErrorMessage = ''

	---- check error
	INSERT INTO @tblVerifiedResult
	EXEC dbo.Acc_LicenseeUpdVerify
		@LicenseeName = @LicenseeName,
		@LicenseeCode = @LicenseeCode

	IF EXISTS (SELECT 1 FROM @tblVerifiedResult WHERE ErrorId IN (201, 202))
	BEGIN
		
		SELECT @ErrorCode = '404', @ErrorMessage = 'Update failed!'
		SELECT ErrorId, ErrorMessage FROM @tblVerifiedResult WHERE ErrorId IN (201, 202)
		RETURN

	END

	SELECT @custId = custId FROM CustDB.dbo.custInfo c WITH(NOLOCK) WHERE c.username = @LicenseeCode AND c.roleid = 1

	BEGIN TRY
		
		IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.LicenseeTransferCode lc WITH (NOLOCK) WHERE lc.LicenseeName = @LicenseeName AND lc.CustID = @custId)
		BEGIN
			INSERT INTO LicenseeTransferCode (LicenseeName, CustID, StatusID)
			SELECT @LicenseeName, @custId, @CodeStatus
		END
		
	END TRY
	BEGIN CATCH

		SELECT @ErrorCode = ERROR_NUMBER(), @ErrorMessage = ERROR_MESSAGE()
		RETURN
		
	END CATCH

	DECLARE @LogSPData VARCHAR(MAX)

	SELECT @LogSPData = '<Acc_LicenseeUpdNewLicenseeCode ' +
		  'LicenseeName="'+ coalesce(cast(@LicenseeName as varchar(50)),space(1)) + '" '+  
		  'LicenseeCode="'+ coalesce(cast(@LicenseeCode as varchar(50)),space(1)) + '" '+  	
		  'CodeStatus="'+ coalesce(cast(@CodeStatus as varchar(2)),space(1))+'" '+  
		  'ErrorCode="'+ coalesce(cast(@ErrorCode as varchar(50)),space(1)) + '" '+  
		  'ErrorMessage="'+ coalesce(cast(@ErrorMessage as varchar(400)),space(1))+'" '+  
		  'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+  	
		  'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+  
		  'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
	  
	SET @endRun		= GETDATE()  
	SET @duration	= DATEDIFF (MILLISECOND, @startRun, @endRun)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
			@UserID				= @UserID
			,@CustID			= @CustID
			,@ActionID			= @ActionID
			,@TrackingValue		= @LogSPData
			,@TrackingValue2	= ''
			,@duration			= @duration
	END TRY 
	BEGIN CATCH
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
			@UserID				= @UserID
			,@CustID			= @CustID
			,@ActionID			= @ActionID
			,@TrackingValue		= @LogSPData
			,@TrackingValue2	= ''
			,@duration			= @duration
	END CATCH

END