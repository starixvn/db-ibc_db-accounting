DECLARE @InputDate DATETIME
DECLARE @TempDate DATETIME
DECLARE @InputDate DATETIME
DECLARE @TempDate DATETIME
DECLARE @count int
DECLARE @DateName varchar(10)

IF @InputDate IS NULL  
BEGIN  
	SELECT @InputDate = DATEADD(DAY, 7, winlostdate)  
	FROM bodb02.dbo.bettrans WITH (NOLOCK)  
	WHERE matchid = 0 
		AND bettype = 20000  
	ORDER BY transid  

	IF @InputDate > CURRENT_TIMESTAMP  
	SET @InputDate = DATEADD(DAY, -7, @InputDate)  
END  

--SELECT @InputDate = CONVERT(DATE,DATEADD (ww,-1,GETDATE())) -- BalanceupDate
SELECT @DateName = DATENAME(dw,CONVERT(DATE,DATEADD (ww,-1,GETDATE())))

IF (@DateName = 'Thursday')
BEGIN
	SELECT @count = -7
	WHILE @count < 0 
	BEGIN
		SET @TempDate = DATEADD(day,@count,@InputDate)
		EXEC dbo.[Task_archive_rptStatement_Insert] @TempDate	
		--SELECT @TempDate
		SELECT @count = @count + 1
	END
END
ELSE IF (@DateName = 'Friday')
BEGIN
	SELECT @count = -7
	WHILE @count < 0 
	BEGIN
		SET @TempDate = DATEADD(day,@count,@InputDate)
		EXEC dbo.[Task_archive_rptStatement_Delete] @TempDate	
		--SELECT @TempDate
		SELECT @count = @count + 1
	END
END
ELSE
	RAISERROR ('Invalid BalanceUp Date',16,1);