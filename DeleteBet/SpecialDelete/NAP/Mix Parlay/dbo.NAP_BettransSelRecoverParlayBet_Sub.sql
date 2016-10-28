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
		,livehomescore			SMALLINT 
		,liveawayscore			SMALLINT 
		,Stake					MONEY
		,Odds					MONEY
		,OddsType				TINYINT
		,hdp1					SMALLMONEY
		,hdp2					SMALLMONEY
		,homeid					INT 
		,awayid					INT 
		,sporttype				SMALLINT 
		,leagueid				INT 
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
			 SubTransID			 
			,SubBetCheck	
			,SubOdds
			,SubBetTeam	
			,SubBetType
			,SubHdp1		
			,SubHdp2						
						
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
			,livehomescore 
			,liveawayscore 
			,Stake	
			,Odds
			,OddsType
			,hdp1
			,hdp2
			,homeid	
			,awayid 
			,sporttype 
			,leagueid 
			,betcheck
			,transdesc)
	SELECT  bm.transid AS SubTransID			 
			,bm.betcheck AS SubBetCheck	
			,bm.odds AS SubOdds
			,bm.betteam AS SubBetTeam	
			,bm.bettype AS SubBetType
			,bm.hdp1 AS SubHdp1		
			,bm.hdp2 AS SubHdp2						
						
			,b.custid AS custid
			,case when EXISTS (select TOP 1 1 from custDB.dbo.Dep_CustSuper with(nolock) WHERE custid = b.srecommend) then 1 else 0 end AS isdeposit
			,b.mrecommend AS mrecommend
			,b.recommend AS recommend
			,b.transid AS transid
			,b.Username AS UserName
			,b.transdate AS TransDate	
			,b.bettype AS BetType	
			,bm.refno AS Refno	
			,b.[status] AS [Status]
			,b.winlost-b.actual_stake AS WinLost
			,b.betid AS betid	
			,b.betteam AS BetTeam
			,b.livehomescore AS livehomescore 
			,b.liveawayscore AS liveawayscore 
			,b.stake AS Stake	
			,b.odds AS Odds
			,b.OddsType AS OddsType
			,b.hdp1 AS hdp1
			,b.hdp2 AS hdp2
			,m.homeid AS homeid	
			,m.awayid AS awayid 
			,m.sporttype AS sporttype 
			,m.leagueid AS leagueid 
			,b.betcheck AS betcheck
			,bm.transdesc AS transdesc
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
			AND b.winlostdate >= @before_yesterday
			AND (b.betfrom IS NULL OR b.betfrom <> 'p')
			AND (m.sporttype BETWEEN 1 AND 99 OR m.sporttype = 154)		
			AND CASE
					WHEN @BetType = 'all' THEN 1
					WHEN @BetType = 'Mix Parlay' THEN CASE WHEN b.betteam = 1 THEN 1 ELSE 0 END
					WHEN @BetType = 'System Parlay' THEN CASE WHEN b.betteam = 1 THEN 0 ELSE 1 END
					ELSE 0
				END	= 1													
	
	SELECT	t.SubTransID     
			 ,t.SubBetCheck  
			 ,t.SubOdds      
			 ,t.SubBetTeam  
			 ,t.SubBetType     
			 ,t.SubHdp1       
			 ,t.SubHdp2     
			 
			 ,T1.GroupName
			 
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
			 ,t.OddsType    
			 ,t.hdp1     
			 ,t.hdp2     
			 ,t.homeid     
			 ,t.awayid     
			 ,t.sporttype    
			 ,t.leagueid    
			 ,t.betcheck    
			 ,t.transdesc    
	FROM	@tblRecoverBet t		
		LEFT JOIN dbo.f_GetBetDaqCustomer(1) f
			ON t.custid = f.CustID
		CROSS APPLY (SELECT CASE
								WHEN f.CustID IS NULL
									AND t.username <> '12EU'
									AND t.IsDeposit = 0
									AND t.mrecommend NOT IN (105181, 118473, 105183) -- MHC
									AND t.recommend NOT IN (11196380, 13423967, 52466) -- Foobet, 1E, 8RM
									AND t.custid NOT IN (1077687,2331,115770,15523642,15042477,16041068,16041058)
										THEN 'Credit' --1. For Normal bets
								WHEN t.recommend = 52466
										THEN '8RM' ----2: For 8RM
								WHEN f.CustID IS NULL -- Betdaq
									AND t.username <> '12EU' 
									AND t.IsDeposit = 1	
									AND t.mrecommend NOT IN (105181, 118473, 105183)
									AND t.recommend NOT IN (11196380, 13423967, 52466) -- Foobet: 11196380, 1E: 13423967, 8RM: 52466
									AND t.custid NOT IN (1077687,2331,115770,15523642,15042477,16041068,16041058) -- Betfair: BFOS, BF, ITibc102, BF3
										THEN 'Deposit' ----3. For Deposit bets
								WHEN t.custid IN (1077687,2331,115770,15523642,15042477,16041068,16041058) -- Betfair: BFOS, BF, ITibc102, BF3
										THEN 'Betfair' ----8: For Betfair
								ELSE NULL
						  END AS GroupName) AS T1								
	WHERE T1.GroupName IS NOT NULL				

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
GRANT EXECUTE ON [dbo].[NAP_BettransSelRecoverParlayBet_Sub] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_BettransSelRecoverParlayBet_Sub] TO [vnteam] AS [dbo]
