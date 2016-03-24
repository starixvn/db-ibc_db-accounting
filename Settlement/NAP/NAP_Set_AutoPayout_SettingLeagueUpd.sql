USE bodb02
GO
ALTER PROCEDURE dbo.NAP_Set_AutoPayout_SettingLeagueUpd @LeagueId INT
	, @IsAutoPayout BIT
	, @IsApplyAll BIT
	, @AdminId INT

	, @IP VARCHAR(20) = ''
	, @ErrCode INT = 0 OUTPUT
	, @ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*	Creator: 20160303@Patrick
	Task: Auto Payout - update setting on league
	DB: DBPRO/BODB02
	
	Revisions:
		
	Param's Explanation:
		- @IsApplyAll: 0: only update on league
					   1: update on league & running match without matches in Queue
 
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @IsAutoPayout_Old BIT, @StarTime DATETIME, @EndTime DATETIME, @Remark VARCHAR(1024)
	
	SELECT @IsAutoPayout = ISNULL(@IsAutoPayout, 0), @StarTime = GETDATE()

	SELECT @IsAutoPayout_Old = ISNULL(IsAutoPayout, 0)
	FROM dbo.League l WITH(NOLOCK) 
	WHERE leagueid = @LeagueId
	
	--check concurrency users
	IF @IsAutoPayout = @IsAutoPayout_Old
	BEGIN
		RETURN
	END

	IF @IsApplyAll = 1
	BEGIN
		--update running match
		UPDATE m
		SET IsAutoPayout = @IsAutoPayout
		FROM dbo.match m WITH(UPDLOCK, ROWLOCK)
		WHERE m.leagueid = @LeagueId AND sporttype = 1 AND eventstatus <> 'completed'
			--AND (NOT EXISTS (SELECT TOP 1 1 FROM DBTXN.bodb02.dbo.Single_Calculate_Queue q WITH(NOLOCK) WHERE q.matchid = m.matchid)
				--OR NOT EXISTS (SELECT TOP 1 1 FROM DBTXN.bodb02.dbo.Parlay_Calculate_Queue q WITH(NOLOCK) WHERE q.matchid = m.matchid)
			--)

		IF @@ERROR > 0
		BEGIN
			SELECT @ErrCode = 1001019, @ErrMsg = 'Cannot update auto payout setting on this match. Please try again.'
			RETURN
		END

		IF EXISTS (SELECT TOP 1 1 
					FROM dbo.match m WITH(NOLOCK)
					WHERE m.leagueid = @LeagueId AND sporttype = 1 AND IsAutoPayout IS NULL)
		BEGIN
			UPDATE m
			SET IsAutoPayout = @IsAutoPayout_Old
			FROM dbo.match m WITH(UPDLOCK, ROWLOCK)
			WHERE m.leagueid = @LeagueId AND sporttype = 1 AND IsAutoPayout IS NULL

			IF @@ERROR > 0
			BEGIN
				SELECT @ErrCode = 1001019, @ErrMsg = 'Cannot update auto payout setting on this match. Please try again.'
				RETURN
			END
		END

	END

	--update setting league
	UPDATE dbo.League WITH(ROWLOCK, UPDLOCK)
	SET IsAutoPayout = @IsAutoPayout
	WHERE leagueid = @LeagueId

	IF @@ERROR > 0
	BEGIN
		SELECT @ErrCode = 1001018, @ErrMsg = 'Cannot update auto payout setting on this league. Please try again.'
		RETURN
	END

	SELECT @EndTime = GETDATE()
	SELECT @Remark = 'NAP: Update auto payout setting on league:' + CAST(@LeagueId AS NVARCHAR(10)) 
		+ ' IsAutoPayout:' + CAST(ISNULL(@IsAutoPayout, 0) AS NVARCHAR(10))
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
