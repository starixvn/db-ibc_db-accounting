/*<info serverAlias="DBACC-bodb02" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_StatementRewardSel]
	@fromdate	SMALLDATETIME,
	@todate		SMALLDATETIME,
	@custid		INT
AS
/*
	Created by: 20240826@Bobby
	Task: 209633 - CreditReward - Reward Statement
	DB: DBACC.bodb02
	ORIGINAL: Acc_StatementSel, Acc_StatementSel_14,Acc_StatementSel_Old

	Revisions:
		- 20240826@Bobby: Init [Redmine: #209633]
*/
BEGIN
	SET NOCOUNT ON;

	----Get Sport bettype Matrix------
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID);

	DECLARE @CID INT, -- to prevent bad parameter sniffing
		@tmpFromDate  SMALLDATETIME,
		@tmpToDate  SMALLDATETIME
	;

	SELECT
		@CID			= @custid,
		@tmpFromDate	= @FromDate,
		@tmpToDate		= @ToDate
	;
	

	DECLARE @roleid INT
	SELECT  @roleid = roleid FROM dbo.customer WITH(NOLOCK) WHERE custid = @CID

	-- get move bet date
	DECLARE @balanceUpDay SMALLDATETIME;
	EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @balanceUpDay OUTPUT

	DROP TABLE IF EXISTS #rptStatementTable;
	CREATE TABLE #Data (
		winlostdate			SMALLDATETIME
		,Bettype			SMALLINT
		,StatusID			INT
		,IsOwner			BIT     DEFAULT 0		
		,BetCount			INT		DEFAULT 0
		,OwnerWinloss		MONEY	NULL
	);

	DROP TABLE IF EXISTS #rptStatementTable;
	CREATE TABLE #rptStatementTable(
		winlostdate			SMALLDATETIME	
		,OpeningBalance		MONEY	NULL
		,TransferAmt		MONEY	NULL
		,ClosingBalance		MONEY	NULL
		,TransCount			INT		DEFAULT 0
		,Balance			MONEY		
		,IsOpeningBalance	BIT		DEFAULT 0
	);

	DECLARE @tbl TABLE(winlostdate SMALLDATETIME)	
	;WITH CTE_WinlostDate (winlostdate) AS
	(		
		SELECT @fromdate as winlostdate
		UNION ALL
		SELECT DATEADD(DAY, 1, winlostdate) as winlostdate
		FROM CTE_WinlostDate
		WHERE winlostdate < @Todate		
	)
	INSERT INTO @tbl (Winlostdate)
	SELECT Winlostdate FROM CTE_WinlostDate
	OPTION (MAXRECURSION 0)

	-- 1.1 Get TransferExtra	
	IF @todate >= @balanceUpDay
	BEGIN
		SELECT @tmpFromDate = IIF(@fromdate < @balanceUpDay, @balanceUpDay, @fromdate);

		INSERT INTO #Data (winlostdate, bettype, StatusID, IsOwner, OwnerWinloss, BetCount)
		SELECT Winlostdate, bettype, 131 AS StatusID, 1 AS IsOwner,
				SUM(Credit-Debit), COUNT(1)
		FROM dbo.TransferExtra bt WITH (NOLOCK) 
		WHERE bt.custID = @CID		
			AND 1 = CASE WHEN bettype = 30000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
						WHEN winlostdate < @balanceUpDay THEN 0 --> old data
					ELSE 1 END
			AND winlostdate BETWEEN @tmpFromDate AND @tmpToDate
		GROUP BY Winlostdate, bettype
	END

	-- 1.2 Get TransferExtra_bk
	IF @fromdate < @balanceUpDay
	BEGIN
		SELECT @tmpFromDate = @fromdate,
			@tmpToDate = DATEADD(DAY, -1, @balanceUpDay);

		INSERT INTO #Data (winlostdate, bettype, StatusID, IsOwner, OwnerWinloss, BetCount)
		SELECT Winlostdate, bettype, 131 AS StatusID, 1 AS IsOwner,
				SUM(Credit-Debit), COUNT(1)
		FROM bodb_Archive.dbo.TransferExtra_bk bt WITH (NOLOCK)					
		WHERE bt.custID = @CID		
			AND winlostdate BETWEEN @tmpFromDate AND @tmpToDate
		GROUP BY Winlostdate, bettype
	END

	-- 2. Get Openning Balance ----	
	BEGIN
		INSERT INTO #Data (winlostdate, bettype, StatusID, IsOwner, OwnerWinloss, BetCount)
		SELECT
			DATEADD(DAY, -1, @FromDate) AS WinlostDate,
			30000 AS bettype,
			131 StatusID,
			1 IsOwner,
			SUM(Credit-Debit) OwnerWinloss,
			COUNT(1) BetCount
		FROM (
			SELECT WinlostDate, Credit, Debit
			FROM dbo.TransferExtra b WITH (NOLOCK)
			WHERE CustId = @CID
				AND WinlostDate < @FromDate
				AND WinlostDate >= @balanceUpDay
			UNION ALL
			SELECT WinlostDate, Credit, Debit
			FROM bodb_Archive.dbo.TransferExtra_bk b WITH (NOLOCK)
			WHERE CustId = @CID
				AND WinlostDate < @FromDate
				AND WinlostDate < @balanceUpDay
		) AS t
		HAVING SUM(Credit-Debit) <> 0
		;

		;WITH CTE_Balance (winlostdate, Balance) AS
		(			
			SELECT
				CASE WHEN winlostdate < @fromdate THEN @fromdate ELSE DATEADD(DAY, 1, winlostdate) END AS winlostdate,
				SUM(CASE WHEN IsOwner = 1 THEN OwnerWinloss ELSE 0 END) AS OpeningBalance
			FROM #Data bt  				
			WHERE statusID NOT IN (0, 1)
				AND winlostdate < @todate			
			GROUP BY CASE WHEN winlostdate < @fromdate THEN @fromdate ELSE DATEADD(DAY, 1, winlostdate) END

		)
		INSERT INTO #rptStatementTable (winlostdate, Balance, IsOpeningBalance)
		SELECT
			tmp.winlostdate,
			SUM(ISNULL(Balance, 0)),
			1
		FROM
			@tbl tmp
			LEFT JOIN CTE_Balance cb ON tmp.winlostdate = cb.winlostdate
		GROUP BY tmp.winlostdate
		ORDER BY winlostdate 	

		 
				
		/*Calculate Opening Balance*/
		DECLARE @total MONEY;
		SELECT @total = 0
		UPDATE #rptStatementTable
		SET OpeningBalance = @total, @total = @total + Balance -- running total
		WHERE IsOpeningBalance = 1

		DELETE #rptStatementTable
		WHERE winlostdate < (SELECT MIN(winlostdate) FROM #rptStatementTable WHERE OpeningBalance <> 0 AND IsOpeningBalance = 1)
			AND IsOpeningBalance = 1 
		/*End Calculate Opening Balance*/
	END

	--select * from #rptStatementTable

	-- IV. Transfer tickets	
	INSERT INTO #rptStatementTable (winlostdate, TransferAmt, TransCount)
	SELECT 
		winlostdate
		,SUM(OwnerWinloss) AS TransferAmt
		,SUM(BetCount) AS TransCount
	FROM #Data bt  
	WHERE  bettype > 30000
		AND winlostdate BETWEEN @fromdate AND @todate
		AND IsOwner = 1
	GROUP BY winlostdate
			
			 
	-- V. Show statement report
	SELECT 
		winlostdate
		,@CID AS CustID
		,SUM(ISNULL(OpeningBalance, 0)) AS [OpeningBalance]
		,SUM(TransferAmt) AS [TransferAmt]
		,SUM(ISNULL(OpeningBalance, 0) + ISNULL([TransferAmt], 0)) AS ClosingBalance
	FROM #rptStatementTable
	GROUP BY winlostdate
	HAVING
		 SUM(TransCount) <> 0
	ORDER BY winlostdate

END
