ALTER PROCEDURE [dbo].[Task_RMS_DailySummaryWinloss]
	@winlostdate	DATETIME,
	@ErrCode		INT = 0				OUTPUT,
	@ErrMsg			VARCHAR(1000) = ''	OUTPUT 
AS
	/*
		Created: Johnson
		Date: 2012-11-01
		Task: Copy won parlay tickets into RMS
		DB: DBCRM/bodb_RMS
		
		Revisions:
			- 20130124@Johnson: get data from rmTransaction_BK instead rmTransaction
			- 20130227@Jamie: Check tickets on rmTransaction before SUM
			- 20130228@Jamie: Get data from bettrans14 directly
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	
	IF NOT EXISTS (SELECT top 1 1 FROM bodb02.dbo.bettrans14 WITH(NOLOCK) WHERE bettype = 9 AND matchid = 9 AND winlostdate = @winlostdate)
	BEGIN
		SELECT	 @ErrMsg= 'WARNING:Data is not moved to bettrans14.'
				,@ErrCode = 101
		RETURN
	END
	
	IF EXISTS (SELECT top 1 1 FROM bodb02.dbo.bettrans WITH(NOLOCK) WHERE bettype = 9 AND matchid = 9 AND winlostdate = @winlostdate)
	BEGIN
		SELECT	 @ErrMsg= 'WARNING:Data is still in bettrans.'
				,@ErrCode = 102
		RETURN
	END
	
	IF NOT EXISTS (SELECT TOP 1 1 FROM rmSumWinloss WITH(NOLOCK) WHERE winlostdate = @winlostdate)
	BEGIN
		INSERT INTO rmSumWinloss (winlostdate
				,custid
				,sporttype
				,statusid
				,username
				,currency
				,stake
				,winlost
				,company_stake
				,company_winlost
				,actualrate
				,odds
				,betcount)
		SELECT	 winlostdate
				,b.custid
				,liveawayscore
				,statusid
				,username
				,currency
				,SUM(stake)
				,SUM(winlost)
				,SUM(stake*(1-tpositiontaking))
				,SUM(-(winlost-stake)*(1-tpositiontaking))
				,actualrate
				,SUM(modds)
				,count(1)
		FROM	bodb02.dbo.bettrans14 b WITH(NOLOCK) 
		WHERE	b.winlostdate = @winlostdate
				AND matchid = 9
				AND bettype = 9
				AND b.statusid IN (111,112,113)
		GROUP BY winlostdate, b.custid, liveawayscore, statusid, username, currency, actualrate
		
		IF @@ERROR > 0
		BEGIN			
			SELECT	 @ErrMsg = 'FAILED:Process summary data failed for :' + CAST(@winlostdate AS VARCHAR(10))
					,@ErrCode = 201
			RETURN
		END	
	END	
	
