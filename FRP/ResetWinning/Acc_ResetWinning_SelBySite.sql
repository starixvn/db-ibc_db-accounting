/*<info serverAlias="DBEXT-bodb02" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ResetWinning_SelBySite]
	@fromdate smalldatetime,
	@todate   smalldatetime 
AS 
 
/*	
	Created: 20200210@Sophia
	Task: Reset Winning - View by Site (adhoc) [redmind: #128212]
	DB: DBEXT.BODB02
	
	Revision:
		- 20200210@Sophia: Initial SPs
		- 20200213@Sophia: Modify Exchange product [redmine: #128471]
		 
	Param Explanation:
		outout: IsDeposit = 0: Credit 
						  = 1: deposit 
						  = 3: By Product (exchange)
						
	   
*/
BEGIN	
	SET NOCOUNT ON
	 
	------Get Sport Bettype Matrix------	
	CREATE TABLE  #SportBettype (ProductID INT, Bettype INT,SubProduct VARCHAR(500))
	INSERT INTO #SportBettype
	SELECT ProductID, Bettype, SubProduct FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', 0)
	
	--- Exclude Exchange product
	DELETE #SportBettype 
	WHERE  ProductID = 31 

	
	CREATE CLUSTERED INDEX CIX_Bettype ON #SportBettype (bettype) 
	----- End get sport bettype  
		
    DECLARE @wldate DATE = @todate,
            @seq    smallint = 0,
            @maxseq smallint = 0 
	
	DECLARE @Date AS TABLE (WLDate DATE )
	
	WHILE (@FromDate <= @wldate)
	BEGIN 
		INSERT INTO @Date (WLDate)
		VALUES (@wldate)

		SELECT @wldate = DATEADD( DAY, -1, @wldate)
	END

	--------------------------------------------------------------------------------------------------------- 
		CREATE TABLE #wl 
		(	winlostdate 	SMALLDATETIME, 
			srecommend 		INT, 
			Currency		INT,
			Sporttype  		SMALLINT, 
			ProductId		INT, 
			ProductName		VARCHAR(250), 
			SubProduct		VARCHAR(250), 
			Winlost			MONEY, 
			WinlostDueTo	MONEY, 
			CommForExtraPT	MONEY,
			WinlostForExtraPT MONEY,
			RealWinlost			MONEY, 
			RealWinlostDueTo	MONEY, 
			RealCommForExtraPT	MONEY,
			RealWinlostForExtraPT MONEY
		) 	 
		INSERT INTO #wl (winlostdate, srecommend, Sporttype, ProductId, SubProduct, 
						 winlost, WinlostDueTo, CommForExtraPT, WinlostForExtraPT )
		SELECT  b.winlostdate,
				b.srecommend,
				CASE WHEN ISNULL(m.Sporttype, 0) <> 0 THEN m.Sporttype ELSE 0 END AS Sporttype,
			    s.ProductId,		
				CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm','BT-Winloss','Bet Builder') THEN s.SubProduct ELSE '' END AS SubProduct,				
				---Base currency
				SUM(
						CASE WHEN b.bettype IN (2199, 2399, 2999) THEN 0
							ELSE
								(ISNULL(winlost,0)-ISNULL(actual_stake,0)+ISNULL(awinlost,0)+ISNULL(mwinlost,0)+ISNULL(swinlost,0)+ISNULL(scomm,0)
									+ CASE
										-- Jackpot
										WHEN b.bettype IN (2198, 2398, 2998) THEN ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000),0)
										ELSE 0 END
								) * b.actualrate
							END
					) AS winlost,
				SUM(
						(	
							CASE
								-- Jackpot
								WHEN b.bettype IN (2198, 2398, 2998) THEN -ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0)
								WHEN b.bettype IN (2199, 2399, 2999) THEN ISNULL(b.Winlost, 0) - ISNULL(b.actual_stake, 0)
							ELSE 0 
							END
						) * b.actualrate
					) AS WinlostDueTo,
				0 AS CommForExtraPT,
				SUM(
						(	
							CASE
							-- Jackpot
							WHEN b.bettype IN (2198, 2398, 2998) THEN
								CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
							WHEN b.bettype IN (2199, 2399, 2999) THEN 0
							ELSE
								CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END
							END
						) * b.actualrate
					) AS WinlostForExtraPT		
				
		FROM dbo.bettrans b WITH (NOLOCK)  
		INNER JOIN #SportBettype s ON s.BetType = b.bettype
		LEFT JOIN dbo.Match m WITH (NOLOCK) ON m.MatchId = b.MatchId AND m.Sporttype = 44		
		WHERE   b.Winlostdate between @fromdate and @todate
			AND b.statusid IN (111, 112, 113)		
			AND b.bettype < 19001
			AND b.MatchID >= 0
		GROUP BY b.Winlostdate,				
				b.srecommend,
				CASE WHEN ISNULL(m.Sporttype, 0) <> 0 THEN m.Sporttype ELSE 0 END ,
			    s.ProductId,		
				CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm','BT-Winloss','Bet Builder') THEN s.SubProduct ELSE '' END 			
				 
		-----------------------------------------------------------------------------------------------

			--- WL by product
			CREATE TABLE #Winlost (Winlostdate SMALLDATETIME, Site VARCHAR(50), Winlost MONEY) 
			CREATE TABLE #ExtraPTWinlost (Winlostdate SMALLDATETIME, Site VARCHAR(50), ExtraPTWinlost MONEY) 
					
			INSERT INTO #Winlost (Winlostdate, Site, Winlost)						
			SELECT  w.Winlostdate, c.Site,
					SUM(ISNULL( w.Winlost,0)) + SUM(ISNULL( w.WinlostDueTo,0))  as Winlost 								
			FROM	#wl w
			INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) 
					ON c.CustID = w.srecommend AND c.roleid = 4			
			GROUP BY w.Winlostdate, c.Site
 
 			--- extraPT	
			INSERT INTO #ExtraPTWinlost (Winlostdate, Site, ExtraPTWinlost)	 
			SELECT  w.Winlostdate, c.Site, 				 
				   SUM(w.WinlostForExtraPT * ISNULL(s.ExtraPT,0)) as ExtraPTWinlost				  
			FROM	#wl w
			INNER JOIN dbo.Acc_GroupExtraPTSetting s WITH(NOLOCK)
					ON w.srecommend = s.SuperId
					AND w.ProductId = s.ProductId
					AND w.SubProduct = s.SubProduct
					AND w.Sporttype = s.Sporttype 
					AND w.Winlostdate BETWEEN s.FromDate AND s.ToDate	
			INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) 
					ON c.CustID = w.srecommend AND c.roleid = 4					
			GROUP BY w.Winlostdate, c.Site				
		
		-----------------------------------------------------------------------------------------------
		------ Exchange product-----		
			--EXEC Acc_Rpt_HouseNetIncome_EX_Deposit @fromdate, @fromdate    ----- cannot use FromDate - ToDate because of output will be different
								 

			DECLARE @FDate  DATE, @TDate    DATE
			
			SELECT @FDate = @FromDate
				, @TDate = @ToDate;
			-- Region: Active licensees

			DECLARE @TmpPartyList AS TABLE(
				PartyID      INT
			  , PartyName    VARCHAR(200)
			  , BrandName    VARCHAR(200)
			  , ParentID     INT);

			INSERT INTO @TmpPartyList (PartyID, PartyName, BrandName,ParentID)
			Select PartyID, PartyName, BrandName,ParentID  from LA_f_PartyListSel ()

			DECLARE @PartyIDs    VARCHAR(1000);

			SELECT @PartyIDs = COALESCE(@PartyIDs+',', '')+CONVERT(VARCHAR(10), p.PartyId)
			FROM @TmpPartyList AS p
			   INNER JOIN bodb_licensee.dbo.OAS_PartyDetail AS pd WITH (NOLOCK) ON p.PartyID = pd.PartyID
			WHERE pd.IsDeposit = 1;
			-- End region

			-- Region: Get Licensees has charge rate

			DECLARE @PartyChargeInfo AS TABLE(
				PartyId       INT
			  , LicenseeId    INT
			  , ParentID      INT
			  , Rate          MONEY
			  , FromDate      SMALLDATETIME
			  , ToDate        SMALLDATETIME
			  , ProductID     INT);

			DECLARE @PartyCharge3rdInfo AS TABLE(
				LicenseeId    INT
			  , Rate          MONEY
			  , FromDate      SMALLDATETIME
			  , ToDate        SMALLDATETIME
			  , ProductID     INT);

			INSERT INTO @PartyChargeInfo(PartyId
								 , LicenseeId
								 , ParentID
								 , Rate
								 , Fromdate
								 , Todate
								 , ProductID)
				 (
					SELECT ci.PartyID
						, ci.LicenseeID
						, p.ParentID
						, ci.DI_Rate
						, ci.Fromdate
						, ci.ToDate
						, ci.ProductID
					FROM bodb_licensee.dbo.LA_f_ChargeInfo
						(@PartyIDs, @FDate, @TDate, 'BX', 'OA', 1) AS ci
						INNER JOIN @TmpPartyList AS p ON ci.PartyID = p.PartyID
					WHERE DI_Rate > 0
						 AND ci.ChargeType = 1 -- get PT
				 );

			INSERT INTO @PartyCharge3rdInfo(LicenseeId
									, Rate
									, FromDate
									, ToDate
									, ProductID)
				 (
					SELECT DISTINCT
						  p.LicenseeID
						, ci.DI_Rate
						, ci.Fromdate
						, ci.ToDate
						, ci.ProductID
					FROM bodb_licensee.dbo.LA_f_ChargeInfo3rd
						(@FDate, @TDate, 'BX', 'OA') AS ci
						INNER JOIN @PartyChargeInfo AS p ON ci.IsParent = 0
													AND p.PartyID = ci.PartyId
					WHERE ci.ChargeType = 1
						 AND ci.IsDeposit = 1
				 );

			INSERT INTO @PartyCharge3rdInfo(LicenseeId
									, Rate
									, FromDate
									, ToDate
									, ProductID)
				 (
					SELECT DISTINCT
						  p.LicenseeID
						, ci.DI_Rate
						, ci.Fromdate
						, ci.ToDate
						, ci.ProductID
					FROM bodb_licensee.dbo.LA_f_ChargeInfo3rd
						(@FDate, @TDate, 'BX', 'OA') AS ci
						INNER JOIN @PartyChargeInfo AS p ON ci.IsParent = 1
													AND p.ParentID = ci.PartyId
					WHERE ci.ChargeType = 1
						 AND ci.IsDeposit = 1
						 AND NOT EXISTS
									 (
										SELECT 1
										FROM @PartyCharge3rdInfo AS ci
										WHERE ci.LicenseeId = p.LicenseeId
									 )
				 );
			-- End Region

			-- Region: Get Exchange

			CREATE TABLE #ExchangeOANDA(
				ExchangeDate    DATE
			  , ExchangeID      INT
			  , Rate            FLOAT);

			INSERT INTO #ExchangeOANDA(ExchangeDate
								, ExchangeID
								, Rate)
				 SELECT ExchangeDate
					 , ExchangeID
					 , BaseCurrencyRate
				 FROM bodb02.dbo.LA_f_ExchangeDailySel
					 (@FDate, @TDate, 'MYR');
			-- End Region

			-- Region: Get Sum data

			CREATE TABLE #TempDataEX(
				PartyId            INT
			  , rptDate            DATETIME
			  , ProductID          INT
			  , CurrencyId         INT
			  , MemberWL           MONEY
			  , AComm              MONEY
			  , PComm              MONEY
			  , AmountToCompany    MONEY
			  , PayToSupplier      MONEY);

			INSERT INTO #TempDataEX(PartyId
							 , rptDate
							 , CurrencyId
							 , MemberWL
							 , AComm
							 , PComm
							 , ProductId
							 , AmountToCompany
							 , PayToSupplier)
				 (
					SELECT p.PartyId
						, b.rptDate
						, b.CurrencyID
						, SUM(ISNULL(b.MemberWL, 0))
						, SUM(ISNULL(b.CommissionA, 0) * e.Rate)
						, SUM(ISNULL(b.CommissionP, 0) * e.Rate)
						, b.ProductId
						, SUM(-ISNULL(b.MemberWL, 0) * p.Rate * e.Rate)
						, SUM(ISNULL(b.MemberWL, 0) * rd.Rate * e.Rate)
					FROM bodb_LicenseeReport.dbo.rpt_BettingByProduct AS b WITH (NOLOCK)
						INNER JOIN #ExchangeOANDA AS e ON b.rptDate = e.ExchangeDate
												   AND b.CurrencyId = e.ExchangeID
						INNER JOIN @PartyChargeInfo AS p ON b.ProductId = p.ProductID
													AND p.LicenseeId = b.SiteId
													AND b.rptDate BETWEEN p.FromDate AND p.ToDate
						INNER JOIN @PartyCharge3rdInfo AS rd ON b.ProductID = rd.ProductID
														AND b.SiteID = rd.LicenseeID
														AND b.rptDate BETWEEN rd.FromDate AND rd.ToDate
					WHERE b.rptDate BETWEEN @FDate AND @TDate
						 AND b.CurrencyID <> 20
						 AND b.customercategory NOT IN(27, 28)
						 AND b.StatusId NOT IN(-1, 101, 102, 103) -- Exclude Reject , Void, Refund
					GROUP BY b.rptdate
						  , b.SiteId
						  , p.PartyId
						  , b.CurrencyID
						  , b.ProductId
				 );

			CREATE TABLE #FinalResult(
				RptDate          VARCHAR(10)
			  , LicenseeWL       MONEY
			  , PayToSupplier    MONEY);

			INSERT INTO #FinalResult(rptDate
							  , LicenseeWL
							  , PayToSupplier)
				 SELECT 'FullRange'
					 , SUM(AmountToCompany) - SUM(AComm + PComm)
					 , SUM(PayToSupplier) + SUM(AComm + PComm)
				 FROM #TempDataEX
		 	
		
		-----------------------------------------------------------------------------------------------
		----- Get Data -----
			SELECT	w.Winlostdate, w.Site,  
					ROUND((ISNULL(w.Winlost, 0)), 2) - ROUND((ISNULL(e.ExtraPTWinlost, 0)), 2) AS WinlostAfterExtraPT,
					CASE WHEN s.SiteID > 1000 THEN 0 ELSE 1 END AS IsDeposit
			FROM #Winlost w 
			LEFT JOIN #ExtraPTWinlost e
				ON w.Winlostdate = e.Winlostdate
				AND w.Site = e.Site
			INNER JOIN bodb_licensee.dbo.view_site_list s 
				ON s.SiteName = w.Site
				
			---exchange product
			UNION
			SELECT @FromDate AS Winlostdate, 'Exchange Product', SUM(LicenseeWL+PayToSupplier) AS WinlostAfterExtraPT, 3 AS IsDeposit
			FROM #FinalResult
			
			ORDER BY IsDeposit, w.Winlostdate, w.Site
			
	-- Region: Drop tmp table
	DROP TABLE #ExchangeOANDA
	DROP TABLE #TempDataEX
	DROP TABLE #FinalResult	
	

	DROP TABLE #SportBettype
    DROP TABLE #Winlost
    DROP TABLE #ExtraPTWinlost
	DROP TABLE #WL
	
		
END
GO