ALTER PROCEDURE [dbo].[Acc_Rpt_GamesActiveMember]  
 @fromdate datetime,  
 @todate datetime,  
 @BalanceUpDay datetime
AS  
/*  
 Created: Amy  
 Task : Retrieve Number of Active member for Games (Bingo, Number Game, Casino)  
 DB: DBAGE/bodb02  
 Original:  
  
 Revisions:      
    - 20110811@Johnson: Add more bettype for number game
    - 20110921@Johnson: Optimize peformance and re-calculate report
    - 20120231@Sophia: Add Live Casino
    - 20130121@Dan: add linked server DBSUM for bodb_Summary
*/  
  
SET NOCOUNT ON  

CREATE TABLE #tmpcust (CustID INT , gameName VARCHAR(10) PRIMARY KEY CLUSTERED (custid, gameName) )
CREATE TABLE #statistic (CustID INT PRIMARY KEY CLUSTERED, NG BIT , BG BIT , CS BIT, LC BIT)
DECLARE @tmpBettype TABLE (bettype int , gameName VARCHAR(10))
DECLARE @tmpSport	TABLE (sporttype INT, gameName VARCHAR(10))

INSERT INTO @tmpBettype 
	SELECT typeid, 'NG'
	FROM bettype WITH(NOLOCK)
	WHERE typeid BETWEEN 81 AND 120
UNION ALL
	SELECT 71, 'CS'
UNION ALL
	SELECT 73, 'BG'
UNION ALL
	SELECT typeid, 'LC'
	FROM bettype WITH(NOLOCK)
	WHERE typeid BETWEEN 1101 AND 1199
	

INSERT INTO @tmpSport
	SELECT 161, 'NG'
UNION
	SELECT 251, 'CS'
UNION 
	SELECT 252, 'BG'
UNION 
	SELECT 162, 'LC'

IF @Todate >= @BalanceUpDay  
BEGIN  	
	IF @BalanceUpDay < @FromDate   
		SELECT @BalanceUpDay=@FromDate  

	INSERT INTO #tmpcust		
		SELECT DISTINCT s.custid, t.gameName
		FROM sum_winloss s with(NOLOCK) 
			INNER JOIN @tmpSport t ON s.sporttype = t.sporttype
		WHERE roleid = 1 AND winlostdate BETWEEN @BalanceUpDay AND @Todate
			--AND NOT EXISTS (SELECT 1 FROM #tmpcust WHERE custid = s.custid AND gameName = t.gameName)
		
	INSERT INTO #tmpcust
		SELECT DISTINCT custid, gameName
		FROM bettrans b WITH(NOLOCK)
			INNER JOIN @tmpBettype t ON b.bettype = t.bettype
		WHERE winlostdate BETWEEN @fromdate and @todate
			AND NOT EXISTS (SELECT 1 FROM #tmpcust WHERE custid = b.custid AND gameName = t.gameName)
END  


IF @FromDate < @BalanceUpDay   
BEGIN  
	IF @todate >= DATEADD(dd, -1, @BalanceUpDay)  
	  SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay)  
    
	INSERT INTO #tmpcust 
		SELECT DISTINCT s.custid , t.gameName
		FROM DBSUM.bodb_Summary.dbo.sum_Winloss_old s WITH (nolock)  
			INNER JOIN @tmpSport t ON s.sporttype = t.sporttype
			WHERE s.roleid = 1 				
				AND winlostdate BETWEEN @fromdate AND @ToDate  
				AND NOT EXISTS(SELECT 1 FROM #tmpcust WHERE custid = s.custid and gameName = t.gameName)
END  

DELETE t
FROM #tmpCust t
	INNER JOIN custInfo ci WITH(NOLOCK) ON t.custid = ci.custid
WHERE roleid =1 AND (currency = 20 or username LIKE 'BIBET%'or username LIKE 'NUBET%' or username LIKE 'CASBET%' )


INSERT INTO #statistic 
	SELECT DISTINCT custid, 0 NG, 0 BG, 0 CS, 0 LC
	FROM #tmpCust

UPDATE #statistic 
SET NG = 1
WHERE custid IN (SELECT custid FROM #tmpCust WHERE gameName = 'NG')


UPDATE #statistic 
SET BG = 1
WHERE custid IN (SELECT custid FROM #tmpCust WHERE gameName = 'BG')


UPDATE #statistic 
SET CS = 1
WHERE custid IN (SELECT custid FROM #tmpCust WHERE gameName = 'CS')


UPDATE #statistic 
SET LC = 1
WHERE custid IN (SELECT custid FROM #tmpCust WHERE gameName = 'LC')


SELECT * 
FROM 
(
	SELECT count(1) as NoActive, 'Bingo (Only)' GameName
	FROM #statistic 
	WHERE BG =  1 AND NG = 0 AND CS = 0 AND LC = 0
UNION ALL
	SELECT count(1), 'Number Game(Only)'
	FROM #statistic
	WHERE NG = 1 AND BG = 0 AND CS = 0 AND LC = 0
UNION ALL
	SELECT count(1), 'Casino (Only)'
	FROM #statistic 
	WHERE CS =  1 AND NG = 0 AND BG = 0 AND LC = 0
UNION ALL
	SELECT count(1), 'Live Casino (Only)'
	FROM #statistic 
	WHERE LC =  1 AND NG = 0 AND BG = 0 AND CS = 0	
	
UNION ALL
	SELECT count(1), 'Number Game-Casino'
	FROM #statistic
	WHERE NG = 1 AND CS = 1 AND BG = 0 AND LC = 0
UNION ALL
	SELECT count(1), 'Number Game-Bingo'
	FROM #statistic
	WHERE NG = 1 AND BG = 1 AND CS = 0 AND LC = 0
UNION ALL
	SELECT count(1), 'Number Game-Live Casino'
	FROM #statistic
	WHERE NG = 1 AND LC = 1 AND CS = 0 AND BG = 0

UNION ALL
	SELECT count(1), 'Bingo-Casino'
	FROM #statistic
	WHERE BG = 1 AND CS = 1 AND NG = 0 AND LC = 0
UNION ALL
	SELECT count(1), 'Bingo-Live Casino'
	FROM #statistic
	WHERE BG = 1 AND LC = 1 AND NG = 0 AND CS = 0
		
UNION ALL
	SELECT count(1), 'Casino-Live Casino'
	FROM #statistic
	WHERE CS = 1 AND LC = 1 AND NG = 0 AND BG = 0
	
UNION ALL
	SELECT count(1), 'Number Game-Bingo-Casino-Live Casino'
	FROM #statistic
	WHERE NG = 1 AND CS = 1 AND BG = 1 AND LC = 1
	
UNION ALL
	SELECT count(1), 'Total Active Members'
	FROM #statistic
) r


DROP TABLE #tmpcust
DROP TABLE #statistic



GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_GamesActiveMember] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_GamesActiveMember] TO [vnteam]