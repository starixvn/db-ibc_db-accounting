 ALTER PROCEDURE [dbo].[Task_DailyABSummaryWinloss]
	@winlostdate	DATETIME,
	@ErrCode		INT = 0 OUTPUT
AS
	/*
		Created: Johnson
		Date: 08Nov2011
		Task: Summary winloss of ABD members by winlost date
		DB: DB054.bodb_ABS
		
		Revisions:
			- 20120702@Johnson: Summary winloss by bettype
		Parameters Explanation:
	*/
SET NOCOUNT ON 

	DECLARE @ErrMsg VARCHAR(1000)

	IF NOT EXISTS (SELECT top(1) 1 FROM bodb02.dbo.bettrans14 WITH(NOLOCK) WHERE winlostdate = @winlostdate)
	BEGIN
		PRINT ('Data is not moved to bettrans14.')
		SET @ErrCode = -101
		RETURN
	END
	
	IF EXISTS(SELECT TOP(1) 1 FROM bodb02.dbo.bettrans WITH(NOLOCK) WHERE winlostdate = @winlostdate AND bettype <= 19000)
	BEGIN
		PRINT ('Data is still in bettrans.')
		SET @ErrCode = -102
		RETURN
	END
	
	IF NOT EXISTS (SELECT 1 FROM ABSum_Winloss WITH(NOLOCK) WHERE winlostdate = @winlostdate)	
	BEGIN
		INSERT INTO ABSum_Winloss (winlostdate, punterid, leagueid, matchid, bettype, currency, statusid, turnover, comm, winlost, betcount)
		SELECT
			@winlostdate, ab.punterid , m.leagueid, m.matchid, b.bettype, b.currency, b.statusid,
			SUM(stake) turnover,
			SUM(playercomm) comm,
			SUM(winlost - actual_stake) winlost,
			COUNT(1) betcount
		FROM ABTransaction ab WITH(NOLOCK) 
			INNER JOIN bodb02.dbo.bettrans14 b WITH(NOLOCK) ON ab.transid = b.transid 
			INNER JOIN bodb02.dbo.match14 m WITH(NOLOCK) ON b.matchid = m.matchid
		WHERE b.winlostdate = @winlostdate			
		GROUP BY ab.punterid, m.leagueid, m.matchid, b.bettype, b.currency, b.statusid
		
		IF @@ERROR > 0
		BEGIN			
			SELECT @ErrMsg = 'Process summary data failed for :' + CAST(@winlostdate AS VARCHAR(10))
			
			RAISERROR (@ErrMsg,16,1)
			SELECT @ErrCode = 101
			RETURN
		END	
	END
GO
GRANT VIEW	DEFINITION ON [Task_DailyABSummaryWinloss] TO [vnteam]