-- if before 2AM (server time), get yesterday's data. otherwise, get today's data instead
SET NOCOUNT ON

DECLARE @dayOffset int = CASE WHEN DATEPART (hour, CURRENT_TIMESTAMP) >= 2 THEN 0 ELSE -1 END

DECLARE @wldate smalldatetime = DATEADD(dd, DATEDIFF(dd, 0, CURRENT_TIMESTAMP), @dayOffset)

DECLARE @msg VARCHAR(max) = ''
DECLARE @msg2 VARCHAR(max) = ''
DECLARE @title varchar(22)

IF (@dayOffset = 0)
BEGIN
	SET @title = CONVERT(VARCHAR(5), @wldate, 1) + ' '
	+ CASE 
		WHEN DATEPART(hour, CURRENT_TIMESTAMP) > 12 THEN CAST(DATEPART(hour, CURRENT_TIMESTAMP)-12 as varchar) + ':' + CAST(DATEPART(minute, CURRENT_TIMESTAMP) as varchar) + 'pm'
		WHEN DATEPART(hour, CURRENT_TIMESTAMP) = 12 THEN CAST(DATEPART(hour, CURRENT_TIMESTAMP) as varchar) + ':' + CAST(DATEPART(minute, CURRENT_TIMESTAMP) as varchar) + 'pm'
		ELSE CAST(DATEPART(hour, CURRENT_TIMESTAMP) as varchar) + ':' + CAST(DATEPART(minute, CURRENT_TIMESTAMP) as varchar) + 'am' END
	+' gmt-4'	
END
ELSE
BEGIN
	SET @title = CONVERT(VARCHAR(10), @wldate, 101)
END

CREATE TABLE #tmpResetWinning (
	Site VARCHAR(50), SB TINYINT, TurnOver	MONEY, Margin MONEY, HouseWinlost MONEY, isDeposit smallint
)

INSERT INTO #tmpResetWinning (Site, SB, TurnOver, Margin, HouseWinlost, isDeposit)
EXEC Acc_ResetWinning_MarginBySite @Winlostdate = @wldate

DECLARE @WLBySite as TABLE (S varchar(30), WL money, TurnOver money , MG MONEY, rn int)
INSERT INTO @WLBySite(S, WL, TurnOver, MG, rn)
SELECT  S = CASE 
				WHEN Site IN ('BEST-ODDS','XYZBET') THEN 'XYZ & Bestodds'
				WHEN Site IN ('611111') THEN '611 (China)'
				WHEN Site IN ('733333') THEN '733 (Malaysia)'
				WHEN Site IN ('755555') THEN '755 (Thailand)'
				WHEN Site IN ('INDO') THEN 'Indo'
				WHEN Site IN ('IbcIndo') THEN 'IbcIndo'
				WHEN Site IN ('IBCMMR') THEN 'Myanmar'
				WHEN Site IN ('722222','222223','222225','222227','spotico','KORIBC','766666', '76666B', '7aa666', 'Saba789') THEN 'Others'
				WHEN Site IN ('789y', 'y987') AND SB = 1 THEN '789Y SB'
				WHEN Site IN ('789y', 'y987') AND SB = 0 THEN '789Y Non-SB'
				WHEN Site = 'Total (w/o CN88)' THEN 'TOTAL'
				WHEN isDeposit = 1 AND Site like '%CV' AND SB = 1 THEN 'CV SB'
				WHEN isDeposit = 1 AND Site like '%CV' AND SB = 0 THEN 'CV NS'
			ELSE CASE WHEN SB = 1 THEN 'CASH SB' ELSE 'CASH Non-SB' END END			
		,WL = -SUM(ISNULL(HouseWinlost,0))  
		,TurnOver = SUM(ISNULL(TurnOver,0)) 
		,MG = CASE WHEN SUM(ISNULL(TurnOver,0)) = 0 THEN 0 ELSE -SUM(ISNULL(HouseWinlost,0))/SUM(ISNULL(TurnOver,0)) * 100 END
		,rn = CASE 
				WHEN Site IN ('BEST-ODDS','XYZBET') THEN 1
				WHEN Site IN ('611111') THEN 2
				WHEN Site IN ('733333') THEN 3
				WHEN Site IN ('755555') THEN 4
				WHEN Site IN ('INDO') THEN 5
				WHEN Site IN ('IbcIndo') THEN 6
				WHEN Site IN ('IBCMMR') THEN 7
				WHEN Site IN ('722222','222223','222225','222227','spotico','KORIBC','766666', '76666B', '7aa666', 'Saba789') THEN 8
				WHEN Site IN ('789y', 'y987') AND SB = 1 THEN 9
				WHEN Site IN ('789y', 'y987') AND SB = 0 THEN 10
				WHEN Site = 'Total (w/o CN88)' THEN 15
				WHEN isDeposit = 1 AND Site like '%CV' AND SB = 1 THEN 13
				WHEN isDeposit = 1 AND Site like '%CV' AND SB = 0 THEN 14
			ELSE CASE WHEN SB = 1 THEN 11 ELSE 12 END END
FROM #tmpResetWinning
WHERE SITE NOT IN ('CN88') AND isDeposit IN (0,1,2,5)
GROUP BY CASE 
				WHEN Site IN ('BEST-ODDS','XYZBET') THEN 'XYZ & Bestodds'
				WHEN Site IN ('611111') THEN '611 (China)'
				WHEN Site IN ('733333') THEN '733 (Malaysia)'
				WHEN Site IN ('755555') THEN '755 (Thailand)'
				WHEN Site IN ('INDO') THEN 'Indo'
				WHEN Site IN ('IbcIndo') THEN 'IbcIndo'
				WHEN Site IN ('IBCMMR') THEN 'Myanmar'
				WHEN Site IN ('722222','222223','222225','222227','spotico','KORIBC','766666', '76666B', '7aa666', 'Saba789') THEN 'Others'
				WHEN Site IN ('789y', 'y987') AND SB = 1 THEN '789Y SB'
				WHEN Site IN ('789y', 'y987') AND SB = 0 THEN '789Y Non-SB'
				WHEN Site = 'Total (w/o CN88)' THEN 'TOTAL'
				WHEN isDeposit = 1 AND Site like '%CV' AND SB = 1 THEN 'CV SB'
				WHEN isDeposit = 1 AND Site like '%CV' AND SB = 0 THEN 'CV NS'
			ELSE CASE WHEN SB = 1 THEN 'CASH SB' ELSE 'CASH Non-SB' END END	
		,CASE 
				WHEN Site IN ('BEST-ODDS','XYZBET') THEN 1
				WHEN Site IN ('611111') THEN 2
				WHEN Site IN ('733333') THEN 3
				WHEN Site IN ('755555') THEN 4
				WHEN Site IN ('INDO') THEN 5
				WHEN Site IN ('IbcIndo') THEN 6
				WHEN Site IN ('IBCMMR') THEN 7
				WHEN Site IN ('722222','222223','222225','222227','spotico','KORIBC','766666', '76666B', '7aa666', 'Saba789') THEN 8
				WHEN Site IN ('789y', 'y987') AND SB = 1 THEN 9
				WHEN Site IN ('789y', 'y987') AND SB = 0 THEN 10
				WHEN Site = 'Total (w/o CN88)' THEN 15
				WHEN isDeposit = 1 AND Site like '%CV' AND SB = 1 THEN 13
				WHEN isDeposit = 1 AND Site like '%CV' AND SB = 0 THEN 14
			ELSE CASE WHEN SB = 1 THEN 11 ELSE 12 END END

-- generate string for winlost by site
SELECT @msg = @msg + '<br>' + 
	CASE WHEN S = 'All Sports' THEN 'ALL'
		WHEN S = 'XYZ & Bestodds' THEN 'XYZ & BO'
		WHEN S = '611 (China)' THEN '611 (Chi)'
		WHEN S = '733 (Malaysia)' THEN '733 (Mala)'
		WHEN S = '755 (Thailand)' THEN '755 (Thai)'
		WHEN S = '789Y SB' THEN 'Y SB'
		WHEN S = '789Y Non-SB' THEN 'Y NS'
		WHEN S = 'CASH SB' THEN 'C SB'
		WHEN S = 'CASH Non-SB' THEN 'C NS'
		WHEN S = 'CV SB' THEN 'CV SB'
		WHEN S = 'CV NS' THEN 'CV NS'
	ELSE S END + ': '
		--+ CASE WHEN ABS(WL) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),WL/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),WL/1000) as VARCHAR(10)) + 'k' END 	
		+ CASE 
			WHEN ABS(WL) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(WL / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(WL) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(WL / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), WL) END
		+ ' ' + CAST(CONVERT(DECIMAL(10,2), MG) as VARCHAR(10)) + '%'	
