USE bodb02
GO
ALTER PROCEDURE dbo.NAP_Set_AutoPayout_SettingMatchUpd @MatchId INT
	, @IsAutoPayout BIT
	, @AdminId INT

	, @IP VARCHAR(20) = ''
	, @ErrCode INT = 0 OUTPUT
	, @ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*	Creator: 20160303@Patrick
	Task: Auto Payout - update setting on match
	DB: DBPRO/BODB02
	
	Revisions:
		
	Param's Explanation:
 
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @IsAutoPayout_Old BIT, @StarTime DATETIME, @EndTime DATETIME, @Remark VARCHAR(1024)
	
	SELECT @IsAutoPayout = ISNULL(@IsAutoPayout, 0), @StarTime = GETDATE()

	SELECT @IsAutoPayout_Old = IsAutoPayout
	FROM dbo.match m WITH(NOLOCK)
	WHERE m.matchid = @MatchId

	IF @IsAutoPayout_Old IS NULL
	BEGIN
		SELECT @IsAutoPayout_Old = ISNULL(IsAutoPayout, 0)
		FROM dbo.League l WITH(NOLOCK)
	END

	--check concurrency users
	IF @IsAutoPayout = @IsAutoPayout_Old
	BEGIN
		RETURN
	END

	--check match <> running
	IF EXISTS (SELECT TOP 1 1 
					FROM dbo.match m WITH(NOLOCK) 
					WHERE matchid = @MatchId AND sporttype = 1 AND eventstatus = 'completed')
	BEGIN
		SELECT @ErrCode = 1001019, @ErrMsg = 'Cannot update auto payout setting on this match. Please try again.'
		RETURN
	END

	----check match in Queue
	--IF EXISTS (SELECT TOP 1 1 FROM DBTXN.bodb02.dbo.Single_Calculate_Queue q WITH(NOLOCK) WHERE q.matchid = @MatchId)
	--	OR EXISTS (SELECT TOP 1 1 FROM DBTXN.bodb02.dbo.Parlay_Calculate_Queue q WITH(NOLOCK) WHERE q.matchid = @MatchId)
	--BEGIN
	--	SELECT @ErrCode = 1001020, @ErrMsg = 'Sorry. Not allow to update Auto Setting of completed match.'
	--	RETURN
	--END

	UPDATE m
	SET IsAutoPayout = @IsAutoPayout
	FROM dbo.match m WITH(UPDLOCK, ROWLOCK)
	WHERE m.matchid = @MatchId

	IF @@ERROR > 0
	BEGIN
		SELECT @ErrCode = 1001019, @ErrMsg = 'Cannot update auto payout setting on this match. Please try again.'
		RETURN
	END

	SELECT @EndTime = GETDATE()
	SELECT @Remark = 'NAP: Update auto payout setting on match:' + CAST(@MatchId AS NVARCHAR(10)) 
		+ ' IsAutoPayout:' + CAST(ISNULL(@IsAutoPayout, 0) AS NVARCHAR(10))
		+ ' Duration:' + CAST(DATEDIFF(MILLISECOND, @StarTime, @EndTime) AS NVARCHAR(50)) + ' ms'

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @AdminId
			, @Matchid			= @MatchId
			, @ActionID			= 160
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
			, @Matchid			= @MatchId
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
GRANT EXECUTE ON [dbo].[NAP_Set_AutoPayout_SettingMatchUpd] TO [bodbAdminNet] AS [dbo]
GO
