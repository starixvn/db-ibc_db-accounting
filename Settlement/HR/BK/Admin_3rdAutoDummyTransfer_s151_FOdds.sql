ALTER Procedure [dbo].[Admin_3rdAutoDummyTransfer_s151_FOdds]
    @eventDate smalldatetime = NULL
AS

/*
Created by:[]
Date:
Task:  
DB: DBTRANS.BODB02
Original:  
Revisions:
  
 */
SET NOCOUNT ON

if @eventDate is NULL
    SET @eventDate = CONVERT(nvarchar(10), CURRENT_TIMESTAMP, 120)

DECLARE @ErrMsg varchar(200),
		@programID varchar(10),
		@raceNumber int,
		@Abs_Balance money

DECLARE @race TABLE (programID varchar(10), raceNumber int, FOddsStatus varchar(10), Abs_Balance money)


INSERT INTO @race (programID, raceNumber, FOddsStatus, Abs_Balance)
SELECT programID, groupmatch, FOddsStatus,
	abs(SUM((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)*b.actualrate))
FROM bettrans b WITH (nolock)
    INNER join outright o WITH (nolock) ON b.matchid = o.orid
WHERE bettype in (41,42,43) 
	and eventdate = @eventdate
GROUP BY programID, groupmatch, FOddsStatus  


if exists (select 1 from @race where FOddsStatus <> 'completed')
BEGIN
    SELECT @ErrMsg = 'Error: uncompleted race existed!'
    RaisError (@ErrMsg, 16, 1)
	RETURN
END

DECLARE Race_Cursor CURSOR  FOR
SELECT programID, raceNumber
FROM   @race

OPEN Race_Cursor

FETCH NEXT FROM Race_Cursor
INTO @programID, @raceNumber

WHILE @@FETCH_STATUS = 0
BEGIN	
	IF EXISTS (SELECT 1
				FROM dbo.bettrans b with (nolock) 
					INNER JOIN dbo.outright o with (nolock) on b.matchid=o.orid 
				WHERE o.eventdate = @eventdate
					AND o.programID = @programID
					AND o.groupmatch = CAST(@raceNumber as varchar(20))
					AND b.status='done'
					and b.bettype in (41,42,43)
				)
	BEGIN
		SELECT @ErrMsg = 'Error: race got dummy transaction existed! - ' + @programID + ',' + cast(@raceNumber as varchar(20))
		RaisError (@ErrMsg, 16, 1)
		RETURN	
	END
	
	EXEC dbo.Admin_3rdDummyTransfer_s151_FOdds 
				@ProgramID = @ProgramID,
				@raceNumber = @raceNumber,
				@EventDate = @EventDate
	
	SELECT @Abs_Balance = abs(isnull(SUM((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)*b.actualrate),0))
	FROM bettrans b WITH (nolock)
		INNER join outright o WITH (nolock) ON b.matchid = o.orid
	WHERE bettype in (41,42,43) 
		and ProgramID = @ProgramID
		and groupmatch = CAST(@raceNumber as varchar(20))
		and EventDate = @EventDate

	if @Abs_Balance > 0
	BEGIN
		SELECT @ErrMsg = 'Error: still got balance left - ' + @programID + ',' + cast(@raceNumber as varchar(20))
		RaisError (@ErrMsg, 16, 1)
		RETURN	
	END

	FETCH NEXT FROM Race_Cursor
	INTO @programID, @raceNumber
END

CLOSE Race_Cursor

DEALLOCATE Race_Cursor

Declare @LogData as nvarchar(300)
SET @LogData = 
	'Dummy Transfer for Horse Racing Fixed Odds - eventdate:' + CAST(@eventdate as nvarchar(20))

EXEC dbo.logfile 151, @LogData


GO

