-- Exec Age_SelBalanceUpDay
--== 1. @winlostdate > MoveBetsDay 
DECLARE	@winlostdate	DATETIME,
		@min_date		DATETIME,
		@max_date		DATETIME,
		@usdActualrate	FLOAT
SELECT	@min_date = '2009-11-17',
		@max_date = '2009-11-19',
		@winlostdate = @min_date

WHILE (@winlostdate <= @max_date)	
BEGIN

	SELECT @usdActualrate = (	SELECT TOP 1 actualrate FROM bettrans b WITH (NOLOCK) 
								WHERE currency = 3 and winlostdate = @winlostdate and bettype < 99)

	INSERT INTO Exchange_History_tmp (winlostdate, currency, actualrate, USDRate, srecommendM88, srecommend12BET, srecommendAB88)
	
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574036, 1752415, 1004374
	FROM bettrans b WITH (NOLOCK) 
	WHERE currency = 1 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574028, 836218, 932209
	FROM bettrans b WITH (NOLOCK) 
	WHERE currency = 2 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1573954, 791080, 932063
	FROM bettrans b WITH (NOLOCK) 
	WHERE currency = 3 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1573967, 836203, 932181
	FROM bettrans b WITH (NOLOCK) 
	WHERE currency = 4 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574024, 0, 0
	FROM bettrans b WITH (NOLOCK) 
	WHERE currency = 5 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1573960, 791081, 932167
	FROM bettrans b WITH (NOLOCK) 
	WHERE currency = 6 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574016, 1015419, 0
	FROM bettrans b WITH (NOLOCK) 
	WHERE currency = 9 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1573975, 836212, 932188
	FROM bettrans b WITH (NOLOCK) 
	WHERE currency = 12 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574008, 836226, 932253
	FROM bettrans b WITH (NOLOCK) 
	WHERE currency = 13 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574102, 1813575, 0
	FROM bettrans b WITH (NOLOCK) 
	WHERE currency = 15 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574095, 916498, 925144
	FROM bettrans b WITH (NOLOCK) 
	WHERE currency = 20 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 0, 1015427, 0
	FROM bettrans b WITH (NOLOCK) 
	WHERE currency = 41 and winlostdate = @winlostdate and bettype < 99
	SET @winlostdate = @winlostdate + 1 
END

--== 2.  BalanceUpDay < @winlostdate <= MoveBetDay


DECLARE	@winlostdate	DATETIME,
		@min_date		DATETIME,
		@max_date		DATETIME,
		@usdActualrate	FLOAT
SELECT	@min_date = '2009-11-07',
		@max_date = '2009-11-16',
		@winlostdate = @min_date

WHILE (@winlostdate <= @max_date)	
BEGIN

	SELECT @usdActualrate = (	SELECT TOP 1 actualrate FROM bettrans14 b WITH (NOLOCK) 
								WHERE currency = 3 and winlostdate = @winlostdate and bettype < 99)

	INSERT INTO Exchange_History_tmp (winlostdate, currency, actualrate, USDRate, srecommendM88, srecommend12BET, srecommendAB88)
	
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574036, 1752415, 1004374
	FROM bettrans14 b WITH (NOLOCK) 
	WHERE currency = 1 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 	
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574028, 836218, 932209
	FROM bettrans14 b WITH (NOLOCK) 
	WHERE currency = 2 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1573954, 791080, 932063
	FROM bettrans14 b WITH (NOLOCK) 
	WHERE currency = 3 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1573967, 836203, 932181
	FROM bettrans14 b WITH (NOLOCK) 
	WHERE currency = 4 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574024, 0, 0
	FROM bettrans14 b WITH (NOLOCK) 
	WHERE currency = 5 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1573960, 791081, 932167
	FROM bettrans14 b WITH (NOLOCK) 
	WHERE currency = 6 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574016, 1015419, 0
	FROM bettrans14 b WITH (NOLOCK) 
	WHERE currency = 9 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1573975, 836212, 932188
	FROM bettrans14 b WITH (NOLOCK) 
	WHERE currency = 12 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574008, 836226, 932253
	FROM bettrans14 b WITH (NOLOCK) 
	WHERE currency = 13 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574102, 1813575, 0
	FROM bettrans14 b WITH (NOLOCK) 
	WHERE currency = 15 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574095, 916498, 925144
	FROM bettrans14 b WITH (NOLOCK) 
	WHERE currency = 20 and winlostdate = @winlostdate and bettype < 99
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 0, 1015427, 0
	FROM bettrans14 b WITH (NOLOCK) 
	WHERE currency = 41 and winlostdate = @winlostdate and bettype < 99
	SET @winlostdate = @winlostdate + 1 

