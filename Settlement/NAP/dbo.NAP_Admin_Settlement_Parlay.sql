/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_Parlay]    Script Date: 08/27/2014 14:06:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.NAP_Admin_Settlement_Parlay    Script Date: 22/07/2014 10:30:29 AM ******/
/****** Object:  Stored Procedure dbo.NAP_Admin_Settlement_Parlay    Script Date: 3/20/2014 5:36:24 PM ******/
/****** Object:  Stored Procedure dbo.NAP_Admin_Settlement_Parlay    Script Date: 3/17/2014 4:21:09 PM ******/

ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Parlay] (
	@matchids VARCHAR(2000)
	,@creator INT
	,@action VARCHAR(20) = 'CAL'
	,@resultPS NVARCHAR(10) = NULL
	,@IP VARCHAR(15) = ''
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
	) WITH RECOMPILE
AS
/*	Creator: Kathy
	Date: 20140213
	Task: Main SP for Mix parlay settlement
	DB: DBTXN/BODB02

	Revisions:
		- 20140417@Kathy: Fix LAS command
		- 20140512@Kathy: allow to execute undo action without score [Redmine:#14449]
		- 20140716@Kathy: Apply BetRadar [Redmine:#17142]
		- 20140717@Kathy: Settle MP for Penalty Shootout [Redmine:#17142]
		- 20141007@Kathy: Correct condition in case settle for sport (Tennis/VolleyBall/Badminton/Squash) [Redmine:#24073]
	Param's Explanation:
	@resultPS: match result of penalty shootout

		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE  @SkipBalanceUpdate BIT
			,@procName nvarchar(50)
			,@mode int

	SELECT   @SkipBalanceUpdate = 0
			,@procName = OBJECT_NAME(@@procid)

	SELECT @mode = CASE WHEN @procName LIKE '%_xtest' OR @procName LIKE '%_xpre%' THEN 1
						ELSE 0
				   END 


	DECLARE @start DATETIME
		,@stop DATETIME
		,@NotKeyScoreList VARCHAR(130)
		,@ActionID INT

	SELECT @start = CURRENT_TIMESTAMP
		,@ErrCode = 0
		,@ErrMsg = ''

	SELECT @ActionID = CASE @Action
			WHEN 'CAL' THEN 104
			WHEN 'UNDO' THEN 105
			WHEN 'REFUND-FT' THEN 106
			WHEN 'REFUND-HT' THEN 120
			WHEN 'REFUND' THEN 107
			END

	-- GET list of matchid(s)
	DECLARE @match TABLE (
		rn INT PRIMARY KEY IDENTITY(1, 1)
		,matchid INT
		,matchcode NVARCHAR(50)
		,eventdate SMALLDATETIME
		,fth SMALLINT
		,fta SMALLINT
		,hth SMALLINT
		,hta SMALLINT
		,SportType SMALLINT
		,betstatus NVARCHAR(50)
		,GoalRecord VARCHAR(50)
		,CalTime INT
		,UNIQUE (matchid)
		)

	-- check and not allow attempt to settlement same game while it's still not finish
	IF EXISTS (
			SELECT 1
			FROM dbo.TempVariableNumber
			WHERE KeyID = 1 AND KeyValue IN (
					SELECT val
					FROM dbo.strSplit(@matchids, ',')
					) 
			) AND @action <> 'UNDO' AND @resultPS IS NULL 
					
	BEGIN
		SELECT @ErrCode = 1000000
			,@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

		RETURN
	END
	
	INSERT INTO @match (
		matchid
		,matchcode
		,eventdate
		,fth
		,fta
		,hth
		,hta
		,SportType
		,betstatus
		,GoalRecord
		)
	SELECT matchid
		,matchcode
		,eventdate
		,finalhomescore
		,finalawayscore
		,hthomescore
		,htawayscore
		,SportType
		,betstatus
		,GoalRecord
	FROM DBPRO.BODB02.dbo.Match WITH (ROWLOCK)
	WHERE matchid IN (
			SELECT val
			FROM dbo.strSplit(@matchids, ',')
			)

	IF EXISTS (
			SELECT 1
			FROM @match
			WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL
			) AND @action <> 'UNDO' AND @resultPS IS NULL
	BEGIN
		SELECT @NotKeyScoreList = COALESCE(@NotKeyScoreList + ',' + matchcode, matchcode)
		FROM @match
		WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL

		-- exclude matches were not keyscore yet
		DELETE
		FROM @match
		WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL
	END

	--- LAS settlement 
	DECLARE @LASCommand NVARCHAR(1000)
		,@createdDate DATETIME

	SELECT @LASCommand = 'EXEC [dbo].[Admin_Settlement_Parlay] @matchids = ' + '''' + CONVERT(NVARCHAR(2000), @matchids) + '''' 
														  + ', @creator = ' + CONVERT(NVARCHAR(10), @creator) 
														  + ', @action = ' + '''' + CONVERT(NVARCHAR(50), @action) + ''''
														  + ',@resultPS = ' + CASE WHEN @resultPS IS NULL THEN 'NULL' ELSE '''' + CONVERT(NVARCHAR(50), @resultPS) + '''' END 									 
		,@createdDate = GETDATE()

	BEGIN TRY
		EXEC DBLAS.LASDB.[dbo].[Las_GeneratingSettlementCommand] @SPName = 'Admin_Settlement_Parlay'
			,@SQLCommand = @LASCommand
			,@CreatedDate = @createdDate
			,@StatusID = 0 -- waiting
			,@MatchID = @matchids
			,@Bettype = 9
			,@Status = 'waiting'
			,@BetCount = 0
		IF @@ERROR <> 0
		BEGIN
			SELECT	@ErrCode = 201
					,@ErrMsg = 'Calculate Parlay for this match is unsuccessfully. Please try again.'
			RETURN
		END 		
	END TRY
	BEGIN CATCH 
		SELECT	@ErrCode = 201
				,@ErrMsg = 'Calculate Parlay for this match is unsuccessfully. Please try again.'
		RETURN
	END CATCH

	DECLARE @rn INT
		,@subStart DATETIME
		,@CalTime INT
		,@selTime INT
		,@updTime INT
		,@9Time INT
		,@2Call INT
		,@29Time INT
		,@PreCal INT
		,@Calculate INT
		,@Summary INT
		,@matchid INT
		,@matchdate DATETIME
		,@finalhomescore INT
		,@finalawayscore INT
		,@hthomescore INT
		,@htawayscore INT
		,@GoalRecord VARCHAR(50)
		,@sporttype TINYINT
		,@betstatus NVARCHAR(50)
		,@TennisTotal SMALLINT
		,@T_Home SMALLINT
		,@T_Away SMALLINT
		,@tmp INT
		,@IsRefundHT BIT

	SET @rn = 1

	WHILE EXISTS (
			SELECT 1
			FROM @match
			WHERE rn = @rn
			)
	BEGIN
		SELECT @subStart = CURRENT_TIMESTAMP
			,@matchid = matchid
			,@matchdate = eventdate
			,@finalhomescore = fth
			,@finalawayscore = fta
			,@hthomescore = hth
			,@htawayscore = hta
			,@sporttype = SportType
			,@betstatus = betstatus
			,@GoalRecord = GoalRecord
		FROM @match
		WHERE rn = @rn

		SELECT @IsRefundHT = CASE WHEN betstatus LIKE 'Refund HT%' THEN 1 ELSE 0 END
		FROM match with(NOLOCK)
		WHERE matchid = @matchid

		IF (@SportType IN (5, 6, 9, 30)) AND @action = 'CAL' AND @betstatus not like 'Refund%' -- Tennis/VolleyBall/Badminton/Squash: get TotalGamesPlayed
												EXEC dbo.NAP_Admin_Settlement_2 @betstatus = @betstatus
				,@Total = @TennisTotal OUTPUT
				,@TotalHome = @T_Home OUTPUT
				,@TotalAway = @T_Away OUTPUT

		IF @SportType = 10 -- Golf, using Stroke count, so swap the score to make it become normal stype
		BEGIN
			SELECT @tmp = @finalhomescore
				,@finalhomescore = @finalawayscore

			SELECT @finalawayscore = @tmp
		END

		-- CALCULATE RESULT of mixparlay for each match
		---------------------------------------------------------------
		--BEGIN TRANSACTION

		--IF @action IN ('REFUND-FT', 'REFUND-HT') -- if REFUND-FT or REFUND-HT called, do 'CAL' first, before do 'REFUND-FT'
		--				EXEC dbo.NAP_Admin_Calculate_9m @matchid, @finalhomescore, @finalawayscore, @hthomescore, @htawayscore, @matchdate, 'CAL', @TennisTotal
			
		--COMMIT TRANSACTION

		--BEGIN TRANSACTION

		--EXEC dbo.NAP_Admin_Calculate_9m @matchid,@finalhomescore,@finalawayscore,@hthomescore,@htawayscore,@matchdate,@action,@TennisTotal

		--COMMIT TRANSACTION
		
		EXEC dbo.NAP_Admin_Calculate_Parlay @matchid = @matchid
			,@mode = 'ALL'
			,@action = @action
			,@resultPS = @resultPS
			,@IsRefundHT = @IsRefundHT
			,@fth = @finalhomescore
			,@fta = @finalawayscore
			,@hth = @hthomescore
			,@hta = @htawayscore
			,@matchdate = @matchdate
			,@TennisTotal = @TennisTotal

		UPDATE @match
		SET CalTime = DATEDIFF(millisecond, @subStart, CURRENT_TIMESTAMP)
		WHERE rn = @rn

		SET @rn = @rn + 1
	END

	-- Generate data for BetParlayDetail/Result
	SET @subStart = CURRENT_TIMESTAMP

	--EXEC dbo.NAP_Admin_Calculate_29_Precal @matchids

				EXEC dbo.NAP_Admin_Calculate_Parlay @matchids = @matchids
			,@mode = 'PRECAL-29'

	SET @PreCal = DATEDIFF(millisecond, @subStart, CURRENT_TIMESTAMP)

	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceBefore (
		custid INT PRIMARY KEY
		,balance MONEY
		)

	DECLARE @TotalAccount INT
		,@TotalAccount_BalanceUpdate INT

	IF @SkipBalanceUpdate = 0
	BEGIN
		--===
			;

		WITH refnos
		AS (
			SELECT DISTINCT refno
			FROM dbo.bettransm b WITH (NOLOCK)
				INNER JOIN @match m ON b.matchid = m.matchid
			)
		INSERT INTO #BalanceBefore
		SELECT custid
			,SUM(winlost - actual_stake + playercomm)
		FROM dbo.bettrans b WITH (ROWLOCK)
			INNER JOIN refnos r ON b.refno = r.refno
		WHERE matchid IN (29)
		GROUP BY custid

		SET @TotalAccount = @@ROWCOUNT
			--===
	END --IF @SkipBalanceUpdate = 0

	---------------------------------------------------------------
	SET @subStart = CURRENT_TIMESTAMP

	SELECT @selTime = 0
		,@updTime = 0
		,@9Time = 0
		,@2Call = 0
		,@29Time = 0

	DECLARE @subMatchIDs VARCHAR(2000)
		,@9Start DATETIME
	DECLARE @Ev TABLE (
		rn INT PRIMARY KEY IDENTITY(1, 1)
		,EventDate SMALLDATETIME
		)

	INSERT INTO @Ev (EventDate)
	SELECT DISTINCT EventDate
	FROM @match
	ORDER BY EventDate

	SET @rn = 1

	WHILE EXISTS (
			SELECT 1
			FROM @Ev
			WHERE rn = @rn
			)
	BEGIN
		SELECT @matchdate = EventDate
		FROM @Ev
		WHERE rn = @rn

		SET @subMatchIDs = (
				SELECT CAST(matchid AS VARCHAR(20)) + ','
				FROM @match
				WHERE EventDate = @matchdate
				FOR XML PATH('')
				)
		SET @subMatchIDs = SUBSTRING(@subMatchIDs, 1, LEN(@subMatchIDs) - 1)

		DECLARE @strXML_modds VARCHAR(MAX)

		SET @strXML_modds = ''
		SET @9Start = CURRENT_TIMESTAMP

		EXEC dbo.NAP_Admin_Calculate_9_Cal @matchid = @subMatchIDs,@matchdate = @matchdate, @mode = @mode

		SET @9Time = @9Time + DATEDIFF(millisecond, @9Start, CURRENT_TIMESTAMP)
		SET @2Call = @2Call + DATEDIFF(millisecond, @9Start, CURRENT_TIMESTAMP)

		--------/ 20121105@Viet : bring modds value from DBTrans to replicated servers.---
		BEGIN TRANSACTION

		SET @9Start = CURRENT_TIMESTAMP

		--EXEC dbo.NAP_Admin_Calculate_29 @matchids = @subMatchIDs
		--	,@matchdate = @matchdate
		
								EXEC dbo.NAP_Admin_Calculate_Parlay @matchids = @subMatchIDs
			,@mode = 'CAL-29'
			,@matchdate = @matchdate

		SET @29Time = @29Time + DATEDIFF(millisecond, @9Start, CURRENT_TIMESTAMP)

		COMMIT TRANSACTION

		SET @rn = @rn + 1
	END

	SET @Calculate = DATEDIFF(millisecond, @subStart, CURRENT_TIMESTAMP)
	--- insert sub-ticket into bettrans
	SET @subStart = CURRENT_TIMESTAMP

				EXEC dbo.NAP_Admin_Calculate_29_Summary

	SET @Summary = DATEDIFF(millisecond, @subStart, CURRENT_TIMESTAMP)
	---------------------------------------------------------------
	SET @rn = 1

	WHILE EXISTS (
			SELECT 1
			FROM @match
			WHERE rn = @rn
			)
	BEGIN
		SELECT @matchid = matchid
		FROM @match
		WHERE rn = @rn

		IF @resultPS IS NOT NULL
			BREAK

		IF @action = 'CAL'
												EXEC DBPRO.BODB02.dbo.NAP_UpdateMatch_Remark @matchid = @matchid
				,@command = 'M'
		ELSE IF @action IN ('REFUND', 'REFUND-FT', 'REFUND-HT')
												EXEC DBPRO.BODB02.dbo.NAP_UpdateMatch_Remark @matchid = @matchid
				,@command = 'R'
		--ELSE IF @action IN ('REFUND-FT', 'REFUND-HT')
		--										EXEC DBPRO.BODB02.dbo.NAP_UpdateMatch_Remark @matchid = @matchid
		--		,@command = 'F'

		---------------------------------------------------------------
		-- update match coz m88 project using DB02.dbo.match.tstamp to know match do parlay settle (vivi@2009-8-27)	
								EXEC DBPRO.BODB02.dbo.NAP_Admin_Match_Update @Command = 'NAP_Admin_Settlement_Parlay'
			,@Matchid = @matchid
			,@creator = @creator

		---------------------------------------------------------------
		SET @rn = @rn + 1
	END

	---------------------------------------------------------------
	SELECT @stop = CURRENT_TIMESTAMP

	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (
		custid INT PRIMARY KEY
		,balance MONEY
		)

	IF @SkipBalanceUpdate = 0
	BEGIN
		--===
		;WITH refnos
		AS (
			SELECT DISTINCT refno
			FROM dbo.bettransm b WITH (NOLOCK)
				INNER JOIN @match m ON b.matchid = m.matchid
			)
		INSERT INTO #BalanceAfter
		SELECT custid
			,SUM(winlost - actual_stake + playercomm)
		FROM dbo.bettrans b WITH (ROWLOCK)
			INNER JOIN refnos r ON b.refno = r.refno
		WHERE matchid IN (29)
		GROUP BY custid
			--===
	END --IF @SkipBalanceUpdate = 0

	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	CREATE TABLE #Balance (
		custid INT PRIMARY KEY
		,balance MONEY
		,Increased BIT
		)

	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

	INSERT INTO #Balance
	SELECT b.custid
		,a.balance - b.balance
		,CASE 
			WHEN a.balance > b.balance THEN 1
			ELSE 0
			END
	FROM #BalanceBefore b
		INNER JOIN #BalanceAfter a ON b.custid = a.custid
	WHERE b.balance <> a.balance

	SET @TotalAccount_BalanceUpdate = @@ROWCOUNT

	INSERT INTO dbo.BalancePendingDebit (
		custid
		,balance
		)
	SELECT custid
		,ABS(balance)
	FROM #Balance
	WHERE Increased = 0

	INSERT INTO dbo.BalancePendingCredit (
		custid
		,balance
		)
	SELECT custid
		,balance
	FROM #Balance
	WHERE Increased = 1

	----
	-- Add Negative Balance into BalanceNegative table 
	----
	INSERT INTO [bodb02].[dbo].[BalanceNegative] (
		[ExecDate]
		,[MatchID]
		,[ActionID]
		,[GroupID]
		,[CustID]
		,[Balance]
		,[StatusID]
		,[Remark]
		)
	SELECT GETDATE()
		,@MatchID
		,@ActionID
		,2 -- Sportsbook Parlay Settlement 
		,CustID
		,Balance
		,0
		,@matchids
	FROM #Balance WITH (NOLOCK)
	WHERE Increased = 0

	---------------------------------------------------
	DROP TABLE #Balance

	DROP TABLE #BalanceBefore

	DROP TABLE #BalanceAfter

	-------------------------------------------------------------
	---                      WRITE LOG                        ---
	---------------------------VVVV------------------------------
	DECLARE @LogData NVARCHAR(200)
	DECLARE @Remark VARCHAR(200)

	SET @rn = 1

	WHILE EXISTS (
			SELECT 1
			FROM @match
			WHERE rn = @rn
			)
	BEGIN
		SELECT @CalTime = CalTime
			,@matchid = matchid
			,@matchdate = eventdate
			,@finalhomescore = fth
			,@finalawayscore = fta
			,@hthomescore = hth
			,@htawayscore = hta
			,@sporttype = SportType
			,@betstatus = betstatus
			,@GoalRecord = GoalRecord
		FROM @match
		WHERE rn = @rn

		SELECT @LogData = 'NAP: Calculate Multiple (' + @action + ') for matchid:' + CAST(@matchid AS NVARCHAR(10)) + ' (' + CAST(DATEDIFF(millisecond, @start, @stop) AS NVARCHAR(50)) + ' ms)' + ' mpcs=' + CAST(@CalTime AS NVARCHAR(10)) + ':' + CAST(@PreCal AS NVARCHAR(10)) + ':' + CAST(@Calculate AS NVARCHAR(10)) + ':' + CAST(@Summary AS NVARCHAR(10)) + ' tsu2s=' + CAST(@9Time AS NVARCHAR(10)) + ':' + CAST(@selTime AS VARCHAR(10)) + ':' + CAST(@updTIme AS VARCHAR(10)) + ':' + CAST(@2Call AS NVARCHAR(10)) + ':' + CAST(@29Time AS NVARCHAR(10))

		EXEC dbo.WriteLog_UserLog @creator
			,@LogData

		--Write Log Settle
		SELECT @Remark = 'NAP: Duration:' + CAST(DATEDIFF(millisecond, @start, @stop) AS NVARCHAR(50)) + ' ms' + ' mpcs=' + CAST(@CalTime AS NVARCHAR(10)) + ':' + CAST(@PreCal AS NVARCHAR(10)) + ':' + CAST(@Calculate AS NVARCHAR(10)) + ':' + CAST(@Summary AS NVARCHAR(10)) + ' tsu2s=' + CAST(@9Time AS NVARCHAR(10)) + ':' + CAST(@selTime AS VARCHAR(10)) + ':' + CAST(@updTIme AS VARCHAR(10)) + ':' + CAST(@2Call AS NVARCHAR(10)) + ':' + CAST(@29Time AS NVARCHAR(10))

		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @creator
				,@Matchid = @matchid
				,@ActionID = @ActionID
				,@finalhomescore = @finalhomescore
				,@finalawayscore = @finalawayscore
				,@hthomescore = @hthomescore
				,@htawayscore = @htawayscore
				,@GoalRecord = @goalrecord
				,@betstatus = @betstatus
				,@Remark = @Remark
				,@IP = @IP
		END TRY

		BEGIN CATCH
			SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 250)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @creator
				,@Matchid = @matchid
				,@ActionID = @ActionID
				,@finalhomescore = @finalhomescore
				,@finalawayscore = @finalawayscore
				,@hthomescore = @hthomescore
				,@htawayscore = @htawayscore
				,@GoalRecord = @goalrecord
				,@betstatus = @betstatus
				,@Remark = @Remark
				,@IP = @IP
		END CATCH

		SET @rn = @rn + 1
	END
END





GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_Parlay] TO [vnteam] AS [dbo]