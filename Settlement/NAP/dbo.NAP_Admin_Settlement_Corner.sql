USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_Corner]    Script Date: 08/07/2015 09:23:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.NAP_Admin_Settlement_Corner    Script Date: 7/6/2015 4:29:06 PM ******/
ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Corner] 
	 @AdminId				INT
	,@Matchid				INT
	,@fthCorners			SMALLINT		= NULL
	,@ftaCorners			SMALLINT		= NULL
	,@hthCorners			SMALLINT		= NULL
	,@htaCorners			SMALLINT		= NULL 
	,@FTFCorner				VARCHAR(1)		= NULL
	,@FTLCorner				VARCHAR(1)		= NULL
	,@HTFCorner				VARCHAR(1)		= NULL
	,@HTLCorner				VARCHAR(1)		= NULL 	
	,@Action				VARCHAR(10)		= 'CAL'
	,@IP					VARCHAR(15)		= ''
	,@ErrCode				INT				= 0		OUTPUT
	,@ErrMsg				NVARCHAR(200)	= ''	OUTPUT
AS
/*	Creator: Jamie
	Date: 20150618
	Task: Settlement Corner bets ONLY 
	DB: DBTXN/BODB02

	Revisions:		
		- 20150807@Kathy: Using new balance table (BalCreditSportsPending,BalDebitSportsPending) [Redmine:#40125]
		- 20160315@Patrick: Auto payout [Redmine: #53262]
		
	Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON 
	DECLARE	 @start						DATETIME
			,@stop						DATETIME
			,@eventstatus				NVARCHAR(50)
			,@fth						INT
			,@fta						INT
			,@hth						INT
			,@hta						INT
			,@goalrecord				VARCHAR(50)
			,@betstatus					VARCHAR(50) 
			,@ActionID					INT
			,@Remark					VARCHAR(500)
			,@LogData					NVARCHAR(300)							

	SELECT	@start = CURRENT_TIMESTAMP
	SELECT	@ActionID = CASE WHEN @Action = 'CAL' THEN 151 
							 WHEN @Action = 'CAL-HT' THEN 161
							 WHEN @Action = 'CAL-FT' THEN 162 
						ELSE 0 END
		
							 
	--Write Log Settle

	SELECT	 @fth			= finalhomescore
			,@fta			= finalawayscore
			,@hth			= hthomescore
			,@hta			= htawayscore
			,@goalrecord	= goalrecord 
			,@betstatus		= betstatus 
	FROM	DBPRO.BODB02.dbo.match WITH (NOLOCK)
	WHERE	matchid = @matchid
		
	-- check and not allow attempt to settlement same game while it's still not finish
	IF EXISTS (
			SELECT 1 
			FROM dbo.TempVariableNumber t WITH(NOLOCK)
			WHERE t.KeyID = 1 
			AND t.KeyValue = @matchid
			)
	BEGIN
		SELECT @ErrCode = 1000000
			,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

		RETURN
	END

	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue)
	VALUES (1, @matchid)

	IF @@ERROR > 0
	BEGIN
		SELECT @ErrCode = 1000000
			, @ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
							+ LEFT(ERROR_MESSAGE(), 400)
		RETURN

	END
	
	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceBefore (custid INT PRIMARY KEY, balance MONEY)

	--===
	IF @Action IN ('CAL', 'CAL-FT')
	BEGIN
		INSERT INTO #BalanceBefore
		SELECT b.custid, SUM(b.winlost - b.actual_stake + b.playercomm)
		FROM dbo.bettrans b WITH (ROWLOCK)
		WHERE b.matchid = @MatchId 
			AND b.bettype IN (194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209)
		GROUP BY b.custid
	END
	ELSE IF @Action = 'CAL-HT'
	BEGIN
		INSERT INTO #BalanceBefore
		SELECT b.custid, SUM(b.winlost - b.actual_stake + b.playercomm)
		FROM dbo.bettrans b WITH (ROWLOCK)
		WHERE b.matchid = @MatchId 
			AND b.bettype IN (200,201,202,203,204,205,207,209)
		GROUP BY b.custid
	END


	--===
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	IF @Action IN ('CAL', 'CAL-FT', 'CAL-HT')
	BEGIN

		DECLARE @Status TABLE(CornerBet BIT, BetCount INT, InRunning INT)

		INSERT INTO @Status(CornerBet, BetCount, InRunning)
		SELECT CASE WHEN bettype IN (194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209) THEN 1
				 ELSE 0 END --others
			, SUM(CASE WHEN statusID BETWEEN 101 AND 102 THEN 0 ELSE 1 END)
			, SUM(CASE WHEN statusID = 0 THEN 1 ELSE 0 END)
		FROM dbo.Bettrans WITH (NOLOCK)
		WHERE matchID = @MatchID 
			AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
			AND bettype NOT BETWEEN 1501 and 1599 -- Keno
			AND bettype NOT BETWEEN 801 AND 899 --Metric Gaming 
			AND bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) --Auto settle Betradar
		GROUP BY CASE WHEN bettype IN (194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209) THEN 1
				 ELSE 0 END --others

		IF NOT EXISTS(SELECT TOP 1 1 FROM @Status WHERE CornerBet = 0)
			INSERT INTO @Status(CornerBet, BetCount, InRunning) VALUES(0, 0, 0)

		DECLARE @NoneCornerBetDone BIT

		SELECT @NoneCornerBetDone = CASE InRunning WHEN 0 THEN 1 ELSE 0 END 
		FROM @Status
		WHERE CornerBet = 0
		
		SELECT @eventstatus = CASE WHEN @Action IN ('CAL', 'CAL-FT') AND @NoneCornerBetDone = 1 THEN N'completed'
								    ELSE eventstatus END
		FROM DBPRO.BODB02.dbo.Match m WITH(NOLOCK)
		WHERE m.matchid = @matchid

		EXEC DBPRO.BODB02.dbo.NAP_Admin_Match_Update 
			@Command			= 'NAP_Admin_Settlement_Corner-CAL'
			,@MatchID			= @matchid
			,@NoneCornerBetDone = @NoneCornerBetDone
			,@Action			= @action
			,@creator			= @AdminID

		EXEC DBPRO.BODB02.dbo.NAP_Admin_Result_Update_1s
				@Command = 'NAP_Admin_Settlement_Corner-CAL',
				@MatchID = @MatchID,
				@fthCorners = @fthCorners,
				@ftaCorners = @ftaCorners,
				@hthCorners = @hthCorners,
				@htaCorners = @htaCorners,
				@ftFCorner = @ftFCorner,
				@ftLCorner = @ftLCorner,
				@htFCorner = @htFCorner,
				@htLCorner = @htLCorner,
				@Action = @Action,
				@IsAuto = 0,
				@creator = @AdminID		

		EXEC dbo.[NAP_Admin_Settlement_3_Corner] @matchid = @matchid, @mode = @action	
			
		IF 	@eventstatus='completed'			
		BEGIN
			EXEC DBPRO.BODB02.dbo.NAP_updateMatch_remark @matchid = @matchid, @command	= 'C'
		END

	END

	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (custid INT PRIMARY KEY, balance MONEY)
	
	IF @Action IN ('CAL', 'CAL-FT')
	BEGIN
		INSERT INTO #BalanceAfter
		SELECT b.custid, SUM(b.winlost - b.actual_stake + b.playercomm)
		FROM dbo.bettrans b WITH (ROWLOCK)
		WHERE b.matchid = @MatchId 
			AND b.bettype IN (194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209)
		GROUP BY b.custid
	END
	ELSE IF @Action = 'CAL-HT'
	BEGIN
		INSERT INTO #BalanceAfter
		SELECT b.custid, SUM(b.winlost - b.actual_stake + b.playercomm)
		FROM dbo.bettrans b WITH (ROWLOCK)
		WHERE b.matchid = @MatchId 
			AND b.bettype IN (200,201,202,203,204,205,207,209)
		GROUP BY b.custid
	END

	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	CREATE TABLE #Balance (custid INT PRIMARY KEY, balance MONEY, Increased BIT)
	DECLARE @tblDebitPending TVP_BalanceList
	DECLARE @tblCreditPending TVP_BalanceList
	
	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

	INSERT INTO #Balance
	SELECT b.custid
		, a.balance - b.balance
		, CASE WHEN a.balance > b.balance THEN 1 ELSE 0	END
	FROM #BalanceBefore b
		INNER JOIN #BalanceAfter a ON b.custid = a.custid
	WHERE b.balance <> a.balance
	
	INSERT INTO @tblDebitPending (custID, balance)
	SELECT custid, ABS(balance)
	FROM #Balance
	WHERE Increased = 0
	
	IF @@ROWCOUNT <> 0
		EXEC dbo.Dot_BalancePendingDebitIns @BalancePending = @tblDebitPending, @Type = 1 -- Sports
			
	INSERT INTO @tblCreditPending (custID, balance)
	SELECT custid, balance
	FROM #Balance
	WHERE Increased = 1
	
	IF @@ROWCOUNT <> 0
		EXEC dbo.Dot_BalancePendingCreditIns @BalancePending = @tblCreditPending, @Type = 1 -- Sports

	----
	-- Add Negative Balance into BalanceNegative table 
	----
	INSERT INTO [bodb02].[dbo].[BalanceNegative] ([ExecDate], [MatchID], [ActionID], [GroupID], [CustID], [Balance], [StatusID], [Remark])
	SELECT GETDATE(), @MatchID, @ActionID, 1/*Sportsbook Single bet Settlement*/, CustID, Balance, 0, NULL
	FROM #Balance WITH(NOLOCK)
	WHERE Increased = 0

	---------------------------------------------------
	DROP TABLE #Balance
	DROP TABLE #BalanceBefore
	DROP TABLE #BalanceAfter

	-------------------------------------------------------------
	---                      WRITE LOG                        ---
	---------------------------VVVV------------------------------

	SELECT @stop = CURRENT_TIMESTAMP

	SELECT @logdata = 'NAP: Calculate Corner (' + @action + ') for matchid:' + CAST(@matchid AS NVARCHAR(10)) 
														   + ' FT:' + CASE WHEN @fthCorners IS NULL THEN '' ELSE CAST(@fthCorners AS VARCHAR(20)) END 
														   + '-'  + CASE WHEN @ftaCorners IS NULL THEN '' ELSE CAST(@ftaCorners AS VARCHAR(20)) END 
														   + ' HT:'  + CASE WHEN @hthCorners IS NULL THEN '' ELSE CAST(@hthCorners AS VARCHAR(20)) END 
														   + '-'  + CASE WHEN @htaCorners IS NULL THEN '' ELSE CAST(@htaCorners AS VARCHAR(20)) END 
														   + ' FTF:' + CASE WHEN @FTFCorner IS NULL THEN '' ELSE @FTFCorner END
														   + ' FTL:' + CASE WHEN @FTLCorner IS NULL THEN '' ELSE @FTLCorner END
														   + ' HTF:' + CASE WHEN @HTFCorner IS NULL THEN '' ELSE @HTFCorner END
														   + ' HTL ' + CASE WHEN @HTLCorner IS NULL THEN '' ELSE @HTLCorner END 
	EXEC dbo.WriteLog_UserLog @UserID = @AdminId, @Doing = @logdata

	SELECT @Remark = 'NAP: '
						+ CASE WHEN @fthCorners IS NULL THEN '' ELSE 'fthCorners:' + CAST(@fthCorners AS VARCHAR(50))  + ' ' END 
						+ CASE WHEN @ftaCorners IS NULL THEN '' ELSE 'ftaCorners:' + CAST(@ftaCorners AS VARCHAR(50))  + '<br/> ' END
						+ CASE WHEN @hthCorners IS NULL THEN '' ELSE 'hthCorners:' + CAST(@hthCorners AS VARCHAR(50))  + ' ' END
						+ CASE WHEN @htaCorners IS NULL THEN '' ELSE 'htaCorners:' + CAST(@htaCorners AS VARCHAR(50))  + '<br/> ' END
						+ CASE WHEN @ftFCorner IS NULL THEN '' ELSE 'ftFCorner:' + @ftFCorner + '<br/> ' END
						+ CASE WHEN @ftLCorner IS NULL THEN '' ELSE 'ftLCorner:' + @ftLCorner + '<br/> ' END
						+ CASE WHEN @htFCorner IS NULL THEN '' ELSE 'htFCorner:' + @htFCorner + '<br/> ' END
						+ CASE WHEN @htLCorner IS NULL THEN '' ELSE 'htLCorner:' + @htLCorner + '<br/> ' END
						+ ' Duration:' + CAST(DATEDIFF(millisecond, @start, @stop) AS NVARCHAR(50)) + 'ms' 
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @userid = @AdminId
			, @matchid			= @MatchID
			, @actionid			= @ActionID
			, @finalhomescore	= @fth
			, @finalawayscore	= @fta
			, @hthomescore		= @hth
			, @htawayscore		= @hta
			, @GoalRecord		= @goalrecord
			, @betstatus		= @betstatus
			, @Remark			= @Remark
			, @ip				= @ip
	END TRY

	BEGIN CATCH
		SELECT @remark = @remark + ' ErrMsg=' + LEFT(ERROR_MESSAGE(), 250)

		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @AdminId
			, @MatchID			= @matchid
			, @actionid			= @actionid
			, @finalhomescore	= @fth
			, @finalawayscore	= @fta
			, @hthomescore		= @hth
			, @htawayscore		= @hta
			, @GoalRecord		= @goalrecord
			, @betstatus		= @betstatus
			, @Remark			= @Remark
			, @IP				= @ip
	END CATCH

	--
	DELETE
	FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid
	
END
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_Corner] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_Corner] TO [vnteam] AS [dbo]