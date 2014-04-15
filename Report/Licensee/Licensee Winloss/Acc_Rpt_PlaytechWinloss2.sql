ALTER PROCEDURE [dbo].[Acc_Rpt_PlaytechWinloss2] 
 @LicenseeID	INT,
 @Currency		INT = 0,
 @FromDate		SMALLDATETIME,  
 @ToDate		SMALLDATETIME,   
 @ReportType	TINYINT=1  
AS  
/*  Created: Hannah  
	Date: 2014-04-14
    Task : Playtech Casino - Win Loss Report 
    DB: DB06.bodb02  
   
    Revisions:  
		
	Param's Explanation:  
	  + @ReportType: 1-Daily; 2-Monthly;  
	  + @BackupDay: The day we move tickets to rptDepWinlostByProduct_bk
*/  
BEGIN  
	SET NOCOUNT ON  

	CREATE TABLE #SAgWinLoss  
	(  
		winlostdate		DATETIME,  
		Currency		INT,
		TurnOver		MONEY,   	
		Winlost			MONEY,  
		LicenseeWL		MONEY, 
		AmtDueTo		MONEY,
		PlayerComm 		MONEY,
		BetCount		BIGINT
	)  

	DECLARE @tempAg	TABLE(custID INT, currency INT) 
	DECLARE @LicenseeName VARCHAR(50)
	DECLARE @VNDCurrencyName VARCHAR(20)

	DECLARE @BackupDay SMALLDATETIME

	SELECT @BackupDay = MIN(winlostdate)
	FROM [bodb_report].[dbo].[rptDepWinlostByProduct] WITH (NOLOCK)

	SELECT @LicenseeName = LicenseeName 
	FROM DBLIC.bodb_Licensee.dbo.Licensees WITH (NOLOCK) 
	WHERE LicenseeID = @LicenseeID

	INSERT INTO @tempAg (custID, currency) 
	SELECT custID, currency 
	FROM DBLIC.bodb_Licensee.dbo.LicenseeCust WITH (NOLOCK) 
	WHERE 
		LicenseeID = @LicenseeID
		AND (@Currency = 0 OR (@Currency <> 0 AND Currency = @Currency))

	SELECT @VNDCurrencyName = currency 
	FROM exchange (NOLOCK) 
	WHERE ExchangeId = 51

	DECLARE @Super AS TABLE (custid INT PRIMARY KEY, currency INT)
	INSERT INTO @Super(custid, currency)  
	SELECT CustID, currency 
	FROM bodb02.dbo.Dep_CustSuper WITH (NOLOCK)  
	WHERE site = @LicenseeName	

	DECLARE @TempFromDate DATETIME 
	DECLARE @TempToDate DATETIME 
	DECLARE @FDate DATETIME 
	DECLARE @TDate DATETIME 
	--to Deal With Parameter Sniffing
	SELECT @FDate = @FromDate, @TDate = @ToDate 

	IF @TDate >= @BackupDay
	BEGIN
		IF @FDate < @BackupDay 
			SET @TempFromDate = @BackupDay
		ELSE
			SET @TempFromDate = @FDate
	
		INSERT INTO #SAgWinLoss
		SELECT   
			r.winlostdate,  
			s.currency,
			SUM(r.turnover) AS Turnover, 
			SUM(r.winlost) AS Winlost,  
			SUM(-1 *r.winlost) AS LicenseeWL,
			SUM(-0.01 *r.winlost) AS AmountDueTo,
			SUM(r.PlayerComm) AS PlayerComm,
			SUM(r.BetCount) AS BetCount	
		FROM 
			bodb_report.dbo.rptDepWinlostByProduct r WITH (NOLOCK)
			INNER JOIN bodb02.dbo.custInfo ci WITH ( NOLOCK) ON ci.CustID = r.CustID
			INNER JOIN @Super s ON ci.srecommend = s.custid
			INNER JOIN @TempAg a ON ci.recommend = a.custid
		WHERE
			r.winlostdate BETWEEN @TempFromDate AND @TDate 
			AND r.sporttype = 254
		GROUP BY   
			r.winlostdate,s.currency
	END  

	IF @FDate < @BackupDay 
	BEGIN
		IF @TDate >= @BackupDay
				SET @TempToDate = DATEADD(DAY, -1, @BackupDay)
			ELSE
				SET  @TempToDate = @TDate	
	
		INSERT INTO #SAgWinLoss  
		SELECT 
			r.winlostdate,  
			s.currency, 
			SUM(r.Turnover) AS Turnover,     
			SUM(r.Winlost) AS Winlost,  
			- SUM(r.winlost) AS LicenseeWL ,
			SUM(-0.01 *r.winlost) AS AmountDueTo,
			SUM(r.playercomm ) AS PlayerComm, 
			SUM(r.BetCount) AS BetCount
		FROM 
			bodb_report.dbo.rptDepWinlostByProduct_bk r WITH ( NOLOCK )  
			INNER JOIN bodb02.dbo.custInfo ci WITH ( NOLOCK) ON ci.CustID = r.CustID
			INNER JOIN @Super s ON ci.srecommend = s.custid
			INNER JOIN @TempAg ag ON ag.custid = ci.recommend
		WHERE  
			r.Winlostdate BETWEEN @FDate AND @TempToDate  
			AND r.sporttype = 254
		GROUP BY  r.winlostdate, s.currency
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
				ELSE e.Code END CurrencyName,
	   SUM(TurnOver)	AS Turnover,   
	   SUM(Winlost)		AS Winlost,  
	   SUM(LicenseeWL)  AS LicenseeWL,
	   SUM(PlayerComm)  AS PlayerComm,
	   SUM(AmtDueto)    AS AmtDueTo,
	   SUM(Betcount)	AS BetCount,
   
	   --BaseRM  
	   CAST(SUM(TurnOver*e.MYR) AS MONEY)	AS TurnoverMYR,   
	   CAST(SUM(Winlost*e.MYR) AS MONEY)	AS WinlostMYR,  
	   CAST(SUM(LicenseeWL*e.MYR) AS MONEY) AS LicenseeWLMYR,
	   CAST(SUM(PlayerComm*e.MYR) AS MONEY) AS PlayerCommMYR,
	   CAST(SUM(AmtDueto*e.MYR) AS MONEY)	AS AmtDueToMYR,
   
	   --BaseUSD  
	   CAST(SUM(TurnOver*e.USD) AS MONEY)	AS TurnoverUSD,   
	   CAST(SUM(Winlost*e.USD) AS MONEY)	AS WinlostUSD,  
	   CAST(SUM(LicenseeWL*e.USD) AS MONEY) AS LicenseeWLUSD,
	   CAST(SUM(PlayerComm*e.USD) AS MONEY) AS PlayerCommUSD,
	   CAST(SUM(AmtDueto*e.USD) AS MONEY)	AS AmtDueToUSD,
   
		--BaseEUR  
	   CAST(SUM(TurnOver*e.EUR) AS MONEY)	AS TurnoverEUR,   
	   CAST(SUM(Winlost*e.EUR) AS MONEY)	AS WinlostEUR,  
	   CAST(SUM(LicenseeWL*e.EUR) AS MONEY) AS LicenseeWLEUR,
	   CAST(SUM(PlayerComm*e.EUR) AS MONEY) AS PlayerCommEUR,
	   CAST(SUM(AmtDueto*e.EUR) AS MONEY)	AS AmtDueToEUR
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
GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_PlaytechWinloss2] TO [bodbLicenseeNet]
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_PlaytechWinloss2] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_PlaytechWinloss2] TO [vnteam] 