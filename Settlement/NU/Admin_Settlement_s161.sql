ALTER PROCEDURE [dbo].[Admin_Settlement_s161]
	@matchid int,
	@IsLive bit = 0,
	@DrawSeq tinyint = 0,
	@action varchar(10) = 'CAL', -- CAL / CAL-HT / Refund / Refund-FT
	@IP varchar(50) = NULL,
	@AdminID int = 148, -- calculated by system (default)
	@IsLoop bit = 0,
	@IsLoopTempTable BIT = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created by:[Joe]
	Date:[20100930]
	Task: Settlement 
	DB: DBTXN/BODB02
	
	Revisions:
		- 20100930@Joe: remove live ticket settlement, since live will automatic settle for every ball draw
		- 20101016@Viet: Add write log
		- 20101103@Joe : Add @IsRefundCommand
		- 20101112@Steven: Add IP param
		- 20101124@viet: Add refund FT and Calculate HT
		- 20101204@viet: Add Dummy Transfer when refund FT
		- 20101217@viet: Remove dummy transfer part
		- 20110606@Lukas: replace update match statement by store procedure	
		- 20110620@Jamie: Refer to BingoBall in DB02 instead of DBTRANS
		- 20110721@Victor: Add New Bettype 88,89
		- 20120404@Joe: add balance table
		- 20120529@Lukas: write log maxTransID value
		- 20120626@Viet: add new bettype 90 (number group)
		- 20120808@Sophia: . Add table TempVariableNumber to check if this match is being calculated then not allow to settle until the on-going process is completed
						   . Add @ErrCode, @ErrMsg to raise error
		- 20120808@Victor: number wheel ticket all liveindicator = 1 , so don't need to settle deadball bettype 90
		- 20130103@Elodie: Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table										
		- 20130121@Elodie: Change link server DB02 to DBPRO
						   Write more log on DBTXN server in case of DBLOG server failure
						   
	Param's Explanation:
	. @IsLoop (used for Balance):
			 1 : is recalled  
			 0 : normal						   
	. @IsLoopTempTable (used for check temp table TempVariableNumber):			
			 1 : is recalled  
			 0 : normal		   
	
*/
SET NOCOUNT ON

Declare @start datetime, @stop datetime
Declare @LogData nvarchar(200), @Remark varchar(500), @ActionID int

IF @IsLIVE = 1
	SELECT @ActionID = 116
ELSE IF @action = 'CAL-HT'
	SELECT @ActionID = 118
ELSE IF @action = 'CAL'
	SELECT @ActionID = 115
ELSE IF @action = 'Refund'
	SELECT @ActionID = 117
ELSE IF @action = 'Refund-FT'
	SELECT @ActionID = 119
	
IF @IsLoopTempTable = 0
BEGIN
	-- check and not allow attempt to settlement same game while it's still not finish
	IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END
		
	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)
	IF (@@Error = 0)
	BEGIN
		BEGIN TRY		
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @AdminID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = @ActionID, 
				@Remark = 'ADD SUCCESS'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @AdminID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = @ActionID, 
				@Remark = @Remark
		END CATCH
	END
	ELSE 
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END
END
---------

SELECT @start = CURRENT_TIMESTAMP

Declare @MaxTransID bigint
SELECT @MaxTransID = max(transid)
FROM dbo.bettrans with (nolock)
WHERE matchid = @matchid

-------------------------------------------------------------
---        CAPTURE value BALANCE before settlement        ---
---------------------------VVVV------------------------------
CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)
Declare @TotalAccount int, @TotalAccount_BalanceUpdate int

IF @IsLoop = 0
BEGIN
--===
	INSERT INTO #BalanceBefore
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid AND transid <= @MaxTransID
	GROUP BY custid

	SET @TotalAccount = @@ROWCOUNT
--===
END


