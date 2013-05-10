ALTER PROCEDURE [dbo].[Acc_Rpt_GamesActiveMember]  
 @fromdate datetime,  
 @todate datetime,  
 @BalanceUpDay datetime
AS  
/*  
 Created: Amy  
 Task : Retrieve Number of Active member for Games (Bingo, Number Game, Casino)  
 DB: DB052.bodb02  
 Original:  
  
 Revisions:      
    
*/  
  
SET NOCOUNT ON  
  
CREATE TABLE #Bingo_tmp(CustID int PRIMARY KEY CLUSTERED)
CREATE TABLE #NumberGame_tmp(CustID int PRIMARY KEY CLUSTERED)
CREATE TABLE #Casino_tmp(CustID int PRIMARY KEY CLUSTERED)
create table #excustids (custid int PRIMARY KEY CLUSTERED)

INSERT INTO #excustids
SELECT custid FROM custinfo WITH (nolock) 
WHERE roleid = 1 
	AND(currency = 20 or username LIKE 'BIBET%'or username LIKE 'NUBET%' or username LIKE 'CASBET%')
  

IF @Todate >= @BalanceUpDay  
BEGIN  
	INSERT INTO #NumberGame_tmp(Custid)
	SELECT distinct custid FROM bettrans WITH (nolock)  
			WHERE bettype BETWEEN 81 AND 87
				AND winlostdate BETWEEN @fromdate AND @todate

	INSERT INTO #Casino_tmp(Custid)
	SELECT distinct custid FROM bettrans WITH (nolock)  
			WHERE bettype=71 AND MATCHID=0 AND winlostdate BETWEEN @fromdate AND @todate

 	INSERT INTO #Bingo_tmp(Custid)
		SELECT distinct custid FROM bettrans WITH (nolock)  
			WHERE bettype =73 AND MATCHID=0 AND winlostdate BETWEEN @fromdate AND @todate 
       
 IF @BalanceUpDay < @FromDate   
  SELECT @BalanceUpDay=@FromDate  
   
 INSERT INTO #NumberGame_tmp(Custid)  
 SELECT distinct s.custid FROM sum_Winloss s WITH (nolock)  
		WHERE s.roleid = 1 AND sporttype = 161 AND winlostdate BETWEEN @BalanceUpDay AND @Todate
			AND s.custid NOT IN (SELECT custid FROM #NumberGame_tmp)

  INSERT INTO #Casino_tmp(Custid)
		SELECT distinct s.custid FROM sum_Winloss s WITH (nolock)  
		WHERE s.roleid = 1 AND sporttype = 251 AND winlostdate BETWEEN @BalanceUpDay AND @Todate
			AND s.custid NOT IN (SELECT custid FROM #Casino_tmp)

  INSERT INTO #Bingo_tmp(Custid)   
		SELECT distinct s.custid FROM sum_Winloss s WITH (nolock)  
		WHERE s.roleid = 1 AND sporttype = 252 AND winlostdate BETWEEN @BalanceUpDay AND @Todate  
			AND s.custid NOT IN (SELECT custid FROM #Bingo_tmp)
END  
  
IF @FromDate < @BalanceUpDay   
BEGIN  
 IF @todate >= DATEADD(dd, -1, @BalanceUpDay)  
  SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay)  
    
    INSERT INTO #NumberGame_tmp(Custid)    
	SELECT distinct s.custid FROM bodb_Summary.dbo.sum_Winloss_old s WITH (nolock)  
			WHERE s.roleid = 1 AND sporttype = 161 AND winlostdate between @fromdate and @ToDate  
				AND s.custid NOT IN (SELECT custid FROM #NumberGame_tmp)

	INSERT INTO #Casino_tmp(Custid) 
	SELECT distinct s.custid FROM bodb_Summary.dbo.sum_Winloss_old s WITH (nolock)  
			WHERE s.roleid = 1 AND sporttype = 251 AND winlostdate between @fromdate and @ToDate  
				AND s.custid NOT IN (SELECT custid FROM #Casino_tmp)

	INSERT INTO #Bingo_tmp(Custid)  
	SELECT distinct s.custid FROM bodb_Summary.dbo.sum_Winloss_old s WITH (nolock)  
			WHERE s.roleid = 1 AND sporttype = 252 AND winlostdate between @fromdate and @ToDate  
				AND s.custid NOT IN (SELECT custid FROM #Bingo_tmp)
       
END  

DELETE #Bingo_tmp WHERE custid IN(select custid from #excustids)
DELETE #NumberGame_tmp WHERE custid IN(select custid from #excustids)
DELETE #Casino_tmp WHERE custid IN(select custid from #excustids)

DECLARE @rpt table (NoActive int,Gamename nvarchar(100))
INSERT @rpt(NoActive,Gamename)

SELECT  count(*),'Bingo' FROM #Bingo_tmp
UNION ALL
SELECT  count(*),'Number Game' FROM #NumberGame_tmp
UNION ALL
SELECT  count(*),'Casino' FROM #Casino_tmp
UNION ALL
SELECT count(distinct n.custid),'Number Game - Casino' FROM #NumberGame_tmp n
INNER JOIN #Casino_tmp c on n.custid=c.custid
UNION ALL
SELECT count(distinct b.custid),'Number Game - Bingo' FROM #Bingo_tmp b
INNER JOIN #NumberGame_tmp c on b.custid=c.custid
UNION ALL
SELECT count(distinct b.custid),'Bingo - Casino' FROM #Bingo_tmp b
INNER JOIN #Casino_tmp c on b.custid=c.custid
UNION ALL
SELECT count(distinct c.custid),'Bingo - Number Game - Casino' FROM #NumberGame_tmp n 
INNER JOIN #Casino_tmp c on n.custid=c.custid
INNER JOIN #Bingo_tmp b on b.custid=c.custid

SELECT * FROM @rpt

DROP TABLE #excustids
DROP TABLE #Bingo_tmp
DROP TABLE #NumberGame_tmp
DROP TABLE #Casino_tmp  
  
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_GamesActiveMember] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_GamesActiveMember] TO [vnteam]