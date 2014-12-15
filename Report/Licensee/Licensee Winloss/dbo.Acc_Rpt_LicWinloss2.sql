USE [bodb02]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_Rpt_LicWinloss2] 
 @LicenseeID	INT,
 @Currency		INT = 0,
 @FromDate		SMALLDATETIME,  
 @ToDate		SMALLDATETIME,   
 @showSB		BIT=1,  
 @ShowRB		BIT=0,  
 @ShowNG		BIT=0, 
 @ShowBA		BIT=0,
 @ShowLC		BIT=0,
 @ShowVS		BIT=0,
 @ShowCS   		BIT=0, -- RNG Casino
 @ShowKN		BIT=0,--Keno
 @ReportType	TINYINT=1,  
 @MoveBetsDay SMALLDATETIME,
 @IsOld BIT = 0, 
 @drawfilter SMALLINT = 1  ,
 @excludeTest BIT = 0
AS  
/*  Created: Henry  
	Date: 2011-07-06
    Task : Winloss Report for Licensee 
    DB: DB052.bodb02  
   
    Revisions:  
		- 20110729@Henry: offer 3 new bettypes for Number Game 
		- 20110903@Henry: support HALF WON/LOSE FOR ONLY bettype in (1,3,7,8,17,18)
		- 20110907@Henry: support to view Licensee Fee
		- 20110930@Henry: put a check for non-BA block
		- 20111013@Henry: change to use rptLicWinloss2
		- 20111208@Jim : change condition Bettype<31 
		- 20120214@Jim: change to use  table ExchangeDaily by use function Lrf_f_GetExchangeDaily
		- 20120601@Jim: enhance query performance 
		- 20120801@Jim: add PlayerComm value 
		- 20120816@Jim: add live casino
		- 20120905@Henry: add Virtual Sports
		- 20130527@Jim: support RNG Casino 
		- 20140331@Hannah: offer Keno
		- 20140704@Jim: offer Sporting solution
		- 20141205@Winnie: change from LicenseeCust to f_SelLicenseeCust ( task change currency KeenOcean)
	Param's Explanation:  
	  + @ReportType: 1-Daily; 2-Monthly;  
	  +	@drawfilter: 'No Draw' filter is supportted (1:Normal 2:No Draw 3:No Draw for Turnover only)
	  + @IsOld: 0 - query in table rptLicWinloss, 1 - query in table rptLicWinloss_old. 
	  + @excludeTest: remove currency UUS
	  + @showSB: Show SportsBook bets
	  + @ShowRB: Show RB bets
	  + @ShowNG: Show Number game bets
	  + @ShowBA: Show Bet Aggregator bets (combined with Sportsbook or Number Game)
	  + @ShowLC: Show Live Casino
	  + @ShowVS: Show Virtual Sports
	  + @MoveBetsDay: The day we move tickets to bettrans14
*/  
BEGIN  
SET NOCOUNT ON  

CREATE TABLE #SAgWinLoss  (  
	winlostdate		DATETIME,  
	Currency		INT,
	TurnOver		MONEY,   	
	Winlost			MONEY,  
	LicenseeWL		MONEY, 
	WinlossRB		MONEY,
	AmtDueToBA	MONEY,   
	AmtDueToRB	MONEY,
	CommBA			MONEY,   
	CommRB		MONEY,   
	PlayerComm 	MONEY,
	Company		MONEY,
	Betcount		BIGINT
)  

DECLARE @tempAg	TABLE( custID INT,currency INT) 
DECLARE @LicenseeName VARCHAR(50)
DECLARE @VNDCurrencyName VARCHAR(20)
DECLARE @bettype AS TABLE (bettype INT PRIMARY KEY)
DECLARE @sporttype TABLE(sporttype INT)


SELECT @LicenseeName = LicenseeName FROM bodb_Licensee.dbo.Licensees (NOLOCK) WHERE LicenseeID = @LicenseeID

