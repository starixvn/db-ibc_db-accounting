CREATE PROCEDURE [dbo].[Acc_Rpt_EnableDisableAccount_OnProduct]
	@MoveBetsDay	SMALLDATETIME	= '2014-05-26',
	@BalanceUpDay	SMALLDATETIME	= '2014-05-24',
	@ListCurrency	NVARCHAR(150)	= 'all', 
	@ShowRB			BIT				= 0,  
	@ShowNG			BIT				= 0,
	@ShowKN			BIT				= 1,
	@ShowLC 		BIT				= 0,
	@ShowVS			BIT				= 0,
	@ShowCS  		BIT				= 0,
	@ShowBI  		BIT				= 0
AS  
/*  Created: Dominic  
	Date: 2014-06-02  
    Task : Total Credit Accounts Enabled/Disabled per Product
    DB: DBAGE/bodb02  
   
    Revisions:  
		
	Param's Explanation:  
	  + @MoveBetsDay: The day of moving bets to battrans14
	  + @BalanceUpDay: The day of moving bets to battransbk
	  + @ListCurrency: The specified date used as one of the filter criterias
	  + @ShowRB: Include RB bets 
	  + @ShowNG: Include Number game bets 
	  + @ShowKN: Include Keno 
	  + @ShowLC: Include Live Casino 
	  + @ShowVS: Include Virtual Sports 
	  +	@ShowCS: Include RNG Casino 
	  +	@ShowBI: Include Bingo 

  
*/  
BEGIN
	DECLARE @CurrentDate SMALLDATETIME
	DECLARE @FirstDate SMALLDATETIME
	DECLARE @TempFromDate SMALLDATETIME
	DECLARE @TempToDate SMALLDATETIME
	
	--Table of real creadit super filter by currency
	CREATE TABLE #FiltedCreditSuper(
			CustID INT,
			SuperStatus BIT,
			MasterEnabled INT,
			MasterDisabled INT,
			AgentEnabled INT,
			AgentDisabled INT,
			MemberEnabled INT,
			MemberDisabled INT,
			)
			
	--Table of Super/master/Member that belong to real super above	
	CREATE TABLE #FiltedDownlineAcc(
		SuperID		INT,
		CustID		INT,
		RoleID		INT,
		IsDisable	BIT
		)
		
	--Table of member that played bet within current month	
	CREATE TABLE #AvailableMember(CustID INT)	
	
	--Tempt table to count enable/disable
	CREATE TABLE #TempResult(
			SuperID		INT, 
			RoleID		INT,
			DisableCnt	INT,
			EnableCnt	INT
			)	
	
	SELECT @CurrentDate = CAST(GETDATE() AS DATE)
	SELECT @FirstDate = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(@CurrentDate)-1),@CurrentDate),101)
	
	--Get real credit super filterd by currencies
	INSERT INTO #FiltedCreditSuper(CustID,SuperStatus)
	SELECT ci.custid,
		CASE
			WHEN @ShowRB = 1 THEN (ci.Disable151_AU & ci.Disable152_AU & ci.Disable152_UK & ci.Disable153_AU & ci.DisableHorseRacing & ci.DisableOpenTote)
			WHEN @ShowNG = 1 THEN ci.DisableNumber
			WHEN @ShowKN = 1 THEN CASE WHEN EXISTS(SELECT TOP 1 1 FROM dbo.CustGameType gt 
																WHERE gt.CustID = ci.CustID
																AND gt.IsDisabled = 0)
												THEN 0
												ELSE 1
												END
			WHEN @ShowLC = 1 THEN (~ci.SyncLiveCasino | ci.DisableLiveCasino)
			WHEN @ShowVS = 1 THEN ci.DisableVirtualSports
			WHEN @ShowCS = 1 THEN (~ci.SyncCasino |(ci.DisableCasino & ci.DisableCasinoBonus))
			WHEN @ShowBI = 1 THEN (~ci.SyncBingo | ci.DisableBingo)
		END
	FROM dbo.custInfo ci WITH(NOLOCK)
	WHERE ci.roleid=4 AND ci.Enabled = 1 AND ci.custid NOT IN (SELECT custid from dbo.f_DepSuper_1 ('all'))
		AND (@ListCurrency= 'all' OR ci.currency IN(SELECT val
                            FROM   dbo.strSplit (@ListCurrency, ','))) AND ci.currency NOT IN (20,27,28)
                            
    --Get data from bettrans       
	IF @CurrentDate > @MoveBetsDay
	BEGIN
		IF @FirstDate <= @MoveBetsDay 
			SET @TempFromDate =  DATEADD(DAY,1,@MoveBetsDay)
		ELSE
			SET @TempFromDate = @FirstDate
			
		INSERT INTO #AvailableMember
		SELECT DISTINCT b.custid FROM dbo.bettrans b
		WHERE b.winlostdate BETWEEN @TempFromDate AND @CurrentDate
		AND (
			b.bettype BETWEEN 31 AND CASE WHEN @ShowRB=1 THEN 49 ELSE 0 END
			OR b.bettype BETWEEN 81 AND (CASE WHEN @showNG=1 THEN 120 ELSE 0 END)
			OR b.bettype BETWEEN 1101 AND (CASE WHEN @ShowLC=1 THEN 1199 ELSE 0 END)
			OR b.bettype BETWEEN 1201 AND (CASE WHEN @showVS=1 THEN 1299 ELSE 0 END)
			OR b.bettype BETWEEN 71 AND (CASE WHEN @showCS=1 THEN 71 ELSE 0 END)
			OR b.bettype BETWEEN 1501 AND (CASE WHEN @ShowKN=1 THEN 1599 ELSE 0 END)
			OR b.bettype BETWEEN 73 AND (CASE WHEN @showBI=1 THEN 73 ELSE 0 END)
		) 
		AND b.status IN ('WON','LOSE','DRAW','RUNNING')
	END
	
	--Get data from sum_winlost
	IF @FirstDate <= @MoveBetsDay
	BEGIN
		IF @CurrentDate >= @MoveBetsDay
			SET @TempToDate = @MoveBetsDay
		ELSE
			SET  @TempToDate = @CurrentDate
	
		IF @BalanceUpDay < @FirstDate 
			SELECT @BalanceUpDay=@FirstDate
			
		INSERT INTO #AvailableMember 
		SELECT DISTINCT smw.custid FROM dbo.sum_winloss smw
		WHERE smw.winlostdate BETWEEN @BalanceUpDay AND @TempToDate
		AND (
			smw.bettype BETWEEN 31 AND CASE WHEN @ShowRB=1 THEN 49 ELSE 0 END
			OR smw.bettype BETWEEN 81 AND (CASE WHEN @showNG=1 THEN 120 ELSE 0 END)
			OR smw.bettype BETWEEN 1101 AND (CASE WHEN @ShowLC=1 THEN 1199 ELSE 0 END)
			OR smw.bettype BETWEEN 1201 AND (CASE WHEN @showVS=1 THEN 1299 ELSE 0 END)
			OR smw.bettype BETWEEN 71 AND (CASE WHEN @showCS=1 THEN 71 ELSE 0 END)
			OR smw.bettype BETWEEN 1501 AND (CASE WHEN @ShowKN=1 THEN 1599 ELSE 0 END)
			OR smw.bettype BETWEEN 73 AND (CASE WHEN @showBI=1 THEN 73 ELSE 0 END)
		)
	END
	
	--Get data from sum_winlost_old
	IF @FirstDate < @BalanceUpDay
	BEGIN
		IF @CurrentDate >= DATEADD(dd, -1, @BalanceUpDay)
			SET @TempToDate = DATEADD(dd, -1, @BalanceUpDay)
		ELSE
			SET @TempToDate = @CurrentDate
			
		INSERT INTO #AvailableMember
		SELECT DISTINCT smwo.custid FROM bodb_Summary.dbo.sum_winloss_old smwo
		WHERE smwo.winlostdate BETWEEN @FirstDate AND @TempToDate
		AND (
			smwo.bettype BETWEEN 31 AND CASE WHEN @ShowRB=1 THEN 49 ELSE 0 END
			OR smwo.bettype BETWEEN 81 AND (CASE WHEN @showNG=1 THEN 120 ELSE 0 END)
			OR smwo.bettype BETWEEN 1101 AND (CASE WHEN @ShowLC=1 THEN 1199 ELSE 0 END)
			OR smwo.bettype BETWEEN 1201 AND (CASE WHEN @showVS=1 THEN 1299 ELSE 0 END)
			OR smwo.bettype BETWEEN 71 AND (CASE WHEN @showCS=1 THEN 71 ELSE 0 END)
			OR smwo.bettype BETWEEN 1501 AND (CASE WHEN @ShowKN=1 THEN 1599 ELSE 0 END)
			OR smwo.bettype BETWEEN 73 AND (CASE WHEN @showBI=1 THEN 73 ELSE 0 END)
		)	
	END
	    
	--Get data for downline list 
    IF @ShowRB = 1
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(ci.Disable151_AU & ci.Disable152_AU & ci.Disable152_UK & ci.Disable153_AU & ci.DisableHorseRacing & ci.DisableOpenTote)
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid IN (2,3) 
		WHERE ci.Enabled = 1
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(ci.Disable151_AU & ci.Disable152_AU & ci.Disable152_UK & ci.Disable153_AU & ci.DisableHorseRacing & ci.DisableOpenTote)
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid  = 1
		WHERE ci.custid IN (SELECT custid FROM #AvailableMember) AND ci.Enabled = 1                   
	END
	IF @ShowNG = 1
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			ci.DisableNumber
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid IN (2,3)  
		WHERE ci.Enabled = 1
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			ci.DisableNumber
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 1
		WHERE ci.custid IN (SELECT custid FROM #AvailableMember)  AND ci.Enabled = 1                    
	END
	IF @ShowLC = 1
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(~ci.SyncLiveCasino | ci.DisableLiveCasino)
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid IN (2,3) 
		WHERE ci.Enabled = 1
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(~ci.SyncLiveCasino | ci.DisableLiveCasino)
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 1
		WHERE ci.custid IN (SELECT custid FROM #AvailableMember)  AND ci.Enabled = 1                  
	END
	IF @ShowVS = 1
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			ci.DisableVirtualSports
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid IN (2,3)  
		WHERE ci.Enabled = 1
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			ci.DisableVirtualSports
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 1   
		WHERE ci.custid IN (SELECT custid FROM #AvailableMember)  AND ci.Enabled = 1                
	END
	IF @ShowCS = 1
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(~ci.SyncCasino |(ci.DisableCasino & ci.DisableCasinoBonus))
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid IN (2,3)  
		WHERE ci.Enabled = 1
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(~ci.SyncCasino |(ci.DisableCasino & ci.DisableCasinoBonus))
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 1  
		WHERE ci.custid IN (SELECT custid FROM #AvailableMember)  AND ci.Enabled = 1             
	END
	IF @ShowBI = 1
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(~ci.SyncBingo | ci.DisableBingo)
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid IN (2,3) 
		WHERE ci.Enabled = 1
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(~ci.SyncBingo | ci.DisableBingo)
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 1
		WHERE ci.custid IN (SELECT custid FROM #AvailableMember)  AND ci.Enabled = 1                 
	END
	IF @ShowKN = 1
    BEGIN      
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			CASE WHEN EXISTS(SELECT TOP 1 1 FROM dbo.CustGameType gt 
																WHERE gt.CustID = ci.CustID
																AND gt.IsDisabled = 0) THEN 0 ELSE 1 END
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid IN (2,3)
		WHERE ci.Enabled = 1 

		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			CASE WHEN EXISTS(SELECT TOP 1 1 FROM dbo.CustGameType gt 
																WHERE gt.CustID = ci.CustID
																AND gt.IsDisabled = 0) THEN 0 ELSE 1 END
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 1  
		WHERE ci.custid IN (SELECT custid FROM #AvailableMember)  AND ci.Enabled = 1                  
	END
		
	--Count enable/disable for downline
	INSERT INTO #TempResult
	SELECT #FiltedDownlineAcc.SuperID,#FiltedDownlineAcc.RoleID,
		SUM(CASE WHEN #FiltedDownlineAcc.IsDisable = 1 THEN 1 ELSE 0 END),
		SUM(CASE WHEN #FiltedDownlineAcc.IsDisable = 0 THEN 1 ELSE 0 END)
	FROM #FiltedDownlineAcc
	GROUP BY #FiltedDownlineAcc.SuperID,#FiltedDownlineAcc.RoleID

	--Update calculated enable/disable to result table
	UPDATE #FiltedCreditSuper
	SET
		#FiltedCreditSuper.MasterEnabled = ISNULL((SELECT #TempResult.EnableCnt FROM #TempResult WHERE 
												#FiltedCreditSuper.CustID = #TempResult.SuperID 
												AND 
												#TempResult.RoleID = 3),0),
		#FiltedCreditSuper.MasterDisabled =  ISNULL((SELECT #TempResult.DisableCnt FROM #TempResult WHERE 
												#FiltedCreditSuper.CustID = #TempResult.SuperID 
												AND 
												#TempResult.RoleID = 3),0),
		#FiltedCreditSuper.AgentEnabled =  ISNULL((SELECT #TempResult.EnableCnt FROM #TempResult WHERE 
												#FiltedCreditSuper.CustID = #TempResult.SuperID 
												AND 
												#TempResult.RoleID = 2),0),
		#FiltedCreditSuper.AgentDisabled =  ISNULL((SELECT #TempResult.DisableCnt FROM #TempResult WHERE 
												#FiltedCreditSuper.CustID = #TempResult.SuperID 
												AND 
												#TempResult.RoleID = 2),0),
		#FiltedCreditSuper.MemberEnabled =  ISNULL((SELECT #TempResult.EnableCnt FROM #TempResult WHERE 
												#FiltedCreditSuper.CustID = #TempResult.SuperID 
												AND 
												#TempResult.RoleID = 1),0),
		#FiltedCreditSuper.MemberDisabled =  ISNULL((SELECT #TempResult.DisableCnt FROM #TempResult WHERE 
												#FiltedCreditSuper.CustID = #TempResult.SuperID 
												AND 
												#TempResult.RoleID = 1),0)

	--Return result
	SELECT ROW_NUMBER() OVER(ORDER BY cust.username,e.currency) As RowNum,cust.username,rs.SuperStatus,e.currency,rs.MasterEnabled,rs.MasterDisabled,
			rs.AgentEnabled,rs.AgentDisabled,rs.MemberEnabled,rs.MemberDisabled
	FROM #FiltedCreditSuper rs
	JOIN dbo.Customer cust ON cust.custid = rs.CustID 
	JOIN dbo.Exchange e ON e.exchangeid = cust.currency

	
	--Drop temp tables
	DROP TABLE #FiltedCreditSuper
	DROP TABLE #FiltedDownlineAcc
	DROP TABLE #AvailableMember
	DROP TABLE #TempResult
END
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_EnableDisableAccount_OnProduct] TO [bodbAdminNet]
