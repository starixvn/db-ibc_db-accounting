ALTER PROCEDURE [dbo].[Acc_Rpt_BAWinlossByLicensee]  
 @LicenseeID	INT = 0,
 @Currency		INT = 0,
 @FromDate		SMALLDATETIME,  
 @ToDate		SMALLDATETIME,   
 @MoveBetsDay SMALLDATETIME,
 @ReportType	TINYINT=1,  
 @drawfilter SMALLINT = 1  ,
 @excludeTest BIT = 0
AS  
/*  Created: Henry  
	Date: 2011-11-04
    Task : BA Winloss Report By Licensee 
    DB: bodb_MoveBet 
   
    Revisions:  
		- 20120214@Jim: change to use  table ExchangeDaily by use function Lrf_f_GetExchangeDaily  
		- 20120803@Jim: add playercomm value (for give commision to member )
	
	Param's Explanation:  
	  + @ReportType: 1-Daily; 2-Monthly;  
	  +	@drawfilter: 'No Draw' filter is supportted (1:Normal 2:No Draw 3:No Draw for Turnover only)
	  + @excludeTest: remove currency UUS
*/  
BEGIN  
	SET NOCOUNT ON  

	DECLARE @TempFromDate SMALLDATETIME  
	DECLARE @TempToDate SMALLDATETIME 
	

	CREATE TABLE #tmp(  
		winlostdate		DATETIME,  
		Currency		INT,
		LicenseeID INT,
		LicenseeName VARCHAR(50),
		TurnOver		MONEY,   	
		Winlost			MONEY,  
		AmtDueToBA	MONEY,   
		Comm	MONEY,
		PlayerComm MONEY,
		Betcount BIGINT
	
	)  
	CREATE INDEX IX_tmp on #tmp (Winlostdate, Currency,LicenseeID)	

	IF @Todate > @MoveBetsDay  
	--get FROM bettrans  
	BEGIN  
		IF @FromDate <= @MoveBetsDay   
			SET @TempFromDate =  DATEADD(DAY,1,@MoveBetsDay)  
		ELSE  
			SET @TempFromDate = @FromDate  
			
		INSERT INTO #tmp
		SELECT   
			b.winlostdate,
			b.Currency,
			l.LicenseeID,
			l.LicenseeName,
			SUM( stake
				*
				CASE WHEN @drawfilter IN (2,3) THEN
					CASE WHEN b.statusID = 111 THEN 0
					WHEN (b.statusID = 112 OR b.statusID = 113)  AND ABS(modds) = 0.25 AND b.bettype IN(1,3,7,8,17,18) THEN 0.5
					ELSE 1 END
				ELSE 1 END
			) turnover,
			SUM(b.winlost - b.actual_stake) AS Winlost,
			- SUM (b.winlost - b.actual_stake + awinlost + comm)  AS AmtDueToBA ,
			SUM (comm ) AS Comm,
			SUM(playercomm) AS PlayerComm,
			COUNT(b.transid)
			* CASE WHEN @drawfilter = 2 THEN
					CASE WHEN b.statusID = 111 THEN 0
					ELSE 1 END
				ELSE 1 END
			   BetCount		
		FROM dbo.bettrans b WITH (NOLOCK)   
			INNER JOIN LicenseeCust lc WITH (NOLOCK) ON b.recommend = lc.custid
			INNER JOIN Licensees l WITH (NOLOCK) ON l.LicenseeID = lc.LicenseeID
		WHERE 
			b.winlostdate BETWEEN @TempFromDate AND @Todate AND
			b.ruben=1 AND   
			b.statusID NOT IN (101, 102, 103) AND
			(@Currency = 0 OR  (@Currency <> 0 AND lc.Currency = @Currency)) AND
			(@LicenseeID = 0 OR (@LicenseeID <> 0 AND l.LicenseeID = @LicenseeID))
		GROUP BY   
			b.winlostdate,b.currency,l.LicenseeID,l.LicenseeName, b.statusID
	END		

	IF @FromDate <= @MoveBetsDay 
	BEGIN
		IF @ToDate >= @MoveBetsDay
				SET @TempToDate = @MoveBetsDay
			ELSE
				SET  @TempToDate = @ToDate
				
		INSERT INTO #tmp
		SELECT   
			b.winlostdate,
			b.currency,
			l.LicenseeID,
			l.LicenseeName,
			SUM(b.turnover
			*
				CASE WHEN @drawfilter IN (2,3) THEN
					CASE WHEN b.statusID = 111  THEN 0
					WHEN b.statusID IN (114,115) THEN 0.5
					ELSE 1 END
				ELSE 1 END
			),  
			sum(b.winlost) AS Winlost,
			- SUM (b.winlost+b.awinlost+b.comm) as AmountDueToBA,
			SUM (comm ) as Comm,
			SUM(playercomm) AS PlayerComm,
			SUM(b.betcount)
			* CASE WHEN @drawfilter = 2 THEN
					CASE WHEN b.statusID = 111 THEN 0
					ELSE 1 END
				ELSE 1 END	
			
		FROM rptLicWinloss b WITH ( NOLOCK )  
			INNER JOIN LicenseeCust lc WITH (NOLOCK) ON b.recommend = lc.custid
			INNER JOIN Licensees l WITH (NOLOCK) ON l.LicenseeID = lc.LicenseeID
		WHERE 
			b.winlostdate BETWEEN @FromDate AND @TempToDate AND 
			b.roleid = 2 AND
			b.statusID <> 101 AND --exclude REJECT bets
			(@Currency = 0 OR  (@Currency <> 0 AND lc.Currency = @Currency)) AND
			(@LicenseeID = 0 OR (@LicenseeID <> 0 AND l.LicenseeID = @LicenseeID))
		GROUP BY   
			b.winlostdate,b.currency,l.LicenseeID,l.LicenseeName, b.statusID	
	END

	IF @excludeTest=1
	BEGIN
		DELETE FROM #tmp WHERE Currency = 20
	END 


	SELECT * INTO #TempExchange 
	FROM bodb02.dbo.Lrf_f_GetExchangeDaily(@FromDate,@ToDate)
	WHERE exchangeid IN (SELECT DISTINCT Currency FROM #tmp)

	SELECT 
		b.LicenseeID,
		b.LicenseeName,
		--b.winlostdate,
		CASE
			WHEN @ReportType = 1 THEN CONVERT(VARCHAR(8),b.winlostdate,112)  
			WHEN @ReportType = 2 THEN CONVERT(VARCHAR(6),b.winlostdate,112) 
		END ReportType,
		b.currency,
		CASE WHEN b.currency = 51 THEN 'INH' ELSE e.Code END AS CurrencyName,
		sum(b.Turnover) AS Turnover,
		sum(b.winlost) AS Winlost,
		sum(b.AmtDueToBA) AS AmtDueToBA,
		sum(b.Comm) AS Comm,
		sum(b.playercomm) AS PlayerComm,
		sum(b.betcount) AS BetCount,
				
		sum(b.Turnover * e.MYR) AS TurnoverMYR,
		sum(b.winlost * e.MYR) AS WinlostMYR,
		sum(b.AmtDueToBA * e.MYR) AS AmtDueToBAMYR,
		sum(b.Comm * e.MYR) AS CommMYR,
		sum(b.playercomm*e.MYR) AS PlayerCommMYR,
			
		sum(b.Turnover * e.USD) AS TurnoverUSD,
		sum(b.winlost * e.USD) AS WinlostUSD,
		sum(b.AmtDueToBA * e.USD) AS AmtDueToBAUSD,
		sum(b.Comm * e.USD) AS CommUSD,
		sum(b.playercomm*e.USD) AS PlayerCommUSD,
			
		sum(b.Turnover * e.EUR) AS TurnoverEUR,
		sum(b.winlost * e.EUR) AS WinlostEUR,
		sum(b.AmtDueToBA * e.EUR) AS AmtDueToBAEUR,
		sum(b.Comm * e.EUR) AS CommEUR,
		sum(b.playercomm*e.EUR) AS PlayerCommEUR
				
		
	FROM #tmp b
	INNER JOIN #TempExchange e 
	ON b.Winlostdate = e.ExchangeDate AND b.currency = e.ExchangeId
	GROUP BY 
			b.LicenseeID,b.LicenseeName,
			CASE
				WHEN @ReportType = 1 THEN CONVERT(VARCHAR(8),b.winlostdate,112)  
				WHEN @ReportType = 2 THEN CONVERT(VARCHAR(6),b.winlostdate,112) 
			END
			,b.currency,CASE WHEN b.currency = 51 THEN 'INH' ELSE e.Code END
	ORDER BY b.LicenseeID,
			CASE
				WHEN @ReportType = 1 THEN CONVERT(VARCHAR(8),b.winlostdate,112)  
				WHEN @ReportType = 2 THEN CONVERT(VARCHAR(6),b.winlostdate,112) 
			END DESC
			,b.currency
	
	DROP TABLE #tmp

	DROP TABLE #TempExchange

END   
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_BAWinlossByLicensee] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_BAWinlossByLicensee] TO [vnteam]  