ALTER PROCEDURE [dbo].[Bet_ExecRep_04] @Winlostdate DATETIME = NULL
	,@Target VARCHAR(30) = 'DBTRANS' -- DBTRANS/REPLICATED
AS
/*
 	DB: DBTXN/bodb02
  	Creator : Viet
 	Date : May 18, 2010
 	Task : Update rates for all existed tickets once financial change rates
 	
 	Revisions:			
		- 20101225@Henry: change bettype to new range
		- 20121022@Thien: change from "b.bettype between 50 and 98" to "b.bettype between 50 and 19998"
		- 20121224@Thien: prevent from running for the day in the past
		- 20130507@Thien: change to use ExecRep [Bet_ExecRep_04], old SP is DBA_UpdateExRates
 		- 20131108@Elodie: Splitting bodb02 into CustDB (call custinfo, exchange by link database)
 		- 20140124@Viet: fix splitting issue
		- 20140701@Jamie: Get virtualmultiplier of bettrans 
 		
 	Param's Explanation: 
 		@Winlostdate: the date that new rates are updated		
 */
SET NOCOUNT ON
BEGIN
	IF @Winlostdate IS NULL RETURN
	IF @Target NOT IN ('DBTRANS', 'REPLICATED') RETURN
	IF @Target = 'DBTRANS' AND @@SERVERNAME <> 'DBTRANS' RETURN
	IF @Target = 'REPLICATED' AND @@SERVERNAME = 'DBTRANS' RETURN

	PRINT 'START: Reminder of UPDATE Exchange Rate Oanda: EXEC CustDB.dbo.DBA_ExchangeDailyOandaUpd_Actualrate @ExchangeDate=''xxx'''

	DECLARE @Cnt INT
	DECLARE @virtualmultiplier SMALLMONEY

	IF @@SERVERNAME = 'DBTRANS'
	BEGIN
		-- update for SB's tickets (using virtualrate)
		PRINT '1.----------------'

		WHILE 1 = 1
		BEGIN
			UPDATE TOP (5000) b
			SET @virtualmultiplier = b.virtualrate/b.actualrate 
				,actualrate = e.actualrate
				,virtualrate = e.actualrate * @virtualmultiplier
				--,virtualrate = e.actualrate * c.virtualmultiplier
			FROM dbo.bettrans b WITH(ROWLOCK, UPDLOCK)
				--,CustDB.dbo.custinfo c WITH (NOLOCK)
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE --b.custid = c.custid AND 
				b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) AND b.actualrate <> b.virtualrate

			SELECT @Cnt = @@ROWCOUNT

			PRINT '  ' + Cast(@Cnt AS VARCHAR(10)) + ' row(s) affected'

			IF @Cnt < 5000
				BREAK

			WAITFOR DELAY '00:00:01' -- Delay 1 Seconds    
		END

		PRINT '2.----------------'

		-- update for SB's tickets (without virtualrate)
		WHILE 1 = 1
		BEGIN
			UPDATE TOP (5000) b
			SET actualrate = e.actualrate
				,virtualrate = e.actualrate
			FROM dbo.bettrans b WITH(ROWLOCK, UPDLOCK)
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) AND b.actualrate = b.virtualrate

			SELECT @Cnt = @@ROWCOUNT

			PRINT '  ' + Cast(@Cnt AS VARCHAR(10)) + ' row(s) affected'

			IF @Cnt < 5000
				BREAK

			WAITFOR DELAY '00:00:01' -- Delay 1 Seconds
		END

		PRINT '3.----------------'

		-- update for TOTE tickets
		WHILE 1 = 1
		BEGIN
			UPDATE TOP (5000) b
			SET actualrate = e.actualrate
				,virtualrate = e.actualrate
			FROM dbo.bettrans b WITH(ROWLOCK, UPDLOCK)
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 AND b.actualrate = b.virtualrate AND b.currency2 IS NULL

			SELECT @Cnt = @@ROWCOUNT

			PRINT '  ' + Cast(@Cnt AS VARCHAR(10)) + ' row(s) affected'

			IF @Cnt < 5000
				BREAK

			WAITFOR DELAY '00:00:01' -- Delay 1 Seconds
		END

		PRINT '4.----------------'

		-- OPENTOTE tickets
		WHILE 1 = 1
		BEGIN
			UPDATE TOP (5000) b
			SET actualrate = e.actualrate
			FROM dbo.bettrans b WITH(ROWLOCK, UPDLOCK)
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 AND b.currency2 IS NOT NULL

			SELECT @Cnt = @@ROWCOUNT

			PRINT '  ' + Cast(@Cnt AS VARCHAR(10)) + ' row(s) affected'

			IF @Cnt < 5000
				BREAK

			WAITFOR DELAY '00:00:01' -- Delay 1 Seconds
		END

		PRINT '5.----------------'

		-- transfer tickets
		WHILE 1 = 1
		BEGIN
			UPDATE TOP (5000) b
			SET actualrate = e.actualrate
			FROM dbo.bettrans b WITH(ROWLOCK, UPDLOCK)
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype >= 19001

			SELECT @Cnt = @@ROWCOUNT

			PRINT '  ' + Cast(@Cnt AS VARCHAR(10)) + ' row(s) affected'

			IF @Cnt < 5000
				BREAK

			WAITFOR DELAY '00:00:01' -- Delay 1 Seconds
		END
	END
	
	IF @@SERVERNAME <> 'DBTRANS'
	BEGIN
		IF (
			SELECT COUNT(1)
			FROM sysobjects
			WHERE NAME IN ('custinfo', 'bettrans', 'exchange') AND type = 'U'
		) < 3 RETURN
		
		-- update for SB's tickets (using virtualrate)
		PRINT '1.----------------'
		WHILE 1 = 1
		BEGIN
			UPDATE TOP (5000) b
			SET @virtualmultiplier = b.virtualrate/b.actualrate 
				,actualrate = e.actualrate
				,virtualrate = e.actualrate * @virtualmultiplier
				--,virtualrate = e.actualrate * c.virtualmultiplier
			FROM dbo.bettrans b WITH(ROWLOCK, UPDLOCK)
				--,dbo.custinfo c WITH (NOLOCK)
				,dbo.exchange e WITH (NOLOCK)
			WHERE --b.custid = c.custid AND 
					b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) AND b.actualrate <> b.virtualrate

			SELECT @Cnt = @@ROWCOUNT

			PRINT '  ' + Cast(@Cnt AS VARCHAR(10)) + ' row(s) affected'

			IF @Cnt < 5000
				BREAK

			WAITFOR DELAY '00:00:01' -- Delay 1 Seconds    
		END

		PRINT '2.----------------'

		-- update for SB's tickets (without virtualrate)
		WHILE 1 = 1
		BEGIN
			UPDATE TOP (5000) b
			SET actualrate = e.actualrate
				,virtualrate = e.actualrate
			FROM dbo.bettrans b WITH(ROWLOCK, UPDLOCK)
				,dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) AND b.actualrate = b.virtualrate

			SELECT @Cnt = @@ROWCOUNT

			PRINT '  ' + Cast(@Cnt AS VARCHAR(10)) + ' row(s) affected'

			IF @Cnt < 5000
				BREAK

			WAITFOR DELAY '00:00:01' -- Delay 1 Seconds
		END

		PRINT '3.----------------'

		-- update for TOTE tickets
		WHILE 1 = 1
		BEGIN
			UPDATE TOP (5000) b
			SET actualrate = e.actualrate
				,virtualrate = e.actualrate
			FROM dbo.bettrans b WITH(ROWLOCK, UPDLOCK)
				,dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 AND b.actualrate = b.virtualrate AND b.currency2 IS NULL

			SELECT @Cnt = @@ROWCOUNT

			PRINT '  ' + Cast(@Cnt AS VARCHAR(10)) + ' row(s) affected'

			IF @Cnt < 5000
				BREAK

			WAITFOR DELAY '00:00:01' -- Delay 1 Seconds
		END

		PRINT '4.----------------'

		-- OPENTOTE tickets
		WHILE 1 = 1
		BEGIN
			UPDATE TOP (5000) b
			SET actualrate = e.actualrate
			FROM dbo.bettrans b WITH(ROWLOCK, UPDLOCK)
				,dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 AND b.currency2 IS NOT NULL

			SELECT @Cnt = @@ROWCOUNT

			PRINT '  ' + Cast(@Cnt AS VARCHAR(10)) + ' row(s) affected'

			IF @Cnt < 5000
				BREAK

			WAITFOR DELAY '00:00:01' -- Delay 1 Seconds
		END

		PRINT '5.----------------'

		-- transfer tickets
		WHILE 1 = 1
		BEGIN
			UPDATE TOP (5000) b
			SET actualrate = e.actualrate
			FROM dbo.bettrans b WITH(ROWLOCK, UPDLOCK)
				,dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype >= 19001

			SELECT @Cnt = @@ROWCOUNT

			PRINT '  ' + Cast(@Cnt AS VARCHAR(10)) + ' row(s) affected'

			IF @Cnt < 5000
				BREAK

			WAITFOR DELAY '00:00:01' -- Delay 1 Seconds
		END
	END
	
	PRINT 'END: Reminder of UPDATE Exchange Rate Oanda: EXEC CustDB.dbo.DBA_ExchangeDailyOandaUpd_Actualrate @ExchangeDate=''xxx'''

END


GO
GRANT VIEW DEFINITION ON [dbo].[Bet_ExecRep_04] TO [vnteam] AS [dbo]