END


--== 3. @winlostdate <= BalanceUpDay


DECLARE	@winlostdate	DATETIME,
		@min_date		DATETIME,
		@max_date		DATETIME,
		@usdActualrate	FLOAT
SELECT	@min_date = '2009-05-01',
		@max_date = '2009-11-06',
		@winlostdate = @min_date

WHILE (@winlostdate <= @max_date)	
BEGIN

	SELECT @usdActualrate = (	SELECT TOP 1 actualrate FROM DB06.bodb_Archive.dbo.bettrans_bk b WITH (NOLOCK) 
								WHERE currency = 3 and winlostdate = @winlostdate)


	INSERT INTO Exchange_History_tmp (winlostdate, currency, actualrate, USDRate, srecommendM88, srecommend12BET, srecommendAB88)
	
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574036, 1752415, 1004374
	FROM DB06.bodb_Archive.dbo.bettrans_bk b WITH (NOLOCK) 
	WHERE currency = 1 and winlostdate = @winlostdate 
	UNION ALL 	
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574028, 836218, 932209
	FROM DB06.bodb_Archive.dbo.bettrans_bk b WITH (NOLOCK) 
	WHERE currency = 2 and winlostdate = @winlostdate 
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1573954, 791080, 932063
	FROM DB06.bodb_Archive.dbo.bettrans_bk b WITH (NOLOCK) 
	WHERE currency = 3 and winlostdate = @winlostdate 
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1573967, 836203, 932181
	FROM DB06.bodb_Archive.dbo.bettrans_bk b WITH (NOLOCK) 
	WHERE currency = 4 and winlostdate = @winlostdate 
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574024, 0, 0
	FROM DB06.bodb_Archive.dbo.bettrans_bk b WITH (NOLOCK) 
	WHERE currency = 5 and winlostdate = @winlostdate 
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1573960, 791081, 932167
	FROM DB06.bodb_Archive.dbo.bettrans_bk b WITH (NOLOCK) 
	WHERE currency = 6 and winlostdate = @winlostdate 
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574016, 1015419, 0
	FROM DB06.bodb_Archive.dbo.bettrans_bk b WITH (NOLOCK) 
	WHERE currency = 9 and winlostdate = @winlostdate 
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1573975, 836212, 932188
	FROM DB06.bodb_Archive.dbo.bettrans_bk b WITH (NOLOCK) 
	WHERE currency = 12 and winlostdate = @winlostdate
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574008, 836226, 932253
	FROM DB06.bodb_Archive.dbo.bettrans_bk b WITH (NOLOCK) 
	WHERE currency = 13 and winlostdate = @winlostdate 
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574102, 1813575, 0
	FROM DB06.bodb_Archive.dbo.bettrans_bk b WITH (NOLOCK) 
	WHERE currency = 15 and winlostdate = @winlostdate 
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 1574095, 916498, 925144
	FROM DB06.bodb_Archive.dbo.bettrans_bk b WITH (NOLOCK) 
	WHERE currency = 20 and winlostdate = @winlostdate 
	UNION ALL 
	SELECT TOP 1 @winlostdate, currency, actualrate, actualrate/@usdActualrate, 0, 1015427, 0
	FROM DB06.bodb_Archive.dbo.bettrans_bk b WITH (NOLOCK) 
	WHERE currency = 41 and winlostdate = @winlostdate 

	SET @winlostdate = @winlostdate + 1 
END


