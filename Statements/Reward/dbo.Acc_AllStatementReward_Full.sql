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

	IF @_ToDate >= @_BalanceUpDay
	BEGIN
		-- always get all data from latest BUDate -> @todate for calculating ACCUMULATED BALANCE row
		IF (@_FromDate > @_BalanceUpDay)
		BEGIN
			SELECT @Fromdate_bk = @_FromDate
			SELECT @_FromDate = @_BalanceUpDay
		END	

		INSERT INTO @StatementTable -- transfer
		SELECT 
			transdate AS accdate,
			refno,
			(Credit-Debit) totalamt,
			ISNULL(bt.typenamee, 'TRANR') transtype,
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
		WHERE 
			bettype > 30000 
			AND b.custid=@CID 
			AND (Credit-Debit) <> 0 
			AND winlostdate BETWEEN @_FromDate and @_ToDate 
			AND winlostdate >= @_BalanceUpDay
	END

	IF @_FromDate <= @_BalanceUpDay
	BEGIN
		-- CORRECT: full day of @ToDate
		IF @_ToDate >= @_BalanceUpDay
		BEGIN
            SELECT @_ToDate = DATEADD(SECOND, -1, CAST(@_BalanceUpDay AS DATETIME))
        END

		INSERT INTO @StatementTable -- transferExtra
		SELECT 
			transdate AS accdate,
			refno,
			(Credit-Debit) totalamt,
			ISNULL(bt.typenamee, 'TRANR') transtype,
			0,
			transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + CAST(actualrate AS VARCHAR(10)) ELSE '' END transdesc, 
			b.creator AS creatorID,
			b.CheckID AS CheckerId, -- Transfer to Casino/Bingo/P2P
			ci.username AS CheckerName,
			b.checkTime,
			0 AS IsAllowVeify
		FROM
			bodb_Archive.dbo.TransferExtra_bk b WITH (NOLOCK)
			LEFT JOIN dbo.bettype bt WITH (NOLOCK) ON b.bettype = bt.typeid 
			LEFT JOIN dbo.Customer ci WITH(NOLOCK) ON b.CheckID = ci.custid
		WHERE 
			bettype > 30000 
			AND b.custid=@CID 
			AND (Credit-Debit) <> 0 
			AND winlostdate BETWEEN @_FromDate and @_ToDate 
		;

		-- TODO: OPENING BALANCE on the fly
		INSERT INTO @StatementTable
		SELECT
			MAX(TransDate) AS accdate,
			0,
			SUM(Credit-Debit),
			'Bal' transtype,
			0 transtypeid,
			'OPENING BALANCE' transdesc, 
			'' creator,
			NULL,
			'',
			NULL,
			0
		FROM bodb_Archive.dbo.TransferExtra_bk b WITH (NOLOCK)
		WHERE CustId = @CID
			AND Transdate < @_FromDate

	END

	--select @Fromdate_bk

	IF (@_IncludeAccBal = 1) AND (@Fromdate_bk <> @_BalanceUpDay)
	BEGIN
		DECLARE @AccBal MONEY, @BUDate DATETIME

		SELECT @AccBal = ISNULL(SUM(totalamt),0)
		FROM @StatementTable
		WHERE accdate < @Fromdate_bk 

		IF EXISTS(SELECT 1 FROM @StatementTable WHERE accdate >= @Fromdate_bk AND @AccBal <> 0) 
			INSERT INTO @StatementTable
			SELECT '', 0, @AccBal, 'BAL', 0, 'ACCUMULATED BALANCE', NULL, NULL, 0, NULL, 0
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
