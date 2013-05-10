 USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Acc_Race_ResultUpd]    Script Date: 02/24/2009 23:49:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
	
	Declare @LogData as nvarchar(200)
	SET @LogData = 'Update Result for Horse ID:' + @ProgramID + ' race:' + CAST(@raceNumber as nvarchar(20)) + ' runner:' + CAST(@runnerNumber as nvarchar(20))
		+ ' winodds:' + CAST(@winOdds as nvarchar(20)) + ' PlaceOdds:' + CAST(@placeOdds as nvarchar(20))
		+ ' IsFavor:' + CAST(@isFav as nvarchar(1)) + ' IsSCR:' + CAST(@isSCR as nvarchar(1))
	EXEC dbo.WriteLog_UserLog @userid, @LogData
END
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Acc_Race_ResultUpd] TO [vnteam]