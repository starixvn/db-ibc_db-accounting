ALTER PROCEDURE [dbo].[Acc_IOM_BettransSelSpecialDel_EarlyKO]
	@MatchID int,  
	@KickOffDate datetime,
	@hdp smallmoney = 9999,  
	--@liveindicator int = 0,  
	@bettypes varchar(128) = '',   
	@betteam1378 varchar(10) = 'ALL',  
	@betteam515 varchar(10) = 'ALL',  
	@betteam430 varchar(120) = '',
	@betteam6 varchar(120) = '',
	@betteam14 varchar(120) = '',
	@betteam16 varchar(120) = '',
	@SAFilter tinyint
AS  
/*  
 Created by: Elodie
 Date:20120703
 Original: Acc_BettransSelSpecialDel_EarlyKO
 Task: Get ticket information needed to be deleted for early kickoff
 DB: DB053.BODB02  
  
 Revision:  

 Explanation's Param:  
	@@betteam430: bettype =4: Correct Score ; bettype =30: 1st Correct Score
	@@betteam6: bettype=6: Total Goal
	@@betteam14: bettype=14: First Goal/Last Goal
	@@betteam16: bettype=16: Half Time/Full Time
    - @SAFilter: 
      + 0: All tickets
      + 1: Normal tickets only
      + 2: SA tickets only	
  
*/
BEGIN
	SET NOCOUNT ON 
	CREATE TABLE #SpecialDeleteBets (transid bigint,SubTransid bigint,refno bigint
	,custid int,username varchar(30),odds smallmoney, OddsType int, transdate datetime,bettype smallint, betteam nvarchar(10),hdp1 smallmoney, hdp2 smallmoney,livehomescore smallint, liveawayscore smallint
	,creator varchar(30),StakePositiontaking money,currency tinyint,IsDeposit bit,site varchar(10),status nvarchar(10), mrecommend int, recommend int, SecAcceptFlag bit)  
	
	CREATE TABLE #SpecialDeleteBetms (transid bigint,SubTransid bigint,refno bigint
	,custid int,username varchar(30),odds smallmoney, OddsType int, transdate datetime,bettype smallint, betteam nvarchar(10),hdp1 smallmoney, hdp2 smallmoney,livehomescore smallint, liveawayscore smallint
	,creator varchar(30),StakePositiontaking money,currency tinyint,IsDeposit bit,site varchar(10),status nvarchar(10), mrecommend int, recommend int, ParlayType smallint)  

	IF exists( SELECT convert(int,val) FROM dbo.strSplit(@bettypes,'^') Where convert(int,val) in (4,30) )	
		INSERT INTO #SpecialDeleteBets 
		SELECT  
			b.transid,
			b.transid AS SubTransID,
			b.refno,
			b.custid,  
			b.username,  
			b.odds,     
			b.OddsType,    
			b.transdate,  
			b.bettype,  
			b.betteam,  
			b.hdp1,  
			b.hdp2,  
			b.livehomescore,  
			b.liveawayscore,  
			cr.username as creator,   
			b.stake as StakePositiontaking,  
			b.currency,  
			1 as IsDeposit, 
			ag.site,
			CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
				 ELSE b.status 
				 END as status,  
			b.mrecommend,  
			b.recommend,
			ISNULL(SecAcceptFlag,0) SecAcceptFlag
		FROM bettrans b with (NOLOCK)	
			INNER JOIN customer ag with (NOLOCK) ON b.recommend = ag.custid  
			INNER JOIN customer cr with (NOLOCK) ON cr.custid = b.creator
			INNER JOIN dbo.strSplit(@bettypes,'^') AS fb ON b.bettype=fb.val
		WHERE	matchid=@matchid   
			AND b.transdate>=@KickOffDate
			AND b.statusID NOT IN (101,102)
			AND b.liveindicator=0
			AND b.bettype in(4,30)
			AND b.betteam  in (SELECT convert(varchar,val) FROM dbo.strSplit(case when @betteam430 = 'All' then betteam else @betteam430 end,'^'))  
    		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END				

	INSERT INTO #SpecialDeleteBets
	SELECT  
		b.transid,
		b.transid AS SubTransID,
		b.refno,
		b.custid,  
		b.username,  
		b.odds,     
		b.OddsType,    
		b.transdate,  
		b.bettype,  
		b.betteam,  
		b.hdp1,  
		b.hdp2,  
		b.livehomescore,  
		b.liveawayscore,  
		cr.username as creator,   
		b.stake as StakePositiontaking,  
		b.currency,   
		1 as IsDeposit,
		ag.site,
		CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
			 ELSE b.status 
			 END as status,  
		b.mrecommend,  
		b.recommend,
		ISNULL(SecAcceptFlag,0) SecAcceptFlag
	FROM bettrans b with (NOLOCK)	
		INNER JOIN customer ag with (NOLOCK) ON b.recommend = ag.custid  
		INNER JOIN customer cr with (NOLOCK) ON cr.custid = b.creator
		INNER JOIN dbo.strSplit(@bettypes,'^') AS fb ON b.bettype=fb.val
	WHERE	matchid=@matchid   
		AND b.transdate>=@KickOffDate
		AND b.statusID NOT IN (101,102)
		AND b.liveindicator=0
		AND CASE
				WHEN b.bettype in (1,3,7,8,2,12) THEN CASE WHEN @betteam1378 = 'ALL' THEN betteam ELSE @betteam1378 END  
				WHEN b.bettype in (5,15) THEN CASE WHEN @betteam515 = 'ALL' THEN betteam ELSE @betteam515 END    
				ELSE betteam
			END = betteam
		AND CASE WHEN b.bettype in (1,3,7,8) THEN CASE   
				 WHEN @hdp = 9999 THEN 1  
				 WHEN @hdp = (hdp1 + hdp2) THEN 1  
				 ELSE 0   
				END  
		ELSE 1 END = 1  
		AND b.bettype NOT IN(4,6,14,16,30)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END			

	UNION ALL  

	SELECT  
		b.transid,
		b.transid AS SubTransID,
		b.refno,
		b.custid,  
		b.username,  
		b.odds,     
		b.OddsType,    
		b.transdate,  
		b.bettype,  
		b.betteam,  
		b.hdp1,  
		hdp2,  
		b.livehomescore,  
		b.liveawayscore,  
		cr.username as creator,   
		b.stake as StakePositiontaking,  
		b.currency, 
		1 as IsDeposit,  
		ag.site,    
		CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
			 ELSE b.status 
			 END as status,  
		b.mrecommend,
		b.recommend,
		ISNULL(SecAcceptFlag,0) SecAcceptFlag		  
	FROM dbo.bettrans b with (NOLOCK)  		
		INNER JOIN dbo.customer AS ag with (NOLOCK) ON b.recommend = ag.custid  
		INNER JOIN dbo.customer AS cr with (NOLOCK) ON cr.custid = b.creator			
	WHERE matchid=@matchid   
		AND b.transdate>=@KickOffDate		
		AND b.statusID NOT IN (101,102)
		AND b.liveindicator=0				
		AND(
			(b.bettype = 6 
			AND b.betteam  in (SELECT convert(varchar,val) FROM dbo.strSplit(case when @betteam6 = 'All' then betteam else @betteam6 end,'^'))  
			)			
			OR
			(b.bettype = 16
			AND b.betteam  in (SELECT convert(varchar,val) FROM dbo.strSplit(case when @betteam16 = 'All' then betteam else @betteam16 end,'^'))  
			)
		)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END					

	UNION ALL  

	SELECT  
		b.transid,
		b.transid AS SubTransID,
		b.refno,
		b.custid,  
		b.username,  
		b.odds,     
		b.OddsType,    
		b.transdate,  
		b.bettype,  
		b.betteam,  
		b.hdp1,  
		hdp2,  
		b.livehomescore,  
		b.liveawayscore,  
		cr.username as creator,   
		b.stake as StakePositiontaking,  
		b.currency,   
		1 as IsDeposit,
		ag.site,    
		CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
			 ELSE b.status 
			 END as status, 
		b.mrecommend,
		b.recommend,
		ISNULL(SecAcceptFlag,0) SecAcceptFlag  
	FROM dbo.bettrans b with (NOLOCK)  		
		INNER JOIN dbo.customer ag with (NOLOCK) ON b.recommend = ag.custid AND b.bettype = 14
		INNER JOIN dbo.customer cr with (NOLOCK) ON cr.custid = b.creator
		LEFT JOIN dbo.strSplit(@betteam14,'^') AS goal ON goal.val=b.betteam--dbo.Acc_SplitIndex(b.betteam,':',2)			
	WHERE matchid=@matchid
		AND b.transdate>=@KickOffDate		
		AND b.statusID NOT IN (101,102)
		AND b.liveindicator=0				
		AND (@betteam14='All' OR goal.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END					
	
	---get sub ticket of a mix parlay	
	CREATE TABLE #Currency (transid bigint,Refno bigint, CurrencyID tinyint,oddstype tinyint, bettype smallint)
	IF EXISTS (SELECT 1 FROM dbo.strSplit(@bettypes,'^') WHERE val IN (9,29))
		AND EXISTS (SELECT 1 FROM dbo.bettransm AS b WITH(NOLOCK) 
					WHERE b.matchid=@matchid  AND b.transdate>=@KickOffDate 
						AND b.statusID NOT IN(101,102) 
						AND b.liveindicator=0)							
						
	BEGIN		
		INSERT INTO #Currency
		SELECT transid,Refno,Currency,oddstype, b2.bettype
		FROM dbo.bettrans AS b2 WITH(NOLOCK)
			 INNER JOIN dbo.strSplit(@bettypes,'^') AS fb ON b2.bettype=fb.val
		WHERE b2.matchid IN (9,29)
			AND b2.bettype IN (9,29)
			AND (b2.betid IS NULL OR b2.betid = 0)
			AND liveindicator=0
			AND transdate>=@KickOffDate	
			AND statusID NOT IN (101,102)
			AND CASE when @SAFilter = 2 then 0 else 1 END = 1				
		
		INSERT INTO #SpecialDeleteBetms 	
		SELECT  
			cy.transid,
			b.transid AS SubTransID,			
			b.refno,
			b.custid,  
			c.username,  
			b.odds,     
			cy.OddsType,    
			b.transdate,  
			b.bettype,  
			b.betteam,  
			b.hdp1,  
			b.hdp2,  
			b.livehomescore,  
			b.liveawayscore,  
			cr.username as creator,   
			b.stake as StakePositiontaking,  
			cy.currencyID,   
			1 as IsDeposit,
			c.[site],  
			b.status, 
			c.mrecommend,  
			c.recommend,
			cy.bettype as parlaytype 
		FROM dbo.bettransm b with (NOLOCK)	
			INNER JOIN customer AS c with (NOLOCK) ON c.custid=b.custid
			INNER JOIN customer cr with (NOLOCK) ON cr.custid = b.creator	
			INNER JOIN #Currency AS cy WITH(NOLOCK) ON cy.refno= b.refno
			--INNER JOIN dbo.strSplit(@bettypes,'^') AS fb ON fb.val=9--mix parlay
		WHERE	b.matchid=@matchid
			AND b.transdate>=@KickOffDate				 
			AND b.statusID NOT IN (101,102)	  
			AND b.liveindicator=0			
			AND CASE when @SAFilter = 2 then 0 else 1 END = 1
	END--exists bettype=9

	--SINGLE TICKET SECTION		
	SELECT s.*,IsMP=0
	FROM #SpecialDeleteBets AS s with (NOLOCK)
	ORDER BY transid

	---MIX PARLAY SECTION
	SELECT s.*,IsMP=1
	FROM #SpecialDeleteBetms AS s with (NOLOCK)
	ORDER BY transid
			
	DROP TABLE #SpecialDeleteBets
	DROP TABLE #SpecialDeleteBetms
	DROP TABLE #Currency
	
	SET NOCOUNT OFF	
END

GO
GRANT EXECUTE ON [dbo].Acc_IOM_BettransSelSpecialDel_EarlyKO TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].Acc_IOM_BettransSelSpecialDel_EarlyKO TO [vnteam]
GO