
ALTER PROCEDURE [dbo].[Admin_Settlement_Refund_BetDaq_xtest]
	@matchid int,
	@creator int, 	
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
	Created: Jamie 
	Task : Refund Running BetDaq 
	Original: 
	DB: DBTRANS.bodb02

	Revisions: 
		- 20120808@Sophia: . Add table TempVariableNumber to check if this match is being calculated then not allow to settle until the on-going process is completed
						   . Add @ErrCode, @ErrMsg to raise error
		- 20120930@Lukas: Put servername to control SP execution
		
	Param's Explanation:
	• @matchid: matchid need to refund
	• @IsExcludeBetdaq: Is Exclude betdaq tickets or not
	• @IsSettleAbandonedMatch: Is Settlement for Abandoned/postponed match or not
	BetDaq account: 
				BQUS888:50057
				BQUSMLB:879241
				BQUSNBA:103873 
*/

SET NOCOUNT ON

DECLARE	@start DATETIME, @stop DATETIME
SELECT	@start = CURRENT_TIMESTAMP

IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
BEGIN
	-- check and not allow attempt to settlement same game while it's still not finish
	IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END

	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)

	---



	CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)

	CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)

	CREATE TABLE #Balance (custid int PRIMARY KEY, balance money, Increased bit)
	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)


	INSERT INTO #BalanceBefore
	SELECT	custid, SUM(winlost-actual_stake+playercomm)
	FROM	dbo.bettrans with (rowlock)
	WHERE 
			(	custid IN (50057, 879241, 103873, 78761, 1077687) 
				OR recommend = 1688156	)
			AND matchid = @matchid
			AND bettype <> 14 --Exclude FGLG 
	GROUP BY custid
END

EXEC dbo.Admin_Calculate_Refund_BetDaq @matchid = @matchid 

IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
BEGIN
	INSERT INTO #BalanceAfter	
	SELECT	custid, SUM(winlost-actual_stake+playercomm)
	FROM	dbo.bettrans with (rowlock)
	WHERE 
			(	custid IN (50057, 879241, 103873, 78761, 1077687) 
				OR recommend = 1688156	)
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

	DROP TABLE #Balance
	DROP TABLE #BalanceBefore
	DROP TABLE #BalanceAfter
END

SELECT	@stop = CURRENT_TIMESTAMP

IF @@SERVERNAME IN ('DBTRANS','DB206')
BEGIN
	Declare @LogData nvarchar(200)
	SELECT @LogData = 'Calculate (Refund Running BetDaq) for matchid:' + CAST(@matchid as nvarchar(10))
	EXEC dbo.WriteLog_UserLog @creator, @LogData

	--Write Log Settle
	DECLARE 
		@finalhomescore INT, @finalawayscore INT,
		@hthomescore INT, @htawayscore INT,
		@goalrecord varchar(50), @betstatus nvarchar(50), @Remark varchar(50)
	SELECT 
		@finalhomescore = finalhomescore,
		@finalawayscore = finalawayscore,
		@hthomescore = hthomescore, 
		@htawayscore = htawayscore,
		@goalrecord = goalrecord,
		@betstatus = betstatus
	 FROM dbo.match WITH(NOLOCK) WHERE matchid = @matchid

	SELECT @Remark ='Duration=' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms;'

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
		@UserID = @creator,
		@Matchid = @matchid,
		@ActionID = 126,
		@finalhomescore = @finalhomescore,
		@finalawayscore = @finalawayscore,  
		@hthomescore = @hthomescore,
		@htawayscore = @htawayscore,
		@GoalRecord =@GoalRecord,
		@betstatus = @betstatus,
		@Remark = @Remark,
		@IP = @IP
END    
  
-----
IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid   



GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_Refund_BetDaq] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Settlement_Refund_BetDaq] TO [vnteam]