ALTER PROCEDURE [dbo].[Acc_Rpt_LicWinlossDetail_SAg2]    
 @LicenseeID INT,  
 @Currency  INT = 0,  
 @FromDate  SMALLDATETIME,    
 @ToDate  SMALLDATETIME,     
 @showSB  BIT=1,    
 @ShowRB  BIT=0,    
 @ShowNG  BIT=0,   
 @ShowBA  BIT=0,  
 @ShowLC  BIT=0,  
 @ShowVS  BIT=0,  
 @ShowCS  BIT=0, -- RNG Casino
 @MoveBetsDay SMALLDATETIME,  
 @IsOld BIT = 0,  
 @drawfilter SMALLINT = 1,  
 @excludeTest BIT = 0  
AS    
/*  
	Created: Scott   
	Date: 2013-02-15    
    Task : Winloss Report for Licensee Super Level  
    DB: DB052.bodb02    
     
    Revisions: 
		- 20130527@Jim: support RNG Casino
 Param's Explanation:    
   + @CustID: SuperID    
   + @drawfilter: 'No Draw' filter is supportted (1:Normal 2:No Draw 3:No Draw for Turnover only)  
   + @IsOld: 0 - query in table rptLicWinloss, 1 - query in table rptLicWinloss_old.   
   + @excludeTest: remove currency UUS  
   + @showSB: Show SportsBook bets  
   + @ShowRB: Show RB bets  
   + @ShowNG: Show Number game bets  
   + @ShowBA: Show Bet Aggregator bets (combined with Sportsbook or Number Game)  
   + @MoveBetsDay: The day we move tickets to bettrans14  
    
*/

    
BEGIN    
SET NOCOUNT ON    
  
CREATE TABLE #SAgWinLoss (    
 winlostdate  DATETIME,    
 CustID   INT,     
 Currency  INT,    
 TurnOver  MONEY,      
 Winlost   MONEY,  
 LicenseeWL  MONEY,   
 WinlossRB  MONEY,    
 AmtDueToBA  MONEY,     
 AmtDueToRB  MONEY,  
 CommBA   MONEY,     
 CommRB   MONEY,    
 PlayerComm   MONEY,  
 Company   MONEY,  
 Betcount  BIGINT  
)    

DECLARE @VNDCurrencyName VARCHAR(20)  
DECLARE @Super AS TABLE (custid int primary key, currency int)  
DECLARE @bettype AS TABLE (bettype INT PRIMARY KEY)  
DECLARE @sporttype TABLE(sporttype INT)  

SELECT @VNDCurrencyName = currency FROM exchange (NOLOCK) WHERE ExchangeId = 51   
    
INSERT INTO @Super(custid,currency)    
SELECT CustID,currency FROM Dep_CustSuper WITH (NOLOCK)    
WHERE  site = (SELECT LicenseeName FROM bodb_Licensee.dbo.Licensees (NOLOCK) WHERE LicenseeID = @LicenseeID )  
	AND (@Currency = 0 OR (@Currency<> 0 AND Currency=@Currency))  
	AND (@excludeTest=0 OR (@excludeTest=1 AND Currency <> 20))   

  
IF @ShowSB = 1    
	INSERT  INTO @sporttype( sporttype)
	VALUES  (0)   
  
IF @ShowRB = 1    
BEGIN    
	INSERT  INTO @sporttype( Sporttype) VALUES  (151)  
      
	INSERT INTO @bettype(bettype)  
	SELECT typeid 
	FROM bettype (NOLOCK)  
	WHERE (typeid BETWEEN 31 AND 33)  
END    

IF @ShowNG = 1  
BEGIN  
	INSERT INTO @sporttype(Sporttype)    
	VALUES(161)    

	INSERT INTO @bettype(bettype)  
	SELECT typeid FROM bettype (NOLOCK)  
	WHERE (typeid BETWEEN 81 AND 120)  
END   
IF @ShowLC = 1  
BEGIN  
	INSERT  INTO @sporttype( Sporttype)  
	VALUES  (162)  

	INSERT INTO @bettype(bettype)  
	SELECT typeid FROM bettype (NOLOCK)  
	WHERE (typeid BETWEEN 1101 AND 1199)  
END  

