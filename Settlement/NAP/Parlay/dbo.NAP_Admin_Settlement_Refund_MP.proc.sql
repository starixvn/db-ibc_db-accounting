ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Refund_MP] (
	@MatchId 	INT
	,@Creator 	INT
	,@Action 	VARCHAR(20)
	,@IP 		VARCHAR(15) = ''
	,@ErrCode 	INT = 0 OUTPUT
	,@ErrMsg 	NVARCHAR(200) = '' OUTPUT
)
AS
/*	Creator: 20161206@Bobby
	Task: #61352 - Apply settle determined for parlay bet types
	DB: DBTXN/BODB02
	ORIGINAL: 

	Revisions:		
		

	Param's Explanation:		
		
*/


BEGIN
	SET NOCOUNT ON

DECLARE @start DATETIME
	, @stop DATETIME
	, @ActionID INT
	, @IsDetermined BIT
	, @resultDetail_cb VARCHAR(MAX) = NULL -- for corners bets
	, @resultDetail_ss VARCHAR(MAX)
	, @SelectedSetCAL VARCHAR(50)
	, @SelectedSetREFUND VARCHAR(50)
	
	DECLARE @TennisTotal INT = NULL, @TotalGameHomeMatch INT = NULL, @TotalGameAwayMatch INT = NULL

	SELECT @ActionID 	= CASE 
						WHEN @action IN ('ABANDONED-2H', 'REFUND-FT') THEN 106
						WHEN @action IN ('ABANDONED-1H', 'REFUND') THEN 107
						WHEN @action IN ('REFUND-HT') THEN 120
						ELSE NULL
					END
		, @IsDetermined = CASE WHEN @action IN ('ABANDONED-1H', 'ABANDONED-2H') THEN 1 ELSE 0 END
		, @start 		= CURRENT_TIMESTAMP
	
	-- match info
	DECLARE 
		@matchdate			SMALLDATETIME
		,@fthomescore		SMALLINT
		,@ftawayscore		SMALLINT
		,@hthomescore		SMALLINT
		,@htawayscore		SMALLINT
		,@SportType			SMALLINT
		,@betstatus			NVARCHAR(50)
		,@GoalRecord		VARCHAR(50)		
		,@IsRefundHT		BIT
		
	SELECT	TOP(1)
		@matchdate 		= eventdate
		,@SportType 	= SportType
		,@fthomescore 	= ISNULL(finalhomescore, 0)
		,@ftawayscore 	= ISNULL(finalawayscore, 0)
		,@hthomescore 	= ISNULL(hthomescore, 0)
		,@htawayscore 	= ISNULL(htawayscore, 0)
		,@betstatus 	= ISNULL(betstatus,'')
		,@GoalRecord 	= ISNULL(GoalRecord, '')
		,@IsRefundHT 	= CASE WHEN @betstatus LIKE 'Refund HT%' THEN 1 ELSE 0 END
	FROM dbo.Match WITH(ROWLOCK)
	WHERE matchid = @matchid
	
	IF @@ROWCOUNT = 0 
	BEGIN
		SELECT	@ErrCode = 1000001
				,@ErrMsg = 'Match does not exist!'
				
		RETURN -- incorrect matchid? maybe
	END
	
	IF @Sporttype = 1
	BEGIN
		EXEC dbo.NAP_Admin_Settlement_2 
			@mode 				= 'cornersBets'
			,@matchid 			= @matchID
			,@str_resultDetail 	= @resultDetail_cb OUTPUT
	END
	
	IF @Sporttype = 5
	BEGIN
		EXEC dbo.NAP_Admin_Settlement_2 @mode = 'sporttingSolution'
			,@matchid = @matchID
			,@Total = @TennisTotal OUTPUT
			,@TotalHome = @TotalGameHomeMatch OUTPUT
			,@TotalAway = @TotalGameAwayMatch OUTPUT
			,@str_resultDetail = @resultDetail_ss OUTPUT	
	END
	
	--CHECK Auto-Bettype first if any
	IF (EXISTS (
			SELECT TOP 1 1
			FROM dbo.bettransm bm (NOLOCK)
			WHERE bm.matchid = @matchId
				AND EXISTS (
					SELECT TOP 1 1 
					FROM dbo.f_Set_GetGroupBettypes() AS f 
					WHERE f.GroupId 	= 8 
						AND f.bettype 	= bm.bettype
				)
			)
	)
	BEGIN		
		EXEC dbo.NAP_Admin_Settlement_Parlay_Betradar
			@MatchId			= @MatchId
			,@matchdate			= @matchdate
			,@Mode				= @Action
	END	
	
	--CHECK for CAL fisrt
	IF(@action IN ('REFUND-HT', 'ABANDONED-2H', 'REFUND-FT'))
	BEGIN
		/*IF(@action IN ('REFUND-HT')) --REFUND Is3x30 AND CAL the REST
		BEGIN
			TODO
		END
		IF(@action IN ('ABANDONED-2H', 'REFUND-FT')) --CAL-HT and REFUND/ABANDONED the REST
		BEGIN
			TODO
		END*/
		
		--DO calculation
		EXEC dbo.NAP_Admin_Settlement_Parlay_Calculate
			@MatchId			= @MatchId
			,@matchdate			= @matchdate
			,@mode				= @Action
			,@hth		 		= @hthomescore
			,@hta		 		= @htawayscore
			,@fth				= @fthomescore
			,@fta				= @ftawayscore
			,@Sporttype			= @Sporttype
			,@betstatus 		= @betstatus
			,@GoalSequence 		= @GoalRecord
			,@resultDetail_cb	= @resultDetail_cb
			,@resultDetail_ss	= @resultDetail_ss
			
	END
	
	--CALL settle determinable first
	IF(@IsDetermined = 1)
	BEGIN
		--DO settle determined
		EXEC dbo.NAP_Admin_Settlement_Parlay_SDT
			@MatchId			= @MatchId
			,@matchdate			= @matchdate
			,@mode				= @Action
			,@hthomescore 		= @hthomescore
			,@htawayscore 		= @htawayscore
			,@fthomescore		= @fthomescore
			,@ftawayscore		= @ftawayscore
			,@Sporttype			= @Sporttype
			,@betstatus 		= @betstatus
			,@GoalRecord 		= @GoalRecord
	END
	ELSE
	BEGIN
		--REFUND all tickets
		EXEC dbo.NAP_Admin_Settlement_Parlay_Refund
			@MatchId			= @MatchId
			,@matchdate			= @matchdate
			,@mode				= @Action
			,@IsRefundHT		= @IsRefundHT
	END
	return
	
	--CAL main tickets by refno
	DECLARE @rowCnt29 int
			,@rowCnt int
	DECLARE @strTransIds varchar(MAX) = ''
			,@strRefnos VARCHAR(MAX) = ''
	
	DECLARE @refnos TABLE (refno BIGINT)		
	CREATE TABLE #tempRefno29 (refno BIGINT, transid BIGINT)	
	
	-- for balance table --	
	DECLARE @BeforeUpd 					TVP_BalanceChange
		, @AfterUpd 					TVP_BalanceChange
		
	CREATE TABLE #Balance_29 (custid int PRIMARY KEY, balance money, Increased bit)
	CREATE INDEX IX_Balance_29_Increased ON #Balance_29 (Increased)
	
	DECLARE @tblDebitPending_29 TVP_BalanceList
	DECLARE @tblCreditPending_29 TVP_BalanceList

	DECLARE @TotalAccount INT, @TotalAccount_BalanceUpdate INT
	
	----------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO @refnos(refno)
	SELECT refno
	FROM dbo.bettransm bm WITH(ROWLOCK)
	WHERE matchid = @matchid
		AND NOT EXISTS (
			SELECT 1 FROM bettransm WITH(NOLOCK) WHERE refno = bm.refno AND statusID IN(1, 101)
		)
	SET @rowCnt = @@ROWCOUNT --number of tickets of the match
	
	BEGIN --BEGIN: calculate 29 ----------------------------------
	
		SELECT transid, refno, 0 AS IsFinished
		INTO #temp_bettrans_29
		FROM bettrans b WITH(NOLOCK)		
		WHERE b.matchid = 29
			AND b.statusID NOT IN (101,102) --('VOID','REJECT')
			AND refno IN (SELECT refno FROM @refnos)
			
		SET @rowCnt29 = @@ROWCOUNT -- number of system parlay ticket

		INSERT INTO dbo.ParlaySettlement_trace (matchid, runcnt, starttime, endtime, doing)
		VALUES (@matchid, @rowCnt29, CURRENT_TIMESTAMP, NULL, 'Start running PRECAL-29')

		IF @rowCnt29 > 0 -- got system parlay tickets
		BEGIN	
			SET @strTransIds = STUFF((
				SELECT ',' + cast(transid as varchar(20)) 
				FROM #temp_bettrans_29 
				FOR XML PATH('')
			), 1,1,'')
		
			-- handle betParlayDetail, betParlayResult
			EXEC dbo.NAP_Admin_Calculate_MP_broker @matchid = @matchid
				,@mode = 'PRECAL-29'
				,@matchdate = @matchdate
				,@strXML = @strTransIds
			
			-- CAPTURE value BALANCE before udpate bettrans
			INSERT INTO @BeforeUpd (
				custid
				,balance
				,balanceType
			)
			SELECT b.custid
				,SUM(b.winlost - b.actual_stake + b.playercomm) AS balance
				,1 -- Sports
			FROM dbo.bettrans b WITH(ROWLOCK)
			WHERE EXISTS( SELECT 1 FROM #temp_bettrans_29 WHERE transid = b.transid)
			GROUP BY b.custid
			--------------------------------------------------------------	
		
			INSERT INTO dbo.ParlaySettlement_trace (matchid, runcnt, starttime, endtime, doing)
			VALUES (@matchid, NULL, CURRENT_TIMESTAMP, NULL, 'Start running CAL-29')

			-- update summary info back to bettrans
			WHILE (1=1)
			BEGIN
				TRUNCATE TABLE #tempRefno29
				SET @strRefnos = ''
				
				UPDATE TOP (800) #temp_bettrans_29
					SET IsFinished = 1
				OUTPUT INSERTED.refno, INSERTED.transid INTO #tempRefno29 (refno, transid)
				WHERE IsFinished = 0
				
				IF @@rowcount = 0
					BREAK
					
				SELECT @strRefnos = @strRefnos + ',' + CONVERT(VARCHAR(20), refno) + '|' + CONVERT(VARCHAR(20), transid)
				FROM	#tempRefno29
				
				SET @strRefnos = STUFF(@strRefnos,1,1,'')
				
				EXEC dbo.NAP_Admin_Calculate_MP_broker
					@mode = '29'
					,@matchdate = @matchdate
					,@strXML = @strRefnos
			END			
												
			-- CAPTURE value BALANCE after update bettrans
			INSERT INTO @AfterUpd (
				custid
				,balance
				,balanceType
			)
			SELECT b.custid
				,SUM(b.winlost - b.actual_stake + b.playercomm) AS balance
				,1 -- Sports
			FROM dbo.bettrans b WITH(ROWLOCK)
			WHERE EXISTS( SELECT 1 FROM #temp_bettrans_29 WHERE transid = b.transid)
			GROUP BY b.custid
			
			INSERT INTO #Balance_29 (custid, balance, Increased)
			SELECT b.custid, a.balance - b.balance, CASE WHEN a.balance > b.balance THEN 1 ELSE 0 END
			FROM #beforeUpd b
				INNER JOIN #afterUpd a ON b.custid = a.custid
			WHERE b.balance <> a.balance

			SET @TotalAccount_BalanceUpdate = @@ROWCOUNT
			
			---INSERT data into pending balance table   
			EXEC [dbo].[NAP_Admin_BalancePendingIns]
				@BeforeUpd	 = @beforeUpd
				, @AfterUpd	 = @afterUpd
		
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
				,@matchid
			FROM #Balance_29 WITH (NOLOCK)
			WHERE Increased = 0
		END
	END
	
	----------------------------------------------------------------------------------------------------------------------------------------
	BEGIN --BEGIN: UPDATE match_remark ----------------------------------	
		DECLARE @command varchar(5)
		--SET @command = CASE WHEN @action = 'CAL' THEN 'M' ELSE 'R' END
		SET @command = 'R'

		EXEC DBPRO.BODB02.dbo.NAP_UpdateMatch_Remark @matchid = @matchid
				,@command = @command
				,@SelectedSetCAL = @SelectedSetCAL
				,@SelectedSetREFUND = @SelectedSetREFUND

		EXEC DBPRO.BODB02.dbo.NAP_Admin_Match_Update @Command = 'NAP_Admin_Settlement_Refund_MP'
			,@Matchid = @matchid
			,@creator = @creator		
	END --END: UPDATE match_remark ----------------------------------	

	INSERT INTO dbo.ParlaySettlement_trace (matchid, runcnt, starttime, endtime, doing)
	VALUES (@matchid, NULL, NULL, CURRENT_TIMESTAMP, 'well done, no more to do')

	----------------------------------------------------------------------------------------------------------------------------------------
	BEGIN --BEGIN: WRITE LOG ----------------------------------		
		DECLARE @Remark VARCHAR(200)
		
		SET @stop = CURRENT_TIMESTAMP

		SELECT @Remark = 'NAP: Calculate Multiple (' + @action + ') for matchid:' + CAST(@matchid AS NVARCHAR(10)) + ' (' + CAST(DATEDIFF(millisecond, @start, @stop) AS NVARCHAR(50)) + ' ms)'
		EXEC dbo.WriteLog_UserLog @creator, @Remark

		SELECT @Remark = 'NAP: Duration:' + CAST(DATEDIFF(millisecond, @start, @stop) AS NVARCHAR(50)) + ' ms'

		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @creator
				,@Matchid = @matchid
				,@ActionID = @ActionID
				,@finalhomescore = @fthomescore
				,@finalawayscore = @ftawayscore
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
				,@finalhomescore = @fthomescore
				,@finalawayscore = @ftawayscore
				,@hthomescore = @hthomescore
				,@htawayscore = @htawayscore
				,@GoalRecord = @goalrecord
				,@betstatus = @betstatus
				,@Remark = @Remark
				,@IP = @IP
		END CATCH
	END --END: WRITE LOG ----------------------------------
	
	RETURN
END	
GO 
