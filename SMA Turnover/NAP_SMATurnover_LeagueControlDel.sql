ALTER PROCEDURE [dbo].[NAP_SMATurnover_LeagueControlDel]
	@LeagueID INT,

	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20140416
	Task : delete turnover setting of league
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		
	Example: EXEC NAP_SMATurnover_LeagueControlDel @LeagueID = 33828, @UserID = 8, @IP ='10.10.8.56'
	
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
		OR NOT EXISTS (SELECT 1 FROM DownlineTo_LeagueControl WITH (NOLOCK) WHERE LeagueID = @LeagueID)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid league.'
		RETURN
	END			
	
	DECLARE @Value INT
	SELECT @Value = Value FROM DownlineTo_LeagueControl WITH (NOLOCK) WHERE LeagueID = @LeagueID

	DELETE DownlineTo_LeagueControl WHERE LeagueID = @LeagueID

	IF @Value <> 0
	BEGIN
		IF NOT EXISTS (	SELECT 1 
						FROM DownlineTo_SportControl sc WITH (NOLOCK) 
							INNER JOIN bodb02.dbo.league l WITH (NOLOCK) ON l.sporttype = sc.sportID
						WHERE l.leagueid = @LeagueID)
			EXEC bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 3, @EventID = @LeagueID
		ELSE
			EXEC bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 5, @EventID = @LeagueID
	END

	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<NAP_SMATurnover_LeagueControlDel LeagueID="' + COALESCE(CAST(@LeagueID AS VARCHAR(10)), SPACE(1)) + '" ' 					
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
				@Duration = @duration		
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<NAP_SMATurnover_LeagueControlDel LeagueID="' + COALESCE(CAST(@LeagueID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ ERROR_MESSAGE() + '" />'		

		EXEC DBTXN.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 30002,
				@TrackingValue = @LogData,
				@Duration = @duration		
	END CATCH
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_LeagueControlDel] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_LeagueControlDel] TO [vnteam]