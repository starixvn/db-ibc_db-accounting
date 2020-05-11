-- if before 2AM (server time), get yesterday's data. otherwise, get today's data instead
DECLARE @dayOffset int = CASE WHEN DATEPART (hour, CURRENT_TIMESTAMP) >= 2 THEN 0 ELSE -1 END

DECLARE @wldate smalldatetime = DATEADD(dd, DATEDIFF(dd, 0, CURRENT_TIMESTAMP), @dayOffset)
DECLARE @msg VARCHAR(max) = ''

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
	Site VARCHAR(50), TurnOver	MONEY, Margin MONEY, HouseWinlost MONEY, isDeposit smallint
)

INSERT INTO #tmpResetWinning (Site, TurnOver, Margin, HouseWinlost, isDeposit)
EXEC Acc_ResetWinning_MarginBySite @Winlostdate = @wldate

DECLARE @WLBySite as TABLE (S varchar(30), WL money, MG MONEY, rn int)
INSERT INTO @WLBySite(S, MG, WL, rn)
SELECT  S = CASE 
				WHEN Site IN ('BEST-ODDS','XYZBET') THEN 'XYZ & Bestodds'
				WHEN Site IN ('611111') THEN '611 (China)'
				WHEN Site IN ('733333') THEN '733 (Malaysia)'
				WHEN Site IN ('755555') THEN '755 (Thailand)'
				WHEN Site IN ('INDO') THEN 'Indo'
				WHEN Site IN ('722222','222223','222225','222227','spotico','KORIBC','766666','7aa666') THEN 'Others'
				WHEN Site IN ('789y', 'y987') THEN '789Y'
			ELSE 'CASH' END			
		,WL = -SUM(ISNULL(HouseWinlost,0)) 
		,MG = CASE WHEN SUM (ISNULL(TurnOver,0)) = 0 THEN 0 ELSE -SUM(ISNULL(HouseWinlost,0))/SUM (ISNULL(TurnOver,0)) * 100 END
		,rn = CASE 
				WHEN Site IN ('BEST-ODDS','XYZBET') THEN 1
				WHEN Site IN ('611111') THEN 2
				WHEN Site IN ('733333') THEN 3
				WHEN Site IN ('755555') THEN 4
				WHEN Site IN ('INDO') THEN 5
				WHEN Site IN ('722222','222223','222225','222227','spotico','KORIBC','766666','7aa666') THEN 6
				WHEN Site IN ('789y', 'y987') THEN 7
			ELSE 8 END
FROM #tmpResetWinning
WHERE SITE NOT IN ('CN88')
GROUP BY CASE 
				WHEN Site IN ('BEST-ODDS','XYZBET') THEN 'XYZ & Bestodds'
				WHEN Site IN ('611111') THEN '611 (China)'
				WHEN Site IN ('733333') THEN '733 (Malaysia)'
				WHEN Site IN ('755555') THEN '755 (Thailand)'
				WHEN Site IN ('INDO') THEN 'Indo'
				WHEN Site IN ('722222','222223','222225','222227','spotico','KORIBC','766666','7aa666') THEN 'Others'
				WHEN Site IN ('789y', 'y987') THEN '789Y'
			ELSE 'CASH' END
		,CASE 
				WHEN Site IN ('BEST-ODDS','XYZBET') THEN 1
				WHEN Site IN ('611111') THEN 2
				WHEN Site IN ('733333') THEN 3
				WHEN Site IN ('755555') THEN 4
				WHEN Site IN ('INDO') THEN 5
				WHEN Site IN ('722222','222223','222225','222227','spotico','KORIBC','766666','7aa666') THEN 6
				WHEN Site IN ('789y', 'y987') THEN 7
			ELSE 8 END

-- generate string for winlost by site
SELECT @msg = @msg + '<br>' + S + ': '
		+ CASE WHEN ABS(WL) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),WL/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),WL/1000) as VARCHAR(10)) + 'k' END 	
		+ ' ' + CAST(CONVERT(DECIMAL(10,2), MG) as VARCHAR(10)) + '%'	
FROM @WLBySite
ORDER BY rn

---- generate string for TOTAL (w/o CN88)
--SELECT @msg = @msg + '<br>--<br>TOTAL (w/o CN88): ' 
--		+ CASE WHEN ABS(SUM(WL)) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),SUM(WL)/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),SUM(WL)/1000) as VARCHAR(10)) + 'k' END 
--		+ 
--		+ '<br>'
--FROM @WLBySite

-- generate string for CN88
SELECT @msg = @msg + '<br>**CN88: '
		+ CASE WHEN ABS(SUM(-ISNULL(HouseWinlost,0))) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),SUM(-ISNULL(HouseWinlost,0))/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),SUM(-ISNULL(HouseWinlost,0))/1000) as VARCHAR(10)) + 'k' END 
		+ ' ' + CAST(CONVERT(DECIMAL(10,2), SUM(-ISNULL(Margin,0))) as VARCHAR(10)) + '%'	
		--+ '<br>'
FROM #tmpResetWinning
WHERE Site IN ('CN88')

DROP TABLE #tmpResetWinning


CREATE TABLE #tmpMargin (
	SportName VARCHAR(50), TurnOver	MONEY, Margin MONEY, HouseWinlost MONEY
)

INSERT INTO #tmpMargin (SportName, TurnOver, Margin, HouseWinlost)
EXEC Acc_ResetWinning_MarginBySport @Winlostdate = @wldate

SELECT @msg = @msg + '<br>------------------<br>[Sports TO & Margin]'

-- generate string for TO & Margin
SELECT @msg = @msg + '<br>' + SportName + ': '
		+ CASE WHEN ABS(TurnOver) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),TurnOver/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),TurnOver/1000) as VARCHAR(10)) + 'k' END 		
		+ ' ' + CAST(CONVERT(DECIMAL(10,2), -Margin) as VARCHAR(10)) + '%'		
FROM #tmpMargin

DROP TABLE #tmpMargin


--
-- non sports
CREATE TABLE #tmpMarginNonSport (
	ProductName VARCHAR(50), TurnOver MONEY, Margin MONEY, HouseWinlost MONEY
)

INSERT INTO #tmpMarginNonSport (ProductName, TurnOver, Margin, HouseWinlost)
EXEC Acc_ResetWinning_MarginByNonSport @Winlostdate = @wldate

UPDATE #tmpMarginNonSport
SET ProductName = 'Saba Club'
WHERE ProductName = 'Saba.club'

SELECT @msg = @msg + '<br>------------------<br>[NonSports TO & Margin]'

-- generate string for TO & Margin
SELECT @msg = @msg + '<br>' + ProductName + ': '
		+ CASE WHEN ABS(TurnOver) > 1000000 THEN CAST(CONVERT(DECIMAL(10,1),TurnOver/1000000) as VARCHAR(10)) + 'm' ELSE CAST(CONVERT(DECIMAL(10,0),TurnOver/1000) as VARCHAR(10)) + 'k' END 		
		+ ' ' + CAST(CONVERT(DECIMAL(10,2), -Margin) as VARCHAR(10)) + '%'		
FROM #tmpMarginNonSport
ORDER BY TurnOver DESC

DROP TABLE #tmpMarginNonSport
---

DECLARE @letstalkNewLine varchar(1000) = ' 
'
SET @msg = replace(@msg, '<br>', @letstalkNewLine)


Select  @msg 
-- send letstalk's message
---EXECUTE	DBSPARE.NotificationDB.dbo.Letstalk_SendMessage @To = 'vietgroup.UAT', @Msg = @msg, @Title = @title -- UAT group