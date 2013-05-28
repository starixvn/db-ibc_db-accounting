ALTER PROCEDURE [dbo].[Dot_Acc_Race_ResultUpd]
	@programID varchar(10),
	@eventdate smalldatetime,
	@raceNumber int,
	@runnerNumber int,
	@placing tinyint = 0,
	@winOdds smallmoney = 0,
	@placeOdds	smallmoney = 0,
	@isSCR bit = 0,
	@isFav bit = 0,
	@userid int = 151 ----doing update status userid
AS
/*
	Create:
	Task:
	DB: DB02.BODB02
	
	Revisions: 
		- 20130524@Elodie: Write settlement log for horse racing
*/
BEGIN
	-- 20100720@Henry: Change SP Logfile to WriteLog_UserLog
	SET NOCOUNT ON;	
	
	UPDATE dbo.outright with (rowlock,updlock)
	SET 
		odds = @winOdds,
		PlaceOdds = @placeOdds,
		Placing = @placing,
		IsFavor = @isFav,
		IsSCR = @isSCR
	WHERE ProgramID = @programID 
		AND eventdate = @eventdate
		AND groupmatch = CAST(@raceNumber as varchar(20))
		AND matchcode = CAST(@runnerNumber as varchar(10))
		AND oddsstatus <> 'completed'
	
	-- WRITE LOG
	DECLARE @Remark VARCHAR(500)
	BEGIN TRY
		SET @Remark = 'Update Result for Horse ID:' + @ProgramID + ' runner:' + CAST(@runnerNumber as nvarchar(20))
					+ ' winodds:' + CAST(@winOdds as nvarchar(20)) + ' PlaceOdds:' + CAST(@placeOdds as nvarchar(20))
					+ ' IsFavor:' + CAST(@isFav as nvarchar(1)) + ' IsSCR:' + CAST(@isSCR as nvarchar(1))
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_SettleOutright 
			@UserID = @userid, 
			@MatchID = @raceNumber, 
			@ActionID = 130, 
			@LeagueID = 0, 
			@EventDate = @eventdate,
			@Remark = @Remark
			
	END TRY
	BEGIN CATCH		
		SET @Remark = 'Update Result for Horse ID:' + @ProgramID + ' race:' + CAST(@raceNumber as nvarchar(20)) + ' runner:' + CAST(@runnerNumber as nvarchar(20)) + ' eventdate:' + CAST(@eventdate as nvarchar(20))
					+ ' winodds:' + CAST(@winOdds as nvarchar(20)) + ' PlaceOdds:' + CAST(@placeOdds as nvarchar(20))
					+ ' IsFavor:' + CAST(@isFav as nvarchar(1)) + ' IsSCR:' + CAST(@isSCR as nvarchar(1))
		EXEC dbo.WriteLog_UserLog @userid, @Remark
	END CATCH	
END

GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Acc_Race_ResultUpd] TO [vnteam]