USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_Rpt_NonSportsProductStatistics_Customer_14]
	@WinlostDate	DATETIME,
	@ProductId		VARCHAR(MAX) = '',
	@Username		VARCHAR(5000) = '',
	@RoleID			TINYINT = 1,
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
	@HousePTValue   MONEY = 0,
	@IsDrillDown	BIT = 0,
	@IsGrandTotal	BIT = 0
AS

/*
	Creator: Percy
	Date: 2016-12-02
	DB: DBACC.bodb02
	Task: Risk and Control - Non-Sport Game Statistics Report - Report by Super/Master/Agent/Username

	Revisions:

	Param's Explanation:
		- @username: search keyword
		- @roleID:
			0: associated customer
			1,2,3,4: super/master/agent/member
		- @Site: List of Company filter
			'ALL'	: All sites (MBC + Licensees)
			'MBC'	: MBC sites only
			'12bet' : Specific Licensee Name 
		- @ProductID: string filter by Product 
		- @BetType: string filter by bettype
		- @LeagueId: string filter by LeagueId (only use for ProductID = 3 - Number Game get LeagueId)  
		- @Sporttype: string filter by Sporttype (only use for ProductID = 5 - Virtual Sports get Sporttype)
		- @GameTableId: filter by specific game table (only use for ProductID = 4 - Live Casino get leagueID)
		- @currency: 
			-1: All convert to RM currency
			 0: All original currencyID
			>0: Filter by original currencyID  
		- @TotalBetType, @GameIncomeType, @HousePTType: 
			 1: >=
			-1: <=
		- @TotalBetValue: Value to compare with SUM(actual_stake)
		- @GameIncomeValue: Value to compare with SUM(winlost-actual_stake)
		- @HousePTValue: Value to compare with 1-tpositiontaking
		- @IsDrillDown: drilldown master/agent/member from super/master/agent
		- @IsGrandTotal: drilldown grandtotal
*/