INSERT INTO @tempAg (custID,currency) 
SELECT DISTINCT custID,currency FROM bodb_Licensee.dbo.f_SelLicenseeCust(0) --bodb_Licensee.dbo.LicenseeCust (NOLOCK) 
WHERE 
	LicenseeID = @LicenseeID
	AND (@Currency = 0 OR (@Currency<> 0 AND Currency=@Currency))
	AND (@excludeTest=0 OR (@excludeTest=1 AND Currency <> 20))	

	

SELECT @VNDCurrencyName = currency FROM exchange (NOLOCK) WHERE ExchangeId = 51

DECLARE @Super AS TABLE (custid int , currency int)
INSERT INTO @Super(custid,currency)  
SELECT DISTINCT CustID,currency FROM bodb_Licensee.dbo.f_SelDepCustSuper(@LicenseeName)--Dep_CustSuper WITH (NOLOCK)  
--WHERE  site = @LicenseeName	

IF @ShowSB = 1  
BEGIN  
	INSERT  INTO @sporttype( sporttype)
    VALUES  (0)	

END  

IF @ShowRB = 1  
BEGIN  
	INSERT  INTO @sporttype( Sporttype)
    VALUES  (151)
    
    INSERT INTO @bettype(bettype)
	SELECT typeid FROM bettype (NOLOCK)
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

