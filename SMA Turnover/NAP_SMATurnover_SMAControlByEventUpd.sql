ALTER PROCEDURE [dbo].[NAP_SMATurnover_SMAControlByEventUpd]
	@SMAID INT,
	@MatchID INT,
	@Value INT,

	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Update configure SMA TO setting by event
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		
	Example: EXEC NAP_SMATurnover_SMAControlByEventUpd @SMAID = 1176070, @MatchID = 6880531, @Value = 50, @UserID = 8, @IP ='10.10.8.56'
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()
	
	--Check permission 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @UserID, @funcname = '[ControlTOBySMAEvent]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	
	IF @SMAID <= 0
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Super/Master/Agent.'
		RETURN
	END		

	IF @Value < 0 OR @Value > 999
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Invalid value.'
		RETURN
	END	

	DECLARE @OldValue INT
	SELECT @OldValue = Value FROM DownlineTo_Match_SMAControl WITH(NOLOCK) WHERE SMAID = @SMAID AND MatchID = @MatchID
	IF @OldValue IS NULL OR @OldValue = @Value
		RETURN

	UPDATE DownlineTo_Match_SMAControl WITH (ROWLOCK,UPDLOCK)
	SET Value = @Value
	WHERE SMAID = @SMAID AND MatchID = @MatchID			

	IF @Value <> 0 AND @OldValue <> 0
			EXEC bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 12, @EventID = @MatchID, @SMAID = @SMAID	
	IF @Value = 0 AND @OldValue <> 0
		EXEC bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 11, @EventID = @MatchID, @SMAID = @SMAID

	DECLARE @LogData NVARCHAR(4000), @TrackingValue2 NVARCHAR(4000)
	SELECT @LogData = '<NAP_SMATurnover_SMAControlByEventUpd SMAID="' + COALESCE(CAST(@SMAID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'Value="' + COALESCE(CAST(@Value AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
	
	SELECT @TrackingValue2 = '<NAP_SMATurnover_SMAControlByEventUpd SMAID="' + COALESCE(CAST(@SMAID AS VARCHAR(10)), SPACE(1)) + '" ' 					
							+ 'MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 					
							+ 'Value="' + COALESCE(CAST(@OldValue AS VARCHAR(20)), SPACE(1)) + '" ' 
							+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
							+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
												
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 30006,
				@TrackingValue = @LogData,
				@TrackingValue2 = @TrackingValue2,
				@Duration = @duration		
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<NAP_SMATurnover_SMAControlByEventUpd SMAID="' + COALESCE(CAST(@SMAID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'Value="' + COALESCE(CAST(@Value AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ ERROR_MESSAGE() + '" />'
		
		SELECT @TrackingValue2 = '<NAP_SMATurnover_SMAControlByEventUpd SMAID="' + COALESCE(CAST(@SMAID AS VARCHAR(10)), SPACE(1)) + '" ' 					
							+ 'MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 					
							+ 'Value="' + COALESCE(CAST(@OldValue AS VARCHAR(20)), SPACE(1)) + '" ' 
							+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
							+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="'+ ERROR_MESSAGE() + '" />'

		EXEC DBTXN.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 30006,
				@TrackingValue = @LogData,
				@TrackingValue2 = @TrackingValue2,
				@Duration = @duration		
	END CATCH
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_SMAControlByEventUpd] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_SMAControlByEventUpd] TO [vnteam]