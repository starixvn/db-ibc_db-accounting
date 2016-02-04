ALTER PROCEDURE [dbo].[Acc_Rpt_RNGCasinoAutomail_Recent]
 @amount MONEY = 5000,
 @fromdate DATETIME,
 @todate DATETIME
 
AS

--declare
-- @amount MONEY ,
-- @fromdate DATETIME,
-- @todate DATETIME
 
--select
-- @amount = 1,
-- @fromdate = '2015-08-01',
-- @todate = '2015-08-31'

/*
 Created: Robert
 Date: 20151001
 Task :#41479 - Big Win/Loss Members on RnG product
 DB: DBACC.bodb02
 Original:
	
 Revisions:
	-20151015@Robert: revise sp
	- 20160108@Percy: Add new range bettype for Casino [Redmine: #49134]
  
 Param's Explanation:
 
*/
IF ISNULL(@amount,0)=0
	RETURN;
ELSE 
BEGIN

	-- Get sport bettype
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT, MatchID INT)
	INSERT INTO @SportBettype (ProductID  , Bettype  ,EventType)
		EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode = 4, @ProductID = 6

	DELETE @SportBettype WHERE bettype = 72

	UPDATE @SportBettype
	SET MatchID = (CASE	WHEN Bettype BETWEEN 2101 AND 2199 THEN 208
						WHEN Bettype BETWEEN 2201 AND 2299 THEN 209
						WHEN Bettype BETWEEN 2301 AND 2399 THEN 210
						ELSE 0 END )-- 71
	SELECT username,
			recommend,
			currency,
			DATEADD( Hour, DATEDIFF(Hour , 0, transdate), 0) AS [Truncate],
			SUM((winlost-actual_stake)*actualrate) AS winlost_rm,
			SUM(winlost-actual_stake) AS winlost
			INTO #temp
	FROM dbo.bettrans b WITH (NOLOCK)
	INNER JOIN @SportBettype s ON b.bettype = s.bettype AND b.matchid = s.MatchID
	WHERE transdate BETWEEN @FromDate and @ToDate
		AND statusID IN (112,113) 
		AND srecommend NOT IN (SELECT custid FROM dbo.Dep_CustSuper WITH (NOLOCK))
	GROUP BY username
		,recommend
		,currency
		,DATEADD( Hour, DATEDIFF(Hour , 0, transdate), 0)
	HAVING ABS(SUM((winlost-actual_stake)*actualrate)) >= @amount

	SELECT t.username  AS member
			,ca.currency
			,ca.username AS agent
			,winlost
			,winlost_rm
			,COUNT(*) NumOfBets
			,[Truncate]
	FROM #temp t
	INNER JOIN dbo.custInfo ca WITH (NOLOCK)  ON ca.custid = t.recommend
	GROUP BY t.username   
			,ca.currency
			,ca.username  
			,winlost
			,winlost_rm
			,[Truncate]
	ORDER BY [Truncate] DESC
	DROP TABLE #temp
END
GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_RNGCasinoAutomail_Recent] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_RNGCasinoAutomail_Recent] TO [vnteam] AS [dbo]
GO