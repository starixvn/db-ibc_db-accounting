/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_LicenseeTransferCode_Upd
(
	@LicenseeName VARCHAR(50),
	@LicenseeCodeOld NVARCHAR(50),
	@LicenseeCode NVARCHAR(50),
	@FromDateOld DATE,
	@ToDateOld DATE,
	@FromDate DATE,
	@ToDate DATE,
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
		- 20200720@Sol: rename sp verify [Redmine: #120670]
		- 20210315@Sol: NAP - Enhance Manage Licensee Code to support change base currency of licensees - [Redmine: #151607]
		- 20210330@Sol: NAP - Enhance Manage Licensee Code to support change base currency of licensees - Phase 2 - [Redmine: #152056]

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
	DECLARE @ActionID	INT = 95027
	DECLARE @CodeStatus_Old TINYINT = NULL

	DECLARE @tblVerifiedResult TABLE (ErrorId INT, ErrorMessage VARCHAR(200))
	DECLARE @custIdOld INT,	@custId INT

	SELECT @startRun = GETDATE(), @ErrorCode = 0, @ErrorMessage = ''

	---- check error
	INSERT INTO @tblVerifiedResult
	EXEC dbo.Acc_LicenseeTransferCode_Verify
		@LicenseeName = @LicenseeName,
		@LicenseeCode = @LicenseeCode,
		@FromDateOld = @FromDateOld,
		@ToDateOld = @ToDateOld,
		@FromDate = @FromDate,
		@ToDate = @ToDate

	IF EXISTS (SELECT 1 FROM @tblVerifiedResult WHERE ErrorId IN (201, 202))
	BEGIN
		
		SELECT @ErrorCode = '404', @ErrorMessage = 'Update failed!'
		SELECT ErrorId, ErrorMessage FROM @tblVerifiedResult WHERE ErrorId IN (201, 202)
		RETURN

	END

	SELECT @custIdOld = custId FROM CustDB.dbo.custInfo c WITH(NOLOCK) WHERE c.username = @LicenseeCodeOld AND c.roleid = 1
	SELECT @custId = custId FROM CustDB.dbo.custInfo c WITH(NOLOCK) WHERE c.username = @LicenseeCode AND c.roleid = 1
	SELECT @CodeStatus_Old = StatusID FROM dbo.LicenseeTransferCode lc WITH (NOLOCK) WHERE lc.LicenseeName = @LicenseeName AND lc.CustID = @custIdOld AND lc.FromDate = @FromDateOld

	BEGIN TRY
		
		IF EXISTS (SELECT TOP 1 1 FROM dbo.LicenseeTransferCode lc WITH (NOLOCK) WHERE lc.LicenseeName = @LicenseeName AND lc.CustID = @custIdOld AND lc.FromDate = @FromDateOld)
		BEGIN

			UPDATE dbo.LicenseeTransferCode WITH(UPDLOCK)
				SET CustID = @custId,
					FromDate = @FromDate,
					ToDate = @ToDate
			WHERE LicenseeName = @LicenseeName AND CustID = @custIdOld AND FromDate = @FromDateOld

		END
		
	END TRY
	BEGIN CATCH

		SELECT @ErrorCode = ERROR_NUMBER(), @ErrorMessage = ERROR_MESSAGE()
		RETURN
		
	END CATCH

	DECLARE @LogSPData VARCHAR(MAX),  
			@LogSPData_Old VARCHAR(2000) 

	Select @LogSPData = '<Acc_LicenseeTransferCode_Upd ' +
		  'LicenseeName="'+ coalesce(cast(@LicenseeName as varchar(50)),space(1)) + '" '+  
		  'LicenseeCode="'+ coalesce(cast(@LicenseeCode as varchar(50)),space(1)) + '" '+  	
		  'FromDate="'+ coalesce(cast(@FromDate as varchar(10)),space(1))+'" '+  
		  'ToDate="'+ coalesce(cast(@ToDate as varchar(10)),space(1))+'" '+  
		  'ErrorCode="'+ coalesce(cast(@ErrorCode as varchar(50)),space(1)) + '" '+  
		  'ErrorMessage="'+ coalesce(cast(@ErrorMessage as varchar(400)),space(1))+'" '+  
		  'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+  	
		  'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+  
		  'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
	  
	SELECT @LogSPData_Old = 
							CASE 
								WHEN @CodeStatus_Old IS NULL THEN '' 
								ELSE  '<Acc_LicenseeTransferCode_Upd ' +
									  'LicenseeName="'+ coalesce(cast(@LicenseeName as varchar(50)),space(1)) + '" '+  
									  'LicenseeCode="'+ coalesce(cast(@LicenseeCodeOld as varchar(50)),space(1)) + '" '+  	
									  'FromDate="'+ coalesce(cast(@FromDateOld as varchar(10)),space(1))+'" '+  
									  'ToDate="'+ coalesce(cast(@ToDateOld as varchar(10)),space(1))+'" '+  
									  'ErrorCode="'+ coalesce(cast(@ErrorCode as varchar(50)),space(1)) + '" '+  
									  'ErrorMessage="'+ coalesce(cast(@ErrorMessage as varchar(400)),space(1))+'" '+  
									  'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+  	
									  'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+  
									  'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
							END

	SET @endRun		= GETDATE()  
	SET @duration	= DATEDIFF (MILLISECOND, @startRun, @endRun)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
			@UserID				= @UserID
			,@CustID			= @CustID
			,@ActionID			= @ActionID
			,@TrackingValue		= @LogSPData
			,@TrackingValue2	= @LogSPData_old
			,@duration			= @duration
	END TRY 
	BEGIN CATCH
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
			@UserID				= @UserID
			,@CustID			= @CustID
			,@ActionID			= @ActionID
			,@TrackingValue		= @LogSPData
			,@TrackingValue2	= @LogSPData_old
			,@duration			= @duration
	END CATCH

END