/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_Refund_All]    Script Date: 09/11/2014 12:49:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Refund_All] 
	@matchid						INT
	,@creator						INT
	,@IsExcludeBetdaq				BIT 			= 0
	,@IsSettleAbandonedMatch		BIT 			= 0
	,@IsExcludeBetfair				BIT 			= 0
	,@IsSettleAbandonedMatchBetFair BIT 			= 0
	,@IsSettleAbandonedMatchIBC		BIT 			= 0
	,@hth 							INT 			= NULL
	,@hta 							INT 			= NULL
	,@fth 							INT 			= NULL
	,@fta 							INT 			= NULL
	,@betstatus						NVARCHAR(50)	= NULL
	,@Action						VARCHAR(10)		= 'CAL'
	,@IsNested						BIT				= 1
	,@IP							VARCHAR(15)		= ''
	,@ErrCode						INT				= 0		OUTPUT
	,@ErrMsg						NVARCHAR(200)	= ''	OUTPUT
AS
/*
	Created: Kathy
	Date: 20140213
	Task : refund tickets 
	Original: refund
	DB: DBTXN/BODB02

	Revisions: 
		- 20140304@Kathy: Execute settlement for abandoned/postponed matches- Clean Sheet, Both/One/Neither team to score, To Win To Nil 
		- 20140426@Kathy: Add 1H FGLG (127) [Redmine:#14449]
		- 20140729@Kathy: Add one more account(BF3) into BetFair's group [Redmine:#19665]
		- 20140704@Kathy: Apply BetRadar [Redmine:#17142]
		- 20140710@Kathy: Apply BetRadar - PenaltyShootout(135) [Redmine:#17142]
		- 20140725@Kathy: Settle determined tickets for Correct Score(4,30), Total Goal (6,126) [Redmine:#19310]
		- 20140812@Kathy: Support new 11 bettypes [Redmine:#19667]
		- 20140909@Kathy: Exclude virtual racing (bettype 1231,1232,1233, 1237, 1238), outright (bettype 10, 31, 32, 33),
						 sportting solution (from 1301 -> 1334), keno (1501 -> 1599)
		- 201409010@Kathy: Update SettlementStatus135 = 4 if the match hasn't any PS ticket [Redmine:#21560]
	
	Param's Explanation:
	• @matchid: matchid need to refund
	• @IsExcludeBetdaq: Is Exclude betdaq tickets or not
	• @IsSettleAbandonedMatch: Is Settlement for Abandoned/postponed match or not
	• @IsExcludeBetfair: Is Exclude betfair tickets or not
	• @IsSettleAbandonedMatchBetFair: Is Settlement for Betfair ticket of Abandoned/postponed match or not
	  @IsSettleAbandonedMatchIBC: Is Settlement for IBC ticket of Abandoned/postponed match or not
	* List of BetDaq Customers 
				custid	--- username	-	roleid
				50057	---	BQUS888		-	1
				879241	---	BQUSMLB		-	1
				103873	---	BQUSNBA		-	1
				78761	---	ITibc101	-	1
				1688156	---	MTEST0101	-	2
				851668  --- BDUS01      -   1
				878902  --- BDUS016     -   1
	* List of Betfair Customers 
				custid	--- username	-	roleid
				2331	---	BF		    -	1
				1077687	---	BFOS		-	1
				15523642--- BF3			-	1
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @start				DATETIME
		,@stop					DATETIME
		,@ScoreLog				VARCHAR(100)
		,@sporttype				TINYINT
		,@IsRefundHT			BIT
		,@IsHTCal				BIT
		,@oddevenht				SMALLMONEY
		,@SettlementStatus135	INT

	SELECT @start = CURRENT_TIMESTAMP
	
	-- check and not allow attempt to settlement same game while it's still not finish
	IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WITH(NOLOCK) WHERE KeyID = 1 AND KeyValue = @matchid)
	BEGIN
		SELECT @ErrCode = 1000000
			,@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

		RETURN
	END

	DECLARE @Remark VARCHAR(500), @ActionID INT

	SELECT @ActionID = 109

	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue)
	VALUES (1, @matchid)

	IF (@@ERROR = 0)
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @creator
				,@Matchid	= @matchid
				,@KeyID		= 1
				,@ActionID	= @ActionID
				,@Remark	= 'ADD SUCCESS'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(ERROR_MESSAGE(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @creator
				,@Matchid	= @matchid
				,@KeyID		= 1
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
	
	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------

	CREATE TABLE #BalanceBefore (custid INT PRIMARY KEY, balance MONEY)

	INSERT INTO #BalanceBefore
	SELECT b.custid
		,SUM(b.winlost - b.actual_stake + b.playercomm)
	FROM dbo.bettrans b WITH (ROWLOCK)
	WHERE b.matchid = @matchid 
	AND b.bettype NOT IN (14, 127)
	AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
	AND b.bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product	
	AND b.bettype NOT BETWEEN 1501 and 1599 -- Keno
	GROUP BY b.custid
	
	-------------------------------------------------------------

	IF @IsSettleAbandonedMatch = 1
		SELECT @IsExcludeBetdaq = 1

	IF @IsSettleAbandonedMatchBetFair = 1
		SELECT @IsExcludeBetfair = 1	

	SELECT @sporttype	= m.SportType
		,@IsRefundHT	= CASE WHEN m.betstatus LIKE 'Refund HT%' THEN 1 ELSE 0 END
	FROM DBPRO.BODB02.dbo.Match m  WITH(NOLOCK)
	WHERE m.matchid = @matchid

	SELECT @IsHTCal = mr.IsHTCal
		,@SettlementStatus135 = mr.SettlementStatus135
	FROM DBPRO.BODB02.dbo.Match_remark mr WITH(NOLOCK)
	WHERE mr.matchid = @matchid
	
	IF NOT EXISTS (SELECT TOP 1 1 FROM bettrans b WITH(NOLOCK) WHERE b.matchid = @matchid and b.bettype = 135)
		AND NOT EXISTS (SELECT TOP 1 1 FROM bettransm bm WITH(NOLOCK) WHERE bm.matchid = @matchid and bm.bettype = 135)
	BEGIN
		SELECT @SettlementStatus135 = CASE WHEN @SettlementStatus135 = 0 THEN 0 -- no offer
										   ELSE 4 -- No ticket
									  END
	END
	ELSE
	BEGIN
		SELECT @SettlementStatus135 = 3 -- Calculated (Manual)
	END
	
	IF @IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1 OR @IsSettleAbandonedMatchIBC = 1
	BEGIN
		DECLARE @TennisTotal	SMALLINT
			,@T_Home			SMALLINT
			,@T_Away			SMALLINT
			,@totalgoal			SMALLMONEY
			,@totalht			SMALLMONEY
		
		DECLARE @betcount_3		INT
			,@betcount_4		INT
			,@betcount_6		INT 
			,@betcount_8		INT
			,@betcount_13 		INT
			,@betcount_26 		INT
			,@betcount_27 		INT
			,@betcount_30 		INT 
			,@betcount_126 		INT
			,@betcount_128 		INT
			,@betcount_129 		INT
			,@betcount_130 		INT
			,@betcount_131 		INT
			,@betcount_132 		INT
			,@betcount_143 		INT
			,@betcount_144 		INT
			,@betcount_145 		INT
			,@betcount_152 		INT
			
		SELECT @ScoreLog = ' HTHScore=' + ISNULL(CAST(@hth AS VARCHAR(10)), '') 
						 + ' HTAScore=' + ISNULL(CAST(@hta AS VARCHAR(10)), '') 
						 + ' FTHScore=' + ISNULL(CAST(@fth AS VARCHAR(10)), '') 
						 + ' FTAScore=' + ISNULL(CAST(@fta AS VARCHAR(10)), '') 
						 + CASE 
								WHEN @SportType IN (5, 6, 9, 30) THEN ' Betstatus=Refund;'
								ELSE ' Betstatus='
						   END + ISNULL(@betstatus,'')
			
		IF @SportType IN (5, 6, 9, 30) -- Tennis/VolleyBall/Badminton/Squash : get TotalGamesPlayed
		BEGIN
			EXEC dbo.Admin_Settlement_2 
				@betstatus	= @betstatus
				,@Total		= @TennisTotal	OUTPUT
				,@TotalHome = @T_Home		OUTPUT
				,@TotalAway = @T_Away		OUTPUT		
		END
		
		SELECT @totalgoal	= CASE 
								WHEN @sporttype IN (5, 6, 9, 30) AND @TennisTotal > 0 THEN @TennisTotal
								ELSE (@fth + @fta)
							  END
			,@totalht		= (@hth + @hta)
			,@oddevenht		= (@hth + @hta) % 2

		IF @Action IN ('CAL', 'CAL-FT') AND @totalgoal IS NULL
		BEGIN
			SELECT @ErrCode = 1000004
				,@ErrMsg = 'Cannot settle determined ticket(s) without FT Score!'

			DELETE
			FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
			WHERE KeyID = 1 AND KeyValue = @matchid

			IF (@@ERROR = 0)
			BEGIN
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID		= @creator
						,@Matchid	= @matchid
						,@KeyID		= 1
						,@ActionID	= @ActionID
						,@Remark	= 'DEL SUCCESS'
				END TRY

				BEGIN CATCH
					SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(ERROR_MESSAGE(), 400)

					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID		= @creator
						,@Matchid	= @matchid
						,@KeyID		= 1
						,@ActionID	= @ActionID
						,@Remark	= @Remark
				END CATCH
			END
			ELSE
			BEGIN
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID		= @creator
						,@Matchid	= @matchid
						,@KeyID		= 1
						,@ActionID	= @ActionID
						,@Remark	= 'DEL FAILED'
				END TRY

				BEGIN CATCH
					SELECT @Remark = 'DEL FAILED ErrMsg=' + left(ERROR_MESSAGE(), 400)

					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID		= @creator
						,@Matchid	= @matchid
						,@KeyID		= 1
						,@ActionID	= @ActionID
						,@Remark	= @Remark
				END CATCH
			END

			RETURN
		END

		IF @Action IN ('CAL', 'CAL-HT') AND @totalht IS NULL
		BEGIN
			SELECT @ErrCode = 1000005
				,@ErrMsg = 'Cannot settle determined ticket(s) without HT Score!'

			DELETE
			FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
			WHERE KeyID = 1 AND KeyValue = @matchid

			IF (@@Error = 0)
			BEGIN
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID		= @creator
						,@Matchid	= @matchid
						,@KeyID		= 1
						,@ActionID	= @ActionID
						,@Remark	= 'DEL SUCCESS'
				END TRY

				BEGIN CATCH
					SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)

					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID		= @creator
						,@Matchid	= @matchid
						,@KeyID		= 1
						,@ActionID	= @ActionID
						,@Remark	= @Remark
				END CATCH
			END
			ELSE
			BEGIN
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID		= @creator
						,@Matchid	= @matchid
						,@KeyID		= 1
						,@ActionID	= @ActionID
						,@Remark	= 'DEL FAILED'
				END TRY

				BEGIN CATCH
					SELECT @Remark = 'DEL FAILED ErrMsg=' + left(ERROR_MESSAGE(), 400)

					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID		= @creator
						,@Matchid	= @matchid
						,@KeyID		= 1
						,@ActionID	= @ActionID
						,@Remark	= @Remark
				END CATCH
			END

			RETURN
		END

		SELECT  @betcount_3		= ISNULL(SUM(CASE b.bettype WHEN 3 THEN 1 ELSE 0 END), 0)
				,@betcount_4 	= ISNULL(SUM(CASE b.bettype WHEN 4 THEN 1 ELSE 0 END), 0)
				,@betcount_6 	= ISNULL(SUM(CASE b.bettype WHEN 6 THEN 1 ELSE 0 END), 0)
				,@betcount_8 	= ISNULL(SUM(CASE b.bettype WHEN 8 THEN 1 ELSE 0 END), 0)
				,@betcount_13 	= ISNULL(SUM(CASE b.bettype WHEN 13 THEN 1 ELSE 0 END), 0)
				,@betcount_26 	= ISNULL(SUM(CASE b.bettype WHEN 26 THEN 1 ELSE 0 END), 0)
				,@betcount_27 	= ISNULL(SUM(CASE b.bettype WHEN 27 THEN 1 ELSE 0 END), 0)
				,@betcount_30 	= ISNULL(SUM(CASE b.bettype WHEN 30 THEN 1 ELSE 0 END), 0)
				,@betcount_126 	= ISNULL(SUM(CASE b.bettype WHEN 126 THEN 1 ELSE 0 END), 0)
				,@betcount_128 	= ISNULL(SUM(CASE b.bettype WHEN 128 THEN 1 ELSE 0 END), 0)
				,@betcount_129 	= ISNULL(SUM(CASE b.bettype WHEN 129 THEN 1 ELSE 0 END), 0)
				,@betcount_130 	= ISNULL(SUM(CASE b.bettype WHEN 130 THEN 1 ELSE 0 END), 0)
				,@betcount_131 	= ISNULL(SUM(CASE b.bettype WHEN 131 THEN 1 ELSE 0 END), 0)
				,@betcount_132 	= ISNULL(SUM(CASE b.bettype WHEN 132 THEN 1 ELSE 0 END), 0)
				,@betcount_143 	= ISNULL(SUM(CASE b.bettype WHEN 143 THEN 1 ELSE 0 END), 0)
				,@betcount_144 	= ISNULL(SUM(CASE b.bettype WHEN 144 THEN 1 ELSE 0 END), 0)
				,@betcount_145 	= ISNULL(SUM(CASE b.bettype WHEN 145 THEN 1 ELSE 0 END), 0)
				,@betcount_152 	= ISNULL(SUM(CASE b.bettype WHEN 152 THEN 1 ELSE 0 END), 0)
		FROM bettrans b WITH(NOLOCK)
		WHERE b.matchid = @matchid 
		AND b.bettype IN (3, 4, 6, 8, 13, 26, 27, 30, 126, 128, 129, 130, 131, 132, 143, 144, 145, 152) 
		AND b.statusID NOT IN (101, 102) 
		AND 1 = CASE 
					WHEN @IsSettleAbandonedMatchIBC = 1 AND (b.custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770, 15523642) AND b.recommend <> 1688156) THEN 1
					WHEN @IsSettleAbandonedMatch = 1 AND (b.custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR b.recommend = 1688156) THEN 1
					WHEN @IsSettleAbandonedMatchBetFair = 1 AND b.custid IN (2331, 1077687, 115770, 15523642) THEN 1
					ELSE 0
				END
	END
			
	/* 	Settle Betdaq, Betfair tickets Abandoned Match for Over/Under  */
	IF @IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1
	BEGIN	
		IF @Action IN ('CAL', 'CAL-HT')
		BEGIN
			EXEC dbo.NAP_Admin_Calculate_Main 
				@matchid						= @matchid
				,@action						= 'REFUND'
				,@mode							= 'ALL'
				,@betcount_8					= @betcount_8 
				,@totalht						= @totalht
				,@IsSettleAbandonedMatch		= @IsSettleAbandonedMatch
				,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
		END

		IF @Action IN ('CAL', 'CAL-FT')
		BEGIN
			EXEC dbo.NAP_Admin_Calculate_Main 
				@matchid						= @matchid
				,@action						= 'REFUND'
				,@mode							= 'ALL'
				,@betcount_3					= @betcount_3 
				,@totalgoal						= @totalgoal			
				,@IsSettleAbandonedMatch		= @IsSettleAbandonedMatch
				,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
		END		
	END
	/* --- END Settle Betdaq, Betfair tickets Abandoned Match for Over/Under  ---*/

	--	Settle tickets Abandoned Match of Soccer 	

	IF (@IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1 OR @IsSettleAbandonedMatchIBC = 1) AND @sporttype = 1
	BEGIN
		IF @action = 'CAL-FT'
		BEGIN
			EXEC dbo.NAP_Admin_Calculate_Main 
				@matchid 						= @matchid
				,@action 						= 'REFUND'
				,@mode							= 'FT'
				,@betcount_4 					= @betcount_4
				,@betcount_6 					= @betcount_6
				,@betcount_13 					= @betcount_13
				,@betcount_26 					= @betcount_26
				,@betcount_27 					= @betcount_27
				,@betcount_130 					= @betcount_130
				,@betcount_131 					= @betcount_131
				,@betcount_132 					= @betcount_132
				,@betcount_144 					= @betcount_144
				,@betcount_145 					= @betcount_145
				,@betcount_152 					= @betcount_152
				,@fth 							= @fth
				,@fta 							= @fta
				,@hth 							= @hth
				,@hta 							= @hta
				,@totalgoal						= @totalgoal
				,@totalht						= @totalht
				,@oddevenht						= @oddevenht
				,@IsSettleAbandonedMatch		= @IsSettleAbandonedMatch
				,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
				,@IsSettleAbandonedMatchIBC		= @IsSettleAbandonedMatchIBC
				,@IsRefundHT					= @IsrefundHT
				,@IsHTCal						= @IsHTCal
		END
		IF @action = 'CAL'
		BEGIN
		EXEC dbo.NAP_Admin_Calculate_Main 
				@matchid 						= @matchid
				,@action 						= 'REFUND'
				,@mode							= 'ALL'
				,@betcount_4 					= @betcount_4
				,@betcount_6 					= @betcount_6
				,@betcount_13 					= @betcount_13
				,@betcount_26 					= @betcount_26
				,@betcount_27 					= @betcount_27
				,@betcount_30 					= @betcount_30
				,@betcount_126 					= @betcount_126
				,@betcount_128 					= @betcount_128
				,@betcount_129 					= @betcount_129
				,@betcount_130 					= @betcount_130
				,@betcount_131 					= @betcount_131
				,@betcount_132 					= @betcount_132
				,@betcount_143 					= @betcount_143
				,@betcount_144 					= @betcount_144
				,@betcount_145 					= @betcount_145
				,@betcount_152					= @betcount_152
				,@fth 							= @fth
				,@fta 							= @fta
				,@hth 							= @hth
				,@hta 							= @hta
				,@totalgoal						= @totalgoal
				,@totalht						= @totalht
				,@oddevenht						= @oddevenht
				,@IsSettleAbandonedMatch		= @IsSettleAbandonedMatch
				,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
				,@IsSettleAbandonedMatchIBC		= @IsSettleAbandonedMatchIBC
				,@IsRefundHT					= @IsrefundHT
				,@IsHTCal						= @IsHTCal
		END
	END
	
	EXEC DBPRO.BODB02.dbo.NAP_Admin_Match_Update 
		@Command	= 'NAP_Admin_Settlement_Refund_All'
		,@MatchID	= @matchid
		,@creator	= @creator

	EXEC dbo.NAP_Admin_Calculate_Main 
		@matchid					= @matchid
		,@action					= 'REFUND'
		,@mode						= 'ALL'
		,@IsExcludeBetdaq			= @IsExcludeBetdaq
		,@IsExcludeBetfair			= @IsExcludeBetfair
		,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
		,@fth						= @fth
		,@fta						= @fta
		,@row_count					= 1
		,@isRefundHT				= @IsRefundHT

	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (custid INT PRIMARY KEY, balance MONEY)
	
	INSERT INTO #BalanceAfter
	SELECT b.custid
		,SUM(b.winlost - b.actual_stake + b.playercomm)
	FROM dbo.bettrans b WITH (ROWLOCK)
	WHERE b.matchid = @matchid 
	AND b.bettype NOT in (14,127)
	AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
	AND b.bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
	AND b.bettype NOT BETWEEN 1501 and 1599 -- Keno
	GROUP BY b.custid
	
	------------------------------------------------------------
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

	--  Betfair & Betdaq - Warning message:
	DECLARE @movebet VARCHAR(20), @matchcode nvarchar(50)

	SELECT @movebet = convert(VARCHAR(20), DATEADD(d, 1, m.kickofftime), 100),
		@matchcode	= m.matchcode
	FROM DBPRO.bodb02.dbo.match m WITH(NOLOCK)
	WHERE m.matchid = @matchid

	IF @matchcode not like '%Hedge%'
	BEGIN 
		IF (@IsExcludeBetdaq = 1 OR @IsSettleAbandonedMatch = 1) AND (@IsExcludeBetfair = 1 OR @IsSettleAbandonedMatchBetFair = 1)
		BEGIN
			SELECT @ErrCode = 1000006
				,@ErrMsg	= 'Please move Betdaq and Betfair tickets to a new match before ' + @movebet + ' GMT-4. Otherwise they will bring harm to the system'
		END
		ELSE IF (@IsExcludeBetdaq = 1 OR @IsSettleAbandonedMatch = 1)
		BEGIN
			SELECT @ErrCode = 1000006
				,@ErrMsg	= 'Please move Betdaq tickets to a new match before ' + @movebet + ' GMT-4. Otherwise they will bring harm to the system'
		END
		ELSE IF (@IsExcludeBetfair = 1 OR @IsSettleAbandonedMatchBetFair = 1)
		BEGIN
			SELECT @ErrCode = 1000006
				,@ErrMsg	= 'Please move Betfair tickets to a new match before ' + @movebet + ' GMT-4. Otherwise they will bring harm to the system'
		END
	END 
	---------------------------------------------------
	DROP TABLE #Balance

	DROP TABLE #BalanceBefore

	DROP TABLE #BalanceAfter

	-------------------------------------------------------------
	---                      WRITE LOG                        ---
	---------------------------VVVV------------------------------
	
	SELECT @stop = CURRENT_TIMESTAMP

	DECLARE @LogData NVARCHAR(200)

	SELECT @LogData = 'NAP: Calculate (Refund All) for matchid:' + CAST(@matchid AS NVARCHAR(10)) 
																 + CASE WHEN @IsExcludeBetdaq = 1				THEN ', Exclude Betdaq tickets'				ELSE '' END 
																 + CASE WHEN @IsSettleAbandonedMatch = 1		THEN ', Settle determined betdaq tickets'	ELSE '' END 
																 + CASE WHEN @IsExcludeBetfair = 1				THEN ', Exclude Betfair tickets'			ELSE '' END 
																 + CASE WHEN @IsSettleAbandonedMatchBetFair = 1 THEN ', Settle determined betfair tickets'	ELSE '' END
																 + CASE WHEN @IsSettleAbandonedMatchIBC = 1		THEN ', Settle determined IBC tickets'		ELSE '' END

	EXEC dbo.WriteLog_UserLog 
		@UserID = @creator
		,@Doing =  @LogData

	--Write Log Settle
	SELECT @Remark = 'NAP: ExcludeBetdaqTickets='			+ convert(char(1),@IsExcludeBetdaq) 
					+ ' SettleDeterminedBetdaqTickets='		+ convert(char(1),@IsSettleAbandonedMatch)
					+ ' ExcludeBetfairTickets='				+ convert(char(1),@IsExcludeBetfair) 
					+ ' SettleDeterminedBetfairTickets='	+ convert(char(1),@IsSettleAbandonedMatchBetFair)
					+ ' SettleDeterminedIBCTickets='		+ convert(char(1),@IsSettleAbandonedMatchIBC)
					+ CASE WHEN (@IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair =1 OR @IsSettleAbandonedMatchIBC = 1) THEN @ScoreLog ELSE '' END 
					+ ' Action=' + @Action
					+ ' Duration=' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms;'

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle 
			@UserID				= @creator
			,@Matchid			= @matchid
			,@ActionID			= @ActionID
			,@finalhomescore 	= 0
			,@finalawayscore 	= 0
			,@hthomescore 		= 0
			,@htawayscore 		= 0
			,@GoalRecord		= ''
			,@betstatus			= 'Refund'
			,@Remark			= @Remark
			,@IP				= @IP
	END TRY

	BEGIN CATCH
		SELECT @Remark = @Remark + ' ErrMsg=' + LEFT(ERROR_MESSAGE(), 250)

		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle 
			@UserID				= @creator
			,@Matchid			= @matchid
			,@ActionID			= @ActionID
			,@finalhomescore	= 0
			,@finalawayscore	= 0
			,@hthomescore 		= 0
			,@htawayscore 		= 0
			,@GoalRecord		= ''
			,@betstatus			= 'Refund'
			,@Remark			= @Remark
			,@IP				= @IP
	END CATCH

	-----
	DELETE
	FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid

	IF (@@ERROR = 0)
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @creator
				,@Matchid	= @matchid
				,@KeyID		= 1
				,@ActionID	= @ActionID
				,@Remark	= 'DEL SUCCESS'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS ErrMsg=' + LEFT(ERROR_MESSAGE(), 350)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @creator
				,@Matchid	= @matchid
				,@KeyID		= 1
				,@ActionID	= @ActionID
				,@Remark	= @Remark
		END CATCH
	END
	ELSE
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @creator
				,@Matchid	= @matchid
				,@KeyID		= 1
				,@ActionID	= @ActionID
				,@Remark	= 'DEL FAILED'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED ErrMsg=' + left(ERROR_MESSAGE(), 350)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @creator
				,@Matchid	= @matchid
				,@KeyID		= 1
				,@ActionID	= @ActionID
				,@Remark	= @Remark
		END CATCH
	END

	IF @IsNested = 0
	BEGIN
		-- Update match_remark
		EXEC DBPRO.BODB02.dbo.NAP_updateMatch_remark 
			@matchid	= @matchid
			,@command	= 'F'

		-- Update SettlementStatus135
		EXEC DBPRO.BODB02.dbo.NAP_updateMatch_remark 
			@matchid	= @matchid
			,@command	= 'PS'
			,@ivalue	= @SettlementStatus135

		-- Write log
		DECLARE @log VARCHAR(200)

		SET @log = 'NAP: Refund for matchid: ' + CONVERT(VARCHAR(10), @matchid)

		EXEC dbo.WriteLog_UserLog 
			@UserID = @creator
			,@Doing = @Log
	END
END













GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_Refund_All] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_Refund_All] TO [vnteam] AS [dbo]