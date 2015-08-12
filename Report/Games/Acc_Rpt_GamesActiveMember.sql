USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_Rpt_GamesActiveMember_xtest]    Script Date: 08/12/2015 13:49:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
ALTER PROCEDURE [dbo].[Acc_Rpt_GamesActiveMember]  
 @fromdate datetime,  
 @todate datetime,  
 @BalanceUpDay datetime,
  @ProductList VARCHAR(200)
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
	- 20150710@Jim:  Microgaming integration & Super Balance (Feature #38168)
Param's Explanation: 
	+ @ProductList : string, collect ProductID seperate by comma ',' .Eg: @ProductList ='0,3,4,6,7'	
*/  
  
SET NOCOUNT ON  

CREATE TABLE #tmpcust (CustID INT , gameName VARCHAR(20) PRIMARY KEY CLUSTERED (custid, gameName) )
CREATE TABLE #statistic (Id INT IDENTITY (1,1) ,CustId INT,MemberCount INT ,GameName VARCHAR(20))
DECLARE @result 	TABLE (ProductID INT,CustID INT,combinations INT,NoActive INT,GameName VARCHAR(1000))
DECLARE @tmpBettype TABLE (bettype int , gameName VARCHAR(20) )
DECLARE @tmpSport	TABLE (sporttype INT, gameName VARCHAR(20))
DECLARE @Product    TABLE (ID INT IDENTITY (1,1) , ProductID INT, ProductPrefix VARCHAR(10))
DECLARE @Product_Filter    TABLE (ProductID INT)
INSERT INTO @Product_Filter (ProductID)
SELECT VAL FROM  dbo.strSplit(@ProductList,',')

INSERT INTO @Product (ProductID,ProductPrefix)
SELECT ProductID,ProductPrefix
FROM dbo.Products WITH (NOLOCK)
WHERE ProductID IN (3,6,7,4,11,12,13,14)
 SELECT 
		p.ProductPrefix
	INTO #exProduct	
	FROM dbo.Products p  WITH (NOLOCK)
	LEFT JOIN @Product_Filter f ON p.ProductID = f.ProductID
	WHERE ISNULL(f.ProductID,0) = 0 
	
		IF EXISTS (SELECT 1 FROM @Product_Filter WHERE ProductID=-1)
		BEGIN
			DELETE #exProduct WHERE ProductPrefix = 'MGC'
		END	
		
UPDATE d
SET ProductPrefix  = s.ProductPrefix  
FROM @Product d 
	INNER JOIN dbo.Products s WITH (NOLOCK) ON d.ProductId = s.ProductId
UPDATE @Product
SET ProductPrefix = 'MG'
WHERE ProductID = -1	

DECLARE @SportBettype TABLE(ProductID INT,Bettype INT,EventType INT,SubProduct VARCHAR(200))
INSERT INTO @SportBettype
EXEC dbo.Acc_SportBettypeMatrix_Sel_xtest @mode=5

INSERT INTO @tmpBettype 
	SELECT CASE p.ProductPrefix  WHEN  'AGCS' THEN 1800
								 WHEN  'VG'	  THEN 1900	
									ELSE sb.Bettype END AS typeid 
		  ,p.ProductPrefix   
	FROM @SportBettype sb
		INNER JOIN @Product p ON sb.ProductID = p.ProductID

INSERT INTO @tmpBettype
SELECT Bettype ,'MG' 
FROM @SportBettype
WHERE SubProduct='MG-SuperLive'

	 
INSERT INTO @tmpSport
SELECT DISTINCT m.Sporttype
   ,p.ProductPrefix	
FROM dbo.SportBettypeMatrix m WITH (NOLOCK) 
INNER JOIN @Product p ON m.ProductID = p.ProductID

IF @Todate >= @BalanceUpDay  
BEGIN  	
	IF @BalanceUpDay < @FromDate   
		SELECT @BalanceUpDay=@FromDate  

	INSERT INTO #tmpcust		
		SELECT DISTINCT s.custid, t.gameName
		FROM sum_winloss s with(NOLOCK) 
			INNER JOIN @tmpSport t ON s.sporttype = t.sporttype
		WHERE roleid = 1 AND winlostdate BETWEEN @BalanceUpDay AND @Todate
			 AND NOT EXISTS (SELECT 1 FROM #tmpcust WHERE custid = s.custid AND gameName = t.gameName)
			
	INSERT INTO #tmpcust
		SELECT DISTINCT custid, gameName
		FROM bettrans b WITH(NOLOCK)
			INNER JOIN @tmpBettype t ON b.bettype = t.bettype
		WHERE winlostdate BETWEEN @fromdate and @todate
			AND NOT EXISTS (SELECT 1 FROM #tmpcust WHERE custid = b.custid AND gameName = t.gameName)
			
	INSERT INTO #tmpcust
	SELECT DISTINCT d.CustID,t.gameName
	FROM DBWH.bodb_account.dbo.mcCustBettingDaily d WITH (NOLOCK)			
		INNER JOIN @tmpBettype t ON d.bettype=t.bettype 
		WHERE t.gameName='MG'
			  AND d.rptDate BETWEEN @BalanceUpDay   AND @ToDate  
			  AND NOT EXISTS(SELECT 1 FROM #tmpcust s WHERE custid = s.custid and gameName = t.gameName)		
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
	INSERT INTO #tmpcust
	SELECT DISTINCT d.CustID,t.gameName
	FROM DBWH.bodb_account.dbo.mcCustBettingDaily d WITH (NOLOCK)			
		INNER JOIN @tmpBettype t ON d.bettype=t.bettype 
		WHERE t.gameName='MG'
			  AND d.rptDate >= @fromdate AND d.rptDate < @BalanceUpDay
			  AND NOT EXISTS(SELECT 1 FROM #tmpcust s WHERE custid = s.custid and gameName = t.gameName)
END  

DELETE t
FROM #tmpCust t
	INNER JOIN custInfo ci WITH(NOLOCK) ON t.custid = ci.custid
WHERE roleid =1 AND (currency = 20 or username LIKE 'BIBET%'or username LIKE 'NUBET%' or username LIKE 'CASBET%' )
--/*
SELECT CustID
	   ,GameName
	   INTO #Result
FROM #tmpCust	   
WHERE CustID NOT IN (SELECT CustID 
					FROM #tmpCust c
					 WHERE GameName IN (SELECT ProductPrefix FROM #exProduct)
					)
---*/
INSERT INTO #statistic (CustID,MemberCount,GameName)
	SELECT CustID,COUNT(gameName),GameName 
	FROM #Result
	GROUP BY CustID,GameName
SELECT
	a.CustID
	,a.MemberCount
	,CASE a.GameName WHEN 'MG' THEN '-1' ELSE CONVERT(VARCHAR(3),p.ProductId) END ProductId 
	,a.GameName ProductPrefix
	,CASE a.GameName WHEN 'MG' THEN 'MG-SuperLive' ELSE p.ProductName END GameName
FROM #statistic a 
LEFT JOIN dbo.Products p ON a.gameName=p.ProductPrefix 

  
 
DROP TABLE #tmpcust
DROP TABLE #statistic
DROP TABLE #exProduct 
DROP TABLE #Result

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_GamesActiveMember] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_GamesActiveMember] TO [vnteam] AS [dbo]