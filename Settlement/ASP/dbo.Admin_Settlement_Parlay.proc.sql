
ALTER PROCEDURE [dbo].[Admin_Settlement_Parlay]
(
	@matchids	VARCHAR(2000),
	@creator	INT,
	@action		VARCHAR(10) = 'CAL',
	@IP			VARCHAR(15) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = '' OUTPUT
)
WITH RECOMPILE
AS
/*	Creator: Viet Hoang
	Date: 2008-12-16
	Task: Main SP for Mix parly settlement
	DB: DBTXN/BODB02

	History:
		- 20091225@Daniel: Add writelog table Userlog_settle
		- 20100209@Daniel: Prevent settle mix-parlay when tickets are being moved
		- 20091225@Daniel: Add writelog to table Userlog_settle	
		- 20100224@Daniel: Support settlement for GOLF (swap the score)
		- 20100305@Daniel: Add back writelog to table Userlog
		- 20100720@Henry: using SP Logfile to write log
		- 20100825@Lukas: Update last time modify (changetime column) for match table
		- 20110222@Joe : change @matchid to be varchar(2000) and create table @match to support multiple match calculate
		- 20110606@Lukas: replace update match statement by store procedure	
		- 20110624@Viet: 20110624@Viet: Offer 'Refund-HT'
		- 20110815@Lukas: merge code from live ( settle for combination parlay)
		- 20110830@Joe: enhance logging, to add duration for each step.
		- 20110918@Lukas: include not keyscore match in error message.
		- 20120404@Joe: BalanceTable
		- 20120710@Lukas: Check for currently running
		- 20121105@Viet: bring modds value from DBTrans to replicated servers.
		- 20130103@Lukas: Restrict settle time for matches under major leage
		- 20130121@Elodie: Change link server DB02, DB06 to DBPRO, DBACC
						   Write more log on DBTXN server in case of DBLOG server failure
		- 20130710@Viet: Change way to Parlay Settlement 
		- 20130711@Jamie: Add Balance Negative 
		- 20140220@Lukas: insert settled command into LAS queue [Redmine:#8785]
	Param's Explanation:
		+ @betstatus: Used for score table, FGLG status, refund status
		
*/
BEGIN
	SET NOCOUNT ON
	
	Declare @SkipBalanceUpdate bit
	SET @SkipBalanceUpdate = 0

	DECLARE  @start				DATETIME
			,@stop				DATETIME
			,@NotKeyScoreList	VARCHAR(130)
			,@ActionID			INT
			
	SELECT	@start = CURRENT_TIMESTAMP,
			@ErrCode = 0,
			@ErrMsg = ''
			
	SELECT @ActionID = CASE @Action 
							WHEN 'CAL' THEN 104
							WHEN 'UNDO' THEN 105
							WHEN 'REFUND-FT' THEN 106
							WHEN 'REFUND-HT' THEN 120
							WHEN 'REFUND' THEN 107
						END
	
	-- GET list of matchid(s)
	DECLARE @match TABLE (
		rn INT PRIMARY KEY IDENTITY(1,1), 
		matchid INT, 
		matchcode NVARCHAR(50),
		eventdate SMALLDATETIME, 
		fth SMALLINT, 
		fta SMALLINT, 
		hth SMALLINT, 
		hta SMALLINT,
		SportType SMALLINT, 
		betstatus NVARCHAR(50), 
		GoalRecord VARCHAR(50),
		CalTime int,
		UNIQUE( matchid )
	)

	INSERT INTO @match(matchid,matchcode, eventdate,fth, fta, hth, hta, SportType, betstatus, GoalRecord)
			SELECT	matchid,matchcode, eventdate,	finalhomescore, finalawayscore, hthomescore, htawayscore,
					SportType, betstatus, GoalRecord
			FROM DBPRO.BODB02.dbo.Match with (rowlock)
			WHERE matchid IN (SELECT val FROM dbo.strSplit(@matchids,','))

	IF EXISTS (SELECT 1 FROM @match	WHERE fth is null or fta is null or hth is null or hta is null)
	BEGIN			
		SELECT @NotKeyScoreList  = COALESCE(@NotKeyScoreList + ',' + matchcode,matchcode)
		FROM @match
		WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL

		-- exclude matches were not keyscore yet
		DELETE FROM @match
		WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL
	END

		--- LAS settlement 
	DECLARE @LASCommand NVARCHAR(1000)
		,@createdDate DATETIME

	SELECT @LASCommand = 'EXEC [dbo].[Admin_Settlement_Parlay] @matchids = ' + CONVERT(NVARCHAR(10), @matchids) + ', @creator = ' + CONVERT(NVARCHAR(10), @creator) + ', @action = ''' + @action + ''''
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

	DECLARE @rn INT,
			@subStart datetime, @CalTime int, @selTime int, @updTime int, @9Time int, @2Call int, @29Time int,
			@PreCal int, @Calculate int, @Summary int,
			@matchid INT, 
			@matchdate DATETIME,
			@finalhomescore INT,@finalawayscore INT,
			@hthomescore INT, @htawayscore INT, @GoalRecord VARCHAR(50),
			@sporttype TINYINT, @betstatus NVARCHAR(50),
			@TennisTotal SMALLINT, @T_Home SMALLINT, @T_Away SMALLINT,
			@tmp INT

	SET @rn = 1
	WHILE EXISTS (SELECT 1 FROM @match WHERE rn = @rn)
	BEGIN

		SELECT
			@subStart = CURRENT_TIMESTAMP,
			@matchid=matchid, @matchdate=eventdate,
			@finalhomescore=fth, @finalawayscore=fta, @hthomescore=hth, @htawayscore = hta,
			@sporttype=SportType, @betstatus=betstatus, @GoalRecord=GoalRecord
		FROM @match
		WHERE rn = @rn

		IF (@SportType IN (5, 6, 9, 30)) and @action = 'CAL' and @betstatus <> 'Refund' -- Tennis/VolleyBall/Badminton/Squash: get TotalGamesPlayed
			EXEC dbo.Admin_Settlement_2
					@betstatus	= @betstatus,
					@Total		= @TennisTotal OUTPUT,
					@TotalHome	= @T_Home OUTPUT,
					@TotalAway	= @T_Away OUTPUT

		IF @SportType = 10 -- Golf, using Stroke count, so swap the score to make it become normal stype
		BEGIN
			SELECT @tmp = @finalhomescore, @finalhomescore = @finalawayscore
			SELECT @finalawayscore = @tmp
		END

		-- CALCULATE RESULT of mixparlay for each match
		---------------------------------------------------------------
		BEGIN TRANSACTION
			IF @action IN ('REFUND-FT','REFUND-HT') -- if REFUND-FT or REFUND-HT called, do 'CAL' first, before do 'REFUND-FT'
				EXEC dbo.Admin_Calculate_9m @matchid, @finalhomescore, @finalawayscore, @hthomescore, @htawayscore, @matchdate, 'CAL', @TennisTotal
		COMMIT TRANSACTION

		BEGIN TRANSACTION
				EXEC dbo.Admin_Calculate_9m @matchid, @finalhomescore, @finalawayscore, @hthomescore, @htawayscore, @matchdate, @action, @TennisTotal
		COMMIT TRANSACTION

		UPDATE @match
		SET CalTime = DATEDIFF(millisecond, @subStart, CURRENT_TIMESTAMP)
		WHERE rn = @rn

		SET @rn = @rn + 1
	END

	-- Generate data for BetParlayDetail/Result
	SET @subStart = CURRENT_TIMESTAMP
		EXEC dbo.Admin_Calculate_29_Precal @matchids
	SET @PreCal = DATEDIFF(millisecond, @subStart, CURRENT_TIMESTAMP)

-------------------------------------------------------------
---        CAPTURE value BALANCE before settlement        ---
---------------------------VVVV------------------------------
CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)
Declare @TotalAccount int, @TotalAccount_BalanceUpdate int
IF @SkipBalanceUpdate = 0
BEGIN
--===
	;WITH refnos AS (
		SELECT distinct refno
		FROM dbo.bettransm b with (nolock)
			INNER JOIN @match m ON b.matchid = m.matchid
	)
	INSERT INTO #BalanceBefore
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans b with (rowlock)
		INNER JOIN refnos r ON b.refno = r.refno
	WHERE matchid IN (29)
	GROUP BY custid

	SET @TotalAccount = @@ROWCOUNT
--===
END --IF @SkipBalanceUpdate = 0

	---------------------------------------------------------------
	SET @subStart = CURRENT_TIMESTAMP
	SELECT @selTime = 0, @updTime = 0, @9Time = 0, @2Call = 0, @29Time = 0

	Declare @subMatchIDs varchar(2000), @9Start datetime
	Declare @Ev TABLE (rn int PRIMARY KEY IDENTITY (1,1), EventDate smalldatetime)
	INSERT INTO @Ev (EventDate)
	SELECT DISTINCT EventDate
	FROM @match
	ORDER BY EventDate

	SET @rn = 1
	WHILE EXISTS (SELECT 1 FROM @Ev WHERE rn = @rn)
	BEGIN
		SELECT @matchdate = EventDate FROM @Ev WHERE rn = @rn

		SET @subMatchIDs = (
				SELECT CAST(matchid as varchar(20)) + ','
				FROM @match
				WHERE EventDate = @matchdate
				FOR XML PATH('')
			)
		SET @subMatchIDs = SUBSTRING(@subMatchIDs, 1, LEN(@subMatchIDs)-1)

		declare @strXML_modds varchar(MAX)
		SET @strXML_modds = ''

			SET @9Start = CURRENT_TIMESTAMP
			
												EXEC dbo.Admin_Calculate_9_Cal
				@matchid = @subMatchIDs, 
				@matchdate = @matchdate
				
			SET @9Time = @9Time + DATEDIFF(millisecond, @9Start, CURRENT_TIMESTAMP)
			SET @2Call = @2Call + DATEDIFF(millisecond, @9Start, CURRENT_TIMESTAMP)
		--------/ 20121105@Viet : bring modds value from DBTrans to replicated servers.---

		BEGIN TRANSACTION
			SET @9Start = CURRENT_TIMESTAMP
			EXEC dbo.Admin_Calculate_29 @matchids = @subMatchIDs, @matchdate = @matchdate
			SET @29Time = @29Time + DATEDIFF(millisecond, @9Start, CURRENT_TIMESTAMP)
		COMMIT TRANSACTION

		SET @rn = @rn + 1
	END

	SET @Calculate = DATEDIFF(millisecond, @subStart, CURRENT_TIMESTAMP)

	--- insert sub-ticket into bettrans
	SET @subStart = CURRENT_TIMESTAMP
		EXEC dbo.Admin_Calculate_29_Summary
	SET @Summary = DATEDIFF(millisecond, @subStart, CURRENT_TIMESTAMP)

	---------------------------------------------------------------
	SET @rn = 1
	WHILE EXISTS (SELECT 1 FROM @match WHERE rn = @rn)
	BEGIN
		SELECT @matchid = matchid FROM @match WHERE rn = @rn

		IF @action = 'CAL'
												EXEC DBPRO.BODB02.dbo.UpdateMatch_Remark @matchid = @matchid, @command = 'M'
		ELSE IF @action = 'REFUND'
												EXEC DBPRO.BODB02.dbo.UpdateMatch_Remark @matchid = @matchid, @command = 'R'
		ELSE IF @action IN ('REFUND-FT','REFUND-HT')
												EXEC DBPRO.BODB02.dbo.UpdateMatch_Remark @matchid = @matchid, @command = 'F'

		---------------------------------------------------------------
		-- update match coz m88 project using DB02.dbo.match.tstamp to know match do parlay settle (vivi@2009-8-27)	
		EXEC DBPRO.BODB02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_Parlay', @Matchid = @matchid, @creator = @creator 
		---------------------------------------------------------------

		SET @rn = @rn + 1
	END

	---------------------------------------------------------------
	SELECT @stop = CURRENT_TIMESTAMP

-------------------------------------------------------------
---         CAPTURE value BALANCE after settlement        ---
---------------------------VVVV------------------------------
CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)
IF @SkipBalanceUpdate = 0
BEGIN
--===
	;WITH refnos AS (
		SELECT distinct refno
		FROM dbo.bettransm b with (nolock)
			INNER JOIN @match m ON b.matchid = m.matchid
	)
	INSERT INTO #BalanceAfter
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans b with (rowlock)
		INNER JOIN refnos r ON b.refno = r.refno
	WHERE matchid IN (29)
	GROUP BY custid
--===
END --IF @SkipBalanceUpdate = 0

-------------------------------------------------------------
---                   compare BALANCE                     ---
---------------------------VVVV------------------------------
CREATE TABLE #Balance (custid int PRIMARY KEY, balance money, Increased bit)
CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

INSERT INTO #Balance
SELECT b.custid, a.balance - b.balance, CASE WHEN a.balance > b.balance THEN 1 ELSE 0 END
FROM #BalanceBefore b
	INNER JOIN #BalanceAfter a ON b.custid = a.custid
WHERE b.balance <> a.balance

SET @TotalAccount_BalanceUpdate = @@ROWCOUNT


INSERT INTO dbo.BalancePendingDebit (custid, balance)
SELECT custid, ABS(balance)
FROM #Balance
WHERE Increased = 0

INSERT INTO dbo.BalancePendingCredit (custid, balance)
SELECT custid, balance
FROM #Balance
WHERE Increased = 1

----
-- Add Negative Balance into BalanceNegative table 
----
INSERT INTO [bodb02].[dbo].[BalanceNegative]
           ([ExecDate]
           ,[MatchID]
           ,[ActionID]
           ,[GroupID]
           ,[CustID]
           ,[Balance]
           ,[StatusID]
           ,[Remark])
SELECT	 GETDATE()
		,@MatchID
		,@ActionID
		,2			-- Sportsbook Parlay Settlement 
		,CustID
		,Balance
		,0
		,@matchids 
FROM	#Balance WITH (NOLOCK)
WHERE	Increased = 0
		        
---------------------------------------------------

DROP TABLE #Balance
DROP TABLE #BalanceBefore
DROP TABLE #BalanceAfter

-------------------------------------------------------------
---                      WRITE LOG                        ---
---------------------------VVVV------------------------------

	Declare @LogData nvarchar(200)
	DECLARE @Remark varchar(200)

	SET @rn = 1
	WHILE EXISTS (SELECT 1 FROM @match WHERE rn = @rn)
	BEGIN

		select
			@CalTime=CalTime,
			@matchid=matchid, @matchdate=eventdate,
			@finalhomescore=fth, @finalawayscore=fta, @hthomescore=hth, @htawayscore = hta,
			@sporttype=SportType, @betstatus=betstatus, @GoalRecord=GoalRecord
		from @match
		where rn = @rn

		SELECT @LogData = 'Calculate Multiple (' + @action 
			+ ') for matchid:' + CAST(@matchid as nvarchar(10)) 
			+ ' (' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms)'
			+ ' mpcs=' + CAST(@CalTime as nvarchar(10)) + ':' + CAST(@PreCal as nvarchar(10)) + ':' + CAST(@Calculate as nvarchar(10)) + ':' + CAST(@Summary as nvarchar(10))
			+ ' tsu2s=' + CAST(@9Time as nvarchar(10)) + ':' + CAST(@selTime as varchar(10)) + ':' + CAST(@updTIme as varchar(10)) + ':' + CAST(@2Call as nvarchar(10)) + ':' + CAST(@29Time as nvarchar(10))
		EXEC dbo.WriteLog_UserLog @creator, @LogData

		--Write Log Settle


		SELECT @Remark = 'Duration:' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms'
			+ ' mpcs=' + CAST(@CalTime as nvarchar(10)) + ':' + CAST(@PreCal as nvarchar(10)) + ':' + CAST(@Calculate as nvarchar(10)) + ':' + CAST(@Summary as nvarchar(10))
			+ ' tsu2s=' + CAST(@9Time as nvarchar(10)) + ':' + CAST(@selTime as varchar(10)) + ':' + CAST(@updTIme as varchar(10)) + ':' + CAST(@2Call as nvarchar(10)) + ':' + CAST(@29Time as nvarchar(10))

		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
				@UserID = @creator,
				@Matchid = @matchid,
				@ActionID = @ActionID,
				@finalhomescore = @finalhomescore,
				@finalawayscore = @finalawayscore,  
				@hthomescore = @hthomescore,
				@htawayscore = @htawayscore,
				@GoalRecord = @goalrecord,
				@betstatus = @betstatus,
				@Remark = @Remark,    
				@IP = @IP
		END TRY  
		BEGIN CATCH	
			SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 250)	
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
				@UserID = @creator,
				@Matchid = @matchid,
				@ActionID = @ActionID,
				@finalhomescore = @finalhomescore,
				@finalawayscore = @finalawayscore,  
				@hthomescore = @hthomescore,
				@htawayscore = @htawayscore,
				@GoalRecord = @goalrecord,
				@betstatus = @betstatus,
				@Remark = @Remark,    
				@IP = @IP
		END CATCH

		SET @rn = @rn + 1

	END	
END




GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_Parlay] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Settlement_Parlay] TO [vnteam] AS [dbo]