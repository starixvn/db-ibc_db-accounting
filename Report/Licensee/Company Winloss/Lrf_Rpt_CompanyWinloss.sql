USE bodb02
GO
ALTER PROCEDURE dbo.Lrf_Rpt_CompanyWinloss @FromDate SMALLDATETIME
	, @ToDate SMALLDATETIME
	, @LicenseeId INT
	, @CurrencyId TINYINT = 0
	, @SportType SMALLINT = -1

	, @MoveBetsDay SMALLDATETIME
	
AS
/*	Creator: 20150612@Patrick
	Task : Get company win loss
	DB: DB052/bodb02

	Param's Explanation:
		@SportType default value is -1 it mean get all sport type
		@CurrencyId default value is 0 it mean get all currency
		@ProductId
	Revisions:	
*/

BEGIN
	SET NOCOUNT ON
	DECLARE @FromDateTmp DATE, @ToDateTmp DATE, @LicenseeName VARCHAR(50)
	SELECT @FromDateTmp = @FromDate, @ToDateTmp = @ToDate
	
	DECLARE @SAgWinLoss TABLE (CustId INT, CompanyWL MONEY) 
	DECLARE @Super AS TABLE (custid INT)
	DECLARE @SportBettypeTmp TABLE(ProductId TINYINT, SportType SMALLINT, BetType SMALLINT, EventType TINYINT, SubProduct VARCHAR(50))
	DECLARE @SportBettype TABLE(BetType SMALLINT)

	SELECT @LicenseeName = LicenseeName
	FROM bodb_Licensee.dbo.Licensees (NOLOCK) WHERE LicenseeID = @LicenseeID

	INSERT INTO @SportBettypeTmp
	EXEC dbo.Acc_SportBettypeMatrix_Sel @mode = 2

	--add more bettype if not config for those bettypes (1700, 1800 & 1900)
	IF NOT EXISTS (SELECT TOP 1 1 FROM @SportBettypeTmp WHERE BetType = 1700) --Gold delux
	BEGIN
		INSERT INTO @SportBettypeTmp(ProductId, SportType, BetType, EventType, SubProduct)
		VALUES(NULL, 255, 1700, 0, '')
	END
	IF NOT EXISTS (SELECT TOP 1 1 FROM @SportBettypeTmp WHERE BetType = 1800) --AG casino
	BEGIN
		INSERT INTO @SportBettypeTmp(ProductId, SportType, BetType, EventType, SubProduct)
		VALUES(NULL, 250, 1800, 0, '')
	END
	IF NOT EXISTS (SELECT TOP 1 1 FROM @SportBettypeTmp WHERE BetType = 1900) --Vegas game
	BEGIN
		INSERT INTO @SportBettypeTmp(ProductId, SportType, BetType, EventType, SubProduct)
		VALUES(NULL, 249, 1900, 0, '')
	END

	IF @SportType = 0
	BEGIN
		INSERT INTO @SportBettype(BetType)
		SELECT bettype
		FROM @SportBettypeTmp WHERE ProductId = 1
		GROUP BY bettype
	END
	ELSE IF @SportType <> -1
	BEGIN
		INSERT INTO @SportBettype(BetType)
		SELECT BetType
		FROM @SportBettypeTmp WHERE SportType = @SportType
		GROUP BY BetType
	END
	ELSE --get all
	BEGIN
		INSERT INTO @SportBettype(BetType)
		SELECT BetType
		FROM @SportBettypeTmp
		GROUP BY BetType
	END
	
	INSERT INTO @Super(custid)
	SELECT DISTINCT CustID
	FROM bodb_Licensee.dbo.f_SelDepCustSuper(@LicenseeName)
	WHERE (@CurrencyId = 0) OR (@CurrencyId <> 0 AND currency = @CurrencyId)

	IF @ToDate > @MoveBetsDay
	BEGIN
		INSERT INTO @SAgWinLoss(CustId, CompanyWL)
		SELECT b.srecommend
			, - SUM(ISNULL(swinlost, 0) + ISNULL(mwinlost, 0) + ISNULL(awinlost, 0) + ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(scomm, 0))
		FROM dbo.bettrans b WITH (NOLOCK, INDEX = IX_srecommend)
			INNER JOIN @Super s ON b.srecommend = s.custid
			INNER JOIN @SportBettype bt ON b.bettype = bt.bettype
		WHERE b.winlostdate BETWEEN @FromDateTmp AND @ToDateTmp
			AND b.statusid IN (111, 112, 113)
		GROUP BY b.srecommend

		--select * from @SAgWinLoss
	END

	IF @FromDateTmp <= @MoveBetsDay 
	BEGIN
		IF @ToDateTmp >= @MoveBetsDay
			SET @ToDateTmp = @MoveBetsDay
		
		INSERT INTO @SAgWinLoss(custid, CompanyWL)
		SELECT b.srecommend
			, - SUM(ISNULL(b.swinlost, 0) + ISNULL(b.mwinlost, 0) + ISNULL(b.awinlost, 0) + ISNULL(b.winlost, 0) + ISNULL(b.scomm, 0)) AS Company
		FROM bodb_Licensee.dbo.rptLicWinloss2 b WITH (NOLOCK)
			INNER JOIN @Super s ON b.srecommend = s.custid
			--INNER JOIN @SportBettype bt ON b.bettype = bt.bettype-- AND b.SportType = bt.SportType
		WHERE b.winlostdate BETWEEN @FromDateTmp AND @ToDateTmp
			AND b.RoleId = 4
			AND (@SportType = -1 OR (@SportType <> -1 AND b.sporttype = @SportType))
			AND b.statusid IN (111, 112, 113)
		GROUP BY b.srecommend

		--select * from @SAgWinLoss

	END
	--show result
	SELECT ROW_NUMBER() OVER(ORDER BY UserName) AS RowId
		, UserName, CompanyWL, c.custid
	FROM @SAgWinLoss tmp
		INNER JOIN dbo.Customer c WITH(NOLOCK) ON tmp.CustId = c.custid
	WHERE roleid = 4
END
GO
GRANT EXECUTE ON [dbo].[Lrf_Rpt_CompanyWinloss] TO [bodbLicenseeNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Lrf_Rpt_CompanyWinloss] TO [bodbAdminNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Lrf_Rpt_CompanyWinloss] TO [vnteam] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Lrf_Rpt_CompanyWinloss] TO [vnteam] AS [dbo]
GO
