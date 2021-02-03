/*<info serverAlias="DBBAH-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Acc_BalanceHistory_Mem
(
	@FromDate DATETIME,
	@Todate DATETIME,
	@UserName VARCHAR(30) = '',
	@ErrorCode INT = 0 OUTPUT,
	@ErrorMess VARchar(1000) = '' OUTPUT
)
AS
/*
	Created: Sol@20210126  
	Task: 130293 - LAP - Detail Transaction Member
	DB: DBBAH/bodb02
	Revisions:  
		- 20210126@Sol: Initialize sp - [RedmineID: #144546] 
	
*/
BEGIN

	DECLARE 
		@MoveBetsDay	SMALLDATETIME, 
		@BalanceUpDay	SMALLDATETIME,
		@InternalFromDate DATETIME,
		@InternalToDate DATETIME,
		@CustId INT = 0,
		@OldCreditFirstTimes MONEY,
		@OldActionDateFirstTimes DATETIME

	DECLARE @tmp TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME) 

	SELECT @CustId = custId 
	FROM dbo.Customer c WITH(NOLOCK)
	WHERE c.username = @UserName AND c.roleid = 1

	--validate user
	IF (@CustId IS NULL OR @CustId = 0)
	BEGIN
		SELECT @ErrorCode = 101, @ErrorMess = 'Invalid member'
		RETURN
	END

	INSERT INTO @tmp(BalanceUpDay, MoveBetsDay)
	EXEC Age_SelBalanceUpDay

	SELECT @MoveBetsDay = MoveBetsDay, @BalanceUpDay = BalanceUpDay FROM @tmp
	SELECT @InternalFromDate = @FromDate, @InternalToDate = DATEADD(DAY, 1, @Todate)

	CREATE TABLE #BalanceRecord(ActionDate DATETIME, winlostdate SMALLDATETIME, refNo BIGINT, actual_stake MONEY, winloss MONEY, playercomm MONEY, BalanceChanged MONEY, NewBalance MONEY, GivenCredit MONEY, BetCredit MONEY, Action VARCHAR(256), custid INT, ActionID TINYINT, rowid BIGINT)
	CREATE TABLE #Transaction(transID BIGINT, custID INT, winlostdate SMALLDATETIME)

	IF EXISTS (SELECT top 1 1 from dbo.Customer c WITH(NOLOCK) WHERE c.creatdate > @InternalToDate AND c.custid = @CustId AND c.roleid = 1)
	BEGIN

		SELECT 
			t.ActionDate, t.winlostdate, t.refNo, t.actual_stake, t.winloss, t.playercomm, t.BalanceChanged, t.NewBalance, t.GivenCredit, t.BetCredit, t.Action
		FROM #BalanceRecord t
		
		DROP TABLE #Transaction
		DROP TABLE #BalanceRecord

	END
	ELSE
	BEGIN

		--- get infor from userlog_credit
		SELECT u.ActionID, l.ActionNameEN, u.logid, u.custid, u.logdate, u.OldValue, u.NewValue 
			INTO #LogCredit 
		FROM DBLog.bodb_CustomerLog.dbo.UserLog_Credit u WITH(NOLOCK)
			INNER JOIN DBLog.bodb_CustomerLog.dbo.LogAction l WITH(NOLOCK)
				ON u.ActionID = l.ActionID
		WHERE 
			u.custid = @CustId
			AND u.logdate >= @InternalFromDate

		IF NOT EXISTS (SELECT TOP 1 1 FROM #LogCredit)
		BEGIN
			SELECT @OldCreditFirstTimes = c.credit, @OldActionDateFirstTimes = @InternalFromDate
			FROM dbo.custInfo c WITH(NOLOCK) 
			WHERE c.custid = @CustId AND c.roleid = 1
		END
		ELSE 
		BEGIN
			SELECT TOP 1 
				@OldCreditFirstTimes = ISNULL(l.OldValue, l.newvalue), 
				@OldActionDateFirstTimes = CASE WHEN l.OldValue IS NULL THEN l.logdate ELSE @InternalFromDate END
			FROM #LogCredit l
			ORDER BY logdate
		END

		--- insert to temp table balance record
		;WITH rs AS
		(
			SELECT 
				ActionDate, 
				NULL winlostdate, 
				b.transid AS refNo, 
				b.actual_stake, 
				b.winlost,
				b.playercomm, 
				b.BalanceChanged, 
				b.NewBalance,
				b.Action, 
				b.custid, b.ActionID, b.RowID
			FROM dbo.BalanceRecord b WITH(NOLOCK)
			WHERE 
				b.custid = @CustId
				AND b.ActionDate BETWEEN @InternalFromDate AND @InternalToDate
				AND b.Actionid <> 33
			UNION
			SELECT 
				ActionDate, 
				NULL winlostdate, 
				b.transid AS refNo, 
				b.actual_stake, 
				b.winlost,
				b.playercomm, 
				b.BalanceChanged, 
				b.NewBalance,
				b.Action, 
				b.custid, b.ActionID, b.RowID
			FROM BalanceRecord.dbo.BalanceRecord_bk b WITH(NOLOCK)
			WHERE 
				b.custid = @CustId
				AND b.ActionDate BETWEEN @InternalFromDate AND @InternalToDate
				AND b.Actionid <> 33
		)
		INSERT INTO #BalanceRecord(ActionDate, winlostdate, refNo, actual_stake, winloss, playercomm, BalanceChanged, NewBalance, GivenCredit, BetCredit, Action, custid, ActionID, rowid)
		SELECT 
			COALESCE(ActionDate, l.logdate) ActionDate, 
			NULL winlostdate, 
			b.refNo, 
			b.actual_stake, 
			b.winlost,
			b.playercomm, 
			b.BalanceChanged, 
			b.NewBalance,
			COALESCE(l.NewValue, lo.NewValue, @OldCreditFirstTimes, 0) GivenCredit,
			(b.NewBalance + COALESCE(l.NewValue, lo.NewValue, @OldCreditFirstTimes, 0)) AS BetCredit,
			COALESCE(Action, l.ActionNameEN) AS Action, 
			COALESCE(b.custid, l.custid) AS custid, b.ActionID, b.RowID
		FROM rs b WITH(NOLOCK)
			FULL JOIN 
			(
				SELECT ActionID, ActionNameEN, logid, custid, logdate, OldValue, NewValue 
				FROM #LogCredit l 
			) l ON l.logdate = b.ActionDate AND l.ActionID = b.ActionID AND l.custid = b.custid
			OUTER APPLY 
			(
				SELECT TOP 1 ActionID, ActionNameEN, logid, custid, logdate, OldValue, NewValue 
				FROM #LogCredit lo
				WHERE lo.logdate < b.ActionDate AND lo.custid = b.custid
				ORDER BY lo.logdate DESC
			) lo 

		--###############################################################
		-- curr data
		IF (@InternalFromDate > @MoveBetsDay)
		BEGIN
			-- bettrans
			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.bettrans b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.transid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)
	
			-- bettransRNG
			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.bettransRNG b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.transid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)

			-- bettransLC
			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.bettransLC b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.transid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)

			-- translog
			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.translog b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.translogid
				INNER JOIN dbo.bettrans bt WITH(NOLOCK)
					ON b.translogid = bt.refno AND b.custid = bt.custid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)
	

		END
		ELSE IF (@InternalFromDate >= @BalanceUpDay AND @InternalToDate <= @MoveBetsDay) -- only bettrans14
		BEGIN
	
			-- bettrans
			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.bettrans14 b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.transid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)
	
			-- bettransRNG
			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.bettransRNG14 b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.transid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)

			-- bettransLC
			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.bettransLC14 b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.transid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)

			-- translog
			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.translog14 b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.translogid
				INNER JOIN dbo.bettrans14 bt WITH(NOLOCK)
					ON b.translogid = bt.refno AND b.custid = bt.custid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)

		END
		ELSE IF (@InternalFromDate >= @BalanceUpDay AND @InternalFromDate <= @MoveBetsDay AND @InternalToDate > @MoveBetsDay) -- bettrans14 and bettrans
		BEGIN

			-- bettrans
			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.bettrans b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.transid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)

			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.bettrans14 b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.transid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)
	
			-- bettransRNG
			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.bettransRNG b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.transid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)

			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.bettransRNG14 b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.transid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)

			-- bettransLC
			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.bettransLC b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.transid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)

			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.bettransLC14 b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.transid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)

			-- translog
			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.translog b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.translogid
				INNER JOIN dbo.bettrans bt WITH(NOLOCK)
					ON b.translogid = bt.refno AND b.custid = bt.custid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)

			INSERT INTO #Transaction(transID, custID, winlostdate)
			SELECT br.refNo, br.custID, b.winlostdate
			FROM #BalanceRecord br
				INNER JOIN dbo.translog14 b WITH(NOLOCK)
					ON br.custid = b.custid AND br.refNo = b.translogid
				INNER JOIN dbo.bettrans14 bt WITH(NOLOCK)
					ON b.translogid = bt.refno AND b.custid = bt.custid
			WHERE br.refNo NOT IN (SELECT transid FROM #Transaction)

		END


		--- update to final result
		UPDATE b
			SET b.winlostdate = t.winlostdate
		FROM #BalanceRecord b
			INNER JOIN #Transaction t
				ON b.custid = t.custID AND b.refNo = t.transID

		SELECT 
			t.ActionDate, t.winlostdate, t.refNo, t.actual_stake, t.winloss, t.playercomm, t.BalanceChanged, t.NewBalance, t.GivenCredit, t.BetCredit, t.Action
		FROM 
		(
			SELECT 
				@OldActionDateFirstTimes ActionDate,
				NULL AS winlostdate, 
				NULL AS refNo, 
				NULL AS actual_stake, 
				NULL AS winloss, 
				NULL AS playercomm, 
				NULL AS BalanceChanged, 
				NULL AS NewBalance, 
				@OldCreditFirstTimes AS GivenCredit, 
				NULL AS BetCredit, 
				'Opening Credit' AS Action,
				NULL AS rowid
			UNION
			SELECT 
				b.ActionDate, 
				b.winlostdate, 
				b.refNo, 
				b.actual_stake,
				b.winloss,
				b.playercomm, 
				b.BalanceChanged, 
				b.NewBalance,
				b.GivenCredit,
				b.BetCredit,
				b.Action,
				b.rowid
			FROM #BalanceRecord b
		) t
		ORDER BY ActionDate, rowid

		DROP TABLE #Transaction
		DROP TABLE #BalanceRecord
		DROP TABLE #LogCredit
	END
END