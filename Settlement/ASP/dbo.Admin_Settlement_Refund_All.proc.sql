ALTER PROCEDURE [Admin_Settlement_Refund_All]
	@matchid int,
	@creator int, 	
	@IsExcludeBetdaq bit = 0,
	@IsSettleAbandonedMatch bit = 0,
	@IsExcludeBetfair bit = 0,
	@IsSettleAbandonedMatchBetFair bit = 0,
	@hth int = NULL,
	@hta int = NULL,
	@fth int = NULL,
	@fta int = NULL,
	@betstatus nvarchar(50) = NULL,
	@Action varchar(10)='CAL',
	@IsNested BIT = 1,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
Created: Thien
Task : refund tickets 
Original: refund
DB: DBTXN/BODB02

Revisions: 
	- 20090915@KhoaTran: Exclude betdaq tickets or not
	- 20091025@PhucPham: agent MTEST0101: 1688156 (requested by Erica)
	- 20091031@Jamie: Change the name of SP - "Refund" into "Admin_Settlement_Refund_All"
	- 20091225@Daniel: Add writelog to table Userlog_settle
	- 20100305@Daniel: Add back writelog to table Userlog
	-- 20100424@Henry: Update column StatusID of Bettrans 
	-- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
	- 20100610@Jamie: Call nested SP "Admin_Calculate_Refund" 
	- 20100720@Henry: Stop using SP Logfile to write log
	- 20100825@Lukas: Update last time modify (changetime column) for match table
	- 20100916@Jamie: Update settleTime for FT Settlement 
	- 20110606@Lukas: replace update match statement by store procedure	
	- 20120215@Jamie: Settle Abandoned Match 
	- 20120314@Jamie: Allow entering scores for settlement O/U BETDAQ 
	- 20120808@Sophia: Add table TempVariableNumber to check if this match is being calculated then not allow to settle until the on-going process is completed
	- 20130103@Elodie: Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table										
	- 20130121@Elodie: Change link server DB02 to DBPRO
					   Write more log on DBTXN server in case of DBLOG server failure
	- 20130624@Jamie: Add BalanceNegative 	
	- 20131227@Kathy: Add more Betdaq's customer: BDUS016, BDUS01 [Redmine:#9765]
	- 20140106@Elodie: Option to exclude Bet Fair tickets in refund process (Redmine:#9764)
	- 20140117@Kathy: Change ErrCode value, add param @IsNested

Param's Explanation:
• @matchid: matchid need to refund
• @IsExcludeBetdaq: Is Exclude betdaq tickets or not
• @IsSettleAbandonedMatch: Is Settlement for Abandoned/postponed match or not
• @IsExcludeBetfair: Is Exclude betfair tickets or not
• @IsSettleAbandonedMatchBetFair: Is Settlement for Betfair ticket of Abandoned/postponed match or not
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

*/

SET NOCOUNT ON

-- check and not allow attempt to settlement same game while it's still not finish
IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
BEGIN
	SELECT  @ErrCode = 1000000,
			@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END
DECLARE  @Remark	VARCHAR(500)
		,@ActionID	INT
		
SELECT	@ActionID = 109 

INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)
IF (@@Error = 0)
BEGIN
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = @ActionID, 
			@Remark = 'ADD SUCCESS'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(error_message(), 400)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = @ActionID, 
			@Remark = @Remark
	END CATCH
END 
ELSE 
BEGIN
	SELECT @ErrCode = 1000000, @ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END
---

DECLARE	@start DATETIME, @stop DATETIME

SELECT	@start = CURRENT_TIMESTAMP

CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)

CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)

CREATE TABLE #Balance (custid int PRIMARY KEY, balance money, Increased bit)
CREATE INDEX IX_Balance_Increased ON #Balance (Increased)


INSERT INTO #BalanceBefore
SELECT	custid, SUM(winlost-actual_stake+playercomm)
FROM	dbo.bettrans with (rowlock)
WHERE	matchid = @matchid 
		AND bettype <> 14
GROUP BY custid

IF @IsSettleAbandonedMatch = 1 SELECT @IsExcludeBetdaq = 1
IF @IsSettleAbandonedMatchBetFair = 1 SELECT @IsExcludeBetfair = 1