FROM @WLBySite
ORDER BY rn

DECLARE @submsg VARCHAR(1000)
SELECT @submsg = '<br>T SB: '	
		--+ CASE WHEN ABS(SUM(HouseWinlost)) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),-SUM(HouseWinlost)/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),-SUM(HouseWinlost)/1000) as VARCHAR(10)) + 'k' END
		+ CASE 
			WHEN ABS(-ISNULL(SUM(HouseWinlost),0)) BETWEEN 0 AND 999999 THEN (CONVERT(VARCHAR(10), (CAST(ROUND(-ISNULL(SUM(HouseWinlost),0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(-ISNULL(SUM(HouseWinlost),0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), (CAST(ROUND(-ISNULL(SUM(HouseWinlost),0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), -ISNULL(SUM(HouseWinlost),0)) END
		+ ' M: ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -SUM(HouseWinlost)*100/NULLIF(SUM(TurnOver),0)),0) as VARCHAR(10)) + '%'
		
FROM #tmpResetWinning
WHERE SB = 1 AND isDeposit IN (0,1) AND Site NOT IN ('CN88')

SELECT @submsg = @submsg + '<br>T NS: '	
		--+ CASE WHEN ABS(SUM(HouseWinlost)) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),-SUM(HouseWinlost)/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),-SUM(HouseWinlost)/1000) as VARCHAR(10)) + 'k' END
		+ CASE 
			WHEN ABS(-ISNULL(SUM(HouseWinlost),0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(-ISNULL(SUM(HouseWinlost),0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(-ISNULL(SUM(HouseWinlost),0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(-ISNULL(SUM(HouseWinlost),0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), -SUM(HouseWinlost)) END
		+ ' M: ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -SUM(HouseWinlost)*100/NULLIF(SUM(TurnOver),0)),0) as VARCHAR(10)) + '%'
FROM #tmpResetWinning
WHERE SB = 0 AND isDeposit IN (0,1) AND Site NOT IN ('CN88')

SET @msg = REPLACE(@msg, 'TOTAL', @submsg + '<br><br>TOTAL')

/*
-- generate string for CN88
SELECT @msg = @msg + '<br><br>**C8: '
		--+ CASE WHEN ABS(SUM(-ISNULL(HouseWinlost,0))) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),SUM(-ISNULL(HouseWinlost,0))/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),SUM(-ISNULL(HouseWinlost,0))/1000) as VARCHAR(10)) + 'k' END 
		+ CASE 
			WHEN ABS(-SUM(HouseWinlost)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(-SUM(HouseWinlost) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(-SUM(HouseWinlost)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(-SUM(HouseWinlost) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), -SUM(HouseWinlost)) END
		+ ' ' + CAST(CONVERT(DECIMAL(10,2), -SUM(HouseWinlost)*100/SUM(Turnover)) as VARCHAR(10)) + '%'
		--+ '<br>'
FROM #tmpResetWinning
WHERE Site IN ('CN88')
*/

CREATE TABLE #tmpMargin (
	SportName VARCHAR(50), Liveindicator BIT, IsSaba tinyint, TurnOver MONEY, Margin MONEY, HouseWinlost MONEY
)

INSERT INTO #tmpMargin (SportName, Liveindicator,  IsSaba, TurnOver, Margin, HouseWinlost)
EXEC Acc_ResetWinning_MarginBySport @Winlostdate = @wldate

SELECT @msg = @msg + '<br>-------<br>[SB TO & M]'

-- generate string for TO & Margin
;WITH _S as (
	SELECT SportName = CASE WHEN SportName = 'All Sports' THEN 'ALL'				
				WHEN SportName = 'Soccer' AND Liveindicator = 1 AND IsSaba = 0 THEN 'R.Soc(L)'
				WHEN SportName = 'Soccer' AND Liveindicator = 0 AND IsSaba = 0 THEN 'R.Soc(NL)'					
				WHEN SportName = 'Soccer' AND IsSaba = 1 THEN 'Saba.Soc'
				WHEN SportName = 'Soccer' AND IsSaba = 2 THEN 'Soccer PG'	-- Saba Soccer Pingoal
				WHEN SportName = 'Basketball' AND IsSaba = 2 THEN 'Basket PG'	-- Saba Basketball Pingoal
				WHEN SportName = 'Basketball' AND IsSaba = 0 THEN 'Real.Bas'
				WHEN SportName = 'Basketball' AND IsSaba = 1 THEN 'Saba.Bas'				
				WHEN SportName = 'Tennis' THEN 'Tenn'				
				WHEN SportName = 'E-Sports' THEN 'E-Spo'
				WHEN SportName = 'Cricket' THEN 'Cricket'
				WHEN SportName = 'Other Sports' THEN 'Others'
				WHEN SportName = 'Parlay' THEN 'Parl'
			ELSE SportName END
		,rn = CASE WHEN SportName = 'All Sports' THEN 1				
				WHEN SportName = 'Soccer' AND IsSaba = 0 AND Liveindicator = 1 THEN 3
				WHEN SportName = 'Soccer' AND IsSaba = 0 AND Liveindicator = 0 THEN 4					
				WHEN SportName = 'Soccer' AND IsSaba = 1 THEN 5
				WHEN SportName = 'Soccer' AND IsSaba = 2 THEN 6
				WHEN SportName = 'Basketball' AND IsSaba = 2 THEN 7
				WHEN SportName = 'Basketball' AND IsSaba = 0 THEN 8
				WHEN SportName = 'Basketball' AND IsSaba = 1 THEN 9				
				WHEN SportName = 'Tennis' THEN 10
				WHEN SportName = 'E-Sports' THEN 11				
				WHEN SportName = 'Cricket' THEN 12
				WHEN SportName = 'Other Sports' THEN 13
				WHEN SportName = 'Parlay' THEN 14
			ELSE 15 END		
		, VAL = CASE 
			WHEN ABS(ISNULL(SUM(TurnOver),0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(SUM(TurnOver),0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(SUM(TurnOver),0)) END
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -SUM(HouseWinlost)*100/NULLIF(SUM(TurnOver),0)),0) as VARCHAR(10)) + '%'
FROM #tmpMargin
GROUP BY CASE WHEN SportName = 'All Sports' THEN 'ALL'				
				WHEN SportName = 'Soccer' AND Liveindicator = 1 AND IsSaba = 0 THEN 'R.Soc(L)'
				WHEN SportName = 'Soccer' AND Liveindicator = 0 AND IsSaba = 0 THEN 'R.Soc(NL)'				
				WHEN SportName = 'Soccer' AND IsSaba = 1 THEN 'Saba.Soc'
				WHEN SportName = 'Soccer' AND IsSaba = 2 THEN 'Soccer PG'	-- Saba Soccer Pingoal
				WHEN SportName = 'Basketball' AND IsSaba = 2 THEN 'Basket PG'	-- Saba Basketball Pingoal
				WHEN SportName = 'Basketball' AND IsSaba = 0 THEN 'Real.Bas'
				WHEN SportName = 'Basketball' AND IsSaba = 1 THEN 'Saba.Bas'				
				WHEN SportName = 'Tennis' THEN 'Tenn'				
				WHEN SportName = 'E-Sports' THEN 'E-Spo'
				WHEN SportName = 'Cricket' THEN 'Cricket'
				WHEN SportName = 'Other Sports' THEN 'Others'
				WHEN SportName = 'Parlay' THEN 'Parl'
			ELSE SportName END
		,CASE WHEN SportName = 'All Sports' THEN 1				
				WHEN SportName = 'Soccer' AND IsSaba = 0 AND Liveindicator = 1 THEN 3
				WHEN SportName = 'Soccer' AND IsSaba = 0 AND Liveindicator = 0 THEN 4					
				WHEN SportName = 'Soccer' AND IsSaba = 1 THEN 5
				WHEN SportName = 'Soccer' AND IsSaba = 2 THEN 6
				WHEN SportName = 'Basketball' AND IsSaba = 2 THEN 7
				WHEN SportName = 'Basketball' AND IsSaba = 0 THEN 8
				WHEN SportName = 'Basketball' AND IsSaba = 1 THEN 9
				WHEN SportName = 'Tennis' THEN 10
				WHEN SportName = 'E-Sports' THEN 11				
				WHEN SportName = 'Cricket' THEN 12
				WHEN SportName = 'Other Sports' THEN 13
				WHEN SportName = 'Parlay' THEN 14
			ELSE 15 END	

UNION ALL 
SELECT SportName = 'Real.Soc'
	,rn = 2
	,VAL = CASE 
			WHEN ABS(ISNULL(SUM(TurnOver),0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(SUM(TurnOver),0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(SUM(TurnOver),0)) END
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -SUM(HouseWinlost)*100/NULLIF(SUM(TurnOver),0)),0) as VARCHAR(10)) + '%'
FROM #tmpMargin
WHERE SportName = 'Soccer' AND IsSaba = 0
)
SELECT @msg = @msg + '<br>' + SportName + ': ' + VAL
FROM _S
ORDER BY rn

-- PHAIO
CREATE TABLE #tmpMarginPH (
	Market VARCHAR(50), TurnOver	MONEY, Margin MONEY, HouseWinlost MONEY
)

SELECT @msg = @msg + '<br>-------<br>[PH TO & M]'

INSERT INTO #tmpMarginPH (Market, TurnOver, Margin, HouseWinlost)
EXEC Acc_ResetWinning_MarginByMarket @Winlostdate = @wldate

SELECT @msg = @msg + ISNULL('<br>'
		+ Market + ': '
			--+ CASE WHEN ABS(TurnOver) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),TurnOver/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),TurnOver/1000) as VARCHAR(10)) + 'k' END 		
			+ CASE 
				WHEN ABS(ISNULL(TurnOver,0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
				WHEN ABS(ISNULL(TurnOver,0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
				ELSE CONVERT (VARCHAR(10), ISNULL(TurnOver,0)) END
			+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -HouseWinlost*100/NULLIF(TurnOver,0)),0) as VARCHAR(10)) + '%'
			,'')
FROM #tmpMarginPH
WHERE Market = 'PHAIO'

SELECT @msg = @msg + '<br>[TimeM TO & M]'
SELECT @msg = @msg + ISNULL('<br>'
		+ Market + ': '
		--+ CASE WHEN ABS(TurnOver) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),TurnOver/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),TurnOver/1000) as VARCHAR(10)) + 'k' END 		
		+ CASE 
			WHEN ABS(ISNULL(TurnOver,0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(TurnOver,0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(TurnOver,0)) END
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -HouseWinlost*100/NULLIF(TurnOver,0)),0) as VARCHAR(10)) + '%'	
		,'')	
