
ALTER PROCEDURE [dbo].[Acc_UserLog_Settle_MatchSelByCode] 
	@matchCode varchar(50) = '',
	@FromDate DATETIME = '',
	@ToDate DATETIME = '',
	@BalanceUpDay DATETIME = ''
AS
/*
Created: Khoa
Date: 20100302
Task : View match info - settlement log
DB: DBAGE/bodb02
Original:

Revisions: 	
	- 20110720@Lukas: get isneutral infor 
	- 20120213@Lukas: Get more column: sporttype, showtime (support Live casino game)
	- 20120910@Sophia: Get homeid2 (it contains bettype of Live Casino)
	- 20130121@Dan: change linked server DB06 to DBARC
*/
SET NOCOUNT ON

DECLARE  @TMP_ALL_MatchInfo TABLE (
									matchid INT, 
									homeid INT, 
									awayid INT, 
									eventdate DATETIME, 
									leagueid INT, 
									isneutral BIT, 
									sporttype INT,
									showtime nvarchar(50),
									homeid2 INT
								)

IF @Todate >= @BalanceUpDay    
BEGIN
	INSERT INTO @TMP_ALL_MatchInfo
	SELECT matchid , homeid , awayid ,  eventdate , leagueid, isneutral, sporttype, showtime, 
		   CASE WHEN ISNULL(homeid2,0) = 0 AND sporttype = 162 THEN 1101 ELSE homeid2 END as homeid2  -- contains bettype of Live Casino 
	FROM match WITH (NOLOCK)
	WHERE matchcode = @matchCode and eventdate BETWEEN @FromDate and @ToDate

	IF @BalanceUpDay < @FromDate     
		SELECT @BalanceUpDay=@FromDate  
	INSERT INTO @TMP_ALL_MatchInfo
	SELECT matchid , homeid , awayid ,  eventdate , leagueid, isneutral, sporttype, showtime,
		   CASE WHEN ISNULL(homeid2,0) = 0 AND sporttype = 162 THEN 1101 ELSE homeid2 END as homeid2  -- contains bettype of Live Casino 
	FROM match14 WITH (NOLOCK)
	WHERE matchcode = @matchCode and eventdate BETWEEN @BalanceUpDay and @ToDate
END

IF @FromDate < @BalanceUpDay   
BEGIN
	IF @ToDate >= DATEADD(dd, -1, @BalanceUpDay)  
		SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay)  

	INSERT INTO @TMP_ALL_MatchInfo
	SELECT matchid , homeid , awayid , eventdate , leagueid, isneutral, sporttype, showtime,
		   CASE WHEN ISNULL(homeid2,0) = 0 AND sporttype = 162 THEN 1101 ELSE homeid2 END as homeid2  -- contains bettype of Live Casino 
	FROM DBARC.bodb_Archive.dbo.match_BK WITH (NOLOCK) 
	WHERE matchcode = @matchCode AND eventdate BETWEEN @FromDate and @ToDate
END

SELECT t.matchid , t.homeid , t.awayid , t.eventdate , t.leagueid, isneutral, sporttype, showtime, homeid2 
FROM @TMP_ALL_MatchInfo t

GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_Settle_MatchSelByCode] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UserLog_Settle_MatchSelByCode] TO [vnteam]