/*
		Settle Betdaq, Betfair tickets Abandoned Match for Over/Under 
*/
IF @IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1
BEGIN 
	DECLARE	@ScoreLog VARCHAR(100)

	DECLARE	@sporttype tinyint

	SELECT	@sporttype = SportType
	FROM	DBPRO.BODB02.dbo.Match with (nolock) 
	WHERE	matchid = @matchid
	
	SELECT	@ScoreLog = ' HTHScore=' + CAST(@hth AS VARCHAR(10))
						+ ' HTAScore=' + CAST(@hta AS VARCHAR(10))
						+ ' FTHScore=' + CAST(@fth AS VARCHAR(10))
						+ ' FTAScore=' + CAST(@fta AS VARCHAR(10))
						+ ' Betstatus=' + @betstatus

	DECLARE @TennisTotal smallint, @T_Home smallint, @T_Away smallint
	IF @SportType IN (5, 6, 9, 30) -- Tennis/VolleyBall/Badminton/Squash : get TotalGamesPlayed
		EXEC dbo.Admin_Settlement_2
			@betstatus = @betstatus,
			@Total =  @TennisTotal OUTPUT,
			@TotalHome = @T_Home OUTPUT,
			@TotalAway = @T_Away OUTPUT

	DECLARE @totalgoal smallmoney, @totalht smallmoney

	SELECT	@totalgoal	= CASE WHEN @sporttype IN (5, 6, 9, 30) and @TennisTotal > 0 THEN @TennisTotal ELSE (@fth + @fta) END,
			@totalht	= (@hth + @hta)
			
	IF @Action IN ('CAL','CAL-FT') AND @totalgoal IS NULL 
	BEGIN
		SELECT	@ErrCode = 1000004
				,@ErrMsg = 'Cannot settle determined ticket(s) without FT Score!'
				
		-----
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid  
		IF (@@Error = 0)
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @creator, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = @ActionID, 
					@Remark = 'DEL SUCCESS'
			END TRY  
			BEGIN CATCH	
				SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)	
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @creator, 
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
					@UserID = @creator, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = @ActionID, 
					@Remark = 'DEL FAILED'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)	
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @creator, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = @ActionID, 
					@Remark = @Remark
			END CATCH
		END
			
		RETURN
	END

	IF @Action IN ('CAL','CAL-HT') AND @totalht IS NULL 
	BEGIN
		SELECT	@ErrCode = 1000005
				,@ErrMsg = 'Cannot settle determined ticket(s) without HT Score!'
		
		-----
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid  
		IF (@@Error = 0)
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @creator, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = @ActionID, 
					@Remark = 'DEL SUCCESS'			
			END TRY  
			BEGIN CATCH	
				SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)	
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @creator, 
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
					@UserID = @creator, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = @ActionID, 
					@Remark = 'DEL FAILED'
			END TRY			
			BEGIN CATCH	
				SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)	
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @creator, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = @ActionID, 
					@Remark = @Remark
			END CATCH
		END
		RETURN
	END
 	 
	DECLARE @betcount_3 int, @betcount_8 int
	
	SELECT	@betcount_3 = ISNULL(SUM(case bettype when 3 then 1 else 0 end), 0),
			@betcount_8 = ISNULL(SUM(case bettype when 8 then 1 else 0 end), 0)
	FROM	bettrans WITH(NOLOCK) 
	WHERE	matchid = @matchid
			AND bettype in (3,8)
			AND 1 = CASE WHEN @IsSettleAbandonedMatch = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) or recommend = 1688156) THEN 1
						 WHEN @IsSettleAbandonedMatchBetFair = 1 AND custid IN (2331, 1077687, 115770) THEN 1
					ELSE 0 END
			AND statusID NOT IN (101, 102)

	IF @Action IN ('CAL','CAL-FT')
	BEGIN
		EXEC dbo.Admin_Calculate_3 @matchid = @matchid, @bettype = 3, @totalgoal = @totalgoal, @betcount = @betcount_3, @IsSettleAbandonedMatch = @IsSettleAbandonedMatch, @IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
	END

	IF @Action IN ('CAL','CAL-HT')
	BEGIN
		EXEC dbo.Admin_Calculate_8 @matchid = @matchid, @bettype = 8, @totalht = @totalht, @betcount = @betcount_8, @IsSettleAbandonedMatch = @IsSettleAbandonedMatch, @IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
	END	
END
/* --- END Settle Betdaq, Betfair tickets Abandoned Match for Over/Under  ---*/

EXEC DBPRO.BODB02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_Refund_All', @MatchID = @matchid, @creator = @creator

EXEC dbo.Admin_Calculate_RefundAll @matchid = @matchid, @IsExcludeBetdaq = @IsExcludeBetdaq, @IsExcludeBetfair = @IsExcludeBetfair

