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

	DECLARE @roleid INT
	SELECT  @roleid = roleid FROM customer WITH (NOLOCK) WHERE custid = @CID


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

	DECLARE @Yesterday DATETIME 
	SELECT  @Yesterday = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
		
	----Get Sport Bettype Matrix------
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)

	--Check to not allow to veify before balance up date
	DECLARE @ArchivedDay		SMALLDATETIME
		, @ConstraintDay	SMALLDATETIME

	SELECT @ArchivedDay	= MAX(winlostdate)
	FROM DBTXN.bodb02.dbo.Task_ArchiveDate WITH (NOLOCK)

	SELECT @ConstraintDay =	CASE 
								WHEN @ArchivedDay > @_BalanceUpDay THEN DATEADD(DAY,7,@_BalanceUpDay) -- new BU
								ELSE @_BalanceUpDay -- old BU
							END

	IF @ToDate >= @_BalanceUpDay
	BEGIN
		-- always get all data from latest BUDate -> @todate for calculating ACCUMULATED BALANCE row
		IF (@_FromDate > @_BalanceUpDay)
		BEGIN
			SELECT @Fromdate_bk = @_FromDate
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

	IF @FromDate <= @_BalanceUpDay
	BEGIN
		-- CORRECT: full day of @ToDate
		IF @ToDate >= @_BalanceUpDay
		BEGIN
            SELECT @_ToDate = @_BalanceUpDay
        END

		INSERT INTO @StatementTable
		SELECT
			accdate,
			0,
			totalamt,
			transtype,
			0,
			transdesc, 
			'' creator,
			NULL,
			'',
			NULL,
			0
		FROM bodb_Report.dbo.[StatementReward] sr WITH (NOLOCK)
		WHERE
			custid = @CID
			AND accdate >= @_FromDate AND accdate < @_ToDate 
			AND transtype <> 'Bal'

		/*INSERT INTO @StatementTable -- transferExtra
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
			0 AS IsAllowVeify
		FROM
			bodb_Archive.dbo.TransferExtra_bk b WITH (NOLOCK)
			LEFT JOIN dbo.bettype bt WITH (NOLOCK) ON b.bettype = bt.typeid 
			LEFT JOIN dbo.Customer ci WITH(NOLOCK) ON b.CheckID = ci.custid
		WHERE b.custid=@CID 
			AND b.bettype > 30000 
			AND (b.Credit-b.Debit) <> 0 
			AND b.transdate >= @_FromDate AND b.transdate < @_ToDate 
			AND b.winlostdate < @_BalanceUpDay
		;*/
	END

	-- TODO: OPENING BALANCE on the fly
	SET @_FromDate = @FromDate;
	INSERT INTO @StatementTable
	SELECT TOP (1)
		accdate,
		0,
		totalamt,
		transtype,
		0,
		'OPENNING BALANCE' transdesc, 
		'' creator,
		NULL,
		'',
		NULL,
		0
	FROM bodb_Report.dbo.[StatementReward] sr WITH (NOLOCK)
	WHERE
		custid = @CID
		AND accdate < @_FromDate
		AND transtype = 'BAL'
	ORDER BY accdate DESC

	/*
	INSERT INTO @StatementTable
	SELECT
		MAX(TransDate) AS accdate,
		0,
		SUM(Credit-Debit),
		'BAL' transtype,
		0 transtypeid,
		'OPENNING BALANCE' transdesc, 
		'' creator,
		NULL,
		'',
		NULL,
		0
	FROM (
		SELECT TransDate, Credit, Debit
		FROM dbo.TransferExtra b WITH (NOLOCK)
		WHERE CustId = @CID
			AND Transdate < @_FromDate
			AND WinlostDate >= @_BalanceUpDay
		UNION ALL
		SELECT TransDate, Credit, Debit
		FROM bodb_Archive.dbo.TransferExtra_bk b WITH (NOLOCK)
		WHERE CustId = @CID
			AND Transdate < @_FromDate
			AND WinlostDate < @_BalanceUpDay
	) AS t
	HAVING SUM(Credit-Debit) <> 0
	*/

	IF (@_IncludeAccBal = 1)
	BEGIN
		IF EXISTS(SELECT 1 FROM @StatementTable WHERE transtype = 'BAL') 
			INSERT INTO @StatementTable
			SELECT '', 0, totalamt, transtype, 0, 'ACCUMULATED BALANCE', NULL, NULL, 0, NULL, 0
			FROM @StatementTable WHERE transtype = 'BAL'
		ELSE
			INSERT INTO @StatementTable
			SELECT '', 0, 0, 'BAL', 0, 'ACCUMULATED BALANCE', NULL, NULL, 0, NULL, 0
	END

	-- OUTPUT result
	SELECT accdate
		, refno
		, SUM(totalamt) AS totalamt
		, transtype
		, transtypeid
		, transdesc
		, ISNULL(c.username, '') AS creator
		, checkerID
		, checkerName
		, checkTime
		, isAllowVeify
	FROM @StatementTable st
	LEFT JOIN dbo.customer c(NOLOCK)
		ON st.creatorID = c.custid
	WHERE accdate >= @Fromdate_bk
		OR transdesc = 'ACCUMULATED BALANCE'
	GROUP BY accdate
		, refno
		, transtype
		, transtypeid
		, transdesc
		, ISNULL(c.username, '')
		, checkerID
		, checkerName
		, checkTime
		, isAllowVeify
	ORDER BY accdate
		, CASE 
			WHEN transdesc LIKE '%OPENING BALANCE%'
				THEN 1
			ELSE 2
			END
		, transtypeid
		, transdesc

END
