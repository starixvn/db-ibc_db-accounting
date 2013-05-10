ALTER PROCEDURE [dbo].[Acc_Rpt_BALicWinloss]  
	@FromDate SMALLDATETIME,
	@ToDate SMALLDATETIME
AS  
/*  Created: Henry  
	Date: 2011-10-14
    TASk : BA Winloss Report for Licensee By date range
    DB: DB052.bodb02  
   
    Revisions:  
		- 20111230@Henry: remove virtual concept
	Param's Explanation:  
*/  
BEGIN  
SET NOCOUNT ON  


DECLARE @TempFromDate SMALLDATETIME  
DECLARE @TempToDate SMALLDATETIME 
DECLARE @MoveBetsDay SMALLDATETIME

SELECT @MoveBetsDay=VValue
	FROM SystemSettings WITH(NOLOCK)	
	WHERE VName = 'MoveBetsDay'


CREATE TABLE #tmp (
	Winlostdate SMALLDATETIME,
	Currency INT,
	LicenseeID INT,
	LicenseeName VARCHAR(50),
	turnover MONEY,
	winlost MONEY,
	--winlostVirtual MONEY,
	AmtDueToBA MONEY,
	--AmtDueToBAVirtual MONEY, 
	Comm MONEY,
	--CommVirtual MONEY,
	Betcount INT)
CREATE UNIQUE CLUSTERED INDEX IX_tmp on #tmp (Winlostdate, Currency,LicenseeID)	

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
		SUM(stake) AS turnover, 
		SUM(b.winlost - b.actual_stake) AS Winlost,
		--SUM((b.winlost - b.actual_stake)*b.virtualrate) AS WinlostVirtual,  
		- SUM (b.winlost - b.actual_stake + awinlost + comm)  AS AmtDueToBA ,
		-- - SUM ((b.winlost - b.actual_stake + awinlost + comm) * b.virtualrate )  AS AmtDueToBAVirtual ,
		SUM (comm - playercomm) AS Comm,
		--SUM ((comm - playercomm)*b.virtualrate) AS CommVirtual,
		COUNT(b.transid) AS BetCount	
	FROM dbo.bettrans b WITH (NOLOCK)   
		INNER JOIN LicenseeBATransaction BA WITH (NOLOCK) ON b.transid = BA.transid
		INNER JOIN LicenseeCust lc WITH (NOLOCK) ON b.recommend = lc.custid
		INNER JOIN Licensees l WITH (NOLOCK) ON l.LicenseeID = lc.LicenseeID
	WHERE 
		b.winlostdate BETWEEN @TempFromDate AND @Todate AND
		b.ruben=1 AND   
		b.statusID NOT IN (101, 102, 103) AND
		b.Currency <> 20
	GROUP BY   
		b.winlostdate,b.currency,l.LicenseeID,l.LicenseeName
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
		SUM(b.turnover) AS turnover, 
		sum(b.winlost) AS Winlost,
		-- SUM(b.winlostvirtual) AS WinlostVirtual,
		- SUM (b.winlost+b.awinlost+b.comm) as AmountDueToBA,
		-- - SUM (b.winlostvirtual + b.commvirtual)  AS AmtDueToBAVirtual ,
		SUM (comm - playercomm) as Comm,
		--SUM (b.commvirtual) AS CommVirtual,
		SUM(b.betcount) AS BetCount	
		
	FROM rptLicWinloss2 b WITH ( NOLOCK )  
		INNER JOIN LicenseeCust lc WITH (NOLOCK) ON b.recommend = lc.custid
		INNER JOIN Licensees l WITH (NOLOCK) ON l.LicenseeID = lc.LicenseeID
	WHERE 
		b.winlostdate BETWEEN @FromDate AND @TempToDate AND 
		b.roleid = 2 AND
		lc.Currency <> 20 AND
		b.statusID <> 101 AND --exclude REJECT bets
		ISNULL(b.isBA,0) = 1
	GROUP BY   
		b.winlostdate,b.currency,l.LicenseeID,l.LicenseeName	
END


SELECT 
	b.LicenseeID,
	b.LicenseeName,
	b.currency,
	CASE WHEN b.currency = 51 THEN 'INH' ELSE e.Code END AS CurrencyName,
	sum(b.Turnover * e.ActualRate) AS TurnoverRM,
	--sum(b.winlostVirtual) AS WinlostVirtual,
	sum(b.winlost * e.ActualRate) AS WinlostRM,
	--sum(b.AmtDueToBAVirtual) AS AmtDueToBAVirtual,
	sum(b.AmtDueToBA * e.ActualRate) AS AmtDueToBARM,
	--sum(b.CommVirtual) AS CommVirtual,
	sum(b.Comm * e.ActualRate) AS CommRM,
	sum(b.betcount) AS BetCount
FROM #tmp b
INNER JOIN dbo.ExchangeDaily e WITH (NOLOCK) ON b.Winlostdate = e.ExchangeDate AND b.currency = e.ExchangeId
GROUP BY b.LicenseeID,b.LicenseeName,b.currency,CASE WHEN b.currency = 51 THEN 'INH' ELSE e.Code END


DROP TABLE #tmp

END   

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_BALicWinloss] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_BALicWinloss] TO [vnteam]    