IF @ShowKN=1 -- Keno
BEGIN 
	INSERT INTO @sporttype (sporttype)
	VALUES(202)

	INSERT INTO @bettype(bettype)
	SELECT typeid FROM bettype (NOLOCK)
	WHERE (typeid BETWEEN 1501 AND 1599)
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
	
	IF @ShowBA=1 
	BEGIN
	
		INSERT INTO #SAgWinLoss  
		
		SELECT   
			b.winlostdate,  
			b.currency,
			SUM( stake
				*
				CASE WHEN @drawfilter IN (2,3) THEN
					CASE WHEN b.statusID = 111 THEN 0
					WHEN (b.statusID = 112 OR b.statusID = 113)  AND ABS(modds) = 0.25 AND b.bettype IN(1,3,7,8,17,18) THEN 0.5
					ELSE 1 END
				ELSE 1 END
			) turnover, 
			SUM(b.winlost - b.actual_stake) AS Winlost,  
			0 as LicenseeWL,
			0 as WinlossRB,
			- SUM (b.winlost - b.actual_stake + awinlost + comm ) as AmountDueToBA,
			0 as AmountDueToRB,
			SUM (comm) as CommBA,
			0 as CommRB,
			SUM( PlayerComm ) AS PlayerComm,
			0 as Company,
			COUNT(b.transid)
			* CASE WHEN @drawfilter = 2 THEN
					CASE WHEN b.statusID = 111 THEN 0
					ELSE 1 END
				ELSE 1 END
			   BetCount	
		FROM 
			dbo.bettrans b WITH ( NOLOCK,INDEX=IX_srecommend)    
			INNER JOIN @TempAg tma ON tma.CustID=b.recommend AND tma.currency=b.currency
			INNER JOIN @Super s ON b.srecommend = s.custid AND s.currency=b.currency
			INNER JOIN bodb_Licensee.dbo.LicenseeBATransaction_active BA WITH (NOLOCK) ON s.custid=BA.srecommend and b.transid = BA.transid 	 
		WHERE 
			b.winlostdate BETWEEN @TempFromDate AND @TDate AND 
			b.statusID  IN (111, 112, 113) 
		GROUP BY   
			b.winlostdate,b.currency, b.statusID
	END
	
	IF @ShowSB=1
	BEGIN
	
		INSERT INTO #SAgWinLoss
		SELECT   
			b.winlostdate,  
			s.currency,
			SUM(stake
				*
				CASE WHEN @drawfilter IN (2,3) THEN
					CASE WHEN b.statusID = 111 THEN 0
					WHEN (b.statusID = 112 OR b.statusID = 113)  AND ABS(modds) = 0.25 AND b.bettype IN(1,3,7,8,17,18) THEN 0.5
					ELSE 1 END
				ELSE 1 END
			) turnover, 
			SUM(b.winlost - b.actual_stake) AS Winlost,  
			- SUM(b.winlost - b.actual_stake) AS LicenseeWL,
			0 AS WinlossRB,
			0 as AmountDueToBA,
			0 as AmountDueToRB,
			0 as CommBA,
			0 as CommRB,
			SUM(PlayerComm) as PlayerComm,
			- SUM(b.awinlost + b.winlost - b.actual_stake + b.comm) Company  ,
			COUNT(b.transid)
			* CASE WHEN @drawfilter = 2 THEN
					CASE WHEN b.statusID = 111 THEN 0
					ELSE 1 END
				ELSE 1 END
			   BetCount	
		FROM 
			Bettrans b WITH ( NOLOCK,INDEX=IX_srecommend )
			INNER JOIN @Super s ON b.srecommend = s.custid AND b.currency=s.currency
			INNER JOIN @TempAg a ON b.recommend = a.custid AND b.currency=a.currency	
		WHERE 
			b.winlostdate BETWEEN @TempFromDate AND @TDate AND  		
			b.statusID  IN (111, 112, 113) AND
			(b.bettype<31 OR (b.bettype BETWEEN 121 AND 999) OR (b.bettype BETWEEN 1301 AND 1399) ) AND
			b.tpositiontaking <> 0
		GROUP BY   
			b.winlostdate,s.currency
			,statusID
	END
	
	IF (@ShowNG=1 OR @ShowLC=1 OR @ShowVS=1 OR @ShowRB=1 OR @ShowCS=1 OR @ShowKN=1)
	BEGIN
		INSERT INTO #SAgWinLoss
		SELECT   
			b.winlostdate,  
			s.currency,
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN stake/2 ELSE stake END
				*
				CASE WHEN @drawfilter IN (2,3) THEN
					CASE WHEN b.statusID = 111 THEN 0
					WHEN (b.statusID = 112 OR b.statusID = 113)  AND ABS(modds) = 0.25 AND b.bettype IN(1,3,7,8,17,18) THEN 0.5
					ELSE 1 END
				ELSE 1 END
			) turnover, 
			SUM(b.winlost - b.actual_stake) AS Winlost,  
			SUM(CASE WHEN b.bettype NOT BETWEEN 31 AND 33 THEN  -1 *(b.winlost - b.actual_stake) ELSE   0 END ) AS LicenseeWL,
			SUM (CASE WHEN b.bettype BETWEEN 31 AND 33 THEN b.awinlost ELSE 0 END) AS WinlossRB,
			0 as AmountDueToBA,
			- SUM (CASE WHEN b.bettype BETWEEN 31 AND 33 THEN b.winlost - b.actual_stake + awinlost + comm ELSE 0 END) as AmountDueToRB,
			0 as CommBA,
			SUM (CASE WHEN b.bettype BETWEEN 31 AND 33 THEN comm ELSE 0 END) AS CommRB,
			SUM(PlayerComm) as PlayerComm,
			- SUM(CASE WHEN b.bettype NOT BETWEEN 31 AND 33 THEN b.awinlost + b.winlost - b.actual_stake + b.comm ELSE 0 END) Company  ,
			COUNT(b.transid)
			* CASE WHEN @drawfilter = 2 THEN
					CASE WHEN b.statusID = 111 THEN 0
					ELSE 1 END
				ELSE 1 END
			   BetCount	
		FROM 
			Bettrans b WITH ( NOLOCK,INDEX=IX_srecommend )
			INNER JOIN @Super s ON b.srecommend = s.custid AND s.currency=b.currency
			INNER JOIN @TempAg a ON b.recommend = a.custid AND b.currency=a.currency
			INNER JOIN @bettype bt ON b.bettype = bt.bettype
		WHERE 
			b.winlostdate BETWEEN @TempFromDate AND @TDate AND  		
			b.statusID  IN (111, 112, 113) 
		GROUP BY   
			b.winlostdate,s.currency,statusID
	END
	
	
	
END  

