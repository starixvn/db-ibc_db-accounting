USE bodb02
GO
ALTER PROCEDURE dbo.NAP_Set_AutoPayout_SettingLeagueUpd 
	@LeagueId 			INT
	, @AutoSetting 		TINYINT
	, @IsApplyAll 		BIT
	, @AdminId 			INT
	, @IP 				VARCHAR(20) = ''
	, @ErrCode 			INT = 0 OUTPUT
	, @ErrMsg 			NVARCHAR(200) = '' OUTPUT
AS
/*	Creator: 20160303@Patrick
	Task: Auto Payout - update setting on league
	DB: DBPRO/BODB02
	
	Revisions:
		- 20160930@Bobby: #65003 - Merge Auto Payout and Inst CAL setting
		
	Param's Explanation:
		- @IsApplyAll: 0: only update on league
					   1: update on league & running match without matches in Queue
 
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @AutoSetting_Old BIT, @StarTime DATETIME, @EndTime DATETIME, @Remark VARCHAR(1024)
	
	SELECT @AutoSetting = ISNULL(@AutoSetting, 0), @StarTime = GETDATE()

	SELECT @AutoSetting_Old = ISNULL(AutoSetting, 0)
	FROM dbo.League l WITH(NOLOCK) 
	WHERE leagueid = @LeagueId
	
	--check concurrency users
	IF @AutoSetting = @AutoSetting_Old
	BEGIN
		RETURN
	END

	IF @IsApplyAll = 1
	BEGIN
		--update running match
		UPDATE m
		SET AutoSetting = @AutoSetting
		FROM dbo.match m WITH(UPDLOCK, ROWLOCK)
		WHERE m.leagueid = @LeagueId AND sporttype = 1 AND eventstatus <> 'completed'

		IF @@ERROR > 0
		BEGIN
			SELECT @ErrCode = 1001019, @ErrMsg = 'Cannot update auto payout setting on this match. Please try again.'
			RETURN
		END
	END

	IF EXISTS (SELECT TOP 1 1 
				FROM dbo.match m WITH(NOLOCK)
				WHERE m.leagueid = @LeagueId AND sporttype = 1 AND AutoSetting IS NULL)
	BEGIN
		UPDATE m
		SET AutoSetting = @AutoSetting_Old
		FROM dbo.match m WITH(UPDLOCK, ROWLOCK)
		WHERE m.leagueid = @LeagueId AND sporttype = 1 AND AutoSetting IS NULL

		IF @@ERROR > 0
		BEGIN
			SELECT @ErrCode = 1001019, @ErrMsg = 'Cannot update auto payout setting on this match. Please try again.'
			RETURN
		END
	END

	--update setting league
	UPDATE dbo.League WITH(ROWLOCK, UPDLOCK)
	SET AutoSetting = @AutoSetting
	WHERE leagueid = @LeagueId

	IF @@ERROR > 0
	BEGIN
		SELECT @ErrCode = 1001018, @ErrMsg = 'Cannot update auto payout setting on this league. Please try again.'
		RETURN
	END

	SELECT @EndTime = GETDATE()
	SELECT @Remark = 'NAP: Update auto payout setting on league:' + CAST(@LeagueId AS NVARCHAR(10)) 
		+ ' AutoSetting:' + CAST(ISNULL(@AutoSetting, 0) AS NVARCHAR(10))
		+ ' Duration:' + CAST(DATEDIFF(MILLISECOND, @StarTime, @EndTime) AS NVARCHAR(50)) + ' ms'

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @AdminId
			, @Matchid			= NULL
			, @ActionID			= 159
			, @finalhomescore	= NULL
			, @finalawayscore	= NULL
			, @hthomescore		= NULL
			, @htawayscore		= NULL
			, @GoalRecord		= NULL
			, @betstatus		= NULL
			, @Remark			= @Remark
			, @IP				= @IP
	END TRY

	BEGIN CATCH
		SELECT @Remark = @Remark + ' ErrMsg=' + LEFT(ERROR_MESSAGE(), 250)

		EXEC DBTXN.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @AdminId
			, @Matchid			= NULL
			, @ActionID			= 159
			, @finalhomescore	= NULL
			, @finalawayscore	= NULL
			, @hthomescore		= NULL
			, @htawayscore		= NULL
			, @GoalRecord		= NULL
			, @betstatus		= NULL
			, @Remark			= @Remark
			, @IP				= @IP
	END CATCH 

END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_AutoPayout_SettingLeagueUpd] TO [bodbAdminNet] AS [dbo]
GO
