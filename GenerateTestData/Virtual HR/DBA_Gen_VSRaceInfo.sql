ALTER PROCEDURE DBA_Gen_VSRaceInfo   	
	@EventStatus VARCHAR(50),
	@EventTime DATETIME,   
	@Payout TINYINT = 4,  
	@EachWay TINYINT = 3,  
	@CourseName VARCHAR(100) = '181_1_Course',  
	@TrackType VARCHAR(10) = 'Flat',  
	@Distance VARCHAR(10) = '1m 2f',  
	@Racers TINYINT = 11,  
	@ForeCastPayout MONEY = 17.31,  
	@TriCastPayout MONEY = 180.90,  
	@Calculate BIT = 0,  
	@BetStatus VARCHAR(10) = NULL,   	
	@ErrMsg NVARCHAR(500) OUTPUT  
AS  
BEGIN  
	--IF EXISTS (SELECT 1 FROM VSRaceInfo WITH (NOLOCK) WHERE EventID = @EventID)  
	--BEGIN  
	-- SELECT @ErrMsg = 'EventID already existed'  
	-- RETURN  
	--END  
	DECLARE @EventID INT  
	SELECT @EventID = max(EventID) from VSRaceInfo WITH (NOLOCK)  

	INSERT INTO VSRaceInfo (EventID, EventTime, LeagueID, PayOut, EachWay, CourseName, TrackType, Distance, Racers, ForeCastPayout, TriCastPayout, CreateDate, Calculate, SportType, ChangeTime, BetStatus, EventStatus)  
	VALUES (@EventID+1, @EventTime, 27538, @PayOut, @EachWay, @CourseName, @TrackType, @Distance, @Racers, @ForeCastPayout, @TriCastPayout, getdate(), @Calculate, 181, getdate(), @BetStatus, @EventStatus)  
	SELECT @EventID+1 EventID  
END  

/*  
DECLARE @ErrMsg NVARCHAR(500), @EventTime DATETIME  
SELECT @EventTime = getdate()  
EXEC DBA_Gen_VSRaceInfo @EventStatus = 'running', @EventTime = @EventTime, @ErrMsg = @ErrMsg  
SELECT @ErrMsg  
*/