IF @IsLIVE = 1
BEGIN
	Declare @Number tinyint
	SELECT @Number = Number
	FROM DBPRO.BODB02.dbo.BingoBall with (nolock)
	WHERE matchid = @matchid AND seq = @DrawSeq 

		EXEC dbo.Admin_Calculate_s161_Live @matchid, @DrawSeq, @Number
	
	SELECT @LogData = 'Calculate Number Game for matchid:' + CAST(@matchid as nvarchar(10)) 
	+ '- [LIVE] - Sequence number: (' + CAST(@DrawSeq as nvarchar(2)) + ') '
	SELECT @ActionID = 116, @Remark = 'Sequence number: (' + CAST(@DrawSeq as nvarchar(2)) + ') <br />'
	
	IF @DrawSeq = 1 -- Cal-HT
	BEGIN
		
		EXEC dbo.Admin_Settlement_s161 
			@matchid = @matchid,
			@action = 'CAL-HT',
			@IP = @IP,
			@AdminID = @AdminID,
			@IsLoop = 1,  --- Use for recall (loop balance)
			@IsLoopTempTable = 1  --- Use for recall (loop TempTable)
	
	END 
			
END
ELSE IF @action = 'Refund'
BEGIN
	
	EXEC DBPRO.BODB02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_s161-Refund', @Matchid = @matchid, @creator = @AdminID
	
	EXEC dbo.[Admin_Calculate_s161_Refund] @matchid, @action
	
	SELECT @LogData = 'REFUND Number Game for matchid:' + CAST(@matchid as nvarchar(10))
	SELECT @ActionID = 117
	
END
ELSE IF @action = 'Refund-FT'
BEGIN
	
	EXEC DBPRO.BODB02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_s161-Refund_FT', @Matchid = @matchid, @creator = @AdminID
	
	EXEC dbo.[Admin_Calculate_s161_Refund] @matchid, @action
	
	SELECT @LogData = 'REFUND FT Number Game for matchid:' + CAST(@matchid as nvarchar(10))
	SELECT @ActionID = 119
END
ELSE IF @action = 'CAL-HT'
BEGIN
	-- gather information for settlement
	Declare @1st_Ball tinyint
	Declare @Result81 nvarchar(1), @Result83 nvarchar(1)

	SELECT	@1st_Ball = Number
	FROM	DBPRO.BODB02.dbo.BingoBall WITH (NOLOCK)
	WHERE	matchid = @matchid
			AND seq = 1

	-- PreGame winning result
	SELECT
		@Result81 = CASE WHEN @1st_Ball >= 38 THEN 'h' ELSE 'a' END,
		@Result83 = CASE @1st_Ball %2 WHEN 1 THEN 'h' ELSE 'a' END

	-- settle PreGame
		EXEC dbo.Admin_Calculate_s161_Pregame @matchid, 81, @Result81, @1st_Ball
		EXEC dbo.Admin_Calculate_s161_Pregame @matchid, 83, @Result83, @1st_Ball
		--EXEC dbo.Admin_Calculate_s161_Pregame @matchid, 90, '', @1st_Ball
		
	
	SELECT @LogData = 'Calculate HT Number Game for matchid:' + CAST(@matchid as nvarchar(10))
	SELECT @ActionID = 118

