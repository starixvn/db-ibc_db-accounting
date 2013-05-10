 USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Acc_Race_StatusUpd]    Script Date: 02/24/2009 23:48:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Dot_Acc_Race_StatusUpd]
	@programID varchar(10),
	@eventdate smalldatetime,
	@raceNumber int,
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
	
	-- HR event status:
	-- closed: new created or had HR result(only closed status can do settle)
	-- running: running event
	-- completed: settled event
	
	-- uppdate status and reset all result columns
	UPDATE dbo.outright with (rowlock, updlock)
	SET 
		oddsstatus = 'closed',
		odds=0, PlaceOdds=0, 
		Placing=0, IsFavor=0, IsSCR=0 
	WHERE ProgramID = @programID 
		AND eventdate = @eventdate 
		AND groupmatch = CAST(@raceNumber as varchar(20))

	Declare @LogData as nvarchar(200)
	SET @LogData = 
		'Update event oddsstatus to closed and reset result column to zero, for Horse ID:' + @ProgramID 
		+ ' eventdate:' + CAST(@eventdate as nvarchar(20))
		+ ' race:' + CAST(@raceNumber as nvarchar(20))

	EXEC dbo.WriteLog_UserLog @userid, @LogData
END
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Acc_Race_StatusUpd] TO [vnteam]