IF @FDate <= @MoveBetsDay 
BEGIN
	IF @TDate >= @MoveBetsDay
			SET @TempToDate = @MoveBetsDay
		ELSE
			SET  @TempToDate = @TDate
	
	IF @ShowBA=1 
	BEGIN
		INSERT INTO #SAgWinLoss  
		SELECT 
			b.winlostdate,  
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
			- SUM (b.winlost+b.awinlost+b.comm) as AmountDueToBA,
			0 as AmountDueToRB,
			SUM (comm) as CommBA,
			0 as CommRB,
			SUM(playerComm ) as PlayerComm,
			0 as Company,
			SUM(b.betcount)
			* CASE WHEN @drawfilter = 2 THEN
					CASE WHEN b.statusID = 111 THEN 0
					ELSE 1 END
				ELSE 1 END
		FROM 
			bodb_Licensee.dbo.rptLicWinloss2 b WITH ( NOLOCK )  
			INNER JOIN @Super s ON b.srecommend = s.custid AND s.currency=b.currency
			INNER JOIN @TempAg ag ON ag.custid = b.recommend AND b.Currency=ag.currency
		WHERE  
			b.Winlostdate BETWEEN @FDate AND @TempToDate  			
			AND b.roleid = 2   
			AND b.statusID <> 101 --exclude REJECT bets
			AND ISNULL(b.isBA,0) = 1
		GROUP BY  b.winlostdate,  b.currency,  b.statusID
	END
	
	--exclude BA tickets
	IF (@showSB = 1 or @ShowRB = 1 or @ShowNG = 1 OR @ShowLC=1 OR @ShowVS=1 OR @ShowCS=1 OR @ShowKN=1)
	BEGIN
	
		INSERT INTO #SAgWinLoss  
		--select * from @tempAg
		SELECT 
			b.winlostdate,  
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
			- SUM(CASE WHEN (b.sporttype IN (0,161,162,251,180,202))  THEN b.winlost ELSE 0 END) AS LicenseeWL ,
			SUM(CASE WHEN b.sporttype = 151 THEN b.awinlost ELSE 0 END) AS WinlossRB,
			0 as AmountDueToBA,
			- SUM ( CASE WHEN b.sporttype = 151 THEN (b.winlost+b.awinlost+b.comm) ELSE 0 END) as AmountDueToRB,
			0 as CommBA,
			SUM ( CASE WHEN b.sporttype = 151 THEN comm ELSE 0 END) as CommRB,
			SUM( b.playercomm ) as PlayerComm, 
			- SUM(CASE WHEN b.sporttype <> 151 THEN b.awinlost + b.winlost + b.comm ELSE 0 END)  as Company   ,
			SUM(b.betcount)
			* CASE WHEN @drawfilter = 2 THEN
					CASE WHEN b.statusID = 111 THEN 0
					ELSE 1 END
				ELSE 1 END
		FROM 
			bodb_Licensee.dbo.rptLicWinloss2 b WITH ( NOLOCK )  
			INNER JOIN @sporttype t ON b.sporttype = t.sporttype
			INNER JOIN @Super s ON b.srecommend = s.custid AND s.currency=b.currency 
			INNER JOIN @TempAg ag ON ag.custid = b.recommend AND b.Currency=ag.currency 
		WHERE  
			b.Winlostdate BETWEEN @FDate AND @TempToDate  
			
			AND b.roleid = 2   
			AND b.statusID <> 101 --exclude REJECT bets
			AND ISNULL(b.isBA,0) = 0
		GROUP BY  b.winlostdate, b.currency,  b.statusID
	END
	