INSERT INTO #BalanceAfter	
SELECT	custid, SUM(winlost-actual_stake+playercomm)
FROM	dbo.bettrans with (rowlock)
WHERE	matchid = @matchid 
		AND bettype <> 14
GROUP BY custid


INSERT INTO #Balance
SELECT b.custid, a.balance - b.balance, CASE WHEN a.balance > b.balance THEN 1 ELSE 0 END
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
		,1			-- Sportsbook Single bet Settlement 
		,CustID
		,Balance
		,0
		,NULL 
FROM	#Balance WITH (NOLOCK)
WHERE	Increased = 0
		        
---------------------------------------------------


DROP TABLE #Balance
DROP TABLE #BalanceBefore
DROP TABLE #BalanceAfter

----------------------------------------------



SELECT	@stop = CURRENT_TIMESTAMP

Declare @LogData nvarchar(200)
SELECT @LogData = 'Calculate (Refund All) for matchid:' + CAST(@matchid as nvarchar(10))
+ CASE WHEN @IsExcludeBetdaq = 1 THEN  ', Exclude Betdaq tickets' ELSE '' END
+ CASE WHEN @IsSettleAbandonedMatch = 1 THEN ', Settle determined betdaq tickets' ELSE '' END
+ CASE WHEN @IsExcludeBetfair = 1 THEN  ', Exclude Betfair tickets' ELSE '' END
+ CASE WHEN @IsSettleAbandonedMatchBetFair = 1 THEN ', Settle determined betfair tickets' ELSE '' END

EXEC dbo.WriteLog_UserLog @creator, @LogData

--Write Log Settle
SELECT @Remark = 'ExcludeBetdaqTickets=' + convert(char(1),@IsExcludeBetdaq) 
					+ ' SettleDeterminedBetdaqTickets=' + convert(char(1),@IsSettleAbandonedMatch)
					+ CASE WHEN @IsSettleAbandonedMatch = 1 THEN ' Action=' + @Action ELSE '' END
					+ CASE WHEN @IsSettleAbandonedMatch = 1 THEN @ScoreLog ELSE '' END
					+ ' ExcludeBetfairTickets=' + convert(char(1),@IsExcludeBetfair) 
					+ ' SettleDeterminedBetfairTickets=' + convert(char(1),@IsSettleAbandonedMatchBetFair)
					+ CASE WHEN @IsSettleAbandonedMatchBetFair = 1 THEN ' Action=' + @Action ELSE '' END
					+ CASE WHEN @IsSettleAbandonedMatchBetFair = 1 THEN @ScoreLog ELSE '' END
					+ ' Duration=' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms;'
BEGIN TRY					
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
		@UserID = @creator,
		@Matchid = @matchid,
		@ActionID = @ActionID,
		@finalhomescore = 0,
		@finalawayscore = 0,  
		@hthomescore = 0,
		@htawayscore = 0,
		@GoalRecord = '',
		@betstatus = 'Refund',
		@Remark = @Remark,
		@IP = @IP
END TRY
BEGIN CATCH
	SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 250)	
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
		@UserID = @creator,
		@Matchid = @matchid,
		@ActionID = @ActionID,
		@finalhomescore = 0,
		@finalawayscore = 0,  
		@hthomescore = 0,
		@htawayscore = 0,
		@GoalRecord = '',
		@betstatus = 'Refund',
		@Remark = @Remark,
		@IP = @IP
END CATCH


-----
DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
WHERE KeyID = 1 AND KeyValue = @matchid    
IF (@@Error = 0)
BEGIN
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = @ActionID, 
			@Remark = 'DEL SUCCESS'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 350)	
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @creator, 
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
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = @ActionID, 
			@Remark = 'DEL FAILED'
	END TRY
	BEGIN CATCH		
		SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 350)	
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = @ActionID, 
			@Remark = @Remark
	END CATCH
END

IF @IsNested = 0
BEGIN
	-- Update match_remark
	EXEC DBPRO.BODB02.dbo.updateMatch_remark @matchid, 'F'

	-- Write log
	DECLARE @log varchar(200)
	set @log = 'Refund for matchid: ' + CONVERT(varchar(10), @matchid)

	EXEC dbo.WriteLog_UserLog @creator, @Log
END 

GO
GRANT EXECUTE ON [Admin_Settlement_Refund_All] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [Admin_Settlement_Refund_All] TO [Dot_Member] AS [dbo]
GO
GRANT VIEW DEFINITION ON [Admin_Settlement_Refund_All] TO [vnteam] AS [dbo]
GO