FROM #tmpMarginPH
WHERE Market LIKE 'TimeM%'

-- non sports
CREATE TABLE #tmpMarginNonSport (
	ProductName VARCHAR(50), TurnOver MONEY, Margin MONEY, HouseWinlost MONEY, ProductCode VARCHAR(50), ProductGroup VARCHAR(10)
)

INSERT INTO #tmpMarginNonSport (ProductName, TurnOver, Margin, HouseWinlost)
EXEC Acc_ResetWinning_MarginByNonSport @Winlostdate = @wldate

-- merge vgaming into sc
;WITH _s AS (
	SELECT TurnOver_SC = SUM(TurnOver), HouseWinlost_SC = SUM(HouseWinlost)
	FROM #tmpMarginNonSport
	WHERE ProductName IN ('Saba.games', 'Vgaming')
)
UPDATE #tmpMarginNonSport
SET TurnOver = TurnOver_SC, HouseWinlost = HouseWinlost_SC, Margin = HouseWinlost_SC * 100 / TurnOver_SC
FROM _s
WHERE ProductName = 'Saba.games'

DELETE #tmpMarginNonSport WHERE ProductName = 'Vgaming'
-- /merge vgaming into sc

--2021-12-24: remove saba promotion from NS
DELETE #tmpMarginNonSport WHERE ProductName = 'Saba Promotion'

UPDATE #tmpMarginNonSport
SET ProductCode = CASE WHEN ProductName = 'All Non Sports' THEN 'ALL' 
			WHEN ProductName = 'Bet Builder' THEN 'BetB'
			WHEN ProductName = 'Metric Gaming - Super Live' THEN 'MetricG'
			WHEN ProductName = 'Number Game' THEN 'NumG'
			WHEN ProductName = 'Virtual Sports' THEN 'VirtSpo'
			WHEN ProductName = 'RNG Casino' THEN '1RNG'
			WHEN ProductName = 'RNG Keno' THEN 'MKeno'
			WHEN ProductName = 'Colossus Bets' THEN 'CB'
			WHEN ProductName = 'Allbet' THEN 'AllB'
			WHEN ProductName = 'Macau Games' THEN 'MacauG'
			WHEN ProductName = 'Fishing World' THEN 'FishW'
			WHEN ProductName = 'Cash Out' THEN 'CashO'
			WHEN ProductName = 'Virtual Sports 2' THEN 'VirtSpo2'
			WHEN ProductName = 'Lottery' THEN 'MLotte'
			--WHEN ProductName = 'Card Club' THEN 'CardC'
			WHEN ProductName = 'Arcadia Gaming' THEN 'ArcaGam'
			WHEN ProductName = 'PG Soft' THEN 'PGSoft'
			WHEN ProductName = 'Virtual Games' THEN 'VirtG'
			WHEN ProductName = 'Table Game' THEN 'TableG'
			WHEN ProductName = 'Saba.games' THEN 'SabaG'
			WHEN ProductName = 'Togel 4D' THEN 'Togel4D'
			WHEN ProductName = 'PP' THEN 'PragP'
			WHEN ProductName = 'SG' THEN 'SpadeG'
			WHEN ProductName = 'IBCBet Live Casino' THEN 'IBCLC'
			WHEN ProductName = 'SA Gaming' THEN 'SAG'
			WHEN ProductName = 'RNG War' THEN 'RNGWar'
			WHEN ProductName = 'Gold Deluxe' THEN 'GoldD'
			WHEN ProductName = 'AG Casino' THEN 'AG'
			WHEN ProductName = 'Sports Lottery' THEN 'SportsLott'	
			WHEN ProductName = 'PP Live Casino' THEN 'PP LC'
			WHEN ProductName = 'AE Sexy' THEN 'AESexy'
			WHEN ProductName = 'Habanero' THEN 'Haban'
			WHEN ProductName = 'AdvantPlay' THEN 'AdPlay'			
			WHEN ProductName = 'AdvantPlay Mini' THEN 'AdPlayMini'
			WHEN ProductName = 'Virtual Sports 3' THEN 'VirtSpo3'
			WHEN ProductName = 'Funky Games' THEN 'FunkyG'
			WHEN ProductName = 'Saba Casino' THEN 'SabaCas'
		ELSE ProductName END
	,ProductGroup = CASE WHEN ProductName = 'All Non Sports' THEN '-'
			WHEN ProductName = 'Allbet' THEN 'LC'			
			WHEN ProductName = 'AE Sexy' THEN 'LC'
			WHEN ProductName = 'IBCBet Live Casino' THEN 'LC'
			WHEN ProductName = 'SA Gaming' THEN 'LC'			
			WHEN ProductName = 'BBIN' THEN 'LC'
			WHEN ProductName = 'ION' THEN 'LC'			
			WHEN ProductName = 'Gold Deluxe' THEN 'LC'
			WHEN ProductName = 'AG Casino' THEN 'LC'
			WHEN ProductName = 'WM' THEN 'LC'
			WHEN ProductName = 'GDG' THEN 'LC'
			WHEN ProductName = 'BG' THEN 'LC'			
			WHEN ProductName = 'PP Live Casino' THEN 'LC'

			WHEN ProductName = 'Macau Games' THEN 'RNG'
			WHEN ProductName = 'Fishing World' THEN 'RNG'
			WHEN ProductName = 'Arcadia Gaming' THEN 'RNG'
			WHEN ProductName = 'PG Soft' THEN 'RNG'
			WHEN ProductName = 'Virtual Games' THEN 'RNG'
			WHEN ProductName = 'Table Game' THEN 'RNG'
			WHEN ProductName = 'Saba.games' THEN 'RNG'			
			WHEN ProductName = 'PP' THEN 'RNG'
			WHEN ProductName = 'SG' THEN 'RNG'
			WHEN ProductName = 'Joker' THEN 'RNG'
			WHEN ProductName = 'RNG War' THEN 'RNG'
			WHEN ProductName = 'RNG Casino' THEN 'RNG'
			WHEN ProductName = 'MaxGame' THEN 'RNG'
			WHEN ProductName = 'Habanero' THEN 'RNG'
			WHEN ProductName = 'Vgaming' THEN 'RNG'
			WHEN ProductName = 'AdvantPlay' THEN 'RNG'			
			WHEN ProductName = 'AdvantPlay Mini' THEN 'RNG'
			WHEN ProductName = 'CG' THEN 'RNG'
			WHEN ProductName = 'Saba Casino' THEN 'RNG'
			
			WHEN ProductName = 'Lottery' THEN 'LOTTERY'
			WHEN ProductName = 'Togel 4D' THEN 'LOTTERY'
			WHEN ProductName = 'RNG Keno' THEN 'LOTTERY'
			WHEN ProductName = 'Number Game' THEN 'LOTTERY'
			WHEN ProductName = 'NG2' THEN 'LOTTERY'
			WHEN ProductName = 'Sports Lottery' THEN 'LOTTERY'				

			WHEN ProductName = 'Metric Gaming - Super Live' THEN 'OTHERS'
			WHEN ProductName = 'Bet Builder' THEN 'OTHERS'
			WHEN ProductName = 'Virtual Sports' THEN 'OTHERS'
			WHEN ProductName = 'Colossus Bets' THEN 'OTHERS'
			WHEN ProductName = 'Cash Out' THEN 'OTHERS'
			WHEN ProductName = 'Virtual Sports 2' THEN 'OTHERS'
			WHEN ProductName = 'Virtual Sports 3' THEN 'OTHERS'
			WHEN ProductName = 'Funky Games' THEN 'OTHERS'
			WHEN ProductName = 'Bitcoin' THEN 'OTHERS'
		ELSE 'OTHERS' END

