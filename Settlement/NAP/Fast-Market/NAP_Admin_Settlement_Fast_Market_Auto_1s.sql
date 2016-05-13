USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_Fast_Market_Auto_1s]    Script Date: 05/13/2016 12:52:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Fast_Market_Auto_1s] @MatchId INT
	, @Action VARCHAR(20)
	, @Results VARCHAR(MAX)

	, @IsAuto BIT = 0
	, @AdminId INT = 0
	, @Ip VARCHAR(20) = ''

	, @ErrCode INT = 0 OUTPUT
	, @ErrMsg VARCHAR(200) = '' OUTPUT
AS
/*
	Created: 20160427@Patrick
	Task: Fast market - Auto/Manual settlement
	DB: DBPRO.BODB02
	Original:
	
	Revisions:

	Param's Explanation:
		- @ResultList = <r>
							<b Id="221">
								<r p="0" r="36" />
								<r p="1" r="1" />
								<r p="2" r="4" />
							</b>
						</r>
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE @Start DATETIME, @Stop DATETIME, @fth INT, @fta INT, @hth INT, @hta INT
		, @ActionID INT, @Remark VARCHAR(3000), @LogData NVARCHAR(300)						
		, @LogResult VARCHAR(MAX) = ''	

	SELECT	@start = CURRENT_TIMESTAMP
	SELECT	@ActionID = CASE WHEN @Action = 'CAL' THEN 165 
							 WHEN @Action = 'UNDO' THEN 166 
							 WHEN @Action = 'REFUND' THEN 167
							 ELSE 0 END  
	--Write Log Settle
	SELECT	 @fth			= finalhomescore
			,@fta			= finalawayscore
			,@hth			= hthomescore
			,@hta			= htawayscore
	FROM	DBPRO.BODB02.dbo.match WITH (NOLOCK)
	WHERE	matchid = @matchid
	SELECT @Results
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
	CREATE TABLE #BalanceAfter (custid INT PRIMARY KEY, balance MONEY)
	CREATE TABLE #Balance (custid INT PRIMARY KEY, balance MONEY, Increased BIT)

	DECLARE @tblDebitPending TVP_BalanceList
	DECLARE @tblCreditPending TVP_BalanceList

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
		SELECT T.C.value('../@Id', 'SMALLINT') AS Bettype
			, T.C.value('./@p', 'TINYINT') AS Position
			, T.C.value('./@r', 'TINYINT') AS BetOption
			, CASE WHEN @Action = 'CAL' AND @IsAuto = 0 THEN 5
					WHEN @Action = 'CAL' AND @IsAuto = 1 THEN 4
					WHEN @Action = 'REFUND' THEN 6
					WHEN @Action = 'UNDO' THEN 2
					ELSE 0 END AS ResultStatus
		FROM @XmlData.nodes('/r/b/r') AS T(C)
	)

	INSERT INTO @ResultDetail (BetType, Position, BetOption, ResultStatus)
	SELECT BetType, Position, BetOption, ResultStatus
	FROM TmpData
	ORDER BY Bettype, Position
	
	DECLARE @BetType SMALLINT, @Position TINYINT, @BetOption TINYINT, @ResultStatus TINYINT, @RowIndex INT
		, @betcount_221 INT, @betcount_222 INT, @betcount_223 INT, @betcount_224 INT, @IsRuntimeError BIT

	SELECT @RowIndex = 1, @IsRuntimeError = 0
	BEGIN TRY
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
					, @action = 'CAL-FM'
					, @mode = 'CAL'
					, @hdp1 = @Position
					, @betoption = @BetOption
					, @betcount_221 = @betcount_221
					, @betcount_222 = @betcount_222
					, @betcount_223 = @betcount_223
					, @betcount_224 = @betcount_224

			END
			ELSE IF @Action = 'REFUND'
			BEGIN
				EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
					, @action = 'REFUND'
					, @mode = 'FastMarket'
					, @hdp1 = @Position
					, @betoption = @BetOption
					, @betcount_221 = @betcount_221
					, @betcount_222 = @betcount_222
					, @betcount_223 = @betcount_223
					, @betcount_224 = @betcount_224
			END
			ELSE IF @Action = 'UNDO'
			BEGIN
				EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
					, @action = 'CAL-FM'
					, @mode = 'UNDO'
					, @hdp1 = @Position
					, @betoption = @BetOption
					, @betcount_221 = @betcount_221
					, @betcount_222 = @betcount_222
					, @betcount_223 = @betcount_223
					, @betcount_224 = @betcount_224
			END
		END
	END TRY
	BEGIN CATCH
		-- Capture Balance incase of failure
		-------------------------------------------------------------
		---         CAPTURE value BALANCE after settlement        ---
		---------------------------VVVV------------------------------
		INSERT INTO #BalanceAfter
		SELECT b.custid, SUM(b.winlost - b.actual_stake + b.playercomm)
		FROM dbo.bettrans b WITH (ROWLOCK)
		WHERE b.matchid = @MatchId 
			AND b.bettype IN (221,222,223,224)
		GROUP BY b.custid

		-------------------------------------------------------------
		---                   compare BALANCE                     ---
		---------------------------VVVV------------------------------
		CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

		INSERT INTO #Balance
		SELECT b.custid, a.balance - b.balance, CASE WHEN a.balance > b.balance THEN 1 ELSE 0 END
		FROM #BalanceBefore b
			INNER JOIN #BalanceAfter a ON b.custid = a.custid
		WHERE b.balance <> a.balance
	
		INSERT INTO @tblDebitPending (custID, balance)
		SELECT custid, ABS(balance)
		FROM #Balance
		WHERE Increased = 0
	
		IF @@ROWCOUNT <> 0
		BEGIN
			EXEC dbo.Dot_BalancePendingDebitIns @BalancePending = @tblDebitPending, @Type = 1 -- Sports
		END

		INSERT INTO @tblCreditPending (custID, balance)
		SELECT custid, balance
		FROM #Balance
		WHERE Increased = 1
	
		IF @@ROWCOUNT <> 0
		BEGIN
			EXEC dbo.Dot_BalancePendingCreditIns @BalancePending = @tblCreditPending, @Type = 1 -- Sports
		END
		----
		-- Add Negative Balance into BalanceNegative table 
		----
		INSERT INTO [bodb02].[dbo].[BalanceNegative] ([ExecDate], [MatchID], [ActionID], [GroupID], [CustID], [Balance], [StatusID], [Remark])
		SELECT GETDATE(), @MatchID, @ActionID, 1, CustID, Balance, 0, NULL
		FROM #Balance WITH(NOLOCK)
		WHERE Increased = 0

		---------------------------------------------------
		DROP TABLE #Balance
		DROP TABLE #BalanceBefore
		DROP TABLE #BalanceAfter
		
		SELECT @ErrCode = 1001017, @ErrMsg = ERROR_MESSAGE()
		RETURN

	END CATCH

	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	INSERT INTO #BalanceAfter
	SELECT b.custid, SUM(b.winlost - b.actual_stake + b.playercomm)
	FROM dbo.bettrans b WITH (ROWLOCK)
	WHERE b.matchid = @MatchId 
		AND b.bettype IN (221,222,223,224)
	GROUP BY b.custid

	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	
	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

	INSERT INTO #Balance
	SELECT b.custid, a.balance - b.balance, CASE WHEN a.balance > b.balance THEN 1 ELSE 0 END
	FROM #BalanceBefore b
		INNER JOIN #BalanceAfter a ON b.custid = a.custid
	WHERE b.balance <> a.balance
	
	INSERT INTO @tblDebitPending (custID, balance)
	SELECT custid, ABS(balance)
	FROM #Balance
	WHERE Increased = 0
	
	IF @@ROWCOUNT <> 0
	BEGIN
		EXEC dbo.Dot_BalancePendingDebitIns @BalancePending = @tblDebitPending, @Type = 1 -- Sports
	END

	INSERT INTO @tblCreditPending (custID, balance)
	SELECT custid, balance
	FROM #Balance
	WHERE Increased = 1
	
	IF @@ROWCOUNT <> 0
	BEGIN
		EXEC dbo.Dot_BalancePendingCreditIns @BalancePending = @tblCreditPending, @Type = 1 -- Sports
	END
	----
	-- Add Negative Balance into BalanceNegative table 
	----
	INSERT INTO [bodb02].[dbo].[BalanceNegative] ([ExecDate], [MatchID], [ActionID], [GroupID], [CustID], [Balance], [StatusID], [Remark])
	SELECT GETDATE(), @MatchID, @ActionID, 1, CustID, Balance, 0, NULL
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

	SELECT @logdata = 'NAP: Auto-Settlement (' + @action + ') for matchid:' + CAST(@matchid AS NVARCHAR(10)) 
		+ '(' + CAST(DATEDIFF(MILLISECOND, @start, @stop) AS NVARCHAR(50)) + ' ms)'

	EXEC dbo.WriteLog_UserLog @UserID = @AdminId, @Doing = @logdata
	
	SET @LogResult = CONVERT(VARCHAR(MAX),(SELECT BetType '@Id'
		,STUFF((select ',' + cast(Position as VARCHAR(3)) from @ResultDetail where BetType = r.BetType for XML PATH ('')),1,1,'') as 'Item/@Position'
		,STUFF((select ',' + cast(BetOption as VARCHAR(3)) from @ResultDetail where BetType = r.BetType for XML PATH ('')),1,1,'') as 'Item/@Result'
	FROM @ResultDetail r
	GROUP BY BetType
	FOR XML PATH('Bettype'), root ('Bettypes'), TYPE))

	
	SELECT @Remark = 'NAP: IsAuto:' + CAST(@IsAuto AS VARCHAR(1))
			+ ' Duration:' + CAST(DATEDIFF(MILLISECOND, @start, @stop) AS NVARCHAR(50)) + 'ms' 
			+ '|' -- signal for web
			+ @LogResult
			
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @userid = @AdminId
			, @matchid			= @MatchID
			, @actionid			= @ActionID
			, @finalhomescore	= @fth
			, @finalawayscore	= @fta
			, @hthomescore		= @hth
			, @htawayscore		= @hta
			, @GoalRecord		= ''
			, @betstatus		= ''
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
			, @GoalRecord		= ''
			, @betstatus		= ''
			, @Remark			= @Remark
			, @IP				= @ip
	END CATCH

	DELETE
	FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid
	
END





GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_Fast_Market_Auto_1s] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_Fast_Market_Auto_1s] TO [vnteam] AS [dbo]