ALTER PROCEDURE [dbo].[Dot_Admin_HorseResultResettle]
	@HorseDate datetime,
	@ProgramID varchar(10),
	@GroupMatch varchar(20),
	@creator int = 0
AS
/*	Created by:[]
	DB: DBTRANS.BODB02
	Revisions:
		-- 20110906@Sophia: Add Linked Server DB02.BODB02.dbo for table Outright, LeagueDetail

*/
BEGIN

	-- log action
	DECLARE @LogData nvarchar(300)
	SET @LogData = 'Calculate Result (redo settlement by admin userid:' + CAST(@creator as varchar(20)) + ') for Horse ID:' + @ProgramID + ' eventdate:' + CAST(@HorseDate as nvarchar(20)) + ' race:' + @GroupMatch
	EXEC dbo.LogFile 151, @LogData

	-- delete horse dummy account
	EXEC Dot_Acc_Race_DummyDel	@programID = @ProgramID, 
								@eventdate = @HorseDate, 
								@raceNumber = @GroupMatch

	-- only when status = 'closed' can settlement
	UPDATE DB02.BODB02.dbo.outright with (rowlock, updlock)
	SET Oddsstatus = 'closed' 
	WHERE ProgramID = @ProgramID 
	AND eventdate = @HorseDate 
	AND groupmatch = @GroupMatch

	-- mark back to not yet settlement
	UPDATE DB02.BODB02.dbo.RaceInfo with (UPDLOCK, ROWLOCK)
    SET Calculate = 0
	WHERE ProgramID = @programID
		AND ProgramDate = @HorseDate
        AND RaceNumber = CAST(@GroupMatch as int)

	-- settlement
	EXEC Admin_3rdAutoSettlement_s151	@programID = @ProgramID, 
										@raceNumber= @GroupMatch,  
										@eventdate = @HorseDate
END


GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Admin_HorseResultResettle] TO [vnteam]