SELECT @msg2 = @msg2 + '<br>[NS TO & M]'
-- generate string for TO & Margin
SELECT @msg2 = @msg2 + '<br>' + ProductCode + ': '
		--+ CASE WHEN ABS(TurnOver) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),TurnOver/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),TurnOver/1000) as VARCHAR(10)) + 'k' END 		
		+ CASE 
			WHEN ABS(ISNULL(TurnOver,0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(TurnOver,0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(TurnOver,0)) END
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -HouseWinlost*100/NULLIF(TurnOver,0)),0) as VARCHAR(10)) + '%'	
FROM #tmpMarginNonSport
WHERE TurnOver > 0
	AND ProductCode = 'ALL'
ORDER BY TurnOver DESC

SELECT @msg2 = @msg2 + '<br>-----<br>*LC: '
		+ CASE 			
			WHEN ABS(ISNULL(SUM(TurnOver),0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(SUM(TurnOver),0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(SUM(TurnOver),0)) END		
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -SUM(HouseWinlost)*100/NULLIF(SUM(TurnOver),0)),0) as VARCHAR(10)) + '%'	
FROM #tmpMarginNonSport
WHERE TurnOver > 0
	AND ProductGroup = 'LC'

SELECT @msg2 = @msg2 + '<br>' + ProductCode + ': '
		--+ CASE WHEN ABS(TurnOver) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),TurnOver/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),TurnOver/1000) as VARCHAR(10)) + 'k' END 		
		+ CASE 
			WHEN ABS(ISNULL(TurnOver,0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(TurnOver,0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(TurnOver,0)) END
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -HouseWinlost*100/NULLIF(TurnOver,0)),0) as VARCHAR(10)) + '%'	
FROM #tmpMarginNonSport
WHERE TurnOver > 0
	AND ProductGroup = 'LC'
ORDER BY TurnOver DESC

SELECT @msg2 = @msg2 + '<br>-----<br>*RNG: '
		+ CASE 			
			WHEN ABS(ISNULL(SUM(TurnOver),0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(SUM(TurnOver),0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(SUM(TurnOver),0)) END		
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -SUM(HouseWinlost)*100/NULLIF(SUM(TurnOver),0)),0) as VARCHAR(10)) + '%'	
FROM #tmpMarginNonSport
WHERE TurnOver > 0
	AND ProductGroup = 'RNG'
SELECT @msg2 = @msg2 + '<br>' + ProductCode + ': '
		--+ CASE WHEN ABS(TurnOver) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),TurnOver/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),TurnOver/1000) as VARCHAR(10)) + 'k' END 		
		+ CASE 
			WHEN ABS(ISNULL(TurnOver,0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(TurnOver,0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(TurnOver,0)) END
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -HouseWinlost*100/NULLIF(TurnOver,0)),0) as VARCHAR(10)) + '%'	
FROM #tmpMarginNonSport
WHERE TurnOver > 0
	AND ProductGroup = 'RNG'
ORDER BY TurnOver DESC

SELECT @msg2 = @msg2 + '<br>-----<br>*Lott/Ken: '
		+ CASE 			
			WHEN ABS(ISNULL(SUM(TurnOver),0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(SUM(TurnOver),0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(SUM(TurnOver),0)) END		
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -SUM(HouseWinlost)*100/NULLIF(SUM(TurnOver),0)),0) as VARCHAR(10)) + '%'	
FROM #tmpMarginNonSport
WHERE TurnOver > 0
	AND ProductGroup = 'LOTTERY'
SELECT @msg2 = @msg2 + '<br>' + ProductCode + ': '
		--+ CASE WHEN ABS(TurnOver) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),TurnOver/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),TurnOver/1000) as VARCHAR(10)) + 'k' END 		
		+ CASE 
			WHEN ABS(ISNULL(TurnOver,0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(TurnOver,0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(TurnOver,0)) END
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -HouseWinlost*100/NULLIF(TurnOver,0)),0) as VARCHAR(10)) + '%'	
FROM #tmpMarginNonSport
WHERE TurnOver > 0
	AND ProductGroup = 'LOTTERY'
ORDER BY TurnOver DESC

SELECT @msg2 = @msg2 + '<br>-----<br>*OTHERS: '
		+ CASE 			
			WHEN ABS(ISNULL(SUM(TurnOver),0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(SUM(TurnOver),0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(SUM(TurnOver),0)) END		
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -SUM(HouseWinlost)*100/NULLIF(SUM(TurnOver),0)),0) as VARCHAR(10)) + '%'
FROM #tmpMarginNonSport
WHERE TurnOver > 0
	AND ProductGroup = 'OTHERS'
SELECT @msg2 = @msg2 + '<br>' + ProductCode + ': '
		--+ CASE WHEN ABS(TurnOver) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),TurnOver/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),TurnOver/1000) as VARCHAR(10)) + 'k' END 		
		+ CASE 
			WHEN ABS(ISNULL(TurnOver,0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(TurnOver,0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(TurnOver,0)) END
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -HouseWinlost*100/NULLIF(TurnOver,0)),0) as VARCHAR(10)) + '%'	
FROM #tmpMarginNonSport
WHERE TurnOver > 0
	AND ProductGroup = 'OTHERS'
ORDER BY TurnOver DESC
-------------

DECLARE @msg_y_dailyperf VARCHAR(MAX) = ''
DECLARE @msg_y_dailyperf2 VARCHAR(MAX) = ''

DECLARE @WL_Y_breakdown as TABLE (S varchar(30), WL money, TurnOver money , MG MONEY, rn int)
INSERT INTO @WL_Y_breakdown(S, WL, TurnOver, MG, rn)
SELECT  S = CASE 
				WHEN Site IN ('789Y') AND SB = 1 THEN 'T SB'
				WHEN Site IN ('789Y') AND SB = 0 THEN 'T NS'
				WHEN Site IN ('ACCUT') AND SB = 1 THEN 'UT SB'
				WHEN Site IN ('ACCUT') AND SB = 0 THEN 'UT NS'
				WHEN Site IN ('ACCYEN789') AND SB = 1 THEN 'Y789 SB'
				WHEN Site IN ('ACCYEN789') AND SB = 0 THEN 'Y789 NS'
				WHEN Site IN ('ACCYEN889') AND SB = 1 THEN 'Y889 SB'
				WHEN Site IN ('ACCYEN889') AND SB = 0 THEN 'Y889 NS'
				WHEN Site IN ('Unassigned') AND SB = 1 THEN 'Other SB'
				WHEN Site IN ('Unassigned') AND SB = 0 THEN 'Other NS'
			ELSE Site END
		,WL = -SUM(ISNULL(HouseWinlost,0))  
		,TurnOver = SUM(ISNULL(TurnOver,0)) 
		,MG = CASE WHEN SUM (ISNULL(TurnOver,0)) = 0 THEN 0 ELSE -SUM(ISNULL(HouseWinlost,0))/SUM (ISNULL(TurnOver,0)) * 100 END
		,rn = CASE 
				WHEN Site IN ('789Y') AND SB = 1 THEN 9
				WHEN Site IN ('789Y') AND SB = 0 THEN 10
				WHEN Site IN ('ACCUT') AND SB = 1 THEN 1
				WHEN Site IN ('ACCUT') AND SB = 0 THEN 2
				WHEN Site IN ('ACCYEN789') AND SB = 1 THEN 3
				WHEN Site IN ('ACCYEN789') AND SB = 0 THEN 4
				WHEN Site IN ('ACCYEN889') AND SB = 1 THEN 5
				WHEN Site IN ('ACCYEN889') AND SB = 0 THEN 6
				WHEN Site IN ('Unassigned') AND SB = 1 THEN 7
				WHEN Site IN ('Unassigned') AND SB = 0 THEN 8
			ELSE 11 END	
