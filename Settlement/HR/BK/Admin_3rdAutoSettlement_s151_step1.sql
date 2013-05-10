
ALTER PROCEDURE [dbo].[Admin_3rdAutoSettlement_s151_step1]
	@ProgramID varchar(10),
	@raceNumber int,
	@eventdate smalldatetime,
	@Action varchar(10) = 'CAL'
AS
BEGIN

/* 
	@Action input
	CAL: (default) settle
	REFUND: race abandon
	DB02.BODB02
Revisions: 
	- 20100720@Henry: Change SP Logfile to WriteLog_UserLog
	- 20100825@Lukas: Update last time modify (changetime column) for Outright table
*/
	Declare @LogData as nvarchar(200)

	-- vivi@2010-4-27
	-- horse racing have two machines calling settlement sp, random delay millisecond to avoid command coming on same time
	DECLARE @Delay char(12)
	DECLARE @Delay1 int, @Delay2 int
	SELECT @Delay1 = RAND()*200000
	SELECT @Delay2 = RAND()*200000
	SELECT @Delay = CONVERT(varchar,DATEADD(ms,(@Delay1+@Delay2)/200,'1970-01-01'),14)
	WAITFOR DELAY @Delay

	-- check settlement or not
	DECLARE @Calculate bit
	SET @Calculate = 0
	SELECT @Calculate = Calculate 
	FROM dbo.RaceInfo
	WHERE ProgramID = @programID 
		AND RaceNumber = @raceNumber 
		AND ProgramDate = @eventdate

	IF @Calculate = 1 and @Action <> 'REFUND'
	BEGIN
		-- Code to Log Message put here
		SET @LogData = 'Calculate Result (' + @Action + ') for Horse ID:' + @ProgramID + ' race:' + CAST(@raceNumber as nvarchar(20)) + ' Fail b/c this race number already settlement - '+ right(@Delay,5)
		EXEC dbo.WriteLog_UserLog 151, @LogData
		RETURN
	END
	ELSE
	BEGIN
		-- mark to settlement
		UPDATE dbo.RaceInfo with (UPDLOCK, ROWLOCK)
		SET Calculate = 1
		WHERE ProgramID = @programID
			AND RaceNumber = @raceNumber
			AND ProgramDate = @eventdate
	END

END


GO
GRANT VIEW DEFINITION ON [dbo].[Admin_3rdAutoSettlement_s151_step1] TO [vnteam]