END 
IF @IsOld = 1 
BEGIN
	SELECT @MaxOldDate = MAX(winlostdate) FROM bodb_Licensee.dbo.rptLicWinloss_old (NOLOCK)
	IF @TDate >= @MaxOldDate
			SET @TempToDate = @MaxOldDate
		ELSE
			SET  @TempToDate = @TDate

	IF @ShowBA=1 
	BEGIN
		INSERT INTO #SAgWinLoss  
		SELECT
			b.winlostdate,  
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
			- SUM (b.winlost+b.awinlost+b.comm) as AmountDueToBA,
			0 as AmountDueToRB,
			SUM (comm ) as CommBA,
			0 as CommRB,
			SUM( playercomm ) AS PlayerComm,
			0 as Company,
			SUM(b.betcount)
			* CASE WHEN @drawfilter = 2 THEN
					CASE WHEN b.statusID = 111 THEN 0
					ELSE 1 END
				ELSE 1 END
		FROM 
			bodb_Licensee.dbo.rptLicWinloss_old b WITH ( NOLOCK )  
			INNER JOIN @TempAg ag ON ag.custid = b.recommend AND b.Currency=ag.currency
		WHERE  
			b.Winlostdate BETWEEN @FDate AND @TempToDate  			 
			AND b.roleid = 2   
			AND b.statusID <> 101 --exclude REJECT bets
			AND ISNULL(b.isBA,0) = 1
		GROUP BY  b.winlostdate,  b.currency, b.statusID
	END

	
	--exclude BA tickets
	IF (@showSB = 1 or @ShowRB = 1 or @ShowNG = 1 OR @ShowLC=1 OR @ShowCS=1 OR @ShowKN=1)
	BEGIN
		INSERT INTO #SAgWinLoss  
		SELECT 
			b.winlostdate,  
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
			- SUM(CASE WHEN (b.sporttype IN (0,161,162,180,251,202))  THEN b.winlost ELSE 0 END) AS LicenseeWL ,
			SUM(CASE WHEN b.sporttype = 151 THEN b.awinlost ELSE 0 END) AS WinlossRB,
			0 as AmountDueToBA,
			- SUM ( CASE WHEN b.sporttype = 151 THEN (b.winlost+b.awinlost+b.comm) ELSE 0 END) as AmountDueToRB,
			0 as CommBA,
			SUM ( CASE WHEN b.sporttype = 151 THEN (comm ) ELSE 0 END) as CommRB,
			SUM ( playercomm) as PlayerComm,
			- SUM(CASE WHEN b.sporttype <> 151 THEN b.awinlost + b.winlost + b.comm ELSE 0 END)  as Company   ,
			SUM(b.betcount)
			* CASE WHEN @drawfilter = 2 THEN
					CASE WHEN b.statusID = 111 THEN 0
					ELSE 1 END
				ELSE 1 END
		FROM 
			bodb_Licensee.dbo.rptLicWinloss_old b WITH ( NOLOCK )  
			INNER JOIN @TempAg ag ON ag.custid = b.recommend AND b.Currency=ag.currency
			INNER JOIN @sporttype t ON b.sporttype = t.sporttype
		WHERE  
			b.Winlostdate BETWEEN @FDate AND @TempToDate  			
			AND b.roleid = 2   
			AND b.statusID <> 101 --exclude REJECT bets
			AND ISNULL(b.isBA,0) = 0
		GROUP BY  b.winlostdate,   b.currency, b.statusID
	END
	
END