IF @ShowVS = 1  
BEGIN  
	INSERT  INTO @sporttype( Sporttype)  
	VALUES  (180)  

	INSERT INTO @bettype(bettype)  
	SELECT typeid FROM bettype (NOLOCK)  
	WHERE (typeid BETWEEN 1201 AND 1299)  
END  

IF @ShowCS=1 -- RNG Casino
BEGIN
	INSERT INTO @sporttype(sporttype)
	VALUES (251)
	INSERT INTO @bettype(bettype)
	VALUES(71)
END
  
DECLARE @TempFromDate DATETIME   
DECLARE @TempToDate DATETIME   
DECLARE @MaxOldDate DATETIME  
DECLARE @FDate DATETIME   
DECLARE @TDate DATETIME  
--to Deal With Parameter Sniffing  
SELECT @FDate=@FromDate,@TDate=@ToDate   
     
IF @TDate > @MoveBetsDay  
BEGIN  
	IF @FDate <= @MoveBetsDay   
		SET @TempFromDate =  DATEADD(DAY,1,@MoveBetsDay)  
	ELSE  
		SET @TempFromDate = @FDate  
  
	IF @ShowBA = 1  
	BEGIN  
		INSERT INTO #SAgWinLoss    
		SELECT b.winlostdate, b.srecommend,b.currency,   
			SUM(stake *  
				CASE WHEN @drawfilter IN (2,3) THEN  
					CASE WHEN b.statusID = 111 THEN 0  
						WHEN (b.statusID = 112 OR b.statusID = 113) AND ABS(modds) = 0.25 AND b.bettype IN(1,3,7,8,17,18) THEN 0.5  
					ELSE 1 END  
				ELSE 1 END  
			) turnover,	
			SUM(b.winlost - b.actual_stake) AS Winlost,    
			0 as LicenseeWL,  
			0 AS WinlossRB,  
			- SUM (b.winlost - b.actual_stake + awinlost + comm ) AS AmountDueToBA,  
			0 AS AmountDueToRB,  
			SUM (comm) AS CommBA,  
			0 AS CommRB,  
			SUM( b.playerComm  ) AS PlayerComm,  
			0 AS Company,  
			COUNT(b.transid) * CASE WHEN @drawfilter = 2 THEN  
									CASE WHEN b.statusID = 111 THEN 0  
									ELSE 1 END  
								ELSE 1 END  BetCount   
		FROM dbo.bettrans b WITH ( NOLOCK,INDEX=IX_srecommend)      
			INNER JOIN @Super s ON b.srecommend = s.custid  
			INNER JOIN bodb_Licensee.dbo.LicenseeBATransaction_active BA WITH (NOLOCK) ON s.custid=BA.srecommend and b.transid = BA.transid     
		WHERE	b.winlostdate BETWEEN @TempFromDate AND @TDate AND    
			b.statusID  IN (111, 112, 113)   
		GROUP BY b.winlostdate,b.currency,b.srecommend,b.statusID   
	END   
   
	IF @ShowSB=1  
	BEGIN  
		INSERT INTO #SAgWinLoss  
		SELECT b.winlostdate, b.srecommend, s.currency,   
			sum(stake *  
				CASE WHEN @drawfilter IN (2,3) THEN  
					CASE WHEN b.statusID = 111 THEN 0  
						WHEN (b.statusID = 112 OR b.statusID = 113) AND ABS(modds) = 0.25 AND b.bettype IN(1,3,7,8,17,18) THEN 0.5  
					ELSE 1 END  
				ELSE 1 END) turnover,  
			SUM(b.winlost - b.actual_stake) AS Winlost,    
			- SUM(b.winlost - b.actual_stake) AS LicenseeWL,  
			0 AS WinlossRB,  
			0 AS AmountDueToBA,  
			0 AS AmountDueToRB,  
			0 AS CommBA,  
			0 AS CommRB,  
			SUM( b.playercomm ) AS PlayerComm,  
			- SUM (b.winlost - b.actual_stake + awinlost + comm ) Company  ,  
			COUNT(b.transid)  
			* CASE WHEN @drawfilter = 2 THEN  
			CASE WHEN b.statusID = 111 THEN 0  
			ELSE 1 END  
			ELSE 1 END BetCount  
		FROM dbo.bettrans b WITH ( NOLOCK,INDEX=IX_srecommend )   
			INNER JOIN @Super s ON b.srecommend = s.custid  
		WHERE b.winlostdate BETWEEN @TempFromDate AND @TDate AND    
			b.statusID  IN (111, 112, 113) AND  
			(b.bettype<31 OR (b.bettype BETWEEN 121 AND 999)) AND  
			b.tpositiontaking <> 0  
		GROUP BY b.winlostdate,s.currency,b.srecommend, b.statusID    
	END  
   
	IF (@ShowNG=1 OR @ShowLC=1 OR @ShowVS=1 OR @ShowRB=1 OR @ShowCS=1)
	BEGIN  
		INSERT INTO #SAgWinLoss  
		SELECT b.winlostdate,b.srecommend,s.currency,   
			sum(  
			CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN stake/2 ELSE stake END  
			*  
			CASE WHEN @drawfilter IN (2,3) THEN  
				CASE WHEN b.statusID = 111 THEN 0  
				WHEN (b.statusID = 112 OR b.statusID = 113) AND ABS(modds) = 0.25 AND b.bettype IN(1,3,7,8,17,18) THEN 0.5  
				ELSE 1 END  
				ELSE 1 END ) turnover,  
			SUM(b.winlost - b.actual_stake) AS Winlost,    
			SUM(CASE WHEN b.bettype NOT BETWEEN 31 AND 33 THEN  -1 *(b.winlost - b.actual_stake) ELSE   0 END ) AS LicenseeWL,  
			SUM (CASE WHEN b.bettype BETWEEN 31 AND 33 THEN b.awinlost ELSE 0 END) AS WinlossRB,  
			0 AS AmountDueToBA,  
			- SUM (CASE WHEN b.bettype BETWEEN 31 AND 33 THEN b.winlost - b.actual_stake + awinlost + comm ELSE 0 END) as AmountDueToRB,  
			0 AS CommBA,  
			SUM (CASE WHEN b.bettype BETWEEN 31 AND 33 THEN comm ELSE 0 END) AS CommRB,  
			SUM( b.playercomm ) AS PlayerComm,  
			- SUM(CASE WHEN b.bettype NOT BETWEEN 31 AND 33 THEN b.awinlost + b.winlost - b.actual_stake + b.comm ELSE 0 END) Company  ,  
			COUNT(b.transid)  
			* CASE WHEN @drawfilter = 2 THEN  
			CASE WHEN b.statusID = 111 THEN 0  
			ELSE 1 END  
			ELSE 1 END  
			BetCount  
		FROM dbo.bettrans b WITH ( NOLOCK,INDEX=IX_srecommend )   
			INNER JOIN @Super s ON b.srecommend = s.custid  
			INNER JOIN @bettype bt ON b.bettype = bt.bettype  
		WHERE b.winlostdate BETWEEN @TempFromDate AND @TDate AND    
			b.statusID  IN (111, 112, 113)  
		GROUP BY b.winlostdate,s.currency,b.srecommend, b.statusID    
	END  
