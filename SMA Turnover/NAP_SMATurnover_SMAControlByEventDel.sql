ALTER PROCEDURE [dbo].[NAP_SMATurnover_SMAControlByEventDel]
	@SMAID INT,
	@MatchID INT,

	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Delete SMA turnover setting by event
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		
	Example: EXEC NAP_SMATurnover_SMAControlByEventDel @SMAID = 1176070, @MatchID = 6880531, @UserID = 8, @IP ='10.10.8.56'
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()
	
	----Check permission 
	--EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @UserID, @funcname = '[ConfigureSMATOByMatch]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	--IF @ErrCode <> 0
	--	RETURN
	
	IF NOT EXISTS (SELECT 1 FROM DownlineTo_Match_SMAControl WITH (NOLOCK) WHERE SMAID = @SMAID AND MatchID = @MatchID)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = ''
		RETURN
	END			

	DECLARE @Value INT, @SportID INT, @LeagueID INT

	SELECT @SportID = m.sporttype, @LeagueID = m.leagueid 
	FROM bodb02.dbo.match m WITH (NOLOCK) 
	WHERE m.matchid = @MatchID

	SELECT @Value = Value FROM DownlineTo_Match_SMAControl WITH (NOLOCK) WHERE MatchID = @MatchID AND SMAID = @SMAID

	DELETE DownlineTo_Match_SMAControl WHERE SMAID = @SMAID AND MatchID = @MatchID			

	IF @Value <> 0
	BEGIN
		IF NOT EXISTS (	SELECT 1 
						FROM DownlineTo_SportControl sc WITH (NOLOCK) WHERE sc.SportID = @SportID)
		AND NOT EXISTS (SELECT 1 
						FROM DownlineTo_LeagueControl lc WITH (NOLOCK) WHERE lc.leagueID = @LeagueID)			
		AND NOT EXISTS (SELECT 1 
						FROM DownlineTo_MatchControl mc WITH (NOLOCK) WHERE mc.MatchID = @MatchID)	
			EXEC bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 11, @EventID = @MatchID, @SMAID = @SMAID
		ELSE
			EXEC bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 13, @EventID = @MatchID, @SMAID = @SMAID	
	END	

	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<NAP_SMATurnover_SMAControlByEventDel SMAID="' + COALESCE(CAST(@SMAID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 	
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'	
												
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 30007,
				@TrackingValue = @LogData,
				@Duration = @duration		
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<NAP_SMATurnover_SMAControlByEventDel SMAID="' + COALESCE(CAST(@SMAID AS VARCHAR(10)), SPACE(1)) + '" ' 	
					+ 'MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ ERROR_MESSAGE() + '" />'		

		EXEC DBTXN.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 30007,
				@TrackingValue = @LogData,
				@Duration = @duration		
	END CATCH
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_SMAControlByEventDel] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_SMAControlByEventDel] TO [vnteam] 