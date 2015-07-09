

ALTER PROCEDURE [dbo].[DBA_UpdateExRates] 
	@Winlostdate datetime = NULL
AS
/*
 	DB: DB02.bodb02
  	Creator : Viet
 	Date : May 18, 2010
 	Task : Update rates for all existed tickets once financial change rates
 	
 	Revisions:			
		- 20101225@Henry: change bettype to new range
		- 20121022@Thien: change from "b.bettype between 50 and 98" to "b.bettype between 50 and 19998"
 		- 20121113@Lukas: Modify SP to be able run on DBTP
 		- 20121224@Thien: prevent from running for the day in the past
 	Param's Explanation: 
 		@Winlostdate: the date that new rates are updated		
 */
SET NOCOUNT ON

IF @Winlostdate < convert(nvarchar(10), getdate() ,120)
BEGIN
	RaisError ('Please comment out this section if you want to run this SP for the day in the past!', 16, 1)
	return
END

IF @Winlostdate is NULL 
    RETURN

DECLARE @Cnt int
IF @@SERVERNAME IN ('DBTP','DWDBG1S')
BEGIN
	PRINT '1.----------------'
	WHILE 1=1
	BEGIN
		UPDATE TOP (5000) dbo.recomm_Log 
		SET  actualrate = e.actualrate
		FROM dbo.recomm_Log b WITH(NOLOCK)
			INNER JOIN dbo.exchange e WITH(NOLOCK) ON b.currency = e.exchangeid
		WHERE	b.actualrate <> e.actualrate
			AND b.winlostdate >= @Winlostdate 
			AND (b.bettype < 30 OR b.bettype between 50 and 19998)
			  	
		SELECT @Cnt = @@ROWCOUNT
		Print '  ' + Cast(@Cnt as varchar(10)) + ' row(s) affected'
		IF @Cnt < 5000 BREAK
		WAITFOR DELAY '00:00:02' -- Delay 2 Seconds    
	END

	--PRINT '2.----------------'
	---- update for SB's tickets (without virtualrate)
	--WHILE 1=1
	--BEGIN
	--	UPDATE TOP (5000) dbo.bettrans 
	--	SET actualrate = e.actualrate, 
	--		virtualrate = e.actualrate
	--	FROM dbo.bettrans b WITH (nolock), dbo.exchange e WITH (nolock)
	--	WHERE b.currency = e.exchangeid 
	--		AND b.actualrate <> e.actualrate
	--		AND b.winlostdate >= @Winlostdate 
	--		AND (b.bettype < 30 OR b.bettype between 50 and 19998)
	--		AND b.actualrate = b.virtualrate		
			  
	--	SELECT @Cnt = @@ROWCOUNT
	--	Print '  ' + Cast(@Cnt as varchar(10)) + ' row(s) affected'
	--	IF @Cnt < 5000 BREAK
	--	WAITFOR DELAY '00:00:02' -- Delay 2 Seconds
	--END
	PRINT '3.----------------'
	-- update for TOTE tickets
	WHILE 1=1
	BEGIN
		UPDATE TOP (5000) dbo.recomm_Log 
		SET actualrate = e.actualrate, 
			virtualrate = e.actualrate
		FROM dbo.recomm_Log b WITH(nolock) 
			INNER JOIN dbo.exchange e WITH (nolock) ON b.currency = e.exchangeid
		WHERE b.actualrate <> e.actualrate
			AND b.winlostdate >= @Winlostdate 
			AND b.bettype between 30 and 49
			AND b.actualrate = b.virtualrate
			and b.currency2 IS NULL
			  
		SELECT @Cnt = @@ROWCOUNT
		Print '  ' + Cast(@Cnt as varchar(10)) + ' row(s) affected'
		IF @Cnt < 5000 BREAK
		WAITFOR DELAY '00:00:02' -- Delay 2 Seconds
	END
	PRINT '4.----------------'
	-- OPENTOTE tickets
	WHILE 1=1
	BEGIN
		UPDATE TOP (5000) dbo.recomm_Log 
		SET actualrate = e.actualrate
		FROM dbo.recomm_Log b WITH (nolock) 
			INNER JOIN dbo.exchange e WITH (nolock) ON b.currency = e.exchangeid
		WHERE b.actualrate <> e.actualrate
			AND b.winlostdate >= @Winlostdate 
			AND b.bettype between 30 and 49
			and b.currency2 IS NOT NULL
			  
		SELECT @Cnt = @@ROWCOUNT
		Print '  ' + Cast(@Cnt as varchar(10)) + ' row(s) affected'
		IF @Cnt < 5000 BREAK
		WAITFOR DELAY '00:00:02' -- Delay 2 Seconds
	END	
