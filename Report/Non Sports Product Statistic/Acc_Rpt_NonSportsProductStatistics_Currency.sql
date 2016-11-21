USE bodb02
GO

ALTER PROCEDURE [dbo].[Acc_Rpt_NonSportsProductStatistics_Currency]
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
	@HousePTValue   MONEY = 0,
	@DrillDownCurrency	SMALLINT = 0
AS
/*
	Created	: 20161114@Harper
	Task	: #62430_Non Sports Product Statistic - Currency Report
	DB		: DBACC/bodb02
	
	Revision:

	Param's Explanation:
		- @Username:  + Search by keyword, member only
		- @Site: List of Company filter
			'ALL': All sites (MBC + Licensees)
			'MBC': MBC sites only
			'12bet' : Specific Licensee Name 
		- @ProductID: string filter by Product 
		- @BetType: string filter by bettype
		- @LeagueId: string filter by LeagueId (ProductID = 3 - Number Game get LeagueId)  
		- @Sporttype: string filter by Sporttype (ProductID = 5 - Virtual Sports get Sporttype)
		- @GameTableId: filter by specific game table (ProductID = 4 - Live Casino get leagueID)
		- @Currency: 
			-1: All and convert to RM
			0: All without convert (original)
			>0: Filter by currency ID without convert (original)  
		- @TotalBetType : 
			1 : is >=
			-1 : is <=
		- @TotalBetValue : Value to compare with @TotalBetType
		- @HousePTType : 
			1 : is >=
			-1 : is <=
		- @HousePTValue : Value to compare with @HousePTType
		- @DrillDownCurrency: 
			0	: Not drilldown
			> 0	: drilldown with this currency to Company level

	exec Acc_Rpt_NonSportsProductStatistics_Currency_14 @TotalBetValue=0.0000,@Sporttype='',@ProductId='21',
	@Username='',@BetType='2401,2405,2403,2404,2402',@GameIncomeValue=0.0000,
	@HousePTValue=0.0000,@HousePTType=0,@GameIncomeType=0,@TotalBetType=0,@WinlostDate='2016-11-06 00:00:00',
	@DrillDownCurrency=47,@ExcludeTest=1,@LeagueId='',@Device='a,d,e,h,i,f,j,l,m,n,p,s,u,w',
	@GameTableId='',@Currency=-1,@Site='All'
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @WLDate DATETIME
	SELECT @WLDate = @WinlostDate

	CREATE TABLE #Data ( Srecommend INT, CustID INT,
						 BetCount INT, CurrencyID INT, Currency NVARCHAR(50),
						 TotalBets MONEY, TotalBetsBase MONEY,
						 TotalWins MONEY, TotalWinsBase MONEY,
						 TotalRefund MONEY, TotalRefundBase MONEY,
						 CompanyTurnOver MONEY, CompanyTurnOverBase MONEY,
						 CompanyGrossIncome MONEY, CompanyGrossIncomeBase MONEY,
						 CompanyComm MONEY, CompanyCommBase MONEY
						)

	CREATE TABLE #ResultByCompany (  
							IsDeposit BIT, SiteName VARCHAR(50), NoOfPlayers INT,
							BetCount INT, CurrencyID INT, Currency NVARCHAR(50)	,
							TotalBets MONEY, TotalBetsBase MONEY,
							TotalWins MONEY, TotalWinsBase MONEY,
							TotalRefund MONEY, TotalRefundBase MONEY,
							CompanyTurnOver MONEY, CompanyTurnOverBase MONEY,
							CompanyGrossIncome MONEY, CompanyGrossIncomeBase MONEY,
							CompanyComm MONEY, CompanyCommBase MONEY							
						)

	CREATE TABLE #ResultByCurrency (  
							CurrencyID INT, Currency NVARCHAR(50),
							NoOfPlayers INT, BetCount INT, 
							TotalBets MONEY, TotalBetsBase MONEY,
							TotalWins MONEY, TotalWinsBase MONEY,
							TotalRefund MONEY, TotalRefundBase MONEY,
							CompanyTurnOver MONEY, CompanyTurnOverBase MONEY,
							CompanyGrossIncome MONEY, CompanyGrossIncomeBase MONEY,
							CompanyComm MONEY, CompanyCommBase MONEY							
						)

	------------------------------------------I. Handle Parameter ------------------------------------------------------

	CREATE TABLE #tmp_ProductID		(ProductID INT)
	CREATE TABLE #tmp_BetType		(Bettype INT)
	CREATE TABLE #tmp_LeagueID		(LeagueID INT)
	CREATE TABLE #tmp_SportType		(Sporttype INT)
	CREATE TABLE #tmp_GameTableID	(GameTableID INT)
	CREATE TABLE #tmp_Devide		(Betfrom NVARCHAR(2))
	CREATE TABLE #tmp_Site			(Site VARCHAR(50))
	CREATE TABLE #tmp_MemIDs		(CustID INT)	

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

	-- Get Cust Info
	IF @Username <> ''
	BEGIN
		INSERT INTO #tmp_MemIDs (CustID)
		SELECT custid 
		FROM dbo.custInfo WITH (NOLOCK)
		WHERE username LIKE + @Username + '%' AND roleid = 1
	END
	-- End Cust Info

	-- Get Sport Bettype Matrix
	DECLARE @isTest BIT = 0
	SELECT @isTest = dbo.f_CheckSPVersion(@@PROCID)

	CREATE TABLE #SportBettype (ProductID INT, Bettype INT, EvenType INT, SubProduct VARCHAR(500), RefTable SMALLINT)
	
	INSERT INTO #SportBettype (ProductID, Bettype, EvenType, SubProduct, RefTable)
	SELECT s.ProductID, s.BetType, s.EventType, s.SubProduct, s.RefTable
	FROM dbo.f_SportBettypeMatrix_Sel(0, 0, 0, 2, '', '', @isTest) s
		INNER JOIN #tmp_ProductID p ON p.ProductID = s.ProductID

	DELETE s
	FROM #SportBettype s
	WHERE s.ProductID NOT IN (3, 5) -- NumberGame, Virtual Sport
		AND NOT EXISTS (SELECT b.Bettype FROM #tmp_BetType b WHERE b.Bettype = s.Bettype)
	-- End Sport Bettype Matrix

	-- Get Site	
	CREATE TABLE #tmp_Company (SiteName VARCHAR(50), Srecommend INT, isDeposit BIT)

	IF @Site <> 'ALL'
	BEGIN
		INSERT INTO #tmp_Site (Site)
		SELECT RTRIM(LTRIM(val)) FROM dbo.strSplit(@Site, ',')

		IF EXISTS (SELECT 1 FROM #tmp_Site WHERE Site NOT IN ('MBC Group')) -- Deposit Or Credit Drill Down
		BEGIN	
			INSERT INTO #tmp_Company (SiteName, Srecommend, isDeposit)
			SELECT s.Site, c.srecommend, ss.isDeposit
			FROM #tmp_Site s
				INNER JOIN dbo.Site ss WITH (NOLOCK) ON s.Site = ss.site
				INNER JOIN dbo.Customer c WITH (NOLOCK) ON ss.Site = c.site
			WHERE c.roleid = 4
		END

		IF EXISTS (SELECT 1 FROM #tmp_Site WHERE Site IN ('MBC Group'))					
		BEGIN
			INSERT INTO #tmp_Company (SiteName, Srecommend, isDeposit)
			SELECT c.site, c.srecommend, 0
			FROM dbo.Customer c WITH (NOLOCK)
			WHERE c.roleid = 4
				AND NOT EXISTS (SELECT 1 FROM dbo.f_DepSuper_1('ALL') f WHERE c.srecommend = f.CustID)
		END
		
	END
	ELSE -- ALL
	BEGIN
		INSERT INTO #tmp_Company (SiteName, Srecommend, isDeposit)
		SELECT ss.site, c.srecommend, ss.isDeposit
		FROM dbo.Customer c WITH (NOLOCK) 
			INNER JOIN dbo.Site ss WITH (NOLOCK) ON ss.Site = c.site
		WHERE c.roleid = 4	
	END

	CREATE NONCLUSTERED INDEX Idx_SrecommendID ON #tmp_Company (Srecommend)
	-- End Site	

	------------------------------------------II. Get Real Data For Report ------------------------------------------------------
	-- Select temp data of bettrans
	CREATE TABLE #tmp_bettrans ( Srecommend INT, CustID INT,
						 BetCount BIGINT, CurrencyID INT, Currency NVARCHAR(50),
						 TotalBets MONEY, TotalBetsBase MONEY,
						 TotalWins MONEY, TotalWinsBase MONEY,
						 TotalRefund MONEY, TotalRefundBase MONEY,
						 CompanyTurnOver MONEY, CompanyTurnOverBase MONEY,
						 CompanyGrossIncome MONEY, CompanyGrossIncomeBase MONEY,
						 CompanyComm MONEY, CompanyCommBase MONEY,
						 RefTable SMALLINT, EvenType INT, Matchid INT, ProductID INT
						)
	INSERT INTO #tmp_bettrans
	        ( Srecommend ,
	          CustID ,
	          BetCount ,
	          CurrencyID ,
	          TotalBets ,
	          TotalBetsBase ,
	          TotalWins ,
	          TotalWinsBase ,
	          TotalRefund ,
	          TotalRefundBase ,
	          CompanyTurnOver ,
	          CompanyTurnOverBase ,
	          CompanyGrossIncome ,
	          CompanyGrossIncomeBase ,
	          CompanyComm ,
	          CompanyCommBase,
			  RefTable,
			  EvenType,
			  Matchid,
			  ProductID
	        )	
	SELECT b.Srecommend, b.custid, 
				COUNT(CASE WHEN b.statusID IN (111, 112, 113) THEN b.transid ELSE NULL END) AS BetCount, b.currency,

				SUM(CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE actual_stake END) AS TotalBets,
				SUM((CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE actual_stake END) * actualrate)  AS TotalBetsBase,

				SUM(CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE winlost END) AS TotalWins,
				SUM((CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE winlost END) * actualrate) AS TotalWinsBase,

				SUM(CASE WHEN b.statusID IN (101,102,103) THEN actual_stake ELSE 0 END) AS TotalRefund,
				SUM((CASE WHEN b.statusID IN (101,102,103) THEN actual_stake ELSE 0 END)  * actualrate) AS TotalRefundBase,

				SUM(CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE (1- b.tpositiontaking) * b.stake END) AS CompanyTurnover,	
				SUM((CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE (1- b.tpositiontaking) * b.stake END) * actualrate) AS CompanyTurnoverBase,		
								
				SUM(winlost - actual_stake + awinlost + mwinlost + swinlost) AS CompanyGrossIncome,
				SUM((winlost - actual_stake + awinlost + mwinlost + swinlost)* actualrate) AS CompanyGrossIncomeBase,

				SUM(scomm) AS CompanyComm,
				SUM(scomm *actualrate) AS CompanyCommBase,

				s.RefTable, s.EvenType, b.matchid, s.ProductID

	FROM  dbo.bettrans b WITH (NOLOCK)
		INNER JOIN #SportBettype s ON s.Bettype = b.bettype
	WHERE b.winlostdate = @WLDate
		AND ((b.currency <> 20 AND @ExcludeTest = 1) OR @ExcludeTest = 0)
		AND (b.currency = @Currency OR @Currency IN (0, -1))
		AND (EXISTS (SELECT 1 FROM #tmp_MemIDs m WHERE m.CustID = b.custid) OR @Username = '')
		AND (EXISTS (SELECT 1 FROM #tmp_Devide d WHERE d.Betfrom = b.betfrom) OR @Device = '')
		AND ( @Site = 'ALL'
				  OR (EXISTS (SELECT 1 From #tmp_Company s WHERE s.srecommend = b.srecommend))
			)
		AND ( (@HousePTType = -1 AND b.tpositiontaking <= @HousePTValue)
			OR (@HousePTType = 1 AND b.tpositiontaking >= @HousePTValue)
			OR @HousePTType = 0)
		AND (@DrillDownCurrency = 0 OR b.currency = @DrillDownCurrency)
	GROUP BY b.Srecommend, b.custid, b.currency, s.RefTable, s.EvenType, b.matchid, s.ProductID	

	--- Check condition 
	IF EXISTS (SELECT 1 FROM #tmp_ProductID WHERE ProductID NOT IN (3, 4, 5)) -- NG, SLI-Live Casino, Virtual Sport
	BEGIN		
		-- 1. By bettype for normal product
		INSERT INTO #Data
				( Srecommend,
				  CustID ,
				  BetCount ,
				  CurrencyID ,	         
				  TotalBets ,
				  TotalBetsBase ,
				  TotalWins ,
				  TotalWinsBase ,
				  TotalRefund ,
				  TotalRefundBase ,
				  CompanyTurnOver ,
				  CompanyTurnOverBase ,
				  CompanyGrossIncome ,
				  CompanyGrossIncomeBase ,
				  CompanyComm ,
				  CompanyCommBase
				)
		SELECT b.Srecommend, b.custid,
				COUNT( BetCount ) AS BetCount, b.CurrencyID,

				SUM(TotalBets) AS TotalBets,
				SUM(TotalBetsBase)  AS TotalBetsBase,

				SUM(TotalWins) AS TotalWins,
				SUM(TotalWinsBase) AS TotalWinsBase,

				SUM(TotalRefund) AS TotalRefund,
				SUM(TotalRefundBase) AS TotalRefundBase,

				SUM(CompanyTurnover) AS CompanyTurnover,	
				SUM(CompanyTurnoverBase) AS CompanyTurnoverBase,		
								
				- SUM(CompanyGrossIncome) AS CompanyGrossIncome,
				- SUM(CompanyGrossIncomeBase) AS CompanyGrossIncomeBase,

				- SUM(CompanyComm) AS CompanyComm,
				- SUM(CompanyCommBase) AS CompanyCommBase

		FROM  #tmp_bettrans b
		WHERE b.RefTable IN (0, 3)
		GROUP BY b.Srecommend, b.custid, b.CurrencyID
		
		-- 2a. By Bettype for Casino Product
		INSERT INTO #Data
				( Srecommend ,
				  CustID ,
				  BetCount ,
				  CurrencyID ,	          
				  TotalBets ,
				  TotalBetsBase ,
				  TotalWins ,
				  TotalWinsBase ,
				  TotalRefund ,
				  TotalRefundBase ,
				  CompanyTurnOver ,
				  CompanyTurnOverBase ,
				  CompanyGrossIncome ,
				  CompanyGrossIncomeBase ,
				  CompanyComm ,
				  CompanyCommBase
				)
		SELECT	b.Srecommend, b.custid,
				COUNT(CASE WHEN StatusID IN (111,112,113) THEN b.TransId ELSE NULL END) AS BetCount, b.currency, 

				SUM(CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE actual_stake END) AS TotalBets,
				SUM((CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE actual_stake END) * actualrate)  AS TotalBetsBase,

				SUM(CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE winlost END) AS TotalWins,
				SUM((CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE winlost END) * actualrate) AS TotalWinsBase,

				SUM(CASE WHEN b.statusID IN (101,102,103) THEN actual_stake ELSE 0 END) AS TotalRefund,
				SUM((CASE WHEN b.statusID IN (101,102,103) THEN actual_stake ELSE 0 END)  * actualrate) AS TotalRefundBase,

				SUM(CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE (1- b.tpositiontaking) * b.stake END) AS CompanyTurnover,	
				SUM((CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE (1- b.tpositiontaking) * b.stake END) * actualrate) AS CompanyTurnoverBase,		
								
				- SUM(winlost - actual_stake + awinlost + mwinlost + swinlost) AS CompanyGrossIncome,
				- SUM((winlost - actual_stake + awinlost + mwinlost + swinlost)* actualrate) AS CompanyGrossIncomeBase,

				- SUM(scomm) AS CompanyComm,
				- SUM(scomm *actualrate) AS CompanyCommBase
		FROM dbo.bettransRnG b WITH (NOLOCK)
			INNER JOIN #SportBettype s ON s.Bettype = b.gameID
		WHERE b.winlostdate = @WLDate
			AND s.RefTable = 1		
			AND ((b.currency <> 20 AND @ExcludeTest = 1) OR @ExcludeTest = 0)
			AND (b.currency = @Currency OR @Currency IN (0, -1))	
			AND (EXISTS (SELECT 1 FROM #tmp_MemIDs m WHERE m.CustID = b.custid) OR @Username = '')
			AND (EXISTS (SELECT 1 FROM #tmp_Devide d WHERE d.Betfrom = b.betfrom) OR @Device = '')
			AND ( @Site = 'ALL'
				  OR (EXISTS (SELECT 1 From #tmp_Company s WHERE s.srecommend = b.srecommend))
			)
			AND ( (@HousePTType = -1 AND b.tpositiontaking <= @HousePTValue)
				OR (@HousePTType = 1 AND b.tpositiontaking >= @HousePTValue)
				OR @HousePTType = 0) 
			AND (@DrillDownCurrency = 0 OR b.currency = @DrillDownCurrency)
		GROUP BY b.Srecommend, b.custid, b.currency
		
		-- 2b. By Bettype for Casino Product
		INSERT INTO #Data
				( Srecommend ,
				  CustID ,
				  BetCount ,
				  CurrencyID ,	          
				  TotalBets ,
				  TotalBetsBase ,
				  TotalWins ,
				  TotalWinsBase ,
				  TotalRefund ,
				  TotalRefundBase ,
				  CompanyTurnOver ,
				  CompanyTurnOverBase ,
				  CompanyGrossIncome ,
				  CompanyGrossIncomeBase ,
				  CompanyComm ,
				  CompanyCommBase
				)
		SELECT	b.Srecommend, b.custid,
				COUNT(CASE WHEN StatusID IN (111,112,113) THEN b.TransId ELSE NULL END) AS BetCount, b.Currency, 

				SUM(CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE actual_stake END) AS TotalBets,
				SUM((CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE actual_stake END) * actualrate)  AS TotalBetsBase,

				SUM(CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE winlost END) AS TotalWins,
				SUM((CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE winlost END) * actualrate) AS TotalWinsBase,

				SUM(CASE WHEN b.statusID IN (101,102,103) THEN actual_stake ELSE 0 END) AS TotalRefund,
				SUM((CASE WHEN b.statusID IN (101,102,103) THEN actual_stake ELSE 0 END)  * actualrate) AS TotalRefundBase,

				SUM(CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE (1- b.tpositiontaking) * b.stake END) AS CompanyTurnover,	
				SUM((CASE WHEN b.statusID IN (101,102,103) THEN 0 ELSE (1- b.tpositiontaking) * b.stake END) * actualrate) AS CompanyTurnoverBase,		
								
				- SUM(winlost - actual_stake + awinlost + mwinlost + swinlost) AS CompanyGrossIncome,
				- SUM((winlost - actual_stake + awinlost + mwinlost + swinlost)* actualrate) AS CompanyGrossIncomeBase,

				- SUM(scomm) AS CompanyComm,
				- SUM(scomm *actualrate) AS CompanyCommBase
		FROM dbo.bettransLC b WITH (NOLOCK)
			INNER JOIN #SportBettype s ON s.Bettype = b.gameID
		WHERE b.winlostdate = @WLDate
			AND s.RefTable = 2	
			AND ((b.currency <> 20 AND @ExcludeTest = 1) OR @ExcludeTest = 0)
			AND (b.currency = @Currency OR @Currency IN (0, -1))			
			AND (EXISTS (SELECT 1 FROM #tmp_MemIDs m WHERE m.CustID = b.custid) OR @Username = '')
			AND (EXISTS (SELECT 1 FROM #tmp_Devide d WHERE d.Betfrom = b.betfrom) OR @Device = '')
			AND ( @Site = 'ALL'
				  OR (EXISTS (SELECT 1 From #tmp_Company s WHERE s.srecommend = b.srecommend))
			)
			AND ( (@HousePTType = -1 AND b.tpositiontaking <= @HousePTValue)
				OR (@HousePTType = 1 AND b.tpositiontaking >= @HousePTValue)
				OR @HousePTType = 0) 
			AND (@DrillDownCurrency = 0 OR b.currency = @DrillDownCurrency)
		GROUP BY b.Srecommend, b.custid, b.currency		
	END

	IF EXISTS (SELECT 1 FROM #tmp_ProductID WHERE ProductID IN (3, 4, 5))
	BEGIN
		-- 3. NumberGame - Live Casino - Virtual Sport (Soccer)
		INSERT INTO #Data
				( Srecommend ,
				  CustID ,
				  BetCount ,
				  CurrencyID ,
				  TotalBets ,
				  TotalBetsBase ,
				  TotalWins ,
				  TotalWinsBase ,
				  TotalRefund ,
				  TotalRefundBase ,
				  CompanyTurnOver ,
				  CompanyTurnOverBase ,
				  CompanyGrossIncome ,
				  CompanyGrossIncomeBase ,
				  CompanyComm ,
				  CompanyCommBase
				)	
		SELECT	b.Srecommend, b.custid,
				COUNT( BetCount ) AS BetCount, b.CurrencyID,

				SUM(TotalBets) AS TotalBets,
				SUM(TotalBetsBase)  AS TotalBetsBase,

				SUM(TotalWins) AS TotalWins,
				SUM(TotalWinsBase) AS TotalWinsBase,

				SUM(TotalRefund) AS TotalRefund,
				SUM(TotalRefundBase) AS TotalRefundBase,

				SUM(CompanyTurnover) AS CompanyTurnover,	
				SUM(CompanyTurnoverBase) AS CompanyTurnoverBase,		
								
				- SUM(CompanyGrossIncome) AS CompanyGrossIncome,
				- SUM(CompanyGrossIncomeBase) AS CompanyGrossIncomeBase,

				- SUM(CompanyComm) AS CompanyComm,
				- SUM(CompanyCommBase) AS CompanyCommBase

		FROM  #tmp_bettrans b
			INNER JOIN dbo.match m WITH (NOLOCK) ON m.matchid = b.matchid
		WHERE b.EvenType = 1
			AND (
				(b.ProductID = 3 AND (@LeagueId = '' OR (EXISTS (SELECT 1 FROM #tmp_LeagueID l WHERE l.LeagueID = m.leagueid)))) OR
				(b.ProductID = 4 AND (@GameTableId = '' OR (EXISTS (SELECT 1 FROM #tmp_GameTableID g WHERE g.GameTableID = m.leagueid)))) OR
				(b.ProductID = 5 AND (@Sporttype = '' OR (EXISTS (SELECT 1 FROM #tmp_SportType st WHERE st.Sporttype = m.sporttype))))
			)	
		GROUP BY b.Srecommend, b.custid, b.CurrencyID
	
		-- 4. Virtual Sport (HR)
		INSERT INTO #Data
				( Srecommend ,
				  CustID ,
				  BetCount ,
				  CurrencyID ,	          
				  TotalBets ,
				  TotalBetsBase ,
				  TotalWins ,
				  TotalWinsBase ,
				  TotalRefund ,
				  TotalRefundBase ,
				  CompanyTurnOver ,
				  CompanyTurnOverBase ,
				  CompanyGrossIncome ,
				  CompanyGrossIncomeBase ,
				  CompanyComm ,
				  CompanyCommBase
				)
		SELECT	b.Srecommend, b.custid,
				COUNT( BetCount ) AS BetCount, b.CurrencyID,

				SUM(TotalBets) AS TotalBets,
				SUM(TotalBetsBase)  AS TotalBetsBase,

				SUM(TotalWins) AS TotalWins,
				SUM(TotalWinsBase) AS TotalWinsBase,

				SUM(TotalRefund) AS TotalRefund,
				SUM(TotalRefundBase) AS TotalRefundBase,

				SUM(CompanyTurnover) AS CompanyTurnover,	
				SUM(CompanyTurnoverBase) AS CompanyTurnoverBase,		
								
				- SUM(CompanyGrossIncome) AS CompanyGrossIncome,
				- SUM(CompanyGrossIncomeBase) AS CompanyGrossIncomeBase,

				- SUM(CompanyComm) AS CompanyComm,
				- SUM(CompanyCommBase) AS CompanyCommBase

		FROM  #tmp_bettrans b
			INNER JOIN dbo.VSRaceInfo r WITH (NOLOCK) ON r.EventID = b.matchid
		WHERE b.ProductID = 5
			AND b.EvenType = 3
			AND (@Sporttype = '' OR (EXISTS(SELECT 1 FROM #tmp_SportType st WHERE st.Sporttype = r.SportType)))			  
		GROUP BY b.Srecommend, b.custid, b.CurrencyID
	END

	-- Get Currency name
	UPDATE d
	SET d.Currency = e.currency
	FROM #Data d
		INNER JOIN dbo.Exchange e ON e.exchangeid = d.CurrencyID
	-- End Currency Name

	------------------------------------------III. Drill down data ------------------------------------------------------

	IF @DrillDownCurrency = 0 -- Report with level 1 - Not Drilldown
	BEGIN
		IF @Currency = -1 -- Base RM
		BEGIN
			INSERT INTO #ResultByCurrency
			        ( CurrencyID ,
			          Currency ,
			          NoOfPlayers ,
			          BetCount ,
			          TotalBets ,
			          TotalWins ,
			          TotalRefund ,
			          CompanyTurnOver ,
			          CompanyGrossIncome ,
			          CompanyComm 
			        )
			SELECT b.CurrencyID,
					b.Currency,
					COUNT(DISTINCT b.CustID) AS NoOfPlayers,
					SUM(b.BetCount) AS BetCount,
					SUM(b.TotalBetsBase) AS TotalBets,
					SUM(b.TotalWinsBase) AS TotalWins,
					SUM(b.TotalRefundBase) AS TotalRefund,
					SUM(b.CompanyTurnOverBase) AS CompanyTurnOver,
					SUM(b.CompanyGrossIncomeBase) AS CompanyGrossIncome,
					SUM(b.CompanyCommBase) AS CompanyComm
			FROM #Data b
			GROUP BY b.CurrencyID, b.Currency
			HAVING (@TotalBetType = 0
					OR (@TotalBetType = 1 AND SUM(b.TotalBetsBase) >= @TotalBetValue) 
					OR (@TotalBetType = -1 AND SUM(b.TotalBetsBase) <= @TotalBetValue)
					)
				AND (@GameIncomeType = 0
					OR (@GameIncomeType = 1 AND SUM(b.TotalBetsBase - b.TotalWinsBase) >= @GameIncomeValue) 
					OR (@GameIncomeType = -1 AND SUM(b.TotalBetsBase - b.TotalWinsBase) <= @GameIncomeValue)
					)
		END
		ELSE -- Original Currency
		BEGIN
			INSERT INTO #ResultByCurrency
			        ( CurrencyID ,
			          Currency ,
			          NoOfPlayers ,
			          BetCount ,
			          TotalBets ,
			          TotalWins ,
			          TotalRefund ,
			          CompanyTurnOver ,
			          CompanyGrossIncome ,
			          CompanyComm 
			        )
			SELECT b.CurrencyID,
					b.Currency,
					COUNT(DISTINCT b.CustID) AS NoOfPlayers,
					SUM(b.BetCount) AS BetCount,
					SUM(b.TotalBets) AS TotalBets,
					SUM(b.TotalWins) AS TotalWins,
					SUM(b.TotalRefund) AS TotalRefund,
					SUM(b.CompanyTurnOver) AS CompanyTurnOver,
					SUM(b.CompanyGrossIncome) AS CompanyGrossIncome,
					SUM(b.CompanyComm) AS CompanyComm
			FROM #Data b
			GROUP BY b.CurrencyID, b.Currency
			HAVING (@TotalBetType = 0
					OR (@TotalBetType = 1 AND SUM(b.TotalBets) >= @TotalBetValue) 
					OR (@TotalBetType = -1 AND SUM(b.TotalBets) <= @TotalBetValue)
					)
				AND (@GameIncomeType = 0
					OR (@GameIncomeType = 1 AND SUM(b.TotalBets - b.TotalWins) >= @GameIncomeValue) 
					OR (@GameIncomeType = -1 AND SUM(b.TotalBets - b.TotalWins) <= @GameIncomeValue)
					)
		END
	END
	ELSE -- @DrillDownCurrency > 0 => Drilldown with selected Currency to Company level
	BEGIN
		IF @Currency = -1 -- Base RM
		BEGIN
			INSERT INTO #ResultByCompany
		        ( SiteName ,
		          NoOfPlayers ,
		          BetCount ,
		          CurrencyID ,
		          Currency ,
		          TotalBets ,
		          TotalWins ,
		          TotalRefund ,
		          CompanyTurnOver ,
		          CompanyGrossIncome ,
		          CompanyComm
		        )
			SELECT c.SiteName,
					COUNT(DISTINCT b.CustID) AS NoOfPlayers,
					SUM(b.BetCount) AS BetCount,
					b.CurrencyID AS CurrencyID,
					b.Currency AS Currency,
					SUM(b.TotalBetsBase) AS TotalBets,
					SUM(b.TotalWinsBase) AS TotalWins,
					SUM(b.TotalRefundBase) AS TotalRefund,
					SUM(b.CompanyTurnOverBase) AS CompanyTurnOver,
					SUM(b.CompanyGrossIncomeBase) AS CompanyGrossIncome,
					SUM(b.CompanyCommBase) AS CompanyComm
			FROM #Data b
				INNER JOIN #tmp_Company c ON b.Srecommend = c.Srecommend
			GROUP BY c.SiteName, b.CurrencyID, b.Currency
			HAVING (@TotalBetType = 0
					OR (@TotalBetType = 1 AND SUM(b.TotalBetsBase) >= @TotalBetValue) 
					OR (@TotalBetType = -1 AND SUM(b.TotalBetsBase) <= @TotalBetValue)
					)
				AND (@GameIncomeType = 0
					OR (@GameIncomeType = 1 AND SUM(b.TotalBetsBase - b.TotalWinsBase) >= @GameIncomeValue) 
					OR (@GameIncomeType = -1 AND SUM(b.TotalBetsBase - b.TotalWinsBase) <= @GameIncomeValue)
					)

		END
		ELSE -- Original Currency
		BEGIN
			INSERT INTO #ResultByCompany
		        ( SiteName ,
		          NoOfPlayers ,
		          BetCount ,
		          CurrencyID ,
		          Currency ,
		          TotalBets ,
		          TotalWins ,
		          TotalRefund ,
		          CompanyTurnOver ,
		          CompanyGrossIncome ,
		          CompanyComm
		        )
			SELECT c.SiteName,
					COUNT(DISTINCT b.CustID) AS NoOfPlayers,
					SUM(b.BetCount) AS BetCount,
					b.CurrencyID AS CurrencyID,
					b.Currency AS Currency,
					SUM(b.TotalBets) AS TotalBets,
					SUM(b.TotalWins) AS TotalWins,
					SUM(b.TotalRefund) AS TotalRefund,
					SUM(b.CompanyTurnOver) AS CompanyTurnOver,
					SUM(b.CompanyGrossIncome) AS CompanyGrossIncome,
					SUM(b.CompanyComm) AS CompanyComm
			FROM #Data b
				INNER JOIN #tmp_Company c ON b.Srecommend = c.Srecommend
			GROUP BY c.SiteName, b.CurrencyID, b.Currency
			HAVING (@TotalBetType = 0
					OR (@TotalBetType = 1 AND SUM(b.TotalBets) >= @TotalBetValue) 
					OR (@TotalBetType = -1 AND SUM(b.TotalBets) <= @TotalBetValue)
					)
				AND (@GameIncomeType = 0
					OR (@GameIncomeType = 1 AND SUM(b.TotalBets - b.TotalWins) >= @GameIncomeValue) 
					OR (@GameIncomeType = -1 AND SUM(b.TotalBets - b.TotalWins) <= @GameIncomeValue)
					)
		END
	END

	------------------------------------------IV. Return Total Rows ------------------------------------------------------
	
	IF @DrillDownCurrency = 0
	BEGIN
		SELECT Currency AS Reportby,
			CurrencyID,
			NoOfPlayers,
			BetCount,
			TotalBets,
			TotalWins,
			TotalRefund,
			CompanyTurnOver,
			CompanyGrossIncome,
			CompanyComm
		FROM #ResultByCurrency
		ORDER BY Currency

		SELECT 'Grand Total RM' AS ReportBy,
			0 AS CurrencyID,
			COUNT(DISTINCT b.CustID) AS NoOfPlayers,
			SUM(b.BetCount) AS BetCount,
			SUM(b.TotalBetsBase) AS TotalBets,
			SUM(b.TotalWinsBase) AS TotalWins,
			SUM(b.TotalRefundBase) AS TotalRefund,
			SUM(b.CompanyTurnOverBase) AS CompanyTurnOver,
			SUM(b.CompanyGrossIncomeBase) AS CompanyGrossIncome,
			SUM(b.CompanyCommBase) AS CompanyComm
		FROM #Data b
			INNER JOIN #ResultByCurrency c ON b.CurrencyID = c.CurrencyID
	END
	ELSE -- @DrillDownCurrency > 0 => Drill down to Company
	BEGIN
		SELECT SiteName AS Reportby,			
			NoOfPlayers,
			BetCount,
			Currency,
			TotalBets,
			TotalWins,
			TotalRefund,
			CompanyTurnOver,
			CompanyGrossIncome,
			CompanyComm
		FROM #ResultByCompany
		ORDER BY SiteName

		SELECT 'Grand Total RM' AS ReportBy,			
			COUNT(DISTINCT b.CustID) AS NoOfPlayers,
			SUM(b.BetCount) AS BetCount,
			'RM' AS Currency,
			SUM(b.TotalBetsBase) AS TotalBets,
			SUM(b.TotalWinsBase) AS TotalWins,
			SUM(b.TotalRefundBase) AS TotalRefund,
			SUM(b.CompanyTurnOverBase) AS CompanyTurnOver,
			SUM(b.CompanyGrossIncomeBase) AS CompanyGrossIncome,
			SUM(b.CompanyCommBase) AS CompanyComm
		FROM #Data b
		WHERE EXISTS (SELECT 1 FROM #tmp_Company c WHERE b.Srecommend = c.Srecommend)
	END

	DROP TABLE #Data
	DROP TABLE #ResultByCompany
	DROP TABLE #ResultByCurrency
	DROP TABLE #SportBettype
	DROP TABLE #tmp_BetType
	DROP TABLE #tmp_Company
	DROP TABLE #tmp_Devide
	DROP TABLE #tmp_GameTableID
	DROP TABLE #tmp_LeagueID
	DROP TABLE #tmp_MemIDs
	DROP TABLE #tmp_ProductID
	DROP TABLE #tmp_Site
	DROP TABLE #tmp_SportType
	DROP TABLE #tmp_bettrans
END
GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_NonSportsProductStatistics_Currency] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_NonSportsProductStatistics_Currency] TO [vnteam];
GO

