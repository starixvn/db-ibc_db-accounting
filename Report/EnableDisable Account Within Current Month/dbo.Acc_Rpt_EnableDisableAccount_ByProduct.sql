CREATE PROCEDURE [dbo].[Acc_Rpt_EnableDisableAccount_ByProduct]
	@MoveBetsDay	SMALLDATETIME,
	@BalanceUpDay	SMALLDATETIME,
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
	  + @ListCurrency: The specified date used as one of the filter criterias, if its value is 'all' then no need to be filtered by currency
	  + @ShowRB: Include RB bets 
	  + @ShowNG: Include Number game bets 
	  + @ShowKN: Include Keno 
	  + @ShowLC: Include Live Casino 
	  + @ShowVS: Include Virtual Sports 
	  +	@ShowCS: Include RNG Casino 
	  +	@ShowBI: Include Bingo 

  
*/  
BEGIN
	SET NOCOUNT ON
	
	DECLARE @CurrentDate SMALLDATETIME
	DECLARE @FirstDate SMALLDATETIME
	DECLARE @TempFromDate SMALLDATETIME
	DECLARE @TempToDate SMALLDATETIME

	
	--Table of real creadit super filter by currency
	CREATE TABLE #FiltedCreditSuper(
			CustID INT,
			SuperStatus BIT
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
	
	SELECT @CurrentDate = CAST(GETDATE() AS DATE)
	SELECT @FirstDate = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(@CurrentDate)-1),@CurrentDate),101)
	
	--Get real credit super filterd by currencies
	INSERT INTO #FiltedCreditSuper(CustID,SuperStatus)
	SELECT ci.custid,
		CASE
			WHEN @ShowRB = 1 THEN (ci.Disable151_AU & ci.Disable152_AU & ci.Disable152_UK & ci.Disable153_AU & ci.DisableHorseRacing & ci.DisableOpenTote)
			WHEN @ShowNG = 1 THEN ci.DisableNumber
			WHEN @ShowKN = 1 THEN CASE WHEN EXISTS(SELECT TOP 1 1 FROM dbo.CustGameType gt WITH(NOLOCK,INDEX=PK_CustGameType)
																WHERE gt.CustID = ci.CustID AND gt.IsDisabled = 0 ) 
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
		SELECT DISTINCT b.custid FROM dbo.bettrans b WITH(NOLOCK)
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
		AND b.status IN ('WON','LOSE','DRAW','running')
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
		SELECT DISTINCT smw.custid FROM dbo.sum_winloss smw WITH(NOLOCK)
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
		SELECT DISTINCT smwo.custid FROM bodb_Summary.dbo.sum_winloss_old smwo WITH(NOLOCK)
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
			CASE WHEN EXISTS(SELECT TOP 1 1 FROM dbo.CustGameType gt WITH(NOLOCK,INDEX=PK_CustGameType)
																WHERE gt.CustID = ci.CustID AND gt.IsDisabled = 0 ) 
																THEN 0 
																ELSE 1 
																END
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid IN (2,3)
		WHERE ci.Enabled = 1 

		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			CASE WHEN EXISTS(SELECT TOP 1 1 FROM dbo.CustGameType gt WITH(NOLOCK,INDEX=PK_CustGameType)
																WHERE gt.CustID = ci.CustID AND gt.IsDisabled = 0 ) 
																THEN 0 
																ELSE 1 
																END
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 1  
		WHERE ci.custid IN (SELECT custid FROM #AvailableMember)  AND ci.Enabled = 1                  
	END
		

	--Return result
	SELECT cust.custid,cust.username,sp.SuperStatus as IsDiable,e.currency,
			ISNULL(rs.MasterEnabled,0)	MasterEnabled,
			ISNULL(rs.MasterDisabled,0) MasterDisabled,
			ISNULL(rs.AgentEnabled,0)	AgentEnabled,
			ISNULL(rs.AgentDisabled,0)	AgentDisabled,
			ISNULL(rs.MemberEnabled,0)	MemberEnabled,
			ISNULL(rs.MemberDisabled,0)	MemberDisabled
	FROM #FiltedCreditSuper sp
	JOIN dbo.Customer cust WITH(NOLOCK) ON cust.custid = sp.CustID 
	JOIN dbo.Exchange e WITH(NOLOCK) ON e.exchangeid = cust.currency
	LEFT JOIN
	(SELECT dl.SuperID,
		SUM(CASE WHEN dl.IsDisable = 0 AND dl.RoleID = 3 THEN 1 ELSE 0 END) MasterEnabled,
		SUM(CASE WHEN dl.IsDisable = 1 AND dl.RoleID = 3 THEN 1 ELSE 0 END) MasterDisabled,
		SUM(CASE WHEN dl.IsDisable = 0 AND dl.RoleID = 2 THEN 1 ELSE 0 END) AgentEnabled,
		SUM(CASE WHEN dl.IsDisable = 1 AND dl.RoleID = 2 THEN 1 ELSE 0 END) AgentDisabled,
		SUM(CASE WHEN dl.IsDisable = 0 AND dl.RoleID = 1 THEN 1 ELSE 0 END) MemberEnabled,
		SUM(CASE WHEN dl.IsDisable = 1 AND dl.RoleID = 1 THEN 1 ELSE 0 END) MemberDisabled
	FROM #FiltedDownlineAcc dl 
	GROUP BY dl.SuperID) rs ON sp.CustID = rs.SuperID
	ORDER BY cust.username,e.currency

	
	--Drop temp tables
	DROP TABLE #FiltedCreditSuper
	DROP TABLE #FiltedDownlineAcc
	DROP TABLE #AvailableMember
END
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_EnableDisableAccount_ByProduct] TO [bodbAdminNet]
