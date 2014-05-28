ALTER PROCEDURE [dbo].[NAP_SMATurnover_LeagueControlUpd]
	@LeagueID INT,
	@Value INT,

	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Update turnover setting for league
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		
	Example: EXEC NAP_SMATurnover_LeagueControlUpd @LeagueID = 33828, @Value = 50, @UserID = 8, @IP ='10.10.8.56'
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()
	
	--Check permission 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @UserID, @funcname = '[ControlTOByEvent]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	
	IF @LeagueID <= 0
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid league.'
		RETURN
	END		

	IF @Value < 0 OR @Value > 999
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Invalid value.'
		RETURN
	END	

	DECLARE @OldValue INT
	SELECT @OldValue = Value FROM DownlineTo_LeagueControl WITH(NOLOCK) WHERE LeagueID = @LeagueID
	IF @OldValue IS NOT NULL AND @OldValue = @Value
		RETURN

	UPDATE DownlineTo_LeagueControl WITH (ROWLOCK,UPDLOCK)
	SET Value = @Value
	WHERE LeagueID = @LeagueID
			
	IF @@ROWCOUNT = 0
	BEGIN
		INSERT INTO DownlineTo_LeagueControl (LeagueID, Value)
		VALUES (@LeagueID, @Value)	
		IF @Value = 0
			EXEC bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 3, @EventID = @LeagueID
		ELSE
		BEGIN
			IF EXISTS (	SELECT 1 
						FROM DownlineTo_SportControl sc WITH (NOLOCK) 
							INNER JOIN bodb02.dbo.league l WITH (NOLOCK) ON l.sporttype = sc.sportID
						WHERE l.leagueid = @LeagueID)
				EXEC bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 2, @EventID = @LeagueID
		END
	END
	ELSE
	BEGIN
		IF @Value <> 0 AND @OldValue <> 0
			EXEC bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 4, @EventID = @LeagueID
		IF @Value = 0 AND @OldValue <> 0
			EXEC bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 3, @EventID = @LeagueID			
	END

	DECLARE @LogData NVARCHAR(4000), @TrackingValue2 NVARCHAR(4000)
	SELECT @LogData = '<NAP_SMATurnover_LeagueControlUpd LeagueID="' + COALESCE(CAST(@LeagueID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'Value="' + COALESCE(CAST(@Value AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
	
	SELECT @TrackingValue2 = '<NAP_SMATurnover_LeagueControlUpd LeagueID="' + COALESCE(CAST(@LeagueID AS VARCHAR(10)), SPACE(1)) + '" ' 					
							+ 'Value="' + COALESCE(CAST(ISNULL(@OldValue,'') AS VARCHAR(20)), SPACE(1)) + '" ' 
							+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
							+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
												
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 30001,
				@TrackingValue = @LogData,
				@TrackingValue2 = @TrackingValue2,
				@Duration = @duration		
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<NAP_SMATurnover_LeagueControlUpd LeagueID="' + COALESCE(CAST(@LeagueID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'Value="' + COALESCE(CAST(@Value AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ ERROR_MESSAGE() + '" />'
		
		SELECT @TrackingValue2 = '<NAP_SMATurnover_LeagueControlUpd LeagueID="' + COALESCE(CAST(@LeagueID AS VARCHAR(10)), SPACE(1)) + '" ' 					
							+ 'Value="' + COALESCE(CAST(ISNULL(@OldValue,'') AS VARCHAR(20)), SPACE(1)) + '" ' 
							+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
							+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="'+ ERROR_MESSAGE() + '" />'

		EXEC DBTXN.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 30001,
				@TrackingValue = @LogData,
				@TrackingValue2 = @TrackingValue2,
				@Duration = @duration		
	END CATCH
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_LeagueControlUpd] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_LeagueControlUpd] TO [vnteam]