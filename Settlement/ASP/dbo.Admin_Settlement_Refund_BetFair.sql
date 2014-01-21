ALTER PROCEDURE [Admin_Settlement_Refund_BetFair]
	@matchid int,
	@creator int, 	
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
Created: Elodie 
Task : Refund Running BetFair
Original: 
DB: DBTXN/BODB02

Revisions: 
	- 20140117@Kathy: Change ErrCode value

Param's Explanation:
• @matchid: matchid need to refund
• @IsExcludeBetfair: Is Exclude betdaq tickets or not
• @IsSettleAbandonedMatchBetFair: Is Settlement for Abandoned/postponed match or not
BetFair account: 
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
DECLARE @Remark VARCHAR(500)
		,@ActionID	INT
		
SELECT	@ActionID = 135
 
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
WHERE	custid IN (2331, 1077687)
		AND matchid = @matchid
		AND bettype <> 14 --Exclude FGLG 
GROUP BY custid

EXEC dbo.Admin_Calculate_Refund_BetFair @matchid = @matchid 

INSERT INTO #BalanceAfter	
SELECT	custid, SUM(winlost-actual_stake+playercomm)
FROM	dbo.bettrans with (rowlock)
WHERE	custid IN (2331, 1077687)
		AND matchid = @matchid
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

----------------------------------------------------

SELECT	@stop = CURRENT_TIMESTAMP

Declare @LogData nvarchar(200)
SELECT @LogData = 'Calculate (Refund Running BetFair) for matchid:' + CAST(@matchid as nvarchar(10))
EXEC dbo.WriteLog_UserLog @creator, @LogData

--Write Log Settle
DECLARE 
	@finalhomescore INT, @finalawayscore INT,
	@hthomescore INT, @htawayscore INT,
	@goalrecord varchar(50), @betstatus nvarchar(50)
SELECT 
	@finalhomescore = finalhomescore,
	@finalawayscore = finalawayscore,
	@hthomescore = hthomescore, 
	@htawayscore = htawayscore,
	@goalrecord = goalrecord,
	@betstatus = betstatus
 FROM dbo.match WITH(NOLOCK) WHERE matchid = @matchid

SELECT @Remark ='Duration=' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms;'

BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
		@UserID = @creator,
		@Matchid = @matchid,
		@ActionID = @ActionID,
		@finalhomescore = @finalhomescore,
		@finalawayscore = @finalawayscore,  
		@hthomescore = @hthomescore,
		@htawayscore = @htawayscore,
		@GoalRecord =@GoalRecord,
		@betstatus = @betstatus,
		@Remark = @Remark,
		@IP = @IP
END TRY
BEGIN CATCH
	SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 350)	
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
		@UserID = @creator,
		@Matchid = @matchid,
		@ActionID = @ActionID,
		@finalhomescore = @finalhomescore,
		@finalawayscore = @finalawayscore,  
		@hthomescore = @hthomescore,
		@htawayscore = @htawayscore,
		@GoalRecord =@GoalRecord,
		@betstatus = @betstatus,
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


GO

GRANT EXECUTE ON [Admin_Settlement_Refund_BetFair] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [Admin_Settlement_Refund_BetFair] TO [vnteam] AS [dbo]
GO


