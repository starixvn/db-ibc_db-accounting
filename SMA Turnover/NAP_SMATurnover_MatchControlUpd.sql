ALTER PROCEDURE [dbo].[NAP_SMATurnover_MatchControlUpd]
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
	Task : Update turnover setting for match
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		
	Example: EXEC NAP_SMATurnover_MatchControlUpd @MatchID = 6880531, @Value = 50, @UserID = 8, @IP ='10.10.8.56'
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()
	
	--Check permission 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @UserID, @funcname = '[ConfigureTOByEvent]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	
	IF @MatchID <= 0
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid match.'
		RETURN
	END		

	IF @Value < 0
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Invalid value.'
		RETURN
	END	

	IF EXISTS (SELECT 1 FROM bodb02.dbo.match WITH (NOLOCK) WHERE matchid = @MatchID AND eventstatus = 'completed')
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'You are not allowed to update max turnover of a settled match.'
		RETURN
	END

	DECLARE @OldValue INT
	SELECT @OldValue = Value FROM DownlineTo_MatchControl WITH(NOLOCK) WHERE MatchID = @MatchID
	IF @OldValue IS NOT NULL AND @OldValue = @Value
		RETURN

	UPDATE DownlineTo_MatchControl WITH (ROWLOCK,UPDLOCK)
	SET Value = @Value
	WHERE MatchID = @MatchID
			
	IF @@ROWCOUNT = 0
		INSERT INTO DownlineTo_MatchControl (MatchID, Value)
		VALUES (@MatchID, @Value)	
	ELSE
		EXEC bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 2, @EventID = @MatchID	

	DECLARE @LogData NVARCHAR(4000), @TrackingValue2 NVARCHAR(4000)
	SELECT @LogData = '<NAP_SMATurnover_MatchControlUpd MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'Value="' + COALESCE(CAST(@Value AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
	
	SELECT @TrackingValue2 = '<NAP_SMATurnover_MatchControlUpd MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 					
							+ 'Value="' + COALESCE(CAST(ISNULL(@OldValue,'') AS VARCHAR(20)), SPACE(1)) + '" ' 
							+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
							+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
												
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 30002,
				@TrackingValue = @LogData,
				@TrackingValue2 = @TrackingValue2,
				@Duration = @duration		
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<NAP_SMATurnover_MatchControlUpd MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'Value="' + COALESCE(CAST(@Value AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ ERROR_MESSAGE() + '" />'
		
		SELECT @TrackingValue2 = '<NAP_SMATurnover_MatchControlUpd MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 					
							+ 'Value="' + COALESCE(CAST(ISNULL(@OldValue,'') AS VARCHAR(20)), SPACE(1)) + '" ' 
							+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
							+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="'+ ERROR_MESSAGE() + '" />'

		EXEC DBTXN.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 30002,
				@TrackingValue = @LogData,
				@TrackingValue2 = @TrackingValue2,
				@Duration = @duration		
	END CATCH
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_MatchControlUpd] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_MatchControlUpd] TO [vnteam]