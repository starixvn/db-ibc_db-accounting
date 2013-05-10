
ALTER PROCEDURE [dbo].[Admin_Settlement_Refund_FGLG_xtest]
	@matchid int,
	@adminid int,
	@LGOnly bit,
	@IP varchar(15) = '',
	@IsLoopTempTable BIT = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
as

/*
	Created: VinhTruong
	Task : Refund Half-time in case there are HT tickets bet on special matches that have 3 sets
	DB: DBTRANS.bodb02
	Original: Admin_Settlement_Refund_FGLG	

	Revisions:
		- 20090113: Include the Refund FGLG for bettransm
		- 20091012@Kiwi: Remove custBetCredit
		- 20091225@Daniel: Add writelog to table Userlog_settle
		- 20100305@Daniel: Add back writelog to table Userlog
		- 20100424@Henry: Update column StatusID of Bettrans
		- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100610@Jamie: Call nested SP "Admin_Calculate_RefundFGLG"
		- 20100720@Henry: Stop using SP Logfile to write log
		- 20120411@Lukas: apply credit/debit balance table
		- 20120808@Sophia: . Add table TempVariableNumber to check if this match is being calculated then not allow to settle until the on-going process is completed
						   . Add new parametter @IsLoopTempTable to indicate this SP is nested or normal called
						   . Add @ErrCode, @ErrMsg to raise error
		- 20120930@Lukas: Put servername to control SP execution
		
	Param's Explanation:
			+ @matchid: matchid of match to Refund HT
			+ @IsLoopTempTable: 1 : is nested
								0 : Normal

*/
SET NOCOUNT ON

declare @matchdate datetime
select	@matchdate=eventdate from match where matchid=@matchid

IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
BEGIN
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
	END 
	------
	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)
	Declare @TotalAccount int, @TotalAccount_BalanceUpdate int
	BEGIN
		INSERT INTO #BalanceBefore
		SELECT custid, SUM(winlost-actual_stake+playercomm)
		FROM dbo.bettrans with (rowlock)
		WHERE matchid = @matchid AND bettype = 14
		GROUP BY custid

		SET @TotalAccount = @@ROWCOUNT
	END 
END


EXEC dbo.Admin_Calculate_RefundFGLG @matchid = @matchid, @LGOnly=@LGOnly, @matchdate=@matchdate

-------------------------------------------------------------
---         CAPTURE value BALANCE after settlement        ---
---------------------------VVVV------------------------------
IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
BEGIN

	CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)
	BEGIN
		INSERT INTO #BalanceAfter
		SELECT custid, SUM(winlost-actual_stake+playercomm)
		FROM dbo.bettrans with (rowlock)
		WHERE matchid = @matchid AND bettype = 14
		GROUP BY custid

	END --IF @SkipBalanceUpdate = 0

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
END

IF @@SERVERNAME IN ('DBTRANS','DB206')
BEGIN
	Declare @LogData nvarchar(200)
	SELECT @LogData = 'Calculate (Refund FT FGLG) for matchid:' + CAST(@matchid as nvarchar(10))
		+ case when @LGOnly = 1 then ' (LG only)' else ' (All)' end
	EXEC dbo.WriteLog_UserLog @AdminID, @LogData


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

	SELECT @Remark = 'RefundLGOnly=' + convert(char(1), @LGOnly)

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
		@UserID = @adminid,
		@Matchid = @matchid,
		@ActionID = 112,
		@finalhomescore = @finalhomescore,
		@finalawayscore = @finalawayscore,  
		@hthomescore = @hthomescore,
		@htawayscore = @htawayscore,
		@GoalRecord = @goalrecord,
		@betstatus = @betstatus,
		@Remark = @Remark,
		@IP = @IP
END
-----
IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
BEGIN
	IF @IsLoopTempTable = 0
	BEGIN
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid
	END
END


GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_Refund_FGLG] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Settlement_Refund_FGLG] TO [VNTeam]

