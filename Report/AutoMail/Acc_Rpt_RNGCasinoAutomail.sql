ALTER PROCEDURE [dbo].[Acc_Rpt_RNGCasinoAutomail]  
 @amount MONEY = 5000,  
 @fromdate DATETIME,  
 @todate DATETIME  
   
AS  

 
/* 
 Created: Dom 
 Date: 20140125 
 Task : RNG Casino Automail report 
 DB: DBACC.bodb02 
 Original: 
 
 Revisions: 
   - 20151026@Robert :Feature #41479 phase 2
   - 20160108@Percy: Add new range bettype for Casino [Redmine: #49134]
 Param's Explanation: 
  
*/
-- Get sport bettype
DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT,SubProduct VARCHAR(500), MatchID INT)
INSERT INTO @SportBettype (ProductID  , Bettype  ,EventType  ,SubProduct)
EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode = 5, @ProductID = 6

DELETE @SportBettype WHERE bettype = 72

UPDATE @SportBettype
SET MatchID = (CASE	WHEN Bettype BETWEEN 2101 AND 2199 THEN 208
					WHEN Bettype BETWEEN 2201 AND 2299 THEN 209
					WHEN Bettype BETWEEN 2301 AND 2399 THEN 210
					ELSE 0 END )-- 71


SELECT  username
       ,recommend
       ,currency
       ,transdate
       ,SUM(( winlost - actual_stake ) * actualrate) winlost_rm
       ,SUM( winlost - actual_stake ) winlost
INTO #temp
FROM bettrans b WITH (NOLOCK)
INNER JOIN @SportBettype s
	ON b.bettype = s.Bettype AND b.matchid = s.MatchID
WHERE transdate BETWEEN @FromDate AND @ToDate
       AND statusID IN (112, 113)
       AND srecommend NOT IN (SELECT custid FROM Dep_CustSuper (NOLOCK))
GROUP BY username
       ,recommend
       ,currency
       ,transdate
HAVING ABS(SUM(( winlost - actual_stake ) * actualrate)) >= @amount

SELECT t. username member
       ,t. transdate
       ,ca. currency
       ,ca. username agent
       ,winlost
       ,winlost_rm
FROM #temp t
INNER JOIN custInfo(NOLOCK ) ca ON ca.custid = t. recommend
ORDER BY t.transdate DESC

DROP TABLE #temp
GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_RNGCasinoAutomail] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_RNGCasinoAutomail] TO [vnteam] AS [dbo]
GO