/*<info serverAlias="DBEXT-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
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
		- 20200226@Sophia: Using new column bettrans.epositiontaking instead of Acc_GroupExtraPTSetting.ExtraPT [RedmineID: #125418]
		- 20200303@Sophia: Remove CutOffDate of ExtraPT, use new column [RedmineID: #129653]
		 
	Param Explanation:
		outout: IsDeposit = 0: Credit 
						  = 1: deposit 
						  = 3: By Product (exchange)
						
	   
*/
BEGIN	
	SET NOCOUNT ON
	 	 
	------Get Sport Bettype Matrix------	
	
	CREATE TABLE #Match (MATCHID INT PRIMARY KEY)
	INSERT INTO #Match (MatchID)
	SELECT DISTINCT MatchID 	
	FROM Bettrans WITH (NOLOCK) 
	WHERE Winlostdate = @FromDate 
	
	--------------------------------------------------------------------------------------------------------- 
		CREATE TABLE #wl 
		(	winlostdate 	SMALLDATETIME, 
			srecommend 		INT, 
			Winlost			MONEY, 
			WinlostDueTo	MONEY, 
			WinlostForExtraPT MONEY,	
			eWinlost			MONEY
		) 	 
		INSERT INTO #wl (winlostdate, srecommend,
						 winlost, WinlostDueTo, eWinlost)
		SELECT  b.winlostdate,
				b.srecommend,			 			
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
						) *  b.actualrate * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)
					) AS eWinlost 			 			
				
		FROM dbo.bettrans b WITH (NOLOCK, index = CIX_Matchid_Bettype)  
		INNER JOIN #Match m ON m.MatchID = b.MatchID		
		WHERE   b.Winlostdate = @Fromdate 
			AND b.statusid IN (111, 112, 113)		
			AND b.bettype < 19001
			AND b.MatchID >= 0
			AND b.Bettype <> 8000 --- exclude Exchange
		GROUP BY b.Winlostdate,				
				b.srecommend 			  			
				 
		-----------------------------------------------------------------------------------------------

			--- WL by product
			CREATE TABLE #Winlost (Winlostdate SMALLDATETIME, Site VARCHAR(50), Winlost MONEY, ExtraPTWinlost MONEY)  
					
			INSERT INTO #Winlost (Winlostdate, Site, Winlost, ExtraPTWinlost)						
			SELECT  w.Winlostdate, c.Site,
					SUM(ISNULL( w.Winlost,0)) + SUM(ISNULL( w.WinlostDueTo,0))  as Winlost,
					SUM(ISNULL(w.eWinlost,0)) as ExtraPTWinlost
			FROM	#wl w
			INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) 
					ON c.CustID = w.srecommend AND c.roleid = 4			
			GROUP BY w.Winlostdate, c.Site 
 		  	
		
		-----------------------------------------------------------------------------------------------
		------ Exchange product-----		
			--EXEC Acc_Rpt_HouseNetIncome_EX_Deposit @fromdate, @fromdate    ----- cannot use FromDate - ToDate because of output will be different
								 
			DECLARE @FDate  DATE, @TDate    DATE
								
			SELECT @FDate = @FromDate
				, @TDate = @FromDate;  ------ Support 1 day only   
				
			-- Region: Active licensees

			DECLARE @TmpPartyList AS TABLE(
				PartyID      INT
			  , PartyName    VARCHAR(200)
			  , BrandName    VARCHAR(200)
			  , ParentID     INT);

			INSERT INTO @TmpPartyList (PartyID, PartyName, BrandName,ParentID)
			SELECT PartyID, PartyName, BrandName,ParentID FROM bodb_licensee.dbo.LA_f_PartyListSel ()

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
					ROUND((ISNULL(w.Winlost, 0)), 2) -  ROUND((ISNULL(w.ExtraPTWinlost, 0)), 2) AS WinlostAfterExtraPT,
					CASE WHEN s.SiteID > 1000 THEN 0 ELSE 1 END AS IsDeposit
			FROM #Winlost w 
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
	 
    DROP TABLE #Winlost 
	DROP TABLE #WL
	DROP TABLE #Match
		
END
GO