END    
   
IF @FDate <= @MoveBetsDay   
BEGIN  
 IF @TDate >= @MoveBetsDay  
   SET @TempToDate = @MoveBetsDay  
  ELSE  
   SET  @TempToDate = @TDate  
 IF @ShowBA = 1  
 BEGIN  
  INSERT INTO #SAgWinLoss    
  SELECT   
   b.winlostdate,    
   b.srecommend,  
   b.currency,  
   SUM(b.turnover  
    *  
    CASE WHEN @drawfilter IN (2,3) THEN  
     CASE WHEN b.statusID = 111  THEN 0  
     WHEN b.statusID IN (114,115) THEN 0.5  
     ELSE 1 END  
    ELSE 1 END  
   ),       
   SUM(b.winlost),    
   0 as LicenseeWL,  
   0 AS WinlossRB,  
   - SUM (b.winlost+b.awinlost+b.comm) AS AmountDueToBA,  
   0 AS AmountDueToRB,  
   SUM (comm ) AS CommBA,  
   0 AS CommRB,  
   SUM( b.playercomm) AS PlayerComm,  
   0 AS Company,  
   SUM(b.betcount)  
   * CASE WHEN @drawfilter = 2 THEN  
     CASE WHEN b.statusID = 111 THEN 0  
     ELSE 1 END  
    ELSE 1 END  
  FROM bodb_Licensee.dbo.rptLicWinloss2 b WITH ( NOLOCK )    
   INNER JOIN @super s ON s.custid = b.srecommend  
  WHERE    
   b.Winlostdate BETWEEN @FDate AND @TempToDate    
   AND b.roleid = 2     
   AND b.statusID <> 101 --exclude REJECT bets  
   AND ISNULL(b.isBA,0) = 1  
  GROUP BY  b.winlostdate,b.currency, b.srecommend  , b.statusID  
 END  
   
 --exclude BA tickets  
 IF (@showSB = 1 or @ShowRB = 1 or @ShowNG = 1 OR @ShowLC=1 OR @ShowVS=1 OR @ShowCS=1)  
 BEGIN  
  INSERT INTO #SAgWinLoss    
  SELECT   
   b.winlostdate,    
   b.srecommend,  
   b.currency,  
   SUM(b.turnover  
    *  
    CASE WHEN @drawfilter IN (2,3) THEN  
     CASE WHEN b.statusID = 111  THEN 0  
     WHEN b.statusID IN (114,115) THEN 0.5  
     ELSE 1 END  
    ELSE 1 END  
   ),       
   SUM(b.winlost),    
   - SUM(CASE WHEN (b.sporttype IN (0,161,162,180,251))  THEN b.winlost ELSE 0 END) AS LicenseeWL ,  
   SUM(CASE WHEN b.sporttype = 151 THEN b.awinlost ELSE 0 END) AS WinlossRB,  
   0 AS AmountDueToBA,  
   - SUM ( CASE WHEN b.sporttype = 151 THEN (b.winlost+b.awinlost+b.comm) ELSE 0 END) AS AmountDueToRB,  
   0 AS CommBA,  
   SUM ( CASE WHEN b.sporttype = 151 THEN comm  ELSE 0 END) AS CommRB,  
   SUM( b.playercomm ) AS PlayerComm,   
   - SUM(CASE WHEN b.sporttype <> 151 THEN  b.awinlost + b.winlost + b.comm ELSE 0 END)  as Company   ,  
   SUM(b.betcount)  
   * CASE WHEN @drawfilter = 2 THEN  
     CASE WHEN b.statusID = 111 THEN 0  
     ELSE 1 END  
    ELSE 1 END  
  FROM   
   bodb_Licensee.dbo.rptLicWinloss2 b WITH ( NOLOCK )    
   INNER JOIN @super s ON s.custid = b.srecommend  
   INNER JOIN @sporttype t ON b.sporttype = t.sporttype  
  WHERE    
   b.Winlostdate BETWEEN @FDate AND @TempToDate    
   AND b.roleid = 2     
   AND b.statusID <> 101 --exclude REJECT bets  
   AND ISNULL(b.isBA,0) = 0  
  GROUP BY  b.winlostdate,b.currency, b.srecommend, b.statusID  
 END  
   
     
 END   
 IF @IsOld = 1   
 BEGIN  
 SELECT @MaxOldDate = max(winlostdate) FROM bodb_Licensee.dbo.rptLicWinloss_old (NOLOCK)  
 IF @TDate >= @MaxOldDate  
   SET @TempToDate = @MaxOldDate  
  ELSE  
   SET  @TempToDate = @TDate  
   
 IF @ShowBA = 1  
 BEGIN  
  INSERT INTO #SAgWinLoss    
  SELECT   
   b.winlostdate,    
   b.srecommend,  
   b.currency,  
   SUM(b.turnover  
    *  
    CASE WHEN @drawfilter IN (2,3) THEN  
     CASE WHEN b.statusID = 111  THEN 0  
     WHEN b.statusID IN (114,115) THEN 0.5  
     ELSE 1 END  
    ELSE 1 END  
   ),       
   SUM(b.winlost),    
   0 as LicenseeWL,  
   0 AS WinlossRB,  
   - SUM (b.winlost+b.awinlost+b.comm) AS AmountDueToBA,  
   0 AS AmountDueToRB,  
   SUM ( CASE WHEN ISNULL(b.isBA,0) = 1 THEN comm   ELSE 0 END) AS CommBA,  
   0 AS CommRB,  
   SUM( b.PlayerComm ) AS PlayerCommm,  
   0 AS Company,  
   SUM(b.betcount)  
   * CASE WHEN @drawfilter = 2 THEN  
     CASE WHEN b.statusID = 111 THEN 0  
     ELSE 1 END  
    ELSE 1 END  
  FROM   
   bodb_Licensee.dbo.rptLicWinloss_old b WITH ( NOLOCK)    
   INNER JOIN @super s ON s.custid = b.srecommend  
  WHERE    
   b.Winlostdate BETWEEN @FDate AND @TempToDate    
   AND b.roleid = 2     
   AND b.statusID <> 101 --exclude REJECT bets  
   AND ISNULL(b.isBA,0) = 1  
  GROUP BY  b.winlostdate,b.currency, b.srecommend, b.statusID  
 END  
   
 --exclude BA tickets  
 IF (@showSB = 1 or @ShowRB = 1 or @ShowNG = 1 OR @ShowLC=1 OR @ShowVS=1 OR @ShowCS=1)  
 BEGIN  
  INSERT INTO #SAgWinLoss    
  SELECT   
   b.winlostdate,    
   b.srecommend,  
   b.currency,  
   SUM(b.turnover  
    *  
    CASE WHEN @drawfilter IN (2,3) THEN  
     CASE WHEN b.statusID = 111  THEN 0  
     WHEN b.statusID IN (114,115) THEN 0.5  
     ELSE 1 END  
    ELSE 1 END  
   ),       
   SUM(b.winlost),    
   - SUM(CASE WHEN (b.sporttype IN (0,161,162,180,251))  THEN b.winlost ELSE 0 END) AS LicenseeWL ,  
   SUM(CASE WHEN b.sporttype = 151 THEN b.awinlost ELSE 0 END) AS WinlossRB,  
   0 AS AmountDueToBA,  
   - SUM ( CASE WHEN b.sporttype = 151 THEN (b.winlost+b.awinlost+b.comm) ELSE 0 END) AS AmountDueToRB,  
   0 AS CommBA,  
   SUM ( CASE WHEN b.sporttype = 151 THEN comm ELSE 0 END) AS CommRB,  
   SUM(b.playercomm) AS PlayerComm,  
   - SUM(CASE WHEN b.sporttype <> 151 THEN b.awinlost + b.winlost + b.comm ELSE 0 END)  as Company   ,  
   SUM(b.betcount)  
   * CASE WHEN @drawfilter = 2 THEN  
     CASE WHEN b.statusID = 111 THEN 0  
     ELSE 1 END  
    ELSE 1 END  
  FROM   
   bodb_Licensee.dbo.rptLicWinloss_old b WITH ( NOLOCK)    
   INNER JOIN @super s ON s.custid = b.srecommend  
   INNER JOIN @sporttype t ON b.sporttype = t.sporttype  
  WHERE    
   b.Winlostdate BETWEEN @FDate AND @TempToDate    
   AND b.roleid = 2     
   AND b.statusID <> 101 --exclude REJECT bets  
   AND ISNULL(b.isBA,0) = 0  
  GROUP BY  b.winlostdate,b.currency, b.srecommend, b.statusID  
 END  
   
 END  
   
 CREATE NONCLUSTERED INDEX IDX_Index_SA ON #SAgWinLoss(Currency)  
 SELECT * INTO #TempExchange  
 FROM Lrf_f_GetExchangeDaily (@Fdate,@Tdate)  
 WHERE exchangeid IN (SELECT DISTINCT Currency FROM #SAgWinLoss)  
   
 SELECT     
 c.username,    
 w.custid,   
 w.currency,  
 CASE WHEN w.Currency = 51 THEN @VNDCurrencyName   
   ELSE e.Code END AS CurrencyName,  
 SUM(TurnOver) AS Turnover,     
 SUM(Winlost)  AS Winlost,    
 SUM(LicenseeWL) AS LicenseeWL,  
 SUM(WinlossRB) AS WinlossRB,  
 SUM(CommBA) AS CommBA,  
 SUM(CommRB) AS CommRB,  
 SUM(PlayerComm) AS PlayerComm,  
 SUM(AmtDuetoBA) AS AmtDuetoBA,  
 SUM(AmtDuetoRB) AS AmtDuetoRB,  
 SUM(Company) AS Company,  
 SUM(Betcount) AS Betcount,  
 --BaseRM    
 CAST(SUM(TurnOver*e.MYR) AS MONEY) AS TurnoverMYR,     
 CAST(SUM(Winlost*e.MYR) AS MONEY) AS WinlostMYR,    
 CAST(SUM(LicenseeWL*e.MYR) AS MONEY) AS LicenseeWLMYR,  
 CAST(SUM(WinlossRB*e.MYR) AS MONEY) AS WinlossRBMYR,  
 CAST(SUM(CommBA * e.MYR) AS MONEY) AS CommBAMYR,  
 CAST(SUM(CommRB * e.MYR) AS MONEY) AS CommRBMYR,  
 CAST(SUM(PlayerComm*e.MYR) AS MONEY) AS PlayerCommMYR,  
 CAST(SUM(AmtDuetoBA*e.MYR) AS MONEY) AS AmtDuetoBAMYR,  
 CAST(SUM(AmtDuetoRB*e.MYR) AS MONEY) AS AmtDuetoRBMYR,  
 CAST(SUM(Company * e.MYR) AS MONEY) AS CompanyMYR,  
 --BaseUSD    
 CAST(SUM(TurnOver*e.USD) AS MONEY) AS TurnoverUSD,     
 CAST(SUM(Winlost*e.USD) AS MONEY) AS WinlostUSD,    
 CAST(SUM(LicenseeWL*e.USD) AS MONEY) AS LicenseeWLUSD,  
 CAST(SUM(WinlossRB*e.USD) AS MONEY) AS WinlossRBUSD,  
 CAST(SUM(CommBA * e.USD) AS MONEY) AS CommBAUSD,  
 CAST(SUM(CommRB * e.USD) AS MONEY) AS CommRBUSD,  
 CAST(SUM(PlayerComm*e.USD) AS MONEY) AS PlayerCommUSD,  
 CAST(SUM(AmtDuetoBA*e.USD) AS MONEY) AS AmtDuetoBAUSD,  
 CAST(SUM(AmtDuetoRB*e.USD) AS MONEY) AS AmtDuetoRBUSD,   
 CAST(SUM(Company * e.USD) AS MONEY) AS CompanyUSD,  
 --BaseEUR    
 CAST(SUM(TurnOver*e.EUR) AS MONEY) AS TurnoverEUR,     
 CAST(SUM(Winlost*e.EUR) AS MONEY) AS WinlostEUR,    
 CAST(SUM(LicenseeWL*e.EUR) AS MONEY) AS LicenseeWLEUR,  
 CAST(SUM(WinlossRB*e.EUR) AS MONEY) AS WinlossRBEUR,  
 CAST(SUM(CommBA * e.EUR) AS MONEY) AS CommBAEUR,  
 CAST(SUM(CommRB * e.EUR) AS MONEY) AS CommRBEUR,  
 CAST(SUM(PlayerComm*e.EUR) AS MONEY) AS PlayerCommEUR,  
 CAST(SUM(AmtDuetoBA*e.EUR) AS MONEY) AS AmtDuetoBAEUR,  
 CAST(SUM(AmtDuetoRB*e.EUR) AS MONEY) AS AmtDuetoRBEUR,  
 CAST(SUM(Company * e.EUR) AS MONEY) AS CompanyEUR  
             
 FROM #SAgWinLoss w     
  INNER JOIN #TempExchange e  
  ON w.winlostdate = e.ExchangeDate AND w.currency = e.ExchangeId  
  INNER JOIN Customer c WITH(NOLOCK) ON w.custid = c.custid  
  GROUP BY w.currency,w.custid, c.username,   
   CASE WHEN w.Currency = 51 THEN @VNDCurrencyName   
    ELSE e.Code END  
  ORDER BY w.currency  
  
DROP TABLE #SAgWinLoss   
DROP TABLE #TempExchange  
  
END     
GO


GRANT EXECUTE ON [dbo].[Acc_Rpt_LicWinlossDetail_SAg2] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_LicWinlossDetail_SAg2] TO [bodbLicenseeNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_LicWinlossDetail_SAg2] TO [vnteam] 
