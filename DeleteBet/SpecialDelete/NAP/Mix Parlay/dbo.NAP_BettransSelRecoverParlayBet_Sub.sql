USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_BettransSelRecoverParlayBet_Sub]    Script Date: 10/11/2016 11:30:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_BettransSelRecoverParlayBet_Sub] 
	@BetType		VARCHAR(20) = 'all'
	,@MatchId		BIGINT			= 0	
	,@TransIds		VARCHAR(4000)	= ''
AS
/*
	Created: Kathy
	Date: 20131022
	DB: DBTXN/bodb02

	Revisions: 		
		- 20161011@Kent: Select sub voided Parlay tickets [Redmine:#65531]

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
		SubTransID				BIGINT		 
		,SubBetCheck			NVARCHAR(50)
		,SubOdds				MONEY   
		,SubBetTeam				NVARCHAR(20)  
		,SubBetType				INT  
		,SubHdp1				SMALLMONEY   
		,SubHdp2				SMALLMONEY	
		,SubTransDesc			NVARCHAR(200)	
		,SubLivehomescore		SMALLINT 
		,SubLiveawayscore		SMALLINT 
		,SubLiveindicator		BIT	
		,SubHomeID				INT 
		,SubAwayID				INT 
		,SubSportType			SMALLINT 
		,SubLeagueID			INT	
				
		,custid					INT
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
		,Stake					MONEY
		,Odds					MONEY		
		,hdp1					SMALLMONEY
		,hdp2					SMALLMONEY		 
		,betcheck				NVARCHAR(50)		
	)		
	DECLARE @tblTransIds TABLE (transid BIGINT)
	DECLARE @before_yesterday DATETIME	

	SELECT @before_yesterday = CONVERT(VARCHAR(10), DATEADD(day, - @beforeDaysNum, GETDATE()), 120)
	
	INSERT INTO @tblTransIds
	SELECT ss.val
	FROM dbo.strSplit(@TransIds, ',') ss				
	
	INSERT INTO @tblRecoverBet(
			 SubTransID			 
			,SubBetCheck	
			,SubOdds
			,SubBetTeam	
			,SubBetType
			,SubHdp1		
			,SubHdp2
			,SubTransDesc
			,SubLivehomescore 
			,SubLiveawayscore 
			,SubLiveindicator
			,SubHomeID
			,SubAwayID
			,SubSportType 
			,SubLeagueID
						
			,custid
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
			,Stake	
			,Odds			
			,hdp1
			,hdp2			 
			,betcheck)
	SELECT  bm.transid AS SubTransID			 
			,bm.betcheck AS SubBetCheck	
			,bm.odds AS SubOdds
			,bm.betteam AS SubBetTeam	
			,bm.bettype AS SubBetType
			,bm.hdp1 AS SubHdp1		
			,bm.hdp2 AS SubHdp2	
			,bm.transdesc AS SubTransDesc	
			,bm.livehomescore AS SubLivehomescore 
			,bm.liveawayscore AS SubLiveawayscore 
			,bm.liveindicator AS SubLiveindicator
			,m.homeid AS SubHomeID
			,m.awayid AS SubAwayID
			,m.sporttype AS SubSportType 
			,m.leagueid AS SubLeagueID				
						
			,b.custid AS custid
			,case when EXISTS (select TOP 1 1 from custDB.dbo.Dep_CustSuper with(nolock) WHERE custid = b.srecommend) then 1 else 0 end AS isdeposit
			,b.mrecommend AS mrecommend
			,b.recommend AS recommend
			,b.transid AS transid
			,b.Username AS UserName
			,b.transdate AS TransDate	
			,b.bettype AS BetType	
			,b.refno AS Refno	
			,b.[status] AS [Status]
			,b.winlost-b.actual_stake AS WinLost
			,b.betid AS betid	
			,b.betteam AS BetTeam												
			,b.stake AS Stake	
			,b.odds AS Odds			
			,b.hdp1 AS hdp1
			,b.hdp2 AS hdp2			 
			,b.betcheck AS betcheck			
	FROM @tblTransIds t
		INNER JOIN dbo.bettrans b WITH (NOLOCK)
				ON t.transid = b.transid			   
		INNER JOIN bettransm bm WITH (NOLOCK)
				ON b.refno = bm.refno				
		INNER JOIN dbo.match m WITH(NOLOCK)
				ON	m.matchid = bm.matchid			   
	WHERE	bm.matchid = @MatchId
			AND b.bettype = 29	
			AND bm.statusid = 102
			AND bm.winlostdate >= @before_yesterday
			AND (b.betfrom IS NULL OR b.betfrom <> 'p')
			AND (m.sporttype BETWEEN 1 AND 99)		
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
	SELECT	t.SubTransID     
			 ,t.SubBetCheck  
			 ,t.SubOdds      
			 ,t.SubBetTeam  
			 ,t.SubBetType     
			 ,t.SubHdp1       
			 ,t.SubHdp2 
			 ,t.SubTransDesc 
			 ,t.SubLivehomescore   
			 ,t.SubLiveawayscore 
			 ,t.SubLiveindicator 
			 ,t.SubHomeID
			 ,t.SubAwayID
			 ,t.SubSportType 
			 ,t.SubLeagueID  			 
			 ,SUBSTRING(g.GroupName, 3, 30) AS GroupName			 
			 ,t.transid    
			 ,t.UserName    
			 ,t.TransDate     
			 ,t.BetType    
			 ,t.Refno     
			 ,t.[Status]     
			 ,t.WinLost    
			 ,t.betid     
			 ,t.BetTeam    			   
			 ,t.Stake     
			 ,t.Odds     			     
			 ,t.hdp1     
			 ,t.hdp2     			 
			 ,t.betcheck			   
	FROM @tblRecoverBet t
		 INNER JOIN CTE_GroupInfo g
			     ON t.custid = g.custid										
	WHERE g.GroupName IS NOT NULL
	ORDER BY g.GroupName, t.transid				

	--- invalid trans info
	/*
	cases : 
		1/ transid in bettrans, subtransid in bettransm14 => isMoved = 1
		2/ transid in bettrans14, subtransid in bettransm14 => isMoved = 1
		3/ transid not in DB => isMoved = 0
		4/ transid in bettrans, subtransid in bettransm => valid
		5/ transid in bettrans14, subtransid in bettransm => isMoved = 1
	*/
	;WITH InvalidTransID AS
	(
		SELECT t.transid		 
		FROM @tblTransIds t
		WHERE NOT EXISTS (SELECT TOP 1 1 
						  FROM @tblRecoverBet 
						  WHERE transid = t.transid)
	),
	InvalidTransInfo AS
	(
		SELECT t.transid, ISNULL(b.refno, b14.refno) AS refno
		FROM InvalidTransID t
			 LEFT JOIN bettrans b WITH(NOLOCK)
					ON t.transid = b.transid
			 LEFT JOIN bettrans14 b14 WITH(NOLOCK)
					ON t.transid = b14.transid					
	)
	SELECT t.transid AS InvalidTrans
		 , CASE
				WHEN t.refno IS NULL THEN 0 -- case 3
				ELSE 1 -- case 1 + 2
		   END AS isMoved
	FROM InvalidTransInfo t		
END
GO

GO
GRANT EXECUTE ON [dbo].[NAP_BettransSelRecoverParlayBet_Sub] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_BettransSelRecoverParlayBet_Sub] TO [vnteam] AS [dbo]
