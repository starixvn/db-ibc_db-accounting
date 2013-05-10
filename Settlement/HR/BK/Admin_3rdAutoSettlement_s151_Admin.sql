ALTER PROCEDURE [dbo].[Admin_3rdAutoSettlement_s151_Admin]
	@LeagueID int,
	@raceNumber int,
	@eventdate smalldatetime,
	@Action varchar(10) = 'CAL'
AS
BEGIN

/* @Action input
CAL: (default) settle
REFUND: race abandon

Revisions:
	-- 20100916@Jamie: Update changeTime for Outright table 
	-- 20110906@Sophia: Add Linked Server DB02.BODB02.dbo for table Outright, RaceInfo
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
	FROM DB02.BODB02.dbo.RaceInfo
	WHERE LeagueID = @LeagueID 
		AND RaceNumber = @raceNumber 
		AND ProgramDate = @eventdate

	IF @Calculate = 1
	BEGIN
		-- Code to Log Message put here		
		SET @LogData = 'Calculate Result (' + @Action + ') for Horse League ID:' + CAST(@LeagueID as nvarchar(20)) + ' race:' + CAST(@raceNumber as nvarchar(20)) + ' Fail b/c this race number already settlement - '+ right(@Delay,5)
		EXEC dbo.WriteLog_UserLog 151, @LogData
		RETURN
	END
	ELSE
	BEGIN
		-- mark to settlement
		UPDATE DB02.BODB02.dbo.RaceInfo with (UPDLOCK, ROWLOCK)
		SET Calculate = 1
		WHERE LeagueID = @LeagueID
			AND RaceNumber = @raceNumber
			AND ProgramDate = @eventdate
	END

	-- start settlement
	IF @Action='CAL'
	BEGIN
		EXEC dbo.[Admin_3rdCalculate_s151_Reject_Admin] @LeagueID, @raceNumber, @eventdate
		EXEC dbo.[Admin_3rdCalculate_s151_Admin]     	@LeagueID, @raceNumber, @eventdate
		EXEC dbo.[Admin_3rdDummyTransfer_s151_Admin] 	@LeagueID, @raceNumber, @eventdate
	END
	ELSE
	BEGIN
		-- REFUND
		EXEC dbo.Admin_3rdCalculate_s151_Refund_Admin @LeagueID, @raceNumber, @eventdate
	END
	
	UPDATE DB02.BODB02.dbo.Outright with (ROWLOCK, UPDLOCK)
	SET oddsstatus = 'completed',
		[status] = CASE @Action WHEN 'CAL' THEN [status] ELSE 'refund' END,
		changeTime = getdate()
	WHERE
		LeagueID = @LeagueID
		AND groupmatch = CAST(@raceNumber as varchar(20))
		AND eventdate = @eventdate
		AND CASE
		WHEN @Action = 'CAL' AND oddsstatus = 'closed' THEN 1
		WHEN @Action = 'REFUND' AND oddsstatus IN ('running','suspend','closed') THEN 1 
		ELSE 0 END = 1

	-- Code to Log Message put here
	SET @LogData = 'Calculate Result (' + @Action + ') for Horse League ID:' + CAST(@LeagueID as nvarchar(20)) + ' race:' + CAST(@raceNumber as nvarchar(20)) + ' - ' + right(@Delay,5)
	EXEC dbo.WriteLog_UserLog 151, @LogData

END

GO
GRANT VIEW DEFINITION ON [dbo].[Admin_3rdAutoSettlement_s151_Admin] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Admin_3rdAutoSettlement_s151_Admin] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Admin_3rdAutoSettlement_s151_Admin] TO [Dot_3rdparty]