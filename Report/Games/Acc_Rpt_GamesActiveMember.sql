USE [bodb02]
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

CREATE TABLE #tmpcust (CustID INT , gameName VARCHAR(10) PRIMARY KEY CLUSTERED (custid, gameName) )
CREATE TABLE #statistic (ID INT IDENTITY (1,1) ,MemberCount INT ,gameName VARCHAR(10))
DECLARE @result 	TABLE (ID INT IDENTITY(1,1),subID INT,combinations INT,NoActive INT,GameName VARCHAR(1000))
DECLARE @tmpBettype TABLE (bettype int , gameName VARCHAR(10) )
DECLARE @tmpSport	TABLE (sporttype INT, gameName VARCHAR(10))
DECLARE @Product    TABLE (ProductID INT, ProductPrefix VARCHAR(10))
INSERT INTO @Product (ProductID)
SELECT VAL FROM  dbo.strSplit(@ProductList,',')

UPDATE d
SET ProductPrefix = CASE s.ProductID WHEN 0 THEN 'MG' ELSE s.ProductPrefix END
FROM @Product d 
	INNER JOIN dbo.Products s WITH (NOLOCK) ON d.ProductId = s.ProductId
	
DECLARE @SportBettype TABLE(ProductID INT,Bettype INT,EventType INT,SubProduct VARCHAR(200))
INSERT INTO @SportBettype
EXEC dbo.Acc_SportBettypeMatrix_Sel @mode=5

INSERT INTO @tmpBettype 
	SELECT CASE p.ProductPrefix  WHEN  'GD'   THEN 1700
								 WHEN  'AGCS' THEN 1800
								 WHEN  'VG'	  THEN 1900	
									ELSE sb.Bettype END AS typeid 
		  ,p.ProductPrefix   
	FROM @SportBettype sb
		INNER JOIN @Product p ON sb.ProductID = p.ProductID
IF EXISTS (SELECT 1 FROM @Product WHERE ProductId =1 )	 
	BEGIN
		INSERT INTO @tmpBettype
		SELECT Bettype ,'MG'  
		FROM @SportBettype
		WHERE SubProduct='MG-SuperLive'
	END
	 
INSERT INTO @tmpSport
SELECT DISTINCT m.Sporttype
   ,p.ProductPrefix	
FROM dbo.SportBettypeMatrix m WITH (NOLOCK) 
INNER JOIN @Product p ON m.ProductID = p.ProductID
	
IF EXISTS (SELECT 1 FROM @Product WHERE ProductId =1 )	 
	BEGIN
		INSERT INTO @tmpSport
		SELECT 1, 'MG'	
	END
 

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
			
	INSERT INTO #tmpcust
	SELECT d.CustID,t.gameName
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
	SELECT d.CustID,t.gameName
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


INSERT INTO #statistic (MemberCount,GameName)
	SELECT COUNT(gameName),GameName 
	FROM #tmpCust
	GROUP BY GameName
----------show result
DECLARE @i INT
		,@j INT
		,@k INT	
		,@n INT
		,@NoActive INT
		,@GameName VARCHAR(100)
		 

SELECT @i =1 
	   ,@j = MAX(ID)
	   ,@k = 1	
	   ,@n=1		
FROM #statistic

INSERT INTO @result (subID,combinations  ,NoActive ,GameName  )
SELECT 
	0
	,1
	,MemberCount
	,GameName
FROM #statistic	

UPDATE @result
SET subID=ID

UPDATE d
SET GameName = s.ProductName
FROM @result d 
	INNER JOIN dbo.Products s ON d.GameName = s.ProductPrefix
 
SET @i=2
WHILE (1< @i and @i < = @j) 
BEGIN 
	WHILE (@k<=@j)
		BEGIN
				SELECT 	@NoActive = NoActive
						,@GameName = GameName
				FROM @result
				WHERE subID=@k
					 AND combinations=1
				WHILE (@n<=@j )
				BEGIN
					 INSERT INTO @result (subID,combinations  ,NoActive ,GameName  )
					 SELECT 
						@k
						,@i
						,@NoActive + NoActive
						, @GameName+'-'+GameName 
					FROM @result
					WHERE  subID = @k+@n 
							AND combinations=@i-1
					SET @n=@n+1	
				END
				SET @k=@k+1
				SET @n=1
		END	
	SET @i = @i+1
	SET @k=1		 
END

UPDATE @result
SET GameName = GameName +CHAR(13)+'(Only)'
WHERE combinations = 1

INSERT INTO @result (subID,combinations  ,NoActive ,GameName)
SELECT 1,12,SUM(NoActive),'Total Active Members'
FROM @result
WHERE combinations=1

SELECT Combinations
	   ,GameName
	   ,NoActive	 
FROM @result

DROP TABLE #tmpcust
DROP TABLE #statistic




GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_GamesActiveMember] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_GamesActiveMember] TO [vnteam] AS [dbo]