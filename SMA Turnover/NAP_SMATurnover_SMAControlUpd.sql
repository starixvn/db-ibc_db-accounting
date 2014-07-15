ALTER PROCEDURE [dbo].[NAP_SMATurnover_SMAControlUpd]
	@SMAID INT,
	@Offset INT,

	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Update turnover setting for SMA
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		
	Example: EXEC NAP_SMATurnover_SMAControlUpd @SMAID = 1176070, @Offset = 5, @UserID = 8, @IP ='10.10.8.56'
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()
	
	--Check permission 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @UserID, @funcname = '[ControlTOBySMA]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	
	IF @SMAID <= 0
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Super/Master/Agent.'
		RETURN
	END		

	IF @Offset < -999 OR @Offset > 999
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Invalid offset.'
		RETURN
	END	

	DECLARE @OldOffset INT
	SELECT @OldOffset = Offset FROM DownlineTo_SMAControl WITH(NOLOCK) WHERE SMAID = @SMAID
	IF @OldOffset IS NULL OR @OldOffset = @Offset
		RETURN

	UPDATE DownlineTo_SMAControl WITH (ROWLOCK,UPDLOCK)
	SET Offset = @Offset
	WHERE SMAID = @SMAID			

	IF @OldOffset <> 0 AND @Offset = 0
		EXEC bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 14, @SMAID = @SMAID, @Offset = @Offset
	IF @OldOffset <> 0 AND @Offset <> 0
		EXEC bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 15, @SMAID = @SMAID, @Offset = @OldOffset

	DECLARE @LogData NVARCHAR(4000), @TrackingValue2 NVARCHAR(4000)
	SELECT @LogData = '<NAP_SMATurnover_SMAControlUpd SMAID="' + COALESCE(CAST(@SMAID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'Offset="' + COALESCE(CAST(@Offset AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
	
	SELECT @TrackingValue2 = '<NAP_SMATurnover_SMAControlUpd SMAID="' + COALESCE(CAST(@SMAID AS VARCHAR(10)), SPACE(1)) + '" ' 					
							+ 'Offset="' + COALESCE(CAST(ISNULL(@OldOffset,'') AS VARCHAR(20)), SPACE(1)) + '" ' 
							+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
							+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
												
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 30009,
				@TrackingValue = @LogData,
				@TrackingValue2 = @TrackingValue2,
				@Duration = @duration		
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<NAP_SMATurnover_SMAControlUpd SMAID="' + COALESCE(CAST(@SMAID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'Offset="' + COALESCE(CAST(@Offset AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ ERROR_MESSAGE() + '" />'
		
		SELECT @TrackingValue2 = '<NAP_SMATurnover_SMAControlUpd SMAID="' + COALESCE(CAST(@SMAID AS VARCHAR(10)), SPACE(1)) + '" ' 					
							+ 'Offset="' + COALESCE(CAST(ISNULL(@OldOffset,'') AS VARCHAR(20)), SPACE(1)) + '" ' 
							+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
							+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="'+ ERROR_MESSAGE() + '" />'

		EXEC DBTXN.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 30009,
				@TrackingValue = @LogData,
				@TrackingValue2 = @TrackingValue2,
				@Duration = @duration		
	END CATCH
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_SMAControlUpd] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_SMAControlUpd] TO [vnteam]