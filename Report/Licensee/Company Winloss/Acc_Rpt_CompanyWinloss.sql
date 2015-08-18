USE bodb02
GO
ALTER PROCEDURE dbo.Acc_Rpt_CompanyWinloss @FromDate SMALLDATETIME
	, @ToDate SMALLDATETIME
	, @LicenseeId INT
	, @CurrencyId TINYINT = 0
	, @ProductPrefix VARCHAR(10) = ''

	, @MoveBetsDay SMALLDATETIME
	
AS
/*	Creator: 20150612@Patrick
	Task : Get company win loss
	DB: DB052/bodb02

	Param's Explanation:
		@ProductId default value is 0 it mean get all products
		@CurrencyId default value is 0 it mean get all currencies
		
	Revisions:
		- 20150630@Patrick: Remove the UUS line
*/

BEGIN
	SET NOCOUNT ON
	DECLARE @FromDateTmp DATE, @ToDateTmp DATE, @LicenseeName VARCHAR(50)
	SELECT @FromDateTmp = @FromDate, @ToDateTmp = @ToDate
	
	DECLARE @SAgWinLoss TABLE (CustId INT, CompanyWL MONEY) 
	DECLARE @Super AS TABLE (custid INT, currency TINYINT)
	DECLARE @BetTypeList TABLE(BetType SMALLINT)
	DECLARE @SportTypeList TABLE(SportType SMALLINT, IsBA BIT)

	SELECT @LicenseeName = LicenseeName
	FROM bodb_Licensee.dbo.Licensees (NOLOCK) WHERE LicenseeID = @LicenseeID

	IF @ProductPrefix = 'SB'
    BEGIN
	   INSERT INTO @SportTypeList(SportType, IsBA)
	   VALUES(0, 0)
    END
	ELSE IF @ProductPrefix = 'BA'
    BEGIN
	   INSERT INTO @SportTypeList(SportType, IsBA)
	   VALUES(0, 1)
    END
	ELSE IF @ProductPrefix = 'RB'
    BEGIN
	   INSERT INTO @SportTypeList(SportType, IsBA)
	   VALUES(151, 0)

	   INSERT INTO @BetTypeList(BetType)
	   SELECT typeid
	   FROM bodb02.dbo.bettype WITH (NOLOCK)
	   WHERE typeid IN (31, 32, 33, 41, 42, 43)
    END
	ELSE IF @ProductPrefix = 'NG'
    BEGIN
	   INSERT INTO @SportTypeList(SportType, IsBA)
	   VALUES(161, 0)

	   INSERT INTO @BetTypeList(BetType)
	   SELECT typeid
	   FROM bodb02.dbo.bettype WITH (NOLOCK)
	   WHERE typeid BETWEEN 81 AND 120

    END
	ELSE IF @ProductPrefix = 'LC'
    BEGIN
	   INSERT INTO @SportTypeList(SportType, IsBA)
	   VALUES(162, 0)

	   INSERT INTO @BetTypeList(BetType)
	   SELECT typeid
	   FROM bodb02.dbo.bettype WITH (NOLOCK)
	   WHERE typeid BETWEEN 1101 AND 1199

    END
	ELSE IF @ProductPrefix = 'VS'
    BEGIN
	   INSERT INTO @SportTypeList(SportType, IsBA)
	   VALUES(180, 0)
	   
	   INSERT INTO @BetTypeList(BetType)
	   SELECT typeid
	   FROM bodb02.dbo.bettype WITH (NOLOCK)
	   WHERE typeid BETWEEN 1201 AND 1299
    END
	ELSE IF @ProductPrefix = 'CS'
    BEGIN
	   INSERT INTO @SportTypeList(SportType, IsBA)
	   VALUES(251, 0)

	   INSERT INTO @BetTypeList(BetType)
	   SELECT typeid
	   FROM bodb02.dbo.bettype WITH (NOLOCK)
	   WHERE typeid IN (71, 72)

    END
	ELSE IF @ProductPrefix = 'KN'
    BEGIN
	   INSERT INTO @SportTypeList(SportType, IsBA)
	   VALUES(202, 0)
	   
	   INSERT INTO @BetTypeList(BetType)
	   SELECT typeid
	   FROM bodb02.dbo.bettype WITH (NOLOCK)
	   WHERE typeid BETWEEN 1501 AND 1599
    END
	ELSE IF @ProductPrefix = 'GD'
    BEGIN
	   INSERT INTO @SportTypeList(SportType, IsBA)
	   VALUES(255, 0)

	   INSERT INTO @BetTypeList(BetType)
	   VALUES(1700)

    END
	ELSE IF @ProductPrefix = 'AGC'
    BEGIN
	   INSERT INTO @SportTypeList(SportType, IsBA)
	   VALUES(250, 0)

	   INSERT INTO @BetTypeList(BetType)
	   VALUES(1800)

    END
	ELSE IF @ProductPrefix = 'VG'
    BEGIN
	   INSERT INTO @SportTypeList(SportType, IsBA)
	   VALUES(249, 0)

	   INSERT INTO @BetTypeList(BetType)
	   VALUES(1900)

    END
	
	INSERT INTO @Super(custid, currency)
	SELECT DISTINCT CustID, currency
	FROM bodb_Licensee.dbo.f_SelDepCustSuper(@LicenseeName)
	WHERE ((@CurrencyId = 0) OR (@CurrencyId <> 0 AND currency = @CurrencyId)) AND currency <> 20
		
	IF @ToDate > @MoveBetsDay
	BEGIN
		IF @ProductPrefix = 'SB'--for SB
		BEGIN
			INSERT INTO @SAgWinLoss(CustId, CompanyWL)
			SELECT b.srecommend
				, - SUM(ISNULL(swinlost, 0) + ISNULL(mwinlost, 0) + ISNULL(awinlost, 0) + ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(scomm, 0))
			FROM dbo.bettrans b WITH (NOLOCK, INDEX = IX_srecommend)
				INNER JOIN @Super s ON b.srecommend = s.custid AND b.currency = s.currency
			WHERE b.winlostdate BETWEEN @FromDateTmp AND @ToDateTmp
				AND (bettype < 31 OR bettype BETWEEN 121 AND 999 OR bettype BETWEEN 1301 AND 1399)
				AND b.statusid IN (111, 112, 113)
				AND b.apositiontaking <> 0
			GROUP BY b.srecommend
		END
		ELSE IF @ProductPrefix = 'BA' --for BA
		BEGIN
			INSERT INTO @SAgWinLoss(CustId, CompanyWL)
			SELECT b.srecommend
				, - SUM(ISNULL(swinlost, 0) + ISNULL(mwinlost, 0) + ISNULL(awinlost, 0) + ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(scomm, 0))
			FROM dbo.bettrans b WITH (NOLOCK, INDEX = IX_srecommend)
				INNER JOIN @Super s ON b.srecommend = s.custid AND b.currency = s.currency
			WHERE b.winlostdate BETWEEN @FromDateTmp AND @ToDateTmp
				AND (bettype < 31 OR bettype BETWEEN 121 AND 999 OR bettype BETWEEN 1301 AND 1399)
				AND b.statusid IN (111, 112, 113)
				AND b.apositiontaking = 0
			GROUP BY b.srecommend
		END
		ELSE IF @ProductPrefix IN ('RB', 'VS', 'NG', 'KN', 'CS', 'LC', 'GD', 'AGC', 'VG')
		BEGIN
			INSERT INTO @SAgWinLoss(CustId, CompanyWL)
			SELECT b.srecommend
				, - SUM(ISNULL(swinlost, 0) + ISNULL(mwinlost, 0) + ISNULL(awinlost, 0) + ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(scomm, 0))
			FROM dbo.bettrans b WITH (NOLOCK, INDEX = IX_srecommend)
				INNER JOIN @Super s ON b.srecommend = s.custid AND b.currency = s.currency
				INNER JOIN @BetTypeList bt ON b.bettype = bt.bettype
			WHERE b.winlostdate BETWEEN @FromDateTmp AND @ToDateTmp
				AND b.statusid IN (111, 112, 113)
			GROUP BY b.srecommend
		END
		ELSE IF ISNULL(@ProductPrefix, '') = '' --for all products
		BEGIN
			INSERT INTO @SAgWinLoss(CustId, CompanyWL)
			SELECT b.srecommend
				, - SUM(ISNULL(swinlost, 0) + ISNULL(mwinlost, 0) + ISNULL(awinlost, 0) + ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(scomm, 0))
			FROM dbo.bettrans b WITH (NOLOCK, INDEX = IX_srecommend)
				INNER JOIN @Super s ON b.srecommend = s.custid AND b.currency = s.currency
			WHERE b.winlostdate BETWEEN @FromDateTmp AND @ToDateTmp
				AND b.bettype < 19999
				AND b.statusid IN (111, 112, 113)
			GROUP BY b.srecommend
		END

		--select * from @SAgWinLoss
	END

	IF @FromDateTmp <= @MoveBetsDay 
	BEGIN
		IF @ToDateTmp >= @MoveBetsDay
			SET @ToDateTmp = @MoveBetsDay
		IF ISNULL(@ProductPrefix, '') <> ''
		BEGIN
			INSERT INTO @SAgWinLoss(custid, CompanyWL)
			SELECT b.srecommend
				, - SUM(ISNULL(b.swinlost, 0) + ISNULL(b.mwinlost, 0) + ISNULL(b.awinlost, 0) + ISNULL(b.winlost, 0) + ISNULL(b.scomm, 0)) AS Company
			FROM bodb_Licensee.dbo.rptLicWinloss2 b WITH (NOLOCK)
				INNER JOIN @Super s ON b.srecommend = s.custid AND b.currency = s.currency
				INNER JOIN @SportTypeList bt ON b.SportType = bt.SportType AND b.IsBA = bt.IsBA
			WHERE b.winlostdate BETWEEN @FromDateTmp AND @ToDateTmp
				AND b.RoleId = 4
				AND b.statusid IN (111, 112, 113, 114, 115)
			GROUP BY b.srecommend
		END
		ELSE
		BEGIN
			INSERT INTO @SAgWinLoss(custid, CompanyWL)
			SELECT b.srecommend
				, - SUM(ISNULL(b.swinlost, 0) + ISNULL(b.mwinlost, 0) + ISNULL(b.awinlost, 0) + ISNULL(b.winlost, 0) + ISNULL(b.scomm, 0)) AS Company
			FROM bodb_Licensee.dbo.rptLicWinloss2 b WITH (NOLOCK)
				INNER JOIN @Super s ON b.srecommend = s.custid AND b.currency = s.currency
			WHERE b.winlostdate BETWEEN @FromDateTmp AND @ToDateTmp
				AND b.RoleId = 4
				AND b.BetType < 19999
				AND b.statusid IN (111, 112, 113, 114, 115)
			GROUP BY b.srecommend
		END

		--select * from @SAgWinLoss

	END
	--show result
	SELECT ROW_NUMBER() OVER(ORDER BY UserName) AS RowId
		, UserName, SUM(CompanyWL) AS CompanyWL--, c.custid
	FROM @SAgWinLoss tmp
		INNER JOIN dbo.Customer c WITH(NOLOCK) ON tmp.CustId = c.custid
	WHERE roleid = 4
	GROUP BY UserName
END
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinloss] TO [bodbLicenseeNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinloss] TO [bodbAdminNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_CompanyWinloss] TO [vnteam] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CompanyWinloss] TO [vnteam] AS [dbo]
GO