FROM #tmpResetWinning
WHERE SITE IN ('789Y') OR isDeposit IN (3)
GROUP BY CASE 
				WHEN Site IN ('789Y') AND SB = 1 THEN 'T SB'
				WHEN Site IN ('789Y') AND SB = 0 THEN 'T NS'
				WHEN Site IN ('ACCUT') AND SB = 1 THEN 'UT SB'
				WHEN Site IN ('ACCUT') AND SB = 0 THEN 'UT NS'
				WHEN Site IN ('ACCYEN789') AND SB = 1 THEN 'Y789 SB'
				WHEN Site IN ('ACCYEN789') AND SB = 0 THEN 'Y789 NS'
				WHEN Site IN ('ACCYEN889') AND SB = 1 THEN 'Y889 SB'
				WHEN Site IN ('ACCYEN889') AND SB = 0 THEN 'Y889 NS'
				WHEN Site IN ('Unassigned') AND SB = 1 THEN 'Other SB'
				WHEN Site IN ('Unassigned') AND SB = 0 THEN 'Other NS'
			ELSE Site END
		,CASE 
				WHEN Site IN ('789Y') AND SB = 1 THEN 9
				WHEN Site IN ('789Y') AND SB = 0 THEN 10
				WHEN Site IN ('ACCUT') AND SB = 1 THEN 1
				WHEN Site IN ('ACCUT') AND SB = 0 THEN 2
				WHEN Site IN ('ACCYEN789') AND SB = 1 THEN 3
				WHEN Site IN ('ACCYEN789') AND SB = 0 THEN 4
				WHEN Site IN ('ACCYEN889') AND SB = 1 THEN 5
				WHEN Site IN ('ACCYEN889') AND SB = 0 THEN 6
				WHEN Site IN ('Unassigned') AND SB = 1 THEN 7
				WHEN Site IN ('Unassigned') AND SB = 0 THEN 8
			ELSE 11 END	

SELECT @msg_y_dailyperf = @msg_y_dailyperf + '<br>' + S + ': '
		--+ CASE WHEN ABS(WL) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),WL/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),WL/1000) as VARCHAR(10)) + 'k' END 	
		+ CASE 
			WHEN ABS(ISNULL(WL,0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(WL,0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(WL,0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(WL,0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(WL,0)) END
		+ ' ' + CAST(CONVERT(DECIMAL(10,2), ISNULL(MG,0)) as VARCHAR(10)) + '%'	
FROM @WL_Y_breakdown
ORDER BY rn

SET @msg_y_dailyperf = REPLACE(@msg_y_dailyperf, '<br>T SB:', '<br><br>T SB:')

CREATE TABLE #tmpMarginY (
	SportName VARCHAR(50), LiveIndicator BIT, IsSaba tinyint, TurnOver MONEY, Margin MONEY, HouseWinlost MONEY
)

INSERT INTO #tmpMarginY (SportName, LiveIndicator, IsSaba, TurnOver, Margin, HouseWinlost)
EXEC Acc_ResetWinning_MarginBySport_Y @Winlostdate = @wldate

SELECT @msg_y_dailyperf = @msg_y_dailyperf + '<br>-------<br>[SB TO & M]'
-- generate string for TO & Margin
;WITH _S as (
	SELECT SportName = CASE WHEN SportName = 'All Sports' THEN 'ALL'				
				WHEN SportName = 'Soccer' AND Liveindicator = 1 AND IsSaba = 0 THEN 'R.Soc(L)'
				WHEN SportName = 'Soccer' AND Liveindicator = 0 AND IsSaba = 0 THEN 'R.Soc(NL)'					
				WHEN SportName = 'Soccer' AND IsSaba = 1 THEN 'Saba.Soc'
				WHEN SportName = 'Soccer' AND IsSaba = 2 THEN 'Soccer PG'	-- Saba Soccer Pingoal
				WHEN SportName = 'Basketball' AND IsSaba = 2 THEN 'Basket PG'	-- Saba Basketball Pingoal
				WHEN SportName = 'Basketball' AND IsSaba = 0 THEN 'Real.Bas'
				WHEN SportName = 'Basketball' AND IsSaba = 1 THEN 'Saba.Bas'				
				WHEN SportName = 'Tennis' THEN 'Tenn'
				WHEN SportName = 'E-Sports' THEN 'E-Spo'
				WHEN SportName = 'Cricket' THEN 'Cricket'
				WHEN SportName = 'Other Sports' THEN 'Others'
				WHEN SportName = 'Parlay' THEN 'Parl'
			ELSE SportName END
		,rn = CASE WHEN SportName = 'All Sports' THEN 1				
				WHEN SportName = 'Soccer' AND IsSaba = 0 AND Liveindicator = 1 THEN 3
				WHEN SportName = 'Soccer' AND IsSaba = 0 AND Liveindicator = 0 THEN 4					
				WHEN SportName = 'Soccer' AND IsSaba = 1 THEN 5
				WHEN SportName = 'Soccer' AND IsSaba = 2 THEN 6
				WHEN SportName = 'Basketball' AND IsSaba = 2 THEN 7
				WHEN SportName = 'Basketball' AND IsSaba = 0 THEN 8
				WHEN SportName = 'Basketball' AND IsSaba = 1 THEN 9
				WHEN SportName = 'Tennis' THEN 10
				WHEN SportName = 'E-Sports' THEN 11				
				WHEN SportName = 'Cricket' THEN 12
				WHEN SportName = 'Other Sports' THEN 13
				WHEN SportName = 'Parlay' THEN 14
			ELSE 15 END	
		, VAL = CASE 
			WHEN ABS(ISNULL(SUM(TurnOver),0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(SUM(TurnOver),0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(SUM(TurnOver),0)) END
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -SUM(HouseWinlost)*100/NULLIF(SUM(TurnOver),0)),0) as VARCHAR(10)) + '%'
FROM #tmpMarginY
GROUP BY CASE WHEN SportName = 'All Sports' THEN 'ALL'			
			WHEN SportName = 'Soccer' AND Liveindicator = 1 AND IsSaba = 0 THEN 'R.Soc(L)'
			WHEN SportName = 'Soccer' AND Liveindicator = 0 AND IsSaba = 0 THEN 'R.Soc(NL)'		
			WHEN SportName = 'Soccer' AND IsSaba = 1 THEN 'Saba.Soc'
			WHEN SportName = 'Soccer' AND IsSaba = 2 THEN 'Soccer PG'	-- Saba Soccer Pingoal
			WHEN SportName = 'Basketball' AND IsSaba = 2 THEN 'Basket PG' -- Saba Basketball Pingoal
			WHEN SportName = 'Basketball' AND IsSaba = 0 THEN 'Real.Bas'
			WHEN SportName = 'Basketball' AND IsSaba = 1 THEN 'Saba.Bas'
			WHEN SportName = 'Tennis' THEN 'Tenn'
			WHEN SportName = 'E-Sports' THEN 'E-Spo'
			WHEN SportName = 'Cricket' THEN 'Cricket'
			WHEN SportName = 'Other Sports' THEN 'Others'
			WHEN SportName = 'Parlay' THEN 'Parl'
		ELSE SportName END
		,CASE WHEN SportName = 'All Sports' THEN 1			
			WHEN SportName = 'Soccer' AND IsSaba = 0 AND Liveindicator = 1 THEN 3
			WHEN SportName = 'Soccer' AND IsSaba = 0 AND Liveindicator = 0 THEN 4			
			WHEN SportName = 'Soccer' AND IsSaba = 1 THEN 5
			WHEN SportName = 'Soccer' AND IsSaba = 2 THEN 6
			WHEN SportName = 'Basketball' AND IsSaba = 2 THEN 7
			WHEN SportName = 'Basketball' AND IsSaba = 0 THEN 8
			WHEN SportName = 'Basketball' AND IsSaba = 1 THEN 9			
			WHEN SportName = 'Tennis' THEN 10
			WHEN SportName = 'E-Sports' THEN 11				
			WHEN SportName = 'Cricket' THEN 12
			WHEN SportName = 'Other Sports' THEN 13
			WHEN SportName = 'Parlay' THEN 14
		ELSE 15 END	

UNION ALL 
SELECT SportName = 'Real.Soc'
	,rn = 2
	,VAL = CASE 			
			WHEN ABS(ISNULL(SUM(TurnOver),0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(SUM(TurnOver),0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(SUM(TurnOver),0)) END
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -SUM(HouseWinlost)*100/NULLIF(SUM(TurnOver),0)),0) as VARCHAR(10)) + '%'
FROM #tmpMarginY
WHERE SportName = 'Soccer' AND IsSaba = 0
)
SELECT @msg_y_dailyperf = @msg_y_dailyperf + '<br>' + SportName + ': ' + VAL
FROM _S
ORDER BY rn


-- non sports
CREATE TABLE #tmpMarginNonSportY (
	ProductName VARCHAR(50), TurnOver MONEY, Margin MONEY, HouseWinlost MONEY
)