END
ELSE IF @action = 'CAL'
BEGIN

	-- gather information for settlement
	Declare @MaxSeq tinyint
	Declare @LastBall tinyint, @SecondBall tinyint, @ThirdBall tinyint
	Declare @OverBallCount tinyint, @UnderBallCount tinyint, @BingoBallSum int

	Declare @Result82 nvarchar(1), @Result84 nvarchar(1)
	Declare @Result85 nvarchar(1), @Result86 nvarchar(1)
	Declare @Result88 nvarchar(1)

	-- get count of ball when bingo hit
	SELECT	@MaxSeq = MAX(seq)
	FROM	DBPRO.BODB02.dbo.BingoBall
	WHERE matchid = @matchid

	-- first & last ball's number & SUM of ball
	SELECT		
			@LastBall = SUM(CASE seq WHEN @MaxSeq THEN Number ELSE 0 END),
			@OverBallCount  = SUM(CASE WHEN Number >= 38 THEN 1 ELSE 0 END),
			@UnderBallCount = SUM(CASE WHEN Number >= 38 THEN 0 ELSE 1 END),
			@BingoBallSum = SUM(Number),
			@SecondBall = SUM(CASE seq WHEN 2 THEN Number ELSE 0 END),
			@ThirdBall = SUM(CASE seq WHEN 3 THEN Number ELSE 0 END)
	FROM	DBPRO.BODB02.dbo.BingoBall
	WHERE	matchid = @matchid

	-- PreGame winning result
	SELECT		
		@Result82 = CASE WHEN @LastBall >= 38 THEN 'h' ELSE 'a' END,
		@Result84 = CASE @LastBall %2 WHEN 1 THEN 'h' ELSE 'a' END,
		@Result85 = CASE
				WHEN @OverBallCount > @UnderBallCount THEN 'h'
				WHEN @OverBallCount < @UnderBallCount THEN 'a'
				ELSE 'x' END,
		@Result86 = CASE @BingoBallSum %2 WHEN 1 THEN 'h' ELSE 'a' END,
		@Result88 = CASE WHEN @SecondBall > @ThirdBall THEN 'h' ELSE 'a' END

	-- settle PreGame
		EXEC dbo.Admin_Calculate_s161_Pregame @matchid, 82, @Result82, 0
		EXEC dbo.Admin_Calculate_s161_Pregame @matchid, 84, @Result84, 0
		EXEC dbo.Admin_Calculate_s161_Pregame @matchid, 85, @Result85, 0
		EXEC dbo.Admin_Calculate_s161_Pregame @matchid, 86, @Result86, 0
		EXEC dbo.Admin_Calculate_s161_Pregame @matchid, 88, @Result88, 0

	EXEC DBPRO.BODB02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_s161-CAL', @Matchid = @matchid, @creator = @AdminID
	
	SELECT @LogData = 'Calculate Number Game for matchid:' + CAST(@matchid as nvarchar(10))
	SELECT @ActionID = 115

END

SELECT @stop = CURRENT_TIMESTAMP



-------------------------------------------------------------
---         CAPTURE value BALANCE after settlement        ---
---------------------------VVVV------------------------------
CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)
IF @IsLoop = 0
BEGIN
--===
	INSERT INTO #BalanceAfter
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid AND transid <= @MaxTransID
	GROUP BY custid
--===
END

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

DROP TABLE #Balance
DROP TABLE #BalanceBefore
DROP TABLE #BalanceAfter


-------------------------------------------------------------
---                      WRITE LOG                        ---
---------------------------VVVV------------------------------

-- LOG
SELECT @LogData = @LogData + '(' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms)' + ' MaxTransID: ' + CONVERT(VARCHAR(20),@MaxTransID)
EXEC dbo.WriteLog_UserLog @AdminID, @LogData

SELECT @Remark = @Remark + 'Duration:' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms - MaxTransID: ' + CONVERT(VARCHAR(20),@MaxTransID)

BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
		@UserID = @AdminID,
		@Matchid = @matchid,
		@ActionID = @ActionID,
		@finalhomescore = NULL,
		@finalawayscore = NULL,  
		@hthomescore = NULL,
		@htawayscore = NULL,
		@GoalRecord = NULL,
		@betstatus = NULL,
		@Remark = @Remark,
		@IP = @IP
END TRY
BEGIN CATCH
	SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 350)
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
		@UserID = @AdminID,
		@Matchid = @matchid,
		@ActionID = @ActionID,
		@finalhomescore = NULL,
		@finalawayscore = NULL,  
		@hthomescore = NULL,
		@htawayscore = NULL,
		@GoalRecord = NULL,
		@betstatus = NULL,
		@Remark = @Remark,
		@IP = @IP
END CATCH
    
----
IF @IsLoopTempTable = 0
BEGIN
	DELETE FROM dbo.TempVariableNumber  WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid
	IF (@@Error = 0)
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @AdminID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = @ActionID, 
				@Remark = 'DEL SUCCESS'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @AdminID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = @ActionID, 
				@Remark = @Remark
		END CATCH
	END
	ELSE
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @AdminID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = @ActionID,
				@Remark = 'DEL FAILED'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @AdminID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = @ActionID,
				@Remark = @Remark
		END CATCH		
	END
END