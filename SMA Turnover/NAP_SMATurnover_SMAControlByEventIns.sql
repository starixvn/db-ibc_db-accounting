ALTER PROCEDURE [dbo].[NAP_SMATurnover_SMAControlByEventIns]
	@SMAName VARCHAR(30),
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
	Task : Add configure SMA TO setting by event
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		
	Example: EXEC NAP_SMATurnover_SMAControlByEventIns @SMAName = 'SuperTest1', @MatchID = 6880531, @Value = 50, @UserID = 8, @IP ='10.10.8.56'
	
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

	IF @Value < 0 OR @Value > 999
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid value.'
		RETURN
	END	

	DECLARE @SMAID INT, @roleID INT, @srecommend INT, @mrecommend INT, @recommend INT
	SELECT @SMAID = NULL
	SELECT @SMAID = CustID, @roleID = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
	FROM bodb02.dbo.Customer WITH (NOLOCK)
	WHERE username = @SMAName
		AND CustID NOT IN (SELECT CustID FROM bodb02.dbo.Dep_CustSuper WITH (NOLOCK))
	
	IF @SMAID IS NULL OR @roleID > 4
	BEGIN
			SELECT @ErrCode = 102, @ErrMsg = 'Invalid Username!'
			RETURN
	END
	ELSE
	BEGIN
		IF (@roleID = 4 AND EXISTS (SELECT 1 FROM DBACC.bodb_ACC.dbo.Acc_CustDirect WITH (NOLOCK) WHERE custid = @SMAID))
			OR (@roleID = 3 AND NOT EXISTS (SELECT 1 FROM DBACC.bodb_ACC.dbo.Acc_CustDirect WITH (NOLOCK) WHERE custid = @srecommend))
			OR (@roleID = 2 AND NOT EXISTS (SELECT 1 FROM DBACC.bodb_ACC.dbo.Acc_CustDirect WITH (NOLOCK) WHERE custid = @mrecommend))
			OR @roleID = 1
		BEGIN
			SELECT @ErrCode = 102, @ErrMsg = 'Invalid Username!'
			RETURN
		END		
	END

	IF EXISTS (SELECT 1 FROM DownlineTo_Match_SMAControl WHERE SMAID = @SMAID AND MatchID = @MatchID)
	BEGIN
			SELECT @ErrCode = 103, @ErrMsg = 'The setting of this customer already existed!'
			RETURN
	END

	DECLARE @SportID INT, @LeagueID INT
	SELECT @SportID = m.sporttype, @LeagueID = m.leagueid 
	FROM bodb02.dbo.match m WITH (NOLOCK) 
	WHERE m.matchid = @MatchID

	DECLARE @SportValue INT, @LeagueValue INT, @MatchValue INT
	SELECT @SportValue = NULL, @LeagueValue = NULL, @MatchValue = NULL

	SELECT @SportValue = Value FROM DownlineTo_SportControl sc WITH (NOLOCK) WHERE sc.SportID = @SportID
	SELECT @LeagueValue = Value FROM DownlineTo_LeagueControl lc WITH (NOLOCK) WHERE lc.leagueID = @LeagueID
	SELECT @MatchValue = Value FROM DownlineTo_MatchControl mc WITH (NOLOCK) WHERE mc.MatchID = @MatchID

	INSERT INTO DownlineTo_Match_SMAControl (SMAID, MatchID, Value)
	VALUES (@SMAID, @MatchID, @Value)	

	IF @Value = 0
		EXEC bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 11, @EventID = @MatchID, @SMAID = @SMAID
	ELSE
	BEGIN			
		IF (@MatchValue IS NOT NULL AND @MatchValue <> 0) 
		OR (@LeagueValue IS NOT NULL AND @LeagueValue <> 0 AND (@MatchValue <> 0 OR @MatchValue IS NULL))
		OR (@SportValue IS NOT NULL AND (@LeagueValue <> 0 OR @LeagueValue IS NULL) AND (@MatchValue <> 0 OR @MatchValue IS NULL))
			EXEC bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 10, @EventID = @MatchID, @SMAID = @SMAID	
	END

	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<NAP_SMATurnover_SMAControlByEventIns SMAName="' + COALESCE(@SMAName, SPACE(1)) + '" ' 					
					+ 'MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'Value="' + COALESCE(CAST(@Value AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
														
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 30005,
				@TrackingValue = @LogData,
				@Duration = @duration		
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<NAP_SMATurnover_SMAControlByEventIns SMAName="' + COALESCE(@SMAName, SPACE(1)) + '" ' 					
					+ 'MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'Value="' + COALESCE(CAST(@Value AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ ERROR_MESSAGE() + '" />'		

		EXEC DBTXN.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 30005,
				@TrackingValue = @LogData,
				@Duration = @duration		
	END CATCH
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_SMAControlByEventIns] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_SMAControlByEventIns] TO [vnteam]