INSERT INTO #tmpMarginNonSportY (ProductName, TurnOver, Margin, HouseWinlost)
EXEC Acc_ResetWinning_MarginByNonSport_Y @Winlostdate = @wldate

SELECT @msg_y_dailyperf2 = @msg_y_dailyperf2 + '[NS TO & M]'
SELECT @msg_y_dailyperf2 = @msg_y_dailyperf2 + '<br>' + 
	CASE WHEN ProductName = 'All Non Sports' THEN 'ALL' 
			WHEN ProductName = 'Bet Builder' THEN 'BetB'
			WHEN ProductName = 'Metric Gaming - Super Live' THEN 'MetricG'
			WHEN ProductName = 'Number Game' THEN 'NumG'
			WHEN ProductName = 'Virtual Sports' THEN 'VirtSpo'
			WHEN ProductName = 'RNG Casino' THEN '1RNG'
			WHEN ProductName = 'RNG Keno' THEN 'MKeno'
			WHEN ProductName = 'Colossus Bets' THEN 'CB'
			WHEN ProductName = 'Allbet' THEN 'AllB'
			WHEN ProductName = 'Macau Games' THEN 'MacauG'
			WHEN ProductName = 'Fishing World' THEN 'FishW'
			WHEN ProductName = 'Cash Out' THEN 'CashO'
			WHEN ProductName = 'Virtual Sports 2' THEN 'VirtSpo2'
			WHEN ProductName = 'Lottery' THEN 'MLotte'
			--WHEN ProductName = 'Card Club' THEN 'CardC'
			WHEN ProductName = 'Arcadia Gaming' THEN 'ArcaGam'
			WHEN ProductName = 'PG Soft' THEN 'PGSoft'
			WHEN ProductName = 'Virtual Games' THEN 'VirtG'
			WHEN ProductName = 'Table Game' THEN 'TableG'
			WHEN ProductName = 'Saba.games' THEN 'SabaG'
			WHEN ProductName = 'Togel 4D' THEN 'I4D'
			WHEN ProductName = 'PP' THEN 'PragP'
			WHEN ProductName = 'SG' THEN 'SpadeG'			
			WHEN ProductName = 'IBCBet Live Casino' THEN 'IBCLC'
			WHEN ProductName = 'SA Gaming' THEN 'SAG'
			WHEN ProductName = 'RNG War' THEN 'RNGWar'
			WHEN ProductName = 'Gold Deluxe' THEN 'GoldD'
			WHEN ProductName = 'AG Casino' THEN 'AG'
			WHEN ProductName = 'Sports Lottery' THEN 'SportsLott'	
			WHEN ProductName = 'PP Live Casino' THEN 'PP LC'
			WHEN ProductName = 'AE Sexy' THEN 'AESexy'
			WHEN ProductName = 'Habanero' THEN 'Haban'
			WHEN ProductName = 'AdvantPlay' THEN 'AdPlay'
			WHEN ProductName = 'AdvantPlay Mini' THEN 'AdPlayMini'
			WHEN ProductName = 'Virtual Sports 3' THEN 'VirtSpo3'
			WHEN ProductName = 'Funky Games' THEN 'FunkyG'
			WHEN ProductName = 'Saba Casino' THEN 'SabaCas'
	ELSE ProductName END + ': '
		--+ CASE WHEN ABS(TurnOver) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),TurnOver/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),TurnOver/1000) as VARCHAR(10)) + 'k' END 		
		+ CASE 
			WHEN ABS(ISNULL(TurnOver,0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(TurnOver,0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(TurnOver,0)) END
		+ ' ' + CAST(CONVERT(DECIMAL(10,2), -ISNULL(Margin,0)) as VARCHAR(10)) + '%'		
FROM #tmpMarginNonSportY
WHERE TurnOver > 0
ORDER BY TurnOver DESC


-- Licensee WL
/*[TOTAL WL & M]
SB: 872k 2.39%
NS: 564k M: 2.12%
*/

---viet
-- For LICENSEEs
CREATE TABLE #tmpMarginLIC (SportName VARCHAR(50), LiveIndicator BIT, IsSaba Tinyint, TurnOver MONEY, Margin MONEY, HouseWinlost MONEY)
CREATE TABLE #tmpMarginNonSportLIC (ProductName VARCHAR(50), TurnOver MONEY, Margin MONEY, HouseWinlost MONEY)

INSERT INTO #tmpMarginLIC (SportName, LiveIndicator, IsSaba, TurnOver, Margin, HouseWinlost)
EXEC Acc_ResetWinning_MarginBySport_Lic @Winlostdate = @wldate, @BaseCurrency = 'CNY' --base currency RMB

INSERT INTO #tmpMarginNonSportLIC (ProductName, TurnOver, Margin, HouseWinlost)
EXEC Acc_ResetWinning_MarginByNonSport_Lic @Winlostdate = @wldate, @BaseCurrency = 'CNY' --base currency RMB

DELETE #tmpMarginLIC WHERE TurnOver IS NULL
DELETE #tmpMarginNonSportLIC WHERE TurnOver IS NULL

-- Licensee margin
DECLARE @msg_LIC_dailyperf VARCHAR(MAX) = ''

-- LIC WL
SELECT @msg_LIC_dailyperf = @msg_LIC_dailyperf + '[TOTAL WL(RMB) & M]'
SELECT @msg_LIC_dailyperf = @msg_LIC_dailyperf + '<br>'
		+ 'SB: '			
			+ CASE 
			WHEN ABS(-ISNULL(SUM(HouseWinlost),0)) BETWEEN 0 AND 999999 THEN (CONVERT(VARCHAR(10), (CAST(ROUND(-ISNULL(SUM(HouseWinlost),0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(-ISNULL(SUM(HouseWinlost),0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), (CAST(ROUND(-ISNULL(SUM(HouseWinlost),0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), -ISNULL(SUM(HouseWinlost),0)) END
		+ '  ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -SUM(HouseWinlost)*100/NULLIF(SUM(TurnOver),0)),0) as VARCHAR(10)) + '%'
FROM #tmpMarginLIC
WHERE SportName = 'All Sports'

SELECT @msg_LIC_dailyperf = @msg_LIC_dailyperf + '<br>'
		+ 'NS: '			
			+ CASE 
			WHEN ABS(-ISNULL(SUM(HouseWinlost),0)) BETWEEN 0 AND 999999 THEN (CONVERT(VARCHAR(10), (CAST(ROUND(-ISNULL(SUM(HouseWinlost),0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(-ISNULL(SUM(HouseWinlost),0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), (CAST(ROUND(-ISNULL(SUM(HouseWinlost),0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), -ISNULL(SUM(HouseWinlost),0)) END
		+ '  ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -SUM(HouseWinlost)*100/NULLIF(SUM(TurnOver),0)),0) as VARCHAR(10)) + '%'
FROM #tmpMarginNonSportLIC
WHERE ProductName = 'All Non Sports'

SELECT @msg_LIC_dailyperf = @msg_LIC_dailyperf + '<br>-------<br>[SB TO(RMB) & M]'
;WITH _S as (
	SELECT SportName = CASE WHEN SportName = 'All Sports' THEN 'ALL'				
				WHEN SportName = 'Soccer' AND Liveindicator = 1 AND IsSaba = 0 THEN 'R.Soc(L)'
				WHEN SportName = 'Soccer' AND Liveindicator = 0 AND IsSaba = 0 THEN 'R.Soc(NL)'					
				WHEN SportName = 'Soccer' AND IsSaba = 1 THEN 'Saba.Soc'
				WHEN SportName = 'Soccer' AND IsSaba = 2 THEN 'Soccer PG'	-- Saba Soccer Pingoal
				WHEN SportName = 'Basketball' AND IsSaba = 2 THEN 'Basket PG'	-- Saba Basketball Pingoal
				WHEN SportName = 'Basketball' AND IsSaba = 0 THEN 'Real.Bas'
				WHEN SportName = 'Basketball' AND IsSaba = 1 THEN 'Saba.Bas'				
				WHEN SportName = 'Tennis' THEN 'Tenn'
				WHEN SportName = 'E-Sports' THEN 'E-Spo'
				WHEN SportName = 'Cricket' THEN 'Cricket'
				WHEN SportName = 'Other Sports' THEN 'Others'
				WHEN SportName = 'Parlay' THEN 'Parl'
			ELSE SportName END
		,rn = CASE WHEN SportName = 'All Sports' THEN 1				
				WHEN SportName = 'Soccer' AND IsSaba = 0 AND Liveindicator = 1 THEN 3
				WHEN SportName = 'Soccer' AND IsSaba = 0 AND Liveindicator = 0 THEN 4					
				WHEN SportName = 'Soccer' AND IsSaba = 1 THEN 5
				WHEN SportName = 'Soccer' AND IsSaba = 2 THEN 6
				WHEN SportName = 'Basketball' AND IsSaba = 2 THEN 7
				WHEN SportName = 'Basketball' AND IsSaba = 0 THEN 8
				WHEN SportName = 'Basketball' AND IsSaba = 1 THEN 9				
				WHEN SportName = 'Tennis' THEN 10
				WHEN SportName = 'E-Sports' THEN 11				
				WHEN SportName = 'Cricket' THEN 12
				WHEN SportName = 'Other Sports' THEN 13
				WHEN SportName = 'Parlay' THEN 14
			ELSE 15 END		
		, VAL = CASE 
			WHEN ABS(ISNULL(SUM(TurnOver),0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(SUM(TurnOver),0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(SUM(TurnOver),0)) END
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -SUM(HouseWinlost)*100/NULLIF(SUM(TurnOver),0)),0) as VARCHAR(10)) + '%'
FROM #tmpMarginLIC
GROUP BY CASE WHEN SportName = 'All Sports' THEN 'ALL'			
			WHEN SportName = 'Soccer' AND Liveindicator = 1 AND IsSaba = 0 THEN 'R.Soc(L)'
			WHEN SportName = 'Soccer' AND Liveindicator = 0 AND IsSaba = 0 THEN 'R.Soc(NL)'		
			WHEN SportName = 'Soccer' AND IsSaba = 1 THEN 'Saba.Soc'
			WHEN SportName = 'Soccer' AND IsSaba = 2 THEN 'Soccer PG'	-- Saba Soccer Pingoal
			WHEN SportName = 'Basketball' AND IsSaba = 2 THEN 'Basket PG'	-- Saba Basketball Pingoal
			WHEN SportName = 'Basketball' AND IsSaba = 0 THEN 'Real.Bas'
			WHEN SportName = 'Basketball' AND IsSaba = 1 THEN 'Saba.Bas'
			WHEN SportName = 'Tennis' THEN 'Tenn'
			WHEN SportName = 'E-Sports' THEN 'E-Spo'
			WHEN SportName = 'Cricket' THEN 'Cricket'
			WHEN SportName = 'Other Sports' THEN 'Others'
			WHEN SportName = 'Parlay' THEN 'Parl'
		ELSE SportName END
		,CASE WHEN SportName = 'All Sports' THEN 1			
			WHEN SportName = 'Soccer' AND IsSaba = 0 AND Liveindicator = 1 THEN 3
			WHEN SportName = 'Soccer' AND IsSaba = 0 AND Liveindicator = 0 THEN 4			
			WHEN SportName = 'Soccer' AND IsSaba = 1 THEN 5
			WHEN SportName = 'Soccer' AND IsSaba = 2 THEN 6
			WHEN SportName = 'Basketball' AND IsSaba = 2 THEN 7
			WHEN SportName = 'Basketball' AND IsSaba = 0 THEN 8
			WHEN SportName = 'Basketball' AND IsSaba = 1 THEN 9	
			WHEN SportName = 'Tennis' THEN 10
			WHEN SportName = 'E-Sports' THEN 11				
			WHEN SportName = 'Cricket' THEN 12
			WHEN SportName = 'Other Sports' THEN 13
			WHEN SportName = 'Parlay' THEN 14
		ELSE 15 END		

UNION ALL 
SELECT SportName = 'Real.Soc'
	,rn = 2
	,VAL = CASE 			
			WHEN ABS(ISNULL(SUM(TurnOver),0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(SUM(TurnOver),0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(SUM(TurnOver),0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(SUM(TurnOver),0)) END
		+ ' ' + CAST(ISNULL(CONVERT(DECIMAL(10,2), -SUM(HouseWinlost)*100/NULLIF(SUM(TurnOver),0)),0) as VARCHAR(10)) + '%'
FROM #tmpMarginLIC
WHERE SportName = 'Soccer' AND IsSaba = 0
)
SELECT @msg_LIC_dailyperf = @msg_LIC_dailyperf + '<br>' + SportName + ': ' + VAL
FROM _S
ORDER BY rn


-- non sports
SELECT @msg_LIC_dailyperf = @msg_LIC_dailyperf + '<br>-------<br>[NS TO(RMB) & M]'
SELECT @msg_LIC_dailyperf = @msg_LIC_dailyperf + '<br>' + 
	CASE WHEN ProductName = 'All Non Sports' THEN 'ALL' 
			WHEN ProductName = 'Bet Builder' THEN 'BetB'
			WHEN ProductName = 'Metric Gaming - Super Live' THEN 'MetricG'
			WHEN ProductName = 'Number Game' THEN 'NumG'
			WHEN ProductName = 'Virtual Sports' THEN 'VirtSpo'
			WHEN ProductName = 'RNG Casino' THEN '1RNG'
			WHEN ProductName = 'RNG Keno' THEN 'MKeno'
			WHEN ProductName = 'Colossus Bets' THEN 'CB'
			WHEN ProductName = 'Allbet' THEN 'AllB'
			WHEN ProductName = 'Macau Games' THEN 'MacauG'
			WHEN ProductName = 'Fishing World' THEN 'FishW'
			WHEN ProductName = 'Cash Out' THEN 'CashO'
			WHEN ProductName = 'Virtual Sports 2' THEN 'VirtSpo2'
			WHEN ProductName = 'Lottery' THEN 'MLotte'
			--WHEN ProductName = 'Card Club' THEN 'CardC'
			WHEN ProductName = 'Arcadia Gaming' THEN 'ArcaGam'
			WHEN ProductName = 'PG Soft' THEN 'PGSoft'
			WHEN ProductName = 'Virtual Games' THEN 'VirtG'
			WHEN ProductName = 'Table Game' THEN 'TableG'
			WHEN ProductName = 'Saba.games' THEN 'SabaG'
			WHEN ProductName = 'Togel 4D' THEN 'I4D'
			WHEN ProductName = 'PP' THEN 'PragP'
			WHEN ProductName = 'SG' THEN 'SpadeG'
			WHEN ProductName = 'IBCBet Live Casino' THEN 'IBCLC'
			WHEN ProductName = 'SA Gaming' THEN 'SAG'
			WHEN ProductName = 'RNG War' THEN 'RNGWar'
			WHEN ProductName = 'Gold Deluxe' THEN 'GoldD'
			WHEN ProductName = 'AG Casino' THEN 'AG'
			WHEN ProductName = 'Sports Lottery' THEN 'SportsLott'	
			WHEN ProductName = 'PP Live Casino' THEN 'PP LC'
			WHEN ProductName = 'AE Sexy' THEN 'AESexy'
			WHEN ProductName = 'Habanero' THEN 'Haban'
			WHEN ProductName = 'AdvantPlay' THEN 'AdPlay'
			WHEN ProductName = 'AdvantPlay Mini' THEN 'AdPlayMini'
			WHEN ProductName = 'Virtual Sports 3' THEN 'VirtSpo3'
			WHEN ProductName = 'Funky Games' THEN 'FunkyG'
			WHEN ProductName = 'Saba Casino' THEN 'SabaCas'
	ELSE ProductName END + ': '
		--+ CASE WHEN ABS(TurnOver) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),TurnOver/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),TurnOver/1000) as VARCHAR(10)) + 'k' END 		
		+ CASE 
			WHEN ABS(ISNULL(TurnOver,0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(TurnOver,0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(TurnOver,0)) END
		+ ' ' + CAST(CONVERT(DECIMAL(10,2), -ISNULL(Margin,0)) as VARCHAR(10)) + '%'		
FROM #tmpMarginNonSportLIC
WHERE TurnOver > 0
ORDER BY TurnOver DESC

------------------------
IF (@dayOffset = -1)
BEGIN
	DECLARE @msg_seal_api VARCHAR(max) = ''
	SELECT @msg_seal_api = 'T: '		
			--+ CASE WHEN ABS(TurnOver) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),TurnOver/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),TurnOver/1000) as VARCHAR(10)) + 'k' END
			+ CASE 
			WHEN ABS(ISNULL(TurnOver,0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(TurnOver,0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(TurnOver,0)) END
			+ ' M: ' + CAST(CONVERT(DECIMAL(10,2), -ISNULL(Margin,0)) as VARCHAR(10)) + '%'
	FROM #tmpMarginNonSport
	WHERE ProductName = 'All Non Sports'

	DECLARE @Temp_taione_ns AS TABLE(ProductName varchar(50), Turnover Money, Margin Money, HouseWinlost Money)
	INSERT INTO @Temp_taione_ns (ProductName, Turnover, Margin, HouseWinlost)
	SELECT SportName, Turnover, Margin, HouseWinlost
	FROM #tmpMargin
	WHERE SportName = 'E-Sports'
	UNION ALL
	SELECT ProductName, Turnover, Margin, HouseWinlost
	FROM #tmpMarginNonSport
	WHERE ProductName IN ('RNG Casino', 'Virtual Games', 'Number Game')
	---
	DECLARE @msg_taione_ns VARCHAR(max) = ''
	INSERT INTO @Temp_taione_ns (ProductName, Turnover, Margin, HouseWinlost)
	SELECT 'All', SUM(Turnover), ISNULL(SUM(HouseWinlost)*100/NULLIF(SUM(Turnover),0),0), SUM(HouseWinlost)
	FROM @Temp_taione_ns

	SELECT @msg_taione_ns = 'T: '		
			--+ CASE WHEN ABS(TurnOver) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),TurnOver/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),TurnOver/1000) as VARCHAR(10)) + 'k' END
			+ CASE 
			WHEN ABS(ISNULL(TurnOver,0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(TurnOver,0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnOver,0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(TurnOver,0)) END
			+ ' M: ' + CAST(CONVERT(DECIMAL(10,2), -ISNULL(Margin,0)) as VARCHAR(10)) + '%'
	FROM @Temp_taione_ns
	WHERE ProductName = 'All'
	---
	DECLARE @msg_infinity_member VARCHAR(max) = ''
	DECLARE @TO_infinity_member MONEY, @Margin_infinity_member MONEY
	SELECT @TO_infinity_member = SUM(TurnOver), @Margin_infinity_member = ISNULL(SUM(HouseWinlost)*100/NULLIF(SUM(Turnover),0),0)
	FROM #tmpResetWinning
	WHERE isDeposit = 0
		AND SB = 1
		AND Site NOT IN ('CN88')

	SELECT @msg_infinity_member = 'T: '		
			--+ CASE WHEN ABS(@TO_infinity_member) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),@TO_infinity_member/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),@TO_infinity_member/1000) as VARCHAR(10)) + 'k' END
			+ CASE 
			WHEN ABS(ISNULL(@TO_infinity_member,0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(@TO_infinity_member,0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
			WHEN ABS(ISNULL(@TO_infinity_member,0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(@TO_infinity_member,0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
			ELSE CONVERT (VARCHAR(10), ISNULL(@TO_infinity_member,0)) END
			+ ' M: ' + CAST(CONVERT(DECIMAL(10,2), -ISNULL(@Margin_infinity_member,0)) as VARCHAR(10)) + '%'		

	EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'SEAL.API', @Msg = @msg_seal_api, @Title = 'This number is for KPI reference only' -- SEAL.API group
	EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'TAIONE.NS', @Msg = @msg_taione_ns, @Title = 'This number is for KPI reference only' -- TAIONE.NS group	
	EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'Infinity.Member', @Msg = @msg_infinity_member, @Title = 'This number is for KPI reference only' -- Infinity.Member group	
END

--- TOP 30 low margin Licensees
/*
	1. Get the list of top 50 Licensees with highest turnover of the day
	2. Sort the list by lowest margin.
	3. Get the top 30 licensees
	4. Order by TO
*/
CREATE TABLE #tmpTopLicenseeMargin (
	Licensee VARCHAR(50), MarginAllSport DECIMAL(19,4), MarginSoccer DECIMAL(19,4), MarginBasketball DECIMAL(19,4), MarginEsport DECIMAL(19,4), MarginTennis DECIMAL(19,4), MarginParlay DECIMAL(19,4), MarginSabaSoccer DECIMAL(19,4), MarginSabaBasketball DECIMAL(19,4), MarginOthersport DECIMAL(19,4), TurnoverAllSport DECIMAL(19,4)
)

INSERT INTO #tmpTopLicenseeMargin (Licensee, MarginAllSport, MarginSoccer, MarginBasketball, MarginEsport, MarginTennis, MarginParlay, MarginSabaSoccer, MarginSabaBasketball, MarginOthersport, TurnoverAllSport)
EXEC Acc_ResetWinning_TopLicenseeMargin @Winlostdate = @wldate

DECLARE @Temp_Top30Final AS TABLE(Licensee VARCHAR(50), MarginAllSport DECIMAL(19,4), TurnoverAllSport DECIMAL(19,4))
INSERT INTO @Temp_Top30Final(Licensee, MarginAllSport, TurnoverAllSport)
SELECT TOP 30 Licensee, MarginAllSport, TurnoverAllSport
FROM #tmpTopLicenseeMargin
WHERE Licensee <> 'Other Licensees'
ORDER BY MarginAllSport


DECLARE @msgLicMargin VARCHAR(max) = '[LIC TO(MYR) Margin]'
SELECT @msgLicMargin = @msgLicMargin + '<br>' + Licensee 
	+ ' ' + CASE 
				WHEN ABS(ISNULL(TurnoverAllSport,0)) BETWEEN 0 AND 999999 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnoverAllSport,0) / 1000.0, 0) AS NUMERIC(4, 0)) )) ) + 'k'
				WHEN ABS(ISNULL(TurnoverAllSport,0)) >= 1000000 THEN ( CONVERT (VARCHAR(10), ( CAST(ROUND(ISNULL(TurnoverAllSport,0) / 1000000.0, 2) AS NUMERIC(6, 2)) )) ) + 'm'
				ELSE CONVERT (VARCHAR(10), ISNULL(TurnoverAllSport,0)) END
	+ ' ' + CAST(CONVERT(DECIMAL(10,2), ISNULL(MarginAllSport,0)*100) as VARCHAR(10)) + '%'

FROM @Temp_Top30Final
ORDER BY TurnoverAllSport DESC

DROP TABLE #tmpResetWinning
DROP TABLE #tmpMargin
DROP TABLE #tmpMarginPH
DROP TABLE #tmpMarginNonSport
DROP TABLE #tmpMarginY
DROP TABLE #tmpMarginNonSportY
DROP TABLE #tmpTopLicenseeMargin
DROP TABLE #tmpMarginLIC
DROP TABLE #tmpMarginNonSportLIC
---

DECLARE @letstalkNewLine varchar(1000) = '
'
SET @msg = replace(@msg, '<br>', @letstalkNewLine)
SET @msg2 = replace(@msg2, '<br>', @letstalkNewLine)
SET @msg_y_dailyperf = replace(@msg_y_dailyperf, '<br>', @letstalkNewLine)
SET @msg_y_dailyperf2 = replace(@msg_y_dailyperf2, '<br>', @letstalkNewLine)
SET @msgLicMargin = replace(@msgLicMargin, '<br>', @letstalkNewLine)
SET @msg_LIC_dailyperf = replace(@msg_LIC_dailyperf, '<br>', @letstalkNewLine)

--PRINT @msg_seal_api
--PRINT @msg_taione_ns
--PRINT @msg_infinity_member
--PRINT  @msg
--PRINT  @msg2
--PRINT @msg_y_dailyperf
--PRINT @msg_y_dailyperf2
--PRINT @msgLicMargin
--PRINT @msg_LIC_dailyperf

-- send letstalk's message
EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'vietgroup', @Msg = @msg, @Title = @title -- main group
EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'vietgroup.UAT', @Msg = @msg, @Title = @title -- UAT group --(Σ PERF)
EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'vietgroup', @Msg = @msg2, @Title = @title -- main group
EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'vietgroup.UAT', @Msg = @msg2, @Title = @title -- UAT group (Σ PERF)
EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'NotiGroup2', @Msg = @msg_y_dailyperf, @Title = @title -- Y-DailyPerformance --(Y PERF)
EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'NotiGroup2', @Msg = @msg_y_dailyperf2, @Title = @title -- Y-DailyPerformance --(Y PERF)
EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'vietgroup', @Msg = @msgLicMargin, @Title = @title -- main group
EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'daily-house-wl', @Msg = @msgLicMargin, @Title = @Title -- Licensee Performance
EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'daily-house-wl', @Msg = @msg_LIC_dailyperf, @Title = @Title -- Licensee Performance
EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'NotiGroup4', @Msg = @msgLicMargin, @Title = @Title -- L-DailyPerformance group --(L PERF)
EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'NotiGroup4', @Msg = @msg_LIC_dailyperf, @Title = @Title -- L-DailyPerformance group --(L PERF)
EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'vietgroup.UAT', @Msg = @msgLicMargin, @Title = @title -- UAT group --(Σ PERF)
