ALTER PROCEDURE [dbo].[Acc_SmartPunterIns]
	@username	VARCHAR(50),
	@remark		NVARCHAR(200) = '',
	@userid		INT,
	@IP			VARCHAR(30),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
	
AS
	/*
		Created: Johnson
		Date: 2014-04-24
		Task: Insert customer into smart punter list
		DB: DBTXN/CustDB
		
		Revisions:
	*/ 
BEGIN
	SET NOCOUNT ON
	
	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()
	
	Declare @CustID int,
			@RoleID tinyint,
			@Currency int
	
	--Check permission
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[ManageSmartPunter]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	
	EXEC DBACC.bodb02.dbo.Acc_CustomerSelInfoByUsername 
		@UserName = @UserName,
		@CustID = @CustID OUTPUT,
		@RoleID = @RoleID OUTPUT,
		@Currency = @Currency OUTPUT
	
	IF @CustID = 0
	BEGIN
		SELECT @ErrCode = 100
		SELECT @ErrMsg = 'This account doesn''t exist in IBC system.'
		RETURN
	END
	
	IF @RoleID <> 1 
	BEGIN
		SELECT @ErrCode = 101
		SELECT @ErrMsg = 'This account is not a member.'
		RETURN
	END
	
	IF EXISTS (SELECT 1 FROM SmartPunterList WITH(NOLOCK) WHERE CustID = @CustID)
	BEGIN
		SELECT @ErrCode = 102
		SELECT @ErrMsg = 'This account is already existed in the monitoring list.'
		RETURN
	END
	
	INSERT INTO SmartPunterList 
		(
		    [custid]
           ,[creator]
           ,[createdate]          
           ,[remark]
		)
	VALUES
		(		
			@CustID,
			@userid, 					
			GETDATE(),						
			@Remark
		)

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = 103
		SELECT @ErrMsg = 'Add smart punter unsuccessfuly.'
		RETURN
	END		
	
	-- write log
	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<Acc_SmartPunterIns UserName="' + COALESCE(@UserName,SPACE(1)) + '" ' 
							+ 'Remark="' + COALESCE(@Remark,SPACE(1)) + '" '	
							+ 'ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="' + coalesce(@ErrMsg,space(1))+'" '
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																		

	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @userid,
			@Custid = @CustID,
			@ActionID = 644,
			@TrackingValue = @LogData,
			@Duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_SmartPunterIns UserName="' + COALESCE(@UserName,SPACE(1)) + '" ' 
							+ 'Remark="' + COALESCE(@Remark,SPACE(1)) + '" '	
							+ 'ErrCode="' + coalesce(cast(ERROR_MESSAGE() as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="' + coalesce(@ErrMsg,space(1))+'" '
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'	
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @userid,
			@Custid = @CustID,
			@ActionID = 644,
			@TrackingValue = @LogData,
			@Duration = @duration
	END CATCH
	
END
GO

GRANT EXECUTE ON [dbo].[Acc_SmartPunterIns] TO [bodbAdminNet]