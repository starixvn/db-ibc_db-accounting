ALTER PROCEDURE [dbo].[NAP_SMATurnoverEventUpd]
	@SportID INT = 0,
	@LeagueID INT = 0,
	@MatchID INT = 0,
	@Value INT,
	@UpdateMode INT = 1,

	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Update turnover setting for event
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		@UpdateMode:	1: Setting sport
						2: Setting league
						3: Setting match

		@Value:			0: Unlimited
						>0: Normal setting
	Example: EXEC Acc_SMATurnoverEventUpd @SportID = 5, @Value = 50, @UpdateMode = 3
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()
	
	--Check permission 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @UserID, @funcname = '[SMATurnoverManagement]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN

	IF @Value < 0
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid value.'
		RETURN
	END
	IF @UpdateMode = 1
	BEGIN
		IF @SportID <= 0
		BEGIN
			SELECT @ErrCode = 102, @ErrMsg = 'Invalid sport.'
			RETURN
		END
		IF @Value > 0
		BEGIN
			UPDATE DownlineTo_SportControl WITH (ROWLOCK,UPDLOCK)
			SET Value = @Value
			WHERE SportID = @SportID
			
			IF @@ROWCOUNT = 0
				INSERT INTO DownlineTo_SportControl (SportID, Value)
				VALUES (@SportID, @Value)
		END
		ELSE --@Value = 0
		BEGIN
			DELETE DownlineTo_SportControl WHERE SportID = @SportID
		END
	END

	IF @UpdateMode = 2
	BEGIN
		IF @LeagueID <= 0
		BEGIN
			SELECT @ErrCode = 103, @ErrMsg = 'Invalid league.'
			RETURN
		END		

		UPDATE DownlineTo_LeagueControl WITH (ROWLOCK,UPDLOCK)
		SET Value = @Value
		WHERE LeagueID = @LeagueID
			
		IF @@ROWCOUNT = 0
			INSERT INTO DownlineTo_LeagueControl (LeagueID, Value)
			VALUES (@LeagueID, @Value)		
	END

	IF @UpdateMode = 3
	BEGIN
		IF @MatchID <= 0
		BEGIN
			SELECT @ErrCode = 104, @ErrMsg = 'Invalid match.'
			RETURN
		END		

		IF EXISTS (SELECT 1 FROM bodb02.dbo.match WITH (NOLOCK) WHERE matchid = @MatchID AND eventstatus = 'completed')
		BEGIN
			SELECT @ErrCode = 105, @ErrMsg = 'You are not allowed to update max turnover of a settled match.'
			RETURN
		END

		UPDATE DownlineTo_MatchControl WITH (ROWLOCK,UPDLOCK)
		SET Value = @Value
		WHERE MatchID = @MatchID
			
		IF @@ROWCOUNT = 0
			INSERT INTO DownlineTo_MatchControl (MatchID, Value)
			VALUES (@MatchID, @Value)		
	END

	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<NAP_SMATurnoverEventUpd SportID="' + COALESCE(CAST(@SportID AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'LeagueID="' + COALESCE(CAST(@LeagueID AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'Value="' + COALESCE(CAST(@Value AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'UpdateMode="' + COALESCE(CAST(@UpdateMode AS VARCHAR(5)), SPACE(1)) + '" ' 
					
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
							
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 637,
				@TrackingValue = @LogData,
				@Duration = @duration		
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<NAP_SMATurnoverEventUpd SportID="' + COALESCE(CAST(@SportID AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'LeagueID="' + COALESCE(CAST(@LeagueID AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'Value="' + COALESCE(CAST(@Value AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'UpdateMode="' + COALESCE(CAST(@UpdateMode AS VARCHAR(5)), SPACE(1)) + '" ' 
					
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ ERROR_MESSAGE() + '" />'

		EXEC DBTXN.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 637,
				@TrackingValue = @LogData,
				@Duration = @duration		
	END CATCH
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnoverEventUpd] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnoverEventUpd] TO [vnteam]