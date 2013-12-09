USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Admin_Settlement_s161]    Script Date: 12/9/2013 12:27:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Admin_Settlement_s161] @matchid INT
	,@IsLive BIT			= 0
	,@DrawSeq TINYINT		= 0
	,@action VARCHAR(10)	= 'CAL'		-- CAL / CAL-HT / Refund / Refund-FT
	,@IP VARCHAR(50)		= NULL
	,@AdminID INT			= 148		-- calculated by system (default)
	,@IsLoop BIT			= 0
	,@IsLoopTempTable BIT	= 0
	,@ErrCode INT			= 0 OUTPUT
	,@ErrMsg NVARCHAR(200)	= '' OUTPUT
AS
/*
	Created by:[Joe]
	Date:[20100930]
	Task: Settlement 
	DB: DBTXN/BODB02
	
	Revisions:
		- 20100930@Joe:		remove live ticket settlement, since live will automatic settle for every ball draw
		- 20101016@Viet:	Add write log
		- 20101103@Joe:		Add @IsRefundCommand
		- 20101112@Steven:	Add IP param
		- 20101124@viet:	Add refund FT and Calculate HT
		- 20101204@viet:	Add Dummy Transfer when refund FT
		- 20101217@viet:	Remove dummy transfer part
		- 20110606@Lukas:	replace update match statement by store procedure	
		- 20110620@Jamie:	Refer to BingoBall in DB02 instead of DBTRANS
		- 20110721@Victor:	Add New Bettype 88,89
		- 20120404@Joe:		add balance table
		- 20120529@Lukas:	write log maxTransID value
		- 20120626@Viet:	add new bettype 90 (number group)
		- 20120808@Sophia:	Add table TempVariableNumber to check if this match is being calculated then not allow to settle until the on-going process is completed
							Add @ErrCode, @ErrMsg to raise error
		- 20120808@Victor:	number wheel ticket all liveindicator = 1 , so don't need to settle deadball bettype 90
		- 20130103@Elodie:	Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table										
		- 20130121@Elodie:	Change link server DB02 to DBPRO
							Write more log on DBTXN server in case of DBLOG server failure
		- 20131208@Viet:	Revise SPs and arrange execrep for calculation part
						   
	Param's Explanation:
		+ @IsLoop (used for Balance):
			 1 : is recalled  
			 0 : normal						   
		+ @IsLoopTempTable (used for check temp table TempVariableNumber):			
			 1 : is recalled  
			 0 : normal		   
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @start DATETIME, @stop DATETIME
	DECLARE @LogData NVARCHAR(200), @Remark VARCHAR(500), @ActionID INT

	IF @IsLIVE = 1					SET @ActionID = 116
	ELSE IF @action = 'CAL-HT'		SET @ActionID = 118
	ELSE IF @action = 'CAL'			SET @ActionID = 115
	ELSE IF @action = 'Refund'		SET @ActionID = 117
	ELSE IF @action = 'Refund-FT'	SET @ActionID = 119

	IF @IsLoopTempTable = 0
	BEGIN
		-- check and not allow attempt to settlement same game while it's still not finish
		IF EXISTS (
				SELECT 1
				FROM dbo.TempVariableNumber WITH(NOLOCK)
				WHERE KeyID = 1 AND KeyValue = @matchid
				)
		BEGIN
			SELECT @ErrCode = 101
				,@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

			RETURN
		END

		INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue)
		VALUES (1, @matchid)

		IF (@@Error = 0)
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @AdminID
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = 'ADD SUCCESS'
			END TRY

			BEGIN CATCH
				SET @Remark = 'ADD SUCCESS ErrMsg=' + left(error_message(), 400)
				
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @AdminID
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = @Remark

			END CATCH
		END
		ELSE
		BEGIN
			SELECT @ErrCode = 100 
				,@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

			RETURN
		END
	END

	---------
	SELECT @start = CURRENT_TIMESTAMP

	DECLARE @MaxTransID BIGINT

	SELECT @MaxTransID = MAX(transid)
	FROM dbo.bettrans WITH(NOLOCK)
	WHERE matchid = @matchid

	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceBefore (custid INT PRIMARY KEY, balance MONEY)

	DECLARE @TotalAccount INT, @TotalAccount_BalanceUpdate INT

	IF @IsLoop = 0
	BEGIN
		--===
		INSERT INTO #BalanceBefore
		SELECT custid, SUM(winlost - actual_stake + playercomm)
		FROM dbo.bettrans WITH(ROWLOCK)
		WHERE matchid = @matchid AND transid <= @MaxTransID
		GROUP BY custid

		SET @TotalAccount = @@ROWCOUNT
			--===
	END

	IF @IsLIVE = 1
	BEGIN
		DECLARE @Number TINYINT

		SELECT @Number = Number
		FROM DBPRO.BODB02.dbo.BingoBall WITH(NOLOCK)
		WHERE matchid = @matchid AND seq = @DrawSeq

		EXEC dbo.Admin_PreCalculate_s161_Live @matchid = @matchid, @DrawSeq = @DrawSeq, @Number = @Number

		SET @LogData = 'Calculate Number Game for matchid:' + CAST(@matchid AS NVARCHAR(10)) + '- [LIVE] - Sequence number: (' + CAST(@DrawSeq AS NVARCHAR(2)) + ') '
		SET @ActionID = 116
		SET @Remark = 'Sequence number: (' + CAST(@DrawSeq AS NVARCHAR(2)) + ') <br />'

		IF @DrawSeq = 1 -- Cal-HT
		BEGIN
			EXEC dbo.Admin_Settlement_s161 @matchid = @matchid
				,@action = 'CAL-HT'
				,@IP = @IP
				,@AdminID = @AdminID
				,@IsLoop = 1 -- Use for recall (loop balance)
				,@IsLoopTempTable = 1 --- Use for recall (loop TempTable)
		END
	END
	ELSE IF @action = 'Refund'
	BEGIN
		EXEC DBPRO.BODB02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_s161-Refund', @Matchid = @matchid, @creator = @AdminID

		EXEC dbo.Admin_PreCalculate_s161_Refund @matchid = @matchid, @action = @action

		SET @LogData = 'REFUND Number Game for matchid:' + CAST(@matchid AS NVARCHAR(10))
		SET @ActionID = 117
	END
	ELSE IF @action = 'Refund-FT'
	BEGIN
		EXEC DBPRO.BODB02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_s161-Refund_FT', @Matchid = @matchid, @creator = @AdminID

		EXEC dbo.Admin_PreCalculate_s161_Refund @matchid = @matchid, @action = @action

		SET @LogData = 'REFUND FT Number Game for matchid:' + CAST(@matchid AS NVARCHAR(10))
		SET @ActionID = 119
	END
	ELSE IF @action = 'CAL-HT'
	BEGIN
		-- gather information for settlement
		DECLARE @1st_Ball TINYINT, @Result81 NVARCHAR(1), @Result83 NVARCHAR(1)		

		SELECT @1st_Ball = Number
		FROM DBPRO.BODB02.dbo.BingoBall WITH(NOLOCK)
		WHERE matchid = @matchid AND seq = 1

		-- PreGame winning result
		SET @Result81 = CASE WHEN @1st_Ball >= 38 THEN 'h' ELSE 'a' END
		SET @Result83 = CASE @1st_Ball % 2 WHEN 1 THEN 'h' ELSE 'a' END

		-- settle PreGame
		EXEC dbo.Admin_PreCalculate_s161_Pregame @matchid = @matchid, @bettype = 81, @betteam = @Result81, @firstball_NO = @1st_Ball
		EXEC dbo.Admin_PreCalculate_s161_Pregame @matchid = @matchid, @bettype = 83, @betteam = @Result83, @firstball_NO = @1st_Ball

		SELECT @LogData = 'Calculate HT Number Game for matchid:' + CAST(@matchid AS NVARCHAR(10))

		SELECT @ActionID = 118
	END
	ELSE IF @action = 'CAL'
	BEGIN
		-- gather information for settlement
		DECLARE @MaxSeq TINYINT
		DECLARE @LastBall TINYINT, @SecondBall TINYINT, @ThirdBall TINYINT
		DECLARE @OverBallCount TINYINT, @UnderBallCount TINYINT, @BingoBallSum INT
		DECLARE @Result82 NVARCHAR(1), @Result84 NVARCHAR(1)
		DECLARE @Result85 NVARCHAR(1), @Result86 NVARCHAR(1)
		DECLARE @Result88 NVARCHAR(1)

		-- get count of ball when bingo hit
		SELECT @MaxSeq = MAX(seq)
		FROM DBPRO.BODB02.dbo.BingoBall WITH(NOLOCK)
		WHERE matchid = @matchid

		-- first & last ball's number & SUM of ball
		SELECT @LastBall = SUM(CASE seq WHEN @MaxSeq THEN Number ELSE 0 END)
			,@OverBallCount = SUM(CASE WHEN Number >= 38 THEN 1 ELSE 0 END)
			,@UnderBallCount = SUM(CASE WHEN Number >= 38 THEN 0 ELSE 1 END)
			,@BingoBallSum = SUM(Number)
			,@SecondBall = SUM(CASE seq WHEN 2 THEN Number ELSE 0 END)
			,@ThirdBall = SUM(CASE seq WHEN 3 THEN Number ELSE 0 END)
		FROM DBPRO.BODB02.dbo.BingoBall WITH(NOLOCK)
		WHERE matchid = @matchid

		-- PreGame winning result
		SET @Result82 = CASE WHEN @LastBall >= 38 THEN 'h' ELSE 'a' END
		SET @Result84 = CASE @LastBall % 2 WHEN 1 THEN 'h' ELSE 'a' END
		SET @Result85 = CASE 
				WHEN @OverBallCount > @UnderBallCount THEN 'h' 
				WHEN @OverBallCount < @UnderBallCount THEN 'a'
				ELSE 'x' END
		SET @Result86 = CASE @BingoBallSum % 2 WHEN 1 THEN 'h' ELSE 'a' END
		SET @Result88 = CASE WHEN @SecondBall > @ThirdBall THEN 'h' ELSE 'a' END

		-- settle PreGame
		EXEC dbo.Admin_PreCalculate_s161_Pregame @matchid = @matchid, @bettype = 82, @betteam = @Result82, @firstball_NO = 0
		EXEC dbo.Admin_PreCalculate_s161_Pregame @matchid = @matchid, @bettype = 84, @betteam = @Result84, @firstball_NO = 0
		EXEC dbo.Admin_PreCalculate_s161_Pregame @matchid = @matchid, @bettype = 85, @betteam = @Result85, @firstball_NO = 0
		EXEC dbo.Admin_PreCalculate_s161_Pregame @matchid = @matchid, @bettype = 86, @betteam = @Result86, @firstball_NO = 0
		EXEC dbo.Admin_PreCalculate_s161_Pregame @matchid = @matchid, @bettype = 88, @betteam = @Result88, @firstball_NO = 0		

		EXEC DBPRO.BODB02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_s161-CAL', @Matchid = @matchid, @creator = @AdminID

		SELECT @LogData = 'Calculate Number Game for matchid:' + CAST(@matchid AS NVARCHAR(10))

		SELECT @ActionID = 115
	END

	SELECT @stop = CURRENT_TIMESTAMP

	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (custid INT PRIMARY KEY, balance MONEY)

	IF @IsLoop = 0
	BEGIN
		--===
		INSERT INTO #BalanceAfter
		SELECT custid, SUM(winlost - actual_stake + playercomm)
		FROM dbo.bettrans WITH(ROWLOCK)
		WHERE matchid = @matchid AND transid <= @MaxTransID
		GROUP BY custid
			--===
	END

	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	CREATE TABLE #Balance (custid INT PRIMARY KEY, balance MONEY, Increased BIT)

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

	DROP TABLE #Balance
	DROP TABLE #BalanceBefore
	DROP TABLE #BalanceAfter

	-------------------------------------------------------------
	---                      WRITE LOG                        ---
	---------------------------VVVV------------------------------
	-- LOG
	SET @LogData = @LogData + '(' + CAST(DATEDIFF(millisecond, @start, @stop) AS NVARCHAR(50)) + ' ms)' + ' MaxTransID: ' + CONVERT(VARCHAR(20), @MaxTransID)

	EXEC dbo.WriteLog_UserLog @UserID = @AdminID, @Doing = @LogData	

	SET @Remark = @Remark + 'Duration:' + CAST(DATEDIFF(millisecond, @start, @stop) AS NVARCHAR(50)) + ' ms - MaxTransID: ' + CONVERT(VARCHAR(20), @MaxTransID)

	BEGIN TRY		
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @AdminID
			,@Matchid = @matchid
			,@ActionID = @ActionID
			,@finalhomescore = NULL
			,@finalawayscore = NULL
			,@hthomescore = NULL
			,@htawayscore = NULL
			,@GoalRecord = NULL
			,@betstatus = NULL
			,@Remark = @Remark
			,@IP = @IP
	END TRY

	BEGIN CATCH
		SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 350)

		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @AdminID
			,@Matchid = @matchid
			,@ActionID = @ActionID
			,@finalhomescore = NULL
			,@finalawayscore = NULL
			,@hthomescore = NULL
			,@htawayscore = NULL
			,@GoalRecord = NULL
			,@betstatus = NULL
			,@Remark = @Remark
			,@IP = @IP
	END CATCH

	----
	IF @IsLoopTempTable = 0
	BEGIN
		DELETE
		FROM dbo.TempVariableNumber
		WHERE KeyID = 1 AND KeyValue = @matchid

		IF (@@Error = 0)
		BEGIN
			BEGIN TRY				
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @AdminID
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = 'DEL SUCCESS'
			END TRY

			BEGIN CATCH
				SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)
				
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @AdminID
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = @Remark
			END CATCH
		END
		ELSE
		BEGIN
			BEGIN TRY				
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @AdminID
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = 'DEL FAILED'
			END TRY

			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)
				
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @AdminID
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = @Remark
			END CATCH
		END
	END
END