CREATE NONCLUSTERED INDEX IDX_Index_SA ON #SAgWinLoss(Currency)
SELECT * INTO #TempExchange 
FROM Lrf_f_GetExchangeDaily(@FDate,@TDate)
WHERE exchangeid IN (SELECT DISTINCT Currency FROM #SAgWinLoss)

SELECT   
   CASE WHEN @ReportType = 1 THEN CONVERT(VARCHAR(8),w.winlostdate,112)  
		WHEN @ReportType = 2 THEN CONVERT(VARCHAR(6),w.winlostdate,112)  
		ELSE '0' END ReportType,  
   Currency ,   
		CASE WHEN Currency = 51 THEN @VNDCurrencyName 
			ELSE e.Code END currencyName,
   SUM(TurnOver)	AS Turnover,   
   SUM(Winlost)		AS Winlost,  
   SUM(LicenseeWL) AS LicenseeWL,
   SUM(WinlossRB)	AS WinlossRB,
   SUM(CommBA) AS CommBA,
   SUM(CommRB) AS CommRB,
   SUM(PlayerComm) AS PlayerComm,
   SUM(AmtDuetoBA) AS AmtDuetoBA,
   SUM(AmtDuetoRB) AS AmtDuetoRB,
   SUM(Company) AS Company,
   SUM(Betcount)	AS Betcount,
   
   --BaseRM  
   CAST(SUM(TurnOver*e.MYR) AS MONEY)	AS TurnoverMYR,   
   CAST(SUM(Winlost*e.MYR) AS MONEY)	AS WinlostMYR,  
   CAST(SUM(LicenseeWL*e.MYR) AS MONEY) AS LicenseeWLMYR,
   CAST(SUM(WinlossRB*e.MYR) AS MONEY)	AS WinlossRBMYR,
   CAST(SUM(CommBA * e.MYR) AS MONEY) AS CommBAMYR,
   CAST(SUM(CommRB * e.MYR) AS MONEY) AS CommRBMYR,
   CAST(SUM(PlayerComm*e.MYR) AS MONEY) AS PlayerCommMYR,
   CAST(SUM(AmtDuetoBA*e.MYR) AS MONEY) AS AmtDuetoBAMYR,
   CAST(SUM(AmtDuetoRB*e.MYR) AS MONEY) AS AmtDuetoRBMYR,
   CAST(SUM(Company * e.MYR) AS MONEY) AS CompanyMYR,
   
   --BaseUSD  
   CAST(SUM(TurnOver*e.USD) AS MONEY)	AS TurnoverUSD,   
   CAST(SUM(Winlost*e.USD) AS MONEY)	AS WinlostUSD,  
   CAST(SUM(LicenseeWL*e.USD) AS MONEY) AS LicenseeWLUSD,
   CAST(SUM(WinlossRB*e.USD) AS MONEY)	AS WinlossRBUSD,
   CAST(SUM(CommBA * e.USD) AS MONEY) AS CommBAUSD,
   CAST(SUM(CommRB * e.USD) AS MONEY) AS CommRBUSD,
   CAST(SUM(PlayerComm*e.USD) AS MONEY) AS PlayerCommUSD,
   CAST(SUM(AmtDuetoBA*e.USD) AS MONEY) AS AmtDuetoBAUSD,
   CAST(SUM(AmtDuetoRB*e.USD) AS MONEY) AS AmtDuetoRBUSD,
   CAST(SUM(Company * e.USD) AS MONEY) AS CompanyUSD,
   
    --BaseEUR  
   CAST(SUM(TurnOver*e.EUR) AS MONEY)	AS TurnoverEUR,   
   CAST(SUM(Winlost*e.EUR) AS MONEY)	AS WinlostEUR,  
   CAST(SUM(LicenseeWL*e.EUR) AS MONEY) AS LicenseeWLEUR,
   CAST(SUM(WinlossRB*e.EUR) AS MONEY)	AS WinlossRBEUR,
   CAST(SUM(CommBA * e.EUR) AS MONEY) AS CommBAEUR,
   CAST(SUM(CommRB * e.EUR) AS MONEY) AS CommRBEUR,
   CAST(SUM(PlayerComm*e.EUR) AS MONEY) AS PlayerCommEUR,
   CAST(SUM(AmtDuetoBA*e.EUR) AS MONEY) AS AmtDuetoBAEUR,
   CAST(SUM(AmtDuetoRB*e.EUR) AS MONEY) AS AmtDuetoRBEUR,
   CAST(SUM(Company * e.EUR) AS MONEY) AS CompanyEUR
FROM	
	#SAgWinLoss w   
	INNER JOIN  #TempExchange e
	ON w.winlostdate = e.ExchangeDate AND w.currency = e.ExchangeId
GROUP BY   
	Currency
	,CASE WHEN @ReportType = 1 THEN CONVERT(VARCHAR(8),w.winlostdate,112)  
		  WHEN @ReportType = 2 THEN CONVERT(VARCHAR(6),w.winlostdate,112)  
		  ELSE '0' END   
	, CASE WHEN Currency = 51 THEN @VNDCurrencyName 
			ELSE e.Code END
ORDER BY ReportType  

DROP TABLE #TempExchange
DROP TABLE #SAgWinLoss   
END

Go
GRANT EXECUTE ON [dbo].[Acc_Rpt_LicWinloss2] TO [bodbLicenseeNet]
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_LicWinloss2] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_LicWinloss2] TO [vnteam] 
