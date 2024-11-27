/*<info serverAlias="DBACC-bodb02" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_AllStatementReward_Full]
	@custid				INT,
	@Fromdate			DATETIME,
	@todate				DATETIME,
	@BalanceUpDay		DATETIME,
	@MoveBetDay			DATETIME,
	@IncludeAccBal		BIT = 1,
	@ShowExchangeRate	BIT = 1
AS
/*
	Created by: 20240826@Bobby
	Task: 209633 - CreditReward - Reward Statement
	DB: DBACC.bodb02
	ORIGINAL: Acc_AllStatement_Full

	Revisions:
		- 20240826@Bobby: Init [Redmine: #209633]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @CID INT -- to prevent bad parameter sniffing
	SELECT  @CID = @custid

	DECLARE @StatementTable TABLE
	(
		accdate			DATETIME,
		refno			BIGINT,
		totalamt		MONEY,
		transtype		NVARCHAR(100),
		transtypeid		TINYINT DEFAULT 0,
		transdesc		NVARCHAR(1000),
		creatorID		INT,
		checkerID		INT NULL,
		checkerName		VARCHAR(50) NULL,
		checkTime		DATETIME NULL,
		isAllowVeify	BIT DEFAULT 0-- display check box "Verify"
	)

	DECLARE @_FromDate DATETIME, @_ToDate DATETIME, @_BalanceUpDay DATETIME, @Fromdate_bk DATETIME, @_IncludeAccBal BIT, @_moveBetsDay SMALLDATETIME
	SELECT  @_FromDate = @Fromdate, @_ToDate = @todate, @_BalanceUpDay = @BalanceUpDay, @Fromdate_bk = @Fromdate, @_IncludeAccBal = @IncludeAccBal
			, @_moveBetsDay = CAST(@MoveBetDay AS SMALLDATETIME)

		
	--Check to not allow to veify before balance up date
	DECLARE @ArchivedDay		SMALLDATETIME
		, @ConstraintDay	SMALLDATETIME

	SELECT @ArchivedDay	= MAX(winlostdate)
	FROM DBTXN.bodb02.dbo.Task_ArchiveDate WITH (NOLOCK)

	SELECT @ConstraintDay =	CASE 
								WHEN @ArchivedDay > @_BalanceUpDay THEN DATEADD(DAY,7,@_BalanceUpDay) -- new BU
								ELSE @_BalanceUpDay -- old BU
							END

	SELECT @Fromdate_bk = @_FromDate;
	IF @_ToDate >= @_BalanceUpDay
	BEGIN
		-- always get all data from latest BUDate -> @todate for calculating ACCUMULATED BALANCE row
		IF (@_FromDate > @_BalanceUpDay)
		BEGIN
			SELECT @_FromDate = @_BalanceUpDay
		END	

		SELECT @_ToDate = DATEADD(DAY, 1, CAST(@ToDate AS DATE)) -- whole ToDate
		INSERT INTO @StatementTable -- transfer
		SELECT 
			transdate AS accdate,
			refno,
			(Credit-Debit) totalamt,
			bt.typenamee AS transtype,
			0,
			transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + CAST(actualrate AS VARCHAR(10)) ELSE '' END transdesc, 
			b.creator AS creatorID,
			b.CheckID AS CheckerId, 
			ci.username AS CheckerName,
			b.checkTime,
			CASE WHEN b.WinlostDate < @ConstraintDay THEN 0 ELSE 1 END AS IsAllowVeify
		FROM
			dbo.TransferExtra b WITH (NOLOCK)
			LEFT JOIN dbo.bettype bt WITH (NOLOCK) ON b.bettype = bt.typeid 
			LEFT JOIN dbo.Customer ci WITH(NOLOCK) ON b.CheckID = ci.custid
		WHERE b.custid=@CID 
			AND b.bettype > 30000 
			AND (b.Credit-b.Debit) <> 0 
			AND b.transdate >= @_FromDate AND b.transdate < @_ToDate 
			AND b.winlostdate >= @_BalanceUpDay
	END

	IF @_FromDate <= @_BalanceUpDay
	BEGIN
		-- CORRECT: full day of @ToDate & in case REVERT transfer cross transdate BUT the same winlostdate. Ex: winlostdate < BU < transdate
		SELECT @_ToDate	= DATEADD(DAY, 1, CAST(@_ToDate AS DATE));

		INSERT INTO @StatementTable
		SELECT
			sr.accdate,
			0,
			sr.totalamt,
			sr.transtype,
			0,
			sr.transdesc, 
			'' creator,
			NULL,
			'',
			NULL,
			0
		FROM bodb_Report.dbo.[StatementExtra] sr WITH (NOLOCK)
			LEFT JOIN @StatementTable tmp ON tmp.accdate = sr.accdate AND tmp.transtype = sr.transtype 
		WHERE
			sr.custid = @CID
			AND sr.accdate >= @_FromDate AND sr.accdate < @_ToDate 
			AND sr.transtype NOT IN ('BALR', 'ACCUM')
			AND tmp.accdate IS NULL --> ignore duplicate rows while running Thursday process
		;

		--TODO: INSERT BAL when @Fromdate_bk = @_BalanceUpDay
		INSERT INTO @StatementTable
		SELECT TOP 1
			accdate,
			0,
			totalamt,
			'BALR' transtype,
			0 transtypeid,
			'OPENING BALANCE' transdesc, 
			'' creator,
			NULL,
			'',
			NULL,
			0
		FROM bodb_Report.dbo.StatementExtra WITH (NOLOCK) 
		WHERE CustId = @CID
			AND AccDate BETWEEN @_FromDate AND @_ToDate
			AND AccDate <= @_BalanceUpDay
			AND transtype = 'ACCUM'
			AND @Fromdate_bk = @_BalanceUpDay
		ORDER BY AccDate DESC
	END

	-- TODO: INSERT - ACCUMULATED BALANCE
	IF (@_IncludeAccBal = 1) AND (@Fromdate_bk <> @_BalanceUpDay)
	BEGIN

		IF @Fromdate_bk < @_BalanceUpDay
		BEGIN
			SELECT @_ToDate = IIF(@ToDate >= @_BalanceUpDay, @_BalanceUpDay, @ToDate);

			WITH CTE_Accum AS (
				SELECT TOP 1 accdate, totalamt
				FROM (
					SELECT TOP(1) accdate, totalamt
					FROM bodb_Report.dbo.[StatementExtra] sr WITH (NOLOCK)
					WHERE custid = @CID
						AND accdate <= @Fromdate_bk
						AND transtype = 'ACCUM'
					ORDER BY accdate DESC
					UNION ALL SELECT NULL, 0 --> Init accum balance from begining
				) AS t
				ORDER BY ABS(totalamt) DESC
			)
			INSERT INTO @StatementTable
			SELECT 
				0,
				0,
				(ac.totalamt + ISNULL(cal.totalamt, 0)) AS totalamt,
				'BALR' AS transtype,
				0,
				'ACCUMULATED BALANCE' transdesc, 
				NULL,
				NULL,
				0,
				NULL,
				0
			FROM CTE_Accum ac
			OUTER APPLY (
				SELECT SUM(sr.totalamt) AS totalamt
				FROM bodb_Report.dbo.[StatementExtra] sr WITH (NOLOCK)
				WHERE sr.custid = @CID
					AND (sr.accdate > ac.accdate OR ac.accdate IS NULL)
					AND sr.accdate < @Fromdate_bk
					AND sr.transtype NOT IN ('BALR', 'ACCUM')
			) AS cal --> CAL ACCUM total
			---------- INCLUDE - OPENING BALANCE
			UNION ALL
			SELECT 
				sr.accdate,
				0,
				sr.totalamt,
				'BALR' AS transtype,
				0,
				'OPENING BALANCE' AS transdesc, 
				NULL,
				NULL,
				0,
				NULL,
				0
			FROM bodb_Report.dbo.[StatementExtra] sr WITH (NOLOCK)
			WHERE sr.custid = @CID
				AND sr.accdate > @Fromdate_bk AND sr.accdate <= @_ToDate 
				AND sr.transtype IN ('ACCUM')
		END
		ELSE IF @Fromdate_bk > @_BalanceUpDay
		BEGIN
			WITH CTE_Accum AS (
				SELECT TOP 1 accdate, totalamt
				FROM (
					SELECT TOP(1) accdate, totalamt
					FROM bodb_Report.dbo.[StatementExtra] sr WITH (NOLOCK)
					WHERE custid = @CID
						AND accdate = @_BalanceUpDay
						AND transtype = 'ACCUM'
					ORDER BY accdate DESC
					UNION ALL SELECT @_BalanceUpDay, 0  --> Init accum balance
				) AS t
				ORDER BY ABS(totalamt) DESC
			)
			INSERT INTO @StatementTable
			SELECT 
				0,
				0,
				(ac.totalamt + ISNULL(cal.totalamt, 0)) AS totalamt,
				'BALR' AS transtype,
				0,
				'ACCUMULATED BALANCE' transdesc, 
				NULL,
				NULL,
				0,
				NULL,
				0
			FROM CTE_Accum ac
			OUTER APPLY (
				SELECT SUM(te.Credit - te.Debit) AS totalamt
				FROM dbo.[TransferExtra] te WITH (NOLOCK)
				WHERE te.custid = @CID
					AND te.TransDate >= ac.accdate AND te.TransDate < @Fromdate_bk
					AND te.Bettype NOT IN (30000)
					AND te.WinlostDate >= @_BalanceUpDay
			) AS cal --> CAL ACCUM total
			
		END
	END

	-- OUTPUT result
	SELECT accdate
		, refno
		, (totalamt) AS totalamt
		, transtype
		, transtypeid
		, transdesc
		, ISNULL(c.username, '') AS creator
		, checkerID
		, checkerName
		, checkTime
		, isAllowVeify
	FROM @StatementTable st
	LEFT JOIN dbo.customer c(NOLOCK) ON st.creatorID = c.custid
	WHERE accdate >= @Fromdate_bk
		OR transdesc = 'ACCUMULATED BALANCE'
	ORDER BY accdate
		, CASE 
			WHEN transdesc LIKE '%OPENING BALANCE%'
				THEN 1
			ELSE 2
		END
		, transtypeid
		, transdesc

END
