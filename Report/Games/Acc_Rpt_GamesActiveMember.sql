USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_Rpt_GamesActiveMember]    Script Date: 09/09/2014 10:21:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
    - 20140909@Daniel: include 3-Games combinations
	- 20150529@Jim: support GD,MG and apply sport-bettype matrix
*/  
  
SET NOCOUNT ON  

CREATE TABLE #tmpcust (CustID INT , gameName VARCHAR(10) PRIMARY KEY CLUSTERED (custid, gameName) )
CREATE TABLE #statistic (CustID INT PRIMARY KEY CLUSTERED, NG BIT , BG BIT , CS BIT, LC BIT, GD BIT, MG BIT)
DECLARE @tmpBettype TABLE (bettype int , gameName VARCHAR(10))
DECLARE @tmpSport	TABLE (sporttype INT, gameName VARCHAR(10))

DECLARE @SportBettype TABLE(ProductID INT,Bettype INT,EventType INT,SubProduct VARCHAR(200))
INSERT INTO @SportBettype
EXEC dbo.Acc_SportBettypeMatrix_Sel @mode=5

INSERT INTO @tmpBettype 
	SELECT Bettype AS typeid , 'NG'   
	FROM @SportBettype   
	WHERE ProductID =3
	 
UNION ALL
	SELECT Bettype, 'CS' 
	FROM @SportBettype   
	WHERE ProductID = 6
	 
UNION ALL
	SELECT Bettype, 'BG'   
	FROM @SportBettype   
	WHERE ProductID = 7
	 
UNION ALL
	SELECT Bettype ,'LC'  
	FROM @SportBettype   
	WHERE ProductID = 4
UNION ALL
	SELECT Bettype ,'GD'  
	FROM @SportBettype   
	WHERE ProductID = 12	
UNION ALL 
	SELECT Bettype ,'MG'  
	FROM @SportBettype
	WHERE SubProduct='MG-SuperLive'
INSERT INTO @tmpSport
	SELECT 161, 'NG'
UNION
	SELECT 251, 'CS'
UNION 
	SELECT 252, 'BG'
UNION 
	SELECT 162, 'LC'
UNION 
	SELECT 255, 'GD'
UNION 
	SELECT 1, 'MG'	

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
	SELECT DISTINCT custid, 0 NG, 0 BG, 0 CS, 0 LC , 0 GD, 0 MG
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

UPDATE #statistic 
SET GD = 1
WHERE custid IN (SELECT custid FROM #tmpCust WHERE gameName = 'GD')

UPDATE #statistic 
SET MG = 1
WHERE custid IN (SELECT custid FROM #tmpCust WHERE gameName = 'MG')

SELECT * 
FROM 
(
	SELECT count(1) as NoActive, 'Bingo (Only)' GameName
	FROM #statistic 
	WHERE BG =  1 AND NG = 0 AND CS = 0 AND LC = 0 AND GD = 0 AND MG = 0
UNION ALL
	SELECT count(1), 'Number Game(Only)'
	FROM #statistic
	WHERE NG = 1 AND BG = 0 AND CS = 0 AND LC = 0 AND GD = 0 AND MG = 0
UNION ALL
	SELECT count(1), 'Casino (Only)'
	FROM #statistic 
	WHERE CS =  1 AND NG = 0 AND BG = 0 AND LC = 0 AND GD = 0 AND MG = 0
UNION ALL
	SELECT count(1), 'Live Casino (Only)'
	FROM #statistic 
	WHERE LC =  1 AND NG = 0 AND BG = 0 AND CS = 0 AND GD = 0 AND MG = 0
UNION ALL
	SELECT count(1), 'Gold Deluxe (Only)'
	FROM #statistic 
	WHERE LC =  0 AND NG = 0 AND BG = 0 AND CS = 0 AND GD = 1 AND MG = 0
UNION ALL
	SELECT count(1), 'Metric Gaming - Super Live (Only)'
	FROM #statistic 
	WHERE LC =  0 AND NG = 0 AND BG = 0 AND CS = 0 AND GD = 0 AND MG = 1	
--2-games combinations:	
UNION ALL
	SELECT count(1), 'Number Game-Casino'
	FROM #statistic
	WHERE NG = 1 AND CS = 1 AND BG = 0 AND LC = 0 AND GD = 0 AND MG = 0
UNION ALL
	SELECT count(1), 'Number Game-Bingo'
	FROM #statistic
	WHERE NG = 1 AND BG = 1 AND CS = 0 AND LC = 0 AND GD = 0 AND MG = 0
UNION ALL
	SELECT count(1), 'Number Game-Live Casino'
	FROM #statistic
	WHERE NG = 1 AND LC = 1 AND CS = 0 AND BG = 0 AND GD = 0 AND MG = 0
	
UNION ALL
	SELECT count(1), 'Bingo-Casino'
	FROM #statistic
	WHERE BG = 1 AND CS = 1 AND NG = 0 AND LC = 0 AND GD = 0 AND MG = 0
UNION ALL
	SELECT count(1), 'Bingo-Live Casino'
	FROM #statistic
	WHERE BG = 1 AND LC = 1 AND NG = 0 AND CS = 0 AND GD = 0 AND MG = 0
		
UNION ALL
	SELECT count(1), 'Casino-Live Casino'
	FROM #statistic
	WHERE CS = 1 AND LC = 1 AND NG = 0 AND BG = 0 AND GD = 0 AND MG = 0  
--3-games combinations:
UNION ALL
	SELECT count(1), 'Casino-Live Casino-Number Game'
	FROM #statistic
	WHERE CS = 1 AND LC = 1 AND NG = 1 AND BG = 0 AND GD = 0 AND MG = 0 
UNION ALL
	SELECT count(1), 'Casino-Live Casino-Bingo'
	FROM #statistic
	WHERE CS = 1 AND LC = 1 AND NG = 0 AND BG = 1 AND GD = 0 AND MG = 0 
UNION ALL
	SELECT count(1), 'Casino-Number Game-Bingo'
	FROM #statistic
	WHERE CS = 1 AND LC = 0 AND NG = 1 AND BG = 1 AND GD = 0 AND MG = 0 
UNION ALL
	SELECT count(1), 'Live Casino-Number Game-Bingo'
	FROM #statistic
	WHERE CS = 0 AND LC = 1 AND NG = 1 AND BG = 1 AND GD = 0 AND MG = 0 
--end of 3 -games combinations ------------------------------
UNION ALL
	SELECT count(1), 'Number Game-Bingo-Casino-Live Casino'
	FROM #statistic
	WHERE NG = 1 AND CS = 1 AND BG = 1 AND LC = 1 AND GD = 0 AND MG = 0 
	
UNION ALL
	SELECT count(1), 'Total Active Members'
	FROM #statistic
) r


DROP TABLE #tmpcust
DROP TABLE #statistic




GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_GamesActiveMember] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_GamesActiveMember] TO [vnteam] AS [dbo]