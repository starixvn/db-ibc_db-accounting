ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_RefundFT] 
	@matchid						INT
	,@adminid						INT
	,@IsExcludeBetdaq				BIT				= 0
	,@IsSettleAbandonedMatch		BIT				= 0
	,@IsExcludeBetfair				BIT 			= 0
	,@IsSettleAbandonedMatchBetFair BIT 			= 0
	,@IsSettleAbandonedMatchIBC		BIT 			= 0
	,@fth							INT 			= NULL
	,@fta							INT 			= NULL
	,@GoalSequence					VARCHAR(50)		= NULL 
	,@fthCorners					SMALLINT		= NULL
	,@ftaCorners					SMALLINT		= NULL
	,@ftFCorner						VARCHAR(1)		= NULL
	,@betstatus						NVARCHAR(50)	= NULL
	,@isExistTotalCorner			BIT				= 0 
	,@isExistHTFCorner				BIT				= 0 
	,@isExistHTLCorner				BIT				= 0 
	,@isExistFTFCorner				BIT				= 0 
	,@isExistFTLCorner				BIT				= 0 
	,@IP							VARCHAR(15)		= ''
	,@ErrCode						INT				= 0			OUTPUT
	,@ErrMsg						NVARCHAR(200)	= ''		OUTPUT
AS
/*
	Created: Kathy
	Date: 20140213
	Task : Refund Full-time tickets
	DB: DBTXN/BODB02
	Original: 
	
	Revisions:
		- 20140304@Kathy: Execute settlement for abandoned/postponed matches- Clean Sheet, Both/One/Neither team to score, To Win To Nil 
		- 20140426@Kathy: Add 1H Total Goal and 1H FGLG bettypes (126, 127) [Redmine:#14449]
		- 20140729@Kathy: Add one more account(BF3) into BetFair's group [Redmine:#19665]
		- 20140617@Kathy: Apply BetRadar [Redmine:#17142]
		- 20140710@Kathy: Apply BetRadar - PenaltyShootout(135) [Redmine:#17142]
		- 20140725@Kathy: Settle determined tickets for Correct Score(4,30), Total Goal (6,126) [Redmine:#19310]
		- 20140811@Kathy: Support new 11 bettypes [Redmine:#19667]
		- 20140909@Kathy: Exclude virtual racing (bettype 1231,1232,1233, 1237, 1238), outright (bettype 10, 31, 32, 33),
						 sportting solution (from 1301 -> 1334), keno (1501 -> 1599)
		- 20140911@Kathy: Update SettlementStatus135 = 4 if the match hasn't any PS ticket [Redmine:#21560]
		- 20150421@Jamie: Settlement Betradar phase 2 [Redmine: #27212]
		- 20150618@Jamie: Offer the option Exclude Corner tickets [Feature #38099]
		- 20150807@Kathy: Using new balance table (BalCreditSportsPending,BalDebitSportsPending) [Redmine:#40125]

		
	Param's Explanation:
	• @matchid: matchid of match to Refund HT
	• @IsSettleAbandonedMatch: Is Settlement for Abandoned/postponed match or not
	• @IsSettleAbandonedMatchBetFair: Is Settlement for Betfair ticket of Abandoned/postponed match or not
	• @IsSettleAbandonedMatchIBC: Is Settlement for IBC ticket of Abandoned/postponed match or not

*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Remark	VARCHAR(500)
		,@ActionID	INT
		,@start		DATETIME
		,@stop		DATETIME

	SELECT @start	= CURRENT_TIMESTAMP
		,@ActionID	= 111
		
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

	IF (@@ERROR = 0)
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @adminID
				,@Matchid	= @matchid
				,@KeyID		= 1
				,@ActionID	= @ActionID
				,@Remark	= 'ADD SUCCESS'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(ERROR_MESSAGE(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @adminID
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

	CREATE TABLE #BalanceBefore (custid	INT PRIMARY KEY, balance MONEY)

	INSERT INTO #BalanceBefore
	SELECT b.custid
		,SUM(b.winlost - b.actual_stake + b.playercomm)
	FROM dbo.bettrans b WITH (ROWLOCK)
	WHERE b.matchid = @matchid 
	AND b.bettype NOT IN (14, 127)
	AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
	AND b.bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
	AND b.bettype NOT BETWEEN 1501 and 1599 -- Keno
	AND b.bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) --AUTO betradar 2 
	GROUP BY b.custid

	DECLARE @status TABLE (FTBet BIT, BetCount INT, InRunning INT)
	
	DECLARE @HTDone BIT, @FTDone BIT

	INSERT INTO @status
	SELECT CASE 
				WHEN b.bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209) THEN 0
				ELSE 1
		   END
		,SUM(CASE 
				WHEN b.statusID IN (101, 102) THEN 0
				ELSE 1
			 END)
		,SUM(CASE 
				WHEN b.statusID = 0 THEN 1
				ELSE 0
			 END)
	FROM dbo.bettrans b WITH (NOLOCK)
	WHERE b.matchid = @matchid
	AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
	AND b.bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
	AND b.bettype NOT BETWEEN 1501 and 1599 -- Keno
	AND b.bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) --AUTO betradar 2 
	GROUP BY CASE 
				WHEN b.bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209) THEN 0
				ELSE 1
			 END

	IF NOT EXISTS (SELECT * FROM @status WHERE FTBet = 0)
		INSERT INTO @status VALUES (0, 0, 0)

	IF NOT EXISTS (SELECT *	FROM @status WHERE FTBet = 1)
		INSERT INTO @status VALUES (1, 0, 0)

	SELECT @HTDone = CASE InRunning
						WHEN 0 THEN 1
						ELSE 0
					 END
	FROM @status
	WHERE FTBet = 0

	SELECT @FTDone = CASE InRunning
						WHEN 0 THEN 1
						ELSE 0
					 END
	FROM @status
	WHERE FTBet = 1

	IF @IsSettleAbandonedMatch = 1
		SELECT @IsExcludeBetdaq = 1

	IF @IsSettleAbandonedMatchBetFair = 1
		SELECT @IsExcludeBetfair = 1

	--=========================================
	-- Check HTNormalBets and HTCornerBet 
	DECLARE	@HTNoneCornerBetDone	BIT
			,@HTCornerBetDone	BIT

	DECLARE	@tmpHTStatus TABLE(
		HTCornerBet	BIT
		,inRunning	INT
	)	

	INSERT INTO @tmpHTStatus(HTCornerBet,inRunning)
	SELECT	CASE WHEN Bettype IN (200,201,202,203,204,205,207,209) THEN 1
				 ELSE 0 END 
			,SUM(CASE WHEN statusID = 0 THEN 1 ELSE 0 END)
	FROM bettrans WITH (NOLOCK)
	WHERE	MatchID = @MatchID 
			AND bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209) --HT bets
			AND statusID NOT BETWEEN 101 AND 102 
	GROUP BY CASE WHEN Bettype IN (200,201,202,203,204,205,207,209) THEN 1
				 ELSE 0 END 

	IF NOT EXISTS(SELECT TOP 1 1 FROM @tmpHTStatus WHERE HTCornerBet = 0)
		INSERT INTO @tmpHTStatus(HTCornerBet,inRunning) VALUES(0,0)

	SELECT	@HTNoneCornerBetDone = CASE InRunning WHEN 0 THEN 1 ELSE 0 END 
	FROM	@tmpHTStatus
	WHERE	HTCornerBet = 0

	---===============================================
	--Check if match already Refund HT => refund whole match
	IF EXISTS (
			SELECT 1
			FROM DBPRO.BODB02.dbo.Match m WITH(NOLOCK)
			WHERE m.matchid = @matchid 
			AND m.betstatus LIKE '%Refund HT%'
			) AND @HTDone = 1
	BEGIN
		-----
		DELETE
		FROM dbo.TempVariableNumber WITH(ROWLOCK, UPDLOCK)
		WHERE KeyID = 1 
		AND KeyValue = @matchid

		IF (@@ERROR = 0)
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID		= @adminID
					,@Matchid	= @matchid
					,@KeyID		= 1
					,@ActionID	= @ActionID
					,@Remark	= 'DEL SUCCESS'
			END TRY

			BEGIN CATCH
				SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(ERROR_MESSAGE(), 400)

				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID		= @adminID
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
					@UserID		= @adminID
					,@Matchid	= @matchid
					,@KeyID		= 1
					,@ActionID	= @ActionID
					,@Remark	= 'DEL FAILED'
			END TRY

			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED ErrMsg=' + left(ERROR_MESSAGE(), 400)

				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID		= @adminID
					,@Matchid	= @matchid
					,@KeyID		= 1
					,@ActionID	= @ActionID
					,@Remark	= @Remark
			END CATCH
		END

																																																																EXEC dbo.NAP_Admin_Settlement_Refund_All 
			@matchid						= @matchid
			,@creator						= @adminid
			,@IsExcludeBetdaq				= @IsExcludeBetdaq
			,@IsSettleAbandonedMatch		= @IsSettleAbandonedMatch
			,@IsExcludeBetfair				= @IsExcludeBetfair
			,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
			,@IsSettleAbandonedMatchIBC		= @IsSettleAbandonedMatchIBC
			,@hth 							= NULL
			,@hta 							= NULL
			,@fth 							= @fth
			,@fta 							= @fta
			,@GoalSequence					= @GoalSequence
			,@fthCorners					= @fthCorners
			,@ftaCorners					= @ftaCorners
			,@hthCorners					= NULL
			,@htaCorners					= NULL
			,@ftFCorner						= @ftFCorner
			,@htFCorner						= NULL
			,@betstatus						= @betstatus
			,@isExistTotalCorner			= @isExistTotalCorner
			,@isExistHTFCorner				= @isExistHTFCorner
			,@isExistHTLCorner				= @isExistHTLCorner
			,@isExistFTFCorner				= @isExistFTFCorner
			,@isExistFTLCorner				= @isExistFTLCorner
			,@Action						= 'CAL-FT'
			,@IP							= @IP
			,@ErrCode						= @ErrCode OUTPUT
			,@ErrMsg						= @ErrMsg OUTPUT

		RETURN
	END

	/*
	Settle Abandoned Match for Over/Under 
*/
	DECLARE @ScoreLog	VARCHAR(100)
		,@sporttype		TINYINT
		,@hth			INT
		,@hta			INT 
		,@IsHTCal		BIT
		,@IsRefundHT	BIT
		,@oddevenht		SMALLMONEY
		,@scorediff		SMALLMONEY

	SELECT @sporttype	= SportType
		,@hth			= hthomescore
		,@hta			= htawayscore
		,@IsRefundHT	= CASE WHEN betstatus LIKE 'Refund HT%' THEN 1 ELSE 0 END 
	FROM DBPRO.BODB02.dbo.Match WITH (NOLOCK)
	WHERE matchid = @matchid

	SELECT @IsHTCal = isHTCal
	FROM DBPRO.BODB02.dbo.Match_remark WITH (NOLOCK)
	WHERE matchid = @matchid	
	

	IF (@IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1 OR @IsSettleAbandonedMatchIBC = 1) AND @HTDone = 1
	BEGIN
		DECLARE @TennisTotal SMALLINT
			,@T_Home		 SMALLINT
			,@T_Away		 SMALLINT
			,@totalgoal		 SMALLMONEY
			,@totalgoal_2H	 SMALLMONEY
			,@totalCorners	 SMALLMONEY 
			
		DECLARE @betcount_3  INT
			,@betcount_4     INT
			,@betcount_6     INT
			,@betcount_13	 INT
			,@betcount_26	 INT
			,@betcount_27	 INT
			,@betcount_128	 INT
			,@betcount_130	 INT
			,@betcount_131	 INT
			,@betcount_132	 INT
			,@betcount_133	 INT
			,@betcount_134	 INT
			,@betcount_140	 INT
			,@betcount_141	 INT
			,@betcount_142	 INT
			,@betcount_144	 INT
			,@betcount_145	 INT
			,@betcount_146	 INT
			,@betcount_147	 INT
			,@betcount_148	 INT
			,@betcount_149	 INT
			,@betcount_150	 INT
			,@betcount_152	 INT

			,@betcount_159 		INT
			,@betcount_161 		INT
			,@betcount_162 		INT
			,@betcount_163 		INT
			,@betcount_170 		INT
			,@betcount_172 		INT
			,@betcount_187 		INT
			,@betcount_195 		INT
			,@betcount_196 		INT
			,@betcount_199 		INT
			,@betcount_206 		INT
			
		SELECT @ScoreLog = ' FTHScore=' + CAST(@fth AS VARCHAR(10)) 
						 + ' FTAScore=' + CAST(@fta AS VARCHAR(10)) 
						 + ' BetStatus=' + ISNULL(@betstatus,'')
						 + CASE WHEN @GoalSequence IS NULL THEN '' ELSE ' GoalSequence=' + @GoalSequence + '<br/> ' END  
						 + CASE WHEN @fthCorners IS NULL THEN '' ELSE ' fthCorners=' + CAST(@fthCorners AS VARCHAR(20)) + '<br/> ' END 
						 + CASE WHEN @ftaCorners IS NULL THEN '' ELSE ' ftaCorners=' + CAST(@ftaCorners AS VARCHAR(20)) + '<br/> ' END 
						 + CASE WHEN @ftFCorner	IS NULL THEN '' ELSE ' ftFCorner=' + @ftFCorner	+ '<br/> ' END 

		IF @SportType IN (5, 6, 9, 30) -- Tennis/VolleyBall/Badminton/Squash : get TotalGamesPlayed
			EXEC dbo.Admin_Settlement_2 
				@betstatus	= @betstatus
				,@Total		= @TennisTotal	OUTPUT
				,@TotalHome = @T_Home		OUTPUT
				,@TotalAway = @T_Away		OUTPUT

		SELECT @totalgoal	= CASE 
								WHEN @sporttype IN (5, 6, 9, 30) AND @TennisTotal > 0 THEN @TennisTotal
								ELSE (@fth + @fta)
							  END
			,@oddevenht		= (@hth + @hta) % 2
			,@scorediff		= (@fth - @fta)
			,@totalCorners	= (@fthCorners + @ftaCorners)
			,@totalgoal_2H  = (@fth + @fta) - (@hth + @hta)

		IF @totalgoal IS NULL
		BEGIN
			SELECT @ErrCode = 1000004
				,@ErrMsg	= 'Cannot settle determined ticket(s) without FT Score!'

			DELETE
			FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
			WHERE KeyID = 1 
			AND KeyValue = @matchid

			IF (@@ERROR = 0)
			BEGIN
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID		= @adminID
						,@Matchid	= @matchid
						,@KeyID		= 1
						,@ActionID	= @ActionID
						,@Remark	= 'DEL SUCCESS'
				END TRY

				BEGIN CATCH
					SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(ERROR_MESSAGE(), 400)

					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID		= @adminID
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
						@UserID		= @adminID
						,@Matchid	= @matchid
						,@KeyID		= 1
						,@ActionID	= @ActionID
						,@Remark	= 'DEL FAILED'
				END TRY

				BEGIN CATCH
					SELECT @Remark = 'DEL FAILED ErrMsg=' + left(ERROR_MESSAGE(), 400)

					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID		= @adminID
						,@Matchid	= @matchid
						,@KeyID		= 1
						,@ActionID	= @ActionID
						,@Remark	= @Remark
				END CATCH
			END

			RETURN
		END
		
		SELECT @betcount_3		= ISNULL(SUM(CASE b.bettype WHEN 3 THEN 1 ELSE 0 END), 0)
	
		  ,@betcount_4		= ISNULL(SUM(CASE b.bettype WHEN 4 THEN 1 ELSE 0 END), 0)
		  ,@betcount_6		= ISNULL(SUM(CASE b.bettype WHEN 6 THEN 1 ELSE 0 END), 0)
		  
		  ,@betcount_13		= ISNULL(SUM(CASE b.bettype WHEN 13 THEN 1 ELSE 0 END), 0)
		  ,@betcount_26		= ISNULL(SUM(CASE b.bettype WHEN 26 THEN 1 ELSE 0 END), 0)
		  ,@betcount_27		= ISNULL(SUM(CASE b.bettype WHEN 27 THEN 1 ELSE 0 END), 0)
		  
		  ,@betcount_128 	= ISNULL(SUM(CASE b.bettype WHEN 128 THEN 1 ELSE 0 END), 0)
		  ,@betcount_130 	= ISNULL(SUM(CASE b.bettype WHEN 130 THEN 1 ELSE 0 END), 0)
		  ,@betcount_131 	= ISNULL(SUM(CASE b.bettype WHEN 131 THEN 1 ELSE 0 END), 0)
		  ,@betcount_132 	= ISNULL(SUM(CASE b.bettype WHEN 132 THEN 1 ELSE 0 END), 0)			  
		  ,@betcount_133 	= ISNULL(SUM(CASE b.bettype WHEN 133 THEN 1 ELSE 0 END), 0)
		  ,@betcount_134 	= ISNULL(SUM(CASE b.bettype WHEN 134 THEN 1 ELSE 0 END), 0)
		  ,@betcount_140 	= ISNULL(SUM(CASE b.bettype WHEN 140 THEN 1 ELSE 0 END), 0)
		  ,@betcount_141 	= ISNULL(SUM(CASE b.bettype WHEN 141 THEN 1 ELSE 0 END), 0)
		  ,@betcount_142 	= ISNULL(SUM(CASE b.bettype WHEN 142 THEN 1 ELSE 0 END), 0)
		  ,@betcount_144 	= ISNULL(SUM(CASE b.bettype WHEN 144 THEN 1 ELSE 0 END), 0)
		  ,@betcount_145 	= ISNULL(SUM(CASE b.bettype WHEN 145 THEN 1 ELSE 0 END), 0)
		  ,@betcount_146 	= ISNULL(SUM(CASE b.bettype WHEN 146 THEN 1 ELSE 0 END), 0)
		  ,@betcount_147 	= ISNULL(SUM(CASE b.bettype WHEN 147 THEN 1 ELSE 0 END), 0)
		  ,@betcount_148 	= ISNULL(SUM(CASE b.bettype WHEN 148 THEN 1 ELSE 0 END), 0)
		  ,@betcount_149 	= ISNULL(SUM(CASE b.bettype WHEN 149 THEN 1 ELSE 0 END), 0)
		  ,@betcount_150 	= ISNULL(SUM(CASE b.bettype WHEN 150 THEN 1 ELSE 0 END), 0)
		  ,@betcount_152 	= ISNULL(SUM(CASE b.bettype WHEN 152 THEN 1 ELSE 0 END), 0)
		  ,@betcount_159 	= ISNULL(SUM(CASE b.bettype WHEN 159 THEN 1 ELSE 0 END), 0)  -- Betradar 2 
		  ,@betcount_161 	= ISNULL(SUM(CASE b.bettype WHEN 161 THEN 1 ELSE 0 END), 0)
		  ,@betcount_162 	= ISNULL(SUM(CASE b.bettype WHEN 162 THEN 1 ELSE 0 END), 0)
		  ,@betcount_163 	= ISNULL(SUM(CASE b.bettype WHEN 163 THEN 1 ELSE 0 END), 0)
		  ,@betcount_170 	= ISNULL(SUM(CASE b.bettype WHEN 170 THEN 1 ELSE 0 END), 0)
		  ,@betcount_172 	= ISNULL(SUM(CASE b.bettype WHEN 172 THEN 1 ELSE 0 END), 0)
		  ,@betcount_187 	= ISNULL(SUM(CASE b.bettype WHEN 187 THEN 1 ELSE 0 END), 0)  
		  ,@betcount_195 	= ISNULL(SUM(CASE b.bettype WHEN 195 THEN 1 ELSE 0 END), 0)
		  ,@betcount_196 	= ISNULL(SUM(CASE b.bettype WHEN 196 THEN 1 ELSE 0 END), 0)
		  ,@betcount_199 	= ISNULL(SUM(CASE b.bettype WHEN 199 THEN 1 ELSE 0 END), 0)
		  ,@betcount_206 	= ISNULL(SUM(CASE b.bettype WHEN 206 THEN 1 ELSE 0 END), 0)

		FROM bettrans b WITH (NOLOCK)
		WHERE b.matchid = @matchid 
		AND b.bettype IN (3, 4, 6, 13, 26, 27, 128, 130, 131, 132, 133, 134, 140, 141, 142, 144, 145, 146, 147, 148, 149, 150, 152,159, 161, 162, 163, 170, 172, 187, 195, 196, 199, 206) 
		AND b.statusID NOT IN (101, 102) 
		AND 1 = CASE WHEN @IsSettleAbandonedMatch = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) THEN 1
				     WHEN @IsSettleAbandonedMatchBetFair = 1 AND custid IN (2331, 1077687, 115770, 15523642) THEN 1
				     WHEN @IsSettleAbandonedMatchIBC = 1 AND (b.custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770, 15523642) AND recommend <> 1688156) THEN 1
				     ELSE 0
				END
	END			
	
	IF (@IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1) AND @HTDone = 1
	BEGIN		
																																																																EXEC dbo.NAP_Admin_Calculate_Main 
			@matchid						= @matchid
			,@action						= 'REFUND'
			,@mode							= 'FT'
			,@totalgoal						= @totalgoal
			,@betcount_3					= @betcount_3
			,@IsSettleAbandonedMatch		= @IsSettleAbandonedMatch
			,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
	END

	/* --- END Settle Abandoned Match ---*/
	IF (@IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1 OR @IsSettleAbandonedMatchIBC = 1) AND @HTDone = 1 AND @sporttype = 1
	BEGIN	
																																																																EXEC dbo.NAP_Admin_Calculate_Main 
			@matchid 						= @matchid
			,@action 						= 'REFUND'
			,@mode							= 'FT'
			,@fth 							= @fth
			,@fta 							= @fta
			,@hth 							= @hth
			,@hta 							= @hta
			,@totalgoal 					= @totalgoal
			,@totalgoal_2H					= @totalgoal_2H
			,@oddevenht 					= @oddevenht
			,@scorediff 					= @scorediff
			,@GoalRecord					= @GoalSequence
			,@fthCorners					= @fthCorners
			,@ftaCorners					= @ftaCorners
			,@totalCorners					= @totalCorners
			,@ftFCorner						= @ftFCorner
			,@betcount_4					= @betcount_4
			,@betcount_6					= @betcount_6
			,@betcount_13 					= @betcount_13
			,@betcount_26 					= @betcount_26
			,@betcount_27 					= @betcount_27
			,@betcount_128 					= @betcount_128
			,@betcount_130 					= @betcount_130
			,@betcount_131 					= @betcount_131
			,@betcount_132 					= @betcount_132
			,@betcount_133 					= @betcount_133
			,@betcount_134 					= @betcount_134
			,@betcount_140 					= @betcount_140
			,@betcount_141 					= @betcount_141
			,@betcount_142 					= @betcount_142
			,@betcount_144 					= @betcount_144
			,@betcount_145 					= @betcount_145
			,@betcount_146 					= @betcount_146
			,@betcount_147 					= @betcount_147
			,@betcount_148 					= @betcount_148
			,@betcount_149 					= @betcount_149
			,@betcount_150 					= @betcount_150
			,@betcount_152 					= @betcount_152
			,@betcount_159 					= @betcount_159  -- Betradar 2 
			,@betcount_161 					= @betcount_161
			,@betcount_162 					= @betcount_162
			,@betcount_163 					= @betcount_163
			,@betcount_170 					= @betcount_170
			,@betcount_172 					= @betcount_172
			,@betcount_187 					= @betcount_187
			,@betcount_195 					= @betcount_195
			,@betcount_196 					= @betcount_196
			,@betcount_199 					= @betcount_199
			,@betcount_206 					= @betcount_206
			,@IsHTCal						= @IsHTCal
			,@IsSettleAbandonedMatch		= @IsSettleAbandonedMatch
			,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
			,@IsSettleAbandonedMatchIBC		= @IsSettleAbandonedMatchIBC
	END

	DECLARE @RowCount INT

				EXEC DBPRO.BODB02.dbo.NAP_Admin_Match_Update 
		@Command	= 'NAP_Admin_Settlement_RefundFT'
		,@MatchID	= @matchid
		,@HTDone	= @HTDone
		,@HTNoneCornerBetDone = @HTNoneCornerBetDone
		,@RowCount	= @RowCount OUTPUT
		,@creator	= @adminid

	
	IF @sporttype = 1 
	BEGIN
								EXEC DBPRO.BODB02.dbo.[NAP_Admin_Result_Update_1s] 
			@Command			= 'NAP_Admin_Settlement_RefundFT'
			,@MatchID			= @matchid
			,@isExistTotalCorner= @isExistTotalCorner
			,@isExistHTFCorner	= @isExistHTFCorner
			,@isExistHTLCorner	= @isExistHTLCorner
			,@isExistFTFCorner	= @isExistFTFCorner
			,@isExistFTLCorner	= @isExistFTLCorner
			,@creator			= @adminid
	END

	IF @RowCount > 0
	BEGIN
		-- Calculate Refund FT
								EXEC dbo.NAP_Admin_Calculate_Main 
			@matchid 					= @matchid
			,@action 					= 'REFUND'
			,@mode						= 'FT'
			,@row_count					= @RowCount
			,@IsExcludeBetdaq			= @IsExcludeBetdaq
			,@IsExcludeBetfair			= @IsExcludeBetfair
			,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
			,@fth						= @fth
			,@fta						= @fta
			,@IsHTCal					= @IsHTCal
			,@IsRefundHT				= @IsRefundHT

		EXEC DBPRO.BODB02.dbo.NAP_updateMatch_remark 
			@matchid	= @matchid
			,@command	= 'F'

	END

	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	
	CREATE TABLE #BalanceAfter (custid INT PRIMARY KEY, balance	MONEY)

	INSERT INTO #BalanceAfter
	SELECT custid
		,SUM(winlost - actual_stake + playercomm)
	FROM dbo.bettrans WITH (ROWLOCK)
	WHERE matchid = @matchid 
	AND bettype NOT IN (14, 127)
	AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
	AND bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
	AND bettype NOT BETWEEN 1501 and 1599 -- Keno
	AND bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) --AUTO betradar 2 
	GROUP BY custid

	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	
	CREATE TABLE #Balance (custid INT PRIMARY KEY, balance	MONEY, Increased BIT)
	DECLARE @tblDebitPending BalanceList
	DECLARE @tblCreditPending BalanceList

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
	--SELECT custid
	--	,ABS(balance)
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
	--SELECT custid
	--	,balance
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
	FROM #Balance WITH (NOLOCK)
	WHERE Increased = 0

	---------------------------------------
	--  Betfair & Betdaq - Warning message:
	DECLARE @movebet VARCHAR(20),@matchcode nvarchar(50)

	SELECT @movebet = convert(VARCHAR(20), DATEADD(d, 1, kickofftime), 100),
		@matchcode	= matchcode
	FROM DBPRO.bodb02.dbo.match WITH (NOLOCK)
	WHERE matchid = @matchid
	
	IF @matchcode not like '%Hedge%'
	BEGIN 
		IF (@IsExcludeBetdaq = 1 OR @IsSettleAbandonedMatch = 1) AND (@IsExcludeBetfair = 1 OR @IsSettleAbandonedMatchBetFair = 1) AND @HTDone = 1
		BEGIN
			SELECT @ErrCode = 1000006
				,@ErrMsg	= 'Please move Betdaq and Betfair tickets to a new match before ' + @movebet + ' GMT-4. Otherwise they will bring harm to the system'
		END
		ELSE IF (@IsExcludeBetdaq = 1 OR @IsSettleAbandonedMatch = 1) AND @HTDone = 1
		BEGIN
			SELECT @ErrCode = 1000006
				,@ErrMsg	= 'Please move Betdaq tickets to a new match before ' + @movebet + ' GMT-4. Otherwise they will bring harm to the system'
		END
		ELSE IF (@IsExcludeBetfair = 1 OR @IsSettleAbandonedMatchBetFair = 1) AND @HTDone = 1
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

	IF @RowCount > 0 OR ((@IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1 OR @IsSettleAbandonedMatchIBC = 1) AND @HTDone = 1)
	BEGIN
		DECLARE @LogData NVARCHAR(300)

		SELECT @LogData = 'NAP: Calculate (Refund FT) for matchid:' 
							+ CAST(@matchid AS NVARCHAR(10)) + CASE WHEN @IsExcludeBetdaq = 1 THEN ', Exclude Betdaq tickets' ELSE '' END 
															 + CASE WHEN @IsSettleAbandonedMatch = 1 THEN ', Settle determined betdaq tickets' ELSE '' END 
															 + CASE WHEN @IsExcludeBetfair = 1 THEN ', Exclude Betfair tickets' ELSE '' END 
															 + CASE WHEN @IsSettleAbandonedMatchBetFair = 1 THEN ', Settle determined betfair tickets' ELSE '' END 
															 + CASE WHEN @IsSettleAbandonedMatchIBC = 1 THEN ', Settle determined IBC tickets' ELSE '' END

		EXEC dbo.WriteLog_UserLog 
			@UserId = @AdminID
			,@Doing = @LogData

		--Write Log Settle
		DECLARE @hthomescore	INT
			,@htawayscore		INT
			,@goalrecord		VARCHAR(50)

		SELECT @Remark = 'NAP: ExcludeBetdaqTickets='	  + convert(CHAR(1), @IsExcludeBetdaq) 
					  + ' SettleDeterminedBetdaqTickets=' + convert(CHAR(1), @IsSettleAbandonedMatch) 
				      + ' ExcludeBetfairTickets='         + convert(CHAR(1), @IsExcludeBetfair) 
					  + ' SettleDeterminedBetfairTickets=' + convert(CHAR(1), @IsSettleAbandonedMatchBetFair) 
					  + ' SettleDeterminedIBCTickets='    + convert(CHAR(1), @IsSettleAbandonedMatchIBC) 
					  + CASE WHEN (@IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1 OR @IsSettleAbandonedMatchIBC = 1) AND @HTDone = 1 THEN @ScoreLog
							 ELSE ''
						END 
					  + ' Duration=' + CAST(DATEDIFF(millisecond, @start, @stop) AS NVARCHAR(50)) + ' ms;'

		SELECT @hthomescore = hthomescore
			,@htawayscore	= htawayscore
			,@goalrecord	= goalrecord
			,@betstatus		= betstatus
		FROM DBPRO.BODB02.dbo.match WITH (NOLOCK)
		WHERE matchid = @matchid

		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle 
				@UserID				= @adminid
				,@Matchid			= @matchid
				,@ActionID			= @ActionID
				,@finalhomescore	= 0
				,@finalawayscore	= 0
				,@hthomescore		= @hthomescore
				,@htawayscore		= @htawayscore
				,@GoalRecord		= @goalrecord
				,@betstatus			= @betstatus
				,@Remark			= @Remark
				,@IP				= @IP
		END TRY

		BEGIN CATCH
			SELECT @Remark = @Remark + ' ErrMsg=' + left(ERROR_MESSAGE(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle 
				@UserID				= @adminid
				,@Matchid			= @matchid
				,@ActionID			= @ActionID
				,@finalhomescore	= 0
				,@finalawayscore	= 0
				,@hthomescore		= @hthomescore
				,@htawayscore		= @htawayscore
				,@GoalRecord		= @goalrecord
				,@betstatus			= @betstatus
				,@Remark			= @Remark
				,@IP				= @IP
		END CATCH
	END

	-----
	DELETE
	FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
	WHERE KeyID = 1 
	AND KeyValue = @matchid

	IF (@@ERROR = 0)
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @adminID
				,@Matchid	= @matchid
				,@KeyID		= 1
				,@ActionID	= @ActionID
				,@Remark	= 'DEL SUCCESS'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS ErrMsg=' + LEFT(ERROR_MESSAGE(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @adminID
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
				@UserID		= @adminID
				,@Matchid	= @matchid
				,@KeyID		= 1
				,@ActionID	= @ActionID
				,@Remark	= 'DEL FAILED'
		END TRY

		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED ErrMsg=' + LEFT(ERROR_MESSAGE(), 400)

			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @adminID
				,@Matchid	= @matchid
				,@KeyID		= 1
				,@ActionID	= @ActionID
				,@Remark	= @Remark
		END CATCH
	END
END
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_RefundFT] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_RefundFT] TO [vnteam] AS [dbo]