BEGIN
	SET NOCOUNT ON

	IF @IsGrandTotal = 1 AND @RoleID <> 0 -- click grand total not from associated link
	BEGIN
		EXEC dbo.Acc_Rpt_NonSportsProductStatistics_GrandTotal
				@WinlostDate = @WinlostDate,
				@ProductId = @ProductId,
				@Username = @Username,
				@Site = @Site,
				@BetType = @BetType,
				@LeagueId = @LeagueId,
				@Sporttype = @Sporttype,
				@GameTableId = @GameTableId,
				@Currency = @Currency,
				@Device = @Device,
				@ExcludeTest = @ExcludeTest,
				@TotalBetType = @TotalBetType,
				@TotalBetValue = @TotalBetValue,
				@GameIncomeType = @GameIncomeType,
				@GameIncomeValue = @GameIncomeValue,
				@HousePTType = @HousePTType,
				@HousePTValue = @HousePTValue
		
		RETURN
	END

	DECLARE @WLDate DATETIME, @UName VARCHAR(5000), @UrsName VARCHAR(5000)
	SELECT  @WLDate = @WinlostDate, @UrsName = @Username

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
	CREATE TABLE #tmp_MemIDs (CustID INT PRIMARY KEY, roleID TINYINT)
	
	SELECT  @UrsName = LTRIM(RTRIM(@UrsName))
	SELECT  @UName = '''' + REPLACE(@UrsName, ',', ''',''') + ''''
	DECLARE @SQL NVARCHAR(MAX)

	DECLARE @CID INT
	
	CREATE TABLE #CustUser (CustID INT, roleID TINYINT)
	IF @IsDrillDown = 1
	BEGIN
		SELECT @CID = custid FROM dbo.Customer WITH(NOLOCK) WHERE username = @UrsName AND roleid = @RoleID
	END
	ELSE IF @RoleID = 0 -- click associated accounts link
	BEGIN
		
		SELECT  @SQL = N'INSERT INTO #CustUser (CustID, roleID)
						SELECT custid, roleid FROM dbo.Customer WITH(NOLOCK)
						WHERE username IN (' + @UName + ')'
		EXEC sp_executesql @SQL
	END
	ELSE
	BEGIN
		IF @UrsName <> ''
		BEGIN
			INSERT INTO #CustUser (CustID)
			SELECT custid FROM dbo.Customer WITH(NOLOCK) WHERE username LIKE @UrsName + '%' AND roleid = @RoleID
		END
	END
	
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

		IF @UrsName <> ''
		BEGIN
			IF @IsDrillDown = 0
			BEGIN
				IF @RoleID IN (0,1)
				BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT c.custid, 1
					FROM
						dbo.Customer c WITH (NOLOCK)
						INNER JOIN #tmp_Company tc ON c.srecommend = tc.srecommend
						INNER JOIN #CustUser cu ON c.custid = cu.CustID
					WHERE c.roleid = 1
				END
				
				IF @RoleID IN (0,2)
				BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT c.custid, 1
					FROM
						dbo.Customer c WITH (NOLOCK)
						INNER JOIN #tmp_Company tc ON c.srecommend = tc.srecommend
						INNER JOIN #CustUser cu ON c.recommend = cu.CustID
					WHERE c.roleid = 1
				END
				
				IF @RoleID IN (0,3)
				BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT c.custid, 1
					FROM
						dbo.Customer c WITH (NOLOCK)
						INNER JOIN #tmp_Company tc ON c.srecommend = tc.srecommend
						INNER JOIN #CustUser cu ON c.mrecommend = cu.CustID
					WHERE c.roleid = 1
				END
				
				IF @RoleID IN (0,4)
				BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT c.custid, 1
					FROM
						dbo.Customer c WITH (NOLOCK)
						INNER JOIN #tmp_Company tc ON c.srecommend = tc.srecommend
						INNER JOIN #CustUser cu ON c.srecommend = cu.CustID
					WHERE c.roleid = 1
				END
			END
			ELSE -- @IsDrillDown = 1
			BEGIN
				IF @RoleID = 1
				BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT custid, 1
					FROM
						dbo.Customer c WITH (NOLOCK)
						INNER JOIN #tmp_Company tc ON c.srecommend = tc.srecommend
					WHERE c.custid = @CID AND roleid = 1
				END
				ELSE IF @RoleID = 2
				BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT custid, 1
					FROM
						dbo.Customer c WITH (NOLOCK)
						INNER JOIN #tmp_Company tc ON c.srecommend = tc.srecommend
					WHERE c.recommend = @CID AND roleid = 1
				END
				ELSE IF @RoleID = 3
				BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT custid, 1
					FROM
						dbo.Customer c WITH (NOLOCK)
						INNER JOIN #tmp_Company tc ON c.srecommend = tc.srecommend
					WHERE c.mrecommend = @CID AND roleid = 1
				END
				ELSE IF @RoleID = 4
				BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT custid, 1
					FROM
						dbo.Customer c WITH (NOLOCK)
						INNER JOIN #tmp_Company tc ON c.srecommend = tc.srecommend
					WHERE c.srecommend = @CID AND roleid = 1
				END
			END
		END
		ELSE -- @Username = ''
		BEGIN
			INSERT INTO #tmp_MemIDs (CustID, roleID)
			SELECT custid, 1
			FROM
				dbo.Customer c WITH (NOLOCK)
				INNER JOIN #tmp_Company tc ON c.srecommend = tc.srecommend
			WHERE c.roleid = 1
		END
	END
	ELSE
	BEGIN
		IF @UrsName <> ''
		BEGIN
			IF @IsDrillDown = 0
			BEGIN
				IF @RoleID IN (0,1)
				BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT c.custid, 1
					FROM
						dbo.Customer c WITH (NOLOCK)
						INNER JOIN #CustUser cu ON c.custid = cu.CustID
					WHERE c.roleid = 1
				END
				
				IF @RoleID IN (0,2)
				BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT c.custid, 1
					FROM
						dbo.Customer c WITH (NOLOCK)
						INNER JOIN #CustUser cu ON c.recommend = cu.CustID
					WHERE c.roleid = 1
				END
				
				IF @RoleID IN (0,3)
				BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT c.custid, 1
					FROM
						dbo.Customer c WITH (NOLOCK)
						INNER JOIN #CustUser cu ON c.mrecommend = cu.CustID
					WHERE c.roleid = 1
				END
				
				IF @RoleID IN (0,4)
				BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT c.custid, 1
					FROM
						dbo.Customer c WITH (NOLOCK)
						INNER JOIN #CustUser cu ON c.srecommend = cu.CustID
					WHERE c.roleid = 1
				END
			END
			ELSE -- @IsDrillDown = 1
			BEGIN
				IF @RoleID = 1
					BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT custid, 1
					FROM dbo.Customer WITH (NOLOCK)
					WHERE custid = @CID AND roleid = 1
				END
				ELSE IF @RoleID = 2
					BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT custid, 1
					FROM dbo.Customer WITH (NOLOCK)
					WHERE recommend = @CID AND roleid = 1
				END
				ELSE IF @RoleID = 3
					BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT custid, 1
					FROM dbo.Customer WITH (NOLOCK)
					WHERE mrecommend = @CID AND roleid = 1
				END
				ELSE IF @RoleID = 4
					BEGIN
					INSERT INTO #tmp_MemIDs (CustID, roleID)
					SELECT custid, 1
					FROM dbo.Customer WITH (NOLOCK)
					WHERE srecommend = @CID AND roleid = 1
				END
			END
		END
	END

	DROP TABLE #tmp_Site
	DROP TABLE #tmp_Company
	-- End Get Site --

	-- Select temp data of bettrans14
	CREATE TABLE #tmp_bettrans
	(
		srecommend INT,
		mrecommend INT,
		recommend INT,
		custid INT,
		BetCount BIGINT,
		CurrencyID INT,
		TotalBets MONEY,
		TotalBetsBase MONEY,
		TotalWins MONEY,
		TotalWinsBase MONEY,
		CompanyTurnover MONEY,
		CompanyTurnoverBase MONEY,
		CompanyGrossIncome MONEY,
		CompanyGrossIncomeBase MONEY,
		CompanyComm MONEY,
		CompanyCommBase MONEY,
		EvenType INT DEFAULT (-1), Matchid INT DEFAULT (-1), ProductID INT,
		tpositiontaking SMALLMONEY
	)

	IF EXISTS (SELECT TOP 1 1 FROM #tmp_MemIDs) -- has filter custid
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE RefTable IN (0, 3)) -- bettrans
		BEGIN
			INSERT INTO #tmp_bettrans
			(
				srecommend,
				mrecommend,
				recommend,
				custid,
				BetCount,
				CurrencyID,
				TotalBets,
				TotalBetsBase,
				TotalWins,
				TotalWinsBase,
				CompanyTurnover,
				CompanyTurnoverBase,
				CompanyGrossIncome,
				CompanyGrossIncomeBase,
				CompanyComm,
				CompanyCommBase,
				EvenType, Matchid, ProductID,
				tpositiontaking
			)
			SELECT
				b.srecommend,
				b.mrecommend,
				b.recommend,
				b.custid,
				COUNT(b.transid) AS BetCount,
				b.currency,
				SUM(actual_stake) AS TotalBets,
				SUM(actual_stake * actualrate) AS TotalBetsBase,
				SUM(winlost) AS TotalWins,
				SUM(winlost * actualrate) AS TotalWinsBase,
				SUM((1- b.tpositiontaking) * b.stake) AS CompanyTurnover,
				SUM((1- b.tpositiontaking) * b.stake * actualrate) AS CompanyTurnoverBase,
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost)) AS CompanyGrossIncome,
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost) * actualrate) AS CompanyGrossIncomeBase,
				SUM(scomm) AS CompanyComm,
				SUM(scomm *actualrate) AS CompanyCommBase,
				s.EvenType, b.matchid, s.ProductID,
				AVG(b.tpositiontaking) AS tpositiontaking
			FROM  dbo.bettrans14 b WITH (NOLOCK)
				INNER JOIN #tmp_MemIDs m ON b.custid = m.CustID
				INNER JOIN #SportBettype s ON s.Bettype = b.bettype
			WHERE b.winlostdate = @WLDate
				AND b.matchid >= 0
				AND b.statusID IN (111, 112, 113) -- won/lose/draw tickets
				AND s.RefTable IN (0, 3)
				AND ((b.currency <> 20 AND @ExcludeTest = 1) OR @ExcludeTest = 0)
				AND (b.currency = @Currency OR @Currency IN (0, -1))
				AND (EXISTS (SELECT 1 FROM #tmp_Devide d WHERE d.Betfrom = b.betfrom) OR @Device = '')
				AND (
					@HousePTType = 0
					OR (@HousePTType = -1 AND b.tpositiontaking >= 1-@HousePTValue) -- 1-tpositiontaking <= @HousePTValue
					OR (@HousePTType = 1 AND b.tpositiontaking <= 1-@HousePTValue) -- 1-tpositiontaking >= @HousePTValue
				)
			GROUP BY b.srecommend, b.mrecommend, b.recommend, b.custid, b.currency, s.EvenType, b.matchid, s.ProductID
		END

		IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE RefTable = 1) -- bettransRnG
		BEGIN
			INSERT INTO #tmp_bettrans
			(
				srecommend,
				mrecommend,
				recommend,
				custid,
				BetCount,
				CurrencyID,
				TotalBets,
				TotalBetsBase,
				TotalWins,
				TotalWinsBase,
				CompanyTurnover,
				CompanyTurnoverBase,
				CompanyGrossIncome,
				CompanyGrossIncomeBase,
				CompanyComm,
				CompanyCommBase,
				ProductID,
				tpositiontaking
			)
			SELECT
				b.srecommend,
				b.mrecommend,
				b.recommend,
				b.custid,
				COUNT(b.transid) AS BetCount,
				b.currency,
				SUM(actual_stake) AS TotalBets,
				SUM(actual_stake * actualrate) AS TotalBetsBase,
				SUM(winlost) AS TotalWins,
				SUM(winlost * actualrate) AS TotalWinsBase,
				SUM((1- b.tpositiontaking) * b.stake) AS CompanyTurnover,
				SUM((1- b.tpositiontaking) * b.stake * actualrate) AS CompanyTurnoverBase,
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost)) AS CompanyGrossIncome,
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost) * actualrate) AS CompanyGrossIncomeBase,
				SUM(scomm) AS CompanyComm,
				SUM(scomm *actualrate) AS CompanyCommBase,
				s.ProductID,
				AVG(b.tpositiontaking) AS tpositiontaking
			FROM dbo.bettransRnG14 b WITH (NOLOCK)
				INNER JOIN #tmp_MemIDs m ON b.custid = m.CustID
				INNER JOIN #SportBettype s ON s.Bettype = b.gameID
			WHERE b.winlostdate = @WLDate
				AND b.statusID IN (111, 112, 113) -- won/lose/draw tickets
				AND s.RefTable = 1		
				AND ((b.currency <> 20 AND @ExcludeTest = 1) OR @ExcludeTest = 0)
				AND (b.currency = @Currency OR @Currency IN (0, -1))
				AND (EXISTS (SELECT 1 FROM #tmp_Devide d WHERE d.Betfrom = b.betfrom) OR @Device = '')
				AND (
					@HousePTType = 0
					OR (@HousePTType = -1 AND b.tpositiontaking >= 1-@HousePTValue) -- 1-tpositiontaking <= @HousePTValue
					OR (@HousePTType = 1 AND b.tpositiontaking <= 1-@HousePTValue) -- 1-tpositiontaking >= @HousePTValue
				)
			GROUP BY b.srecommend, b.mrecommend, b.recommend, b.custid, b.currency, s.ProductID
		END
		
		IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE RefTable = 2) -- bettransLC
		BEGIN
			INSERT INTO #tmp_bettrans
			(
				srecommend,
				mrecommend,
				recommend,
				custid,
				BetCount,
				CurrencyID,
				TotalBets,
				TotalBetsBase,
				TotalWins,
				TotalWinsBase,
				CompanyTurnover,
				CompanyTurnoverBase,
				CompanyGrossIncome,
				CompanyGrossIncomeBase,
				CompanyComm,
				CompanyCommBase,
				ProductID,
				tpositiontaking
			)
			SELECT
				b.srecommend,
				b.mrecommend,
				b.recommend,
				b.custid,
				COUNT(b.transid) AS BetCount,
				b.currency,
				SUM(actual_stake) AS TotalBets,
				SUM(actual_stake * actualrate) AS TotalBetsBase,
				SUM(winlost) AS TotalWins,
				SUM(winlost * actualrate) AS TotalWinsBase,
				SUM((1- b.tpositiontaking) * b.stake) AS CompanyTurnover,
				SUM((1- b.tpositiontaking) * b.stake * actualrate) AS CompanyTurnoverBase,
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost)) AS CompanyGrossIncome,
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost) * actualrate) AS CompanyGrossIncomeBase,
				SUM(scomm) AS CompanyComm,
				SUM(scomm *actualrate) AS CompanyCommBase,
				s.ProductID,
				AVG(b.tpositiontaking) AS tpositiontaking
			FROM dbo.bettransLC14 b WITH (NOLOCK)
				INNER JOIN #tmp_MemIDs m ON b.custid = m.CustID
				INNER JOIN #SportBettype s ON s.Bettype = b.gameID
			WHERE b.winlostdate = @WLDate
				AND b.statusID IN (111, 112, 113) -- won/lose/draw tickets
				AND s.RefTable = 1		
				AND ((b.currency <> 20 AND @ExcludeTest = 1) OR @ExcludeTest = 0)
				AND (b.currency = @Currency OR @Currency IN (0, -1))
				AND (EXISTS (SELECT 1 FROM #tmp_Devide d WHERE d.Betfrom = b.betfrom) OR @Device = '')
				AND (
					@HousePTType = 0
					OR (@HousePTType = -1 AND b.tpositiontaking >= 1-@HousePTValue) -- 1-tpositiontaking <= @HousePTValue
					OR (@HousePTType = 1 AND b.tpositiontaking <= 1-@HousePTValue) -- 1-tpositiontaking >= @HousePTValue
				)
			GROUP BY b.srecommend, b.mrecommend, b.recommend, b.custid, b.currency, s.ProductID
		END
	END
	ELSE -- non filter custid
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE RefTable IN (0, 3)) -- bettrans
		BEGIN
			INSERT INTO #tmp_bettrans
			(
				srecommend,
				mrecommend,
				recommend,
				custid,
				BetCount,
				CurrencyID,
				TotalBets,
				TotalBetsBase,
				TotalWins,
				TotalWinsBase,
				CompanyTurnover,
				CompanyTurnoverBase,
				CompanyGrossIncome,
				CompanyGrossIncomeBase,
				CompanyComm,
				CompanyCommBase,
				EvenType, matchid, ProductID,
				tpositiontaking
			)
			SELECT
				b.srecommend,
				b.mrecommend,
				b.recommend,
				b.custid,
				COUNT(b.transid) AS BetCount,
				b.currency,
				SUM(actual_stake) AS TotalBets,
				SUM(actual_stake * actualrate) AS TotalBetsBase,
				SUM(winlost) AS TotalWins,
				SUM(winlost * actualrate) AS TotalWinsBase,
				SUM((1- b.tpositiontaking) * b.stake) AS CompanyTurnover,
				SUM((1- b.tpositiontaking) * b.stake * actualrate) AS CompanyTurnoverBase,
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost)) AS CompanyGrossIncome,
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost) * actualrate) AS CompanyGrossIncomeBase,
				SUM(scomm) AS CompanyComm,
				SUM(scomm *actualrate) AS CompanyCommBase,
				s.EvenType, b.matchid, s.ProductID,
				AVG(b.tpositiontaking) AS tpositiontaking
			FROM  dbo.bettrans14 b WITH (NOLOCK)
				INNER JOIN #SportBettype s ON s.Bettype = b.bettype
			WHERE b.winlostdate = @WLDate
				AND b.statusID IN (111, 112, 113) -- won/lose/draw tickets
				AND b.matchid >= 0
				AND s.RefTable IN (0, 3)
				AND ((b.currency <> 20 AND @ExcludeTest = 1) OR @ExcludeTest = 0)
				AND (b.currency = @Currency OR @Currency IN (0, -1))
				AND (EXISTS (SELECT 1 FROM #tmp_Devide d WHERE d.Betfrom = b.betfrom) OR @Device = '')
				AND (
					@HousePTType = 0
					OR (@HousePTType = -1 AND b.tpositiontaking >= 1-@HousePTValue) -- 1-tpositiontaking <= @HousePTValue
					OR (@HousePTType = 1 AND b.tpositiontaking <= 1-@HousePTValue) -- 1-tpositiontaking >= @HousePTValue
				)
			GROUP BY b.srecommend, b.mrecommend, b.recommend, b.custid, b.currency, s.EvenType, b.matchid, s.ProductID
		END

		IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE RefTable = 1) -- bettransRnG
		BEGIN
			INSERT INTO #tmp_bettrans
			(
				srecommend,
				mrecommend,
				recommend,
				custid,
				BetCount,
				CurrencyID,
				TotalBets,
				TotalBetsBase,
				TotalWins,
				TotalWinsBase,
				CompanyTurnover,
				CompanyTurnoverBase,
				CompanyGrossIncome,
				CompanyGrossIncomeBase,
				CompanyComm,
				CompanyCommBase,
				ProductID,
				tpositiontaking
			)
			SELECT
				b.srecommend,
				b.mrecommend,
				b.recommend,
				b.custid,
				COUNT(b.transid) AS BetCount,
				b.currency,
				SUM(actual_stake) AS TotalBets,
				SUM(actual_stake * actualrate) AS TotalBetsBase,
				SUM(winlost) AS TotalWins,
				SUM(winlost * actualrate) AS TotalWinsBase,
				SUM((1- b.tpositiontaking) * b.stake) AS CompanyTurnover,
				SUM((1- b.tpositiontaking) * b.stake * actualrate) AS CompanyTurnoverBase,
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost)) AS CompanyGrossIncome,
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost) * actualrate) AS CompanyGrossIncomeBase,
				SUM(scomm) AS CompanyComm,
				SUM(scomm *actualrate) AS CompanyCommBase,
				s.ProductID,
				AVG(b.tpositiontaking) AS tpositiontaking
			FROM dbo.bettransRnG14 b WITH (NOLOCK)
				INNER JOIN #SportBettype s ON s.Bettype = b.gameID
			WHERE b.winlostdate = @WLDate
				AND b.statusID IN (111, 112, 113) -- won/lose/draw tickets
				AND s.RefTable = 1		
				AND ((b.currency <> 20 AND @ExcludeTest = 1) OR @ExcludeTest = 0)
				AND (b.currency = @Currency OR @Currency IN (0, -1))
				AND (EXISTS (SELECT 1 FROM #tmp_Devide d WHERE d.Betfrom = b.betfrom) OR @Device = '')
				AND (
					@HousePTType = 0
					OR (@HousePTType = -1 AND b.tpositiontaking >= 1-@HousePTValue) -- 1-tpositiontaking <= @HousePTValue
					OR (@HousePTType = 1 AND b.tpositiontaking <= 1-@HousePTValue) -- 1-tpositiontaking >= @HousePTValue
				)
			GROUP BY b.srecommend, b.mrecommend, b.recommend, b.custid, b.currency, s.ProductID
		END

		IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE RefTable = 2) -- bettransLC
		BEGIN
			INSERT INTO #tmp_bettrans
			(
				srecommend,
				mrecommend,
				recommend,
				custid,
				BetCount,
				CurrencyID,
				TotalBets,
				TotalBetsBase,
				TotalWins,
				TotalWinsBase,
				CompanyTurnover,
				CompanyTurnoverBase,
				CompanyGrossIncome,
				CompanyGrossIncomeBase,
				CompanyComm,
				CompanyCommBase,
				ProductID,
				tpositiontaking
			)
			SELECT
				b.srecommend,
				b.mrecommend,
				b.recommend,
				b.custid,
				COUNT(b.transid) AS BetCount,
				b.currency,
				SUM(actual_stake) AS TotalBets,
				SUM(actual_stake * actualrate) AS TotalBetsBase,
				SUM(winlost) AS TotalWins,
				SUM(winlost * actualrate) AS TotalWinsBase,
				SUM((1- b.tpositiontaking) * b.stake) AS CompanyTurnover,
				SUM((1- b.tpositiontaking) * b.stake * actualrate) AS CompanyTurnoverBase,
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost)) AS CompanyGrossIncome,
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost) * actualrate) AS CompanyGrossIncomeBase,
				SUM(scomm) AS CompanyComm,
				SUM(scomm *actualrate) AS CompanyCommBase,
				s.ProductID,
				AVG(b.tpositiontaking) AS tpositiontaking
			FROM dbo.bettransLC14 b WITH (NOLOCK)
				INNER JOIN #SportBettype s ON s.Bettype = b.gameID
			WHERE b.winlostdate = @WLDate
				AND b.statusID IN (111, 112, 113) -- won/lose/draw tickets
				AND s.RefTable = 2		
				AND ((b.currency <> 20 AND @ExcludeTest = 1) OR @ExcludeTest = 0)
				AND (b.currency = @Currency OR @Currency IN (0, -1))
				AND (EXISTS (SELECT 1 FROM #tmp_Devide d WHERE d.Betfrom = b.betfrom) OR @Device = '')
				AND (
					@HousePTType = 0
					OR (@HousePTType = -1 AND b.tpositiontaking >= 1-@HousePTValue) -- 1-tpositiontaking <= @HousePTValue
					OR (@HousePTType = 1 AND b.tpositiontaking <= 1-@HousePTValue) -- 1-tpositiontaking >= @HousePTValue
				)
			GROUP BY b.srecommend, b.mrecommend, b.recommend, b.custid, b.currency, s.ProductID
		END
	END

	-- Get data
	CREATE TABLE #Data
	( 
		srecommend INT,
		mrecommend INT,
		recommend INT,
		custid BIGINT,
		BetCount INT,
		CurrencyID INT,
		TotalBets MONEY,
		TotalBetsBase MONEY,
		TotalWins MONEY,
		TotalWinsBase MONEY,
		CompanyTurnover MONEY,
		CompanyTurnoverBase MONEY,
		CompanyGrossIncome MONEY,
		CompanyGrossIncomeBase MONEY,
		CompanyComm MONEY,
		CompanyCommBase MONEY,
		tpositiontaking SMALLMONEY
	)
	--- Check condition 
	IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE ProductID NOT IN (3, 4, 5)) -- NG, SLI-Live Casino, Virtual Sport
	BEGIN		
		INSERT INTO #Data
		(
			srecommend,
			mrecommend,
			recommend,
			custid,
			BetCount,
			CurrencyID,
			TotalBets,
			TotalBetsBase,
			TotalWins,
			TotalWinsBase,
			CompanyTurnover,
			CompanyTurnoverBase,
			CompanyGrossIncome,
			CompanyGrossIncomeBase,
			CompanyComm,
			CompanyCommBase,
			tpositiontaking
		)
		SELECT
			srecommend,
			mrecommend,
			recommend,
			custid,
			SUM(BetCount) AS BetCount,
			CurrencyID,
			SUM(TotalBets) AS TotalBets,
			SUM(TotalBetsBase) AS TotalBetsBase,
			SUM(TotalWins) AS TotalWins,
			SUM(TotalWinsBase) AS TotalWinsBase,
			SUM(CompanyTurnover) AS CompanyTurnover,
			SUM(CompanyTurnoverBase) AS CompanyTurnoverBase,
			- SUM(CompanyGrossIncome) AS CompanyGrossIncome,
			- SUM(CompanyGrossIncomeBase) AS CompanyGrossIncomeBase,
			- SUM(CompanyComm) AS CompanyComm,
			- SUM(CompanyCommBase) AS CompanyCommBase,
			AVG(tpositiontaking) AS tpositiontaking
		FROM  #tmp_bettrans
		WHERE ProductID NOT IN (3, 4, 5)
		GROUP BY srecommend, mrecommend, recommend, custid, CurrencyID
	END

	IF EXISTS (SELECT TOP 1 1 FROM #SportBettype WHERE ProductID IN (3, 4, 5)) -- NG, SLI-Live Casino, Virtual Sport
	BEGIN		
		INSERT INTO #Data
		(
			srecommend,
			mrecommend,
			recommend,
			custid,
			BetCount,
			CurrencyID,
			TotalBets,
			TotalBetsBase,
			TotalWins,
			TotalWinsBase,
			CompanyTurnover,
			CompanyTurnoverBase,
			CompanyGrossIncome,
			CompanyGrossIncomeBase,
			CompanyComm,
			CompanyCommBase,
			tpositiontaking
		)
		SELECT
			srecommend,
			mrecommend,
			recommend,
			custid,
			SUM(BetCount) AS BetCount,
			CurrencyID,
			SUM(TotalBets) AS TotalBets,
			SUM(TotalBetsBase) AS TotalBetsBase,
			SUM(TotalWins) AS TotalWins,
			SUM(TotalWinsBase) AS TotalWinsBase,
			SUM(CompanyTurnover) AS CompanyTurnover,
			SUM(CompanyTurnoverBase) AS CompanyTurnoverBase,
			- SUM(CompanyGrossIncome) AS CompanyGrossIncome,
			- SUM(CompanyGrossIncomeBase) AS CompanyGrossIncomeBase,
			- SUM(CompanyComm) AS CompanyComm,
			- SUM(CompanyCommBase) AS CompanyCommBase,
			AVG(tpositiontaking) AS tpositiontaking
		FROM  #tmp_bettrans b
			INNER JOIN dbo.match14 m WITH (NOLOCK) ON m.matchid = b.matchid
		WHERE ProductID IN (3, 4, 5) AND b.EvenType = 1
			AND (
				(b.ProductID = 3 AND (@LeagueId = '' OR (EXISTS (SELECT 1 FROM #tmp_LeagueID l WHERE l.LeagueID = m.leagueid)))) OR
				(b.ProductID = 4 AND (@GameTableId = '' OR (EXISTS (SELECT 1 FROM #tmp_GameTableID g WHERE g.GameTableID = m.leagueid)))) OR
				(b.ProductID = 5 AND (@Sporttype = '' OR (EXISTS (SELECT 1 FROM #tmp_SportType st WHERE st.Sporttype = m.sporttype))))
			)
		GROUP BY srecommend, mrecommend, recommend, custid, CurrencyID

		-- HR
		INSERT INTO #Data
		(
			srecommend,
			mrecommend,
			recommend,
			custid,
			BetCount,
			CurrencyID,
			TotalBets,
			TotalBetsBase,
			TotalWins,
			TotalWinsBase,
			CompanyTurnover,
			CompanyTurnoverBase,
			CompanyGrossIncome,
			CompanyGrossIncomeBase,
			CompanyComm,
			CompanyCommBase,
			tpositiontaking
		)
		SELECT
			srecommend,
			mrecommend,
			recommend,
			custid,
			SUM(BetCount) AS BetCount,
			CurrencyID,
			SUM(TotalBets) AS TotalBets,
			SUM(TotalBetsBase) AS TotalBetsBase,
			SUM(TotalWins) AS TotalWins,
			SUM(TotalWinsBase) AS TotalWinsBase,
			SUM(CompanyTurnover) AS CompanyTurnover,
			SUM(CompanyTurnoverBase) AS CompanyTurnoverBase,
			- SUM(CompanyGrossIncome) AS CompanyGrossIncome,
			- SUM(CompanyGrossIncomeBase) AS CompanyGrossIncomeBase,
			- SUM(CompanyComm) AS CompanyComm,
			- SUM(CompanyCommBase) AS CompanyCommBase,
			AVG(tpositiontaking) AS tpositiontaking
		FROM  #tmp_bettrans b
			INNER JOIN dbo.VSRaceInfo r WITH (NOLOCK) ON r.EventID = b.matchid
		WHERE b.ProductID = 5 AND b.EvenType = 3
			AND (@Sporttype = '' OR (EXISTS(SELECT 1 FROM #tmp_SportType st WHERE st.Sporttype = r.SportType)))			  
		GROUP BY b.srecommend, b.mrecommend, b.recommend, b.custid, b.CurrencyID
	END

	-- Return Data
	IF @roleID IN (1,2,3,4) -- member (username) / agent / master / super
	BEGIN
		IF @IsDrillDown = 1
		BEGIN
			SELECT @roleID = @roleID - 1
		END

		IF @Currency = -1 OR @IsGrandTotal = 1 -- base RM
		BEGIN
			;WITH Result AS (
				SELECT
					CASE @roleID
						WHEN 1 THEN custid
						WHEN 2 THEN recommend
						WHEN 3 THEN mrecommend
						WHEN 4 THEN srecommend
						END AS custid,
					SUM(BetCount) AS BetCount,
					CurrencyID,
					SUM(TotalBetsBase)  AS TotalBets,
					SUM(TotalWinsBase) AS TotalWins,
					SUM(CompanyTurnoverBase) AS CompanyTurnover,		
					SUM(CompanyGrossIncomeBase) AS CompanyGrossIncome,
					SUM(CompanyCommBase) AS CompanyComm,
					AVG(tpositiontaking) AS tpositiontaking
				FROM #Data
				GROUP BY CASE @roleID
						WHEN 1 THEN custid
						WHEN 2 THEN recommend
						WHEN 3 THEN mrecommend
						WHEN 4 THEN srecommend
						END, CurrencyID
				HAVING
					(
						@TotalBetType = 0
						OR (@TotalBetType = 1 AND SUM(TotalBets) >= @TotalBetValue) 
						OR (@TotalBetType = -1 AND SUM(TotalBets) <= @TotalBetValue)
					)
					AND
					(
						@GameIncomeType = 0
						OR (@GameIncomeType = 1 AND SUM(TotalBets - TotalWins) >= @GameIncomeValue) 
						OR (@GameIncomeType = -1 AND SUM(TotalBets - TotalWins) <= @GameIncomeValue)
					)
			)
			SELECT
				c.custid AS ReportById,
				c.username AS ReportBy,
				c.roleid AS RoleId,
				CASE c.roleid WHEN 1 THEN 'Member' WHEN 2 THEN 'Agent' WHEN 3 THEN 'Master' WHEN 4 THEN 'Super' ELSE '' END AS RoleName,
				e.exchangeid AS CurrencyId,
				e.currency AS Currency,
				r.BetCount,
				r.TotalBets,
				r.TotalWins,
				r.CompanyTurnover,
				r.CompanyGrossIncome,
				r.CompanyComm,
				1-tpositiontaking AS HousePT
			FROM Result r
				INNER JOIN dbo.Exchange e WITH (NOLOCK) ON r.CurrencyID = e.exchangeid
				INNER JOIN dbo.Customer c WITH (NOLOCK) ON r.custid = c.custid
			ORDER BY c.username
		END
		ELSE
		BEGIN
			;WITH Result AS (
				SELECT
					CASE @roleID
						WHEN 1 THEN custid
						WHEN 2 THEN recommend
						WHEN 3 THEN mrecommend
						WHEN 4 THEN srecommend
						END AS custid,
					SUM(BetCount) AS BetCount,
					CurrencyID,
					SUM(TotalBets)  AS TotalBets,
					SUM(TotalWins) AS TotalWins,
					SUM(CompanyTurnover) AS CompanyTurnover,		
					SUM(CompanyGrossIncome) AS CompanyGrossIncome,
					SUM(CompanyComm) AS CompanyComm,
					AVG(tpositiontaking) AS tpositiontaking
				FROM #Data
				GROUP BY CASE @roleID
						WHEN 1 THEN custid
						WHEN 2 THEN recommend
						WHEN 3 THEN mrecommend
						WHEN 4 THEN srecommend
						END, CurrencyID
				HAVING
					(
						@TotalBetType = 0
						OR (@TotalBetType = 1 AND SUM(TotalBets) >= @TotalBetValue) 
						OR (@TotalBetType = -1 AND SUM(TotalBets) <= @TotalBetValue)
					)
					AND
					(
						@GameIncomeType = 0
						OR (@GameIncomeType = 1 AND SUM(TotalBets - TotalWins) >= @GameIncomeValue) 
						OR (@GameIncomeType = -1 AND SUM(TotalBets - TotalWins) <= @GameIncomeValue)
					)
			)
			SELECT
				c.custid AS ReportById,
				c.username AS ReportBy,
				c.roleid AS RoleId,
				CASE c.roleid WHEN 1 THEN 'Member' WHEN 2 THEN 'Agent' WHEN 3 THEN 'Master' WHEN 4 THEN 'Super' ELSE '' END AS RoleName,
				e.exchangeid AS CurrencyId,
				e.currency AS Currency,
				r.BetCount,
				r.TotalBets,
				r.TotalWins,
				r.CompanyTurnover,
				r.CompanyGrossIncome,
				r.CompanyComm,
				1-tpositiontaking AS HousePT
			FROM Result r
				INNER JOIN dbo.Exchange e WITH (NOLOCK) ON r.CurrencyID = e.exchangeid
				INNER JOIN dbo.Customer c WITH (NOLOCK) ON r.custid = c.custid
			ORDER BY c.username
		END
	END
	ELSE -- @roleID = 0 --> click associated accounts link
	BEGIN
		IF @Currency = -1 -- base RM
		BEGIN
			;WITH Result AS (
				SELECT
					c.custid,
					SUM(BetCount) AS BetCount,
					CurrencyID,
					SUM(TotalBetsBase)  AS TotalBets,
					SUM(TotalWinsBase) AS TotalWins,
					SUM(CompanyTurnoverBase) AS CompanyTurnover,		
					SUM(CompanyGrossIncomeBase) AS CompanyGrossIncome,
					SUM(CompanyCommBase) AS CompanyComm,
					AVG(tpositiontaking) AS tpositiontaking
				FROM #Data d
					INNER JOIN #CustUser c
						ON c.CustID = CASE c.roleID
										WHEN 1 THEN d.custid
										WHEN 2 THEN d.recommend
										WHEN 3 THEN d.mrecommend
										WHEN 4 THEN d.srecommend
										END
				GROUP BY c.custid, CurrencyID
				HAVING
					(
						@TotalBetType = 0
						OR (@TotalBetType = 1 AND SUM(TotalBets) >= @TotalBetValue) 
						OR (@TotalBetType = -1 AND SUM(TotalBets) <= @TotalBetValue)
					)
					AND
					(
						@GameIncomeType = 0
						OR (@GameIncomeType = 1 AND SUM(TotalBets - TotalWins) >= @GameIncomeValue) 
						OR (@GameIncomeType = -1 AND SUM(TotalBets - TotalWins) <= @GameIncomeValue)
					)
			)
			SELECT
				c.custid AS ReportById,
				c.username AS ReportBy,
				c.roleid AS RoleId,
				CASE c.roleid WHEN 1 THEN 'Member' WHEN 2 THEN 'Agent' WHEN 3 THEN 'Master' WHEN 4 THEN 'Super' ELSE '' END AS RoleName,
				e.exchangeid AS CurrencyId,
				e.currency AS Currency,
				r.BetCount,
				r.TotalBets,
				r.TotalWins,
				r.CompanyTurnover,
				r.CompanyGrossIncome,
				r.CompanyComm,
				1-tpositiontaking AS HousePT
			FROM Result r
				INNER JOIN dbo.Exchange e WITH (NOLOCK) ON r.CurrencyID = e.exchangeid
				INNER JOIN dbo.Customer c WITH (NOLOCK) ON r.custid = c.custid
			ORDER BY c.username
		END
		ELSE
		BEGIN
			;WITH Result AS (
				SELECT
					c.custid,
					SUM(BetCount) AS BetCount,
					CurrencyID,
					SUM(TotalBets)  AS TotalBets,
					SUM(TotalWins) AS TotalWins,
					SUM(CompanyTurnover) AS CompanyTurnover,		
					SUM(CompanyGrossIncome) AS CompanyGrossIncome,
					SUM(CompanyComm) AS CompanyComm,
					AVG(tpositiontaking) AS tpositiontaking
				FROM #Data d
					INNER JOIN #CustUser c
						ON c.CustID = CASE c.roleID
										WHEN 1 THEN d.custid
										WHEN 2 THEN d.recommend
										WHEN 3 THEN d.mrecommend
										WHEN 4 THEN d.srecommend
										END
				GROUP BY c.custid, CurrencyID
				HAVING
					(
						@TotalBetType = 0
						OR (@TotalBetType = 1 AND SUM(TotalBets) >= @TotalBetValue) 
						OR (@TotalBetType = -1 AND SUM(TotalBets) <= @TotalBetValue)
					)
					AND
					(
						@GameIncomeType = 0
						OR (@GameIncomeType = 1 AND SUM(TotalBets - TotalWins) >= @GameIncomeValue) 
						OR (@GameIncomeType = -1 AND SUM(TotalBets - TotalWins) <= @GameIncomeValue)
					)
			)
			SELECT
				c.custid AS ReportById,
				c.username AS ReportBy,
				c.roleid AS RoleId,
				CASE c.roleid WHEN 1 THEN 'Member' WHEN 2 THEN 'Agent' WHEN 3 THEN 'Master' WHEN 4 THEN 'Super' ELSE '' END AS RoleName,
				e.exchangeid AS CurrencyId,
				e.currency AS Currency,
				r.BetCount,
				r.TotalBets,
				r.TotalWins,
				r.CompanyTurnover,
				r.CompanyGrossIncome,
				r.CompanyComm,
				1-tpositiontaking AS HousePT
			FROM Result r
				INNER JOIN dbo.Exchange e WITH (NOLOCK) ON r.CurrencyID = e.exchangeid
				INNER JOIN dbo.Customer c WITH (NOLOCK) ON r.custid = c.custid
			ORDER BY c.username
		END
	END

	--- Total
	SELECT
		'GrandTotal' AS ReportBy,
		SUM(BetCount) AS BetCount,
		-1 AS CurrencyId,
		'RM' AS Currency,
		SUM(TotalBetsBase)  AS TotalBets,
		SUM(TotalWinsBase) AS TotalWins,
		SUM(CompanyTurnoverBase) AS CompanyTurnover,		
		SUM(CompanyGrossIncomeBase) AS CompanyGrossIncome,
		SUM(CompanyCommBase) AS CompanyComm,
		1-AVG(tpositiontaking) AS HousePT
	FROM #Data
	HAVING
		(
			@TotalBetType = 0
			OR (@TotalBetType = 1 AND SUM(TotalBets) >= @TotalBetValue) 
			OR (@TotalBetType = -1 AND SUM(TotalBets) <= @TotalBetValue)
		)
		AND
		(
			@GameIncomeType = 0
			OR (@GameIncomeType = 1 AND SUM(TotalBets - TotalWins) >= @GameIncomeValue) 
			OR (@GameIncomeType = -1 AND SUM(TotalBets - TotalWins) <= @GameIncomeValue)
		)

	DROP TABLE #Data
	DROP TABLE #SportBettype
	DROP TABLE #tmp_bettrans
	DROP TABLE #tmp_Devide
	DROP TABLE #tmp_GameTableID
	DROP TABLE #tmp_LeagueID
	DROP TABLE #tmp_MemIDs
	DROP TABLE #tmp_SportType
	DROP TABLE #CustUser
END
GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_NonSportsProductStatistics_Customer_14] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_NonSportsProductStatistics_Customer_14] TO [vnteam];
GO