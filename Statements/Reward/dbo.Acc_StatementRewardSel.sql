/*<info serverAlias="DBACC-bodb02" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_StatementRewardSel]
	@fromdate		SMALLDATETIME,
	@todate			SMALLDATETIME,
	@balanceUpDay	SMALLDATETIME = NULL,
	@custid			INT
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

	DECLARE @CID		INT, -- to prevent bad parameter sniffing
		@tmpFromDate	SMALLDATETIME,
		@tmpToDate		SMALLDATETIME
		--,@balanceUpDay	SMALLDATETIME
	;

	SELECT
		@CID			= @custid,
		@tmpFromDate	= @FromDate,
		@tmpToDate		= @ToDate
	;

	DROP TABLE IF EXISTS #rptStatementTable;
	CREATE TABLE #rptStatementTable(
		winlostdate			SMALLDATETIME	
		,OpeningBalance		MONEY	NULL
		,TransferAmt		MONEY	NULL
		,ClosingBalance		AS OpeningBalance + TransferAmt
	);

	-- get move bet date
	IF @balanceUpDay IS NULL
		EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @balanceUpDay OUTPUT;

	-- Get TransferExtra	
	IF @todate >= @balanceUpDay
	BEGIN
		SELECT @tmpFromDate = IIF(@fromdate < @balanceUpDay, @balanceUpDay, @fromdate)
		;

		WITH CTE_Data (Winlostdate, transferAmt) AS (
			SELECT Winlostdate, SUM(Credit-Debit)
			FROM dbo.TransferExtra WITH (NOLOCK) 
			WHERE custID = @CID		
				AND Bettype > 30000
				AND winlostdate BETWEEN @tmpFromDate AND @tmpToDate
			GROUP BY Winlostdate
		), 
		CTE_Balance (balanceUpDay, OpeningBalance) AS (
			SELECT TOP 1 winlostdate, totalAmt
			FROM (
				SELECT TOP 1 winlostdate, (Credit - Debit)
				FROM dbo.TransferExtra WITH (NOLOCK) 
				WHERE custId = @CID	
					AND bettype = 30000
					AND winlostdate >= @balanceUpDay -- the last BU
				ORDER BY winlostdate DESC
				UNION ALL
				SELECT @balanceUpDay, 0 --> Init BU
			) AS bal (winlostdate, totalAmt)
			ORDER BY ABS(totalAmt) DESC
		)
		INSERT INTO #rptStatementTable (winlostdate, OpeningBalance, TransferAmt)
		SELECT rpt.winlostdate
			, SUM(rpt.openingBalance + rpt.transferAmt) OVER(ORDER BY rpt.winlostdate) - rpt.transferAmt AS OpeningBalance
			, rpt.TransferAmt
		FROM (
			SELECT DATEADD(DAY, -1, @fromdate), (bal.OpeningBalance + ISNULL(fw.totalAmt, 0)), 0
			FROM CTE_Balance AS bal
			OUTER APPLY (
				SELECT SUM(tx.Credit - tx.Debit)
				FROM dbo.TransferExtra tx WITH (NOLOCK) 
				WHERE tx.custId = @CID	
					AND tx.bettype > 30000
					AND tx.winlostdate < @fromdate
					AND tx.winlostdate >= bal.balanceUpDay 
			) AS fw (totalAmt) --> forward total amount
			UNION ALL
			SELECT dt.winlostdate, 0,  dt.transferAmt
			FROM CTE_Data AS dt
		) AS rpt (winlostdate, OpeningBalance, transferAmt)
		ORDER BY rpt.winlostdate
	END

	-- 1.2 Get rptStatementExtra_Old
	IF @fromdate < @balanceUpDay
	BEGIN
		SELECT @tmpFromDate = @fromdate,
			@tmpToDate		= DATEADD(DAY, -1, @balanceUpDay);

		INSERT INTO #rptStatementTable (winlostdate, OpeningBalance, TransferAmt)
		SELECT Winlostdate, OpeningBalance, TransferAmt
		FROM bodb_Report.dbo.rptStatementExtra_Old rpt WITH (NOLOCK)	
		WHERE custID = @CID		
			AND winlostdate BETWEEN @tmpFromDate AND @tmpToDate
	END

	-- Show statement report
	SELECT 
		winlostdate
		,@CID AS CustId
		,OpeningBalance
		,TransferAmt
		,ClosingBalance
	FROM #rptStatementTable
	WHERE winlostdate >= @fromdate
	ORDER BY winlostdate

END
