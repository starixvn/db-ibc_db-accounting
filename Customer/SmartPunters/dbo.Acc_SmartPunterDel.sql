ALTER PROCEDURE [dbo].[Acc_SmartPunterDel]
	@custid		INT,
	@userid		INT,
	@IP			VARCHAR(50),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Johnson
		Date: 2014-04-24
		Task: Remove customer from smart punter list
		DB: DBTXN/CustDB
		
		Revisions:
	*/ 
BEGIN
	SET NOCOUNT ON 
	
	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()
	
	--Check permission
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[ManageSmartPunter]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	
	IF NOT EXISTS (SELECT 1 FROM SmartPunterList WITH (NOLOCK) WHERE CustID = @CustID)
	BEGIN
		SELECT @ErrCode = 101
		SELECT @ErrMsg = 'This account doesn''t exist in the monitoring list.'
		RETURN
	END		
	
	DELETE SmartPunterList  WITH (ROWLOCK) WHERE CustID = @CustID
			
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = 102
		SELECT @ErrMsg = 'Delete account unsuccessfuly.'
		RETURN
	END
	
	-- write log
	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<Acc_SmartPunterDel ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '												
					+ 'ErrMsg="' + coalesce(@ErrMsg,space(1))+'" '
					+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'
					
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @userid,
			@Custid = @CustID,
			@ActionID = 646,
			@TrackingValue = @LogData,
			@Duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_SmartPunterDel ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '												
					+ 'ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1))+'" '
					+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'
					
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @userid,
			@Custid = @CustID,
			@ActionID = 646
			@TrackingValue = @LogData,
			@Duration = @duration
	END CATCH
END
GO

GRANT EXECUTE ON [dbo].[Acc_SmartPunterDel] TO [bodbAdminNet]