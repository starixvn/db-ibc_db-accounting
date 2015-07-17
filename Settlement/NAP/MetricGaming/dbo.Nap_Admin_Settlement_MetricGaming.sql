USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_MetricGaming]    Script Date: 07/17/2015 09:08:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_MetricGaming] 
	@MatchId					INT
	,@Bettype					INT
	,@ResultID					INT	
	,@BettypeTime				VARCHAR(100)	= ''
	,@Result					VARCHAR(4000)
	,@Action					VARCHAR(10)		= 'CAL'
	,@AdminId					INT	
	,@IsSettleDetermined		BIT				= 0
	,@SuspendedTime				TINYINT			= 0
	,@IP						VARCHAR(50)		= ''
	,@ErrCode					INT				= 0		OUTPUT
	,@ErrMsg					NVARCHAR(200)	= ''	OUTPUT
AS
	/*
		Created: Johnson
		Date: 2015-07-01
		Task: Main sp settle Metric Gaming
		DB: DBTXN/bodb02
		
		Revisions:
		
		Parameter's Explantion:
			-@Result = <Result>
							<Row GameResult="7" OtherInfo="6:10"/>
							<Row GameResult="8" OtherInfo="6:20"/>
						</Result>: Every Single Minute
			-@Result = <Result>
							<Row GameResult="15"/>
						</Result>: NONE
			-@Result = <Result>
							<Row GameResult="9" OtherInfo="62"/>
						</Result>: Time of Posession
	*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ActionID		INT
			,@start			DATETIME
			,@stop			DATETIME
			,@Remark		VARCHAR(500)
			,@LogData		NVARCHAR(300)
			,@ticketCount	INT = 0
	
	SELECT @ActionID = CASE WHEN @Action = 'CAL'	THEN 152--MG-calculate
							WHEN @Action = 'UNDO'	THEN 153
							WHEN @Action = 'REFUND' THEN 154
							END
			,@start = CURRENT_TIMESTAMP
			
	-- check and not allow attempt to settlement same game while it's still not finish
	IF EXISTS (
			SELECT 1 
			FROM dbo.TempVariableNumber t WITH(NOLOCK)
			WHERE t.KeyID = 3
			AND t.KeyValue = @matchid
			)
	BEGIN
		SELECT @ErrCode = 1000000
			,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

		RETURN
	END

	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue)
	VALUES (3, @matchid)

	IF (@@ERROR = 0)
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @AdminId
				,@Matchid	= @matchid
				,@KeyID		= 3
				,@ActionID	= @ActionID
				,@Remark	= 'ADD SUCCESS'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(ERROR_MESSAGE(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @AdminId
				,@Matchid	= @matchid
				,@KeyID		= 3
				,@ActionID	= @ActionID
				,@Remark	= @Remark
		END CATCH
	END
	ELSE
	BEGIN
		SELECT @ErrCode = 1000000
			,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

		RETURN
	END
	
	SELECT	@ticketCount = COUNT(1)
	FROM	dbo.translog WITH(NOLOCK)
	WHERE	eventID = @MatchId
			AND gameID = @Bettype
	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceBefore (
		custid		INT PRIMARY KEY
		,balance	MONEY
		)
	
	DECLARE @TotalAccount				INT = 0
		,@TotalAccount_BalanceUpdate	INT = 0
	
	INSERT INTO #BalanceBefore
	SELECT b.custid
		,SUM(b.winlost - b.actual_stake + b.playercomm)
	FROM dbo.bettrans b WITH (ROWLOCK)
	WHERE b.matchid = @matchid 
		AND b.bettype = @Bettype
	GROUP BY b.custid
	
	EXEC DBPRO.BODB02.dbo.NAP_Admin_MetricGamingResult_Update
		@ResultID				= @ResultID
		,@Action				= @Action
		,@Result				= @Result
		,@AdminId				= @AdminId
		,@isSettleDetermined	= @isSettleDetermined
		
	
	EXEC NAP_Admin_Calculate_801
		@matchid				= @matchid
		,@bettype				= @bettype
		,@bettypeTime			= @bettypeTime
		,@Action				= @Action
		,@ResultID				= @ResultID
		,@Result				= @Result
		,@isSettleDetermined	= @isSettleDetermined
	
	-------------------------------------------------------------
	---         CAPTURE value BALANCE after unsettlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (custid int PRIMARY KEY , balance money)
 
	INSERT INTO #BalanceAfter
	SELECT custid,sum( winlost-actual_stake+playercomm)
	FROM dbo.bettrans b WITH (ROWLOCK)
	WHERE matchid = @Matchid 
		AND b.bettype = @Bettype
	Group by custid
    
    -------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	CREATE TABLE #Balance (custid INT PRIMARY KEY, balance MONEY, Increased BIT)

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
	
	-------------------------------------------------------------
	---                      WRITE LOG                        ---
	---------------------------VVVV------------------------------     
	SELECT @stop = CURRENT_TIMESTAMP
	
	SELECT @LogData = 'NAP: Calculate (' + @Action + ') for matchid:' + CAST(@MatchId AS VARCHAR(10))
							+ 'Bettype:' + CAST(@Bettype AS VARCHAR(10)) 
	
	EXEC dbo.WriteLog_UserLog 
		@UserID = @AdminId
		,@Doing = @LogData
		
	-- WRITE LOG	
	/* Format
		<Log>
			<Event IsSettleDetermined="" Duration="" TC="" Bal="" NewAttribute=""/>
				<Result>
					<Row GameResult="7" OtherInfo="6:10"/>
                    <Row GameResult="8" OtherInfo="6:20"/>
				</Result>
			</Event>
		</Log>
	*/
	SELECT @Remark = '<Log>
							<Event IsSettleDetermined ="' + CAST(@IsSettleDetermined AS varchar(10)) + '"'
											+ ' Duration="'+ CAST(DATEDIFF(MILLISECOND, @start, @stop) AS VARCHAR(20)) + ' ms"'
											+ ' TC="' + CAST(@ticketCount AS VARCHAR(20)) + '"'
											+ ' Bal="' + CAST(@TotalAccount_BalanceUpdate AS VARCHAR(20)) + '/' + CAST(@TotalAccount AS VARCHAR(20)) +  '" />'
								+ @Result
						  +	'<Event>'
					+ '</Log>'

	SELECT @Remark
			
	--BEGIN TRY
	--	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_SettleMetricGaming 
	--		@UserID			= @AdminId
	--		,@MatchID		= @matchid
	--		,@bettype		= @bettype
	--		,@bettypeTime	= @bettypeTime
	--		,@ResultID		= @ResultID
	--		,@ActionID		= @ActionID			
	--		,@Result		= @Result
	--		,@Remark		= @Remark
	--		,@IP			= @IP
	--END TRY
	--BEGIN CATCH
	--	SELECT @Remark = 'ErrMsg=' + left(error_message(), 400)
	--	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_SettleMetricGaming 
	--		@UserID			= @AdminId
	--		,@MatchID		= @matchid
	--		,@bettype		= @bettype
	--		,@bettypeTime	= @bettypeTime
	--		,@ResultID		= @ResultID
	--		,@ActionID		= @ActionID			
	--		,@Result		= @Result
	--		,@Remark		= @Remark
	--		,@IP			= @IP
	--END CATCH		
		
	DELETE
	FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
	WHERE KeyID = 3
		AND KeyValue = @matchid	
		
	IF (@@Error = 0)
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @AdminId,
				@Matchid = @matchid,
				@KeyID = 3,
				@ActionID = @ActionID,
				@Remark = 'DEL SUCCESS'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @AdminId,
				@Matchid = @matchid,
				@KeyID = 3,
				@ActionID = @ActionID,
				@Remark = @Remark
		END CATCH
	END
	ELSE
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @AdminId,
				@Matchid = @matchid,
				@KeyID = 3,
				@ActionID = @ActionID,
				@Remark = 'DEL FAILED'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @AdminId,
				@Matchid = @matchid,
				@KeyID = 3,
				@ActionID = @ActionID,
				@Remark = @Remark
		END CATCH
	END

END



GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_MetricGaming] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_MetricGaming] TO [vnteam] AS [dbo]