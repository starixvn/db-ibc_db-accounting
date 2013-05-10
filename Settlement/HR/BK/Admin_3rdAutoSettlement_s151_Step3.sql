


ALTER PROCEDURE [dbo].[Admin_3rdAutoSettlement_s151_Step3]
	@ProgramID varchar(10),
	@raceNumber int,
	@eventdate smalldatetime,
	@Action varchar(10) = 'CAL'
AS
/*
	Created:
	Task:
	DB02.BODB02
	
	Revisions:
	
*/
BEGIN

	Declare @LogData as nvarchar(200)

	-- vivi@2010-4-27
	-- horse racing have two machines calling settlement sp, random delay millisecond to avoid command coming on same time
	DECLARE @Delay char(12)
	DECLARE @Delay1 int, @Delay2 int
	SELECT @Delay1 = RAND()*200000
	SELECT @Delay2 = RAND()*200000
	SELECT @Delay = CONVERT(varchar,DATEADD(ms,(@Delay1+@Delay2)/200,'1970-01-01'),14)
	WAITFOR DELAY @Delay
	

	UPDATE dbo.Outright with (ROWLOCK, UPDLOCK)
	SET oddsstatus = 'completed',
		[status] = CASE @Action WHEN 'CAL' THEN [status] ELSE 'refund' END,
		changetime = getdate()
	WHERE
		ProgramID = @ProgramID
		AND groupmatch = CAST(@raceNumber as varchar(20))
		AND eventdate = @eventdate
		AND CASE
		WHEN @Action = 'CAL' AND oddsstatus = 'closed' THEN 1
		WHEN @Action = 'REFUND' AND oddsstatus IN ('running','suspend','closed') THEN 1 
		ELSE 0 END = 1

	-- Code to Log Message put here
	SET @LogData = 'Calculate Result (' + @Action + ') for Horse ID:' + @ProgramID + ' race:' + CAST(@raceNumber as nvarchar(20)) + ' - ' + right(@Delay,5)
	EXEC dbo.WriteLog_UserLog 151, @LogData


END


GO
GRANT VIEW DEFINITION ON [dbo].[Admin_3rdAutoSettlement_s151_Step3] TO [vnteam]