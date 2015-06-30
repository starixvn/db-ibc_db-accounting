 ALTER PROCEDURE DBA_Gen_VSOutRight
	@RacerID INT,
	@HumanID INT,
	@EventID INT,
	@RacerNum TINYINT,	
	@WinOdds SMALLMONEY,	
	@IsFavor VARCHAR(3) = NULL,
	@MaxBet INT = 2200, 
	@Lane TINYINT,	
	@Type TINYINT = 0, -- 0: VSOutright, 1: VSOutright14
	@ErrMsg NVARCHAR(500) OUTPUT
AS
BEGIN
	DECLARE @EventDate SMALLDATETIME, @KickoffTime DATETIME, @PlaceOdds SMALLMONEY,	@PayOut INT, @EventStatus VARCHAR(50)
	
	SELECT @EventDate = convert(varchar(10),EventTime,101), @KickoffTime = EventTime, @PayOut = PayOut, @EventStatus = EventStatus
	FROM VSRaceInfo WITH (NOLOCK)
	WHERE EventID = @EventID
	
	IF @Type = 0
	BEGIN				
		SELECT @PlaceOdds = @WinOdds / @PayOut
		INSERT INTO VSOutRight (EventID, RacerNum, IsFavor, EventDate, KickoffTime, RacerID, HumanID, WinOdds, PlaceOdds, Lane, MaxBet, DisplayMode, Creator, EventStatus)
		VALUES (@EventID, @RacerNum, @IsFavor, @EventDate, @KickoffTime, @RacerID, @HumanID, @WinOdds, @PlaceOdds, @Lane, @MaxBet, 0, 181, @EventStatus)
	END
	ELSE
	BEGIN			
		SELECT @PlaceOdds = @WinOdds / @PayOut
		INSERT INTO VSOutRight14 (EventID, RacerNum, IsFavor, EventDate, KickoffTime, RacerID, HumanID, WinOdds, PlaceOdds, Lane, MaxBet, DisplayMode, Creator, EventStatus)
		VALUES (@EventID, @RacerNum, @IsFavor, @EventDate, @KickoffTime, @RacerID, @HumanID, @WinOdds, @PlaceOdds, @Lane, @MaxBet, 0, 181, @EventStatus)
	END
END
	
/* 
DECLARE @ErrMsg NVARCHAR(500)
EXEC DBA_Gen_VSOutRight @RacerID = 229864, @HumanID = 227161, @EventID = 12981, @RacerNum = 2, @WinOdds = 4, @IsFavor = 'F', @Lane = 1, @ErrMsg = @ErrMsg
SELECT @ErrMsg
*/

