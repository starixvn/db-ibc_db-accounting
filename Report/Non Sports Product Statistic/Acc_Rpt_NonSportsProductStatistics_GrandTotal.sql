USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_Rpt_NonSportsProductStatistics_GrandTotal]
	@WinlostDate	DATETIME,
	@ProductId		VARCHAR(MAX) = '',
	@Username		VARCHAR(50) = '',
	@Site			VARCHAR(MAX) = 'ALL',	
	@BetType		VARCHAR(MAX) = '',
	@LeagueId		VARCHAR(MAX) = '',
	@Sporttype		VARCHAR(MAX) = '',
	@GameTableId	VARCHAR(MAX) = '',
	@Currency		SMALLINT = 0,	
	@Device			VARCHAR(200) = '',
	@ExcludeTest	BIT = 1, 
	@TotalBetType	SMALLINT = 0,
	@TotalBetValue  MONEY = NULL,
	@GameIncomeType	SMALLINT = 0,
	@GameIncomeValue MONEY = NULL,	 
	@HousePTType	SMALLINT = 0,
	@HousePTValue   MONEY = 0
AS

/*
	Creator: Percy
	Date: 2016-11-25
	DB: DBACC.bodb02
	Task: View grand total

	Revisions:

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @WLDate DATETIME
	SELECT  @WLDate = @WinlostDate

	CREATE TABLE #tmp_ProductID		(ProductID INT)
	CREATE TABLE #tmp_BetType		(Bettype INT)
	CREATE TABLE #tmp_LeagueID		(LeagueID INT)
	CREATE TABLE #tmp_SportType		(Sporttype INT)
	CREATE TABLE #tmp_GameTableID	(GameTableID INT)
	CREATE TABLE #tmp_Devide		(Betfrom NVARCHAR(2))

	-- Get Info from Pars list
	IF @ProductId <> ''
	BEGIN
		INSERT INTO #tmp_ProductID (ProductID)
		SELECT val FROM dbo.strSplit(@ProductId, ',')
	END

	IF @BetType <> ''
	BEGIN
		INSERT INTO #tmp_BetType (Bettype)
		SELECT val FROM dbo.strSplit(@BetType, ',')
	END

	IF @LeagueId <> ''
	BEGIN
		INSERT INTO #tmp_LeagueID (LeagueID)
		SELECT val FROM dbo.strSplit(@LeagueId, ',')
	END

	IF @Sporttype <> ''
	BEGIN
		INSERT INTO #tmp_SportType (Sporttype)
		SELECT val FROM dbo.strSplit(@Sporttype, ',')
	END

	IF @GameTableId <> ''
	BEGIN
		INSERT INTO #tmp_GameTableID (GameTableID)
		SELECT val FROM dbo.strSplit(@GameTableId, ',')
	END

	IF @Device <> ''
	BEGIN
		INSERT INTO #tmp_Devide (Betfrom)
		SELECT val FROM dbo.strSplit(@Device, ',')
	END
	-- End Info from Pars list

	-- Get Sport Bettype Matrix --
	DECLARE @isTest BIT = 0
	SELECT @isTest = dbo.f_CheckSPVersion(@@PROCID)

	CREATE TABLE #SportBettype (ProductID INT, Bettype INT, EvenType INT, RefTable SMALLINT)
	
	INSERT INTO #SportBettype (ProductID, Bettype, EvenType, RefTable)
	SELECT s.ProductID, s.BetType, s.EventType, s.RefTable
	FROM
		dbo.f_SportBettypeMatrix_Sel(0, 0, 0, 2, '', '', @isTest) s
		INNER JOIN #tmp_ProductID p ON s.ProductID = p.ProductID
		INNER JOIN #tmp_BetType b ON s.BetType = b.Bettype

	INSERT INTO #SportBettype (ProductID, Bettype, EvenType, RefTable)
	SELECT s.ProductID, s.BetType, s.EventType, s.RefTable
	FROM
		dbo.f_SportBettypeMatrix_Sel(0, 0, 0, 2, '', '', @isTest) s
		INNER JOIN #tmp_ProductID p ON s.ProductID = p.ProductID
	WHERE p.ProductID IN (3, 5) -- Number Game, Virtual Sport (input @bettype = '')

	DROP TABLE #tmp_ProductID
	DROP TABLE #tmp_BetType
	-- End Get Sport Bettype Matrix --

	-- Get Site	
	CREATE TABLE #tmp_Site (Site VARCHAR(50))
	CREATE TABLE #tmp_Company (SiteName VARCHAR(50), srecommend INT PRIMARY KEY)
	CREATE TABLE #tmp_MemIDs (CustID INT PRIMARY KEY)	
	
	IF @Site <> 'ALL'
	BEGIN
		INSERT INTO #tmp_Site (Site)
		SELECT RTRIM(LTRIM(val)) FROM dbo.strSplit(@Site, ',')

		INSERT INTO #tmp_Company (SiteName, Srecommend)
		SELECT s.Site, c.srecommend
		FROM #tmp_Site s
			INNER JOIN dbo.Site ss WITH (NOLOCK) ON s.Site = ss.site
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON ss.Site = c.site
		WHERE c.roleid = 4

		IF @Username <> ''
		BEGIN
			INSERT INTO #tmp_MemIDs (CustID)
			SELECT custid
			FROM
				dbo.Customer c WITH (NOLOCK)
				INNER JOIN #tmp_Company tc ON c.srecommend = tc.srecommend
			WHERE username LIKE + @Username + '%' AND roleid = 1
		END
		ELSE
		BEGIN
			INSERT INTO #tmp_MemIDs (CustID)
			SELECT custid
			FROM
				dbo.Customer c WITH (NOLOCK)
				INNER JOIN #tmp_Company tc ON c.srecommend = tc.srecommend
			WHERE c.roleid = 1
		END
	END
	ELSE
	BEGIN
		IF @Username <> ''
		BEGIN
			INSERT INTO #tmp_MemIDs (CustID)
			SELECT custid
			FROM dbo.Customer WITH (NOLOCK)
			WHERE username LIKE + @Username + '%' AND roleid = 1
		END
	END

	DROP TABLE #tmp_Site
	DROP TABLE #tmp_Company
	-- End Get Site --

	-- Select temp data of bettrans
	CREATE TABLE #tmp_bettrans
	(
		custid INT,
		BetCount BIGINT,
		CurrencyID INT,
		TotalBets MONEY,
		TotalWins MONEY,
		CompanyTurnover MONEY,
		CompanyGrossIncome MONEY,
		CompanyComm MONEY,
		RefTable TINYINT, EvenType INT DEFAULT (-1), Matchid INT DEFAULT (-1), ProductID INT, statusID TINYINT
	)

	IF EXISTS (SELECT TOP 1 1 FROM #tmp_MemIDs) -- has filter custid
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE RefTable IN (0, 3)) -- bettrans
		BEGIN
			INSERT INTO #tmp_bettrans
			(
				custid,
				BetCount,
				CurrencyID,
				TotalBets,
				TotalWins,
				CompanyTurnover,
				CompanyGrossIncome,
				CompanyComm,
				RefTable, EvenType, Matchid, ProductID, statusID
			)
			SELECT
				b.custid,
				COUNT(b.transid) AS BetCount,
				b.currency,
				SUM(actual_stake * actualrate) AS TotalBets,
				SUM(winlost * actualrate) AS TotalWins,
				SUM((1- b.tpositiontaking) * b.stake * actualrate) AS CompanyTurnover,		
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost) * actualrate) AS CompanyGrossIncome,
				SUM(scomm *actualrate) AS CompanyComm,
				0 AS RefTable, s.EvenType, b.matchid, s.ProductID,
				CASE WHEN statusID = 103 THEN 103 ELSE 112 END AS statusID
			FROM  dbo.bettrans b WITH (NOLOCK)
				INNER JOIN #tmp_MemIDs m ON b.custid = m.CustID
				INNER JOIN #SportBettype s ON s.Bettype = b.bettype
			WHERE b.winlostdate = @WLDate
				AND b.statusID IN (111, 112, 113, 103) -- won/lose/draw/refund tickets
				AND s.RefTable IN (0, 3)
				AND ((b.currency <> 20 AND @ExcludeTest = 1) OR @ExcludeTest = 0)
				AND (b.currency = @Currency OR @Currency IN (0, -1))
				AND (EXISTS (SELECT 1 FROM #tmp_Devide d WHERE d.Betfrom = b.betfrom) OR @Device = '')
				AND (
					@HousePTType = 0
					OR (@HousePTType = -1 AND b.tpositiontaking <= @HousePTValue)
					OR (@HousePTType = 1 AND b.tpositiontaking >= @HousePTValue)
				)
			GROUP BY b.custid, b.currency, s.EvenType, b.matchid, s.ProductID,
				CASE WHEN statusID = 103 THEN 103 ELSE 112 END
		END

		IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE RefTable = 1) -- bettransRnG
		BEGIN
			INSERT INTO #tmp_bettrans
			(
				custid,
				BetCount,
				CurrencyID,
				TotalBets,
				TotalWins,
				CompanyTurnover,
				CompanyGrossIncome,
				CompanyComm,
				RefTable, ProductID, statusID
			)
			SELECT
				b.custid,
				COUNT(b.transid) AS BetCount,
				b.currency,
				SUM(actual_stake * actualrate) AS TotalBets,
				SUM(winlost * actualrate) AS TotalWins,
				SUM((1- b.tpositiontaking) * b.stake * actualrate) AS CompanyTurnover,		
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost) * actualrate) AS CompanyGrossIncome,
				SUM(scomm *actualrate) AS CompanyComm,
				1 AS RefTable, s.ProductID,
				CASE WHEN statusID = 103 THEN 103 ELSE 112 END AS statusID
			FROM dbo.bettransRnG b WITH (NOLOCK)
				INNER JOIN #tmp_MemIDs m ON b.custid = m.CustID
				INNER JOIN #SportBettype s ON s.Bettype = b.gameID
			WHERE b.winlostdate = @WLDate
				AND b.statusID IN (111, 112, 113, 103) -- won/lose/draw/refund tickets
				AND s.RefTable = 1		
				AND ((b.currency <> 20 AND @ExcludeTest = 1) OR @ExcludeTest = 0)
				AND (b.currency = @Currency OR @Currency IN (0, -1))
				AND (EXISTS (SELECT 1 FROM #tmp_Devide d WHERE d.Betfrom = b.betfrom) OR @Device = '')
				AND (
					@HousePTType = 0
					OR (@HousePTType = -1 AND b.tpositiontaking <= @HousePTValue)
					OR (@HousePTType = 1 AND b.tpositiontaking >= @HousePTValue)
				) 
			GROUP BY b.custid, b.currency, s.ProductID,
				CASE WHEN statusID = 103 THEN 103 ELSE 112 END
		END
		
		IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE RefTable = 2) -- bettransLC
		BEGIN
			INSERT INTO #tmp_bettrans
			(
				custid,
				BetCount,
				CurrencyID,
				TotalBets,
				TotalWins,
				CompanyTurnover,
				CompanyGrossIncome,
				CompanyComm,
				RefTable, ProductID, statusID
			)
			SELECT
				b.custid,
				COUNT(b.transid) AS BetCount,
				b.currency,
				SUM(actual_stake * actualrate) AS TotalBets,
				SUM(winlost * actualrate) AS TotalWins,
				SUM((1- b.tpositiontaking) * b.stake * actualrate) AS CompanyTurnover,		
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost) * actualrate) AS CompanyGrossIncome,
				SUM(scomm *actualrate) AS CompanyComm,
				1 AS RefTable, s.ProductID,
				CASE WHEN statusID = 103 THEN 103 ELSE 112 END AS statusID
			FROM dbo.bettransLC b WITH (NOLOCK)
				INNER JOIN #tmp_MemIDs m ON b.custid = m.CustID
				INNER JOIN #SportBettype s ON s.Bettype = b.gameID
			WHERE b.winlostdate = @WLDate
				AND b.statusID IN (111, 112, 113, 103) -- won/lose/draw/refund tickets
				AND s.RefTable = 1		
				AND ((b.currency <> 20 AND @ExcludeTest = 1) OR @ExcludeTest = 0)
				AND (b.currency = @Currency OR @Currency IN (0, -1))
				AND (EXISTS (SELECT 1 FROM #tmp_Devide d WHERE d.Betfrom = b.betfrom) OR @Device = '')
				AND (
					@HousePTType = 0
					OR (@HousePTType = -1 AND b.tpositiontaking <= @HousePTValue)
					OR (@HousePTType = 1 AND b.tpositiontaking >= @HousePTValue)
				) 
			GROUP BY b.custid, b.currency, s.ProductID,
				CASE WHEN statusID = 103 THEN 103 ELSE 112 END
		END
	END
	ELSE -- filter custid
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE RefTable IN (0, 3)) -- bettrans
		BEGIN
			INSERT INTO #tmp_bettrans
			(
				custid,
				BetCount,
				CurrencyID,
				TotalBets,
				TotalWins,
				CompanyTurnover,
				CompanyGrossIncome,
				CompanyComm,
				RefTable, EvenType, matchid, ProductID, statusID
			)
			SELECT
				b.custid,
				COUNT(b.transid) AS BetCount,
				b.currency,
				SUM(actual_stake * actualrate) AS TotalBets,
				SUM(winlost * actualrate) AS TotalWins,
				SUM((1- b.tpositiontaking) * b.stake * actualrate) AS CompanyTurnover,		
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost) * actualrate) AS CompanyGrossIncome,
				SUM(scomm *actualrate) AS CompanyComm,
				0 AS RefTable, s.EvenType, b.matchid, s.ProductID,
				CASE WHEN statusID = 103 THEN 103 ELSE 112 END AS statusID
			FROM  dbo.bettrans b WITH (NOLOCK)
				INNER JOIN #SportBettype s ON s.Bettype = b.bettype
			WHERE b.winlostdate = @WLDate
				AND b.statusID IN (111, 112, 113, 103) -- won/lose/draw/refund tickets
				AND b.matchid > 0
				AND s.RefTable IN (0, 3)
				AND ((b.currency <> 20 AND @ExcludeTest = 1) OR @ExcludeTest = 0)
				AND (b.currency = @Currency OR @Currency IN (0, -1))
				AND (EXISTS (SELECT 1 FROM #tmp_Devide d WHERE d.Betfrom = b.betfrom) OR @Device = '')
				AND (
					@HousePTType = 0
					OR (@HousePTType = -1 AND b.tpositiontaking <= @HousePTValue)
					OR (@HousePTType = 1 AND b.tpositiontaking >= @HousePTValue)
				)
			GROUP BY custid, b.currency, s.EvenType, b.matchid, s.ProductID,
				CASE WHEN statusID = 103 THEN 103 ELSE 112 END
		END

		IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE RefTable = 1) -- bettransRnG
		BEGIN
			INSERT INTO #tmp_bettrans
			(
				custid,
				BetCount,
				CurrencyID,
				TotalBets,
				TotalWins,
				CompanyTurnover,
				CompanyGrossIncome,
				CompanyComm,
				RefTable, ProductID, statusID
			)
			SELECT
				b.custid,
				COUNT(b.transid) AS BetCount,
				b.currency,
				SUM(actual_stake * actualrate) AS TotalBets,
				SUM(winlost * actualrate) AS TotalWins,
				SUM((1- b.tpositiontaking) * b.stake * actualrate) AS CompanyTurnover,		
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost) * actualrate) AS CompanyGrossIncome,
				SUM(scomm *actualrate) AS CompanyComm,
				1 AS RefTable, s.ProductID,
				CASE WHEN statusID = 103 THEN 103 ELSE 112 END AS statusID
			FROM dbo.bettransRnG b WITH (NOLOCK)
				INNER JOIN #SportBettype s ON s.Bettype = b.gameID
			WHERE b.winlostdate = @WLDate
				AND b.statusID IN (111, 112, 113, 103) -- won/lose/draw/refund tickets
				AND s.RefTable = 1		
				AND ((b.currency <> 20 AND @ExcludeTest = 1) OR @ExcludeTest = 0)
				AND (b.currency = @Currency OR @Currency IN (0, -1))
				AND (EXISTS (SELECT 1 FROM #tmp_Devide d WHERE d.Betfrom = b.betfrom) OR @Device = '')
				AND (
					@HousePTType = 0
					OR (@HousePTType = -1 AND b.tpositiontaking <= @HousePTValue)
					OR (@HousePTType = 1 AND b.tpositiontaking >= @HousePTValue)
				) 
			GROUP BY b.custid, b.currency, s.ProductID,
				CASE WHEN statusID = 103 THEN 103 ELSE 112 END
		END

		IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE RefTable = 2) -- bettransLC
		BEGIN
			INSERT INTO #tmp_bettrans
			(
				custid,
				BetCount,
				CurrencyID,
				TotalBets,
				TotalWins,
				CompanyTurnover,
				CompanyGrossIncome,
				CompanyComm,
				RefTable, ProductID, statusID
			)
			SELECT
				b.custid,
				COUNT(b.transid) AS BetCount,
				b.currency,
				SUM(actual_stake * actualrate) AS TotalBets,
				SUM(winlost * actualrate) AS TotalWins,
				SUM((1- b.tpositiontaking) * b.stake * actualrate) AS CompanyTurnover,		
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost) * actualrate) AS CompanyGrossIncome,
				SUM(scomm *actualrate) AS CompanyComm,
				2 AS RefTable, s.ProductID,
				CASE WHEN statusID = 103 THEN 103 ELSE 112 END AS statusID
			FROM dbo.bettransLC b WITH (NOLOCK)
				INNER JOIN #SportBettype s ON s.Bettype = b.gameID
			WHERE b.winlostdate = @WLDate
				AND b.statusID IN (111, 112, 113, 103) -- won/lose/draw/refund tickets
				AND s.RefTable = 2		
				AND ((b.currency <> 20 AND @ExcludeTest = 1) OR @ExcludeTest = 0)
				AND (b.currency = @Currency OR @Currency IN (0, -1))
				AND (EXISTS (SELECT 1 FROM #tmp_Devide d WHERE d.Betfrom = b.betfrom) OR @Device = '')
				AND (
					@HousePTType = 0
					OR (@HousePTType = -1 AND b.tpositiontaking <= @HousePTValue)
					OR (@HousePTType = 1 AND b.tpositiontaking >= @HousePTValue)
				) 
			GROUP BY b.custid, b.currency, s.ProductID,
				CASE WHEN statusID = 103 THEN 103 ELSE 112 END
		END
	END

	-- Get data
	CREATE TABLE #Data
	( 
		custid BIGINT,
		BetCount INT,
		CurrencyID INT,
		TotalBets MONEY,
		TotalWins MONEY,
		TotalRefund MONEY,
		CompanyTurnover MONEY,
		CompanyGrossIncome MONEY,
		CompanyComm MONEY
	)
	--- Check condition 
	IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE ProductID NOT IN (3, 4, 5)) -- NG, SLI-Live Casino, Virtual Sport
	BEGIN		
		INSERT INTO #Data
		(
			custid,
			BetCount,
			CurrencyID,
			TotalBets,
			TotalWins,
			TotalRefund,
			CompanyTurnover,
			CompanyGrossIncome,
			CompanyComm
		)
		SELECT
			custid,
			SUM(CASE WHEN statusID = 112 THEN BetCount ELSE 0 END) AS BetCount,
			CurrencyID,
			SUM(CASE WHEN statusID = 112 THEN TotalBets ELSE 0 END) AS TotalBets,
			SUM(CASE WHEN statusID = 112 THEN TotalWins ELSE 0 END) AS TotalWins,
			SUM(CASE WHEN statusID = 103 THEN TotalBets ELSE 0 END) AS TotalRefund,
			SUM(CASE WHEN statusID = 112 THEN CompanyTurnover ELSE 0 END) AS CompanyTurnover,		
			- SUM(CASE WHEN statusID = 112 THEN CompanyGrossIncome ELSE 0 END) AS CompanyGrossIncome,
			- SUM(CASE WHEN statusID = 112 THEN CompanyComm ELSE 0 END) AS CompanyComm
		FROM  #tmp_bettrans
		WHERE ProductID NOT IN (3, 4, 5)
		GROUP BY custid, CurrencyID
	END

	IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE ProductID IN (3, 4, 5)) -- NG, SLI-Live Casino, Virtual Sport
	BEGIN		
		INSERT INTO #Data
		(
			custid,
			BetCount,
			CurrencyID,
			TotalBets,
			TotalWins,
			TotalRefund,
			CompanyTurnover,
			CompanyGrossIncome,
			CompanyComm
		)
		SELECT
			custid,
			SUM(CASE WHEN statusID = 112 THEN BetCount ELSE 0 END) AS BetCount,
			CurrencyID,
			SUM(CASE WHEN statusID = 112 THEN TotalBets ELSE 0 END) AS TotalBets,
			SUM(CASE WHEN statusID = 112 THEN TotalWins ELSE 0 END) AS TotalWins,
			SUM(CASE WHEN statusID = 103 THEN TotalBets ELSE 0 END) AS TotalRefund,
			SUM(CASE WHEN statusID = 112 THEN CompanyTurnover ELSE 0 END) AS CompanyTurnover,		
			- SUM(CASE WHEN statusID = 112 THEN CompanyGrossIncome ELSE 0 END) AS CompanyGrossIncome,
			- SUM(CASE WHEN statusID = 112 THEN CompanyComm ELSE 0 END) AS CompanyComm
		FROM  #tmp_bettrans b
			INNER JOIN dbo.match m WITH (NOLOCK) ON m.matchid = b.matchid
		WHERE ProductID IN (3, 4, 5) AND b.EvenType = 1
			AND (
				(b.ProductID = 3 AND (@LeagueId = '' OR (EXISTS (SELECT 1 FROM #tmp_LeagueID l WHERE l.LeagueID = m.leagueid)))) OR
				(b.ProductID = 4 AND (@GameTableId = '' OR (EXISTS (SELECT 1 FROM #tmp_GameTableID g WHERE g.GameTableID = m.leagueid)))) OR
				(b.ProductID = 5 AND (@Sporttype = '' OR (EXISTS (SELECT 1 FROM #tmp_SportType st WHERE st.Sporttype = m.sporttype))))
			)
		GROUP BY custid, CurrencyID

		-- HR
		INSERT INTO #Data
		(
			custid,
			BetCount,
			CurrencyID,
			TotalBets,
			TotalWins,
			TotalRefund,
			CompanyTurnover,
			CompanyGrossIncome,
			CompanyComm
		)
		SELECT
			custid,
			SUM(CASE WHEN statusID = 112 THEN BetCount ELSE 0 END) AS BetCount,
			CurrencyID,
			SUM(CASE WHEN statusID = 112 THEN TotalBets ELSE 0 END) AS TotalBets,
			SUM(CASE WHEN statusID = 112 THEN TotalWins ELSE 0 END) AS TotalWins,
			SUM(CASE WHEN statusID = 103 THEN TotalBets ELSE 0 END) AS TotalRefund,
			SUM(CASE WHEN statusID = 112 THEN CompanyTurnover ELSE 0 END) AS CompanyTurnover,		
			- SUM(CASE WHEN statusID = 112 THEN CompanyGrossIncome ELSE 0 END) AS CompanyGrossIncome,
			- SUM(CASE WHEN statusID = 112 THEN CompanyComm ELSE 0 END) AS CompanyComm
		FROM  #tmp_bettrans b
			INNER JOIN dbo.VSRaceInfo r WITH (NOLOCK) ON r.EventID = b.matchid
		WHERE b.ProductID = 5 AND b.EvenType = 3
			AND (@Sporttype = '' OR (EXISTS(SELECT 1 FROM #tmp_SportType st WHERE st.Sporttype = r.SportType)))			  
		GROUP BY b.custid, b.CurrencyID
	END

	-- Return Data
	;WITH Result AS (
		SELECT
			COUNT(DISTINCT custid) AS NoOfPlayers,
			SUM(BetCount) AS BetCount,
			CurrencyID,
			SUM(TotalBets)  AS TotalBets,
			SUM(TotalWins) AS TotalWins,
			SUM(TotalRefund) AS TotalRefund,
			SUM(CompanyTurnover) AS CompanyTurnover,		
			SUM(CompanyGrossIncome) AS CompanyGrossIncome,
			SUM(CompanyComm) AS CompanyComm
		FROM #Data
		GROUP BY CurrencyID
	)
	SELECT
		NoOfPlayers,
		e.currency,
		r.BetCount,
		r.TotalBets,
		r.TotalWins,
		r.TotalRefund,
		r.CompanyTurnover,
		r.CompanyGrossIncome,
		r.CompanyComm
	FROM Result r
		INNER JOIN dbo.Exchange e WITH (NOLOCK) ON r.CurrencyID = e.exchangeid
	--ORDER BY e.currency

	--- Total
	SELECT
		COUNT(DISTINCT custid) AS NoOfPlayers,
		SUM(BetCount) AS BetCount,
		SUM(TotalBets)  AS TotalBets,
		SUM(TotalWins) AS TotalWins,
		SUM(TotalRefund) AS TotalRefund,
		SUM(CompanyTurnover) AS CompanyTurnover,		
		SUM(CompanyGrossIncome) AS CompanyGrossIncome,
		SUM(CompanyComm) AS CompanyComm
	FROM #Data

	DROP TABLE #Data
	DROP TABLE #SportBettype
	DROP TABLE #tmp_bettrans
	DROP TABLE #tmp_Devide
	DROP TABLE #tmp_GameTableID
	DROP TABLE #tmp_LeagueID
	DROP TABLE #tmp_MemIDs
	DROP TABLE #tmp_SportType
END
GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_NonSportsProductStatistics_GrandTotal] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_NonSportsProductStatistics_GrandTotal] TO [vnteam];
GO