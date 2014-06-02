ALTER PROCEDURE [dbo].[Acc_SmartPunterUpd]
	@CustID		INT,
	@remark		VARCHAR(200) = ''
	@userid		INT,
	@IP			VARCHAR(50),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT	
AS
	/*
		Created: Johnson
		Date: 2014-04-24
		Task: Update info for smart punter
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
		
	IF NOT EXISTS (SELECT 1 FROM SmartPunterList WITH(NOLOCK) WHERE CustID = @CustID)
	BEGIN
		SELECT @ErrCode = 100
		SELECT @ErrMsg = 'This account doesn''t exist in the monitoring list.'
		RETURN
	END
	
	DECLARE @Old_Remark NVARCHAR(200)
	
	SELECT @Old_Remark = Remark 
	FROM SmartPunterList WITH(NOLOCK) 
	WHERE CustID = @CustID
	
	UPDATE SmartPunterList WITH(ROWLOCK,UPDLOCK)
	SET	Remark = @Remark,
		lastmodifytime = GETDATE(),
		lastmodifyuser = @userid		
	WHERE CustID = @CustID
	
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = 101
		SELECT @ErrMsg = 'Update account unsuccessfuly.'
		RETURN
	END
	
	-- write log
	DECLARE @LogData VARCHAR(4000),	
			@LogData_Old VARCHAR(4000)

	SELECT @LogData = '<Acc_SmartPunterUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)),SPACE(1)) + '" ' 
							+ 'Remark="' + COALESCE(@Remark,SPACE(1)) + '" '
							+ 'ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="' + coalesce(@ErrMsg,space(1))+'" '
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																		

	SELECT @LogData_Old = '<Acc_SmartPunterUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)),SPACE(1)) + '" ' 
							+ 'Remark="' + COALESCE(@Old_Remark,SPACE(1)) + '" '	
							+ 'ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="' + coalesce(@ErrMsg,space(1))+'" '
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @userid,
			@Custid = @CustID,
			@ActionID = 645,
			@TrackingValue = @LogData,
			@TrackingValue2 = @LogData_Old,
			@Duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_SmartPunterUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)),SPACE(1)) + '" ' 
							+ 'Remark="' + COALESCE(@Remark,SPACE(1)) + '" '
							+ 'ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1))+'" '
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																		

		SELECT @LogData_Old = '<Acc_SmartPunterUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)),SPACE(1)) + '" ' 
							+ 'Remark="' + COALESCE(@Old_Remark,SPACE(1)) + '" '	
							+ 'ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1))+'" '
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @userid,
			@Custid = @CustID,
			@ActionID = 645,
			@TrackingValue = @LogData,
			@TrackingValue2 = @LogData_Old,
			@Duration = @duration
	END CATCH
	
END 
GO

GRANT EXECUTE ON [dbo].[Acc_SmartPunterUpd] TO [bodbAdminNet]