END
ELSE
BEGIN
	-- update for SB's tickets (using virtualrate)
	PRINT '1.----------------'
	WHILE 1=1
	BEGIN
		UPDATE TOP (5000) dbo.bettrans 
		SET  actualrate = e.actualrate, 
			virtualrate =  e.actualrate * c.virtualmultiplier
		FROM dbo.bettrans b WITH (nolock), 
			dbo.custinfo c WITH (nolock), 
			dbo.exchange e WITH (nolock)
		WHERE b.custid = c.custid 
			AND b.currency = e.exchangeid 
			AND b.actualrate <> e.actualrate
			AND b.winlostdate >= @Winlostdate 
			AND (b.bettype < 30 OR b.bettype between 50 and 19998)
			AND b.actualrate <> b.virtualrate
			  	
		SELECT @Cnt = @@ROWCOUNT
		Print '  ' + Cast(@Cnt as varchar(10)) + ' row(s) affected'
		IF @Cnt < 5000 BREAK
		WAITFOR DELAY '00:00:02' -- Delay 2 Seconds    
	END

	PRINT '2.----------------'
	-- update for SB's tickets (without virtualrate)
	WHILE 1=1
	BEGIN
		UPDATE TOP (5000) dbo.bettrans 
		SET actualrate = e.actualrate, 
			virtualrate = e.actualrate
		FROM dbo.bettrans b WITH (nolock), dbo.exchange e WITH (nolock)
		WHERE b.currency = e.exchangeid 
			AND b.actualrate <> e.actualrate
			AND b.winlostdate >= @Winlostdate 
			AND (b.bettype < 30 OR b.bettype between 50 and 19998)
			AND b.actualrate = b.virtualrate		
			  
		SELECT @Cnt = @@ROWCOUNT
		Print '  ' + Cast(@Cnt as varchar(10)) + ' row(s) affected'
		IF @Cnt < 5000 BREAK
		WAITFOR DELAY '00:00:02' -- Delay 2 Seconds
	END
	PRINT '3.----------------'
	-- update for TOTE tickets
	WHILE 1=1
	BEGIN
		UPDATE TOP (5000) dbo.bettrans 
		SET actualrate = e.actualrate, 
			virtualrate = e.actualrate
		FROM dbo.bettrans b WITH (nolock), dbo.exchange e WITH (nolock)
		WHERE b.currency = e.exchangeid 
			AND b.actualrate <> e.actualrate
			AND b.winlostdate >= @Winlostdate 
			AND b.bettype between 30 and 49
			AND b.actualrate = b.virtualrate
			and b.currency2 IS NULL
			  
		SELECT @Cnt = @@ROWCOUNT
		Print '  ' + Cast(@Cnt as varchar(10)) + ' row(s) affected'
		IF @Cnt < 5000 BREAK
		WAITFOR DELAY '00:00:02' -- Delay 2 Seconds
	END
	PRINT '4.----------------'
	-- OPENTOTE tickets
	WHILE 1=1
	BEGIN
		UPDATE TOP (5000) dbo.bettrans 
		SET actualrate = e.actualrate
		FROM dbo.bettrans b WITH (nolock), dbo.exchange e WITH (nolock)
		WHERE b.currency = e.exchangeid 
			AND b.actualrate <> e.actualrate
			AND b.winlostdate >= @Winlostdate 
			AND b.bettype between 30 and 49
			and b.currency2 IS NOT NULL
			  
		SELECT @Cnt = @@ROWCOUNT
		Print '  ' + Cast(@Cnt as varchar(10)) + ' row(s) affected'
		IF @Cnt < 5000 BREAK
		WAITFOR DELAY '00:00:02' -- Delay 2 Seconds
	END
	PRINT '5.----------------'
	-- transfer tickets
	WHILE 1=1
	BEGIN
		UPDATE TOP (5000) dbo.bettrans 
		SET actualrate = e.actualrate
		FROM dbo.bettrans b WITH (nolock),dbo.exchange e WITH (nolock)
		WHERE b.currency = e.exchangeid 
			AND b.actualrate <> e.actualrate
			AND b.winlostdate >= @Winlostdate 
			AND b.bettype >=19001 
		
		SELECT @Cnt = @@ROWCOUNT
		Print '  ' + Cast(@Cnt as varchar(10)) + ' row(s) affected'
		IF @Cnt < 5000 BREAK
		WAITFOR DELAY '00:00:02' -- Delay 2 Seconds
	END
END


GO
GRANT VIEW DEFINITION ON [dbo].[DBA_UpdateExRates] TO [vnteam] AS [dbo]