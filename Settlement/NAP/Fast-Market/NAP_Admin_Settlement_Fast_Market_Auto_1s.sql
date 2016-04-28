USE bodb02
GO

ALTER PROCEDURE dbo.NAP_Admin_Settlement_Fast_Market_Auto_1s @MatchId INT
	, @Action VARCHAR(20)
	, @Results VARCHAR(MAX)

	, @IsAuto BIT = 0
	, @AdminId INT = 0
	, @Ip VARCHAR(20) = ''

	, @ErrCode INT OUTPUT
	, @ErrMsg VARCHAR(200) OUTPUT
AS
/*
	Created: 20160427@Patrick
	Task: Fast market - Auto/Manual settlement
	DB: DBPRO.BODB02
	Original:
	
	Revisions:

	Param's Explanation:
		- @ResultList = '<bettypes>
							<bettype id="">
								<item position="" result="" />
								<item position="" result="" />
							</bettype>
	
						</bettypes>'
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE @start DATETIME, @stop DATETIME, @fth INT, @fta INT, @hth INT, @hta INT
		, @ActionID INT, @Remark VARCHAR(500), @LogData NVARCHAR(300)							

	SELECT	@start = CURRENT_TIMESTAMP
	SELECT	@ActionID = CASE WHEN @Action = 'CAL'	THEN 148 
							 WHEN @Action = 'UNDO'	THEN 149 
							 WHEN @Action = 'REFUND'THEN 150
							 ELSE 0 END  
	--Write Log Settle
	SELECT	 @fth			= finalhomescore
			,@fta			= finalawayscore
			,@hth			= hthomescore
			,@hta			= htawayscore
	FROM	DBPRO.BODB02.dbo.match WITH (NOLOCK)
	WHERE	matchid = @matchid
		
	-- check and not allow attempt to settlement same game while it's still not finish
	IF EXISTS (SELECT 1 
				FROM dbo.TempVariableNumber t WITH(NOLOCK)
				WHERE t.KeyID = 1 AND t.KeyValue = @matchid)
	BEGIN
		SELECT @ErrCode = 1000000
			, @ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END

	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue)
	VALUES (1, @matchid)

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = 1000000
			, @ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END

	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceBefore (custid INT PRIMARY KEY, balance MONEY)

	INSERT INTO #BalanceBefore
	SELECT b.custid, SUM(b.winlost - b.actual_stake + b.playercomm)
	FROM dbo.bettrans b WITH (ROWLOCK)
	WHERE b.matchid = @MatchId 
		AND b.bettype IN (221,222,223,224)
	GROUP BY b.custid
	
	DECLARE @XmlData XML
	SET @XmlData =  CONVERT(XML, @Results)

	DECLARE @ResultDetail TABLE(BetType SMALLINT, Position TINYINT, BetOption TINYINT, ResultStatus TINYINT, RowIndex INT IDENTITY(1,1))

	;WITH TmpData AS (
		SELECT T.C.value('../@id', 'SMALLINT') AS Bettype
			, T.C.value('./@position', 'TINYINT') AS Position
			, T.C.value('./@result', 'TINYINT') AS BetOption
			, CASE WHEN @Action = 'CAL' AND @IsAuto = 0 THEN 5
					WHEN @Action = 'CAL' AND @IsAuto = 1 THEN 4
					WHEN @Action = 'REFUND' THEN 6
					WHEN @Action = 'UNDO' THEN 2
					ELSE 0 END AS ResultStatus
		FROM @XmlData.nodes('/bettypes/bettype/item') AS T(C)
	)

	INSERT INTO @ResultDetail (BetType, Position, BetOption, ResultStatus)
	SELECT BetType, Position, BetOption, ResultStatus
	FROM TmpData
	ORDER BY Bettype, Position
	
	DECLARE @BetType SMALLINT, @Position TINYINT, @BetOption TINYINT, @ResultStatus TINYINT, @RowIndex INT
		, @betcount_221 INT, @betcount_222 INT, @betcount_223 INT, @betcount_224 INT

	SET @RowIndex = 1
	WHILE EXISTS (SELECT TOP 1 1 FROM @ResultDetail WHERE RowIndex = @RowIndex)
	BEGIN
		SELECT @BetType = BetType, @Position = Position, @BetOption = BetOption, @ResultStatus = ResultStatus
		FROM @ResultDetail
		WHERE RowIndex = @RowIndex

		SET @RowIndex = @RowIndex + 1

		IF @BetType IS NULL OR @Position IS NULL
			CONTINUE

		--update result detail
		EXEC DBPRO.bodb02.dbo.NAP_Set_FastMarket_ResultDetailUpd @MatchId = @MatchId
			, @BetType = @BetType
			, @Position = @Position
			, @BetOption = @BetOption
			, @ResultStatus = @ResultStatus
			, @Action = @Action

			, @ErrCode = @ErrCode OUTPUT
			, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode > 0
		BEGIN
			--TODO
			BREAK
		END

		--get betcount
		SELECT @betcount_221 = ISNULL(SUM(CASE bettype WHEN 221 THEN 1 ELSE 0 END), 0)
			, @betcount_222 = ISNULL(SUM(CASE bettype WHEN 222 THEN 1 ELSE 0 END), 0)
			, @betcount_223 = ISNULL(SUM(CASE bettype WHEN 223 THEN 1 ELSE 0 END), 0)
			, @betcount_224 = ISNULL(SUM(CASE bettype WHEN 224 THEN 1 ELSE 0 END), 0)
		FROM dbo.bettrans WITH(NOLOCK)
		WHERE matchid = @MatchId
			AND bettype = @BetType
			AND hdp1 = @Position

		IF @Action = 'CAL'
		BEGIN
			EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
				, @ResourceIDs	= @ResourceIDs
				, @action		= 'CAL'
				, @mode			= 'UNDO'
		END
		ELSE IF @Action = 'REFUND'
		BEGIN
			
		END
		ELSE IF Action = 'UNDO'
		BEGIN
		END
	END

	IF @Action='CAL'
	BEGIN
		EXEC DBPRO.BODB02.dbo.NAP_Admin_Result_Update_1s 
			@Command			= 'NAP_Admin_Settlement_Auto_1s-CAL',
			@MatchID			= @MatchID,
			@ResourceIDs		= @ResourceIDs, 
			@Results			= @Results,
			@IsAuto				= @IsAuto,
			@creator			= @AdminID 			

								EXEC dbo.NAP_Admin_Settlement_3_Auto_1s 
			 @matchid		= @matchid
			,@ResourceIDs	= @ResourceIDs
			,@mode			= @action						

	END
	ELSE IF @action = 'UNDO'
	BEGIN
								EXEC dbo.NAP_Admin_Calculate_Main 
			 @matchid		= @matchid
			,@ResourceIDs	= @ResourceIDs
			,@action		= 'CAL'		-- Default Action for UNDO Settlement 
			,@mode			= 'UNDO' 

		EXEC dbo.NAP_Admin_Settlement_Parlay
			@matchids		= @matchid
			,@creator		= @AdminID
			,@ResourceIDs	= @ResourceIDs
			,@action		= 'UNDO'
			,@IP			= @IP

								EXEC DBPRO.BODB02.dbo.NAP_Admin_Result_Update_1s 
			@Command			= 'NAP_Admin_Settlement_Auto_1s-UNDO',
			@MatchID			= @MatchID,
			@ResourceIDs		= @ResourceIDs, 
			@Results			= @Results,
			@IsAuto				= @IsAuto,
			@creator			= @AdminID 

	END
	ELSE IF @Action = 'REFUND'
	BEGIN
		
		IF @IsSettleAbandonedMatchIBC = 1 
		BEGIN
			DECLARE	 @betCount_216			INT	= 0
					,@GoalScorerAnytime		VARCHAR(MAX)=''

			DECLARE	@tmpResourceIDs	TABLE(
				 ID			INT IDENTITY(1,1)
				,ResourceID	VARCHAR(20)
				,Bettype	INT
			)
			INSERT INTO @tmpResourceIDs(ResourceID, Bettype)
			SELECT	Val, CAST(LEFT(val,3) AS INT) FROM dbo.StrSplit(@ResourceIDs,',')

			DECLARE	@tmpResults TABLE(
				 ID			INT IDENTITY(1,1)
				,HomeValue	VARCHAR(50)
			)
			INSERT INTO @tmpResults(HomeValue)
			SELECT	Val FROM dbo.StrSplit(@Results,',') WHERE @Results IS NOT NULL 

			UPDATE @tmpResults
			SET		HomeValue = NULL
			WHERE	HomeValue ='NL'

			SELECT	 @betCount_216	= ISNULL(SUM(CASE WHEN bettype = 216 THEN 1 ELSE 0 END),0)
			FROM	dbo.Bettrans WITH (NOLOCK)
			WHERE	MatchID = @MatchID 
					AND Bettype = 216
					AND	Bettype IN  (SELECT Bettype FROM @tmpResourceIDs)
					AND StatusID NOT BETWEEN 101 AND 102 
	
			SELECT	@GoalScorerAnytime		= @GoalScorerAnytime + CASE WHEN t.ResourceID LIKE '216__' THEN ISNULL(r.HomeValue,'') +',' ELSE '' END 
			FROM	@tmpResourceIDs t
					INNER JOIN @tmpResults r ON t.ID = r.ID 
			WHERE	t.ResourceID LIKE '216__'	

			IF ISNULL(@GoalScorerAnytime,'') =''
			BEGIN
				SELECT	 @ErrCode	= 1001014
						,@ErrMsg	= 'Cannot settle determined ticket(s) without suspended result!'		
				RETURN 	
			END

												EXEC dbo.NAP_Admin_Calculate_Main 
				 @matchid					= @matchid
				,@ResourceIDs				= @ResourceIDs
				,@action					= 'REFUND'	
				,@mode						= 'ALL' 
				,@GoalScorerAnytime			= @GoalScorerAnytime
				,@IsSettleAbandonedMatchIBC	= @IsSettleAbandonedMatchIBC
				,@betCount_216				= @betCount_216
		END

								EXEC DBPRO.BODB02.dbo.NAP_Admin_Result_Update_1s 
					@Command			= 'NAP_Admin_Settlement_Auto_1s-REFUND',
					@MatchID			= @MatchID,
					@ResourceIDs		= @ResourceIDs, 
					@Results			= @Results,
					@IsAuto				= @IsAuto,
					@creator			= @AdminID 	

								EXEC dbo.NAP_Admin_Calculate_Main 
			 @matchid					= @matchid
			,@ResourceIDs				= @ResourceIDs
			,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
			,@action					= 'REFUND'	
			,@mode						= 'ALL' 
			,@row_count					= 1 
	END


	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (custid INT PRIMARY KEY, balance MONEY)
	INSERT INTO #BalanceAfter
	SELECT b.custid
		,SUM(b.winlost - b.actual_stake + b.playercomm)
	FROM dbo.bettrans b WITH (ROWLOCK)
	WHERE	b.matchid = @matchid 
			AND b.bettype IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217,901,902,903)
			AND 1 = CASE WHEN b.bettype IN (901,902,903) 
									AND b.refno IN (SELECT transid FROM #tmpTrans)	
								THEN 1 
						WHEN b.bettype NOT IN (901,902,903) THEN 1
						ELSE 0 END
	GROUP BY b.custid



	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	CREATE TABLE #Balance (custid INT PRIMARY KEY, balance MONEY, Increased BIT)
	DECLARE @tblDebitPending TVP_BalanceList
	DECLARE @tblCreditPending TVP_BalanceList
	
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

	--INSERT INTO dbo.BalancePendingDebit (custid, balance)
	--SELECT custid, ABS(balance)
	--FROM #Balance
	--WHERE Increased = 0
	INSERT INTO @tblDebitPending (custID, balance)
	SELECT	custid, ABS(balance)
	FROM	#Balance
	WHERE	Increased = 0
	
	IF @@rowcount <> 0
		EXEC dbo.Dot_BalancePendingDebitIns 
			@BalancePending = @tblDebitPending
			,@Type			= 1 -- Sports

	
	--INSERT INTO dbo.BalancePendingCredit (custid, balance)
	--SELECT custid, balance
	--FROM #Balance
	--WHERE Increased = 1
	INSERT INTO @tblCreditPending (custID, balance)
	SELECT	custid, balance
	FROM	#Balance
	WHERE	Increased = 1
	
	IF @@rowcount <> 0
		EXEC dbo.Dot_BalancePendingCreditIns 
			@BalancePending = @tblCreditPending
			,@Type			= 1 -- Sports

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
		,1 -- Sportsbook Single bet Settlement 
		,CustID
		,Balance
		,0
		,NULL
	FROM #Balance WITH(NOLOCK)
	WHERE Increased = 0

	---------------------------------------------------
	DROP TABLE #Balance

	DROP TABLE #BalanceBefore

	DROP TABLE #BalanceAfter
	
	DROP TABLE #tmpTrans
	-------------------------------------------------------------
	---                      WRITE LOG                        ---
	---------------------------VVVV------------------------------

	SELECT @stop = CURRENT_TIMESTAMP

	SELECT @logdata = 'NAP: Auto-Settlement (' + @action + ') for matchid:' + CAST(@matchid AS NVARCHAR(10)) 
														   + ' ResourceID:' + CAST(@ResourceIDs AS VARCHAR(MAX))
														   + ' SettleDeterminedTickets:' + CAST(@IsSettleAbandonedMatchIBC AS VARCHAR(1))
														   + ' Result:' + @Results + '(' + CAST(DATEDIFF(millisecond, @start, @stop) AS NVARCHAR(50)) + ' ms)'
	EXEC dbo.WriteLog_UserLog 
		@UserID = @AdminId
		,@Doing = @logdata

	SELECT @Remark = 'NAP: ResourceID:' + @ResourceIDs +  ' <br/> ' 
						+ CASE WHEN ISNULL(@Results,'') ='' THEN '' ELSE ' Result:'+ ISNULL(@Results,'') + ' <br/> ' END
						+ ' SettleDeterminedTickets:' + CAST(@IsSettleAbandonedMatchIBC AS VARCHAR(1))
						+ ' IsAuto:' + CAST(@IsAuto AS VARCHAR(1))
						+ ' Duration:' + CAST(DATEDIFF(millisecond, @start, @stop) AS NVARCHAR(50)) + 'ms' 
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle 
			@userid				= @AdminId
			,@matchid			= @MatchID
			,@actionid			= @ActionID
			,@finalhomescore	= @fth
			,@finalawayscore	= @fta
			,@hthomescore		= @hth
			,@htawayscore		= @hta
			,@GoalRecord		= @goalrecord
			,@betstatus			= @betstatus
			,@Remark			= @Remark
			,@ip				= @ip
	END TRY

	BEGIN CATCH
		SELECT @remark = @remark + ' ErrMsg=' + LEFT(ERROR_MESSAGE(), 250)

		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle 
			@UserID				= @AdminId
			,@MatchID			= @matchid
			,@actionid			= @actionid
			,@finalhomescore	= @fth
			,@finalawayscore	= @fta
			,@hthomescore		= @hth
			,@htawayscore		= @hta
			,@GoalRecord		= @goalrecord
			,@betstatus			= @betstatus
			,@Remark			= @Remark
			,@IP				= @ip
	END CATCH

	--
	DELETE
	FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
	WHERE KeyID = 1 
	AND KeyValue = @matchid

	IF @@ERROR = 0
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@userid		= @AdminId
				,@matchid	= @matchid
				,@keyid		= 1
				,@actionid	= @actionid
				,@remark	= 'DEL SUCCESS'
		END TRY

		BEGIN CATCH
			SELECT @remark = 'DEL SUCCESS ErrMsg=' + LEFT(ERROR_MESSAGE(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @AdminId
				,@MatchID	= @matchid
				,@KeyID		= 1
				,@ActionID	= @actionid
				,@Remark	= @remark
		END CATCH
	END
	ELSE
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@userid		= @AdminId
				,@matchid	= @matchid
				,@keyid		= 1
				,@actionid	= @actionid
				,@remark	= 'DEL FAILED'
		END TRY

		BEGIN CATCH
			SELECT @remark = 'DEL FAILED ErrMsg=' + LEFT(ERROR_MESSAGE(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @AdminId
				,@MatchID	= @matchid
				,@KeyID		= 1
				,@ActionID	= @actionid
				,@Remark	= @remark
		END CATCH
	END
END

GO

GRANT EXECUTE ON [NAP_Set_FastMarket_ResultDetailUpd] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_FastMarket_ResultDetailUpd] TO [vnteam] AS [dbo]
GO