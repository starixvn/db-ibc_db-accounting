ALTER PROCEDURE [dbo].[DBA_HR_Settlement_ToteFixed]
	@ProgramID varchar(10),
	@raceNumber int,
	@eventdate smalldatetime
AS
	EXEC dbo.DBA_HR_Placing								@ProgramID, @raceNumber, @eventdate, @Results=''
	--EXEC dbo.[Admin_3rdCalculate_s151_Tote]				@ProgramID, @raceNumber, @eventdate
	EXEC dbo.Admin_3rdCalculate_s151					@ProgramID, @raceNumber, @eventdate
	EXEC dbo.[Admin_3rdCalculate_s151_Fixed]			@ProgramID, @raceNumber, @eventdate
	EXEC dbo.[Admin_3rdDummyTransfer_s151_ToteFixed]	@ProgramID, @raceNumber, @eventdate

	UPDATE dbo.Outright
	SET oddsstatus = 'completed'
	WHERE
		ProgramID = @ProgramID
		AND groupmatch = CAST(@raceNumber as varchar(20))
		AND eventdate = @eventdate
		AND oddsstatus = 'closed'

	-- Code to Log Message put here
	Declare @LogData as nvarchar(300)
	SET @LogData = 'Calculate Result for Horse ID:' + @ProgramID + ' race:' + CAST(@raceNumber as nvarchar(20))
	EXEC dbo.logfile 151, @LogData


GO
GRANT VIEW DEFINITION ON [dbo].[DBA_HR_Settlement_ToteFixed] TO [vnteam]