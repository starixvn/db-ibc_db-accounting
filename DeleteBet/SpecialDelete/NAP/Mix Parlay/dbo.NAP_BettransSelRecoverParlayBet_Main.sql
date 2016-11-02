USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_BettransSelRecoverParlayBet_Main]     Script Date: 10/11/2016 11:30:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_BettransSelRecoverParlayBet_Main] 
	@BetType		VARCHAR(20) = 'all'
	,@TransIds		VARCHAR(4000)	= ''
AS
/*
	Created: Kathy
	Date: 20131022
	DB: DBTXN/bodb02

	Revisions: 		
		- 20161011@Kent: Select main voided Parlay tickets [Redmine:#65531]

	Param's Explanation:			
			- @BetType:
			'all': All
			'Mix Parlay': Mix Parlay
			'System Parlay': System Parlay
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @beforeDaysNum INT = 2
	
	DECLARE @tblRecoverBet TABLE (		
		custid					INT
		,isdeposit				TINYINT
		,mrecommend				INT
		,recommend				INT
		,transid				BIGINT
		,UserName				VARCHAR(30)
		,TransDate				DATETIME 
		,BetType				SMALLINT
		,Refno					BIGINT
		,Status					NVARCHAR(10)
		,WinLost				MONEY
		,betid					BIGINT 
		,BetTeam				NVARCHAR(20)
		,livehomescore			SMALLINT 
		,liveawayscore			SMALLINT 
		,Stake					MONEY
		,Odds					MONEY		
		,hdp1					SMALLMONEY
		,hdp2					SMALLMONEY						
		,betcheck				NVARCHAR(50)
		,transdesc				NVARCHAR(200)
	)	
	DECLARE @tblTransIds TABLE (transid BIGINT)
	DECLARE @before_yesterday DATETIME	

	SELECT @before_yesterday = CONVERT(VARCHAR(10), DATEADD(day, - @beforeDaysNum, GETDATE()), 120)
	
	INSERT INTO @tblTransIds
	SELECT ss.val
	FROM dbo.strSplit(@TransIds, ',') ss					
			
	INSERT INTO @tblRecoverBet(			 							
			custid
			,isdeposit
			,mrecommend				
			,recommend				
			,transid
			,UserName
			,TransDate	
			,BetType	
			,Refno	
			,Status
			,WinLost
			,betid	
			,BetTeam
			,livehomescore 
			,liveawayscore 
			,Stake	
			,Odds			
			,hdp1
			,hdp2			
			,betcheck
			,transdesc)
	SELECT  z.custid AS custid
			,case when EXISTS (select TOP 1 1 from custDB.dbo.Dep_CustSuper with(nolock) WHERE custid = b.srecommend) then 1 else 0 end AS isdeposit
			,b.mrecommend AS mrecommend
			,b.recommend AS recommend
			,z.transid AS transid
			,b.Username AS UserName
			,b.transdate AS TransDate	
			,z.bettype AS BetType	
			,z.refno AS Refno	
			,z.[status] AS [Status]
			,z.winlost-b.actual_stake AS WinLost
			,b.betid AS betid	
			,z.betteam AS BetTeam
			,z.livehomescore AS livehomescore
			,z.liveawayscore AS liveawayscore 
			,z.stake AS Stake	
			,z.odds AS Odds			
			,z.hdp1 AS hdp1
			,z.hdp2 AS hdp2		
			,z.betcheck AS betcheck
			,b.transdesc AS transdesc
	FROM @tblTransIds t
		 INNER JOIN dbo.bettrans b WITH (NOLOCK)
				ON t.transid = b.transid	
		 INNER JOIN dbo.zzzbettrans z WITH (NOLOCK)
				ON	z.transid = b.transid
				AND z.matchid = b.matchid
				AND z.custid = b.custid	
				AND z.bettype = b.bettype
	WHERE b.bettype = 29	
		AND b.winlostdate >= @before_yesterday
		AND b.statusid = 102
		AND (b.betfrom IS NULL OR b.betfrom <> 'p')
		AND CASE
				WHEN @BetType = 'all' THEN 1
				WHEN @BetType = 'Mix Parlay' THEN CASE WHEN b.betteam = 1 THEN 1 ELSE 0 END
				WHEN @BetType = 'System Parlay' THEN CASE WHEN b.betteam = 1 THEN 0 ELSE 1 END
				ELSE 0
			END	= 1			
	
	-- UPDATE SiteName
	;WITH CustSiteName AS (
		SELECT DISTINCT ag.custid, ci.site, ci.srecommend, ci.mrecommend
		FROM CUSTDB.dbo.Customer ci WITH(NOLOCK)
			INNER JOIN @tblRecoverBet ag
			ON ci.custid = ag.recommend
		
	)
	--format group
	, CTE_GroupInfo AS (
		SELECT DISTINCT d.custid
			,cs.mrecommend
			,CASE WHEN s.custid IS NOT NULL THEN 1 ELSE 0 END AS IsDeposit
			,CASE 
				WHEN (
					d.recommend NOT IN (52466)
					AND d.custid NOT IN (1077687,2331,115770,15523642,15042477,16041068,16041058)
					AND s.custid IS NULL
				) THEN '0-Credit'
				WHEN d.recommend IN (52466) THEN '1-8RM'
				WHEN (
					d.recommend NOT IN (52466)
					AND d.custid NOT IN (1077687,2331,115770,15523642,15042477,16041068,16041058)
					AND s.custid IS NOT NULL
				) THEN '2-Deposit'
				WHEN d.custid IN (1077687,2331,115770,15523642,15042477,16041068,16041058) THEN '3-BetFair'
			END AS GroupName
		FROM @tblRecoverBet d
			INNER JOIN CustSiteName cs 
			ON d.custid = cs.custid
			LEFT JOIN CustDB.dbo.Dep_CustSuper s WITH(NOLOCK) 
			ON cs.srecommend = s.custid
	)
	SELECT	SUBSTRING(g.GroupName, 3, 30) AS GroupName			 
			 ,t.transid    
			 ,t.UserName    
			 ,t.TransDate     
			 ,t.BetType    
			 ,t.Refno     
			 ,t.[Status]     
			 ,t.WinLost    
			 ,t.betid     
			 ,t.BetTeam    
			 ,t.livehomescore   
			 ,t.liveawayscore   
			 ,t.Stake     
			 ,t.Odds			    
			 ,t.hdp1     
			 ,t.hdp2			    
			 ,t.betcheck    
			 ,t.transdesc    
	FROM @tblRecoverBet t
		 INNER JOIN CTE_GroupInfo g
				 ON t.custid = g.custid										
	WHERE g.GroupName IS NOT NULL
	ORDER BY g.GroupName, t.transid								

	--- invalid trans info
	SELECT t.transid AS InvalidTrans
		,CASE 
			WHEN t.transid IN (
					SELECT b14.transid
					FROM dbo.bettrans14 b14 WITH (NOLOCK)
					WHERE b14.transid = t.transid
					) THEN 1
			ELSE 0
			END AS isMoved
	FROM @tblTransIds t
	WHERE NOT EXISTS (SELECT TOP 1 1 FROM @tblRecoverBet r WHERE r.transid = t.transid)
END
GO

GO
GRANT EXECUTE ON [dbo].[NAP_BettransSelRecoverParlayBet_Main] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_BettransSelRecoverParlayBet_Main] TO [vnteam] AS [dbo]

