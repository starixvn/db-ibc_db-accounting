ALTER PROCEDURE [dbo].[U3_Rpt_MatchWinLoss_Ag]
	@CustID   INT,
	@FromDate DATETIME,
	@ToDate   DATETIME	
AS
/*
Created: 20150209@Sophia 
Task : U3 report match winloss - for Number game, Bingo, Live Casino
DB: DBAGE/bodb02
Original: Age_Rpt_MatchWinLoss_Ag
Revisions:
   
*/
	BEGIN 
	SET NOCOUNT ON

	----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT)
	INSERT INTO @SportBettype
	EXEC dbo.Acc_SportBettypeMatrix_Sel @mode=4


	SELECT x.* ,isnull(x.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
	FROM (
		SELECT m.matchid
			,m.homeid
			,m.awayid
			,b.bettype
			,b.liveindicator
			,m.isNeutral
			,m.matchcode
			,m.showtime
			,SUM(b.comm / (1 - b.apositiontaking)) AS GrossComm
			,SUM(comm - playercomm) AS commission
			,SUM(awinlost) AS positiontaking
		FROM bettrans b WITH (NOLOCK)
			INNER JOIN match m WITH (NOLOCK) ON m.matchid = b.matchid
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		WHERE b.recommend = @custid			
			AND m.eventdate >= @fromdate
			AND m.eventdate <= @todate
			AND m.eventstatus = 'completed'
			AND isnull(m.betstatus, '') <> 'refund'
			AND s.ProductID IN (3) --- Number Game
		GROUP BY m.matchid
			,m.homeid
			,m.awayid
			,m.matchcode
			,b.bettype
			,m.isNeutral
			,b.liveindicator
			,m.showtime	

		UNION ALL --- Not Number Game not Group By liveindicator	 
		SELECT m.matchid
			,m.homeid
			,m.awayid
			,b.bettype
			,0 AS liveindicator
			,m.isNeutral
			,m.matchcode
			,m.showtime
			,SUM(b.comm / (1 - b.apositiontaking)) AS GrossComm
			,SUM(comm - playercomm) AS commission
			,SUM(awinlost) AS positiontaking
		FROM bettrans b WITH (NOLOCK)
			INNER JOIN match m WITH (NOLOCK) ON m.matchid = b.matchid
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype			 
		WHERE b.recommend = @custid
			AND m.eventdate >= @fromdate
			AND m.eventdate <= @todate
			AND m.eventstatus = 'completed'
			AND isnull(m.betstatus, '') <> 'refund'
			AND s.ProductID IN (4,7)
		GROUP BY m.matchid
			,m.homeid
			,m.awayid
			,m.matchcode
			,b.bettype
			,m.isNeutral
			,m.showtime
	
		UNION ALL
			SELECT m.matchid
			,m.homeid
			,m.awayid
			,b.bettype
			,b.liveindicator
			,m.isNeutral
			,m.matchcode
			,m.showtime
			,SUM(b.comm / (1 - b.apositiontaking)) AS GrossComm
			,SUM(comm - playercomm) AS commission
			,SUM(awinlost) AS positiontaking
		FROM bettrans14 b WITH (NOLOCK)
			INNER JOIN match14 m WITH (NOLOCK) ON m.matchid = b.matchid
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		WHERE b.recommend = @custid			
			AND m.eventdate >= @fromdate
			AND m.eventdate <= @todate
			AND m.eventstatus = 'completed'
			AND isnull(m.betstatus, '') <> 'refund'
			AND s.ProductID IN (3) --- Number Game
		GROUP BY m.matchid
			,m.homeid
			,m.awayid
			,m.matchcode
			,b.bettype
			,m.isNeutral
			,b.liveindicator
			,m.showtime	

		UNION ALL --- Not Number Game not Group By liveindicator	 
		SELECT m.matchid
			,m.homeid
			,m.awayid
			,b.bettype
			,0 AS liveindicator
			,m.isNeutral
			,m.matchcode
			,m.showtime
			,SUM(b.comm / (1 - b.apositiontaking)) AS GrossComm
			,SUM(comm - playercomm) AS commission
			,SUM(awinlost) AS positiontaking
		FROM bettrans14 b WITH (NOLOCK)
			INNER JOIN match14 m WITH (NOLOCK) ON m.matchid = b.matchid
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype			 
		WHERE b.recommend = @custid
			AND m.eventdate >= @fromdate
			AND m.eventdate <= @todate
			AND m.eventstatus = 'completed'
			AND isnull(m.betstatus, '') <> 'refund'
			AND s.ProductID IN (4,7)
		GROUP BY m.matchid
			,m.homeid
			,m.awayid
			,m.matchcode
			,b.bettype
			,m.isNeutral
			,m.showtime
		) x
	ORDER BY x.showtime
END
GO

GRANT EXECUTE ON [dbo].[U3_Rpt_MatchWinLoss_Ag] TO [bodbDownlineNet]
GO

GRANT EXECUTE ON [dbo].[U3_Rpt_MatchWinLoss_Ag] TO [bodbDownlineNetView]
GO

GRANT VIEW DEFINITION ON [dbo].[U3_Rpt_MatchWinLoss_Ag] TO [vnteam]

