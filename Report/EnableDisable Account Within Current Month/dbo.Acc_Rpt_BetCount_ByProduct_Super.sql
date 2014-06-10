CREATE PROCEDURE [dbo].[Acc_Rpt_BetCount_ByProduct_Super]
	@MoveBetsDay	SMALLDATETIME,
	@BalanceUpDay	SMALLDATETIME,
	@ListCurrency	NVARCHAR(150)	= 'all', 
	@CustID			INT,
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
    Task : Total settled/running bets count per Product by super within current month
    DB: DBAGE/bodb02  
   
    Revisions:  
		
	Param's Explanation:  
	  + @MoveBetsDay: The day of moving bets to battrans14
	  + @BalanceUpDay: The day of moving bets to battransbk
	  + @ListCurrency: The specified date used as one of the filter criterias,if it is 'all' then no need filtered by currenies
	  + @CustID: SuperID
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
			
	--Table of Super/master/Member that belong to real super above	
	CREATE TABLE #FiltedDownlineAcc(
		CustID		INT,
		IsDisable	BIT,
		BetStatus	NVARCHAR(10), 
		BetCount	INT
		)
		
	--Table of member that played bet within current month	
	CREATE TABLE #AvailableMember(CustID INT, BetStatus NVARCHAR(10), BetCount INT)	
	
	SELECT @CurrentDate = CAST(GETDATE() AS DATE)
	SELECT @FirstDate = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(@CurrentDate)-1),@CurrentDate),101)
                            
    --Get data from bettrans       
	IF @CurrentDate > @MoveBetsDay
	BEGIN
		IF @FirstDate <= @MoveBetsDay 
			SET @TempFromDate =  DATEADD(DAY,1,@MoveBetsDay)
		ELSE
			SET @TempFromDate = @FirstDate
			
		INSERT INTO #AvailableMember
		SELECT b.custid,b.[status],COUNT(1) FROM dbo.bettrans b WITH(NOLOCK)
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
		AND b.status IN ('WON','LOSE','DRAW','RUNNING') AND b.srecommend = @CustID
		GROUP BY b.custid,b.[status]
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
		SELECT smw.custid,'SETTLED',smw.BetCount FROM dbo.sum_winloss smw WITH(NOLOCK)
		WHERE smw.winlostdate BETWEEN @BalanceUpDay AND @TempToDate
		AND (
			smw.bettype BETWEEN 31 AND CASE WHEN @ShowRB=1 THEN 49 ELSE 0 END
			OR smw.bettype BETWEEN 81 AND (CASE WHEN @showNG=1 THEN 120 ELSE 0 END)
			OR smw.bettype BETWEEN 1101 AND (CASE WHEN @ShowLC=1 THEN 1199 ELSE 0 END)
			OR smw.bettype BETWEEN 1201 AND (CASE WHEN @showVS=1 THEN 1299 ELSE 0 END)
			OR smw.bettype BETWEEN 71 AND (CASE WHEN @showCS=1 THEN 71 ELSE 0 END)
			OR smw.bettype BETWEEN 1501 AND (CASE WHEN @ShowKN=1 THEN 1599 ELSE 0 END)
			OR smw.bettype BETWEEN 73 AND (CASE WHEN @showBI=1 THEN 73 ELSE 0 END)
		) AND smw.srecommend = @CustID
	END
	
	--Get data from sum_winlost_old
	IF @FirstDate < @BalanceUpDay
	BEGIN
		IF @CurrentDate >= DATEADD(dd, -1, @BalanceUpDay)
			SET @TempToDate = DATEADD(dd, -1, @BalanceUpDay)
		ELSE
			SET @TempToDate = @CurrentDate
			
		INSERT INTO #AvailableMember
		SELECT smwo.custid,'SETTLED',smwo.BetCount FROM bodb_Summary.dbo.sum_winloss_old smwo WITH(NOLOCK)
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
		AND smwo.srecommend = @CustID
	END
	    
	--Get data for downline list 
    IF @ShowRB = 1
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT ci.custid,
			(ci.Disable151_AU & ci.Disable152_AU & ci.Disable152_UK & ci.Disable153_AU & ci.DisableHorseRacing & ci.DisableOpenTote),
			av.BetStatus,
			av.BetCount
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #AvailableMember av ON av.CustID = ci.custid                 
	END
	IF @ShowNG = 1
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT ci.custid,
			ci.DisableNumber,
			av.BetStatus,
			av.BetCount
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #AvailableMember av ON av.CustID = ci.custid                  
	END
	IF @ShowLC = 1
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT ci.custid,
			(~ci.SyncLiveCasino | ci.DisableLiveCasino),
			av.BetStatus,
			av.BetCount
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #AvailableMember av ON av.CustID = ci.custid               
	END
	IF @ShowVS = 1
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT ci.custid,
			ci.DisableVirtualSports,
			av.BetStatus,
			av.BetCount
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #AvailableMember av ON av.CustID = ci.custid               
	END
	IF @ShowCS = 1
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT ci.custid,
			(~ci.SyncCasino |(ci.DisableCasino & ci.DisableCasinoBonus)),
			av.BetStatus,
			av.BetCount
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #AvailableMember av ON av.CustID = ci.custid             
	END
	IF @ShowBI = 1
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT ci.custid,
			(~ci.SyncBingo | ci.DisableBingo),
			av.BetStatus,
			av.BetCount
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #AvailableMember av ON av.CustID = ci.custid                   
	END
	IF @ShowKN = 1
    BEGIN      
		INSERT INTO #FiltedDownlineAcc
		SELECT ci.custid,
			CASE WHEN EXISTS(SELECT TOP 1 1 FROM dbo.CustGameType gt WITH(NOLOCK,INDEX=PK_CustGameType)
																WHERE gt.CustID = ci.CustID AND gt.IsDisabled = 0 ) 
																THEN 0 
																ELSE 1 
																END,
			av.BetStatus,
			av.BetCount
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #AvailableMember av ON av.CustID = ci.custid                 
	END


	--Return result
	SELECT cs.custid,cs.username,rs.IsDisable,
			SUM(CASE WHEN rs.BetStatus <> 'running' THEN rs.BetCount ELSE 0 END) SettledBets,
			SUM(CASE WHEN rs.BetStatus = 'running' THEN rs.BetCount ELSE 0 END)  RunningBets
	FROM #FiltedDownlineAcc rs
	JOIN dbo.Customer cs ON cs.custid = rs.CustID
	GROUP BY cs.custid,cs.username,rs.IsDisable
	ORDER BY cs.username
	
	--Drop temp tables
	DROP TABLE #FiltedDownlineAcc
	DROP TABLE #AvailableMember
END
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_BetCount_ByProduct_Super] TO [bodbAdminNet]
